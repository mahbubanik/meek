import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/prayer_service.dart';
import '../../services/quran_api_service.dart';
import '../quran/quran_screen.dart';
import '../fiqh/fiqh_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/ambient_orb.dart';
import '../../services/version_check_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PrayerService _prayerService = PrayerService();
  
  // State
  String _greeting = 'Assalamu Alaikum';
  int _currentSurah = 1;
  int _currentAyah = 1;
  String? _currentPrayer;
  String? _timeRemaining;
  bool _isLoading = true;
  int _userStreak = 0; // Added streak state

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Check for updates after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionCheckService().checkVersion(context);
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load prayer times
      final prayerTimes = await _prayerService.getPrayerTimes();
      if (prayerTimes != null && mounted) {
        // Schedule Notifications
        // Note: Real app should check 'notifications_enabled' from preferences
        _prayerService.schedulePrayerNotifications(prayerTimes);

        final current = _prayerService.getCurrentPrayer(prayerTimes);
        if (current != null) {
          setState(() {
            _currentPrayer = current.name;
            _timeRemaining = _prayerService.formatTimeRemaining(current.minutesRemaining);
          });
        } else {
          final next = _prayerService.getNextPrayer(prayerTimes);
          if (next != null) {
            setState(() {
              _currentPrayer = next.name;
              _timeRemaining = 'in ${_prayerService.formatTimeRemaining(next.minutesRemaining)}';
            });
          }
        }
      }
      
      // Dynamic Greeting
      final hour = DateTime.now().hour;
      String greeting = 'Assalamu Alaikum';
      if (hour >= 5 && hour < 12) greeting = 'Sabah al-Khair';
      else if (hour >= 12 && hour < 17) greeting = 'Masa\' al-Khair';
      else if (hour >= 17 && hour < 22) greeting = 'Masa\' al-Nur';
      
      if (mounted) setState(() => _greeting = greeting);
      
      // Load user data from Supabase
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        // 1. Get Progress
        final progressResponse = await supabase
            .from('quran_progress') // Updated table name from initial schema sync
            .select('last_surah, last_ayah')
            .eq('user_id', user.id)
            .maybeSingle(); // Use maybeSingle to avoid exception on empty
        
        // 2. Get Streak
        final streakResponse = await supabase
            .from('user_streaks')
            .select('current_streak')
            .eq('user_id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            if (progressResponse != null) {
              _currentSurah = progressResponse['last_surah'] ?? 1;
              _currentAyah = (progressResponse['last_ayah'] ?? 0) + 1;
            }
            if (streakResponse != null) {
              _userStreak = streakResponse['current_streak'] ?? 0;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader()
                    .animate()
                    .fadeIn()
                    .slideX(begin: -0.1),
                  
                  const SizedBox(height: AppTheme.spacing16),
                  
                  // Zone A: Quran Card (flex 3 = 60%)
                  Expanded(
                    flex: 3,
                    child: _buildQuranCard()
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.05),
                  ),
                  
                  const SizedBox(height: AppTheme.spacing12),
                  
                  // Zone B: Fiqh Q&A (flex 2 = 40%)
                  Expanded(
                    flex: 2,
                    child: _buildFiqhSection()
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.05),
                  ),
                ],
              ),
            ),
          ),
          
          // Ambient Orb (floating)
          const AmbientOrb(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Greeting and Prayer Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: AppTypography.headingSmall(context.foregroundColor),
            ),
            const SizedBox(height: 4),
            if (_currentPrayer != null)
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_currentPrayer',
                    style: AppTypography.labelMedium(context.foregroundColor),
                  ),
                  Text(
                    ' • $_timeRemaining left',
                    style: AppTypography.bodySmall(context.mutedColor),
                  ),
                ],
              ),
          ],
        ),
        
        // Header Actions
        Row(
          children: [
            // Streak Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warmGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warmGold.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.warmGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_userStreak',
                    style: const TextStyle(
                      color: AppColors.warmGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),

            // Notification Bell
            _buildNotificationBell(),
            const SizedBox(width: AppTheme.spacing8),
            // Profile Avatar
            _buildProfileButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: context.borderColor),
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: context.mutedColor,
              size: 20,
            ),
            onPressed: () {
              // Show notifications
            },
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline,
          color: context.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildQuranCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuranScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(32), // Exact match to web
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Top Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Surah $_currentSurah',
                          style: AppTypography.headingSmall(context.foregroundColor),
                        ),
                        Text(
                          'Verse $_currentAyah',
                          style: AppTypography.bodySmall(context.mutedColor),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: context.mutedColor.withValues(alpha: 0.1),
                        borderRadius: AppTheme.borderRadiusFull,
                      ),
                      child: Text(
                        _currentAyah == 1 && _currentSurah == 1 ? 'BEGIN' : 'CONTINUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: context.mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Progress Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(true),
                    _buildProgressDot(true, opacity: 0.4),
                    _buildProgressDot(false),
                    _buildProgressDot(false),
                    _buildProgressDot(false),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacing16),
                
                // Arabic Opening
                Column(
                  children: [
                    Text(
                      'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
                      style: AppTypography.arabicMedium(
                        context.foregroundColor.withValues(alpha: 0.9),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                      style: AppTypography.arabicLarge(context.foregroundColor),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacing16),
                
                // Hint
                Text(
                  'TAP ANYWHERE TO PRACTICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: context.foregroundColor.withValues(alpha: 0.6),
                  ),
                ),
                
                const Spacer(),
                
                // Continue Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: AppTheme.borderRadiusLarge,
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Continue',
                        style: AppTypography.button(Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildProgressDot(bool active, {double opacity = 1.0}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active 
          ? context.primaryColor.withValues(alpha: opacity)
          : context.borderColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: context.primaryColor.withValues(alpha: 0.4),
          strokeWidth: 2,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'GATHERING PROGRESS...',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: context.mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFiqhSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'FIQH Q&A',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: context.foregroundColor.withValues(alpha: 0.7),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        // Search Bar
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const FiqhScreen()),
                ),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppTheme.borderRadiusFull,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: context.mutedColor, size: 18),
                      const SizedBox(width: AppTheme.spacing12),
                      Text(
                        'Ask about prayer, fasting...',
                        style: AppTypography.bodyMedium(context.mutedColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: AppTheme.spacing8),
            
            // Mic Button
            GestureDetector(
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const FiqhScreen()),
              ),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_outlined,
                  color: context.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        // Empty state or recent questions
        Expanded(
          child: Center(
            child: Text(
              'Ask any Islamic question',
              style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

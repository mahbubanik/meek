import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../services/prayer_service.dart';

/// The Ambient Orb - A Breakthrough UI Component
/// 
/// A subtle, spiritually-aware presence that hovers at the bottom of the screen.
/// It pulses gently when there's a spiritual context to share, never intrusive,
/// always caring. Like a patient friend who waits for you to be ready.
class AmbientOrb extends StatefulWidget {
  const AmbientOrb({super.key});

  @override
  State<AmbientOrb> createState() => _AmbientOrbState();
}

class _AmbientOrbState extends State<AmbientOrb> with SingleTickerProviderStateMixin {
  final PrayerService _prayerService = PrayerService();
  
  bool _isExpanded = false;
  bool _isActive = true;
  PrayerTimes? _prayerTimes;
  PrayerInfo? _currentPrayer;
  PrayerInfo? _nextPrayer;
  
  // Today's duas (rotating)
  final List<Map<String, String>> _duas = [
    {
      'arabic': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'transliteration': 'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina adhaban-nar',
      'english': 'Our Lord, give us good in this world and good in the Hereafter and protect us from the torment of the Fire.',
      'source': 'Quran 2:201',
    },
    {
      'arabic': 'سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ الْعَظِيمِ',
      'transliteration': 'Subhan Allahi wa bihamdihi, Subhan Allahil Adheem',
      'english': 'Glory be to Allah and praise Him, Glory be to Allah the Almighty.',
      'source': 'Sahih Bukhari',
    },
  ];
  
  Map<String, String> get _todaysDua => _duas[DateTime.now().day % _duas.length];

  @override
  void initState() {
    super.initState();
    _loadPrayerData();
  }

  Future<void> _loadPrayerData() async {
    try {
      final times = await _prayerService.getPrayerTimes();
      if (times != null && mounted) {
        setState(() {
          _prayerTimes = times;
          _currentPrayer = _prayerService.getCurrentPrayer(times);
          _nextPrayer = _prayerService.getNextPrayer(times);
        });
      }
    } catch (e) {
      debugPrint('Ambient Orb error: $e');
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop when expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ).animate().fadeIn(duration: 200.ms),
            ),
          ),
        
        // The Orb Button
        Positioned(
          bottom: 24,
          right: 24,
          child: GestureDetector(
            onTap: _toggleExpand,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                if (_isActive && !_isExpanded)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.primaryColor.withValues(alpha: 0.3),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.4, 1.4),
                      duration: 2500.ms,
                    )
                    .fade(begin: 0.4, end: 0, duration: 2500.ms),
                
                // Inner orb
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primaryColor,
                        context.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.dark_mode,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded Panel with Scroll
        if (_isExpanded)
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return _buildExpandedPanel(scrollController)
                  .animate()
                  .fadeIn(duration: 200.ms);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedPanel(ScrollController scrollController) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 80),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.dark_mode, color: context.primaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'SPIRITUAL MOMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: context.foregroundColor.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.mutedColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16, color: context.foregroundColor.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current Prayer Window
          if (_currentPrayer != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).fade(begin: 1, end: 0.3, duration: 1000.ms),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentPrayer!.name} Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '${_prayerService.formatTimeRemaining(_currentPrayer!.minutesRemaining)} remaining',
                          style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Next Prayer
          if (_nextPrayer != null && _currentPrayer == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.schedule, color: context.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nextPrayer!.name,
                          style: AppTypography.bodyMedium(context.foregroundColor),
                        ),
                        Text(
                          'In ${_prayerService.formatTimeRemaining(_nextPrayer!.minutesRemaining)}',
                          style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Dua Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S DUA",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: context.foregroundColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _todaysDua['arabic']!,
                        style: AppTypography.arabicMedium(context.primaryColor),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _todaysDua['transliteration']!,
                        style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.7)).copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${_todaysDua['english']!}"',
                        style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.9)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Divider(color: context.borderColor),
                      const SizedBox(height: 8),
                      Text(
                        '— ${_todaysDua['source']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.foregroundColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_arrow_up, color: context.foregroundColor.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 4),
              Text(
                'Tap outside to close',
                style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.5)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

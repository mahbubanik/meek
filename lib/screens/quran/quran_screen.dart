import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../services/quran_api_service.dart';
import '../../widgets/quran/surah_selector.dart';
import '../../widgets/quran/listen_tab.dart';
import '../../widgets/quran/meaning_tab.dart';
import '../../widgets/quran/practice_tab.dart';

/// Quran Screen - Exact match to web app design
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QuranApiService _quranService = QuranApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Current state
  Surah? _currentSurah;
  Verse? _currentVerse;
  int _currentAyah = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Start with Al-Ikhlas (Surah 112) like the screenshot
      _currentSurah = allSurahs.firstWhere((s) => s.id == 112);
      await _loadVerse(_currentSurah!.id, _currentAyah);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVerse(int surahId, int ayah) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final verse = await _quranService.getVerse(surahId, ayah);
      setState(() {
        _currentVerse = verse;
        _currentAyah = ayah;
      });
    } catch (e) {
      // Use offline fallback
      setState(() {
        _currentVerse = Verse(
          id: 1,
          verseKey: '$surahId:$ayah',
          verseNumber: ayah,
          surahNumber: surahId,
          textUthmani: _getOfflineArabicText(surahId, ayah),
          translations: [],
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getOfflineArabicText(int surah, int ayah) {
    // Bismillah
    if (ayah == 1 && surah != 1 && surah != 9) {
      return 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
    }
    // Al-Ikhlas
    if (surah == 112) {
      const verses = [
        'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        'ٱللَّهُ ٱلصَّمَدُ',
        'لَمْ يَلِدْ وَلَمْ يُولَدْ',
        'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
      ];
      return verses[ayah.clamp(1, 4) - 1];
    }
    return 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ';
  }

  void _selectSurah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahSelector(
        onSelect: (surah) {
          setState(() {
            _currentSurah = surah;
            _currentAyah = 1;
          });
          _loadVerse(surah.id, 1);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _previousVerse() {
    if (_currentAyah > 1) {
      _loadVerse(_currentSurah!.id, _currentAyah - 1);
    }
  }

  void _nextVerse() {
    if (_currentSurah != null && _currentAyah < _currentSurah!.versesCount) {
      _loadVerse(_currentSurah!.id, _currentAyah + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.deepNavy : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header (X button, Surah name, progress dots)
            _buildHeader(isDark),
            
            // Tab Bar (Listen, Meaning, Practice)
            _buildTabBar(isDark),
            
            // Content
            Expanded(
              child: _isLoading
                ? _buildLoadingState()
                : _error != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        ListenTab(
                          verse: _currentVerse!,
                          surah: _currentSurah!,
                          audioPlayer: _audioPlayer,
                        ),
                        MeaningTab(
                          verse: _currentVerse!,
                          surah: _currentSurah!,
                        ),
                        PracticeTab(
                          verse: _currentVerse!,
                          surah: _currentSurah!,
                          onComplete: () => _nextVerse(),
                        ),
                      ],
                    ),
            ),
            
            // Bottom Navigation (Prev | Verse X of Y | Next) - matches screenshot
            _buildBottomNavigation(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // X (Close) button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.close,
              color: isDark ? AppColors.cream : AppColors.charcoal,
              size: 24,
            ),
          ),
          
          const Spacer(),
          
          // Surah name with dropdown
          GestureDetector(
            onTap: _selectSurah,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentSurah?.nameSimple ?? 'Al-Ikhlas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.cream : AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? AppColors.cream : AppColors.charcoal,
                  size: 20,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Progress dots (placeholder for now)
          _buildProgressDots(isDark),
        ],
      ),
    );
  }

  Widget _buildProgressDots(bool isDark) {
    final totalVerses = _currentSurah?.versesCount ?? 4;
    final dotsToShow = totalVerses > 5 ? 5 : totalVerses;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotsToShow, (index) {
        final isActive = index < _currentAyah;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.warmGold
                : (isDark ? Colors.white24 : Colors.black26),
          ),
        );
      }),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? AppColors.cream.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.6),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Listen'),
          Tab(text: 'Meaning'),
          Tab(text: 'Practice'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.teal),
          const SizedBox(height: 16),
          Text(
            'Loading verse...',
            style: TextStyle(color: AppColors.lightGray),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Could not load verse',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(color: AppColors.lightGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom navigation - EXACT match to screenshot
  /// Shows: < Prev | Verse X of Y | Next >
  Widget _buildBottomNavigation(bool isDark) {
    // Hide on Practice tab
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 2) return const SizedBox.shrink();
        
        final canGoPrev = _currentAyah > 1;
        final canGoNext = _currentSurah != null && _currentAyah < _currentSurah!.versesCount;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.deepNavy : AppColors.offWhite,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous
              GestureDetector(
                onTap: canGoPrev ? _previousVerse : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: canGoPrev
                          ? (isDark ? AppColors.cream : AppColors.charcoal)
                          : (isDark ? Colors.white24 : Colors.black26),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Prev',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: canGoPrev
                            ? (isDark ? AppColors.cream : AppColors.charcoal)
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Verse indicator
              Text(
                'Verse $_currentAyah of ${_currentSurah?.versesCount ?? 0}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.cream.withValues(alpha: 0.6) : AppColors.charcoal.withValues(alpha: 0.6),
                ),
              ),
              
              // Next
              GestureDetector(
                onTap: canGoNext ? _nextVerse : null,
                child: Row(
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: canGoNext
                            ? AppColors.teal
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: canGoNext
                          ? AppColors.teal
                          : (isDark ? Colors.white24 : Colors.black26),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

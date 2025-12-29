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
      // Start with Al-Fatihah
      _currentSurah = allSurahs.firstWhere((s) => s.id == 1);
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
          textUthmani: surahId == 1 && ayah == 1 
            ? 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'
            : 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
          translations: [],
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader().animate().fadeIn().slideY(begin: -0.1),
            
            // Tab Bar
            _buildTabBar(),
            
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
            
            // Navigation Footer (for Listen & Meaning tabs)
            _buildNavigationFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: context.foregroundColor),
          ),
          
          // Surah name (tappable)
          Expanded(
            child: GestureDetector(
              onTap: _selectSurah,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentSurah?.nameSimple ?? 'Select Surah',
                        style: AppTypography.headingSmall(context.foregroundColor),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: context.mutedColor,
                        size: 20,
                      ),
                    ],
                  ),
                  if (_currentSurah != null)
                    Text(
                      'Verse $_currentAyah of ${_currentSurah!.versesCount}',
                      style: AppTypography.bodySmall(context.mutedColor),
                    ),
                ],
              ),
            ),
          ),
          
          // Settings
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_outlined, color: context.mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.borderRadiusFull,
        border: Border.all(color: context.borderColor),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: context.primaryColor,
          borderRadius: AppTheme.borderRadiusFull,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: context.mutedColor,
        labelStyle: AppTypography.labelMedium(Colors.white),
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
          CircularProgressIndicator(color: context.primaryColor),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Loading verse...',
            style: AppTypography.bodyMedium(context.mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Could not load verse',
              style: AppTypography.headingSmall(context.foregroundColor),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              _error ?? 'Unknown error',
              style: AppTypography.bodySmall(context.mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationFooter() {
    // Hide footer on Practice tab
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 2) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              top: BorderSide(color: context.borderColor),
            ),
          ),
          child: Row(
            children: [
              // Previous
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentAyah > 1 ? _previousVerse : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
              ),
              
              const SizedBox(width: AppTheme.spacing12),
              
              // Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentSurah != null && _currentAyah < _currentSurah!.versesCount
                    ? _nextVerse
                    : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

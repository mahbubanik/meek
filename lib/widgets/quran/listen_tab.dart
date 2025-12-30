import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/quran_api_service.dart';

/// Listen Tab - Exact clone from web app
/// Features: Arabic verse, Play Sheikh button, 2-column word grid with numbered badges
class ListenTab extends StatefulWidget {
  final Verse verse;
  final Surah surah;
  final AudioPlayer audioPlayer;

  const ListenTab({
    super.key,
    required this.verse,
    required this.surah,
    required this.audioPlayer,
  });

  @override
  State<ListenTab> createState() => _ListenTabState();
}

class _ListenTabState extends State<ListenTab> {
  final QuranApiService _quranService = QuranApiService();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _loadingWords = false;
  String? _audioUrl;
  int? _playingWordIndex;
  List<Map<String, dynamic>> _wordMeanings = [];
  AudioPlayer? _wordAudioPlayer;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    _loadWordByWord();
    _setupAudioListener();
    _wordAudioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _wordAudioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ListenTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verse.verseKey != widget.verse.verseKey) {
      _loadAudio();
      _loadWordByWord();
    }
  }

  void _setupAudioListener() {
    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
          }
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    setState(() => _isLoading = true);
    try {
      final url = await _quranService.getAudioUrl(
        widget.surah.id,
        widget.verse.verseNumber,
      );
      _audioUrl = url;
      await widget.audioPlayer.setUrl(url);
    } catch (e) {
      debugPrint('Error loading audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWordByWord() async {
    setState(() => _loadingWords = true);
    try {
      final words = await _quranService.getWordByWord(
        widget.surah.id,
        widget.verse.verseNumber,
      );
      if (mounted) {
        setState(() => _wordMeanings = words);
      }
    } catch (e) {
      debugPrint('Error loading words: $e');
      // Fallback to verse words if API fails
      if (mounted) {
        setState(() {
          _wordMeanings = widget.verse.words
              .where((w) => w.isWord)
              .map((w) => {
                    'text_uthmani': w.textUthmani,
                    'transliteration': {'text': w.transliteration ?? ''},
                    'translation': {'text': w.translation ?? ''},
                  })
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingWords = false);
    }
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.seek(Duration.zero);
      await widget.audioPlayer.play();
    }
  }

  Future<void> _playWord(Map<String, dynamic> word, int idx) async {
    setState(() => _playingWordIndex = idx);
    
    // Check if word has audio URL
    final audioUrl = word['audio']?['url'];
    if (audioUrl == null) {
      // No word audio, just highlight briefly
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _playingWordIndex = null);
      });
      return;
    }

    try {
      final fullUrl = 'https://audio.qurancdn.com/$audioUrl';
      await _wordAudioPlayer?.setUrl(fullUrl);
      await _wordAudioPlayer?.play();
      
      _wordAudioPlayer?.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playingWordIndex = null);
        }
      });
    } catch (e) {
      debugPrint('Word audio error: $e');
      if (mounted) setState(() => _playingWordIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing24),
          
          // Main Verse Display (centered Arabic)
          _buildMainVerseDisplay()
            .animate()
            .fadeIn()
            .slideY(begin: 0.05),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Play Sheikh Button
          _buildPlaySheikhButton()
            .animate()
            .fadeIn(delay: 100.ms),
          
          const SizedBox(height: AppTheme.spacing32),
          
          // Word by Word Section
          _buildWordByWordSection()
            .animate()
            .fadeIn(delay: 200.ms),
          
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildMainVerseDisplay() {
    return Column(
      children: [
        // Arabic Verse - Large, Gold, Centered
        Text(
          widget.verse.textUthmani,
          style: AppTypography.arabicLarge(context.arabicTextColor).copyWith(
            fontSize: 32,
            height: 2.0,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        
        const SizedBox(height: AppTheme.spacing16),
        
        // Instruction label
        Text(
          'LISTEN & REPEAT • TAP WORDS TO HEAR PRONUNCIATION',
          style: AppTypography.uppercaseLabel(context.mutedColor).copyWith(
            fontSize: 10,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlaySheikhButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _togglePlayback,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: context.primaryColor,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: context.primaryColor,
                size: 24,
              ),
            const SizedBox(width: 12),
            Text(
              _isPlaying ? 'Pause' : 'Play Sheikh',
              style: AppTypography.bodyMedium(context.primaryColor).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordByWordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.volume_up,
              size: 16,
              color: context.mutedColor,
            ),
            const SizedBox(width: 8),
            Text(
              'WORD-BY-WORD (TAP TO HEAR)',
              style: AppTypography.uppercaseLabel(context.mutedColor),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacing16),
        
        // Word Grid - 2 columns exactly like web app
        _loadingWords
            ? _buildLoadingGrid()
            : _buildWordGrid(),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: context.mutedColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: context.mutedColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: context.mutedColor.withValues(alpha: 0.1),
        );
      },
    );
  }

  Widget _buildWordGrid() {
    // Filter out non-word entries (like verse numbers)
    final words = _wordMeanings.where((w) {
      final text = w['text_uthmani']?.toString() ?? '';
      return text.isNotEmpty && !text.contains('۞');
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: words.length,
      itemBuilder: (context, idx) {
        final word = words[idx];
        final isActive = _playingWordIndex == idx;
        
        return _buildWordCard(word, idx, isActive);
      },
    );
  }

  Widget _buildWordCard(Map<String, dynamic> word, int idx, bool isActive) {
    final textUthmani = word['text_uthmani']?.toString() ?? '';
    final transliteration = word['transliteration']?['text']?.toString() ?? '';
    final translation = word['translation']?['text']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _playWord(word, idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? context.primaryColor
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? context.primaryColor
                : context.borderColor,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Numbered Badge (top-left)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : context.mutedColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.white
                          : context.mutedColor,
                    ),
                  ),
                ),
              ),
            ),
            
            // Word Content (centered)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arabic Word
                  Text(
                    textUthmani,
                    style: AppTypography.arabicMedium(
                      isActive ? Colors.white : context.primaryColor,
                    ).copyWith(fontSize: 24),
                    textDirection: TextDirection.rtl,
                  ),
                  
                  if (transliteration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // Transliteration
                    Text(
                      transliteration,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.8)
                            : context.mutedColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  if (translation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // Translation
                    Text(
                      translation,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : context.foregroundColor.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Audio indicator when playing
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.volume_up,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

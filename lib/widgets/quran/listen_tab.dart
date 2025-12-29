import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/quran_api_service.dart';

/// Listen Tab - Audio playback with word-by-word display
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
  String? _audioUrl;
  int? _activeWordIndex;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    _setupAudioListener();
  }

  @override
  void didUpdateWidget(ListenTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verse.verseKey != widget.verse.verseKey) {
      _loadAudio();
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
    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _playWord(int index) {
    setState(() {
      _activeWordIndex = index;
    });
    // Brief haptic-like visual feedback
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _activeWordIndex = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing24),
          
          // Arabic Verse (Large Display)
          _buildArabicDisplay()
            .animate()
            .fadeIn()
            .slideY(begin: 0.05),
          
          const SizedBox(height: AppTheme.spacing32),
          
          // Play Button
          _buildPlayButton()
            .animate()
            .fadeIn(delay: 100.ms)
            .scale(begin: const Offset(0.9, 0.9)),
          
          const SizedBox(height: AppTheme.spacing32),
          
          // Word by Word
          if (widget.verse.words.isNotEmpty)
            _buildWordByWord()
              .animate()
              .fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildArabicDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.borderRadiusXLarge,
        border: Border.all(color: context.borderColor),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Text(
            widget.verse.textUthmani,
            style: AppTypography.arabicLarge(context.arabicTextColor),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Verse reference
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: AppTheme.borderRadiusFull,
            ),
            child: Text(
              '${widget.surah.nameSimple} ${widget.verse.verseNumber}',
              style: AppTypography.labelSmall(context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Column(
      children: [
        // Main Play Button
        GestureDetector(
          onTap: _isLoading ? null : _togglePlayback,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primaryColor,
                  context.accentColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowPrimary(context.primaryColor),
            ),
            child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        Text(
          _isPlaying ? 'Tap to pause' : 'Tap to listen',
          style: AppTypography.bodySmall(context.mutedColor),
        ),
      ],
    );
  }

  Widget _buildWordByWord() {
    final words = widget.verse.words.where((w) => w.isWord).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORD BY WORD',
          style: AppTypography.uppercaseLabel(context.mutedColor),
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppTheme.borderRadiusLarge,
            border: Border.all(color: context.borderColor),
          ),
          child: Wrap(
            spacing: AppTheme.spacing12,
            runSpacing: AppTheme.spacing16,
            alignment: WrapAlignment.center,
            textDirection: TextDirection.rtl,
            children: words.asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              final isActive = _activeWordIndex == index;
              
              return GestureDetector(
                onTap: () => _playWord(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: isActive 
                      ? context.primaryColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.textUthmani,
                        style: AppTypography.arabicMedium(
                          isActive ? context.primaryColor : context.arabicTextColor,
                        ),
                      ),
                      if (word.translation != null)
                        Text(
                          word.translation!,
                          style: AppTypography.bodySmall(context.mutedColor),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing8),
        
        Text(
          'Tap any word to hear pronunciation',
          style: AppTypography.bodySmall(context.mutedColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

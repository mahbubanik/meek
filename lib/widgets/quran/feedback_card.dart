import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/tajweed_feedback.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../common/completion_modal.dart';

/// Feedback Card - Exact clone from web app's FeedbackView.tsx
/// Features: Emotional header, dual audio cards (Your/Teacher), AI Analysis, Action buttons
class FeedbackCard extends StatefulWidget {
  final TajweedFeedback feedback;
  final VoidCallback onRetry;
  final VoidCallback onComplete;
  final String? userRecordingPath;
  final String? teacherAudioUrl;
  final String surahName;
  final int verseNumber;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onRetry,
    required this.onComplete,
    this.userRecordingPath,
    this.teacherAudioUrl,
    this.surahName = 'Al-Ikhlas',
    this.verseNumber = 1,
  });

  @override
  State<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard> {
  AudioPlayer? _userAudioPlayer;
  AudioPlayer? _teacherAudioPlayer;
  bool _isUserPlaying = false;
  bool _isTeacherPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayers();
  }

  void _initAudioPlayers() {
    if (widget.userRecordingPath != null) {
      _userAudioPlayer = AudioPlayer();
      _userAudioPlayer?.setFilePath(widget.userRecordingPath!);
      _userAudioPlayer?.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isUserPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isUserPlaying = false;
            }
          });
        }
      });
    }

    if (widget.teacherAudioUrl != null) {
      _teacherAudioPlayer = AudioPlayer();
      _teacherAudioPlayer?.setUrl(widget.teacherAudioUrl!);
      _teacherAudioPlayer?.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isTeacherPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isTeacherPlaying = false;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _userAudioPlayer?.dispose();
    _teacherAudioPlayer?.dispose();
    super.dispose();
  }

  void _toggleUserPlayback() async {
    if (_isUserPlaying) {
      await _userAudioPlayer?.pause();
    } else {
      await _userAudioPlayer?.seek(Duration.zero);
      await _userAudioPlayer?.play();
    }
  }

  void _toggleTeacherPlayback() async {
    if (_isTeacherPlaying) {
      await _teacherAudioPlayer?.pause();
    } else {
      await _teacherAudioPlayer?.seek(Duration.zero);
      await _teacherAudioPlayer?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emotionalMessage = widget.feedback.emotionalMessage;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Emotional Header with Mashallah
          _buildEmotionalHeader(context, emotionalMessage)
            .animate()
            .fadeIn(),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // 2. Your Recitation Audio Card
          _buildAudioCard(
            context: context,
            title: 'YOUR RECITATION',
            isPlaying: _isUserPlaying,
            onPlay: widget.userRecordingPath != null ? _toggleUserPlayback : null,
            isPrimary: true,
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Divider
          Container(
            height: 1,
            color: context.borderColor,
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // 3. Teacher's Version Audio Card
          _buildAudioCard(
            context: context,
            title: "TEACHER'S VERSION",
            isPlaying: _isTeacherPlaying,
            onPlay: widget.teacherAudioUrl != null ? _toggleTeacherPlayback : null,
            isPrimary: false,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Divider
          Container(
            height: 1,
            color: context.borderColor,
          ),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // 4. AI Analysis Section
          _buildAIAnalysisSection(context)
            .animate()
            .fadeIn(delay: 300.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Divider
          Container(
            height: 1,
            color: context.borderColor,
          ),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // 5. Action Buttons
          _buildActionButtons(context)
            .animate()
            .fadeIn(delay: 400.ms),
          
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildEmotionalHeader(BuildContext context, EmotionalMessage message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: context.borderColor.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          Text(
            message.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            message.arabic,
            style: AppTypography.arabicFeedback(context.primaryColor).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.english,
            style: AppTypography.bodySmall(context.foregroundColor.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.surahName,
                style: AppTypography.labelSmall(context.mutedColor),
              ),
              Text(' • ', style: TextStyle(color: context.mutedColor)),
              Text(
                'Verse ${widget.verseNumber}',
                style: AppTypography.labelSmall(context.mutedColor).copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard({
    required BuildContext context,
    required String title,
    required bool isPlaying,
    required VoidCallback? onPlay,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary 
            ? context.surfaceColor 
            : context.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.uppercaseLabel(context.mutedColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Play Button
              GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? context.primaryColor 
                        : context.mutedColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: isPrimary
                        ? [
                            BoxShadow(
                              color: context.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: isPrimary 
                        ? Colors.white 
                        : context.mutedColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Waveform Visualization
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(24, (index) {
                      // Simulate waveform pattern
                      final heights = isPrimary
                          ? [0.5, 1.0, 0.3, 0.8, 0.5, 1.0, 0.3, 0.6, 0.9, 0.4, 0.7, 0.5, 1.0, 0.3, 0.8, 0.5, 1.0, 0.3, 0.6, 0.9, 0.4, 0.7, 0.5, 1.0]
                          : [0.4, 0.8, 0.2, 0.6, 0.4, 0.8, 0.2, 0.5, 0.7, 0.3, 0.6, 0.4, 0.8, 0.2, 0.6, 0.4, 0.8, 0.2, 0.5, 0.7, 0.3, 0.6, 0.4, 0.8];
                      final height = heights[index % heights.length];
                      
                      return Container(
                        width: 3,
                        height: 32 * height,
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? (index % 3 == 0 
                                  ? context.primaryColor 
                                  : context.primaryColor.withValues(alpha: 0.2))
                              : (index % 2 == 0 
                                  ? context.mutedColor 
                                  : context.mutedColor.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Analysis Header with Score
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI Analysis: ',
              style: AppTypography.bodyMedium(context.primaryColor).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.feedback.score}% Match',
              style: AppTypography.bodyMedium(context.primaryColor).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Positives with green checkmarks
        if (widget.feedback.positives.isNotEmpty) ...[
          ...widget.feedback.positives.map((positive) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      positive,
                      style: AppTypography.bodyMedium(context.foregroundColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        
        // Improvements in orange card
        if (widget.feedback.improvements.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'TO IMPROVE',
                      style: AppTypography.uppercaseLabel(Colors.orange.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...widget.feedback.improvements.map((improvement) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      improvement,
                      style: AppTypography.bodyMedium(context.foregroundColor.withValues(alpha: 0.8)),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        
        // Violations in Red Card (Specific Mistakes)
        if (widget.feedback.violations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'SPECIFIC MISTAKES',
                      style: AppTypography.uppercaseLabel(Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...widget.feedback.violations.map((violation) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '-${violation.deduction}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${violation.rule} (${violation.timestamp})',
                            style: AppTypography.bodySmall(context.foregroundColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        
        // Details quote
        if (widget.feedback.details.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            widget.feedback.details,
            style: AppTypography.bodySmall(context.mutedColor).copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT NEXT?',
          style: AppTypography.uppercaseLabel(context.mutedColor),
        ),
        const SizedBox(height: 16),
        
        // Practice Again Button
        GestureDetector(
          onTap: widget.onRetry,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: context.mutedColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Practice Again',
                  style: AppTypography.bodyMedium(context.mutedColor).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Mark Complete Button (Primary)
        GestureDetector(
          onTap: () {
            // Trigger Completion Modal
            CompletionModal.show(
              context,
              surahNumber: 112, // TODO: Pass actual surah
              verseNumber: widget.verseNumber,
              onContinue: () {
                Navigator.of(context).pop(); // Close modal
                widget.onComplete(); // Navigate to next
              },
              onPracticeAgain: () {
                Navigator.of(context).pop(); // Close modal
                widget.onRetry(); // Retry
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(12),
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
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mark Verse Complete',
                  style: AppTypography.bodyMedium(Colors.white).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Skip to Next Button
        GestureDetector(
          onTap: widget.onComplete,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Skip to Next Verse',
                  style: AppTypography.bodySmall(context.primaryColor).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: context.primaryColor, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io' as io; // Prefixed to avoid conflicts, used conditionally
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart'; // For fetching blob on web

import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../models/tajweed_feedback.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import 'feedback_card.dart';
import 'waveform.dart';

/// Practice Tab - Recording with AI feedback
class PracticeTab extends StatefulWidget {
  final Verse verse;
  final Surah surah;
  final VoidCallback onComplete;

  const PracticeTab({
    super.key,
    required this.verse,
    required this.surah,
    required this.onComplete,
  });

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

enum RecordingState { ready, recording, processing, feedback }

class _PracticeTabState extends State<PracticeTab> {
  final AudioRecorder _recorder = AudioRecorder();
  final AiService _aiService = AiService();

  RecordingState _state = RecordingState.ready;
  int _duration = 0;
  Timer? _timer;
  List<double> _audioLevels = List.filled(15, 0.1);
  TajweedFeedback? _feedback;
  String? _recordingPath; // Path on mobile/desktop, or Blob URL on web

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        String? path;
        
        if (!kIsWeb) {
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        } 
        // On web, path is ignored by start(), it returns a blob URL on stop()

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // Browser might use default if this isn't supported
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path ?? '',
        );

        setState(() {
          _recordingPath = path; // Will be null on web initially
          _state = RecordingState.recording;
          _duration = 0;
        });

        // Start timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_duration >= 120) {
            _stopRecording();
            return;
          }
          setState(() {
            _duration++;
          });
        });

        // Start monitoring amplitude for waveform
        _monitorAmplitude();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _monitorAmplitude() async {
    while (_state == RecordingState.recording) {
      if (!mounted) break;
      try {
        final amplitude = await _recorder.getAmplitude();
        final level = (amplitude.current + 60) / 60; // Normalize to 0-1
        
        setState(() {
          _audioLevels = [
            ..._audioLevels.sublist(1),
            level.clamp(0.1, 1.0),
          ];
        });
      } catch (e) {
        // Ignore amplitude errors
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    
    try {
      final path = await _recorder.stop();
      debugPrint('🛑 Recording stopped. Output path/url: $path');
      
      setState(() {
        _recordingPath = path;
        _state = RecordingState.processing;
      });

      if (path != null) {
        await _analyzeRecording(path);
      } else {
        _resetRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording failed: No audio captured')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _resetRecording();
    }
  }

  Future<void> _analyzeRecording(String path) async {
    try {
      Uint8List? audioBytes;

      if (kIsWeb) {
        // Fetch audio bytes from Blob URL
        debugPrint('🌐 Fetching audio from Blob URL: $path');
        final response = await Dio().get(
          path,
          options: Options(responseType: ResponseType.bytes),
        );
        audioBytes = Uint8List.fromList(response.data);
      } else {
        // Read from file system
        debugPrint('📂 Reading audio from file: $path');
        final file = io.File(path);
        audioBytes = await file.readAsBytes();
      }

      if (audioBytes == null || audioBytes.isEmpty) {
        throw Exception('Failed to get audio bytes');
      }

      debugPrint('🎙️ Analyzing ${audioBytes.length} bytes of audio...');

      final feedback = await _aiService.analyzeRecitation(
        audioBytes: audioBytes,
        surah: widget.surah.id,
        ayah: widget.verse.verseNumber,
        verseText: widget.verse.textUthmani,
      );

      if (mounted) {
        setState(() {
          _feedback = feedback;
          _state = RecordingState.feedback;
        });
      }
    } catch (e) {
      debugPrint('Error during analysis: $e');
      // Use fallback feedback on error unless it's a critical logic failure
      if (mounted) {
        setState(() {
          _feedback = TajweedFeedback(
            score: 0,
            positives: [],
            improvements: ['Could not analyze audio. Please try again.'],
            violations: [],
            details: 'Detailed Error: $e',
          );
          _state = RecordingState.feedback;
        });
      }
    }
  }

  void _resetRecording() {
    setState(() {
      _state = RecordingState.ready;
      _duration = 0;
      _feedback = null;
      _audioLevels = List.filled(15, 0.1);
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing16),
          
          // Status Label
          _buildStatusLabel()
            .animate()
            .fadeIn(),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Arabic Verse
          _buildArabicVerse()
            .animate()
            .fadeIn(delay: 50.ms),
          
          const SizedBox(height: AppTheme.spacing32),
          
          // State-based content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStateContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLabel() {
    String text;
    switch (_state) {
      case RecordingState.ready:
        text = 'READY TO RECITE?';
        break;
      case RecordingState.recording:
        text = '🔴 RECORDING...';
        break;
      case RecordingState.processing:
        text = 'ANALYZING...';
        break;
      case RecordingState.feedback:
        text = 'YOUR FEEDBACK';
        break;
    }

    return Text(
      text,
      style: AppTypography.uppercaseLabel(context.mutedColor),
    );
  }

  Widget _buildArabicVerse() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.borderRadiusXLarge,
        border: Border.all(color: context.borderColor),
      ),
      child: Text(
        widget.verse.textUthmani,
        style: AppTypography.arabicLarge(context.arabicTextColor),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case RecordingState.ready:
        return _buildReadyState();
      case RecordingState.recording:
        return _buildRecordingState();
      case RecordingState.processing:
        return _buildProcessingState();
      case RecordingState.feedback:
        return _buildFeedbackState();
    }
  }

  Widget _buildReadyState() {
    return Column(
      key: const ValueKey('ready'),
      children: [
        // Big Mic Button
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                // Outer glow effect
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
                // Inner shadow for depth
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.mic,
              color: context.isDarkMode ? AppColors.deepNavy : Colors.white,
              size: 48,
            ),
          ),
        ).animate().scale(begin: const Offset(0.9, 0.9)),
        
        const SizedBox(height: AppTheme.spacing16),
        
        Text(
          'Tap to start recording',
          style: AppTypography.bodyMedium(context.mutedColor),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      key: const ValueKey('recording'),
      children: [
        // Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.recordingRed,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).fade(
              begin: 1.0,
              end: 0.3,
              duration: 800.ms,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              _formatDuration(_duration),
              style: AppTypography.monoLarge(context.foregroundColor),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacing24),
        
        // Waveform
        LiveWaveform(levels: _audioLevels),
        
        const SizedBox(height: AppTheme.spacing24),
        
        // Stop Button
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.recordingRedLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.recordingRed.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.stop,
              color: AppColors.recordingRed,
              size: 32,
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        Text(
          'Tap to stop',
          style: AppTypography.bodySmall(context.mutedColor),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      key: const ValueKey('processing'),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: context.primaryColor,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing16),
        
        Text(
          'Analyzing your recitation...',
          style: AppTypography.bodyMedium(context.foregroundColor),
        ),
        
        const SizedBox(height: AppTheme.spacing8),
        
        Text(
          'This takes a moment',
          style: AppTypography.bodySmall(context.mutedColor),
        ),
      ],
    );
  }

  Widget _buildFeedbackState() {
    return Column(
      key: const ValueKey('feedback'),
      children: [
        if (_feedback != null)
          FeedbackCard(
            feedback: _feedback!,
            onRetry: _resetRecording,
            onComplete: widget.onComplete,
          ),
      ],
    );
  }
}

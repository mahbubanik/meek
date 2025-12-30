import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

class CompletionModal extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final VoidCallback onContinue;
  final VoidCallback onPracticeAgain;

  const CompletionModal({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.onContinue,
    required this.onPracticeAgain,
  });

  static Future<void> show(BuildContext context, {
    required int surahNumber,
    required int verseNumber,
    required VoidCallback onContinue,
    required VoidCallback onPracticeAgain,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9), // Dark overlay
      builder: (context) => CompletionModal(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        onContinue: onContinue,
        onPracticeAgain: onPracticeAgain,
      ),
    );
  }

  @override
  State<CompletionModal> createState() => _CompletionModalState();
}

class _CompletionModalState extends State<CompletionModal> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti Layer
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.teal,
              AppColors.warmGold,
              Colors.white,
            ],
            gravity: 0.3,
          ),
        ),

        // Modal Content
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Dark card background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.teal.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.2),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Checkmark
                _buildCheckmark()
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5)),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Verse ${widget.verseNumber} Completed!',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'MashAllah, you are making great progress.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // Primary Action: Continue
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warmGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue to Next Verse',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Secondary Action: Practice Again
                TextButton(
                  onPressed: widget.onPracticeAgain,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.6),
                  ),
                  child: const Text(
                    'Practice Again',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckmark() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.teal,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 48,
        weight: 800, // Extra bold icon
      ),
    );
  }
}

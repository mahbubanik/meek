import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/tajweed_feedback.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

/// Feedback Card with emotional header and detailed analysis
class FeedbackCard extends StatelessWidget {
  final TajweedFeedback feedback;
  final VoidCallback onRetry;
  final VoidCallback onComplete;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onRetry,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final emotionalMessage = feedback.emotionalMessage;
    
    return Column(
      children: [
        // Emotional Header
        _buildEmotionalHeader(context, emotionalMessage)
          .animate()
          .fadeIn()
          .scale(begin: const Offset(0.95, 0.95)),
        
        const SizedBox(height: AppTheme.spacing16),
        
        // Score Card
        _buildScoreCard(context)
          .animate()
          .fadeIn(delay: 100.ms),
        
        const SizedBox(height: AppTheme.spacing16),
        
        // Positives
        if (feedback.positives.isNotEmpty)
          _buildPositives(context)
            .animate()
            .fadeIn(delay: 200.ms),
        
        const SizedBox(height: AppTheme.spacing12),
        
        // Improvements
        if (feedback.improvements.isNotEmpty)
          _buildImprovements(context)
            .animate()
            .fadeIn(delay: 300.ms),
        
        const SizedBox(height: AppTheme.spacing12),
        
        // Details
        if (feedback.details.isNotEmpty)
          _buildDetails(context)
            .animate()
            .fadeIn(delay: 400.ms),
        
        const SizedBox(height: AppTheme.spacing24),
        
        // Action Buttons
        _buildActionButtons(context)
          .animate()
          .fadeIn(delay: 500.ms)
          .slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildEmotionalHeader(BuildContext context, EmotionalMessage message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.05),
            context.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppTheme.borderRadiusXLarge,
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            message.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          Text(
            message.arabic,
            style: AppTypography.arabicFeedback(context.primaryColor),
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          Text(
            message.english,
            style: AppTypography.bodyMedium(context.foregroundColor.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.accentColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${feedback.score}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing4),
          
          Text(
            'Match Score',
            style: AppTypography.bodySmall(context.mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPositives(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'WHAT YOU DID WELL',
                style: AppTypography.uppercaseLabel(AppColors.success),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          ...feedback.positives.map((positive) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
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
      ),
    );
  }

  Widget _buildImprovements(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 16),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'TO IMPROVE',
                style: AppTypography.uppercaseLabel(AppColors.warning),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          ...feedback.improvements.map((improvement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
              child: Text(
                improvement,
                style: AppTypography.bodyMedium(context.foregroundColor),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: AppTheme.borderRadiusLarge,
      ),
      child: Text(
        '"${feedback.details}"',
        style: AppTypography.bodyMedium(context.mutedColor).copyWith(
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Retry
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            ),
          ),
        ),
        
        const SizedBox(width: AppTheme.spacing12),
        
        // Complete
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            ),
          ),
        ),
      ],
    );
  }
}

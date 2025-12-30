import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/fiqh_service.dart';
import '../../widgets/fiqh/collapsible_section.dart';

/// Structured Fiqh Answer View
/// Replicates src/components/fiqh/AnswerView.tsx
class FiqhAnswerView extends StatelessWidget {
  final String question;
  final FiqhResponse response;
  final String madhab;
  final VoidCallback onAskAgain;
  final ScrollController scrollController;

  const FiqhAnswerView({
    super.key,
    required this.question,
    required this.response,
    required this.madhab,
    required this.onAskAgain,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Question Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              question,
              style: AppTypography.headingSmall(context.foregroundColor).copyWith(
                height: 1.4,
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),

          const SizedBox(height: 32),

          // 2. Answer Section Header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ANSWER',
                style: AppTypography.uppercaseLabel(AppColors.teal),
              ),
              const Spacer(),
              _buildMadhabBadge(context),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // 3. Direct Answer Text
          MarkdownBody(
            data: response.directAnswer,
            styleSheet: MarkdownStyleSheet(
              p: AppTypography.bodyLarge(context.foregroundColor).copyWith(height: 1.6),
              strong: TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // 4. Detailed Reasoning (Collapsible)
          if (response.reasoning.isNotEmpty)
            CollapsibleSection(
              title: 'Why? See reasoning',
              icon: const Icon(Icons.info_outline),
              child: MarkdownBody(
                data: response.reasoning,
                styleSheet: MarkdownStyleSheet(
                   p: AppTypography.bodyMedium(context.foregroundColor),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

          // 5. Other Schools (Collapsible)
          if (response.otherSchools.isNotEmpty)
            CollapsibleSection(
              title: 'Other Schools of Thought',
              icon: const Icon(Icons.school_outlined),
              child: Column(
                children: response.otherSchools.map((pos) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pos.madhab}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(pos.position)),
                    ],
                  ),
                )).toList(),
              ),
            ).animate().fadeIn(delay: 400.ms),

            // 6. Citations (Collapsible)
            if (response.citations.isNotEmpty)
              CollapsibleSection(
                title: 'Sources & Citations',
                icon: const Icon(Icons.menu_book_outlined),
                child: Column(
                  children: response.citations.map((cite) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.mutedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote, size: 16, color: context.mutedColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          '${cite.source} ${cite.reference}',
                          style: AppTypography.labelSmall(context.mutedColor),
                        )),
                      ],
                    ),
                  )).toList(),
                ),
              ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 48),

          // 7. Feedback Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeedbackButton(context, Icons.thumb_up_alt_outlined),
              const SizedBox(width: 16),
              _buildFeedbackButton(context, Icons.thumb_down_alt_outlined),
            ],
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 32),
          
          // 8. Ask Another Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAskAgain,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: context.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Ask Another Question',
                style: AppTypography.labelLarge(context.foregroundColor),
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildMadhabBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Text(
        madhab,
        style: AppTypography.labelSmall(AppColors.teal),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context, IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.mutedColor, size: 20),
      ),
    );
  }
}

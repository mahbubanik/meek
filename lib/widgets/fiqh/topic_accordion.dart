import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

/// Reusable Accordion Widget for Fiqh Topics
/// Matches web app's `AnimatePresence` + `motion.div` expand effect
class TopicAccordion extends StatefulWidget {
  final String title;
  final String icon; // Emoji icon
  final List<String> questions;
  final Function(String) onQuestionTap;
  final bool isExpanded;
  final VoidCallback onToggle;

  const TopicAccordion({
    super.key,
    required this.title,
    required this.icon,
    required this.questions,
    required this.onQuestionTap,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<TopicAccordion> createState() => _TopicAccordionState();
}

class _TopicAccordionState extends State<TopicAccordion> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TopicAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded ? AppColors.teal.withValues(alpha: 0.3) : context.borderColor,
          width: widget.isExpanded ? 1.5 : 1,
        ),
        boxShadow: widget.isExpanded ? [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.isExpanded 
                          ? AppColors.teal.withValues(alpha: 0.1) 
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.headingSmall(context.foregroundColor).copyWith(
                        fontSize: 16,
                        fontWeight: widget.isExpanded ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.isExpanded ? AppColors.teal : context.mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Align(
                  heightFactor: _heightFactor.value,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.borderColor.withValues(alpha: 0.5))),
                  color: isDark ? Colors.black12 : Colors.grey[50],
                ),
                child: Column(
                  children: widget.questions.map((q) => _buildQuestionItem(context, q)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildQuestionItem(BuildContext context, String question) {
    return InkWell(
      onTap: () => widget.onQuestionTap(question),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: AppTypography.bodyMedium(context.foregroundColor).copyWith(
                  height: 1.4,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: context.mutedColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

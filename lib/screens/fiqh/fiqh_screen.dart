import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';

class FiqhScreen extends StatefulWidget {
  const FiqhScreen({super.key});

  @override
  State<FiqhScreen> createState() => _FiqhScreenState();
}

class _FiqhScreenState extends State<FiqhScreen> {
  final TextEditingController _questionController = TextEditingController();
  final AiService _aiService = AiService();
  final ScrollController _scrollController = ScrollController();
  
  List<QAEntry> _history = [];
  bool _isLoading = false;
  String _selectedMadhab = 'Hanafi';

  final List<String> _madhabs = ['Hanafi', 'Shafi\'i', 'Hanbali', 'Maliki'];

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
      _history.add(QAEntry(question: question, answer: null));
    });

    _questionController.clear();

    try {
      final answer = await _aiService.askFiqhQuestion(
        question,
        madhab: _selectedMadhab,
      );

      setState(() {
        _history.last.answer = answer;
        _isLoading = false;
      });

      // Scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() {
        _history.last.answer = 'I apologize, I could not process your question. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fiqh Q&A',
          style: AppTypography.headingSmall(context.foregroundColor),
        ),
        actions: [
          // Madhab selector
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedMadhab = value;
              });
            },
            itemBuilder: (context) => _madhabs.map((madhab) {
              return PopupMenuItem(
                value: madhab,
                child: Row(
                  children: [
                    if (madhab == _selectedMadhab)
                      Icon(Icons.check, color: context.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(madhab),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing8,
              ),
              child: Row(
                children: [
                  Icon(Icons.mosque_outlined, color: context.primaryColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _selectedMadhab,
                    style: AppTypography.labelMedium(context.primaryColor),
                  ),
                  Icon(Icons.arrow_drop_down, color: context.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome or History
          Expanded(
            child: _history.isEmpty
              ? _buildWelcome()
              : _buildHistory(),
          ),
          
          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤲', style: TextStyle(fontSize: 64))
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
            
            const SizedBox(height: AppTheme.spacing24),
            
            Text(
              'Ask Islamic Questions',
              style: AppTypography.headingMedium(context.foregroundColor),
            ).animate().fadeIn(delay: 100.ms),
            
            const SizedBox(height: AppTheme.spacing12),
            
            Text(
              'Get answers based on authentic sources\nfollowing the $_selectedMadhab madhab',
              style: AppTypography.bodyMedium(context.mutedColor),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: AppTheme.spacing32),
            
            // Example questions
            _buildExampleQuestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleQuestions() {
    final examples = [
      'How do I perform Wudu?',
      'What breaks the fast?',
      'Can I combine prayers while traveling?',
    ];

    return Column(
      children: [
        Text(
          'TRY ASKING',
          style: AppTypography.uppercaseLabel(context.mutedColor),
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        ...examples.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: GestureDetector(
              onTap: () {
                _questionController.text = question;
                _askQuestion();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppTheme.borderRadiusMedium,
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  question,
                  style: AppTypography.bodyMedium(context.foregroundColor),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 100))),
          );
        }),
      ],
    );
  }

  Widget _buildHistory() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return _buildQAEntry(entry, index);
      },
    );
  }

  Widget _buildQAEntry(QAEntry entry, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question bubble
        Container(
          margin: const EdgeInsets.only(
            left: AppTheme.spacing48,
            bottom: AppTheme.spacing12,
          ),
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusLarge),
              topRight: Radius.circular(AppTheme.radiusLarge),
              bottomLeft: Radius.circular(AppTheme.radiusLarge),
              bottomRight: Radius.circular(AppTheme.radiusSmall),
            ),
          ),
          child: Text(
            entry.question,
            style: AppTypography.bodyMedium(Colors.white),
          ),
        ).animate().fadeIn().slideX(begin: 0.1),
        
        // Answer bubble
        if (entry.answer != null)
          Container(
            margin: const EdgeInsets.only(
              right: AppTheme.spacing48,
              bottom: AppTheme.spacing24,
            ),
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
                bottomLeft: Radius.circular(AppTheme.radiusSmall),
                bottomRight: Radius.circular(AppTheme.radiusLarge),
              ),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.warmGold,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'Islamic Scholar',
                      style: AppTypography.labelSmall(AppColors.warmGold),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  entry.answer!,
                  style: AppTypography.bodyMedium(context.foregroundColor).copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1)
        else if (_isLoading && index == _history.length - 1)
          Container(
            margin: const EdgeInsets.only(
              right: AppTheme.spacing48,
              bottom: AppTheme.spacing24,
            ),
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppTheme.borderRadiusLarge,
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  'Consulting sources...',
                  style: AppTypography.bodySmall(context.mutedColor),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                enabled: !_isLoading,
                maxLines: null,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _askQuestion(),
                decoration: InputDecoration(
                  hintText: 'Ask an Islamic question...',
                  prefixIcon: Icon(Icons.chat_outlined, color: context.mutedColor),
                ),
              ),
            ),
            
            const SizedBox(width: AppTheme.spacing12),
            
            // Send Button
            GestureDetector(
              onTap: _isLoading ? null : _askQuestion,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QAEntry {
  final String question;
  String? answer;

  QAEntry({required this.question, this.answer});
}

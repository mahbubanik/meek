import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/fiqh_service.dart';
import '../../widgets/fiqh/topic_accordion.dart';
import '../../widgets/fiqh/answer_view.dart';

class FiqhScreen extends StatefulWidget {
  const FiqhScreen({super.key});

  @override
  State<FiqhScreen> createState() => _FiqhScreenState();
}

class _FiqhScreenState extends State<FiqhScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // State
  String? _expandedTopicId;
  String _selectedMadhab = 'Hanafi';
  bool _isLoading = false;
  FiqhResponse? _currentResponse;
  String? _currentQuestion;
  final FiqhService _fiqhService = FiqhService();
  
  final List<String> _madhabs = ['Hanafi', 'Shafi\'i', 'Hanbali', 'Maliki'];

  // ... (Data list remains same)
  final List<Map<String, dynamic>> _topics = [
    {
      'id': 'prayer',
      'title': 'Prayer (Salah)',
      'icon': '🕌',
      'questions': [
        'How do I perform Wudu?',
        'What nullifies my prayer?',
        'Can I combine prayers while traveling?',
        'How to pray Witr?',
      ]
    },
    {
      'id': 'fasting',
      'title': 'Fasting (Sawm)',
      'icon': '🌙',
      'questions': [
        'What breaks a fast?',
        'Can I brush my teeth while fasting?',
        'Rules for missed fasts',
      ]
    },
    {
      'id': 'zakat',
      'title': 'Charity (Zakat)',
      'icon': '💎',
      'questions': [
        'How do I calculate Zakat?',
        'Who is eligible to receive Zakat?',
      ]
    },
    {
      'id': 'marriage',
      'title': 'Marriage & Family',
      'icon': '👨‍👩‍👧',
      'questions': [
        'What are the requirements for Nikah?',
        'Rights of husband and wife',
      ]
    },
    {
      'id': 'work',
      'title': 'Work & Finance',
      'icon': '💼',
      'questions': [
        'Is investing in stocks Halal?',
        'Ruling on mortgages',
      ]
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTopicToggle(String id) {
    setState(() {
      if (_expandedTopicId == id) {
        _expandedTopicId = null;
      } else {
        _expandedTopicId = id;
      }
    });
  }

  Future<void> _handleAskQuestion(String question) async {
    if (question.isEmpty) return;
    
    FocusScope.of(context).unfocus();
    _searchController.clear();

    setState(() {
      _isLoading = true;
      _currentQuestion = question;
    });

    try {
      final response = await _fiqhService.askQuestion(
        question: question,
        madhab: _selectedMadhab,
      );

      setState(() {
        _currentResponse = response;
        _isLoading = false;
      });
      
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _resetToHome() {
    setState(() {
      _currentResponse = null;
      _currentQuestion = null;
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.deepNavy : AppColors.offWhite,
      body: Stack(
        children: [
          // Main Scrollable Content
          if (_isLoading)
            _buildLoadingState(context)
          else if (_currentResponse != null && _currentQuestion != null)
            FiqhAnswerView(
              question: _currentQuestion!,
              response: _currentResponse!,
              madhab: _selectedMadhab,
              onAskAgain: _resetToHome,
              scrollController: _scrollController,
            )
          else
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar Area (Sliver)
                SliverAppBar(
                  backgroundColor: context.surfaceColor,
                  expandedHeight: 0,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mosque_outlined, color: AppColors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Fiqh AI',
                        style: AppTypography.headingSmall(context.foregroundColor),
                      ),
                    ],
                  ),
                  actions: [
                    _buildMadhabSelector(context),
                    const SizedBox(width: 16),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Bottom padding for sticky bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Text(
                          _getGreeting(),
                          style: AppTypography.bodyLarge(context.mutedColor),
                        ).animate().fadeIn(),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          'What would you like to know?',
                          style: AppTypography.headingLarge(context.foregroundColor).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 32),

                        // Recent Questions (Chips)
                        _buildRecentQuestions(context),

                        const SizedBox(height: 32),

                        // Browse Topics Header
                        Text(
                          'BROWSE TOPICS',
                          style: AppTypography.uppercaseLabel(context.mutedColor),
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 16),

                        // Topic Accordions
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _topics.length,
                          itemBuilder: (context, index) {
                            final topic = _topics[index];
                            return TopicAccordion(
                              title: topic['title'],
                              icon: topic['icon'],
                              questions: topic['questions'],
                              isExpanded: _expandedTopicId == topic['id'],
                              onToggle: () => _handleTopicToggle(topic['id']),
                              onQuestionTap: _handleAskQuestion,
                            ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 50)));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Sticky Bottom Search Bar
          if (!_isLoading && _currentResponse == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickySearchBar(context),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(color: AppColors.teal),
          ).animate().scale(),
          const SizedBox(height: 24),
          Text(
            'Consulting Sources...',
            style: AppTypography.headingSmall(context.foregroundColor),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Analyzing Quran & Sunnah based on $_selectedMadhab view',
            style: AppTypography.bodyMedium(context.mutedColor),
          ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildMadhabSelector(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => _selectedMadhab = value),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => _madhabs.map((madhab) {
        return PopupMenuItem(
          value: madhab,
          child: Row(
            children: [
              if (madhab == _selectedMadhab)
                Icon(Icons.check, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text(madhab),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(
              _selectedMadhab,
              style: AppTypography.labelMedium(AppColors.teal),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, color: AppColors.teal, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentQuestions(BuildContext context) {
    // TODO: Fetch real recent questions
    final recents = [
      'Is my Wudu valid?',
      'Praying in a moving car',
      'Kaffarah for oath',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final q = recents[index];
          return InkWell(
            onTap: () => _handleAskQuestion(q),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: context.mutedColor),
                  const SizedBox(width: 8),
                  Text(
                    q,
                    style: AppTypography.bodySmall(context.foregroundColor),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 50))).slideX();
        },
      ),
    );
  }

  Widget _buildStickySearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.deepNavy : AppColors.offWhite).withValues(alpha: 0.8),
            border: Border(top: BorderSide(color: context.borderColor)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: context.mutedColor),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Ask anything about Fiqh...',
                      hintStyle: AppTypography.bodyMedium(context.mutedColor),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTypography.bodyMedium(context.foregroundColor),
                    onSubmitted: _handleAskQuestion,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

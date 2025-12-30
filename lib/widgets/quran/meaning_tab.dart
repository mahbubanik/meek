import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/quran_api_service.dart';

/// Meaning Tab - Exact clone from web app
/// Features: Arabic verse, English translation, Bangla translation, Word-by-word, Tafsir, Tips
class MeaningTab extends StatefulWidget {
  final Verse verse;
  final Surah surah;

  const MeaningTab({
    super.key,
    required this.verse,
    required this.surah,
  });

  @override
  State<MeaningTab> createState() => _MeaningTabState();
}

class _MeaningTabState extends State<MeaningTab> {
  final QuranApiService _quranService = QuranApiService();
  
  bool _loadingTranslations = false;
  bool _loadingWords = false;
  bool _showTafsir = false;
  bool _expandedTafsir = false;
  bool _showTips = false;
  
  String _englishTranslation = '';
  String _banglaTranslation = '';
  String _tafsirText = '';
  String _tafsirSource = 'Ibn Kathir';
  List<Map<String, dynamic>> _wordMeanings = [];

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadWordMeanings();
    _loadTafsir();
  }

  @override
  void didUpdateWidget(MeaningTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verse.verseKey != widget.verse.verseKey) {
      _loadTranslations();
      _loadWordMeanings();
      _loadTafsir();
    }
  }

  Future<void> _loadTranslations() async {
    setState(() => _loadingTranslations = true);
    try {
      final translations = await _quranService.getVerseTranslations(
        widget.surah.id,
        widget.verse.verseNumber,
      );
      if (mounted) {
        setState(() {
          _englishTranslation = translations['english'] ?? '';
          _banglaTranslation = translations['bangla'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading translations: $e');
    } finally {
      if (mounted) setState(() => _loadingTranslations = false);
    }
  }

  Future<void> _loadWordMeanings() async {
    setState(() => _loadingWords = true);
    try {
      final words = await _quranService.getWordByWord(
        widget.surah.id,
        widget.verse.verseNumber,
      );
      if (mounted) setState(() => _wordMeanings = words);
    } catch (e) {
      debugPrint('Error loading words: $e');
    } finally {
      if (mounted) setState(() => _loadingWords = false);
    }
  }

  Future<void> _loadTafsir() async {
    try {
      final tafsir = await _quranService.getTafsir(
        widget.surah.id,
        widget.verse.verseNumber,
      );
      if (mounted) {
        setState(() {
          _tafsirText = tafsir['text'] ?? _getDefaultTafsir();
          _tafsirSource = tafsir['source'] ?? 'MEEK Commentary';
        });
      }
    } catch (e) {
      debugPrint('Error loading tafsir: $e');
      setState(() => _tafsirText = _getDefaultTafsir());
    }
  }

  String _getDefaultTafsir() {
    if (widget.surah.id == 1) {
      final tafsirs = {
        1: "The Basmalah (In the name of Allah, the Most Gracious, the Most Merciful) is the opening of the Quran. It teaches us to begin every good action by invoking Allah's name.",
        2: "All praise belongs to Allah, the Lord of all the worlds. This encompasses everything that exists.",
        3: "Ar-Rahman (The Most Gracious) describes Allah's mercy that encompasses all creation.",
        4: "Allah is the Owner and Master of the Day of Recompense.",
        5: "We declare that we worship none but Him and seek help from none but Him.",
        6: "We ask Allah to guide us to the Straight Path.",
        7: "The path of those whom Allah has blessed.",
      };
      return tafsirs[widget.verse.verseNumber] ?? 'Reflect on this verse and its deeper meaning.';
    }
    return 'This verse contains profound wisdom. Take time to reflect on its meaning.';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          // English Translation Card
          _buildTranslationCard(
            context: context,
            title: 'English Translation',
            text: _englishTranslation.isNotEmpty 
                ? _englishTranslation 
                : widget.verse.englishTranslation,
            icon: Icons.language,
            iconColor: context.primaryColor,
            bgColor: context.primaryColor.withValues(alpha: 0.05),
            borderColor: context.primaryColor.withValues(alpha: 0.2),
            isLoading: _loadingTranslations,
          ).animate().fadeIn().slideY(begin: 0.05),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Bangla Translation Card
          _buildTranslationCard(
            context: context,
            title: 'বাংলা অনুবাদ',
            text: _banglaTranslation.isNotEmpty 
                ? _banglaTranslation 
                : widget.verse.banglaTranslation,
            icon: Icons.public,
            iconColor: AppColors.warmGold,
            bgColor: AppColors.warmGold.withValues(alpha: 0.05),
            borderColor: AppColors.warmGold.withValues(alpha: 0.2),
            isLoading: _loadingTranslations,
          ).animate().fadeIn(delay: 50.ms),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Word by Word Section
          _buildWordByWordSection(context)
            .animate()
            .fadeIn(delay: 100.ms),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Understanding/Tafsir Expandable
          _buildTafsirSection(context)
            .animate()
            .fadeIn(delay: 150.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Memorization Tips Expandable
          _buildTipsSection(context)
            .animate()
            .fadeIn(delay: 200.ms),
          
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildTranslationCard({
    required BuildContext context,
    required String title,
    required String text,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.uppercaseLabel(context.mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.mutedColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading translation...',
                  style: AppTypography.bodyMedium(context.mutedColor),
                ),
              ],
            )
          else
            Text(
              text.isNotEmpty ? text : 'Translation loading...',
              style: AppTypography.bodyLarge(context.foregroundColor).copyWith(
                height: 1.8,
                fontSize: 17,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordByWordSection(BuildContext context) {
    final words = _wordMeanings.where((w) {
      final text = w['text_uthmani']?.toString() ?? '';
      return text.isNotEmpty && !text.contains('۞');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, size: 16, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'WORD BY WORD',
              style: AppTypography.uppercaseLabel(context.mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _loadingWords
            ? _buildLoadingGrid(context)
            : _buildWordGrid(context, words),
      ],
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
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
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 50, height: 20, color: context.mutedColor.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Container(width: 30, height: 12, color: context.mutedColor.withValues(alpha: 0.2)),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms);
      },
    );
  }

  Widget _buildWordGrid(BuildContext context, List<Map<String, dynamic>> words) {
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
        final textUthmani = word['text_uthmani']?.toString() ?? '';
        final transliteration = word['transliteration']?['text']?.toString() ?? '';
        final translation = word['translation']?['text']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Stack(
            children: [
              // Numbered badge
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: context.mutedColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: context.mutedColor,
                      ),
                    ),
                  ),
                ),
              ),
              
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      textUthmani,
                      style: AppTypography.arabicMedium(context.primaryColor).copyWith(fontSize: 24),
                      textDirection: TextDirection.rtl,
                    ),
                    if (transliteration.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        transliteration,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                    if (translation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        translation,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.foregroundColor.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ).animate()
          .fadeIn(delay: Duration(milliseconds: idx * 30))
          .slideY(begin: 0.1);
      },
    );
  }

  Widget _buildTafsirSection(BuildContext context) {
    return Column(
      children: [
        // Header Button
        GestureDetector(
          onTap: () => setState(() => _showTafsir = !_showTafsir),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: context.primaryColor.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  'UNDERSTANDING',
                  style: AppTypography.uppercaseLabel(context.mutedColor),
                ),
                const Spacer(),
                Text(
                  'Tafsir',
                  style: TextStyle(fontSize: 10, color: context.mutedColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
                Icon(
                  _showTafsir ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: context.mutedColor,
                ),
              ],
            ),
          ),
        ),
        
        // Expandable Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildTafsirContent(context),
          crossFadeState: _showTafsir ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildTafsirContent(BuildContext context) {
    final displayText = _tafsirText.isNotEmpty ? _tafsirText : _getDefaultTafsir();
    final shouldTruncate = displayText.length > 200 && !_expandedTafsir;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Text(
                shouldTruncate ? '${displayText.substring(0, 200)}...' : displayText,
                style: AppTypography.bodyMedium(context.foregroundColor.withValues(alpha: 0.8)).copyWith(
                  height: 1.9,
                ),
              ),
              if (shouldTruncate)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.surfaceColor.withValues(alpha: 0),
                          context.surfaceColor,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          if (displayText.length > 200)
            TextButton(
              onPressed: () => setState(() => _expandedTafsir = !_expandedTafsir),
              child: Text(_expandedTafsir ? '← Show less' : 'Continue reading →'),
            ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  'SOURCE:',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: context.mutedColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _tafsirSource,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Column(
      children: [
        // Header Button
        GestureDetector(
          onTap: () => setState(() => _showTips = !_showTips),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 16, color: AppColors.warmGold),
                const SizedBox(width: 8),
                Text(
                  'MEMORIZATION TIPS',
                  style: AppTypography.uppercaseLabel(context.mutedColor),
                ),
                const Spacer(),
                Icon(
                  _showTips ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: context.mutedColor,
                ),
              ],
            ),
          ),
        ),
        
        // Expandable Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildTipsContent(context),
          crossFadeState: _showTips ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildTipsContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warmGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTip('📝 Connect Words to Meanings',
              'When you understand what you recite, memorization becomes easier. Focus on the word-by-word breakdown above.'),
          const SizedBox(height: 16),
          _buildTip('🔄 Repeat with Purpose',
              'Recite this verse 10 times while looking, then 10 times from memory. This strengthens retention.'),
          const SizedBox(height: 16),
          _buildTip('🌙 Best Times to Memorize',
              'After Fajr and before bed are optimal times when the mind is most receptive to new information.'),
        ],
      ),
    );
  }

  Widget _buildTip(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.warmGold.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: context.foregroundColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

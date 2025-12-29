import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/surah.dart';
import '../../models/verse.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

/// Meaning Tab - Translations and Tafsir
class MeaningTab extends StatelessWidget {
  final Verse verse;
  final Surah surah;

  const MeaningTab({
    super.key,
    required this.verse,
    required this.surah,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arabic Verse
          _buildArabicSection(context)
            .animate()
            .fadeIn()
            .slideY(begin: 0.05),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // English Translation
          _buildTranslationSection(
            context: context,
            title: 'ENGLISH TRANSLATION',
            text: verse.englishTranslation.isNotEmpty 
              ? verse.englishTranslation
              : 'In the name of Allah, the Most Gracious, the Most Merciful.',
            icon: '🇬🇧',
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Bangla Translation
          _buildTranslationSection(
            context: context,
            title: 'BANGLA TRANSLATION',
            text: verse.banglaTranslation.isNotEmpty 
              ? verse.banglaTranslation
              : 'পরম করুণাময় অতি দয়ালু আল্লাহর নামে।',
            icon: '🇧🇩',
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Tafsir
          _buildTafsirSection(context)
            .animate()
            .fadeIn(delay: 300.ms),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Word Meanings
          if (verse.words.isNotEmpty)
            _buildWordMeanings(context)
              .animate()
              .fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildArabicSection(BuildContext context) {
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
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(
            verse.textUthmani,
            style: AppTypography.arabicLarge(context.arabicTextColor),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          Text(
            '${surah.nameSimple} - Verse ${verse.verseNumber}',
            style: AppTypography.labelSmall(context.mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSection({
    required BuildContext context,
    required String title,
    required String text,
    required String icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                title,
                style: AppTypography.uppercaseLabel(context.mutedColor),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          Text(
            text,
            style: AppTypography.bodyLarge(context.foregroundColor).copyWith(
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTafsirSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: context.primaryColor,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'TAFSIR',
                style: AppTypography.uppercaseLabel(context.mutedColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusFull,
                ),
                child: Text(
                  'Ibn Kathir',
                  style: AppTypography.labelSmall(context.primaryColor),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          Text(
            _generateTafsirContent(),
            style: AppTypography.bodyMedium(context.foregroundColor).copyWith(
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          TextButton(
            onPressed: () {},
            child: Text('Read more →'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordMeanings(BuildContext context) {
    final words = verse.words.where((w) => w.isWord && w.translation != null).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORD MEANINGS',
          style: AppTypography.uppercaseLabel(context.mutedColor),
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppTheme.borderRadiusLarge,
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: words.map((word) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        word.textUthmani,
                        style: AppTypography.arabicSmall(context.arabicTextColor),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        word.translation ?? '',
                        style: AppTypography.bodyMedium(context.foregroundColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _generateTafsirContent() {
    if (verse.surahNumber == 1 && verse.verseNumber == 1) {
      return 'The Basmalah (بسم الله الرحمن الرحيم) is the phrase recited before '
          'beginning any good action. It means "In the name of Allah, the Most '
          'Gracious, the Most Merciful." Muslims begin every significant act with '
          'this invocation to seek Allah\'s blessings and remind themselves that '
          'all actions should be done for His sake.';
    }
    return 'Tafsir for this verse provides deeper understanding of its meaning, '
        'context of revelation, and scholarly interpretations. This helps in '
        'understanding the wisdom and guidance contained in Allah\'s words.';
  }
}

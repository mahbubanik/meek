import 'package:flutter/material.dart';
import '../../models/surah.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/quran_api_service.dart';

/// Surah Selector Bottom Sheet Modal
class SurahSelector extends StatefulWidget {
  final Function(Surah) onSelect;

  const SurahSelector({super.key, required this.onSelect});

  @override
  State<SurahSelector> createState() => _SurahSelectorState();
}

class _SurahSelectorState extends State<SurahSelector> {
  final TextEditingController _searchController = TextEditingController();
  final QuranApiService _quranService = QuranApiService();
  
  List<Surah> _surahs = [];
  List<Surah> _filteredSurahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await _quranService.getAllSurahs();
      setState(() {
        _surahs = surahs;
        _filteredSurahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      // Use offline list
      setState(() {
        _surahs = allSurahs;
        _filteredSurahs = allSurahs;
        _isLoading = false;
      });
    }
  }

  void _filterSurahs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSurahs = _surahs;
      });
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      _filteredSurahs = _surahs.where((s) {
        return s.nameSimple.toLowerCase().contains(lower) ||
               s.nameArabic.contains(query) ||
               s.translatedName.toLowerCase().contains(lower) ||
               s.id.toString() == query;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Row(
              children: [
                Text(
                  'Select Surah',
                  style: AppTypography.headingMedium(context.foregroundColor),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.mutedColor),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSurahs,
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                prefixIcon: Icon(Icons.search, color: context.mutedColor),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterSurahs('');
                      },
                      icon: Icon(Icons.clear, color: context.mutedColor),
                    )
                  : null,
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator(color: context.primaryColor))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                  itemCount: _filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = _filteredSurahs[index];
                    return _buildSurahTile(surah);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahTile(Surah surah) {
    return InkWell(
      onTap: () => widget.onSelect(surah),
      borderRadius: AppTheme.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacing12,
          horizontal: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.borderColor.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            // Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Center(
                child: Text(
                  surah.id.toString(),
                  style: AppTypography.labelMedium(context.primaryColor),
                ),
              ),
            ),

            const SizedBox(width: AppTheme.spacing12),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameSimple,
                    style: AppTypography.bodyMedium(context.foregroundColor),
                  ),
                  Text(
                    '${surah.translatedName} • ${surah.versesCount} verses',
                    style: AppTypography.bodySmall(context.mutedColor),
                  ),
                ],
              ),
            ),

            // Arabic name
            Text(
              surah.nameArabic,
              style: AppTypography.arabicSmall(context.arabicTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

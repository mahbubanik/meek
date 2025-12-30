import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/surah.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../../services/quran_api_service.dart';

/// Surah Selector Bottom Sheet Modal
/// Features: Sync with 'Currently Reading', Next Up cards, and Searchable List
class SurahSelector extends StatefulWidget {
  final Function(Surah) onSelect;
  final int? initialSurahId;

  const SurahSelector({
    super.key, 
    required this.onSelect,
    this.initialSurahId,
  });

  @override
  State<SurahSelector> createState() => _SurahSelectorState();
}

class _SurahSelectorState extends State<SurahSelector> {
  final TextEditingController _searchController = TextEditingController();
  final QuranApiService _quranService = QuranApiService();
  final _supabase = Supabase.instance.client;
  
  List<Surah> _surahs = [];
  List<Surah> _filteredSurahs = [];
  bool _isLoading = true;
  
  // Sync State
  int? _currentReadingSurahId;
  Surah? _currentReadingSurah;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Load All Surahs
      final surahs = await _quranService.getAllSurahs();
      
      // 2. Load Progress (Sync)
      int progressId = widget.initialSurahId ?? 1;
      final user = _supabase.auth.currentUser;
      if (user != null && widget.initialSurahId == null) {
        final response = await _supabase
            .from('quran_progress')
            .select('last_surah')
            .eq('user_id', user.id)
            .maybeSingle();
        if (response != null) {
          progressId = response['last_surah'] ?? 1;
        }
      }

      final current = surahs.firstWhere((s) => s.id == progressId, orElse: () => surahs.first);

      if (mounted) {
        setState(() {
          _surahs = surahs;
          _filteredSurahs = surahs;
          _currentReadingSurahId = progressId;
          _currentReadingSurah = current;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Offline Fallback
      if (mounted) {
        setState(() {
          _surahs = allSurahs;
          _filteredSurahs = allSurahs;
          _currentReadingSurahId = widget.initialSurahId ?? 1;
          _currentReadingSurah = allSurahs.firstWhere((s) => s.id == _currentReadingSurahId, orElse: () => allSurahs.first);
          _isLoading = false;
        });
      }
    }
  }

  void _filterSurahs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSurahs = _surahs);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : AppColors.offWhite;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: backgroundColor,
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

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSurahs,
              style: TextStyle(color: context.foregroundColor),
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                hintStyle: TextStyle(color: context.mutedColor),
                prefixIcon: Icon(Icons.search, color: context.mutedColor),
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: AppColors.teal))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                  children: [
                    // Section 1: Currently Reading
                    if (_searchController.text.isEmpty && _currentReadingSurah != null) ...[
                      Text(
                        'CURRENTLY READING',
                        style: AppTypography.uppercaseLabel(context.mutedColor),
                      ),
                      const SizedBox(height: 12),
                      _buildCurrentSurahCard(isDark),
                      const SizedBox(height: 24),
                      
                      // Section 2: Next Ups (Horizontal List) // Removed as per screenshot focus on single big card
                      // Actually screenshot shows 'Next Up' style small cards below... let's check
                      // Ah, the screenshot has "Currently Reading" (big) then "All 114" (list)
                      // But effectively the list allows browsing. 
                      // I will implement the big card then the list.
                    ],

                    Text(
                      'ALL 114 SURAHS',
                      style: AppTypography.uppercaseLabel(context.mutedColor),
                    ),
                    const SizedBox(height: 12),
                    
                    ..._filteredSurahs.map((surah) => _buildSurahTile(surah, isDark)).toList(),
                    
                    const SizedBox(height: 48), // Padding for bottom
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSurahCard(bool isDark) {
    final surah = _currentReadingSurah!;
    return GestureDetector(
      onTap: () => widget.onSelect(surah),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withOpacity(0.3), width: 1),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Number Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  surah.id.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameSimple,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${surah.versesCount} verses • ${surah.revelationPlace}',
                    style: TextStyle(
                      color: context.mutedColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arabic Name
            Text(
              surah.nameArabic,
              style: TextStyle(
                fontFamily: 'Amiri', // Assuming font exists, typical for Quran apps
                fontSize: 24,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(duration: 400.ms);
  }

  Widget _buildSurahTile(Surah surah, bool isDark) {
    final isCurrent = surah.id == _currentReadingSurahId;
    final bgColor = isDark 
        ? const Color(0xFF1E293B) 
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => widget.onSelect(surah),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Number
                Text(
                  '${surah.id}.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.mutedColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            surah.nameSimple,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            surah.nameArabic,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.teal.withOpacity(0.8),
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${surah.revelationPlace} • ${surah.versesCount} verses',
                        style: TextStyle(
                          color: context.mutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Badge or Arrow
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.teal.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: context.mutedColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

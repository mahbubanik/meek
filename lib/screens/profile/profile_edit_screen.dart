import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  final String currentName;
  final String currentMadhab;

  const ProfileEditScreen({
    super.key,
    required this.currentName,
    required this.currentMadhab,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late String _selectedMadhab;
  bool _isLoading = false;

  final List<String> _madhabs = ['Hanafi', 'Shafi\'i', 'Maliki', 'Hanbali'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _selectedMadhab = _madhabs.firstWhere(
      (m) => m.toLowerCase() == widget.currentMadhab.toLowerCase(),
      orElse: () => 'Hanafi',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        name: _nameController.text.trim(),
        madhab: _selectedMadhab.toLowerCase(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveChanges,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)
                )
              : const Icon(Icons.check, color: AppColors.teal),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Placeholder
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: context.primaryColor,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surfaceColor, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ).animate().scale(),

            const SizedBox(height: 32),

            // Form Fields
            Text('FULL NAME', style: AppTypography.uppercaseLabel(context.mutedColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text('MADHAB (SCHOOL OF THOUGHT)', style: AppTypography.uppercaseLabel(context.mutedColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMadhab,
                  isExpanded: true,
                  items: _madhabs.map((String madhab) {
                    return DropdownMenuItem<String>(
                      value: madhab,
                      child: Text(madhab),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedMadhab = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This setting personalizes your Fiqh answers.',
              style: AppTypography.bodySmall(context.mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

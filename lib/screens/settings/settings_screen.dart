import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() {
            _profileData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    // Use local profile data or fallback to auth user info
    final displayName = _profileData?['name'] ?? 'User';
    final displayMadhab = _profileData?['madhab'] ?? 'Hanafi';
    final notificationsEnabled = _profileData?['notifications_enabled'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.headingSmall(
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          // Profile Section
          _buildSection(
            context: context,
            title: 'Profile',
            children: [
              _buildListTile(
                context: context,
                icon: Icons.person_outline,
                title: displayName,
                subtitle: authProvider.user?.email ?? 'Not signed in',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEditScreen(
                        currentName: displayName,
                        currentMadhab: displayMadhab,
                      ),
                    ),
                  );
                  _loadProfile(); // Refresh after edit
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Preferences Section
          _buildSection(
            context: context,
            title: 'Preferences',
            children: [
              _buildSwitchTile(
                context: context,
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.mosque_outlined,
                title: 'Madhab',
                subtitle: displayMadhab.toString().toUpperCase(),
                onTap: () async {
                   // Quick edit just for Madhab
                   await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEditScreen(
                        currentName: displayName,
                        currentMadhab: displayMadhab,
                      ),
                    ),
                  );
                  _loadProfile();
                },
              ),
              _buildSwitchTile(
                context: context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                value: notificationsEnabled,
                onChanged: (value) async {
                  // Optimistic update
                  setState(() {
                    _profileData?['notifications_enabled'] = value;
                  });
                  try {
                    await authProvider.updateProfile(notificationsEnabled: value);
                  } catch (e) {
                     _loadProfile(); // Revert on error
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Account Section
          _buildSection(
            context: context,
            title: 'Account',
            children: [
              _buildListTile(
                context: context,
                icon: Icons.logout_outlined,
                title: 'Sign Out',
                titleColor: AppColors.error,
                onTap: () async {
                  await authProvider.signOut();
                  // Auth wrapper will handle redirection
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacing4,
            bottom: AppTheme.spacing8,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.uppercaseLabel(context.mutedColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppTheme.borderRadiusLarge,
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.mutedColor),
      title: Text(
        title,
        style: AppTypography.bodyMedium(titleColor ?? context.foregroundColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.bodySmall(context.mutedColor),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: context.mutedColor,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.mutedColor),
      title: Text(
        title,
        style: AppTypography.bodyMedium(context.foregroundColor),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: context.primaryColor,
      ),
    );
  }
}

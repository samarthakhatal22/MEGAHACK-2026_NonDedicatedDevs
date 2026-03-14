import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../one/providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _emailAlerts = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: 8),
                    _buildActivityStats(context),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context,
                      title: 'Account',
                      children: [
                        _buildInfoTile(context,
                            icon: Icons.person_outline,
                            label: 'Full name',
                            value: 'Arjun Patel'),
                        _buildInfoTile(context,
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: 'arjun.patel@meity.gov.in'),
                        _buildInfoTile(context,
                            icon: Icons.business_outlined,
                            label: 'Ministry',
                            value: 'MeitY'),
                        _buildInfoTile(context,
                            icon: Icons.badge_outlined,
                            label: 'Role',
                            value: 'Policy Analyst',
                            isLast: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      context,
                      title: 'Preferences',
                      children: [
                        _buildToggleTile(
                          context,
                          icon: Icons.notifications_outlined,
                          label: 'Push notifications',
                          value: _notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _notificationsEnabled = val),
                        ),
                        _buildToggleTile(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email alerts',
                          value: _emailAlerts,
                          onChanged: (val) =>
                              setState(() => _emailAlerts = val),
                        ),
                        _buildToggleTile(
                          context,
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark mode',
                          value: themeProvider.isDark,
                          onChanged: (val) {
                            themeProvider.toggleTheme(val);
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      context,
                      title: 'App',
                      children: [
                        _buildNavTile(context,
                            icon: Icons.help_outline,
                            label: 'Help & support',
                            onTap: () {}),
                        _buildNavTile(context,
                            icon: Icons.info_outline,
                            label: 'About CivicShield',
                            onTap: () {}),
                        _buildNavTile(context,
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy policy',
                            onTap: () {},
                            isLast: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context),
                    const SizedBox(height: 12),
                    Text(
                      'CivicShield v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  // ── Profile Header ───────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  'AP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(Icons.camera_alt,
                      size: 12, color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Arjun Patel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Policy Analyst · MeitY',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active account',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity Stats ───────────────────────────────────────────────────────────

  Widget _buildActivityStats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _buildStatItem(context, '128', 'Searches'),
            _buildStatDivider(context),
            _buildStatItem(context, '34', 'Chats'),
            _buildStatDivider(context),
            _buildStatItem(context, '19', 'Saved'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 0.5,
      height: 36,
      color: colorScheme.outlineVariant,
    );
  }

  // ── Section Card ─────────────────────────────────────────────────────────────

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colorScheme.outlineVariant, width: 0.5),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Info Tile ────────────────────────────────────────────────────────────────

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle Tile ──────────────────────────────────────────────────────────────

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ── Nav Tile ─────────────────────────────────────────────────────────────────

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16))
          : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: colorScheme.outlineVariant, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                size: 18, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // ── Logout Button ────────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: Icon(Icons.logout, size: 18, color: colorScheme.error),
          label: Text(
            'Log out',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: colorScheme.errorContainer, width: 0.8),
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout Dialog ────────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontWeight: FontWeight.w500)),
        content: const Text(
            'You will need to sign in again to access CivicShield.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
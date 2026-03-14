import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
 
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
 
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
 
class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _emailAlerts = true;
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
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
                          value: _darkModeEnabled,
                          onChanged: (val) =>
                              setState(() => _darkModeEnabled = val),
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
                            label: 'About PolicyLens',
                            onTap: () {}),
                        _buildNavTile(context,
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy policy',
                            onTap: () {},
                            isLast: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFactCheckHistory(context),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context),
                    const SizedBox(height: 12),
                    Text(
                      'PolicyLens v1.0.0',
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
                    border: Border.all(
                        color: colorScheme.surface, width: 2),
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
              color: const Color(0xFFD7EDCA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active account',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A5E20),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout, size: 18, color: Color(0xFF8C1D18)),
          label: const Text(
            'Log out',
            style: TextStyle(
              color: Color(0xFF8C1D18),
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFFF09595), width: 0.8),
            backgroundColor: const Color(0xFFFCEBEB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
 
  // ── Fact Check History ──────────────────────────────────────────────────────
  
  Widget _buildFactCheckHistory(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return _buildSectionCard(
      context,
      title: 'Fact Check History',
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('fact_checks')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading history: ${snapshot.error}', 
                  style: const TextStyle(fontSize: 12)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No fact checks yet', 
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length > 5 ? 5 : docs.length, // Show last 5
              separatorBuilder: (context, index) => Divider(
                height: 1, 
                color: colorScheme.outlineVariant,
                indent: 14,
                endIndent: 14,
              ),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final result = data['result'] as Map<String, dynamic>?;
                final status = result?['status'] ?? 'Pending';
                final query = data['queryText'] ?? 'Unknown query';
                final imageUrl = data['imageUrl'] as String?;
                final timestamp = data['timestamp'] as Timestamp?;
                
                String timeStr = 'Recent';
                if (timestamp != null) {
                  timeStr = DateFormat('MMM d, h:mm a').format(timestamp.toDate());
                }

                Color statusColor;
                switch (status.toLowerCase()) {
                  case 'true': statusColor = Colors.green; break;
                  case 'false': statusColor = Colors.red; break;
                  default: statusColor = Colors.orange;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Text(
                        query,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      subtitle: Text(timeStr, style: const TextStyle(fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        if (true) // Could be a 'See all' button
          _buildNavTile(
            context,
            icon: Icons.history,
            label: 'View full history',
            isLast: true,
            onTap: () {
              // Navigate to a dedicated history page if needed
            },
          ),
      ],
    );
  }

  // ── Logout Dialog ────────────────────────────────────────────────────────────
 
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontWeight: FontWeight.w500)),
        content: const Text(
            'You will need to sign in again to access PolicyLens.'),
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
              backgroundColor: const Color(0xFF8C1D18),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
 
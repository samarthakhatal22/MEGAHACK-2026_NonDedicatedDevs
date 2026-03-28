import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/glass_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (streamContext, userSnapshot) {
          final userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final fullName = userData['fullName'] ?? user.displayName ?? 'New User';
          final email = userData['email'] ?? user.email ?? '';
          final ministry = userData['ministry'] ?? 'Not specified';
          final role = userData['role'] ?? 'User';

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [const Color(0xFFF8F9FA), const Color(0xFFFFFFFF)],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(context, colorScheme),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildProfileHeader(
                                  context, fullName, ministry, role, colorScheme),
                              const SizedBox(height: 32),
                              _buildActivityStats(context, user.uid, colorScheme),
                              const SizedBox(height: 32),
                              _buildSectionCard(
                                context,
                                colorScheme,
                                title: 'Account Information',
                                children: [
                                  _buildInfoTile(context, colorScheme,
                                      icon: Icons.person_outline,
                                      label: 'Full Name',
                                      value: fullName),
                                  _buildInfoTile(context, colorScheme,
                                      icon: Icons.email_outlined,
                                      label: 'Email',
                                      value: email),
                                  _buildInfoTile(context, colorScheme,
                                      icon: Icons.business_outlined,
                                      label: 'Ministry',
                                      value: ministry),
                                  _buildInfoTile(context, colorScheme,
                                      icon: Icons.badge_outlined,
                                      label: 'Role',
                                      value: role,
                                      isLast: true),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildSectionCard(
                                context,
                                colorScheme,
                                title: 'System Preferences',
                                children: [
                                  _buildToggleTile(
                                    context,
                                    colorScheme,
                                    icon: Icons.notifications_none,
                                    label: 'Push Notifications',
                                    value: _notificationsEnabled,
                                    onChanged: (val) =>
                                        setState(() => _notificationsEnabled = val),
                                    isLast: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildLogoutButton(context, colorScheme),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildTopBar(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Text(
            'Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit_note, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String ministry,
      String role, ColorScheme colorScheme) {
    final initials = name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase())
        .take(2)
        .join('');

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 46,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 20),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          '$role · $ministry',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStats(
      BuildContext context, String uid, ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fact_checks')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (statsContext, snapshot) {
          final factCheckCount = snapshot.data?.docs.length ?? 0;

          return GlassContainer(
            opacity: 0.05,
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  _buildStatItem(colorScheme, '0', 'Searches'),
                  _buildStatDivider(colorScheme),
                  _buildStatItem(colorScheme, factCheckCount.toString(), 'Reports'),
                  _buildStatDivider(colorScheme),
                  _buildStatItem(colorScheme, 'Active', 'Status'),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildStatItem(ColorScheme colorScheme, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 30,
      color: colorScheme.onSurface.withOpacity(0.05),
    );
  }

  Widget _buildSectionCard(BuildContext context, ColorScheme colorScheme,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        GlassContainer(
          opacity: 0.03,
          borderRadius: 24,
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInfoTile(BuildContext context, ColorScheme colorScheme,
      {required IconData icon,
      required String label,
      required String value,
      bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.05), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(BuildContext context, ColorScheme colorScheme,
      {required IconData icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged,
      bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.05), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout),
        label: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8C1D18).withOpacity(0.1),
          foregroundColor: const Color(0xFFF09595),
          side: const BorderSide(color: Color(0xFF8C1D18), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to end your session?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFF8C1D18)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
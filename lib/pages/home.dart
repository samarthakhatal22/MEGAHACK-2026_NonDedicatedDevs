import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'profile.dart';
import 'scams_page.dart';
import 'fact_check_chat.dart';
import 'search_page.dart';
import 'ScamAlert.dart';
import '../services/fact_check_service.dart';

class PolicyLensApp extends StatelessWidget {
  const PolicyLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolicyLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        fontFamily: 'GoogleSans',
      ),
      home: const HomePage(),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum PolicyStatus { active, draft, conflict, review }

class PolicyModel {
  final String title;
  final String ministry;
  final String date;
  final PolicyStatus status;

  const PolicyModel({
    required this.title,
    required this.ministry,
    required this.date,
    required this.status,
  });
}

class MetricModel {
  final String value;
  final String label;
  final IconData icons;
  final Color? backgroundColor;
  final Color? valueColor;
  final Color? labelColor;
  final Color? iconColor;

  const MetricModel({
    required this.value,
    required this.label,
    required this.icons,
    this.backgroundColor,
    this.valueColor,
    this.labelColor,
    this.iconColor,
  });
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color chipBg;
  final Color chipText;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.chipBg,
    required this.chipText,
  });
}

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;

  final _factCheckService = FactCheckService(
    apiKey: dotenv.env['GROQ_API_KEY'] ?? '',
  );

  final List<MetricModel> _metrics = const [
    MetricModel(
      value: '1,284',
      label: 'Total policies',
      icons: Icons.policy_outlined,
      backgroundColor: Color(0xFFE8DEF8),
      valueColor: Color(0xFF21005D),
      labelColor: Color(0xFF4F378B),
      iconColor: Color(0xFF6750A4),
    ),
    MetricModel(
      value: '47',
      label: 'Updated',
      icons: Icons.update_outlined,
      backgroundColor: Color(0xFFD3E4FD),
      valueColor: Color(0xFF0D47A1),
      labelColor: Color(0xFF185FA5),
      iconColor: Color(0xFF185FA5),
    ),
    MetricModel(
      value: '12',
      label: 'Pending',
      icons: Icons.pending_outlined,
      backgroundColor: Color(0xFFFFF0C5),
      valueColor: Color(0xFF7A4F00),
      labelColor: Color(0xFF854F0B),
      iconColor: Color(0xFFBA7517),
    ),
    MetricModel(
      value: '3',
      label: 'Conflicts',
      icons: Icons.warning_amber_outlined,
      backgroundColor: Color(0xFFFCDAD7),
      valueColor: Color(0xFF8C1D18),
      labelColor: Color(0xFF8C1D18),
      iconColor: Color(0xFFE24B4A),
    ),
  ];

  final List<PolicyModel> _recentPolicies = const [
    PolicyModel(
      title: 'Digital India Act 2024',
      ministry: 'MeitY',
      date: 'Jan 2024',
      status: PolicyStatus.active,
    ),
    PolicyModel(
      title: 'NEP Amendment v3',
      ministry: 'MoE',
      date: 'Mar 2024',
      status: PolicyStatus.draft,
    ),
    PolicyModel(
      title: 'PDPB Regulations',
      ministry: 'MHA',
      date: 'Feb 2024',
      status: PolicyStatus.conflict,
    ),
    PolicyModel(
      title: 'Green Hydrogen Mission',
      ministry: 'MNRE',
      date: 'Apr 2024',
      status: PolicyStatus.review,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String initials = 'U';
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      initials = names.length >= 2
          ? '${names[0][0]}${names[1][0]}'.toUpperCase()
          : names[0][0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            // Index 0 — Home
            _buildHomeTab(context, user, initials),
            // Index 1 — Scams
            const ScamsPage(),
            // Index 2 — Fact Check
            FactCheckChatPage(service: _factCheckService),
            // Index 3 — Profile
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ─── Home tab ──────────────────────────────────────────────────────────────

  Widget _buildHomeTab(BuildContext context, User? user, String initials) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildTopAppBar(context, user, initials),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildSearchBar(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'Overview'),
                const SizedBox(height: 8),
                _buildMetricsGrid(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'Recent policies'),
                const SizedBox(height: 8),
                _buildPoliciesCard(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'Recent Scam Alerts'),
                const SizedBox(height: 8),
                _buildScamAlertsCard(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'AI activity'),
                const SizedBox(height: 8),
                _buildAIActivityCard(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top App Bar ───────────────────────────────────────────────────────────

  Widget _buildTopAppBar(BuildContext context, User? user, String initials) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            'Civic-Shield',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: user?.photoURL != null
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search policies, acts, amendments...',
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
            ),
            Icon(Icons.tune, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  // ─── Metrics Grid ──────────────────────────────────────────────────────────

  Widget _buildMetricsGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: _metrics.length,
      itemBuilder: (context, index) {
        final metric = _metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: metric.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(metric.icons, size: 20, color: metric.iconColor),
              const SizedBox(height: 4),
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: metric.valueColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: metric.labelColor ?? colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Policies Card ─────────────────────────────────────────────────────────

  Widget _buildPoliciesCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      color: colorScheme.surface,
      child: Column(
        children: _recentPolicies.asMap().entries.map((entry) {
          return _buildPolicyListItem(
            context,
            entry.value,
            entry.key == _recentPolicies.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPolicyListItem(BuildContext context, PolicyModel policy, bool isLast) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusConfig = _getStatusConfig(policy.status);

    return InkWell(
      onTap: () {},
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusConfig.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusConfig.icon, size: 18, color: statusConfig.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${policy.ministry} · ${policy.date}',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(policy.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PolicyStatus status) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: config.chipText),
      ),
    );
  }

  _StatusConfig _getStatusConfig(PolicyStatus status) {
    switch (status) {
      case PolicyStatus.active:
        return _StatusConfig(
          label: 'Active',
          icon: Icons.check_circle_outline,
          iconBg: const Color(0xFFD7EDCA),
          iconColor: const Color(0xFF1A5E20),
          chipBg: const Color(0xFFD7EDCA),
          chipText: const Color(0xFF1A5E20),
        );
      case PolicyStatus.draft:
        return _StatusConfig(
          label: 'Draft',
          icon: Icons.edit_outlined,
          iconBg: const Color(0xFFFFF0C5),
          iconColor: const Color(0xFF7A4F00),
          chipBg: const Color(0xFFFFF0C5),
          chipText: const Color(0xFF7A4F00),
        );
      case PolicyStatus.conflict:
        return _StatusConfig(
          label: 'Conflict',
          icon: Icons.warning_amber_outlined,
          iconBg: const Color(0xFFFCDAD7),
          iconColor: const Color(0xFF8C1D18),
          chipBg: const Color(0xFFFCDAD7),
          chipText: const Color(0xFF8C1D18),
        );
      case PolicyStatus.review:
        return _StatusConfig(
          label: 'Review',
          icon: Icons.rate_review_outlined,
          iconBg: const Color(0xFFD3E4FD),
          iconColor: const Color(0xFF0D47A1),
          chipBg: const Color(0xFFD3E4FD),
          chipText: const Color(0xFF0D47A1),
        );
    }
  }

  // ─── Scam Alerts Card ──────────────────────────────────────────────────────

  Widget _buildScamAlertsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayAlerts = scamAlertsData.take(3).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      color: colorScheme.surface,
      child: Column(
        children: displayAlerts.asMap().entries.map((entry) {
          return _buildScamAlertListItem(
            context,
            entry.value,
            entry.key == displayAlerts.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScamAlertListItem(
    BuildContext context,
    Map<String, dynamic> alert,
    bool isLast,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskLevel = (alert['risk_level'] ?? '').toString();

    Color riskColor;
    Color riskBg;
    if (riskLevel == 'High') {
      riskColor = const Color(0xFF8C1D18);
      riskBg = const Color(0xFFFCDAD7);
    } else if (riskLevel == 'Medium') {
      riskColor = const Color(0xFF7A4F00);
      riskBg = const Color(0xFFFFF0C5);
    } else {
      riskColor = const Color(0xFF1A5E20);
      riskBg = const Color(0xFFD7EDCA);
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text((alert['title'] ?? '').toString()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why it is fake:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text((alert['why_it_is_fake'] ?? '').toString()),
                  const SizedBox(height: 12),
                  const Text('How to stay safe:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text((alert['how_to_stay_safe'] ?? '').toString()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: riskBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, size: 20, color: riskColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (alert['title'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (alert['short_description'] ?? '').toString(),
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (alert['platform_spread'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (alert['scam_type'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Activity Card ──────────────────────────────────────────────────────

  Widget _buildAIActivityCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, size: 20, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask the AI assistant',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Verify claims and policy details quickly',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => setState(() => _selectedNavIndex = 2),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Open', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.security_outlined),
          selectedIcon: Icon(Icons.security),
          label: 'Scams',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified),
          label: 'Fact Check',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
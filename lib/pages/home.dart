import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../one/localization/app_text.dart';
import '../one/providers/language_provider.dart';
import '../services/fact_check_service.dart';
import 'ScamAlert.dart';
import 'fact_check_chat.dart';
import 'profile.dart';
import 'scams_page.dart';
import 'search_page.dart';

class PolicyLensApp extends StatelessWidget {
  const PolicyLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolicyLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      home: const HomePage(),
    );
  }
}

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
  final IconData icon;
  final Color? backgroundColor;
  final Color? valueColor;
  final Color? labelColor;
  final Color? iconColor;

  const MetricModel({
    required this.value,
    required this.label,
    required this.icon,
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

  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.chipBg,
    required this.chipText,
  });
}

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
      icon: Icons.policy_outlined,
      backgroundColor: Color(0xFFE8DEF8),
      valueColor: Color(0xFF21005D),
      labelColor: Color(0xFF4F378B),
      iconColor: Color(0xFF6750A4),
    ),
    MetricModel(
      value: '47',
      label: 'Updated',
      icon: Icons.update_outlined,
      backgroundColor: Color(0xFFD3E4FD),
      valueColor: Color(0xFF0D47A1),
      labelColor: Color(0xFF185FA5),
      iconColor: Color(0xFF185FA5),
    ),
    MetricModel(
      value: '12',
      label: 'Pending',
      icon: Icons.pending_outlined,
      backgroundColor: Color(0xFFFFF0C5),
      valueColor: Color(0xFF7A4F00),
      labelColor: Color(0xFF854F0B),
      iconColor: Color(0xFFBA7517),
    ),
    MetricModel(
      value: '3',
      label: 'Conflicts',
      icon: Icons.warning_amber_outlined,
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
    final text = AppText.of(context);
    final initials = _buildInitials(user);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildHomeTab(context, user, initials, text),
            const ScamsPage(),
            FactCheckChatPage(service: _factCheckService),
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, text),
    );
  }

  String _buildInitials(User? user) {
    if (user?.displayName == null || user!.displayName!.isEmpty) {
      return 'U';
    }

    final names = user.displayName!.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }

    return names[0][0].toUpperCase();
  }

  Widget _buildHomeTab(
    BuildContext context,
    User? user,
    String initials,
    AppText text,
  ) {
    return Column(
      children: [
        _buildTopAppBar(context, user, initials, text),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildSearchBar(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, text.overview),
                const SizedBox(height: 8),
                _buildMetricsGrid(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, text.recentPolicies),
                const SizedBox(height: 8),
                _buildPoliciesCard(context, text),
                const SizedBox(height: 20),
                _buildSectionLabel(context, text.recentScamAlerts),
                const SizedBox(height: 8),
                _buildScamAlertsCard(context),
                const SizedBox(height: 20),
                _buildSectionLabel(context, text.aiActivity),
                const SizedBox(height: 8),
                _buildAIActivityCard(context, text),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    User? user,
    String initials,
    AppText text,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            'Civic-Shield',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
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
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                user != null ? initials : 'U',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AppLanguage>(
            tooltip: text.language,
            onSelected: (value) {
              context.read<LanguageProvider>().setLanguage(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: AppLanguage.english, child: Text('English')),
              PopupMenuItem(value: AppLanguage.hindi, child: Text('Hindi')),
              PopupMenuItem(value: AppLanguage.marathi, child: Text('Marathi')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    text.language,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search policies, scams, and advisories',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: metric.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(metric.icon, size: 20, color: metric.iconColor),
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

  Widget _buildPoliciesCard(BuildContext context, AppText text) {
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
          final index = entry.key;
          final policy = entry.value;
          final isLast = index == _recentPolicies.length - 1;
          return _buildPolicyListItem(context, policy, isLast, text);
        }).toList(),
      ),
    );
  }

  Widget _buildPolicyListItem(
    BuildContext context,
    PolicyModel policy,
    bool isLast,
    AppText text,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusConfig = _getStatusConfig(policy.status, text);

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
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
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
              child: Icon(
                statusConfig.icon,
                size: 18,
                color: statusConfig.iconColor,
              ),
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
                    '${policy.ministry} � ${policy.date}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(policy.status, text),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PolicyStatus status, AppText text) {
    final config = _getStatusConfig(status, text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: config.chipText,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(PolicyStatus status, AppText text) {
    switch (status) {
      case PolicyStatus.active:
        return _StatusConfig(
          label: text.active,
          icon: Icons.check_circle_outline,
          iconBg: const Color(0xFFD7EDCA),
          iconColor: const Color(0xFF1A5E20),
          chipBg: const Color(0xFFD7EDCA),
          chipText: const Color(0xFF1A5E20),
        );
      case PolicyStatus.draft:
        return _StatusConfig(
          label: text.draft,
          icon: Icons.edit_outlined,
          iconBg: const Color(0xFFFFF0C5),
          iconColor: const Color(0xFF7A4F00),
          chipBg: const Color(0xFFFFF0C5),
          chipText: const Color(0xFF7A4F00),
        );
      case PolicyStatus.conflict:
        return _StatusConfig(
          label: text.conflict,
          icon: Icons.warning_amber_outlined,
          iconBg: const Color(0xFFFCDAD7),
          iconColor: const Color(0xFF8C1D18),
          chipBg: const Color(0xFFFCDAD7),
          chipText: const Color(0xFF8C1D18),
        );
      case PolicyStatus.review:
        return _StatusConfig(
          label: text.review,
          icon: Icons.rate_review_outlined,
          iconBg: const Color(0xFFD3E4FD),
          iconColor: const Color(0xFF0D47A1),
          chipBg: const Color(0xFFD3E4FD),
          chipText: const Color(0xFF0D47A1),
        );
    }
  }

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
                  const Text(
                    'Why it is fake:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text((alert['why_it_is_fake'] ?? '').toString()),
                  const SizedBox(height: 12),
                  const Text(
                    'How to stay safe:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
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
              child: Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: riskColor,
              ),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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

  Widget _buildAIActivityCard(BuildContext context, AppText text) {
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
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.askAIAssistant,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Verify claims and policy details quickly',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => setState(() => _selectedNavIndex = 2),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(text.open, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppText text) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) =>
          setState(() => _selectedNavIndex = index),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: text.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.security_outlined),
          selectedIcon: const Icon(Icons.security),
          label: text.scams,
        ),
        NavigationDestination(
          icon: const Icon(Icons.verified_outlined),
          selectedIcon: const Icon(Icons.verified),
          label: text.factCheck,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: text.profile,
        ),
      ],
    );
  }
}

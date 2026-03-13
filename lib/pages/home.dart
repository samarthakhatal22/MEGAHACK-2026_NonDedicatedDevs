import 'package:flutter/material.dart';
import 'search_page.dart';
import 'profile.dart';
import 'ScamAlert.dart';
import 'fact_check_chat.dart';
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
 
enum PolicyStatus { active, draft, conflict, review }
 
class MetricModel {
  final String value;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color valueColor;
  final Color labelColor;
  final Color iconColor;
 
  const MetricModel({
    required this.value,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.valueColor,
    required this.labelColor,
    required this.iconColor,
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
    apiKey: const String.fromEnvironment('GROQ_API_KEY'),
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
    final colorScheme = Theme.of(context).colorScheme;
 
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _selectedNavIndex == 2
            ? FactCheckChatPage(service: _factCheckService)
            : Column(
                children: [
                  _buildTopAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildSearchBar(context),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                          const SizedBox(height: 20),
                          _buildSectionLabel(context, 'Overview'),
                          const SizedBox(height: 8),
                          _buildMetricsGrid(context),
                          const SizedBox(height: 20),
                          _buildSectionHeader(context, 'Recent scam alerts', onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScamAlerts()),
                            );
                          }),
                          const SizedBox(height: 8),
                          _buildScamAlertsCard(context),
                          const SizedBox(height: 20),
                          _buildSectionHeader(context, 'Recent policies',
                              onViewAll: () {}),
                          const SizedBox(height: 8),
                          _buildPoliciesCard(context),
                          const SizedBox(height: 20),
                          _buildAIActivityCard(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
 
  // ── Top App Bar ──────────────────────────────────────────────────────────────
 
  Widget _buildTopAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'PolicyLens',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                'AP',
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
 
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
 
  // ── Search Bar ───────────────────────────────────────────────────────────────
 
  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
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
                'Search policies, acts, amendments…',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.tune, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
 
  // ── Quick Actions ────────────────────────────────────────────────────────────
 
  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    final actions = [
      {'icon': Icons.report_outlined, 'label': 'Report\nScam', 'color': const Color(0xFFE24B4A), 'bg': const Color(0xFFFCDAD7)},
      {'icon': Icons.fact_check_outlined, 'label': 'Fast\nCheck', 'color': const Color(0xFF185FA5), 'bg': const Color(0xFFD3E4FD)},
      {'icon': Icons.shield_outlined, 'label': 'Verify\nPolicy', 'color': const Color(0xFF1A5E20), 'bg': const Color(0xFFD7EDCA)},
      {'icon': Icons.notifications_active_outlined, 'label': 'Alerts', 'color': const Color(0xFF7A4F00), 'bg': const Color(0xFFFFF0C5)},
    ];
 
    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: (action['bg'] as Color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    action['icon'] as IconData,
                    size: 22,
                    color: action['color'] as Color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: action['color'] as Color,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
 
  // ── Section Label ────────────────────────────────────────────────────────────
 
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
 
  // ── Section Header with View All ─────────────────────────────────────────────
 
  Widget _buildSectionHeader(BuildContext context, String label,
      {required VoidCallback onViewAll}) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
 
  // ── Metrics Grid (smaller) ───────────────────────────────────────────────────
 
  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,        // ← 4 in a row instead of 2
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,   // ← smaller cards
      ),
      itemCount: _metrics.length,
      itemBuilder: (context, index) {
        final metric = _metrics[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: metric.backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(metric.icon, size: 16, color: metric.iconColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.value,
                    style: TextStyle(
                      fontSize: 16,               // ← smaller font
                      fontWeight: FontWeight.w600,
                      color: metric.valueColor,
                    ),
                  ),
                  Text(
                    metric.label,
                    style: TextStyle(
                      fontSize: 9,                // ← smaller label
                      color: metric.labelColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
 
  // ── Scam Alerts Card (only 3) ────────────────────────────────────────────────
 
  Widget _buildScamAlertsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    // ← only take first 3
    final displayAlerts = scamAlertsData.take(3).toList();
 
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      color: colorScheme.surface,
      child: Column(
        children: [
          ...displayAlerts.asMap().entries.map((entry) {
            final index = entry.key;
            final alert = entry.value;
            final isLast = index == displayAlerts.length - 1;
            return _buildScamAlertListItem(context, alert, isLast);
          }),
        ],
      ),
    );
  }
 
  Widget _buildScamAlertListItem(
    BuildContext context,
    Map<String, dynamic> alert,
    bool isLast,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskLevel = alert['risk_level'] as String;
 
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
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(alert['title'],
                style: const TextStyle(fontWeight: FontWeight.w500)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why it is fake:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(alert['why_it_is_fake']),
                  const SizedBox(height: 12),
                  const Text('How to stay safe:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(alert['how_to_stay_safe']),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            // colored left accent bar
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: riskColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: riskBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: riskColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          riskLevel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: riskColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert['short_description'],
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.devices_outlined,
                          size: 11,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        alert['platform_spread'],
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.label_outline,
                          size: 11,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          alert['scam_type'],
                          style: TextStyle(
                            fontSize: 10,
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
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
 
  // ── Policies Card ────────────────────────────────────────────────────────────
 
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
        children: [
          ..._recentPolicies.asMap().entries.map((entry) {
            final index = entry.key;
            final policy = entry.value;
            final isLast = index == _recentPolicies.length - 1;
            return _buildPolicyListItem(context, policy, isLast);
          }),
        ],
      ),
    );
  }
 
  Widget _buildPolicyListItem(
    BuildContext context,
    PolicyModel policy,
    bool isLast,
  ) {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: statusConfig.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusConfig.icon,
                  size: 16, color: statusConfig.iconColor),
            ),
            const SizedBox(width: 10),
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
                  Text(
                    '${policy.ministry} · ${policy.date}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: config.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: config.chipText,
        ),
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
 
  // ── AI Activity Card ─────────────────────────────────────────────────────────
 
  Widget _buildAIActivityCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 20,
              color: colorScheme.onPrimary,
            ),
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
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Verify policies, check facts instantly',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => setState(() => _selectedNavIndex = 2),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Open', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
 
  // ── Bottom Nav (4 tabs) ──────────────────────────────────────────────────────
 
  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScamAlerts()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning_amber_rounded),
          label: 'Scams',
        ),
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check),
          label: 'Fast Check',
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

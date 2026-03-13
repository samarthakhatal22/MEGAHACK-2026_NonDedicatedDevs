import 'package:flutter/material.dart';
import 'search_page.dart';
import 'profile.dart';
 
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
  final Color? backgroundColor;
  final Color? valueColor;
  final Color? labelColor;
 
  const MetricModel({
    required this.value,
    required this.label,
    this.backgroundColor,
    this.valueColor,
    this.labelColor,
  });
}
 
class HomePage extends StatefulWidget {
  const HomePage({super.key});
 
  @override
  State<HomePage> createState() => _HomePageState();
}
 
class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;
 
  final List<MetricModel> _metrics = const [
    MetricModel(value: '1,284', label: 'Total policies'),
    MetricModel(value: '47', label: 'Updated this month'),
    MetricModel(value: '12', label: 'Pending review'),
    MetricModel(
      value: '3',
      label: 'Conflicts flagged',
      backgroundColor: Color(0xFFFCDAD7),
      valueColor: Color(0xFF8C1D18),
      labelColor: Color(0xFF8C1D18),
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
        child: Column(
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
                    const SizedBox(height: 20),
                    _buildSectionLabel(context, 'Overview'),
                    const SizedBox(height: 8),
                    _buildMetricsGrid(context),
                    const SizedBox(height: 20),
                    _buildSectionLabel(context, 'Recent policies'),
                    const SizedBox(height: 8),
                    _buildPoliciesCard(context),
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
 
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
                'Good morning',
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
          CircleAvatar(
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
        ],
      ),
    );
  }
 
  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return GestureDetector(
      onTap: () {},
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
        childAspectRatio: 1.6,
      ),
      itemCount: _metrics.length,
      itemBuilder: (context, index) {
        final metric = _metrics[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: metric.backgroundColor ?? colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: metric.valueColor ?? colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.label,
                style: TextStyle(
                  fontSize: 11,
                  color: metric.labelColor ?? colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
 
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
      BuildContext context, PolicyModel policy, bool isLast) {
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
                    'Ask the AI assistant',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Last query 2 minutes ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
 
  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  } else if (index == 4) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  } else {
    setState(() => _selectedNavIndex = index);
  }
},
      // onDestinationSelected: (index) {
     // setState(() => _selectedNavIndex = index);
      // },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.upload_file_outlined),
          selectedIcon: Icon(Icons.upload_file),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.compare_arrows_outlined),
          selectedIcon: Icon(Icons.compare_arrows),
          label: 'Compare',
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
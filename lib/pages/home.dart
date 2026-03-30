import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'profile.dart';
import 'package:civicshield/Widgets/scamalertsection.dart';
import 'scams_page.dart';
import 'fact_check_chat.dart';
import '../one/localization/app_text.dart';
import '../one/providers/language_provider.dart';
import '../services/fact_check_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;

  static const String _groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  final _factCheckService = FactCheckService(apiKey: _groqApiKey);

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
    String initials = "U";
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      List<String> names = user.displayName!.split(" ");
      if (names.length >= 2) {
        initials = "${names[0][0]}${names[1][0]}".toUpperCase();
      } else {
        initials = names[0][0].toUpperCase();
      }
    }

    final colorScheme = Theme.of(context).colorScheme;
    final text = AppText.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            // Home (Index 0)
            Column(
              children: [
                _buildTopAppBar(context, colorScheme, user, initials, text),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildSectionLabel(context, text.overview, colorScheme),
                        const SizedBox(height: 8),
                        _buildMetricsGrid(context, colorScheme, _metrics(text)),
                        const SizedBox(height: 20),
                        _buildSectionLabel(
                          context,
                          text.recentPolicies,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildPoliciesCard(context, colorScheme, text),
                        const SizedBox(height: 20),
                        _buildSectionLabel(
                          context,
                          text.recentScamAlerts,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        const ScamAlertSection(),
                        const SizedBox(height: 20),
                        _buildSectionLabel(
                          context,
                          text.aiActivity,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildAIActivityCard(context, colorScheme, text),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Scams (Index 1)
            const ScamsPage(),
            // Profile (Index 2)
            const ProfilePage(),
            // Fact Check (Index 3)
            FactCheckChatPage(service: _factCheckService),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, text),
    );
  }

  List<MetricModel> _metrics(AppText text) {
    return [
      MetricModel(value: '1,284', label: text.totalPolicies),
      MetricModel(value: '47', label: text.updatedThisMonth),
      MetricModel(value: '12', label: text.pendingReview),
      MetricModel(
        value: '3',
        label: text.conflictsFlagged,
        backgroundColor: const Color(0xFFFCDAD7),
        valueColor: const Color(0xFF8C1D18),
        labelColor: const Color(0xFF8C1D18),
      ),
    ];
  }

  Widget _buildTopAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    User? user,
    String initials,
    AppText text,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 1),
              Text(
                'Civic-Shield',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
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

  Widget _buildSectionLabel(
    BuildContext context,
    String label,
    ColorScheme colorScheme,
  ) {
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

  Widget _buildMetricsGrid(
    BuildContext context,
    ColorScheme colorScheme,
    List<MetricModel> metrics,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2, // Increased from 1.6 to make it shorter
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ), // Reduced vertical padding
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
                  fontSize: 20, // Slightly smaller font
                  fontWeight: FontWeight.w500,
                  color: metric.valueColor ?? colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 1), // Reduced height
              Text(
                metric.label,
                style: TextStyle(
                  fontSize: 10, // Slightly smaller font
                  color: metric.labelColor ?? colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoliciesCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppText text,
  ) {
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
            return _buildPolicyListItem(
              context,
              policy,
              isLast,
              colorScheme,
              text,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPolicyListItem(
    BuildContext context,
    PolicyModel policy,
    bool isLast,
    ColorScheme colorScheme,
    AppText text,
  ) {
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
                    '${policy.ministry} \u00B7 ${policy.date}',
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

  /*
  Widget _buildScamAlertsCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      color: colorScheme.surface,
      child: Column(
        children: [
          ...scamAlertsData.asMap().entries.map((entry) {
            final index = entry.key;
            final alert = entry.value;
            final isLast = index == scamAlertsData.length - 1;
            return _buildScamAlertListItem(context, alert, isLast, colorScheme);
          }),
        ],
      ),
    );
  }
  */ //static data for scam alerts

  Widget _buildAIActivityCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppText text,
  ) {
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
                    text.lastQuery,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                setState(() => _selectedNavIndex = 3);
              },
              style: FilledButton.styleFrom(
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
      onDestinationSelected: (index) {
        setState(() => _selectedNavIndex = index);
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: text.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.security_outlined),
          selectedIcon: Icon(Icons.security),
          label: text.scams,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: text.profile,
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified),
          label: text.factCheck,
        ),
      ],
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

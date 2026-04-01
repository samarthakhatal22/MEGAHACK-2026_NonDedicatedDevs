// ignore_for_file: duplicate_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../one/localization/app_text.dart';
import '../services/fact_check_service.dart';
import 'ScamAlert.dart';
import 'fact_check_chat.dart';
import 'profile.dart';
import 'scams_page.dart';
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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _factCheckService = FactCheckService(
    apiKey: dotenv.env['GROQ_API_KEY'] ?? '',
  );

  final List<MetricModel> _metrics = const [
    MetricModel(
      value: '1,284',
      label: 'Total policies',
      icon: Icons.policy,
      backgroundColor: Color(0xFFE8DEF8),
      valueColor: Color(0xFF1A237E),
      labelColor: Color(0xFF4F378B),
      iconColor: Color(0xFF1A237E),
    ),
    MetricModel(
      value: '47',
      label: 'Updated',
      icon: Icons.update,
      backgroundColor: Color(0xFFD3E4FD),
      valueColor: Color(0xFF0D47A1),
      labelColor: Color(0xFF185FA5),
      iconColor: Color(0xFF2979FF),
    ),
    MetricModel(
      value: '12',
      label: 'Pending',
      icon: Icons.pending,
      backgroundColor: Color(0xFFFFF0C5),
      valueColor: Color(0xFFF57F17),
      labelColor: Color(0xFF854F0B),
      iconColor: Color(0xFFF57F17),
    ),
    MetricModel(
      value: '3',
      label: 'Conflicts',
      icon: Icons.warning_amber,
      backgroundColor: Color(0xFFFCDAD7),
      valueColor: Color(0xFFB71C1C),
      labelColor: Color(0xFF8C1D18),
      iconColor: Color(0xFFB71C1C),
    ),
  ];

  // final List<PolicyModel> _recentPolicies = const [
  //   PolicyModel(
  //     title: 'Digital India Act 2024',
  //     ministry: 'MeitY',
  //     date: 'Jan 2024',
  //     status: PolicyStatus.active,
  //   ),
  //   PolicyModel(
  //     title: 'NEP Amendment v3',
  //     ministry: 'MoE',
  //     date: 'Mar 2024',
  //     status: PolicyStatus.draft,
  //   ),
  //   PolicyModel(
  //     title: 'PDPB Regulations',
  //     ministry: 'MHA',
  //     date: 'Feb 2024',
  //     status: PolicyStatus.conflict,
  //   ),
  //   PolicyModel(
  //     title: 'Green Hydrogen Mission',
  //     ministry: 'MNRE',
  //     date: 'Apr 2024',
  //     status: PolicyStatus.review,
  //   ),
  // ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            // Dark gradient hero header
            _buildHeroHeader(context, user, initials, text),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSectionLabel(
                      context,
                      text.overview,
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    _buildMetricsGrid(context),
                    const SizedBox(height: 28),
                    // _buildSectionLabel(context, text.recentPolicies)
                    //     .animate()
                    //     .fadeIn(duration: 500.ms, delay: 100.ms)
                    //     .slideX(begin: -0.1),
                    // const SizedBox(height: 12),
                    // _buildPoliciesCard(context, text)
                    //     .animate()
                    //     .fadeIn(duration: 600.ms, delay: 200.ms)
                    //     .slideY(begin: 0.1),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, text.recentScamAlerts)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 300.ms)
                        .slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    _buildScamAlertsCard(context)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, text.aiActivity)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 500.ms)
                        .slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    _buildAIActivityCard(context, text)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dark gradient hero header with app title, search, and user avatar.
  Widget _buildHeroHeader(
    BuildContext context,
    User? user,
    String initials,
    AppText text,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.premiumNavy,
            AppColors.darkNavy,
            AppColors.premiumNavy.withBlue(60),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepPurple.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CivicShield',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                                letterSpacing: -1,
                              ),
                        ),
                        Text(
                          'Empowering Communities',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // child: IconButton(
                      //   icon: const Icon(Icons.notifications_none, color: Colors.white),
                      //   onPressed: () {},
                      // ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.premiumGold.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.deepPurple,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Premium Styled Search Bar
                Hero(
                  tag: 'search-bar',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      ),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.premiumGold,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Search policies or advisories...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.premiumGold,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                1.3, // Reduced aspect ratio to provide more height
          ),
          itemCount: _metrics.length,
          itemBuilder: (context, index) {
            final metric = _metrics[index];
            return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(metric.icon, size: 24, color: metric.iconColor),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: metric.iconColor?.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.value,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            metric.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate(delay: (index * 100).ms)
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  curve: Curves.easeOutBack,
                );
          },
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
      //color: colorScheme.surface,
      // child: Column(
      //   children: _recentPolicies.asMap().entries.map((entry) {
      //     return _buildPolicyListItem(
      //       context,
      //       entry.value,
      //       entry.key == _recentPolicies.length - 1,
      //     );
      //   }).toList(),
      // ),
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
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusConfig.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusConfig.icon,
                size: 20,
                color: statusConfig.iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${policy.ministry} · ${policy.date}',
                    style: TextStyle(
                      fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.chipText),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: config.chipText,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(PolicyStatus status, AppText text) {
    switch (status) {
      case PolicyStatus.active:
        return _StatusConfig(
          label: text.active,
          icon: Icons.check_circle,
          iconBg: const Color(0xFFD7EDCA),
          iconColor: AppColors.emeraldGreen,
          chipBg: const Color(0xFFD7EDCA),
          chipText: AppColors.emeraldGreen,
        );
      case PolicyStatus.draft:
        return _StatusConfig(
          label: text.draft,
          icon: Icons.edit,
          iconBg: const Color(0xFFFFF0C5),
          iconColor: AppColors.amberWarning,
          chipBg: const Color(0xFFFFF0C5),
          chipText: const Color(0xFF7A4F00),
        );
      case PolicyStatus.conflict:
        return _StatusConfig(
          label: text.conflict,
          icon: Icons.warning_amber,
          iconBg: const Color(0xFFFCDAD7),
          iconColor: AppColors.crimsonRed,
          chipBg: const Color(0xFFFCDAD7),
          chipText: AppColors.crimsonRed,
        );
      case PolicyStatus.review:
        return _StatusConfig(
          label: text.review,
          icon: Icons.rate_review,
          iconBg: const Color(0xFFD3E4FD),
          iconColor: AppColors.electricBlue,
          chipBg: const Color(0xFFD3E4FD),
          chipText: const Color(0xFF0D47A1),
        );
    }
  }

  Widget _buildScamAlertsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayAlerts = scamAlertsData.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryIndigo.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
    IconData riskIcon;
    if (riskLevel == 'High') {
      riskColor = AppColors.crimsonRed;
      riskBg = const Color(0xFFFCDAD7);
      riskIcon = Icons.dangerous;
    } else if (riskLevel == 'Medium') {
      riskColor = AppColors.amberWarning;
      riskBg = const Color(0xFFFFF0C5);
      riskIcon = Icons.warning_amber;
    } else {
      riskColor = AppColors.emeraldGreen;
      riskBg = const Color(0xFFD7EDCA);
      riskIcon = Icons.info;
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
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: riskBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(riskIcon, size: 22, color: riskColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (alert['title'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(riskIcon, size: 10, color: riskColor),
                            const SizedBox(width: 4),
                            Text(
                              riskLevel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (alert['platform_spread'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryIndigo.withOpacity(0.06),
            AppColors.electricBlue.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryIndigo.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryIndigo.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryIndigo, AppColors.electricBlue],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 22,
                color: Colors.white,
              ),
              // child: Icon(
              //   Icons.auto_awesome,
              //   size: 20,
              //   color: colorScheme.onPrimaryContainer,
              // ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.askAIAssistant,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Verify claims and policy details quickly',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryIndigo, AppColors.electricBlue],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedNavIndex = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  text.open,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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

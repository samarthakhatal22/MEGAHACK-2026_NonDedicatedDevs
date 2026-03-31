import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../one/localization/app_text.dart';
import '../models/scamalert.dart';
import '../services/multi_source_scam_service.dart';

// ── Category display config ────────────────────────────────────────────────────

const Map<String, _CategoryMeta> _categoryMeta = {
  'UPI Fraud': _CategoryMeta(icon: '💰', color: Color(0xFF8C1D18)),
  'Phishing': _CategoryMeta(icon: '🎣', color: Color(0xFF6A1E5A)),
  'WhatsApp Scam': _CategoryMeta(icon: '📱', color: Color(0xFF0D47A1)),
  'Investment Scam': _CategoryMeta(icon: '📈', color: Color(0xFF7A4F00)),
  'Job Scam': _CategoryMeta(icon: '🎓', color: Color(0xFF1A5E20)),
  'Delivery Scam': _CategoryMeta(icon: '📦', color: Color(0xFF37474F)),
  'Other': _CategoryMeta(icon: '⚠️', color: Color(0xFF4A4A4A)),
};

class _CategoryMeta {
  final String icon;
  final Color color;
  const _CategoryMeta({required this.icon, required this.color});
}

// ── Page ─────────────────────────────────────────────────────────────────────

class ScamsPage extends StatefulWidget {
  const ScamsPage({super.key});

  @override
  State<ScamsPage> createState() => _ScamsPageState();
}

class _ScamsPageState extends State<ScamsPage>
    with AutomaticKeepAliveClientMixin {
  // Keeps fetch alive when user switches tabs and returns.
  @override
  bool get wantKeepAlive => true;

  final MultiSourceScamService _service = MultiSourceScamService();
  late Future<List<ScamAlertGroup>> _futureGroups;

  @override
  void initState() {
    super.initState();
    _futureAlerts = _service.fetchScamAlerts(languageCode: _languageCode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode != _languageCode) {
      _languageCode = localeCode;
      _futureAlerts = _service.fetchScamAlerts(languageCode: _languageCode);
    }
  }

  void _refresh() {
    setState(() {
      _futureAlerts = _service.fetchScamAlerts(languageCode: _languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final text = AppText.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scam Alerts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<ScamAlertGroup>>(
        future: _futureGroups,
        builder: (context, snapshot) {
          // ── Loading ────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingList();
          }

          // ── Error ──────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return _FullPageError(
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final groups = snapshot.data ?? [];

          // ── Empty ──────────────────────────────────────────────────────────
          if (groups.isEmpty) {
            return _FullPageError(
              message:
                  '⚠️ Unable to fetch latest scam alerts.\nPlease check your connection or try again.',
              onRetry: _refresh,
            );
          }

          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return Center(child: Text(text.noScamAlerts));
          }

          // ── Category sections ──────────────────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _ScamTile(
                alert: alert,
                localeCode: localeCode,
                text: text,
              );
              final group = groups[index];
              return _CategorySection(group: group);
            },
          );
        },
      ),
    );
  }
}

// ── Category section (header + alert card list) ───────────────────────────────

class _CategorySection extends StatelessWidget {
  final ScamAlertGroup group;
  const _CategorySection({required this.group});

  @override
  Widget build(BuildContext context) {
    final meta =
        _categoryMeta[group.category] ??
        const _CategoryMeta(icon: '⚠️', color: Color(0xFF4A4A4A));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // ── Section header ─────────────────────────────────────────────────
        Row(
          children: [
            Text(meta.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              group.category.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: meta.color,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${group.alerts.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: meta.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Alert tiles ────────────────────────────────────────────────────
        ...group.alerts.map((alert) => _ScamTile(alert: alert)),
      ],
    );
  }
}

// ── Individual alert tile ─────────────────────────────────────────────────────

class _ScamTile extends StatelessWidget {
  final ScamAlert alert;
  final String localeCode;
  final AppText text;

  const _ScamTile({
    required this.alert,
    required this.localeCode,
    required this.text,
  });
  const _ScamTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine risk style
    Color riskColor;
    Color riskBg;
    if (alert.riskLevel.toLowerCase() == 'high') {
      riskColor = const Color(0xFF8C1D18);
      riskBg = const Color(0xFFFCDAD7);
    } else if (alert.riskLevel.toLowerCase() == 'medium') {
      riskColor = const Color(0xFF7A4F00);
      riskBg = const Color(0xFFFFF0C5);
    } else {
      riskColor = const Color(0xFF1A5E20);
      riskBg = const Color(0xFFD7EDCA);
    }
    final riskStyle = _riskStyle(alert.riskLevel);
    final confStyle = _confidenceStyle(alert.confidenceLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context, alert),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: risk badge | confidence dot | date ───────────────
              Row(
                children: [
                  // Risk level pill
                  _SmallBadge(
                    label: '${alert.riskLevel} Risk',
                    bg: riskStyle.bg,
                    fg: riskStyle.fg,
                  ),
                  const SizedBox(width: 6),
                  // Confidence dot + label
                  _ConfidenceDot(
                    level: alert.confidenceLevel,
                    color: confStyle.color,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${alert.riskLevel} ${text.risk}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(alert.publishedDate, localeCode),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Title ──────────────────────────────────────────────────────
              Text(
                alert.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              // ── Description ────────────────────────────────────────────────
              Text(
                alert.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              // ── Footer: source label ───────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.sensors, size: 12, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Source: ${alert.source}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, String localeCode) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy', localeCode).format(date);
  }

  void _showDetails(BuildContext context, ScamAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScamDetailsSheet(alert: alert, text: text),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _ScamDetailsSheet extends StatelessWidget {
  final ScamAlert alert;
  final AppText text;

  const _ScamDetailsSheet({required this.alert, required this.text});
  const _ScamDetailsSheet({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final confStyle = _confidenceStyle(alert.confidenceLevel);
    final meta =
        _categoryMeta[alert.category] ??
        const _CategoryMeta(icon: '⚠️', color: Color(0xFF4A4A4A));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            // Handle bar
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Category chip
            Row(
              children: [
                Text(meta.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                _SmallBadge(
                  label: alert.category,
                  bg: meta.color.withValues(alpha: 0.12),
                  fg: meta.color,
                ),
                const Spacer(),
                // Confidence badge
                _SmallBadge(
                  label: '${confStyle.dot} ${alert.confidenceLevel} Confidence',
                  bg: confStyle.color.withValues(alpha: 0.12),
                  fg: confStyle.color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              alert.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            // Source + date
            Text(
              'Source: ${alert.source}   ·   ${_formatDate(alert.publishedDate)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              alert.description,
              style: const TextStyle(fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 24),
            // Protection tips
            Text(
              'HOW TO PROTECT YOURSELF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildTip(
              Icons.verified_user,
              'Verify through official Govt. channels (india.gov.in).',
            ),
            _buildTip(
              Icons.link_off,
              'Never click on suspicious links in SMS or WhatsApp.',
            ),
            _buildTip(
              Icons.security,
              'Report scams to 1930 (Cyber Crime Helpline).',
            ),
            _buildTip(
              Icons.block,
              'Never share OTP, Aadhaar, or banking credentials.',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SmallBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final String level;
  final Color color;
  const _ConfidenceDot({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$level Conf.',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Confidence style ──────────────────────────────────────────────────────────

class _ConfStyle {
  final Color color;
  final String dot;
  const _ConfStyle({required this.color, required this.dot});
}

_ConfStyle _confidenceStyle(String level) {
  switch (level) {
    case 'High':
      return const _ConfStyle(color: Color(0xFFB71C1C), dot: '🔴');
    case 'Medium':
      return const _ConfStyle(color: Color(0xFF7A4F00), dot: '🟡');
    default:
      return const _ConfStyle(color: Color(0xFF1A5E20), dot: '🟢');
  }
}

// ── Risk level style ──────────────────────────────────────────────────────────

class _RiskStyle {
  final Color bg;
  final Color fg;
  const _RiskStyle({required this.bg, required this.fg});
}

_RiskStyle _riskStyle(String level) {
  switch (level.toLowerCase()) {
    case 'high':
      return const _RiskStyle(bg: Color(0xFFFCDAD7), fg: Color(0xFF8C1D18));
    case 'medium':
      return const _RiskStyle(bg: Color(0xFFFFF0C5), fg: Color(0xFF7A4F00));
    default:
      return const _RiskStyle(bg: Color(0xFFD7EDCA), fg: Color(0xFF1A5E20));
  }
}

// ── Full-page error widget ────────────────────────────────────────────────────

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FullPageError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading list ─────────────────────────────────────────────────────

class _LoadingList extends StatefulWidget {
  @override
  State<_LoadingList> createState() => _LoadingListState();
}

class _LoadingListState extends State<_LoadingList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.3 + (_anim.value * 0.45);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: 6,
          itemBuilder: (context2, index2) => Opacity(
            opacity: opacity,
            child: Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

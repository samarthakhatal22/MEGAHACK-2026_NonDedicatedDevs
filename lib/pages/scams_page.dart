import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scamalert.dart';
import '../one/localization/app_text.dart';
import '../services/multi_source_scam_service.dart';

const Map<String, _CategoryMeta> _categoryMeta = {
  'UPI Fraud': _CategoryMeta(icon: 'money', color: Color(0xFF8C1D18)),
  'Phishing': _CategoryMeta(icon: 'phishing', color: Color(0xFF6A1E5A)),
  'WhatsApp Scam': _CategoryMeta(icon: 'chat', color: Color(0xFF0D47A1)),
  'Investment Scam': _CategoryMeta(
    icon: 'trending_up',
    color: Color(0xFF7A4F00),
  ),
  'Job Scam': _CategoryMeta(icon: 'work', color: Color(0xFF1A5E20)),
  'Delivery Scam': _CategoryMeta(
    icon: 'local_shipping',
    color: Color(0xFF37474F),
  ),
  'Other': _CategoryMeta(icon: 'warning', color: Color(0xFF4A4A4A)),
};

class _CategoryMeta {
  final String icon;
  final Color color;

  const _CategoryMeta({required this.icon, required this.color});
}

class ScamsPage extends StatefulWidget {
  const ScamsPage({super.key});

  @override
  State<ScamsPage> createState() => _ScamsPageState();
}

class _ScamsPageState extends State<ScamsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final MultiSourceScamService _service = MultiSourceScamService();
  late Future<List<ScamAlertGroup>> _futureGroups;

  @override
  void initState() {
    super.initState();
    _futureGroups = _service.fetchGroupedAlerts(limit: 30);
  }

  void _refresh() {
    setState(() {
      _futureGroups = _service.fetchGroupedAlerts(limit: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }

          if (snapshot.hasError) {
            return _FullPageError(
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final groups = snapshot.data ?? const <ScamAlertGroup>[];
          if (groups.isEmpty) {
            return _FullPageError(
              message:
                  'Unable to fetch latest scam alerts. Please check your connection and try again.',
              onRetry: _refresh,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _CategorySection(group: groups[index]);
            },
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ScamAlertGroup group;

  const _CategorySection({required this.group});

  @override
  Widget build(BuildContext context) {
    final meta =
        _categoryMeta[group.category] ??
        const _CategoryMeta(icon: 'warning', color: Color(0xFF4A4A4A));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(_iconFromName(meta.icon), size: 18, color: meta.color),
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
        ...group.alerts.map((alert) => _ScamTile(alert: alert)),
      ],
    );
  }
}

class _ScamTile extends StatelessWidget {
  final ScamAlert alert;

  const _ScamTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = AppText.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
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
        onTap: () => _showDetails(context, alert, text),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SmallBadge(
                    label: '${alert.riskLevel} ${text.risk}',
                    bg: riskStyle.bg,
                    fg: riskStyle.fg,
                  ),
                  const SizedBox(width: 6),
                  _ConfidenceDot(
                    level: alert.confidenceLevel,
                    color: confStyle.color,
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
              Text(
                alert.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
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
    if (date == null) {
      return '';
    }
    return DateFormat('MMM dd, yyyy', localeCode).format(date);
  }

  void _showDetails(BuildContext context, ScamAlert alert, AppText text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScamDetailsSheet(alert: alert, text: text),
    );
  }
}

class _ScamDetailsSheet extends StatelessWidget {
  final ScamAlert alert;
  final AppText text;

  const _ScamDetailsSheet({required this.alert, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final confStyle = _confidenceStyle(alert.confidenceLevel);
    final meta =
        _categoryMeta[alert.category] ??
        const _CategoryMeta(icon: 'warning', color: Color(0xFF4A4A4A));

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
            Row(
              children: [
                Icon(_iconFromName(meta.icon), size: 16, color: meta.color),
                const SizedBox(width: 6),
                _SmallBadge(
                  label: alert.category,
                  bg: meta.color.withValues(alpha: 0.12),
                  fg: meta.color,
                ),
                const Spacer(),
                _SmallBadge(
                  label: '${confStyle.dot} ${alert.confidenceLevel} Confidence',
                  bg: confStyle.color.withValues(alpha: 0.12),
                  fg: confStyle.color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              alert.description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              text.protectYourself,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            _tipRow(context, text.tipVerify),
            _tipRow(context, text.tipNoLinks),
            _tipRow(context, text.tipReport),
            const SizedBox(height: 16),
            Text(
              'Source: ${alert.source}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _SmallBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          level,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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

class _ConfidenceStyle {
  final Color color;
  final String dot;

  const _ConfidenceStyle({required this.color, required this.dot});
}

_ConfidenceStyle _confidenceStyle(String level) {
  switch (level.toLowerCase()) {
    case 'high':
      return const _ConfidenceStyle(color: Color(0xFFB71C1C), dot: 'H');
    case 'medium':
      return const _ConfidenceStyle(color: Color(0xFF7A4F00), dot: 'M');
    default:
      return const _ConfidenceStyle(color: Color(0xFF1A5E20), dot: 'L');
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FullPageError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'money':
      return Icons.currency_rupee;
    case 'phishing':
      return Icons.phishing;
    case 'chat':
      return Icons.chat_bubble_outline;
    case 'trending_up':
      return Icons.trending_up;
    case 'work':
      return Icons.work_outline;
    case 'local_shipping':
      return Icons.local_shipping_outlined;
    default:
      return Icons.warning_amber_outlined;
  }
}

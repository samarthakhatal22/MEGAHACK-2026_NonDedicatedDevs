import 'package:flutter/material.dart';
import '../models/scamalert.dart';
import '../services/multi_source_scam_service.dart';

/// Home-screen preview card strip for Scam Alerts.
///
/// Shows up to 3 horizontally-scrollable cards, each displaying:
///  • Category icon + label
///  • Risk level badge
///  • Confidence indicator (🔴 🟡 🟢)
///  • Title + short description
///  • Source tag
///
/// Uses [MultiSourceScamService] for live data.
/// Falls back to the existing RapidAPI / curated list automatically
/// (handled inside the service).
class ScamAlertSection extends StatefulWidget {
  const ScamAlertSection({super.key});

  @override
  State<ScamAlertSection> createState() => _ScamAlertSectionState();
}

class _ScamAlertSectionState extends State<ScamAlertSection> {
  final MultiSourceScamService _service = MultiSourceScamService();
  late Future<List<ScamAlert>> _futureAlerts;

  @override
  void initState() {
    super.initState();
    _futureAlerts = _service.fetchScamAlerts(limit: 5);
  }

  void _refresh() {
    setState(() {
      _futureAlerts = _service.fetchScamAlerts(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Strip header ────────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.security, size: 14, color: colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              'RECENT SCAM ALERTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _refresh,
              child: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Horizontal scroll card strip ────────────────────────────────────
        SizedBox(
          height: 210,
          child: FutureBuilder<List<ScamAlert>>(
            future: _futureAlerts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _LoadingShimmer();
              }

              if (snapshot.hasError) {
                return _ErrorCard(
                  message: 'Could not load scam alerts.',
                  onRetry: _refresh,
                );
              }

              final alerts = snapshot.data ?? const <ScamAlert>[];
              if (alerts.isEmpty) {
                return _ErrorCard(
                  message: 'No scam alerts found at this time.',
                  onRetry: _refresh,
                );
              }

              final displayed = alerts.length > 3 ? alerts.sublist(0, 3) : alerts;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 4),
                itemCount: displayed.length,
                separatorBuilder: (context2, index2) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _AlertCard(alert: displayed[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final ScamAlert alert;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width       = (MediaQuery.of(context).size.width * 0.80).clamp(240.0, 320.0);
    final riskStyle   = _riskStyle(alert.riskLevel);
    final confStyle   = _confidenceStyle(alert.confidenceLevel);
    final meta        = _categoryMeta[alert.category] ??
        const _CategoryMeta(icon: '⚠️', color: Color(0xFF4A4A4A));

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.7),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: risk + confidence + date ──────────────────────────
          Row(
            children: [
              // Risk badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: riskStyle.bg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${alert.riskLevel} Risk',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: riskStyle.fg,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Confidence dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: confStyle.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                confStyle.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: confStyle.color,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(alert.publishedDate),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Category chip ──────────────────────────────────────────────────
          Row(
            children: [
              Text(meta.icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text(
                alert.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: meta.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── Title ──────────────────────────────────────────────────────────
          Text(
            alert.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          // ── Description ────────────────────────────────────────────────────
          Expanded(
            child: Text(
              alert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Footer: source tag ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rss_feed_rounded,
                    size: 9, color: colorScheme.primary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    alert.source,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ── Style helpers ─────────────────────────────────────────────────────────────

const Map<String, _CategoryMeta> _categoryMeta = {
  'UPI Fraud':       _CategoryMeta(icon: '💰', color: Color(0xFF8C1D18)),
  'Phishing':        _CategoryMeta(icon: '🎣', color: Color(0xFF6A1E5A)),
  'WhatsApp Scam':   _CategoryMeta(icon: '📱', color: Color(0xFF0D47A1)),
  'Investment Scam': _CategoryMeta(icon: '📈', color: Color(0xFF7A4F00)),
  'Job Scam':        _CategoryMeta(icon: '🎓', color: Color(0xFF1A5E20)),
  'Delivery Scam':   _CategoryMeta(icon: '📦', color: Color(0xFF37474F)),
  'Other':           _CategoryMeta(icon: '⚠️', color: Color(0xFF4A4A4A)),
};

class _CategoryMeta {
  final String icon;
  final Color  color;
  const _CategoryMeta({required this.icon, required this.color});
}

class _RiskStyle {
  final Color bg;
  final Color fg;
  const _RiskStyle({required this.bg, required this.fg});
}

_RiskStyle _riskStyle(String level) {
  switch (level.toLowerCase()) {
    case 'high':   return const _RiskStyle(bg: Color(0xFFFCDAD7), fg: Color(0xFF8C1D18));
    case 'medium': return const _RiskStyle(bg: Color(0xFFFFF0C5), fg: Color(0xFF7A4F00));
    default:       return const _RiskStyle(bg: Color(0xFFD7EDCA), fg: Color(0xFF1A5E20));
  }
}

class _ConfidenceStyle {
  final Color  color;
  final String label;
  const _ConfidenceStyle({required this.color, required this.label});
}

_ConfidenceStyle _confidenceStyle(String level) {
  switch (level) {
    case 'High':   return const _ConfidenceStyle(color: Color(0xFFB71C1C), label: 'High Conf.');
    case 'Medium': return const _ConfidenceStyle(color: Color(0xFF7A4F00), label: 'Med. Conf.');
    default:       return const _ConfidenceStyle(color: Color(0xFF1A5E20), label: 'Low Conf.');
  }
}

// ── Shimmer loading ───────────────────────────────────────────────────────────

class _LoadingShimmer extends StatefulWidget {
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        final opacity = 0.3 + (_anim.value * 0.4);
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context2, index2) => const SizedBox(width: 10),
          itemBuilder: (context, _) => Opacity(
            opacity: opacity,
            child: Container(
              width: 260,
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

// ── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String       message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
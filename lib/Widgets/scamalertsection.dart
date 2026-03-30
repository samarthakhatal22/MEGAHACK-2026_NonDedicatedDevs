import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../one/localization/app_text.dart';
import '../models/scamalert.dart';
import '../services/cybernews.dart';

class ScamAlertSection extends StatefulWidget {
  const ScamAlertSection({super.key});

  @override
  State<ScamAlertSection> createState() => _ScamAlertSectionState();
}

class _ScamAlertSectionState extends State<ScamAlertSection> {
  final CyberNewsService _service = CyberNewsService();
  late Future<List<ScamAlert>> _futureAlerts;
  String _languageCode = 'en';

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
    final colorScheme = Theme.of(context).colorScheme;
    final text = AppText.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security, size: 14, color: colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              text.recentScamAlerts.toUpperCase(),
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
        SizedBox(
          height: 200,
          child: FutureBuilder<List<ScamAlert>>(
            future: _futureAlerts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _LoadingShimmer();
              }

              if (snapshot.hasError) {
                return _ErrorCard(
                  message: '${text.errorPrefix}: ${snapshot.error}',
                  retryLabel: text.retry,
                  onRetry: _refresh,
                );
              }

              final alerts = snapshot.data ?? const <ScamAlert>[];
              if (alerts.isEmpty) {
                return _ErrorCard(
                  message: text.noScamAlerts,
                  retryLabel: text.retry,
                  onRetry: _refresh,
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 4),
                itemCount: alerts.length > 3 ? 3 : alerts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _AlertCard(
                  alert: alerts[index],
                  text: text,
                  localeCode: localeCode,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.text,
    required this.localeCode,
  });

  final ScamAlert alert;
  final AppText text;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = (MediaQuery.of(context).size.width * 0.80).clamp(
      240.0,
      320.0,
    );
    final riskStyle = _riskStyle(alert.riskLevel);

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
          // ── Header row: shield icon + risk badge ──────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: riskStyle.badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 17,
                  color: riskStyle.badgeText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: riskStyle.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${alert.riskLevel} ${text.risk}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: riskStyle.badgeText,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(alert.publishedDate, localeCode),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // ── Title ─────────────────────────────────────────────────────────
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
          const SizedBox(height: 6),
          // ── Description ───────────────────────────────────────────────────
          Expanded(
            child: Text(
              alert.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Footer: source tag ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rss_feed_rounded,
                      size: 9,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      alert.source,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, String localeCode) {
    if (date == null) return '';
    return DateFormat('MMM d', localeCode).format(date);
  }

  _RiskStyle _riskStyle(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return _RiskStyle(
          badgeBg: const Color(0xFFFCDAD7),
          badgeText: const Color(0xFF8C1D18),
        );
      case 'medium':
        return _RiskStyle(
          badgeBg: const Color(0xFFFFF0C5),
          badgeText: const Color(0xFF7A4F00),
        );
      default: // low
        return _RiskStyle(
          badgeBg: const Color(0xFFD7EDCA),
          badgeText: const Color(0xFF1A5E20),
        );
    }
  }
}

class _RiskStyle {
  final Color badgeBg;
  final Color badgeText;
  const _RiskStyle({required this.badgeBg, required this.badgeText});
}

// ── Loading shimmer ──────────────────────────────────────────────────────────

class _LoadingShimmer extends StatefulWidget {
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

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
          separatorBuilder: (_, _) => const SizedBox(width: 10),
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
  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
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
          Icon(
            Icons.wifi_off_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(retryLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scamalert.dart';
import '../services/cybernews.dart';
import '../Widgets/scamalertsection.dart';

class ScamsPage extends StatefulWidget {
  const ScamsPage({super.key});

  @override
  State<ScamsPage> createState() => _ScamsPageState();
}

class _ScamsPageState extends State<ScamsPage> {
  final CyberNewsService _service = CyberNewsService();
  late Future<List<ScamAlert>> _futureAlerts;

  @override
  void initState() {
    super.initState();
    _futureAlerts = _service.fetchScamAlerts();
  }

  void _refresh() {
    setState(() {
      _futureAlerts = _service.fetchScamAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Recent Scam Alerts'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<ScamAlert>>(
        future: _futureAlerts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return const Center(child: Text('No scam alerts found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _ScamTile(alert: alert);
            },
          );
        },
      ),
    );
  }
}

class _ScamTile extends StatelessWidget {
  final ScamAlert alert;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          _showDetails(context, alert);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${alert.riskLevel} Risk',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(alert.publishedDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alert.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.source, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    alert.source,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showDetails(BuildContext context, ScamAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScamDetailsSheet(alert: alert),
    );
  }
}

class _ScamDetailsSheet extends StatelessWidget {
  final ScamAlert alert;

  const _ScamDetailsSheet({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            alert.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            alert.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'HOW TO PROTECT YOURSELF',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildTip(Icons.verified_user, 'Verify through official Govt. channels.'),
          _buildTip(Icons.link_off, 'Never click on suspicious links in SMS/WhatsApp.'),
          _buildTip(Icons.security, 'Report scams to 1930 (Cyber Crime Helpline).'),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

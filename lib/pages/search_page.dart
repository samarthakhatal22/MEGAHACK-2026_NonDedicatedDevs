import 'package:flutter/material.dart';
 
// ─── Models ───────────────────────────────────────────────────────────────────
 
enum PolicyStatus { active, draft, conflict, review }
 
class PolicyResult {
  final String title;
  final String ministry;
  final String date;
  final String excerpt;
  final int matchPercent;
  final PolicyStatus status;
  final int pages;
 
  const PolicyResult({
    required this.title,
    required this.ministry,
    required this.date,
    required this.excerpt,
    required this.matchPercent,
    required this.status,
    required this.pages,
  });
}
 
// ─── Dummy Data ────────────────────────────────────────────────────────────────
 
const List<PolicyResult> _allResults = [
  PolicyResult(
    title: 'Personal Data Protection Bill 2023',
    ministry: 'MeitY',
    date: 'Jan 2024',
    excerpt:
        'Grants citizens the right to access, correct, and erase their personal data. Data fiduciaries must ensure privacy by design and default.',
    matchPercent: 94,
    status: PolicyStatus.active,
    pages: 47,
  ),
  PolicyResult(
    title: 'Digital Personal Data Protection Rules 2024',
    ministry: 'MeitY',
    date: 'Mar 2024',
    excerpt:
        'Implementing regulations specifying consent notice formats, grievance redressal timelines, and data localisation requirements.',
    matchPercent: 81,
    status: PolicyStatus.draft,
    pages: 22,
  ),
  PolicyResult(
    title: 'IT Act Amendment — Section 43A',
    ministry: 'MeitY',
    date: '2011',
    excerpt:
        'Body corporate handling sensitive personal data must implement reasonable security practices and procedures.',
    matchPercent: 72,
    status: PolicyStatus.review,
    pages: 8,
  ),
  PolicyResult(
    title: 'Digital India Act 2024',
    ministry: 'MeitY',
    date: 'Jan 2024',
    excerpt:
        'Comprehensive framework governing digital infrastructure, cybersecurity obligations, and platform accountability in India.',
    matchPercent: 65,
    status: PolicyStatus.active,
    pages: 94,
  ),
  PolicyResult(
    title: 'NEP Amendment v3',
    ministry: 'MoE',
    date: 'Mar 2024',
    excerpt:
        'Amendments to the National Education Policy focusing on digital literacy, vocational training, and multilingual instruction.',
    matchPercent: 40,
    status: PolicyStatus.draft,
    pages: 31,
  ),
  PolicyResult(
    title: 'Green Hydrogen Mission Policy',
    ministry: 'MNRE',
    date: 'Apr 2024',
    excerpt:
        'National mission to develop green hydrogen as a clean energy source with production incentives and export targets.',
    matchPercent: 28,
    status: PolicyStatus.active,
    pages: 56,
  ),
];
 
const List<String> _ministries = [
  'All',
  'MeitY',
  'MoE',
  'MHA',
  'MNRE',
  'Finance',
];
 
const List<String> _years = ['All', '2024', '2023', '2022', '2021'];
 
const List<String> _statuses = ['All', 'Active', 'Draft', 'Conflict', 'Review'];
 
// ─── Search Page ───────────────────────────────────────────────────────────────
 
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
 
  @override
  State<SearchPage> createState() => _SearchPageState();
}
 
class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
 
  String _query = '';
  String _selectedMinistry = 'All';
  String _selectedYear = 'All';
  String _selectedStatus = 'All';
  bool _showFilters = false;
 
  List<PolicyResult> get _filteredResults {
    return _allResults.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.title.toLowerCase().contains(_query.toLowerCase()) ||
          p.ministry.toLowerCase().contains(_query.toLowerCase()) ||
          p.excerpt.toLowerCase().contains(_query.toLowerCase());
 
      final matchesMinistry =
          _selectedMinistry == 'All' || p.ministry == _selectedMinistry;
 
      final matchesYear =
          _selectedYear == 'All' || p.date.contains(_selectedYear);
 
      final matchesStatus = _selectedStatus == 'All' ||
          p.status.name.toLowerCase() == _selectedStatus.toLowerCase();
 
      return matchesQuery && matchesMinistry && matchesYear && matchesStatus;
    }).toList()
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final results = _filteredResults;
 
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            if (_showFilters) _buildFilterPanel(context),
            _buildResultsCount(context, results.length),
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildResultCard(context, results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── Search Header ────────────────────────────────────────────────────────────
 
  Widget _buildSearchHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search policies, acts, amendments…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 18, color: colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              Icons.tune,
              color: _showFilters ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _showFilters
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
 
  // ── Filter Panel ─────────────────────────────────────────────────────────────
 
  Widget _buildFilterPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(context, 'Ministry', _ministries, _selectedMinistry,
              (val) => setState(() => _selectedMinistry = val)),
          const SizedBox(height: 8),
          _buildFilterRow(context, 'Year', _years, _selectedYear,
              (val) => setState(() => _selectedYear = val)),
          const SizedBox(height: 8),
          _buildFilterRow(context, 'Status', _statuses, _selectedStatus,
              (val) => setState(() => _selectedStatus = val)),
          if (_selectedMinistry != 'All' ||
              _selectedYear != 'All' ||
              _selectedStatus != 'All') ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() {
                _selectedMinistry = 'All';
                _selectedYear = 'All';
                _selectedStatus = 'All';
              }),
              child: Text(
                'Clear all filters',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
 
  Widget _buildFilterRow(
    BuildContext context,
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = selected == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
 
  // ── Results Count ─────────────────────────────────────────────────────────────
 
  Widget _buildResultsCount(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text(
            '$count result${count != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (_query.isNotEmpty) ...[
            Text(
              ' for "$_query"',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Sorted by relevance',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
 
  // ── Result Card ───────────────────────────────────────────────────────────────
 
  Widget _buildResultCard(BuildContext context, PolicyResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusConfig = _getStatusConfig(result.status);
    final isHighMatch = result.matchPercent >= 80;
 
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isHighMatch ? colorScheme.primary : colorScheme.outlineVariant,
              width: isHighMatch ? 3 : 0.5,
            ),
            top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
            right: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    result.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMatchBadge(context, result.matchPercent),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              result.excerpt,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetaChip(
                  context,
                  result.ministry,
                  const Color(0xFFD3E4FD),
                  const Color(0xFF0D47A1),
                ),
                const SizedBox(width: 6),
                Text(
                  result.date,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${result.pages} pages',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(statusConfig),
              ],
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildMatchBadge(BuildContext context, int percent) {
    final colorScheme = Theme.of(context).colorScheme;
    Color bg;
    Color text;
 
    if (percent >= 80) {
      bg = const Color(0xFFD7EDCA);
      text = const Color(0xFF1A5E20);
    } else if (percent >= 60) {
      bg = const Color(0xFFFFF0C5);
      text = const Color(0xFF7A4F00);
    } else {
      bg = colorScheme.surfaceContainerHighest;
      text = colorScheme.onSurfaceVariant;
    }
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }
 
  Widget _buildMetaChip(
      BuildContext context, String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }
 
  Widget _buildStatusChip(_StatusConfig config) {
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
 
  // ── Empty State ───────────────────────────────────────────────────────────────
 
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try different keywords or clear filters',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _query = '';
                _selectedMinistry = 'All';
                _selectedYear = 'All';
                _selectedStatus = 'All';
              });
            },
            child: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
 
  // ── Status Config ─────────────────────────────────────────────────────────────
 
  _StatusConfig _getStatusConfig(PolicyStatus status) {
    switch (status) {
      case PolicyStatus.active:
        return _StatusConfig(
          label: 'Active',
          chipBg: const Color(0xFFD7EDCA),
          chipText: const Color(0xFF1A5E20),
        );
      case PolicyStatus.draft:
        return _StatusConfig(
          label: 'Draft',
          chipBg: const Color(0xFFFFF0C5),
          chipText: const Color(0xFF7A4F00),
        );
      case PolicyStatus.conflict:
        return _StatusConfig(
          label: 'Conflict',
          chipBg: const Color(0xFFFCDAD7),
          chipText: const Color(0xFF8C1D18),
        );
      case PolicyStatus.review:
        return _StatusConfig(
          label: 'Review',
          chipBg: const Color(0xFFD3E4FD),
          chipText: const Color(0xFF0D47A1),
        );
    }
  }
}
 
class _StatusConfig {
  final String label;
  final Color chipBg;
  final Color chipText;
 
  _StatusConfig({
    required this.label,
    required this.chipBg,
    required this.chipText,
  });
}
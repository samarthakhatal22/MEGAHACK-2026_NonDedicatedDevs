import 'package:flutter/material.dart';
import 'dart:async';
import '../services/search_service.dart' as search_service;

// ─── Search Page ───────────────────────────────────────────────────────────────

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final search_service.SearchService _searchService = search_service.SearchService();

  String _query = '';
  String _selectedMinistry = 'All';
  String _selectedYear = 'All';
  String _selectedStatus = 'All';
  bool _showFilters = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  List<search_service.PolicyResult> _apiResults = [];

  // ── Filters ───────────────────────────────────────────────────────────────
  final List<String> _ministries = [
    'All',
    'MeitY',
    'MoE',
    'MHA',
    'MNRE',
    'Finance',
  ];

  final List<String> _years = ['All', '2024', '2023', '2022', '2021'];
  final List<String> _statuses = ['All', 'Active', 'Draft', 'Conflict', 'Review'];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _errorMessage = null;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runPolicySearch);
  }

  Future<void> _runPolicySearch() async {
    final q = _query.trim();
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _apiResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchPolicies(
        query: q,
        ministry: _selectedMinistry,
        status: _selectedStatus,
        year: _selectedYear,
      );

      if (!mounted) return;
      setState(() {
        _apiResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiResults = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<search_service.PolicyResult> get _filteredResults {
    return _apiResults.where((p) {
      final matchesMinistry =
          _selectedMinistry == 'All' || p.ministry == _selectedMinistry;

      final matchesYear =
          _selectedYear == 'All' || p.date.contains(_selectedYear);

      final matchesStatus =
          _selectedStatus == 'All' || p.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesMinistry && matchesYear && matchesStatus;
    }).toList();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
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
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search policies, acts, amendments…',
                  prefixIcon:
                      Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 18, color: colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onQueryChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(Icons.tune,
                color: _showFilters ? colorScheme.primary : colorScheme.onSurfaceVariant),
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
          _buildFilterRow('Ministry', _ministries, _selectedMinistry,
              (val) => setState(() => _selectedMinistry = val)),
          const SizedBox(height: 8),
          _buildFilterRow('Year', _years, _selectedYear,
              (val) => setState(() => _selectedYear = val)),
          const SizedBox(height: 8),
          _buildFilterRow('Status', _statuses, _selectedStatus,
              (val) => setState(() => _selectedStatus = val)),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
      String label, List<String> options, String selected, ValueChanged<String> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected ? colorScheme.primary : colorScheme.outline,
                            width: isSelected ? 1.2 : 0.8),
                      ),
                      child: Text(option,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant)),
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
          Text('$count result${count != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          if (_query.isNotEmpty) ...[
            Text(' for "$_query"',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  // ── Result Card ───────────────────────────────────────────────────────────────
  Widget _buildResultCard(BuildContext context, search_service.PolicyResult result) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _buildFullNewsPopup(context, result),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(result.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(result.ministry, style: TextStyle(fontSize: 11)),
              const SizedBox(width: 10),
              Text(result.date, style: TextStyle(fontSize: 11)),
              const Spacer(),
              Text('${result.pages} pages', style: TextStyle(fontSize: 11)),
            ],
          )
        ],
      ),
    ));
  }

  Widget _buildFullNewsPopup(BuildContext context, search_service.PolicyResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Policy Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.account_balance_outlined, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(result.ministry, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(result.date, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    result.excerpt,
                    style: TextStyle(fontSize: 15, height: 1.6, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasApiError = (_errorMessage ?? '').isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            hasApiError ? 'Search request failed' : 'No results found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            hasApiError ? (_errorMessage ?? 'Unknown error') : 'Try different keywords or clear filters',
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
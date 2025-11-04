import 'package:flutter/material.dart';

enum SearchFilterType {
  all,
  quotations,
  invoices,
  companies,
  clients,
}

class SearchFilterBar extends StatefulWidget {
  final Function(String query, SearchFilterType filter) onSearch;
  final String hintText;

  const SearchFilterBar({
    super.key,
    required this.onSearch,
    this.hintText = 'Search...',
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilterType _selectedFilter = SearchFilterType.all;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => _performSearch(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'Toggle filters',
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SearchFilterType.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                      _performSearch();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  void _performSearch() {
    widget.onSearch(_searchController.text.trim(), _selectedFilter);
  }

  String _getFilterLabel(SearchFilterType filter) {
    switch (filter) {
      case SearchFilterType.all:
        return 'All';
      case SearchFilterType.quotations:
        return 'Quotations';
      case SearchFilterType.invoices:
        return 'Invoices';
      case SearchFilterType.companies:
        return 'Companies';
      case SearchFilterType.clients:
        return 'Clients';
    }
  }
}

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final VoidCallback onTap;

  SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.onTap,
  });
}

class SearchResultsList extends StatelessWidget {
  final List<SearchResultItem> results;
  final bool isLoading;
  final String emptyMessage;

  const SearchResultsList({
    super.key,
    required this.results,
    this.isLoading = false,
    this.emptyMessage = 'No results found',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(result.icon),
            title: Text(result.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.subtitle),
                Text(
                  result.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onTap: result.onTap,
          ),
        );
      },
    );
  }
}
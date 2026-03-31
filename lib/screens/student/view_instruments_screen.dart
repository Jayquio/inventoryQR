// lib/screens/student/view_instruments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/instrument_card.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class ViewInstrumentsScreen extends StatefulWidget {
  final String userRole;

  const ViewInstrumentsScreen({super.key, this.userRole = 'Student'});

  @override
  State<ViewInstrumentsScreen> createState() => _ViewInstrumentsScreenState();
}

class _ViewInstrumentsScreenState extends State<ViewInstrumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _page = 0;
  final int _perPage = 6;
  List<Instrument> _instruments = [];
  bool _loading = true;
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiClient.instance.fetchInstruments();
      if (!context.mounted) return;
      setState(() {
        _instruments = items;
        _loading = false;
      });
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showInstrumentDetails(BuildContext context, instrument) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstrumentHeader(instrument),
            const SizedBox(height: 12),
            _buildInstrumentDetailsList(instrument),
            const SizedBox(height: 12),
            _buildActionButtons(context, instrument),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentHeader(instrument) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: const Icon(Icons.science, color: Colors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            instrument.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInstrumentDetailsList(instrument) {
    return Column(
      children: [
        _buildDetailRow('Category', instrument.category),
        _buildDetailRow('Available', '${instrument.available}/${instrument.quantity}'),
        _buildDetailRow('Status', instrument.status),
        _buildDetailRow('Condition', instrument.condition),
        _buildDetailRow('Location', instrument.location),
        _buildDetailRow('Last Maintenance', instrument.lastMaintenance),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, instrument) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _getOnPressedAction(context, instrument),
            icon: const Icon(Icons.assignment),
            label: Text(_getActionButtonLabel()),
          ),
        ),
      ],
    );
  }

  VoidCallback? _getOnPressedAction(BuildContext context, instrument) {
    final bool isUser = widget.userRole == 'Student' || widget.userRole == 'Teacher';
    final bool isAdmin = widget.userRole == 'Admin';

    if (isUser) {
      if (instrument.available > 0) {
        return () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/submit_request', arguments: instrument.name);
        };
      }
      return null;
    }

    if (isAdmin) {
      return () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/log_maintenance', arguments: instrument.name);
      };
    }

    return null;
  }

  String _getActionButtonLabel() {
    final bool isUser = widget.userRole == 'Student' || widget.userRole == 'Teacher';
    final bool isAdmin = widget.userRole == 'Admin';

    if (isUser) return 'Request This';
    if (isAdmin) return 'Log Maintenance';
    return 'Update';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: R.text(18, w), fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: R.text(10, w)),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final searchTerm = _searchController.text.toLowerCase();
    
    final totalInstruments = _instruments.length;
    final availableInstruments = _instruments.where((i) => i.available > 0).length;
    final categories = _instruments.map((i) => i.category).toSet().length;

    final filteredInstruments = _instruments.where((instrument) {
      if (_typeFilter != 'All' && instrument.type.toLowerCase() != _typeFilter.toLowerCase()) return false;
      if (searchTerm.isEmpty) return true;
      return instrument.name.toLowerCase().contains(searchTerm) ||
          instrument.category.toLowerCase().contains(searchTerm) ||
          instrument.status.toLowerCase().contains(searchTerm) ||
          instrument.condition.toLowerCase().contains(searchTerm) ||
          instrument.location.toLowerCase().contains(searchTerm);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Instruments')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          // Quick Overview Container
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Total', totalInstruments.toString(), Icons.inventory_2_outlined),
                _buildStatDivider(),
                _buildStatItem(context, 'Available', availableInstruments.toString(), Icons.check_circle_outline),
                _buildStatDivider(),
                _buildStatItem(context, 'Categories', categories.toString(), Icons.category_outlined),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DebouncedSearchBar(
                    controller: _searchController,
                    hintText: 'Search instruments...',
                    onChanged: (value) => setState(() {
                      _page = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _typeFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Types')),
                    DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
                    DropdownMenuItem(value: 'reagent', child: Text('Reagent')),
                  ],
                  onChanged: (v) => setState(() {
                    _typeFilter = v ?? 'All';
                    _page = 0;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: LayoutBuilder(
                key: ValueKey('${_searchController.text}_$_page'),
                builder: (context, constraints) {
                  final int crossAxisCount = R.columns(constraints.maxWidth, xs: 2, sm: 3, md: 4, lg: 5);
                  final double spacing = 6.0;
                  final double totalPadding = 32.0; // 16 * 2
                  final double itemWidth = (constraints.maxWidth - totalPadding - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                  
                  // Ultra-compact height calculation:
                  // Image (16:9 aspect) -> itemWidth / 1.77
                  // Title + Status + Pills + Spacing
                  // 14 (Title) + 12 (Status) + 18 (Pills) + 12 (Spacings) + 8 (Internal Padding)
                  const double fixedContentHeight = 64;
                  final double cellHeight = (itemWidth / 1.77) + fixedContentHeight;
                  final double childAspectRatio = (itemWidth / cellHeight).clamp(0.5, 1.0);

                  final totalPages = (filteredInstruments.length / _perPage).ceil();
                  final start = (_page * _perPage).clamp(0, filteredInstruments.length);
                  final end = (start + _perPage).clamp(0, filteredInstruments.length);
                  final pageItems = filteredInstruments.sublist(start, end);

                  if (pageItems.isEmpty) {
                    return const Center(child: Text('No instruments found'));
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: pageItems.length,
                          itemBuilder: (context, index) {
                            return InstrumentCard(
                              instrument: pageItems[index],
                              highlight: _searchController.text,
                              onTap: () => _showInstrumentDetails(context, pageItems[index]),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Page ${_page + 1} of ${totalPages == 0 ? 1 : totalPages}',
                              style: TextStyle(fontSize: R.text(12, w)),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _page > 0 ? () => setState(() => _page--) : null,
                              child: const Text('Prev'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

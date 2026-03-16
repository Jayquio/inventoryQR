// lib/screens/admin/manage_instruments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/instrument_card.dart';
import '../../core/constants.dart';

class ManageInstrumentsScreen extends StatefulWidget {
  const ManageInstrumentsScreen({super.key});

  @override
  State<ManageInstrumentsScreen> createState() => _ManageInstrumentsScreenState();
}

class _ManageInstrumentsScreenState extends State<ManageInstrumentsScreen> {
  late List<Instrument> _instruments;
  final TextEditingController _searchController = TextEditingController();
  int _page = 0;
  final int _perPage = 6;
  bool _loading = true;
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _instruments = [];
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _instruments = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showInstrumentDetails(BuildContext context, Instrument instrument, int index) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Category', instrument.category),
            _buildDetailRow('Quantity', instrument.quantity.toString()),
            _buildDetailRow('Available', instrument.available.toString()),
            _buildDetailRow('Borrowed', (instrument.quantity - instrument.available).toString()),
            _buildDetailRow('Status', instrument.status),
            _buildDetailRow('Condition', instrument.condition),
            _buildDetailRow('Location', instrument.location),
            _buildDetailRow('Last Maintenance', instrument.lastMaintenance),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final spacing = 8.0;
                final w = constraints.maxWidth;
                final cols = w < 480 ? 2 : 3;
                final bw = ((w - (spacing * (cols - 1))) / cols).clamp(160.0, w);
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: bw,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _editInstrument(index);
                        },
                        child: const Text(
                          'Update',
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: bw,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/qr_generator',
                            arguments: {'userRole': 'Teacher', 'preSelectedInstrument': instrument.name},
                          );
                        },
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text(
                          'Generate QR',
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: bw,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/qr_scanner', arguments: 'Teacher');
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(
                          'Return QR',
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
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
 
  void _editInstrument(int index) {
    final instrument = _instruments[index];
    showDialog(
      context: context,
      builder: (context) {
        String typeValue = instrument.type;
        final nameController = TextEditingController(text: instrument.name);
        final categoryController = TextEditingController(text: instrument.category);
        final quantityController = TextEditingController(text: instrument.quantity.toString());
        final availableController = TextEditingController(text: instrument.available.toString());
        final statusController = TextEditingController(text: instrument.status);
        final conditionController = TextEditingController(text: instrument.condition);
        final locationController = TextEditingController(text: instrument.location);
        final lastMaintenanceController = TextEditingController(text: instrument.lastMaintenance);
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Update Instrument'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: typeValue,
                    items: const [
                      DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
                      DropdownMenuItem(value: 'reagent', child: Text('Reagent')),
                    ],
                    onChanged: (v) => setStateDialog(() => typeValue = v ?? 'instrument'),
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                  TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                  TextField(controller: availableController, decoration: const InputDecoration(labelText: 'Available'), keyboardType: TextInputType.number),
                  TextField(controller: statusController, decoration: const InputDecoration(labelText: 'Status')),
                  TextField(controller: conditionController, decoration: const InputDecoration(labelText: 'Condition')),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                  TextField(controller: lastMaintenanceController, decoration: const InputDecoration(labelText: 'Last Maintenance')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final qty = int.tryParse(quantityController.text) ?? -1;
                        final avail = int.tryParse(availableController.text) ?? -1;
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                          return;
                        }
                        if (qty < 0 || avail < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity and Available must be valid numbers')));
                          return;
                        }
                        if (avail > qty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Available cannot exceed Quantity')));
                          return;
                        }
                        setStateDialog(() => submitting = true);
                        try {
                          final updated = Instrument(
                            type: typeValue,
                            name: nameController.text.trim(),
                            category: categoryController.text.trim(),
                            quantity: qty,
                            available: avail,
                            status: statusController.text.trim(),
                            condition: conditionController.text.trim(),
                            location: locationController.text.trim(),
                            lastMaintenance: lastMaintenanceController.text.trim(),
                          );
                          await ApiClient.instance.updateInstrument(originalName: instrument.name, instrument: updated);
                          if (!mounted) return;
                          setState(() {
                            _instruments[index] = updated;
                          });
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Instrument updated in database')),
                          );
                        } catch (e) {
                          setStateDialog(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }
  void _addInstrument() {
    showDialog(
      context: context,
      builder: (context) {
        String typeValue = 'instrument';
        final nameController = TextEditingController();
        final categoryController = TextEditingController();
        final quantityController = TextEditingController();
        final availableController = TextEditingController();
        final statusController = TextEditingController();
        final conditionController = TextEditingController();
        final locationController = TextEditingController();
        final lastMaintenanceController = TextEditingController();

        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Add Instrument'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: typeValue,
                    items: const [
                      DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
                      DropdownMenuItem(value: 'reagent', child: Text('Reagent')),
                    ],
                    onChanged: (v) => setStateDialog(() => typeValue = v ?? 'instrument'),
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                  TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                  TextField(controller: availableController, decoration: const InputDecoration(labelText: 'Available'), keyboardType: TextInputType.number),
                  TextField(controller: statusController, decoration: const InputDecoration(labelText: 'Status')),
                  TextField(controller: conditionController, decoration: const InputDecoration(labelText: 'Condition')),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                  TextField(controller: lastMaintenanceController, decoration: const InputDecoration(labelText: 'Last Maintenance')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final qty = int.tryParse(quantityController.text) ?? -1;
                        final avail = int.tryParse(availableController.text) ?? -1;
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                          return;
                        }
                        if (qty < 0 || avail < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity and Available must be valid numbers')));
                          return;
                        }
                        if (avail > qty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Available cannot exceed Quantity')));
                          return;
                        }
                        setStateDialog(() => submitting = true);
                        try {
                          final newInstrument = Instrument(
                            type: typeValue,
                            name: nameController.text.trim(),
                            category: categoryController.text.trim(),
                            quantity: qty,
                            available: avail,
                            status: statusController.text.trim(),
                            condition: conditionController.text.trim(),
                            location: locationController.text.trim(),
                            lastMaintenance: lastMaintenanceController.text.trim(),
                          );
                          await ApiClient.instance.createInstrument(instrument: newInstrument);
                          if (!mounted) return;
                          setState(() {
                            _instruments.add(newInstrument);
                          });
                          if (context.mounted) Navigator.pop(context);
                          // Prompt to generate QR after successful add
                          Future.microtask(() {
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Generate QR for new item?'),
                                content: Text('Create QR labels for "${newInstrument.name}" now?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pushNamed(
                                        context,
                                        '/qr_generator',
                                        arguments: {
                                          'userRole': 'Teacher',
                                          'preSelectedInstrument': newInstrument.name
                                        },
                                      );
                                    },
                                    child: const Text('Generate'),
                                  ),
                                ],
                              ),
                            );
                          });
                        } catch (e) {
                          setStateDialog(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
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
      if (_typeFilter != 'All' && instrument.type.toLowerCase() != _typeFilter.toLowerCase()) {
        return false;
      }
      if (searchTerm.isEmpty) return true;
      return instrument.name.toLowerCase().contains(searchTerm) ||
          instrument.category.toLowerCase().contains(searchTerm) ||
          instrument.status.toLowerCase().contains(searchTerm) ||
          instrument.condition.toLowerCase().contains(searchTerm) ||
          instrument.location.toLowerCase().contains(searchTerm);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Instruments"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/qr_scanner', arguments: 'Teacher');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
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
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addInstrument,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
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
                  const double spacing = 6.0;
                  const double totalPadding = 32.0;
                  final double itemWidth =
                      (constraints.maxWidth - totalPadding - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                  const double fixedContentHeight = 64;
                  final double cellHeight = (itemWidth / 1.77) + fixedContentHeight;
                  final double childAspectRatio = (itemWidth / cellHeight).clamp(0.5, 1.0);

                  final totalPages = (filteredInstruments.length / _perPage).ceil();
                  final start = (_page * _perPage).clamp(0, filteredInstruments.length);
                  final end = (start + _perPage).clamp(0, filteredInstruments.length);
                  final pageItems = filteredInstruments.sublist(start, end);

                  if (pageItems.isEmpty) {
                    return const Center(child: Text('No instruments found.'));
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
                            final instrument = pageItems[index];
                            final originalIndex = _instruments.indexOf(instrument);
                            return InstrumentCard(
                              instrument: instrument,
                              highlight: _searchController.text,
                              onTap: () => _showInstrumentDetails(context, instrument, originalIndex),
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
                              onPressed: _page > 0
                                  ? () => setState(() {
                                        _page--;
                                      })
                                  : null,
                              child: const Text('Prev'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _page < totalPages - 1
                                  ? () => setState(() {
                                        _page++;
                                      })
                                  : null,
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

 

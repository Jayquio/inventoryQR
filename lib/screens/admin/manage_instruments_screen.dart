// lib/screens/admin/manage_instruments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../widgets/role_guard.dart';
import '../../data/auth_service.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/instrument_card.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class ManageInstrumentsScreen extends StatefulWidget {
  const ManageInstrumentsScreen({super.key});

  @override
  State<ManageInstrumentsScreen> createState() => _ManageInstrumentsScreenState();
}

class _ManageInstrumentsScreenState extends State<ManageInstrumentsScreen> {
  static const String _exceptionPrefix = 'Exception: ';
  static const String _lastMaintenanceLabel = 'Last Maintenance';

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
      if (!context.mounted) return;
      setState(() {
        _instruments = items;
        _loading = false;
      });
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
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
            _buildInstrumentHeader(instrument),
            const SizedBox(height: 16),
            _buildInstrumentDetailsList(instrument),
            const SizedBox(height: 16),
            _buildActionButtons(context, instrument, index),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentHeader(Instrument instrument) {
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

  Widget _buildInstrumentDetailsList(Instrument instrument) {
    return Column(
      children: [
        _buildDetailRow('Category', instrument.category),
        _buildDetailRow('Quantity', instrument.quantity.toString()),
        _buildDetailRow('Available', instrument.available.toString()),
        _buildDetailRow('Borrowed', (instrument.quantity - instrument.available).toString()),
        _buildDetailRow('Status', instrument.status),
        _buildDetailRow('Condition', instrument.condition),
        _buildDetailRow('Location', instrument.location),
        _buildDetailRow(_lastMaintenanceLabel, instrument.lastMaintenance),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Instrument instrument, int index) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const spacing = 8.0;
        final w = constraints.maxWidth;
        final cols = w < 480 ? 2 : 3;
        final bw = ((w - (spacing * (cols - 1))) / cols).clamp(160.0, w);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: [
            _buildUpdateButton(context, index, bw),
            _buildQrButton(context, instrument, bw),
            _buildReturnButton(context, instrument, index, bw),
          ],
        );
      },
    );
  }

  Widget _buildUpdateButton(BuildContext context, int index, double width) {
    return SizedBox(
      width: width,
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
    );
  }

  Widget _buildQrButton(BuildContext context, Instrument instrument, double width) {
    return SizedBox(
      width: width,
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
    );
  }

  Widget _buildReturnButton(BuildContext context, Instrument instrument, int index, double width) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: instrument.available < instrument.quantity
            ? () async {
                try {
                  final newAvail = await ApiClient.instance.processTransaction(
                    type: 'return',
                    instrumentName: instrument.name,
                    processedBy: AuthService.instance.currentUsername,
                  );
                  if (!context.mounted) return;
                  if (newAvail != null) {
                    setState(() {
                      _instruments[index].available = newAvail;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully returned 1 unit of ${instrument.name}')),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            : null,
        icon: const Icon(Icons.keyboard_return),
        label: const Text(
          'Manual Return',
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
    _showInstrumentForm(instrument: _instruments[index], index: index);
  }

  void _addInstrument() {
    _showInstrumentForm();
  }

  void _showInstrumentForm({Instrument? instrument, int? index}) {
    final bool isEdit = instrument != null && index != null;
    final controllers = _InstrumentFormControllers(instrument: instrument);
    String typeValue = instrument?.type ?? 'instrument';

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(isEdit ? 'Update Instrument' : 'Add Instrument'),
            content: _InstrumentFormContent(
              typeValue: typeValue,
              controllers: controllers,
              onTypeChanged: (v) => setStateDialog(() => typeValue = v),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : () => _submitForm(
                  context: dialogContext,
                  isEdit: isEdit,
                  index: index,
                  originalName: instrument?.name,
                  typeValue: typeValue,
                  controllers: controllers,
                  setSubmitting: (v) => setStateDialog(() => submitting = v),
                ),
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm({
    required BuildContext context,
    required bool isEdit,
    int? index,
    String? originalName,
    required String typeValue,
    required _InstrumentFormControllers controllers,
    required Function(bool) setSubmitting,
  }) async {
    final qty = int.tryParse(controllers.quantity.text) ?? -1;
    final avail = int.tryParse(controllers.available.text) ?? -1;

    if (!_validateForm(context, controllers.name.text, qty, avail)) return;

    setSubmitting(true);
    try {
      final item = _createInstrumentFromControllers(typeValue, controllers, qty, avail);

      if (isEdit) {
        await ApiClient.instance.updateInstrument(originalName: originalName!, instrument: item);
        if (context.mounted) setState(() => _instruments[index!] = item);
      } else {
        await ApiClient.instance.createInstrument(instrument: item);
        if (context.mounted) setState(() => _instruments.add(item));
      }

      if (context.mounted) {
        _onSuccess(context, isEdit, item);
      }
    } catch (e) {
      if (context.mounted) {
        _onError(context, e);
      }
    } finally {
      if (context.mounted) setSubmitting(false);
    }
  }

  void _onSuccess(BuildContext context, bool isEdit, Instrument item) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Instrument updated' : 'Instrument added')),
    );
    if (!isEdit) _showQrDialog(context, item.name);
  }

  void _onError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
    );
  }

  bool _validateForm(BuildContext context, String name, int qty, int avail) {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return false;
    }
    if (qty < 0 || avail < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity and Available must be valid numbers')));
      return false;
    }
    if (avail > qty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Available cannot exceed Quantity')));
      return false;
    }
    return true;
  }

  Instrument _createInstrumentFromControllers(String type, _InstrumentFormControllers controllers, int qty, int avail) {
    return Instrument(
      type: type,
      name: controllers.name.text.trim(),
      category: controllers.category.text.trim(),
      quantity: qty,
      available: avail,
      status: controllers.status.text.trim(),
      condition: controllers.condition.text.trim(),
      location: controllers.location.text.trim(),
      lastMaintenance: controllers.lastMaintenance.text.trim(),
    );
  }

  void _showQrDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate QR?'),
        content: Text('Create QR labels for "$name" now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/qr_generator', arguments: {
                'userRole': 'Teacher',
                'preSelectedInstrument': name
              });
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.toLowerCase();
    final filteredInstruments = _getFilteredInstruments(searchTerm);

    return RoleGuard(
      allowed: const {UserRole.admin, UserRole.superadmin},
      webOnly: true,
      child: Scaffold(
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
            _buildStatsRow(),
            _buildSearchFilterBar(),
            Expanded(
              child: _buildInstrumentList(filteredInstruments),
            ),
          ],
        ),
      ),
    );
  }

  List<Instrument> _getFilteredInstruments(String searchTerm) {
    return _instruments.where((instrument) {
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
  }

  Widget _buildStatsRow() {
    final totalInstruments = _instruments.length;
    final availableInstruments = _instruments.where((i) => i.available > 0).length;
    final categories = _instruments.map((i) => i.category).toSet().length;

    return Container(
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
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
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
    );
  }

  Widget _buildInstrumentList(List<Instrument> filteredInstruments) {
    return AnimatedSwitcher(
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
              _buildPagination(totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
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
    );
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _InstrumentFormControllers {
  final TextEditingController name;
  final TextEditingController category;
  final TextEditingController quantity;
  final TextEditingController available;
  final TextEditingController status;
  final TextEditingController condition;
  final TextEditingController location;
  final TextEditingController lastMaintenance;

  _InstrumentFormControllers({Instrument? instrument})
      : name = TextEditingController(text: instrument?.name ?? ''),
        category = TextEditingController(text: instrument?.category ?? ''),
        quantity = TextEditingController(text: instrument?.quantity.toString() ?? ''),
        available = TextEditingController(text: instrument?.available.toString() ?? ''),
        status = TextEditingController(text: instrument?.status ?? ''),
        condition = TextEditingController(text: instrument?.condition ?? ''),
        location = TextEditingController(text: instrument?.location ?? ''),
        lastMaintenance = TextEditingController(text: instrument?.lastMaintenance ?? '');
}

class _InstrumentFormContent extends StatelessWidget {
  final String typeValue;
  final _InstrumentFormControllers controllers;
  final Function(String) onTypeChanged;

  const _InstrumentFormContent({
    required this.typeValue,
    required this.controllers,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: typeValue,
            items: const [
              DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
              DropdownMenuItem(value: 'reagent', child: Text('Reagent')),
            ],
            onChanged: (v) => onTypeChanged(v ?? 'instrument'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          TextField(controller: controllers.name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: controllers.category, decoration: const InputDecoration(labelText: 'Category')),
          TextField(
            controller: controllers.quantity,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: controllers.available,
            decoration: const InputDecoration(labelText: 'Available'),
            keyboardType: TextInputType.number,
          ),
          TextField(controller: controllers.status, decoration: const InputDecoration(labelText: 'Status')),
          TextField(controller: controllers.condition, decoration: const InputDecoration(labelText: 'Condition')),
          TextField(controller: controllers.location, decoration: const InputDecoration(labelText: 'Location')),
          TextField(
            controller: controllers.lastMaintenance,
            decoration: const InputDecoration(labelText: _ManageInstrumentsScreenState._lastMaintenanceLabel),
          ),
        ],
      ),
    );
  }
}

 

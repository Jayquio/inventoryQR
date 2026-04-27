// lib/screens/admin/manage_instruments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../widgets/role_guard.dart';
import '../../data/auth_service.dart';
import '../../widgets/search_bar.dart';
import '../../core/theme.dart';
import 'dart:math' as math; // Import for random number generation

class ManageInstrumentsScreen extends StatefulWidget {
  const ManageInstrumentsScreen({super.key});

  @override
  State<ManageInstrumentsScreen> createState() =>
      _ManageInstrumentsScreenState();
}

class _ManageInstrumentsScreenState extends State<ManageInstrumentsScreen> {
  static const String _exceptionPrefix = 'Exception: ';
  static const String _lastMaintenanceLabel = 'Last Maintenance';
  static const String _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'; // For random serial generation

  late List<Instrument> _instruments;
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String _typeFilter = 'All';
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _instruments = [];
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiClient.instance.fetchInstruments();
      int pending = 0;
      try {
        final requests = await ApiClient.instance.fetchRequests();
        pending = requests
            .where(
              (r) => (r['status'] ?? '').toString().toLowerCase() == 'pending',
            )
            .length;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _instruments = items;
        _pendingRequests = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(_exceptionPrefix, '')),
        ),
      );
    }
  }

  String _generateSerialNumber(String instrumentType) {
    final prefix = instrumentType.substring(0, 3).toUpperCase();
    final random = math.Random();
    final suffix = List.generate(
      6,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
    return '$prefix-$suffix';
  }

  void _showInstrumentDetails(
    BuildContext context,
    Instrument instrument,
    int index,
  ) {
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
        if (instrument.serialNumber != null &&
            instrument.serialNumber!.isNotEmpty)
          _buildDetailRow('Serial Number', instrument.serialNumber!),
        _buildDetailRow('Quantity', instrument.quantity.toString()),
        _buildDetailRow('Available', instrument.available.toString()),
        _buildDetailRow(
          'Borrowed',
          (instrument.quantity - instrument.available).toString(),
        ),
        _buildDetailRow('Status', instrument.status),
        _buildDetailRow('Condition', instrument.condition),
        _buildDetailRow('Location', instrument.location),
        _buildDetailRow(_lastMaintenanceLabel, instrument.lastMaintenance),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Instrument instrument,
    int index,
  ) {
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
            _buildDeleteButton(context, instrument, index, bw),
          ],
        );
      },
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    Instrument instrument,
    int index,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: Colors.red,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          Navigator.pop(context);
          _confirmDelete(instrument, index);
        },
        icon: const Icon(Icons.delete_outline),
        label: const Text(
          'Remove',
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  void _confirmDelete(Instrument instrument, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Instrument?'),
        content: Text(
          'Are you sure you want to remove "${instrument.name}" from the inventory? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteInstrument(instrument, index);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInstrument(Instrument instrument, int index) async {
    try {
      await ApiClient.instance.deleteInstrument(name: instrument.name);
      if (!mounted) return;
      setState(() {
        _instruments.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${instrument.name}" removed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove instrument: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildQrButton(
    BuildContext context,
    Instrument instrument,
    double width,
  ) {
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
            arguments: {
              'userRole': 'Teacher',
              'preSelectedInstrument': instrument.name,
            },
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

  Future<void> _handleManualReturn(
    BuildContext context,
    Instrument instrument,
    int index,
  ) async {
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
        // Ensure widget is still mounted after popping bottom sheet context
        if (!mounted) return;
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Successfully returned 1 unit of ${instrument.name}'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildReturnButton(
    BuildContext context,
    Instrument instrument,
    int index,
    double width,
  ) {
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
            ? () => _handleManualReturn(context, instrument, index)
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 33 * 0.55,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13 * 0.85,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final t = type.toLowerCase();
    final isReagent = t == 'reagent';
    final isConsumable = t == 'consumable';
    final color = isReagent
        ? Colors.orange
        : (isConsumable ? Colors.purple : AppTheme.primaryColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isReagent ? 'Reagent' : (isConsumable ? 'Consumable' : 'Instrument'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final lower = status.toLowerCase();
    final color = switch (lower) {
      'available' => Colors.green,
      'in use' => Colors.amber.shade700,
      'under maintenance' => Colors.orange,
      'damaged' => Colors.red,
      'out of stock' => Colors.grey,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInstrumentImage(Instrument instrument) {
    final imagePath = instrument.imageAsset;
    if (imagePath != null && imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imagePath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildImageFallback(),
        ),
      );
    }
    return _buildImageFallback();
  }

  Widget _buildImageFallback() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildRowActions(Instrument instrument, int originalIndex) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: () => _editInstrument(originalIndex),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit'),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              _showInstrumentDetails(context, instrument, originalIndex),
          icon: const Icon(Icons.update, size: 16),
          label: const Text('Update'),
        ),
        TextButton.icon(
          onPressed: () => _confirmDelete(instrument, originalIndex),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
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
              setStateDialog: setStateDialog,
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () => _submitForm(
                        dialogContext: dialogContext,
                        isEdit: isEdit,
                        index: index,
                        originalName: instrument?.name,
                        typeValue: typeValue,
                        controllers: controllers,
                        setSubmitting: (v) =>
                            setStateDialog(() => submitting = v),
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
    required BuildContext dialogContext,
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
      final item = _createInstrumentFromControllers(
        typeValue,
        controllers,
        qty,
        avail,
      );
      await _persistInstrument(
        item: item,
        isEdit: isEdit,
        index: index,
        originalName: originalName,
      );
      if (!mounted || !dialogContext.mounted) return;
      _handleSubmitSuccess(
        item: item,
        isEdit: isEdit,
        dialogContext: dialogContext,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(_exceptionPrefix, '')),
        ),
      );
    } finally {
      if (dialogContext.mounted) setSubmitting(false);
    }
  }

  Future<void> _persistInstrument({
    required Instrument item,
    required bool isEdit,
    required int? index,
    required String? originalName,
  }) async {
    if (isEdit) {
      await ApiClient.instance.updateInstrument(
        originalName: originalName!,
        instrument: item,
      );
      if (!mounted) return;
      setState(() => _instruments[index!] = item);
      return;
    }

    await ApiClient.instance.createInstrument(instrument: item);
    if (!mounted) return;
    setState(() => _instruments.insert(0, item));
  }

  void _handleSubmitSuccess({
    required Instrument item,
    required bool isEdit,
    required BuildContext dialogContext,
  }) {
    if (!mounted) return;
    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit ? 'Instrument updated' : 'Instrument added'),
      ),
    );
    if (isEdit) return;
    _showGenerateQrPrompt(item.name);
  }

  void _showGenerateQrPrompt(String instrumentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate QR?'),
        content: Text('Create QR labels for "$instrumentName" now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                context,
                '/qr_generator',
                arguments: {
                  'userRole': 'Teacher',
                  'preSelectedInstrument': instrumentName,
                },
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  bool _validateForm(BuildContext context, String name, int qty, int avail) {
    if (name.trim().isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return false;
    }
    if (qty < 0 || avail < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity and Available must be valid numbers'),
        ),
      );
      return false;
    }
    if (avail > qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Available cannot exceed Quantity')),
      );
      return false;
    }
    return true;
  }

  Instrument _createInstrumentFromControllers(
    String type,
    _InstrumentFormControllers controllers,
    int qty,
    int avail,
  ) {
    final normalizedType = type.toLowerCase() == 'reagent'
        ? 'reagent'
        : 'instrument';
    String? finalSerialNumber;

    if (normalizedType == 'reagent') {
      finalSerialNumber = null; // Reagents don't use serial numbers
    } else if (controllers.autoGenerateSerialNumber ||
        controllers.serialNumber.text.trim().isEmpty) {
      // Generate if auto-generate is checked OR if field is empty (and not a reagent)
      finalSerialNumber = _generateSerialNumber(controllers.name.text.trim());
    } else {
      // Use manual input if provided and auto-generate is not checked
      finalSerialNumber = controllers.serialNumber.text.trim();
    }

    return Instrument(
      type: normalizedType,
      name: controllers.name.text.trim(),
      serialNumber: finalSerialNumber,
      category: normalizedType == 'reagent' ? 'Reagent' : 'Instrument',
      quantity: qty,
      available: avail,
      status: controllers.status.text.trim(),
      condition: controllers.condition.text.trim(),
      location: 'Central Lab',
      lastMaintenance: controllers.lastMaintenance.text.trim(),
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
                Navigator.pushNamed(
                  context,
                  '/qr_scanner',
                  arguments: 'Teacher',
                );
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
            Expanded(child: _buildInstrumentList(filteredInstruments)),
          ],
        ),
      ),
    );
  }

  List<Instrument> _getFilteredInstruments(String searchTerm) {
    return _instruments.where((instrument) {
      if (_typeFilter != 'All' &&
          instrument.type.toLowerCase() != _typeFilter.toLowerCase()) {
        return false;
      }
      if (searchTerm.isEmpty) return true;
      return instrument.name.toLowerCase().contains(searchTerm) ||
          (instrument.serialNumber?.toLowerCase().contains(searchTerm) ??
              false) ||
          instrument.category.toLowerCase().contains(searchTerm) ||
          instrument.status.toLowerCase().contains(searchTerm) ||
          instrument.condition.toLowerCase().contains(searchTerm) ||
          instrument.location.toLowerCase().contains(searchTerm);
    }).toList();
  }

  Widget _buildStatsRow() {
    final totalInstruments = _instruments.fold<int>(
      0,
      (sum, i) => sum + i.quantity,
    );
    final availableInstruments = _instruments.fold<int>(
      0,
      (sum, i) => sum + i.available,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.inventory_2_outlined,
            value: totalInstruments.toString(),
            label: 'Total Items',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle_outline,
            value: availableInstruments.toString(),
            label: 'Available',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.pending_actions_outlined,
            value: _pendingRequests.toString(),
            label: 'Pending',
            color: const Color(0xFFF59E0B),
          ),
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
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _typeFilter,
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list, size: 20),
            items: const [
              DropdownMenuItem(
                value: 'All',
                child: Text('Instruments and Reagent'),
              ),
              DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
              DropdownMenuItem(value: 'reagent', child: Text('Reagent')),
              DropdownMenuItem(value: 'consumable', child: Text('Consumable')),
            ],
            onChanged: (v) => setState(() => _typeFilter = v ?? 'All'),
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
    if (filteredInstruments.isEmpty) {
      return const Center(child: Text('No instruments found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: filteredInstruments.length,
      itemBuilder: (context, index) {
        final instrument = filteredInstruments[index];
        final originalIndex = _instruments.indexOf(instrument);
        final borrowed = (instrument.quantity - instrument.available).clamp(
          0,
          instrument.quantity,
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                _showInstrumentDetails(context, instrument, originalIndex),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstrumentImage(instrument),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                instrument.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTypeBadge(instrument.type),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Category: ${instrument.category}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              'Qty: ${instrument.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              'Available: ${instrument.available}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              'Borrowed: $borrowed',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(instrument.status),
                        const SizedBox(height: 8),
                        _buildRowActions(instrument, originalIndex),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  final TextEditingController serialNumber;
  final TextEditingController category;
  final TextEditingController quantity;
  final TextEditingController available;
  final TextEditingController status;
  final TextEditingController condition;
  final TextEditingController location;
  final TextEditingController lastMaintenance;
  bool autoGenerateSerialNumber; // New field

  _InstrumentFormControllers({Instrument? instrument})
    : name = TextEditingController(text: instrument?.name ?? ''),
      serialNumber = TextEditingController(
        text: instrument?.serialNumber ?? '',
      ),
      category = TextEditingController(text: instrument?.category ?? ''),
      quantity = TextEditingController(
        text: instrument?.quantity.toString() ?? '',
      ),
      available = TextEditingController(
        text: instrument?.available.toString() ?? '',
      ),
      status = TextEditingController(text: instrument?.status ?? ''),
      condition = TextEditingController(text: instrument?.condition ?? ''),
      location = TextEditingController(text: instrument?.location ?? ''),
      lastMaintenance = TextEditingController(
        text: instrument?.lastMaintenance ?? '',
      ),
      autoGenerateSerialNumber =
          instrument?.serialNumber == null ||
          instrument!.serialNumber!.isEmpty; // Default to true if no serial
}

class _InstrumentFormContent extends StatelessWidget {
  final String typeValue;
  final _InstrumentFormControllers controllers;
  final Function(String) onTypeChanged;
  final StateSetter setStateDialog;

  const _InstrumentFormContent({
    required this.typeValue,
    required this.controllers,
    required this.onTypeChanged,
    required this.setStateDialog,
  });

  static const List<String> _categoryOptions = [
    'Glassware',
    'Measuring',
    'Heating',
    'Microscopy',
    'Safety',
    'Chemicals',
    'Biology',
    'Physics',
    'Other',
  ];

  static const List<String> _statusOptions = [
    'Available',
    'In Use',
    'Under Maintenance',
    'Out of Stock',
    'Damaged',
  ];

  static const List<String> _conditionOptions = [
    'New',
    'Good',
    'Fair',
    'Needs Repair',
    'Unserviceable',
  ];

  List<String> _optionsWithCurrent(List<String> options, String current) {
    final normalizedCurrent = current.trim();
    if (normalizedCurrent.isEmpty || options.contains(normalizedCurrent)) {
      return options;
    }
    return [normalizedCurrent, ...options];
  }

  @override
  Widget build(BuildContext context) {
    final t = typeValue.toLowerCase();
    final isNoSerialType = t == 'reagent' || t == 'consumable';
    final categoryOptions = _optionsWithCurrent(
      _categoryOptions,
      controllers.category.text,
    );
    final statusOptions = _optionsWithCurrent(
      _statusOptions,
      controllers.status.text,
    );
    final conditionOptions = _optionsWithCurrent(
      _conditionOptions,
      controllers.condition.text,
    );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: typeValue,
            items: const [
              DropdownMenuItem(value: 'instrument', child: Text('Instrument')),
              DropdownMenuItem(value: 'reagent', child: Text('Reagent')),
              DropdownMenuItem(value: 'consumable', child: Text('Consumable')),
            ],
            onChanged: (v) => onTypeChanged(v ?? 'instrument'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          TextField(
            controller: controllers.name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          // Auto-generate checkbox
          Row(
            children: [
              Checkbox(
                value: controllers.autoGenerateSerialNumber,
                onChanged: (bool? value) {
                  setStateDialog(() {
                    controllers.autoGenerateSerialNumber = value ?? false;
                    if (controllers.autoGenerateSerialNumber) {
                      controllers.serialNumber
                          .clear(); // Clear manual input if auto-generating
                    }
                  });
                },
              ),
              const Text('Auto-generate Serial Number'),
            ],
          ),
          // Serial Number input field, enabled only if not auto-generating
          TextField(
            controller: controllers.serialNumber,
            enabled: !isNoSerialType && !controllers.autoGenerateSerialNumber,
            decoration: InputDecoration(
              labelText: isNoSerialType
                  ? 'Serial Number (not used for this type)'
                  : (controllers.autoGenerateSerialNumber
                        ? 'Serial Number (Auto-generated)'
                        : 'Serial Number'),
              hintText: controllers.autoGenerateSerialNumber && !isNoSerialType
                  ? 'Will be generated automatically'
                  : null,
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: controllers.category.text.trim().isEmpty
                ? null
                : controllers.category.text.trim(),
            items: categoryOptions
                .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => controllers.category.text = v ?? '',
            decoration: const InputDecoration(labelText: 'Category'),
          ),
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
          DropdownButtonFormField<String>(
            initialValue: controllers.status.text.trim().isEmpty
                ? null
                : controllers.status.text.trim(),
            items: statusOptions
                .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => controllers.status.text = v ?? '',
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          DropdownButtonFormField<String>(
            initialValue: controllers.condition.text.trim().isEmpty
                ? null
                : controllers.condition.text.trim(),
            items: conditionOptions
                .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => controllers.condition.text = v ?? '',
            decoration: const InputDecoration(labelText: 'Condition'),
          ),
          TextField(
            controller: controllers.lastMaintenance,
            decoration: const InputDecoration(
              labelText: _ManageInstrumentsScreenState._lastMaintenanceLabel,
            ),
          ),
        ],
      ),
    );
  }
}

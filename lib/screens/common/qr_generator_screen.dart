import 'package:flutter/material.dart';
import '../../data/qr_code_service.dart';
import '../../data/auth_service.dart';
import '../../data/api_client.dart';
import '../../models/instrument.dart';
import '../../core/utils/qr_downloader.dart';

class QrGeneratorScreen extends StatefulWidget {
  final String userRole;
  final String? preSelectedInstrument;
  const QrGeneratorScreen({super.key, required this.userRole, this.preSelectedInstrument});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  QrType? _selectedType;
  String? _selectedInstrument;
  String? _selectedCourse;
  DateTime? _neededAt;
  String? _payload;
  List<Instrument> _instruments = [];
  bool _loading = true;
  bool _advanced = false;

  final List<String> _caseCourses = [
    'BS Pharmacy',
    'BS Biology',
    'BS Radiologic Technology',
    'BS Medical Technology/Medical Laboratory Science',
    'BS Nursing',
  ];

  @override
  void initState() {
    super.initState();
    final role = widget.userRole.toLowerCase();
    if (role == 'student') {
      _selectedType = QrType.borrow;
    } else {
      _selectedType = QrType.receive;
    }
    _selectedInstrument = widget.preSelectedInstrument;
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Instrument> items = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _instruments = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatNeededAt(DateTime dt) {
    final months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = dt.toLocal();
    var hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hh = hour.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • $hh:$minute $suffix';
  }

  bool get _canGenerateBorrow => true;
  bool get _canGenerateReceiveReturn =>
      AuthService.instance.currentRole == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrintOptionsHeader(),
            const SizedBox(height: 8),
            _buildTypeSelection(),
            const SizedBox(height: 16),
            _buildInstrumentSelection(),
            const SizedBox(height: 16),
            if (_advanced && _selectedType == QrType.borrow) ...[
              _buildCourseSelection(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
            ],
            _buildGenerateButton(),
            const SizedBox(height: 24),
            _buildQrResult(),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final roleName = AuthService.instance.currentRole.name;
    final allowed = [
      if (_canGenerateBorrow) 'Borrow',
      if (_canGenerateReceiveReturn) 'Receive',
      if (_canGenerateReceiveReturn) 'Return',
    ];
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generate QR Code'),
          Text(
            'Role: $roleName • Allowed: ${allowed.join(", ")}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        if (_payload != null)
          IconButton(
            tooltip: 'Print view',
            icon: const Icon(Icons.print),
            onPressed: _showPrintDialog,
          ),
      ],
    );
  }

  void _showPrintDialog() {
    if (_payload == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedInstrument ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            QrCodeService.instance.buildQrWidget(_payload!, size: 260),
            const SizedBox(height: 8),
            const Text('Tip: Use system print or screenshot to create a label.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPrintOptionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Print Options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Text('Advanced'),
            Switch.adaptive(
              value: _advanced,
              onChanged: (v) => setState(() => _advanced = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSelection() {
    if (!_advanced) {
      return const Wrap(
        spacing: 12,
        children: [
          ChoiceChip(
            label: Text('Label'),
            selected: true,
            onSelected: null,
          ),
        ],
      );
    }
    return Wrap(
      spacing: 12,
      children: [
        ChoiceChip(
          label: const Text('Borrow'),
          selected: _selectedType == QrType.borrow,
          onSelected: _canGenerateBorrow
              ? (v) => setState(() => _selectedType = QrType.borrow)
              : null,
        ),
        ChoiceChip(
          label: const Text('Receive'),
          selected: _selectedType == QrType.receive,
          onSelected: _canGenerateReceiveReturn
              ? (v) => setState(() => _selectedType = QrType.receive)
              : null,
        ),
        ChoiceChip(
          label: const Text('Return'),
          selected: _selectedType == QrType.returnItem,
          onSelected: _canGenerateReceiveReturn
              ? (v) => setState(() => _selectedType = QrType.returnItem)
              : null,
        ),
      ],
    );
  }

  Widget _buildInstrumentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Instrument', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            value: _selectedInstrument,
            items: _instruments.map((inst) {
              final serial = (inst.serialNumber != null && inst.serialNumber!.isNotEmpty)
                  ? ' • SN: ${inst.serialNumber}'
                  : '';
              return DropdownMenuItem<String>(
                value: inst.name,
                child: Text('${inst.name}$serial', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedInstrument = v),
            decoration: const InputDecoration(
              labelText: 'Select Instrument',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Course (CASE)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCourse,
          items: _caseCourses
              .map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (v) => setState(() => _selectedCourse = v),
          decoration: const InputDecoration(
            labelText: 'Select Course',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Scheduled Borrowing Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: _neededAt ?? now,
              firstDate: now,
              lastDate: DateTime(now.year + 1),
            );
            if (!context.mounted || date == null) return;
            
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_neededAt ?? now),
            );
            if (!context.mounted || time == null) return;
            setState(() => _neededAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(_neededAt == null ? 'Set Schedule' : _formatNeededAt(_neededAt!)),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: _generate,
      icon: const Icon(Icons.qr_code_2),
      label: Text(_advanced ? 'Generate QR Code' : 'Generate Label'),
    );
  }

  Widget _buildQrResult() {
    if (_payload == null) return const SizedBox.shrink();
    final instName = (_selectedInstrument ?? 'qr').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Generated QR', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Center(child: QrCodeService.instance.buildQrWidget(_payload!, size: 220)),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await downloadQrFile(_payload!, 'qr_$instName.png');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR downloaded!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download QR as PNG'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(_payload!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.05),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Default: Prints a universal instrument label (INSTR). Toggle Advanced to create Borrow/Receive/Return QR.',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generate() {
    if (_selectedInstrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an instrument')),
      );
      return;
    }
    try {
      String payload;
      if (!_advanced) {
        payload = QrCodeService.instance.buildInstrumentLabelPayload(instrumentName: _selectedInstrument!);
      } else {
        if (_selectedType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a QR type')),
          );
          return;
        }
        payload = QrCodeService.instance.buildPayload(
          type: _selectedType!,
          instrumentName: _selectedInstrument!,
          course: _selectedCourse,
          neededAt: _neededAt,
        );
      }
      setState(() => _payload = payload);
    } on QrPermissionException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}

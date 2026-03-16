import 'package:flutter/material.dart';
import '../../data/qr_code_service.dart';
import '../../data/auth_service.dart';
import '../../data/api_client.dart';
import '../../models/instrument.dart';

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
  String? _payload;
  List<String> _instrumentNames = [];
  bool _loading = true;
  bool _advanced = false;

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
        _instrumentNames = items.map((e) => e.name).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _canGenerateBorrow => true;
  bool get _canGenerateReceiveReturn =>
      AuthService.instance.currentRole == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final roleName = AuthService.instance.currentRole.name;
    final allowed = [
      if (_canGenerateBorrow) 'Borrow',
      if (_canGenerateReceiveReturn) 'Receive',
      if (_canGenerateReceiveReturn) 'Return',
    ];
    return Scaffold(
      appBar: AppBar(
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
              onPressed: () {
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
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 8),
            if (!_advanced)
              Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: const Text('Label'),
                    selected: true,
                    onSelected: null,
                  ),
                ],
              )
            else
              Wrap(
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
              ),
            const SizedBox(height: 16),
            const Text('Instrument', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _selectedInstrument?.isNotEmpty == true && _instrumentNames.contains(_selectedInstrument)
                    ? _selectedInstrument
                    : null,
                items: _instrumentNames
                    .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedInstrument = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select instrument',
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code_2),
              label: Text(_advanced ? 'Generate QR Code' : 'Generate Label'),
            ),
            const SizedBox(height: 24),
            if (_payload != null) ...[
              const Text('Generated QR', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(child: QrCodeService.instance.buildQrWidget(_payload!, size: 220)),
              const SizedBox(height: 12),
              SelectableText(_payload!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.blue.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Default: Prints a universal instrument label (INSTR). Toggle Advanced to create Borrow/Receive/Return QR.',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
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
        final role = AuthService.instance.currentRole;
        payload = (_selectedType == QrType.borrow && !(role == UserRole.student || role == UserRole.staff))
            ? QrCodeService.instance.buildPayloadForPrint(type: _selectedType!, instrumentName: _selectedInstrument!)
            : QrCodeService.instance.buildPayload(type: _selectedType!, instrumentName: _selectedInstrument!);
      }
      setState(() => _payload = payload);
    } on QrPermissionException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}

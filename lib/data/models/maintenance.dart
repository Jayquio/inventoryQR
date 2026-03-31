// lib/models/maintenance.dart

class Maintenance {
  final String instrumentName;
  final String technician;
  final String date;
  final String type;
  final String notes;
  final String status;

  const Maintenance({
    required this.instrumentName,
    required this.technician,
    required this.date,
    required this.type,
    required this.notes,
    required this.status,
  });
}

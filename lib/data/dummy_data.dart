import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import 'package:flutter_application_inventorymanagement/models/maintenance.dart';
import 'package:flutter_application_inventorymanagement/models/request.dart';

const String _microscopeOlympusCx23 = 'Microscope Olympus CX23';
const String _centrifugeMachine = 'Centrifuge Machine';

List<Instrument> instruments = [
  Instrument(
    name: _microscopeOlympusCx23,
    category: 'Microscopy',
    quantity: 5,
    available: 3,
    status: 'Available',
    condition: 'Good',
    location: 'Lab Room A',
    lastMaintenance: '2024-10-15',
  ),
  Instrument(
    name: _centrifugeMachine,
    category: 'Sample Processing',
    quantity: 3,
    available: 2,
    status: 'Available',
    condition: 'Good',
    location: 'Lab Room B',
    lastMaintenance: '2024-09-20',
    imageAsset: 'assets/images/instruments/centrifugemachine.png',
  ),
  Instrument(
    name: 'Hematology Analyzer',
    category: 'Hematology',
    quantity: 2,
    available: 2,
    status: 'Available',
    condition: 'Excellent',
    location: 'Lab Room C',
    lastMaintenance: '2024-08-05',
  ),
  Instrument(
    name: 'Clinical Chemistry Analyzer',
    category: 'Chemistry',
    quantity: 2,
    available: 1,
    status: 'In Use',
    condition: 'Good',
    location: 'Lab Room C',
    lastMaintenance: '2024-07-18',
  ),
  Instrument(
    name: 'Autoclave Sterilizer',
    category: 'Sterilization',
    quantity: 1,
    available: 1,
    status: 'Available',
    condition: 'Good',
    location: 'Sterilization Room',
    lastMaintenance: '2024-06-10',
  ),
  Instrument(
    name: 'Incubator 37°C',
    category: 'Incubation',
    quantity: 3,
    available: 2,
    status: 'Available',
    condition: 'Good',
    location: 'Lab Room A',
    lastMaintenance: '2024-05-22',
  ),
  Instrument(
    name: 'Refrigerated Storage',
    category: 'Cold Storage',
    quantity: 2,
    available: 2,
    status: 'Available',
    condition: 'Excellent',
    location: 'Cold Room',
    lastMaintenance: '2024-04-30',
  ),
];

List<Request> requests = [
  Request(
    studentName: 'John Dela Cruz',
    instrumentName: _microscopeOlympusCx23,
    purpose: 'Cell study experiment',
    status: RequestStatus.pending,
  ),
  Request(
    studentName: 'Maria Santos',
    instrumentName: _centrifugeMachine,
    purpose: 'Blood sample processing',
    status: RequestStatus.approved,
  ),
];

List<Maintenance> maintenanceRecords = [
  Maintenance(
    instrumentName: _microscopeOlympusCx23,
    technician: 'John Doe',
    date: '2024-10-15',
    type: 'Routine Maintenance',
    notes: 'Cleaned and calibrated',
    status: 'Completed',
  ),
  Maintenance(
    instrumentName: _centrifugeMachine,
    technician: 'Jane Smith',
    date: '2024-09-20',
    type: 'Calibration',
    notes: 'Speed calibration completed',
    status: 'Completed',
  ),
];

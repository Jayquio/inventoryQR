// lib/models/request.dart

enum RequestStatus { pending, approved, rejected }

class Request {
  final String studentName;
  final String instrumentName;
  final String requestDate;
  final String returnDate;
  RequestStatus status;
  final String purpose;

  Request({
    required this.studentName,
    required this.instrumentName,
    required this.requestDate,
    required this.returnDate,
    this.status = RequestStatus.pending, // Default to pending
    required this.purpose,
  });
}

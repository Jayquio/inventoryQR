enum RequestStatus { pending, approved, rejected, returned }

class Request {
  final String id;
  final String studentName;
  final String instrumentName;
  final int quantity;
  final String purpose;
  final String? course;
  final String? neededAt;
  final String instrumentType;
  final String? approvedBy;
  final String? rejectedBy;
  final String? returnedBy;
  RequestStatus status;

  Request({
    this.id = '',
    required this.studentName,
    required this.instrumentName,
    this.quantity = 1,
    required this.purpose,
    this.course,
    this.neededAt,
    this.instrumentType = 'instrument',
    this.approvedBy,
    this.rejectedBy,
    this.returnedBy,
    required this.status,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final status = switch (statusStr) {
      'approved' => RequestStatus.approved,
      'rejected' => RequestStatus.rejected,
      'returned' => RequestStatus.returned,
      _ => RequestStatus.pending,
    };
    return Request(
      id: json['id']?.toString() ?? '',
      studentName: (json['studentName'] ?? '') as String,
      instrumentName: (json['instrumentName'] ?? '') as String,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      purpose: (json['purpose'] ?? '') as String,
      course: (json['course'] ?? '') as String?,
      neededAt: (json['neededAt'] ?? '') as String?,
      instrumentType: (json['instrumentType'] ?? 'instrument').toString().toLowerCase(),
      approvedBy: (json['approvedBy'] ?? '') as String?,
      rejectedBy: (json['rejectedBy'] ?? '') as String?,
      returnedBy: (json['returnedBy'] ?? '') as String?,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    final statusStr = switch (status) {
      RequestStatus.approved => 'approved',
      RequestStatus.rejected => 'rejected',
      RequestStatus.returned => 'returned',
      RequestStatus.pending => 'pending',
    };
    return {
      if (id.isNotEmpty) 'id': id,
      'studentName': studentName,
      'instrumentName': instrumentName,
      'quantity': quantity,
      'purpose': purpose,
      if (course != null && course!.isNotEmpty) 'course': course,
      if (neededAt != null && neededAt!.isNotEmpty) 'neededAt': neededAt,
      'instrumentType': instrumentType,
      if (approvedBy != null && approvedBy!.isNotEmpty) 'approvedBy': approvedBy,
      if (rejectedBy != null && rejectedBy!.isNotEmpty) 'rejectedBy': rejectedBy,
      if (returnedBy != null && returnedBy!.isNotEmpty) 'returnedBy': returnedBy,
      'status': statusStr,
    };
  }
}

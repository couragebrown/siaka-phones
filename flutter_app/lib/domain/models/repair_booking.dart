class RepairBooking {
  final String id;
  final String deviceModel;
  final String issueType;
  final String description;
  final String? photoPath;
  final String? dropOffBranch;
  final double estimatedCost;
  final DateTime appointmentDate;
  final String timeSlot;
  final String customerName;
  final String customerPhone;
  final String status;

  const RepairBooking({
    required this.id,
    required this.deviceModel,
    required this.issueType,
    required this.description,
    this.photoPath,
    this.dropOffBranch,
    required this.estimatedCost,
    required this.appointmentDate,
    required this.timeSlot,
    required this.customerName,
    required this.customerPhone,
    this.status = 'Confirmed',
  });

  RepairBooking copyWith({
    String? id,
    String? deviceModel,
    String? issueType,
    String? description,
    String? photoPath,
    String? dropOffBranch,
    double? estimatedCost,
    DateTime? appointmentDate,
    String? timeSlot,
    String? customerName,
    String? customerPhone,
    String? status,
  }) {
    return RepairBooking(
      id: id ?? this.id,
      deviceModel: deviceModel ?? this.deviceModel,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      dropOffBranch: dropOffBranch ?? this.dropOffBranch,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
    );
  }
}


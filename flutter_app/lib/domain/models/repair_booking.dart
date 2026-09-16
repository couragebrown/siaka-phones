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
}


class RepairBooking {
  final String id;
  final String deviceModel;
  final String issueType;
  final String description;
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
    required this.estimatedCost,
    required this.appointmentDate,
    required this.timeSlot,
    required this.customerName,
    required this.customerPhone,
    this.status = 'Confirmed',
  });
}

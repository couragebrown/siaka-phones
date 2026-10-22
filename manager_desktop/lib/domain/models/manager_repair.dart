enum RepairStage {
  received('Received', 0xFFD97706, 0xFFFEF3C7),
  diagnosing('Diagnosing', 0xFF2563EB, 0xFFDBEAFE),
  awaitingParts('Awaiting Parts', 0xFF7C3AED, 0xFFEDE9FE),
  readyForPickup('Ready for Pickup', 0xFF059669, 0xFFD1FAE5),
  completed('Completed', 0xFF475569, 0xFFF1F5F9);

  final String label;
  final int textColor;
  final int bgColor;

  const RepairStage(this.label, this.textColor, this.bgColor);
}

class ManagerRepair {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deviceModel;
  final String reportedIssue;
  final DateTime bookedDate;
  RepairStage stage;
  double estimatedCost;
  String technicianNotes;
  final String description;
  final String dropOffBranch;
  final String timeSlot;
  final String? photoPath;
  final DateTime? appointmentDate;

  ManagerRepair({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deviceModel,
    required this.reportedIssue,
    required this.bookedDate,
    this.stage = RepairStage.received,
    this.estimatedCost = 0.0,
    this.technicianNotes = '',
    this.description = '',
    this.dropOffBranch = 'Siaka Phones Circle',
    this.timeSlot = 'Morning (09:00 - 12:00)',
    this.photoPath,
    this.appointmentDate,
  });
}

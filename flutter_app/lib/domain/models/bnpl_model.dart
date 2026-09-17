class BnplApplication {
  final String id;
  final String brand;
  final String modelName;
  final String storage;
  final String ram;
  final String condition;
  final String preferredColor;
  final String planDuration;
  final String customerName;
  final String customerPhone;
  final String notes;
  final String status;
  final DateTime createdAt;

  const BnplApplication({
    required this.id,
    required this.brand,
    required this.modelName,
    required this.storage,
    required this.ram,
    required this.condition,
    required this.preferredColor,
    required this.planDuration,
    required this.customerName,
    required this.customerPhone,
    required this.notes,
    this.status = 'Under Review by Manager',
    required this.createdAt,
  });
}

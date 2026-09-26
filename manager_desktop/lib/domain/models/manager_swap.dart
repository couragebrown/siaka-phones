enum SwapEvaluationStatus {
  underReview('Under Review', 0xFFD97706, 0xFFFEF3C7),
  approved('Approved & Offered', 0xFF059669, 0xFFD1FAE5),
  rejected('Declined', 0xFFDC2626, 0xFFFEE2E2),
  swapped('Completed', 0xFF475569, 0xFFF1F5F9);

  final String label;
  final int textColor;
  final int bgColor;

  const SwapEvaluationStatus(this.label, this.textColor, this.bgColor);
}

class ManagerSwap {
  final String id;
  final String customerName;
  final String customerPhone;
  final String targetDevice;
  final double targetDevicePrice;
  final String currentDevice;
  final String deviceCondition;
  final int batteryHealth;
  final double estimatedTradeInValue;
  final double customerCashTopUp;
  final DateTime submissionDate;
  SwapEvaluationStatus status;
  String inspectionNotes;

  ManagerSwap({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.targetDevice,
    required this.targetDevicePrice,
    required this.currentDevice,
    required this.deviceCondition,
    required this.batteryHealth,
    required this.estimatedTradeInValue,
    required this.customerCashTopUp,
    required this.submissionDate,
    this.status = SwapEvaluationStatus.underReview,
    this.inspectionNotes = '',
  });
}

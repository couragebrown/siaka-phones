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
  final String currentStorage;
  final bool turnsOn;
  final bool screenIntact;
  final String desiredBrand;
  final String desiredModel;
  final String desiredStorage;
  final String desiredRam;
  final String desiredCondition;
  final String desiredColor;
  final String preferredBranch;
  final String customerNotes;
  double? offeredCost;
  final DateTime submissionDate;
  SwapEvaluationStatus status;
  String inspectionNotes;

  ManagerSwap({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.targetDevice,
    this.targetDevicePrice = 0.0,
    required this.currentDevice,
    required this.deviceCondition,
    this.batteryHealth = 85,
    this.estimatedTradeInValue = 0.0,
    this.customerCashTopUp = 0.0,
    this.currentStorage = '128 GB',
    this.turnsOn = true,
    this.screenIntact = true,
    this.desiredBrand = '',
    this.desiredModel = '',
    this.desiredStorage = '',
    this.desiredRam = '',
    this.desiredCondition = '',
    this.desiredColor = '',
    this.preferredBranch = 'Circle Main Branch',
    this.customerNotes = '',
    this.offeredCost,
    required this.submissionDate,
    this.status = SwapEvaluationStatus.underReview,
    this.inspectionNotes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'targetDevice': targetDevice,
    'targetDevicePrice': targetDevicePrice,
    'currentDevice': currentDevice,
    'deviceCondition': deviceCondition,
    'batteryHealth': batteryHealth,
    'estimatedTradeInValue': estimatedTradeInValue,
    'customerCashTopUp': customerCashTopUp,
    'currentStorage': currentStorage,
    'turnsOn': turnsOn,
    'screenIntact': screenIntact,
    'desiredBrand': desiredBrand,
    'desiredModel': desiredModel,
    'desiredStorage': desiredStorage,
    'desiredRam': desiredRam,
    'desiredCondition': desiredCondition,
    'desiredColor': desiredColor,
    'preferredBranch': preferredBranch,
    'customerNotes': customerNotes,
    if (offeredCost != null) 'offeredCost': offeredCost,
    'submissionDate': submissionDate.toIso8601String(),
    'status': status.name,
    'inspectionNotes': inspectionNotes,
  };

  factory ManagerSwap.fromMap(Map<String, dynamic> m) {
    SwapEvaluationStatus status = SwapEvaluationStatus.underReview;
    final statusStr = m['status']?.toString().toLowerCase() ?? '';
    for (final s in SwapEvaluationStatus.values) {
      if (s.name.toLowerCase() == statusStr || s.label.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    return ManagerSwap(
      id: m['id']?.toString() ?? '',
      customerName: m['customerName']?.toString() ?? '',
      customerPhone: m['customerPhone']?.toString() ?? '',
      targetDevice: m['targetDevice']?.toString() ?? '',
      targetDevicePrice: (m['targetDevicePrice'] as num?)?.toDouble() ?? 0.0,
      currentDevice: m['currentDevice']?.toString() ?? '',
      deviceCondition: m['deviceCondition']?.toString() ?? 'Good',
      batteryHealth: (m['batteryHealth'] as num?)?.toInt() ?? 85,
      estimatedTradeInValue: (m['estimatedTradeInValue'] as num?)?.toDouble() ?? 0.0,
      customerCashTopUp: (m['customerCashTopUp'] as num?)?.toDouble() ?? 0.0,
      currentStorage: m['currentStorage']?.toString() ?? '128 GB',
      turnsOn: m['turnsOn'] is bool ? m['turnsOn'] as bool : (m['turnsOn']?.toString().toLowerCase() != 'false'),
      screenIntact: m['screenIntact'] is bool ? m['screenIntact'] as bool : (m['screenIntact']?.toString().toLowerCase() != 'false'),
      desiredBrand: m['desiredBrand']?.toString() ?? '',
      desiredModel: m['desiredModel']?.toString() ?? '',
      desiredStorage: m['desiredStorage']?.toString() ?? '',
      desiredRam: m['desiredRam']?.toString() ?? '',
      desiredCondition: m['desiredCondition']?.toString() ?? '',
      desiredColor: m['desiredColor']?.toString() ?? '',
      preferredBranch: m['preferredBranch']?.toString() ?? 'Circle Main Branch',
      customerNotes: m['customerNotes']?.toString() ?? m['notes']?.toString() ?? '',
      offeredCost: (m['offeredCost'] as num?)?.toDouble(),
      submissionDate: DateTime.tryParse(m['submissionDate']?.toString() ?? '') ?? DateTime.now(),
      status: status,
      inspectionNotes: m['inspectionNotes']?.toString() ?? '',
    );
  }
}

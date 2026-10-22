enum BnplStatus {
  pending('Pending Review', 0xFFD97706, 0xFFFEF3C7),
  approved('Approved', 0xFF059669, 0xFFD1FAE5),
  rejected('Declined', 0xFFDC2626, 0xFFFEE2E2);

  final String label;
  final int textColor;
  final int bgColor;

  const BnplStatus(this.label, this.textColor, this.bgColor);
}

class ManagerBnpl {
  final String id;
  final String applicantName;
  final String phone;
  final String email;
  final String nationalId;
  final String location;
  final String employer;
  final double monthlySalary;
  final String requestedPhone;
  final String brand;
  final String modelName;
  final String storage;
  final String ram;
  final String deviceCondition;
  final String preferredColor;
  final String planDuration;
  final String customerNotes;
  final String preferredBranch;
  final double phonePrice;
  final double downPayment;
  final double monthlyInstallment;
  final double? dailyInstallment;
  final double? weeklyInstallment;
  final int tenureMonths;
  final DateTime applicationDate;
  BnplStatus status;
  String managerNotes;

  ManagerBnpl({
    required this.id,
    required this.applicantName,
    required this.phone,
    required this.email,
    required this.nationalId,
    this.location = 'Greater Accra, Ghana',
    required this.employer,
    required this.monthlySalary,
    required this.requestedPhone,
    this.brand = '',
    this.modelName = '',
    this.storage = '',
    this.ram = '',
    this.deviceCondition = '',
    this.preferredColor = '',
    this.planDuration = 'Monthly',
    this.customerNotes = '',
    this.preferredBranch = 'Siaka Phones Circle',
    required this.phonePrice,
    required this.downPayment,
    required this.monthlyInstallment,
    this.dailyInstallment,
    this.weeklyInstallment,
    required this.tenureMonths,
    required this.applicationDate,
    this.status = BnplStatus.pending,
    this.managerNotes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'applicantName': applicantName,
    'phone': phone,
    'email': email,
    'nationalId': nationalId,
    'location': location,
    'employer': employer,
    'monthlySalary': monthlySalary,
    'requestedPhone': requestedPhone,
    'brand': brand,
    'modelName': modelName,
    'storage': storage,
    'ram': ram,
    'deviceCondition': deviceCondition,
    'preferredColor': preferredColor,
    'planDuration': planDuration,
    'customerNotes': customerNotes,
    'preferredBranch': preferredBranch,
    'phonePrice': phonePrice,
    'downPayment': downPayment,
    'monthlyInstallment': monthlyInstallment,
    'dailyInstallment': dailyInstallment,
    'weeklyInstallment': weeklyInstallment,
    'tenureMonths': tenureMonths,
    'applicationDate': applicationDate.toIso8601String(),
    'status': status.name,
    'managerNotes': managerNotes,
  };

  factory ManagerBnpl.fromMap(Map<String, dynamic> m) {
    BnplStatus status = BnplStatus.pending;
    final statusStr = (m['status'] ?? m['stage'] ?? m['condition'] ?? '').toString().toLowerCase();
    for (final s in BnplStatus.values) {
      if (s.name.toLowerCase() == statusStr || s.label.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    final reqPhone = m['requestedPhone']?.toString() ??
        (m['modelName'] != null && m['brand'] != null ? '${m['brand']} ${m['modelName']}' : (m['name']?.toString() ?? 'Phone'));

    return ManagerBnpl(
      id: m['id']?.toString() ?? '',
      applicantName: m['applicantName']?.toString() ?? m['customerName']?.toString() ?? m['name']?.toString() ?? 'Customer',
      phone: m['phone']?.toString() ?? m['customerPhone']?.toString() ?? '024 555 0192',
      email: m['email']?.toString() ?? m['customerEmail']?.toString() ?? 'applicant@gmail.com',
      nationalId: m['nationalId']?.toString() ?? 'GHA-729104820-1',
      location: m['location']?.toString() ?? 'Greater Accra, Ghana',
      employer: m['employer']?.toString() ?? 'Self Employed / Trader',
      monthlySalary: (m['monthlySalary'] as num?)?.toDouble() ?? 3500.0,
      requestedPhone: reqPhone,
      brand: m['brand']?.toString() ?? '',
      modelName: m['modelName']?.toString() ?? '',
      storage: m['storage']?.toString() ?? '',
      ram: m['ram']?.toString() ?? '',
      deviceCondition: m['deviceCondition']?.toString() ?? m['condition']?.toString() ?? '',
      preferredColor: m['preferredColor']?.toString() ?? m['color']?.toString() ?? '',
      planDuration: m['planDuration']?.toString() ?? 'Monthly',
      customerNotes: m['customerNotes']?.toString() ?? m['notes']?.toString() ?? '',
      preferredBranch: m['preferredBranch']?.toString() ?? m['branch']?.toString() ?? 'Siaka Phones Circle',
      phonePrice: (m['phonePrice'] as num?)?.toDouble() ?? (m['price'] as num?)?.toDouble() ?? 2800.0,
      downPayment: (m['downPayment'] as num?)?.toDouble() ?? 840.0,
      monthlyInstallment: (m['monthlyInstallment'] as num?)?.toDouble() ?? 326.0,
      dailyInstallment: (m['dailyInstallment'] as num?)?.toDouble(),
      weeklyInstallment: (m['weeklyInstallment'] as num?)?.toDouble(),
      tenureMonths: (m['tenureMonths'] as num?)?.toInt() ?? (m['stock'] as num?)?.toInt() ?? 6,
      applicationDate: DateTime.tryParse(m['applicationDate']?.toString() ?? m['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: status,
      managerNotes: m['managerNotes']?.toString() ?? '',
    );
  }
}

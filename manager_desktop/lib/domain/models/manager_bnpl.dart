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
  final double phonePrice;
  final double downPayment;
  final double monthlyInstallment;
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
    required this.phonePrice,
    required this.downPayment,
    required this.monthlyInstallment,
    required this.tenureMonths,
    required this.applicationDate,
    this.status = BnplStatus.pending,
    this.managerNotes = '',
  });
}

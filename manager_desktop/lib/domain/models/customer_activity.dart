class CustomerActivity {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final DateTime signupDate;
  int loginCount;
  DateTime lastLogin;
  final String primaryDevice;
  final String status;
  final double totalSpend;
  final int totalOrders;
  final String branch;
  final bool isOnline;

  CustomerActivity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.signupDate,
    required this.loginCount,
    required this.lastLogin,
    required this.primaryDevice,
    this.status = 'Active',
    this.totalSpend = 0.0,
    this.totalOrders = 0,
    this.branch = 'Accra Central (Circle)',
    this.isOnline = false,
  });
}

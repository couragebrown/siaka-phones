import 'package:flutter/foundation.dart';
import '../../domain/models/repair_booking.dart';

class RepairRepository extends ChangeNotifier {
  final List<RepairBooking> _bookings = [
    RepairBooking(
      id: 'REP-GH-8219',
      deviceModel: 'Samsung Galaxy S22 Ultra',
      issueType: 'Screen Replacement / AMOLED Crack',
      description: 'Front glass cracked, display touch working. Genuine replacement requested.',
      dropOffBranch: 'Siaka Phones Circle',
      estimatedCost: 0.0,
      appointmentDate: DateTime.now().subtract(const Duration(days: 4)),
      timeSlot: 'Morning (9:00 AM - 1:00 PM)',
      customerName: 'Kwame Mensah',
      customerPhone: '024 555 0192',
      status: 'Completed',
    ),
    RepairBooking(
      id: 'REP-GH-9442',
      deviceModel: 'iPhone 13 Pro',
      issueType: 'Battery Degradation / Fast Drain',
      description: 'Battery health degraded at 74%. Needs original battery replacement.',
      dropOffBranch: 'Siaka Phones Madina',
      estimatedCost: 0.0,
      appointmentDate: DateTime.now().add(const Duration(days: 1)),
      timeSlot: 'Afternoon (2:00 PM - 5:00 PM)',
      customerName: 'Kwame Mensah',
      customerPhone: '024 555 0192',
      status: 'In Progress / Diagnostic',
    ),
  ];

  List<RepairBooking> get bookings => List.unmodifiable(_bookings);

  final Map<String, double> issuePricing = {
    'Screen Replacement / AMOLED Crack': 149.99,
    'Battery Degradation / Fast Drain': 69.99,
    'Charging Port / USB-C Fault': 59.99,
    'Water & Liquid Ingress Damage': 89.99,
    'Camera Lens & Sensor Malfunction': 119.99,
    'Speaker / Mic Audio Distortion': 49.99,
    'Back Glass & Chassis Damage': 79.99,
    'Motherboard / Power Boot Loop': 199.99,
    'Other Hardware / Software Fault': 39.99,
  };

  Future<RepairBooking> createBooking({
    required String deviceModel,
    required String issueType,
    required String description,
    String? photoPath,
    String? dropOffBranch,
    required double estimatedCost,
    required DateTime appointmentDate,
    required String timeSlot,
    required String customerName,
    required String customerPhone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final booking = RepairBooking(
      id: 'REP-GH-${1000 + _bookings.length * 17 + (DateTime.now().millisecond % 900)}',
      deviceModel: deviceModel,
      issueType: issueType,
      description: description,
      photoPath: photoPath,
      dropOffBranch: dropOffBranch ?? 'Siaka Phones Circle',
      estimatedCost: estimatedCost,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      customerName: customerName,
      customerPhone: customerPhone,
      status: 'Confirmed',
    );
    _bookings.insert(0, booking);
    notifyListeners();
    return booking;
  }
}


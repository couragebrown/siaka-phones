import 'package:flutter/foundation.dart';
import '../../domain/models/repair_booking.dart';

class RepairRepository extends ChangeNotifier {
  final List<RepairBooking> _bookings = [];

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


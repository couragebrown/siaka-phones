import 'package:flutter/foundation.dart';
import '../../domain/models/repair_booking.dart';

class RepairRepository extends ChangeNotifier {
  final List<RepairBooking> _bookings = [];

  List<RepairBooking> get bookings => List.unmodifiable(_bookings);

  final Map<String, double> issuePricing = {
    'Cracked Screen / AMOLED Panel': 149.99,
    'Battery Degradation / Fast Drain': 69.99,
    'Water Damage Diagnostic & Clean': 89.99,
    'Camera Lens & Sensor Calibration': 119.99,
    'USB-C Port / Wireless Charging': 59.99,
    'Motherboard / Logic Chip Repair': 199.99,
  };

  Future<RepairBooking> createBooking({
    required String deviceModel,
    required String issueType,
    required String description,
    required double estimatedCost,
    required DateTime appointmentDate,
    required String timeSlot,
    required String customerName,
    required String customerPhone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final booking = RepairBooking(
      id: 'REP-${1000 + _bookings.length * 17 + DateTime.now().millisecond}',
      deviceModel: deviceModel,
      issueType: issueType,
      description: description,
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

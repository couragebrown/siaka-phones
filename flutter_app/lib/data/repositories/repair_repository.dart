import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/repair_booking.dart';
import '../services/supabase_service.dart';

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

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final repairMap = {
        'id': 'REPAIR_${booking.id}',
        'name': '${booking.customerName} - ${booking.deviceModel}',
        'brand': booking.deviceModel,
        'category': 'REPAIR_RECORD',
        'price': booking.estimatedCost,
        'original_price': booking.estimatedCost,
        'stock': 1,
        'customerName': booking.customerName,
        'customerPhone': booking.customerPhone,
        'deviceModel': booking.deviceModel,
        'reportedIssue': booking.issueType,
        'description': booking.description,
        'dropOffBranch': booking.dropOffBranch,
        'timeSlot': booking.timeSlot,
        'photoPath': booking.photoPath,
        'appointmentDate': booking.appointmentDate.toIso8601String(),
        'bookedDate': DateTime.now().toIso8601String(),
        'specs': jsonEncode({
          'customerName': booking.customerName,
          'customerPhone': booking.customerPhone,
          'deviceModel': booking.deviceModel,
          'issueType': booking.issueType,
          'description': booking.description,
          'dropOffBranch': booking.dropOffBranch,
          'timeSlot': booking.timeSlot,
          'photoPath': booking.photoPath,
          'appointmentDate': booking.appointmentDate.toIso8601String(),
          'status': booking.status,
        }),
        'condition': 'received',
        'created_at': DateTime.now().toIso8601String(),
      };

      SupabaseService().upsertRawRecord(repairMap);
    }

    return booking;
  }

  void updateBookingCost(String id, double cost, {String? status}) {
    final cleanId = id.replaceFirst('REPAIR_', '');
    final idx = _bookings.indexWhere((b) => b.id.replaceFirst('REPAIR_', '') == cleanId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        estimatedCost: cost,
        status: status ?? _bookings[idx].status,
      );
      notifyListeners();
    }
  }

  Future<void> fetchRemoteRepairs() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);
      final req = await client.getUrl(Uri.parse('http://$host:8088/api/repairs'));
      final resp = await req.close().timeout(const Duration(milliseconds: 1500));
      if (resp.statusCode == HttpStatus.ok) {
        final body = await resp.transform(utf8.decoder).join();
        if (body.isNotEmpty) {
          final list = jsonDecode(body) as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final rawId = item['id']?.toString() ?? '';
              final cost = (item['estimatedCost'] as num?)?.toDouble() ?? 0.0;
              final stageLabel = item['stageLabel']?.toString();
              updateBookingCost(rawId, cost, status: stageLabel);
            }
          }
        }
      }
    } catch (_) {}
  }
}


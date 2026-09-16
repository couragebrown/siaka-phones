import 'package:flutter/foundation.dart';
import '../../../data/repositories/repair_repository.dart';
import '../../../domain/models/repair_booking.dart';

class RepairsViewModel extends ChangeNotifier {
  final RepairRepository _repairRepository;

  RepairsViewModel({
    required RepairRepository repairRepository,
  }) : _repairRepository = repairRepository;

  String _deviceModel = 'Siaka Quantum Titan 16 Pro';
  String _selectedIssue = 'Screen Replacement / AMOLED Crack';
  String _description = '';
  String? _photoPath;
  String _selectedBranch = 'Siaka Phones Circle';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _timeSlot = '10:00 AM - 12:00 PM';
  final String _customerName = 'Courage Brown';
  final String _customerPhone = '+233 24 100 2001';
  bool _isSubmitting = false;
  RepairBooking? _lastBooking;


  String get deviceModel => _deviceModel;
  String get selectedIssue => _selectedIssue;
  String get description => _description;
  String? get photoPath => _photoPath;
  String get selectedBranch => _selectedBranch;
  DateTime get selectedDate => _selectedDate;
  String get timeSlot => _timeSlot;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  bool get isSubmitting => _isSubmitting;
  RepairBooking? get lastBooking => _lastBooking;

  Map<String, double> get issuePricing => _repairRepository.issuePricing;
  double get estimatedCost => _repairRepository.issuePricing[_selectedIssue] ?? 99.99;

  void setDeviceModel(String model) {
    _deviceModel = model;
    notifyListeners();
  }

  void setSelectedIssue(String issue) {
    _selectedIssue = issue;
    notifyListeners();
  }

  void setDescription(String desc) {
    _description = desc;
    notifyListeners();
  }

  void setPhotoPath(String? path) {
    _photoPath = path;
    notifyListeners();
  }

  void removePhoto() {
    _photoPath = null;
    notifyListeners();
  }

  void attachDamagePhoto(String nameOrPath) {
    _photoPath = nameOrPath;
    notifyListeners();
  }


  void setSelectedBranch(String branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  void setAppointmentDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setTimeSlot(String slot) {
    _timeSlot = slot;
    notifyListeners();
  }

  Future<bool> bookAppointment() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _lastBooking = await _repairRepository.createBooking(
        deviceModel: _deviceModel,
        issueType: _selectedIssue,
        description: _description.trim().isEmpty ? 'General inspection & diagnostic' : _description.trim(),
        photoPath: _photoPath,
        dropOffBranch: _selectedBranch,
        estimatedCost: estimatedCost,
        appointmentDate: _selectedDate,
        timeSlot: _timeSlot,
        customerName: _customerName,
        customerPhone: _customerPhone,
      );
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void resetBookingState() {
    _lastBooking = null;
    _photoPath = null;
    _description = '';
    notifyListeners();
  }
}


import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../domain/models/bnpl_model.dart';

class BnplViewModel extends ChangeNotifier {
  static const List<String> supportedBrands = [
    'Tecno',
    'Infinix',
    'Samsung',
    'iPhone',
  ];

  static const Map<String, List<String>> popularModels = {
    'Tecno': [
      'Camon 30 Pro 5G',
      'Camon 30 Premier',
      'Phantom V Fold 2',
      'Spark 20 Pro+',
      'Pova 6 Pro 5G',
    ],
    'Infinix': [
      'Note 40 Pro+ 5G',
      'Note 40 Pro',
      'Zero 30 5G',
      'GT 20 Pro',
      'Hot 40 Pro',
    ],
    'Samsung': [
      'Galaxy S24 Ultra',
      'Galaxy S24+',
      'Galaxy S23 FE',
      'Galaxy A55 5G',
      'Galaxy Z Flip 5',
    ],
    'iPhone': [
      'iPhone 15 Pro Max',
      'iPhone 15 Pro',
      'iPhone 15',
      'iPhone 14 Pro Max',
      'iPhone 13',
    ],
  };

  static const List<String> storageOptions = [
    '64 GB',
    '128 GB',
    '256 GB',
    '512 GB',
    '1 TB',
  ];

  static const List<String> ramOptions = [
    '4 GB',
    '6 GB',
    '8 GB',
    '12 GB',
    '16 GB',
  ];

  static const List<String> conditionOptions = [
    'Brand New (Sealed)',
    'Certified Pre-Owned',
  ];

  static const List<String> colorOptions = [
    'Black / Dark Titanium',
    'Silver / Natural',
    'Gold / Champagne',
    'Blue / Deep Navy',
    'Any Available Color',
  ];

  static const List<String> planDurationOptions = [
    'Daily',
    'Weekly',
    'Monthly',
  ];

  String _selectedBrand = 'iPhone';
  String _modelName = '';
  String _selectedStorage = '256 GB';
  String _selectedRam = '8 GB';
  String _selectedCondition = 'Brand New (Sealed)';
  String _selectedColor = 'Any Available Color';
  String _selectedPlanDuration = 'Monthly';

  String _customerName = 'Kwame Mensah';
  String _customerPhone = '024 555 0192';
  String _notes = '';

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  BnplApplication? _lastApplication;
  final List<BnplApplication> _submittedApplications = [];

  // Getters
  String get selectedBrand => _selectedBrand;
  String get modelName => _modelName;
  String get selectedStorage => _selectedStorage;
  String get selectedRam => _selectedRam;
  String get selectedCondition => _selectedCondition;
  String get selectedColor => _selectedColor;
  String get selectedPlanDuration => _selectedPlanDuration;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get notes => _notes;
  bool get isSubmitting => _isSubmitting;
  bool get isSubmitted => _isSubmitted;
  String? get errorMessage => _errorMessage;
  BnplApplication? get lastApplication => _lastApplication;
  List<BnplApplication> get submittedApplications =>
      List.unmodifiable(_submittedApplications);

  List<String> get currentBrandSuggestions =>
      popularModels[_selectedBrand] ?? const [];

  void setBrand(String brand) {
    if (supportedBrands.contains(brand) && _selectedBrand != brand) {
      _selectedBrand = brand;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void setModelName(String name) {
    _modelName = name;
    _errorMessage = null;
    notifyListeners();
  }

  void setStorage(String storage) {
    _selectedStorage = storage;
    notifyListeners();
  }

  void setRam(String ram) {
    _selectedRam = ram;
    notifyListeners();
  }

  void setCondition(String condition) {
    _selectedCondition = condition;
    notifyListeners();
  }

  void setColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setPlanDuration(String duration) {
    _selectedPlanDuration = duration;
    notifyListeners();
  }

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  void setCustomerPhone(String phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  Future<bool> submitApplication() async {
    if (_modelName.trim().isEmpty) {
      _errorMessage = 'Please enter or select a phone model.';
      notifyListeners();
      return false;
    }

    if (_customerPhone.trim().isEmpty) {
      _errorMessage = 'Please provide your contact phone number.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    // Brief simulated dispatch to manager
    await Future.delayed(const Duration(milliseconds: 300));

    final randomId = 'BNPL-${Random().nextInt(9000) + 1000}';
    final application = BnplApplication(
      id: randomId,
      brand: _selectedBrand,
      modelName: _modelName.trim(),
      storage: _selectedStorage,
      ram: _selectedRam,
      condition: _selectedCondition,
      preferredColor: _selectedColor,
      planDuration: _selectedPlanDuration,
      customerName: _customerName.trim().isEmpty ? 'Customer' : _customerName.trim(),
      customerPhone: _customerPhone.trim(),
      notes: _notes.trim(),
      status: 'Submitted to Manager',
      createdAt: DateTime.now(),
    );

    _submittedApplications.insert(0, application);
    _lastApplication = application;
    _isSubmitting = false;
    _isSubmitted = true;
    notifyListeners();
    return true;
  }

  void resetForm() {
    _isSubmitted = false;
    _isSubmitting = false;
    _errorMessage = null;
    _modelName = '';
    _notes = '';
    notifyListeners();
  }
}

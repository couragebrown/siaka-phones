import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../data/services/supabase_service.dart';
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

  static const List<String> branchOptions = [
    'Siaka Phones Circle',
    'Siaka Phones Madina',
    'Siaka Phones Kasoa',
  ];

  String _selectedBrand = 'iPhone';
  String _modelName = '';
  String _selectedStorage = '256 GB';
  String _selectedRam = '8 GB';
  String _selectedCondition = 'Brand New (Sealed)';
  String _selectedColor = 'Any Available Color';
  String _selectedPlanDuration = 'Monthly';
  String _selectedBranch = 'Siaka Phones Circle';

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
  String get selectedBranch => _selectedBranch;
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

  void setBranch(String branch) {
    _selectedBranch = branch;
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
      preferredBranch: _selectedBranch,
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

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final tenureMonths = int.tryParse(application.planDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 6;
      final bnplMap = {
        'id': 'BNPL_${application.id}',
        'name': '${application.customerName} - ${application.brand} ${application.modelName}',
        'brand': application.brand,
        'category': 'BNPL_RECORD',
        'price': 2800.0,
        'original_price': 3200.0,
        'stock': tenureMonths,
        'specs': jsonEncode({
          'customerName': application.customerName,
          'customerPhone': application.customerPhone,
          'brand': application.brand,
          'modelName': application.modelName,
          'storage': application.storage,
          'ram': application.ram,
          'condition': application.condition,
          'preferredColor': application.preferredColor,
          'planDuration': application.planDuration,
          'preferredBranch': application.preferredBranch,
          'notes': application.notes,
          'status': application.status,
        }),
        'condition': 'pending',
        'storage': application.storage,
        'ram': application.ram,
        'color': application.preferredColor,
        'created_at': application.createdAt.toIso8601String(),
      };

      SupabaseService().upsertRawRecord(bnplMap);

      // Direct local sync post to PC Manager
      () async {
        try {
          final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
          final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
          final req = await client.postUrl(Uri.parse('http://$host:8088/api/bnpl'));
          req.headers.contentType = ContentType.json;
          req.write(jsonEncode({
            'id': application.id,
            'brand': application.brand,
            'modelName': application.modelName,
            'requestedPhone': '${application.brand} ${application.modelName}',
            'storage': application.storage,
            'ram': application.ram,
            'condition': application.condition,
            'deviceCondition': application.condition,
            'preferredColor': application.preferredColor,
            'color': application.preferredColor,
            'planDuration': application.planDuration,
            'preferredBranch': application.preferredBranch,
            'branch': application.preferredBranch,
            'customerName': application.customerName,
            'applicantName': application.customerName,
            'customerPhone': application.customerPhone,
            'phone': application.customerPhone,
            'notes': application.notes,
            'customerNotes': application.notes,
            'status': 'pending',
            'createdAt': application.createdAt.toIso8601String(),
            'applicationDate': application.createdAt.toIso8601String(),
          }));
          await req.close();
        } catch (_) {}

        try {
          final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
          final notifClient = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
          final notifReq = await notifClient.postUrl(Uri.parse('http://$host:8088/api/notifications'));
          notifReq.headers.contentType = ContentType.json;
          notifReq.write(jsonEncode({
            'id': 'NOTIF_BNPL_${application.id}',
            'title': 'New BNPL Application: ${application.brand} ${application.modelName}',
            'message': '${application.customerName} applied for ${application.planDuration} plan on ${application.brand} ${application.modelName} (${application.preferredBranch})',
            'type': 'bnpl',
            'target': 'manager',
            'referenceId': application.id,
          }));
          await notifReq.close();
        } catch (_) {}
      }();
    }

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

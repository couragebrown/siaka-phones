import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../domain/models/swap_model.dart';

class TradeInViewModel extends ChangeNotifier {
  // Brand list for selection
  static const List<String> desiredBrandOptions = [
    'iPhone',
    'Samsung',
    'Tecno',
    'Infinix',
  ];

  static const List<String> currentBrandOptions = [
    'iPhone',
    'Samsung',
    'Tecno',
    'Infinix',
    'Google',
    'Xiaomi',
    'Other',
  ];

  static const Map<String, List<String>> brandModels = {
    'iPhone': [
      'iPhone 15 Pro Max',
      'iPhone 15 Pro',
      'iPhone 15',
      'iPhone 14 Pro Max',
      'iPhone 13',
      'iPhone 12',
      'iPhone 11',
    ],
    'Samsung': [
      'Galaxy S24 Ultra',
      'Galaxy S24+',
      'Galaxy S23 Ultra',
      'Galaxy A55 5G',
      'Galaxy A35 5G',
      'Galaxy Z Flip 5',
    ],
    'Tecno': [
      'Camon 30 Pro 5G',
      'Camon 30 Premier',
      'Spark 20 Pro+',
      'Phantom V Fold',
      'Phantom X2 Pro',
    ],
    'Infinix': [
      'Note 40 Pro+ 5G',
      'Note 40 Pro',
      'Zero 30 5G',
      'GT 20 Pro',
      'Hot 40 Pro',
    ],
    'Google': [
      'Pixel 8 Pro',
      'Pixel 8',
      'Pixel 7 Pro',
      'Pixel 7a',
    ],
    'Xiaomi': [
      'Xiaomi 14 Ultra',
      'Redmi Note 13 Pro+',
      'Poco X6 Pro',
    ],
    'Other': [
      'OnePlus 12',
      'Oppo Reno 11',
      'Vivo V30 Pro',
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

  static const List<String> desiredConditionOptions = [
    'Brand New (Sealed)',
    'Certified Pre-Owned',
  ];

  static const List<String> currentConditionOptions = [
    'Flawless (Like New)',
    'Good (Minor Scratches)',
    'Fair (Visible Wear)',
    'Cracked / Broken',
  ];

  static const List<String> branchOptions = [
    'Circle Main Branch (Opposite VIP)',
    'Madina Branch (Zongo Junction)',
    'Kasoa Branch (Old Barrier)',
  ];

  // 1. Desired Phone State (What the user wants)
  String _desiredBrand = 'iPhone';
  String _desiredModel = '';
  String _desiredStorage = '256 GB';
  String _desiredRam = '8 GB';
  String _desiredCondition = 'Brand New (Sealed)';
  String _desiredColor = 'Default';

  // 2. Current Phone State (What the user is swapping with)
  String _currentBrand = 'iPhone';
  String _currentModel = '';
  String _currentStorage = '128 GB';
  String _currentCondition = 'Good (Minor Scratches)';
  bool _turnsOn = true;
  bool _screenIntact = true;

  // 3. Financial estimates in Ghana Cedis (₵)
  double _estimatedDesiredPrice = 0.0;
  double _estimatedTradeInCredit = 0.0;

  // 4. Contact & Submission Details
  String _applicantName = '';
  String _applicantPhone = '';
  String _preferredBranch = 'Circle Main Branch (Opposite VIP)';
  String _notes = '';

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  SwapApplication? _lastApplication;
  final List<SwapApplication> _submittedApplications = [
    SwapApplication(
      id: 'SWAP-GH-7840',
      desiredBrand: 'iPhone',
      desiredModel: 'iPhone 15 Pro Max',
      desiredStorage: '256 GB',
      desiredRam: '8 GB',
      desiredCondition: 'Brand New (Sealed)',
      desiredColor: 'Natural Titanium',
      currentBrand: 'iPhone',
      currentModel: 'iPhone 13',
      currentStorage: '128 GB',
      currentCondition: 'Good (Minor Scratches)',
      turnsOn: true,
      screenIntact: true,
      applicantName: 'Kwame Mensah',
      applicantPhone: '024 555 0192',
      preferredBranch: 'Circle Main Branch (Opposite VIP)',
      notes: 'Battery health is 87%, with original box',
      status: 'Under Review by Manager',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SwapApplication(
      id: 'SWAP-GH-4921',
      desiredBrand: 'Samsung',
      desiredModel: 'Galaxy S24 Ultra',
      desiredStorage: '512 GB',
      desiredRam: '12 GB',
      desiredCondition: 'Brand New (Sealed)',
      desiredColor: 'Titanium Gray',
      currentBrand: 'Samsung',
      currentModel: 'Galaxy S22',
      currentStorage: '128 GB',
      currentCondition: 'Good (Minor Scratches)',
      turnsOn: true,
      screenIntact: true,
      applicantName: 'Kwame Mensah',
      applicantPhone: '024 555 0192',
      preferredBranch: 'Madina Branch (Zongo Junction)',
      notes: 'Clean device, swapped in-store',
      status: 'Completed / Swapped',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  // Getters - Desired Phone
  String get desiredBrand => _desiredBrand;
  String get desiredModel => _desiredModel;
  String get desiredStorage => _desiredStorage;
  String get desiredRam => _desiredRam;
  String get desiredCondition => _desiredCondition;
  String get desiredColor => _desiredColor;
  double get estimatedDesiredPrice => _estimatedDesiredPrice;

  // Getters - Current Phone
  String get currentBrand => _currentBrand;
  String get currentModel => _currentModel;
  String get currentStorage => _currentStorage;
  String get currentCondition => _currentCondition;
  bool get turnsOn => _turnsOn;
  bool get screenIntact => _screenIntact;
  double get estimatedTradeInCredit => _estimatedTradeInCredit;

  // Financials
  double get estimatedTopUp => max(0.0, _estimatedDesiredPrice - _estimatedTradeInCredit);

  // Backwards compatibility aliases
  String get brand => _currentBrand;
  String get model => _currentModel;
  String get storage => _currentStorage;
  String get condition => _currentCondition;
  double get estimatedQuote => _estimatedTradeInCredit;
  bool get hasCalculated => _isSubmitted;

  // Contact
  String get applicantName => _applicantName;
  String get applicantPhone => _applicantPhone;
  String get preferredBranch => _preferredBranch;
  String get notes => _notes;
  bool get isSubmitting => _isSubmitting;
  bool get isSubmitted => _isSubmitted;
  SwapApplication? get lastApplication => _lastApplication;
  List<SwapApplication> get swapApplications => List.unmodifiable(_submittedApplications);

  TradeInViewModel() {
    _recalculate();
  }

  // Setters - Desired Device
  void setDesiredBrand(String b) {
    if (_desiredBrand != b) {
      _desiredBrand = b;
      notifyListeners();
    }
  }

  void setDesiredModel(String m) {
    _desiredModel = m;
    _recalculate();
  }

  void setDesiredStorage(String s) {
    _desiredStorage = s;
    _recalculate();
  }

  void setDesiredRam(String r) {
    _desiredRam = r;
    _recalculate();
  }

  void setDesiredCondition(String c) {
    _desiredCondition = c;
    _recalculate();
  }

  void setDesiredColor(String c) {
    _desiredColor = c;
    notifyListeners();
  }

  // Setters - Current Device
  void setCurrentBrand(String b) {
    if (_currentBrand != b) {
      _currentBrand = b;
      notifyListeners();
    }
  }

  void setCurrentModel(String m) {
    _currentModel = m;
    _recalculate();
  }

  void setCurrentStorage(String s) {
    _currentStorage = s;
    _recalculate();
  }

  void setCurrentCondition(String c) {
    _currentCondition = c;
    _recalculate();
  }

  void setTurnsOn(bool val) {
    _turnsOn = val;
    _recalculate();
  }

  void setScreenIntact(bool val) {
    _screenIntact = val;
    _recalculate();
  }

  // Setters - Contact info
  void setApplicantName(String name) {
    _applicantName = name;
  }

  void setApplicantPhone(String phone) {
    _applicantPhone = phone;
  }

  void setPreferredBranch(String branch) {
    _preferredBranch = branch;
    notifyListeners();
  }

  void setNotes(String n) {
    _notes = n;
  }

  // Backwards compatibility setters
  void setBrand(String b) => setCurrentBrand(b);
  void setModel(String m) => setCurrentModel(m);
  void setStorage(String s) => setCurrentStorage(s);
  void setCondition(String c) => setCurrentCondition(c);

  void _recalculate() {
    // 1. Calculate Desired Device Retail Price in Cedis (₵)
    double desiredBase = 9500.0;
    final dModelLower = _desiredModel.toLowerCase();

    if (dModelLower.contains('15 pro max')) {
      desiredBase = 15500.0;
    } else if (dModelLower.contains('15 pro')) {
      desiredBase = 13800.0;
    } else if (dModelLower.contains('15')) {
      desiredBase = 10200.0;
    } else if (dModelLower.contains('14 pro max')) {
      desiredBase = 11800.0;
    } else if (dModelLower.contains('13')) {
      desiredBase = 7200.0;
    } else if (dModelLower.contains('12')) {
      desiredBase = 5400.0;
    } else if (dModelLower.contains('s24 ultra')) {
      desiredBase = 14200.0;
    } else if (dModelLower.contains('s24')) {
      desiredBase = 11500.0;
    } else if (dModelLower.contains('s23')) {
      desiredBase = 9200.0;
    } else if (dModelLower.contains('camon 30 premier') || dModelLower.contains('phantom')) {
      desiredBase = 4800.0;
    } else if (dModelLower.contains('camon 30') || dModelLower.contains('gt 20')) {
      desiredBase = 3800.0;
    } else if (dModelLower.contains('note 40')) {
      desiredBase = 3400.0;
    } else if (dModelLower.contains('spark 20') || dModelLower.contains('hot 40')) {
      desiredBase = 2400.0;
    }

    // Storage addition
    if (_desiredStorage == '256 GB') desiredBase += 600.0;
    if (_desiredStorage == '512 GB') desiredBase += 1400.0;
    if (_desiredStorage == '1 TB') desiredBase += 2800.0;

    // RAM addition
    if (_desiredRam == '12 GB') desiredBase += 400.0;
    if (_desiredRam == '16 GB') desiredBase += 800.0;

    // Condition discount
    if (_desiredCondition == 'Certified Pre-Owned') {
      desiredBase *= 0.82;
    }

    _estimatedDesiredPrice = desiredBase.roundToDouble();

    // 2. Calculate Current Device Trade-in Credit in Cedis (₵)
    double creditBase = 5000.0;
    final cModelLower = _currentModel.toLowerCase();

    if (cModelLower.contains('15 pro max')) {
      creditBase = 11000.0;
    } else if (cModelLower.contains('15 pro')) {
      creditBase = 9500.0;
    } else if (cModelLower.contains('15')) {
      creditBase = 7200.0;
    } else if (cModelLower.contains('14 pro max')) {
      creditBase = 8400.0;
    } else if (cModelLower.contains('13')) {
      creditBase = 5200.0;
    } else if (cModelLower.contains('12')) {
      creditBase = 3800.0;
    } else if (cModelLower.contains('11')) {
      creditBase = 2800.0;
    } else if (cModelLower.contains('s24 ultra')) {
      creditBase = 10200.0;
    } else if (cModelLower.contains('s24')) {
      creditBase = 7800.0;
    } else if (cModelLower.contains('s23')) {
      creditBase = 6200.0;
    } else if (cModelLower.contains('s22')) {
      creditBase = 4200.0;
    } else if (cModelLower.contains('camon') || cModelLower.contains('note')) {
      creditBase = 2200.0;
    } else if (cModelLower.contains('spark') || cModelLower.contains('hot')) {
      creditBase = 1400.0;
    }

    if (_currentStorage == '256 GB') creditBase += 400.0;
    if (_currentStorage == '512 GB') creditBase += 800.0;
    if (_currentStorage == '1 TB') creditBase += 1500.0;

    if (_currentCondition == 'Flawless (Like New)') {
      creditBase *= 1.0;
    } else if (_currentCondition == 'Good (Minor Scratches)') {
      creditBase *= 0.85;
    } else if (_currentCondition == 'Fair (Visible Wear)') {
      creditBase *= 0.65;
    } else {
      creditBase *= 0.35;
    }

    if (!_turnsOn) creditBase *= 0.45;
    if (!_screenIntact) creditBase *= 0.55;

    _estimatedTradeInCredit = creditBase.roundToDouble();
    notifyListeners();
  }

  Future<void> submitSwapRequest() async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final randomId = 'SWAP-GH-${1000 + Random().nextInt(9000)}';
    final application = SwapApplication(
      id: randomId,
      desiredBrand: _desiredBrand,
      desiredModel: _desiredModel,
      desiredStorage: _desiredStorage,
      desiredRam: _desiredRam,
      desiredCondition: _desiredCondition,
      desiredColor: _desiredColor,
      estimatedDesiredPrice: _estimatedDesiredPrice,
      currentBrand: _currentBrand,
      currentModel: _currentModel,
      currentStorage: _currentStorage,
      currentCondition: _currentCondition,
      turnsOn: _turnsOn,
      screenIntact: _screenIntact,
      estimatedTradeInCredit: _estimatedTradeInCredit,
      estimatedTopUp: estimatedTopUp,
      applicantName: _applicantName,
      applicantPhone: _applicantPhone,
      preferredBranch: _preferredBranch,
      notes: _notes,
      createdAt: DateTime.now(),
    );

    _submittedApplications.insert(0, application);
    _lastApplication = application;
    _isSubmitting = false;
    _isSubmitted = true;
    notifyListeners();
  }

  void reset() {
    _isSubmitted = false;
    _isSubmitting = false;
    _desiredModel = '';
    _currentModel = '';
    _applicantName = '';
    _applicantPhone = '';
    _notes = '';
    notifyListeners();
  }

  void lockQuote() {
    _isSubmitted = true;
    notifyListeners();
  }
}

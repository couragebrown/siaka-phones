import 'package:flutter/foundation.dart';
import '../../../domain/models/trade_in_quote.dart';

class TradeInViewModel extends ChangeNotifier {
  String _brand = 'Apple';
  String _model = 'iPhone 15 Pro Max';
  String _storage = '256 GB';
  String _condition = 'Flawless';
  bool _turnsOn = true;
  bool _screenIntact = true;
  double _estimatedQuote = 650.0;
  bool _hasCalculated = false;

  String get brand => _brand;
  String get model => _model;
  String get storage => _storage;
  String get condition => _condition;
  bool get turnsOn => _turnsOn;
  bool get screenIntact => _screenIntact;
  double get estimatedQuote => _estimatedQuote;
  bool get hasCalculated => _hasCalculated;

  void setBrand(String b) {
    _brand = b;
    _recalculate();
  }

  void setModel(String m) {
    _model = m;
    _recalculate();
  }

  void setStorage(String s) {
    _storage = s;
    _recalculate();
  }

  void setCondition(String c) {
    _condition = c;
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

  void _recalculate() {
    double base = 600.0;
    if (_model.contains('15 Pro') || _model.contains('S24 Ultra')) base = 700.0;
    if (_model.contains('14') || _model.contains('S23')) base = 480.0;

    if (_storage == '512 GB') base += 80.0;
    if (_storage == '1 TB') base += 150.0;

    if (_condition == 'Good') base *= 0.85;
    if (_condition == 'Fair') base *= 0.65;
    if (_condition == 'Broken') base *= 0.35;

    if (!_turnsOn) base *= 0.4;
    if (!_screenIntact) base *= 0.6;

    _estimatedQuote = base.roundToDouble();
    notifyListeners();
  }

  void lockQuote() {
    _hasCalculated = true;
    notifyListeners();
  }

  void reset() {
    _hasCalculated = false;
    notifyListeners();
  }
}

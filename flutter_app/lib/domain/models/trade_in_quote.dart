class TradeInQuote {
  final String id;
  final String brand;
  final String model;
  final String storage;
  final String condition;
  final bool turnsOn;
  final bool screenIntact;
  final double estimatedValue;
  final DateTime quoteDate;

  const TradeInQuote({
    required this.id,
    required this.brand,
    required this.model,
    required this.storage,
    required this.condition,
    required this.turnsOn,
    required this.screenIntact,
    required this.estimatedValue,
    required this.quoteDate,
  });
}

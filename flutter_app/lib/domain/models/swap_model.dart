class SwapApplication {
  final String id;
  // Phone the user wants
  final String desiredBrand;
  final String desiredModel;
  final String desiredStorage;
  final String desiredRam;
  final String desiredCondition;
  final String desiredColor;

  // Phone the user is swapping with
  final String currentBrand;
  final String currentModel;
  final String currentStorage;
  final String currentCondition;
  final bool turnsOn;
  final bool screenIntact;

  // Contact details
  final String applicantName;
  final String applicantPhone;
  final String preferredBranch;
  final String notes;
  final String status;
  final DateTime createdAt;

  // Optional legacy price fields (defaults to 0.0)
  final double estimatedDesiredPrice;
  final double estimatedTradeInCredit;
  final double estimatedTopUp;

  const SwapApplication({
    required this.id,
    required this.desiredBrand,
    required this.desiredModel,
    required this.desiredStorage,
    required this.desiredRam,
    required this.desiredCondition,
    required this.desiredColor,
    required this.currentBrand,
    required this.currentModel,
    required this.currentStorage,
    required this.currentCondition,
    required this.turnsOn,
    required this.screenIntact,
    required this.applicantName,
    required this.applicantPhone,
    required this.preferredBranch,
    required this.notes,
    this.status = 'Under Review by Manager',
    required this.createdAt,
    this.estimatedDesiredPrice = 0.0,
    this.estimatedTradeInCredit = 0.0,
    this.estimatedTopUp = 0.0,
  });
}

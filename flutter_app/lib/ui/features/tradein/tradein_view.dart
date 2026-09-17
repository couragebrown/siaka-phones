import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/dialer_service.dart';
import '../../../domain/models/swap_model.dart';
import 'tradein_view_model.dart';

class TradeInView extends StatefulWidget {
  final TradeInViewModel viewModel;
  final VoidCallback onApplyToPurchase;

  const TradeInView({
    super.key,
    required this.viewModel,
    required this.onApplyToPurchase,
  });

  @override
  State<TradeInView> createState() => _TradeInViewState();
}

class _TradeInViewState extends State<TradeInView> {
  final TextEditingController _desiredModelController = TextEditingController();
  final TextEditingController _currentModelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _desiredModelController.text = widget.viewModel.desiredModel;
    _currentModelController.text = widget.viewModel.currentModel;
    _nameController.text = widget.viewModel.applicantName;
    _phoneController.text = widget.viewModel.applicantPhone;
    _notesController.text = widget.viewModel.notes;
  }

  @override
  void dispose() {
    _desiredModelController.dispose();
    _currentModelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _callCustomerService(BuildContext context) async {
    final success = await DialerService.openDialer('+2330245550192');
    if (success) return;

    Clipboard.setData(const ClipboardData(text: '+2330245550192'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Customer service number copied: +233 (024) 555-0192',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isSubmitted && widget.viewModel.lastApplication != null) {
          return _buildSubmittedView(context, widget.viewModel.lastApplication!);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swap My Device',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Trade-In & Instant Upgrade in Cedis',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Call Customer Service',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(Icons.phone_outlined,
                      color: Color(0xFF1C7BFF), size: 18),
                ),
                onPressed: () => _callCustomerService(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 16),
                _buildDesiredDeviceSection(),
                const SizedBox(height: 16),
                _buildCurrentDeviceSection(),
                const SizedBox(height: 16),
                _buildSwapCalculationCard(),
                const SizedBox(height: 16),
                _buildContactSection(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C7BFF), Color(0xFF0F56C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C7BFF).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Official Siaka Swap Program',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Top Value Guaranteed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upgrade Your Phone Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the phone you want with your preferred specifications, tell us what you have, and our Store Manager will contact you with the best valuation and cost!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Section 1: Phone the user wants
  Widget _buildDesiredDeviceSection() {
    final vm = widget.viewModel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepBadge('1', const Color(0xFF1C7BFF)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone You Want',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Select brand, model & your preferred specifications',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Brand selection cards
          const Text(
            'Select Phone Brand',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TradeInViewModel.desiredBrandOptions.map((brand) {
                final isSelected = vm.desiredBrand == brand;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      vm.setDesiredBrand(brand);
                      _desiredModelController.text = vm.desiredModel;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            brand == 'iPhone'
                                ? Icons.apple_rounded
                                : brand == 'Samsung'
                                    ? Icons.phone_android_rounded
                                    : Icons.smartphone_rounded,
                            size: 16,
                            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            brand,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Phone Model input
          const Text(
            'Model / Name You Want',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _desiredModelController,
            onChanged: (val) => vm.setDesiredModel(val),
            decoration: InputDecoration(
              hintText: 'e.g. iPhone 15 Pro Max, Galaxy S24...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF1C7BFF), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1C7BFF), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick popular suggestions for desired brand
          Text(
            'Popular ${vm.desiredBrand} suggestions (Tap to select):',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (TradeInViewModel.brandModels[vm.desiredBrand] ?? []).take(5).map((model) {
              final isMatch = vm.desiredModel.toLowerCase() == model.toLowerCase();
              return InkWell(
                onTap: () {
                  _desiredModelController.text = model;
                  vm.setDesiredModel(model);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMatch ? const Color(0xFF1C7BFF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMatch ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    model,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isMatch ? FontWeight.bold : FontWeight.w500,
                      color: isMatch ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Preferred Storage
          const Text(
            'Preferred Storage',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: TradeInViewModel.storageOptions.map((s) {
              final isSel = vm.desiredStorage == s;
              return ChoiceChip(
                label: Text(s, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : const Color(0xFF334155))),
                selected: isSel,
                selectedColor: const Color(0xFF1C7BFF),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (_) => vm.setDesiredStorage(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Preferred RAM
          const Text(
            'Preferred RAM',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: TradeInViewModel.ramOptions.map((r) {
              final isSel = vm.desiredRam == r;
              return ChoiceChip(
                label: Text(r, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : const Color(0xFF334155))),
                selected: isSel,
                selectedColor: const Color(0xFF1C7BFF),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (_) => vm.setDesiredRam(r),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Condition (Brand New / Pre-Owned)
          const Text(
            'Desired Condition',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: TradeInViewModel.desiredConditionOptions.map((c) {
              final isSel = vm.desiredCondition == c;
              return ChoiceChip(
                label: Text(c, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : const Color(0xFF334155))),
                selected: isSel,
                selectedColor: const Color(0xFF1C7BFF),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (_) => vm.setDesiredCondition(c),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device specs saved. Official device cost is provided directly by Store Manager.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section 2: Phone the user is swapping with
  Widget _buildCurrentDeviceSection() {
    final vm = widget.viewModel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepBadge('2', const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Phone You Are Swapping',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Provide your current device details to calculate trade-in credit',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Current Brand selection
          const Text(
            'Select Current Phone Brand',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TradeInViewModel.currentBrandOptions.map((brand) {
                final isSelected = vm.currentBrand == brand;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      vm.setCurrentBrand(brand);
                      _currentModelController.text = vm.currentModel;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        brand,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFFB45309) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Current Model input
          const Text(
            'Your Current Model Name',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _currentModelController,
            onChanged: (val) => vm.setCurrentModel(val),
            decoration: InputDecoration(
              hintText: 'e.g. iPhone 13, Galaxy S22...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.devices_other_rounded, color: Color(0xFFF59E0B), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick suggestions for current brand
          Text(
            'Common ${vm.currentBrand} models:',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (TradeInViewModel.brandModels[vm.currentBrand] ?? []).take(5).map((model) {
              final isMatch = vm.currentModel.toLowerCase() == model.toLowerCase();
              return InkWell(
                onTap: () {
                  _currentModelController.text = model;
                  vm.setCurrentModel(model);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMatch ? const Color(0xFFF59E0B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMatch ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    model,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isMatch ? FontWeight.bold : FontWeight.w500,
                      color: isMatch ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Current Storage
          const Text(
            'Current Phone Storage',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: TradeInViewModel.storageOptions.map((s) {
              final isSel = vm.currentStorage == s;
              return ChoiceChip(
                label: Text(s, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : const Color(0xFF334155))),
                selected: isSel,
                selectedColor: const Color(0xFFF59E0B),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (_) => vm.setCurrentStorage(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Current Condition
          const Text(
            'Current Physical Condition',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TradeInViewModel.currentConditionOptions.map((c) {
              final isSel = vm.currentCondition == c;
              return ChoiceChip(
                label: Text(c, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : const Color(0xFF334155))),
                selected: isSel,
                selectedColor: const Color(0xFFF59E0B),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (_) => vm.setCurrentCondition(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Device Health Checks
          const Text(
            'Functional Checks',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => vm.setTurnsOn(!vm.turnsOn),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: vm.turnsOn,
                      onChanged: (val) => vm.setTurnsOn(val ?? true),
                      activeColor: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Phone powers on and charges normally',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => vm.setScreenIntact(!vm.screenIntact),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: vm.screenIntact,
                      onChanged: (val) => vm.setScreenIntact(val ?? true),
                      activeColor: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Touchscreen and camera work properly',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trade-in valuation is evaluated and confirmed by our Store Manager.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section 3: Swap Valuation Card
  Widget _buildSwapCalculationCard() {
    final vm = widget.viewModel;

    final wantedName = vm.desiredModel.trim().isNotEmpty
        ? '${vm.desiredBrand} ${vm.desiredModel}'
        : '${vm.desiredBrand} (Model not entered)';

    final currentName = vm.currentModel.trim().isNotEmpty
        ? '${vm.currentBrand} ${vm.currentModel}'
        : '${vm.currentBrand} (Model not entered)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C7BFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SWAP SUMMARY',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Text(
                'Valuation by Store Manager',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Desired Phone line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.smartphone_rounded, color: Color(0xFF4ADE80), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wanted: $wantedName',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${vm.desiredStorage} • ${vm.desiredRam} • ${vm.desiredCondition}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TARGET',
                  style: TextStyle(color: Color(0xFF4ADE80), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Trade-in phone line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFBBF24), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Swapping: $currentName',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${vm.currentStorage} • ${vm.currentCondition}',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TRADE-IN',
                  style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFF334155), height: 1),
          ),

          // Store Manager will contact you note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_in_talk_rounded, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager Will Contact You for Cost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No upfront cost. The Store Manager will review specs and contact you with valuation and top-up difference.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section 4: Contact & Branch Selection
  Widget _buildContactSection() {
    final vm = widget.viewModel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepBadge('3', const Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Contact & Preferred Branch',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Where you will bring your phone for in-store physical swap',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Applicant Name
          const Text(
            'Your Full Name *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            onChanged: (val) => vm.setApplicantName(val),
            decoration: InputDecoration(
              hintText: 'e.g. Kwame Mensah',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Phone Number
          const Text(
            'Phone / WhatsApp Number *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (val) => vm.setApplicantPhone(val),
            decoration: InputDecoration(
              hintText: 'e.g. 024 555 0192',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preferred Branch
          const Text(
            'Preferred Siaka Store Branch *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: vm.preferredBranch,
                items: TradeInViewModel.branchOptions.map((branch) {
                  return DropdownMenuItem(
                    value: branch,
                    child: Text(
                      branch,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) vm.setPreferredBranch(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          const Text(
            'Additional Notes for Manager (Optional)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 2,
            onChanged: (val) => vm.setNotes(val),
            decoration: InputDecoration(
              hintText: 'e.g. Battery health is 88%, comes with original box & charger...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge(String number, Color color) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final vm = widget.viewModel;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C7BFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: vm.isSubmitting
            ? null
            : () async {
                if (vm.desiredModel.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select or type the phone model you want.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (vm.currentModel.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select or type the phone you are swapping.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                await vm.submitSwapRequest();
              },
        child: vm.isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Submit Swap Request for Manager Review',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Submission Confirmation View
  Widget _buildSubmittedView(BuildContext context, SwapApplication app) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            widget.viewModel.reset();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Swap Request Submitted',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Swap Request Sent to Manager!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reference #${app.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C7BFF),
            ),
          ),
          const SizedBox(height: 20),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Swap Device Breakdown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                // Wanted Phone
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smartphone_rounded, color: Color(0xFF16A34A), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone You Want',
                              style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${app.desiredBrand} ${app.desiredModel}',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '${app.desiredStorage} • ${app.desiredRam} • ${app.desiredCondition}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Target Device',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Swapped Phone
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: Color(0xFFD97706), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Device You Are Swapping',
                              style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${app.currentBrand} ${app.currentModel}',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '${app.currentStorage} • ${app.currentCondition}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Trade-In Device',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),

                // Valuation & Cost Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.contact_phone_rounded, color: Color(0xFF1C7BFF), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valuation & Cost: Pending Manager Review',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'The Store Manager will contact you with the verified valuation and final top-up difference.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Branch & Applicant
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.store_mall_directory_rounded, size: 16, color: Color(0xFF1C7BFF)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Branch: ${app.preferredBranch}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Applicant: ${app.applicantName} (${app.applicantPhone})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manager review note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1C7BFF), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Our Store Manager will verify your device specs and contact you directly via phone / WhatsApp within 30-60 minutes to finalize your swap! You can also bring your phone to the branch directly.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C7BFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Call Store Manager (+233 024 555-0192)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              onPressed: () => _callCustomerService(context),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.viewModel.reset();
              },
              child: const Text(
                'Submit Another Swap Request',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              widget.viewModel.reset();
              widget.onApplyToPurchase();
            },
            child: const Text(
              'Back to Catalog / Home',
              style: TextStyle(color: Color(0xFF1C7BFF), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}
}

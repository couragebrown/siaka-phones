import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/dialer_service.dart';
import '../../../domain/models/bnpl_model.dart';
import 'bnpl_view_model.dart';

class BnplView extends StatefulWidget {
  final BnplViewModel viewModel;
  final VoidCallback? onReturnHome;

  const BnplView({
    super.key,
    required this.viewModel,
    this.onReturnHome,
  });

  @override
  State<BnplView> createState() => _BnplViewState();
}

class _BnplViewState extends State<BnplView> {
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _modelController.text = widget.viewModel.modelName;
    _nameController.text = widget.viewModel.customerName;
    _phoneController.text = widget.viewModel.customerPhone;
    _notesController.text = widget.viewModel.notes;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _callCustomerServiceLine(BuildContext context) async {
    final success = await DialerService.openDialer('+2330245550192');
    if (success) {
      return;
    }

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
                'Customer service number copied to clipboard: +233 (024) 555-0192',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black12,
            iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
            title: const Column(
              children: [
                Text(
                  'Buy Now Pay Later',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '0% APR Installment Plans with Siaka Pay',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: vm.isSubmitted && vm.lastApplication != null
              ? _buildSuccessView(context, vm.lastApplication!)
              : _buildApplicationForm(context, vm),
        );
      },
    );
  }

  Widget _buildApplicationForm(BuildContext context, BnplViewModel vm) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        // Intro Hero Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1C7BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C7BFF).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Direct Manager Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '0% Interest',
                    style: TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Get Your Dream Device Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select between our featured phone brands, type your model, pick your specs, and our Store Manager will review your custom plan and reply to you directly.',
                style: TextStyle(
                  color: Color(0xFFE0E7FF),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Error message banner if any
        if (vm.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // STEP 1: Select Brand
        _buildSectionHeader(
          stepNumber: '1',
          title: 'Select Phone Brand',
          subtitle: 'Choose between Tecno, Infinix, Samsung, or iPhone',
        ),
        const SizedBox(height: 10),
        _buildBrandSelector(vm),

        const SizedBox(height: 22),

        // STEP 2: Type Phone Name / Model
        _buildSectionHeader(
          stepNumber: '2',
          title: 'Type Phone Model / Name',
          subtitle: 'Enter the exact model or tap a popular suggestion',
        ),
        const SizedBox(height: 10),
        _buildModelInput(vm),

        const SizedBox(height: 22),

        // STEP 3: Select Specs
        _buildSectionHeader(
          stepNumber: '3',
          title: 'Select Phone Specifications',
          subtitle: 'Configure storage, RAM, condition, and installment duration',
        ),
        const SizedBox(height: 12),
        _buildSpecsSelector(vm),

        const SizedBox(height: 22),

        // STEP 4: Contact & Manager Notes
        _buildSectionHeader(
          stepNumber: '4',
          title: 'Your Contact Details',
          subtitle: 'Our Store Manager will contact you via WhatsApp / Call',
        ),
        const SizedBox(height: 12),
        _buildContactSection(vm),

        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: const Color(0xFF1C7BFF).withValues(alpha: 0.3),
            ),
            onPressed: vm.isSubmitting
                ? null
                : () {
                    // Update latest values from text controllers
                    vm.setModelName(_modelController.text);
                    vm.setCustomerName(_nameController.text);
                    vm.setCustomerPhone(_phoneController.text);
                    vm.setNotes(_notesController.text);
                    vm.submitApplication();
                  },
            child: vm.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Submit for Manager Review',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Customer service hotline quick card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.headset_mic_rounded,
                  color: Color(0xFF1C7BFF), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Questions? Hotline: +233 (024) 555-0192',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _callCustomerServiceLine(context),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Call',
                  style: TextStyle(
                    color: Color(0xFF1C7BFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1C7BFF),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSelector(BnplViewModel vm) {
    const brandIcons = {
      'Tecno': Icons.phone_android_rounded,
      'Infinix': Icons.bolt_rounded,
      'Samsung': Icons.devices_other_rounded,
      'iPhone': Icons.apple_rounded,
    };

    return Row(
      children: BnplViewModel.supportedBrands.map((brand) {
        final isSelected = vm.selectedBrand == brand;
        final icon = brandIcons[brand] ?? Icons.smartphone_rounded;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                vm.setBrand(brand);
                // If text controller is empty or matches previous brand, clear or suggest
                if (_modelController.text.isNotEmpty &&
                    !_modelController.text.toLowerCase().contains(brand.toLowerCase())) {
                  // Keep whatever custom text user typed or set hint
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1C7BFF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF1C7BFF).withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.white : const Color(0xFF1C7BFF),
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      brand,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModelInput(BnplViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          TextField(
            controller: _modelController,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Model / Name *',
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
              hintText: 'e.g. ${vm.selectedBrand == "iPhone" ? "iPhone 15 Pro Max" : vm.selectedBrand == "Samsung" ? "Galaxy S24 Ultra" : vm.selectedBrand == "Tecno" ? "Camon 30 Pro 5G" : "Note 40 Pro+ 5G"}',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.phone_iphone_rounded,
                color: Color(0xFF1C7BFF),
                size: 20,
              ),
              suffixIcon: _modelController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        _modelController.clear();
                        vm.setModelName('');
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1C7BFF), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              vm.setModelName(val);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Popular ${vm.selectedBrand} models (Tap to select):',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vm.currentBrandSuggestions.map((model) {
              final isChosen =
                  _modelController.text.trim().toLowerCase() ==
                      model.toLowerCase();
              return ActionChip(
                label: Text(model),
                labelStyle: TextStyle(
                  color: isChosen ? Colors.white : const Color(0xFF334155),
                  fontSize: 11.5,
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.w500,
                ),
                backgroundColor:
                    isChosen ? const Color(0xFF1C7BFF) : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isChosen
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () {
                  _modelController.text = model;
                  vm.setModelName(model);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsSelector(BnplViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Storage
          _buildSpecOptionGroup(
            title: 'Internal Storage',
            icon: Icons.storage_rounded,
            options: BnplViewModel.storageOptions,
            selectedValue: vm.selectedStorage,
            onSelected: vm.setStorage,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // RAM
          _buildSpecOptionGroup(
            title: 'RAM / Memory',
            icon: Icons.memory_rounded,
            options: BnplViewModel.ramOptions,
            selectedValue: vm.selectedRam,
            onSelected: vm.setRam,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Condition
          _buildSpecOptionGroup(
            title: 'Device Condition',
            icon: Icons.verified_outlined,
            options: BnplViewModel.conditionOptions,
            selectedValue: vm.selectedCondition,
            onSelected: vm.setCondition,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Installment Term
          _buildSpecOptionGroup(
            title: 'Installment Duration',
            icon: Icons.calendar_month_rounded,
            options: BnplViewModel.planDurationOptions,
            selectedValue: vm.selectedPlanDuration,
            onSelected: vm.setPlanDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecOptionGroup({
    required String title,
    required IconData icon,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1C7BFF)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final isSel = opt == selectedValue;
            return ChoiceChip(
              label: Text(opt),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : const Color(0xFF334155),
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
              selected: isSel,
              selectedColor: const Color(0xFF1C7BFF),
              backgroundColor: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFFCBD5E1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              onSelected: (_) => onSelected(opt),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContactSection(BnplViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Full Name *',
              prefixIcon:
                  const Icon(Icons.person_outline_rounded, color: Color(0xFF1C7BFF), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => vm.setCustomerName(val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Phone Number / WhatsApp *',
              hintText: 'e.g. 024 XXX XXXX',
              prefixIcon:
                  const Icon(Icons.phone_outlined, color: Color(0xFF1C7BFF), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => vm.setCustomerPhone(val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Notes for Store Manager (Optional)',
              hintText: 'Preferred branch pickup (Circle, Madina, Kasoa) or color preference...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.note_alt_outlined, color: Color(0xFF1C7BFF), size: 20),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => vm.setNotes(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, BnplApplication application) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // Success Header Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Application Submitted to Manager!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'Reference: ${application.id}',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you, ${application.customerName}! Your request has been queued directly for the Siaka Phones Store Manager.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Manager response expected within 30 - 60 minutes on ${application.customerPhone} (WhatsApp/Phone).',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Requested Configuration Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_outlined,
                      color: Color(0xFF1C7BFF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Requested Phone & Specs',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildSummaryRow('Selected Brand', application.brand),
              _buildSummaryRow('Phone Model', application.modelName),
              _buildSummaryRow('Internal Storage', application.storage),
              _buildSummaryRow('RAM / Memory', application.ram),
              _buildSummaryRow('Condition', application.condition),
              _buildSummaryRow('Financing Duration', application.planDuration),
              if (application.notes.isNotEmpty)
                _buildSummaryRow('Notes', application.notes),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Customer Service Hotline Action
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.headset_mic_rounded,
                      color: Color(0xFF1C7BFF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Need Instant Approval?',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'You can call our dedicated customer service line directly to speak with the on-duty manager regarding your request.',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C7BFF),
                    side: const BorderSide(color: Color(0xFF1C7BFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: const Text(
                    'Call Customer Service: +233 (024) 555-0192',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () => _callCustomerServiceLine(context),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Buttons: Submit Another or Return Home
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                onPressed: () {
                  widget.viewModel.resetForm();
                  _modelController.clear();
                  _notesController.clear();
                },
                child: const Text(
                  'Submit Another Request',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (widget.onReturnHome != null) {
                    widget.onReturnHome!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(
                  'Return to Shop',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

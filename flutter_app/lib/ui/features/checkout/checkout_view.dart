import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../../domain/models/order.dart';
import 'checkout_view_model.dart';

class CheckoutView extends StatefulWidget {
  final CheckoutViewModel viewModel;
  final Function(OrderModel) onOrderPlaced;

  const CheckoutView({
    super.key,
    required this.viewModel,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _zipController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.viewModel.fullName);
    _addressController = TextEditingController(text: widget.viewModel.address);
    _cityController = TextEditingController(text: widget.viewModel.city);
    _zipController = TextEditingController(text: widget.viewModel.zip);
    _phoneController = TextEditingController(text: widget.viewModel.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Express Checkout'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Shipping Details Card
                const Text('1. Delivery Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Recipient Full Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildTextField(_addressController, 'Street Address', Icons.home_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_cityController, 'City', Icons.location_city_outlined)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_zipController, 'ZIP Code', Icons.mail_outline)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_phoneController, 'Mobile Phone for Tracking SMS', Icons.phone_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Method Card
                const Text('2. Payment Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildPaymentOption('Siaka Apple Pay', Icons.apple, 'Instant 1-Click biometric auth'),
                      const Divider(color: AppColors.borderLight, height: 16),
                      _buildPaymentOption('Credit / Debit Card', Icons.credit_card, 'Visa, Mastercard, Amex'),
                      const Divider(color: AppColors.borderLight, height: 16),
                      _buildPaymentOption('Siaka 0% APR Financing', Icons.savings_outlined, 'Split in 4 payments of \$${(widget.viewModel.total / 4).toStringAsFixed(2)}'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Total Summary Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Due', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          Text(
                            '\$${widget.viewModel.total.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                NeonButton(
                  label: 'Confirm & Place Order',
                  icon: Icons.shield_rounded,
                  isLoading: widget.viewModel.isPlacingOrder,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      widget.viewModel.updateShippingInfo(
                        fullName: _nameController.text,
                        address: _addressController.text,
                        city: _cityController.text,
                        zip: _zipController.text,
                        phone: _phoneController.text,
                      );
                      final order = await widget.viewModel.placeOrder();
                      if (order != null) {
                        widget.onOrderPlaced(order);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 14, color: AppColors.neonEmerald),
                      SizedBox(width: 6),
                      Text(
                        '256-bit Encrypted Bank-Grade Security',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.cyan, size: 20),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String subtitle) {
    final isSelected = widget.viewModel.selectedPaymentMethod == title;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.viewModel.selectPaymentMethod(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan.withOpacity(0.15) : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppColors.cyan : AppColors.borderLight),
              ),
              child: Icon(icon, color: isSelected ? AppColors.cyan : Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

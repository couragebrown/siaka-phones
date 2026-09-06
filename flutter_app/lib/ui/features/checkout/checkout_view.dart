import 'package:flutter/material.dart';
import '../../../domain/models/order.dart';
import 'checkout_view_model.dart';

class CheckoutView extends StatefulWidget {
  final CheckoutViewModel viewModel;
  final ValueChanged<int> onTabSelected;
  final Function(OrderModel) onOrderPlaced;

  const CheckoutView({
    super.key,
    required this.viewModel,
    required this.onTabSelected,
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

  int _selectedAddressIndex = 1;
  int _selectedShippingIndex = 1;
  int _checkoutStep = 0;

  final List<Map<String, String>> _addresses = [
    {
      'name': 'John Doe',
      'type': 'Default',
      'line1': '123 Tech Street, Silicon Valley',
      'line2': 'San Francisco, CA 94107, USA',
      'phone': '+1(555) 123-4567',
    },
    {
      'name': 'John Doe',
      'type': '',
      'line1': '456 Innovation Drive, Apt 12B',
      'line2': 'New York, NY 10001, USA',
      'phone': '+1(555) 987-6543',
    },
  ];

  final List<Map<String, dynamic>> _shippingOptions = [
    {'label': 'Standard Shipping (3–5 days)', 'price': 'FREE'},
    {'label': 'Expedited Shipping (2–3 days)', 'price': '₵9.99'},
    {'label': 'Overnight Shipping (1 day)', 'price': '₵19.99'},
  ];

  int _selectedPaymentIndex = 0;
  bool _saveCard = true;

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
        final content = _buildStepContent();

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1F2937)),
              onPressed: () {
                if (_checkoutStep == 0) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _checkoutStep--);
                }
              },
            ),
            title: const Text('Checkout',
                style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: content,
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent() {
    if (_checkoutStep == 1) {
      return _buildPaymentStep();
    }

    if (_checkoutStep == 2) {
      return _buildReviewStep();
    }

    return _buildShippingStep();
  }

  Widget _buildShippingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _checkoutHeader(),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping Address',
                style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Change',
                style: TextStyle(
                    color: Color(0xFF1C7BFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        RadioGroup<int>(
          groupValue: _selectedAddressIndex,
          onChanged: (value) =>
              setState(() => _selectedAddressIndex = value ?? 0),
          child: Column(
            children: [
              ...List.generate(_addresses.length, (index) {
                final address = _addresses[index];
                final isSelected = _selectedAddressIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedAddressIndex = index),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.white : const Color(0xFFF7F9FB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          activeColor: const Color(0xFF1C7BFF),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${address['name']} ',
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if ((address['type'] ?? '').isNotEmpty)
                                      TextSpan(
                                        text: address['type'],
                                        style: const TextStyle(
                                          color: Color(0xFF667085),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                address['line1'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF475467),
                                  fontSize: 14,
                                ),
                              ),
                              if ((address['line2'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  address['line2']!,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Phone: ${address['phone'] ?? ''}',
                                style: const TextStyle(
                                  color: Color(0xFF475467),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showAddAddressDialog,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6, bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1C7BFF), width: 1.5),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Color(0xFF1C7BFF), size: 30),
                  SizedBox(width: 8),
                  Text(
                    'Add New Address',
                    style: TextStyle(
                      color: Color(0xFF1C7BFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text('Shipping Method',
            style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        RadioGroup<int>(
          groupValue: _selectedShippingIndex,
          onChanged: (value) =>
              setState(() => _selectedShippingIndex = value ?? 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: List.generate(_shippingOptions.length, (index) {
                final option = _shippingOptions[index];
                final selected = _selectedShippingIndex == index;
                return _shippingOption(
                    option['label'],
                    option['price'],
                    selected,
                    () => setState(() => _selectedShippingIndex = index));
              }),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text('Order Summary',
            style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('iPhone 15 Pro Max',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text('₵1,099',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: TextStyle(color: Color(0xFF1F2937))),
                  Text('₵1,287',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shipping', style: TextStyle(color: Color(0xFF1F2937))),
                  Text('FREE',
                      style: TextStyle(
                          color: Color(0xFF0F9F65),
                          fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Tax',
                      style: TextStyle(color: Color(0xFF1F2937))),
                  Text('₵103',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('₵1,390',
                      style: TextStyle(
                          color: Color(0xFF1C7BFF),
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                widget.viewModel.updateShippingInfo(
                  fullName: _nameController.text,
                  address: _addressController.text,
                  city: _cityController.text,
                  zip: _zipController.text,
                  phone: _phoneController.text,
                );
                setState(() => _checkoutStep = 1);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continue to Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return RadioGroup<int>(
      groupValue: _selectedPaymentIndex,
      onChanged: (value) => setState(() => _selectedPaymentIndex = value ?? 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _checkoutHeader(),
          const SizedBox(height: 18),
          const Text('Payment Method',
              style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1C7BFF), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Radio<int>(
                      value: 0,
                      activeColor: Color(0xFF1C7BFF),
                    ),
                    Container(
                      width: 38,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text('VISA',
                            style: TextStyle(
                                color: Color(0xFF1C7BFF),
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Credit / Debit Card',
                        style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFF1F2937), size: 28),
                  ],
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card Number',
                              style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '1234 5678 9012 3456',
                                filled: true,
                                fillColor: Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VISA',
                              style: TextStyle(
                                  color: Color(0xFF1C7BFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          SizedBox(height: 1),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expiry Date',
                              style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '08 / 28',
                                filled: true,
                                fillColor: Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CVV',
                              style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: TextField(
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: '...',
                                filled: true,
                                fillColor: Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide:
                                      BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Name on Card',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'John Doe',
                      filled: true,
                      fillColor: Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Checkbox(
                      value: _saveCard,
                      onChanged: (value) =>
                          setState(() => _saveCard = value ?? false),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      activeColor: const Color(0xFF1C7BFF),
                    ),
                    const Expanded(
                      child: Text(
                        'Save this card for faster checkout',
                        style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _paymentMethodTile('Mastercard', 1),
          const SizedBox(height: 12),
          _paymentMethodTile('PayPal', 2),
          const SizedBox(height: 12),
          _paymentMethodTile('Apple Pay', 3),
          const SizedBox(height: 12),
          _paymentMethodTile('Google Pay', 4),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Details',
                  style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _priceRow('Subtotal', '₵1,287'),
                const SizedBox(height: 12),
                _priceRow('Shipping', 'FREE',
                    valueColor: const Color(0xFF0F9F65)),
                const SizedBox(height: 12),
                _priceRow('Estimated Tax', '₵103'),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 14),
                _priceRow(
                  'Total',
                  '₵1,390',
                  labelStyle: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                  valueColor: const Color(0xFF1C7BFF),
                  valueStyle: const TextStyle(
                      color: Color(0xFF1C7BFF),
                      fontSize: 28,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => _checkoutStep = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C7BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue to Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _checkoutHeader(),
        const SizedBox(height: 20),
        const Text('Delivery Summary',
            style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shipping Address',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  TextButton(
                    onPressed: () => setState(() => _checkoutStep = 0),
                    child: const Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF1C7BFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('John Doe (+1 555-123-4567)',
                  style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                  '123 Tech Street, Silicon Valley, San Francisco, CA 94107',
                  style: TextStyle(
                      color: Color(0xFF667085), fontSize: 16, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  TextButton(
                    onPressed: () => setState(() => _checkoutStep = 1),
                    child: const Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF1C7BFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('VISA •••• ••••• •••• 3456',
                    style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Expires 08/28',
                    style: TextStyle(color: Color(0xFF667085), fontSize: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shipping Speed',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  TextButton(
                    onPressed: () => setState(() => _checkoutStep = 0),
                    child: const Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF1C7BFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Standard Shipping (3–5 days)',
                    style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('FREE Delivery by May 27, 2025',
                    style: TextStyle(
                        color: Color(0xFF0F9F65),
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 58,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'SIAKA10',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 18)),
            Text('₵1,287',
                style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Discount (SIAKA10)',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 18)),
            Text('-₵0.00',
                style: TextStyle(
                    color: Color(0xFF0F9F65),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 18)),
            Text('FREE',
                style: TextStyle(
                    color: Color(0xFF0F9F65),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Estimated Tax',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 18)),
            Text('₵103',
                style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total',
                style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            Text('₵1,390',
                style: TextStyle(
                    color: Color(0xFF1C7BFF),
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              final order = await widget.viewModel.placeOrder();
              if (order != null) {
                widget.onOrderPlaced(order);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Place Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _paymentMethodTile(String label, int index) {
    final selected = _selectedPaymentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color:
                  selected ? const Color(0xFF1C7BFF) : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              activeColor: const Color(0xFF1C7BFF),
            ),
            if (label == 'Mastercard')
              const Icon(Icons.credit_card_rounded,
                  size: 24, color: Color(0xFF1F2937))
            else if (label == 'PayPal')
              const Text('P',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C7BFF)))
            else if (label == 'Google Pay')
              const Text('G',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C7BFF)))
            else
              const Icon(Icons.apple, size: 24, color: Color(0xFF1F2937)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1F2937), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF1F2937),
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: labelStyle ??
                const TextStyle(color: Color(0xFF344054), fontSize: 17)),
        Text(value,
            style: valueStyle ??
                TextStyle(
                    color: valueColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _checkoutProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        final step = index + 1;
        final completed = index < _checkoutStep;
        final active = index <= _checkoutStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: index == 0
                    ? const SizedBox()
                    : Container(
                        height: 2,
                        color: active
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFFE5E7EB),
                      ),
              ),
              GestureDetector(
                onTap: () => setState(() => _checkoutStep = index),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: completed
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '$step',
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF7A8194),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: index == 2
                    ? const SizedBox()
                    : Container(
                        height: 2,
                        color: index < _checkoutStep
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFFE5E7EB),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _checkoutHeader() {
    const labels = ['Shipping', 'Payment', 'Review'];
    return Column(
      children: [
        _checkoutProgress(),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            labels.length,
            (index) => Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: index <= _checkoutStep
                      ? const Color(0xFF1C7BFF)
                      : const Color(0xFF7A8194),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAddressDialog() {
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _zipController.clear();
    _phoneController.clear();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: _addressController,
                decoration:
                    const InputDecoration(labelText: 'Detailed Address'),
              ),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Town or City'),
              ),
              TextField(
                controller: _zipController,
                decoration: const InputDecoration(labelText: 'Ghana GPS Code'),
              ),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty ||
                  _addressController.text.trim().isEmpty ||
                  _cityController.text.trim().isEmpty ||
                  _phoneController.text.trim().isEmpty) {
                return;
              }
              setState(() {
                _addresses.add({
                  'name': _nameController.text.trim(),
                  'type': 'New',
                  'line1': _addressController.text.trim(),
                  'line2':
                      'Town/City: ${_cityController.text.trim()} | GPS: ${_zipController.text.trim()}',
                  'phone': _phoneController.text.trim(),
                });
                _selectedAddressIndex = _addresses.length - 1;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Widget _shippingOption(
      String label, String price, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: selected
                      ? const Color(0xFF1C7BFF)
                      : const Color(0xFFE5E7EB))),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: _shippingOptions
                  .indexWhere((option) => option['label'] == label),
              activeColor: const Color(0xFF1C7BFF),
            ),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            Text(price,
                style: TextStyle(
                    color: selected
                        ? const Color(0xFF0F9F65)
                        : const Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined, 'Home'),
            _navItem(1, Icons.search_rounded, 'Search'),
            _navItem(3, Icons.favorite_border_rounded, 'Wishlist'),
            _navItem(2, Icons.shopping_bag_rounded, 'Cart',
                isSelected: true, badge: 3),
            _navItem(4, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      {bool isSelected = false, int badge = 0}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTabSelected(index),
      child: SizedBox(
        width: 72,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isSelected
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFF7A8194),
                    size: 26),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFF7A8194),
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
            if (badge > 0)
              Positioned(
                right: 14,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Color(0xFF1C7BFF), shape: BoxShape.circle),
                  child: Center(
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

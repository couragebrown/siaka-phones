import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav_scaffold.dart';
import '../../core/widgets/featured_phone_card.dart';
import '../../../domain/models/order.dart';
import '../../../data/mock_data.dart';
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

  // Flow step: 0 = Shipping, 1 = Review, 2 = Payment
  int _checkoutStep = 0;

  // Shipping selection
  int _selectedShippingOptionIndex = 0;
  late Map<String, String> _address;

  // Payment selection: 0 = Mobile Money, 1 = Card, 2 = Apple/Google Pay, 3 = Pay on Delivery
  int _selectedPaymentMethodIndex = 0;
  String _selectedMoMoCarrier = 'MTN MoMo';
  bool _saveCard = true;

  // Controllers for Edit Address Dialog
  final TextEditingController _dlgNameController = TextEditingController();
  final TextEditingController _dlgAddressController = TextEditingController();
  final TextEditingController _dlgCityController = TextEditingController();
  final TextEditingController _dlgZipController = TextEditingController();
  final TextEditingController _dlgPhoneController = TextEditingController();

  // Controllers for Card Payment
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  // Controller for MoMo phone
  final TextEditingController _momoPhoneController =
      TextEditingController(text: '024 555 0192');

  final List<Map<String, dynamic>> _shippingMethods = [
    {
      'name': 'Standard Express (2–4 days)',
      'desc': 'Insured delivery directly to your doorstep',
      'fee': 0.0,
      'isFreeOverThreshold': true,
      'icon': Icons.local_shipping_rounded,
    },
    {
      'name': 'Priority Overnight (Next Day)',
      'desc': 'Guaranteed morning delivery nationwide',
      'fee': 25.0,
      'isFreeOverThreshold': false,
      'icon': Icons.bolt_rounded,
    },
    {
      'name': 'Siaka Hub Pickup (Accra Mall)',
      'desc': 'Ready in 2 hours with free device unboxing',
      'fee': 0.0,
      'isFreeOverThreshold': false,
      'icon': Icons.storefront_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.viewModel.userRepository?.profile ?? MockData.profile;
    _address = {
      'name': p.name,
      'line1': p.detailAddress,
      'line2': '${p.region}, Ghana • ${p.gpsCode}',
      'detailAddress': p.detailAddress,
      'region': p.region,
      'gpsCode': p.gpsCode,
      'phone': p.phone,
    };
    widget.viewModel.updateShippingInfo(
      fullName: _address['name'],
      address: _address['detailAddress'],
      city: _address['region'],
      zip: _address['gpsCode'],
      phone: _address['phone'],
    );
    _applySelectedShipping();
  }

  @override
  void dispose() {
    _dlgNameController.dispose();
    _dlgAddressController.dispose();
    _dlgCityController.dispose();
    _dlgZipController.dispose();
    _dlgPhoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    _momoPhoneController.dispose();
    super.dispose();
  }

  void _applySelectedShipping() {
    final option = _shippingMethods[_selectedShippingOptionIndex];
    final subtotal = widget.viewModel.subtotal;
    double fee = (option['fee'] as num).toDouble();
    if (option['isFreeOverThreshold'] == true && subtotal > 500) {
      fee = 0.0;
    }
    widget.viewModel.selectShippingMethod(option['name'] as String, fee);
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1F2937), size: 19),
              onPressed: () {
                if (_checkoutStep == 0) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _checkoutStep--);
                }
              },
            ),
            title: Text(
              _getAppBarTitle(),
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Uniform 3-Step Header: Shipping -> Review -> Payment
                        _buildStepHeader(),
                        const SizedBox(height: 16),

                        // Active step content
                        _buildStepBody(),
                      ],
                    ),
                  ),
                ),
                // Bottom Navigation Bar
                AppBottomNavBar(
                  currentIndex: 2,
                  onTabSelected: widget.onTabSelected,
                  cartBadgeCount: widget.viewModel.itemCount,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getAppBarTitle() {
    return 'Checkout';
  }

  /// Compact, uniform 3-step progress indicator: Shipping -> Review -> Payment
  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepNode(0, 'Shipping'),
          _buildStepLine(0),
          _buildStepNode(1, 'Review'),
          _buildStepLine(1),
          _buildStepNode(2, 'Payment'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String title) {
    final isCompleted = index < _checkoutStep;
    final isActive = index == _checkoutStep;

    return GestureDetector(
      onTap: () {
        if (index < _checkoutStep) {
          setState(() => _checkoutStep = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF059669)
                  : isActive
                      ? const Color(0xFF1C7BFF)
                      : const Color(0xFFF1F5F9),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF059669)
                    : isActive
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 15)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF1C7BFF)
                  : isCompleted
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterIndex) {
    final isDone = afterIndex < _checkoutStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
        color: isDone ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_checkoutStep) {
      case 0:
        return _buildShippingStep();
      case 1:
        return _buildReviewStep();
      case 2:
        return _buildPaymentStep();
      default:
        return _buildShippingStep();
    }
  }

  // ===========================================================================
  // STEP 0: SHIPPING
  // ===========================================================================
  Widget _buildShippingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Delivery Address Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Delivery Address',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            InkWell(
              onTap: _showEditAddressDialog,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: Color(0xFF1C7BFF)),
                    SizedBox(width: 3),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Color(0xFF1C7BFF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Single Saved Address Card (from user account)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1C7BFF),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 10),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C7BFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFF1C7BFF),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _address['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C7BFF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Saved Address',
                            style: TextStyle(
                              color: Color(0xFF1C7BFF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _address['line1'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _address['line2'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _address['phone'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Delivery Speed Section
        const Text(
          'Delivery Speed',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: List.generate(_shippingMethods.length, (index) {
              final method = _shippingMethods[index];
              final isSelected = _selectedShippingOptionIndex == index;
              final subtotal = widget.viewModel.subtotal;
              final fee = (method['fee'] as num).toDouble();
              final isFree =
                  method['isFreeOverThreshold'] == true && subtotal > 500;
              final displayPrice =
                  isFree || fee == 0.0 ? 'FREE' : _formatPrice(fee);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedShippingOptionIndex = index);
                  _applySelectedShipping();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1C7BFF)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1C7BFF)
                                : const Color(0xFF94A3B8),
                            width: isSelected ? 5.5 : 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        method['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'] as String,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              method['desc'] as String,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayPrice,
                        style: TextStyle(
                          color: displayPrice == 'FREE'
                              ? const Color(0xFF059669)
                              : const Color(0xFF1C7BFF),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 20),

        // Action Button: Continue to Review
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              widget.viewModel.updateShippingInfo(
                fullName: _address['name'],
                address: _address['detailAddress'] ?? _address['line1'],
                city: _address['region'] ?? 'Greater Accra',
                zip: _address['gpsCode'] ?? '',
                phone: _address['phone'],
              );
              _applySelectedShipping();
              setState(() => _checkoutStep = 1);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text(
              'Continue to Review',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 1: REVIEW
  // ===========================================================================
  Widget _buildReviewStep() {
    final items = widget.viewModel.items;
    final selectedShipping = _shippingMethods[_selectedShippingOptionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Delivery destination summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: Color(0xFF1C7BFF)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Shipping Destination',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _checkoutStep = 0),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Color(0xFF1C7BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_address['name']} • ${_address['phone']}',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_address['line1']}, ${_address['line2']}',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 11.5,
                ),
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(selectedShipping['icon'] as IconData,
                            size: 15, color: const Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selectedShipping['name'] as String,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _checkoutStep = 0),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: Color(0xFF1C7BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Order Items List
        Text(
          'Items in Order (${items.length})',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: ProductPhoneGraphic(product: item.product),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.selectedStorage} • ${item.selectedColor}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatPrice(item.totalPrice),
                      style: const TextStyle(
                        color: Color(0xFF1C7BFF),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Complete Price Details Breakdown
        _buildReviewPriceSummary(),

        const SizedBox(height: 20),

        // Action Button: Continue to Payment
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _checkoutStep = 2),
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: const Text(
              'Continue to Payment',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPriceSummary() {
    final subtotal = widget.viewModel.subtotal;
    final discount = widget.viewModel.discountAmount;
    final shipping = widget.viewModel.shipping;
    final tax = widget.viewModel.tax;
    final total = widget.viewModel.total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', _formatPrice(subtotal)),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _summaryRow(
              'Promo Discount (${widget.viewModel.appliedPromoCode})',
              '-${_formatPrice(discount)}',
              valueColor: const Color(0xFF059669),
            ),
          ],
          const SizedBox(height: 6),
          _summaryRow(
            'Shipping',
            shipping == 0.0 ? 'FREE' : _formatPrice(shipping),
            valueColor: shipping == 0.0
                ? const Color(0xFF059669)
                : const Color(0xFF1F2937),
          ),
          const SizedBox(height: 6),
          _summaryRow('Estimated Tax (8.25%)', '\$${tax.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _summaryRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isBold: true,
            valueColor: const Color(0xFF1C7BFF),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: PAYMENT
  // ===========================================================================
  Widget _buildPaymentStep() {
    final total = widget.viewModel.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        // Method 0: Mobile Money (Ghana Local)
        _buildPaymentOptionCard(
          index: 0,
          title: 'Mobile Money (MoMo)',
          subtitle: 'Instant push notification on your phone',
          icon: Icons.phone_android_rounded,
          badgeText: 'POPULAR',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Carrier Selector: MTN, Telecel, AT
              Row(
                children: ['MTN MoMo', 'Telecel Cash', 'AT Money'].map((carrier) {
                  final isCarrierSelected = _selectedMoMoCarrier == carrier;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMoMoCarrier = carrier);
                        widget.viewModel.selectPaymentMethod(carrier);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isCarrierSelected
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCarrierSelected
                                ? const Color(0xFF1C7BFF)
                                : const Color(0xFFE2E8F0),
                            width: isCarrierSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            carrier,
                            style: TextStyle(
                              color: isCarrierSelected
                                  ? const Color(0xFF1C7BFF)
                                  : const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: isCarrierSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Mobile Number Input
              SizedBox(
                height: 42,
                child: TextField(
                  controller: _momoPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.dialpad_rounded,
                        size: 16, color: Color(0xFF64748B)),
                    hintText: 'e.g. 024 123 4567',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1C7BFF)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Method 1: Credit / Debit Card
        _buildPaymentOptionCard(
          index: 1,
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, American Express',
          icon: Icons.credit_card_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Card Number
              SizedBox(
                height: 42,
                child: TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payment_rounded,
                        size: 16, color: Color(0xFF64748B)),
                    hintText: 'Card Number (•••• •••• •••• ••••)',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1C7BFF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Expiry & CVV
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _cardExpiryController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'MM / YY',
                          hintStyle: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF1C7BFF)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _cardCvvController,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'CVV / CVC',
                          hintStyle: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF1C7BFF)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Cardholder Name
              SizedBox(
                height: 42,
                child: TextField(
                  controller: _cardHolderController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        size: 16, color: Color(0xFF64748B)),
                    hintText: 'Cardholder Full Name',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1C7BFF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _saveCard,
                      onChanged: (v) => setState(() => _saveCard = v ?? true),
                      activeColor: const Color(0xFF1C7BFF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Save card securely for future purchases',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Method 2: Apple Pay / Google Pay
        _buildPaymentOptionCard(
          index: 2,
          title: 'Apple Pay & Google Pay',
          subtitle: 'Instant 1-tap checkout via device wallet',
          icon: Icons.account_balance_wallet_rounded,
        ),

        const SizedBox(height: 10),

        // Method 3: Pay on Delivery / Hub
        _buildPaymentOptionCard(
          index: 3,
          title: 'Cash on Delivery / Pickup Hub',
          subtitle: 'Inspect your device before paying cash or card',
          icon: Icons.handshake_rounded,
        ),

        const SizedBox(height: 16),

        // Final Price Confirmation Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payable',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Inclusive of all taxes & insurance',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF1C7BFF),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '256-bit encrypted checkout with authentic brand warranty',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Place Order Action Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: widget.viewModel.isPlacingOrder
                ? null
                : () async {
                    final order = await widget.viewModel.placeOrder();
                    if (order != null) {
                      widget.onOrderPlaced(order);
                    }
                  },
            icon: widget.viewModel.isPlacingOrder
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_outline_rounded, size: 16),
            label: Text(
              widget.viewModel.isPlacingOrder
                  ? 'Processing Order...'
                  : 'Place Order • \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
    Widget? child,
  }) {
    final isSelected = _selectedPaymentMethodIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethodIndex = index);
        switch (index) {
          case 0:
            widget.viewModel.selectPaymentMethod(_selectedMoMoCarrier);
            break;
          case 1:
            widget.viewModel.selectPaymentMethod('Credit / Debit Card');
            break;
          case 2:
            widget.viewModel.selectPaymentMethod('Apple / Google Pay');
            break;
          case 3:
            widget.viewModel.selectPaymentMethod('Cash on Delivery');
            break;
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1C7BFF)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1C7BFF)
                          : const Color(0xFF94A3B8),
                      width: isSelected ? 5.5 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected && child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color valueColor = const Color(0xFF1F2937),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
              fontSize: isBold ? 14.5 : 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 15.5 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showEditAddressDialog() {
    _dlgNameController.text = _address['name'] ?? '';
    _dlgAddressController.text =
        _address['detailAddress'] ?? _address['line1'] ?? '';
    _dlgCityController.text = _address['region'] ?? 'Greater Accra';
    _dlgZipController.text = _address['gpsCode'] ?? '';
    _dlgPhoneController.text = _address['phone'] ?? '';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Delivery Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(_dlgNameController, 'Full Name', 'e.g. Courage Brown'),
              const SizedBox(height: 8),
              _dialogField(_dlgAddressController, 'Detail Address',
                  'e.g. House No. 14, Independence Ave'),
              const SizedBox(height: 8),
              _dialogField(_dlgCityController, 'Region / City', 'e.g. Greater Accra'),
              const SizedBox(height: 8),
              _dialogField(_dlgZipController, 'Ghana GPS Code', 'e.g. GA-014-2041'),
              const SizedBox(height: 8),
              _dialogField(_dlgPhoneController, 'Phone Number',
                  'e.g. +233 24 555 0192',
                  keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (_dlgAddressController.text.trim().isEmpty ||
                  _dlgZipController.text.trim().isEmpty) {
                return;
              }
              final name = _dlgNameController.text.trim();
              final detail = _dlgAddressController.text.trim();
              final region = _dlgCityController.text.trim();
              final gps = _dlgZipController.text.trim().toUpperCase();
              final phone = _dlgPhoneController.text.trim();

              setState(() {
                _address = {
                  'name': name.isNotEmpty ? name : (_address['name'] ?? ''),
                  'line1': detail,
                  'line2': '$region, Ghana • $gps',
                  'detailAddress': detail,
                  'region': region,
                  'gpsCode': gps,
                  'phone': phone.isNotEmpty ? phone : (_address['phone'] ?? ''),
                };
              });

              widget.viewModel.updateShippingInfo(
                fullName: _address['name'],
                address: _address['detailAddress'],
                city: _address['region'],
                zip: _address['gpsCode'],
                phone: _address['phone'],
              );

              // Update account saved address in UserRepository
              widget.viewModel.userRepository?.updateAddress(
                detailAddress: detail,
                gpsCode: gps,
                region: region,
              );
              if (name.isNotEmpty || phone.isNotEmpty) {
                widget.viewModel.userRepository?.updateProfile(
                  name: name.isNotEmpty ? name : null,
                  phone: phone.isNotEmpty ? phone : null,
                );
              }

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delivery address updated successfully'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C7BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11.5),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1C7BFF)),
          ),
        ),
      ),
    );
  }
}

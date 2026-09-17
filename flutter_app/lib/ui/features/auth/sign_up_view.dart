import 'package:flutter/material.dart';

class SignUpView extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(
    String name,
    String email,
    String phone,
    String address,
    String country,
    String region,
    String gpsCode,
  ) onCreateAccount;
  final VoidCallback onSignInTap;

  const SignUpView({
    super.key,
    required this.onBack,
    required this.onCreateAccount,
    required this.onSignInTap,
  });

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  String? _selectedProvider;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController =
      TextEditingController(text: 'Ghana');
  final TextEditingController _gpsCodeController = TextEditingController();
  String? _selectedRegion;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();
  final _gpsCodeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  Map<String, String> _fieldErrors = {};

  static const List<String> _regions = [
    'Ahafo',
    'Ashanti',
    'Bono',
    'Bono East',
    'Central',
    'Eastern',
    'Greater Accra',
    'North East',
    'Northern',
    'Oti',
    'Savannah',
    'Upper East',
    'Upper West',
    'Volta',
    'Western',
    'Western North',
  ];

  @override
  void initState() {
    super.initState();
    _validateOnUnfocus(_nameFocusNode, 'name', _nameController, 'Full name is required.');
    _validateOnUnfocus(_usernameFocusNode, 'username', _usernameController, 'Username is required.');
    _validateOnUnfocus(_emailFocusNode, 'email', _emailController, 'Enter a valid email address.', optionalEmail: true);
    _validateOnUnfocus(_phoneFocusNode, 'phone', _phoneController, 'Enter a valid phone number.', minimumLength: 10);
    _validateOnUnfocus(_addressFocusNode, 'address', _addressController, 'Detailed address is required.');
    _validateOnUnfocus(_countryFocusNode, 'country', _countryController, 'Country is required.');
    _validateOnUnfocus(_gpsCodeFocusNode, 'gpsCode', _gpsCodeController, 'Ghana GPS code is required.');
    _validateOnUnfocus(_passwordFocusNode, 'password', _passwordController, 'Password must be at least 8 characters.', minimumLength: 8);
    _validateOnUnfocus(_confirmPasswordFocusNode, 'confirmPassword', _confirmPasswordController, 'Passwords do not match.', mustMatchPassword: true);
  }

  void _validateOnUnfocus(
    FocusNode node,
    String key,
    TextEditingController controller,
    String message, {
    int minimumLength = 0,
    bool optionalEmail = false,
    bool mustMatchPassword = false,
  }) {
    node.addListener(() {
      if (!node.hasFocus) {
        final text = controller.text.trim();
        setState(() {
          if (text.isEmpty && !mustMatchPassword) {
            _fieldErrors[key] = message;
          } else if (minimumLength > 0 && text.length < minimumLength) {
            _fieldErrors[key] = message;
          } else if (optionalEmail && text.isNotEmpty && !text.contains('@')) {
            _fieldErrors[key] = message;
          } else if (mustMatchPassword && text != _passwordController.text) {
            _fieldErrors[key] = message;
          } else {
            _fieldErrors.remove(key);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _gpsCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _countryFocusNode.dispose();
    _gpsCodeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final country = _countryController.text.trim();
    final gpsCode = _gpsCodeController.text.trim();
    final password = _passwordController.text;

    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Full name is required.';
    if (username.isEmpty) errors['username'] = 'Username is required.';
    if (email.isNotEmpty && !email.contains('@')) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (phone.length < 10) errors['phone'] = 'Enter a valid phone number.';
    if (address.isEmpty) errors['address'] = 'Detailed address is required.';
    if (country.isEmpty) errors['country'] = 'Country is required.';
    if (_selectedRegion == null) errors['region'] = 'Select your region.';
    if (gpsCode.isEmpty) errors['gpsCode'] = 'Ghana GPS code is required.';
    if (password.length < 8) {
      errors['password'] = 'Password must be at least 8 characters.';
    }
    if (password != _confirmPasswordController.text) {
      errors['confirmPassword'] = 'Passwords do not match.';
    }
    if (!_acceptedTerms) {
      errors['terms'] = 'You must accept the terms to continue.';
    }

    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) {
      return;
    }

    widget.onCreateAccount(
      name,
      email,
      phone,
      address,
      country,
      _selectedRegion!,
      gpsCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  const Center(child: _ProfilePlusAvatar()),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Sign up to get started with your account and orders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSignUpForm(),
                  const SizedBox(height: 20),
                  _buildPrimaryButton(
                    label: 'Create Account',
                    onPressed: _handleCreateAccount,
                  ),
                  const SizedBox(height: 22),
                  _buildOrDivider(),
                  const SizedBox(height: 20),
                  _buildSocialIconsRow(),
                  const SizedBox(height: 26),
                  _buildFooterSwitch(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: IconButton(
            onPressed: widget.onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  size: 22,
                  color: Color(0xFF1C7BFF),
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'SiakaPhones',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 38), // Balance for back button
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputGroup(
          label: 'Full Name',
          controller: _nameController,
          hintText: 'Enter your name',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          focusNode: _nameFocusNode,
          errorText: _fieldErrors['name'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Username',
          controller: _usernameController,
          hintText: 'Choose a username',
          prefixIcon: Icons.alternate_email_rounded,
          focusNode: _usernameFocusNode,
          errorText: _fieldErrors['username'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Email',
          controller: _emailController,
          hintText: 'Enter your email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          focusNode: _emailFocusNode,
          errorText: _fieldErrors['email'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Phone Number',
          controller: _phoneController,
          hintText: '024 123 4567',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          focusNode: _phoneFocusNode,
          errorText: _fieldErrors['phone'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Detailed Address',
          controller: _addressController,
          hintText: 'Street, area, town or city',
          prefixIcon: Icons.home_outlined,
          keyboardType: TextInputType.streetAddress,
          focusNode: _addressFocusNode,
          errorText: _fieldErrors['address'],
        ),
        const SizedBox(height: 16),
        _buildRegionField(),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Ghana GPS Code',
          controller: _gpsCodeController,
          hintText: 'e.g. GA-123-4567',
          prefixIcon: Icons.location_on_outlined,
          focusNode: _gpsCodeFocusNode,
          errorText: _fieldErrors['gpsCode'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Password',
          controller: _passwordController,
          hintText: 'Create a password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: !_passwordVisible,
          suffixIcon: _passwordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          focusNode: _passwordFocusNode,
          errorText: _fieldErrors['password'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hintText: 'Re-enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: !_passwordVisible,
          suffixIcon: _passwordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          focusNode: _confirmPasswordFocusNode,
          errorText: _fieldErrors['confirmPassword'],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                value: _acceptedTerms,
                onChanged: (val) =>
                    setState(() => _acceptedTerms = val ?? false),
                activeColor: const Color(0xFF1C7BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'I agree to the Terms and Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (_fieldErrors.containsKey('terms'))
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 26),
            child: Text(
              _fieldErrors['terms']!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildRegionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Region',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _fieldErrors.containsKey('region')
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              isExpanded: true,
              hint: const Row(
                children: [
                  Icon(Icons.map_outlined, size: 19, color: Color(0xFF94A3B8)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select your region',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              items: _regions
                  .map(
                    (region) => DropdownMenuItem(
                      value: region,
                      child: Text(
                        region,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRegion = val;
                  _fieldErrors.remove('region');
                });
              },
            ),
          ),
        ),
        if (_fieldErrors.containsKey('region'))
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              _fieldErrors['region']!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildInputGroup({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    FocusNode? focusNode,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFE2E8F0),
              width: hasError ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(prefixIcon, size: 19, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: isPassword && obscureText,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffixIcon != null)
                GestureDetector(
                  onTap: onSuffixTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      suffixIcon,
                      size: 19,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C7BFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
      ],
    );
  }

  Widget _buildSocialIconsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularSocialButton(
          icon: _googleIconWidget(),
          providerName: 'Google',
        ),
        const SizedBox(width: 18),
        _buildCircularSocialButton(
          icon: const Icon(Icons.apple, color: Colors.black, size: 22),
          providerName: 'Apple',
        ),
        const SizedBox(width: 18),
        _buildCircularSocialButton(
          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
          providerName: 'Facebook',
        ),
      ],
    );
  }

  Widget _buildCircularSocialButton({
    required Widget icon,
    required String providerName,
  }) {
    final isSelected = _selectedProvider == providerName;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedProvider = providerName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting with $providerName...'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _googleIconWidget() {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFFEA4335),
                    Color(0xFFFBBC05),
                    Color(0xFF34A853),
                  ],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 20.0, 20.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSwitch() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSignInTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Sign In',
                style: TextStyle(
                  color: Color(0xFF1C7BFF),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePlusAvatar extends StatelessWidget {
  const _ProfilePlusAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C7BFF).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF1C7BFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final void Function(
    String name,
    String email,
    String phone,
    String address,
    String country,
    String region,
    String gpsCode,
  ) onCreateAccount;

  const LoginView({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  String _selectedTab = 'Sign In';
  String? _selectedProvider;

  // Controllers
  final TextEditingController _loginIdentifierController =
      TextEditingController(text: 'john.doe@example.com');
  final TextEditingController _loginPasswordController =
      TextEditingController(text: '••••••••••••');

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
  final _loginIdentifierFocusNode = FocusNode();
  final _loginPasswordFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();
  final _gpsCodeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _rememberMe = true;
  bool _loginPasswordVisible = false;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _validateOnUnfocus(
        _nameFocusNode, 'name', _nameController, 'Full name is required.');
    _validateOnUnfocus(_usernameFocusNode, 'username', _usernameController,
        'Username is required.');
    _validateOnUnfocus(_emailFocusNode, 'email', _emailController,
        'Enter a valid email address.',
        optionalEmail: true);
    _validateOnUnfocus(_phoneFocusNode, 'phone', _phoneController,
        'Enter a valid phone number.',
        minimumLength: 10);
    _validateOnUnfocus(_addressFocusNode, 'address', _addressController,
        'Detailed address is required.');
    _validateOnUnfocus(_countryFocusNode, 'country', _countryController,
        'Country is required.');
    _validateOnUnfocus(_gpsCodeFocusNode, 'gpsCode', _gpsCodeController,
        'Ghana GPS code is required.');
    _validateOnUnfocus(_passwordFocusNode, 'password', _passwordController,
        'Password must be at least 8 characters.',
        minimumLength: 8);
    _validateOnUnfocus(
      _confirmPasswordFocusNode,
      'confirmPassword',
      _confirmPasswordController,
      'Passwords do not match.',
      mustMatchPassword: true,
    );
  }

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _gpsCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _loginIdentifierFocusNode.dispose();
    _loginPasswordFocusNode.dispose();
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

  void _validateOnUnfocus(
    FocusNode focusNode,
    String errorKey,
    TextEditingController controller,
    String message, {
    int minimumLength = 1,
    bool optionalEmail = false,
    bool mustMatchPassword = false,
  }) {
    focusNode.addListener(() {
      if (focusNode.hasFocus || _selectedTab == 'Sign In') {
        return;
      }

      final value = controller.text.trim();
      final hasError = mustMatchPassword
          ? value != _passwordController.text
          : optionalEmail
              ? value.isNotEmpty && !value.contains('@')
              : value.length < minimumLength;
      final errors = Map<String, String>.from(_fieldErrors);
      if (hasError) {
        errors[errorKey] = message;
      } else {
        errors.remove(errorKey);
      }
      setState(() => _fieldErrors = errors);
    });
  }

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = tab;
      _selectedProvider = null;
      _fieldErrors = {};
    });
  }

  void _handleSignIn() {
    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;

    final errors = <String, String>{};
    if (identifier.isEmpty) {
      errors['loginIdentifier'] = 'Please enter your email or phone.';
    }
    if (password.isEmpty) {
      errors['loginPassword'] = 'Please enter your password.';
    }

    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }

    widget.onSignIn();
  }

  void _createAccount() {
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
    final isSignIn = _selectedTab == 'Sign In';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildTabSwitch(),
              const SizedBox(height: 24),
              Center(
                child: isSignIn
                    ? const _GreetingAvatar()
                    : const _ProfilePlusAvatar(),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  isSignIn ? 'Welcome to SiakaPhones' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  isSignIn
                      ? 'Explore a modern experience built for speed and simplicity.'
                      : 'Sign up to get started with your account and orders.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (isSignIn) _buildSignInForm() else _buildSignUpForm(),
              const SizedBox(height: 20),
              _buildPrimaryButton(
                label: isSignIn ? 'Sign In' : 'Create Account',
                onPressed: isSignIn ? _handleSignIn : _createAccount,
              ),
              const SizedBox(height: 22),
              _buildOrDivider(),
              const SizedBox(height: 20),
              if (isSignIn)
                _buildSignInSocialList()
              else
                _buildSignUpSocialIconsRow(),
              const SizedBox(height: 24),
              _buildFooterSwitch(isSignIn),
              const SizedBox(height: 12),
            ],
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
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFBFD8FF)),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    size: 15,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'SiakaPhones',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 38), // Balance for back button
      ],
    );
  }


  Widget _buildTabSwitch() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ['Sign In', 'Create Account'].map((tab) {
          final active = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectTab(tab),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: active
                        ? AppColors.textPrimary
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputGroup(
          label: 'Email or Phone',
          controller: _loginIdentifierController,
          hintText: 'Enter your email or phone',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          focusNode: _loginIdentifierFocusNode,
          errorText: _fieldErrors['loginIdentifier'],
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          label: 'Password',
          controller: _loginPasswordController,
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: !_loginPasswordVisible,
          suffixIcon: _loginPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: () =>
              setState(() => _loginPasswordVisible = !_loginPasswordVisible),
          focusNode: _loginPasswordFocusNode,
          errorText: _fieldErrors['loginPassword'],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        value: _rememberMe,
                        onChanged: (val) =>
                            setState(() => _rememberMe = val ?? false),
                        activeColor: AppColors.cyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Remember me',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(

              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset link sent to your email.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
                activeColor: AppColors.cyan,
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
                  color: Color(0xFF374151),
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
    const regions = [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Region',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _fieldErrors.containsKey('region')
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              isExpanded: true,
              hint: const Row(
                children: [
                  Icon(Icons.map_outlined, size: 19, color: Color(0xFF9CA3AF)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select your region',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),

              items: regions
                  .map(
                    (region) => DropdownMenuItem(
                      value: region,
                      child: Text(
                        region,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (region) => setState(() {
                _selectedRegion = region;
                _fieldErrors.remove('region');
              }),
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
    String? errorText,
    FocusNode? focusNode,
  }) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(prefixIcon, size: 19, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: isPassword && obscureText,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
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
                      color: const Color(0xFF9CA3AF),
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
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15.5,
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
        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
      ],
    );
  }

  Widget _buildSignInSocialList() {
    return Column(
      children: [
        _buildFullSocialButton(
          label: 'Continue with Google',
          icon: _googleIconWidget(),
          providerName: 'Google',
        ),
        const SizedBox(height: 12),
        _buildFullSocialButton(
          label: 'Continue with Apple',
          icon: const Icon(Icons.apple, color: Colors.black, size: 21),
          providerName: 'Apple',
        ),
        const SizedBox(height: 12),
        _buildFullSocialButton(
          label: 'Continue with Facebook',
          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 21),
          providerName: 'Facebook',
        ),
      ],
    );
  }

  Widget _buildFullSocialButton({
    required String label,
    required Widget icon,
    required String providerName,
  }) {
    final isSelected = _selectedProvider == providerName;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedProvider = providerName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signing in with $providerName...'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.cyan : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildSignUpSocialIconsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularSocialButton(
          icon: _googleIconWidget(),
          providerName: 'Google',
        ),
        const SizedBox(width: 20),
        _buildCircularSocialButton(
          icon: const Icon(Icons.apple, color: Colors.black, size: 22),
          providerName: 'Apple',
        ),
        const SizedBox(width: 20),
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
            color: isSelected ? AppColors.cyan : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
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

  Widget _buildFooterSwitch(bool isSignIn) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(isSignIn ? 'Create Account' : 'Sign In'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isSignIn
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isSignIn ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  color: AppColors.cyan,
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

/// Stylized greeting avatar matching the left mockup
class _GreetingAvatar extends StatelessWidget {
  const _GreetingAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shoulders / Shirt
            Positioned(
              bottom: -4,
              child: Container(
                width: 76,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1), // Modern soft purple-blue shirt
                  borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
                ),
              ),
            ),
            // Collar detail
            Positioned(
              bottom: 26,
              child: Container(
                width: 18,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDBB5),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
              ),
            ),
            // Neck
            Positioned(
              bottom: 30,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDBB5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Head
            Positioned(
              bottom: 38,
              child: Container(
                width: 38,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE3C6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Hair
            Positioned(
              top: 22,
              child: Container(
                width: 40,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF262E3D),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Waving Hand on the left (as in the mockup)
            Positioned(
              top: 36,
              left: 18,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 15,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDBB5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stylized profile avatar with "+" badge matching the right mockup
class _ProfilePlusAvatar extends StatelessWidget {
  const _ProfilePlusAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shoulders / Shirt
                  Positioned(
                    bottom: -4,
                    child: Container(
                      width: 66,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(33)),
                      ),
                    ),
                  ),
                  // Neck
                  Positioned(
                    bottom: 26,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDBB5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Head
                  Positioned(
                    bottom: 34,
                    child: Container(
                      width: 32,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE3C6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Hair
                  Positioned(
                    top: 14,
                    child: Container(
                      width: 34,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF262E3D),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                          bottom: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Circular "+" badge at top right
          Positioned(
            top: 2,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

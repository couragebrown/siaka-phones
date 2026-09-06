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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: 'john.doe@example.com');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController =
      TextEditingController(text: 'Ghana');
  final TextEditingController _gpsCodeController = TextEditingController();
  String? _selectedRegion;
  final TextEditingController _passwordController =
      TextEditingController(text: '••••••••••••');
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
      if (tab == 'Create Account') {
        _emailController.clear();
        _passwordController.clear();
      }
    });
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'SiakaPhones',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isSignIn ? 'Welcome Back' : 'Create Account',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        if (isSignIn) ...[
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 30)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignIn
                          ? 'Sign in to your account to explore exclusive offers'
                          : 'Create your account to unlock exclusive offers',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Container(
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: ['Sign In', 'Create Account'].map((item) {
                    final active = _selectedTab == item;
                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectTab(item),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: active
                                ? BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Text(
                              item,
                              style: TextStyle(
                                color: active
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _socialButton(
                      label: 'Apple',
                      isSelected: _selectedProvider == 'Apple',
                      onTap: () => setState(() => _selectedProvider = 'Apple'),
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _socialButton(
                      label: 'Google',
                      isSelected: _selectedProvider == 'Google',
                      onTap: () => setState(() => _selectedProvider = 'Google'),
                      icon: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'or continue with your account',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _labelledField(
                label:
                    isSignIn ? 'Email, Username, or Phone Number' : 'Full Name',
                controller: isSignIn ? _emailController : _nameController,
                hintText: isSignIn
                    ? 'name@example.com, username, or 024 123 4567'
                    : 'Your full name',
                prefixIcon: isSignIn
                    ? Icons.person_outline_rounded
                    : Icons.person_outline_rounded,
                keyboardType:
                    isSignIn ? TextInputType.text : TextInputType.name,
                errorText: isSignIn ? null : _fieldErrors['name'],
                focusNode: isSignIn ? null : _nameFocusNode,
              ),
              if (!isSignIn) ...[
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Username',
                  controller: _usernameController,
                  hintText: 'Choose a username',
                  prefixIcon: Icons.alternate_email_rounded,
                  errorText: _fieldErrors['username'],
                  focusNode: _usernameFocusNode,
                ),
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Email Address (Optional)',
                  controller: _emailController,
                  hintText: 'name@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _fieldErrors['email'],
                  focusNode: _emailFocusNode,
                ),
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hintText: 'e.g. 024 123 4567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  errorText: _fieldErrors['phone'],
                  focusNode: _phoneFocusNode,
                ),
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Detailed Address',
                  controller: _addressController,
                  hintText: 'Street, area, town or city',
                  prefixIcon: Icons.home_outlined,
                  keyboardType: TextInputType.streetAddress,
                  errorText: _fieldErrors['address'],
                  focusNode: _addressFocusNode,
                ),
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Country',
                  controller: _countryController,
                  hintText: 'Country',
                  prefixIcon: Icons.public_outlined,
                  errorText: _fieldErrors['country'],
                  focusNode: _countryFocusNode,
                ),
                const SizedBox(height: 18),
                _regionField(),
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Ghana GPS Code',
                  controller: _gpsCodeController,
                  hintText: 'e.g. GA-123-4567',
                  prefixIcon: Icons.location_on_outlined,
                  errorText: _fieldErrors['gpsCode'],
                  focusNode: _gpsCodeFocusNode,
                ),
              ],
              const SizedBox(height: 18),
              _labelledField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'At least 8 characters',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                suffixIcon: _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                errorText: isSignIn ? null : _fieldErrors['password'],
                focusNode: isSignIn ? null : _passwordFocusNode,
              ),
              if (!isSignIn) ...[
                const SizedBox(height: 18),
                _labelledField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  hintText: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  suffixIcon: _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  errorText: _fieldErrors['confirmPassword'],
                  focusNode: _confirmPasswordFocusNode,
                ),
              ],
              const SizedBox(height: 18),
              if (isSignIn)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                            activeColor: AppColors.cyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                            activeColor: AppColors.cyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms and Privacy Policy',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_fieldErrors.containsKey('terms'))
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          _fieldErrors['terms']!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 26),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isSignIn ? widget.onSignIn : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(isSignIn ? 'Sign In' : 'Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _regionField() {
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
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedRegion,
          isExpanded: true,
          hint: const Text('Select your region'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.map_outlined),
            filled: true,
            fillColor: Colors.white,
            errorText: _fieldErrors['region'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
          items: regions
              .map(
                (region) => DropdownMenuItem(
                  value: region,
                  child: Text(region),
                ),
              )
              .toList(),
          onChanged: (region) => setState(() => _selectedRegion = region),
        ),
      ],
    );
  }

  Widget _labelledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    String? errorText,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Icon(prefixIcon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: isPassword && !_passwordVisible,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (suffixIcon != null)
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

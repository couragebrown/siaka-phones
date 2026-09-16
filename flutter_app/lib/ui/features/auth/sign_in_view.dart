import 'package:flutter/material.dart';

import 'sign_up_view.dart';

class SignInView extends StatefulWidget {
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
  )? onCreateAccount;
  final VoidCallback? onNavigateToSignUp;

  const SignInView({
    super.key,
    required this.onBack,
    required this.onSignIn,
    this.onCreateAccount,
    this.onNavigateToSignUp,
  });

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  String? _selectedProvider;

  // Controllers
  final TextEditingController _loginIdentifierController =
      TextEditingController(text: 'john.doe@example.com');
  final TextEditingController _loginPasswordController =
      TextEditingController(text: '••••••••••••');

  // Focus Nodes
  final _loginIdentifierFocusNode = FocusNode();
  final _loginPasswordFocusNode = FocusNode();

  bool _rememberMe = true;
  bool _loginPasswordVisible = false;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _loginIdentifierFocusNode.dispose();
    _loginPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;

    final errors = <String, String>{};
    if (identifier.isEmpty) {
      errors['loginIdentifier'] = 'Enter your email or phone number.';
    }
    if (password.isEmpty) {
      errors['loginPassword'] = 'Enter your password.';
    }

    setState(() => _fieldErrors = errors);

    if (errors.isEmpty) {
      widget.onSignIn();
    }
  }

  void _goToSignUp() {
    if (widget.onNavigateToSignUp != null) {
      widget.onNavigateToSignUp!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpView(
          onBack: () => Navigator.of(context).pop(),
          onCreateAccount: (name, email, phone, address, country, region, gpsCode) {
            Navigator.of(context).pop();
            widget.onCreateAccount?.call(
              name,
              email,
              phone,
              address,
              country,
              region,
              gpsCode,
            );
          },
          onSignInTap: () => Navigator.of(context).pop(),
        ),
      ),
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
                  const Center(child: _GreetingAvatar()),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Welcome to SiakaPhones',
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
                      'Explore a modern experience built for speed and simplicity.',
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
                  _buildSignInForm(),
                  const SizedBox(height: 20),
                  _buildPrimaryButton(
                    label: 'Sign In',
                    onPressed: _handleSignIn,
                  ),
                  const SizedBox(height: 8),
                  _buildOrDivider(),
                  const SizedBox(height: 8),
                  _buildSocialList(),
                  const SizedBox(height: 10),
                  _buildFooterSwitch(),
                  const SizedBox(height: 4),
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
        const SizedBox(width: 38), // spacer to balance the right side
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  size: 15,
                  color: Color(0xFF1C7BFF),
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'SiakaPhones',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 38), // Balance spacer
      ],
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
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(
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
                    activeColor: const Color(0xFF1C7BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
                  color: Color(0xFF1C7BFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        Expanded(
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Or',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 1)),
      ],
    );
  }

  Widget _buildSocialList() {
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

    return Tooltip(
      message: providerName,
      child: GestureDetector(
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1C7BFF)
                  : const Color(0xFFE2E8F0),
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
        onTap: _goToSignUp,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Create Account',
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

class _GreetingAvatar extends StatelessWidget {
  const _GreetingAvatar();

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
            Icons.lock_open_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

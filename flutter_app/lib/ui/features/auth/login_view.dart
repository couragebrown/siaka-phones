import 'package:flutter/material.dart';

import 'sign_in_view.dart';
import 'sign_up_view.dart';

export 'sign_in_view.dart';
export 'sign_up_view.dart';

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
  bool _showSignUp = false;

  @override
  Widget build(BuildContext context) {
    if (_showSignUp) {
      return SignUpView(
        onBack: () => setState(() => _showSignUp = false),
        onCreateAccount: widget.onCreateAccount,
        onSignInTap: () => setState(() => _showSignUp = false),
      );
    }

    return SignInView(
      onBack: widget.onBack,
      onSignIn: widget.onSignIn,
      onCreateAccount: widget.onCreateAccount,
      onNavigateToSignUp: () => setState(() => _showSignUp = true),
    );
  }
}

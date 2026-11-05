import 'package:flutter/material.dart';

/// Terms and Conditions page for Siaka Phones.
/// When opened from the sign up flow, the user can review the terms and tap
/// "Confirm & Agree" to return with a positive confirmation (`true`).
class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: 'Back',
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF1C7BFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1C7BFF).withValues(alpha: 0.25),
                                blurRadius: 14,
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
                                    width: 38,
                                    height: 38,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(
                                        'assets/images/siaka_logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/images/app_icon.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.phone_android_rounded,
                                            color: Color(0xFF1C7BFF),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Siaka Phones Ghana',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Official Policy',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'TERMS AND CONDITIONS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Please read these Terms and Conditions carefully before creating an account or placing orders on Siaka Phones.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Welcome Intro Card
                        _buildSectionContainer(
                          child: const Text(
                            'Welcome to Siaka Phones. By downloading, accessing, creating an account, or using the Siaka Phones app, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these Terms, please do not use our services.',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13.5,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 1. USE OF THE APP
                        _buildSection(
                          number: '1',
                          title: 'USE OF THE APP',
                          content:
                              'Siaka Phones provides a platform for browsing, purchasing, and managing mobile phones, accessories, and related products. You agree to use the app only for lawful purposes and in accordance with these Terms.',
                        ),

                        // 2. ACCOUNT REGISTRATION
                        _buildSection(
                          number: '2',
                          title: 'ACCOUNT REGISTRATION',
                          content:
                              'To access certain features, you may be required to create an account. You are responsible for maintaining the confidentiality of your login information and for all activities conducted through your account.\n\nYou agree to provide accurate, current, and complete information during registration and keep your information updated.',
                        ),

                        // 3. PRODUCTS AND PRICING
                        _buildSection(
                          number: '3',
                          title: 'PRODUCTS AND PRICING',
                          content:
                              'We strive to ensure that all product descriptions, images, and prices are accurate. However, errors may occasionally occur. Siaka Phones reserves the right to correct any errors, update information, or cancel orders if incorrect information has been displayed.\n\nAll prices are subject to change without prior notice.',
                        ),

                        // 4. ORDERS AND PAYMENTS
                        _buildSection(
                          number: '4',
                          title: 'ORDERS AND PAYMENTS',
                          content:
                              'By placing an order through Siaka Phones, you agree that:',
                          bulletPoints: const [
                            'All payment information provided is accurate and authorized.',
                            'Orders are subject to acceptance and availability.',
                            'We reserve the right to refuse or cancel any order for any reason, including suspected fraud, pricing errors, or stock limitations.',
                          ],
                        ),

                        // 5. DELIVERY AND SHIPPING
                        _buildSection(
                          number: '5',
                          title: 'DELIVERY AND SHIPPING',
                          content:
                              'Delivery times are estimates and may vary depending on location, availability, and logistical factors. Siaka Phones is not responsible for delays caused by third-party delivery services or circumstances beyond our control.',
                        ),

                        // 6. RETURNS AND REFUNDS
                        _buildSection(
                          number: '6',
                          title: 'RETURNS AND REFUNDS',
                          content:
                              'Returns and refunds may be available according to our Return Policy. Products must be returned in their original condition with all accessories and packaging where applicable.\n\nRefund approval is subject to inspection and compliance with our return requirements.',
                        ),

                        // 7. USER CONDUCT
                        _buildSection(
                          number: '7',
                          title: 'USER CONDUCT',
                          content: 'You agree not to:',
                          bulletPoints: const [
                            'Use the app for illegal or fraudulent purposes.',
                            'Interfere with the operation or security of the app.',
                            'Upload viruses, malicious software, or harmful content.',
                            'Misrepresent your identity or provide false information.',
                            'Attempt unauthorized access to our systems or other users\' accounts.',
                          ],
                        ),

                        // 8. INTELLECTUAL PROPERTY
                        _buildSection(
                          number: '8',
                          title: 'INTELLECTUAL PROPERTY',
                          content:
                              'All content within the Siaka Phones app, including logos, trademarks, product images, graphics, text, and software, is the property of Siaka Phones or its licensors and is protected by applicable intellectual property laws.\n\nNo content may be copied, reproduced, or distributed without written permission.',
                        ),

                        // 9. LIMITATION OF LIABILITY
                        _buildSection(
                          number: '9',
                          title: 'LIMITATION OF LIABILITY',
                          content:
                              'To the maximum extent permitted by law, Siaka Phones shall not be liable for any indirect, incidental, special, or consequential damages arising from the use or inability to use the app, products, or services.',
                        ),

                        // 10. PRIVACY
                        _buildSection(
                          number: '10',
                          title: 'PRIVACY',
                          content:
                              'Your privacy is important to us. By using the app, you agree to the collection and use of your information in accordance with our Privacy Policy.',
                        ),

                        // 11. TERMINATION
                        _buildSection(
                          number: '11',
                          title: 'TERMINATION',
                          content:
                              'Siaka Phones reserves the right to suspend or terminate any account that violates these Terms or engages in harmful, fraudulent, or unlawful activities.',
                        ),

                        // 12. CHANGES TO TERMS
                        _buildSection(
                          number: '12',
                          title: 'CHANGES TO TERMS',
                          content:
                              'We may update these Terms and Conditions periodically. Continued use of the app after updates are published constitutes acceptance of the revised Terms.',
                        ),

                        // 13. GOVERNING LAW
                        _buildSection(
                          number: '13',
                          title: 'GOVERNING LAW',
                          content:
                              'These Terms and Conditions shall be governed by and interpreted under the laws of the Republic of Ghana. Any disputes arising from the use of the app shall be subject to the jurisdiction of Ghanaian courts.',
                        ),

                        // 14. CONTACT US
                        _buildSection(
                          number: '14',
                          title: 'CONTACT US',
                          content:
                              'If you have any questions regarding these Terms and Conditions, please contact us:\n\nSiaka Phones\nEmail: support@siakaphones.com\nPhone: +233 24 000 0000\nAddress: Accra, Ghana',
                        ),

                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF1C7BFF),
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'By tapping "Confirm & Agree", you acknowledge that you have read, understood, and agreed to these Terms and Conditions.',
                                  style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Sticky Confirm Button Bar
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: bottomPadding > 0 ? bottomPadding + 6 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C7BFF),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: const Color(0xFF1C7BFF).withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Confirm & Agree',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    List<String>? bulletPoints,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFF1C7BFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...bulletPoints.map(
              (bp) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: Color(0xFF1C7BFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bp,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


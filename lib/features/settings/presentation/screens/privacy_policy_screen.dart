import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, List<String>)>[
    (
      '1. Introduction',
      [
        'This Privacy Policy explains how Smart POS & Inventory ("we", "our", or "us") collects, uses, stores, and protects your information when you use our point-of-sale and inventory management application (the "Service"). By accessing or using the Service, you agree to the practices described in this Privacy Policy.',
      ],
    ),
    (
      '2. Information We Collect',
      [
        'Account Information: When you register and log in to the Service, we collect your name, email address, shop name, and the credentials needed to access your account.',
        'Business Data: To operate the point-of-sale and inventory features, we store information you enter, including products, categories, packages, pricing, stock levels, purchases, sales, and customer details.',
        'Usage Information: We may collect basic technical information such as device type, operating system, app version, and general usage patterns to maintain and improve the Service.',
      ],
    ),
    (
      '3. How We Use Your Information',
      [
        'We use your information to provide, maintain, and improve the Service, including processing sales, tracking inventory and stock, generating reports, and managing your account. We may also use your contact information to send important notices about the Service, such as security alerts, updates, or changes to these terms.',
        'We do not sell your personal information. We only use the data you provide to operate the Service as described in this Privacy Policy.',
      ],
    ),
    (
      '4. Data Storage and Security',
      [
        'Your data is stored on secure servers and protected using reasonable administrative, technical, and physical safeguards. We apply industry-standard security measures to prevent unauthorized access, alteration, disclosure, or destruction of your information.',
        'You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account. Please notify us immediately if you suspect any unauthorized use of your account.',
      ],
    ),
    (
      '5. Data Sharing and Disclosure',
      [
        'We do not share your personal information with third parties except where it is necessary to operate the Service, to comply with legal obligations, to protect the rights and safety of our users or the public, or with your consent.',
        'If we engage third-party service providers to help operate the Service (such as hosting or cloud infrastructure), we require them to protect your information and to use it only for the services we request.',
      ],
    ),
    (
      '6. Data Retention',
      [
        'We retain your information for as long as your account is active or as needed to provide the Service, comply with legal obligations, resolve disputes, and enforce our agreements. You may request deletion of your account and associated data at any time by contacting us.',
      ],
    ),
    (
      '7. Your Rights',
      [
        'Depending on your jurisdiction, you may have the right to access, correct, update, export, or delete your personal information, and to object to or restrict certain processing activities. To exercise any of these rights, please contact us using the details below and we will respond within a reasonable time.',
      ],
    ),
    (
      '8. Changes to This Privacy Policy',
      [
        'We may update this Privacy Policy from time to time to reflect changes in our practices or applicable law. When we make changes, we will update the "Last Updated" date at the top of this policy and notify you where appropriate. Your continued use of the Service after changes take effect constitutes your acceptance of the revised policy.',
      ],
    ),
    (
      '9. Contact Us',
      [
        'If you have any questions or concerns about this Privacy Policy or how your information is handled, please contact us through the support channels provided within the application.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenTopBar(
              title: 'Privacy Policy',
              showMenuButton: false,
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Last Updated: September 25, 2026',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final (title, paragraphs) in _sections)
                      _section(title, paragraphs),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> paragraphs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  color: AppColors.gray,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _sections = <(String, List<String>)>[
    (
      '1. Acceptance of Terms',
      [
        'By accessing or using Smart POS & Inventory (the "Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not access or use the Service. Any new features, tools, or content added to the Service are also subject to these terms.',
      ],
    ),
    (
      '2. Description of Service',
      [
        'The Service is a point-of-sale and inventory management application that allows you to manage sales, products, categories, packages, stock levels, purchases, and reports for your business. We provide the Service on the terms set out in this agreement.',
      ],
    ),
    (
      '3. Account Responsibilities',
      [
        'You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account. You agree to provide accurate and complete information during registration and to keep such information up to date. You must notify us promptly if you suspect any unauthorized use of your account.',
      ],
    ),
    (
      '4. Acceptable Use',
      [
        'You agree not to misuse the Service, including attempting to access it using a method other than the interface and instructions we provide, interfering with the Service or its servers, or using the Service to violate any applicable law or regulation. You must not use the Service for any unlawful, harmful, or fraudulent purpose.',
      ],
    ),
    (
      '5. Your Data and Content',
      [
        'You retain ownership of the business data you enter into the Service. By using the Service, you grant us a limited license to store, process, and display that data solely to provide the Service to you. We do not sell your data and do not use it for any purpose other than operating the Service.',
      ],
    ),
    (
      '6. Intellectual Property',
      [
        'The Service, including its software, design, text, graphics, and logos, is owned by us or our licensors and is protected by applicable intellectual property laws. You may not copy, modify, distribute, sell, or reverse engineer any part of the Service without our prior written consent.',
      ],
    ),
    (
      '7. Disclaimer of Warranties',
      [
        'The Service is provided on an "as is" and "as available" basis, without warranties of any kind, whether express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not warrant that the Service will be uninterrupted, timely, secure, or error-free.',
      ],
    ),
    (
      '8. Limitation of Liability',
      [
        'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits, revenue, data, or goodwill, arising out of or in connection with your use of the Service. Our total aggregate liability to you shall not exceed the amount you paid to use the Service during the twelve months preceding the claim.',
      ],
    ),
    (
      '9. Indemnification',
      [
        'You agree to indemnify and hold us harmless from any claims, losses, liabilities, damages, costs, and expenses arising out of your use of the Service, your violation of these Terms, or your infringement of any rights of a third party.',
      ],
    ),
    (
      '10. Termination',
      [
        'We may suspend or terminate your access to the Service at any time, with or without notice, if you breach these Terms or if we believe such action is necessary to protect the Service or other users. You may stop using the Service at any time. Upon termination, your right to use the Service ceases immediately.',
      ],
    ),
    (
      '11. Changes to These Terms',
      [
        'We may revise these Terms of Service from time to time. When we do, we will update the "Last Updated" date at the top of this document and notify you where appropriate. Continued use of the Service after changes take effect constitutes your acceptance of the revised terms.',
      ],
    ),
    (
      '12. Governing Law',
      [
        'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which we operate, without regard to its conflict of law provisions. Any legal action arising out of these Terms shall be brought in the competent courts of that jurisdiction.',
      ],
    ),
    (
      '13. Contact Us',
      [
        'If you have any questions about these Terms of Service, please contact us through the support channels provided within the application.',
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
              title: 'Terms of Service',
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
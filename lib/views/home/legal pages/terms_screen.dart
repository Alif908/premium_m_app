import 'package:flutter/material.dart';
import 'package:premium_m_app/views/home/legal%20pages/legal_widget.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F3),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFFFFE4EC), Color(0xFFFFF5F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1A1A1A),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LegalHeaderBanner(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        subtitle: 'Last Updated: 16 June 2026',
                        description:
                            'Welcome to Badacoin Store, owned and operated by '
                            'Best Agency India, a division of Capitanse Technology '
                            'Private Limited. By using the App, you agree to these terms.',
                      ),

                      const SizedBox(height: 16),

                      LegalSection(
                        number: '1',
                        title: 'Introduction',
                        content:
                            'The App is intended exclusively for registered merchants, '
                            'business owners, store operators, and authorized representatives '
                            'participating in the Badacoin rewards ecosystem.',
                      ),

                      LegalSection(
                        number: '2',
                        title: 'Eligibility',
                        bullets: const [
                          'You must be at least 18 years old.',
                          'You must operate or represent a legitimate business.',
                          'You must complete mobile number verification.',
                          'You must comply with all applicable laws.',
                        ],
                      ),

                      LegalSection(
                        number: '3',
                        title: 'Account Registration',
                        content:
                            'The App requires mobile number registration, OTP '
                            'verification, and store profile information. Users are '
                            'responsible for maintaining accurate account information.',
                      ),

                      LegalSection(
                        number: '4',
                        title: 'Store Information',
                        content:
                            'Merchants may provide store name, owner name, mobile number, '
                            'email address, address, state, district, city, business '
                            'documents, and store photographs. The Company may verify '
                            'submitted information.',
                      ),

                      LegalSection(
                        number: '5',
                        title: 'OTP Authentication',
                        bulletsLabel: 'Users must:',
                        bullets: const [
                          'Register a valid mobile number.',
                          'Complete OTP verification.',
                          'Protect OTP codes.',
                        ],
                      ),

                      LegalSection(
                        number: '6',
                        title: 'Subscription Plans',
                        content:
                            'The App may provide paid subscription plans. Subscription '
                            'benefits may include reward transaction limits, promotional '
                            'features, advertising tools, offer management, and additional '
                            'services. The Company may modify subscription plans at any time.',
                      ),

                      LegalSection(
                        number: '7',
                        title: 'Payments',
                        content:
                            'Payments are processed through authorized payment providers '
                            'including Razorpay. The Company does not store complete payment '
                            'card information. Users agree to provide accurate payment information.',
                      ),

                      LegalSection(
                        number: '8',
                        title: 'Wallet Services',
                        content:
                            'The App may maintain wallet balances, reward balances, and '
                            'transaction records. Wallet balances displayed within the App '
                            'are subject to verification. Wallet balances do not constitute '
                            'a bank account, deposit account, or investment product.',
                      ),

                      LegalSection(
                        number: '9',
                        title: 'QR Reward Transfers',
                        content:
                            'The App allows merchants to transfer rewards through QR scanning '
                            'and phone-number-based reward allocation.',
                        bulletsLabel: 'Users agree:',
                        bullets: const [
                          'Not to perform fraudulent transfers.',
                          'Not to manipulate reward systems.',
                          'Not to create fake transactions.',
                        ],
                      ),

                      LegalSection(
                        number: '10',
                        title: 'Offers and Promotions',
                        content:
                            'Merchants may purchase promotional offers, popup advertisements, '
                            'and marketing campaigns. The Company reserves the right to '
                            'review, reject, modify, or remove promotional content.',
                      ),

                      LegalSection(
                        number: '11',
                        title: 'Image Uploads',
                        content:
                            'Merchants may upload store photographs, promotional banners, '
                            'and marketing materials. Users confirm that uploaded content '
                            'is lawful, accurate, and does not infringe third-party rights.',
                      ),

                      LegalSection(
                        number: '12',
                        title: 'Location Services',
                        content:
                            'Location information may be used for store verification, '
                            'fraud prevention, service eligibility verification, and '
                            'operational support. By enabling location services, users '
                            'consent to collection and processing of location information.',
                      ),

                      LegalSection(
                        number: '13',
                        title: 'Notifications',
                        content: 'The App may send:',
                        bullets: const [
                          'Subscription reminders',
                          'Reward notifications',
                          'Wallet updates',
                          'Security alerts',
                          'Promotional notices',
                          'Operational announcements',
                        ],
                      ),

                      LegalSection(
                        number: '14',
                        title: 'Prohibited Activities',
                        bullets: const [
                          'Create fake stores or submit false information.',
                          'Abuse reward systems or manipulate transactions.',
                          'Upload unlawful content.',
                          'Attempt unauthorized access.',
                        ],
                        isWarning: true,
                      ),

                      LegalSection(
                        number: '15',
                        title: 'Subscription Cancellation and Refunds',
                        content:
                            'Subscription purchases are subject to plan terms and pricing '
                            'displayed within the App. Refund requests, where applicable, '
                            'may be reviewed individually according to Company policy and '
                            'applicable law.',
                      ),

                      LegalSection(
                        number: '16',
                        title: 'Suspension & Termination',
                        content:
                            'The Company may suspend accounts involved in fraud, policy '
                            'violations, security concerns, or illegal activities.',
                        isWarning: true,
                      ),

                      // ✅ FIXED: linkText + linkUrl added
                      LegalSection(
                        number: '17',
                        title: 'Account Deletion',
                        content:
                            'Users may request account deletion through the link below '
                            'or by contacting Bestagencyindia2026@gmail.com. '
                            'Identity verification may be required before processing '
                            'deletion requests.',
                        linkText: 'Delete Account Page',
                        linkUrl:
                            'https://coinapi.bestagencyindia.com/delete-store.html',
                      ),

                      LegalSection(
                        number: '18',
                        title: 'Intellectual Property',
                        content:
                            'All App content, trademarks, logos, graphics, software, '
                            'databases, and related materials remain the property of '
                            'Capitanse Technology Private Limited.',
                      ),

                      LegalSection(
                        number: '19',
                        title: 'Disclaimer',
                        content:
                            'The App is provided on an "AS IS" and "AS AVAILABLE" basis. '
                            'The Company makes no guarantees regarding continuous '
                            'availability, error-free operation, or compatibility with '
                            'all devices.',
                      ),

                      LegalSection(
                        number: '20',
                        title: 'Limitation of Liability',
                        content:
                            'To the fullest extent permitted by law, the Company shall '
                            'not be liable for indirect, incidental, special, or '
                            'consequential damages arising from use of the App.',
                      ),

                      LegalSection(
                        number: '21',
                        title: 'Governing Law',
                        content:
                            'These Terms are governed by the laws of India. Disputes shall '
                            'be subject to the exclusive jurisdiction of the courts of '
                            'Thrissur, Kerala, India.',
                      ),

                      const SizedBox(height: 8),
                      const ContactCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

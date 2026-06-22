import 'package:flutter/material.dart';
import 'package:premium_m_app/views/home/legal%20pages/legal_widget.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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
                      'Privacy Policy',
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
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Last Updated: 16 June 2026',
                        description:
                            'Capitanse Technology Private Limited respects your privacy '
                            'and is committed to protecting information collected through '
                            'Badacoin Store.',
                      ),

                      const SizedBox(height: 16),

                      SectionLabel(label: 'Information We Collect'),
                      const SizedBox(height: 10),
                      const _DataCollectedGrid(),

                      const SizedBox(height: 16),

                      LegalSection(
                        number: '2',
                        title: 'How We Use Information',
                        bullets: const [
                          'Authenticate merchants and verify stores.',
                          'Process subscriptions and manage rewards.',
                          'Process transactions and prevent fraud.',
                          'Provide customer support.',
                          'Deliver notifications and service updates.',
                          'Maintain security and comply with legal obligations.',
                        ],
                      ),

                      LegalSection(
                        number: '3',
                        title: 'Legal Basis for Processing',
                        bullets: const [
                          'Legitimate business operations',
                          'Subscription management',
                          'Payment processing',
                          'Fraud prevention',
                          'Security monitoring',
                          'Legal compliance',
                        ],
                      ),

                      LegalSection(
                        number: '4',
                        title: 'Location Data Usage',
                        content: 'Location information may be used for:',
                        bullets: const [
                          'Store verification',
                          'Fraud prevention',
                          'Service eligibility checks',
                          'Operational support',
                        ],
                      ),

                      LegalSection(
                        number: '5',
                        title: 'Firebase Notification Services',
                        content:
                            'The App uses Firebase Cloud Messaging (FCM) to deliver '
                            'notifications. Firebase may process:',
                        bullets: const [
                          'Notification tokens',
                          'Device identifiers',
                          'Diagnostic information',
                          'Technical service information',
                        ],
                      ),

                      LegalSection(
                        number: '6',
                        title: 'Data Sharing',
                        content:
                            'We do not sell personal information. Information may be '
                            'shared with:',
                        bullets: const [
                          'Razorpay — Payment processing',
                          'Firebase — Notifications & analytics',
                          'Cloud hosting providers',
                          'Legal authorities when required by law',
                        ],
                      ),

                      LegalSection(
                        number: '7',
                        title: 'Data Retention',
                        content: 'Information may be retained for:',
                        bullets: const [
                          'Business operations',
                          'Legal compliance',
                          'Fraud prevention',
                          'Financial auditing',
                          'Security investigations',
                          'Dispute resolution',
                        ],
                      ),

                      LegalSection(
                        number: '8',
                        title: 'Data Security',
                        content:
                            'We implement reasonable safeguards to protect your '
                            'information. However, no electronic system can guarantee '
                            'absolute security.',
                      ),

                      LegalSection(
                        number: '9',
                        title: 'Your Rights',
                        bullets: const [
                          'Access your personal data.',
                          'Request correction of inaccurate data.',
                          'Request deletion of your data.',
                          'Get information regarding how your data is processed.',
                        ],
                      ),

                      // ✅ FIXED: linkText + linkUrl added
                      LegalSection(
                        number: '10',
                        title: 'Account Deletion',
                        content:
                            'Users may request account deletion through the link below '
                            'or by contacting support. Identity verification may be '
                            'required before processing requests. Certain information '
                            'may be retained where required by law.',
                        linkText: 'Delete Account Page',
                        linkUrl:
                            'https://coinapi.bestagencyindia.com/delete-store.html',
                      ),

                      LegalSection(
                        number: '11',
                        title: 'Third-Party Services',
                        bullets: const [
                          'Razorpay — Payment processing',
                          'Firebase — Notifications & analytics',
                          'Cloud hosting providers',
                          'Analytics providers',
                          'Monitoring services',
                        ],
                      ),

                      LegalSection(
                        number: '12',
                        title: "Children's Privacy",
                        content:
                            'The App is not intended for individuals under 18 years of age.',
                        isWarning: true,
                      ),

                      LegalSection(
                        number: '13',
                        title: 'Google Play Data Safety',
                        content: 'Data collected includes:',
                        bullets: const [
                          'Phone number, Name, Email address',
                          'Store information',
                          'Location information',
                          'Photos and uploaded images',
                          'Wallet activity and reward transactions',
                          'Payment information',
                          'Device information',
                          'Notification token',
                        ],
                      ),

                      LegalSection(
                        number: '14',
                        title: 'Changes to Policy',
                        content:
                            'The Company may update this Privacy Policy periodically. '
                            'Continued use of the App after changes constitutes acceptance '
                            'of the revised Privacy Policy.',
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

class _DataCollectedGrid extends StatelessWidget {
  static const _items = [
    (icon: Icons.phone_outlined, label: 'Phone Number'),
    (icon: Icons.person_outline_rounded, label: 'Owner Name'),
    (icon: Icons.mail_outline_rounded, label: 'Email Address'),
    (icon: Icons.store_outlined, label: 'Store Info'),
    (icon: Icons.location_on_outlined, label: 'GPS Location'),
    (icon: Icons.photo_outlined, label: 'Photos'),
    (icon: Icons.account_balance_wallet_outlined, label: 'Wallet Activity'),
    (icon: Icons.receipt_long_outlined, label: 'Transactions'),
    (icon: Icons.payment_outlined, label: 'Payment Info'),
    (icon: Icons.notifications_outlined, label: 'FCM Token'),
    (icon: Icons.phone_android_outlined, label: 'Device Info'),
    (icon: Icons.qr_code_outlined, label: 'QR Transfers'),
  ];

  const _DataCollectedGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D94).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: const Color(0xFFFF4D94), size: 22),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

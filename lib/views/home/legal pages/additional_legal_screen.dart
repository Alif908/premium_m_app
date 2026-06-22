import 'package:flutter/material.dart';
import 'package:premium_m_app/views/home/legal%20pages/legal_widget.dart';

class AdditionalLegalPoliciesPage extends StatelessWidget {
  const AdditionalLegalPoliciesPage({super.key});

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
                      'Additional Policies',
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
                        icon: Icons.gavel_rounded,
                        title: 'Additional Legal Policies',
                        subtitle: 'Last Updated: 16 June 2026',
                        description:
                            'These supplementary policies govern specific features '
                            'and services of the Badacoin Store platform.',
                      ),

                      const SizedBox(height: 16),

                      _PolicyCard(
                        icon: Icons.delete_outline_rounded,
                        title: 'Data Deletion Policy',
                        content:
                            'Users may request account deletion through the link below '
                            'or by contacting Bestagencyindia2026@gmail.com.\n\n'
                            'The Company may retain information for:',
                        linkText: 'Delete Account Page',
                        linkUrl:
                            'https://coinapi.bestagencyindia.com/delete-store.html',
                        bullets: const [
                          'Legal obligations',
                          'Fraud prevention',
                          'Financial auditing',
                          'Security investigations',
                          'Dispute resolution',
                        ],
                      ),

                      _PolicyCard(
                        icon: Icons.sms_outlined,
                        title: 'OTP Authentication Policy',
                        content: 'Users must:',
                        bullets: const [
                          'Register a valid mobile number.',
                          'Complete OTP verification.',
                          'Protect OTP codes.',
                        ],
                      ),

                      _PolicyCard(
                        icon: Icons.sms_failed_outlined,
                        title: 'OTP Restrictions',
                        content: 'Users must not:',
                        bullets: const [
                          'Share OTP codes.',
                          'Attempt unauthorized access.',
                          'Use another person\'s mobile number.',
                        ],
                        isWarning: true,
                      ),

                      _PolicyCard(
                        icon: Icons.location_on_outlined,
                        title: 'GPS Location Consent',
                        content: 'Location information may be collected for:',
                        bullets: const [
                          'Store verification',
                          'Fraud prevention',
                          'Service eligibility',
                          'Operational support',
                        ],
                      ),

                      _PolicyCard(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Subscription Policy',
                        content: 'Subscription purchases are subject to:',
                        bullets: const [
                          'Plan terms',
                          'Pricing displayed within the App',
                          'Verification requirements',
                        ],
                      ),

                      _PolicyCard(
                        icon: Icons.payment_outlined,
                        title: 'Payment & Refund Policy',
                        content:
                            'Payments are processed through Razorpay. '
                            'Refund requests, where applicable, shall be reviewed '
                            'individually according to Company policy and applicable law.',
                      ),

                      _PolicyCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet Policy',
                        content: 'Wallet balances:',
                        bullets: const [
                          'Are subject to verification',
                          'May be adjusted in case of fraud',
                          'Do not constitute a bank account',
                        ],
                      ),

                      _PolicyCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Reward Transfer Policy',
                        content:
                            'Merchants must only issue rewards for genuine customer '
                            'purchases. Fraudulent reward transfers may result in:',
                        bullets: const [
                          'Reward reversal',
                          'Account suspension',
                          'Account termination',
                        ],
                        isWarning: true,
                      ),

                      _PolicyCard(
                        icon: Icons.campaign_outlined,
                        title: 'Offer & Popup Advertising Policy',
                        content: 'Promotional content must:',
                        bullets: const [
                          'Be accurate',
                          'Comply with applicable laws',
                          'Avoid misleading claims',
                        ],
                      ),

                      _PolicyCard(
                        icon: Icons.storefront_outlined,
                        title: 'Merchant Conduct Policy',
                        content: 'Merchants must:',
                        bullets: const [
                          'Conduct business ethically',
                          'Provide accurate information',
                          'Comply with Company policies',
                        ],
                        isWarning: true,
                      ),

                      _PolicyCard(
                        icon: Icons.notifications_outlined,
                        title: 'Firebase Notification Policy',
                        content:
                            'The App may use Firebase Cloud Messaging (FCM) to send:',
                        bullets: const [
                          'Reward notifications',
                          'Subscription reminders',
                          'Wallet updates',
                          'Security alerts',
                          'Promotional announcements',
                        ],
                      ),

                      const SizedBox(height: 16),

                      SectionLabel(label: 'Google Play Data Safety'),
                      const SizedBox(height: 10),
                      const _GooglePlayCard(),

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

// ─────────────────────────────────────────────────────────────────────────────
// _PolicyCard
// ─────────────────────────────────────────────────────────────────────────────

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final List<String>? bullets;
  final bool isWarning;
  final String? linkText;
  final String? linkUrl;

  const _PolicyCard({
    required this.icon,
    required this.title,
    this.content,
    this.bullets,
    this.isWarning = false,
    this.linkText,
    this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isWarning
        ? const Color(0xFFEF4444)
        : const Color(0xFFFF4D94);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFFFF5F5)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: isWarning
            ? Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isWarning
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 12),
            Text(
              content!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.6,
              ),
            ),
          ],
          if (linkText != null && linkUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => openUrl(linkUrl!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      color: accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      linkText!,
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 10),
            ...bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// _GooglePlayCard
// ─────────────────────────────────────────────────────────────────────────────

class _GooglePlayCard extends StatelessWidget {
  const _GooglePlayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.android_rounded,
                  color: Color(0xFF4CAF50),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Google Play Data Safety',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF3F3F3), height: 1),
          const SizedBox(height: 12),
          GPRow(
            label: 'Data Collected',
            value:
                'Phone Number, Name, Email, Store Information, Location, Photos, '
                'Wallet Activity, Transaction History, Payment Information, Notification Token',
          ),
          const SizedBox(height: 10),
          GPRow(
            label: 'Purpose',
            value:
                'Authentication, Payments, Subscription Management, Reward Management, '
                'Fraud Prevention, Security, Notifications, Customer Support',
          ),
          const SizedBox(height: 10),
          GPRow(
            label: 'Shared With',
            value: 'Razorpay, Firebase, Service Providers, Legal Authorities',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We do not sell personal information.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

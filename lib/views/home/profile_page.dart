import 'package:flutter/material.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/views/home/legal%20pages/additional_legal_screen.dart';
import 'package:premium_m_app/views/home/legal%20pages/privacy_screen.dart';
import 'package:premium_m_app/views/home/legal%20pages/terms_screen.dart';
import 'package:premium_m_app/views/login_page.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// Base URL for images served from backend /uploads
// ─────────────────────────────────────────────────────────────
const String _imageBaseUrl = 'https://coinapi.bestagencyindia.com/uploads/';

// ─────────────────────────────────────────────────────────────
// URL launcher helper (used by Legal links)
// ─────────────────────────────────────────────────────────────
Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─────────────────────────────────────────────────────────────
// ProfileSettingsPage
// ─────────────────────────────────────────────────────────────

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  StoreModel? _store;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final store = await StoreApiService.getProfile();
      if (mounted) setState(() => _store = store);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              // ── AppBar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Profile & Settings',
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
                            Icons.close,
                            color: Color(0xFF1A1A1A),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4D94)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF4D94),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D94),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final store = _store!;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFFFF4D94),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header Card ────────────────────────────────────
            _ProfileHeaderCard(store: store),

            const SizedBox(height: 14),

            // ── Stats Row ──────────────────────────────────────────────
            _StatsRow(store: store),

            const SizedBox(height: 14),

            // ── Section Label ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Store',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // ── Shop Details + Subscription grouped card ───────────────
            Container(
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
                children: [
                  _SettingsTileItem(
                    icon: Icons.store_rounded,
                    title: 'Shop Details',
                    subtitle: store.storeName,
                    onTap: () {},
                    showDivider: true,
                  ),
                  _SettingsTileItem(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Subscription',
                    subtitle: _subscriptionSubtitle(store),
                    subtitleColor: _subscriptionSubtitleColor(store),
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Section Label ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Legal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // ── Links Card ─────────────────────────────────────────────
            const _LinksCard(),

            const SizedBox(height: 24),

            // ── Version ────────────────────────────────────────────────
            const Center(
              child: Text(
                'Version 2.1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // const SizedBox(height: 12),
            _DeleteAccountButton(),
            const SizedBox(height: 12),

            // ── Logout Button ──────────────────────────────────────────
            const _LogoutButton(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  String _subscriptionSubtitle(StoreModel store) {
    switch (store.subscriptionStatus) {
      case 'active':
        if (store.subscriptionExpiry != null) {
          final days = store.subscriptionExpiry!
              .difference(DateTime.now())
              .inDays;
          if (days <= 0) return 'Active — expires today';
          return 'Active — ${days}d remaining';
        }
        return 'Active';
      case 'expired':
        return 'Expired — tap to renew';
      default:
        return 'Inactive — tap to subscribe';
    }
  }

  Color _subscriptionSubtitleColor(StoreModel store) {
    switch (store.subscriptionStatus) {
      case 'active':
        return const Color(0xFF22C55E);
      case 'expired':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFEF4444);
    }
  }
}

// ── Profile Header Card ───────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final StoreModel store;

  const _ProfileHeaderCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final bool isActive = store.isSubscriptionActive;
    final Color badgeColor = isActive
        ? const Color(0xFFFF4D94)
        : const Color(0xFF9E9E9E);
    final Color badgeBg = isActive
        ? const Color(0xFFFFE4EE)
        : const Color(0xFFF0F0F0);

    final String? imageUrl =
        (store.shopImage != null && store.shopImage!.isNotEmpty)
        ? '$_imageBaseUrl${store.shopImage}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D94).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ShopAvatar(imageUrl: imageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.ownerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E8E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive
                                ? Icons.workspace_premium_rounded
                                : Icons.block_rounded,
                            color: badgeColor,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isActive ? 'Premium Partner' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF3F3F3), height: 1),
          const SizedBox(height: 16),

          if (store.address != null && store.address!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              text:
                  '${store.address}, ${store.city}, ${store.district}, ${store.state}',
            ),
            const SizedBox(height: 10),
          ],

          _InfoRow(icon: Icons.phone_outlined, text: store.phone),

          if (store.email != null && store.email!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.mail_outline_rounded, text: store.email!),
          ],

          if (store.isExpiringSoon && store.subscriptionExpiry != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCA28).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subscription expires in '
                      '${store.subscriptionExpiry!.difference(DateTime.now()).inDays}d. '
                      'Renew now to avoid interruption.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shop Avatar ───────────────────────────────────────────────────────────────

class _ShopAvatar extends StatelessWidget {
  final String? imageUrl;

  const _ShopAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D94).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const _AvatarFallback();
                },
                errorBuilder: (_, __, ___) => const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF48FB1), Color(0xFFF8BBD0), Color(0xFFFFF5F8)],
        ),
      ),
      child: const Icon(Icons.store_rounded, color: Colors.white, size: 36),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: const Color(0xFFFF4D94)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF444444),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final StoreModel store;

  const _StatsRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final wallet = store.walletBalance >= 1000
        ? '₹${(store.walletBalance / 1000).toStringAsFixed(1)}K'
        : '₹${store.walletBalance.toStringAsFixed(0)}';

    final subStatus = store.subscriptionStatus == 'active'
        ? 'Active'
        : store.subscriptionStatus == 'expired'
        ? 'Expired'
        : 'Inactive';
    final subColor = store.subscriptionStatus == 'active'
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    final statusLabel = store.status == 'approved'
        ? 'Approved'
        : store.status == 'pending'
        ? 'Pending'
        : 'Rejected';
    final statusColor = store.status == 'approved'
        ? const Color(0xFF22C55E)
        : store.status == 'pending'
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            value: wallet,
            valueColor: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.workspace_premium_outlined,
            label: 'Subscription',
            value: subStatus,
            valueColor: subColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.verified_outlined,
            label: 'Status',
            value: statusLabel,
            valueColor: statusColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          Icon(icon, size: 18, color: const Color(0xFFFF4D94)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile Item ────────────────────────────────────────────────────────

class _SettingsTileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsTileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF4D94), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor ?? const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Color(0xFFF3F3F3),
          ),
      ],
    );
  }
}

// ── Links Card ────────────────────────────────────────────────────────────────

class _LinksCard extends StatelessWidget {
  const _LinksCard();

  // ── URL map for each legal link ──────────────────────────────
  static const _links = [
    (icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', url: ''),
    (icon: Icons.description_outlined, label: 'Terms & Conditions', url: ''),
    (icon: Icons.gavel_outlined, label: 'Additional Legal Policies', url: ''),
    (
      icon: Icons.headset_mic_outlined,
      label: 'Help & Support',
      url: 'mailto:Bestagencyindia2026@gmail.com',
    ),
    (
      icon: Icons.info_outline_rounded,
      label: 'About Badacoin.store',
      url: 'https://coinapi.bestagencyindia.com/about',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: List.generate(_links.length, (index) {
          final isLast = index == _links.length - 1;
          final item = _links[index];
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (item.label == 'Terms & Conditions') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndConditionsPage(),
                      ),
                    );
                  } else if (item.label == 'Privacy Policy') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  } else if (item.label == 'Additional Legal Policies') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdditionalLegalPoliciesPage(),
                      ),
                    );
                  } else {
                    _openUrl(item.url);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: const Color(0xFF666666),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFCCCCCC),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: Color(0xFFF3F3F3),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF8E8E8E)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFFF3D3D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          await StoreApiService.logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF3D3D).withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF3D3D), size: 20),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3D3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'You will be redirected to the account deletion page. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        try {
          await StoreApiService.openDeleteAccountPage();
        } catch (e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

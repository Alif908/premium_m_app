import 'dart:async';

import 'package:flutter/material.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/views/home/add_offer_screen.dart';
import 'package:premium_m_app/views/home/add_pop_screen.dart';
import 'package:premium_m_app/views/home/history_screen.dart';
import 'package:premium_m_app/views/home/offers_show.dart';
import 'package:premium_m_app/views/home/payment&wallet_screen.dart';
import 'package:premium_m_app/views/home/popup_showing_screen.dart';
import 'package:premium_m_app/views/home/profile_page.dart';
import 'package:premium_m_app/views/home/qrscanner_screen.dart';
import 'package:premium_m_app/views/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StoreModel? _store;
  bool _isLoading = true;

  // ── Offers preview state ────────────────────────────────────
  List<OfferModel> _offers = [];
  bool _offersLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStore();
    _loadOffers();
  }

  Future<void> _loadStore() async {
    try {
      final store = await StoreApiService.getProfile();

      if (!mounted) return;

      setState(() {
        _store = store;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('Error loading store: $e');

      if (e.statusCode == 401 && mounted) {
        debugPrint('🚨 Session Expired');
        debugPrint('🚪 Redirecting to LoginPage');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      debugPrint('Unexpected Error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Load offers for the preview row on the home page ────────
  Future<void> _loadOffers() async {
    if (!mounted) return;
    setState(() => _offersLoading = true);
    try {
      final offers = await StoreApiService.getOffers();
      if (!mounted) return;
      setState(() {
        // Home page only needs a small preview row.
        _offers = offers.take(5).toList();
        _offersLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading offers preview: $e');
      if (!mounted) return;
      setState(() => _offersLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    try {
      await _loadStore();
    } catch (_) {}

    try {
      await _loadOffers();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🏠 HOME PAGE BUILD");
    debugPrint("Offers Length: ${_offers.length}");
    debugPrint("Offers Loading: $_offersLoading");
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF0F3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEC4899)),
        ),
      );
    }

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
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            color: const Color(0xFFEC4899),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _Header(store: _store),
                  const SizedBox(height: 20),
                  _ActiveSubscriptionBadge(store: _store),
                  const SizedBox(height: 20),
                  _StatsRow(store: _store),
                  const SizedBox(height: 20),
                  _ScanQrCard(),
                  const SizedBox(height: 28),

                  // ── My Offers preview (below Scan QR) ──────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Offers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OffersListScreen(),
                          ),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _OffersPreviewRow(
                    offers: _offers,
                    isLoading: _offersLoading,
                    onAddOffer: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateOfferScreen()),
                      );
                      _loadOffers();
                    },
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ➕ Add Offer (create new)
                  _QuickActionTile(
                    icon: Icons.add,
                    title: 'Add Offer',
                    subtitle: 'Create new promotion',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateOfferScreen()),
                      );
                      _loadOffers();
                    },
                  ),
                  const SizedBox(height: 12),

                  // ➕ Add Popup (create new)
                  _QuickActionTile(
                    icon: Icons.add,
                    title: 'Add Popup',
                    subtitle: 'Create popup campaign',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreatePopupScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 📄 Offers (VIEW list of added offers) — FIXED
                  _QuickActionTile(
                    icon: Icons.local_offer_rounded,
                    title: 'Offers',
                    subtitle: 'View added offers',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OffersListScreen(),
                        ),
                      );
                      _loadOffers();
                    },
                  ),
                  const SizedBox(height: 12),

                  // 📄 Popup offer (VIEW list of added popups)
                  // NOTE: needs PopupListScreen + backend /popup-list (getPopups)
                  _QuickActionTile(
                    icon: Icons.campaign_rounded,
                    title: 'Popup offer',
                    subtitle: 'View added popup ads',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PopupsListScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _QuickActionTile(
                    icon: Icons.history_rounded,
                    title: 'Transaction History',
                    subtitle: 'View all transactions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    icon: Icons.credit_card_rounded,
                    title: 'Payments & Wallet',
                    subtitle: 'Manage subscription',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PaymentsWalletScreen()),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header Widget ──────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final StoreModel? store;
  const _Header({this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hello, ${store?.ownerName ?? 'Partner'} ',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              store?.storeName ?? 'Your Store',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E8E),
              ),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileSettingsPage()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF48FB1),
                    Color(0xFFF8BBD0),
                    Color(0xFFFFF5F8),
                  ],
                ),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Active Subscription Badge ──────────────────────────────────────────────
class _ActiveSubscriptionBadge extends StatelessWidget {
  final StoreModel? store;
  const _ActiveSubscriptionBadge({this.store});

  @override
  Widget build(BuildContext context) {
    final isActive = store?.isSubscriptionActive ?? false;
    final label = isActive ? 'Active Subscription' : 'No Active Subscription';
    final color = isActive ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    final icon =
        isActive ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final StoreModel? store;
  const _StatsRow({this.store});

  @override
  Widget build(BuildContext context) {
    final wallet = store?.walletBalance ?? 0.0;
    final planStatus = store?.subscriptionStatus ?? '-';
    final daysLeft = store?.daysLeft ?? 0;
    final hasExpiry = store?.subscriptionExpiry != null;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Wallet',
            value: '₹${wallet.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Plan', value: planStatus),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Days Left',
            value: hasExpiry ? '$daysLeft' : '—',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D94).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E8E),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanQrCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QRScannerScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFF48FB1), Color(0xFFF8BBD0), Color(0xFFFFF5F8)],
          ),
        ),
        child: const Column(
          children: [
            _QrIcon(),
            SizedBox(height: 14),
            Text(
              'Scan QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrIcon extends StatelessWidget {
  const _QrIcon();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        height: 52,
        child: CustomPaint(painter: _QrPainter()),
      );
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final double u = size.width / 7;
    _drawCornerSquare(canvas, paint, strokePaint, Offset.zero, u);
    _drawCornerSquare(
      canvas,
      paint,
      strokePaint,
      Offset(size.width - 3 * u, 0),
      u,
    );
    _drawCornerSquare(
      canvas,
      paint,
      strokePaint,
      Offset(0, size.height - 3 * u),
      u,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * u + u * 0.2, 3 * u + u * 0.2, u * 0.6, u * 0.6),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * u, 4 * u, u * 0.7, u * 0.7),
        const Radius.circular(1.5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5.3 * u, 4 * u, u * 0.7, u * 0.7),
        const Radius.circular(1.5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * u, 5.3 * u, u * 0.7, u * 0.7),
        const Radius.circular(1.5),
      ),
      paint,
    );
  }

  void _drawCornerSquare(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    Offset offset,
    double u,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx, offset.dy, 3 * u, 3 * u),
        const Radius.circular(4),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          offset.dx + u * 0.75,
          offset.dy + u * 0.75,
          u * 1.5,
          u * 1.5,
        ),
        const Radius.circular(2),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OffersPreviewRow extends StatelessWidget {
  final List<OfferModel> offers;
  final bool isLoading;
  final VoidCallback onAddOffer;

  const _OffersPreviewRow({
    required this.offers,
    required this.isLoading,
    required this.onAddOffer,
  });

  static const List<Color> _fallbackColors = [
    Color(0xFFF3D6F5),
    Color(0xFFFFE4CC),
    Color(0xFFD6EEF8),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFEC4899)),
        ),
      );
    }

    if (offers.isEmpty) {
      return GestureDetector(
        onTap: onAddOffer,
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFEC4899).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFFEC4899)),
                SizedBox(height: 6),
                Text(
                  'No offers yet — tap to add one',
                  style: TextStyle(color: Color(0xFF8E8E8E), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final offer = offers[i];
          final bannerUrl = StoreApiService.resolveBannerUrl(offer.banner);
          final isActive = offer.isActive;
          final isExpired = offer.isExpired;
          final fallback = _fallbackColors[i % _fallbackColors.length];

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OffersListScreen()),
            ),
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: fallback,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerUrl != null)
                      Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFEC4899),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            offer.isPopup ? Icons.campaign : Icons.local_offer,
                            color: const Color(0xFFEC4899),
                            size: 36,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          offer.isPopup ? Icons.campaign : Icons.local_offer,
                          color: const Color(0xFFEC4899),
                          size: 36,
                        ),
                      ),

                    // Status badge top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.grey.withOpacity(0.85)
                              : (isActive
                                  ? const Color(0xFF34C759).withOpacity(0.9)
                                  : Colors.grey.withOpacity(0.85)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpired
                              ? 'Expired'
                              : (isActive ? 'Active' : 'Inactive'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Bottom title overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          offer.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D94).withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4EE),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFFFF4D94), size: 22),
            ),
            const SizedBox(width: 16),
            Column(
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

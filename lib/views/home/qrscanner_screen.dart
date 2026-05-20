import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:premium_m_app/views/home/CustomerDetailsScreen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _glowController;
  late AnimationController _iconController;

  late Animation<double> _scanLineAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _iconAnim;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _scanned = false;

  // ── Manual entry ────────────────────────────────────────────
  final TextEditingController _phoneController = TextEditingController();
  bool _showManualEntry = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📷 [QRScanner] initState — scanner initializing');

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _iconAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    debugPrint('✅ [QRScanner] All animation controllers initialized');
  }

  @override
  void dispose() {
    debugPrint('🗑️ [QRScanner] dispose — releasing controllers');
    _scanLineController.dispose();
    _glowController.dispose();
    _iconController.dispose();
    _scannerController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── QR decode + navigate ────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_scanned) {
      debugPrint('⚠️ [QRScanner] _onDetect called but _scanned=true, ignoring');
      return;
    }

    debugPrint('📷 [QRScanner] _onDetect triggered');
    debugPrint('   Barcodes count: ${capture.barcodes.length}');

    final barcode = capture.barcodes.firstOrNull;
    debugPrint('   First barcode: ${barcode?.rawValue}');
    debugPrint('   Format: ${barcode?.format}');

    final rawValue = barcode?.rawValue;

    if (rawValue == null || rawValue.isEmpty) {
      debugPrint('❌ [QRScanner] rawValue is null or empty — skipping');
      return;
    }

    debugPrint('📦 [QRScanner] Raw QR value: "$rawValue"');

    int? userId;

    if (rawValue.startsWith('userId:')) {
      final extracted = rawValue.replaceFirst('userId:', '').trim();
      userId = int.tryParse(extracted);
      debugPrint(
        '🔍 [QRScanner] Format: userId: prefix → extracted: "$extracted" → parsed: $userId',
      );
    } else {
      userId = int.tryParse(rawValue.trim());
      debugPrint('🔍 [QRScanner] Format: plain integer → parsed: $userId');
    }

    if (userId == null) {
      debugPrint('❌ [QRScanner] Could not parse userId from: "$rawValue"');
      _showInvalidQrSnack();
      return;
    }

    debugPrint('✅ [QRScanner] userId parsed: $userId — navigating');
    setState(() => _scanned = true);
    _scannerController.stop();
    _navigateToCustomer(userId);
  }

  // ── Manual phone entry submit ───────────────────────────────
  void _onManualSubmit() async {
    final phone = _phoneController.text.trim();
    debugPrint('📱 [QRScanner] Manual entry submitted: "$phone"');

    if (phone.length != 10) {
      debugPrint('❌ [QRScanner] Invalid phone length: ${phone.length}');
      _showSnack('Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _isSearching = true);

    try {
      debugPrint('🔍 [QRScanner] Looking up userId for phone: $phone');

      final userId = await _getUserIdByPhone(phone);

      if (!mounted) return;

      if (userId == null) {
        debugPrint('❌ [QRScanner] No user found for phone: $phone');
        setState(() => _isSearching = false);
        _showSnack('No customer found with this number');
        return;
      }

      debugPrint('✅ [QRScanner] Found userId: $userId for phone: $phone');
      setState(() {
        _isSearching = false;
        _showManualEntry = false;
        _scanned = true;
      });
      _scannerController.stop();
      _phoneController.clear();
      _navigateToCustomer(userId);
    } catch (e) {
      debugPrint('🔴 [QRScanner] Error looking up phone: $e');
      if (!mounted) return;
      setState(() => _isSearching = false);
      _showSnack('Something went wrong. Try again.');
    }
  }

  // ── Lookup userId by phone via API ──────────────────────────
  // TODO: Replace with your actual StoreApiService call
  // Example: final result = await StoreApiService.getUserByPhone(phone);
  Future<int?> _getUserIdByPhone(String phone) async {
    debugPrint('📡 [QRScanner] _getUserIdByPhone: $phone');

    // ── Placeholder — replace with real API call ─────────────
    // final result = await StoreApiService.getUserByPhone(phone);
    // return result?.id;

    // Simulated delay (remove when real API is connected)
    await Future.delayed(const Duration(milliseconds: 800));
    debugPrint('⚠️ [QRScanner] Using placeholder — connect real API here');
    return null;
  }

  void _navigateToCustomer(int userId) {
    debugPrint(
      '🚀 [QRScanner] Navigating to CustomerDetailsScreen userId: $userId',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailsScreen(userId: userId)),
    ).then((_) {
      debugPrint(
        '🔙 [QRScanner] Returned from CustomerDetailsScreen — resuming',
      );
      if (mounted) {
        setState(() => _scanned = false);
        _scannerController.start();
        debugPrint('✅ [QRScanner] Scanner restarted');
      }
    });
  }

  void _showInvalidQrSnack() {
    _showSnack('Invalid QR code. Please scan a valid ClubIndia QR.');
  }

  void _showSnack(String message) {
    debugPrint('💬 [QRScanner] Snack: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.2),
            radius: 1.4,
            colors: [Color(0xFF1b2e42), Color(0xFF0f1e2d), Color(0xFF0b1520)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Top black bar ──────────────────────
                      Container(
                        decoration: const BoxDecoration(color: Colors.black),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    debugPrint('🔙 [QRScanner] Close tapped');
                                    Navigator.of(context).maybePop();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Color(0xFFFAFAFA),
                                  ),
                                ),
                              ),
                              const Text(
                                'Scan QR Code',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFAFAFA),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    debugPrint(
                                      '🔦 [QRScanner] Torch toggle tapped',
                                    );
                                    _scannerController.toggleTorch();
                                  },
                                  child: const Icon(
                                    Icons.flashlight_on_rounded,
                                    size: 22,
                                    color: Color(0xFFFAFAFA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Scanner area ───────────────────────
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── QR box ──────────────────
                                SizedBox(
                                  width: 272,
                                  height: 368,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.topCenter,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _glowAnim,
                                        builder: (context, child) {
                                          final glowSpread =
                                              6.0 + (_glowAnim.value * 8.0);
                                          final glowOpacity =
                                              0.5 + (_glowAnim.value * 0.22);
                                          final outerOpacity =
                                              0.2 + (_glowAnim.value * 0.12);

                                          return Container(
                                            width: 272,
                                            height: 290,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              border: Border.all(
                                                color: const Color(0xFFF472B6),
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFEC4899,
                                                  ).withOpacity(glowOpacity),
                                                  blurRadius: glowSpread * 3,
                                                  spreadRadius: glowSpread,
                                                ),
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFEC4899,
                                                  ).withOpacity(outerOpacity),
                                                  blurRadius: 55,
                                                  spreadRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Stack(
                                            children: [
                                              MobileScanner(
                                                controller: _scannerController,
                                                onDetect: _onDetect,
                                              ),
                                              AnimatedBuilder(
                                                animation: _scanLineAnim,
                                                builder: (context, _) {
                                                  return Positioned(
                                                    top:
                                                        _scanLineAnim.value *
                                                        286,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      height: 2,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.transparent,
                                                            const Color(
                                                              0xFFEC4899,
                                                            ).withOpacity(0.5),
                                                            const Color(
                                                              0xFFEC4899,
                                                            ).withOpacity(0.95),
                                                            const Color(
                                                              0xFFEC4899,
                                                            ).withOpacity(0.5),
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const Positioned(
                                                top: 12,
                                                left: 12,
                                                child: _CornerMarker(
                                                  corner: _Corner.topLeft,
                                                ),
                                              ),
                                              const Positioned(
                                                top: 12,
                                                right: 12,
                                                child: _CornerMarker(
                                                  corner: _Corner.topRight,
                                                ),
                                              ),
                                              const Positioned(
                                                bottom: 12,
                                                left: 12,
                                                child: _CornerMarker(
                                                  corner: _Corner.bottomLeft,
                                                ),
                                              ),
                                              const Positioned(
                                                bottom: 12,
                                                right: 12,
                                                child: _CornerMarker(
                                                  corner: _Corner.bottomRight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        bottom: 46,
                                        left: 0,
                                        right: 0,
                                        child: Text(
                                          'Point camera at customer QR code',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xBFFFFFFF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // ── OR divider ───────────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.45,
                                            ),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Enter number button / field ──
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.12),
                                            end: Offset.zero,
                                          ).animate(anim),
                                          child: child,
                                        ),
                                      ),
                                  child: _showManualEntry
                                      ? _ManualEntryField(
                                          key: const ValueKey('field'),
                                          controller: _phoneController,
                                          isSearching: _isSearching,
                                          onSubmit: _onManualSubmit,
                                          onCancel: () {
                                            debugPrint(
                                              '❌ [QRScanner] Manual entry cancelled',
                                            );
                                            setState(() {
                                              _showManualEntry = false;
                                              _phoneController.clear();
                                            });
                                          },
                                        )
                                      : GestureDetector(
                                          key: const ValueKey('button'),
                                          onTap: () {
                                            debugPrint(
                                              '📱 [QRScanner] Enter number tapped',
                                            );
                                            setState(
                                              () => _showManualEntry = true,
                                            );
                                          },
                                          child: Container(
                                            width: 272,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFF472B6,
                                                ).withOpacity(0.5),
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.phone_outlined,
                                                  color: Color(0xFFF472B6),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Enter Customer Number',
                                                  style: TextStyle(
                                                    color: Color(0xFFF472B6),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
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
      ),
    );
  }
}

// ── Manual entry field widget ─────────────────────────────────

class _ManualEntryField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _ManualEntryField({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 272,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF472B6).withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFFF472B6),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: '10 digit mobile number',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    cursorColor: const Color(0xFFF472B6),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Cancel
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Search
              Expanded(
                child: GestureDetector(
                  onTap: isSearching ? null : onSubmit,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF48FB1), Color(0xFFF8BBD0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Corner marker widget ──────────────────────────────────────

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerMarker extends StatelessWidget {
  final _Corner corner;
  const _CornerMarker({super.key, required this.corner});

  @override
  Widget build(BuildContext context) {
    final bool top = corner == _Corner.topLeft || corner == _Corner.topRight;
    final bool left = corner == _Corner.topLeft || corner == _Corner.bottomLeft;

    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF472B6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double x = left ? 0 : size.width;
    final double y = top ? 0 : size.height;
    final double dx = left ? size.width : -size.width;
    final double dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

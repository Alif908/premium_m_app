// ============================================================
// lib/views/home/QRScannerScreen.dart
//
// Three reward approaches — all properly connected:
//
//   Approach 2 (PRIMARY)   QR scanned → parse userId directly
//                          → navigate CustomerDetailsScreen(userId, mode: qr)
//
//   Approach 1 (CLUBINDIA) QR starts with "CLUBINDIA-{phone}"
//                          → getUserIdByPhone API
//                          → if found: CustomerDetailsScreen(userId, mode: qr)
//                          → if not found: show error, resume scan
//
//   Approach 3 (MANUAL)    Store owner types phone + amount inline
//                          → manualPhoneTransfer() directly
//                          → ManualSuccessSheet, NO CustomerDetailsScreen
//
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/views/home/CustomerDetailsScreen.dart';

// ─── Transfer mode passed to CustomerDetailsScreen ──────────
enum RewardTransferMode { qr }

// ─── Internal screen state ───────────────────────────────────
enum _ScreenMode { scanning, manualEntry }

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  // ── Animations ───────────────────────────────────────────
  late final AnimationController _scanLineCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _iconCtrl;
  late final Animation<double> _scanLineAnim;
  late final Animation<double> _glowAnim;

  // ── Scanner ───────────────────────────────────────────────
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // ── State ─────────────────────────────────────────────────
  _ScreenMode _mode = _ScreenMode.scanning;
  bool _qrLocked = false; // prevents double-fire on QR detect
  bool _isWorking = false; // spinner for API calls

  // ── Manual entry controllers ──────────────────────────────
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    debugPrint('📷 [QRScanner] initState');

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scanLineAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.linear));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    debugPrint('🗑️ [QRScanner] dispose');
    _scanLineCtrl.dispose();
    _glowCtrl.dispose();
    _iconCtrl.dispose();
    _scanner.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // APPROACH 1 + 2 — QR Detection
  // ══════════════════════════════════════════════════════════

  void _onDetect(BarcodeCapture capture) {
    if (_qrLocked || _mode != _ScreenMode.scanning) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    debugPrint('📦 [QRScanner] QR raw: "$rawValue"');
    _lockScanner();

    if (rawValue.startsWith('CLUBINDIA-')) {
      // Approach 1
      final phone = rawValue.replaceFirst('CLUBINDIA-', '').trim();
      _resolvePhoneToUserId(phone);
    } else if (rawValue.startsWith('userId:')) {
      // Approach 2 — "userId:123"
      final userId = int.tryParse(rawValue.replaceFirst('userId:', '').trim());
      _navigateToCustomer(userId);
    } else if (rawValue.trim().startsWith('{')) {
      // ✅ NEW: JSON format — {"user_id": 3}
      try {
        final Map<String, dynamic> json = jsonDecode(rawValue.trim());
        final userId = json['user_id'] is int
            ? json['user_id'] as int
            : int.tryParse(json['user_id']?.toString() ?? '');
        debugPrint('🔍 [QRScanner] JSON format → userId: $userId');
        _navigateToCustomer(userId);
      } catch (e) {
        debugPrint('❌ [QRScanner] JSON parse failed: $e');
        _unlockScanner();
        _showError('Invalid QR code. Please scan a valid ClubIndia QR.');
      }
    } else {
      // Approach 2 — plain integer "123"
      final userId = int.tryParse(rawValue.trim());
      debugPrint('🔍 [QRScanner] Plain integer → userId: $userId');
      _navigateToCustomer(userId);
    }
  }

  /// Approach 1: CLUBINDIA- QR → look up userId by phone, then navigate
  Future<void> _resolvePhoneToUserId(String phone) async {
    debugPrint('📡 [QRScanner] _resolvePhoneToUserId: $phone');
    setState(() => _isWorking = true);

    try {
      final userId = await StoreApiService.getUserIdByPhone(phone);
      debugPrint('✅ [QRScanner] Phone lookup → userId: $userId');

      if (!mounted) return;
      setState(() => _isWorking = false);

      if (userId == null) {
        _unlockScanner();
        _showError('No customer found for this QR code');
        return;
      }

      _navigateToCustomer(userId);
    } on ApiException catch (e) {
      debugPrint('🔴 [QRScanner] ApiException in phone lookup: ${e.message}');
      if (!mounted) return;
      setState(() => _isWorking = false);
      _unlockScanner();
      _showError(e.message);
    } catch (e) {
      debugPrint('🔴 [QRScanner] Unknown error in phone lookup: $e');
      if (!mounted) return;
      setState(() => _isWorking = false);
      _unlockScanner();
      _showError('Something went wrong. Try scanning again.');
    }
  }

  /// Navigate to CustomerDetailsScreen — Approaches 1 & 2
  void _navigateToCustomer(int? userId) {
    if (userId == null) {
      debugPrint('❌ [QRScanner] Cannot navigate — userId is null');
      _unlockScanner();
      _showError('Invalid QR code. Please scan a valid ClubIndia QR.');
      return;
    }

    debugPrint(
      '🚀 [QRScanner] Navigating → CustomerDetailsScreen(userId: $userId)',
    );
    _scanner.stop();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailsScreen(userId: userId)),
    ).then((_) {
      debugPrint('🔙 [QRScanner] Returned from CustomerDetailsScreen');
      if (mounted) {
        _unlockScanner();
        _scanner.start();
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // APPROACH 3 — Manual Phone + Amount (inline, no navigation)
  // ══════════════════════════════════════════════════════════

  Future<void> _onManualTransferSubmit() async {
    final phone = _phoneCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();

    debugPrint(
      '📱 [QRScanner] Manual submit — phone: $phone  amount: $amountText',
    );

    // ── Validation ────────────────────────────────────────
    if (phone.length != 10) {
      _showError('Enter a valid 10-digit mobile number');
      return;
    }

    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      _showError('Enter a valid purchase amount');
      return;
    }

    setState(() => _isWorking = true);
    FocusScope.of(context).unfocus();

    try {
      debugPrint(
        '📡 [QRScanner] manualPhoneTransfer(phone: $phone, amount: $amount)',
      );

      // Approach 3: single API call — finds user or creates temp account
      final result = await StoreApiService.manualPhoneTransfer(
        phone: phone,
        purchaseAmount: amount,
      );

      debugPrint(
        '✅ [QRScanner] manualPhoneTransfer success → '
        'pts: ${result.rewardPoints}  isTemp: ${result.isTemporaryUser}',
      );

      if (!mounted) return;
      setState(() => _isWorking = false);

      // Clear fields before showing success sheet
      _phoneCtrl.clear();
      _amountCtrl.clear();

      // Show inline success bottom sheet — no navigation needed
      _showManualSuccessSheet(result);
    } on ApiException catch (e) {
      debugPrint(
        '🔴 [QRScanner] ApiException in manualPhoneTransfer: ${e.message}',
      );
      if (!mounted) return;
      setState(() => _isWorking = false);
      _showError(e.message);
    } catch (e) {
      debugPrint('🔴 [QRScanner] Unknown error in manualPhoneTransfer: $e');
      if (!mounted) return;
      setState(() => _isWorking = false);
      _showError('Something went wrong. Try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // MANUAL SUCCESS BOTTOM SHEET
  // ══════════════════════════════════════════════════════════

  void _showManualSuccessSheet(ManualTransferResultModel result) {
    debugPrint('🎉 [QRScanner] Showing manual success sheet');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ManualSuccessSheet(result: result),
    ).then((_) {
      // After dismissal, switch back to scanner view
      if (mounted) {
        setState(() => _mode = _ScreenMode.scanning);
        _scanner.start();
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════

  void _lockScanner() {
    setState(() => _qrLocked = true);
    _scanner.stop();
    debugPrint('🔒 [QRScanner] Scanner locked');
  }

  void _unlockScanner() {
    if (mounted) setState(() => _qrLocked = false);
    debugPrint('🔓 [QRScanner] Scanner unlocked');
  }

  void _switchToManualEntry() {
    debugPrint('📱 [QRScanner] Switching to manual entry');
    _scanner.stop();
    setState(() => _mode = _ScreenMode.manualEntry);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  void _switchToScanner() {
    debugPrint('📷 [QRScanner] Switching back to scanner');
    FocusScope.of(context).unfocus();
    _phoneCtrl.clear();
    _amountCtrl.clear();
    setState(() => _mode = _ScreenMode.scanning);
    _scanner.start();
  }

  void _showError(String message) {
    debugPrint('💬 [QRScanner] Error snack: $message');
    if (!mounted) return;
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

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.2),
            radius: 1.4,
            colors: [Color(0xFF1b2e42), Color(0xFF0f1e2d), Color(0xFF0b1520)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: _mode == _ScreenMode.scanning
                ? _buildScannerView(key: const ValueKey('scanner'))
                : _buildManualEntryView(key: const ValueKey('manual')),
          ),
        ),
      ),
    );
  }

  // ─── Scanner view (Approach 1 + 2) ───────────────────────
  Widget _buildScannerView({Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────
                  _buildTopBar(
                    title: 'Scan QR Code',
                    onClose: () => Navigator.of(context).maybePop(),
                  ),

                  // ── Scanner area ─────────────────────────
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // QR viewfinder
                            _buildQrBox(),

                            const SizedBox(height: 28),

                            // Working indicator or OR divider
                            if (_isWorking)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFF472B6),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Looking up customer…',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              _buildOrDivider(),

                            const SizedBox(height: 20),

                            // Enter number button (switches to manual view)
                            if (!_isWorking)
                              GestureDetector(
                                onTap: _switchToManualEntry,
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
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  // ─── Manual entry view (Approach 3) ──────────────────────
  Widget _buildManualEntryView({Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────
                  _buildTopBar(
                    title: 'Enter Customer Details',
                    onClose: _switchToScanner,
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),

                          // Approach 3 label badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF472B6).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF472B6).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Manual Reward Transfer',
                              style: TextStyle(
                                color: Color(0xFFF472B6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'No QR needed',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Phone field ──────────────────
                          Text(
                            'Customer Phone Number',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField(
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            hintText: '10-digit mobile number',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            prefixIcon: Icons.phone_outlined,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),

                          const SizedBox(height: 20),

                          // ── Amount field ─────────────────
                          Text(
                            'Purchase Amount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField(
                            controller: _amountCtrl,
                            hintText: 'Enter amount in ₹',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Icons.currency_rupee,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            onSubmitted: (_) =>
                                _isWorking ? null : _onManualTransferSubmit(),
                          ),

                          const SizedBox(height: 12),

                          // Temp account note
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.white.withOpacity(0.35),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'If customer is not registered, a temporary wallet is auto-created',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // ── Submit button ─────────────────
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: GestureDetector(
                              onTap: _isWorking
                                  ? null
                                  : _onManualTransferSubmit,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: double.infinity,
                                height: 58,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: _isWorking
                                        ? [
                                            const Color(
                                              0xFFF9A8D4,
                                            ).withOpacity(0.5),
                                            const Color(
                                              0xFFEC4899,
                                            ).withOpacity(0.5),
                                          ]
                                        : [
                                            const Color(0xFFF9A8D4),
                                            const Color(0xFFEC4899),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: _isWorking
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFEC4899,
                                            ).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: _isWorking
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Transfer Reward Points',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ══════════════════════════════════════════════════════════

  Widget _buildTopBar({required String title, required VoidCallback onClose}) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close,
                size: 24,
                color: Color(0xFFFAFAFA),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
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
                debugPrint('🔦 [QRScanner] Torch toggle');
                _scanner.toggleTorch();
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
    );
  }

  Widget _buildQrBox() {
    return SizedBox(
      width: 272,
      height: 320,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Glowing border
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) {
              final glowSpread = 6.0 + (_glowAnim.value * 8.0);
              final glowOpacity = 0.5 + (_glowAnim.value * 0.22);
              return Container(
                width: 272,
                height: 290,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF472B6),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(glowOpacity),
                      blurRadius: glowSpread * 3,
                      spreadRadius: glowSpread,
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFFEC4899,
                      ).withOpacity(glowOpacity * 0.4),
                      blurRadius: 55,
                      spreadRadius: 12,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  MobileScanner(controller: _scanner, onDetect: _onDetect),
                  // Scan line
                  AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (context, _) => Positioned(
                      top: _scanLineAnim.value * 286,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFEC4899).withOpacity(0.5),
                              const Color(0xFFEC4899).withOpacity(0.95),
                              const Color(0xFFEC4899).withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Corner markers
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: _CornerMarker(corner: _Corner.topLeft),
                  ),
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: _CornerMarker(corner: _Corner.topRight),
                  ),
                  const Positioned(
                    bottom: 12,
                    left: 12,
                    child: _CornerMarker(corner: _Corner.bottomLeft),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 12,
                    child: _CornerMarker(corner: _Corner.bottomRight),
                  ),
                ],
              ),
            ),
          ),
          // Hint label below viewfinder
          const Positioned(
            bottom: 40,
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
    );
  }

  Widget _buildOrDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: Colors.white.withOpacity(0.15)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'OR',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: Colors.white.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    required TextInputType keyboardType,
    IconData? prefixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF472B6).withOpacity(0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            const SizedBox(width: 14),
            Icon(prefixIcon, color: const Color(0xFFF472B6), size: 18),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              maxLength: maxLength,
              autofocus: false,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              cursorColor: const Color(0xFFF472B6),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MANUAL SUCCESS BOTTOM SHEET (Approach 3)
// Shown after manualPhoneTransfer() succeeds
// ══════════════════════════════════════════════════════════════

class _ManualSuccessSheet extends StatelessWidget {
  final ManualTransferResultModel result;

  const _ManualSuccessSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 28),

          // Success icon
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Points Transferred!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1a1a1a),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            result.phone,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Points badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF0F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '+${result.rewardPoints.toStringAsFixed(2)} pts',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New balance: ${result.formattedBalance}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Temporary user hint
          if (result.isTemporaryUser)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCF50).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFB07800),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.statusMessage,
                      style: const TextStyle(
                        color: Color(0xFF705000),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CORNER MARKER
// ══════════════════════════════════════════════════════════════

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerMarker extends StatelessWidget {
  final _Corner corner;
  const _CornerMarker({super.key, required this.corner});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _CornerPainter(
          top: corner == _Corner.topLeft || corner == _Corner.topRight,
          left: corner == _Corner.topLeft || corner == _Corner.bottomLeft,
        ),
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

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

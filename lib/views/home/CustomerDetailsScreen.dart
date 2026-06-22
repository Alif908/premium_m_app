import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/views/home/home_page.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int userId;

  const CustomerDetailsScreen({super.key, required this.userId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with TickerProviderStateMixin {
  // ── Input ─────────────────────────────────────────────────
  final TextEditingController _amountCtrl = TextEditingController(text: '0');
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  // ── API state ─────────────────────────────────────────────
  bool _isLoading = false;
  ScanResultModel? _result;
  bool _showSuccess = false;

  // ── Success animation ─────────────────────────────────────
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;

  // ── Quick-amount presets ──────────────────────────────────
  static const List<int> _presets = [100, 250, 500, 1000];

  double get _purchaseAmount => double.tryParse(_amountCtrl.text) ?? 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🛍️ [CustomerDetails] initState — userId: ${widget.userId}');

    _amountCtrl.addListener(() => setState(() {}));
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );

    _successFade = CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _focusNode.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // CONFIRM — Approach 1 & 2
  // POST /store/instant-qr-transfer
  // ══════════════════════════════════════════════════════════

  Future<void> _confirmAndAddPoints() async {
    debugPrint(
      '✅ [CustomerDetails] _confirmAndAddPoints — '
      'userId: ${widget.userId}  amount: $_purchaseAmount',
    );

    if (_purchaseAmount <= 0) {
      _showSnack('Enter a valid purchase amount');
      return;
    }

    setState(() => _isLoading = true);
    _focusNode.unfocus();

    try {
      // scanQr wraps POST /store/instant-qr-transfer
      // body: { qr_data: { user_id }, purchase_amount }
      final result = await StoreApiService.scanQr(
        userId: widget.userId,
        purchaseAmount: _purchaseAmount,
      );

      debugPrint(
        '✅ [CustomerDetails] scanQr success — '
        'customer: ${result.customer.name ?? "ID#${result.customer.id}"}  '
        'pts: ${result.transaction.rewardPoints}  '
        'newBal: ${result.customer.walletBalance}',
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
        _showSuccess = true;
      });

      _successCtrl.forward();

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomePage(), // OR HomePage
          ),
          (route) => false,
        );
      });
    } on ApiException catch (e) {
      debugPrint(
        '🔴 [CustomerDetails] ApiException: [${e.statusCode}] ${e.message}',
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(e.message);
    } catch (e) {
      debugPrint('🔴 [CustomerDetails] Unknown error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Something went wrong. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // AMOUNT HELPERS
  // ══════════════════════════════════════════════════════════

  void _setPreset(int value) {
    _amountCtrl.text = value.toString();
    _amountCtrl.selection = TextSelection.collapsed(
      offset: _amountCtrl.text.length,
    );
    _focusNode.unfocus();
  }

  void _increment() {
    final v = (_purchaseAmount.toInt()) + 1;
    _amountCtrl.text = v.toString();
    _amountCtrl.selection = TextSelection.collapsed(
      offset: _amountCtrl.text.length,
    );
  }

  void _decrement() {
    final v = (_purchaseAmount.toInt()) - 1;
    if (v < 0) return;
    _amountCtrl.text = v.toString();
    _amountCtrl.selection = TextSelection.collapsed(
      offset: _amountCtrl.text.length,
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // RESET — clears the form on pull-to-refresh
  // ══════════════════════════════════════════════════════════

  Future<void> _resetForm() async {
    setState(() {
      _amountCtrl.text = '0';
      _amountCtrl.selection = TextSelection.collapsed(offset: 1);
      _result = null;
      _showSuccess = false;
    });
    _focusNode.unfocus();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF0F4),
      body: Stack(
        children: [
          // ── Main content ────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _resetForm,
                  color: const Color(0xFFEC4899),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // ── App bar ─────────────────────
                            _buildTopBar(),

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),

                                    // ── Customer card ────────
                                    _buildCustomerCard(),

                                    const SizedBox(height: 16),

                                    // ── Amount card ──────────
                                    _buildAmountCard(),

                                    const SizedBox(height: 16),

                                    // ── Quick presets ─────────
                                    _buildPresetRow(),

                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),

                            // ── Confirm button ───────────────
                            _buildConfirmButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Success overlay ──────────────────────────────
          if (_showSuccess && _result != null) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // COMPONENT BUILDERS
  // ══════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: Color(0xFF1a1a1a),
                ),
              ),
            ),
          ),
          const Text(
            'Add Points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1a1a),
            ),
          ),
          // Customer ID badge (top-right)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${widget.userId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEC4899),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _card(
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person_outline, color: Colors.white, size: 24),
            ),
          ),

          const SizedBox(width: 14),

          // Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Scanned',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 15,
                    color: Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'User ID #${widget.userId}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Ready badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ready',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Amount',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reward points are calculated on confirm',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 14),

          // Amount input row
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFFEC4899)
                    : const Color(0xFFF472B6).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Rupee prefix
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFFBBBBBB),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Amount text field
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFF1a1a1a),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onTap: () {
                      if (_amountCtrl.text == '0') {
                        _amountCtrl.clear();
                      }
                    },
                  ),
                ),

                // Stepper
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stepperBtn(
                        icon: Icons.keyboard_arrow_up,
                        onTap: _increment,
                      ),
                      _stepperBtn(
                        icon: Icons.keyboard_arrow_down,
                        onTap: _decrement,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Icon(icon, size: 20, color: const Color(0xFF999999)),
      ),
    );
  }

  Widget _buildPresetRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick amounts',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF1a1a1a).withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _presets
              .map(
                (v) => Expanded(
                  child: GestureDetector(
                    onTap: () => _setPreset(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                        right: v != _presets.last ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _purchaseAmount == v.toDouble()
                            ? const Color(0xFFEC4899).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _purchaseAmount == v.toDouble()
                              ? const Color(0xFFEC4899)
                              : const Color(0xFFEEEEEE),
                          width: _purchaseAmount == v.toDouble() ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '₹$v',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _purchaseAmount == v.toDouble()
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final hasValidAmount = _purchaseAmount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GestureDetector(
        onTap: (_isLoading || !hasValidAmount) ? null : _confirmAndAddPoints,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: hasValidAmount
                  ? [const Color(0xFFF9A8D4), const Color(0xFFEC4899)]
                  : [
                      const Color(0xFFF9A8D4).withOpacity(0.5),
                      const Color(0xFFEC4899).withOpacity(0.5),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: hasValidAmount
                ? [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Confirm & Add Points',
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
    );
  }

  // ══════════════════════════════════════════════════════════
  // SUCCESS OVERLAY
  // Built from ScanResultModel returned by scanQr()
  // ══════════════════════════════════════════════════════════

  Widget _buildSuccessOverlay() {
    final r = _result!;
    final customerName = r.customer.name?.trim();
    final hasName = customerName != null && customerName.isNotEmpty;

    return FadeTransition(
      opacity: _successFade,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: ScaleTransition(
            scale: _successScale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.18),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Check icon
                  Container(
                    width: 72,
                    height: 72,
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
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Points Added!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Customer name (if returned by API) or fallback
                  if (hasName)
                    Text(
                      customerName!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'User #${r.customer.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),

                  const SizedBox(height: 22),

                  // Points badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0F4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '+${r.transaction.rewardPoints.toStringAsFixed(2)} pts',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'on ₹${r.transaction.purchaseAmount.toStringAsFixed(0)} purchase',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                        if (r.transaction.rewardPercentage > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${r.transaction.rewardPercentage.toStringAsFixed(1)}% reward rate',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFBBBBBB),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // New wallet balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: Color(0xFF888888),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'New Balance: ₹${r.customer.walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Store balance (if returned by API)
                  if (r.store.walletBalance > 0)
                    Text(
                      'Store wallet: ₹${r.store.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Auto-close indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: Color(0xFFDDDDDD),
                          strokeWidth: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Returning to scanner…',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBBBBBB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.07),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

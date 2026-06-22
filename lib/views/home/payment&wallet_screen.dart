import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';

class PaymentsWalletScreen extends StatefulWidget {
  const PaymentsWalletScreen({super.key});

  @override
  State<PaymentsWalletScreen> createState() => _PaymentsWalletScreenState();
}

class _PaymentsWalletScreenState extends State<PaymentsWalletScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  List<SubscriptionPlanModel> _plans = [];
  List<SubscriptionAddonModel> _addons = [];
  double _walletBalance = 0.0;

  StoreModel? _store;

  int? _purchasingPlanId;

  // ── Razorpay ───────────────────────────────────────────────────────────────
  late Razorpay _razorpay;

  RazorpayOrderModel? _pendingOrder;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    _loadData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Razorpay Callbacks ─────────────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    dev.log(
      '✅ [Razorpay] Payment success | orderId: ${response.orderId} | paymentId: ${response.paymentId}',
      name: 'PaymentsWalletScreen',
    );

    if (_pendingOrder == null) {
      dev.log(
        '🔴 [Razorpay] _pendingOrder is null — cannot verify',
        name: 'PaymentsWalletScreen',
      );
      _showSnack(
        'Payment received but verification failed. Contact support.',
        isError: true,
      );
      if (mounted) setState(() => _purchasingPlanId = null);
      return;
    }

    try {
      final result = await StoreApiService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        planId: _pendingOrder!.plan.id,
      );

      dev.log(
        '✅ [Razorpay] Payment verified | expiry: ${result.expiry}',
        name: 'PaymentsWalletScreen',
      );

      await _loadData();

      if (mounted) {
        _showSnack(
          'Subscription activated! Expires ${_formatDate(result.expiry)} 🎉',
        );
      }
    } on ApiException catch (e) {
      dev.log(
        '🔴 [Razorpay] verifyPayment ApiException: ${e.message}',
        name: 'PaymentsWalletScreen',
      );
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      dev.log(
        '🔴 [Razorpay] verifyPayment unknown error: $e',
        name: 'PaymentsWalletScreen',
      );
      if (mounted) {
        _showSnack(
          'Payment received but verification failed. Contact support.',
          isError: true,
        );
      }
    } finally {
      _pendingOrder = null;
      if (mounted) setState(() => _purchasingPlanId = null);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    dev.log(
      '🔴 [Razorpay] Payment error | code: ${response.code} | message: ${response.message}',
      name: 'PaymentsWalletScreen',
    );
    _pendingOrder = null;
    if (mounted) {
      setState(() => _purchasingPlanId = null);
      _showSnack(
        response.message?.isNotEmpty == true
            ? response.message!
            : 'Payment cancelled',
        isError: true,
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    dev.log(
      '💳 [Razorpay] External wallet: ${response.walletName}',
      name: 'PaymentsWalletScreen',
    );
    _pendingOrder = null;
    if (mounted) {
      setState(() => _purchasingPlanId = null);
      _showSnack(
        'External wallet selected: ${response.walletName}',
        isError: true,
      );
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StoreApiService.getPlans(),
        StoreApiService.getProfile(),
        StoreApiService.getAddons(),
      ]);

      setState(() {
        _plans = results[0] as List<SubscriptionPlanModel>;
        _store = results[1] as StoreModel;
        _walletBalance = _store?.walletBalance ?? 0.0;
        _addons = results[2] as List<SubscriptionAddonModel>;
        _loading = false;
      });
    } on ApiException catch (e) {
      dev.log(
        '🔴 [_loadData] ApiException: ${e.message}',
        name: 'PaymentsWalletScreen',
      );
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      dev.log('🔴 [_loadData] Unknown error: $e', name: 'PaymentsWalletScreen');
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  // ── Add Money ──────────────────────────────────────────────────────────────

  Future<void> _showAddMoneyDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Money to Wallet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount (₹)',
            filled: true,
            fillColor: const Color(0xFFFDF0F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixText: '₹ ',
          ),
        ),
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
              'Add',
              style: TextStyle(
                color: Color(0xFFEC4899),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final amount = double.tryParse(controller.text);
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount', isError: true);
      return;
    }

    try {
      final newBalance = await StoreApiService.addMoneyToWallet(amount);
      setState(() => _walletBalance = newBalance);
      _showSnack('₹${amount.toStringAsFixed(0)} added successfully!');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack('Something went wrong', isError: true);
    }
  }

  // ── Purchase Plan ──────────────────────────────────────────────────────────

  Future<void> _purchasePlan(SubscriptionPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Switch to ${plan.name}?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${plan.price.toStringAsFixed(0)}/month · ${plan.durationDays} days',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEC4899),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will be redirected to Razorpay to complete payment.',
              style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
          ],
        ),
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
              'Proceed',
              style: TextStyle(
                color: Color(0xFFEC4899),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _purchasingPlanId = plan.id);

    try {
      final order = await StoreApiService.createOrder(plan.id);
      _pendingOrder = order;

      dev.log(
        '✅ [_purchasePlan] Order created: ${order.orderId} | amount: ₹${order.amountRupees}',
        name: 'PaymentsWalletScreen',
      );

      final options = {
        'key': 'rzp_test_RpQCDZttUbr3uO',
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': 'Premium Store',
        'description': '${plan.name} · ${plan.durationDays} days',
        'prefill': {
          'contact': _store?.phone ?? '',
          'email': _store?.email ?? '',
        },
        'theme': {'color': '#EC4899'},
      };

      _razorpay.open(options);
    } on ApiException catch (e) {
      dev.log(
        '🔴 [_purchasePlan] ApiException: ${e.message}',
        name: 'PaymentsWalletScreen',
      );
      _pendingOrder = null;
      if (mounted) {
        _showSnack(e.message, isError: true);
        setState(() => _purchasingPlanId = null);
      }
    } catch (e) {
      dev.log(
        '🔴 [_purchasePlan] Unknown error: $e',
        name: 'PaymentsWalletScreen',
      );
      _pendingOrder = null;
      if (mounted) {
        _showSnack('Something went wrong. Please try again.', isError: true);
        setState(() => _purchasingPlanId = null);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatWallet(double v) {
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime dt) =>
      '${_monthName(dt.month)} ${dt.day}, ${dt.year}';

  String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  int? get _currentPlanId => _store?.subscriptionPlanId;
  bool get _isSubscriptionActive => _store?.isSubscriptionActive ?? false;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF0F4),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                  ),
                  const Text(
                    'Payments & Wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEC4899),
                      ),
                    )
                  : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadData)
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFEC4899),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Wallet Balance ──────────────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF48FB1),
                              Color(0xFFF8BBD0),
                              Color(0xFFFFF5F8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatWallet(_walletBalance),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _showAddMoneyDialog,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFF48FB1),
                            Color(0xFFF8BBD0),
                            Color(0xFFFFF5F8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Add Money',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Current Plan ────────────────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF0F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFEC4899),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Plan',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentPlanName(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isSubscriptionActive
                              ? const Color(0xFFE8F8EF)
                              : const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSubscriptionActive
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              color: _isSubscriptionActive
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isSubscriptionActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: _isSubscriptionActive
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEEEEE), height: 1),
                  const SizedBox(height: 16),
                  _buildPlanDetailRow('Plan Amount', _currentPlanPrice()),
                  const SizedBox(height: 12),
                  _buildPlanDetailRow(
                    'Expires On',
                    _store?.subscriptionExpiry != null
                        ? _formatDate(_store!.subscriptionExpiry!)
                        : '—',
                  ),
                  const SizedBox(height: 12),
                  _buildPlanDetailRow('Payment Method', 'Razorpay'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Available Plans ─────────────────────────────────────────────
            const Text(
              'Available Plans',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1a1a1a),
              ),
            ),
            const SizedBox(height: 14),

            if (_plans.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No plans available',
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                ),
              )
            else
              ...List.generate(_plans.length, (i) {
                final plan = _plans[i];
                final isCurrent = plan.id == _currentPlanId;
                final isPurchasing = _purchasingPlanId == plan.id;
                final isRecommended =
                    _plans.length == 3 && i == _plans.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlanCard(
                    plan: plan,
                    isCurrent: isCurrent,
                    isRecommended: isRecommended,
                    isPurchasing: isPurchasing,
                    onTap: () => _purchasePlan(plan),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // ── Add-ons ─────────────────────────────────────────────────────
            const Text(
              'Add-ons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1a1a1a),
              ),
            ),
            const SizedBox(height: 14),

            if (_addons.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No add-ons available',
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                ),
              )
            else
              ..._addons.map(
                (addon) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAddonCard(addon),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Helper methods ─────────────────────────────────────────────────────────

  String _currentPlanName() {
    if (_currentPlanId == null) return 'No Plan';
    try {
      return _plans.firstWhere((p) => p.id == _currentPlanId).name;
    } catch (_) {
      return 'Plan #$_currentPlanId';
    }
  }

  String _currentPlanPrice() {
    if (_currentPlanId == null) return '—';
    try {
      final plan = _plans.firstWhere((p) => p.id == _currentPlanId);
      return '₹${plan.price.toStringAsFixed(0)}/month';
    } catch (_) {
      return '—';
    }
  }

  // ── Widget builders ────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPlanDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF555555),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF555555),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildAddonCard(SubscriptionAddonModel addon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF0F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.extension_outlined,
              color: Color(0xFFEC4899),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              addon.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a1a),
              ),
            ),
          ),
          Text(
            '₹${addon.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEC4899),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlanModel plan,
    required bool isCurrent,
    bool isRecommended = false,
    bool isPurchasing = false,
    VoidCallback? onTap,
  }) {
    final features = <String>[
      plan.isUnlimitedTransactions
          ? 'Unlimited transactions'
          : 'Up to ${plan.transactionsLimit} transactions/month',
      '${plan.flaresLimit} flares',
      plan.isUnlimitedProducts
          ? 'Unlimited product listings'
          : '${plan.productLimit} product listings',
      '${plan.redeemPercentage.toStringAsFixed(1)}% redeem coins',
      if (plan.allowPopup) 'Popup offers',
      ...plan.featureList,
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFFFF0F5) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isCurrent
                ? Border.all(color: const Color(0xFFEC4899), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFEC4899,
                ).withOpacity(isCurrent ? 0.12 : 0.08),
                blurRadius: 20,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8EF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF22C55E),
                                  size: 13,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${plan.price.toStringAsFixed(0)}/month · ${plan.durationDays}d',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...features.map((f) => _buildFeature(f)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEC4899),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'Current\nPlan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFEC4899),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: isPurchasing ? null : onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF48FB1),
                              Color(0xFFF8BBD0),
                              Color(0xFFFFF5F8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: isPurchasing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Select',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF48FB1),
                    Color(0xFFF8BBD0),
                    Color(0xFFFFF5F8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Recommended',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFFEC4899),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF48FB1), Color(0xFFF8BBD0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentsWalletScreen — fully API-integrated with Addon purchase flow
// ─────────────────────────────────────────────────────────────────────────────

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
  List<StoreActiveAddonModel> _myAddons = []; // ← NEW: active addons
  double _walletBalance = 0.0;

  StoreModel? _store;

  // Which plan_id is currently being purchased (shows loading on that button)
  int? _purchasingPlanId;

  // Which addon_id is currently being purchased
  int? _purchasingAddonId; // ← NEW

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load core data — these must succeed
      final results = await Future.wait([
        StoreApiService.getPlans(),
        StoreApiService.getAddons(),
        StoreApiService.getProfile(),
      ]);

      // Load my-addons separately — if endpoint not ready, fail silently
      List<StoreActiveAddonModel> myAddons = [];
      try {
        myAddons = await StoreApiService.getMyAddons();
        dev.log(
          '✅ [_loadData] getMyAddons success: ${myAddons.length}',
          name: 'PaymentsWalletScreen',
        );
      } catch (e) {
        // Backend endpoint /store/my-addons may not exist yet — ignore
        dev.log(
          '⚠️ [_loadData] getMyAddons failed (endpoint may not exist yet): $e',
          name: 'PaymentsWalletScreen',
        );
      }

      setState(() {
        _plans = results[0] as List<SubscriptionPlanModel>;
        _addons = results[1] as List<SubscriptionAddonModel>;
        _store = results[2] as StoreModel;
        _myAddons = myAddons;
        _walletBalance = _store?.walletBalance ?? 0.0;
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
        content: Text(
          '₹${plan.price.toStringAsFixed(0)}/month · ${plan.durationDays} days\n\n'
          'You will be redirected to Razorpay to complete payment.',
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

      // TODO: Open Razorpay SDK here
      // On success: await StoreApiService.verifyPayment(...)

      if (!mounted) return;
      _showSnack(
        'Order created: ${order.orderId}. Integrate Razorpay SDK to complete.',
      );
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _purchasingPlanId = null);
    }
  }

  // ── Purchase Addon ─────────────────────────────────────────────────────────
  // NEW: Full addon purchase flow per PDF architecture

  Future<void> _purchaseAddon(SubscriptionAddonModel addon) async {
    // 1. Check if store has active subscription first (PDF rule)
    if (!(_store?.isSubscriptionActive ?? false)) {
      _showSnack(
        'Active subscription required to purchase add-ons',
        isError: true,
      );
      return;
    }

    // 2. Check if this addon is already active
    final alreadyActive = _myAddons.any(
      (a) => a.addonId == addon.id && a.isActive,
    );

    if (alreadyActive) {
      final existing = _myAddons.firstWhere(
        (a) => a.addonId == addon.id && a.isActive,
      );
      _showSnack(
        '${addon.name} already active until ${existing.formattedExpiry}',
        isError: true,
      );
      return;
    }

    // 3. Confirm dialog with pricing info
    final typeLabel = addon.type == 'per_day' ? '1 Day' : '1 Month';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Purchase ${addon.name}?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${addon.price.toStringAsFixed(0)} · Valid for $typeLabel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEC4899),
              ),
            ),
            if (addon.description != null) ...[
              const SizedBox(height: 8),
              Text(
                addon.description!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
            ],
            const SizedBox(height: 12),
            // Show popup city restriction note from PDF
            if (addon.name.toLowerCase().contains('popup'))
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFFF9800),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only one popup allowed per city at a time.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ],
                ),
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
              'Purchase',
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

    // 4. Call API
    setState(() => _purchasingAddonId = addon.id);

    try {
      final result = await StoreApiService.purchaseAddon(addon.id);

      if (!mounted) return;

      // 5. Refresh my-addons list to show updated status
      final updatedAddons = await StoreApiService.getMyAddons();
      if (!mounted) return;

      setState(() => _myAddons = updatedAddons);

      _showSnack(
        '${addon.name} activated until ${_formatDate(result.expiry)}!',
      );
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack('Something went wrong', isError: true);
    } finally {
      if (mounted) setState(() => _purchasingAddonId = null);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
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

  // Check if a specific addon is currently active (for badge display)
  bool _isAddonActive(int addonId) =>
      _myAddons.any((a) => a.addonId == addonId && a.isActive);

  // Get active addon expiry for display
  StoreActiveAddonModel? _getActiveAddon(int addonId) {
    try {
      return _myAddons.firstWhere((a) => a.addonId == addonId && a.isActive);
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF0F4),
      body: SafeArea(
        child: Column(
          children: [
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Wallet Balance ────────────────────────────────────────────────
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

          // ── Current Plan card ─────────────────────────────────────────────
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

          // ── Available Plans ───────────────────────────────────────────────
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

          // ── Add-ons ───────────────────────────────────────────────────────
          const Text(
            'Add-ons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 14),

          // ── No subscription warning (PDF rule) ───────────────────────────
          if (!_isSubscriptionActive)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Purchase a subscription plan first to activate add-ons.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                child: _buildAddonCard(addon: addon),
              ),
            ),

          const SizedBox(height: 30),
        ],
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

  Widget _buildAddonCard({required SubscriptionAddonModel addon}) {
    IconData icon = Icons.extension_outlined;
    if (addon.name.toLowerCase().contains('flare')) {
      icon = Icons.bolt_rounded;
    } else if (addon.name.toLowerCase().contains('product')) {
      icon = Icons.inventory_2_outlined;
    } else if (addon.name.toLowerCase().contains('popup')) {
      icon = Icons.campaign_outlined;
    } else if (addon.name.toLowerCase().contains('offer')) {
      icon = Icons.local_offer_outlined;
    }

    // Check if this addon is currently active
    final isActive = _isAddonActive(addon.id);
    final activeAddon = _getActiveAddon(addon.id);
    final isPurchasing = _purchasingAddonId == addon.id;
    final typeLabel = addon.type == 'per_day' ? '/day' : '/month';

    return _buildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF0F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFEC4899), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${addon.price.toStringAsFixed(0)}$typeLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEC4899),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (addon.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    addon.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                // Show expiry if active
                if (isActive && activeAddon != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 13,
                        color: Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active · Expires ${activeAddon.formattedExpiry}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Button: "Active" badge if already purchased, else "Add" button
          isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: isPurchasing ? null : () => _purchaseAddon(addon),
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
                            'Add',
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

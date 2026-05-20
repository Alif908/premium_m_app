import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/models/store_model.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int userId; // ← passed from QR scan

  const CustomerDetailsScreen({super.key, required this.userId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '0',
  );
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isLoading = false;

  // Real data from scan result
  ScanResultModel? _scanResult;

  // Fallback display values before confirm
  String get customerName => _scanResult?.customer.name ?? 'Customer';
  String get customerInitials {
    final name = customerName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  double get currentPoints => _scanResult?.customer.walletBalance ?? 0;
  double get purchaseAmount => double.tryParse(_amountController.text) ?? 0;

  // Optimistic preview using plan's reward % — shown before confirm
  // After confirm, use real transaction data
  double get newPoints => _scanResult != null
      ? _scanResult!.transaction.rewardPoints
      : (purchaseAmount * 0.01); // rough preview

  double get totalPoints => _scanResult != null
      ? (_scanResult!.customer.walletBalance +
            _scanResult!.transaction.rewardPoints)
      : currentPoints + newPoints;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    final val = (int.tryParse(_amountController.text) ?? 0) + 1;
    _amountController.text = val.toString();
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
  }

  void _decrement() {
    final val = (int.tryParse(_amountController.text) ?? 0) - 1;
    if (val < 0) return;
    _amountController.text = val.toString();
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
  }

  void _confirmAndAddPoints() async {
    if (purchaseAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid purchase amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await StoreApiService.scanQr(
        userId: widget.userId,
        purchaseAmount: purchaseAmount,
      );

      if (!mounted) return;

      setState(() => _scanResult = result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ₹${result.transaction.rewardPoints.toStringAsFixed(2)} points added to ${result.customer.name ?? "customer"}',
          ),
          backgroundColor: const Color(0xFFEC4899),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF0F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
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
                              'Customer Details',
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // Customer card
                              _buildCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFF472B6),
                                            Color(0xFFEC4899),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          customerInitials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 18,
                                              color: Color(0xFF555555),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              customerName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1a1a1a),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.military_tech_outlined,
                                              size: 18,
                                              color: Color(0xFFEC4899),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${currentPoints.toStringAsFixed(2)} Points',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Purchase amount card
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Enter Purchase Amount',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1a1a1a),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _isFocused
                                              ? const Color(0xFFEC4899)
                                              : const Color(0xFFF472B6),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 16),
                                            child: Text(
                                              '₹',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Color(0xFFBBBBBB),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: _amountController,
                                              focusNode: _focusNode,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Color(0xFF666666),
                                                fontWeight: FontWeight.w400,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                              onTap: () {
                                                if (_amountController.text ==
                                                    '0') {
                                                  _amountController.clear();
                                                }
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: _increment,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 5,
                                                        ),
                                                    child: const Icon(
                                                      Icons.keyboard_arrow_up,
                                                      size: 20,
                                                      color: Color(0xFF999999),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _decrement,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 5,
                                                        ),
                                                    child: const Icon(
                                                      Icons.keyboard_arrow_down,
                                                      size: 20,
                                                      color: Color(0xFF999999),
                                                    ),
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
                              ),

                              const SizedBox(height: 16),

                              // Points summary
                              _buildCard(
                                child: Column(
                                  children: [
                                    _PointsRow(
                                      label: 'Current Points',
                                      value: currentPoints.toStringAsFixed(2),
                                      valueColor: const Color(0xFF1a1a1a),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Divider(
                                        color: Color(0xFFEEEEEE),
                                        height: 1,
                                      ),
                                    ),
                                    _PointsRow(
                                      label: 'New Points',
                                      value: '+${newPoints.toStringAsFixed(2)}',
                                      valueColor: const Color(0xFF1a1a1a),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Divider(
                                        color: Color(0xFFEEEEEE),
                                        height: 1,
                                      ),
                                    ),
                                    _PointsRow(
                                      label: 'Total Points',
                                      value: totalPoints.toStringAsFixed(2),
                                      valueColor: const Color(0xFFEC4899),
                                      valueFontSize: 22,
                                      valueFontWeight: FontWeight.w700,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Confirm button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: GestureDetector(
                          onTap: _isLoading ? null : _confirmAndAddPoints,
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEC4899,
                                  ).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
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
                                  : const Text(
                                      'Confirm & Add Points',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
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
}

class _PointsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double valueFontSize;
  final FontWeight valueFontWeight;

  const _PointsRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueFontSize = 18,
    this.valueFontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: valueFontWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

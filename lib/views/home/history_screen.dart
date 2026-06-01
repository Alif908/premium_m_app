// ============================================================
// lib/screens/history_screen.dart
// Partner Store App — Transaction History Screen
// Preserves exact UI & layout structure without changes
// ============================================================

import 'package:flutter/material.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  // ── State ──────────────────────────────────────────────────
  String _selectedFilter = 'Today';
  bool _isLoading = true;
  String? _errorMessage;

  // API response — holds transactions + summary totals
  TransactionHistoryResponse? _response;

  // ── Filter label → API filter param mapping ────────────────
  static const _filterMap = {
    'Today': 'today',
    'Week': 'week',
    'Month': 'month',
  };

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // ── API call ───────────────────────────────────────────────
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiFilter = _filterMap[_selectedFilter] ?? 'today';
      final response = await StoreApiService.getTransactions(filter: apiFilter);
      if (mounted) {
        setState(() {
          _response = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiException) {
            _errorMessage = e.message;
          } else {
            _errorMessage = 'Something went wrong. Please try again.';
          }
          _isLoading = false;
        });
      }
    }
  }

  // ── Helpers from TransactionHistoryResponse model ──────────
  List<StoreTransactionModel> get _transactions =>
      _response?.transactions ?? [];

  // formattedTotalAmount from model e.g. "₹13,500.00"
  String get _totalAmount => _response?.formattedTotalAmount ?? '₹0';

  // formattedTotalPoints from model e.g. "1350 pts"
  String get _totalPoints => _response?.formattedTotalPoints ?? '0 pts';

  int get _count => _response?.count ?? 0;

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF0F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _fetchTransactions,
              color: const Color(0xFFEC4899),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // ── Top bar ──────────────────────────
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
                                'Transaction History',
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

                                // ── Summary cards ─────────────
                                Row(
                                  children: [
                                    _buildSummaryCard('Total', _totalAmount),
                                    const SizedBox(width: 10),
                                    _buildSummaryCard('Points', _totalPoints),
                                    const SizedBox(width: 10),
                                    _buildSummaryCard('Count', '$_count'),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ── Filter row ────────────────
                                Row(
                                  children: [
                                    _buildFilterChip('Today'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Week'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Month'),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.filter_alt_outlined,
                                        color: Color(0xFF555555),
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // ── Body: loading / error / list ──
                                if (_isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFEC4899),
                                      ),
                                    ),
                                  )
                                else if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFEC4899),
                                            size: 40,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF555555),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: _fetchTransactions,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFF48FB1),
                                                    Color(0xFFF8BBD0),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: const Text(
                                                'Retry',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (_transactions.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Text(
                                        'No transactions found',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ..._transactions.map(
                                    (t) => _buildTransactionCard(t),
                                  ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Filter chip: tapping re-fetches from API ───────────────
  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        if (_selectedFilter == label) return; // no-op if already selected
        setState(() => _selectedFilter = label);
        _fetchTransactions(); // re-fetch with new filter
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFF48FB1),
                    Color(0xFFF8BBD0),
                    Color(0xFFFFF5F8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.07),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w400,
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
                  color: Color(0xFF1a1a1a),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction card uses StoreTransactionModel getters ────
  Widget _buildTransactionCard(StoreTransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.07),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar — uses t.initials from model
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF48FB1),
                  Color(0xFFF8BBD0),
                  Color(0xFFFFF5F8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                t.initials, // StoreTransactionModel.initials
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + time — uses t.displayName, t.formattedTime
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.displayName, // StoreTransactionModel.displayName
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.formattedTime, // StoreTransactionModel.formattedTime
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Amount + points — uses t.formattedAmount, t.formattedPoints
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.formattedAmount, // StoreTransactionModel.formattedAmount
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1a1a1a),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.formattedPoints, // StoreTransactionModel.formattedPoints
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

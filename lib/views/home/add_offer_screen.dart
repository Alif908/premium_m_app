import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:premium_m_app/models/store_model.dart';
import 'package:premium_m_app/services/store_api_service.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  // ── Controllers ───────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _daysController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  File? _bannerFile;
  bool _submitting = false;

  // Razorpay
  late Razorpay _razorpay;

  // Cached from step 1 — needed for step 2
  RazorpayOfferOrderModel? _pendingOrder;

  final _picker = ImagePicker();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _daysController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ── Razorpay callbacks ────────────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingOrder == null) return;

    // ── Validation ─────────────────────────────
    if (response.orderId == null || response.orderId!.trim().isEmpty) {
      _showSnack(
        'Payment verification failed. Missing order id.',
        isError: true,
      );
      _pendingOrder = null;
      return;
    }

    if (response.paymentId == null || response.paymentId!.trim().isEmpty) {
      _showSnack(
        'Payment verification failed. Missing payment id.',
        isError: true,
      );
      _pendingOrder = null;
      return;
    }

    if (response.signature == null || response.signature!.trim().isEmpty) {
      _showSnack(
        'Payment verification failed. Missing signature.',
        isError: true,
      );
      _pendingOrder = null;
      return;
    }

    setState(() => _submitting = true);

    try {
      final offer = await StoreApiService.verifyOfferPurchase(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
        title: _pendingOrder!.offerTitle,
        description: _pendingOrder!.offerDescription,
        days: _pendingOrder!.days,
        banner: _pendingOrder!.banner,
      );

      if (!mounted) return;

      _showSnack('Offer "${offer.title}" activated! 🎉');

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Verification failed. Contact support.',
          isError: true,
        );
      }
    } finally {
      _pendingOrder = null;

      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _submitting = false);
    _pendingOrder = null;
    _showSnack(
      response.message?.isNotEmpty == true
          ? response.message!
          : 'Payment cancelled',
      isError: true,
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _submitting = false);
    _pendingOrder = null;
    _showSnack(
      'External wallet selected: ${response.walletName}',
      isError: true,
    );
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFFEC4899),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFEC4899),
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_bannerFile != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () {
                  setState(() => _bannerFile = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked != null) setState(() => _bannerFile = File(picked.path));
  }

  // ── Preview & Pay ─────────────────────────────────────────────────────────

  Future<void> _previewAndPay() async {
    if (_submitting) return;

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final daysText = _daysController.text.trim();

    // Validation
    if (title.isEmpty) {
      _showSnack('Please enter offer title', isError: true);
      return;
    }

    if (daysText.isEmpty) {
      _showSnack('Please enter number of days', isError: true);
      return;
    }

    final days = int.tryParse(daysText);

    if (days == null || days <= 0) {
      _showSnack(
        'Days must be a valid number greater than 0',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Step 1: Create Razorpay Order
      final order = await StoreApiService.purchaseOffer(
        title: title,
        description: desc,
        days: days,
        bannerImage: _bannerFile,
      );

      _pendingOrder = order;

      // Step 2: Show Confirmation Dialog
      final confirmed = await _showPriceConfirmDialog(order);

      if (!mounted || confirmed != true) {
        _pendingOrder = null;

        if (mounted) {
          setState(() => _submitting = false);
        }
        return;
      }

      // Step 3: Open Razorpay
      final options = {
        'key': 'rzp_test_RpQCDZttUbr3uO',
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': 'Offer Activation',
        'description': '${order.days} day offer: ${order.offerTitle}',
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#EC4899',
        },
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        _pendingOrder = null;

        if (mounted) {
          setState(() => _submitting = false);
        }

        _showSnack(
          'Unable to open payment gateway.',
          isError: true,
        );
      }
    } on ApiException catch (e) {
      _pendingOrder = null;

      if (mounted) {
        _showSnack(e.message, isError: true);
        setState(() => _submitting = false);
      }
    } catch (e) {
      _pendingOrder = null;

      if (mounted) {
        _showSnack(
          'Something went wrong. Please try again.',
          isError: true,
        );
        setState(() => _submitting = false);
      }
    }
  }

  // ── Price confirmation dialog ─────────────────────────────────────────────

  Future<bool?> _showPriceConfirmDialog(RazorpayOfferOrderModel order) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1a1a1a),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Offer Title', order.offerTitle),
            const SizedBox(height: 10),
            _confirmRow(
              'Duration',
              '${order.days} day${order.days > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 10),
            _confirmRow('Price per day', order.formattedPerDay),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  order.formattedTotalPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Computed total price preview ──────────────────────────────────────────
  // Note: This is a local estimate only. Actual price comes from backend.

  // ── Build ─────────────────────────────────────────────────────────────────

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
                      // ── Top bar ───────────────────────────────────
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
                                onTap: _submitting
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                                child: const Icon(
                                  Icons.close,
                                  size: 24,
                                  color: Color(0xFF1a1a1a),
                                ),
                              ),
                            ),
                            const Text(
                              'Create Offer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Content ───────────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // ── Banner ──────────────────────────
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Offer Banner',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1a1a1a),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: double.infinity,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDF0F4),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFF472B6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _bannerFile != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.file(
                                                      _bannerFile!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Positioned(
                                                      bottom: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(
                                                            0.55,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            20,
                                                          ),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              color:
                                                                  Colors.white,
                                                              size: 14,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'Change',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 52,
                                                    height: 52,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.upload_outlined,
                                                      color: Color(0xFFEC4899),
                                                      size: 26,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Upload Image',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF1a1a1a),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text(
                                                    'PNG, JPG up to 5MB',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF999999),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Title ────────────────────────────
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Offer Title *',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1a1a1a),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: _titleController,
                                      hint:
                                          'e.g., 50% Off on Summer Collection',
                                      capitalization:
                                          TextCapitalization.sentences,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Description ──────────────────────
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1a1a1a),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: _descController,
                                      hint: 'Describe your offer...',
                                      maxLines: 4,
                                      capitalization:
                                          TextCapitalization.sentences,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Days ─────────────────────────────
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Number of Days *',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1a1a1a),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Offer will be visible to users for this many days',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      controller: _daysController,
                                      hint: 'e.g., 7',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      prefixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                        color: Color(0xFFEC4899),
                                        size: 20,
                                      ),
                                      suffixText: 'days',
                                    ),
                                    // Live price preview
                                    ValueListenableBuilder(
                                      valueListenable: _daysController,
                                      builder: (_, value, __) {
                                        final d = int.tryParse(value.text);
                                        if (d == null || d <= 0)
                                          return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDF0F4),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.info_outline,
                                                  size: 16,
                                                  color: Color(0xFFEC4899),
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    'Final price will be confirmed before payment',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF666666),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // ── Preview & Pay button ──────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: GestureDetector(
                          onTap: _submitting ? null : _previewAndPay,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: _submitting
                                    ? [
                                        const Color(0xFFF8BBD0),
                                        const Color(0xFFFFF5F8),
                                      ]
                                    : [
                                        const Color(0xFFF48FB1),
                                        const Color(0xFFF8BBD0),
                                        const Color(0xFFFFF5F8),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: _submitting
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Processing...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.payment_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Preview & Pay',
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
            );
          },
        ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1a1a1a)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFDF0F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 4 : 16,
          vertical: 14,
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

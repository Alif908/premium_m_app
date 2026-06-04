// ============================================================
// lib/services/store_api_service.dart
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:premium_m_app/models/store_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────

// const String _baseUrl = 'https://coinapi.bestagencyindia.com/api';
const String _baseUrl = 'http://192.168.1.5:3030/api';
const String _tokenKey = 'store_token';

// ─────────────────────────────────────────────────────────────
// EXCEPTION
// ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => '❌ ApiException [$statusCode]: $message';
}

// ─────────────────────────────────────────────────────────────
// STORE API SERVICE
// ─────────────────────────────────────────────────────────────

class StoreApiService {
  // ── Token helpers ──────────────────────────────────────────

  static Future<void> _saveToken(String token) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log('💾 [Auth] _saveToken() called', name: 'StoreApiService');
    dev.log('   Key         : $_tokenKey', name: 'StoreApiService');
    dev.log('   Token length: ${token.length}', name: 'StoreApiService');
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_tokenKey, token);
    dev.log('   Saved       : $success', name: 'StoreApiService');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
  }

  static Future<String?> _getToken() async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log('🔑 [Auth] _getToken() called', name: 'StoreApiService');
    dev.log('   Looking up key: "$_tokenKey"', name: 'StoreApiService');

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    dev.log('   All SharedPrefs keys: $allKeys', name: 'StoreApiService');
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      dev.log(
        '   Result: NULL — key "$_tokenKey" not found',
        name: 'StoreApiService',
      );
    } else if (token.isEmpty) {
      dev.log('   Result: EMPTY STRING', name: 'StoreApiService');
    } else {
      dev.log(
        '   Result: EXISTS | length: ${token.length}',
        name: 'StoreApiService',
      );
    }
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    return token;
  }

  static Future<void> logout() async {
    dev.log('🚪 [Auth] logout() — removing token', name: 'StoreApiService');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    dev.log('✅ [Auth] Token removed', name: 'StoreApiService');
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    final loggedIn = token != null && token.isNotEmpty;
    dev.log('🔐 [Auth] isLoggedIn: $loggedIn', name: 'StoreApiService');
    return loggedIn;
  }

  // ── JSON request helper ────────────────────────────────────

  static Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{'Content-Type': 'application/json'};

    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log('📤 [$method] $endpoint', name: 'StoreApiService');
    dev.log('   URI: $uri', name: 'StoreApiService');

    if (requiresAuth) {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        dev.log(
          '🔴 [Auth] No token — aborting $endpoint',
          name: 'StoreApiService',
        );
        throw ApiException(
          statusCode: 401,
          message: 'Session expired. Please login again.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
      dev.log('   Auth: Bearer token attached', name: 'StoreApiService');
    }

    if (body != null) {
      dev.log('   Body: ${jsonEncode(body)}', name: 'StoreApiService');
    } else {
      dev.log('   Body: none', name: 'StoreApiService');
    }

    http.Response response;

    try {
      switch (method) {
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;
        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        case 'GET':
        default:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      dev.log('🔴 [Network Error] $endpoint → $e', name: 'StoreApiService');
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }

    dev.log('📥 [$method] $endpoint', name: 'StoreApiService');
    dev.log('   Status: ${response.statusCode}', name: 'StoreApiService');
    dev.log('   Body: ${response.body}', name: 'StoreApiService');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map
          ? decoded['message'] ?? 'Something went wrong'
          : 'Something went wrong';
      dev.log(
        '🔴 [API Error] [$method] $endpoint → [${response.statusCode}] $msg',
        name: 'StoreApiService',
      );
      throw ApiException(statusCode: response.statusCode, message: msg);
    }

    return decoded;
  }

  // ── Multipart request helper ───────────────────────────────

  static Future<dynamic> _multipartRequest({
    required String method,
    required String endpoint,
    required Map<String, String> fields,
    File? imageFile,
    String fileField = 'banner',
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log('📤 [MULTIPART $method] $endpoint', name: 'StoreApiService');
    dev.log('   Fields: $fields', name: 'StoreApiService');
    dev.log('   File: ${imageFile?.path ?? "none"}', name: 'StoreApiService');

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      dev.log(
        '🔴 [Auth] No token for multipart $endpoint',
        name: 'StoreApiService',
      );
      throw ApiException(
        statusCode: 401,
        message: 'Session expired. Please login again.',
      );
    }

    final request = http.MultipartRequest(method, uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileField, imageFile.path),
      );
      dev.log('   File attached: ${imageFile.path}', name: 'StoreApiService');
    }

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 30));
    } catch (e) {
      dev.log('🔴 [Network Error] $endpoint → $e', name: 'StoreApiService');
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }

    final response = await http.Response.fromStream(streamed);
    dev.log('📥 [MULTIPART $method] $endpoint', name: 'StoreApiService');
    dev.log('   Status: ${response.statusCode}', name: 'StoreApiService');
    dev.log('   Body: ${response.body}', name: 'StoreApiService');
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map
          ? decoded['message'] ?? 'Something went wrong'
          : 'Something went wrong';
      throw ApiException(statusCode: response.statusCode, message: msg);
    }

    return decoded;
  }

  // ════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/send-otp
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    dev.log('🔑 [sendOtp] phone: $phone', name: 'StoreApiService');
    final data = await _request(
      method: 'POST',
      endpoint: '/store/send-otp',
      body: {'phone': phone},
    );
    dev.log(
      '✅ [sendOtp] Success | OTP(dev): ${data['otp']}',
      name: 'StoreApiService',
    );
    return Map<String, dynamic>.from(data);
  }

  /// POST /api/store/verify-otp
  static Future<String> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    dev.log('✅ [verifyOtp] phone: $phone | otp: $otp', name: 'StoreApiService');
    final data = await _request(
      method: 'POST',
      endpoint: '/store/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      dev.log(
        '🔴 [verifyOtp] Token not found in response: $data',
        name: 'StoreApiService',
      );
      throw ApiException(
        statusCode: 500,
        message: 'Login failed. Token not received.',
      );
    }
    await _saveToken(token);
    dev.log(
      '🎟️ [verifyOtp] Login success, token saved',
      name: 'StoreApiService',
    );
    return token;
  }

  // ════════════════════════════════════════════════════════════
  // PROFILE
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/profile
  static Future<StoreModel> getProfile() async {
    dev.log('👤 [getProfile] Fetching profile...', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/store/profile',
      requiresAuth: true,
    );
    dev.log('📦 [getProfile] raw response: $data', name: 'StoreApiService');
    final storeJson = data['store'] ?? data;
    final store = StoreModel.fromJson(storeJson as Map<String, dynamic>);
    dev.log(
      '✅ [getProfile] storeName: ${store.storeName} | '
      'subscriptionStatus: ${store.subscriptionStatus} | '
      'walletBalance: ${store.walletBalance}',
      name: 'StoreApiService',
    );
    return store;
  }

  // ════════════════════════════════════════════════════════════
  // QR REWARD TRANSFER
  // ════════════════════════════════════════════════════════════

  static Future<ScanResultModel> scanQr({
    required int userId,
    required double purchaseAmount,
  }) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log(
      '📷 [scanQr] ── Approach 2: Instant QR Transfer ──',
      name: 'StoreApiService',
    );
    dev.log('   userId        : $userId', name: 'StoreApiService');
    dev.log('   purchaseAmount: ₹$purchaseAmount', name: 'StoreApiService');

    if (purchaseAmount <= 0) {
      throw ApiException(
        statusCode: 400,
        message: 'Enter a valid purchase amount',
      );
    }

    final qrData = {'user_id': userId};
    dev.log('   qr_data (sent to backend): $qrData', name: 'StoreApiService');

    final data = await _request(
      method: 'POST',
      endpoint: '/store/instant-qr-transfer',
      body: {'qr_data': qrData, 'purchase_amount': purchaseAmount},
      requiresAuth: true,
    );

    dev.log('📦 [scanQr] raw response: $data', name: 'StoreApiService');

    final result = _buildScanResultFromInstantTransfer(
      data,
      userId,
      purchaseAmount,
    );

    dev.log('✅ [scanQr] Transfer complete', name: 'StoreApiService');
    dev.log(
      '   customer      : ${result.customer.name ?? "ID #$userId"}',
      name: 'StoreApiService',
    );
    dev.log(
      '   rewardPoints  : ${result.transaction.rewardPoints}',
      name: 'StoreApiService',
    );
    dev.log(
      '   newBalance    : ${result.customer.walletBalance}',
      name: 'StoreApiService',
    );
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    return result;
  }

  // ════════════════════════════════════════════════════════════
  // MANUAL PHONE REWARD TRANSFER
  // ════════════════════════════════════════════════════════════

  static Future<ManualTransferResultModel> manualPhoneTransfer({
    required String phone,
    required double purchaseAmount,
  }) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log(
      '📱 [manualPhoneTransfer] ── Approach 3 ──',
      name: 'StoreApiService',
    );
    dev.log('   phone         : $phone', name: 'StoreApiService');
    dev.log('   purchaseAmount: ₹$purchaseAmount', name: 'StoreApiService');

    if (phone.isEmpty || phone.length != 10) {
      throw ApiException(
        statusCode: 400,
        message: 'Invalid phone number. Must be 10 digits.',
      );
    }

    if (purchaseAmount <= 0) {
      throw ApiException(
        statusCode: 400,
        message: 'Enter a valid purchase amount',
      );
    }

    final data = await _request(
      method: 'POST',
      endpoint: '/store/manual-phone-transfer',
      body: {'phone': phone, 'purchase_amount': purchaseAmount},
      requiresAuth: true,
    );

    dev.log(
      '📦 [manualPhoneTransfer] raw response: $data',
      name: 'StoreApiService',
    );

    final result = ManualTransferResultModel.fromJson(
      data as Map<String, dynamic>,
    );

    dev.log(
      '✅ [manualPhoneTransfer] Transfer complete',
      name: 'StoreApiService',
    );
    dev.log('   phone         : ${result.phone}', name: 'StoreApiService');
    dev.log(
      '   rewardPoints  : ${result.rewardPoints}',
      name: 'StoreApiService',
    );
    dev.log(
      '   walletBalance : ${result.walletBalance}',
      name: 'StoreApiService',
    );
    dev.log(
      '   isTemporary   : ${result.isTemporaryUser}',
      name: 'StoreApiService',
    );
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    return result;
  }

  // ════════════════════════════════════════════════════════════
  // LOOKUP USER BY PHONE
  // ════════════════════════════════════════════════════════════

  static Future<int?> getUserIdByPhone(String phone) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log(
      '🔍 [getUserIdByPhone] Looking up userId for phone: $phone',
      name: 'StoreApiService',
    );

    if (phone.isEmpty || phone.length != 10) {
      throw ApiException(
        statusCode: 400,
        message: 'Invalid phone number. Must be 10 digits.',
      );
    }

    try {
      final data = await _request(
        method: 'GET',
        endpoint: '/store/user-by-phone?phone=$phone',
        requiresAuth: true,
      );

      dev.log(
        '📦 [getUserIdByPhone] raw response: $data',
        name: 'StoreApiService',
      );

      final userJson =
          data['user'] as Map<String, dynamic>? ??
          data as Map<String, dynamic>?;
      final userId = userJson?['id'];
      final parsedId = userId is int
          ? userId
          : int.tryParse(userId?.toString() ?? '');

      dev.log(
        '✅ [getUserIdByPhone] phone: $phone → userId: $parsedId',
        name: 'StoreApiService',
      );
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
      return parsedId;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        dev.log(
          '⚠️ [getUserIdByPhone] 404 — no user found for phone: $phone',
          name: 'StoreApiService',
        );
        dev.log(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
          name: 'StoreApiService',
        );
        return null;
      }
      dev.log(
        '🔴 [getUserIdByPhone] ApiException [${e.statusCode}]: ${e.message}',
        name: 'StoreApiService',
      );
      dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SUBSCRIPTION PLANS
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/plans
  static Future<List<SubscriptionPlanModel>> getPlans() async {
    dev.log('📦 [getPlans] Fetching plans...', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/store/plans',
      requiresAuth: true,
    );
    dev.log('📦 [getPlans] raw response: $data', name: 'StoreApiService');
    final plans = (data as List)
        .map((p) => SubscriptionPlanModel.fromJson(p as Map<String, dynamic>))
        .toList();
    dev.log('✅ [getPlans] count: ${plans.length}', name: 'StoreApiService');
    return plans;
  }

  // ════════════════════════════════════════════════════════════
  // SUBSCRIPTION ADDONS
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/addons
  static Future<List<SubscriptionAddonModel>> getAddons() async {
    dev.log('🧩 [getAddons] Fetching addons...', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/store/addons',
      requiresAuth: true,
    );
    dev.log('📦 [getAddons] raw response: $data', name: 'StoreApiService');
    final addons = (data as List)
        .map((a) => SubscriptionAddonModel.fromJson(a as Map<String, dynamic>))
        .toList();
    dev.log('✅ [getAddons] count: ${addons.length}', name: 'StoreApiService');
    return addons;
  }

  // ════════════════════════════════════════════════════════════
  // MY ACTIVE ADDONS
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/my-transactions/addons
  static Future<List<StoreActiveAddonModel>> getMyAddons() async {
    dev.log(
      '🧩 [getMyAddons] Fetching active addons...',
      name: 'StoreApiService',
    );
    final data = await _request(
      method: 'GET',
      endpoint: '/store/my-transactions/addons',
      requiresAuth: true,
    );
    dev.log('📦 [getMyAddons] raw response: $data', name: 'StoreApiService');

    final Map<String, dynamic> responseMap = data as Map<String, dynamic>;
    final List<dynamic> transactionsList =
        responseMap['transactions'] as List? ?? [];

    final addons = transactionsList
        .map((a) => StoreActiveAddonModel.fromJson(a as Map<String, dynamic>))
        .toList();

    dev.log(
      '✅ [getMyAddons] total: ${addons.length} | '
      'active: ${addons.where((a) => a.isActive).length}',
      name: 'StoreApiService',
    );
    return addons;
  }

  // ════════════════════════════════════════════════════════════
  // PAYMENT — CREATE ORDER (subscription)
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/create-order
  static Future<RazorpayOrderModel> createOrder(int planId) async {
    dev.log('💳 [createOrder] planId: $planId', name: 'StoreApiService');
    final data = await _request(
      method: 'POST',
      endpoint: '/store/create-order',
      body: {'plan_id': planId},
      requiresAuth: true,
    );
    dev.log('📦 [createOrder] raw response: $data', name: 'StoreApiService');
    final order = RazorpayOrderModel.fromJson(data);
    dev.log(
      '✅ [createOrder] orderId: ${order.orderId} | amount: ₹${order.amountRupees}',
      name: 'StoreApiService',
    );
    return order;
  }

  // ════════════════════════════════════════════════════════════
  // PAYMENT — VERIFY PAYMENT (subscription)
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/verify-payment
  static Future<({String message, DateTime expiry})> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int planId,
  }) async {
    dev.log(
      '✅ [verifyPayment] orderId: $razorpayOrderId | planId: $planId',
      name: 'StoreApiService',
    );
    final data = await _request(
      method: 'POST',
      endpoint: '/store/verify-payment',
      body: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'plan_id': planId,
      },
      requiresAuth: true,
    );
    dev.log('📦 [verifyPayment] raw response: $data', name: 'StoreApiService');
    final expiry =
        DateTime.tryParse(data['expiry'].toString()) ?? DateTime.now();
    dev.log(
      '✅ [verifyPayment] Subscription active until: $expiry',
      name: 'StoreApiService',
    );
    return (message: data['message'] as String, expiry: expiry);
  }

  // ════════════════════════════════════════════════════════════
  // WALLET
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/wallet/add
  static Future<double> addMoneyToWallet(double amount) async {
    dev.log('💰 [addMoneyToWallet] amount: ₹$amount', name: 'StoreApiService');
    if (amount <= 0) {
      throw ApiException(statusCode: 400, message: 'Enter a valid amount');
    }
    final data = await _request(
      method: 'POST',
      endpoint: '/store/wallet/add',
      body: {'amount': amount},
      requiresAuth: true,
    );
    dev.log(
      '📦 [addMoneyToWallet] raw response: $data',
      name: 'StoreApiService',
    );
    final balance = double.tryParse(data['balance'].toString()) ?? 0.0;
    dev.log(
      '✅ [addMoneyToWallet] New balance: ₹$balance',
      name: 'StoreApiService',
    );
    return balance;
  }

  // ════════════════════════════════════════════════════════════
  // TRANSACTION HISTORY
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/my-transactions/rewards?filter=today|week|month
  static Future<TransactionHistoryResponse> getTransactions({
    String filter = 'today',
  }) async {
    dev.log('📋 [getTransactions] filter: $filter', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/store/my-transactions/rewards?filter=$filter',
      requiresAuth: true,
    );
    dev.log(
      '📦 [getTransactions] raw keys: ${(data as Map).keys}',
      name: 'StoreApiService',
    );
    final response = TransactionHistoryResponse.fromJson(
      data as Map<String, dynamic>,
    );
    dev.log(
      '✅ [getTransactions] count: ${response.transactions.length} | '
      'totalAmount: ₹${response.totalAmount} | '
      'totalPoints: ${response.totalPoints}',
      name: 'StoreApiService',
    );
    return response;
  }

  // ════════════════════════════════════════════════════════════
  // OFFERS (Flares)
  // ════════════════════════════════════════════════════════════

  // ────────────────────────────────────────────────────────────
  // STEP 1 — CREATE OFFER PURCHASE ORDER
  // POST /api/store/offer   (multipart)
  // Returns: { order, addon, total_price, offer_data }
  // ────────────────────────────────────────────────────────────

  static Future<RazorpayOfferOrderModel> purchaseOffer({
    required String title,
    required String description,
    required int days,
    File? bannerImage,
  }) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log(
      '🎯 [purchaseOffer] title: $title | days: $days',
      name: 'StoreApiService',
    );

    final fields = <String, String>{
      'title': title,
      'description': description,
      'days': days.toString(),
    };

    final data = await _multipartRequest(
      method: 'POST',
      endpoint: '/store/offer',
      fields: fields,
      imageFile: bannerImage,
    );

    dev.log('📦 [purchaseOffer] raw response: $data', name: 'StoreApiService');

    final result = RazorpayOfferOrderModel.fromJson(
      data as Map<String, dynamic>,
    );

    dev.log(
      '✅ [purchaseOffer] orderId: ${result.orderId} | totalPrice: ₹${result.totalPrice}',
      name: 'StoreApiService',
    );
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    return result;
  }

  // ────────────────────────────────────────────────────────────
  // STEP 2 — VERIFY OFFER PURCHASE
  // POST /api/store/offer/verify-payment
  // ────────────────────────────────────────────────────────────

  static Future<OfferModel> verifyOfferPurchase({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String title,
    required String description,
    required int days,
    String? banner,
  }) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log(
      '✅ [verifyOfferPurchase] orderId: $razorpayOrderId | days: $days | banner: $banner',
      name: 'StoreApiService',
    );

    final body = <String, dynamic>{
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'title': title,
      'description': description,
      'days': days,
      if (banner != null) 'banner': banner,
    };

    final data = await _request(
      method: 'POST',
      endpoint: '/store/offer/verify-payment',
      body: body,
      requiresAuth: true,
    );

    dev.log(
      '📦 [verifyOfferPurchase] raw response: $data',
      name: 'StoreApiService',
    );

    final offer = OfferModel.fromJson(data['offer'] as Map<String, dynamic>);

    dev.log(
      '✅ [verifyOfferPurchase] offerId: ${offer.id} | title: ${offer.title}',
      name: 'StoreApiService',
    );
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    return offer;
  }

  // ════════════════════════════════════════════════════════════
  // POPUPS
  // ════════════════════════════════════════════════════════════

  // ────────────────────────────────────────────────────────────
  // STEP 1 — CREATE POPUP PURCHASE ORDER
  // POST /api/store/pop-up   (multipart)
  //
  // Backend ഇതു return ചെയ്യും:
  // { order, addon, total_price, popup_data: { title, banner } }
  //
  // NOTE: Popup is fixed 1-day, no `days` field needed.
  //       Backend checks city exclusivity before creating order.
  // ────────────────────────────────────────────────────────────

  static Future<RazorpayPopupOrderModel> purchasePopup({
    required String title,
    String? description,
    int days = 1,
    File? bannerImage,
  }) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log('🎯 [purchasePopup] title: $title', name: 'StoreApiService');

    final fields = <String, String>{
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'days': days.toString(),
    };

    final data = await _multipartRequest(
      method: 'POST',
      endpoint: '/store/pop-up',
      fields: fields,
      imageFile: bannerImage,
    );

    dev.log('📦 [purchasePopup] raw response: $data', name: 'StoreApiService');

    final result = RazorpayPopupOrderModel.fromJson(
      data as Map<String, dynamic>,
    );

    dev.log(
      '✅ [purchasePopup] orderId: ${result.orderId} | totalPrice: ₹${result.totalPrice}',
      name: 'StoreApiService',
    );
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    return result;
  }

  // ────────────────────────────────────────────────────────────
  // STEP 2 — VERIFY POPUP PURCHASE
  // POST /api/store/pop-up/verify-payment   (JSON)
  //
  // Body: razorpay_order_id, razorpay_payment_id, razorpay_signature,
  //       title, banner (filename from step 1)
  // Returns: { message, popup }
  //
  // NOTE: Backend re-checks city exclusivity here too (race-condition safe).
  // ────────────────────────────────────────────────────────────

  static Future<PopupModel> verifyPopupPurchase({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String title,
    String? description,
    int days = 1,
    String? banner,
  }) async {
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');
    dev.log(
      '✅ [verifyPopupPurchase] orderId: $razorpayOrderId | banner: $banner',
      name: 'StoreApiService',
    );

    final body = <String, dynamic>{
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (banner != null) 'banner': banner,
    };

    final data = await _request(
      method: 'POST',
      endpoint: '/store/pop-up/verify-payment',
      body: body,
      requiresAuth: true,
    );

    dev.log(
      '📦 [verifyPopupPurchase] raw response: $data',
      name: 'StoreApiService',
    );

    final popup = PopupModel.fromJson(data['popup'] as Map<String, dynamic>);

    dev.log(
      '✅ [verifyPopupPurchase] popupId: ${popup.id} | title: ${popup.title}',
      name: 'StoreApiService',
    );
    dev.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'StoreApiService');

    return popup;
  }

  // ────────────────────────────────────────────────────────────
  // GET OFFERS
  // ────────────────────────────────────────────────────────────

  /// GET /api/store/offer-list
  static Future<List<OfferModel>> getOffers() async {
    dev.log('📋 [getOffers] Fetching offers...', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/store/offer-list',
      requiresAuth: true,
    );
    dev.log('📦 [getOffers] raw response: $data', name: 'StoreApiService');
    final offers = (data as List)
        .map((o) => OfferModel.fromJson(o as Map<String, dynamic>))
        .toList();
    dev.log('✅ [getOffers] count: ${offers.length}', name: 'StoreApiService');
    return offers;
  }

  /// GET /api/store/offer/:id
  static Future<OfferModel> getOfferById(int id) async {
    dev.log('🔍 [getOfferById] id: $id', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/store/offer/$id',
      requiresAuth: true,
    );
    dev.log('📦 [getOfferById] raw response: $data', name: 'StoreApiService');
    final offer = OfferModel.fromJson(data);
    dev.log('✅ [getOfferById] title: ${offer.title}', name: 'StoreApiService');
    return offer;
  }

  /// PUT /api/store/offer/:id
  static Future<OfferModel> updateOffer({
    required int id,
    String? title,
    String? description,
    String? offerType,
    DateTime? expiryDate,
    bool? isActive,
    File? bannerImage,
  }) async {
    dev.log(
      '✏️ [updateOffer] id: $id | title: $title | isActive: $isActive',
      name: 'StoreApiService',
    );
    final fields = <String, String>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (offerType != null) 'offer_type': offerType,
      if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      if (isActive != null) 'is_active': isActive.toString(),
    };
    final data = await _multipartRequest(
      method: 'PUT',
      endpoint: '/store/offer/$id',
      fields: fields,
      imageFile: bannerImage,
    );
    dev.log('📦 [updateOffer] raw response: $data', name: 'StoreApiService');
    final offer = OfferModel.fromJson(data['offer']);
    dev.log('✅ [updateOffer] offerId: ${offer.id}', name: 'StoreApiService');
    return offer;
  }

  /// DELETE /api/store/offer/:id
  static Future<void> deleteOffer(int id) async {
    dev.log('🗑️ [deleteOffer] id: $id', name: 'StoreApiService');
    await _request(
      method: 'DELETE',
      endpoint: '/store/offer/$id',
      requiresAuth: true,
    );
    dev.log('✅ [deleteOffer] Deleted offer id: $id', name: 'StoreApiService');
  }

  // ════════════════════════════════════════════════════════════
  // FCM TOKEN
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/save-fcm-token
  static Future<void> saveFcmToken(String fcmToken) async {
    dev.log('🔔 [saveFcmToken] Saving FCM token...', name: 'StoreApiService');
    await _request(
      method: 'POST',
      endpoint: '/store/save-fcm-token',
      body: {'fcm_token': fcmToken},
      requiresAuth: true,
    );
    dev.log('✅ [saveFcmToken] FCM token saved', name: 'StoreApiService');
  }

  // ════════════════════════════════════════════════════════════
  // LOCATION (public — no auth)
  // ════════════════════════════════════════════════════════════

  /// GET /api/public/states
  static Future<List<String>> getStates() async {
    dev.log('🗺️ [getStates] Fetching states...', name: 'StoreApiService');
    final data = await _request(method: 'GET', endpoint: '/public/states');
    final states = List<String>.from(data as List);
    dev.log('✅ [getStates] count: ${states.length}', name: 'StoreApiService');
    return states;
  }

  /// GET /api/public/districts/:state
  static Future<List<String>> getDistricts(String state) async {
    dev.log('🗺️ [getDistricts] state: $state', name: 'StoreApiService');
    final data = await _request(
      method: 'GET',
      endpoint: '/public/districts/${Uri.encodeComponent(state)}',
    );
    final districts = List<String>.from(data as List);
    dev.log(
      '✅ [getDistricts] count: ${districts.length}',
      name: 'StoreApiService',
    );
    return districts;
  }

  /// GET /api/public/cities?state=&district=
  static Future<List<String>> getCities(String state, String district) async {
    dev.log(
      '🏙️ [getCities] state: $state | district: $district',
      name: 'StoreApiService',
    );
    final uri = Uri.parse(
      '$_baseUrl/public/cities',
    ).replace(queryParameters: {'state': state, 'district': district});
    dev.log('   URI: $uri', name: 'StoreApiService');
    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      dev.log('🔴 [getCities] Network error: $e', name: 'StoreApiService');
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }
    dev.log('   Status: ${response.statusCode}', name: 'StoreApiService');
    dev.log('   Body: ${response.body}', name: 'StoreApiService');
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch cities',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final cities = List<String>.from(decoded['cities'] ?? []);
    dev.log('✅ [getCities] count: ${cities.length}', name: 'StoreApiService');
    return cities;
  }

  // ════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════

  static ScanResultModel _buildScanResultFromInstantTransfer(
    Map<String, dynamic> data,
    int userId,
    double purchaseAmount,
  ) {
    dev.log(
      '🔧 [_buildScanResult] Building ScanResultModel from: $data',
      name: 'StoreApiService',
    );

    final customerJson = data['customer'] as Map<String, dynamic>?;
    final customerName = customerJson?['name']?.toString();
    final customerBalance = _parseDouble(
      customerJson?['wallet_balance'] ?? data['wallet_balance'] ?? 0,
    );

    final rewardPoints = _parseDouble(
      data['reward_points'] ?? data['transaction']?['reward_points'] ?? 0,
    );
    final rewardPercentage = _parseDouble(
      data['reward_percentage'] ??
          data['transaction']?['reward_percentage'] ??
          0,
    );

    final storeJson = data['store'] as Map<String, dynamic>?;

    dev.log(
      '   customerName    : ${customerName ?? "not in response"}',
      name: 'StoreApiService',
    );
    dev.log('   customerBalance : $customerBalance', name: 'StoreApiService');
    dev.log('   rewardPoints    : $rewardPoints', name: 'StoreApiService');
    dev.log('   rewardPercentage: $rewardPercentage', name: 'StoreApiService');

    return ScanResultModel(
      customer: ScanCustomerModel(
        id: customerJson != null
            ? (customerJson['id'] as int? ?? userId)
            : userId,
        name: customerName,
        walletBalance: customerBalance,
      ),
      store: ScanStoreModel(
        id: storeJson != null ? (storeJson['id'] as int? ?? 0) : 0,
        storeName: storeJson?['store_name']?.toString() ?? '',
        walletBalance: _parseDouble(storeJson?['wallet_balance'] ?? 0),
      ),
      transaction: ScanTransactionModel(
        purchaseAmount: purchaseAmount,
        rewardPercentage: rewardPercentage,
        rewardPoints: rewardPoints,
      ),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

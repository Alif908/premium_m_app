// ============================================================
// lib/services/store_api_service.dart
// Partner Store App — Full API Service
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

const String _baseUrl = 'https://coinapi.bestagencyindia.com/api';
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    dev.log('💾 [Auth] Store token saved', name: 'StoreApiService');
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    dev.log(
      '🔑 [Auth] _getToken → ${token != null ? "found" : "null"}',
      name: 'StoreApiService',
    );
    return token;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    dev.log(
      '🚪 [Auth] Store logged out — token cleared',
      name: 'StoreApiService',
    );
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    dev.log('🔑 TOKEN: $token', name: 'StoreApiService');
    return token != null && token.isNotEmpty;
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

    if (requiresAuth) {
      final token = await _getToken();
      if (token == null) {
        dev.log(
          '🔴 [Auth] No token found for $endpoint',
          name: 'StoreApiService',
        );
        throw ApiException(
          statusCode: 401,
          message: 'Session expired. Please login again.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
      dev.log(
        '🔐 [Auth] Token attached for $endpoint',
        name: 'StoreApiService',
      );
    }

    dev.log(
      '\n📤 [$method] $endpoint\n'
      '   Headers: $headers\n'
      '   Body: ${body != null ? jsonEncode(body) : "none"}',
      name: 'StoreApiService',
    );

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

    dev.log(
      '\n📥 [$method] $endpoint\n'
      '   Status: ${response.statusCode}\n'
      '   Body: ${response.body}',
      name: 'StoreApiService',
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map
          ? decoded['message'] ?? 'Something went wrong'
          : 'Something went wrong';
      dev.log(
        '🔴 [API Error] $endpoint → [${response.statusCode}] $msg',
        name: 'StoreApiService',
      );
      throw ApiException(statusCode: response.statusCode, message: msg);
    }

    return decoded;
  }

  // ── Multipart request helper (for image uploads) ───────────

  static Future<dynamic> _multipartRequest({
    required String method,
    required String endpoint,
    required Map<String, String> fields,
    File? imageFile,
    String fileField = 'banner',
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final token = await _getToken();

    if (token == null) {
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
    }

    dev.log(
      '\n📤 [MULTIPART $method] $endpoint\n'
      '   Fields: $fields\n'
      '   File: ${imageFile?.path ?? "none"}',
      name: 'StoreApiService',
    );

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

    dev.log(
      '\n📥 [MULTIPART $method] $endpoint\n'
      '   Status: ${response.statusCode}\n'
      '   Body: ${response.body}',
      name: 'StoreApiService',
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map
          ? decoded['message'] ?? 'Something went wrong'
          : 'Something went wrong';
      dev.log(
        '🔴 [API Error] $endpoint → [${response.statusCode}] $msg',
        name: 'StoreApiService',
      );
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
      '✅ [sendOtp] Success. OTP (dev): ${data['otp']}',
      name: 'StoreApiService',
    );
    return Map<String, dynamic>.from(data);
  }

  /// POST /api/store/verify-otp
  static Future<String> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    dev.log('✅ [verifyOtp] phone: $phone, otp: $otp', name: 'StoreApiService');

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

    // Backend returns { store: {...} }
    final storeJson = data['store'] ?? data;
    final store = StoreModel.fromJson(storeJson as Map<String, dynamic>);

    dev.log(
      '✅ [getProfile] store: ${store.storeName} | '
      'subscriptionStatus: ${store.subscriptionStatus} | '
      'walletBalance: ${store.walletBalance}',
      name: 'StoreApiService',
    );
    return store;
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

    dev.log(
      '✅ [getPlans] count: ${plans.length} | '
      'names: ${plans.map((p) => p.name).toList()}',
      name: 'StoreApiService',
    );
    return plans;
  }

  // ════════════════════════════════════════════════════════════
  // SUBSCRIPTION ADDONS — list available addons
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

    dev.log(
      '✅ [getAddons] count: ${addons.length} | '
      'names: ${addons.map((a) => a.name).toList()}',
      name: 'StoreApiService',
    );
    return addons;
  }

  // ════════════════════════════════════════════════════════════
  // ADDON PURCHASE
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/purchase-addon
  /// Body: { addon_id: int }
  /// Response: { message: "Addon activated", expiry: "2025-..." }
  static Future<({String message, DateTime expiry})> purchaseAddon(
    int addonId,
  ) async {
    dev.log(
      '🧩 [purchaseAddon] addonId: $addonId — calling API...',
      name: 'StoreApiService',
    );

    final data = await _request(
      method: 'POST',
      endpoint: '/store/purchase-addon',
      body: {'addon_id': addonId},
      requiresAuth: true,
    );

    dev.log('📦 [purchaseAddon] raw response: $data', name: 'StoreApiService');

    final expiryRaw = data['expiry']?.toString();
    dev.log(
      '📅 [purchaseAddon] expiry raw: $expiryRaw',
      name: 'StoreApiService',
    );

    final expiry = DateTime.tryParse(expiryRaw ?? '') ?? DateTime.now();
    final message = data['message']?.toString() ?? 'Addon activated';

    dev.log(
      '✅ [purchaseAddon] addonId: $addonId activated | '
      'message: $message | expiry: $expiry',
      name: 'StoreApiService',
    );

    return (message: message, expiry: expiry);
  }

  // ════════════════════════════════════════════════════════════
  // MY ACTIVE ADDONS — check what addons store currently has
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/my-addons
  /// Response: [ { id, store_id, addon_id, start_date, expiry_date, status, SubscriptionAddon: {...} } ]
  static Future<List<StoreActiveAddonModel>> getMyAddons() async {
    dev.log(
      '🧩 [getMyAddons] Fetching store active addons...',
      name: 'StoreApiService',
    );

    final data = await _request(
      method: 'GET',
      endpoint: '/store/my-addons',
      requiresAuth: true,
    );

    dev.log('📦 [getMyAddons] raw response: $data', name: 'StoreApiService');

    final addons = (data as List)
        .map((a) => StoreActiveAddonModel.fromJson(a as Map<String, dynamic>))
        .toList();

    dev.log(
      '✅ [getMyAddons] total: ${addons.length} | '
      'active: ${addons.where((a) => a.isActive).length} | '
      'addonIds: ${addons.map((a) => a.addonId).toList()}',
      name: 'StoreApiService',
    );

    return addons;
  }

  // ════════════════════════════════════════════════════════════
  // PAYMENT — CREATE ORDER
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
      '✅ [createOrder] orderId: ${order.orderId} | '
      'amount: ₹${order.amountRupees}',
      name: 'StoreApiService',
    );
    return order;
  }

  // ════════════════════════════════════════════════════════════
  // PAYMENT — VERIFY PAYMENT
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/verify-payment
  static Future<({String message, DateTime expiry})> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int planId,
  }) async {
    dev.log(
      '✅ [verifyPayment] orderId: $razorpayOrderId | '
      'paymentId: $razorpayPaymentId | planId: $planId',
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
    dev.log('💰 [addMoney] amount: ₹$amount', name: 'StoreApiService');

    if (amount <= 0) {
      dev.log('🔴 [addMoney] Invalid amount: $amount', name: 'StoreApiService');
      throw ApiException(statusCode: 400, message: 'Enter a valid amount');
    }

    final data = await _request(
      method: 'POST',
      endpoint: '/store/wallet/add',
      body: {'amount': amount},
      requiresAuth: true,
    );

    dev.log('📦 [addMoney] raw response: $data', name: 'StoreApiService');

    final balance = double.tryParse(data['balance'].toString()) ?? 0.0;
    dev.log('✅ [addMoney] New balance: ₹$balance', name: 'StoreApiService');
    return balance;
  }

  // ════════════════════════════════════════════════════════════
  // SCAN QR
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/scan
  static Future<ScanResultModel> scanQr({
    required int userId,
    required double purchaseAmount,
  }) async {
    dev.log(
      '📷 [scanQr] userId: $userId | purchaseAmount: ₹$purchaseAmount',
      name: 'StoreApiService',
    );

    if (purchaseAmount <= 0) {
      dev.log(
        '🔴 [scanQr] Invalid purchase amount: $purchaseAmount',
        name: 'StoreApiService',
      );
      throw ApiException(
        statusCode: 400,
        message: 'Enter a valid purchase amount',
      );
    }

    final data = await _request(
      method: 'POST',
      endpoint: '/store/scan',
      body: {'user_id': userId, 'purchase_amount': purchaseAmount},
      requiresAuth: true,
    );

    dev.log('📦 [scanQr] raw response: $data', name: 'StoreApiService');

    final result = ScanResultModel.fromJson(data);
    dev.log(
      '✅ [scanQr] customer: ${result.customer.name} | '
      'rewardPoints: ${result.transaction.rewardPoints} | '
      'newBalance: ${result.customer.walletBalance}',
      name: 'StoreApiService',
    );
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // TRANSACTION HISTORY
  // ════════════════════════════════════════════════════════════

  /// GET /api/store/transactions?filter=today|week|month
  static Future<TransactionHistoryResponse> getTransactions({
    String filter = 'today',
  }) async {
    dev.log('📋 [getTransactions] filter: $filter', name: 'StoreApiService');

    final data = await _request(
      method: 'GET',
      endpoint: '/store/transactions?filter=$filter',
      requiresAuth: true,
    );

    dev.log(
      '📦 [getTransactions] raw response keys: ${(data as Map).keys}',
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
  // OFFERS (Flares) — CRUD
  // ════════════════════════════════════════════════════════════

  /// POST /api/store/offer   (with optional banner image)
  static Future<OfferModel> createOffer({
    required String title,
    String? description,
    required String offerType,
    DateTime? expiryDate,
    File? bannerImage,
  }) async {
    dev.log(
      '🎯 [createOffer] title: $title | offerType: $offerType | '
      'expiryDate: $expiryDate | hasBanner: ${bannerImage != null}',
      name: 'StoreApiService',
    );

    final fields = <String, String>{
      'title': title,
      'offer_type': offerType,
      if (description != null) 'description': description,
      if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
    };

    final data = await _multipartRequest(
      method: 'POST',
      endpoint: '/store/offer',
      fields: fields,
      imageFile: bannerImage,
      fileField: 'banner',
    );

    dev.log('📦 [createOffer] raw response: $data', name: 'StoreApiService');

    final offer = OfferModel.fromJson(data['offer']);
    dev.log(
      '✅ [createOffer] offerId: ${offer.id} | title: ${offer.title}',
      name: 'StoreApiService',
    );
    return offer;
  }

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
    dev.log('✅ [getOfferById] offer: ${offer.title}', name: 'StoreApiService');
    return offer;
  }

  /// PUT /api/store/offer/:id   (with optional new banner image)
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
      fileField: 'banner',
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
    dev.log('🔔 [saveFcmToken] token: $fcmToken', name: 'StoreApiService');

    await _request(
      method: 'POST',
      endpoint: '/store/save-fcm-token',
      body: {'fcm_token': fcmToken},
      requiresAuth: true,
    );

    dev.log('✅ [saveFcmToken] FCM token saved', name: 'StoreApiService');
  }

  // ════════════════════════════════════════════════════════════
  // LOCATION (public — no auth needed)
  // ════════════════════════════════════════════════════════════

  /// GET /api/public/states
  static Future<List<String>> getStates() async {
    dev.log('🗺️ [getStates] Fetching states...', name: 'StoreApiService');

    final data = await _request(method: 'GET', endpoint: '/public/states');

    dev.log('📦 [getStates] raw: $data', name: 'StoreApiService');

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

    dev.log('📦 [getDistricts] raw: $data', name: 'StoreApiService');

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

    dev.log('📤 [GET] /public/cities → $uri', name: 'StoreApiService');

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      dev.log(
        '🔴 [Network Error] /public/cities → $e',
        name: 'StoreApiService',
      );
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }

    dev.log(
      '📥 [GET] /public/cities\n'
      '   Status: ${response.statusCode}\n'
      '   Body: ${response.body}',
      name: 'StoreApiService',
    );

    if (response.statusCode != 200) {
      dev.log(
        '🔴 [getCities] Failed: ${response.statusCode}',
        name: 'StoreApiService',
      );
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
}

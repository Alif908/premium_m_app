// ============================================================
// lib/models/store_model.dart
// Partner Store App — All Models
// Matches exact backend response shapes from partnerstorecontroller.js
// ============================================================

// ─────────────────────────────────────────────────────────────
// STORE MODEL
// Source: GET /api/store/profile → { store: {...} }
// ─────────────────────────────────────────────────────────────

class StoreModel {
  final int id;
  final String storeName;
  final String ownerName;
  final String phone;
  final String? email;
  final int? categoryId;
  final String? address;
  final String state;
  final String district;
  final String city;
  final String? shopImage;
  final String? idProof;
  final String status;
  final String subscriptionStatus; // "inactive" | "active" | "expired"
  final int? subscriptionPlanId;
  final DateTime? subscriptionExpiry;
  final double walletBalance;
  final int? createdBy;
  final DateTime? createdAt;

  const StoreModel({
    required this.id,
    required this.storeName,
    required this.ownerName,
    required this.phone,
    this.email,
    this.categoryId,
    this.address,
    required this.state,
    required this.district,
    required this.city,
    this.shopImage,
    this.idProof,
    required this.status,
    required this.subscriptionStatus,
    this.subscriptionPlanId,
    this.subscriptionExpiry,
    required this.walletBalance,
    this.createdBy,
    this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    _log('StoreModel.fromJson → raw: $json');
    return StoreModel(
      id: json['id'] ?? 0,
      storeName: json['store_name']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      categoryId: _parseInt(json['category_id']),
      address: json['address']?.toString(),
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      shopImage: json['shop_image']?.toString(),
      idProof: json['id_proof']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      subscriptionStatus: json['subscription_status']?.toString() ?? 'inactive',
      subscriptionPlanId: _parseInt(json['subscription_plan_id']),
      subscriptionExpiry: _parseDate(json['subscription_expiry']),
      walletBalance: _parseDouble(json['wallet_balance']),
      createdBy: _parseInt(json['created_by']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isApproved => status == 'approved';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get isSubscriptionExpired => subscriptionStatus == 'expired';

  bool get isExpiringSoon {
    if (subscriptionExpiry == null || !isSubscriptionActive) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      subscriptionExpiry!.year,
      subscriptionExpiry!.month,
      subscriptionExpiry!.day,
    );
    return expiry.difference(today).inDays <= 7 && expiry.isAfter(today);
  }

  int get daysLeft {
    if (subscriptionExpiry == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      subscriptionExpiry!.year,
      subscriptionExpiry!.month,
      subscriptionExpiry!.day,
    );
    final diff = expiry.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get formattedBalance => '₹${walletBalance.toStringAsFixed(2)}';
}

// ─────────────────────────────────────────────────────────────
// SUBSCRIPTION PLAN MODEL
// Source: GET /api/store/plans → [...]
// ─────────────────────────────────────────────────────────────

class SubscriptionPlanModel {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final int transactionsLimit;
  final int flaresLimit;
  final int productLimit;
  final bool isUnlimitedTransactions;
  final bool isUnlimitedProducts;
  final double redeemPercentage;
  final String? features;
  final bool allowPopup;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.transactionsLimit,
    required this.flaresLimit,
    required this.productLimit,
    required this.isUnlimitedTransactions,
    required this.isUnlimitedProducts,
    required this.redeemPercentage,
    this.features,
    required this.allowPopup,
    required this.isActive,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    _log('SubscriptionPlanModel.fromJson → raw: $json');
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      durationDays: json['duration_days'] ?? 0,
      transactionsLimit: json['transactions_limit'] ?? 0,
      flaresLimit: json['flares_limit'] ?? 0,
      productLimit: json['product_limit'] ?? 0,
      isUnlimitedTransactions: json['is_unlimited_transactions'] == true,
      isUnlimitedProducts: json['is_unlimited_products'] == true,
      redeemPercentage: _parseDouble(json['redeem_percentage']),
      features: json['features']?.toString(),
      allowPopup: json['allow_popup'] == true,
      isActive: json['is_active'] != false,
    );
  }

  List<String> get featureList {
    if (features == null || features!.trim().isEmpty) return [];
    try {
      final cleaned = features!
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '');
      return cleaned
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [features!];
    }
  }

  String get formattedPrice => '₹${price.toInt()}';

  String get formattedDuration {
    if (durationDays >= 365) return '${(durationDays / 365).round()} Year';
    if (durationDays >= 30) return '${(durationDays / 30).round()} Month(s)';
    return '$durationDays Days';
  }
}

// ─────────────────────────────────────────────────────────────
// SUBSCRIPTION ADDON MODEL
// Source: GET /api/store/addons → [...]
// ─────────────────────────────────────────────────────────────

class SubscriptionAddonModel {
  final int id;
  final String name;
  final double price;
  final String type; // "per_day" | "per_month" | "per_unit"
  final String? description;
  final bool isActive;

  const SubscriptionAddonModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    this.description,
    required this.isActive,
  });

  factory SubscriptionAddonModel.fromJson(Map<String, dynamic> json) {
    _log('SubscriptionAddonModel.fromJson → raw: $json');
    return SubscriptionAddonModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      type: json['type']?.toString() ?? 'per_unit',
      description: json['description']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  String get formattedPrice => '₹${price.toInt()}';
}

// ─────────────────────────────────────────────────────────────
// STORE ACTIVE ADDON MODEL
// Source: GET /api/store/my-transactions/addons → { transactions: [...] }
// ─────────────────────────────────────────────────────────────

class StoreActiveAddonModel {
  final int id;
  final int storeId;
  final int addonId;
  final DateTime startDate;
  final DateTime expiryDate;
  final String status; // "active" | "expired"
  final SubscriptionAddonModel? addon;

  const StoreActiveAddonModel({
    required this.id,
    required this.storeId,
    required this.addonId,
    required this.startDate,
    required this.expiryDate,
    required this.status,
    this.addon,
  });

  factory StoreActiveAddonModel.fromJson(Map<String, dynamic> json) {
    _log('StoreActiveAddonModel.fromJson → raw: $json');
    final addonJson =
        json['SubscriptionAddon'] as Map<String, dynamic>? ??
        json['addon'] as Map<String, dynamic>?;
    _log('StoreActiveAddonModel → addonJson: $addonJson');
    return StoreActiveAddonModel(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      addonId: json['addon_id'] ?? 0,
      startDate: _parseDate(json['start_date']) ?? DateTime.now(),
      expiryDate: _parseDate(json['expiry_date']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      addon: addonJson != null
          ? SubscriptionAddonModel.fromJson(addonJson)
          : null,
    );
  }

  bool get isActive {
    if (status != 'active') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.isAfter(today) || expiry.isAtSameMomentAs(today);
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final diff = expiry.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get formattedExpiry {
    const months = [
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
    ];
    return '${months[expiryDate.month]} ${expiryDate.day}, ${expiryDate.year}';
  }
}

// ─────────────────────────────────────────────────────────────
// RAZORPAY ORDER MODEL (subscription)
// Source: POST /api/store/create-order → { order: {...}, plan: {...} }
// ─────────────────────────────────────────────────────────────

class RazorpayOrderModel {
  final String orderId;
  final int amountPaise;
  final String currency;
  final String receipt;
  final SubscriptionPlanModel plan;

  const RazorpayOrderModel({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.receipt,
    required this.plan,
  });

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) {
    _log('RazorpayOrderModel.fromJson → raw: $json');
    final order = json['order'] as Map<String, dynamic>;
    return RazorpayOrderModel(
      orderId: order['id']?.toString() ?? '',
      amountPaise: order['amount'] ?? 0,
      currency: order['currency']?.toString() ?? 'INR',
      receipt: order['receipt']?.toString() ?? '',
      plan: SubscriptionPlanModel.fromJson(
        json['plan'] as Map<String, dynamic>,
      ),
    );
  }

  double get amountRupees => amountPaise / 100;
  String get formattedAmount => '₹${amountRupees.toStringAsFixed(2)}';
}

// ─────────────────────────────────────────────────────────────
// RAZORPAY OFFER ORDER MODEL
// Source: POST /api/store/offer (multipart)
// → { order, addon, total_price, offer_data: { title, description, days, banner } }
// ─────────────────────────────────────────────────────────────

class RazorpayOfferOrderModel {
  final String orderId;
  final int amountPaise;
  final String currency;
  final String receipt;
  final double totalPrice;
  final double addonPricePerDay;
  final String offerTitle;
  final String offerDescription;
  final int days;
  final String? banner;

  const RazorpayOfferOrderModel({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.receipt,
    required this.totalPrice,
    required this.addonPricePerDay,
    required this.offerTitle,
    required this.offerDescription,
    required this.days,
    this.banner,
  });

  factory RazorpayOfferOrderModel.fromJson(Map<String, dynamic> json) {
    _log('RazorpayOfferOrderModel.fromJson → raw: $json');

    final order = json['order'] as Map<String, dynamic>;
    final offerData = json['offer_data'] as Map<String, dynamic>? ?? {};
    final addon = json['addon'] as Map<String, dynamic>? ?? {};

    return RazorpayOfferOrderModel(
      orderId: order['id']?.toString() ?? '',
      amountPaise: order['amount'] ?? 0,
      currency: order['currency']?.toString() ?? 'INR',
      receipt: order['receipt']?.toString() ?? '',
      totalPrice: _parseDouble(json['total_price']),
      addonPricePerDay: _parseDouble(addon['price']),
      offerTitle: offerData['title']?.toString() ?? '',
      offerDescription: offerData['description']?.toString() ?? '',
      days: _parseInt(offerData['days']) ?? 0,
      banner: offerData['banner']?.toString(),
    );
  }

  double get amountRupees => amountPaise / 100;
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(0)}';
  String get formattedPerDay => '₹${addonPricePerDay.toStringAsFixed(0)}/day';
}

// ─────────────────────────────────────────────────────────────
// RAZORPAY POPUP ORDER MODEL
// Source: POST /api/store/pop-up (multipart)
// → { order, addon, total_price, popup_data: { title, banner } }
//
// NOTE: Popup is always 1 day. Backend may return popup_data or offer_data
//       key — both are handled in fromJson.
// ─────────────────────────────────────────────────────────────

class RazorpayPopupOrderModel {
  final String orderId;
  final int amountPaise;
  final String currency;
  final String receipt;
  final double totalPrice;
  final double addonPricePerDay;
  final String popupTitle;
  final String popupDescription;
  final int days;
  final String? banner;

  const RazorpayPopupOrderModel({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.receipt,
    required this.totalPrice,
    required this.addonPricePerDay,
    required this.popupTitle,
    required this.popupDescription,
    required this.days,
    this.banner,
  });

  factory RazorpayPopupOrderModel.fromJson(Map<String, dynamic> json) {
    _log('RazorpayPopupOrderModel.fromJson → raw: $json');

    final order = json['order'] as Map<String, dynamic>;

    // Backend returns popup_data; fallback to offer_data just in case
    final popupData =
        (json['popup_data'] ?? json['offer_data']) as Map<String, dynamic>? ??
        {};

    final addon = json['addon'] as Map<String, dynamic>? ?? {};

    return RazorpayPopupOrderModel(
      orderId: order['id']?.toString() ?? '',
      amountPaise: order['amount'] ?? 0,
      currency: order['currency']?.toString() ?? 'INR',
      receipt: order['receipt']?.toString() ?? '',
      totalPrice: _parseDouble(json['total_price']),
      addonPricePerDay: _parseDouble(addon['price']),
      popupTitle: popupData['title']?.toString() ?? '',
      popupDescription: popupData['description']?.toString() ?? '',
      days: _parseInt(popupData['days']) ?? 1,
      banner: popupData['banner']?.toString(),
    );
  }

  double get amountRupees => amountPaise / 100;
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(0)}';
  String get formattedPerDay => '₹${addonPricePerDay.toStringAsFixed(0)}/day';
}

// ─────────────────────────────────────────────────────────────
// OFFER MODEL (Flares)
// Source: GET /api/store/offer-list → [...]
//         POST /api/store/offer/verify-payment → { offer: {...} }
// ─────────────────────────────────────────────────────────────

class OfferModel {
  final int id;
  final int storeId;
  final String title;
  final String? description;
  final String? banner;
  final String offerType; // "normal" | "popup"
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime? createdAt;

  const OfferModel({
    required this.id,
    required this.storeId,
    required this.title,
    this.description,
    this.banner,
    required this.offerType,
    this.expiryDate,
    required this.isActive,
    this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    _log('OfferModel.fromJson → raw: $json');
    return OfferModel(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      banner: json['banner']?.toString(),
      offerType: json['offer_type']?.toString() ?? 'normal',
      expiryDate: _parseDate(json['expiry_date']),
      isActive: json['is_active'] != false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isPopup => offerType == 'popup';
  bool get isNormal => offerType == 'normal';

  bool get isExpired {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
    return expiry.isBefore(today);
  }

  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
    return expiry.difference(today).inDays;
  }
}

// ─────────────────────────────────────────────────────────────
// POPUP MODEL
// Source: POST /api/store/pop-up/verify-payment → { popup: {...} }
//         Matches Popup Sequelize model (table: popups)
// ─────────────────────────────────────────────────────────────

class PopupModel {
  final int id;
  final int storeId;
  final int addonId;
  final String city;
  final String title;
  final String? banner;
  final double addonPrice;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime? createdAt;

  const PopupModel({
    required this.id,
    required this.storeId,
    required this.addonId,
    required this.city,
    required this.title,
    this.banner,
    required this.addonPrice,
    this.startDate,
    this.expiryDate,
    required this.isActive,
    this.createdAt,
  });

  factory PopupModel.fromJson(Map<String, dynamic> json) {
    _log('PopupModel.fromJson → raw: $json');
    return PopupModel(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      addonId: json['addon_id'] ?? 0,
      city: json['city']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      banner: json['banner']?.toString(),
      addonPrice: _parseDouble(json['addon_price']),
      startDate: _parseDate(json['start_date']),
      expiryDate: _parseDate(json['expiry_date']),
      isActive: json['is_active'] != false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  int get hoursLeft {
    if (expiryDate == null) return 0;
    final diff = expiryDate!.difference(DateTime.now()).inHours;
    return diff < 0 ? 0 : diff;
  }

  String get formattedExpiry {
    if (expiryDate == null) return '';
    const months = [
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
    ];
    final h = expiryDate!.hour;
    final m = expiryDate!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${months[expiryDate!.month]} ${expiryDate!.day}, ${expiryDate!.year} · $displayH:$m $period';
  }

  String get formattedPrice => '₹${addonPrice.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────
// SCAN QR RESPONSE MODELS
// Source: POST /store/instant-qr-transfer
// ─────────────────────────────────────────────────────────────

class ScanResultModel {
  final ScanCustomerModel customer;
  final ScanStoreModel store;
  final ScanTransactionModel transaction;

  const ScanResultModel({
    required this.customer,
    required this.store,
    required this.transaction,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    _log('ScanResultModel.fromJson → raw: $json');
    return ScanResultModel(
      customer: ScanCustomerModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      store: ScanStoreModel.fromJson(json['store'] as Map<String, dynamic>),
      transaction: ScanTransactionModel.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }
}

class ScanCustomerModel {
  final int id;
  final String? name;
  final double walletBalance;

  const ScanCustomerModel({
    required this.id,
    this.name,
    required this.walletBalance,
  });

  factory ScanCustomerModel.fromJson(Map<String, dynamic> json) {
    _log('ScanCustomerModel.fromJson → raw: $json');
    return ScanCustomerModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString(),
      walletBalance: _parseDouble(json['wallet_balance']),
    );
  }

  String get displayName => name ?? 'Customer';

  String get initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}

class ScanStoreModel {
  final int id;
  final String storeName;
  final double walletBalance;

  const ScanStoreModel({
    required this.id,
    required this.storeName,
    required this.walletBalance,
  });

  factory ScanStoreModel.fromJson(Map<String, dynamic> json) {
    _log('ScanStoreModel.fromJson → raw: $json');
    return ScanStoreModel(
      id: json['id'] ?? 0,
      storeName: json['store_name']?.toString() ?? '',
      walletBalance: _parseDouble(json['wallet_balance']),
    );
  }
}

class ScanTransactionModel {
  final double purchaseAmount;
  final double rewardPercentage;
  final double rewardPoints;

  const ScanTransactionModel({
    required this.purchaseAmount,
    required this.rewardPercentage,
    required this.rewardPoints,
  });

  factory ScanTransactionModel.fromJson(Map<String, dynamic> json) {
    _log('ScanTransactionModel.fromJson → raw: $json');
    return ScanTransactionModel(
      purchaseAmount: _parseDouble(json['purchase_amount']),
      rewardPercentage: _parseDouble(json['reward_percentage']),
      rewardPoints: _parseDouble(json['reward_points']),
    );
  }

  String get formattedRewardPoints => '₹${rewardPoints.toStringAsFixed(2)}';
  String get formattedPurchaseAmount => '₹${purchaseAmount.toStringAsFixed(2)}';
}

// ─────────────────────────────────────────────────────────────
// MANUAL TRANSFER RESULT MODEL
// Source: POST /store/manual-phone-transfer
// ─────────────────────────────────────────────────────────────

class ManualTransferResultModel {
  final String message;
  final bool isTemporaryUser;
  final String phone;
  final double rewardPoints;
  final double walletBalance;

  const ManualTransferResultModel({
    required this.message,
    required this.isTemporaryUser,
    required this.phone,
    required this.rewardPoints,
    required this.walletBalance,
  });

  factory ManualTransferResultModel.fromJson(Map<String, dynamic> json) {
    _log('ManualTransferResultModel.fromJson → raw: $json');
    return ManualTransferResultModel(
      message: json['message']?.toString() ?? '',
      isTemporaryUser: json['temporary_user'] == true,
      phone: json['phone']?.toString() ?? '',
      rewardPoints: _parseDouble(json['reward_points']),
      walletBalance: _parseDouble(json['wallet_balance']),
    );
  }

  String get formattedPoints => '+${rewardPoints.toStringAsFixed(2)} pts';
  String get formattedBalance => '₹${walletBalance.toStringAsFixed(2)}';

  String get statusMessage => isTemporaryUser
      ? 'New account created for $phone. Points saved — ask them to sign up!'
      : 'Points credited to $phone successfully';
}

// ─────────────────────────────────────────────────────────────
// STORE TRANSACTION MODEL
// Source: GET /api/store/my-transactions/rewards
// ─────────────────────────────────────────────────────────────

class StoreTransactionModel {
  final int id;
  final int userId;
  final int storeId;
  final double purchaseAmount;
  final double rewardPoints;
  final double rewardPercentage;
  final String? userName;
  final DateTime? createdAt;

  const StoreTransactionModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.purchaseAmount,
    required this.rewardPoints,
    required this.rewardPercentage,
    this.userName,
    this.createdAt,
  });

  factory StoreTransactionModel.fromJson(Map<String, dynamic> json) {
    _log('StoreTransactionModel.fromJson → raw: $json');
    final userJson =
        json['user'] as Map<String, dynamic>? ??
        json['User'] as Map<String, dynamic>?;
    final name =
        userJson?['name']?.toString() ??
        userJson?['phone']?.toString() ??
        json['user_name']?.toString();
    return StoreTransactionModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      purchaseAmount: _parseDouble(json['purchase_amount']),
      rewardPoints: _parseDouble(json['reward_points']),
      rewardPercentage: _parseDouble(json['reward_percentage']),
      userName: name,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  String get displayName => userName ?? 'Customer';

  String get initials {
    if (userName == null || userName!.trim().isEmpty) return '?';
    final parts = userName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String get formattedAmount {
    final val = purchaseAmount.toInt();
    if (val >= 1000) {
      final s = val.toString();
      final result = StringBuffer('₹');
      final offset = s.length % 3;
      for (int i = 0; i < s.length; i++) {
        if (i != 0 && (i - offset) % 3 == 0) result.write(',');
        result.write(s[i]);
      }
      return result.toString();
    }
    return '₹$val';
  }

  String get formattedPoints => '+${rewardPoints.toInt()} pts';

  String get formattedTime {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(
      createdAt!.year,
      createdAt!.month,
      createdAt!.day,
    );
    final diffInDays = today.difference(createdDay).inDays;

    final h = createdAt!.hour;
    final m = createdAt!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final timeStr = '$displayH:$m $period';

    if (diffInDays == 0) return 'Today, $timeStr';
    if (diffInDays == 1) return 'Yesterday, $timeStr';
    if (diffInDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[createdAt!.weekday - 1]}, $timeStr';
    }
    final weeks = diffInDays ~/ 7;
    return '${weeks == 0 ? 1 : weeks}w ago';
  }
}

// ─────────────────────────────────────────────────────────────
// TRANSACTION HISTORY RESPONSE
// Source: GET /api/store/my-transactions/rewards
// ─────────────────────────────────────────────────────────────

class TransactionHistoryResponse {
  final List<StoreTransactionModel> transactions;
  final double totalAmount;
  final double totalPoints;
  final int count;

  const TransactionHistoryResponse({
    required this.transactions,
    required this.totalAmount,
    required this.totalPoints,
    required this.count,
  });

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    _log('TransactionHistoryResponse.fromJson → raw keys: ${json.keys}');

    final list = (json['transactions'] as List? ?? [])
        .map((t) => StoreTransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    return TransactionHistoryResponse(
      transactions: list,
      totalAmount: _parseDouble(summary['total_purchase_amount']),
      totalPoints: _parseDouble(summary['total_rewards_given']),
      count: _parseInt(summary['total_transactions']) ?? list.length,
    );
  }

  bool get isEmpty => transactions.isEmpty;
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedTotalPoints => '${totalPoints.toInt()} pts';
}

// ─────────────────────────────────────────────────────────────
// PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────

void _log(String msg) {
  // ignore: avoid_print
  print('[StoreModel] $msg');
}

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  return int.tryParse(val.toString());
}

DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  return DateTime.tryParse(val.toString());
}

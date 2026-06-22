import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:premium_m_app/firebase_options.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/views/home/home_page.dart';
import 'package:premium_m_app/views/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ─────────────────────────────────────────────
// IMAGE DOWNLOAD HELPER
// ─────────────────────────────────────────────
Future<String?> _downloadAndSaveImage(String imageUrl) async {
  try {
    debugPrint('⬇️ [FCM] Downloading image: $imageUrl');
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/store_notification_image.jpg';
    final response = await http.get(Uri.parse(imageUrl));
    debugPrint('   HTTP Status: ${response.statusCode}');
    debugPrint('   Bytes      : ${response.bodyBytes.length}');

    if (response.statusCode != 200) {
      debugPrint('❌ [FCM] Image download failed: ${response.statusCode}');
      return null;
    }

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    debugPrint('✅ [FCM] Image saved: $filePath');
    return filePath;
  } catch (e) {
    debugPrint('❌ [FCM] Image download error: $e');
    return null;
  }
}

// ─────────────────────────────────────────────
// SHOW LOCAL NOTIFICATION (with/without image)
// ─────────────────────────────────────────────
Future<void> _showLocalNotification({
  required int id,
  required String? title,
  required String? body,
  String? imageUrl,
  String? payload,
}) async {
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('🔔 [StoreNotification] _showLocalNotification()');
  debugPrint('   Title   : $title');
  debugPrint('   Body    : $body');
  debugPrint('   ImageUrl: ${imageUrl ?? "NULL — no image"}');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  StyleInformation? styleInformation;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    debugPrint('⬇️ [StoreNotification] Image found — downloading...');
    final imagePath = await _downloadAndSaveImage(imageUrl);

    if (imagePath != null) {
      debugPrint('✅ [StoreNotification] BigPicture style applied');
      styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(imagePath),
        largeIcon: FilePathAndroidBitmap(imagePath),
        hideExpandedLargeIcon: false,
        contentTitle: title,
        summaryText: body,
      );
    } else {
      debugPrint('⚠️ [StoreNotification] Image failed — BigText fallback');
    }
  } else {
    debugPrint('ℹ️ [StoreNotification] No image — BigText style');
  }

  styleInformation ??= BigTextStyleInformation(body ?? '');

  await flutterLocalNotificationsPlugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: styleInformation,
      ),
    ),
    payload: payload,
  );

  debugPrint('✅ [StoreNotification] show() called');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

// ─────────────────────────────────────────────
// BACKGROUND HANDLER
// ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('📩 [FCM] Background message');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body : ${message.notification?.body}');

  final notification = message.notification;
  if (notification == null) return;

  final imageUrl =
      notification.android?.imageUrl ?? notification.apple?.imageUrl;

  // await _showLocalNotification(
  //   id: notification.hashCode,
  //   title: notification.title,
  //   body: notification.body,
  //   imageUrl: imageUrl,
  //   payload: message.data['type'],
  // );
}

// ─────────────────────────────────────────────
// LOCAL NOTIFICATION SETUP
// ─────────────────────────────────────────────
Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('👆 [StoreNotification] Tapped: ${response.payload}');
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  debugPrint('✅ [StoreNotification] Local notifications initialized');
}

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await setupLocalNotifications();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PLATFORM ERROR: $error');
    return true;
  };

  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('🔥 FCM TOKEN: $fcmToken');

    if (fcmToken != null) {
      final loggedIn = await StoreApiService.isLoggedIn();
      if (loggedIn) {
        await StoreApiService.saveFcmToken(fcmToken);
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final loggedIn = await StoreApiService.isLoggedIn();
      if (loggedIn) {
        await StoreApiService.saveFcmToken(newToken);
      }
    });

    // ── Foreground notification with image ──────────────────
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //   debugPrint('📩 [FCM] Foreground message');
    //   debugPrint('   Title             : ${message.notification?.title}');
    //   debugPrint('   Body              : ${message.notification?.body}');
    //   debugPrint(
    //     '   android?.imageUrl : ${message.notification?.android?.imageUrl}',
    //   );
    //   debugPrint(
    //     '   apple?.imageUrl   : ${message.notification?.apple?.imageUrl}',
    //   );
    //   debugPrint('   data              : ${message.data}');
    //   debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    //   final notification = message.notification;
    //   if (notification == null) return;

    //   final imageUrl =
    //       notification.android?.imageUrl ?? notification.apple?.imageUrl;

    //   await _showLocalNotification(
    //     id: message.hashCode,
    //     title: notification.title,
    //     body: notification.body,
    //     imageUrl: imageUrl,
    //     payload: message.data['type'],
    //   );
    // });

    FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationNavigation);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationNavigation(initialMessage);
    }
  } catch (e) {
    debugPrint('❌ Firebase setup error: $e');
  }

  final bool isLoggedIn = await StoreApiService.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// ─────────────────────────────────────────────
// NAVIGATION HANDLER
// ─────────────────────────────────────────────
void handleNotificationNavigation(RemoteMessage message) {
  final type = message.data['type'];
  debugPrint('🎯 Notification tapped — type: $type');
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => const HomePage()),
  );
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ClubIndia Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFFFF0F3),
      ),
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}

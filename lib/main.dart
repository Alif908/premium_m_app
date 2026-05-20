import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:premium_m_app/services/store_api_service.dart';
import 'package:premium_m_app/views/home/home_page.dart';
import 'package:premium_m_app/views/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint('🔴 STACK TRACE:\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PLATFORM ERROR: $error');
    debugPrint('🔴 STACK TRACE:\n$stack');
    return true;
  };

  // ✅ 'store_token' — store_api_service.dart-ലെ _tokenKey ആണ് ഇത്
  final bool isLoggedIn = await StoreApiService.isLoggedIn();
  debugPrint('🔐 isLoggedIn at startup: $isLoggedIn');

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

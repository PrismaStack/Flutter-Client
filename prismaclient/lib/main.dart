// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart'; // Import the User model
import 'ui/login_screen.dart';
import 'ui/prisma_desktop_app.dart';
import 'ui/prisma_mobile_app.dart'; // Import the new mobile app view

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _currentUser;

  void _handleLoginSuccess(User user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  /// Builds the appropriate home screen based on the platform.
  Widget _buildHomeScreen() {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      return PrismaMobileHome(
        currentUser: _currentUser!,
        onLogout: _handleLogout,
      );
    } else {
      return PrismaDesktopHome(
        currentUser: _currentUser!,
        onLogout: _handleLogout,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prisma Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF21242E),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: _currentUser != null
          ? _buildHomeScreen() // Use the helper to select the view
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}
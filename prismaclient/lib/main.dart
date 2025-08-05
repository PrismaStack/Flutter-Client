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
  // CHANGED: Add state to hold the authentication token
  String? _token;

  // CHANGED: The login handler now accepts the user and their token
  void _handleLoginSuccess(User user, String token) {
    setState(() {
      _currentUser = user;
      _token = token;
    });
  }

  // CHANGED: Logout should clear both the user and the token
  void _handleLogout() {
    setState(() {
      _currentUser = null;
      _token = null;
    });
  }

  /// Builds the appropriate home screen based on the platform.
  Widget _buildHomeScreen() {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    // FIX: Pass the token down to the main app views
    if (isMobile) {
      return PrismaMobileHome(
        currentUser: _currentUser!,
        token: _token!,
        onLogout: _handleLogout,
      );
    } else {
      return PrismaDesktopHome(
        currentUser: _currentUser!,
        token: _token!,
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
      // CHANGED: Check for user AND token to determine if logged in.
      // Pass the updated login handler to the LoginScreen.
      home: _currentUser != null && _token != null
          ? _buildHomeScreen() // Use the helper to select the view
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}
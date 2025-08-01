// main.dart
import 'package:flutter/material.dart';
import 'models.dart'; // Import the User model
import 'ui/desktop/login_screen.dart';
import 'ui/desktop/prisma_desktop_app.dart'; // Import your main desktop app

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
          ? PrismaDesktopHome(
              currentUser: _currentUser!,
              onLogout: _handleLogout, // FIX: Pass the callback here
            )
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}
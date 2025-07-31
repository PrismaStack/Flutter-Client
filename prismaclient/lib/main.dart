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
  // UPDATED: Store the full User object, not just a boolean
  User? _currentUser;

  // UPDATED: The handler now receives the User object on success
  void _handleLoginSuccess(User user) {
    setState(() {
      _currentUser = user;
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
      // UPDATED: Pass the currentUser to the home screen
      home: _currentUser != null
          ? PrismaDesktopHome(currentUser: _currentUser!)
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}
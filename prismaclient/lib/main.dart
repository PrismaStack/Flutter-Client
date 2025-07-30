import 'package:flutter/material.dart';
import 'ui/desktop/login.dart';
import 'ui/desktop/prisma_desktop_app.dart';

void main() {
  runApp(const PrismaAppRoot());
}

class PrismaAppRoot extends StatefulWidget {
  const PrismaAppRoot({super.key});

  @override
  State<PrismaAppRoot> createState() => _PrismaAppRootState();
}

class _PrismaAppRootState extends State<PrismaAppRoot> {
  bool _loggedIn = false;

  void _onLoginSuccess() {
    setState(() {
      _loggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prisma Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: _loggedIn
          ? const PrismaDesktopHome()
          : LoginScreen(onLoginSuccess: _onLoginSuccess),
    );
  }
}
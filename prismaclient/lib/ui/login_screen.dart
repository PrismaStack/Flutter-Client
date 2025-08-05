// ui/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models.dart'; // Import User model
import '../../config.dart';

class LoginScreen extends StatefulWidget {
  // CHANGED: Callback now expects a User and a Token string
  final void Function(User, String) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMode { login, register }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.login;
  String _username = '';
  String _password = '';
  String _error = '';
  bool _loading = false;

  void _switchMode() {
    setState(() {
      _authMode =
          _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _error = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = '';
    });

    final isLogin = _authMode == AuthMode.login;
    final url = Uri.parse(isLogin
        ? '${AppConfig.apiDomain}/api/login'
        : '${AppConfig.apiDomain}/api/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
        }),
      );
      // FIX: Server returns 200 for both successful login and registration.
      if (response.statusCode == 200) {
        if (isLogin) {
          // FIX: On successful login, parse the user AND the token.
          // The server now returns a flat JSON object with user data and the token.
          final responseData = json.decode(response.body);
          final user = User.fromJson(responseData);
          final token = responseData['token'] as String;

          // Call the callback with both user and token.
          widget.onLoginSuccess(user, token);
        } else {
          // On successful register, switch to login mode with a message
          setState(() {
            _authMode = AuthMode.login;
            _error = 'Registration successful! Please sign in.';
          });
        }
      } else {
        setState(() {
          _error = utf8.decode(response.bodyBytes);
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to connect to server: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;
    return Scaffold(
      backgroundColor: const Color(0xFF21242E),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF262A36).withOpacity(0.98),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bubble_chart, color: Colors.tealAccent, size: 56),
                const SizedBox(height: 16),
                Text(
                  isLogin ? "Sign In to Prisma" : "Create your Prisma Account",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const ValueKey('username'),
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: const TextStyle(color: Colors.tealAccent),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Enter a username";
                    }
                    return null;
                  },
                  onSaved: (val) => _username = val ?? '',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('password'),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.tealAccent),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.length < 4) {
                      return "Password must be at least 4 characters";
                    }
                    return null;
                  },
                  onSaved: (val) => _password = val ?? '',
                ),
                const SizedBox(height: 18),
                if (_error.isNotEmpty)
                  Text(
                    _error,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                if (_error.isNotEmpty) const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.teal),
                          )
                        : Text(isLogin ? "Sign In" : "Register"),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading ? null : _switchMode,
                  child: Text(
                    isLogin
                        ? "Don't have an account? Register"
                        : "Already have an account? Sign In",
                    style: const TextStyle(color: Colors.tealAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
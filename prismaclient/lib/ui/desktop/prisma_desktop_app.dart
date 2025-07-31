import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models.dart';
import 'chat_view.dart';
import 'drawers/left_drawer.dart';
import 'drawers/right_drawer.dart';
import 'settings/settings_view.dart';

// PrismaDesktopApp StatelessWidget is unchanged...

class PrismaDesktopApp extends StatelessWidget {
  const PrismaDesktopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prisma Chat (Desktop)',
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
      home: null,
    );
  }
}

class PrismaDesktopHome extends StatefulWidget {
  final User currentUser;
  const PrismaDesktopHome({super.key, required this.currentUser});

  @override
  State<PrismaDesktopHome> createState() => _PrismaDesktopHomeState();
}

class _PrismaDesktopHomeState extends State<PrismaDesktopHome> {
  Channel? _selectedChannel;
  bool _showSettings = false;

  // **NEW**: State for managing a single, shared WebSocket connection.
  WebSocketChannel? _channel;
  StreamController<dynamic> _streamController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      // Connect to the WebSocket
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080/api/ws?user_id=${widget.currentUser.id}'),
      );

      // Listen to the channel and pipe messages into our broadcast controller
      _channel!.stream.listen(
        (message) {
          _streamController.add(message);
        },
        onDone: () {
          // Handle reconnection if the connection closes
          if (mounted) {
            Future.delayed(const Duration(seconds: 5), _connectWebSocket);
          }
        },
        onError: (error) {
          // Handle errors and schedule reconnection
          _streamController.addError(error);
          if (mounted) {
            Future.delayed(const Duration(seconds: 5), _connectWebSocket);
          }
        },
      );
    } catch (e) {
      _streamController.addError(e);
    }
  }

  void _handleChannelSelected(Channel channel) {
    setState(() {
      _selectedChannel = channel;
    });
  }

  void _toggleSettingsView() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showSettings
          ? SettingsView(
              currentUser: widget.currentUser,
              onClose: _toggleSettingsView,
            )
          : Row(
              children: [
                LeftDrawer(
                  user: widget.currentUser,
                  onChannelSelected: _handleChannelSelected,
                  onSettingsTapped: _toggleSettingsView,
                ),
                Expanded(
                  flex: 3,
                  child: _selectedChannel == null
                      ? _buildWelcomeView()
                      : ChatView(
                          key: ValueKey(_selectedChannel!.id),
                          channel: _selectedChannel!,
                          currentUser: widget.currentUser,
                          // **MODIFIED**: Pass the shared stream
                          webSocketStream: _streamController.stream,
                        ),
                ),
                // **MODIFIED**: Pass the shared stream
                RightDrawer(
                  currentUser: widget.currentUser,
                  webSocketStream: _streamController.stream,
                ),
              ],
            ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 60, color: Colors.tealAccent.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'Select a channel to start chatting',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _streamController.close();
    super.dispose();
  }
}
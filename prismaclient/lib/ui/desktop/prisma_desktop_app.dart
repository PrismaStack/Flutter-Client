import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models.dart';
import '../../config.dart';
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
  final VoidCallback onLogout;

  const PrismaDesktopHome({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<PrismaDesktopHome> createState() => _PrismaDesktopHomeState();
}

class _PrismaDesktopHomeState extends State<PrismaDesktopHome> {
  Channel? _selectedChannel;
  bool _showSettings = false;

  WebSocketChannel? _channel;
  final StreamController<dynamic> _streamController = StreamController.broadcast();
  List<User>? _onlineUsers;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsDomain}/api/ws?user_id=${widget.currentUser.id}'),
      );

      _channel!.stream.listen(
        (message) {
          // Handle presence updates directly in this stateful widget
          final decodedWrapper = json.decode(message);
          final event = decodedWrapper['event'];
          if (event == 'presence_update') {
            final payload = decodedWrapper['payload'];
            if (payload is List) {
              if (mounted) {
                setState(() {
                  _onlineUsers = payload.map<User>((data) => User.fromJson(data)).toList();
                });
              }
            }
          }
          // Pipe all messages to the stream for other listeners (like ChatView)
          _streamController.add(message);
        },
        onDone: () {
          if (mounted) {
            Future.delayed(const Duration(seconds: 5), _connectWebSocket);
          }
        },
        onError: (error) {
          _streamController.addError(error);
          if (mounted) {
            setState(() => _onlineUsers = []); // Clear users on error
            Future.delayed(const Duration(seconds: 5), _connectWebSocket);
          }
        },
      );
    } catch (e) {
      if(mounted) setState(() => _onlineUsers = []);
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
              onLogout: widget.onLogout,
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
                          webSocketStream: _streamController.stream,
                        ),
                ),
                RightDrawer(
                  currentUser: widget.currentUser,
                  onlineUsers: _onlineUsers,
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
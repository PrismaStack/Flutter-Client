// ui/prisma_mobile_app.dart
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

/// The main application screen for mobile devices. It uses a Scaffold to
/// provide an AppBar and swipeable drawers for channels and user lists.
class PrismaMobileHome extends StatefulWidget {
  final User currentUser;
  // CHANGED: Add token property
  final String token;
  final VoidCallback onLogout;

  const PrismaMobileHome({
    super.key,
    required this.currentUser,
    // CHANGED: Add token to constructor
    required this.token,
    required this.onLogout,
  });

  @override
  State<PrismaMobileHome> createState() => _PrismaMobileHomeState();
}

class _PrismaMobileHomeState extends State<PrismaMobileHome> {
  Channel? _selectedChannel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State logic for WebSocket and online users, similar to the desktop view
  WebSocketChannel? _channel;
  final StreamController<dynamic> _streamController =
      StreamController.broadcast();
  List<User>? _onlineUsers;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _streamController.close();
    super.dispose();
  }

  void _connectWebSocket() {
    try {
      // FIX: Use the token for a secure WebSocket connection instead of user_id.
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsDomain}/api/ws?token=${widget.token}'),
      );

      _channel!.stream.listen(
        (message) {
          final decodedWrapper = json.decode(message);
          final event = decodedWrapper['event'];
          if (event == 'presence_update') {
            final payload = decodedWrapper['payload'];
            if (payload is List && mounted) {
              setState(() {
                _onlineUsers =
                    payload.map<User>((data) => User.fromJson(data)).toList();
              });
            }
          }
          _streamController.add(message);
        },
        onDone: () {
          if (mounted)
            Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
        onError: (error) {
          _streamController.addError(error);
          if (mounted) {
            setState(() => _onlineUsers = []);
            Future.delayed(const Duration(seconds: 5), _connectWebSocket);
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _onlineUsers = []);
      _streamController.addError(e);
    }
  }

  void _handleChannelSelected(Channel channel) {
    setState(() {
      _selectedChannel = channel;
    });
    // Close the drawer after selecting a channel
    Navigator.of(context).pop();
  }

  void _navigateToSettings() {
    // For mobile, we push the SettingsView as a new screen
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsView(
        currentUser: widget.currentUser,
        // FIX: Pass token to settings view
        token: widget.token,
        onClose: () => Navigator.of(context).pop(),
        onLogout: () {
          // Pop the settings screen first, then log out
          Navigator.of(context).pop();
          widget.onLogout();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_selectedChannel?.name ?? 'Prisma Chat'),
        backgroundColor: const Color(0xFF262A36),
        actions: [
          // Button to open the right drawer (online users list)
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: 'Online Users',
          ),
        ],
      ),
      drawer: LeftDrawer(
        user: widget.currentUser,
        // FIX: Pass token to left drawer
        token: widget.token,
        onChannelSelected: _handleChannelSelected,
        onSettingsTapped: _navigateToSettings,
      ),
      endDrawer: RightDrawer(
        currentUser: widget.currentUser,
        onlineUsers: _onlineUsers,
      ),
      body: _selectedChannel == null
          ? _buildWelcomeView()
          : ChatView(
              key: ValueKey(_selectedChannel!.id),
              channel: _selectedChannel!,
              currentUser: widget.currentUser,
              // FIX: Pass token to chat view
              token: widget.token,
              webSocketStream: _streamController.stream,
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
          const Text('Select a channel to start chatting',
              style: TextStyle(fontSize: 18, color: Colors.white54)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Text('Open Channels'),
          )
        ],
      ),
    );
  }
}
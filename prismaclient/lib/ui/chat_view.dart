import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../config.dart';
import 'message/message_input.dart';
import 'message/message_tile.dart';

class ChatView extends StatefulWidget {
  final Channel channel;
  final User currentUser;
  // CHANGED: Add token property
  final String token;
  final Stream<dynamic> webSocketStream;

  const ChatView({
    super.key,
    required this.channel,
    required this.currentUser,
    // CHANGED: Add token to constructor
    required this.token,
    required this.webSocketStream,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _streamSubscription;

  // FIX: Helper to create authenticated headers
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _listenToWebSocket();
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel.id != oldWidget.channel.id) {
      _fetchMessages();
    }
    if (widget.webSocketStream != oldWidget.webSocketStream) {
      _listenToWebSocket();
    }
  }

  void _listenToWebSocket() {
    _streamSubscription?.cancel();
    _streamSubscription = widget.webSocketStream.listen((message) {
      final decodedWrapper = json.decode(message);
      final event = decodedWrapper['event'];

      if (event == 'new_message') {
        final newMessage = Message.fromJson(decodedWrapper['payload']);
        if (newMessage.channelId == widget.channel.id) {
          if (mounted) {
            setState(() {
              _messages.insert(0, newMessage);
            });
          }
        }
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _error = "WebSocket Error: $error";
        });
      }
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _messages = [];
    });
    try {
      // FIX: Add authorization header to the request
      final response = await http.get(
        Uri.parse('${AppConfig.apiDomain}/api/channels/${widget.channel.id}/messages'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((json) => Message.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _messages = messages;
          });
        }
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    try {
      // FIX: Add authorization header to the request
      final response = await http.post(
        Uri.parse('${AppConfig.apiDomain}/api/messages'),
        headers: _authHeaders,
        body: jsonEncode({
          'content': content,
          'channel_id': widget.channel.id,
          // 'user_id' is no longer needed in the body,
          // the server gets it from the token
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF21242E),
      child: Column(
        children: [
          _buildChannelHeader(),
          Expanded(child: _buildMessageList()),
          MessageInput(
            channelName: widget.channel.name,
            onSend: _sendMessage,
            currentUser: widget.currentUser,
            // FIX: Pass token down to the MessageInput for file uploads
            token: widget.token,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Be the first to say something in #${widget.channel.name}!',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final bool isMe = message.userId == widget.currentUser.id;
        return MessageTile(
          username: message.username,
          time: DateFormat('h:mm a').format(message.createdAt.toLocal()),
          message: message.content,
          me: isMe,
          avatar: message.avatarUrl,
        );
      },
    );
  }

  Widget _buildChannelHeader() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF262A36).withOpacity(0.93),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF222430), width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.tag, color: Colors.tealAccent, size: 22),
          const SizedBox(width: 8),
          Text(
            widget.channel.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent.shade100,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Let the chatting begin!",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.push_pin_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.people), onPressed: () {}),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
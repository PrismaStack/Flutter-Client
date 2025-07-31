// ui/desktop/message/message_input.dart

import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final String channelName;
  final Future<void> Function(String message) onSend;

  const MessageInput({
    super.key,
    required this.channelName,
    required this.onSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _isSending = false;

  void _handleSend() async {
    if (_isSending || _controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    await widget.onSend(_controller.text.trim());

    if(mounted) {
      _controller.clear();
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF262A36).withOpacity(0.97),
        border: const Border(
          top: BorderSide(color: Color(0xFF23253A), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _handleSend(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Message #${widget.channelName}",
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.tealAccent),
            onPressed: () {},
          ),
          const SizedBox(width: 2),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF36D1C4), Color(0xFF5B9DF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: _isSending
                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                   : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
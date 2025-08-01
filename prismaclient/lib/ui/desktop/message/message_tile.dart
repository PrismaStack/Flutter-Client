import 'package:flutter/material.dart';
import '../../../config.dart';

class MessageTile extends StatelessWidget {
  final String username;
  final String? avatar;
  final String time;
  final String message;
  final bool me;
  const MessageTile({
    required this.username,
    this.avatar,
    required this.time,
    required this.message,
    required this.me,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: me ? Colors.tealAccent : Colors.blueGrey,
            radius: 18,
            backgroundImage: avatar != null
                ? NetworkImage('${AppConfig.apiDomain}$avatar')
                : null,
            child: avatar == null
                ? Text(username[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        color: me ? Colors.tealAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
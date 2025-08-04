// ui/desktop/message/message_tile.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
                ..._parseMessageContent(message, context), // Message content is parsed here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW WIDGET & HELPERS ---

class _FileAttachmentTile extends StatelessWidget {
  final Map<String, dynamic> uploadData;

  const _FileAttachmentTile({required this.uploadData});

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final String filename = uploadData['orig_filename'] ?? 'file';
    final int filesize = uploadData['filesize'] ?? 0;
    final String url = uploadData['url'] ?? '';
    final fullUrl = Uri.parse('${AppConfig.apiDomain}$url');

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Material(
        color: const Color(0xFF2A2D31),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () async {
            if (await canLaunchUrl(fullUrl)) {
              await launchUrl(fullUrl, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 350),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insert_drive_file_rounded, color: Colors.white70, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filename,
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatBytes(filesize),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
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

// --- MODIFIED PARSING LOGIC ---

List<Widget> _parseMessageContent(String message, BuildContext context) {
  const fileMarker = 'PRISMA_FILE_PAYLOAD::';
  if (message.startsWith(fileMarker)) {
    try {
      final jsonString = message.substring(fileMarker.length);
      final uploadData = json.decode(jsonString);
      return [ _FileAttachmentTile(uploadData: uploadData) ];
    } catch (e) {
      return [Text(message, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))];
    }
  }

  final widgets = <Widget>[];
  final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
  final matches = urlRegExp.allMatches(message);
  int lastIndex = 0;

  for (var match in matches) {
    if (match.start > lastIndex) {
      widgets.add(Text(
        message.substring(lastIndex, match.start),
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
      ));
    }
    final url = match.group(0)!;

    if (_isYouTube(url)) {
      widgets.add(_YouTubeEmbed(url));
    } else if (_isImage(url)) {
      widgets.add(_ImageEmbed(url));
    } else {
      widgets.add(_LinkWidget(url));
    }
    lastIndex = match.end;
  }

  if (lastIndex < message.length) {
    widgets.add(Text(
      message.substring(lastIndex),
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
    ));
  }

  if (widgets.isEmpty) {
    widgets.add(Text(
      message,
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
    ));
  }

  return widgets;
}

bool _isImage(String url) {
  return url.toLowerCase().endsWith('.png') ||
      url.toLowerCase().endsWith('.jpg') ||
      url.toLowerCase().endsWith('.jpeg') ||
      url.toLowerCase().endsWith('.gif') ||
      url.toLowerCase().endsWith('.webp');
}

bool _isYouTube(String url) {
  return RegExp(r'(youtube\.com\/watch\?v=|youtu\.be\/)').hasMatch(url);
}

class _ImageEmbed extends StatelessWidget {
  final String url;
  const _ImageEmbed(this.url);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Text("Could not load image", style: TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }
}

class _YouTubeEmbed extends StatelessWidget {
  final String url;
  const _YouTubeEmbed(this.url);

  String? get videoId {
    try {
        final uri = Uri.parse(url);
        if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
        } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.first;
        }
    } catch (e) {
        return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final id = videoId;
    if (id == null || id.isEmpty) return _LinkWidget(url);

    final uri = Uri.parse(url);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: InkWell(
        onTap: () async {
            if (await canLaunchUrl(uri)) {
                // FIXED: Use the new mode parameter
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
        },
        child: Image.network(
          "https://i.ytimg.com/vi/$id/hqdefault.jpg",
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Text("View on YouTube", style: TextStyle(color: Colors.blueAccent)),
        ),
      ),
    );
  }
}

class _LinkWidget extends StatelessWidget {
  final String url;
  const _LinkWidget(this.url);

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(url);
    return InkWell(
      child: Text(
        url,
        style: const TextStyle(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
          fontSize: 15,
        ),
      ),
      onTap: () async {
        if (await canLaunchUrl(uri)) {
          // FIXED: Use the new mode parameter instead of forceWebView
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
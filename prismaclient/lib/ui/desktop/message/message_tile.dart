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
                ..._parseMessageContent(message, context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _parseMessageContent(String message, BuildContext context) {
  final widgets = <Widget>[];

  // Regex for URLs
  final urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)', caseSensitive: false);

  // Split message into text and URLs
  final matches = urlRegExp.allMatches(message);
  int lastIndex = 0;

  for (var match in matches) {
    // Add text before the URL
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

  // Add any trailing text
  if (lastIndex < message.length) {
    widgets.add(Text(
      message.substring(lastIndex),
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
    ));
  }

  // If there are no links, just render the message as text
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
  // Matches YouTube links
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

  String get videoId {
    final uri = Uri.tryParse(url);
    if (uri == null) return "";
    if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : "";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final id = videoId;
    if (id.isEmpty) return _LinkWidget(url);

    // Desktop fallback: clickable thumbnail
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: InkWell(
        onTap: () async {
          if (await canLaunch(url)) await launch(url);
        },
        child: Image.network(
          "https://img.youtube.com/vi/$id/0.jpg",
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Text("View on YouTube", style: TextStyle(color: Colors.blueAccent)),
        ),
      ),
    );

    // Uncomment below for webview preview on web only (requires webview_flutter for web)
    /*
    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: SizedBox(
          height: 220,
          child: WebView(
            initialUrl: 'https://www.youtube.com/embed/$id',
            javascriptMode: JavascriptMode.unrestricted,
          ),
        ),
      );
    }
    */
  }
}

class _LinkWidget extends StatelessWidget {
  final String url;
  const _LinkWidget(this.url);

  @override
  Widget build(BuildContext context) {
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
        if (await canLaunch(url)) {
          await launch(url, forceWebView: false);
        }
      },
    );
  }
}
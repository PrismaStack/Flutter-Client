// ui/desktop/message/message_input.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart'; // UPDATED: Import file_picker
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../../config.dart';
import '../../../models.dart';

class MessageInput extends StatefulWidget {
  final String channelName;
  final Future<void> Function(String message) onSend;
  final User currentUser;

  const MessageInput({
    super.key,
    required this.channelName,
    required this.onSend,
    required this.currentUser,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _isUploading = false;

  void _handleSend() async {
    if (_isSending || _controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    await widget.onSend(_controller.text.trim());

    if (mounted) {
      _controller.clear();
      setState(() => _isSending = false);
    }
  }

  // Check if a filename is an image based on its extension
  bool _isImageFile(String filename) {
    final lowercased = filename.toLowerCase();
    return lowercased.endsWith('.png') ||
        lowercased.endsWith('.jpg') ||
        lowercased.endsWith('.jpeg') ||
        lowercased.endsWith('.gif') ||
        lowercased.endsWith('.webp');
  }

  // UPDATED: Handles picking any file and uploading it
  Future<void> _handleFileUpload() async {
    setState(() => _isUploading = true);
    try {
      // Use file_picker to select any file type
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result == null) {
        setState(() => _isUploading = false);
        return; // User canceled the picker
      }

      final String filename = result.files.single.name;
      final bool isImage = _isImageFile(filename);

      // 1. Create the multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiDomain}/api/upload-file'),
      );
      request.fields['user_id'] = widget.currentUser.id.toString();

      // 2. Add file to the request (platform-specific)
      if (kIsWeb) {
        final fileBytes = result.files.single.bytes!;
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
          contentType: MediaType('application', 'octet-stream'),
        ));
      } else {
        final filePath = result.files.single.path!;
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('application', 'octet-stream'),
        ));
      }

      // 3. Send the request
      var response = await request.send();

      // 4. Handle the response
      if (response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final uploadJson = json.decode(responseData);
        final String url = uploadJson['url'];
        final String fullUrl = '${AppConfig.apiDomain}$url';

        // 5. Send a different message format based on file type
        if (isImage) {
          // For images, just send the URL to get it embedded
          await widget.onSend(fullUrl);
        } else {
          // For other files, send the special payload for the custom tile
          const fileMarker = 'PRISMA_FILE_PAYLOAD::';
          final messageContent = '$fileMarker$responseData';
          await widget.onSend(messageContent);
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Failed to upload file: ${response.reasonPhrase} - $errorBody');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white54),
              onPressed: _handleFileUpload,
              tooltip: 'Attach File',
            ),
          const SizedBox(width: 8),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
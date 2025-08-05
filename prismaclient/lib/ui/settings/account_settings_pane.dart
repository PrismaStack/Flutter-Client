import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../../../models.dart';
import '../../../config.dart';
import 'dart:convert';

class AccountSettingsPane extends StatefulWidget {
  final User user;
  final Function(String) onAvatarUpdated;
  // CHANGED: Add token property
  final String token;

  const AccountSettingsPane({
    super.key,
    required this.user,
    required this.onAvatarUpdated,
    // CHANGED: Add token to constructor
    required this.token,
  });

  @override
  State<AccountSettingsPane> createState() => _AccountSettingsPaneState();
}

class _AccountSettingsPaneState extends State<AccountSettingsPane> {
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiDomain}/api/upload-avatar'),
      );
      // FIX: Add Authorization header to the multipart request
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // ---- FIX for Web File Upload ----
      // Switched to a streaming approach for web to avoid a known platform issue.
      if (kIsWeb) {
        final file = _selectedImage!;
        request.files.add(
          http.MultipartFile(
            'avatar',
            file.openRead(),
            await file.length(),
            filename: file.name,
            contentType: MediaType('image', path.extension(file.name).replaceFirst('.', '')),
          ),
        );
      } else {
        // Desktop: use fromPath
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            _selectedImage!.path,
            contentType: MediaType('image', path.extension(_selectedImage!.path).replaceFirst('.', '')),
          ),
        );
      }
      // ---- END FIX ----

      request.fields['user_id'] = widget.user.id.toString();

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        widget.onAvatarUpdated(jsonResponse['avatar_url']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildAvatar() {
    final currentAvatar = widget.user.avatarUrl;

    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.tealAccent,
          backgroundImage: currentAvatar != null
              ? NetworkImage('${AppConfig.apiDomain}$currentAvatar')
              : null,
          child: currentAvatar == null
              ? const Icon(Icons.person, size: 50, color: Colors.black87)
              : null,
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.tealAccent,
            onPressed: _isUploading ? null : _pickImage,
            child: const Icon(Icons.camera_alt, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232635),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildAuthCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFF111214),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Banner
          Container(
            height: 100,
            decoration: const BoxDecoration(color: Color(0xFF6B45BC)),
          ),
          // Profile Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' •••',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2D31),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Edit User Profile'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFF111214),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _InfoRow(label: 'Display Name', value: widget.user.displayName),
            const Divider(color: Colors.white10),
            _InfoRow(label: 'Username', value: widget.user.username),
            const Divider(color: Colors.white10),
            _InfoRow(label: 'Email', value: widget.user.email, hasReveal: true),
            const Divider(color: Colors.white10),
            _InfoRow(label: 'Phone Number', value: widget.user.phone, hasReveal: true, showEdit: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFF111214),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password and Authentication',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2D31),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Change Password'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.shield, color: Colors.greenAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Multi-Factor Authentication Enabled',
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Authenticator App',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configuring an authenticator app is a good way to add an extra layer of security to your Discord account to make sure that only you have the ability to log in.',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('View Backup Codes'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Remove Authenticator App'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool hasReveal;
  final bool showEdit;

  const _InfoRow({
    required this.label,
    required this.value,
    this.hasReveal = false,
    this.showEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (hasReveal)
                      TextButton(
                        onPressed: () {},
                        child: const Text('Reveal', style: TextStyle(color: Colors.tealAccent)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showEdit)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2D31),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Edit'),
            )
          else
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2D31),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Remove'),
            ),
        ],
      ),
    );
  }
}
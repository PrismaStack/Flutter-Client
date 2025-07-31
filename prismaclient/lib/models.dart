// UPDATED: User class with more fields for the settings page and avatarUrl
class User {
  final int id;
  final String username;
  final String displayName;
  final String email;
  final String phone;
  final String? avatarUrl; // This field already exists and is correct
  final String role; // NEW: Add role for differentiating admins

  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.role, // NEW
  });

  // UPDATED: Factory now handles 'role' and 'avatar_url' from different sources
  factory User.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String;
    return User(
      id: json['id'],
      username: username.toLowerCase().replaceAll(' ', ''),
      displayName: username,
      // These are dummy values for the settings page, adjust as needed
      email: 's*********e@protonmail.com',
      phone: '************34',
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'guest', // NEW: Handle role from JSON
    );
  }
}

// --- Other models (Channel, ChannelCategory, Message) are unchanged ---

class Channel {
  final int id;
  String name;
  final int categoryId;
  int position;

  Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.position,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      position: json['position'] ?? 0,
    );
  }
}

class ChannelCategory {
  final int id;
  String name;
  int position;
  final List<Channel> channels;

  ChannelCategory({
    required this.id,
    required this.name,
    required this.position,
    required this.channels,
  });

  factory ChannelCategory.fromJson(Map<String, dynamic> json) {
    var channelList = json['channels'] as List? ?? [];
    List<Channel> channels =
        channelList.map((i) => Channel.fromJson(i)).toList();
    channels.sort((a, b) => a.position.compareTo(b.position));
    return ChannelCategory(
      id: json['id'],
      name: json['name'],
      position: json['position'] ?? 0,
      channels: channels,
    );
  }
}

class Message {
  final int id;
  final int channelId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final String? avatarUrl; // This field already exists and is correct

  Message({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      channelId: json['channel_id'],
      userId: json['user_id'],
      username: json['username'],
      content: json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      avatarUrl: json['avatar_url'],
    );
  }
}
import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../config.dart';

class RightDrawer extends StatelessWidget {
  final User currentUser;
  final List<User>? onlineUsers;

  const RightDrawer({
    super.key,
    required this.currentUser,
    required this.onlineUsers,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (onlineUsers == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      final admins = onlineUsers!.where((u) => u.role == 'admin').toList();
      final members = onlineUsers!.where((u) => u.role != 'admin').toList();

      admins.sort((a, b) => a.displayName.compareTo(b.displayName));
      members.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (admins.isEmpty && members.isEmpty) {
        content = const Center(child: Text('No users online', style: TextStyle(color: Colors.white54)));
      } else {
        content = ListView(
          padding: EdgeInsets.zero,
          children: [
            if (admins.isNotEmpty) ...[
              const _SectionHeader(title: "Admins"),
              ...admins.map((user) => _MemberTile(user: user)),
            ],
            if (members.isNotEmpty) ...[
              const _SectionHeader(title: "Members"),
              ...members.map((user) => _MemberTile(user: user)),
            ],
          ],
        );
      }
    }

    return Container(
      width: 260,
      color: const Color(0xFF1A1C22),
      child: content,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.tealAccent.shade100.withOpacity(0.8),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User user;
  const _MemberTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role == 'admin';
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: isAdmin ? Colors.deepPurpleAccent : Colors.tealAccent,
        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? NetworkImage('${AppConfig.apiDomain}${user.avatarUrl}')
            : null,
        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
            ? Text(
                user.displayName.isNotEmpty ? user.displayName[0] : '?',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.displayName,
              style: TextStyle(
                color: isAdmin ? Colors.deepPurple.shade200 : Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAdmin)
            const Icon(Icons.star, color: Colors.amberAccent, size: 16),
        ],
      ),
      trailing: const Icon(
        Icons.circle,
        color: Colors.greenAccent,
        size: 14,
      ),
    );
  }
}
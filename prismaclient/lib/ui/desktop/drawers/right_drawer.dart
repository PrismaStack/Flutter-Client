import 'package:flutter/material.dart';

class RightDrawer extends StatelessWidget {
  const RightDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF1A1C22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: "Admins"),
          const _MemberTile(name: "SarahRose", admin: true, online: true),
          const _MemberTile(name: "Ryzreth", admin: true, online: false),
          const SizedBox(height: 12),
          const _SectionHeader(title: "Members"),
          Expanded(
            child: ListView(
              children: const [
                _MemberTile(name: "Jodfie", online: true),
                _MemberTile(name: "KMTRZ", online: true),
                _MemberTile(name: "Matt N3PAY", online: false),
                _MemberTile(name: "shortword", online: true),
                _MemberTile(name: "ZephyraTheMare", online: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widgets for RightDrawer
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
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
  final String name;
  final bool admin;
  final bool online;
  const _MemberTile({required this.name, this.admin = false, this.online = false});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: admin
            ? Colors.deepPurpleAccent
            : (online ? Colors.tealAccent : Colors.blueGrey),
        child: Text(
          name[0],
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: admin
                    ? Colors.deepPurpleAccent
                    : (online ? Colors.tealAccent : Colors.white70),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (admin)
            const Icon(Icons.star, color: Colors.amberAccent, size: 16),
        ],
      ),
      trailing: Icon(
        online ? Icons.circle : Icons.circle_outlined,
        color: online ? Colors.greenAccent : Colors.white12,
        size: 14,
      ),
    );
  }
}
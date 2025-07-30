import 'package:flutter/material.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Workspace/server icons sidebar
        Container(
          width: 68,
          color: const Color(0xFF181B23),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _SidebarIcon(icon: Icons.bubble_chart, selected: true),
              _SidebarIcon(icon: Icons.group),
              _SidebarIcon(icon: Icons.settings),
              const Spacer(),
              _SidebarIcon(icon: Icons.account_circle),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Channel list
        Container(
          width: 220,
          color: const Color(0xFF232635),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: "Welcome"),
              ...["welcome", "announcements", "blog-updates", "introductions"]
                  .map((c) => _ChannelTile(channel: c, selected: c == "welcome")),
              const SizedBox(height: 18),
              const _SectionHeader(title: "Communications Lobby"),
              ...["general-lobby", "off-topic", "sdr-rx-and-id", "amateur-radio", "space-comms"]
                  .map((c) => _ChannelTile(channel: c, selected: c == "general-lobby")),
              const Spacer(),
              const _MeTile(username: "SarahRose", status: "Online"),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

// Widgets for LeftDrawer
class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _SidebarIcon({required this.icon, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: selected
          ? BoxDecoration(
              color: Colors.tealAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: IconButton(
        icon: Icon(icon, color: selected ? Colors.tealAccent : Colors.white54, size: 28),
        onPressed: () {},
      ),
    );
  }
}

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

class _ChannelTile extends StatelessWidget {
  final String channel;
  final bool selected;
  const _ChannelTile({required this.channel, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.tealAccent.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.tag, size: 18, color: selected ? Colors.tealAccent : Colors.white30),
              const SizedBox(width: 8),
              Text(
                "#$channel",
                style: TextStyle(
                  color: selected ? Colors.tealAccent : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeTile extends StatelessWidget {
  final String username;
  final String status;
  const _MeTile({required this.username, required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.tealAccent,
            radius: 16,
            child: const Icon(Icons.person, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
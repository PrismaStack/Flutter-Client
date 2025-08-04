import 'package:flutter/material.dart';

class AppearanceSettingsPane extends StatelessWidget {
  const AppearanceSettingsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Appearance", style: TextStyle(
            color: Colors.tealAccent.shade100,
            fontSize: 23,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          )),
          const SizedBox(height: 24),
          Text("Customize the look and feel of Prisma Chat.",
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 26),
          Row(
            children: [
              Icon(Icons.dark_mode, color: Colors.tealAccent.shade100),
              const SizedBox(width: 16),
              Text("Dark mode is always enabled (for now)",
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
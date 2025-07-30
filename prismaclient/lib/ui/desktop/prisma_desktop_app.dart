import 'package:flutter/material.dart';
import 'drawers/left_drawer.dart';
import 'drawers/right_drawer.dart';
import 'message/message_input.dart';
import 'message/message_tile.dart';

class PrismaDesktopApp extends StatelessWidget {
  const PrismaDesktopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prisma Chat (Desktop)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const PrismaDesktopHome(),
    );
  }
}

class PrismaDesktopHome extends StatelessWidget {
  const PrismaDesktopHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const LeftDrawer(),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF21242E),
                image: DecorationImage(
                  image: AssetImage('assets/prisma_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.18), BlendMode.darken
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Channel header
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262A36).withOpacity(0.93),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF222430), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.tag, color: Colors.tealAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "#general-lobby",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent.shade100,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "General lobby to mingle and get to know other users.",
                            style: TextStyle(
                              color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.push_pin_outlined), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.group), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  // Chat messages
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                      children: const [
                        MessageTile(
                          username: "SarahRose",
                          avatar: null,
                          time: "5:40 AM",
                          message: "Hey! Welcome to Prisma 🎉",
                          me: true,
                        ),
                        MessageTile(
                          username: "PrismaBot",
                          avatar: null,
                          time: "5:41 AM",
                          message: "Let us know if you need anything.",
                          me: false,
                        ),
                        MessageTile(
                          username: "SarahRose",
                          avatar: null,
                          time: "5:45 AM",
                          message: "Trying out the new desktop UI. Looks nice!",
                          me: true,
                        ),
                      ],
                    ),
                  ),
                  // Chat input
                  const MessageInput(),
                ],
              ),
            ),
          ),
          const RightDrawer(),
        ],
      ),
    );
  }
}
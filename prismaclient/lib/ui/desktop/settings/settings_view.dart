import 'package:flutter/material.dart';
import '../../../models.dart';
import 'account_settings_pane.dart';
import 'appearance_settings_pane.dart';

class SettingsView extends StatefulWidget {
  User currentUser;
  final VoidCallback onClose;
  final VoidCallback onLogout;

  SettingsView({
    super.key,
    required this.currentUser,
    required this.onClose,
    required this.onLogout,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _selectedPageId = 'my_account';

  Widget _buildContentPane() {
    switch (_selectedPageId) {
      case 'my_account':
        return AccountSettingsPane(
          user: widget.currentUser,
          onAvatarUpdated: (avatarUrl) {
            setState(() {
              widget.currentUser = User(
                id: widget.currentUser.id,
                username: widget.currentUser.username,
                displayName: widget.currentUser.displayName,
                email: widget.currentUser.email,
                phone: widget.currentUser.phone,
                avatarUrl: avatarUrl,
                role: widget.currentUser.role,
              );
            });
          },
        );
      case 'appearance':
        return const AppearanceSettingsPane();
      default:
        return Center(
          child: Text(
            'Settings for "$_selectedPageId" coming soon!',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingsSidebar(
          currentUser: widget.currentUser,
          selectedPageId: _selectedPageId,
          onPageSelected: (id) => setState(() => _selectedPageId = id),
          onLogout: widget.onLogout,
        ),
        Expanded(
          child: Column(
            children: [
              _SettingsHeader(onClose: widget.onClose),
              Expanded(
                child: ClipRect(
                  child: _buildContentPane(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _SettingsHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      color: const Color(0xFF232635),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 60.0),
          child: InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1.5),
                  ),
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
                const SizedBox(height: 2),
                const Text('ESC', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  final User currentUser;
  final String selectedPageId;
  final Function(String) onPageSelected;
  final VoidCallback onLogout;

  const _SettingsSidebar({
    required this.currentUser,
    required this.selectedPageId,
    required this.onPageSelected,
    required this.onLogout,
  });

  static const _userSettings = [
    {'id': 'my_account', 'label': 'My Account'},
    {'id': 'profiles', 'label': 'Profiles'},
    {'id': 'appearance', 'label': 'Appearance'},
    {'id': 'privacy', 'label': 'Privacy'},
  ];

  static const _adminSettings = [
    {'id': 'global_server_settings', 'label': 'Global Server Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.only(right: 40, top: 60, bottom: 20),
      color: const Color(0xFF21242E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ListView(
              children: [
                _NavSection(
                  title: 'User Settings',
                  items: _userSettings,
                  selectedId: selectedPageId,
                  onSelected: onPageSelected,
                ),
                if (currentUser.role == 'admin') ...[
                  const SizedBox(height: 24),
                  _NavSection(
                    title: 'Admin',
                    items: _adminSettings,
                    selectedId: selectedPageId,
                    onSelected: onPageSelected,
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          _NavTile(
            label: 'Log Out',
            isSelected: false,
            onTap: onLogout,
            icon: Icons.logout,
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final String selectedId;
  final Function(String) onSelected;

  const _NavSection({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        ...items.map((item) => _NavTile(
          label: item['label']!,
          isSelected: selectedId == item['id'],
          onTap: () => onSelected(item['id']!),
        )),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _NavTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.white70),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
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
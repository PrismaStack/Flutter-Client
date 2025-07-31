import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models.dart';

// --- Main Widget ---

class LeftDrawer extends StatefulWidget {
  final User user;
  final void Function(Channel channel) onChannelSelected;
  final VoidCallback onSettingsTapped;

  const LeftDrawer({
    super.key,
    required this.user,
    required this.onChannelSelected,
    required this.onSettingsTapped,
  });

  @override
  State<LeftDrawer> createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  List<ChannelCategory> _categories = [];
  int? _selectedChannelId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8080/api/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final categories =
            data.map((json) => ChannelCategory.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _categories = categories;
            if (_categories.isNotEmpty && _categories.first.channels.isNotEmpty) {
              final firstChannel = _categories.first.channels.first;
              _selectedChannelId = firstChannel.id;
              widget.onChannelSelected(firstChannel);
            }
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrder(
      String endpoint, List<Map<String, int>> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/reorder/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to update order: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sync Error: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  void _onCategoryReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);

      final orderData = _categories.asMap().entries.map((entry) {
        return {'id': entry.value.id, 'position': entry.key};
      }).toList();
      _updateOrder('categories', orderData);
    });
  }

  void _onChannelReorder(ChannelCategory category, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final channel = category.channels.removeAt(oldIndex);
      category.channels.insert(newIndex, channel);

      final orderData = category.channels.asMap().entries.map((entry) {
        return {'id': entry.value.id, 'position': entry.key};
      }).toList();
      _updateOrder('channels', orderData);
    });
  }

  void _showContextMenu(BuildContext context, Offset position, Channel channel) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(
          value: 'rename',
          child: Row(children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 8),
            Text('Rename Channel'),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Channel', style: TextStyle(color: Colors.redAccent)),
          ]),
        ),
      ],
      elevation: 8,
      color: const Color(0xFF2C313D),
    ).then((value) {
      if (value == 'rename') {
        _showRenameDialog(channel);
      } else if (value == 'delete') {
        _showDeleteConfirmationDialog(channel);
      }
    });
  }

  Future<void> _createChannel(String name, int categoryId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/channels'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'category_id': categoryId}),
      );
      if (response.statusCode == 201) {
        _fetchData();
      } else {
        throw Exception('Failed to create channel: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Rename dialog implementation
  void _showRenameDialog(Channel channel) {
    final controller = TextEditingController(text: channel.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C313D),
          title: const Text('Rename Channel', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'New channel name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Name cannot be empty' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _renameChannel(channel.id, controller.text.trim());
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  // Delete confirmation dialog implementation
  void _showDeleteConfirmationDialog(Channel channel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C313D),
        title: Text('Delete Channel', style: TextStyle(color: Colors.red.shade300)),
        content: Text(
          'Are you sure you want to delete the channel #${channel.name}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteChannel(channel.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameChannel(int channelId, String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/channels/$channelId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': newName}),
      );
      if (response.statusCode == 200) {
        await _fetchData();
      } else {
        throw Exception('Failed to rename channel: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error renaming channel: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _deleteChannel(int channelId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/channels/$channelId'),
      );
      if (response.statusCode == 200) {
        await _fetchData();
      } else {
        throw Exception('Failed to delete channel: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting channel: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _showCreateChannelDialogFor(ChannelCategory category) {
    final formKey = GlobalKey<FormState>();
    String channelName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C313D),
          title: Text('Create New Channel in "${category.name}"', style: const TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Channel Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter a channel name' : null,
              onSaved: (value) => channelName = value!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.of(context).pop();
                  await _createChannel(channelName, category.id);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      ));
    }
    return ReorderableListView.builder(
      itemCount: _categories.length,
      onReorder: _onCategoryReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          key: ValueKey(category.id),
          color: Colors.transparent,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 18),
              _SectionHeader(
                title: category.name,
                onAdd: widget.user.role == 'admin' ? () => _showCreateChannelDialogFor(category) : null,
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, size: 20, color: Colors.white24),
                ),
              ),
              ReorderableListView.builder(
                key: ValueKey('channels-${category.id}'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: category.channels.length,
                onReorder: (oldI, newI) => _onChannelReorder(category, oldI, newI),
                buildDefaultDragHandles: false,
                itemBuilder: (context, channelIndex) {
                  final channel = category.channels[channelIndex];
                  return GestureDetector(
                    key: ValueKey(channel.id),
                    onSecondaryTapUp: (details) {
                      _showContextMenu(context, details.globalPosition, channel);
                    },
                    child: _ChannelTile(
                      channelName: channel.name,
                      selected: channel.id == _selectedChannelId,
                      onTap: () {
                        setState(() => _selectedChannelId = channel.id);
                        widget.onChannelSelected(channel);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 68,
          color: const Color(0xFF181B23),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _SidebarIcon(icon: Icons.bubble_chart, selected: true),
              const Spacer(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Container(
          width: 220,
          color: const Color(0xFF232635),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildChannelList()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _MeTile(
                  user: widget.user,
                  onSettingsPressed: widget.onSettingsTapped,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Helper Widgets (with changes) ---
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  final Widget dragHandle;
  const _SectionHeader({required this.title, this.onAdd, required this.dragHandle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.tealAccent.shade100.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              if (onAdd != null)
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: Colors.tealAccent),
                  onPressed: onAdd,
                  tooltip: "Add Channel",
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              dragHandle,
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final String channelName;
  final bool selected;
  final VoidCallback onTap;
  const _ChannelTile({super.key, required this.channelName, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.tealAccent.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.tag, size: 18, color: selected ? Colors.tealAccent : Colors.white30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channelName,
                  style: TextStyle(
                    color: selected ? Colors.tealAccent : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
              ),
              // No reorder handle on channels!
            ],
          ),
        ),
      ),
    );
  }
}

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

class _MeTile extends StatelessWidget {
  final User user;
  final VoidCallback? onSettingsPressed;
  const _MeTile({required this.user, this.onSettingsPressed});
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
            backgroundImage: user.avatarUrl != null
                ? NetworkImage('http://localhost:8080${user.avatarUrl}')
                : null,
            child: user.avatarUrl == null
                ? const Icon(Icons.person, color: Colors.black87)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              user.displayName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }
}
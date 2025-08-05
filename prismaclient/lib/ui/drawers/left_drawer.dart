import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models.dart';
import '../../../config.dart';

class LeftDrawer extends StatefulWidget {
  final User user;
  // CHANGED: Add token property
  final String token;
  final void Function(Channel channel) onChannelSelected;
  final VoidCallback onSettingsTapped;

  const LeftDrawer({
    super.key,
    required this.user,
    // CHANGED: Add token to constructor
    required this.token,
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

  // FIX: Helper to create authenticated headers
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // FIX: Add authorization header to the request
      final response = await http.get(
        Uri.parse('${AppConfig.apiDomain}/api/categories'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final categories =
            data.map((json) => ChannelCategory.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _categories = categories;

            // ---- FIX ----
            // The following block was removed. It was auto-selecting the first channel
            // and causing a navigation issue (a "pop") on mobile before the UI
            // was ready, leading to a black screen. The app will now wait for
            // the user to manually select a channel.
            /*
            if (_categories.isNotEmpty && _categories.first.channels.isNotEmpty) {
              final firstChannel = _categories.first.channels.first;
              _selectedChannelId = firstChannel.id;
              widget.onChannelSelected(firstChannel);
            }
            */
            // ---- END FIX ----
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
      // FIX: Add authorization header to the request
      final response = await http.post(
        Uri.parse('${AppConfig.apiDomain}/api/reorder/$endpoint'),
        headers: _authHeaders,
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

  Future<void> _moveChannelToCategory(Channel channel, int fromCategoryId, int toCategoryId) async {
    if (fromCategoryId == toCategoryId) return;
    try {
      // FIX: Add authorization header to the request
      final response = await http.put(
        Uri.parse('${AppConfig.apiDomain}/api/channels/${channel.id}'),
        headers: _authHeaders,
        body: json.encode({'category_id': toCategoryId}),
      );
      if (response.statusCode == 200) {
        _fetchData();
      } else {
        throw Exception('Failed to move channel: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving channel: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showContextMenu(BuildContext context, Offset position, Channel channel) {
    final fromCategory = _categories.firstWhere((cat) =>
      cat.channels.any((c) => c.id == channel.id),
      orElse: () => _categories.first
    );
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
        if (_categories.length > 1)
          PopupMenuItem(
            value: 'move',
            child: Row(children: const [
              Icon(Icons.drive_file_move_outline, size: 18),
              SizedBox(width: 8),
              Text('Move to...'),
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
      } else if (value == 'move') {
        _showMoveChannelDialog(channel, fromCategory);
      }
    });
  }

  void _showMoveChannelDialog(Channel channel, ChannelCategory fromCategory) {
    int? selectedCategoryId = _categories.where((c) => c.id != fromCategory.id).first.id;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C313D),
          title: const Text('Move Channel', style: TextStyle(color: Colors.white)),
          content: DropdownButtonFormField<int>(
            dropdownColor: const Color(0xFF2C313D),
            value: selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Select Category'),
            items: _categories.where((c) => c.id != fromCategory.id).map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) => selectedCategoryId = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategoryId != null) {
                  Navigator.of(context).pop();
                  await _moveChannelToCategory(channel, fromCategory.id, selectedCategoryId!);
                }
              },
              child: const Text('Move'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createChannel(String name, int categoryId) async {
    try {
      // FIX: Add authorization header to the request
      final response = await http.post(
        Uri.parse('${AppConfig.apiDomain}/api/channels'),
        headers: _authHeaders,
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

  Future<int?> _createCategory(String name) async {
    try {
      // FIX: Add authorization header to the request
      final response = await http.post(
        Uri.parse('${AppConfig.apiDomain}/api/categories'),
        headers: _authHeaders,
        body: jsonEncode({'name': name}),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating category: ${response.body}'), backgroundColor: Colors.redAccent),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
      return null;
    }
  }

  void _showCreateChannelDialog() {
    final formKey = GlobalKey<FormState>();
    String channelName = '';
    String newCategoryName = '';
    ChannelCategory? selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    bool createNewCategory = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C313D),
              title: const Text('Create New Channel', style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Channel Name'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter a channel name' : null,
                      onSaved: (value) => channelName = value!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text("Create new category", style: TextStyle(color: Colors.white70)),
                      value: createNewCategory,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          createNewCategory = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (createNewCategory)
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'New Category Name'),
                        validator: (value) {
                          if (createNewCategory && (value == null || value.trim().isEmpty)) {
                            return 'Enter a category name';
                          }
                          return null;
                        },
                        onSaved: (value) => newCategoryName = value!,
                        style: const TextStyle(color: Colors.white),
                      )
                    else
                      DropdownButtonFormField<ChannelCategory>(
                        value: selectedCategory,
                        dropdownColor: const Color(0xFF2C313D),
                        decoration: const InputDecoration(labelText: 'Choose Existing Category'),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.name, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) => setDialogState(() => selectedCategory = value),
                        validator: (value) {
                          if (!createNewCategory && value == null) {
                            return 'Select a category';
                          }
                          return null;
                        },
                      ),
                  ],
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

                      int? categoryId;
                      if (createNewCategory) {
                        categoryId = await _createCategory(newCategoryName);
                      } else {
                        categoryId = selectedCategory!.id;
                      }

                      if (categoryId != null) {
                        await _createChannel(channelName, categoryId);
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
      // FIX: Add authorization header to the request
      final response = await http.put(
        Uri.parse('${AppConfig.apiDomain}/api/channels/$channelId'),
        headers: _authHeaders,
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
      // FIX: Add authorization header to the request
      final response = await http.delete(
        Uri.parse('${AppConfig.apiDomain}/api/channels/$channelId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
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
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: category.name,
                onAdd: widget.user.role == 'admin' ? _showCreateChannelDialog : null,
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
                ? NetworkImage('${AppConfig.apiDomain}${user.avatarUrl}')
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
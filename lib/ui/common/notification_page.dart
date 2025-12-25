import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification_item.dart';
import '../../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _service = NotificationService();

  String _detectRole(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    if (uri.startsWith('/teacher')) return 'teacher';
    if (uri.startsWith('/admin')) return 'admin';
    return 'student';
  }

  String _baseOf(String role) => switch (role) {
        'teacher' => '/teacher',
        'admin' => '/admin',
        _ => '/student',
      };

  Future<void> _openNotification(NotificationItem item, String base) async {
    await _service.markAsRead(item.id);
    if (!mounted) return;
    if (item.postId != null && item.postId!.isNotEmpty) {
      context.push('$base/forum/${item.postId}');
    }
  }

  String _timeAgo(NotificationItem item) {
    final created = item.createdAt;
    if (created == null) return 'Just now';
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: () => _service.markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3FB),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'notification',
                    isActive: true,
                    onTap: () {},
                  ),
                  _SegmentButton(
                    label: 'message',
                    isActive: false,
                    onTap: () => context.go('$base/messages?tab=message'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationItem>>(
              stream: _service.notificationsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const _EmptyPlaceholder();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return _NotificationTile(
                      item: item,
                      timeAgo: _timeAgo(item),
                      onTap: () => _openNotification(item, base),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: items.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.timeAgo,
    required this.onTap,
  });

  final NotificationItem item;
  final String timeAgo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.read;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.campaign_outlined,
                  color: Color(0xFF3D5CFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13.5,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isUnread)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 6),
                child: Icon(Icons.circle, color: Color(0xFF3D5CFF), size: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_none,
              size: 64, color: Color(0xFFB0B4C4)),
          SizedBox(height: 10),
          Text(
            'You are all caught up',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B90A0),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'New notifications will appear here.',
            style: TextStyle(color: Color(0xFF8B90A0)),
          ),
        ],
      ),
    );
  }
}

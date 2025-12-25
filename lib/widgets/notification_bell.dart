import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationBell extends StatelessWidget {
  NotificationBell({
    super.key,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final VoidCallback onTap;
  final Color iconColor;
  final NotificationService _service = NotificationService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _service.unreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded,
                  color: iconColor, size: 28),
              onPressed: onTap,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

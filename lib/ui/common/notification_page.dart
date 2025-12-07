import 'package:flutter/material.dart';

import 'messages_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessagesPage(initialTab: InboxTab.notifications);
  }
}

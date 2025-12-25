import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';

enum InboxTab { notifications, messages }

const _inboxPrimary = Color(0xFF3D5CFF);
const _inboxMuted = Color(0xFF858597);

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
    this.initialTab = InboxTab.messages,
  });

  final InboxTab initialTab;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchCtrl = TextEditingController();
  InboxTab _currentTab = InboxTab.messages;
  bool _tabSynced = false;
  final NotificationService _notifService = NotificationService();

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

  String _chatId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return sorted.join('_');
  }

  void _syncTabFromUri() {
    if (_tabSynced) return;
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    final initial = tabParam == 'notifications'
        ? InboxTab.notifications
        : widget.initialTab;
    _currentTab = initial;
    _tabSynced = true;
  }

  void _setTab(InboxTab tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
      _searchCtrl.clear();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTabFromUri();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in")),
      );
    }

    final title =
        _currentTab == InboxTab.messages ? 'Messages' : 'Notifications';

    return WillPopScope(
      onWillPop: () async {
        context.go(base);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(base),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Column(
          children: [
            // Top tabs
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    text: 'notification',
                    isActive: _currentTab == InboxTab.notifications,
                    onTap: () => _setTab(InboxTab.notifications),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    text: 'message',
                    isActive: _currentTab == InboxTab.messages,
                    onTap: () => _setTab(InboxTab.messages),
                  ),
                ),
              ],
            ),

            // Search field (messages only)
            if (_currentTab == InboxTab.messages)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search... ',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _currentTab == InboxTab.messages
                    ? (_searchCtrl.text.trim().isEmpty
                        ? _RecentChatsList(
                            key: const ValueKey('recent_chats'),
                            currentEmail: user.email!,
                          )
                        : _SearchUserList(
                            key: const ValueKey('search_users'),
                            searchText: _searchCtrl.text.trim(),
                          ))
                    : _NotificationList(
                        key: const ValueKey('notification_tab'),
                        base: base,
                        service: _notifService,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recent chats list
class _RecentChatsList extends StatelessWidget {
  final String currentEmail;
  const _RecentChatsList({super.key, required this.currentEmail});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('user')
          .where('user_email', isEqualTo: currentEmail)
          .limit(1)
          .get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnap.data!.docs.isEmpty) {
          return const Center(child: Text("User not found"));
        }

        final currentUser = userSnap.data!.docs.first.data() as Map<String, dynamic>;
        final userId = currentUser['user_id'].toString();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .orderBy('updatedAt', descending: true)
              .snapshots(),
          builder: (context, chatSnap) {
            if (!chatSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = chatSnap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['participants0'] == userId ||
                  data['participants1'] == userId;
            }).toList();

            if (chats.isEmpty) {
              return const Center(child: Text("No chats yet"));
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, i) {
                final raw = chats[i].data() as Map<String, dynamic>;
                final chatId = (raw['chats_id'] ?? chats[i].id).toString();
                final otherIdRaw = raw['participants0'] == userId
                    ? raw['participants1']
                    : raw['participants0'];
                final otherId = otherIdRaw?.toString() ?? '';
                if (chatId.isEmpty) return const SizedBox.shrink();
                if (otherId.isEmpty) {
                  return const SizedBox.shrink();
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, msgSnap) {
                    if (!msgSnap.hasData || msgSnap.data!.docs.isEmpty) {
                      // Skip chats with no messages yet
                      return const SizedBox.shrink();
                    }

                    final msg = msgSnap.data!.docs.first.data()
                        as Map<String, dynamic>;
                    final lastText = (msg['text'] ?? '').toString();
                    final senderId = msg['user_id'];
                    final createdAt =
                        (msg['createdAt'] as Timestamp?)?.toDate();

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('user')
                          .where('user_id', isEqualTo: otherId)
                          .limit(1)
                          .snapshots(),
                      builder: (context, otherSnap) {
                        if (!otherSnap.hasData || otherSnap.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final otherUser = otherSnap.data!.docs.first.data()
                            as Map<String, dynamic>;
                        final name = otherUser['user_fullname'] ?? 'Unknown';
                        final avatar = otherUser['user_img'];

                        final isMine = senderId == userId;
                        final preview = lastText.isEmpty
                            ? '…'
                            : (isMine ? 'You: $lastText' : lastText);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatar != null &&
                                    avatar.toString().isNotEmpty
                                ? NetworkImage(avatar)
                                : null,
                            backgroundColor: const Color(0xFFE8EEF9),
                            child: avatar == null
                                ? const Icon(Icons.person,
                                    color: Colors.black54)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            preview,
                            style: TextStyle(
                              fontWeight: isMine
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: createdAt != null
                              ? Text(
                                  "",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                )
                              : null,
                          onTap: () => context.push('/chat/$chatId'),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// Search user list
class _SearchUserList extends StatelessWidget {
  final String searchText;
  const _SearchUserList({super.key, required this.searchText});

  String _chatId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return sorted.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentEmail = currentUser.email ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['user_email'] == currentEmail) return false;
          final fullname =
              (data['user_fullname'] ?? '').toString().toLowerCase();
          final email = (data['user_email'] ?? '').toString().toLowerCase();
          final userId = (data['user_id'] ?? '').toString().toLowerCase();
          final code = (data['user_code'] ?? '').toString().toLowerCase();
          final q = searchText.toLowerCase();
          return fullname.contains(q) ||
              email.contains(q) ||
              userId.contains(q) ||
              code.contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            final rawOtherId = data['user_id'];
            if (rawOtherId == null || rawOtherId.toString().isEmpty) {
              return const SizedBox.shrink();
            }
            final otherId = rawOtherId.toString();
            final name = data['user_fullname'] ?? 'Unknown';
            final avatar = data['user_img'];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar != null &&
                        avatar.toString().isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                backgroundColor: const Color(0xFFE8EEF9),
                child: avatar == null
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
              ),
              title: Text(name),
              onTap: () async {
                final meSnap = await FirebaseFirestore.instance
                    .collection('user')
                    .where('user_email', isEqualTo: currentEmail)
                    .limit(1)
                    .get();
                if (meSnap.docs.isEmpty) return;
                final myId = meSnap.docs.first['user_id'].toString();
                if (myId.isEmpty || otherId.isEmpty) return;

                final cid = _chatId(myId, otherId);
                final chatRef =
                    FirebaseFirestore.instance.collection('chats').doc(cid);

                if (!(await chatRef.get()).exists) {
                  await chatRef.set({
                    'chats_id': cid,
                    'participants0': myId,
                    'participants1': otherId,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'last_message': '',
                  });
                }

                if (context.mounted) context.push('/chat/$cid');
              },
            );
          },
        );
      },
    );
  }
}

// Notifications tab
class _NotificationList extends StatelessWidget {
  const _NotificationList({
    super.key,
    required this.base,
    required this.service,
  });

  final String base;
  final NotificationService service;

  String _timeAgo(DateTime? created) {
    if (created == null) return 'Just now';
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'm ago';
    if (diff.inHours < 24) return 'h ago';
    return 'd ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationItem>>(
      stream: service.notificationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const _EmptyPlaceholder();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final item = items[index];
            return _NotificationTile(
              item: item,
              timeAgo: _timeAgo(item.createdAt),
              onTap: () async {
                await service.markAsRead(item.id);
                if (!context.mounted) return;
                if (item.postId != null && item.postId!.isNotEmpty) {
                  context.push('/forum/');
                }
              },
            );
          },
        );
      },
    );
  }
}

// Tab button
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.isActive,
    this.onTap,
  });

  final String text;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black87 : _inboxMuted;
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 90 : 0,
              decoration: BoxDecoration(
                color: _inboxPrimary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
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
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
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
                  color: _inboxPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                          isUnread ? FontWeight.w800 : FontWeight.w600,
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
                child: Icon(Icons.circle,
                    color: _inboxPrimary, size: 10),
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
          Icon(Icons.notifications_none_rounded,
              size: 80, color: _inboxMuted),
          SizedBox(height: 12),
          Text(
            "No notifications yet",
            style: TextStyle(
              color: _inboxMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

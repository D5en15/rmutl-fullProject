// lib/ui/common/messages_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchCtrl = TextEditingController();

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

  String _threadId(String uid1, String uid2) {
    final a = [uid1, uid2]..sort();
    return '${a[0]}_${a[1]}';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";

    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("กรุณาเข้าสู่ระบบ")),
      );
    }

    final bool isSearching = _searchCtrl.text.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) return true;
        context.go(base);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Messages',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go(base);
              }
            },
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Column(
          children: [
            // ---------- Tabs ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _TabButton(
                    text: 'notification',
                    isActive: false,
                    onTap: () => context.go('$base/notifications'),
                  ),
                  const SizedBox(width: 18),
                  _TabButton(
                    text: 'message',
                    isActive: true,
                    trailingDot: true,
                    onTap: () {}, // อยู่หน้า message แล้ว
                  ),
                ],
              ),
            ),

            // ---------- Search ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหารายชื่อ...',
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

            // ---------- List ----------
            Expanded(
              child: isSearching
                  // 🔍 ค้นหาผู้ใช้ทั้งหมด
                  ? StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return const Center(child: Text("ยังไม่มีผู้ใช้"));
                        }

                        final users =
                            snap.data!.docs.where((u) => u.id != currentUser.uid);
                        final filtered = users.where((u) {
                          final data = u.data() as Map<String, dynamic>;
                          final name =
                              data['displayName'] ?? data['email'] ?? '';
                          return name
                              .toLowerCase()
                              .contains(_searchCtrl.text.toLowerCase());
                        });

                        if (filtered.isEmpty) {
                          return const Center(child: Text("ไม่พบผู้ใช้"));
                        }

                        return ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final doc = filtered.elementAt(i);
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final uid = doc.id;
                            final name =
                                data['displayName'] ?? data['email'] ?? 'Unknown';
                            final avatar = data['avatar'];
                            final tid = _threadId(currentUser.uid, uid);

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFD9FFEE),
                                backgroundImage: avatar != null
                                    ? AssetImage('assets/avatars/$avatar')
                                    : null,
                                child: avatar == null
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: const Text("แตะเพื่อเริ่มแชท",
                                  style:
                                      TextStyle(color: Color(0xFF707070))),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/chat/$tid'),
                            );
                          },
                        );
                      },
                    )
                  // 📜 แสดงเฉพาะคนที่เคยแชท
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('participants',
                              arrayContains: currentUser.uid)
                          .snapshots(),
                      builder: (context, chatSnap) {
                        if (chatSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!chatSnap.hasData ||
                            chatSnap.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("ยังไม่มีการสนทนา"));
                        }

                        final chatDocs = chatSnap.data!.docs;

                        return ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: chatDocs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final chat = chatDocs[i];
                            final data =
                                chat.data() as Map<String, dynamic>;
                            final participants =
                                List<String>.from(data['participants'] ?? []);
                            if (participants.length < 2)
                              return const SizedBox();

                            final otherUid = participants.firstWhere(
                              (id) => id != currentUser.uid,
                              orElse: () => '',
                            );
                            if (otherUid.isEmpty) return const SizedBox();

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(otherUid)
                                  .get(),
                              builder: (context, userSnap) {
                                if (!userSnap.hasData ||
                                    !userSnap.data!.exists) {
                                  return const SizedBox();
                                }
                                final udata = userSnap.data!.data()
                                    as Map<String, dynamic>;
                                final name = udata['displayName'] ??
                                    udata['email'] ??
                                    'Unknown';
                                final avatar = udata['avatar'];

                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(chat.id)
                                      .collection('messages')
                                      .orderBy('createdAt',
                                          descending: true)
                                      .limit(1)
                                      .snapshots(),
                                  builder: (_, msgSnap) {
                                    String lastText = "ยังไม่มีข้อความ";
                                    String timeText = "";
                                    if (msgSnap.hasData &&
                                        msgSnap.data!.docs.isNotEmpty) {
                                      final last = msgSnap.data!.docs.first
                                          .data() as Map<String, dynamic>;
                                      lastText = last['text'] ?? '';
                                      final ts = last['createdAt'];
                                      if (ts is Timestamp) {
                                        timeText =
                                            _formatTime(ts.toDate());
                                      }
                                    }

                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor:
                                            const Color(0xFFD9FFEE),
                                        backgroundImage: avatar != null
                                            ? AssetImage(
                                                'assets/avatars/$avatar')
                                            : null,
                                        child: avatar == null
                                            ? const Icon(Icons.person,
                                                color: Colors.white)
                                            : null,
                                      ),
                                      title: Text(name,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w700)),
                                      subtitle: Text(
                                        lastText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Color(0xFF707070)),
                                      ),
                                      trailing: Text(
                                        timeText,
                                        style: const TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 12),
                                      ),
                                      onTap: () =>
                                          context.push('/chat/${chat.id}'),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.isActive,
    this.trailingDot = false,
    this.onTap,
  });

  final String text;
  final bool isActive;
  final bool trailingDot;
  final VoidCallback? onTap;

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black87 : _muted;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: color),
                ),
                if (trailingDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 90 : 0,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
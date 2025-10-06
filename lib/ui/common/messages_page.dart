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

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);

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
        body: Center(child: Text("กรุณาเข้าสู่ระบบ")),
      );
    }

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
          title: const Text("Messages",
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Column(
          children: [
            // 🔹 แถบเมนู
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    text: 'notification',
                    isActive: false,
                    onTap: () => context.go('$base/notifications'),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    text: 'message',
                    isActive: true,
                    onTap: () {},
                  ),
                ),
              ],
            ),

            // 🔍 ช่องค้นหา
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหาผู้ใช้...',
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
              child: _searchCtrl.text.trim().isEmpty
                  ? _RecentChatsList(currentEmail: user.email!)
                  : _SearchUserList(searchText: _searchCtrl.text.trim()),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ✅ แสดงเฉพาะคนที่เคยคุย (และต้องมีข้อความจริง ๆ)
//
class _RecentChatsList extends StatelessWidget {
  final String currentEmail;
  const _RecentChatsList({required this.currentEmail});

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
          return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
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
              return const Center(child: Text("ยังไม่มีการสนทนา"));
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, i) {
                final chat = chats[i].data() as Map<String, dynamic>;
                final chatId = chat['chats_id'];
                final otherId = chat['participants0'] == userId
                    ? chat['participants1']
                    : chat['participants0'];

                // ✅ ดึงข้อความล่าสุดของห้องนี้
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, msgSnap) {
                    if (!msgSnap.hasData ||
                        msgSnap.data!.docs.isEmpty) {
                      return const SizedBox.shrink(); // ❌ ไม่มีข้อความ ไม่แสดง
                    }

                    final msg = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
                    final lastText = msg['text'] ?? '';
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
                        if (!otherSnap.hasData ||
                            otherSnap.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final otherUser = otherSnap.data!.docs.first.data()
                            as Map<String, dynamic>;
                        final name = otherUser['user_fullname'] ?? 'Unknown';
                        final avatar = otherUser['user_img'];

                        // ✅ ตรวจสอบว่าใครส่งข้อความล่าสุด
                        final isMine = senderId == userId;

                        // ✅ ถ้าอีกฝั่งเป็นคนส่ง → ข้อความตัวหนา
                        final msgStyle = TextStyle(
                          fontWeight: isMine
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: Colors.black87,
                        );

                        // ✅ ถ้าอีกฝั่งเป็นคนส่ง → ขึ้นต้นด้วยชื่อ (สั้นๆ)
                        final displayText = isMine
                            ? lastText
                            : "${name.split(' ').first}: $lastText";

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
                            displayText,
                            style: msgStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: createdAt != null
                              ? Text(
                                  "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}",
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

//
// ✅ ค้นหาผู้ใช้ทั้งหมด
//
class _SearchUserList extends StatelessWidget {
  final String searchText;
  const _SearchUserList({required this.searchText});

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
          return fullname.contains(searchText.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("ไม่พบผู้ใช้"));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            final otherId = data['user_id'].toString();
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

//
// ✅ ปุ่ม Tab บนสุด
//
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.isActive,
    this.onTap,
  });

  final String text;
  final bool isActive;
  final VoidCallback? onTap;

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black87 : _muted;
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
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

  String _threadId(String id1, String id2) {
    final a = [id1, id2]..sort();
    return '${a[0]}_${a[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("กรุณาเข้าสู่ระบบ")));
    }

    return WillPopScope(
      // ✅ ถ้ากดปุ่มย้อนกลับ → กลับหน้า Home ของบทบาทนั้น
      onWillPop: () async {
        context.go(base);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Messages",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(base),
          ),
        ),
        body: Column(
          children: [
            // 🔍 Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหาด้วยชื่อจริง...',
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

            // 👥 รายชื่อผู้ใช้
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('user').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // filter: ไม่เอาตัวเอง + filter ตามชื่อ
                  final filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['user_email'] == currentUser.email) return false;
                    final fullname = (data['user_fullname'] ?? '').toString().toLowerCase();
                    return fullname.contains(_searchCtrl.text.toLowerCase());
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
                      final email = data['user_email'] ?? '';
                      final avatar = data['user_img'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(name),
                        subtitle: Text(email),
                        onTap: () async {
                          // 🔹 หา user_id ของตัวเอง
                          final meSnap = await FirebaseFirestore.instance
                              .collection('user')
                              .where('user_email', isEqualTo: currentUser.email)
                              .limit(1)
                              .get();
                          if (meSnap.docs.isEmpty) return;
                          final myId = meSnap.docs.first['user_id'].toString();

                          // 🔹 threadId = user_id1_user_id2
                          final tid = _threadId(myId, otherId);

                          // 🔹 ถ้ายังไม่มี chat → สร้างใหม่
                          final chatRef = FirebaseFirestore.instance.collection('chats').doc(tid);
                          if (!(await chatRef.get()).exists) {
                            await chatRef.set({
                              'participants': [myId, otherId],
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }

                          if (!mounted) return;
                          context.push('/chat/$tid');
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
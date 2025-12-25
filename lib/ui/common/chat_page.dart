import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatsId;
  const ChatPage({super.key, required this.chatsId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();

  static const _primary = Color(0xFF3D5CFF);
  static const _bubbleBg = Color(0xFFF4F6FF);

  String? _myUserId;
  String? otherUserName;
  String? otherUserImg;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mySnap = await FirebaseFirestore.instance
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (mySnap.docs.isEmpty) return;
    final myId = mySnap.docs.first['user_id'].toString();
    _myUserId = myId;

    final chat = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatsId)
        .get();

    if (!chat.exists) return;
    final chatData = chat.data()!;
    final otherId = chatData['participants0'] == myId
        ? chatData['participants1']
        : chatData['participants0'];

    final otherSnap = await FirebaseFirestore.instance
        .collection('user')
        .where('user_id', isEqualTo: otherId)
        .limit(1)
        .get();

    if (otherSnap.docs.isNotEmpty) {
      final u = otherSnap.docs.first.data();
      setState(() {
        otherUserName = u['user_fullname'] ?? 'Chat';
        otherUserImg = u['user_img'];
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ ฟังก์ชันส่งข้อความใหม่ (Hybrid timestamp)
  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_myUserId == null || _myUserId!.isEmpty) return;

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('user')
          .where('user_email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) return;
      final uData = userSnap.docs.first.data();
      final userId = uData['user_id'];
      final userName = uData['user_fullname'] ?? user.email ?? 'Unknown';

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatsId);

      // ✅ บันทึกข้อความด้วยเวลาท้องถิ่นทันที
      await chatRef.collection('messages').add({
        'chats_id': widget.chatsId,
        'user_id': userId,
        'user_name': userName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // 🕒 local timestamp
      });

      // ✅ อัปเดตข้อมูลห้อง (เวลา + ข้อความล่าสุด)
      await chatRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
        'last_message': text.trim(),
      });

      _controller.clear();
    } catch (e) {
      debugPrint('❌ Send message failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        otherUserName ?? 'Chat',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE8EEF9),
                    backgroundImage: (otherUserImg != null &&
                            otherUserImg!.trim().isNotEmpty)
                        ? NetworkImage(otherUserImg!)
                        : null,
                    child: (otherUserImg == null ||
                            otherUserImg!.trim().isEmpty)
                        ? const Icon(Icons.person, color: Colors.black54)
                        : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ---------- Message List ----------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatsId)
                    .collection('messages')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(child: Text("ยังไม่มีข้อความ"));
                  }

                  final docs = snap.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final text = data['text'] ?? '';
                      final senderId = data['user_id'];
                      final senderName = data['user_name'] ?? 'Unknown';
                      final time = (data['createdAt'] is Timestamp)
                          ? (data['createdAt'] as Timestamp).toDate()
                          : (data['createdAt'] as DateTime?);

                      final isMe =
                          senderId != null && senderId.toString() == _myUserId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: _Bubble(
                          left: !isMe,
                          label: senderName,
                          text: text,
                          time: time,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ---------- Input ----------
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _bubbleBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: _send,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _send(_controller.text),
                      icon: const Icon(Icons.send_rounded, color: _primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool left;
  final String label;
  final String text;
  final DateTime? time;

  const _Bubble({
    required this.left,
    required this.label,
    required this.text,
    this.time,
  });

  static const _primary = Color(0xFF3D5CFF);
  static const _bubbleBg = Color(0xFFF4F6FF);

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isMe = !left;
    final bg = isMe ? _primary : _bubbleBg;
    final fg = isMe ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (left)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .76,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: fg, fontSize: 14.5)),
                if (time != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(time),
                      style:
                          TextStyle(color: fg.withOpacity(0.7), fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.threadId});
  final String threadId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();

  static const _primary = Color(0xFF3D5CFF);
  static const _bubbleBg = Color(0xFFF4F6FF);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.threadId);

    // ✅ ดึง participants เดิมจาก chat
    final snap = await chatRef.get();
    List<dynamic> participants = [];
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      participants = List.from(data['participants'] ?? []);
    }

    // ✅ หา otherUid จาก chatId (split ด้วย "_")
    final ids = widget.threadId.split("_");
    String? otherUid;
    if (ids.length == 2) {
      otherUid = ids.firstWhere((id) => id != user.uid, orElse: () => user.uid);
    }

    // ✅ เพิ่ม currentUser + otherUid ลง participants
    final updatedParticipants = {
      user.uid,
      if (otherUid != null) otherUid,
      ...participants,
    }.toList();

    await chatRef.set({
      'participants': updatedParticipants,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ เพิ่ม message
    await chatRef.collection('messages').add({
      'text': text.trim(),
      'senderId': user.uid,
      'senderName': user.displayName ?? user.email ?? 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
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
            // ---------- AppBar ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Chat',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE8EEF9),
                    child: Icon(Icons.person, color: Colors.black54, size: 18),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Messages ----------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.threadId)
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
                      final isMe = data['senderId'] == user?.uid;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: _Bubble(
                          left: !isMe,
                          label: data['senderName'] ?? 'Unknown',
                          text: data['text'] ?? '',
                          time: (data['createdAt'] as Timestamp?)?.toDate(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ---------- Input Bar ----------
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
                      icon: const Icon(Icons.send_rounded,
                          color: Color(0xFF3D5CFF)),
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
  const _Bubble({
    required this.left,
    required this.label,
    required this.text,
    this.time,
  });

  final bool left;
  final String label;
  final String text;
  final DateTime? time;

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
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .76,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      style: TextStyle(color: fg.withOpacity(0.7), fontSize: 10),
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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  // mock messages
  final _messages = <_Msg>[
    const _Msg(left: true, name: 'Brooke', text: 'Hey Lucas!'),
    const _Msg(left: true, name: 'Brooke', text: "How's your project going?"),
    const _Msg(left: false, name: 'Lucas', text: "It's going well. Thanks for asking!"),
    const _Msg(left: true, name: 'Brooke', text: 'No worries. Let me know if you need any help 😊'),
    const _Msg(left: false, name: 'Lucas', text: "You're the best!"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  const Text('Brooke Davis',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  return Align(
                    alignment:
                        m.left ? Alignment.centerLeft : Alignment.centerRight,
                    child: _Bubble(
                      left: m.left,
                      label: m.name,
                      text: m.text,
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Color(0xFF3D5CFF)),
                    ),
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

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Msg(left: false, name: 'Me', text: text.trim()));
      _controller.clear();
    });
  }
}

class _Msg {
  final bool left;
  final String name;
  final String text;
  const _Msg({required this.left, required this.name, required this.text});
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.left, required this.label, required this.text});
  final bool left;
  final String label;
  final String text;

  static const _primary = Color(0xFF3D5CFF);
  static const _bubbleBg = Color(0xFFF4F6FF);

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
            child: Text(text, style: TextStyle(color: fg, fontSize: 14.5)),
          ),
        ],
      ),
    );
  }
}

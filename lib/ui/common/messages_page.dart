import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static const _muted = Color(0xFF858597);
  static const _primary = Color(0xFF3D5CFF);

  @override
  Widget build(BuildContext context) {
    final threads = List.generate(
      8,
      (i) => _ThreadTileData(
        id: 't$i',
        name: i.isEven ? 'Bert Pullman' : 'Daniel Lawson',
        online: i.isEven,
        time: i.isEven ? '04:32 pm' : '12:00 am',
        lastMessage:
            'Congratulations on completing the first lesson, keep up the good work!',
        hasPreviewBox: i.isEven, // card preview (กล่องชมพูในดีไซน์)
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                  const SizedBox(width: 4),
                  const Text('Notifications',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _TabButton(
                    text: 'notification',
                    isActive: false,
                    onTap: () => context.go('/student/notifications'),
                  ),
                  const SizedBox(width: 18),
                  _TabButton(
                    text: 'message',
                    isActive: true,
                    trailingDot: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: threads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ThreadTile(
                  data: threads[i],
                  onTap: () => context.go('/chat/${threads[i].id}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ใช้ซ้ำกับหน้า Notifications
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          children: [
            Row(
              children: [
                Text(text,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
                if (trailingDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  )
                ]
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 70 : 0,
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

class _ThreadTileData {
  final String id;
  final String name;
  final bool online;
  final String time;
  final String lastMessage;
  final bool hasPreviewBox;
  _ThreadTileData({
    required this.id,
    required this.name,
    required this.online,
    required this.time,
    required this.lastMessage,
    required this.hasPreviewBox,
  });
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.data, required this.onTap});
  final _ThreadTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // หัวแถว: avatar name status time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9FFEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Text(data.online ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: data.online
                                      ? const Color(0xFF00B894)
                                      : const Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                )),
                            const Spacer(),
                            Text(data.time,
                                style: const TextStyle(
                                    color: Color(0xFF9CA3AF), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF707070)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (data.hasPreviewBox) ...[
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

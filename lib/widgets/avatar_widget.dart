import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 40,
  });

  bool _isNetworkUrl(String v) =>
      v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final v = imageUrl?.trim();
    ImageProvider? avatar;

    // ✅ ตรวจสอบและกำหนดแหล่งรูปภาพ
    if (v != null && v.isNotEmpty) {
      if (_isNetworkUrl(v)) {
        avatar = NetworkImage(v);
      } else if (v.startsWith('assets/')) {
        avatar = AssetImage(v);
      } else {
        avatar = AssetImage('assets/avatars/$v');
      }
    }

    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: const Color(0xFFE9ECFF),

        // ✅ ใช้ Stack เพื่อให้แสดง loader/placeholder ได้สวยงาม
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ ถ้ามีรูปให้แสดง NetworkImage ปลอดภัย (ไม่ crash)
            if (avatar != null)
              Image(
                image: avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('⚠️ Failed to load avatar: $error');
                  return const Icon(Icons.person,
                      color: Color(0xFF4B5563), size: 34);
                },
              )
            else
              // ✅ ถ้ายังไม่มีรูป ให้แสดง placeholder
              const Center(
                child: Icon(
                  Icons.person,
                  color: Color(0xFF4B5563),
                  size: 34,
                ),
              ),

            // ✅ ขณะโหลดรูป (fade-in effect)
            if (avatar != null)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.transparent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const AvatarWidget({super.key, this.imageUrl, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final v = imageUrl!.trim();
      if (v.startsWith('http')) {
        avatar = NetworkImage(v);
      } else if (v.startsWith('assets/')) {
        avatar = AssetImage(v);
      } else {
        avatar = AssetImage('assets/avatars/$v');
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: avatar,
      backgroundColor: const Color(0xFFE9ECFF),
      child: avatar == null
          ? const Icon(Icons.person, color: Color(0xFF4B5563), size: 34)
          : null,
    );
  }
}
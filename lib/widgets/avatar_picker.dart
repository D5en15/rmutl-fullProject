// lib/widgets/avatar_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatefulWidget {
  final String? imageUrl;
  final Function(File file)? onImageSelected;

  const AvatarPicker({
    super.key,
    this.imageUrl,
    this.onImageSelected,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _imageProvider = NetworkImage(widget.imageUrl!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _imageProvider = FileImage(file));
      widget.onImageSelected?.call(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundImage: _imageProvider,
          backgroundColor: const Color(0xFFE9ECFF),
          child: _imageProvider == null
              ? const Icon(Icons.person, size: 36, color: Color(0xFF4B5563))
              : null,
        ),
        InkWell(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, size: 18, color: Color(0xFF3D5CFF)),
          ),
        ),
      ],
    );
  }
}
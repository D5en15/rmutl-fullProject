import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function()? onSubmitted;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.readOnly = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🟦 Label อยู่ด้านบนเหมือนเดิม
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),

        // 🟩 ช่องกรอกข้อมูล
        TextFormField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3D5CFF), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
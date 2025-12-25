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
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

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
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    OutlineInputBorder buildBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: color, width: width),
        );

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
          focusNode: focusNode,
          obscureText: obscure,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            border: buildBorder(const Color(0xFFE0E0E0)),
            enabledBorder: buildBorder(const Color(0xFFE0E0E0)),
            focusedBorder: buildBorder(const Color(0xFF3D5CFF), 1.5),
            errorBorder: buildBorder(Colors.red.shade400),
            focusedErrorBorder: buildBorder(Colors.red.shade400, 1.5),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

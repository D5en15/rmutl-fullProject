import 'package:flutter/material.dart';

class OtpButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  const OtpButton({
    super.key,
    required this.text,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3D5CFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3D5CFF),
                ),
              )
            : Text(text,
                style: const TextStyle(
                    color: Color(0xFF3D5CFF), fontSize: 14)),
      ),
    );
  }
}
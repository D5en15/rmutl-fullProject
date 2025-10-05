import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onPressed;
  final Color color;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
    this.color = const Color(0xFF3D5CFF),
    this.height = 50,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
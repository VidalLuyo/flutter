import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;           // Texto que aparecerá en el botón
  final VoidCallback onPressed; // Acción al presionar

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

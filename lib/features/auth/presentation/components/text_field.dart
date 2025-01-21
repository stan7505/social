import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback? toggleVisibility;
  final IconData? icon;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.toggleVisibility,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[100]!.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8)),
              ),
            ),
          ),
          if (toggleVisibility != null)
            GestureDetector(
              onTap: toggleVisibility,
              child:
                  Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            ),
          const SizedBox(width: 13),
        ],
      ),
    );
  }
}

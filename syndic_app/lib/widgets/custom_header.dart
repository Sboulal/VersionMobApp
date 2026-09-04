import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed; // 🟢 ضرورية باش نبدلو الوجهة ديال السهم

  const CustomHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = true,
    this.onBackPressed, // 🟢 كنزيدوها هنا
  });

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          if (showBackButton) 
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (onBackPressed != null) {
                  onBackPressed!(); // 🟢 يلا عطيناه مسار فـ الصفحة، غيمشي ليه
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context); // 🟢 الحالة العادية
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showBackButton) const SizedBox(width: 8),

          const Icon(Icons.apartment, color: Colors.black87, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(color: mainBlue, fontWeight: FontWeight.bold, fontSize: 18)
                ),
                Text(
                  subtitle, 
                  style: const TextStyle(color: Colors.black54, fontSize: 12)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
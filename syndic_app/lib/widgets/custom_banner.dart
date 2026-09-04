import 'package:flutter/material.dart';

class CustomBanner extends StatelessWidget {
  final String residenceName;
  final bool showBackButton;

  const CustomBanner({
    super.key,
    required this.residenceName,
    this.showBackButton = true, // Par défaut kayn l'flèche dyal retour
  });

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF1A5EAC);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: mainBlue,
        image: DecorationImage(
          image: const NetworkImage("https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop"), 
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(mainBlue.withOpacity(0.85), BlendMode.srcOver),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8, // chwia d l'espace lfo9
        bottom: 16, 
        left: showBackButton ? 4 : 16, // ila kant l'flèche n9so l'padding
        right: 16
      ), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 🟢 L'flèche dyal retour kiban ghir ila kant showBackButton = true
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Katrje3 l'page li 9bel
                    }
                  },
                ),
              if (!showBackButton) const SizedBox(width: 8), // espace ila makanch l'flèche
              
              const Icon(Icons.apartment, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                "Sindy | $residenceName",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.notifications_none, color: Colors.white, size: 26),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
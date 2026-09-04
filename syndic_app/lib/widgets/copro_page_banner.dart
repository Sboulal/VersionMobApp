import 'package:flutter/material.dart';

/// Bannière commune à toutes les pages copropriétaire.
///
/// Le gabarit est fixe (150 px), utilise la même image que la page Charges
/// et garde exactement les mêmes espacements sur toutes les pages.
class CoproPageBanner extends StatelessWidget {
  final String residenceName;
  final String title;
  final String? subtitle;
  final String? photoUrl;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CoproPageBanner({
    super.key,
    required this.residenceName,
    required this.title,
    this.subtitle,
    this.photoUrl,
    this.showBackButton = false,
    this.onBackPressed,
  });

  static const double height = 150.0;

  static const String bannerImage =
      'https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop';

  static const String defaultAvatar =
      'https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A5EAC),
          image: DecorationImage(
            image: NetworkImage(bannerImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0xD91A5EAC),
              BlendMode.srcOver,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackButton) ...[
                  GestureDetector(
                    onTap: onBackPressed ?? () => Navigator.maybePop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],

                const Icon(
                  Icons.apartment,
                  color: Colors.white,
                  size: 24,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Sindy | $residenceName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 26,
                ),

                const SizedBox(width: 12),

                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : const NetworkImage(defaultAvatar),
                  ),
                ),
              ],
            ),

            const Spacer(),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),

            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

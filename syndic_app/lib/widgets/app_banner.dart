import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/profile_page.dart';
import 'package:syndic_app/pages/forgot_password_page.dart';
import 'package:syndic_app/pages/notifications_page.dart';

class AppBanner extends StatelessWidget {
  final String firstName;
  final String residenceName;
  final String lotInfo;
  final String? photoUrl;

  final bool showNotifications;
  final VoidCallback? onNotificationTap;

  const AppBanner({
    super.key,
    required this.firstName,
    required this.residenceName,
    required this.lotInfo,
    this.photoUrl,
    this.showNotifications = true,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF1A5EAC);

    final String imageUrl =
        (photoUrl ?? '').trim();

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: mainBlue,

        image: const DecorationImage(
          image: NetworkImage(
            "https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop",
          ),
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

          // ======================================================
          // TOP ROW
          // ======================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const Icon(
                Icons.apartment,
                color: Colors.white,
                size: 24,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  "Sindy | $residenceName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ==================================================
              // NOTIFICATIONS
              // ==================================================

              if (showNotifications) ...[
                const SizedBox(width: 8),

                InkWell(
                  borderRadius: BorderRadius.circular(30),

                  onTap: onNotificationTap ??
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsPage(),
                          ),
                        );
                      },

                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),
              ],

              // ==================================================
              // USER DROPDOWN
              // ==================================================

              PopupMenuButton<String>(
                offset: const Offset(0, 50),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                color: Colors.white,
                elevation: 4,

                onSelected: (value) async {

                  // PROFILE
                  if (value == 'profile') {

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UnifiedProfilePage(),
                      ),
                    );

                    // الصفحة اللي مستعملة AppBanner
                    // تقدر تدير refresh للبيانات من برا
                  }

                  // PASSWORD
                  else if (value == 'password') {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ForgotPasswordPage(),
                      ),
                    );
                  }

                  // LOGOUT
                  else if (value == 'logout') {

                    final prefs =
                        await SharedPreferences.getInstance();

                    await prefs.remove('auth_token');

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },

                itemBuilder: (_) => [

                  _buildPopupItem(
                    'profile',
                    Icons.person_outline,
                    'Profil',
                  ),

                  _buildPopupItem(
                    'password',
                    Icons.lock_outline,
                    'Changer mot de passe',
                  ),

                  const PopupMenuDivider(),

                  _buildPopupItem(
                    'logout',
                    Icons.logout,
                    'Déconnexion',
                    destructive: true,
                  ),
                ],

                // ==================================================
                // AVATAR
                // ==================================================

                child: Container(
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

                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : const NetworkImage(
                            "https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true",
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // GREETING
          // ======================================================

          Text(
            "Bonjour, $firstName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            "$residenceName • $lotInfo",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // POPUP ITEM
  // ==============================================================

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text, {
    bool destructive = false,
  }) {
    final color =
        destructive ? Colors.redAccent : const Color(0xFF1A5EAC);

    return PopupMenuItem<String>(
      value: value,

      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(width: 12),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
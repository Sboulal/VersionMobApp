import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/main_layout.dart';
import 'package:syndic_app/services/syndic_auth_service.dart';
import 'package:syndic_app/pages/copro_annonces_page.dart';
import 'package:syndic_app/pages/copro_main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/landing_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UnifiedProfilePage extends StatefulWidget {
  final bool isMainScreen;
  const UnifiedProfilePage({super.key, this.isMainScreen = true});

  @override
  State<UnifiedProfilePage> createState() => _UnifiedProfilePageState();
}

class _UnifiedProfilePageState extends State<UnifiedProfilePage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);
  final Color redColor = const Color(0xFFD32F2F);

  final SyndicAuthService _authService = SyndicAuthService();
  final ImagePicker _picker = ImagePicker();

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profil;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: mainBlue, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    );
  }
  Future<void> _loadProfil() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _authService.getProfil();
      
      // Mettre à jour le Cache si l'API renvoie une photo
      final photo = data['photo_url'] ?? data['photo'];
      if (photo != null && photo.isNotEmpty) {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('photo_url', photo);
      }

      setState(() {
        _profil = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, 
        maxWidth: 800,  
        maxHeight: 800, 
      );
      
      if (pickedFile == null) return; 

      setState(() {
        _imageFile = File(pickedFile.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Envoi de la photo en cours..."), duration: Duration(seconds: 2)),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final role = _profil?['role'] == 'syndic' ? 'syndic' : 'copro';
      final url = Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/$role/profil/photo"); 

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.files.add(
        await http.MultipartFile.fromPath('photo', _imageFile!.path)
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      try {
        var data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          
          if (data['photo_url'] != null) {
             await prefs.setString('photo_url', data['photo_url']);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Photo mise à jour avec succès !"), backgroundColor: Colors.green),
            );
            _loadProfil(); 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? "Erreur d'enregistrement."), backgroundColor: Colors.orange),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          String serverResponse = response.body;
          if (serverResponse.length > 50) {
            serverResponse = serverResponse.substring(0, 50) + "..."; 
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur Serveur ${response.statusCode} : $serverResponse"), 
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur système : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  
 Future<void> _handleLogout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('photo_url');
    await prefs.remove('auth_token'); 

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSyndic = _profil?['role'] == 'syndic';

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        leading: widget.isMainScreen 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // 🟢 HNA SALA7NA L'NAVIGATION BACH TRJE3 L'NFS L'ESPACE MNIN JAT
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isSyndic ? const MainLayout() : const CoproMainLayout(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            )
          : null,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(_errorMessage!, style: TextStyle(color: redColor)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProfil,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildProfileHeader(isSyndic),
                          SizedBox(height: 24),

                          _buildStatsCards(),
                          SizedBox(height: 24),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Settings",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          _buildSettingTile(
                            icon: Icons.person_outline,
                            title: "Mes informations",
                            subtitle: "Modifier mon nom et téléphone",
                            onTap: _showEditProfileDialog,
                          ),
                          SizedBox(height: 12),

                          _buildSettingTile(
                            icon: Icons.lock_outline,
                            title: "Mot de passe",
                            subtitle: "Changer mon mot de passe",
                            onTap: _showChangePasswordDialog,
                          ),
                          SizedBox(height: 12),

                          _buildSettingTile(
                            icon: Icons.campaign_outlined,
                            title: "Dernières annonces",
                            subtitle: "Voir les nouveautés",
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CoproAnnoncesPage(showBackButton: true)),
                            ),
                          ),
                          SizedBox(height: 12),

                          _buildSettingTile(
                            icon: Icons.notifications_none,
                            title: "Notifications",
                            subtitle: "Alertes et rappels",
                            trailing: Switch(
                              value: _notificationsEnabled,
                              activeColor: Colors.white,
                              activeTrackColor: mainBlue,
                              onChanged: (val) => setState(() => _notificationsEnabled = val),
                            ),
                            onTap: () {},
                          ),
                            SizedBox(height: 12),
                            _buildSettingTile(
                              icon: Icons.person_remove_alt_1_outlined,
                              title: "Supprimer mon compte",
                              subtitle: "Suppression de vos données",
                              iconColor: redColor,
                              onTap: () => _supprimerCompte(context),
                            ),
                            SizedBox(height: 12),

                          _buildSettingTile(
                            icon: Icons.logout,
                            title: "Se déconnecter",
                            subtitle: "Quitter l'application",
                            iconColor: redColor,
                            onTap: _handleLogout,
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // --- WIDGETS ---

  // --- WIDGETS ---

  Widget _buildProfileHeader(bool isSyndic) {
    final String? photoUrl = _profil?['photo_url'] ?? _profil?['photo'];

    // 🟢 N-7eddo l-ImageProvider 9bel bash n-t7ekmo fiha mzyan w n-tfadaw l-crash
    ImageProvider? bgImage;
    if (_imageFile != null) {
      bgImage = FileImage(_imageFile!);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      bgImage = NetworkImage(photoUrl);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: mainBlue.withOpacity(0.1),
              backgroundImage: bgImage,
              
              // 🟢 L-FIX HNA: Ila kant bgImage null, ta onBackgroundImageError khassha tkon null
              onBackgroundImageError: bgImage != null
                  ? (error, stackTrace) {
                      debugPrint("Erreur image (ancien lien ignoré)");
                    }
                  : null,
                  
              child: bgImage == null
                  ? Icon(isSyndic ? Icons.manage_accounts : Icons.person, color: mainBlue, size: 50)
                  : null,
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Icon(Icons.camera_alt, color: mainBlue, size: 20),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          _profil?['nom'] ?? 'Utilisateur',
          style:  TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        SizedBox(height: 4),
        Text(
          _profil?['email'] ?? '',
          style:  TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(isSyndic ? "Syndic" : "Copropriétaire", mainBlue),
            SizedBox(width: 8),
            _buildBadge(
              isSyndic ? (_profil?['copropriete'] ?? 'N/A') : (_profil?['lot'] ?? 'N/A'),
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildStatCard(
          "Solde", 
          _profil?['solde_formate']?.replaceAll(' MAD', '') ?? "0", 
          mainBlue
        ),
        SizedBox(width: 12.w),
        _buildStatCard(
          "Prochaine", 
          _profil?['prochaine_charge'] ?? "-", 
          Colors.orange
        ),
        SizedBox(width: 12.w),
        _buildStatCard(
          "Impayé", 
          _profil?['dernier_impaye'] ?? "-", 
          redColor
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final effectiveColor = iconColor ?? mainBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

Future<void> _supprimerCompte(BuildContext context) async {
  bool? confirmer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Supprimer le compte"),
      content: const Text(
        "Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et vos données personnelles ne seront plus accessibles.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirmer != true) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/account/delete"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await prefs.clear();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (route) => false,
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Erreur lors de la suppression"), backgroundColor: Colors.red),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau : $e"), backgroundColor: Colors.red),
      );
    }
  }
}

  Future<void> _showChangePasswordDialog() async {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
              contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 8),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 20, left: 20),
              title: const Text(
                "Modifier mon mot de passe",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ancienCtrl,
                    obscureText: true,
                    decoration: _customInputDecoration("Ancien mot de passe"),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: nouveauCtrl,
                    obscureText: true,
                    decoration: _customInputDecoration("Nouveau mot de passe"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (ancienCtrl.text.isEmpty || nouveauCtrl.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Le nouveau mot de passe doit contenir au moins 6 caractères.")),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _authService.updatePassword(
                              ancienPassword: ancienCtrl.text,
                              nouveauPassword: nouveauCtrl.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Mot de passe mis à jour avec succès.")),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Valider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

 Future<void> _showEditProfileDialog() async {
    final nomCtrl = TextEditingController(text: _profil?['nom'] ?? '');
    final telCtrl = TextEditingController(text: _profil?['telephone'] ?? '');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent, // Enlève l'effet Material 3
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
              contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 8),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 20, left: 20),
              title: const Text(
                "Modifier mes informations",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomCtrl,
                    decoration: _customInputDecoration("Nom complet"),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _customInputDecoration("Téléphone"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nomCtrl.text.trim().isEmpty) return;
                          
                          setDialogState(() => isSubmitting = true);
                          
                          try {
                            setState(() {
                              _profil?['nom'] = nomCtrl.text;
                              _profil?['telephone'] = telCtrl.text;
                            });

                            if (ctx.mounted) Navigator.pop(ctx);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Informations mises à jour avec succès.")),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Valider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/widgets/custom_header.dart';
import 'package:syndic_app/pages/main_layout.dart';
import 'package:syndic_app/services/syndic_auth_service.dart';

import 'package:syndic_app/pages/annonces_page.dart';
import 'package:syndic_app/pages/copro_main_layout.dart';

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

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profil;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _authService.getProfil();
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

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Modifier mon mot de passe"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ancienCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Ancien mot de passe"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nouveauCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
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
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Valider", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSyndic = _profil?['role'] == 'syndic';

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfil,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(
                  title: "Sindy",
                  subtitle: isSyndic ? "Espace Syndic\nMon Profil" : "Résidence Les Jardins\nMon Profil",
                  showBackButton: true,
                  onBackPressed: widget.isMainScreen
                      ? () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => isSyndic 
                                  ? const MainLayout() 
                                  : const CoproMainLayout(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_errorMessage!, style: TextStyle(color: redColor, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _loadProfil, child: const Text("Réessayer")),
                      ],
                    ),
                  )
                else ...[
                  // بطاقة الهوية
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: mainBlue.withOpacity(0.1),
                          child: Icon(isSyndic ? Icons.manage_accounts : Icons.person, color: mainBlue, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profil?['nom'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSyndic ? "Syndic de copropriété" : "Copropriétaire",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mainBlue),
                              ),
                              const SizedBox(height: 2),
                              Text(_profil?['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              Text(_profil?['telephone'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // تفاصيل الوحدة أو الإقامة (🟢 L'ERREUR KANT HNA WA T7ELLAT)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(isSyndic ? Icons.apartment : Icons.door_front_door, color: Colors.black54, size: 20),
                        const SizedBox(width: 12),
                        // 🟢 EXPANDED zednaha hna bach mayb9ach l'overflow
                        Expanded(
                          child: Text(
                            isSyndic 
                                ? "Copropriété : ${_profil?['copropriete'] ?? 'N/A'}"
                                : "Lot / Appartement : ${_profil?['lot'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildActionButton(Icons.edit, "Modifier mes informations", mainBlue, _showEditProfileDialog),
                  const SizedBox(height: 12),

                  _buildActionButton(Icons.lock, "Modifier mon mot de passe", mainBlue, _showChangePasswordDialog),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: mainBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.notifications, color: Colors.white, size: 20),
                            ),
                            Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.blue.shade300,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActionButton(Icons.logout, "Se déconnecter", redColor, _handleLogout),
                  const SizedBox(height: 24),

                  // البطاقة المالية و الإعلانات
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          "Solde", 
                          _profil?['solde_formate'] ?? "0 MAD", 
                          isAmount: true, 
                          amountValue: _profil?['solde_brut']
                        ),
                        const Divider(height: 30, color: Color(0xFFEEEEEE)),
                        _buildInfoRow("Prochaine charge", _profil?['prochaine_charge'] ?? "N/A"),
                        const Divider(height: 30, color: Color(0xFFEEEEEE)),
                        _buildInfoRow("Dernier impayé", _profil?['dernier_impaye'] ?? "Aucun"),
                        const Divider(height: 30, color: Color(0xFFEEEEEE)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnoncesPage()));
                          },
                          child: Container(
                            color: Colors.transparent, 
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text("Dernières annonces", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isAmount = false, dynamic amountValue}) {
    Color valueColor = Colors.black87;
    if (isAmount && amountValue != null) {
      double val = double.tryParse(amountValue.toString()) ?? 0;
      valueColor = val < 0 ? redColor : Colors.black87; 
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
        ),
        icon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Modifier mes informations"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(labelText: "Nom complet"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Téléphone"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
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
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Valider", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
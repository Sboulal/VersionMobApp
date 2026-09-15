import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/models/NotificationModel.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showBackButton;
  final String role;
  const NotificationsScreen({super.key, required this.role, this.showBackButton = false});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // 🟢 1. Récupération des notifications avec le VRAI token
  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      // 🟢 L'URL change automatiquement selon le rôle !
      final url = "https://api.syndify.nomade-cloud.com/api/mobile/${widget.role}/notifications";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> notifsJson = data['data'];
        setState(() {
          notifications = notifsJson.map((json) => NotificationModel.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Erreur chargement notifications: $e");
      setState(() => isLoading = false);
    }
  }

  // 🟢 2. Marquer comme lu avec le VRAI token
  Future<void> _marquerCommeLu(NotificationModel notif) async {
    if (notif.lu) return; // Si c'est déjà lu, on ne fait rien

    // On met à jour l'UI instantanément pour que ça soit fluide
    setState(() {
      notif.lu = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/notifications/${notif.id}/lu"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
    } catch (e) {
      print("Erreur marquer lu: $e");
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'charge': return Icons.receipt_long;
      case 'paiement': return Icons.check_circle;
      case 'annonce': return Icons.campaign;
      case 'document': return Icons.description;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'charge': return Colors.redAccent;
      case 'paiement': return Colors.green;
      case 'annonce': return Colors.orange;
      case 'document': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5EAC)))
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "Aucune notification pour le moment.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF1A5EAC),
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(notif.type).withOpacity(0.1),
                          child: Icon(
                            _getIconForType(notif.type),
                            color: _getColorForType(notif.type),
                          ),
                        ),
                        title: Text(
                          notif.titre,
                          style: TextStyle(
                            fontWeight: notif.lu ? FontWeight.normal : FontWeight.bold,
                            color: notif.lu ? Colors.grey[700] : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(notif.message),
                            const SizedBox(height: 4),
                            Text(
                              notif.dateHumaine,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () => _marquerCommeLu(notif),
                      );
                    },
                  ),
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/notifications"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _notifications = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Config dyal l'icon w loun 3la hssab l'type
  Map<String, dynamic> _getIconConfig(String type) {
    switch (type.toLowerCase()) {
      case 'charge':
        return {'icon': Icons.account_balance_wallet, 'color': Colors.red.shade400, 'bg': Colors.red.shade50};
      case 'paiement':
        return {'icon': Icons.check_circle, 'color': Colors.green.shade500, 'bg': Colors.green.shade50};
      case 'annonce':
        return {'icon': Icons.campaign, 'color': Colors.orange.shade500, 'bg': Colors.orange.shade50};
      case 'document':
        return {'icon': Icons.description, 'color': mainBlue, 'bg': mainBlue.withOpacity(0.1)};
      default:
        return {'icon': Icons.notifications, 'color': Colors.blueGrey, 'bg': Colors.blueGrey.shade50};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainBlue))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final config = _getIconConfig(notif['type']);
                    final bool isRead = notif['is_read'] ?? true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : Colors.blue.shade50.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: config['bg'],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(config['icon'], color: config['color'], size: 24),
                        ),
                        title: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['message'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif['date'] ?? '',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 60, color: Colors.blueGrey.shade200),
          const SizedBox(height: 16),
          Text(
            "Aucune notification",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            "Vous êtes à jour !",
            style: TextStyle(color: Colors.blueGrey.shade300),
          ),
        ],
      ),
    );
  }
}
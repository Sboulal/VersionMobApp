import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CoproAnnoncesPage extends StatefulWidget {
  const CoproAnnoncesPage({super.key});

  @override
  State<CoproAnnoncesPage> createState() => _CoproAnnoncesPageState();
}

class _CoproAnnoncesPageState extends State<CoproAnnoncesPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _annoncesList = [];
  List<String> _readAnnoncesIds = [];
  final String _residenceName = "Résidence Les Palmiers";

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
    _fetchAnnonces();
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readAnnoncesIds = prefs.getStringList('read_annonces') ?? [];
    });
  }

  Future<void> _markAsRead(String id) async {
    if (!_readAnnoncesIds.contains(id)) {
      setState(() => _readAnnoncesIds.add(id));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_annonces', _readAnnoncesIds);
    }
  }

  Future<void> _fetchAnnonces() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(
            "https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-annonces"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _annoncesList = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hexString) {
    var hexColor = hexString.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse("0x$hexColor"));
  }

  IconData _getIcon(String iconStr) {
    switch (iconStr) {
      case 'build':
        return Icons.build_circle;
      case 'warning':
        return Icons.warning;
      case 'groups':
        return Icons.groups;
      case 'info':
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // ======================================================
          // BACKGROUND SKYLINE
          // ======================================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCitySkyline(),
          ),

          // ======================================================
          // CONTENT
          // ======================================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNIÈRE COMME LE DASHBOARD
              _buildBanner(context),

              // RESTE DU CONTENU
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: mainBlue),
                      )
                    : _buildContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BANNER EXACTEMENT COMME DASHBOARD
  // ==========================================================
  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: mainBlue,
        image: DecorationImage(
          image: const NetworkImage(
            "https://images.unsplash.com/photo-1460317442991-0ec209397118?q=80&w=2070&auto=format&fit=crop",
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            mainBlue.withOpacity(0.85),
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
              const Icon(Icons.apartment, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Sindy | $_residenceName",
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
              const Icon(Icons.notifications_none, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(
                    "https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Tableau d'affichage",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "Actualités de votre copropriété",
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

  // ==========================================================
  // CONTENU DE LA PAGE
  // ==========================================================
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            "Dernières annonces",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ),
        Expanded(
          child: _annoncesList.isEmpty
              ? Center(
                  child: Text(
                    "Aucune annonce pour le moment.",
                    style: TextStyle(color: Colors.blueGrey.shade400),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: _annoncesList.length,
                  itemBuilder: (context, index) {
                    final ann = _annoncesList[index];
                    final String idStr = ann['id'].toString();
                    final bool isRead = _readAnnoncesIds.contains(idStr);
                    final aColor = _hexToColor(ann['colorHex']);

                    return GestureDetector(
                      onTap: () => _markAsRead(idStr),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.white.withOpacity(0.8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? Colors.grey.shade200
                                : aColor.withOpacity(0.3),
                          ),
                          boxShadow: isRead
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? Colors.grey.shade100
                                    : aColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIcon(ann['iconString']),
                                color: isRead ? Colors.grey : aColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ann["title"],
                                          style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                            fontSize: 15,
                                            color: isRead
                                                ? Colors.black54
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "Nouveau",
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${ann["category"]} • ${ann["date"]}",
                                    style: TextStyle(
                                      color: isRead ? Colors.grey : aColor,
                                      fontSize: 12,
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    ann["message"],
                                    style: TextStyle(
                                      color: isRead
                                          ? Colors.grey
                                          : Colors.black87,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================================
  // CITY SKYLINE
  // ==========================================================
  Widget _buildCitySkyline() {
    final color = mainBlue.withOpacity(0.03);
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBuilding(50, 120, color),
          _buildBuilding(65, 180, color),
          _buildBuilding(45, 140, color),
          _buildBuilding(75, 210, color),
          _buildBuilding(60, 160, color),
          _buildBuilding(50, 100, color),
        ],
      ),
    );
  }

  Widget _buildBuilding(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
            (height / 25).floor(),
            (index) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        width: 8,
                        height: 10,
                        color: Colors.white.withOpacity(0.4)),
                    Container(
                        width: 8,
                        height: 10,
                        color: Colors.white.withOpacity(0.4)),
                    if (width > 55)
                      Container(
                          width: 8,
                          height: 10,
                          color: Colors.white.withOpacity(0.4)),
                  ],
                )),
      ),
    );
  }
}
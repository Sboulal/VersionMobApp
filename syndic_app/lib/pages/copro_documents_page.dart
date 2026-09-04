import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CoproDocumentsPage extends StatefulWidget {
  const CoproDocumentsPage({super.key});

  @override
  State<CoproDocumentsPage> createState() => _CoproDocumentsPageState();
}

class _CoproDocumentsPageState extends State<CoproDocumentsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _groupedDocuments = [];
  final String _residenceName = "Résidence Les Palmiers"; 

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/copro/mes-documents"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _groupedDocuments = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // --- BACKGROUND WATERMARK (العمارات فـ اللور) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCitySkyline(),
          ),

          // --- CONTENU PRINCIPAL ---
          // ❌ SafeArea retiré ici
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
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
                  top: MediaQuery.of(context).padding.top + 16, 
                  bottom: 16, 
                  left: 16, 
                  right: 16
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.apartment, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    
                    // 🟢 Correction : Expanded + Ellipsis pour éviter que ça se compresse
                    Expanded(
                      child: Text(
                        "Sindy | $_residenceName", 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                        backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=Copro&background=ffffff&color=1A5EAC&size=128&bold=true"),
                      ),
                    ),
                  ],
                ),
              ),
              // 2. Titre de la page
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 12.0),
                child: Text(
                  "Documents",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                ),
              ),

              // 3. Arborescence des dossiers et fichiers
              Expanded(
                child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : _groupedDocuments.isEmpty
                    ? Center(child: Text("Aucun document disponible.", style: TextStyle(color: Colors.blueGrey.shade400)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _groupedDocuments.length,
                        itemBuilder: (context, index) {
                          final group = _groupedDocuments[index];
                          final files = group['files'] as List;

                          return Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              iconColor: mainBlue,
                              collapsedIconColor: Colors.blueGrey,
                              leading: Icon(Icons.folder_open_rounded, color: Colors.amber.shade600, size: 28),
                              title: Text(
                                group['category'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              children: files.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 56.0, bottom: 12.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Dossier vide", style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
                                        ),
                                      )
                                    ]
                                  : files.map((file) => Container(
                                      margin: const EdgeInsets.only(left: 24.0, right: 8.0, bottom: 12.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade100),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                            child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(file['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                                                const SizedBox(height: 4),
                                                Text("${file['date']} • ${file['size']}", style: const TextStyle(color: Colors.black54, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility, color: Colors.black54, size: 20),
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ouverture du document...")));
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.file_download, color: Colors.black54, size: 20),
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Téléchargement en cours...")));
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                            ),
                          );
                        },
                      ),
              ),

              // 4. Bouton bas
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.transparent, 
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: mainBlue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cloud_download, size: 20),
                    label: const Text(
                      "TÉLÉCHARGER TOUT (ZIP)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Téléchargement de tous les documents..."), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          (height / 25).floor(), 
          (index) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
              Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
              if (width > 55) Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
            ],
          )
        ),
      ),
    );
  }
}
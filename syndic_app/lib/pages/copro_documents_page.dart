import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart'; 
import 'package:syndic_app/pages/pdf_viewer_page.dart'; 

// ==========================================
// PAGE DES DOCUMENTS (COPRO)
// ==========================================
class CoproDocumentsPage extends StatefulWidget {
  final bool showBackButton;

  const CoproDocumentsPage({super.key, this.showBackButton = false});

  @override
  State<CoproDocumentsPage> createState() => _CoproDocumentsPageState();
}

class _CoproDocumentsPageState extends State<CoproDocumentsPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  bool _isLoading = true;
  List<dynamic> _groupedDocuments = [];

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

  // 🟢 LA FONCTION POUR OUVRIR LE PDF
  void _openFile(String url, String fileName) {
    if (url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(pdfUrl: url, documentName: fileName),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format de fichier non pris en charge pour la lecture interne.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildCitySkyline(),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Appel propre au CustomHeader (sans les paramètres qui causent l'erreur)
                CustomHeader(
                  title: "Vos Documents",
                  subtitle: "Règlements, PV et factures",
                  showBackButton: widget.showBackButton,
                  // 🟢 REMPLACE 'onBackTap' PAR 'onBackPressed'
                  onBackPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  }
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: mainBlue))
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Text(
            "Dossiers et Fichiers",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
          ),
        ),
        Expanded(
          child: _groupedDocuments.isEmpty
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
                            : files.map((file) {
                                return GestureDetector(
                                  // 🟢 CLIC SUR TOUTE LA LIGNE
                                  onTap: () => _openFile(file['url'], file['name']),
                                  child: Container(
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
                                              // 🟢 CLIC SUR LE BOUTON VOIR
                                              onPressed: () => _openFile(file['url'], file['name']),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.file_download, color: Colors.black54, size: 20),
                                              // 🟢 CLIC SUR LE BOUTON TÉLÉCHARGER
                                              onPressed: () => _openFile(file['url'], file['name']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
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
      width: width, height: height,
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate((height / 25).floor(), (index) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
                    Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
                    if (width > 55) Container(width: 8, height: 10, color: Colors.white.withOpacity(0.4)),
                  ],
                )),
      ),
    );
  }
}
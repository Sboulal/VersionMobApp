import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/widgets/custom_header.dart';
import 'package:syndic_app/pages/main_layout.dart';
import 'package:url_launcher/url_launcher.dart'; // 🟢 Ajout de url_launcher
import 'pdf_viewer_page.dart';

// ==========================================
// 1. LISTE DES DOCUMENTS (Écran 15)
// ==========================================
class DocumentsPage extends StatefulWidget {
  final bool isMainScreen;
  const DocumentsPage({super.key, this.isMainScreen = true});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
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
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/documents"),
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

  // 🟢 Fonction activée pour ouvrir les PDF
void _openFile(String url, String fileName) {
  // Vérifie s'il s'agit d'un PDF
  if (url.toLowerCase().endsWith('.pdf')) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(pdfUrl: url, documentName: fileName),
      ),
    );
  } else {
    // Si ce n'est pas un PDF (ex: image), on garde url_launcher ou on affiche un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Format de fichier non pris en charge pour la lecture interne.")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: CustomHeader(
                title: "Sindy",
                subtitle: "Résidence Les Jardins\nDocuments",
                showBackButton: true,
                onBackPressed: widget.isMainScreen 
                    ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false)
                    : null,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: mainBlue))
                : _groupedDocuments.isEmpty
                  ? const Center(child: Text("Aucun document trouvé.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _groupedDocuments.length,
                      itemBuilder: (context, index) {
                        final group = _groupedDocuments[index];
                        final files = group['files'] as List;
                        
                        // 🟢 UI façon "Dossiers" (ExpansionTile)
                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: files.isNotEmpty,
                            leading: const Icon(Icons.folder, color: Color(0xFFFFC107), size: 32),
                            title: Text(group['category'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            children: files.isEmpty
                                ? [const Padding(padding: EdgeInsets.all(16.0), child: Text("Dossier vide", style: TextStyle(color: Colors.grey)))]
                                : files.map((file) => Container(
                                    margin: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white, 
                                      borderRadius: BorderRadius.circular(12), 
                                      border: Border.all(color: Colors.grey.shade200)
                                    ),
                                    child: ListTile(
  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
  // 🟢 AJOUT DE maxLines ET overflow ICI
  title: Text(
    file['name'], 
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  subtitle: Text("${file['date']} • ${file['size']}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
  trailing: IconButton(
    icon: const Icon(Icons.download_rounded, color: Colors.black54),
    onPressed: () => _openFile(file['url'], file['name']),
  ),
  onTap: () => _openFile(file['url'], file['name']),
)
                                  )).toList(),
                          ),
                        );
                      },
                    ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Ajouter un document", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AjouterDocumentPage())).then((_) => _fetchDocuments());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. AJOUTER UN DOCUMENT (Écran 16)
// ==========================================
class AjouterDocumentPage extends StatefulWidget {
  const AjouterDocumentPage({super.key});

  @override
  State<AjouterDocumentPage> createState() => _AjouterDocumentPageState();
}

class _AjouterDocumentPageState extends State<AjouterDocumentPage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  // 🟢 Catégories exactes selon le cahier des charges
  String _selectedCategory = "Assemblées générales";
  final List<String> _categories = ["Assemblées générales", "Factures", "Règlement", "Charges", "Autres"];

  File? _pickedFile;
  bool _isPublishing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );

    if (result != null && result.isNotEmpty && result.first.path != null) {
      setState(() {
        _pickedFile = File(result.first.path!);
      });
    }
  }

  Future<void> _publishDocument() async {
    if (_nomController.text.trim().isEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le nom et le fichier sont obligatoires."), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isPublishing = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      var request = http.MultipartRequest('POST', Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/documents"));
      request.headers.addAll({"Authorization": "Bearer $token", "Accept": "application/json"});
      
      request.fields['nom'] = _nomController.text.trim();
      request.fields['categorie'] = _selectedCategory;
      if (_descController.text.isNotEmpty) request.fields['description'] = _descController.text.trim();

      request.files.add(await http.MultipartFile.fromPath('fichier', _pickedFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document publié avec succès."), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur Serveur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur réseau : $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: "Sindy", subtitle: "Créer un document", showBackButton: true),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NOUVEAU DOCUMENT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),

                    _buildInputLabel("Nom du document *"),
                    _buildTextField("Ex: PV d'AG 2026", _nomController, null),
                    const SizedBox(height: 16),

                    _buildInputLabel("Catégorie"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel("Description éventuelle"),
                    _buildTextField("Saisissez une courte description...", _descController, null, maxLines: 3),
                    const SizedBox(height: 16),

                    _buildInputLabel("Fichier à publier *"),
                    _pickedFile != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_pickedFile!.path.split('/').last, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
                                IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.black45), onPressed: () => setState(() => _pickedFile = null)),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE3F2FD), foregroundColor: mainBlue, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Choisir un fichier", style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _pickFile,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _isPublishing ? null : _publishDocument,
                  child: _isPublishing ? const CircularProgressIndicator(color: Colors.white) : const Text("Publier", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData? icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        suffixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 18) : null,
        filled: true, fillColor: bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
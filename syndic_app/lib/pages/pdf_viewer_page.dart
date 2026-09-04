import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String documentName;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.documentName});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdfFromNetwork();
  }

  Future<void> _loadPdfFromNetwork() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          // 🟢 Affichage du code HTTP pour le débogage (ex: Erreur 404)
          _errorMessage = "Erreur HTTP ${response.statusCode}\nLe fichier est introuvable sur le serveur.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur réseau. Vérifiez votre connexion.";
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName, 
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF1A5EAC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openExternal,
            tooltip: "Ouvrir dans le navigateur",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _pdfBytes == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? "Impossible de charger le PDF en interne.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _openExternal,
                          icon: const Icon(Icons.download),
                          label: const Text("Ouvrir avec le navigateur"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A5EAC),
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : SfPdfViewer.memory(
                  _pdfBytes!,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                ),
    );
  }
}
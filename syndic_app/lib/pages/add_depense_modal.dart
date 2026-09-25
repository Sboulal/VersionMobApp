import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddDepenseModal extends StatefulWidget {
  final Color mainBlue;
  final VoidCallback onSuccess;

  const AddDepenseModal({
    super.key,
    required this.mainBlue,
    required this.onSuccess,
  });

  @override
  State<AddDepenseModal> createState() => _AddDepenseModalState();
}

class _AddDepenseModalState extends State<AddDepenseModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _fournisseurController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  
  String _selectedCategory = "Maintenance";
  final List<String> _categories = ["Maintenance", "Entretien", "Frais administratifs", "Autre"];
  bool _isSubmitting = false;

  // Variables pour le fichier
  File? _selectedFile;
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50, maxWidth: 800, maxHeight: 800);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _selectedFileName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur caméra : $e")));
    }
  }

  Future<void> _pickPDF() async {
    try {
      PlatformFile? result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.path != null) {
        setState(() {
          _selectedFile = File(result.path!);
          _selectedFileName = result.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur fichier : $e")));
    }
  }
  
  Future<void> _submitDepense() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La description et le montant sont obligatoires.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      var uri = Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/depenses");
      var request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['title'] = _titleController.text;
      request.fields['amount'] = (num.tryParse(_amountController.text) ?? 0).toString();
      request.fields['date'] = DateTime.now().toIso8601String().split('T')[0];
      request.fields['category'] = _selectedCategory;
      request.fields['fournisseur'] = _fournisseurController.text;
      request.fields['reference'] = _refController.text;

      if (_selectedFile != null) {
        request.files.add(await http.MultipartFile.fromPath('document', _selectedFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        widget.onSuccess();
        if (mounted) Navigator.pop(context); // Nseddo l-Modal b3d n-naja7
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur Serveur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Center(child: Text("CONFIRMATION", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Confirmez-vous l'ajout de la dépense de ${_amountController.text} MAD (${_titleController.text}) ?", 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 14.sp)
            ),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: Colors.green, size: 16),
                SizedBox(width: 8.w),
                Expanded(child: Text("Le solde des copropriétaires sera automatiquement recalculé selon les tantièmes.", style: TextStyle(fontSize: 12.sp, color: Colors.black54))),
              ],
            )
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
              onPressed: () {
                Navigator.pop(context); // Sedd l-AlertDialog
                _submitDepense(); // Sift l-API
              },
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMER ET ENREGISTRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ANNULER", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.90.sh,
      decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Enregistrer une dépense", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Colors.grey.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Description / Titre"),
                        _buildTextField("Ex: Réparation Ascenseur", _titleController, null),
                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildInputLabel("Catégorie"), 
                              _buildDropdown(_selectedCategory, (v) => setState(() => _selectedCategory = v!))
                            ])),
                            SizedBox(width: 12.w),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildInputLabel("Montant (MAD)"), 
                              _buildTextField("Ex: 3500", _amountController, null, isNum: true)
                            ])),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildInputLabel("Fournisseur (Opt)"), 
                              _buildTextField("Ex: Otis", _fournisseurController, null)
                            ])),
                            SizedBox(width: 12.w),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildInputLabel("Référence (Opt)"), 
                              _buildTextField("REF-9082", _refController, null)
                            ])),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        Text("Pièce justificative (Facture)", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 12.h),
                        
                        if (_selectedFile != null)
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.green.shade200)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 12.w),
                                Expanded(child: Text(_selectedFileName ?? "Fichier sélectionné", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => setState(() { _selectedFile = null; _selectedFileName = null; }),
                                )
                              ],
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(child: _buildUploadButton("Prendre photo", Icons.camera_alt, Colors.grey.shade100, Colors.black54, () => _pickImage(ImageSource.camera))),
                              SizedBox(width: 8.w),
                              Expanded(child: _buildUploadButton("Galerie", Icons.photo_library, Colors.grey.shade100, Colors.black54, () => _pickImage(ImageSource.gallery))),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          _buildUploadButton("Importer PDF", Icons.picture_as_pdf, Colors.blue.shade50, widget.mainBlue, _pickPDF),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                      onPressed: _showConfirmation,
                      child: Text("ENREGISTRER DÉPENSE", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.0.h),
      child: Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData? icon, {bool isNum = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black54, fontSize: 13.sp),
        suffixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 20.sp) : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildDropdown(String value, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.r), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp, overflow: TextOverflow.ellipsis)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        icon: Icon(icon, size: 16.sp),
        label: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600)),
        onPressed: onPressed,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddLotFormModal extends StatefulWidget {
  final Color mainBlue;
  final VoidCallback onSuccess;
  final dynamic existingLot; 
  
  const AddLotFormModal({
    super.key,
    required this.mainBlue, 
    required this.onSuccess,
    this.existingLot,
  });

  @override
  State<AddLotFormModal> createState() => _AddLotFormModalState();
}

class _AddLotFormModalState extends State<AddLotFormModal> {
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _etageController = TextEditingController();
  final TextEditingController _tantiemesController = TextEditingController();
  final TextEditingController _surfaceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _typeOptions = ["Appartement", "Magasin", "Bureau", "Villa", "Garage", "Autre"];
  String _selectedType = "Appartement";

  String _ownerName = "";
  String _ownerPhone = "";
  String _ownerEmail = "";

  bool _isSubmitting = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLot != null) {
      _isEditMode = true;
      _numeroController.text = widget.existingLot['id'].toString();
      _etageController.text = widget.existingLot['floor'].toString();
      _tantiemesController.text = widget.existingLot['tantiemes'].toString();
      
      String ownerVal = widget.existingLot['owner'].toString();
      _ownerName = (ownerVal == "Sans propriétaire" || ownerVal == "Inconnu") ? "" : ownerVal;
      _ownerPhone = widget.existingLot['telephone'] ?? "";
      _ownerEmail = widget.existingLot['email'] ?? "";

      String existingType = widget.existingLot['type'] ?? "Appartement";
      if (_typeOptions.contains(existingType)) {
        _selectedType = existingType;
      }
    }
  }

  void _showOwnerDialog() {
    final nameCtrl = TextEditingController(text: _ownerName);
    final phoneCtrl = TextEditingController(text: _ownerPhone);
    final emailCtrl = TextEditingController(text: _ownerEmail);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFFE8EAF6), child: Icon(Icons.person, color: const Color(0xFF1A5EAC))),
              SizedBox(width: 12.w),
              Text("Saisie Propriétaire", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSimpleInput("Nom & Prénom", nameCtrl),
              SizedBox(height: 12.h),
              _buildSimpleInput("Téléphone", phoneCtrl, isNumber: true),
              SizedBox(height: 12.h),
              _buildSimpleInput("Email", emailCtrl),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue),
              onPressed: () {
                setState(() {
                  _ownerName = nameCtrl.text;
                  _ownerPhone = phoneCtrl.text;
                  _ownerEmail = emailCtrl.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      }
    );
  }

  Future<void> _submitLot() async {
    if (_numeroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le numéro du lot est obligatoire", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    String apiUrl = "https://api.syndify.nomade-cloud.com/api/mobile/syndic/lots";
    if (_isEditMode) {
      apiUrl = "$apiUrl/${widget.existingLot['db_id']}";
    }

    try {
      final bodyData = {
        "numero_lot": _numeroController.text.trim(),
        "type": _selectedType, 
        "etage": _etageController.text.trim(),
        "proprietaire": _ownerName.trim().isEmpty ? "Sans propriétaire" : _ownerName.trim(),
        "telephone": _ownerPhone.trim(),
        "email": _ownerEmail.trim(),
        "tantiemes": _tantiemesController.text.isEmpty ? 0 : num.tryParse(_tantiemesController.text) ?? 0,
        "surface": _surfaceController.text.isEmpty ? 0 : num.tryParse(_surfaceController.text) ?? 0,
        "notes": _notesController.text.trim(),
      };

      final response = await (_isEditMode ? http.put : http.post)(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(bodyData),
      );

      final data = jsonDecode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        widget.onSuccess(); 
        if (mounted) Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? "Erreur d'enregistrement", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Problème de connexion au serveur.", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                Text(_isEditMode ? "Modifier le lot" : "Ajouter un nouveau lot", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
                  Row(
                    children: [
                      Expanded(child: _buildInputBlock("Numéro du lot", _numeroController)),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildDropdownBlock("Type", _selectedType, _typeOptions, (newValue) {
                        setState(() {
                          _selectedType = newValue!;
                        });
                      })),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInputBlock("Étage", _etageController),
                  SizedBox(height: 24.h),

                  GestureDetector(
                    onTap: _showOwnerDialog,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Propriétaire", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                              Icon(Icons.edit, size: 16.sp, color: widget.mainBlue),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(_ownerName.isEmpty ? "Appuyez pour saisir..." : _ownerName, style: TextStyle(fontSize: 16.sp, color: _ownerName.isEmpty ? Colors.grey : Colors.black87, fontWeight: FontWeight.bold)),
                          if (_ownerPhone.isNotEmpty) Text(_ownerPhone, style: TextStyle(color: Colors.black54, fontSize: 14.sp)),
                          if (_ownerEmail.isNotEmpty) Text(_ownerEmail, style: TextStyle(color: Colors.black54, fontSize: 14.sp)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Row(
                    children: [
                      Expanded(child: _buildInputBlock("Tantièmes", _tantiemesController, isNumber: true)),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildInputBlock("Surface (m²)", _surfaceController, isNumber: true)),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInputBlock("Notes éventuelles", _notesController, maxLines: 3),
                  SizedBox(height: 32.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                      onPressed: _isSubmitting ? null : _submitLot,
                      child: _isSubmitting 
                          ? SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isEditMode ? "Mettre à jour" : "Enregistrer", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildInputBlock(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: widget.mainBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownBlock(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20.sp),
          isExpanded: true,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option, style: TextStyle(fontSize: 14.sp)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: widget.mainBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInput(String hint, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }
}
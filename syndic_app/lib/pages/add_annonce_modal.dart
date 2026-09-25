import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddAnnonceModal extends StatefulWidget {
  final Color mainBlue;
  final VoidCallback onSuccess;

  const AddAnnonceModal({
    super.key,
    required this.mainBlue,
    required this.onSuccess,
  });

  @override
  State<AddAnnonceModal> createState() => _AddAnnonceModalState();
}

class _AddAnnonceModalState extends State<AddAnnonceModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();

  String _selectedCategory = "Information";
  final List<String> _categories = ["Travaux", "Entretien", "Information", "Urgent", "Assemblée Générale"];
  bool _sendNotification = true;
  bool _isSubmitting = false;

  Future<void> _submitAnnonce() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le titre et le message sont obligatoires.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/annonces"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "title": _titleController.text.trim(),
          "category": _selectedCategory,
          "message": _messageController.text.trim(),
          "expiration_date": _expDateController.text.isNotEmpty ? _expDateController.text : null,
          "send_notification": _sendNotification
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        widget.onSuccess();
        if (mounted) Navigator.pop(context); // Nseddo l-Modal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur Serveur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur réseau: $e"), backgroundColor: Colors.red));
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
            Text("Confirmez-vous la création et la publication de l'annonce ?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: Colors.green, size: 16),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _sendNotification ? "L'annonce sera visible. Une notification Push sera envoyée." : "L'annonce sera visible sans notification.", 
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54)
                  ),
                ),
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
                Navigator.pop(context); // Sedd dialog
                _submitAnnonce(); // Sift API
              },
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMER ET PUBLIER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.mainBlue, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
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
                Text("Créer une annonce", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
                        _buildInputLabel("Titre *"),
                        TextField(controller: _titleController, decoration: _inputDecoration("Ex: Travaux ascenseur")),
                        SizedBox(height: 16.h),

                        _buildInputLabel("Catégorie"),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(8.r)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(fontSize: 13.sp)))).toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val!),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        _buildInputLabel("Message *"),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: _inputDecoration("Saisissez votre message ici..."),
                        ),
                        SizedBox(height: 16.h),

                        _buildInputLabel("Date d'expiration"),
                        TextField(
                          controller: _expDateController,
                          readOnly: true, 
                          onTap: () => _selectDate(context), 
                          decoration: _inputDecoration("Choisir une date (Optionnel)", icon: Icons.calendar_today),
                        ),
                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            Checkbox(
                              value: _sendNotification,
                              activeColor: widget.mainBlue,
                              onChanged: (val) => setState(() => _sendNotification = val ?? true),
                            ),
                            Text("Envoyer une notification Push", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                      onPressed: _isSubmitting ? null : _showConfirmation,
                      child: Text("PUBLIER", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black38, fontSize: 13.sp),
      suffixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 18.sp) : null,
      filled: true, fillColor: const Color(0xFFF4F6F9),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
    );
  }
}
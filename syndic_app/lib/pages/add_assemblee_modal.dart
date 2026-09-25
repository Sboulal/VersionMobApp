import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddAssembleeModal extends StatefulWidget {
  final Color mainBlue;
  final VoidCallback onSuccess;

  const AddAssembleeModal({
    super.key,
    required this.mainBlue,
    required this.onSuccess,
  });

  @override
  State<AddAssembleeModal> createState() => _AddAssembleeModalState();
}

class _AddAssembleeModalState extends State<AddAssembleeModal> {
  final TextEditingController _titreController = TextEditingController(text: "Assemblée Générale Annuelle");
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _heureController = TextEditingController(text: "19:00");
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _ordreJourController = TextEditingController();
  
  bool _sendNotification = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    DateTime futureDate = DateTime.now().add(const Duration(days: 15));
    _dateController.text = "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 15)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: widget.mainBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: widget.mainBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _heureController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitAG() async {
    if (_titreController.text.isEmpty || _lieuController.text.isEmpty || _ordreJourController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/assemblees"),
        headers: {
          "Content-Type": "application/json", 
          "Accept": "application/json", 
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "titre": _titreController.text,
          "date": _dateController.text,
          "heure": _heureController.text,
          "lieu": _lieuController.text,
          "ordre_jour": _ordreJourController.text,
          "notifier_residents": _sendNotification
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSuccess();
        if (mounted) Navigator.pop(context); 
      } else {
        try {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur serveur: ${data['message'] ?? 'Inconnue'}"), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ));
        } catch (formatException) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur Système (Code ${response.statusCode}). Vérifiez le backend."), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e"), backgroundColor: Colors.redAccent));
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
                Text("Planifier une AG", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.blue.shade100)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: widget.mainBlue),
                        SizedBox(width: 12.w),
                        Expanded(child: Text("La Loi 18-00 exige l'envoi des convocations 15 jours avant la date de l'AG.", style: TextStyle(fontSize: 12.sp, color: Colors.black87))),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  _buildInput("Titre de l'assemblée", _titreController),
                  SizedBox(height: 16.h),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput("Date", _dateController, readOnly: true, onTap: () => _selectDate(context), suffixIcon: Icons.calendar_month),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildInput("Heure", _heureController, readOnly: true, onTap: () => _selectTime(context), suffixIcon: Icons.access_time),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  _buildInput("Lieu (Ex: Garage, Appt Syndic...)", _lieuController),
                  SizedBox(height: 16.h),

                  _buildInput("Ordre du jour (Points à débattre)", _ordreJourController, maxLines: 4, hint: "- Bilan financier\n- Choix du concierge\n- ..."),
                  SizedBox(height: 24.h),

                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade200)),
                    child: SwitchListTile(
                      activeColor: widget.mainBlue,
                      title: Text("Envoyer une Convocation (Push)", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      subtitle: Text("Les copropriétaires recevront une alerte sur leur téléphone.", style: TextStyle(fontSize: 12.sp)),
                      value: _sendNotification,
                      onChanged: (val) => setState(() => _sendNotification = val),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                      onPressed: _isSubmitting ? null : _submitAG,
                      child: _isSubmitting 
                        ? SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("PLANIFIER ET CONVOQUER", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildInput(String label, TextEditingController controller, {bool readOnly = false, VoidCallback? onTap, IconData? suffixIcon, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black45) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 14.0.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: widget.mainBlue)),
          ),
        ),
      ],
    );
  }
}
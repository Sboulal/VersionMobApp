import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPaiementModal extends StatefulWidget {
  final Color mainBlue;
  final VoidCallback onSuccess;

  const AddPaiementModal({
    super.key,
    required this.mainBlue,
    required this.onSuccess,
  });

  @override
  State<AddPaiementModal> createState() => _AddPaiementModalState();
}

class _AddPaiementModalState extends State<AddPaiementModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  String _selectedMode = "Virement";
  final List<String> _modes = ["Virement", "Espèces", "Chèque", "Autre"];
  
  String? _selectedUserId;
  List<dynamic> _owners = [];
  bool _isLoadingOwners = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/paiements/coproprietaires"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _owners = data['data'];
          if (_owners.isNotEmpty) _selectedUserId = _owners[0]['user_id'].toString();
          _isLoadingOwners = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingOwners = false);
    }
  }

  Future<void> _submitPaiement() async {
    if (_amountController.text.isEmpty || _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le montant et le copropriétaire sont obligatoires.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/paiements"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "user_id": _selectedUserId,
          "amount": num.tryParse(_amountController.text) ?? 0,
          "date": DateTime.now().toIso8601String().split('T')[0],
          "payment_method": _selectedMode,
          "reference": _refController.text.isNotEmpty ? _refController.text : null,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur réseau"), backgroundColor: Colors.red));
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
                Text("Enregistrer un paiement", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Colors.grey.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Copropriétaire / Lot", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
                        SizedBox(height: 6.h),
                        _isLoadingOwners 
                          ? const LinearProgressIndicator() 
                          : Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.r)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedUserId,
                                  isExpanded: true,
                                  items: _owners.map<DropdownMenuItem<String>>((o) {
                                    return DropdownMenuItem<String>(
                                      value: o['user_id'].toString(),
                                      child: Text("${o['owner_name']} (Lot: ${o['lot_id']})", style: TextStyle(fontSize: 14.sp)),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedUserId = val),
                                ),
                              ),
                            ),
                        SizedBox(height: 16.h),

                        Text("Montant (MAD)", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: _amountController, 
                          keyboardType: TextInputType.number, 
                          decoration: InputDecoration(
                            hintText: "Ex: 2500", 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)), 
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h)
                          ),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(height: 16.h),

                        Text("Mode de paiement", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.r)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMode,
                              isExpanded: true,
                              items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(fontSize: 14.sp)))).toList(),
                              onChanged: (val) => setState(() => _selectedMode = val!),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        Text("Référence (Optionnel)", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black54)),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: _refController, 
                          decoration: InputDecoration(
                            hintText: "Ex: Chèque N°12345", 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)), 
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h)
                          ),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                      onPressed: _isSubmitting ? null : _submitPaiement,
                      child: _isSubmitting 
                        ? SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Text("ENREGISTRER LE PAIEMENT", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
}
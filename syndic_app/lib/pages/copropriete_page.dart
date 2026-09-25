import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndic_app/pages/main_layout.dart'; 
import 'package:syndic_app/pages/login_page.dart';
import 'package:syndic_app/pages/syndic_validation_page.dart'; // Wla smitha kifma drtiha f l-fichier jdida
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CoproprietePage extends StatefulWidget {
  final bool isMainScreen; 
  const CoproprietePage({super.key, this.isMainScreen = true}); 

  @override
  State<CoproprietePage> createState() => _CoproprietePageState();
}

class _CoproprietePageState extends State<CoproprietePage> {
  final Color mainBlue = const Color(0xFF1A5EAC);
  final Color bgLight = const Color(0xFFF4F6F9);

  List<dynamic> allLots = [];
  bool _isLoading = true;
  String _errorMessage = "";

  String selectedFilter = "Tous";
  // 🟢 1. Khelina ghir 3 dyal les statuts, w beddelna "Impayé" b "En retard"
  final List<String> filters = ["Tous", "À jour", "En retard"];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchLots(); 
  }

  Future<void> _fetchLots() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.syndify.nomade-cloud.com/api/mobile/syndic/lots"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          allLots = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? "Erreur lors du chargement des lots.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Problème de connexion au serveur.";
        _isLoading = false;
      });
    }
  }

  void _showEditLotModal(BuildContext context, dynamic lot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 🟢 Nti ymknek t3eyti l-AddLotFormModal l-jdida dyalk hna (ila knti khrjtiha f fichier)
      builder: (context) => const SizedBox(), // Placeholder (dir blasstha AddLotFormModal dyalk)
    );
  }

@override
  Widget build(BuildContext context) {
    List<dynamic> filteredLots = allLots.where((lot) {
      String status = lot["status"]?.toString() ?? "À jour";
      
      // 🟢 Hna 9addina l-logic bach y-9ra "Impayé" wla "En retard"
      bool matchesFilter = selectedFilter == "Tous" ||
          (selectedFilter == "En retard" && (status == "Impayé" || status == "En retard")) ||
          status == selectedFilter;

      bool matchesSearch = lot["owner"].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          lot["id"].toString().toLowerCase().contains(searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(),
            _buildImageBanner(),

            SizedBox(height: 24.h),
            
            // 🟢 HNA T7IYDAT DIK L-CARTE LIMOUNIYA
            
            // 🟢 Titre jdid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w),
              child: Text(
                "Liste des copropriétaires", 
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 18.sp)
              ),
            ),
            SizedBox(height: 12.h),

            // 🟢 Filtres
            SizedBox(
              height: 38.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                itemCount: filters.length,
                itemBuilder: (context, index) => _buildFilterChip(filters[index]),
              ),
            ),
            SizedBox(height: 16.h),
            
            // 🟢 Barre de recherche
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w), 
              child: _buildSearchBar()
            ),
            SizedBox(height: 16.h),
            
            // 🟢 Liste des lots
            Expanded(
              child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 14.sp)))
                      : filteredLots.isEmpty
                          ? Center(child: Text("Aucun lot trouvé", style: TextStyle(color: Colors.black54, fontSize: 16.sp)))
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                              itemCount: filteredLots.length,
                              itemBuilder: (context, index) => _buildLotCard(filteredLots[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 16.0.w, right: 16.0.w, top: 16.0.h, bottom: 16.0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.isMainScreen) 
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainLayout()), 
                  (Route<dynamic> route) => false,
                );
              },
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: Colors.black87, size: 20.sp),
              ),
            ),
          Icon(Icons.apartment, color: Colors.black87, size: 32.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sindy", style: TextStyle(color: mainBlue, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                Text("Résidence Les Jardins\nCopropriété", style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.w),
      width: double.infinity,
      height: 120.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        image: DecorationImage(
          image: const NetworkImage("https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=2070&auto=format&fit=crop"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      padding: EdgeInsets.all(16.0.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Copropriété",
            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            "Gérez les lots et les copropriétaires de la résidence",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  // 🟢 4. Zawaqna les Filtres (Colors dynamiques 3la 7ssab l'état)
  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    
    // Loun dyal l-filtre kaytbeddel 3la 7ssab chno khtarina
    Color activeColor = mainBlue;
    if (isSelected) {
       if (label == "À jour") activeColor = const Color(0xFF4CAF50);
       else if (label == "En retard") activeColor = const Color(0xFFD32F2F);
    }

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.0.w),
        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: "Rechercher un propriétaire ou un lot",
        hintStyle: TextStyle(color: Colors.black38, fontSize: 14.sp),
        prefixIcon: Icon(Icons.search, color: Colors.black54, size: 20.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildLotCard(dynamic lot) {
    Color statusColor = lot["status"] == "À jour" ? const Color(0xFF4CAF50) : (lot["status"] == "Impayé" ? const Color(0xFFD32F2F) : const Color(0xFFFF9800));
    
    // 🟢 5. Smiya li ghatban f l-badge dyal l-carte
    String displayStatus = lot["status"];
    if (displayStatus == "Impayé") displayStatus = "En retard";

    bool hasPhoto = lot["photo"] != null && lot["photo"].toString().isNotEmpty;
    String phone = lot["telephone"]?.toString().trim() ?? "";
    String email = lot["email"]?.toString().trim() ?? "";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LotDetailPage(lot: lot, mainBlue: mainBlue)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.0.h),
        padding: EdgeInsets.all(16.0.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 55.w,
              height: 55.h,
              decoration: BoxDecoration(
                color: hasPhoto ? Colors.grey.shade200 : statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: hasPhoto ? Colors.transparent : statusColor.withOpacity(0.3)),
                image: hasPhoto
                    ? DecorationImage(
                        image: NetworkImage(lot["photo"]),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasPhoto
                  ? Center(
                      child: Text(
                        lot["id"].toString(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
                    )
                  : null,
            ),
            
            SizedBox(width: 14.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot["owner"].toString(), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87)
                  ),
                  SizedBox(height: 4.h),
                  
                  Text(
                    "Lot ${lot["id"]} • ${lot["floor"]} • ${lot["tantiemes"]} tantièmes", 
                    style: TextStyle(color: Colors.black54, fontSize: 12.sp, fontWeight: FontWeight.w500)
                  ),
                  
                  SizedBox(height: 8.h),

                  if (phone.isNotEmpty && phone != "null") ...[
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14.sp, color: Colors.blueGrey.shade400),
                        SizedBox(width: 6.w),
                        Text(phone, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13.sp)),
                      ],
                    ),
                    SizedBox(height: 4.h),
                  ],

                  if (email.isNotEmpty && email != "null") ...[
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14.sp, color: Colors.blueGrey.shade400),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            email, 
                            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13.sp), 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                  ],

                  SizedBox(height: 6.h),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 4.r, backgroundColor: statusColor),
                        SizedBox(width: 6.w),
                        Text(
                          displayStatus, // 🟢 Tbeddlat hta hna l "En retard"
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11.sp)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _showEditLotModal(context, lot),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade200, width: 1)
                ),
                child: Icon(Icons.edit_outlined, color: Colors.black54, size: 18.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLotFormModal extends StatefulWidget {
  final Color mainBlue;
  final VoidCallback onSuccess;
  final dynamic existingLot; 
  
  const _AddLotFormModal({
    required this.mainBlue, 
    required this.onSuccess,
    this.existingLot,
  });

  @override
  State<_AddLotFormModal> createState() => _AddLotFormModalState();
}

class _AddLotFormModalState extends State<_AddLotFormModal> {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              CircleAvatar(backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.person, color: Color(0xFF1A5EAC))),
              SizedBox(width: 12),
              Text("Saisie Propriétaire", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSimpleInput("Nom & Prénom", nameCtrl),
              SizedBox(height: 12),
              _buildSimpleInput("Téléphone", phoneCtrl, isNumber: true),
              SizedBox(height: 12),
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
      height: MediaQuery.of(context).size.height * 0.90, 
      decoration: const BoxDecoration(color: Color(0xFFF4F6F9), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditMode ? "Modifier le lot" : "Ajouter un nouveau lot", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                  SizedBox(height: 24),

                  GestureDetector(
                    onTap: _showOwnerDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Propriétaire", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                              Icon(Icons.edit, size: 16, color: widget.mainBlue),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(_ownerName.isEmpty ? "Appuyez pour saisir..." : _ownerName, style: TextStyle(fontSize: 16.sp, color: _ownerName.isEmpty ? Colors.grey : Colors.black87, fontWeight: FontWeight.bold)),
                          if (_ownerPhone.isNotEmpty) Text(_ownerPhone, style: const TextStyle(color: Colors.black54)),
                          if (_ownerEmail.isNotEmpty) Text(_ownerEmail, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: _buildInputBlock("Tantièmes", _tantiemesController, isNumber: true)),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildInputBlock("Surface (m²)", _surfaceController, isNumber: true)),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInputBlock("Notes éventuelles", _notesController, maxLines: 3),
                  SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.mainBlue, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                      onPressed: _isSubmitting ? null : _submitLot,
                      child: _isSubmitting 
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isEditMode ? "Mettre à jour" : "Enregistrer", style:  TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.mainBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownBlock(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          isExpanded: true,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.mainBlue)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }
}

class LotDetailPage extends StatelessWidget {
  final dynamic lot;
  final Color mainBlue;
  
  const LotDetailPage({super.key, required this.lot, required this.mainBlue});

  @override
  Widget build(BuildContext context) {
    Color statusColor = lot["status"] == "À jour" ? const Color(0xFF4CAF50) : (lot["status"] == "Impayé" ? const Color(0xFFD32F2F) : const Color(0xFFFF9800));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔴 La page détail pourrait aussi utiliser ce nouveau layout ou un CustomHeader
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sindy", style: TextStyle(color: mainBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Résidence Les Jardins\nDétail du lot", style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("LOT ${lot['id']}", style:  TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 8),
                    Text(lot["owner"].toString(), style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("${lot["floor"]} | ${lot["tantiemes"]} tantièmes", style: TextStyle(color: Colors.black54, fontSize: 14.sp)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: statusColor),
                        SizedBox(width: 6),
                        Text(lot["status"], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.black12),
                    
                     Text("Historical payments", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 12.h),
                    _buildPaymentRow("Paiement de lot", "15 000 MAD"),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style:  TextStyle(color: Colors.black54, fontSize: 14.sp)),
        Text(amount, style:   TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)),
      ],
    );
  }
}
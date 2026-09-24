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
  final List<String> filters = ["Tous", "À jour", "Partiellement payé", "Impayés"];
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

  void _showAddLotModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLotFormModal(mainBlue: mainBlue, onSuccess: _fetchLots),
    );
  }

  void _showEditLotModal(BuildContext context, dynamic lot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLotFormModal(mainBlue: mainBlue, onSuccess: _fetchLots, existingLot: lot),
    );
  }

 @override
  Widget build(BuildContext context) {
    List<dynamic> filteredLots = allLots.where((lot) {
      bool matchesFilter = selectedFilter == "Tous" ||
          (selectedFilter == "Impayés" && lot["status"] == "Impayé") ||
          lot["status"] == selectedFilter;

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
            // 🟢 L'en-tête blanc avec le logo et le titre
            _buildTopHeader(),
            
            // 🟢 La bannière image avec texte par-dessus
            _buildImageBanner(),

            SizedBox(height: 16.h),
            
            // 🟢 🟢 BOUTON DES VALIDATIONS EN ATTENTE 🟢 🟢
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.orange.shade50, // Loun Limouni bach y-tir l-intibah
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: Colors.orange.shade200, width: 1),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt_1, color: Colors.orange, size: 28),
                  title: const Text(
                    "Demandes d'inscription", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)
                  ),
                  subtitle: const Text("Gérez les résidents en attente", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
                  onTap: () {
                    // 🟢 Kat-ddih l-page dyal l-validation jdida li qaddina
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SyndicValidationPage())
                    );
                  },
                ),
              ),
            ),
            
            SizedBox(height: 16.h),

            // 🟢 Filtres
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filters.length,
                itemBuilder: (context, index) => _buildFilterChip(filters[index]),
              ),
            ),
            SizedBox(height: 16.h),
            
            // 🟢 Barre de recherche
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0), 
              child: _buildSearchBar()
            ),
            SizedBox(height: 16.h),
            
            // 🟢 Liste des lots
            Expanded(
              child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: mainBlue))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style:  TextStyle(color: Colors.red)))
                      : filteredLots.isEmpty
                          ?  Center(child: Text("Aucun lot enregistré", style: TextStyle(color: Colors.black54, fontSize: 16.sp)))
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: filteredLots.length,
                              itemBuilder: (context, index) => _buildLotCard(filteredLots[index]),
                            ),
            ),
            
            // 🟢 Bouton Ajouter
            Container(
              padding: const EdgeInsets.all(16.0),
              color: bgLight,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label:  Text("Ajouter un lot", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddLotModal(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
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
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
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
                child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              ),
            ),
          const Icon(Icons.apartment, color: Colors.black87, size: 32),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sindy", style: TextStyle(color: mainBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Résidence Les Jardins\nCopropriété", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      width: double.infinity,
      height: 120, // Hauteur de l'image
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          // Une belle image de bâtiments comme sur le design
          image: const NetworkImage("https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=2070&auto=format&fit=crop"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4), // Filtre sombre pour faire ressortir le texte
            BlendMode.darken,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, // Aligner le texte en bas
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Copropriété",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            "Gérez les lots et les copropriétaires de la résidence",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ANCIENS WIDGETS CONSERVÉS INTACTS
  // ==========================================================
  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? mainBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        hintText: "Rechercher un propriétaire ou un lot",
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
    );
  }

 Widget _buildLotCard(dynamic lot) {
    Color statusColor = lot["status"] == "À jour" ? const Color(0xFF4CAF50) : (lot["status"] == "Impayé" ? const Color(0xFFD32F2F) : const Color(0xFFFF9800));
    
    // Vérifier si la photo existe
    bool hasPhoto = lot["photo"] != null && lot["photo"].toString().isNotEmpty;

    // 🟢 Récupérer les données de contact
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
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0), // Padding augmenté pour aérer
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100), // Bordure légère
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alignement vers le haut car le contenu est plus long
          children: [
            // ==============================================
            // AVATAR / IMAGE DU LOT
            // ==============================================
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: hasPhoto ? Colors.grey.shade200 : statusColor.withOpacity(0.1), // Fond plus clair si pas de photo
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
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16.sp), // Texte prend la couleur du statut
                      ),
                    )
                  : null,
            ),
            
            SizedBox(width: 14),
            
            // ==============================================
            // INFORMATIONS DU COPROPRIÉTAIRE
            // ==============================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du propriétaire
                  Text(
                    lot["owner"].toString(), 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                  ),
                  SizedBox(height: 4),
                  
                  // Détails du lot (Étage, tantièmes)
                  Text(
                    "Lot ${lot["id"]} • ${lot["floor"]} • ${lot["tantiemes"]} tantièmes", 
                    style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)
                  ),
                  
                  SizedBox(height: 8),

                  // 🟢 TÉLÉPHONE (S'il existe)
                  if (phone.isNotEmpty && phone != "null") ...[
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Colors.blueGrey.shade400),
                        SizedBox(width: 6),
                        Text(phone, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],

                  // 🟢 EMAIL (S'il existe)
                  if (email.isNotEmpty && email != "null") ...[
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.blueGrey.shade400),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email, 
                            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13), 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],

                  SizedBox(height: 6),
                  
                  // Statut (À jour / Impayé)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: statusColor),
                        SizedBox(width: 6),
                        Text(
                          lot["status"], 
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==============================================
            // BOUTON MODIFIER
            // ==============================================
            GestureDetector(
              onTap: () => _showEditLotModal(context, lot),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200, width: 1)
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.black54, size: 18),
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
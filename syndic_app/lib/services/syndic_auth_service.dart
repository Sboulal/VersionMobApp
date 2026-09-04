import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SyndicAuthService {
  static const String baseUrl = 'https://api.syndify.nomade-cloud.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 🟢 دالة صغيرة باش نعرفو المستعمل واش syndic ولا copro
  Future<String> _getRolePrefix() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    return role == 'coproprietaire' ? 'copro' : 'syndic';
  }

  // ==========================================
  // 1. LOGIN (هادي لي كانت ناقصاك)
  // ==========================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/syndic/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['data']['token']);
      
      // 🟢 حفظ الدور (Role) باش التطبيق يعرف أين واجهة يحل
      await prefs.setString('user_role', data['data']['role'] ?? 'syndic'); 
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erreur de connexion');
    }
  }

  // ==========================================
  // 2. PROFIL
  // ==========================================
  Future<Map<String, dynamic>> getProfil() async {
    final token = await _getToken();
    final prefix = await _getRolePrefix(); // 🟢 كنجيبو الـ prefix ديناميكياً

    final response = await http.get(
      Uri.parse('$baseUrl/mobile/$prefix/profil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erreur lors du chargement du profil');
    }
  }

  // ==========================================
  // 3. UPDATE PASSWORD
  // ==========================================
  Future<void> updatePassword({
    required String ancienPassword,
    required String nouveauPassword,
  }) async {
    final token = await _getToken();
    final prefix = await _getRolePrefix(); // 🟢

    final response = await http.put(
      Uri.parse('$baseUrl/mobile/$prefix/profil/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ancien_password': ancienPassword,
        'nouveau_password': nouveauPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (!(response.statusCode == 200 && data['success'] == true)) {
      throw Exception(data['message'] ?? 'Erreur lors de la mise à jour du mot de passe');
    }
  }

  // ==========================================
  // 4. LOGOUT
  // ==========================================
  Future<void> logout() async {
    final token = await _getToken();
    final prefix = await _getRolePrefix(); // 🟢

    await http.post(
      Uri.parse('$baseUrl/mobile/$prefix/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role'); // 🟢 نمسحو الدور حتى هو
  }

  // ==========================================
  // 5. UPLOAD DOCUMENT (Syndic uniquement)
  // ==========================================
  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String categorie,
    String? nom,
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/mobile/syndic/documents'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['categorie'] = categorie;
    if (nom != null && nom.isNotEmpty) {
      request.fields['nom'] = nom;
    }
    request.files.add(await http.MultipartFile.fromPath('fichier', file.path)); // 🟢 تأكدي أن السمية هي fichier كيما فالسيرفر

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      return data['url'] != null ? {'url': data['url']} : data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Erreur lors de la publication du document');
    }
  }
}
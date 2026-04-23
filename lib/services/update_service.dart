import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'auth_service.dart';

class UpdateService {
  static String get apiUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  // Fungsi untuk Sitter mengirim laporan foto dan teks
  static Future<bool> sendLiveUpdate(int requestId, int sitterId, String notes, XFile photoFile) async {
    String? token = await AuthService.getToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/updates/upload'));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['pet_request_id'] = requestId.toString();
      request.fields['sitter_id'] = sitterId.toString();
      request.fields['notes'] = notes;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          await photoFile.readAsBytes(),
          filename: photoFile.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Error upload update: $e");
      return false;
    }
  }
}
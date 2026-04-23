import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'auth_service.dart'; // Untuk mengambil token JWT

class BiddingService {
  // Menentukan HTTP API URL
  static String get apiUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  // Menentukan WebSocket URL
  static String get wsUrl {
    if (kIsWeb) return 'ws://localhost:8080/ws';
    if (Platform.isAndroid) return 'ws://10.0.2.2:8080/ws';
    return 'ws://localhost:8080/ws';
  }

  // Fungsi untuk mengirim penawaran harga (Oleh Sitter) - VERSI FINAL
  static Future<bool> submitBid(int requestId, int sitterId, double amount) async {
    String? token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/bids'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pet_request_id': requestId,
          'sitter_id': sitterId,
          'amount': amount,
        }),
      );

      // PERBAIKAN: Terima status 200 (OK) atau 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Ini akan memberitahu Anda via Terminal apa yang membuat Golang menolak tawaran Anda
        print("GAGAL SUBMIT BID (Status ${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error submit bid: $e");
      return false;
    }
  }

  // Fungsi untuk membuat pesanan penitipan baru (Oleh Pet Owner) - VERSI FINAL
  static Future<int?> createPetRequest(
      String petName,
      String petType,
      DateTime startDate,
      DateTime endDate,
      String location,
      String notes) async {
    String? token = await AuthService.getToken();
    if (token == null) return null;

    try {
      // 1. Ekstrak user_id langsung dari dalam token JWT
      final parts = token.split('.');
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final int userId = payload['user_id']; // Dapatkan ID Anda

      final response = await http.post(
        Uri.parse('$apiUrl/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId, // 2. KIRIM USER ID KE DATABASE
          'pet_name': petName,
          'pet_type': petType,
          'start_date': startDate.toUtc().toIso8601String(),
          'end_date': endDate.toUtc().toIso8601String(),
          'location': location,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['id'] ?? data['data']['ID'];
      } else {
        print("GAGAL API (Status ${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error koneksi create request: $e");
      return null;
    }
  }

  // Mengambil daftar tawaran yang sudah masuk untuk sebuah pesanan (Untuk Owner & Sitter)
  static Future<List<dynamic>> getBids(int requestId) async {
    String? token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/requests/$requestId/bids'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error get bids: $e");
      return [];
    }
  }

  // Fungsi untuk menyetujui tawaran dari Sitter (Oleh Pet Owner)
  static Future<bool> acceptBid(int bidId) async {
    String? token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/bids/$bidId/accept'),
        headers: {'Authorization': 'Bearer $token'},
      );
      // Status 200 OK berarti transaksi lelang berhasil disepakati
      return response.statusCode == 200;
    } catch (e) {
      print("Error accept bid: $e");
      return false;
    }
  }

  // Fungsi untuk mengambil semua daftar pesanan penitipan (untuk Sitter)
  static Future<List<dynamic>> getAllRequests() async {
    String? token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/requests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error get all requests: $e");
      return [];
    }
  }
}
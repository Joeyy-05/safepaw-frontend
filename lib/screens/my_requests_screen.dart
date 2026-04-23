import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/bidding_service.dart';
import '../services/auth_service.dart';
import 'sitter_bids_screen.dart';
import 'active_order_screen.dart'; // Wajib diimport untuk navigasi ke Dashboard

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> _myRequests = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  Future<void> _fetchMyRequests() async {
    String? token = await AuthService.getToken();
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        String resp = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final decoded = jsonDecode(resp);
        _currentUserId = decoded['user_id'];
      }
    }

    final allRequests = await BiddingService.getAllRequests();

    if (mounted) {
      setState(() {
        if (_currentUserId != null) {
          _myRequests = allRequests.where((req) => req['user_id'] == _currentUserId).toList();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penitipan Saya', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myRequests.isEmpty
          ? const Center(child: Text('Anda belum memiliki riwayat penitipan hewan.'))
          : ListView.builder(
        // Mencegah efek melar (stretch) pada Android
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final req = _myRequests[index];
          final String status = req['status'] ?? 'open';
          final bool isMatched = status == 'matched' || status == 'completed';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // PERBAIKAN LOGIKA NAVIGASI: Arahkan berdasarkan Status
                final reqId = req['ID'] ?? req['id'];
                if (isMatched) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveOrderScreen(petRequestId: reqId)));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SitterBidsScreen(petRequestId: reqId)));
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.pets, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${req['pet_name']} (${req['pet_type']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text("📍 ${req['location']}", style: const TextStyle(color: Colors.black87, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                              isMatched ? "Status: Sitter Terpilih" : "Status: Menunggu Sitter",
                              style: TextStyle(color: isMatched ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
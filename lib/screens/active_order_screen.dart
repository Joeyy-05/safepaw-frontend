import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'live_update_screen.dart';

class ActiveOrderScreen extends StatefulWidget {
  final int petRequestId;

  const ActiveOrderScreen({super.key, required this.petRequestId});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  String? _userRole;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _decodeUserToken();
  }

  Future<void> _decodeUserToken() async {
    String? token = await AuthService.getToken();
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        String resp = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final decoded = jsonDecode(resp);
        setState(() {
          _userId = decoded['user_id'];
          _userRole = decoded['role'];
        });
      }
    }
  }

  void _kembaliKeHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Penitipan', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Status Kesepakatan
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.handshake, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text('Lelang Selesai & Sepakat!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Hewan peliharaan sedang dalam masa penitipan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Area Aksi Berdasarkan Peran
              if (_userRole == 'sitter') ...[
                const Text('Tugas Anda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LiveUpdateScreen(petRequestId: widget.petRequestId, sitterId: _userId!)),
                      );
                    }
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('Kirim Live Update (Foto & Laporan)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ] else if (_userRole == 'owner' || _userRole == 'pet_owner') ...[
                const Text('Pantauan Langsung:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                // Untuk tahap ini, kita arahkan Owner ke halaman statis sederhana, idealnya ini menembak GET /api/updates
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: const Text('Catatan MVP: Fitur penarikan data visual laporan Sitter akan diintegrasikan lebih lanjut. Sitter sudah dapat mengirimkan data ke database server Anda.', style: TextStyle(color: Colors.grey)),
                ),
              ],

              const Spacer(),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _kembaliKeHome,
                child: const Text('Tutup dan Kembali ke Beranda', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
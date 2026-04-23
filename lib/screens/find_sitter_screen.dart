import 'package:flutter/material.dart';
import '../services/bidding_service.dart';
import '../utils/app_colors.dart';
import 'bidding_room_screen.dart';

class FindSitterScreen extends StatefulWidget {
  const FindSitterScreen({super.key});

  @override
  State<FindSitterScreen> createState() => _FindSitterScreenState();
}

class _FindSitterScreenState extends State<FindSitterScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final data = await BiddingService.getAllRequests();
    setState(() {
      _requests = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cari Pekerjaan Penitipan', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(child: Text("Belum ada pesanan penitipan saat ini."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text("${req['pet_name']} (${req['pet_type']})", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("📍 Lokasi: ${req['location']}"),
                  Text("👤 Pemilik: ${req['Owner'] != null ? req['Owner']['name'] : 'User'}"),
                  const SizedBox(height: 8),
                  Text("📝 Catatan: ${req['notes']}", maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BiddingRoomScreen(petRequestId: req['ID']),
                    ),
                  );
                },
                child: const Text("Tawarkan"),
              ),
            ),
          );
        },
      ),
    );
  }
}
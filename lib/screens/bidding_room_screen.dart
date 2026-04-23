import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/app_colors.dart';
import '../services/bidding_service.dart';
import '../services/auth_service.dart';

class BiddingRoomScreen extends StatefulWidget {
  final int petRequestId;

  const BiddingRoomScreen({super.key, required this.petRequestId});

  @override
  State<BiddingRoomScreen> createState() => _BiddingRoomScreenState();
}

class _BiddingRoomScreenState extends State<BiddingRoomScreen> {
  late WebSocketChannel _channel;
  List<dynamic> _bids = [];
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _currentUserId;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _decodeUserToken();
    final existingBids = await BiddingService.getBids(widget.petRequestId);

    _channel = WebSocketChannel.connect(Uri.parse(BiddingService.wsUrl));
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'NEW_BID' && data['pet_request_id'] == widget.petRequestId) {
        if (mounted) {
          setState(() {
            _bids.add(data);
            _bids.sort((a, b) => (a['amount'] as num).compareTo(b['amount'] as num));
          });
        }
      }
    });

    if (mounted) {
      setState(() {
        _bids = existingBids;
        _bids.sort((a, b) => (a['amount'] as num).compareTo(b['amount'] as num));
        _isLoading = false;
      });
    }
  }

  Future<void> _decodeUserToken() async {
    String? token = await AuthService.getToken();
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        String resp = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final decoded = jsonDecode(resp);
        setState(() {
          _currentUserId = decoded['user_id'];
          _currentUserRole = decoded['role'];
        });
      }
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _sendBid() async {
    if (_amountController.text.isEmpty || _currentUserId == null) return;
    setState(() => _isSubmitting = true);

    double amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    bool success = await BiddingService.submitBid(widget.petRequestId, _currentUserId!, amount);

    setState(() => _isSubmitting = false);
    if (success) {
      _amountController.clear();
      FocusScope.of(context).unfocus();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim tawaran')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Papan Lelang (Live)', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // HEADER INFORMASI LELANG
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFF3E0), // Latar oranye sangat muda
            width: double.infinity,
            child: const Row(
              children: [
                Icon(Icons.gavel, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Berikan harga terbaik Anda. Sistem Reverse-Auction akan memprioritaskan Sitter dengan harga paling kompetitif.",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // DAFTAR LEADERBOARD
          Expanded(
            child: _bids.isEmpty
                ? const Center(child: Text("Belum ada tawaran. Jadilah yang pertama!", style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bids.length,
              itemBuilder: (context, index) {
                final bid = _bids[index];
                String sitterName = bid['Sitter'] != null ? bid['Sitter']['name'] : 'Sitter #${bid['sitter_id']}';
                bool isLowest = index == 0; // Rank 1 selalu index 0 karena sudah disortir

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLowest ? const Color(0xFFE8F5E9) : Colors.white, // Hijau muda jika termurah
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isLowest ? Colors.green : Colors.grey.shade300, width: isLowest ? 2 : 1),
                    boxShadow: [if (isLowest) const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isLowest ? Colors.green : Colors.grey.shade400,
                            radius: 20,
                            child: isLowest ? const Icon(Icons.star, color: Colors.white, size: 20) : Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          Text(sitterName, style: TextStyle(fontWeight: FontWeight.bold, color: isLowest ? Colors.green.shade800 : AppColors.textPrimary, fontSize: 16)),
                        ],
                      ),
                      Text('Rp ${bid['amount'].toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLowest ? Colors.green.shade700 : Colors.black54)),
                    ],
                  ),
                );
              },
            ),
          ),

          // AREA INPUT LELANG (FORM BUKAN CHAT)
          if (_currentUserRole == 'sitter')
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Ajukan Tawaran Anda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _sendBid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Kirim Penawaran Resmi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
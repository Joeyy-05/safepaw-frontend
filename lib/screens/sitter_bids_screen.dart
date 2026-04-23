import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/app_colors.dart';
import '../services/bidding_service.dart';
import 'active_order_screen.dart';

class SitterBidsScreen extends StatefulWidget {
  final int petRequestId;
  const SitterBidsScreen({super.key, required this.petRequestId});

  @override
  State<SitterBidsScreen> createState() => _SitterBidsScreenState();
}

class _SitterBidsScreenState extends State<SitterBidsScreen> {
  List<dynamic> _biddingSitters = [];
  late WebSocketChannel _channel;
  bool _isLoading = true;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _initRealTimeData();
  }

  Future<void> _initRealTimeData() async {
    final existingBids = await BiddingService.getBids(widget.petRequestId);

    _channel = WebSocketChannel.connect(Uri.parse(BiddingService.wsUrl));
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'NEW_BID' && data['pet_request_id'] == widget.petRequestId) {
        if (mounted) {
          setState(() {
            _biddingSitters.add(data);
            _biddingSitters.sort((a, b) => (a['amount'] as num).compareTo(b['amount'] as num));
          });
        }
      }
    });

    if (mounted) {
      setState(() {
        _biddingSitters = existingBids;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  void _showDealConfirm(dynamic bid) {
    final sitterName = bid['Sitter'] != null ? bid['Sitter']['name'] : 'Sitter #${bid['sitter_id']}';
    final amount = bid['amount'];
    final bidId = bid['ID'] ?? bid['id'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Konfirmasi Penawaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Apakah Anda setuju dengan harga Rp $amount dari $sitterName?'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isAccepting ? null : () => Navigator.pop(context),
                            child: const Text('Tunggu Dulu'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: _isAccepting
                                ? null
                                : () async {
                              setModalState(() => _isAccepting = true);
                              bool success = await BiddingService.acceptBid(bidId);
                              setModalState(() => _isAccepting = false);

                              if (success && mounted) {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => ActiveOrderScreen(petRequestId: widget.petRequestId)),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyetujui tawaran.')));
                              }
                            },
                            child: _isAccepting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Deal!'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawaran Masuk', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Container(
            color: Colors.blueGrey[50],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 80, color: AppColors.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(_biddingSitters.isEmpty ? 'Menunggu Sitter merespons...' : 'Sitter ditemukan!', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 400,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Sitter Terdekat (Harga Tawaran)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: _biddingSitters.isEmpty
                        ? const Center(child: Text("Belum ada penawaran. Sistem sedang menyiarkan pesanan Anda..."))
                        : ListView.builder(
                      physics: const BouncingScrollPhysics(), // Menghilangkan efek melar
                      itemCount: _biddingSitters.length,
                      itemBuilder: (context, index) {
                        final bid = _biddingSitters[index];
                        final sitterName = bid['Sitter'] != null ? bid['Sitter']['name'] : 'Sitter #${bid['sitter_id']}';
                        final amount = bid['amount'];

                        // PERBAIKAN: Layout Custom Row yang menggantikan ListTile agar tidak Overflow
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sitterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    const Text('Menunggu konfirmasi...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min, // Mencegah overflow
                                children: [
                                  Text('Rp $amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _showDealConfirm(bid),
                                      child: const Text('Pilih', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      },
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
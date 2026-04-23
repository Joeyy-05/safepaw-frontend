import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sitter_bids_screen.dart';
import '../services/bidding_service.dart';
import '../services/auth_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  // Controller untuk input dinamis
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedHewan = 'Anjing';
  DateTimeRange? _selectedDateRange;

  bool _isLoading = false;
  String _userName = "Pemilik";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Mengambil nama pengguna dari JWT
  Future<void> _loadUserName() async {
    String? token = await AuthService.getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          String resp = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final decoded = jsonDecode(resp);
          if (mounted) {
            setState(() => _userName = decoded['name'] ?? "Pemilik");
          }
        }
      } catch (e) {
        print("Gagal decode nama: $e");
      }
    }
  }

  // Membuka kalender bawaan Flutter
  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF59E0B), // Warna Oranye SafePaw
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _mulaiLelang() async {
    // Validasi form agar tidak ada yang kosong
    if (_petNameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama hewan, lokasi, dan tanggal wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Kirim data dinamis ke API
    int? newRequestId = await BiddingService.createPetRequest(
      _petNameController.text,
      _selectedHewan,
      _selectedDateRange!.start,
      _selectedDateRange!.end,
      _locationController.text,
      _notesController.text,
    );

    setState(() => _isLoading = false);

    if (newRequestId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SitterBidsScreen(petRequestId: newRequestId),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat pesanan lelang. Cek koneksi Anda.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCC80),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER AREA
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFCC80),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Mulai Penitipan, $_userName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFF81C784),
                        child: Icon(Icons.pets, size: 40, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FORM INPUT AREA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Hewan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _petNameController,
                    decoration: _inputStyle('Masukkan nama peliharaan Anda'),
                  ),
                  const SizedBox(height: 24),

                  const Text('Jenis Hewan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedHewan,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    decoration: _inputStyle(''),
                    items: ['Anjing', 'Kucing', 'Burung', 'Kelinci', 'Lainnya'].map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedHewan = val!),
                  ),
                  const SizedBox(height: 24),

                  const Text('Tanggal Penitipan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange == null
                                ? 'Pilih tanggal mulai & selesai'
                                : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                            style: TextStyle(color: _selectedDateRange == null ? Colors.grey : Colors.black87, fontSize: 15),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Lokasi / Alamat Jemput', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: _inputStyle('Contoh: Tarutung, Jl. Sisingamangaraja'),
                  ),
                  const SizedBox(height: 24),

                  const Text('Catatan Tambahan (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _inputStyle('Contoh: Alergi ayam, harus jalan sore...'),
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _mulaiLelang,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Siarkan Pesanan ke Sitter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi helper untuk styling TextField agar seragam
  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
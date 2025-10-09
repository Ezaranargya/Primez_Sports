import 'package:flutter/material.dart';

class CommunityChatPage extends StatelessWidget{
  final String brand;

  const CommunityChatPage({super.key,required this.brand});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Komunitas $brand"),
        backgroundColor: const Color(0xFFE53E3E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text("Kumpulan Brand $brand Official"),
                  backgroundColor: Colors.grey[200], 
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text("Ikuti"),
                    )
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Admin",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "https://i.ibb.co.com/DPr3vv4X/nike-giannis.png",
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Nike Giannis Immortality 4 EP (NIKFQ3681301) adalah" 
              "sepatu basket low-top ringan dengan midsole empuk" 
              "untuk kenyamanan, outsole karet berpola multidireksi" 
              "untuk grip maksimal, serta upper mesh yang menjaga" 
              "sirkulasi udara. Stabil dan fleksibel, cocok bagi pemain" 
              "cepat yang mengejar performa optimal.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              "Opsi pembelian",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildPriceTile("Rp839.300", "Shopee"),
                _buildPriceTile("Rp899.150", "Tokopedia"),
                _buildPriceTile("Rp1.499.000", "Blibli"),
                _buildPriceTile("Rp959.200", "Toko offline"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTile(String price, String seller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53E3E)),
      ),
      child: Row(
        children: [
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFE53E3E),
            ),
          ),
          const Spacer(),
          Text(
            seller,
            style: const TextStyle(fontSize: 14),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
        ],
      ),
    );
  }
}
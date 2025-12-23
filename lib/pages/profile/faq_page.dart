import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              _buildFaqItem(
                question: 'Apa itu Primez Sports?',
                answer:
                    'Primez Sports adalah aplikasi yang menyediakan informasi seputar sepatu olahraga, berita terkini, dan komunitas untuk para penggemar yang mempunyai antusias tinggi.',
              ),
              _buildFaqItem(
                question: 'Bagaimana cara membeli produk di aplikasi?',
                answer:
                    'Aplikasi Primez Sports hanya menyediakan katalog dan informasi produk. Untuk pembelian, Anda dapat menghubungi toko resmi atau marketplace yang tertera.',
              ),
              _buildFaqItem(
                question: 'Bagaimana cara menemukan sepatu yang sesuai?',
                answer:
                    'Anda bisa memilih kategori seperti Sepak Bola, Basket, atau Voli. Setiap kategori menyediakan rekomendasi berdasarkan model, brand, dan popularitas.',
              ),
              _buildFaqItem(
                question: 'Untuk apa fitur komunitas?',
                answer:
                    'Fitur Komunitas adalah tempat untuk melihat postingan atau pembahasan sepatu dari berbagai brand seperti Nike, Adidas, Jordan, Puma, Under Armour, dan lainnya.',
              ),
              _buildFaqItem(
                question: 'Apa isi fitur Berita?',
                answer:
                    'Berita berisi informasi berita terbaru mengenai rilis sepatu, update model, teknologi baru, dan informasi menarik dari berbagai brand olahraga.',
              ),
              _buildFaqItem(
                question: 'Apakah saya bisa mengganti username atau bio?',
                answer:
                    'Ya, Anda bisa mengubah username dan menambahkan bio di halaman Edit Profile.',
              ),
              _buildFaqItem(
                question: 'Cara melihat postingan di komunitas brand?',
                answer:
                    'Cukup klik salah satu brand, dan Anda akan diarahkan ke halaman postingan terkait brand tersebut.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          iconColor: const Color(0xFFE53E3E),
          collapsedIconColor: Colors.grey[600],
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
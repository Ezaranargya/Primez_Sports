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
                question: 'Apakah ada biaya berlangganan?',
                answer:
                    'Tidak, Primez Sports sepenuhnya gratis untuk digunakan. Anda dapat mengakses semua fitur tanpa biaya apapun.',
              ),
              _buildFaqItem(
                question: 'Bagaimana cara bergabung dengan komunitas?',
                answer:
                    'Anda dapat bergabung dengan komunitas dengan mengunjungi halaman Komunitas dan memilih topik yang Anda minati.',
              ),
              _buildFaqItem(
                question: 'Apakah data saya aman?',
                answer:
                    'Ya, kami sangat menjaga keamanan data pengguna. Semua informasi disimpan dengan aman menggunakan Firebase Authentication dan Firestore.',
              ),
              _buildFaqItem(
                question: 'Bagaimana cara menambahkan produk ke favorit?',
                answer:
                    'Anda dapat menambahkan produk ke favorit dengan menekan ikon hati (♥) pada halaman detail produk atau di halaman katalog.',
              ),
              _buildFaqItem(
                question: 'Bagaimana cara mengubah password?',
                answer:
                    'Anda dapat mengubah password melalui menu Profile > Email, kemudian pilih opsi "Ganti Password".',
              ),
              _buildFaqItem(
                question: 'Apakah tersedia di platform lain?',
                answer:
                    'Saat ini Primez Sports tersedia untuk Android dan iOS. Kami sedang mengembangkan versi web yang akan segera hadir.',
              ),
              _buildFaqItem(
                question: 'Bagaimana cara menghubungi customer support?',
                answer:
                    'Anda dapat menghubungi kami melalui email di support@primezsports.com atau melalui media sosial kami.',
              ),
              _buildFaqItem(
                question: 'Apakah produk yang ditampilkan original?',
                answer:
                    'Semua produk yang ditampilkan dalam aplikasi adalah produk original dari brand resmi. Kami tidak mempromosikan produk tiruan atau palsu.',
              ),

              SizedBox(height: 32.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[300]!,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_center_outlined,
                      size: 48.sp,
                      color: const Color(0xFFE53E3E),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Masih ada pertanyaan?',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Hubungi kami untuk bantuan lebih lanjut',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur hubungi support segera hadir'),
                            backgroundColor: Color(0xFFE53E3E),
                          ),
                        );
                      },
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Hubungi Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
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
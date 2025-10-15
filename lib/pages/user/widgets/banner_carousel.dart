import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';

class BannerCarousel extends StatefulWidget {
  /// Setiap banner berisi map:
  /// {
  ///   'image': 'assets/sepatu.jpg',
  ///   'product': Product(...)
  /// }
  final List<Map<String, dynamic>> banners;

  final double height;
  final double borderRadius;
  final Color activeColor;
  final Color inactiveColor;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Function(Product product)? onBannerTap;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.height = 160,
    this.borderRadius = 12,
    this.activeColor = Colors.redAccent,
    this.inactiveColor = Colors.grey,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.onBannerTap,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      Future.delayed(widget.autoPlayInterval, _autoSlide);
    }
  }

  void _autoSlide() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    if (widget.autoPlay) {
      Future.delayed(widget.autoPlayInterval, _autoSlide);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // === Gambar Banner dengan shadow ===
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            child: SizedBox(
              height: widget.height.h,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.banners.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final banner = widget.banners[index];
                  return GestureDetector(
                    onTap: () {
                      if (widget.onBannerTap != null &&
                          banner['product'] != null) {
                        widget.onBannerTap!(banner['product']);
                      }
                    },
                    child: Image.asset(
                      banner['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // === Indicator di luar gambar ===
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            bool isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: isActive ? 10.w : 8.w,
              width: isActive ? 10.w : 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? widget.activeColor : widget.inactiveColor,
              ),
            );
          }),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BannerCarousel extends StatefulWidget {
  final List<Product> banners;
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
    this.borderRadius = 15,
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
  late PageController _pageController;
  int _currentPage = 0;
  final Map<int, Uint8List> _imageCache = {};
  bool _isInitialized = false;

  static const int _infiniteMultiplier = 10000;
  int get _initialPage =>
      widget.banners.isEmpty ? 0 : _infiniteMultiplier * widget.banners.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.9,
    );

    _preloadImages();

    if (widget.autoPlay && widget.banners.isNotEmpty) {
      Future.delayed(widget.autoPlayInterval, _autoSlide);
    }
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners != widget.banners) {
      _imageCache.clear();
      _preloadImages();
    }
  }

  Future<void> _preloadImages() async {
    for (int i = 0; i < widget.banners.length; i++) {
      final product = widget.banners[i];
      try {
        if (product.bannerImage.isNotEmpty) {
          _imageCache[i] = base64Decode(product.bannerImage);
        } else if (product.imageBase64.isNotEmpty) {
          _imageCache[i] = base64Decode(product.imageBase64);
        }
      } catch (e) {
        print('❌ Error preloading image $i: $e');
      }
    }

    if (mounted) setState(() => _isInitialized = true);
  }

  void _autoSlide() {
    if (!mounted || widget.banners.isEmpty) return;

    final currentPageValue = _pageController.page ?? _initialPage.toDouble();

    _pageController.animateToPage(
      currentPageValue.toInt() + 1,
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
    _imageCache.clear();
    super.dispose();
  }

  Widget _buildBannerImage(Product product, int index) {
    if (_imageCache.containsKey(index)) {
      return Image.memory(
        _imageCache[index]!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    try {
      if (product.bannerImage.isNotEmpty) {
        return Image.memory(
          base64Decode(product.bannerImage),
          fit: BoxFit.cover,
        );
      } else if (product.imageBase64.isNotEmpty) {
        return Image.memory(
          base64Decode(product.imageBase64),
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('❌ Error decoding image: $e');
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 50.w, color: Colors.grey[600]),
            SizedBox(height: 8.h),
            Text(
              'No Banner Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return Container(
        height: widget.height.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
        ),
        child: Center(
          child: Text(
            'No Banners Available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: widget.height.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: widget.activeColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: null,
            onPageChanged: (index) {
              setState(() => _currentPage = index % widget.banners.length);
            },
            itemBuilder: (context, index) {
              final actualIndex = index % widget.banners.length;
              final product = widget.banners[actualIndex];

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: GestureDetector(
                  onTap: () {
                    if (widget.onBannerTap != null) {
                      widget.onBannerTap!(product);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProductDetailPage(product: product),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(widget.borderRadius.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: Colors.grey[200]),
                          _buildBannerImage(product, actualIndex),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 20.h,
                            left: 20.w,
                            right: 20.w,
                            child: Text(
                              product.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          Positioned(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  product.formattedPrice,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'See details',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16.h),

        SmoothPageIndicator(
          controller: _pageController,
          count: widget.banners.length,
          effect: WormEffect(
            dotHeight: 8.h,
            dotWidth: 8.w,
            spacing: 8.w,
            activeDotColor: widget.activeColor,
            dotColor: widget.inactiveColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

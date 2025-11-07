import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseOptionsList extends StatefulWidget {
  final List<PurchaseOption> options;

  const PurchaseOptionsList({super.key, required this.options});

  @override
  State<PurchaseOptionsList> createState() => _PurchaseOptionsListState();
}

class _PurchaseOptionsListState extends State<PurchaseOptionsList> {
  bool _isExpanded = false;

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Tidak bisa membuka link",
              style: TextStyle(fontSize: 14.sp),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE53E3E),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12.r),
              bottom: _isExpanded ? Radius.zero : Radius.circular(12.r),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Opsi pembelian\nbisa lewat link di Sini",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      ...widget.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isLast = index == widget.options.length - 1;

                        return InkWell(
                          onTap: option.link.isNotEmpty
                              ? () => _launchUrl(context, option.link)
                              : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: !isLast
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1.h,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    Formatter.formatPrice(option.price),
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                if (option.logoUrl.isNotEmpty)
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: 50.w,
                                      minHeight: 20.h,
                                    ),
                                    child: Image.asset(
                                      option.logoUrl,
                                      height: 30.h,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _buildStoreBadge(option.storeName),
                                    ),
                                  )
                                else
                                  _buildStoreBadge(option.storeName),

                                SizedBox(width: 12.w),
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "*Harga Dapat Berubah Sewaktu-waktu",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFFE53E3E),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreBadge(String storeName) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Text(
        storeName,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
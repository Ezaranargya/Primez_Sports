import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';

class CommunityCard extends StatefulWidget {
  final String title;
  final String brand;
  final VoidCallback onTap;

  const CommunityCard({
    super.key,
    required this.title,
    required this.brand,
    required this.onTap,
  });

  @override
  State<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  bool isJoined = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ListTile(
        onTap: widget.onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 18.r,
          backgroundColor: Colors.grey[200],
          child: Text(
            widget.brand[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: () {
            setState(() {
              isJoined = !isJoined;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isJoined
                      ? 'Berhasil mengikuti ${widget.title}'
                      : 'Berhasil berhenti mengikuti ${widget.title}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor:
                isJoined ? Colors.grey[200] : AppColors.primary,
            minimumSize: Size(55.w, 28.h),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            isJoined ? 'Diikuti' : 'Ikuti',
            style: TextStyle(
              color: isJoined ? Colors.black87 : Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

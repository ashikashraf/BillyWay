import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:billy_way/core/theme/app_colors.dart';

class AppLoadingAnimation extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;

  const AppLoadingAnimation({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
  });

  @override
  State<AppLoadingAnimation> createState() => _AppLoadingAnimationState();
}

class _AppLoadingAnimationState extends State<AppLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: RotationTransition(
              turns: _controller,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color ?? AppColors.primary,
                      (widget.color ?? AppColors.primary).withValues(alpha: 0.3)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: widget.size * 0.7,
                    height: widget.size * 0.7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.message != null) ...[
            SizedBox(height: 16.h),
            Text(
              widget.message!,
              style: TextStyle(
                color: widget.color ?? AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

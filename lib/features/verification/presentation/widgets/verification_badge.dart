import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/config/app_config.dart';

/// Success/failure badge widget
class VerificationBadge extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String subtitle;
  final bool animate;

  const VerificationBadge({
    Key? key,
    required this.isSuccess,
    required this.title,
    required this.subtitle,
    this.animate = true,
  }) : super(key: key);

  @override
  State<VerificationBadge> createState() => _VerificationBadgeState();
}

class _VerificationBadgeState extends State<VerificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.animate) {
      _controller = AnimationController(
        duration: Duration(milliseconds: AppConfig.animationDurationLong),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.elasticOut,
        ),
      );

      _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );

      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (!widget.animate) {
      return content;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final backgroundColor = widget.isSuccess
        ? AuraTheme.successGreen
        : AuraTheme.errorRed;

    final iconData = widget.isSuccess
        ? Icons.check_circle
        : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with glow effect
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 80,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            widget.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppConfig.borderRadiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCurrentTime(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

/// Compact verification badge for list items
class CompactVerificationBadge extends StatelessWidget {
  final bool isSuccess;
  final double size;

  const CompactVerificationBadge({
    Key? key,
    required this.isSuccess,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AuraTheme.successGreen : AuraTheme.errorRed;
    final icon = isSuccess ? Icons.check_circle : Icons.cancel;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

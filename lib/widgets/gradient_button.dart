import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/theme_provider.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppColors.orangeGradient
              : AppColors.indigoGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkAccent
                      : AppColors.lightAccent)
                  .withAlpha(_isHovered ? 60 : 30),
              blurRadius: _isHovered ? 12 : 8,
              spreadRadius: _isHovered ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withAlpha(50),
            highlightColor: Colors.white.withAlpha(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      widget.icon,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isLoading ? 'Optimizing...' : widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          .animate(target: _isHovered ? 1 : 0)
          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.03, 1.03)),
    );
  }
}

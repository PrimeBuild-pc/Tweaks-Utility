import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final double size;
  final bool isDarkMode;
  
  const AppIcon({
    super.key,
    this.size = 100,
    this.isDarkMode = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF2C3E50),
                  const Color(0xFF1A2530),
                ]
              : [
                  const Color(0xFF3498DB),
                  const Color(0xFF2980B9),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF3498DB)
                      : Colors.white.withOpacity(0.8),
                  width: size * 0.03,
                ),
              ),
            ),
            
            // Inner circle
            Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDarkMode
                      ? [
                          const Color(0xFF3498DB),
                          const Color(0xFF2980B9),
                        ]
                      : [
                          Colors.white,
                          Colors.white.withOpacity(0.8),
                        ],
                ),
              ),
            ),
            
            // Lightning bolt
            Icon(
              Icons.bolt,
              color: isDarkMode ? Colors.white : const Color(0xFF2980B9),
              size: size * 0.3,
            ),
          ],
        ),
      ),
    );
  }
}

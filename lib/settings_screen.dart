import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/theme_provider.dart';
import 'widgets/animated_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: AnimatedBackground(
            isDarkMode: themeProvider.isDarkMode,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    isDarkMode: themeProvider.isDarkMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (value) => themeProvider.toggleTheme(),
                          activeColor: AppColors.darkAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    isDarkMode: themeProvider.isDarkMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: AppColors.darkAccent,
                          ),
                          title: Text(
                            'Version',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '1.0.0',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.code,
                            color: AppColors.darkAccent,
                          ),
                          title: Text(
                            'Developer',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'PrimeOptimizer Team',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
        );
      },
    );
  }
}

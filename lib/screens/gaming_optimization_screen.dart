import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/optimization_utils.dart';
import '../widgets/gradient_button.dart';

class GamingOptimizationScreen extends StatefulWidget {
  const GamingOptimizationScreen({super.key});

  @override
  State<GamingOptimizationScreen> createState() => _GamingOptimizationScreenState();
}

class _GamingOptimizationScreenState extends State<GamingOptimizationScreen> {
  bool _isOptimizing = false;
  List<String> _optimizationLog = [];
  bool _cpuOptimization = true;
  bool _gpuOptimization = true;
  bool _ramOptimization = true;
  bool _networkOptimization = true;
  bool _diskOptimization = true;
  
  Future<void> _optimizeForGaming() async {
    setState(() {
      _isOptimizing = true;
      _optimizationLog.clear();
    });

    try {
      _addToLog('Starting gaming optimization...');

      if (_cpuOptimization) {
        _addToLog('Optimizing CPU for gaming...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ CPU optimized for gaming');
      }

      if (_gpuOptimization) {
        _addToLog('Optimizing GPU for gaming...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ GPU optimized for gaming');
      }

      if (_ramOptimization) {
        _addToLog('Optimizing RAM for gaming...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ RAM optimized for gaming');
      }

      if (_networkOptimization) {
        _addToLog('Optimizing network for lower latency...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ Network optimized for lower latency');
      }

      if (_diskOptimization) {
        _addToLog('Optimizing disk for faster game loading...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ Disk optimized for gaming');
      }

      _addToLog('Gaming optimization completed!');
    } catch (e) {
      _addToLog('Error during optimization: $e');
    } finally {
      setState(() {
        _isOptimizing = false;
      });
    }
  }

  void _addToLog(String message) {
    setState(() {
      _optimizationLog.add('${DateTime.now().toString().split('.')[0]}: $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gaming Optimization',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Optimize your system for gaming',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 24),
            
            // Optimization options
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimization Options',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CheckboxListTile(
                      title: const Text('CPU Optimization'),
                      subtitle: const Text('Optimize CPU scheduling and power settings'),
                      value: _cpuOptimization,
                      onChanged: (value) {
                        setState(() {
                          _cpuOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.memory,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    CheckboxListTile(
                      title: const Text('GPU Optimization'),
                      subtitle: const Text('Optimize GPU settings for maximum performance'),
                      value: _gpuOptimization,
                      onChanged: (value) {
                        setState(() {
                          _gpuOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.videogame_asset,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    CheckboxListTile(
                      title: const Text('RAM Optimization'),
                      subtitle: const Text('Optimize memory allocation and paging'),
                      value: _ramOptimization,
                      onChanged: (value) {
                        setState(() {
                          _ramOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.memory_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    CheckboxListTile(
                      title: const Text('Network Optimization'),
                      subtitle: const Text('Reduce latency and optimize for online gaming'),
                      value: _networkOptimization,
                      onChanged: (value) {
                        setState(() {
                          _networkOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.wifi,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    CheckboxListTile(
                      title: const Text('Disk Optimization'),
                      subtitle: const Text('Optimize disk access for faster game loading'),
                      value: _diskOptimization,
                      onChanged: (value) {
                        setState(() {
                          _diskOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.storage,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // Log output
            _optimizationLog.isNotEmpty
                ? Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.terminal,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Optimization Log',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.black.withAlpha(50)
                                      : Colors.grey.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  itemCount: _optimizationLog.length,
                                  itemBuilder: (context, index) {
                                    final log = _optimizationLog[index];
                                    final isSuccess = log.contains('✓');
                                    final isError = log.contains('✗');
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        log,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: isSuccess
                                              ? Colors.green
                                              : isError
                                                  ? Colors.red
                                                  : isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const Spacer(),
            
            const SizedBox(height: 16),
            
            GradientButton(
              text: 'Optimize for Gaming',
              icon: Icons.sports_esports,
              isLoading: _isOptimizing,
              onPressed: _isOptimizing ? null : _optimizeForGaming,
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

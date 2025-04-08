import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/optimization_utils.dart';
import '../widgets/gradient_button.dart';

class NetworkOptimizationScreen extends StatefulWidget {
  const NetworkOptimizationScreen({super.key});

  @override
  State<NetworkOptimizationScreen> createState() =>
      _NetworkOptimizationScreenState();
}

class _NetworkOptimizationScreenState extends State<NetworkOptimizationScreen> {
  bool _isOptimizing = false;
  List<String> _optimizationLog = [];
  bool _tcpOptimization = true;
  bool _dnsOptimization = true;
  bool _nagleOptimization = true;
  bool _qosOptimization = true;
  bool _adapterOptimization = true;

  Map<String, dynamic> _networkStats = {
    'ping': '-- ms',
    'jitter': '-- ms',
    'download': '-- Mbps',
    'upload': '-- Mbps',
  };

  @override
  void initState() {
    super.initState();
    _getNetworkStats();
  }

  Future<void> _getNetworkStats() async {
    try {
      // Placeholder for actual implementation
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _networkStats = {
          'ping': '25 ms',
          'jitter': '3 ms',
          'download': '250 Mbps',
          'upload': '50 Mbps',
        };
      });
    } catch (e) {
      print('Error getting network stats: $e');
    }
  }

  Future<void> _optimizeNetwork() async {
    setState(() {
      _isOptimizing = true;
      _optimizationLog.clear();
    });

    try {
      _addToLog('Starting network optimization...');

      if (_tcpOptimization) {
        _addToLog('Optimizing TCP/IP settings...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ TCP/IP settings optimized');
      }

      if (_dnsOptimization) {
        _addToLog('Optimizing DNS settings...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ DNS settings optimized');
      }

      if (_nagleOptimization) {
        _addToLog('Disabling Nagle\'s algorithm for lower latency...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ Nagle\'s algorithm disabled');
      }

      if (_qosOptimization) {
        _addToLog('Optimizing QoS settings...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ QoS settings optimized');
      }

      if (_adapterOptimization) {
        _addToLog('Optimizing network adapters...');
        // Placeholder for actual implementation
        await Future.delayed(const Duration(seconds: 1));
        _addToLog('✓ Network adapters optimized');
      }

      _addToLog('Network optimization completed!');

      // Get updated network stats
      await _getNetworkStats();
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
      _optimizationLog
          .add('${DateTime.now().toString().split('.')[0]}: $message');
    });
  }

  Widget _buildNetworkStatCard(String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
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
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Network Optimization',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getNetworkStats,
            tooltip: 'Refresh network stats',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Optimize your network for lower latency and better performance',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 24),

            // Network stats
            Text(
              'Network Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildNetworkStatCard(
                        'Ping', _networkStats['ping'], Icons.speed),
                    _buildNetworkStatCard('Jitter', _networkStats['jitter'],
                        Icons.compare_arrows),
                    _buildNetworkStatCard(
                        'Download', _networkStats['download'], Icons.download),
                    _buildNetworkStatCard(
                        'Upload', _networkStats['upload'], Icons.upload),
                  ],
                ).animate().fadeIn(duration: 400.ms);
              },
            ),

            const SizedBox(height: 24),

            // Optimization options
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                      title: const Text('TCP/IP Optimization'),
                      subtitle:
                          const Text('Optimize TCP/IP stack for lower latency'),
                      value: _tcpOptimization,
                      onChanged: (value) {
                        setState(() {
                          _tcpOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.settings_ethernet,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('DNS Optimization'),
                      subtitle: const Text(
                          'Optimize DNS settings for faster lookups'),
                      value: _dnsOptimization,
                      onChanged: (value) {
                        setState(() {
                          _dnsOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.dns,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Disable Nagle\'s Algorithm'),
                      subtitle: const Text('Reduce latency for small packets'),
                      value: _nagleOptimization,
                      onChanged: (value) {
                        setState(() {
                          _nagleOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.speed,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('QoS Optimization'),
                      subtitle: const Text('Prioritize gaming traffic'),
                      value: _qosOptimization,
                      onChanged: (value) {
                        setState(() {
                          _qosOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.priority_high,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Network Adapter Optimization'),
                      subtitle: const Text('Optimize network adapter settings'),
                      value: _adapterOptimization,
                      onChanged: (value) {
                        setState(() {
                          _adapterOptimization = value ?? true;
                        });
                      },
                      secondary: Icon(
                        Icons.settings_input_hdmi,
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
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
              text: 'Optimize Network',
              icon: Icons.network_check,
              isLoading: _isOptimizing,
              onPressed: _isOptimizing ? null : _optimizeNetwork,
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

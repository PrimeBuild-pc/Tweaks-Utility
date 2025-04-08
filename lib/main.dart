import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'utils/optimization_utils.dart';
import 'utils/direct_hardware_utils.dart';
import 'settings_screen.dart';
import 'providers/theme_provider.dart';
import 'widgets/animated_background.dart';
import 'widgets/gradient_button.dart';
import 'screens/gaming_optimization_screen.dart';
import 'screens/network_optimization_screen.dart';
import 'screens/download_center_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: const OptimizationApp(),
    ),
  );
}

class OptimizationApp extends StatelessWidget {
  const OptimizationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Windows Optimizer',
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.lightAccent,
              secondary: AppColors.lightAccent,
              surface: AppColors.lightSurface,
            ),
            scaffoldBackgroundColor: AppColors.lightBackground,
            cardTheme: CardTheme(
              color: AppColors.lightCardBackground,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.lightSurface,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.darkAccent,
              secondary: AppColors.darkAccent,
              surface: AppColors.darkSurface,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            cardTheme: CardTheme(
              color: AppColors.darkCardBackground,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkSurface,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class SystemInfo {
  final String cpu;
  final String gpu;
  final String ram;
  final String storage;
  final String network;

  SystemInfo({
    required this.cpu,
    required this.gpu,
    required this.ram,
    required this.storage,
    required this.network,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SystemInfo _systemInfo = SystemInfo(
    cpu: 'Loading...',
    gpu: 'Loading...',
    ram: 'Loading...',
    storage: 'Loading...',
    network: 'Loading...',
  );
  bool _isOptimizing = false;
  List<String> _optimizationLog = [];

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  // Removed _loadSystemHealth method as we no longer need it

  Map<String, dynamic> _hardwareInfo = {};

  Future<void> _loadSystemInfo() async {
    try {
      // Get detailed hardware information using direct_hardware_utils.dart
      final hardwareInfo = await DirectHardwareUtils.getDetailedHardwareInfo();

      setState(() {
        _hardwareInfo = hardwareInfo;

        if (_hardwareInfo.isNotEmpty) {
          _systemInfo = SystemInfo(
            // Format: "manufacturer model base_frequency_in_MHz"
            cpu:
                '${_hardwareInfo['cpu']['manufacturer']} ${_hardwareInfo['cpu']['name']} ${_hardwareInfo['cpu']['clockSpeed']} MHz',
            // Format: "manufacturer model VRAM_in_GB"
            gpu:
                '${_hardwareInfo['gpu']['manufacturer']} ${_hardwareInfo['gpu']['name']} ${_hardwareInfo['gpu']['vram']}',
            ram:
                '${_hardwareInfo['ram']['total']} ${_hardwareInfo['ram']['type']} @ ${_hardwareInfo['ram']['frequency']} (${_hardwareInfo['ram']['banks']})',
            storage: _hardwareInfo['storage']
                .map((drive) =>
                    '${drive['drive']} ${drive['type']} ${drive['capacity']} (${drive['free']} free)')
                .join(', '),
            network:
                '${_hardwareInfo['network']['type']} - ${_hardwareInfo['network']['adapter']} (${_hardwareInfo['network']['speed']})',
          );
        }
      });
    } catch (e) {
      print('Error loading system info: $e');

      // Fallback to basic system info if detailed info is not available
      try {
        final cpuInfo = await Process.run('wmic', ['cpu', 'get', 'name']);
        final gpuInfo = await Process.run(
            'wmic', ['path', 'win32_VideoController', 'get', 'name']);
        final ramInfo = await Process.run(
            'wmic', ['ComputerSystem', 'get', 'TotalPhysicalMemory']);
        final diskInfo =
            await Process.run('wmic', ['diskdrive', 'get', 'model,size']);
        final networkInfo = await Process.run('ipconfig', ['/all']);

        setState(() {
          _systemInfo = SystemInfo(
            cpu: cpuInfo.stdout.toString().split('\n')[1].trim(),
            gpu: gpuInfo.stdout.toString().split('\n')[1].trim(),
            ram:
                '${(int.parse(ramInfo.stdout.toString().split('\n')[1].trim()) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
            storage: diskInfo.stdout.toString().split('\n')[1].trim(),
            network: networkInfo.stdout
                .toString()
                .split('Physical Address')[1]
                .split('\n')[0]
                .trim(),
          );
        });
      } catch (fallbackError) {
        print('Error with fallback system info: $fallbackError');
        setState(() {
          _systemInfo = SystemInfo(
            cpu: 'Error loading CPU info',
            gpu: 'Error loading GPU info',
            ram: 'Error loading RAM info',
            storage: 'Error loading storage info',
            network: 'Error loading network info',
          );
        });
      }
    }
  }

  // Removed _getDetailedHardwareInfo method as it's no longer needed

  Future<void> _optimizeSystem() async {
    setState(() {
      _isOptimizing = true;
      _optimizationLog.clear();
    });

    try {
      _addToLog('Starting system optimization...');

      _addToLog('Clearing temporary files...');
      if (await OptimizationUtils.clearTempFiles()) {
        _addToLog('✓ Temporary files cleared successfully');
      } else {
        _addToLog('✗ Failed to clear temporary files');
      }

      _addToLog('Checking disk health...');
      if (await OptimizationUtils.checkDisk()) {
        _addToLog('✓ Disk check completed');
      } else {
        _addToLog('✗ Disk check failed');
      }

      _addToLog('Analyzing disk fragmentation...');
      if (await OptimizationUtils.defragmentDisk()) {
        _addToLog('✓ Disk defragmentation completed');
      } else {
        _addToLog('✗ Disk defragmentation failed');
      }

      _addToLog('Optimizing startup programs...');
      if (await OptimizationUtils.optimizeStartup()) {
        _addToLog('✓ Startup optimization completed');
      } else {
        _addToLog('✗ Startup optimization failed');
      }

      // Refresh system info after optimization
      await _loadSystemInfo();
      _addToLog('System optimization completed!');
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

  // Removed _buildHealthIndicator method as it's no longer needed

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'PrimeOptimizer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(themeProvider.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: themeProvider.toggleTheme,
              ),
            ],
          ),
          drawer: Drawer(
            child: Container(
              color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color:
                          themeProvider.isDarkMode ? Colors.black : Colors.blue,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withAlpha(179),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PrimeOptimizer',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Performance Optimization Suite',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withAlpha(204),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sports_esports),
                    title: const Text('Gaming Optimization'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GamingOptimizationScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.network_check),
                    title: const Text('Network Optimization'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NetworkOptimizationScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download Center'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DownloadCenterScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          body: AnimatedBackground(
            isDarkMode: themeProvider.isDarkMode,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System Info Section
                    Text(
                      'System Information',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Your hardware details and current system status',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 100.ms)
                        .slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hardware Information
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
                                      'Hardware Specifications',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // CPU Information
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.memory,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'CPU',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(_systemInfo.cpu,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                              if (_hardwareInfo.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Cores: ${_hardwareInfo['cpu']['cores']} | Threads: ${_hardwareInfo['cpu']['threads']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  'Frequency: ${_hardwareInfo['cpu']['frequency']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // GPU Information
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.videogame_asset,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'GPU',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(_systemInfo.gpu,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                              if (_hardwareInfo.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'VRAM: ${_hardwareInfo['gpu']['vram']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  'Driver: ${_hardwareInfo['gpu']['driver']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // RAM Information
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.memory_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'RAM',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(_systemInfo.ram,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                              if (_hardwareInfo.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Configuration: ${_hardwareInfo['ram']['banks']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  'Channels: ${_hardwareInfo['ram']['channels']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // Storage Information
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.storage,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Storage',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(_systemInfo.storage,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                              if (_hardwareInfo.isNotEmpty &&
                                                  _hardwareInfo['storage'] !=
                                                      null) ...[
                                                const SizedBox(height: 8),
                                                ..._hardwareInfo['storage']
                                                    .map<Widget>((drive) =>
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 4),
                                                          child: Text(
                                                            '${drive['drive']} (${drive['model']}): ${drive['capacity']} - ${drive['free']} free',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall,
                                                          ),
                                                        ))
                                                    .toList(),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // Network Information
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.wifi,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Network',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(_systemInfo.network,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                              if (_hardwareInfo.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Adapter: ${_hardwareInfo['network']['adapter']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  'IP: ${_hardwareInfo['network']['ipAddress']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // OS Information
                                    if (_hardwareInfo.isNotEmpty)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.computer,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Operating System',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_hardwareInfo['os']['name']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Version: ${_hardwareInfo['os']['version']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  'Build: ${_hardwareInfo['os']['build']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  'Architecture: ${_hardwareInfo['os']['architecture']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 24),

                            // Optimization Button Section
                            const SizedBox(height: 16),
                            if (_optimizationLog.isNotEmpty) ...[
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.terminal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Optimization Log',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: themeProvider.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: themeProvider.isDarkMode
                                              ? Colors.black.withAlpha(50)
                                              : Colors.grey.withAlpha(20),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: _optimizationLog.map((log) {
                                            final isSuccess = log.contains('✓');
                                            final isError = log.contains('✗');

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                          : themeProvider
                                                                  .isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Optimize System',
                      icon: Icons.auto_fix_high,
                      isLoading: _isOptimizing,
                      onPressed: _isOptimizing ? null : _optimizeSystem,
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

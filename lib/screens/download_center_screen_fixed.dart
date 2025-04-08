import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class DownloadCenterScreen extends StatefulWidget {
  const DownloadCenterScreen({super.key});

  @override
  State<DownloadCenterScreen> createState() => _DownloadCenterScreenState();
}

class _DownloadCenterScreenState extends State<DownloadCenterScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _softwareList = [];
  Map<String, bool> _downloadStatus = {};
  Map<String, double> _downloadProgress = {};
  
  @override
  void initState() {
    super.initState();
    _loadSoftwareList();
  }
  
  Future<void> _loadSoftwareList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Placeholder for actual implementation
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _softwareList = [
          {
            'id': 'directx',
            'name': 'DirectX Runtime',
            'description': 'Microsoft DirectX Runtime for gaming',
            'category': 'Gaming',
            'icon': Icons.videogame_asset,
          },
          {
            'id': 'vcredist',
            'name': 'Visual C++ Redistributable',
            'description': 'Microsoft Visual C++ Redistributable packages',
            'category': 'System',
            'icon': Icons.build,
          },
          {
            'id': 'dotnet',
            'name': '.NET Framework',
            'description': 'Microsoft .NET Framework runtime',
            'category': 'System',
            'icon': Icons.code,
          },
          {
            'id': 'msi_afterburner',
            'name': 'MSI Afterburner',
            'description': 'Graphics card overclocking and monitoring utility',
            'category': 'Gaming',
            'icon': Icons.speed,
          },
          {
            'id': 'rivatuner',
            'name': 'RivaTuner Statistics Server',
            'description': 'FPS limiting and monitoring tool',
            'category': 'Gaming',
            'icon': Icons.monitor,
          },
          {
            'id': 'discord',
            'name': 'Discord',
            'description': 'Voice, video and text chat for gamers',
            'category': 'Communication',
            'icon': Icons.chat,
          },
        ];
        
        for (var software in _softwareList) {
          _downloadStatus[software['id']] = false;
          _downloadProgress[software['id']] = 0.0;
        }
      });
    } catch (e) {
      print('Error loading software list: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _downloadSoftware(Map<String, dynamic> software) async {
    setState(() {
      _downloadStatus[software['id']] = true;
      _downloadProgress[software['id']] = 0.0;
    });
    
    try {
      // Simulate download progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _downloadProgress[software['id']] = i / 10;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${software['name']} downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ${software['name']}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _downloadStatus[software['id']] = false;
      });
    }
  }
  
  List<String> get categories {
    final Set<String> uniqueCategories = {};
    for (var software in _softwareList) {
      uniqueCategories.add(software['category']);
    }
    return uniqueCategories.toList()..sort();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return DefaultTabController(
      length: categories.length + 1, // +1 for "All" tab
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Download Center',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              ...categories.map((category) => Tab(text: category)).toList(),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // "All" tab
                  _buildSoftwareList(_softwareList),
                  // Category tabs
                  ...categories.map((category) {
                    final filteredList = _softwareList
                        .where((software) => software['category'] == category)
                        .toList();
                    return _buildSoftwareList(filteredList);
                  }).toList(),
                ],
              ),
      ),
    );
  }
  
  Widget _buildSoftwareList(List<Map<String, dynamic>> softwareList) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: softwareList.length,
      itemBuilder: (context, index) {
        final software = softwareList[index];
        final isDownloading = _downloadStatus[software['id']] ?? false;
        final progress = _downloadProgress[software['id']] ?? 0.0;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(
              software['icon'] ?? Icons.download,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            title: Text(
              software['name'],
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(software['description']),
                const SizedBox(height: 8),
                if (isDownloading)
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            trailing: isDownloading
                ? Text('${(progress * 100).toInt()}%')
                : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadSoftware(software),
                    tooltip: 'Download',
                  ),
            isThreeLine: isDownloading,
          ),
        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 50 * index));
      },
    );
  }
}

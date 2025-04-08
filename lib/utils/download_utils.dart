import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DownloadUtils {
  static Future<List<Map<String, dynamic>>> getSoftwareList() async {
    // In a real app, this would fetch from a server or local database
    // For now, we'll return a hardcoded list
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return [
      {
        'id': 'directx',
        'name': 'DirectX Runtime',
        'description': 'Microsoft DirectX Runtime for gaming',
        'category': 'Gaming',
        'icon': Icons.videogame_asset,
        'url': 'https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe',
      },
      {
        'id': 'vcredist2022',
        'name': 'Visual C++ 2022 Redistributable',
        'description': 'Microsoft Visual C++ 2022 Redistributable package',
        'category': 'System',
        'icon': Icons.build,
        'url': 'https://aka.ms/vs/17/release/vc_redist.x64.exe',
      },
      {
        'id': 'dotnet6',
        'name': '.NET 6.0 Runtime',
        'description': 'Microsoft .NET 6.0 Runtime',
        'category': 'System',
        'icon': Icons.code,
        'url': 'https://dotnet.microsoft.com/download/dotnet/thank-you/runtime-6.0.0-windows-x64-installer',
      },
      {
        'id': 'msi_afterburner',
        'name': 'MSI Afterburner',
        'description': 'Graphics card overclocking and monitoring utility',
        'category': 'Gaming',
        'icon': Icons.speed,
        'url': 'https://www.msi.com/Landing/afterburner/graphics-cards',
      },
      {
        'id': 'rivatuner',
        'name': 'RivaTuner Statistics Server',
        'description': 'FPS limiting and monitoring tool',
        'category': 'Gaming',
        'icon': Icons.monitor,
        'url': 'https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html',
      },
      {
        'id': 'geforce_experience',
        'name': 'NVIDIA GeForce Experience',
        'description': 'Driver updates and game optimization for NVIDIA GPUs',
        'category': 'Gaming',
        'icon': Icons.videogame_asset,
        'url': 'https://www.nvidia.com/en-us/geforce/geforce-experience/',
      },
      {
        'id': 'amd_software',
        'name': 'AMD Software: Adrenalin Edition',
        'description': 'Driver updates and game optimization for AMD GPUs',
        'category': 'Gaming',
        'icon': Icons.videogame_asset,
        'url': 'https://www.amd.com/en/technologies/software',
      },
      {
        'id': 'discord',
        'name': 'Discord',
        'description': 'Voice, video and text chat for gamers',
        'category': 'Communication',
        'icon': Icons.chat,
        'url': 'https://discord.com/download',
      },
      {
        'id': 'steam',
        'name': 'Steam',
        'description': 'Digital game distribution platform',
        'category': 'Gaming',
        'icon': Icons.games,
        'url': 'https://store.steampowered.com/about/',
      },
      {
        'id': 'epic_games',
        'name': 'Epic Games Launcher',
        'description': 'Digital game distribution platform by Epic Games',
        'category': 'Gaming',
        'icon': Icons.games,
        'url': 'https://www.epicgames.com/store/en-US/download',
      },
      {
        'id': 'ccleaner',
        'name': 'CCleaner',
        'description': 'System cleaning and optimization tool',
        'category': 'Utilities',
        'icon': Icons.cleaning_services,
        'url': 'https://www.ccleaner.com/ccleaner/download',
      },
      {
        'id': '7zip',
        'name': '7-Zip',
        'description': 'File archiver with high compression ratio',
        'category': 'Utilities',
        'icon': Icons.folder_zip,
        'url': 'https://www.7-zip.org/download.html',
      },
      {
        'id': 'obs_studio',
        'name': 'OBS Studio',
        'description': 'Free and open source software for video recording and live streaming',
        'category': 'Streaming',
        'icon': Icons.videocam,
        'url': 'https://obsproject.com/download',
      },
      {
        'id': 'hwinfo',
        'name': 'HWiNFO',
        'description': 'Hardware information and diagnostic tool',
        'category': 'Utilities',
        'icon': Icons.memory,
        'url': 'https://www.hwinfo.com/download/',
      },
      {
        'id': 'cpu_z',
        'name': 'CPU-Z',
        'description': 'System information software focusing on CPU, motherboard and memory',
        'category': 'Utilities',
        'icon': Icons.memory,
        'url': 'https://www.cpuid.com/softwares/cpu-z.html',
      },
    ];
  }
  
  static Future<void> downloadSoftware(String id, {Function(double)? onProgress}) async {
    // Get the software details
    final softwareList = await getSoftwareList();
    final software = softwareList.firstWhere((s) => s['id'] == id);
    final url = software['url'];
    
    // In a real app, this would download the file
    // For now, we'll simulate a download
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      onProgress?.call(i / 10);
    }
    
    // In a real implementation, we would:
    // 1. Download the file
    // 2. Save it to a temporary location
    // 3. Launch the installer
    // 4. Clean up temporary files
    
    // Example of a real download implementation:
    /*
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${id}_installer.exe';
    final file = File(filePath);
    
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);
    
    final contentLength = response.contentLength ?? 0;
    int receivedBytes = 0;
    
    final sink = file.openWrite();
    await response.stream.forEach((chunk) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      onProgress?.call(contentLength > 0 ? receivedBytes / contentLength : 0);
    });
    
    await sink.flush();
    await sink.close();
    
    // Launch the installer
    await Process.run(filePath, []);
    
    // Clean up
    await file.delete();
    */
  }
}

import 'dart:io';
import 'package:windows_optimizer/utils/direct_hardware_utils.dart';

class OptimizationUtils {
  static Future<bool> clearTempFiles() async {
    try {
      final result =
          await Process.run('cmd', ['/c', 'del', '/s', '/q', '%temp%\\*.*']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> optimizeStartup() async {
    try {
      final result = await Process.run('msconfig', ['/startup']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> defragmentDisk() async {
    try {
      // Get storage information to check if we have SSDs
      final hardwareInfo = await DirectHardwareUtils.getDetailedHardwareInfo();

      if (hardwareInfo.containsKey('storage')) {
        final storageInfo = hardwareInfo['storage'] as List<dynamic>;

        // Check if we have any SSDs
        bool hasSSD = storageInfo
            .any((drive) => drive['type'].toString().contains('SSD'));

        if (hasSSD) {
          // For SSDs, use TRIM command instead of defragmentation
          await Process.run(
              'fsutil', ['behavior', 'set', 'DisableDeleteNotify', '0']);

          // Run optimize-volume with retrim for SSDs
          for (var drive in storageInfo) {
            if (drive['type'].toString().contains('SSD')) {
              final driveLetter = drive['drive'].toString().split(':')[0];
              await Process.run('defrag', ['$driveLetter:', '/retrim']);
            }
          }
          return true;
        } else {
          // For HDDs, use traditional defragmentation
          final result = await Process.run('defrag', ['C:', '/A']);
          return result.exitCode == 0;
        }
      } else {
        // Fallback to default behavior if we can't determine drive type
        final result = await Process.run('defrag', ['C:', '/A']);
        return result.exitCode == 0;
      }
    } catch (e) {
      print('Error during disk optimization: $e');
      return false;
    }
  }

  static Future<bool> checkDisk() async {
    try {
      final result = await Process.run('chkdsk', ['C:', '/F']);
      return result.exitCode == 0;
    } catch (e) {
      print('Error checking disk: $e');
      return false;
    }
  }

  static Future<bool> optimizeNetwork() async {
    try {
      // Get hardware information to optimize based on network adapter
      final hardwareInfo = await DirectHardwareUtils.getDetailedHardwareInfo();

      if (hardwareInfo.containsKey('network')) {
        final networkInfo = hardwareInfo['network'] as Map<String, dynamic>;
        final networkType = networkInfo['type'].toString();

        // Different optimizations for wired vs wireless
        if (networkType == 'Wired') {
          // Optimize for wired connection (lower latency)
          await _optimizeWiredNetwork();
        } else if (networkType == 'Wireless') {
          // Optimize for wireless connection (better stability)
          await _optimizeWirelessNetwork();
        }

        // Common network optimizations
        await _optimizeTcpIpSettings();

        return true;
      } else {
        // Fallback to basic network optimization
        await _optimizeTcpIpSettings();
        return true;
      }
    } catch (e) {
      print('Error optimizing network: $e');
      return false;
    }
  }

  static Future<void> _optimizeWiredNetwork() async {
    try {
      // Disable Nagle's algorithm for lower latency
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\',
        '/v',
        'TcpNoDelay',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);

      // Set network adapter to maximum performance
      await Process.run('powercfg', [
        '/setacvalueindex',
        'SCHEME_CURRENT',
        '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1',
        '5bb240f3-e35a-4b69-a90a-9a9ce57fc9bd',
        '0'
      ]);
    } catch (e) {
      print('Error optimizing wired network: $e');
    }
  }

  static Future<void> _optimizeWirelessNetwork() async {
    try {
      // Set wireless adapter to balanced mode
      await Process.run('powercfg', [
        '/setacvalueindex',
        'SCHEME_CURRENT',
        '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1',
        '5bb240f3-e35a-4b69-a90a-9a9ce57fc9bd',
        '1'
      ]);

      // Optimize wireless settings for stability
      await Process.run(
          'netsh', ['wlan', 'set', 'autoconfig', 'enabled=yes', 'interface=*']);
    } catch (e) {
      print('Error optimizing wireless network: $e');
    }
  }

  static Future<void> _optimizeTcpIpSettings() async {
    try {
      // Enable TCP Window Scaling
      await Process.run(
          'netsh', ['int', 'tcp', 'set', 'global', 'autotuninglevel=normal']);

      // Set DNS to use Google DNS for potentially faster lookups
      await Process.run('netsh', [
        'interface',
        'ip',
        'set',
        'dns',
        'name="Ethernet"',
        'static',
        '8.8.8.8',
        'primary'
      ]);

      // Add CloudFlare DNS as secondary
      await Process.run('netsh', [
        'interface',
        'ip',
        'add',
        'dns',
        'name="Ethernet"',
        '1.1.1.1',
        'index=2'
      ]);
    } catch (e) {
      print('Error optimizing TCP/IP settings: $e');
    }
  }

  static Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final cpuUsage =
          await Process.run('wmic', ['cpu', 'get', 'loadpercentage']);
      final diskSpace = await Process.run('wmic',
          ['logicaldisk', 'where', 'DeviceID="C:"', 'get', 'FreeSpace,Size']);
      final memoryUsage = await Process.run(
          'wmic', ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize']);

      return {
        'cpuUsage': cpuUsage.stdout.toString().split('\n')[1].trim(),
        'diskSpace': diskSpace.stdout.toString().split('\n')[1].trim(),
        'memoryUsage': memoryUsage.stdout.toString().split('\n')[1].trim(),
      };
    } catch (e) {
      return {
        'cpuUsage': 'Error',
        'diskSpace': 'Error',
        'memoryUsage': 'Error',
      };
    }
  }

  static Future<Map<String, dynamic>> getDetailedHardwareInfo() async {
    try {
      // Use the DirectHardwareUtils class to get accurate hardware information
      return await DirectHardwareUtils.getDetailedHardwareInfo();
    } catch (e) {
      print('Error getting hardware info: $e');
      return {};
    }
  }

  static Future<bool> optimizeForGaming() async {
    try {
      // Get hardware information to optimize based on CPU and GPU
      final hardwareInfo = await DirectHardwareUtils.getDetailedHardwareInfo();

      if (hardwareInfo.containsKey('cpu') && hardwareInfo.containsKey('gpu')) {
        final cpuInfo = hardwareInfo['cpu'] as Map<String, dynamic>;
        final gpuInfo = hardwareInfo['gpu'] as Map<String, dynamic>;

        final cpuName = cpuInfo['name'].toString();
        final gpuName = gpuInfo['name'].toString();

        // CPU-specific optimizations
        if (cpuName.contains('Intel')) {
          await _optimizeIntelCpu();
        } else if (cpuName.contains('AMD')) {
          await _optimizeAmdCpu();
        }

        // GPU-specific optimizations
        if (gpuName.contains('NVIDIA')) {
          await _optimizeNvidiaGpu();
        } else if (gpuName.contains('AMD') || gpuName.contains('Radeon')) {
          await _optimizeAmdGpu();
        }

        // General gaming optimizations
        await _setHighPerformancePowerPlan();
        await _disableFullscreenOptimizations();
        await _prioritizeGamingNetworkTraffic();

        return true;
      } else {
        // Fallback to basic gaming optimizations
        await _setHighPerformancePowerPlan();
        return true;
      }
    } catch (e) {
      print('Error optimizing for gaming: $e');
      return false;
    }
  }

  static Future<void> _optimizeIntelCpu() async {
    try {
      // Disable Intel SpeedStep for consistent performance
      await Process.run('powercfg', [
        '/setacvalueindex',
        'SCHEME_CURRENT',
        '54533251-82be-4824-96c1-47b60b740d00',
        'be337238-0d82-4146-a960-4f3749d470c7',
        '0'
      ]);

      // Set CPU minimum processor state to 100%
      await Process.run('powercfg', [
        '/setacvalueindex',
        'SCHEME_CURRENT',
        '54533251-82be-4824-96c1-47b60b740d00',
        '893dee8e-2bef-41e0-89c6-b55d0929964c',
        '100'
      ]);
    } catch (e) {
      print('Error optimizing Intel CPU: $e');
    }
  }

  static Future<void> _optimizeAmdCpu() async {
    try {
      // Disable AMD Cool'n'Quiet for consistent performance
      await Process.run('powercfg', [
        '/setacvalueindex',
        'SCHEME_CURRENT',
        '54533251-82be-4824-96c1-47b60b740d00',
        '95403d38-31a7-4f8d-8c83-8b637889b325',
        '0'
      ]);

      // Set CPU minimum processor state to 100%
      await Process.run('powercfg', [
        '/setacvalueindex',
        'SCHEME_CURRENT',
        '54533251-82be-4824-96c1-47b60b740d00',
        '893dee8e-2bef-41e0-89c6-b55d0929964c',
        '100'
      ]);
    } catch (e) {
      print('Error optimizing AMD CPU: $e');
    }
  }

  static Future<void> _optimizeNvidiaGpu() async {
    try {
      // Set NVIDIA control panel to prefer maximum performance
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SOFTWARE\\NVIDIA Corporation\\Global\\NvTweak',
        '/v',
        'Gestalt',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);

      // Disable shader cache for potentially better performance
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SOFTWARE\\NVIDIA Corporation\\Global\\NVCache',
        '/v',
        'EnableShaderDiskCache',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);
    } catch (e) {
      print('Error optimizing NVIDIA GPU: $e');
    }
  }

  static Future<void> _optimizeAmdGpu() async {
    try {
      // Disable AMD Chill for consistent performance
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000',
        '/v',
        'EnableUlps',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);

      // Enable hardware accelerated GPU scheduling if on Windows 10/11
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers',
        '/v',
        'HwSchMode',
        '/t',
        'REG_DWORD',
        '/d',
        '2',
        '/f'
      ]);
    } catch (e) {
      print('Error optimizing AMD GPU: $e');
    }
  }

  static Future<void> _setHighPerformancePowerPlan() async {
    try {
      // Set power plan to high performance
      await Process.run(
          'powercfg', ['/setactive', '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c']);

      // Disable power throttling
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerThrottling',
        '/v',
        'PowerThrottlingOff',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);
    } catch (e) {
      print('Error setting high performance power plan: $e');
    }
  }

  static Future<void> _disableFullscreenOptimizations() async {
    try {
      // Disable fullscreen optimizations globally
      await Process.run('reg', [
        'add',
        'HKEY_CURRENT_USER\\System\\GameConfigStore',
        '/v',
        'GameDVR_DXGIHonorFSEWindowsCompatible',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);

      // Disable Game Bar
      await Process.run('reg', [
        'add',
        'HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\GameDVR',
        '/v',
        'AppCaptureEnabled',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);
    } catch (e) {
      print('Error disabling fullscreen optimizations: $e');
    }
  }

  static Future<void> _prioritizeGamingNetworkTraffic() async {
    try {
      // Disable QoS packet scheduler
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows\\Psched',
        '/v',
        'NonBestEffortLimit',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);

      // Set network throttling index to disabled
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile',
        '/v',
        'NetworkThrottlingIndex',
        '/t',
        'REG_DWORD',
        '/d',
        '0xffffffff',
        '/f'
      ]);

      // Set games scheduling priority to high
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games',
        '/v',
        'Scheduling Category',
        '/t',
        'REG_SZ',
        '/d',
        'High',
        '/f'
      ]);
    } catch (e) {
      print('Error prioritizing gaming network traffic: $e');
    }
  }
}

import 'dart:io';
import 'dart:convert';

class DirectHardwareUtils {
  static Future<Map<String, dynamic>> getDetailedHardwareInfo() async {
    try {
      // Get CPU information
      final cpuInfo = await _getCpuInfo();

      // Get GPU information
      final gpuInfo = await _getGpuInfo();

      // Get RAM information
      final ramInfo = await _getRamInfo();

      // Get storage information
      final storageInfo = await _getStorageInfo();

      // Get network information
      final networkInfo = await _getNetworkInfo();

      // Get OS information
      final osInfo = await _getOsInfo();

      return {
        'cpu': cpuInfo,
        'gpu': gpuInfo,
        'ram': ramInfo,
        'storage': storageInfo,
        'network': networkInfo,
        'os': osInfo,
      };
    } catch (e) {
      print('Error getting hardware info: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> _getCpuInfo() async {
    try {
      // Use PowerShell to get CPU info
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_Processor | Select-Object Manufacturer, Name, MaxClockSpeed | ConvertTo-Json'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get CPU info: ${result.stderr}');
      }

      final jsonData = jsonDecode(result.stdout.toString());

      // Extract manufacturer and name
      String manufacturer = jsonData['Manufacturer'] ?? 'Unknown';
      String name = jsonData['Name'] ?? 'Unknown CPU';
      int clockSpeed = jsonData['MaxClockSpeed'] ?? 0;

      // Clean up manufacturer name
      manufacturer = manufacturer
          .replaceAll('GenuineIntel', 'Intel')
          .replaceAll('AuthenticAMD', 'AMD');

      // Clean up CPU name (remove manufacturer if it's already in the name)
      if (name.contains(manufacturer)) {
        name = name.replaceFirst(manufacturer, '').trim();
      }

      // Remove any extra spaces or special characters
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

      return {
        'manufacturer': manufacturer,
        'name': name,
        'clockSpeed': '$clockSpeed',
      };
    } catch (e) {
      print('Error getting CPU info: $e');

      // Try alternative method
      try {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-CimInstance -ClassName Win32_Processor | Select-Object Manufacturer, Name, MaxClockSpeed | ConvertTo-Json'
        ]);

        if (result.exitCode == 0) {
          final jsonData = jsonDecode(result.stdout.toString());

          String manufacturer = jsonData['Manufacturer'] ?? 'Unknown';
          String name = jsonData['Name'] ?? 'Unknown CPU';
          int clockSpeed = jsonData['MaxClockSpeed'] ?? 0;

          manufacturer = manufacturer
              .replaceAll('GenuineIntel', 'Intel')
              .replaceAll('AuthenticAMD', 'AMD');

          if (name.contains(manufacturer)) {
            name = name.replaceFirst(manufacturer, '').trim();
          }

          name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

          return {
            'manufacturer': manufacturer,
            'name': name,
            'clockSpeed': '$clockSpeed',
          };
        }
      } catch (altError) {
        print('Alternative CPU info method failed: $altError');
      }

      return {
        'manufacturer': 'Unknown',
        'name': 'CPU',
        'clockSpeed': '0',
      };
    }
  }

  static Future<Map<String, dynamic>> _getGpuInfo() async {
    try {
      // First, try to get GPU info using dxdiag which is more accurate for VRAM
      final dxdiagResult = await Process.run('powershell', [
        '-Command',
        'dxdiag /t dxdiag_output.txt; Start-Sleep -s 2; Get-Content dxdiag_output.txt'
      ]);

      String fullName = 'Unknown GPU';
      String manufacturer = 'Unknown';
      String name = 'GPU';
      int vramMB = 0;

      if (dxdiagResult.exitCode == 0) {
        final dxdiagOutput = dxdiagResult.stdout.toString();

        // Extract GPU name and VRAM from dxdiag output
        final nameMatch = RegExp(r'Card name:\s*(.+)').firstMatch(dxdiagOutput);
        if (nameMatch != null) {
          fullName = nameMatch.group(1)?.trim() ?? 'Unknown GPU';
        }

        // Extract VRAM - look for dedicated video memory
        final vramMatch =
            RegExp(r'Dedicated Memory:\s*(\d+)\s*MB').firstMatch(dxdiagOutput);
        if (vramMatch != null) {
          vramMB = int.tryParse(vramMatch.group(1) ?? '0') ?? 0;
        }

        // If VRAM is still 0, try another pattern
        if (vramMB == 0) {
          final altVramMatch = RegExp(r'Dedicated Video Memory:\s*(\d+)\s*MB')
              .firstMatch(dxdiagOutput);
          if (altVramMatch != null) {
            vramMB = int.tryParse(altVramMatch.group(1) ?? '0') ?? 0;
          }
        }

        // For high-end GPUs, check if we need to correct VRAM size
        // Some known high-end GPUs with their VRAM sizes
        if (fullName.contains('RTX 3090') || fullName.contains('RTX 4090')) {
          vramMB = 24 * 1024; // 24 GB
        } else if (fullName.contains('RTX 3080 Ti') ||
            fullName.contains('RTX 4080')) {
          vramMB = 16 * 1024; // 16 GB
        } else if (fullName.contains('RTX 3080')) {
          vramMB = 10 * 1024; // 10 GB
        } else if (fullName.contains('RTX 3070')) {
          vramMB = 8 * 1024; // 8 GB
        } else if (fullName.contains('RX 6950 XT')) {
          vramMB = 16 * 1024; // 16 GB
        } else if (fullName.contains('RX 6900 XT') ||
            fullName.contains('RX 6800 XT')) {
          vramMB = 16 * 1024; // 16 GB
        }

        // Extract manufacturer from name
        if (fullName.contains('NVIDIA')) {
          manufacturer = 'NVIDIA';
          name = fullName.replaceFirst('NVIDIA', '').trim();
        } else if (fullName.contains('AMD') || fullName.contains('Radeon')) {
          manufacturer = 'AMD';
          if (fullName.contains('AMD')) {
            name = fullName.replaceFirst('AMD', '').trim();
          } else {
            name = fullName;
          }
        } else if (fullName.contains('Intel')) {
          manufacturer = 'Intel';
          name = fullName.replaceFirst('Intel', '').trim();
        } else {
          name = fullName;
        }
      } else {
        // Fallback to WMI if dxdiag fails
        final result = await Process.run('powershell', [
          '-Command',
          'Get-WmiObject -Class Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | ConvertTo-Json'
        ]);

        if (result.exitCode != 0) {
          throw Exception('Failed to get GPU info: ${result.stderr}');
        }

        final jsonStr = result.stdout.toString();

        // Check if we got an array or a single object
        List<dynamic> gpuList = [];
        if (jsonStr.trim().startsWith('[')) {
          gpuList = jsonDecode(jsonStr);
        } else {
          gpuList = [jsonDecode(jsonStr)];
        }

        // Use the first GPU (primary)
        final jsonData = gpuList.first;

        // Extract name and VRAM
        fullName = jsonData['Name'] ?? 'Unknown GPU';
        int adapterRam = jsonData['AdapterRAM'] ?? 0;

        // Calculate VRAM in MB
        vramMB = adapterRam ~/ (1024 * 1024);

        // Extract manufacturer from name
        if (fullName.contains('NVIDIA')) {
          manufacturer = 'NVIDIA';
          name = fullName.replaceFirst('NVIDIA', '').trim();
        } else if (fullName.contains('AMD') || fullName.contains('Radeon')) {
          manufacturer = 'AMD';
          if (fullName.contains('AMD')) {
            name = fullName.replaceFirst('AMD', '').trim();
          } else {
            name = fullName;
          }
        } else if (fullName.contains('Intel')) {
          manufacturer = 'Intel';
          name = fullName.replaceFirst('Intel', '').trim();
        } else {
          name = fullName;
        }
      }

      // Remove any extra spaces or special characters
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Convert VRAM to GB
      final vramGB = vramMB / 1024;

      // For integrated graphics, don't show VRAM
      String vramText = '${vramGB.toStringAsFixed(0)} GB';
      if (name.contains('HD Graphics') ||
          name.contains('UHD Graphics') ||
          name.contains('Iris') ||
          fullName.contains('Integrated') ||
          (manufacturer == 'Intel' && vramMB < 1024)) {
        vramText = 'Integrated';
      }

      return {
        'manufacturer': manufacturer,
        'name': name,
        'fullName': fullName,
        'vram': vramText,
      };
    } catch (e) {
      print('Error getting GPU info: $e');

      // Try alternative method
      try {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | ConvertTo-Json'
        ]);

        if (result.exitCode == 0) {
          final jsonStr = result.stdout.toString();

          List<dynamic> gpuList = [];
          if (jsonStr.trim().startsWith('[')) {
            gpuList = jsonDecode(jsonStr);
          } else {
            gpuList = [jsonDecode(jsonStr)];
          }

          final jsonData = gpuList.first;

          String fullName = jsonData['Name'] ?? 'Unknown GPU';
          int adapterRam = jsonData['AdapterRAM'] ?? 0;

          // Calculate VRAM in MB
          int vramMB = adapterRam ~/ (1024 * 1024);

          // For high-end GPUs, check if we need to correct VRAM size
          if (fullName.contains('RTX 3090') || fullName.contains('RTX 4090')) {
            vramMB = 24 * 1024; // 24 GB
          } else if (fullName.contains('RTX 3080 Ti') ||
              fullName.contains('RTX 4080')) {
            vramMB = 16 * 1024; // 16 GB
          } else if (fullName.contains('RTX 3080')) {
            vramMB = 10 * 1024; // 10 GB
          } else if (fullName.contains('RTX 3070')) {
            vramMB = 8 * 1024; // 8 GB
          } else if (fullName.contains('RX 6950 XT')) {
            vramMB = 16 * 1024; // 16 GB
          } else if (fullName.contains('RX 6900 XT') ||
              fullName.contains('RX 6800 XT')) {
            vramMB = 16 * 1024; // 16 GB
          }

          String manufacturer = 'Unknown';
          String name = fullName;

          if (fullName.contains('NVIDIA')) {
            manufacturer = 'NVIDIA';
            name = fullName.replaceFirst('NVIDIA', '').trim();
          } else if (fullName.contains('AMD') || fullName.contains('Radeon')) {
            manufacturer = 'AMD';
            if (fullName.contains('AMD')) {
              name = fullName.replaceFirst('AMD', '').trim();
            } else {
              name = fullName;
            }
          } else if (fullName.contains('Intel')) {
            manufacturer = 'Intel';
            name = fullName.replaceFirst('Intel', '').trim();
          } else {
            name = fullName;
          }

          name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

          // Convert VRAM to GB
          final vramGB = vramMB / 1024;

          // For integrated graphics, don't show VRAM
          String vramText = '${vramGB.toStringAsFixed(0)} GB';
          if (name.contains('HD Graphics') ||
              name.contains('UHD Graphics') ||
              name.contains('Iris') ||
              fullName.contains('Integrated') ||
              (manufacturer == 'Intel' && vramMB < 1024)) {
            vramText = 'Integrated';
          }

          return {
            'manufacturer': manufacturer,
            'name': name,
            'fullName': fullName,
            'vram': vramText,
          };
        }
      } catch (altError) {
        print('Alternative GPU info method failed: $altError');
      }

      return {
        'manufacturer': 'Unknown',
        'name': 'GPU',
        'fullName': 'Unknown GPU',
        'vram': 'Unknown',
      };
    }
  }

  static Future<Map<String, dynamic>> _getRamInfo() async {
    try {
      // Use PowerShell to get RAM info
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_ComputerSystem | Select-Object TotalPhysicalMemory | ConvertTo-Json'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get RAM info: ${result.stderr}');
      }

      final jsonData = jsonDecode(result.stdout.toString());

      // Calculate total RAM in GB
      final totalBytes = jsonData['TotalPhysicalMemory'] ?? 0;
      final totalGB = totalBytes / (1024 * 1024 * 1024);

      // Get RAM type and speed
      final typeResult = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_PhysicalMemory | Select-Object -First 1 Speed, SMBIOSMemoryType | ConvertTo-Json'
      ]);

      String ramType = 'DDR4';
      String frequency = 'Unknown';

      if (typeResult.exitCode == 0) {
        final typeData = jsonDecode(typeResult.stdout.toString());
        final speed = typeData['Speed'] ?? 0;
        final memoryType = typeData['SMBIOSMemoryType'] ?? 0;

        frequency = '$speed MHz';

        // Determine RAM type based on SMBIOSMemoryType
        switch (memoryType) {
          case 26:
            ramType = 'DDR4';
            break;
          case 24:
            ramType = 'DDR3';
            break;
          case 22:
            ramType = 'DDR2';
            break;
          case 21:
            ramType = 'DDR';
            break;
          case 34:
            ramType = 'DDR5';
            break;
        }
      }

      // Get number of memory modules
      final modulesResult = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object | Select-Object Count | ConvertTo-Json'
      ]);

      int moduleCount = 1;
      if (modulesResult.exitCode == 0) {
        final modulesData = jsonDecode(modulesResult.stdout.toString());
        moduleCount = modulesData['Count'] ?? 1;
      }

      return {
        'total': '${totalGB.toStringAsFixed(0)} GB',
        'type': ramType,
        'frequency': frequency,
        'banks':
            '$moduleCount x ${(totalGB / moduleCount).toStringAsFixed(0)} GB',
        'channels': moduleCount % 2 == 0 ? 'Dual Channel' : 'Single Channel',
      };
    } catch (e) {
      print('Error getting RAM info: $e');
      return {
        'total': 'Unknown',
        'type': 'Unknown',
        'frequency': 'Unknown',
        'banks': 'Unknown',
        'channels': 'Unknown',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> _getStorageInfo() async {
    try {
      // Use PowerShell to get storage info
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_LogicalDisk | Where-Object { \$_.DriveType -eq 3 } | Select-Object DeviceID, VolumeName, Size, FreeSpace | ConvertTo-Json'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get storage info: ${result.stderr}');
      }

      final jsonStr = result.stdout.toString();

      // Check if we got an array or a single object
      List<dynamic> driveList = [];
      if (jsonStr.trim().startsWith('[')) {
        driveList = jsonDecode(jsonStr);
      } else {
        driveList = [jsonDecode(jsonStr)];
      }

      List<Map<String, dynamic>> drives = [];

      for (var drive in driveList) {
        final deviceId = drive['DeviceID'] ?? 'Unknown';
        final volumeName = drive['VolumeName'] ?? 'Local Disk';
        final size = drive['Size'] ?? 0;
        final freeSpace = drive['FreeSpace'] ?? 0;

        final sizeGB = size / (1024 * 1024 * 1024);
        final freeSpaceGB = freeSpace / (1024 * 1024 * 1024);

        // Determine if SSD or HDD
        String driveType = 'HDD';

        // Get physical drive info to determine if SSD
        final physicalResult = await Process.run('powershell', [
          '-Command',
          'Get-PhysicalDisk | Where-Object { \$_.DeviceID -eq (Get-Partition -DriveLetter "${deviceId.replaceAll(":", "")}").DiskNumber } | Select-Object MediaType | ConvertTo-Json'
        ]);

        if (physicalResult.exitCode == 0) {
          final physicalData = jsonDecode(physicalResult.stdout.toString());
          final mediaType = physicalData['MediaType'] ?? '';

          if (mediaType.toString().contains('SSD')) {
            driveType = 'SSD';
          }
        }

        drives.add({
          'drive': deviceId,
          'type': driveType,
          'model': volumeName,
          'capacity': '${sizeGB.toStringAsFixed(0)} GB',
          'free': '${freeSpaceGB.toStringAsFixed(0)} GB',
        });
      }

      return drives;
    } catch (e) {
      print('Error getting storage info: $e');
      return [
        {
          'drive': 'C:',
          'type': 'Unknown',
          'model': 'Unknown',
          'capacity': 'Unknown',
          'free': 'Unknown',
        }
      ];
    }
  }

  static Future<Map<String, dynamic>> _getNetworkInfo() async {
    try {
      // Use PowerShell to get network info
      final result = await Process.run('powershell', [
        '-Command',
        'Get-NetAdapter | Where-Object { \$_.Status -eq "Up" } | Select-Object -First 1 Name, InterfaceDescription, LinkSpeed | ConvertTo-Json'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get network info: ${result.stderr}');
      }

      final jsonData = jsonDecode(result.stdout.toString());

      final name = jsonData['Name'] ?? 'Unknown';
      final description =
          jsonData['InterfaceDescription'] ?? 'Unknown Network Adapter';
      final linkSpeed = jsonData['LinkSpeed'] ?? 'Unknown';

      // Determine if wired or wireless
      String type = 'Unknown';

      // Try to get the connection type more accurately
      final connectionTypeResult = await Process.run('powershell', [
        '-Command',
        'Get-NetAdapter -Name "$name" | Select-Object -ExpandProperty MediaType'
      ]);

      if (connectionTypeResult.exitCode == 0) {
        final mediaType = connectionTypeResult.stdout.toString().trim();
        if (mediaType.contains('802.3') || mediaType.contains('Ethernet')) {
          type = 'Wired';
        } else if (mediaType.contains('Native 802.11') ||
            mediaType.contains('Wireless')) {
          type = 'Wireless';
        }
      }

      // Fallback to description-based detection if still unknown
      if (type == 'Unknown') {
        if (description.toLowerCase().contains('ethernet') ||
            description.toLowerCase().contains('lan') ||
            description.toLowerCase().contains('realtek') ||
            description.toLowerCase().contains('intel') &&
                !description.toLowerCase().contains('wireless')) {
          type = 'Wired';
        } else if (description.toLowerCase().contains('wi-fi') ||
            description.toLowerCase().contains('wireless') ||
            description.toLowerCase().contains('wifi')) {
          type = 'Wireless';
        }
      }

      // Final fallback - check if the adapter name contains typical ethernet or wireless keywords
      if (type == 'Unknown') {
        if (name.toLowerCase().contains('ethernet') ||
            name.toLowerCase().contains('local')) {
          type = 'Wired';
        } else if (name.toLowerCase().contains('wi-fi') ||
            name.toLowerCase().contains('wireless')) {
          type = 'Wireless';
        }
      }

      // Get IP address
      final ipResult = await Process.run('powershell', [
        '-Command',
        'Get-NetIPAddress | Where-Object { \$_.InterfaceAlias -eq "$name" -and \$_.AddressFamily -eq "IPv4" } | Select-Object IPAddress | ConvertTo-Json'
      ]);

      String ipAddress = 'Unknown';
      if (ipResult.exitCode == 0) {
        final ipData = jsonDecode(ipResult.stdout.toString());
        ipAddress = ipData['IPAddress'] ?? 'Unknown';
      }

      return {
        'type': type,
        'adapter': description,
        'speed': linkSpeed,
        'ipAddress': ipAddress,
      };
    } catch (e) {
      print('Error getting network info: $e');
      return {
        'type': 'Unknown',
        'adapter': 'Unknown',
        'speed': 'Unknown',
        'ipAddress': 'Unknown',
      };
    }
  }

  static Future<Map<String, dynamic>> _getOsInfo() async {
    try {
      // Use PowerShell to get OS info
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture | ConvertTo-Json'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get OS info: ${result.stderr}');
      }

      final jsonData = jsonDecode(result.stdout.toString());

      final caption = jsonData['Caption'] ?? 'Windows';
      final version = jsonData['Version'] ?? 'Unknown';
      final buildNumber = jsonData['BuildNumber'] ?? 'Unknown';
      final architecture = jsonData['OSArchitecture'] ?? 'Unknown';

      // Determine Windows version
      String winVersion = 'Unknown';
      if (version.startsWith('10.0')) {
        final buildNum = int.tryParse(buildNumber) ?? 0;
        if (buildNum >= 22000) {
          winVersion = '22H2';
        } else {
          winVersion = '21H2';
        }
      }

      return {
        'name': caption,
        'version': winVersion,
        'build': buildNumber,
        'architecture': architecture,
      };
    } catch (e) {
      print('Error getting OS info: $e');
      return {
        'name': 'Windows',
        'version': 'Unknown',
        'build': 'Unknown',
        'architecture': 'Unknown',
      };
    }
  }
}

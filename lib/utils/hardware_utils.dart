import 'dart:io';

class HardwareUtils {
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

      // Get motherboard information
      final motherboardInfo = await _getMotherboardInfo();

      return {
        'cpu': cpuInfo,
        'gpu': gpuInfo,
        'ram': ramInfo,
        'storage': storageInfo,
        'network': networkInfo,
        'os': osInfo,
        'motherboard': motherboardInfo,
      };
    } catch (e) {
      print('Error getting hardware info: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> _getCpuInfo() async {
    try {
      final result = await Process.run('wmic', [
        'cpu',
        'get',
        'name,manufacturer,numberofcores,numberoflogicalprocessors,maxclockspeed,l3cachesize,architecture',
        '/format:csv'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get CPU info: ${result.stderr}');
      }

      final lines = result.stdout.toString().split('\n');
      if (lines.length < 2) {
        throw Exception('Invalid CPU info output');
      }

      // Skip the first line (header) and empty lines
      final dataLine =
          lines.where((line) => line.trim().isNotEmpty).skip(1).first;
      final parts = dataLine.split(',');

      if (parts.length < 7) {
        throw Exception('Invalid CPU info format');
      }

      final name = parts[1].trim();
      final manufacturer = parts[2].trim();
      final cores = parts[3].trim();
      final threads = parts[4].trim();
      final clockSpeed = parts[5].trim();
      final l3Cache = parts[6].trim();

      // Get the base frequency in MHz
      final clockSpeedMHz = int.tryParse(clockSpeed) ?? 0;

      return {
        'name': name,
        'manufacturer': manufacturer,
        'cores': cores,
        'threads': threads,
        'frequency': '${(clockSpeedMHz / 1000.0).toStringAsFixed(1)} GHz',
        'clockSpeed': '$clockSpeedMHz',
        'architecture': _getCpuArchitecture(manufacturer, name),
        'cache': '${int.tryParse(l3Cache) ?? 0} MB L3 Cache',
      };
    } catch (e) {
      print('Error getting CPU info: $e');
      return {
        'name': 'Unknown CPU',
        'manufacturer': 'Unknown',
        'model': 'CPU',
        'cores': '0',
        'threads': '0',
        'frequency': 'Unknown',
        'clockSpeed': '0',
        'architecture': 'Unknown',
        'cache': 'Unknown',
      };
    }
  }

  static String _getCpuArchitecture(String manufacturer, String name) {
    if (manufacturer.contains('Intel')) {
      if (name.contains('12th Gen') || name.contains('13th Gen')) {
        return 'Intel 7 (10nm)';
      } else if (name.contains('11th Gen')) {
        return 'Intel 10 (10nm)';
      } else if (name.contains('10th Gen') ||
          name.contains('9th Gen') ||
          name.contains('8th Gen')) {
        return '14nm';
      }
    } else if (manufacturer.contains('AMD')) {
      if (name.contains('7000') || name.contains('7 7')) {
        return '5nm Zen 4';
      } else if (name.contains('5000') || name.contains('5 5')) {
        return '7nm Zen 3';
      } else if (name.contains('3000') || name.contains('5 3')) {
        return '7nm Zen 2';
      }
    }

    return 'Unknown';
  }

  static Future<Map<String, dynamic>> _getGpuInfo() async {
    try {
      final result = await Process.run('wmic', [
        'path',
        'win32_VideoController',
        'get',
        'name,adapterram,driverversion,currenthorizontalresolution,currentverticalresolution,currentrefreshrate',
        '/format:csv'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get GPU info: ${result.stderr}');
      }

      final lines = result.stdout.toString().split('\n');
      if (lines.length < 2) {
        throw Exception('Invalid GPU info output');
      }

      // Skip the first line (header) and empty lines
      final dataLine =
          lines.where((line) => line.trim().isNotEmpty).skip(1).first;
      final parts = dataLine.split(',');

      if (parts.length < 7) {
        throw Exception('Invalid GPU info format');
      }

      final name = parts[1].trim();
      final adapterRam = parts[2].trim();
      final driverVersion = parts[3].trim();
      final horizontalResolution = parts[4].trim();
      final verticalResolution = parts[5].trim();
      final refreshRate = parts[6].trim();

      // Calculate VRAM in GB
      final vramBytes = int.tryParse(adapterRam) ?? 0;
      final vramGB = vramBytes / (1024 * 1024 * 1024);

      // Extract manufacturer from name
      String manufacturer = 'Unknown';
      if (name.contains('NVIDIA')) {
        manufacturer = 'NVIDIA';
      } else if (name.contains('AMD') || name.contains('Radeon')) {
        manufacturer = 'AMD';
      } else if (name.contains('Intel')) {
        manufacturer = 'Intel';
      }

      return {
        'name': name,
        'manufacturer': manufacturer,
        'vram': '${vramGB.toStringAsFixed(0)} GB',
        'driver': driverVersion,
        'resolution': '$horizontalResolution x $verticalResolution',
        'refreshRate': '$refreshRate Hz',
      };
    } catch (e) {
      print('Error getting GPU info: $e');
      return {
        'name': 'Unknown GPU',
        'manufacturer': 'Unknown',
        'vram': 'Unknown',
        'driver': 'Unknown',
        'resolution': 'Unknown',
        'refreshRate': 'Unknown',
      };
    }
  }

  static Future<Map<String, dynamic>> _getRamInfo() async {
    try {
      // Get total RAM
      final totalResult = await Process.run('wmic',
          ['computersystem', 'get', 'totalphysicalmemory', '/format:csv']);

      if (totalResult.exitCode != 0) {
        throw Exception('Failed to get RAM info: ${totalResult.stderr}');
      }

      final totalLines = totalResult.stdout.toString().split('\n');
      if (totalLines.length < 2) {
        throw Exception('Invalid RAM info output');
      }

      // Skip the first line (header) and empty lines
      final totalDataLine =
          totalLines.where((line) => line.trim().isNotEmpty).skip(1).first;
      final totalParts = totalDataLine.split(',');

      if (totalParts.length < 2) {
        throw Exception('Invalid RAM info format');
      }

      final totalBytes = int.tryParse(totalParts[1].trim()) ?? 0;
      final totalGB = totalBytes / (1024 * 1024 * 1024);

      // Get RAM modules
      final modulesResult = await Process.run('wmic', [
        'memorychip',
        'get',
        'capacity,speed,manufacturer,configuredclockspeed',
        '/format:csv'
      ]);

      if (modulesResult.exitCode != 0) {
        throw Exception(
            'Failed to get RAM modules info: ${modulesResult.stderr}');
      }

      final modulesLines = modulesResult.stdout.toString().split('\n');

      // Skip the first line (header) and empty lines
      final moduleDataLines =
          modulesLines.where((line) => line.trim().isNotEmpty).skip(1).toList();

      int moduleCount = moduleDataLines.length;
      String ramType = 'DDR4'; // Default
      int frequency = 0;

      if (moduleDataLines.isNotEmpty) {
        final parts = moduleDataLines[0].split(',');
        if (parts.length >= 5) {
          frequency = int.tryParse(parts[4].trim()) ?? 0;
        }
      }

      // Determine RAM type based on frequency
      if (frequency > 4000) {
        ramType = 'DDR5';
      } else if (frequency > 1600) {
        ramType = 'DDR4';
      } else if (frequency > 800) {
        ramType = 'DDR3';
      }

      return {
        'total': '${totalGB.toStringAsFixed(0)} GB',
        'type': ramType,
        'frequency': '$frequency MHz',
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
      final result = await Process.run('wmic', [
        'logicaldisk',
        'get',
        'deviceid,volumename,size,freespace,description',
        '/format:csv'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get storage info: ${result.stderr}');
      }

      final lines = result.stdout.toString().split('\n');
      if (lines.length < 2) {
        throw Exception('Invalid storage info output');
      }

      // Skip the first line (header) and empty lines
      final dataLines =
          lines.where((line) => line.trim().isNotEmpty).skip(1).toList();

      List<Map<String, dynamic>> drives = [];

      for (var line in dataLines) {
        final parts = line.split(',');

        if (parts.length < 6) continue;

        final deviceId = parts[1].trim();
        final description = parts[2].trim();
        final freeSpace = parts[3].trim();
        final size = parts[4].trim();
        final volumeName = parts[5].trim();

        // Skip CD-ROM drives
        if (description.contains('CD-ROM') || size.isEmpty) continue;

        final sizeBytes = int.tryParse(size) ?? 0;
        final freeSpaceBytes = int.tryParse(freeSpace) ?? 0;

        final sizeGB = sizeBytes / (1024 * 1024 * 1024);
        final freeSpaceGB = freeSpaceBytes / (1024 * 1024 * 1024);

        // Determine drive type
        String driveType = 'HDD';

        // Check if it's an SSD using additional WMI query
        final physicalDriveResult = await Process.run(
            'wmic', ['diskdrive', 'get', 'model,mediatype', '/format:csv']);
        if (physicalDriveResult.exitCode == 0) {
          final physicalDriveLines =
              physicalDriveResult.stdout.toString().split('\n');
          for (var driveLine in physicalDriveLines
              .where((line) => line.trim().isNotEmpty)
              .skip(1)) {
            final driveParts = driveLine.split(',');
            if (driveParts.length >= 3) {
              final model = driveParts[1].trim();
              final mediaType = driveParts[2].trim();

              if (mediaType.contains('SSD') ||
                  model.contains('SSD') ||
                  model.contains('Solid State')) {
                driveType = 'SSD';

                // Check if it's NVMe
                if (model.contains('NVMe') || model.contains('PCIe')) {
                  driveType = 'SSD (NVMe)';
                }
              }
            }
          }
        }

        drives.add({
          'drive': deviceId,
          'type': driveType,
          'model': volumeName.isNotEmpty ? volumeName : 'Local Disk',
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
      final result = await Process.run('ipconfig', ['/all']);

      if (result.exitCode != 0) {
        throw Exception('Failed to get network info: ${result.stderr}');
      }

      final output = result.stdout.toString();

      // Determine if wired or wireless
      bool isWired = output.contains('Ethernet adapter') &&
          !output.contains('Media disconnected');
      bool isWireless = output.contains('Wireless LAN adapter') &&
          !output.contains('Media disconnected');

      String type = isWired ? 'Wired' : (isWireless ? 'Wireless' : 'Unknown');

      // Extract adapter name
      String adapter = 'Unknown Network Adapter';
      String speed = 'Unknown';
      String ipAddress = 'Unknown';

      if (isWired) {
        final ethernetSections = output
            .split('Ethernet adapter')
            .where((section) =>
                !section.contains('Media disconnected') &&
                section.contains('IPv4 Address'))
            .toList();
        final ethernetSection =
            ethernetSections.isNotEmpty ? ethernetSections.first : null;

        if (ethernetSection != null) {
          // Extract adapter name
          adapter = ethernetSection.split(':').first.trim();

          // Extract IP address
          final ipMatch = RegExp(r'IPv4 Address[.\s]+: ([0-9.]+)')
              .firstMatch(ethernetSection);
          if (ipMatch != null) {
            ipAddress = ipMatch.group(1) ?? 'Unknown';
          }

          // Get speed using additional WMI query
          final speedResult = await Process.run('wmic', [
            'nic',
            'where',
            'NetEnabled=TRUE',
            'get',
            'Name,Speed',
            '/format:csv'
          ]);
          if (speedResult.exitCode == 0) {
            final speedLines = speedResult.stdout.toString().split('\n');
            for (var line
                in speedLines.where((line) => line.trim().isNotEmpty).skip(1)) {
              final parts = line.split(',');
              if (parts.length >= 3) {
                final adapterName = parts[1].trim();
                final adapterSpeed = parts[2].trim();

                if (adapterName.isNotEmpty && adapterSpeed.isNotEmpty) {
                  final speedMbps = int.tryParse(adapterSpeed) ?? 0;
                  if (speedMbps > 0) {
                    if (speedMbps >= 1000000000) {
                      speed =
                          '${(speedMbps / 1000000000).toStringAsFixed(0)} Gbps';
                    } else {
                      speed =
                          '${(speedMbps / 1000000).toStringAsFixed(0)} Mbps';
                    }
                    break;
                  }
                }
              }
            }
          }
        }
      } else if (isWireless) {
        final wirelessSections = output
            .split('Wireless LAN adapter')
            .where((section) =>
                !section.contains('Media disconnected') &&
                section.contains('IPv4 Address'))
            .toList();
        final wirelessSection =
            wirelessSections.isNotEmpty ? wirelessSections.first : null;

        if (wirelessSection != null) {
          // Extract adapter name
          adapter = wirelessSection.split(':').first.trim();

          // Extract IP address
          final ipMatch = RegExp(r'IPv4 Address[.\s]+: ([0-9.]+)')
              .firstMatch(wirelessSection);
          if (ipMatch != null) {
            ipAddress = ipMatch.group(1) ?? 'Unknown';
          }

          // Extract signal strength
          final signalMatch = RegExp(r'Signal Strength[.\s]+: ([0-9]+)%')
              .firstMatch(wirelessSection);
          if (signalMatch != null) {
            final signalStrength = signalMatch.group(1) ?? 'Unknown';
            speed = '$signalStrength% Signal';
          }
        }
      }

      return {
        'type': type,
        'adapter': adapter,
        'speed': speed,
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
      final result = await Process.run('wmic', [
        'os',
        'get',
        'caption,version,buildnumber,osarchitecture',
        '/format:csv'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get OS info: ${result.stderr}');
      }

      final lines = result.stdout.toString().split('\n');
      if (lines.length < 2) {
        throw Exception('Invalid OS info output');
      }

      // Skip the first line (header) and empty lines
      final dataLine =
          lines.where((line) => line.trim().isNotEmpty).skip(1).first;
      final parts = dataLine.split(',');

      if (parts.length < 5) {
        throw Exception('Invalid OS info format');
      }

      final caption = parts[1].trim();
      final version = parts[2].trim();
      final buildNumber = parts[3].trim();
      final architecture = parts[4].trim();

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

  static Future<Map<String, dynamic>> _getMotherboardInfo() async {
    try {
      final result = await Process.run('wmic', [
        'baseboard',
        'get',
        'manufacturer,product,serialnumber,version',
        '/format:csv'
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to get motherboard info: ${result.stderr}');
      }

      final lines = result.stdout.toString().split('\n');
      if (lines.length < 2) {
        throw Exception('Invalid motherboard info output');
      }

      // Skip the first line (header) and empty lines
      final dataLine =
          lines.where((line) => line.trim().isNotEmpty).skip(1).first;
      final parts = dataLine.split(',');

      if (parts.length < 5) {
        throw Exception('Invalid motherboard info format');
      }

      final manufacturer = parts[1].trim();
      final product = parts[2].trim();

      // Get BIOS version
      final biosResult =
          await Process.run('wmic', ['bios', 'get', 'version', '/format:csv']);
      String biosVersion = 'Unknown';

      if (biosResult.exitCode == 0) {
        final biosLines = biosResult.stdout.toString().split('\n');
        if (biosLines.length >= 2) {
          final biosDataLine =
              biosLines.where((line) => line.trim().isNotEmpty).skip(1).first;
          final biosParts = biosDataLine.split(',');

          if (biosParts.length >= 2) {
            biosVersion = biosParts[1].trim();
          }
        }
      }

      // Determine chipset
      String chipset = 'Unknown';
      if (product.contains('Z690') || product.contains('Z790')) {
        chipset = 'Intel Z690/Z790';
      } else if (product.contains('B660') || product.contains('B760')) {
        chipset = 'Intel B660/B760';
      } else if (product.contains('X570') || product.contains('X670')) {
        chipset = 'AMD X570/X670';
      } else if (product.contains('B550') || product.contains('B650')) {
        chipset = 'AMD B550/B650';
      }

      return {
        'manufacturer': manufacturer,
        'model': product,
        'chipset': chipset,
        'biosVersion': biosVersion,
      };
    } catch (e) {
      print('Error getting motherboard info: $e');
      return {
        'manufacturer': 'Unknown',
        'model': 'Unknown',
        'chipset': 'Unknown',
        'biosVersion': 'Unknown',
      };
    }
  }
}

import 'package:flutter/material.dart';
import 'utils/hardware_utils.dart';

void main() {
  runApp(const TestHardwareApp());
}

class TestHardwareApp extends StatelessWidget {
  const TestHardwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hardware Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestHardwareScreen(),
    );
  }
}

class TestHardwareScreen extends StatefulWidget {
  const TestHardwareScreen({super.key});

  @override
  State<TestHardwareScreen> createState() => _TestHardwareScreenState();
}

class _TestHardwareScreenState extends State<TestHardwareScreen> {
  Map<String, dynamic> _hardwareInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHardwareInfo();
  }

  Future<void> _loadHardwareInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hardwareInfo = await HardwareUtils.getDetailedHardwareInfo();
      setState(() {
        _hardwareInfo = hardwareInfo;
        _isLoading = false;
      });
      
      // Print debug info
      print('CPU Info: ${hardwareInfo['cpu']}');
      print('GPU Info: ${hardwareInfo['gpu']}');
    } catch (e) {
      print('Error loading hardware info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Test'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CPU Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_hardwareInfo.containsKey('cpu'))
                    ..._hardwareInfo['cpu'].entries.map<Widget>((entry) => Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        )),
                  const SizedBox(height: 16),
                  const Text(
                    'GPU Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_hardwareInfo.containsKey('gpu'))
                    ..._hardwareInfo['gpu'].entries.map<Widget>((entry) => Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        )),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHardwareInfo,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
    );
  }
}

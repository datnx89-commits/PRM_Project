import 'package:flutter/material.dart';
import 'data/services/database_seeder.dart';
import 'data/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const SeedRunnerApp());
}

class SeedRunnerApp extends StatelessWidget {
  const SeedRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SeedRunnerScreen(),
    );
  }
}

class SeedRunnerScreen extends StatefulWidget {
  const SeedRunnerScreen({super.key});

  @override
  State<SeedRunnerScreen> createState() => _SeedRunnerScreenState();
}

class _SeedRunnerScreenState extends State<SeedRunnerScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;
  bool _isFinished = false;

  Future<void> _startSeeding() async {
    setState(() {
      _isRunning = true;
      _isFinished = false;
      _logs.clear();
    });

    try {
      final seeder = DatabaseSeeder();
      await seeder.seedAll(
        onProgress: (msg) {
          setState(() {
            _logs.add(msg);
          });
        },
      );
      setState(() {
        _isFinished = true;
      });
    } catch (e) {
      setState(() {
        _logs.add('Lỗi trong quá trình nạp dữ liệu: $e');
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công cụ khởi tạo dữ liệu mẫu (Seed Data)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _isFinished ? Colors.green : Colors.blueGrey,
              ),
              onPressed: _isRunning ? null : _startSeeding,
              child: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isFinished ? 'Nạp lại dữ liệu mẫu' : 'Bắt đầu nạp dữ liệu mẫu lên Firestore',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhật ký tiến trình:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logs.isEmpty
                    ? const Text(
                        'Chưa có hoạt động. Nhấn nút bên trên để bắt đầu.',
                        style: TextStyle(color: Colors.white70),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              '> ${_logs[index]}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 13,
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
    );
  }
}

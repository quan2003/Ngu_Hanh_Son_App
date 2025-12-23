import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Simple test screen to navigate to the boundaries map
class TestBoundariesScreen extends StatelessWidget {
  const TestBoundariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Boundaries Map'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 32),
            const Text(
              'Kiểm tra Bản đồ Ranh giới',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Click nút bên dưới để xem bản đồ ranh giới các tổ dân phố với đường line từ file GeoJSON',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/map-boundaries');
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Xem Bản đồ Ranh giới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

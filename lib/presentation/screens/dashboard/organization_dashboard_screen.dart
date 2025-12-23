import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/organization_provider.dart';
import '../chi_bo/to_chuc_dang_list_screen.dart';
import '../chi_bo/to_dan_pho_list_screen.dart';

class OrganizationDashboardScreen extends ConsumerWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toChucDangAsync = ref.watch(toChucDangListProvider);
    final toDanPhoAsync = ref.watch(toDanPhoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Tổ Chức'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tổ chức Đảng Section
            _SectionCard(
              title: 'Tổ chức Đảng',
              icon: Icons.groups,
              color: Colors.red,
              dataAsync: toChucDangAsync,
              onViewAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ToChucDangListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Tổ dân phố Section
            _SectionCard(
              title: 'Tổ dân phố',
              icon: Icons.home,
              color: Colors.blue,
              dataAsync: toDanPhoAsync,
              onViewAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ToDanPhoListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final AsyncValue dataAsync;
  final VoidCallback onViewAll;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.dataAsync,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return dataAsync.when(
      data: (data) {
        final count = (data as List).length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 2,
            child: Column(
              children: [
                Container(
                  color: color,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Tổng: $count bản ghi',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onViewAll,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Xem chi tiết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lỗi tải dữ liệu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        error.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

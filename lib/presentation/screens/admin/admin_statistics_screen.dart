import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';

class AdminStatisticsScreen extends ConsumerWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê & Báo cáo'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: statsAsync.when(
        data: (stats) {
          final totalUsers = stats['totalUsers'] ?? 0;
          final totalFeedbacks = stats['totalFeedbacks'] ?? 0;
          final newUsersThisWeek = stats['newUsersThisWeek'] ?? 0;
          final newFeedbacksToday = stats['newFeedbacksToday'] ?? 0;
          final pendingFeedbacks = stats['pendingFeedbacks'] ?? 0;
          final processingFeedbacks = stats['processingFeedbacks'] ?? 0;
          final completedFeedbacks = stats['completedFeedbacks'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Stats
                const Text(
                  'Tổng quan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      'Tổng người dùng',
                      '$totalUsers',
                      Icons.people,
                      Colors.blue,
                      '+$newUsersThisWeek tuần này',
                    ),
                    _buildStatCard(
                      'Tổng phản ánh',
                      '$totalFeedbacks',
                      Icons.feedback,
                      Colors.orange,
                      '+$newFeedbacksToday hôm nay',
                    ),
                    _buildStatCard(
                      'Chờ duyệt',
                      '$pendingFeedbacks',
                      Icons.pending,
                      Colors.red,
                      'Cần xử lý',
                    ),
                    _buildStatCard(
                      'Đang xử lý',
                      '$processingFeedbacks',
                      Icons.autorenew,
                      Colors.purple,
                      'Theo dõi',
                    ),
                    _buildStatCard(
                      'Hoàn tất',
                      '$completedFeedbacks',
                      Icons.done_all,
                      Colors.green,
                      'Đã xử lý',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Feedback Statistics by Status
                const Text(
                  'Thống kê phản ánh',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSectionCard(
                  title: 'Trạng thái phản ánh',
                  children: [
                    _buildProgressRow('Đã nhận', pendingFeedbacks,
                        totalFeedbacks, Colors.orange),
                    _buildProgressRow('Đang xử lý', processingFeedbacks,
                        totalFeedbacks, Colors.blue),
                    _buildProgressRow('Hoàn tất', completedFeedbacks,
                        totalFeedbacks, Colors.green),
                  ],
                ),

                const SizedBox(height: 24),

                // Summary card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Tóm tắt',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                            'Tổng số người dùng', '$totalUsers người'),
                        _buildSummaryRow(
                            'Tổng phản ánh', '$totalFeedbacks phản ánh'),
                        _buildSummaryRow('Tỷ lệ hoàn thành',
                            '${totalFeedbacks > 0 ? ((completedFeedbacks / totalFeedbacks) * 100).toStringAsFixed(1) : 0}%'),
                        _buildSummaryRow(
                            'Cần xử lý ngay', '$pendingFeedbacks phản ánh'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(adminStatisticsProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int value, int total, Color color) {
    final percentage =
        total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(
                '$value/$total ($percentage%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

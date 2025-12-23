import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/feedback.dart' as entity;
import '../../providers/admin_providers.dart';
import '../../widgets/custom_animated_dialog.dart';
import '../../../data/repositories/admin_feedback_repository.dart';
import '../../../data/repositories/admin_user_repository.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() =>
      _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  String _filterStatus = 'all'; // all, Đã nhận, Đang xử lý, Đã hoàn thành
  final _feedbackRepository = AdminFeedbackRepository();
  final _userRepository = AdminUserRepository();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Map<String, String> _userNames = {}; // Cache user names by userId

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    try {
      final users = await _userRepository.getAllUsers();
      if (!mounted) return;
      setState(() {
        _userNames = {for (var user in users) user.id: user.name};
      });
    } catch (e) {
      print('❌ Error loading user names: $e');
    }
  }

  List<entity.Feedback> _filterFeedbacks(List<entity.Feedback> feedbacks) {
    if (_filterStatus == 'all') return feedbacks;
    return feedbacks.where((f) => f.status == _filterStatus).toList();
  }

  int _countByStatus(List<entity.Feedback> feedbacks, String status) {
    if (status == 'all') return feedbacks.length;
    return feedbacks.where((f) => f.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final feedbacksAsync = ref.watch(adminFeedbacksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Phản ánh'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: feedbacksAsync.when(
        data: (feedbacks) {
          final filteredFeedbacks = _filterFeedbacks(feedbacks);

          return Column(
            children: [
              // Filter
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                            'Tất cả', 'all', _countByStatus(feedbacks, 'all')),
                        _buildFilterChip('Đã nhận', 'Đã nhận',
                            _countByStatus(feedbacks, 'Đã nhận')),
                        _buildFilterChip('Đang xử lý', 'Đang xử lý',
                            _countByStatus(feedbacks, 'Đang xử lý')),
                        _buildFilterChip('Hoàn tất', 'Đã hoàn thành',
                            _countByStatus(feedbacks, 'Đã hoàn thành')),
                      ],
                    ),
                  ],
                ),
              ),

              // Feedback list
              Expanded(
                child: filteredFeedbacks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feedback_outlined,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Không có phản ánh nào',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredFeedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = filteredFeedbacks[index];
                          return _buildFeedbackCard(feedback);
                        },
                      ),
              ),
            ],
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
                onPressed: () => ref.refresh(adminFeedbacksStreamProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      selectedColor: Colors.orange.shade200,
    );
  }

  Widget _buildFeedbackCard(entity.Feedback feedback) {
    final statusColor = _getStatusColor(feedback.status);
    final userName = _userNames[feedback.userId] ?? 'Đang tải...';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.feedback, color: statusColor),
        ),
        title: Text(
          feedback.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    userName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _dateFormat.format(feedback.createdAt),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildStatusBadge(feedback.status),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Danh mục', feedback.category),
                _buildInfoRow('Mô tả', feedback.description),
                _buildInfoRow('Người gửi', userName),

                // Images Gallery
                if (feedback.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Hình ảnh:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: feedback.images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = feedback.images[index];
                        return GestureDetector(
                          onTap: () => _showImageDialog(imageUrl),
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else
                  _buildInfoRow('Hình ảnh', 'Không có'),

                if (feedback.location != null)
                  _buildInfoRow('Vị trí',
                      '${feedback.location!['lat']?.toStringAsFixed(6)}, ${feedback.location!['lng']?.toStringAsFixed(6)}'),
                if (feedback.response != null)
                  _buildInfoRow('Phản hồi', feedback.response!),
                if (feedback.updatedAt != null)
                  _buildInfoRow(
                      'Cập nhật', _dateFormat.format(feedback.updatedAt!)),
                const Divider(height: 24),

                // Actions
                if (feedback.status == 'Đã nhận')
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _updateStatus(feedback, 'Đang xử lý'),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Bắt đầu xử lý'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _updateStatus(feedback, 'Đã hủy'),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Hủy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteFeedback(feedback),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa phản ánh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (feedback.status == 'Đang xử lý')
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(feedback, 'Đã hoàn thành'),
                          icon: const Icon(Icons.done_all),
                          label: const Text('Hoàn tất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(feedback, 'Đã hủy'),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Hủy xử lý'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (feedback.status == 'Đã hoàn thành')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Phản ánh đã được xử lý hoàn tất',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (feedback.status == 'Đã hủy')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Phản ánh đã bị hủy',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteFeedback(feedback),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Xóa phản ánh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã nhận':
        return Colors.orange;
      case 'Đang xử lý':
        return Colors.blue;
      case 'Đã hoàn thành':
        return Colors.green;
      case 'Đã hủy':
        return Colors.orange.shade700;
      case 'Đã xóa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateStatus(entity.Feedback feedback, String newStatus) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Cập nhật trạng thái',
      message: 'Chuyển trạng thái sang "$newStatus"?',
      confirmText: 'Xác nhận',
      confirmColor: Colors.blue,
    );

    if (!confirmed) return;

    try {
      await _feedbackRepository.updateFeedbackStatus(feedback.id, newStatus);

      if (!mounted) return;

      await CustomAnimatedDialog.showSuccess(
        context: context,
        title: 'Thành công',
        message: 'Đã cập nhật trạng thái phản ánh',
      );
    } catch (e) {
      if (!mounted) return;

      await CustomAnimatedDialog.showError(
        context: context,
        title: 'Lỗi',
        message: 'Không thể cập nhật: $e',
      );
    }
  }

  void _deleteFeedback(entity.Feedback feedback) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xóa phản ánh',
      message:
          'Bạn có chắc chắn muốn xóa phản ánh này?\n\nHành động này không thể hoàn tác!',
      confirmText: 'Xóa',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    try {
      // Update status to "deleted" instead of actually deleting
      await _feedbackRepository.updateFeedbackStatus(feedback.id, 'Đã xóa');

      if (!mounted) return;

      await CustomAnimatedDialog.showSuccess(
        context: context,
        title: 'Thành công',
        message: 'Đã xóa phản ánh',
      );

      // Close the detail dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;

      await CustomAnimatedDialog.showError(
        context: context,
        title: 'Lỗi',
        message: 'Không thể xóa: $e',
      );
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Full size image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Không thể tải ảnh\n$error',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

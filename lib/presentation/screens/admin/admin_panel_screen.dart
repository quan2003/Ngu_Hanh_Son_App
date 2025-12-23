import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_animated_dialog.dart';
import 'admin_users_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_statistics_screen.dart';
import 'organization_data_screen.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Quản Trị Hệ Thống'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          appUserAsync.when(
            data: (appUser) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appUser?.displayName ?? 'Admin',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Panel Quản Trị',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trung tâm Dữ liệu Đảng Bộ - Phường Ngũ Hành Sơn',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            const Text(
              'Thống Kê Nhanh',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Real-time stats from Firebase
            _buildStatsSection(ref),

            const SizedBox(height: 24),

            // Management Sections
            const Text(
              'Quản Lý Hệ Thống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildManagementCard(
              context,
              icon: Icons.people_outline,
              title: 'Quản lý Người dùng',
              subtitle: 'Xem, chặn/mở chặn người dùng',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminUsersScreen(),
                ),
              ),
            ),

            _buildManagementCard(
              context,
              icon: Icons.feedback_outlined,
              title: 'Quản lý Phản ánh',
              subtitle: 'Duyệt và xử lý phản ánh từ người dân',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminFeedbackScreen(),
                ),
              ),
            ),

            _buildManagementCard(
              context,
              icon: Icons.admin_panel_settings_outlined,
              title: 'Quản lý Admin',
              subtitle: 'Thêm/xóa quản trị viên',
              color: Colors.purple,
              onTap: () => _showAdminManagement(context, ref),
            ),
            _buildManagementCard(
              context,
              icon: Icons.domain,
              title: 'Quản lý Dữ liệu Tổ chức',
              subtitle: 'Xem Tổ chức Đảng, Tổ dân phố',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrganizationDataScreen(),
                ),
              ),
            ),
            _buildManagementCard(
              context,
              icon: Icons.bar_chart,
              title: 'Thống kê & Báo cáo',
              subtitle: 'Xem chi tiết thống kê hệ thống',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminStatisticsScreen(),
                ),
              ),
            ),

            _buildManagementCard(
              context,
              icon: Icons.group_outlined,
              title: 'Quản lý Đảng viên',
              subtitle: 'Thêm, sửa, xóa thông tin đảng viên',
              color: Colors.red,
              onTap: () => _showPartyMemberManagement(context, ref),
            ),

            _buildManagementCard(
              context,
              icon: Icons.settings_outlined,
              title: 'Cài đặt Hệ thống',
              subtitle: 'Cấu hình chung của hệ thống',
              color: Colors.grey,
              onTap: () => _showSystemSettings(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref) {
    final statsAsync = ref.watch(adminStatisticsProvider);

    return statsAsync.when(
      data: (stats) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Người dùng',
                    value: '${stats['totalUsers'] ?? 0}',
                    subtitle: '+${stats['newUsersThisWeek'] ?? 0} tuần này',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.feedback,
                    title: 'Phản ánh',
                    value: '${stats['totalFeedbacks'] ?? 0}',
                    subtitle: '+${stats['newFeedbacksToday'] ?? 0} hôm nay',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    title: 'Chờ duyệt',
                    value: '${stats['pendingFeedbacks'] ?? 0}',
                    subtitle: 'Phản ánh mới',
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Hoàn tất',
                    value: '${stats['completedFeedbacks'] ?? 0}',
                    subtitle: 'Đã xử lý',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  title: 'Người dùng',
                  value: '...',
                  subtitle: 'Đang tải',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.feedback,
                  title: 'Phản ánh',
                  value: '...',
                  subtitle: 'Đang tải',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminManagement(BuildContext context, WidgetRef ref) async {
    final userService = ref.read(userServiceProvider);
    final adminEmails = await userService.getAdminEmails();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.purple),
                  SizedBox(width: 12),
                  Text(
                    'Quản lý Admin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: adminEmails.length + 1,
                itemBuilder: (context, index) {
                  if (index == adminEmails.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddAdminDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm Admin mới'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    );
                  }

                  final email = adminEmails[index];
                  final isDefault =
                      UserService.defaultAdminEmails.contains(email);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(email),
                      subtitle: isDefault
                          ? const Text(
                              'Admin mặc định',
                              style: TextStyle(color: Colors.green),
                            )
                          : const Text('Có thể xóa'),
                      trailing: isDefault
                          ? const Icon(Icons.lock, color: Colors.grey)
                          : IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _removeAdmin(context, ref, email),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.purple),
            SizedBox(width: 12),
            Text('Thêm Admin mới'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              hintText: 'newadmin@example.com',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                final userService = ref.read(userServiceProvider);
                await userService.addAdminEmail(emailController.text.trim());

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                }

                if (context.mounted) {
                  Navigator.pop(context); // Close bottom sheet

                  await CustomAnimatedDialog.showSuccess(
                    context: context,
                    title: 'Thành công',
                    message: 'Đã thêm admin: ${emailController.text}',
                  );

                  // Refresh admin list by re-opening the management screen
                  _showAdminManagement(context, ref);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                }

                if (context.mounted) {
                  await CustomAnimatedDialog.showError(
                    context: context,
                    title: 'Lỗi',
                    message: 'Không thể thêm admin: $e',
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _removeAdmin(BuildContext context, WidgetRef ref, String email) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc muốn xóa admin:\n$email?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
      confirmColor: Colors.red,
    );

    if (!confirmed || !context.mounted) return;

    final userService = ref.read(userServiceProvider);
    await userService.removeAdminEmail(email);
    if (context.mounted) {
      Navigator.pop(context); // Close bottom sheet

      await CustomAnimatedDialog.showSuccess(
        context: context,
        title: 'Đã xóa',
        message: 'Admin đã được xóa khỏi danh sách',
      );
    }
  }

  void _showPartyMemberManagement(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.group, color: Colors.red),
                  SizedBox(width: 12),
                  Text(
                    'Quản lý Đảng viên',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.person_add,
                      title: 'Thêm Đảng viên mới',
                      subtitle: 'Nhập thông tin đảng viên',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tính năng đang phát triển'),
                            content: const Text(
                                'Chức năng thêm đảng viên sẽ sớm được cập nhật.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildFeatureItem(
                      icon: Icons.search,
                      title: 'Tìm kiếm Đảng viên',
                      subtitle: 'Tra cứu thông tin theo tên, mã',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tính năng đang phát triển'),
                            content: const Text(
                                'Chức năng tìm kiếm đảng viên sẽ sớm được cập nhật.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildFeatureItem(
                      icon: Icons.edit,
                      title: 'Cập nhật thông tin',
                      subtitle: 'Chỉnh sửa hồ sơ đảng viên',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tính năng đang phát triển'),
                            content: const Text(
                                'Chức năng cập nhật thông tin sẽ sớm được cập nhật.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildFeatureItem(
                      icon: Icons.upload_file,
                      title: 'Import từ Excel',
                      subtitle: 'Nhập dữ liệu hàng loạt',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tính năng đang phát triển'),
                            content: const Text(
                                'Chức năng import Excel sẽ sớm được cập nhật.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildFeatureItem(
                      icon: Icons.download,
                      title: 'Export báo cáo',
                      subtitle: 'Xuất danh sách ra Excel',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tính năng đang phát triển'),
                            content: const Text(
                                'Chức năng export báo cáo sẽ sớm được cập nhật.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSystemSettings(BuildContext mainContext, WidgetRef ref) {
    showModalBottomSheet(
      context: mainContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'Cài đặt Hệ thống',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSettingItem(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: 'Cấu hình thông báo đẩy',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showNotificationSettings(mainContext, ref);
                        });
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.security,
                      title: 'Bảo mật',
                      subtitle: 'Cài đặt xác thực và quyền truy cập',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showSecuritySettings(mainContext, ref);
                        });
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.backup,
                      title: 'Sao lưu dữ liệu',
                      subtitle: 'Tự động backup định kỳ',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showBackupSettings(mainContext, ref);
                        });
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.mail,
                      title: 'Email template',
                      subtitle: 'Cấu hình mẫu email gửi người dùng',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showEmailTemplateSettings(mainContext, ref);
                        });
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.color_lens,
                      title: 'Giao diện',
                      subtitle: 'Tùy chỉnh màu sắc, logo',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showThemeSettings(mainContext, ref);
                        });
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.info,
                      title: 'Về ứng dụng',
                      subtitle: 'Phiên bản, giấy phép',
                      onTap: () {
                        Navigator.pop(context);
                        showAboutDialog(
                          context: context,
                          applicationName: 'NHS App - Quản Trị',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: Colors.red,
                          ),
                          children: [
                            const Text(
                              'Hệ thống quản lý Đảng bộ Phường Ngũ Hành Sơn',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '© 2025 - All rights reserved',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.grey.shade700),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
  // ==================== SYSTEM SETTINGS IMPLEMENTATIONS ====================

  void _showNotificationSettings(BuildContext context, WidgetRef ref) async {
    final settingsService = ref.read(systemSettingsServiceProvider);
    final currentSettings = await settingsService.getNotificationSettings();

    bool pushEnabled = currentSettings['pushEnabled'] ?? true;
    bool emailEnabled = currentSettings['emailEnabled'] ?? true;
    bool smsEnabled = currentSettings['smsEnabled'] ?? false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange),
              SizedBox(width: 12),
              Text('Cài đặt Thông báo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Thông báo đẩy (Push)'),
                subtitle: const Text('Gửi qua Firebase Cloud Messaging'),
                value: pushEnabled,
                onChanged: (value) => setState(() => pushEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Thông báo Email'),
                subtitle: const Text('Gửi qua email người dùng'),
                value: emailEnabled,
                onChanged: (value) => setState(() => emailEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Thông báo SMS'),
                subtitle: const Text('Gửi qua tin nhắn điện thoại'),
                value: smsEnabled,
                onChanged: (value) => setState(() => smsEnabled = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await settingsService.updateNotificationSettings(
                    pushEnabled: pushEnabled,
                    emailEnabled: emailEnabled,
                    smsEnabled: smsEnabled,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showSuccess(
                      context: context,
                      title: 'Đã lưu',
                      message: 'Cài đặt thông báo đã được cập nhật',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showError(
                      context: context,
                      title: 'Lỗi',
                      message: 'Không thể lưu cài đặt: $e',
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecuritySettings(BuildContext context, WidgetRef ref) async {
    final settingsService = ref.read(systemSettingsServiceProvider);
    final currentSettings = await settingsService.getSecuritySettings();

    bool twoFactorAuth = currentSettings['twoFactorAuth'] ?? false;
    bool requireEmailVerification =
        currentSettings['requireEmailVerification'] ?? true;
    int sessionTimeout = currentSettings['sessionTimeout'] ?? 30;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red),
              SizedBox(width: 12),
              Text('Cài đặt Bảo mật'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Xác thực 2 yếu tố'),
                  subtitle: const Text('Bắt buộc OTP khi đăng nhập'),
                  value: twoFactorAuth,
                  onChanged: (value) => setState(() => twoFactorAuth = value),
                ),
                SwitchListTile(
                  title: const Text('Xác minh Email'),
                  subtitle: const Text('Yêu cầu xác minh email khi đăng ký'),
                  value: requireEmailVerification,
                  onChanged: (value) =>
                      setState(() => requireEmailVerification = value),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Thời gian phiên làm việc'),
                  subtitle: Text('$sessionTimeout phút'),
                  trailing: DropdownButton<int>(
                    value: sessionTimeout,
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 phút')),
                      DropdownMenuItem(value: 30, child: Text('30 phút')),
                      DropdownMenuItem(value: 60, child: Text('60 phút')),
                      DropdownMenuItem(value: 120, child: Text('2 giờ')),
                    ],
                    onChanged: (value) =>
                        setState(() => sessionTimeout = value!),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await settingsService.updateSecuritySettings(
                    twoFactorAuth: twoFactorAuth,
                    requireEmailVerification: requireEmailVerification,
                    sessionTimeout: sessionTimeout,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showSuccess(
                      context: context,
                      title: 'Đã lưu',
                      message: 'Cài đặt bảo mật đã được cập nhật',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showError(
                      context: context,
                      title: 'Lỗi',
                      message: 'Không thể lưu cài đặt: $e',
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupSettings(BuildContext context, WidgetRef ref) async {
    final settingsService = ref.read(systemSettingsServiceProvider);
    final currentSettings = await settingsService.getBackupSettings();

    bool autoBackup = currentSettings['autoBackup'] ?? true;
    String backupFrequency = currentSettings['backupFrequency'] ?? 'daily';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.backup, color: Colors.blue),
              SizedBox(width: 12),
              Text('Cài đặt Sao lưu'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Tự động sao lưu'),
                subtitle: const Text('Backup dữ liệu định kỳ'),
                value: autoBackup,
                onChanged: (value) => setState(() => autoBackup = value),
              ),
              if (autoBackup) ...[
                const Divider(),
                ListTile(
                  title: const Text('Tần suất sao lưu'),
                  trailing: DropdownButton<String>(
                    value: backupFrequency,
                    items: const [
                      DropdownMenuItem(
                          value: 'daily', child: Text('Hàng ngày')),
                      DropdownMenuItem(
                          value: 'weekly', child: Text('Hàng tuần')),
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Hàng tháng')),
                    ],
                    onChanged: (value) =>
                        setState(() => backupFrequency = value!),
                  ),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Tải xuống Backup'),
                subtitle: const Text('Export toàn bộ dữ liệu'),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await settingsService.updateBackupSettings(
                    autoBackup: autoBackup,
                    backupFrequency: backupFrequency,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showSuccess(
                      context: context,
                      title: 'Đã lưu',
                      message: 'Cài đặt sao lưu đã được cập nhật',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showError(
                      context: context,
                      title: 'Lỗi',
                      message: 'Không thể lưu cài đặt: $e',
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang xuất dữ liệu...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context);
      await CustomAnimatedDialog.showInfo(
        context: context,
        title: 'Xuất dữ liệu',
        message:
            'Chức năng export dữ liệu sẽ được hoàn thiện trong phiên bản sau.\n\nDữ liệu sẽ được xuất ra định dạng JSON/Excel.',
      );
    }
  }

  void _showEmailTemplateSettings(BuildContext context, WidgetRef ref) async {
    final settingsService = ref.read(systemSettingsServiceProvider);
    final templates = await settingsService.getEmailTemplates();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mail, color: Colors.purple),
            SizedBox(width: 12),
            Text('Email Templates'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(template['name'] as String),
                  subtitle: Text(template['subject'] as String),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _editEmailTemplate(context, ref, template);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _editEmailTemplate(
      BuildContext context, WidgetRef ref, Map<String, dynamic> template) {
    final settingsService = ref.read(systemSettingsServiceProvider);
    final subjectController =
        TextEditingController(text: template['subject'] as String);
    final bodyController = TextEditingController(
      text: template['body'] as String? ??
          'Xin chào {userName},\n\nNội dung email...',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa: ${template['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Nội dung email',
                  border: OutlineInputBorder(),
                  helperText: 'Biến: {userName}, {feedbackTitle}, {status}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await settingsService.updateEmailTemplate(
                  type: template['type'] as String,
                  name: template['name'] as String,
                  subject: subjectController.text,
                  body: bodyController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  await CustomAnimatedDialog.showSuccess(
                    context: context,
                    title: 'Đã lưu',
                    message: 'Email template đã được cập nhật',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  await CustomAnimatedDialog.showError(
                    context: context,
                    title: 'Lỗi',
                    message: 'Không thể lưu template: $e',
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showThemeSettings(BuildContext context, WidgetRef ref) async {
    final themeNotifier = ref.read(themeProvider.notifier);

    bool darkMode = themeNotifier.isDarkMode;
    Color primaryColor = themeNotifier.primaryColor;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.color_lens, color: Colors.purple),
              SizedBox(width: 12),
              Text('Cài đặt Giao diện'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Chế độ tối'),
                  subtitle: const Text('Giao diện tối (Dark mode)'),
                  value: darkMode,
                  onChanged: (value) => setState(() => darkMode = value),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Màu chủ đạo'),
                  subtitle: const Text('Nhấn để chọn màu'),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  onTap: () async {
                    Color? selectedColor = await showDialog<Color>(
                      context: context,
                      builder: (BuildContext pickerContext) {
                        Color tempColor = primaryColor;
                        return StatefulBuilder(
                          builder: (context, setPickerState) => AlertDialog(
                            title: const Text('Chọn màu chủ đạo'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Color preview
                                  Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: tempColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Màu đã chọn',
                                        style: TextStyle(
                                          color:
                                              tempColor.computeLuminance() > 0.5
                                                  ? Colors.black
                                                  : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  BlockPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (Color color) {
                                      setPickerState(() {
                                        tempColor = color;
                                      });
                                    },
                                    availableColors: const [
                                      Colors.red,
                                      Colors.pink,
                                      Colors.purple,
                                      Colors.deepPurple,
                                      Colors.indigo,
                                      Colors.blue,
                                      Colors.lightBlue,
                                      Colors.cyan,
                                      Colors.teal,
                                      Colors.green,
                                      Colors.lightGreen,
                                      Colors.lime,
                                      Colors.yellow,
                                      Colors.amber,
                                      Colors.orange,
                                      Colors.deepOrange,
                                      Colors.brown,
                                      Colors.grey,
                                      Colors.blueGrey,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(pickerContext),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(pickerContext, tempColor),
                                child: const Text('Chọn'),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (selectedColor != null) {
                      setState(() {
                        primaryColor = selectedColor;
                      });
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Logo ứng dụng'),
                  subtitle: const Text('Tải lên logo mới'),
                  trailing: const Icon(Icons.upload_file),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadLogo(context, ref);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update theme using themeProvider
                  await themeNotifier.updateTheme(darkMode, primaryColor);

                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showSuccess(
                      context: context,
                      title: 'Đã lưu',
                      message: 'Cài đặt giao diện đã được áp dụng thành công!',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    await CustomAnimatedDialog.showError(
                      context: context,
                      title: 'Lỗi',
                      message: 'Không thể lưu cài đặt: $e',
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadLogo(BuildContext context, WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!context.mounted) return;

      // Show uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải lên logo...'),
            ],
          ),
        ),
      );

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final logoRef = storageRef.child('app_settings/logo.png');

      final File file = File(image.path);
      await logoRef.putFile(file);

      // Get download URL
      final downloadUrl = await logoRef.getDownloadURL();

      // Save to system settings
      final settingsService = ref.read(systemSettingsServiceProvider);
      final themeNotifier = ref.read(themeProvider.notifier);
      await settingsService.updateThemeSettings(
        logoUrl: downloadUrl,
        darkMode: themeNotifier.isDarkMode,
        primaryColorValue: themeNotifier.primaryColor.value,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close uploading dialog
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Thành công',
          message: 'Logo đã được cập nhật!\nKhởi động lại app để xem thay đổi.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close uploading dialog
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể tải lên logo: $e',
        );
      }
    }
  }
}

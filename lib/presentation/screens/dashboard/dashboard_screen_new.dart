import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/organization_provider.dart';
import '../admin/admin_panel_screen.dart';

/// Simplified Dashboard using real Firebase data
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final toChucDangAsync = ref.watch(toChucDangListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏛️ Tổ chức Đảng'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'logout') {
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(toChucDangListProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appUserAsync.when(
                        data: (user) => Text(
                          'Xin chào, ${user?.displayName ?? "Người dùng"}!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        loading: () =>
                            CircularProgressIndicator(color: Colors.white),
                        error: (_, __) => Text('Xin chào!',
                            style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Dữ liệu từ Firebase - Real-time',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Admin Panel
              appUserAsync.when(
                data: (user) {
                  if (user?.isAdmin ?? false) {
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading:
                            Icon(Icons.admin_panel_settings, color: Colors.red),
                        title: Text('Admin Panel',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Quản trị hệ thống'),
                        trailing: Icon(Icons.arrow_forward, color: Colors.red),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminPanelScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return SizedBox();
                },
                loading: () => SizedBox(),
                error: (_, __) => SizedBox(),
              ),

              SizedBox(height: 24),

              // Quick Links
              Text(
                'Truy cập nhanh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.domain, color: Colors.blue),
                  title: Text('Danh sách Tổ Chức Đảng'),
                  subtitle: toChucDangAsync.when(
                    data: (list) => Text('${list.length} tổ chức đảng'),
                    loading: () => Text('Đang tải...'),
                    error: (_, __) => Text('Lỗi'),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navigate to organization list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đang phát triển tính năng này')),
                    );
                  },
                ),
              ),

              SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '✅ Dữ liệu được lấy trực tiếp từ Firebase Firestore',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '✅ Không còn dữ liệu mẫu cố định',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '✅ Admin có thể quản lý dữ liệu qua Admin Panel',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Dùng prefix để tránh mơ hồ tên
import '../../../core/theme/app_colors.dart' as theme;
import '../../../core/constants/app_constants.dart' as c;

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_animated_dialog.dart';
import '../dashboard/dashboard_screen.dart';
import '../to_dan_pho/to_dan_pho_screen.dart';
import '../map/map_screen.dart'; // Version cũ - có thể lag
// Version tối ưu - mượt mà ⚡
import '../feedback/feedback_screen.dart';
import '../../../data/services/push_notification_service.dart';
import '../../../data/services/supabase_notification_listener_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Setup notifications when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
    });
  }

  Future<void> _setupNotifications() async {
    try {
      debugPrint('🏠 HOME: Setting up notifications...');

      final authService = ref.read(firebaseAuthServiceProvider);
      final user = authService.currentUser;

      if (user == null) {
        debugPrint('⚠️ HOME: No user found');
        return;
      }

      debugPrint('👤 HOME: Current user: ${user.uid}');

      final pushNotificationService = PushNotificationService();
      debugPrint(
          '🔔 HOME: Push service initialized: ${pushNotificationService.isInitialized}');

      if (!pushNotificationService.isInitialized) {
        debugPrint('⏳ HOME: Waiting for push service...');
        await Future.delayed(const Duration(seconds: 1));
      }

      if (pushNotificationService.isInitialized) {
        // Save FCM token
        debugPrint('💾 HOME: Saving FCM token...');
        await pushNotificationService.saveFCMToken(user.uid);
        debugPrint('✅ HOME: FCM token saved');
        debugPrint(
            '📱 HOME: Token: ${pushNotificationService.fcmToken}'); // Start notification listener
        debugPrint('🎧 HOME: Starting notification listener...');
        final notificationListener = SupabaseNotificationListenerService();
        await notificationListener.startListening(user.uid);
        debugPrint('✅ HOME: Notification listener started');
      } else {
        debugPrint('⚠️ HOME: Push service not ready');
      }
    } catch (e, stack) {
      debugPrint('❌ HOME: Error setting up notifications: $e');
      debugPrint('Stack: $stack');
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ToDanPhoScreen(),
    // MapScreenOptimized(), // Version tối ưu - mượt mà ⚡
    const MapScreen(), // Version cũ - có thể lag
    const FeedbackScreen(),
  ];

  final List<String> _screenTitles = const [
    'Tổ chức Đảng',
    'Tổ dân phố',
    'Bản đồ',
    'Góp ý',
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_outlined),
      activeIcon: Icon(Icons.account_balance),
      label: 'Tổ chức Đảng',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outlined),
      activeIcon: Icon(Icons.people),
      label: 'Tổ dân phố',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'Bản đồ',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.feedback_outlined),
      activeIcon: Icon(Icons.feedback),
      label: 'Góp ý',
    ),
  ];

  Future<void> _handleLogout() async {
    final confirm = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xác nhận đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
    );

    if (confirm != true || !mounted) return;

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final userService = ref.read(userServiceProvider);

      await authService.logout();
      await userService.clearUser();

      if (mounted) {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đăng xuất thành công',
          message: 'Hẹn gặp lại bạn!',
        );

        if (mounted) {
          context.go(c.AppConstants.welcomeRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi đăng xuất',
          message: e.toString(),
        );
      }
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                title == 'Đăng xuất' ? FontWeight.w600 : FontWeight.w500,
            color: title == 'Đăng xuất' ? color : theme.AppColors.textPrimary,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: color.withOpacity(0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.AppColors.primary,
                theme.AppColors.primaryDark,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            title: Text(
              _screenTitles[_currentIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Notification icon with badge
              Consumer(
                builder: (context, ref, child) {
                  final unreadCountAsync =
                      ref.watch(unreadNotificationsCountProvider);

                  return unreadCountAsync.when(
                    data: (count) => Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            context.push('/notifications');
                          },
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: theme.AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    loading: () => IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                    error: (_, __) => IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAFAFA),
                Colors.white,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // User Header
              appUserAsync.when(
                data: (appUser) {
                  final displayName = appUser?.displayName ?? 'Người dùng';
                  final email = appUser?.email ?? '';
                  final isAdmin = appUser?.isAdmin ?? false;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.AppColors.primary,
                          theme.AppColors.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: UserAccountsDrawerHeader(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      currentAccountPicture: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: appUser?.photoURL != null
                              ? NetworkImage(appUser!.photoURL!)
                              : null,
                          child: appUser?.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 35,
                                  color: theme.AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      accountName: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      accountEmail: Row(
                        children: [
                          Flexible(
                            child: Text(
                              email,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.AppColors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                loading: () => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.AppColors.primary,
                        theme.AppColors.primaryDark,
                      ],
                    ),
                  ),
                  child: const UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    accountName: Text('Đang tải...'),
                    accountEmail: Text(''),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.AppColors.primary,
                        theme.AppColors.primaryDark,
                      ],
                    ),
                  ),
                  child: const UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    accountName: Text('Lỗi tải dữ liệu'),
                    accountEmail: Text(''),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              _buildDrawerItem(
                context,
                icon: Icons.person_outline,
                title: 'Thông tin cá nhân',
                color: theme.AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),

              _buildDrawerItem(
                context,
                icon: Icons.settings_outlined,
                title: 'Cài đặt',
                color: theme.AppColors.grey600,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),

              // Admin Panel (chỉ hiện nếu là admin)
              appUserAsync.when(
                data: (appUser) {
                  if (appUser?.isAdmin ?? false) {
                    return _buildDrawerItem(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Quản trị viên',
                      color: theme.AppColors.error,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.AppColors.error.withOpacity(0.2),
                              theme.AppColors.error.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.AppColors.error,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Divider(height: 24, thickness: 1),

              _buildDrawerItem(
                context,
                icon: Icons.map_outlined,
                title: 'Bản đồ Ranh giới',
                color: Colors.green,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.2),
                        Colors.green.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Mới',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/map-boundaries');
                },
              ),

              _buildDrawerItem(
                context,
                icon: Icons.help_outline,
                title: 'Trợ giúp',
                color: theme.AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/help');
                },
              ),

              _buildDrawerItem(
                context,
                icon: Icons.info_outline,
                title: 'Về ứng dụng',
                color: theme.AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: c.AppConstants.appName,
                    applicationVersion: c.AppConstants.appVersion,
                    applicationLegalese: '© 2025 ${c.AppConstants.appSubtitle}',
                    children: const [
                      SizedBox(height: 16),
                      Text(
                        'Ứng dụng quản lý dữ liệu Đảng bộ phường Ngũ Hành Sơn',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                },
              ),

              const Divider(height: 24, thickness: 1),

              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Đăng xuất',
                color: theme.AppColors.error,
                onTap: _handleLogout,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: _navItems,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.AppColors.primary,
          unselectedItemColor: theme.AppColors.grey500,
          showUnselectedLabels: true,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/push_notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_animated_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _preferencesService = PreferencesService();
  final _pushNotificationService = PushNotificationService();
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _language = 'vi';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notificationsEnabled =
        await _preferencesService.getNotificationsEnabled();
    final emailNotifications =
        await _preferencesService.getEmailNotifications();
    final pushNotifications = await _preferencesService.getPushNotifications();
    final darkMode = await _preferencesService.getDarkMode();
    final language = await _preferencesService.getLanguage();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _emailNotifications = emailNotifications;
        _pushNotifications = pushNotifications;
        _darkMode = darkMode;
        _language = language;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Tài khoản'),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              appUserAsync.when(
                data: (user) => _buildInfoTile(
                  icon: Icons.person_outline,
                  title: 'Tên người dùng',
                  subtitle: user?.displayName ?? 'Chưa cập nhật',
                  onTap: () {},
                ),
                loading: () => _buildInfoTile(
                  icon: Icons.person_outline,
                  title: 'Tên người dùng',
                  subtitle: 'Đang tải...',
                  onTap: () {},
                ),
                error: (_, __) => _buildInfoTile(
                  icon: Icons.person_outline,
                  title: 'Tên người dùng',
                  subtitle: 'Lỗi',
                  onTap: () {},
                ),
              ),
              const Divider(height: 1),
              appUserAsync.when(
                data: (user) => _buildInfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: user?.email ?? '',
                  onTap: () {},
                ),
                loading: () => _buildInfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'Đang tải...',
                  onTap: () {},
                ),
                error: (_, __) => _buildInfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'Lỗi',
                  onTap: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Thông báo'),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Bật thông báo',
                subtitle: 'Nhận thông báo từ ứng dụng',
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  await _preferencesService.setNotificationsEnabled(value);
                  if (!value) {
                    setState(() {
                      _emailNotifications = false;
                      _pushNotifications = false;
                    });
                    await _preferencesService.setEmailNotifications(false);
                    await _preferencesService.setPushNotifications(false);
                  }
                },
              ),
              if (_notificationsEnabled) ...[
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Thông báo Email',
                  subtitle: 'Nhận thông báo qua email',
                  value: _emailNotifications,
                  onChanged: (value) async {
                    setState(() => _emailNotifications = value);
                    await _preferencesService.setEmailNotifications(value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.phone_android_outlined,
                  title: 'Thông báo đẩy',
                  subtitle: 'Nhận thông báo đẩy trên thiết bị',
                  value: _pushNotifications,
                  onChanged: (value) async {
                    try {
                      final user = ref.read(currentUserProvider);
                      if (user == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Vui lòng đăng nhập để bật thông báo đẩy'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() => _pushNotifications = value);
                      await _preferencesService.setPushNotifications(value);

                      // Enable/disable push notifications via FCM
                      if (value) {
                        await _pushNotificationService
                            .enableNotifications(user.uid);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                        'Đã bật thông báo đẩy. Bạn sẽ nhận được thông báo quan trọng.'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } else {
                        await _pushNotificationService
                            .disableNotifications(user.uid);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã tắt thông báo đẩy'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: ${e.toString()}'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                      // Rollback state on error
                      setState(() => _pushNotifications = !value);
                    }
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Giao diện'),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Chế độ tối',
                subtitle: 'Sử dụng giao diện tối',
                value: _darkMode,
                onChanged: (value) async {
                  setState(() => _darkMode = value);
                  await _preferencesService.setDarkMode(value);

                  // Update theme provider
                  final themeNotifier = ref.read(themeProvider.notifier);
                  await themeNotifier.updateTheme(
                    value,
                    const Color(0xFFB71C1C), // Primary color
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              value ? Icons.dark_mode : Icons.light_mode,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(value
                                ? 'Đã bật chế độ tối'
                                : 'Đã tắt chế độ tối'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.language_outlined,
                title: 'Ngôn ngữ',
                subtitle: _language == 'vi' ? 'Tiếng Việt' : 'English',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data & Storage Section
          _buildSectionHeader('Dữ liệu & Bộ nhớ'),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildListTile(
                icon: Icons.storage_outlined,
                title: 'Quản lý bộ nhớ',
                subtitle: 'Xóa dữ liệu cache và tạm thời',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(),
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.download_outlined,
                title: 'Tải dữ liệu xuống',
                subtitle: 'Tải xuống dữ liệu cá nhân',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDownloadDataDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader('Bảo mật'),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildListTile(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                subtitle: 'Cập nhật mật khẩu của bạn',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(),
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.security_outlined,
                title: 'Xác thực hai yếu tố',
                subtitle: 'Tăng cường bảo mật tài khoản',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Sắp ra mắt',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Quyền riêng tư',
                subtitle: 'Quản lý quyền riêng tư của bạn',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('Về ứng dụng'),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: 'Phiên bản',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article_outlined,
                      color: AppColors.primary, size: 20),
                ),
                title: const Text(
                  'Điều khoản sử dụng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Xem điều khoản',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTermsDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.policy_outlined,
                      color: AppColors.primary, size: 20),
                ),
                title: const Text(
                  'Chính sách bảo mật',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Bảo vệ dữ liệu',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyPolicyDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.grey600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey600,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.grey600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey600,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Chọn ngôn ngữ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: _language,
              onChanged: (value) async {
                setState(() => _language = value!);
                await _preferencesService.setLanguage(value!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã chuyển sang Tiếng Việt'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) async {
                setState(() => _language = value!);
                await _preferencesService.setLanguage(value!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Xóa bộ nhớ cache'),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa dữ liệu cache?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Điều này sẽ:',
              style: TextStyle(color: AppColors.grey600),
            ),
            SizedBox(height: 4),
            Text('• Giải phóng bộ nhớ thiết bị',
                style: TextStyle(fontSize: 13)),
            Text('• Xóa dữ liệu tạm thời', style: TextStyle(fontSize: 13)),
            Text('• Có thể làm chậm ứng dụng lần mở đầu',
                style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Clear cache directory
        final cacheDir = await getTemporaryDirectory();
        if (cacheDir.existsSync()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đã xóa cache thành công'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDownloadDataDialog() async {
    final appUser = await ref.read(currentAppUserProvider.future);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Tải dữ liệu xuống'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dữ liệu của bạn sẽ được tải xuống dưới dạng file JSON bao gồm:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDataItem('Thông tin cá nhân', appUser?.displayName ?? 'N/A'),
            _buildDataItem('Email', appUser?.email ?? 'N/A'),
            _buildDataItem(
                'Số điện thoại', appUser?.phoneNumber ?? 'Chưa cập nhật'),
            _buildDataItem(
                'Vai trò', appUser?.isAdmin == true ? 'Admin' : 'User'),
            const SizedBox(height: 12),
            const Text(
              'Dữ liệu sẽ được lưu vào thư mục Downloads của bạn.',
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              if (mounted) {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Request storage permission
                  var status = await Permission.storage.status;
                  if (!status.isGranted) {
                    status = await Permission.storage.request();
                  }

                  // Create user data JSON
                  final userData = {
                    'exportedAt': DateTime.now().toIso8601String(),
                    'user': {
                      'uid': appUser?.uid,
                      'displayName': appUser?.displayName,
                      'email': appUser?.email,
                      'phoneNumber': appUser?.phoneNumber,
                      'role': appUser?.role.name,
                      'isAdmin': appUser?.isAdmin,
                      'createdAt': appUser?.createdAt?.toIso8601String(),
                      'lastLogin': appUser?.lastLogin?.toIso8601String(),
                    },
                    'preferences': {
                      'notificationsEnabled': _notificationsEnabled,
                      'emailNotifications': _emailNotifications,
                      'pushNotifications': _pushNotifications,
                      'darkMode': _darkMode,
                      'language': _language,
                    }
                  };

                  // Convert to JSON string
                  final jsonString =
                      const JsonEncoder.withIndent('  ').convert(userData);

                  // Get Downloads directory
                  Directory? directory;
                  if (Platform.isAndroid) {
                    directory = Directory('/storage/emulated/0/Download');
                    if (!await directory.exists()) {
                      directory = await getExternalStorageDirectory();
                    }
                  } else {
                    directory = await getApplicationDocumentsDirectory();
                  }

                  // Create file name with timestamp
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final fileName = 'user_data_$timestamp.json';
                  final filePath = '${directory?.path}/$fileName';

                  // Write to file
                  final file = File(filePath);
                  await file.writeAsString(jsonString);

                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    await CustomAnimatedDialog.showSuccess(
                      context: context,
                      title: 'Thành công',
                      message: 'Dữ liệu đã được lưu vào:\n$filePath',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    await CustomAnimatedDialog.showError(
                      context: context,
                      title: 'Lỗi',
                      message: 'Không thể tải dữ liệu: ${e.toString()}',
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download),
            label: const Text('Tải xuống'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isObscureCurrent = true;
    bool isObscureNew = true;
    bool isObscureConfirm = true;
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              const Text('Đổi mật khẩu'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yêu cầu mật khẩu:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Ít nhất 6 ký tự\n• Bao gồm chữ và số\n• Khác mật khẩu cũ',
                  style: TextStyle(fontSize: 11, color: AppColors.grey600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: isObscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => isObscureCurrent = !isObscureCurrent);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: isObscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => isObscureNew = !isObscureNew);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: isObscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => isObscureConfirm = !isObscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (currentPasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng điền đầy đủ thông tin'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu xác nhận không khớp'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final authService =
                            ref.read(firebaseAuthServiceProvider);
                        await authService.changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${e.toString()}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (result == true && mounted) {
      await CustomAnimatedDialog.showSuccess(
        context: context,
        title: 'Thành công',
        message: 'Đổi mật khẩu thành công',
      );
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.privacy_tip_outlined, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            const Text('Quyền riêng tư'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cài đặt quyền riêng tư:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Dữ liệu của bạn được mã hóa và bảo vệ'),
              Text('• Thông tin cá nhân không được chia sẻ'),
              Text('• Bạn có quyền xóa dữ liệu bất kỳ lúc nào'),
              SizedBox(height: 12),
              Text(
                'Để biết thêm chi tiết, vui lòng xem Chính sách bảo mật.',
                style: TextStyle(fontSize: 12, color: AppColors.grey600),
              ),
            ],
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_outlined, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Điều khoản sử dụng'),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Chấp nhận điều khoản',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Bằng cách sử dụng ứng dụng, bạn đồng ý với các điều khoản này.'),
              SizedBox(height: 16),
              Text(
                '2. Sử dụng dịch vụ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Bạn cam kết sử dụng ứng dụng một cách hợp pháp và đúng mục đích.'),
              SizedBox(height: 16),
              Text(
                '3. Quyền sở hữu trí tuệ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Mọi nội dung trong ứng dụng thuộc quyền sở hữu của chúng tôi.'),
            ],
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

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.policy_outlined, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Chính sách bảo mật'),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thu thập dữ liệu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Chúng tôi thu thập:'),
              Text('• Thông tin cá nhân (tên, email, số điện thoại)'),
              Text('• Dữ liệu sử dụng ứng dụng'),
              SizedBox(height: 16),
              Text(
                'Sử dụng dữ liệu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Dữ liệu được sử dụng để:'),
              Text('• Cung cấp và cải thiện dịch vụ'),
              Text('• Bảo mật tài khoản'),
              Text('• Gửi thông báo quan trọng'),
              SizedBox(height: 16),
              Text(
                'Bảo vệ dữ liệu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Chúng tôi sử dụng các biện pháp bảo mật tiêu chuẩn công nghiệp để bảo vệ dữ liệu của bạn.'),
            ],
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
}

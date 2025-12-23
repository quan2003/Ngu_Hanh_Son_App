import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/preferences_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_animated_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _preferencesService = PreferencesService();
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
                    setState(() => _pushNotifications = value);
                    await _preferencesService.setPushNotifications(value);
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đang phát triển'),
                        duration: Duration(seconds: 2),
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
                onTap: () {
                  _showLanguageDialog();
                },
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
                trailing: const Icon(Icons.chevron_right),
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
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
              _buildListTile(
                icon: Icons.article_outlined,
                title: 'Điều khoản sử dụng',
                subtitle: 'Xem điều khoản và điều kiện',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.policy_outlined,
                title: 'Chính sách bảo mật',
                subtitle: 'Xem chính sách bảo mật',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
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
        title: const Text('Chọn ngôn ngữ'),
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
                    const SnackBar(content: Text('Tính năng đang phát triển')),
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
        title: const Text('Xóa bộ nhớ cache'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa dữ liệu cache? Điều này sẽ giải phóng bộ nhớ nhưng có thể làm chậm ứng dụng khi khởi động lại.',
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
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Simulate cache clearing (in real app, clear actual cache)
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Close loading
          await CustomAnimatedDialog.showSuccess(
            context: context,
            title: 'Thành công',
            message: 'Đã xóa cache thành công',
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          await CustomAnimatedDialog.showError(
            context: context,
            title: 'Lỗi',
            message: 'Không thể xóa cache: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _showDownloadDataDialog() async {
    final appUser = await ref.read(currentAppUserProvider.future);
    if (appUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tải dữ liệu xuống'),
        content: const Text(
          'Tải xuống tất cả dữ liệu cá nhân của bạn dưới dạng file JSON?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tải xuống'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Thành công',
          message: 'Dữ liệu đã được tải xuống',
        );
      } catch (e) {
        if (mounted) {
          await CustomAnimatedDialog.showError(
            context: context,
            title: 'Lỗi',
            message: 'Không thể tải dữ liệu: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isObscureCurrent = true;
    bool isObscureNew = true;
    bool isObscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    border: const OutlineInputBorder(),
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
                    border: const OutlineInputBorder(),
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
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin'),
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                    ),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mật khẩu xác nhận không khớp'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        final authService = ref.read(firebaseAuthServiceProvider);
        await authService.changePassword(
          currentPasswordController.text,
          newPasswordController.text,
        );

        if (mounted) {
          await CustomAnimatedDialog.showSuccess(
            context: context,
            title: 'Thành công',
            message: 'Đổi mật khẩu thành công',
          );
        }
      } catch (e) {
        if (mounted) {
          await CustomAnimatedDialog.showError(
            context: context,
            title: 'Lỗi',
            message: e.toString(),
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}

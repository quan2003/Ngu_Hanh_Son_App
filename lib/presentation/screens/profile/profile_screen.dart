import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_animated_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      await CustomAnimatedDialog.showError(
        context: context,
        title: 'Lỗi',
        message: 'Vui lòng nhập tên hiển thị',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        // Update Firebase Auth profile
        await authService.updateDisplayName(_nameController.text.trim());

        // Update Firestore
        final appUser = await ref.read(currentAppUserProvider.future);
        if (appUser != null) {
          final updatedUser = appUser.copyWith(
            displayName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );
          await firestoreService.saveUser(updatedUser);
        }

        // Refresh provider
        ref.invalidate(currentAppUserProvider);

        if (mounted) {
          await CustomAnimatedDialog.showSuccess(
            context: context,
            title: 'Thành công',
            message: 'Cập nhật thông tin thành công',
          );
          setState(() => _isEditing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể cập nhật: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Chỉnh sửa',
            ),
        ],
      ),
      body: appUserAsync.when(
        data: (appUser) {
          if (appUser == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin người dùng'),
            );
          }
          if (_nameController.text.isEmpty && appUser.displayName != null) {
            _nameController.text = appUser.displayName!;
          }
          if (_phoneController.text.isEmpty && appUser.phoneNumber != null) {
            _phoneController.text = appUser.phoneNumber!;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with avatar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: appUser.photoURL != null
                              ? NetworkImage(appUser.photoURL!)
                              : null,
                          child: appUser.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appUser.displayName ?? 'Người dùng',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: appUser.isAdmin
                              ? AppColors.error
                              : AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          appUser.isAdmin
                              ? 'Quản trị viên'
                              : appUser.isModerator
                                  ? 'Điều hành viên'
                                  : 'Thành viên',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSectionTitle('Thông tin cơ bản'),
                      const SizedBox(height: 16),

                      // Display name field
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'Tên hiển thị',
                        child: _isEditing
                            ? TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập tên hiển thị',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              )
                            : Text(
                                appUser.displayName ?? 'Chưa cập nhật',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Phone field
                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        child: _isEditing
                            ? TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập số điện thoại',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              )
                            : Text(
                                appUser.phoneNumber ?? 'Chưa cập nhật',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),

                      // Email field
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        child: Text(
                          appUser.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // User ID
                      _buildInfoCard(
                        icon: Icons.badge_outlined,
                        label: 'ID người dùng',
                        child: Text(
                          appUser.uid,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Thông tin hoạt động'),
                      const SizedBox(height: 16),

                      // Created at
                      if (appUser.createdAt != null)
                        _buildInfoCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'Ngày tạo tài khoản',
                          child: Text(
                            _formatDate(appUser.createdAt!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Last login
                      if (appUser.lastLogin != null)
                        _buildInfoCard(
                          icon: Icons.login_outlined,
                          label: 'Đăng nhập gần nhất',
                          child: Text(
                            _formatDate(appUser.lastLogin!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Edit buttons
                      if (_isEditing) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() => _isEditing = false);
                                        _nameController.text =
                                            appUser.displayName ?? '';
                                        _phoneController.text =
                                            appUser.phoneNumber ?? '';
                                      },
                                child: const Text('Hủy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Lưu'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32), // Action buttons
                      _buildActionButton(
                        icon: Icons.lock_outline,
                        label: 'Đổi mật khẩu',
                        color: AppColors.warning,
                        onTap: () => _showChangePasswordDialog(),
                      ),

                      const SizedBox(height: 12),

                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Xóa tài khoản',
                        color: AppColors.error,
                        onTap: () async {
                          final confirm =
                              await CustomAnimatedDialog.showConfirmation(
                            context: context,
                            title: 'Xác nhận xóa tài khoản',
                            message:
                                'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.',
                          );
                          if (confirm == true) {
                            // TODO: Implement delete account
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Tính năng xóa tài khoản đang phát triển'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
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
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentAppUserProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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

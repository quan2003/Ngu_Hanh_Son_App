import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_animated_dialog.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all'; // all, user, admin
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<User> _filterUsers(List<User> users) {
    return users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filterRole == 'all' || user.role == _filterRole;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _countByRole(List<User> users, String role) {
    if (role == 'all') return users.length;
    return users.where((u) => u.role == role).length;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Add user button
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Tạo người dùng mới',
            onPressed: () => _showCreateUserDialog(),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          final filteredUsers = _filterUsers(users);

          return Column(
            children: [
              // Search & Filter
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên hoặc email...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filter chips
                    Row(
                      children: [
                        const Text('Vai trò: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: Text(
                                    'Tất cả (${_countByRole(users, 'all')})'),
                                selected: _filterRole == 'all',
                                onSelected: (_) =>
                                    setState(() => _filterRole = 'all'),
                              ),
                              FilterChip(
                                label: Text(
                                    'User (${_countByRole(users, 'user')})'),
                                selected: _filterRole == 'user',
                                onSelected: (_) =>
                                    setState(() => _filterRole = 'user'),
                              ),
                              FilterChip(
                                label: Text(
                                    'Admin (${_countByRole(users, 'admin')})'),
                                selected: _filterRole == 'admin',
                                onSelected: (_) =>
                                    setState(() => _filterRole = 'admin'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // User list
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy người dùng',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user);
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
                onPressed: () => ref.refresh(adminUsersStreamProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isAdmin = user.role == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isBlocked
              ? Colors.red.shade100
              : (isAdmin ? Colors.purple.shade100 : Colors.blue.shade100),
          child: Icon(
            user.isBlocked
                ? Icons.block
                : (isAdmin ? Icons.admin_panel_settings : Icons.person),
            color: user.isBlocked
                ? Colors.red.shade700
                : (isAdmin ? Colors.purple.shade700 : Colors.blue.shade700),
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: user.isBlocked ? TextDecoration.lineThrough : null,
            color: user.isBlocked ? Colors.grey : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        isAdmin ? Colors.purple.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'User',
                    style: TextStyle(
                      fontSize: 11,
                      color: isAdmin
                          ? Colors.purple.shade700
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (user.isBlocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔒 Bị chặn',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID', user.id),
                _buildInfoRow('Vai trò', isAdmin ? 'Admin' : 'User'),
                _buildInfoRow(
                    'Ngày tham gia', _dateFormat.format(user.createdAt)),
                if (user.phone != null)
                  _buildInfoRow('Số điện thoại', user.phone!),
                _buildInfoRow('Trạng thái',
                    user.isBlocked ? '🔴 Bị chặn' : '🟢 Hoạt động'),
                const Divider(height: 24),

                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // View detail
                    ElevatedButton.icon(
                      onPressed: () => _viewUserDetail(user),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Xem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Edit
                    ElevatedButton.icon(
                      onPressed: () => _editUser(user),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Sửa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Block/Unblock
                    if (!user.isBlocked)
                      ElevatedButton.icon(
                        onPressed: () => _blockUser(user),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Chặn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _unblockUser(user),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mở chặn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),

                    // Toggle role (Admin/User)
                    if (!user.isBlocked)
                      ElevatedButton.icon(
                        onPressed: () => _toggleUserRole(user),
                        icon: Icon(
                          isAdmin ? Icons.person : Icons.admin_panel_settings,
                          size: 18,
                        ),
                        label: Text(isAdmin ? 'Set User' : 'Set Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ), // Soft Delete
                    ElevatedButton.icon(
                      onPressed: () => _deleteUser(user),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Permanent Delete
                    ElevatedButton.icon(
                      onPressed: () => _permanentlyDeleteUser(user),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Xóa vĩnh viễn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
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

  void _viewUserDetail(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
              color: user.role == 'admin' ? Colors.purple : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(user.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email', user.email),
            _buildInfoRow('ID', user.id),
            _buildInfoRow(
                'Vai trò', user.role == 'admin' ? 'Admin' : 'Người dùng'),
            if (user.phone != null) _buildInfoRow('Số điện thoại', user.phone!),
            _buildInfoRow('Ngày tham gia', _dateFormat.format(user.createdAt)),
          ],
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

  // Edit user information
  void _editUser(User user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.orange),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Chỉnh sửa người dùng',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
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
              if (!formKey.currentState!.validate()) return;
              try {
                final repository = AdminUserRepository();
                await repository.updateUser(
                  user.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  await CustomAnimatedDialog.showSuccess(
                    context: context,
                    title: 'Thành công',
                    message: 'Đã cập nhật thông tin người dùng',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  await CustomAnimatedDialog.showError(
                    context: context,
                    title: 'Lỗi',
                    message: 'Không thể cập nhật: $e',
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

  // Block user
  void _blockUser(User user) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xác nhận chặn',
      message: 'Bạn có chắc muốn chặn người dùng:\n${user.name}?',
      confirmText: 'Chặn',
      confirmColor: Colors.red,
    );

    if (!confirmed || !context.mounted) return;
    try {
      final repository = AdminUserRepository();
      await repository.blockUser(user.id);

      if (context.mounted) {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đã chặn',
          message: 'Người dùng đã bị chặn',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể chặn người dùng: $e',
        );
      }
    }
  }

  // Unblock user
  void _unblockUser(User user) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xác nhận mở chặn',
      message: 'Bạn có chắc muốn mở chặn người dùng:\n${user.name}?',
      confirmText: 'Mở chặn',
      confirmColor: Colors.green,
    );

    if (!confirmed || !context.mounted) return;
    try {
      final repository = AdminUserRepository();
      await repository.unblockUser(user.id);

      if (context.mounted) {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đã mở chặn',
          message: 'Người dùng đã được mở chặn',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể mở chặn người dùng: $e',
        );
      }
    }
  }

  // Toggle user role (Admin <-> User)
  void _toggleUserRole(User user) async {
    final isAdmin = user.role == 'admin';
    final newRole = isAdmin ? 'user' : 'admin';

    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xác nhận thay đổi vai trò',
      message:
          'Bạn có chắc muốn thay đổi vai trò của ${user.name} thành ${newRole == 'admin' ? 'Admin' : 'User'}?',
      confirmText: 'Xác nhận',
      confirmColor: Colors.purple,
    );

    if (!confirmed || !context.mounted) return;
    try {
      final repository = AdminUserRepository();
      await repository.updateUserRole(user.id, newRole);

      if (context.mounted) {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Thành công',
          message:
              'Đã thay đổi vai trò thành ${newRole == 'admin' ? 'Admin' : 'User'}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể thay đổi vai trò: $e',
        );
      }
    }
  }

  // Delete user (soft delete)
  void _deleteUser(User user) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: 'Xác nhận xóa',
      message:
          'Bạn có chắc muốn xóa người dùng:\n${user.name}?\n\nLưu ý: Đây là xóa mềm, dữ liệu sẽ được đánh dấu là đã xóa và sẽ không hiển thị trong danh sách.',
      confirmText: 'Xóa',
      confirmColor: Colors.red,
    );

    if (!confirmed || !context.mounted) return;
    try {
      final repository = AdminUserRepository();
      await repository.deleteUser(user.id);
      if (context.mounted) {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đã xóa',
          message: 'Người dùng đã được xóa khỏi danh sách',
        );
      }
      // Auto refresh after dialog
      ref.invalidate(adminUsersStreamProvider);
    } catch (e) {
      if (context.mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể xóa người dùng: $e',
        );
      }
    }
  }

  // Permanently delete user
  void _permanentlyDeleteUser(User user) async {
    final confirmed = await CustomAnimatedDialog.showConfirmation(
      context: context,
      title: '⚠️ Xác nhận xóa vĩnh viễn',
      message:
          'Bạn có chắc muốn XÓA VĨNH VIỄN người dùng:\n${user.name} (${user.email})?\n\n⚠️ CẢNH BÁO: Hành động này KHÔNG THỂ HOÀN TÁC!\nTất cả dữ liệu liên quan sẽ bị xóa hoàn toàn.',
      confirmText: 'XÓA VĨNH VIỄN',
      confirmColor: Colors.red.shade900,
    );

    if (!confirmed || !context.mounted) return;

    // Double confirmation
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 30),
            SizedBox(width: 8),
            Text('Xác nhận lần 2'),
          ],
        ),
        content: Text(
          'Nhập "XOA" để xác nhận xóa vĩnh viễn người dùng ${user.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          Builder(
            builder: (context) {
              final controller = TextEditingController();
              return TextButton(
                onPressed: () {
                  if (controller.text.toUpperCase() == 'XOA') {
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đúng "XOA"')),
                    );
                  }
                },
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Nhập "XOA"',
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );

    if (doubleConfirmed != true || !context.mounted) return;

    try {
      final repository = AdminUserRepository();
      await repository.permanentlyDeleteUser(user.id);
      if (context.mounted) {
        await CustomAnimatedDialog.showSuccess(
          context: context,
          title: 'Đã xóa vĩnh viễn',
          message: 'Người dùng đã bị xóa hoàn toàn khỏi hệ thống',
        );
      }
      // Auto refresh after dialog
      ref.invalidate(adminUsersStreamProvider);
    } catch (e) {
      if (context.mounted) {
        await CustomAnimatedDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể xóa vĩnh viễn người dùng: $e',
        );
      }
    }
  }

  // Show create user dialog
  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue),
              SizedBox(width: 8),
              Text('Tạo người dùng mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên người dùng *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu *',
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Tối thiểu 6 ký tự',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      prefixIcon: Icon(Icons.security),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedRole = value ?? 'user');
                    },
                  ),
                  const SizedBox(height: 16),
                  // Thông báo: Admin tạo user sẽ tự động bỏ qua xác thực email
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'User do admin tạo sẽ không cần xác thực email',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context); // Close dialog first

                try {
                  // Show loading
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final authService = ref.read(firebaseAuthServiceProvider);

                  // Create Firebase Auth account (returns Map with userId)
                  final result = await authService.createUserAccount(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    displayName: nameController.text.trim(),
                  );

                  final userId = result['userId'] as String?;
                  if (userId != null) {
                    debugPrint('📝 Saving user to Firestore: $userId');

                    // LƯU VÀO FIRESTORE TRƯỚC KHI SIGN OUT
                    // User do ADMIN TẠO → Tự động bỏ qua xác thực email
                    final userJson = {
                      'uid': userId,
                      'email': emailController.text.trim().toLowerCase(),
                      'displayName': nameController.text.trim(),
                      'phoneNumber': phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      'role': selectedRole,
                      'createdAt': DateTime.now().toIso8601String(),
                      'updatedAt': DateTime.now().toIso8601String(),
                      'isBlocked': false,
                      'isDeleted': false,
                      'skipEmailVerification':
                          true, // Admin tạo → Tự động bỏ qua xác thực
                      'createdBy': 'admin', // Đánh dấu được tạo bởi admin
                    };
                    // Save directly to Firestore with all fields
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .set(userJson, SetOptions(merge: true));

                    debugPrint('✅ User saved to Firestore successfully');
                    debugPrint('📋 User data saved: $userJson');

                    // If admin role, add to admin emails
                    if (selectedRole == 'admin') {
                      final firestoreService =
                          ref.read(firestoreServiceProvider);
                      await firestoreService
                          .addAdminEmail(emailController.text.trim());
                      debugPrint('✅ Added to admin emails');
                    }

                    // SAU ĐÓ MỚI SIGN OUT
                    debugPrint('🔓 Signing out new user...');
                    await authService.signOutCurrentUser();
                    debugPrint('✅ Signed out - Admin will need to log back in');
                  }

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    await CustomAnimatedDialog.showSuccess(
                      context: context,
                      title: 'Thành công',
                      message:
                          'Người dùng đã được tạo thành công!\n\nLưu ý: Bạn đã bị đăng xuất. Vui lòng đăng nhập lại.',
                    );
                  }
                  // Refresh list after dialog
                  ref.invalidate(adminUsersStreamProvider);
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    await CustomAnimatedDialog.showError(
                      context: context,
                      title: 'Lỗi',
                      message: 'Không thể tạo người dùng: $e',
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}

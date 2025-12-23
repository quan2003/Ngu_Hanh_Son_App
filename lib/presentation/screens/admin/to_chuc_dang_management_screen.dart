import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/to_chuc_dang.dart';
import '../../providers/organization_provider.dart';

/// Màn hình quản lý Tổ Chức Đảng với đầy đủ chức năng CRUD
class ToChucDangManagementScreen extends ConsumerStatefulWidget {
  const ToChucDangManagementScreen({super.key});

  @override
  ConsumerState<ToChucDangManagementScreen> createState() =>
      _ToChucDangManagementScreenState();
}

class _ToChucDangManagementScreenState
    extends ConsumerState<ToChucDangManagementScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, type  @override
  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamProvider để real-time sync với Firestore
    final toChucDangAsync = ref.watch(toChucDangStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Tổ Chức Đảng'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(toChucDangStreamProvider);
            },
            tooltip: 'Làm mới',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tên tổ chức'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'type',
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: _sortBy == 'type' ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Loại tổ chức'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tổ chức đảng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // List
          Expanded(
            child: toChucDangAsync.when(
              data: (toChucDangList) {
                if (toChucDangList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có tổ chức đảng nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm tổ chức đầu tiên'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter and sort
                var filteredList = toChucDangList.where((item) {
                  final searchLower = _searchQuery.toLowerCase();
                  return item.name.toLowerCase().contains(searchLower) ||
                      item.type.toLowerCase().contains(searchLower) ||
                      item.officerInCharge
                          .toLowerCase()
                          .contains(searchLower) ||
                      item.secretary.toLowerCase().contains(searchLower);
                }).toList();

                // Sort
                if (_sortBy == 'name') {
                  filteredList.sort((a, b) => a.name.compareTo(b.name));
                } else if (_sortBy == 'type') {
                  filteredList.sort((a, b) => a.type.compareTo(b.type));
                }

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy kết quả',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.groups,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Loại: ${item.type}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (item.officerInCharge.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Ủy viên: ${item.officerInCharge}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            if (item.secretary.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Bí thư: ${item.secretary}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(context, item);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, item);
                            } else if (value == 'detail') {
                              _showDetailDialog(context, item);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Chi tiết'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Sửa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Xóa',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải dữ liệu',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(toChucDangListProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Tổ Chức'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ToChucDang item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.groups, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Loại:', item.type),
              const Divider(height: 20),
              const Text(
                'Ủy viên phụ trách',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Họ tên:', item.officerInCharge),
              _buildDetailRow('Chức vụ:', item.officerPosition),
              _buildDetailRow('Điện thoại:', item.officerPhone),
              const Divider(height: 20),
              const Text(
                'Bí thư',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Họ tên:', item.secretary),
              _buildDetailRow('Điện thoại:', item.secretaryPhone),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, item);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Sửa'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'Đảng bộ cơ sở');
    final officerController = TextEditingController();
    final officerPositionController = TextEditingController();
    final officerPhoneController = TextEditingController();
    final secretaryController = TextEditingController();
    final secretaryPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Tổ Chức Đảng Mới'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tổ chức *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên tổ chức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Loại tổ chức *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập loại tổ chức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ủy viên phụ trách',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: officerController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: officerPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: officerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bí thư',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: secretaryController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: secretaryPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
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
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final now = DateTime.now();
                final docRef =
                    FirebaseFirestore.instance.collection('to_chuc_dang').doc();

                final newOrg = ToChucDang(
                  id: docRef.id,
                  name: nameController.text.trim(),
                  type: typeController.text.trim(),
                  officerInCharge: officerController.text.trim(),
                  officerPosition: officerPositionController.text.trim(),
                  officerPhone: officerPhoneController.text.trim(),
                  secretary: secretaryController.text.trim(),
                  secretaryPhone: secretaryPhoneController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );

                try {
                  await ref
                      .read(organizationRepositoryProvider)
                      .createToChucDang(newOrg);
                  ref.invalidate(toChucDangStreamProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Thêm tổ chức thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ToChucDang item) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final typeController = TextEditingController(text: item.type);
    final officerController = TextEditingController(text: item.officerInCharge);
    final officerPositionController =
        TextEditingController(text: item.officerPosition);
    final officerPhoneController =
        TextEditingController(text: item.officerPhone);
    final secretaryController = TextEditingController(text: item.secretary);
    final secretaryPhoneController =
        TextEditingController(text: item.secretaryPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh Sửa Tổ Chức Đảng'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tổ chức *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên tổ chức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Loại tổ chức *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập loại tổ chức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ủy viên phụ trách',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: officerController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: officerPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: officerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bí thư',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: secretaryController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: secretaryPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
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
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedOrg = ToChucDang(
                  id: item.id,
                  name: nameController.text.trim(),
                  type: typeController.text.trim(),
                  officerInCharge: officerController.text.trim(),
                  officerPosition: officerPositionController.text.trim(),
                  officerPhone: officerPhoneController.text.trim(),
                  secretary: secretaryController.text.trim(),
                  secretaryPhone: secretaryPhoneController.text.trim(),
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now(),
                );
                try {
                  await ref
                      .read(organizationRepositoryProvider)
                      .updateToChucDang(updatedOrg);
                  ref.invalidate(toChucDangStreamProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cập nhật thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ToChucDang item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tổ chức "${item.name}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(organizationRepositoryProvider)
                    .deleteToChucDang(item.id);
                ref.invalidate(toChucDangStreamProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã xóa tổ chức'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(chưa cập nhật)' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

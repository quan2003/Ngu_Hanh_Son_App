import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/to_chuc_dang.dart';
import '../providers/organization_provider.dart';

class EditToChucDangDialog extends ConsumerStatefulWidget {
  final ToChucDang toChucDang;

  const EditToChucDangDialog({
    super.key,
    required this.toChucDang,
  });

  @override
  ConsumerState<EditToChucDangDialog> createState() =>
      _EditToChucDangDialogState();
}

class _EditToChucDangDialogState extends ConsumerState<EditToChucDangDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _officerInChargeController;
  late TextEditingController _officerPositionController;
  late TextEditingController _officerPhoneController;
  late TextEditingController _secretaryController;
  late TextEditingController _secretaryPhoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.toChucDang.name);
    _typeController = TextEditingController(text: widget.toChucDang.type);
    _officerInChargeController =
        TextEditingController(text: widget.toChucDang.officerInCharge);
    _officerPositionController =
        TextEditingController(text: widget.toChucDang.officerPosition);
    _officerPhoneController =
        TextEditingController(text: widget.toChucDang.officerPhone);
    _secretaryController =
        TextEditingController(text: widget.toChucDang.secretary);
    _secretaryPhoneController =
        TextEditingController(text: widget.toChucDang.secretaryPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _officerInChargeController.dispose();
    _officerPositionController.dispose();
    _officerPhoneController.dispose();
    _secretaryController.dispose();
    _secretaryPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedToChucDang = ToChucDang(
        id: widget.toChucDang.id,
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        officerInCharge: _officerInChargeController.text.trim(),
        officerPosition: _officerPositionController.text.trim(),
        officerPhone: _officerPhoneController.text.trim(),
        secretary: _secretaryController.text.trim(),
        secretaryPhone: _secretaryPhoneController.text.trim(),
        createdAt: widget.toChucDang.createdAt,
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateToChucDang(updatedToChucDang);

      // Refresh data
      ref.invalidate(toChucDangListProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('✏️ Chỉnh Sửa Tổ Chức Đảng'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tổ chức *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên tổ chức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Loại *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    hintText: 'Chi bộ, Đảng bộ cơ sở...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập loại tổ chức';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Ủy viên phụ trách',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _officerInChargeController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _officerPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _officerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Bí thư',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _secretaryController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _secretaryPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

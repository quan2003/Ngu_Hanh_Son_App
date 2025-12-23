import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/to_dan_pho.dart';
import '../providers/organization_provider.dart';

class EditToDanPhoDialog extends ConsumerStatefulWidget {
  final ToDanPho toDanPho;

  const EditToDanPhoDialog({
    super.key,
    required this.toDanPho,
  });

  @override
  ConsumerState<EditToDanPhoDialog> createState() => _EditToDanPhoDialogState();
}

class _EditToDanPhoDialogState extends ConsumerState<EditToDanPhoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _staffInChargeController;
  late TextEditingController _staffPositionController;
  late TextEditingController _staffPhoneController;
  late TextEditingController _leaderController;
  late TextEditingController _leaderPhoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.toDanPho.name);
    _staffInChargeController =
        TextEditingController(text: widget.toDanPho.staffInCharge);
    _staffPositionController =
        TextEditingController(text: widget.toDanPho.staffPosition);
    _staffPhoneController =
        TextEditingController(text: widget.toDanPho.staffPhone);
    _leaderController = TextEditingController(text: widget.toDanPho.leader);
    _leaderPhoneController =
        TextEditingController(text: widget.toDanPho.leaderPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _staffInChargeController.dispose();
    _staffPositionController.dispose();
    _staffPhoneController.dispose();
    _leaderController.dispose();
    _leaderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedToDanPho = ToDanPho(
        id: widget.toDanPho.id,
        name: _nameController.text.trim(),
        staffInCharge: _staffInChargeController.text.trim(),
        staffPosition: _staffPositionController.text.trim(),
        staffPhone: _staffPhoneController.text.trim(),
        leader: _leaderController.text.trim(),
        leaderPhone: _leaderPhoneController.text.trim(),
        createdAt: widget.toDanPho.createdAt,
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateToDanPho(updatedToDanPho);

      // Refresh data
      ref.invalidate(toDanPhoListProvider);

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
      title: const Text('✏️ Chỉnh Sửa Tổ Dân Phố'),
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
                    labelText: 'Tên tổ dân phố *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên tổ dân phố';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Cán bộ phụ trách',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _staffInChargeController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _staffPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _staffPhoneController,
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
                  'Trưởng tổ dân phố',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _leaderController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _leaderPhoneController,
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

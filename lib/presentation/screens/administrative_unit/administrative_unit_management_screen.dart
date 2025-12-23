import 'package:flutter/material.dart';
import 'package:nhs_dangbo_app/data/services/administrative_unit_service.dart';
import 'package:nhs_dangbo_app/domain/models/administrative_unit.dart';

/// Screen for managing administrative units (Chi bộ, Tổ dân phố)
class AdministrativeUnitManagementScreen extends StatefulWidget {
  const AdministrativeUnitManagementScreen({super.key});

  @override
  State<AdministrativeUnitManagementScreen> createState() =>
      _AdministrativeUnitManagementScreenState();
}

class _AdministrativeUnitManagementScreenState
    extends State<AdministrativeUnitManagementScreen> {
  final AdministrativeUnitService _service = AdministrativeUnitService();
  String _selectedType = 'chi_bo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn vị hành chính'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'phuong',
                child: Text('Phường'),
              ),
              const PopupMenuItem(
                value: 'chi_bo',
                child: Text('Chi bộ'),
              ),
              const PopupMenuItem(
                value: 'to_dan_pho',
                child: Text('Tổ dân phố'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_getTypeLabel(_selectedType)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AdministrativeUnit>>(
        stream: _service.getUnitsByType(_selectedType),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final units = snapshot.data!;

          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ${_getTypeLabel(_selectedType).toLowerCase()}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm mới'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForUnit(unit.color),
                    child: Text(
                      unit.name.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    unit.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unit.description != null)
                        Text(unit.description!),
                      if (unit.leaderName != null)
                        Text('Lãnh đạo: ${unit.leaderName}'),
                      if (unit.memberCount != null)
                        Text('Số thành viên: ${unit.memberCount}'),
                      if (unit.centerLat != null && unit.centerLng != null)
                        Text(
                          'Tọa độ: ${unit.centerLat!.toStringAsFixed(4)}, ${unit.centerLng!.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(context, unit: unit);
                      } else if (value == 'delete') {
                        _confirmDelete(context, unit);
                      }
                    },
                  ),
                  onTap: () => _showUnitDetails(context, unit),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'phuong':
        return 'Phường';
      case 'chi_bo':
        return 'Chi bộ';
      case 'to_dan_pho':
        return 'Tổ dân phố';
      default:
        return type;
    }
  }

  Color _getColorForUnit(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _showAddEditDialog(BuildContext context, {AdministrativeUnit? unit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAdministrativeUnitScreen(
          unit: unit,
          type: _selectedType,
        ),
      ),
    );
  }

  void _showUnitDetails(BuildContext context, AdministrativeUnit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(unit.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Loại', _getTypeLabel(unit.type)),
              if (unit.description != null)
                _buildDetailRow('Mô tả', unit.description!),
              if (unit.leaderName != null)
                _buildDetailRow('Lãnh đạo', unit.leaderName!),
              if (unit.leaderPhone != null)
                _buildDetailRow('Số điện thoại', unit.leaderPhone!),
              if (unit.memberCount != null)
                _buildDetailRow('Số thành viên', unit.memberCount.toString()),
              if (unit.centerLat != null && unit.centerLng != null)
                _buildDetailRow(
                  'Tọa độ',
                  '${unit.centerLat!.toStringAsFixed(6)}, ${unit.centerLng!.toStringAsFixed(6)}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditDialog(context, unit: unit);
            },
            child: const Text('Sửa'),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdministrativeUnit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${unit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.deleteUnit(unit.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

/// Screen for adding/editing administrative units
class AddEditAdministrativeUnitScreen extends StatefulWidget {
  final AdministrativeUnit? unit;
  final String type;

  const AddEditAdministrativeUnitScreen({
    super.key,
    this.unit,
    required this.type,
  });

  @override
  State<AddEditAdministrativeUnitScreen> createState() =>
      _AddEditAdministrativeUnitScreenState();
}

class _AddEditAdministrativeUnitScreenState
    extends State<AddEditAdministrativeUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdministrativeUnitService _service = AdministrativeUnitService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _leaderNameController;
  late TextEditingController _leaderPhoneController;
  late TextEditingController _memberCountController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  String _selectedColor = '#2196F3';

  final List<String> _colors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.unit?.description ?? '');
    _leaderNameController =
        TextEditingController(text: widget.unit?.leaderName ?? '');
    _leaderPhoneController =
        TextEditingController(text: widget.unit?.leaderPhone ?? '');
    _memberCountController =
        TextEditingController(text: widget.unit?.memberCount?.toString() ?? '');
    _latController =
        TextEditingController(text: widget.unit?.centerLat?.toString() ?? '');
    _lngController =
        TextEditingController(text: widget.unit?.centerLng?.toString() ?? '');
    _selectedColor = widget.unit?.color ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _leaderNameController.dispose();
    _leaderPhoneController.dispose();
    _memberCountController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.unit == null ? 'Thêm mới' : 'Chỉnh sửa',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên *',
                hintText: 'Nhập tên đơn vị',
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
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _leaderNameController,
              decoration: const InputDecoration(
                labelText: 'Tên lãnh đạo',
                hintText: 'Nhập tên lãnh đạo',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _leaderPhoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: 'Nhập số điện thoại',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memberCountController,
              decoration: const InputDecoration(
                labelText: 'Số thành viên',
                hintText: 'Nhập số thành viên',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tọa độ trung tâm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Vĩ độ (Latitude)',
                      hintText: '16.0544',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Kinh độ (Longitude)',
                      hintText: '108.2022',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Màu hiển thị',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveUnit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final unit = AdministrativeUnit(
        id: widget.unit?.id ?? '',
        name: _nameController.text.trim(),
        type: widget.type,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        leaderName: _leaderNameController.text.trim().isEmpty
            ? null
            : _leaderNameController.text.trim(),
        leaderPhone: _leaderPhoneController.text.trim().isEmpty
            ? null
            : _leaderPhoneController.text.trim(),
        memberCount: _memberCountController.text.trim().isEmpty
            ? null
            : int.tryParse(_memberCountController.text.trim()),
        centerLat: _latController.text.trim().isEmpty
            ? null
            : double.tryParse(_latController.text.trim()),
        centerLng: _lngController.text.trim().isEmpty
            ? null
            : double.tryParse(_lngController.text.trim()),
        color: _selectedColor,
      );

      if (widget.unit == null) {
        await _service.addUnit(unit);
      } else {
        await _service.updateUnit(widget.unit!.id, unit);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.unit == null
                ? 'Thêm mới thành công'
                : 'Cập nhật thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}

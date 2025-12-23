import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/to_chuc_dang.dart';
import '../../../domain/entities/to_dan_pho.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/edit_to_chuc_dang_dialog.dart';
import '../../widgets/edit_to_dan_pho_dialog.dart';

class OrganizationDataScreenWithEdit extends ConsumerStatefulWidget {
  const OrganizationDataScreenWithEdit({super.key});

  @override
  ConsumerState<OrganizationDataScreenWithEdit> createState() =>
      _OrganizationDataScreenWithEditState();
}

class _OrganizationDataScreenWithEditState
    extends ConsumerState<OrganizationDataScreenWithEdit> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📋 Quản Lý Dữ Liệu Tổ Chức'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            tabs: const [
              Tab(text: '🏛️ Tổ Chức Đảng'),
              Tab(text: '👥 Tổ Dân Phố'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildToChucDangTab(),
            _buildToDanPhoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildToChucDangTab() {
    final toChucDangAsync = ref.watch(toChucDangListProvider);

    return toChucDangAsync.when(
      data: (toChucDangList) {
        if (toChucDangList.isEmpty) {
          return _buildEmptyState('Không có dữ liệu Tổ chức Đảng');
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số: ${toChucDangList.length} tổ chức',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: toChucDangList.length,
                itemBuilder: (context, index) {
                  final item = toChucDangList[index];
                  return _buildToChucDangCard(item);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildToChucDangCard(ToChucDang item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.groups, color: Colors.blue.shade700),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildInfoChip('Loại', item.type, Colors.blue),
            if (item.officerInCharge.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildInfoChip('Ủy viên', item.officerInCharge, Colors.green),
            ],
            if (item.secretary.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildInfoChip('Bí thư', item.secretary, Colors.orange),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Xem chi tiết'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showToChucDangDetail(item);
                break;
              case 'edit':
                showDialog(
                  context: context,
                  builder: (context) => EditToChucDangDialog(toChucDang: item),
                );
                break;
              case 'delete':
                _confirmDeleteToChucDang(item);
                break;
            }
          },
        ),
        onTap: () => _showToChucDangDetail(item),
      ),
    );
  }

  Widget _buildToDanPhoTab() {
    final toDanPhoAsync = ref.watch(toDanPhoListProvider);

    return toDanPhoAsync.when(
      data: (toDanPhoList) {
        if (toDanPhoList.isEmpty) {
          return _buildEmptyState('Không có dữ liệu Tổ dân phố');
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số: ${toDanPhoList.length} tổ dân phố',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: toDanPhoList.length,
                itemBuilder: (context, index) {
                  final item = toDanPhoList[index];
                  return _buildToDanPhoCard(item);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildToDanPhoCard(ToDanPho item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.people, color: Colors.green.shade700),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (item.staffInCharge.isNotEmpty) ...[
              _buildInfoChip('Cán bộ', item.staffInCharge, Colors.teal),
              const SizedBox(height: 4),
            ],
            if (item.leader.isNotEmpty)
              _buildInfoChip('Trưởng', item.leader, Colors.purple),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Xem chi tiết'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showToDanPhoDetail(item);
                break;
              case 'edit':
                showDialog(
                  context: context,
                  builder: (context) => EditToDanPhoDialog(toDanPho: item),
                );
                break;
              case 'delete':
                _confirmDeleteToDanPho(item);
                break;
            }
          },
        ),
        onTap: () => _showToDanPhoDetail(item),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải dữ liệu',
            style: TextStyle(fontSize: 18, color: Colors.red.shade600),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  void _showToChucDangDetail(ToChucDang item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.groups, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Loại:', item.type),
              const Divider(),
              const Text(
                'Ủy viên phụ trách',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('Họ tên:', item.officerInCharge),
              _buildDetailRow('Chức vụ:', item.officerPosition),
              _buildDetailRow('Điện thoại:', item.officerPhone),
              const Divider(),
              const Text(
                'Bí thư',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              showDialog(
                context: context,
                builder: (context) => EditToChucDangDialog(toChucDang: item),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  void _showToDanPhoDetail(ToDanPho item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.people, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cán bộ phụ trách',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('Họ tên:', item.staffInCharge),
              _buildDetailRow('Chức vụ:', item.staffPosition),
              _buildDetailRow('Điện thoại:', item.staffPhone),
              const Divider(),
              const Text(
                'Trưởng tổ dân phố',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('Họ tên:', item.leader),
              _buildDetailRow('Điện thoại:', item.leaderPhone),
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
              showDialog(
                context: context,
                builder: (context) => EditToDanPhoDialog(toDanPho: item),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa'),
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
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(chưa cập nhật)' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteToChucDang(ToChucDang item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác Nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(organizationRepositoryProvider);
        await repo.deleteToChucDang(item.id);
        ref.invalidate(toChucDangListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa thành công'),
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
      }
    }
  }

  Future<void> _confirmDeleteToDanPho(ToDanPho item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác Nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(organizationRepositoryProvider);
        await repo.deleteToDanPho(item.id);
        ref.invalidate(toDanPhoListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa thành công'),
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
      }
    }
  }
}

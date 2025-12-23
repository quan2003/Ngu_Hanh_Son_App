import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/to_dan_pho.dart';
import '../../../domain/models/household_stats.dart';
import '../../../data/services/household_stats_service.dart';
import '../../providers/organization_provider.dart';

/// Màn hình quản lý Tổ Dân Phố với đầy đủ chức năng CRUD
class ToDanPhoManagementScreen extends ConsumerStatefulWidget {
  const ToDanPhoManagementScreen({super.key});

  @override
  ConsumerState<ToDanPhoManagementScreen> createState() =>
      _ToDanPhoManagementScreenState();
}

class _ToDanPhoManagementScreenState
    extends ConsumerState<ToDanPhoManagementScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name
  final HouseholdStatsService _statsService = HouseholdStatsService();
  Map<String, HouseholdStats> _householdStatsMap = {};
  @override
  void initState() {
    super.initState();
    _loadHouseholdStats();
  }

  Future<void> _loadHouseholdStats() async {
    final statsStream = _statsService.getHouseholdStats();
    statsStream.listen((statsList) {
      if (mounted) {
        print('📊 Loaded ${statsList.length} household stats');
        setState(() {
          _householdStatsMap = {};
          for (var stats in statsList) {
            // Extract ID: "tdp_1" -> "1", "tdp_10" -> "10"
            String cleanId = stats.tdpId.replaceFirst('tdp_', '');
            _householdStatsMap[cleanId] = stats;
            if (_householdStatsMap.length <= 3) {
              print(
                  '  - Mapped: tdpId="${stats.tdpId}" -> cleanId="$cleanId"');
            }
          }
          print(
              '📊 _householdStatsMap has ${_householdStatsMap.length} entries');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamProvider để real-time sync với Firestore
    final toDanPhoAsync = ref.watch(toDanPhoStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Tổ Dân Phố'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(toDanPhoStreamProvider);
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
                      color: _sortBy == 'name' ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tên tổ dân phố'),
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
                hintText: 'Tìm kiếm tổ dân phố...',
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
            child: toDanPhoAsync.when(
              data: (toDanPhoList) {
                if (toDanPhoList.isEmpty) {
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
                          'Chưa có tổ dân phố nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm tổ dân phố đầu tiên'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter and sort
                var filteredList = toDanPhoList.where((item) {
                  final searchLower = _searchQuery.toLowerCase();
                  return item.name.toLowerCase().contains(searchLower) ||
                      item.staffInCharge.toLowerCase().contains(searchLower) ||
                      item.leader.toLowerCase().contains(searchLower);
                }).toList(); // Sort by name with natural number sorting
                if (_sortBy == 'name') {
                  filteredList.sort((a, b) {
                    // Extract numbers from name like "Tổ dân phố số 120"
                    final numA = _extractNumber(a.name);
                    final numB = _extractNumber(b.name);

                    if (numA != null && numB != null) {
                      return numA.compareTo(numB);
                    }
                    return a.name.compareTo(b.name);
                  });
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
                    final hasStats = _householdStatsMap.containsKey(item.id);
                    if (index == 0) {
                      print('🔍 Item ID: ${item.id}, Has stats: $hasStats');
                      if (!hasStats && _householdStatsMap.isNotEmpty) {
                        print(
                            '🔍 Available IDs in map: ${_householdStatsMap.keys.take(3).join(", ")}');
                      }
                    }
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
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.people,
                            color: Colors.green.shade700,
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
                            // Household stats
                            if (_householdStatsMap.containsKey(item.id))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_householdStatsMap[item.id]!.reportedHouseholdCount} hộ • ${_householdStatsMap[item.id]!.populationCount} nhân khẩu',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            if (_householdStatsMap.containsKey(item.id))
                              const SizedBox(height: 6),
                            if (item.staffInCharge.isNotEmpty)
                              Text(
                                'Cán bộ: ${item.staffInCharge}${item.staffPosition.isNotEmpty ? ' - ${item.staffPosition}' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            if (item.staffPhone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'SĐT: ${item.staffPhone}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            if (item.leader.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Tổ trưởng: ${item.leader}',
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
                            } else if (value == 'editStats') {
                              _showEditStatsDialog(context, item);
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
                                  Text('Sửa thông tin'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'editStats',
                              child: Row(
                                children: [
                                  Icon(Icons.bar_chart,
                                      size: 20, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Sửa số hộ & địa chỉ',
                                      style: TextStyle(color: Colors.blue)),
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
                        ref.invalidate(toDanPhoStreamProvider);
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
        label: const Text('Thêm Tổ Dân Phố'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ToDanPho item) {
    final stats = _householdStatsMap[item.id];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.green.shade700),
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
              // Household Statistics Section
              if (stats != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home,
                              size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Thống kê hộ dân',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Số hộ (CV 603):',
                          '${stats.reportedHouseholdCount} hộ'),
                      _buildDetailRow(
                          'Số hộ (cũ):', '${stats.oldHouseholdCount} hộ'),
                      _buildDetailRow(
                          'Nhân khẩu:', '${stats.populationCount} người'),
                      if (stats.poorHouseholdCity > 0 ||
                          stats.poorHouseholdCentral > 0) ...[
                        const Divider(height: 16),
                        _buildDetailRow(
                            'Hộ nghèo (TP):', '${stats.poorHouseholdCity} hộ'),
                        _buildDetailRow('Hộ nghèo (TW):',
                            '${stats.poorHouseholdCentral} hộ'),
                      ],
                      if (stats.nearPoorHouseholdCity > 0 ||
                          stats.nearPoorHouseholdCentral > 0) ...[
                        _buildDetailRow('Cận nghèo (TP):',
                            '${stats.nearPoorHouseholdCity} hộ'),
                        _buildDetailRow('Cận nghèo (TW):',
                            '${stats.nearPoorHouseholdCentral} hộ'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Meeting Location Section
              if (stats != null &&
                  (stats.meetingLocationName != null ||
                      stats.meetingLocationAddress != null)) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 20, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Địa chỉ nhà sinh hoạt',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (stats.meetingLocationName != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Tên:', stats.meetingLocationName!),
                      ],
                      if (stats.meetingLocationAddress != null) ...[
                        _buildDetailRow(
                            'Địa chỉ:', stats.meetingLocationAddress!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'Cán bộ phụ trách',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Họ tên:', item.staffInCharge),
              _buildDetailRow('Chức vụ:', item.staffPosition),
              _buildDetailRow('Điện thoại:', item.staffPhone),
              const Divider(height: 20),
              const Text(
                'Tổ trưởng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
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
              _showEditStatsDialog(context, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.bar_chart, size: 18),
            label: const Text('Số hộ & địa chỉ'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, item);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Sửa thông tin'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final staffController = TextEditingController();
    final staffPositionController = TextEditingController();
    final staffPhoneController = TextEditingController();
    final leaderController = TextEditingController();
    final leaderPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Tổ Dân Phố Mới'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tổ dân phố *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên tổ dân phố';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cán bộ phụ trách',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: staffController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: staffPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: staffPhoneController,
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
                    'Tổ trưởng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: leaderController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: leaderPhoneController,
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
                    FirebaseFirestore.instance.collection('to_dan_pho').doc();

                final newItem = ToDanPho(
                  id: docRef.id,
                  name: nameController.text.trim(),
                  staffInCharge: staffController.text.trim(),
                  staffPosition: staffPositionController.text.trim(),
                  staffPhone: staffPhoneController.text.trim(),
                  leader: leaderController.text.trim(),
                  leaderPhone: leaderPhoneController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );

                try {
                  await ref
                      .read(organizationRepositoryProvider)
                      .createToDanPho(newItem);
                  ref.invalidate(toDanPhoStreamProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Thêm tổ dân phố thành công'),
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

  void _showEditDialog(BuildContext context, ToDanPho item) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final staffController = TextEditingController(text: item.staffInCharge);
    final staffPositionController =
        TextEditingController(text: item.staffPosition);
    final staffPhoneController = TextEditingController(text: item.staffPhone);
    final leaderController = TextEditingController(text: item.leader);
    final leaderPhoneController = TextEditingController(text: item.leaderPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh Sửa Tổ Dân Phố'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tổ dân phố *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên tổ dân phố';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cán bộ phụ trách',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: staffController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: staffPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: staffPhoneController,
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
                    'Tổ trưởng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: leaderController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: leaderPhoneController,
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
                final updatedItem = ToDanPho(
                  id: item.id,
                  name: nameController.text.trim(),
                  staffInCharge: staffController.text.trim(),
                  staffPosition: staffPositionController.text.trim(),
                  staffPhone: staffPhoneController.text.trim(),
                  leader: leaderController.text.trim(),
                  leaderPhone: leaderPhoneController.text.trim(),
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now(),
                );

                try {
                  await ref
                      .read(organizationRepositoryProvider)
                      .updateToDanPho(updatedItem);
                  ref.invalidate(toDanPhoStreamProvider);
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

  void _showEditStatsDialog(BuildContext context, ToDanPho item) {
    final formKey = GlobalKey<FormState>();

    // Get existing stats or create new with tdp_ prefix
    final existingStats = _householdStatsMap[item.id];
    final tdpIdWithPrefix = 'tdp_${item.id}';

    final oldHouseholdController = TextEditingController(
      text: existingStats?.oldHouseholdCount.toString() ?? '0',
    );
    final reportedHouseholdController = TextEditingController(
      text: existingStats?.reportedHouseholdCount.toString() ?? '0',
    );
    final populationController = TextEditingController(
      text: existingStats?.populationCount.toString() ?? '0',
    );
    final poorCityController = TextEditingController(
      text: existingStats?.poorHouseholdCity.toString() ?? '0',
    );
    final poorCentralController = TextEditingController(
      text: existingStats?.poorHouseholdCentral.toString() ?? '0',
    );
    final nearPoorCityController = TextEditingController(
      text: existingStats?.nearPoorHouseholdCity.toString() ?? '0',
    );
    final nearPoorCentralController = TextEditingController(
      text: existingStats?.nearPoorHouseholdCentral.toString() ?? '0',
    );
    final meetingLocationNameController = TextEditingController(
      text: existingStats?.meetingLocationName ?? '',
    );
    final meetingLocationAddressController = TextEditingController(
      text: existingStats?.meetingLocationAddress ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sửa Số Hộ & Địa Chỉ',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Household counts section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Số Hộ Gia Đình',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: oldHouseholdController,
                              decoration: const InputDecoration(
                                labelText: 'Số hộ cũ',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bắt buộc';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Số không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: reportedHouseholdController,
                              decoration: const InputDecoration(
                                labelText: 'Số hộ (CV 603)',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bắt buộc';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Số không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: populationController,
                        decoration: const InputDecoration(
                          labelText: '👥 Nhân khẩu',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Bắt buộc';
                          if (int.tryParse(value) == null) {
                            return 'Số không hợp lệ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Poor households section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏠 Hộ Nghèo & Cận Nghèo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: poorCityController,
                              decoration: const InputDecoration(
                                labelText: 'Hộ nghèo TP',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: poorCentralController,
                              decoration: const InputDecoration(
                                labelText: 'Hộ nghèo TW',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nearPoorCityController,
                              decoration: const InputDecoration(
                                labelText: 'Cận nghèo TP',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: nearPoorCentralController,
                              decoration: const InputDecoration(
                                labelText: 'Cận nghèo TW',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Meeting location section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏢 Địa Chỉ Nhà Sinh Hoạt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: meetingLocationNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên địa điểm',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'VD: Nhà văn hóa TDP 120',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: meetingLocationAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ đầy đủ',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'VD: 123 Đường ABC, Phường XYZ',
                        ),
                        maxLines: 2,
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newStats = HouseholdStats(
                  tdpId: tdpIdWithPrefix, // Use "tdp_1" format for Firestore
                  tdpName: item.name,
                  oldHouseholdCount:
                      int.parse(oldHouseholdController.text.trim()),
                  reportedHouseholdCount:
                      int.parse(reportedHouseholdController.text.trim()),
                  populationCount: int.parse(populationController.text.trim()),
                  poorHouseholdCity: int.parse(
                      poorCityController.text.trim().isEmpty
                          ? '0'
                          : poorCityController.text.trim()),
                  poorHouseholdCentral: int.parse(
                      poorCentralController.text.trim().isEmpty
                          ? '0'
                          : poorCentralController.text.trim()),
                  nearPoorHouseholdCity: int.parse(
                      nearPoorCityController.text.trim().isEmpty
                          ? '0'
                          : nearPoorCityController.text.trim()),
                  nearPoorHouseholdCentral: int.parse(
                      nearPoorCentralController.text.trim().isEmpty
                          ? '0'
                          : nearPoorCentralController.text.trim()),
                  meetingLocationName:
                      meetingLocationNameController.text.trim().isEmpty
                          ? null
                          : meetingLocationNameController.text.trim(),
                  meetingLocationAddress:
                      meetingLocationAddressController.text.trim().isEmpty
                          ? null
                          : meetingLocationAddressController.text.trim(),
                  heroicMothers: existingStats?.heroicMothers ?? [],
                );

                try {
                  await _statsService.setHouseholdStats(newStats);
                  // Reload stats
                  await _loadHouseholdStats();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cập nhật số hộ & địa chỉ thành công'),
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
            child: const Text('💾 Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ToDanPho item) {
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
          'Bạn có chắc chắn muốn xóa tổ dân phố "${item.name}"?\n\nHành động này không thể hoàn tác.',
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
                    .deleteToDanPho(item.id);
                ref.invalidate(toDanPhoStreamProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã xóa tổ dân phố'),
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
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Extract number from name like "Tổ dân phố số 120" -> 120
  int? _extractNumber(String name) {
    final regex = RegExp(r'số\s+(\d+)');
    final match = regex.firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    // Try to extract any number from the string
    final numRegex = RegExp(r'\d+');
    final numMatch = numRegex.firstMatch(name);
    if (numMatch != null) {
      return int.tryParse(numMatch.group(0)!);
    }
    return null;
  }
}

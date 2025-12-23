import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/household_stats_service.dart';
import '../../../domain/models/household_stats.dart';
import '../../providers/organization_provider.dart';
import 'to_chuc_dang_management_screen.dart';
import 'to_dan_pho_management_screen.dart';

class OrganizationDataScreen extends ConsumerStatefulWidget {
  const OrganizationDataScreen({super.key});

  @override
  ConsumerState<OrganizationDataScreen> createState() =>
      _OrganizationDataScreenState();
}

class _OrganizationDataScreenState
    extends ConsumerState<OrganizationDataScreen> {
  int _selectedTab = 0; // 0: Tổ chức Đảng, 1: Tổ dân phố
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
        setState(() {
          _householdStatsMap = {};
          for (var stats in statsList) {
            // Extract ID: "tdp_1" -> "1", "tdp_10" -> "10"
            String cleanId = stats.tdpId.replaceFirst('tdp_', '');
            _householdStatsMap[cleanId] = stats;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📋 Dữ Liệu Tổ Chức'),
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
                  'Không có dữ liệu',
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
          padding: const EdgeInsets.all(12),
          itemCount: toChucDangList.length,
          itemBuilder: (context, index) {
            final item = toChucDangList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
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
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Loại: ${item.type}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (item.officerInCharge.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
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
                        padding: const EdgeInsets.only(top: 4),
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
                    if (value == 'detail') {
                      _showToChucDangDetail(context, item);
                    } else if (value == 'manage') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ToChucDangManagementScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Xem chi tiết'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('⚙️ Quản lý',
                              style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _showToChucDangDetail(context, item);
                },
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
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToDanPhoTab() {
    final toDanPhoAsync = ref.watch(toDanPhoListProvider);

    return toDanPhoAsync.when(
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
                  'Không có dữ liệu',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort by number in name
        final sortedList = List.from(toDanPhoList);
        sortedList.sort((a, b) {
          final numA = _extractNumberFromName(a.name);
          final numB = _extractNumberFromName(b.name);
          if (numA != null && numB != null) {
            return numA.compareTo(numB);
          }
          return a.name.compareTo(b.name);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final item = sortedList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
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
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (item.staffPhone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'SĐT: ${item.staffPhone}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    if (item.leader.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Trưởng: ${item.leader}',
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
                    if (value == 'detail') {
                      _showToDanPhoDetail(context, item);
                    } else if (value == 'manage') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ToDanPhoManagementScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Xem chi tiết'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('⚙️ Quản lý',
                              style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _showToDanPhoDetail(context, item);
                },
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
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToChucDangDetail(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Loại:', item.type),
              _buildDetailRow('Ủy viên phụ trách:', item.officerInCharge),
              _buildDetailRow('Chức vụ:', item.officerPosition),
              _buildDetailRow('Điện thoại:', item.officerPhone),
              _buildDetailRow('Bí thư:', item.secretary),
              _buildDetailRow('Điện thoại bí thư:', item.secretaryPhone),
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

  void _showToDanPhoDetail(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Cán bộ phụ trách:', item.staffInCharge),
              _buildDetailRow('Chức vụ:', item.staffPosition),
              _buildDetailRow('Điện thoại:', item.staffPhone),
              _buildDetailRow('Trưởng tổ:', item.leader),
              _buildDetailRow('Điện thoại trưởng:', item.leaderPhone),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
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

  /// Extract number from name like "Tổ dân phố số 120" -> 120
  int? _extractNumberFromName(String name) {
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

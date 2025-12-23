import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/organization_provider.dart';
import '../../providers/household_stats_provider.dart';
import '../../widgets/to_dan_pho_card.dart';

/// Màn hình Tổ Dân Phố với thống kê tổng quan
class ToDanPhoScreen extends ConsumerWidget {
  const ToDanPhoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toDanPhoAsync = ref.watch(toDanPhoListProvider);
    final totalHouseholdStatsAsync = ref.watch(totalHouseholdStatsProvider);
    final searchQuery = ref.watch(toDanPhoSearchQueryProvider);
    final sortOption = ref.watch(toDanPhoSortProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(toDanPhoListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header Title
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.people,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổ Dân Phố',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Quản lý thông tin các tổ dân phố',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar with Sort Button
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tổ, tổ trưởng, SĐT, mẹ VNAH...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    ref
                                        .read(toDanPhoSearchQueryProvider
                                            .notifier)
                                        .state = '';
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
                          ref.read(toDanPhoSearchQueryProvider.notifier).state =
                              value;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.sort, color: Colors.white),
                            tooltip: 'Sắp xếp',
                            onPressed: () {
                              _showSortBottomSheet(context, ref, sortOption);
                            },
                          ),
                        ),
                        if (sortOption != SortOption.idAsc)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ), // Statistics Cards
            SliverToBoxAdapter(
              child: totalHouseholdStatsAsync.when(
                data: (householdStats) =>
                    _buildStatisticsSection(householdStats),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _buildStatisticsSection({}),
              ),
            ),

            // List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danh sách tổ dân phố',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    toDanPhoAsync.whenData((list) {
                          final filteredOrgs = ref
                                  .watch(advancedFilteredToDanPhoProvider)
                                  .value ??
                              [];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '${filteredOrgs.length} tổ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          );
                        }).value ??
                        const SizedBox(),
                  ],
                ),
              ),
            ), // Tổ Dân Phố List
            toDanPhoAsync.when(
              data: (allOrgs) {
                final filteredOrgs =
                    ref.watch(advancedFilteredToDanPhoProvider).value ?? [];

                if (filteredOrgs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchQuery.isEmpty
                                ? Icons.inbox
                                : Icons.search_off,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'Chưa có tổ dân phố nào'
                                : 'Không tìm thấy kết quả',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final org = filteredOrgs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ToDanPhoCard(
                            toDanPho: org,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    ToDanPhoDetailDialog(toDanPho: org),
                              );
                            },
                          ),
                        );
                      },
                      childCount: filteredOrgs.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(toDanPhoListProvider);
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
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> householdStats) {
    // Lấy dữ liệu từ Firebase
    final reportedHouseholds = householdStats['reportedHouseholdCount'] ?? 0;

    // Số liệu cố định cho Hộ nghèo và Hộ cận nghèo
    const poorCity = 606;
    const poorCentral = 417;
    const nearPoorCity = 83;
    const nearPoorCentral = 35;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Thống Kê Tổng Quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Row 1: Tổng số Tổ dân phố & Số hộ gia đình
          Row(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final toDanPhoAsync = ref.watch(toDanPhoListProvider);
                    return _buildStatCard(
                      title: 'Tổng số Tổ dân phố',
                      value: toDanPhoAsync.when(
                        data: (list) => list.length.toString(),
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      icon: Icons.people,
                      color: Colors.green,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Số hộ gia đình',
                  value: '$reportedHouseholds',
                  icon: Icons.home_work,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Hộ nghèo & Hộ cận nghèo
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Hộ nghèo',
                  value: '$poorCity TP\n$poorCentral TW',
                  icon: Icons.favorite_border,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Hộ cận nghèo',
                  value: '$nearPoorCity TP\n$nearPoorCentral TW',
                  icon: Icons.volunteer_activism,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(
      BuildContext context, WidgetRef ref, SortOption currentSort) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sắp xếp theo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption(
              context,
              ref,
              title: 'ID tăng dần',
              icon: Icons.sort,
              option: SortOption.idAsc,
              currentSort: currentSort,
            ),
            _buildSortOption(
              context,
              ref,
              title: 'ID giảm dần',
              icon: Icons.sort,
              option: SortOption.idDesc,
              currentSort: currentSort,
            ),
            _buildSortOption(
              context,
              ref,
              title: 'Tên A-Z',
              icon: Icons.sort_by_alpha,
              option: SortOption.nameAsc,
              currentSort: currentSort,
            ),
            _buildSortOption(
              context,
              ref,
              title: 'Tên Z-A',
              icon: Icons.sort_by_alpha,
              option: SortOption.nameDesc,
              currentSort: currentSort,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required SortOption option,
    required SortOption currentSort,
  }) {
    final isSelected = option == currentSort;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.black,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        ref.read(toDanPhoSortProvider.notifier).state = option;
        Navigator.pop(context);
      },
    );
  }
}

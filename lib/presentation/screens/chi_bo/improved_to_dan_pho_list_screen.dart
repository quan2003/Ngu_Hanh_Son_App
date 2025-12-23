import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/to_dan_pho_card.dart';

class ImprovedToDanPhoListScreen extends ConsumerWidget {
  const ImprovedToDanPhoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(toDanPhoSearchQueryProvider);
    final sortOption = ref.watch(toDanPhoSortProvider);
    final organizationsAsync = ref.watch(filteredToDanPhoProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '👥 Tổ Dân Phố',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(128, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade800,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.people,
                        size: 150,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.home_work,
                        size: 120,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Sort button with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sắp xếp',
                    onPressed: () {
                      _showSortBottomSheet(context, ref, sortOption);
                    },
                  ),
                  if (sortOption != SortOption.idAsc)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Statistics Header
          organizationsAsync.when(
            data: (organizations) => SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.green.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.home_work,
                      label: 'Tổng số',
                      value: '${organizations.length}',
                      color: Colors.green.shade700,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    _buildStatItem(
                      icon: searchQuery.isNotEmpty ? Icons.search : Icons.list,
                      label:
                          searchQuery.isNotEmpty ? 'Kết quả' : 'Đang hiển thị',
                      value: '${organizations.length}',
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // Search Box
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    ref.read(toDanPhoSearchQueryProvider.notifier).state =
                        value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tổ dân phố, cán bộ, trưởng tổ...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.green.shade600),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: Colors.grey.shade400),
                            onPressed: () {
                              ref
                                  .read(toDanPhoSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Current Sort Info
          if (sortOption != SortOption.idAsc)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Chip(
                  avatar: const Icon(Icons.sort, size: 18),
                  label: Text('Sắp xếp: ${sortOption.label}'),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    ref.read(toDanPhoSortProvider.notifier).state =
                        SortOption.idAsc;
                  },
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // List with enhanced cards
          organizationsAsync.when(
            data: (organizations) {
              if (organizations.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'Chưa có dữ liệu'
                              : 'Không tìm thấy kết quả',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(toDanPhoSearchQueryProvider.notifier)
                                  .state = '';
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Xóa tìm kiếm'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final org = organizations[index];
                      return _buildEnhancedCard(context, org, index);
                    },
                    childCount: organizations.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải dữ liệu...'),
                  ],
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: $error',
                      style: TextStyle(color: Colors.red.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCard(BuildContext context, dynamic org, int index) {
    // Extract number for display
    final numMatch = RegExp(r'\d+').firstMatch(org.name);
    final displayNum = numMatch?.group(0) ?? '${index + 1}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ToDanPhoDetailDialog(toDanPho: org),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayNum,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (org.staffInCharge.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${org.staffPosition}: ${org.staffInCharge}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (org.leader.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Trưởng: ${org.leader}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet(
      BuildContext context, WidgetRef ref, SortOption currentOption) {
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
            Row(
              children: [
                const Icon(Icons.sort, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Sắp xếp theo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...[
              SortOption.idAsc,
              SortOption.idDesc,
              SortOption.nameAsc,
              SortOption.nameDesc,
            ].map((option) {
              final isSelected = currentOption == option;
              return ListTile(
                leading: Icon(
                  _getSortIcon(option),
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.green : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  ref.read(toDanPhoSortProvider.notifier).state = option;
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.idAsc:
        return Icons.arrow_upward;
      case SortOption.idDesc:
        return Icons.arrow_downward;
      case SortOption.nameAsc:
        return Icons.sort_by_alpha;
      case SortOption.nameDesc:
        return Icons.sort_by_alpha;
      default:
        return Icons.sort;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/to_chuc_dang_card.dart';

class ToChucDangListScreen extends ConsumerWidget {
  const ToChucDangListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(toChucDangSearchQueryProvider);
    final sortOption = ref.watch(toChucDangSortProvider);
    final organizationsAsync = ref.watch(filteredToChucDangProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổ chức Đảng'),
        elevation: 0,
        actions: [
          // Sort button
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (option) {
              ref.read(toChucDangSortProvider.notifier).state = option;
            },
            itemBuilder: (context) => SortOption.values.map((option) {
              return PopupMenuItem<SortOption>(
                value: option,
                child: Row(
                  children: [
                    if (sortOption == option)
                      const Icon(Icons.check, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                ref.read(toChucDangSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tổ chức đảng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref
                              .read(toChucDangSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: organizationsAsync.when(
              data: (organizations) {
                if (organizations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy dữ liệu',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: organizations.length,
                  itemBuilder: (context, index) {
                    final org = organizations[index];
                    return ToChucDangCard(
                      toChucDang: org,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              ToChucDangDetailDialog(toChucDang: org),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

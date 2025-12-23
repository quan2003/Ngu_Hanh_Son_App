import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/organization_repository.dart';
import '../../domain/entities/to_chuc_dang.dart';
import '../../domain/entities/to_dan_pho.dart';
import '../../domain/models/household_stats.dart';
import 'household_stats_provider.dart';

// Repository provider
final organizationRepositoryProvider = Provider((ref) {
  return OrganizationRepository();
});

// Tổ chức Đảng Providers
final toChucDangListProvider = FutureProvider<List<ToChucDang>>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getAllToChucDang();
});

final toChucDangStreamProvider = StreamProvider<List<ToChucDang>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getToChucDangStream();
});

final toChucDangByIdProvider =
    FutureProvider.family<ToChucDang?, String>((ref, id) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getToChucDangById(id);
});

final searchToChucDangProvider =
    FutureProvider.family<List<ToChucDang>, String>((ref, query) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.searchToChucDang(query);
});

final toChucDangByTypeProvider =
    FutureProvider.family<List<ToChucDang>, String>((ref, type) async {
  final repo = ref.watch(organizationRepositoryProvider);
  final all = await repo.getAllToChucDang();
  return all.where((e) => e.type == type).toList();
});

// Tổ dân phố Providers
final toDanPhoListProvider = FutureProvider<List<ToDanPho>>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getAllToDanPho();
});

final toDanPhoStreamProvider = StreamProvider<List<ToDanPho>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getToDanPhoStream();
});

final toDanPhoByIdProvider =
    FutureProvider.family<ToDanPho?, String>((ref, id) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getToDanPhoById(id);
});

final searchToDanPhoProvider =
    FutureProvider.family<List<ToDanPho>, String>((ref, query) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.searchToDanPho(query);
});

// Sort options
enum SortOption {
  nameAsc('Tên A-Z'),
  nameDesc('Tên Z-A'),
  idAsc('STT Thấp → Cao'),
  idDesc('STT Cao → Thấp'),
  typeAsc('Loại A-Z'),
  typeDesc('Loại Z-A');

  final String label;
  const SortOption(this.label);
}

// Sort state providers
final toChucDangSortProvider =
    StateProvider<SortOption>((ref) => SortOption.idAsc);
final toDanPhoSortProvider =
    StateProvider<SortOption>((ref) => SortOption.idAsc);

// Search query state
final toChucDangSearchQueryProvider = StateProvider<String>((ref) => '');
final toDanPhoSearchQueryProvider = StateProvider<String>((ref) => '');

// Helper function to sort ToChucDang list
List<ToChucDang> _sortToChucDangList(List<ToChucDang> list, SortOption option) {
  final sorted = List<ToChucDang>.from(list);
  switch (option) {
    case SortOption.nameAsc:
      sorted.sort((a, b) => a.name.compareTo(b.name));
      break;
    case SortOption.nameDesc:
      sorted.sort((a, b) => b.name.compareTo(a.name));
      break;
    case SortOption.idAsc:
      // Sort by STT (official order number)
      sorted.sort((a, b) => a.stt.compareTo(b.stt));
      break;
    case SortOption.idDesc:
      // Sort by STT (descending)
      sorted.sort((a, b) => b.stt.compareTo(a.stt));
      break;
    case SortOption.typeAsc:
      sorted.sort((a, b) => a.type.compareTo(b.type));
      break;
    case SortOption.typeDesc:
      sorted.sort((a, b) => b.type.compareTo(a.type));
      break;
  }
  return sorted;
}

// Helper function to extract number from name
int _extractNumber(String text) {
  // Extract number from text like "Tổ dân phố số 1" or "Chi bộ 2"
  final match = RegExp(r'\d+').firstMatch(text);
  if (match != null) {
    return int.tryParse(match.group(0)!) ?? 0;
  }
  return 0;
}

// Helper function to sort ToDanPho list
List<ToDanPho> _sortToDanPhoList(List<ToDanPho> list, SortOption option) {
  final sorted = List<ToDanPho>.from(list);
  switch (option) {
    case SortOption.nameAsc:
      sorted.sort((a, b) => a.name.compareTo(b.name));
      break;
    case SortOption.nameDesc:
      sorted.sort((a, b) => b.name.compareTo(a.name));
      break;
    case SortOption.idAsc:
      // Sort by number extracted from name
      sorted.sort((a, b) {
        final numA = _extractNumber(a.name);
        final numB = _extractNumber(b.name);
        return numA.compareTo(numB);
      });
      break;
    case SortOption.idDesc:
      // Sort by number extracted from name (descending)
      sorted.sort((a, b) {
        final numA = _extractNumber(a.name);
        final numB = _extractNumber(b.name);
        return numB.compareTo(numA);
      });
      break;
    case SortOption.typeAsc:
    case SortOption.typeDesc:
      // ToDanPho doesn't have type, sort by name instead
      sorted.sort((a, b) => option == SortOption.typeAsc
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
      break;
  }
  return sorted;
}

// Derived providers for filtered and sorted data
final filteredToChucDangProvider =
    FutureProvider<List<ToChucDang>>((ref) async {
  final query = ref.watch(toChucDangSearchQueryProvider);
  final sortOption = ref.watch(toChucDangSortProvider);

  List<ToChucDang> data;
  if (query.isEmpty) {
    data = await ref.watch(toChucDangListProvider.future);
  } else {
    // Simple local search
    final allData = await ref.watch(toChucDangListProvider.future);
    data = allData
        .where((item) =>
            item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.type.toLowerCase().contains(query.toLowerCase()) ||
            item.officerInCharge.toLowerCase().contains(query.toLowerCase()) ||
            item.secretary.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  return _sortToChucDangList(data, sortOption);
});

final filteredToDanPhoProvider = FutureProvider<List<ToDanPho>>((ref) async {
  final query = ref.watch(toDanPhoSearchQueryProvider);
  final sortOption = ref.watch(toDanPhoSortProvider);

  List<ToDanPho> data;
  if (query.isEmpty) {
    data = await ref.watch(toDanPhoListProvider.future);
  } else {
    // Enhanced search - tìm kiếm theo nhiều tiêu chí
    final allData = await ref.watch(toDanPhoListProvider.future);
    final queryLower = query.toLowerCase();

    data = allData.where((item) {
      // Tìm theo tên tổ
      if (item.name.toLowerCase().contains(queryLower)) return true;

      // Tìm theo cán bộ phụ trách
      if (item.staffInCharge.toLowerCase().contains(queryLower)) return true;

      // Tìm theo tổ trưởng
      if (item.leader.toLowerCase().contains(queryLower)) return true;

      // Tìm theo số điện thoại (cán bộ hoặc tổ trưởng)
      if (item.staffPhone.toLowerCase().contains(queryLower)) return true;
      if (item.leaderPhone.toLowerCase().contains(queryLower)) return true;

      return false;
    }).toList();
  }

  return _sortToDanPhoList(data, sortOption);
});

// Provider for total party member statistics across all organizations
final totalPartyMemberStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final organizations = await ref.watch(toChucDangListProvider.future);

  int totalMembers = 0;
  int officialMembers = 0;
  int probationaryMembers = 0;

  for (var org in organizations) {
    totalMembers += org.totalMembers;
    officialMembers += org.officialMembers;
    probationaryMembers += org.probationaryMembers;
  }

  return {
    'totalMembers': totalMembers,
    'officialMembers': officialMembers,
    'probationaryMembers': probationaryMembers,
  };
});

/// Provider tìm kiếm nâng cao Tổ Dân Phố
/// Hỗ trợ tìm kiếm theo: tên, tổ trưởng, SĐT, cán bộ, mẹ VNAH, tổng nhân khẩu
final advancedFilteredToDanPhoProvider =
    FutureProvider<List<ToDanPho>>((ref) async {
  final query = ref.watch(toDanPhoSearchQueryProvider);
  final sortOption = ref.watch(toDanPhoSortProvider);
  final allToDanPho = await ref.watch(toDanPhoListProvider.future);

  if (query.isEmpty) {
    return _sortToDanPhoList(allToDanPho, sortOption);
  }

  final queryLower = query.toLowerCase();
  final filteredList = <ToDanPho>[];

  // Lấy household stats để tìm kiếm nâng cao
  try {
    // householdStatsListProvider là StreamProvider, cần dùng .future để lấy snapshot đầu tiên
    final householdStatsAsync = ref.watch(householdStatsListProvider);

    // Kiểm tra xem stream đã có dữ liệu chưa
    final householdStatsList = householdStatsAsync.when(
      data: (list) => list,
      loading: () => <HouseholdStats>[],
      error: (_, __) => <HouseholdStats>[],
    );

    for (var tdp in allToDanPho) {
      bool shouldInclude = false;

      // Tìm theo thông tin cơ bản của tổ
      if (tdp.name.toLowerCase().contains(queryLower) ||
          tdp.staffInCharge.toLowerCase().contains(queryLower) ||
          tdp.leader.toLowerCase().contains(queryLower) ||
          tdp.staffPhone.contains(queryLower) ||
          tdp.leaderPhone.contains(queryLower)) {
        shouldInclude = true;
      }

      // Tìm theo thông tin trong household stats
      if (!shouldInclude && householdStatsList.isNotEmpty) {
        try {
          final stats = householdStatsList.firstWhere(
            (s) => s.tdpId == tdp.id,
            orElse: () => throw Exception('Not found'),
          );

          // Tìm theo tổng nhân khẩu
          if (stats.populationCount.toString().contains(queryLower)) {
            shouldInclude = true;
          }

          // Tìm theo tên mẹ VNAH
          if (!shouldInclude && stats.heroicMothers.isNotEmpty) {
            for (var mother in stats.heroicMothers) {
              if (mother.name.toLowerCase().contains(queryLower)) {
                shouldInclude = true;
                break;
              }
            }
          }
        } catch (e) {
          // Không tìm thấy stats cho tổ này, bỏ qua
        }
      }

      if (shouldInclude) {
        filteredList.add(tdp);
      }
    }
  } catch (e) {
    // Nếu lỗi khi lấy household stats, fallback về search cơ bản
    final basicFiltered = allToDanPho.where((item) {
      return item.name.toLowerCase().contains(queryLower) ||
          item.staffInCharge.toLowerCase().contains(queryLower) ||
          item.leader.toLowerCase().contains(queryLower) ||
          item.staffPhone.contains(queryLower) ||
          item.leaderPhone.contains(queryLower);
    }).toList();

    return _sortToDanPhoList(basicFiltered, sortOption);
  }

  return _sortToDanPhoList(filteredList, sortOption);
});

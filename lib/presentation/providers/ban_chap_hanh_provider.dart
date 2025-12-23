import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ban_chap_hanh_data.dart';
import '../../domain/entities/ban_chap_hanh_member.dart';

// Provider for all members
final banChapHanhMembersProvider = Provider<List<BanChapHanhMember>>((ref) {
  return BanChapHanhData.getAllMembers();
});

// Provider for Thường trực
final thuongTrucMembersProvider = Provider<List<BanChapHanhMember>>((ref) {
  return BanChapHanhData.getThuongTruc();
});

// Provider for Thường vụ (includes Thường trực)
final thuongVuMembersProvider = Provider<List<BanChapHanhMember>>((ref) {
  return BanChapHanhData.getThuongVu();
});

// Provider for statistics
final banChapHanhStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return BanChapHanhData.getStatistics();
});

// Provider for filtered members by type
final membersByTypeProvider =
    Provider.family<List<BanChapHanhMember>, MemberType>((ref, type) {
  final allMembers = ref.watch(banChapHanhMembersProvider);
  switch (type) {
    case MemberType.thuongTruc:
      return allMembers.where((m) => m.isThuongTruc).toList();
    case MemberType.thuongVu:
      return allMembers.where((m) => m.isThuongVu || m.isThuongTruc).toList();
    case MemberType.banChapHanh:
      return allMembers;
  }
});

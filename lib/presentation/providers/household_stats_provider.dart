import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/household_stats_service.dart';
import '../../domain/models/household_stats.dart';

// Service provider
final householdStatsServiceProvider = Provider((ref) {
  return HouseholdStatsService();
});

// Stream provider for all household stats
final householdStatsListProvider = StreamProvider<List<HouseholdStats>>((ref) {
  final service = ref.watch(householdStatsServiceProvider);
  return service.getHouseholdStats();
});

// Future provider for total statistics
final totalHouseholdStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(householdStatsServiceProvider);
  return service.getTotalStats();
});

// Family provider for getting stats by TDP ID
final householdStatsByTdpIdProvider =
    FutureProvider.family<HouseholdStats?, String>((ref, tdpId) async {
  final service = ref.watch(householdStatsServiceProvider);
  return service.getStatsByTdpId(tdpId);
});

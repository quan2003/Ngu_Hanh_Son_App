/// Mock data for development and testing
library;

import '../domain/entities/chi_bo.dart';
import '../domain/entities/dang_bo.dart';

class MockData {
  MockData._();

  /// List of Party Organizations (Đảng bộ)
  static final List<DangBo> dangBoList = [
    DangBo(
      id: 'db1',
      name: 'Đảng bộ Phường Ngũ Hành Sơn',
      area: 'Phường Ngũ Hành Sơn, Quận Ngũ Hành Sơn, TP. Đà Nẵng',
      secretary: 'Nguyễn Văn A',
      viceSecretary: 'Trần Thị B',
      totalMembers: 225,
      totalHouseholds: 1175,
      totalPoorHouseholds: 58,
      totalPolicyFamilies: 140,
      chiBoCount: 5,
      description: 'Đảng bộ Phường Ngũ Hành Sơn với 5 Chi bộ trực thuộc',
      coordinates: [16.0544, 108.2022],
    ),
    DangBo(
      id: 'db2',
      name: 'Đảng bộ Phường Hòa Quý',
      area: 'Phường Hòa Quý, Quận Ngũ Hành Sơn, TP. Đà Nẵng',
      secretary: 'Lê Văn C',
      viceSecretary: 'Phạm Thị D',
      totalMembers: 180,
      totalHouseholds: 950,
      totalPoorHouseholds: 42,
      totalPolicyFamilies: 105,
      chiBoCount: 4,
      description: 'Đảng bộ Phường Hòa Quý với 4 Chi bộ trực thuộc',
      coordinates: [16.0644, 108.2122],
    ),
    DangBo(
      id: 'db3',
      name: 'Đảng bộ Phường Hòa Hải',
      area: 'Phường Hòa Hải, Quận Ngũ Hành Sơn, TP. Đà Nẵng',
      secretary: 'Võ Văn E',
      viceSecretary: 'Hoàng Thị F',
      totalMembers: 195,
      totalHouseholds: 1020,
      totalPoorHouseholds: 48,
      totalPolicyFamilies: 115,
      chiBoCount: 4,
      description: 'Đảng bộ Phường Hòa Hải với 4 Chi bộ trực thuộc',
      coordinates: [16.0444, 108.1922],
    ),
  ];

  /// List of Chi Bo (Party Cells) - Organized by Đảng bộ
  static final Map<String, List<ChiBo>> chiBoByDangBo = {
    'db1': [
      // Chi bộ thuộc Đảng bộ Phường Ngũ Hành Sơn
      ChiBo(
        id: 'cb1_1',
        name: 'Chi bộ 1',
        area: 'Tổ dân phố 1, 2, 3',
        members: 45,
        households: 234,
        poorHouseholds: 12,
        policyFamilies: 28,
        description: 'Chi bộ 1 quản lý tổ dân phố 1, 2, 3',
        coordinates: [16.055, 108.201],
        polygon: {
          'type': 'Polygon',
          'coordinates': [
            [
              [108.201, 16.055],
              [108.203, 16.056],
              [108.204, 16.054],
              [108.202, 16.053],
              [108.201, 16.055],
            ]
          ]
        },
      ),
      ChiBo(
        id: 'cb1_2',
        name: 'Chi bộ 2',
        area: 'Tổ dân phố 4, 5, 6',
        members: 38,
        households: 198,
        poorHouseholds: 8,
        policyFamilies: 22,
        description: 'Chi bộ 2 quản lý tổ dân phố 4, 5, 6',
        coordinates: [16.053, 108.205],
        polygon: {
          'type': 'Polygon',
          'coordinates': [
            [
              [108.205, 16.053],
              [108.207, 16.054],
              [108.208, 16.052],
              [108.206, 16.051],
              [108.205, 16.053],
            ]
          ]
        },
      ),
      ChiBo(
        id: 'cb1_3',
        name: 'Chi bộ 3',
        area: 'Tổ dân phố 7, 8, 9',
        members: 52,
        households: 276,
        poorHouseholds: 15,
        policyFamilies: 35,
        description: 'Chi bộ 3 quản lý tổ dân phố 7, 8, 9',
        coordinates: [16.057, 108.203],
        polygon: {
          'type': 'Polygon',
          'coordinates': [
            [
              [108.203, 16.057],
              [108.205, 16.058],
              [108.206, 16.056],
              [108.204, 16.055],
              [108.203, 16.057],
            ]
          ]
        },
      ),
      ChiBo(
        id: 'cb1_4',
        name: 'Chi bộ 4',
        area: 'Tổ dân phố 10, 11, 12',
        members: 42,
        households: 215,
        poorHouseholds: 10,
        policyFamilies: 25,
        description: 'Chi bộ 4 quản lý tổ dân phố 10, 11, 12',
        coordinates: [16.052, 108.199],
        polygon: {
          'type': 'Polygon',
          'coordinates': [
            [
              [108.199, 16.052],
              [108.201, 16.053],
              [108.202, 16.051],
              [108.200, 16.050],
              [108.199, 16.052],
            ]
          ]
        },
      ),
      ChiBo(
        id: 'cb1_5',
        name: 'Chi bộ 5',
        area: 'Tổ dân phố 13, 14, 15',
        members: 48,
        households: 252,
        poorHouseholds: 13,
        policyFamilies: 30,
        description: 'Chi bộ 5 quản lý tổ dân phố 13, 14, 15',
        coordinates: [16.056, 108.207],
        polygon: {
          'type': 'Polygon',
          'coordinates': [
            [
              [108.207, 16.056],
              [108.209, 16.057],
              [108.210, 16.055],
              [108.208, 16.054],
              [108.207, 16.056],
            ]
          ]
        },
      ),
    ],
    'db2': [
      // Chi bộ thuộc Đảng bộ Phường Hòa Quý
      ChiBo(
        id: 'cb2_1',
        name: 'Chi bộ 1',
        area: 'Tổ dân phố 1, 2, 3',
        members: 42,
        households: 220,
        poorHouseholds: 10,
        policyFamilies: 25,
        description: 'Chi bộ 1 - Đảng bộ Hòa Quý',
        coordinates: [16.0644, 108.2122],
      ),
      ChiBo(
        id: 'cb2_2',
        name: 'Chi bộ 2',
        area: 'Tổ dân phố 4, 5, 6',
        members: 45,
        households: 235,
        poorHouseholds: 11,
        policyFamilies: 27,
        description: 'Chi bộ 2 - Đảng bộ Hòa Quý',
        coordinates: [16.0654, 108.2132],
      ),
      ChiBo(
        id: 'cb2_3',
        name: 'Chi bộ 3',
        area: 'Tổ dân phố 7, 8, 9',
        members: 48,
        households: 250,
        poorHouseholds: 12,
        policyFamilies: 28,
        description: 'Chi bộ 3 - Đảng bộ Hòa Quý',
        coordinates: [16.0664, 108.2142],
      ),
      ChiBo(
        id: 'cb2_4',
        name: 'Chi bộ 4',
        area: 'Tổ dân phố 10, 11',
        members: 45,
        households: 245,
        poorHouseholds: 9,
        policyFamilies: 25,
        description: 'Chi bộ 4 - Đảng bộ Hòa Quý',
        coordinates: [16.0634, 108.2112],
      ),
    ],
    'db3': [
      // Chi bộ thuộc Đảng bộ Phường Hòa Hải
      ChiBo(
        id: 'cb3_1',
        name: 'Chi bộ 1',
        area: 'Tổ dân phố 1, 2, 3',
        members: 50,
        households: 260,
        poorHouseholds: 13,
        policyFamilies: 30,
        description: 'Chi bộ 1 - Đảng bộ Hòa Hải',
        coordinates: [16.0444, 108.1922],
      ),
      ChiBo(
        id: 'cb3_2',
        name: 'Chi bộ 2',
        area: 'Tổ dân phố 4, 5, 6',
        members: 47,
        households: 245,
        poorHouseholds: 11,
        policyFamilies: 28,
        description: 'Chi bộ 2 - Đảng bộ Hòa Hải',
        coordinates: [16.0454, 108.1932],
      ),
      ChiBo(
        id: 'cb3_3',
        name: 'Chi bộ 3',
        area: 'Tổ dân phố 7, 8',
        members: 48,
        households: 255,
        poorHouseholds: 12,
        policyFamilies: 29,
        description: 'Chi bộ 3 - Đảng bộ Hòa Hải',
        coordinates: [16.0464, 108.1942],
      ),
      ChiBo(
        id: 'cb3_4',
        name: 'Chi bộ 4',
        area: 'Tổ dân phố 9, 10',
        members: 50,
        households: 260,
        poorHouseholds: 12,
        policyFamilies: 28,
        description: 'Chi bộ 4 - Đảng bộ Hòa Hải',
        coordinates: [16.0434, 108.1912],
      ),
    ],
  };

  /// Legacy: Get all Chi Bo as a flat list (for backward compatibility)
  static List<ChiBo> get chiBoList {
    return chiBoByDangBo.values.expand((list) => list).toList();
  }

  /// Get statistics for a specific Đảng bộ
  static Map<String, dynamic> getStatisticsForDangBo(String dangBoId) {
    final chiBoList = chiBoByDangBo[dangBoId] ?? [];
    int totalPopulation = 0;
    int totalHouseholds = 0;
    int totalPoorHouseholds = 0;
    int totalPolicyFamilies = 0;
    int totalMembers = 0;

    for (var chiBo in chiBoList) {
      totalHouseholds += chiBo.households;
      totalPoorHouseholds += chiBo.poorHouseholds;
      totalPolicyFamilies += chiBo.policyFamilies;
      totalMembers += chiBo.members;
    }

    // Estimate population (avg 3.5 people per household)
    totalPopulation = (totalHouseholds * 3.5).round();

    return {
      'population': totalPopulation,
      'households': totalHouseholds,
      'poorHouseholds': totalPoorHouseholds,
      'policyFamilies': totalPolicyFamilies,
      'chiBoCount': chiBoList.length,
      'partyMembers': totalMembers,
      'heroMothers': (totalHouseholds * 0.076).round(), // Mock ratio
      'schools': (chiBoList.length * 2.4).round(), // Mock ratio
      'culturalHouses': chiBoList.length + 3, // Mock data
    };
  }

  /// Get overall statistics across all Đảng bộ
  static Map<String, dynamic> getStatistics() {
    int totalPopulation = 0;
    int totalHouseholds = 0;
    int totalPoorHouseholds = 0;
    int totalPolicyFamilies = 0;
    int totalMembers = 0;

    for (var chiBo in chiBoList) {
      totalHouseholds += chiBo.households;
      totalPoorHouseholds += chiBo.poorHouseholds;
      totalPolicyFamilies += chiBo.policyFamilies;
      totalMembers += chiBo.members;
    }

    // Estimate population (avg 3.5 people per household)
    totalPopulation = (totalHouseholds * 3.5).round();

    return {
      'population': totalPopulation,
      'households': totalHouseholds,
      'poorHouseholds': totalPoorHouseholds,
      'policyFamilies': totalPolicyFamilies,
      'chiBoCount': chiBoList.length,
      'partyMembers': totalMembers,
      'dangBoCount': dangBoList.length,
      'heroMothers': 231, // Mock data
      'schools': 32, // Mock data
      'culturalHouses': 24, // Mock data
    };
  }
}

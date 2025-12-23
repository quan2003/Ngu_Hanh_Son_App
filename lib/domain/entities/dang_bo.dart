/// Entity representing a Party Organization (Đảng bộ)
class DangBo {
  final String id;
  final String name;
  final String area;
  final String secretary; // Bí thư
  final String viceSecretary; // Phó bí thư
  final int totalMembers; // Tổng số đảng viên
  final int totalHouseholds; // Tổng số hộ dân
  final int totalPoorHouseholds; // Tổng số hộ nghèo
  final int totalPolicyFamilies; // Tổng số GCCS
  final int chiBoCount; // Số lượng Chi bộ
  final String description;
  final List<double> coordinates; // [lat, lng]
  final Map<String, dynamic>? polygon;

  DangBo({
    required this.id,
    required this.name,
    required this.area,
    required this.secretary,
    required this.viceSecretary,
    required this.totalMembers,
    required this.totalHouseholds,
    required this.totalPoorHouseholds,
    required this.totalPolicyFamilies,
    required this.chiBoCount,
    this.description = '',
    this.coordinates = const [0, 0],
    this.polygon,
  });

  factory DangBo.fromJson(Map<String, dynamic> json) {
    return DangBo(
      id: json['id'] as String,
      name: json['name'] as String,
      area: json['area'] as String,
      secretary: json['secretary'] as String,
      viceSecretary: json['viceSecretary'] as String,
      totalMembers: json['totalMembers'] as int,
      totalHouseholds: json['totalHouseholds'] as int,
      totalPoorHouseholds: json['totalPoorHouseholds'] as int,
      totalPolicyFamilies: json['totalPolicyFamilies'] as int,
      chiBoCount: json['chiBoCount'] as int,
      description: json['description'] as String? ?? '',
      coordinates: (json['coordinates'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0, 0],
      polygon: json['polygon'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'secretary': secretary,
      'viceSecretary': viceSecretary,
      'totalMembers': totalMembers,
      'totalHouseholds': totalHouseholds,
      'totalPoorHouseholds': totalPoorHouseholds,
      'totalPolicyFamilies': totalPolicyFamilies,
      'chiBoCount': chiBoCount,
      'description': description,
      'coordinates': coordinates,
      'polygon': polygon,
    };
  }

  @override
  String toString() {
    return 'DangBo(id: $id, name: $name, chiBoCount: $chiBoCount)';
  }
}

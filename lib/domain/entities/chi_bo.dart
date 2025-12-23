/// Chi Bo (Chi Bộ) Entity
class ChiBo {
  final String id;
  final String name;
  final String area;
  final int members;
  final int households;
  final int poorHouseholds;
  final int policyFamilies;
  final String? description;
  final List<double>? coordinates; // [lat, lng]
  final Map<String, dynamic>? polygon; // GeoJSON polygon

  ChiBo({
    required this.id,
    required this.name,
    required this.area,
    required this.members,
    required this.households,
    this.poorHouseholds = 0,
    this.policyFamilies = 0,
    this.description,
    this.coordinates,
    this.polygon,
  });

  factory ChiBo.fromJson(Map<String, dynamic> json) {
    return ChiBo(
      id: json['id'] as String,
      name: json['name'] as String,
      area: json['area'] as String,
      members: json['members'] as int,
      households: json['households'] as int,
      poorHouseholds: json['poorHouseholds'] as int? ?? 0,
      policyFamilies: json['policyFamilies'] as int? ?? 0,
      description: json['description'] as String?,
      coordinates: json['coordinates'] != null
          ? List<double>.from(json['coordinates'] as List)
          : null,
      polygon: json['polygon'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'members': members,
      'households': households,
      'poorHouseholds': poorHouseholds,
      'policyFamilies': policyFamilies,
      'description': description,
      'coordinates': coordinates,
      'polygon': polygon,
    };
  }
}

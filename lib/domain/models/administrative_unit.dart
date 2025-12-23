/// Model for administrative units (Chi bộ, Tổ dân phố, etc.)
class AdministrativeUnit {
  final String id;
  final String name;
  final String type; // 'chi_bo', 'to_dan_pho', 'phuong'
  final String? description;
  final Map<String, dynamic>? properties;
  final List<List<double>>? boundaryCoordinates; // For polygons
  final double? centerLat; // For point markers
  final double? centerLng;
  final String? color; // Display color on map
  final int? memberCount;
  final String? leaderId;
  final String? leaderName;
  final String? leaderPhone;
  
  const AdministrativeUnit({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.properties,
    this.boundaryCoordinates,
    this.centerLat,
    this.centerLng,
    this.color,
    this.memberCount,
    this.leaderId,
    this.leaderName,
    this.leaderPhone,
  });
  
  factory AdministrativeUnit.fromJson(Map<String, dynamic> json) {
    return AdministrativeUnit(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
      boundaryCoordinates: json['boundary'] != null
          ? (json['boundary'] as List)
              .map((coord) => (coord as List).map((e) => (e as num).toDouble()).toList())
              .toList()
          : null,
      centerLat: json['centerLat'] as double?,
      centerLng: json['centerLng'] as double?,
      color: json['color'] as String?,
      memberCount: json['memberCount'] as int?,
      leaderId: json['leaderId'] as String?,
      leaderName: json['leaderName'] as String?,
      leaderPhone: json['leaderPhone'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (description != null) 'description': description,
      if (properties != null) 'properties': properties,
      if (boundaryCoordinates != null) 'boundary': boundaryCoordinates,
      if (centerLat != null) 'centerLat': centerLat,
      if (centerLng != null) 'centerLng': centerLng,
      if (color != null) 'color': color,
      if (memberCount != null) 'memberCount': memberCount,
      if (leaderId != null) 'leaderId': leaderId,
      if (leaderName != null) 'leaderName': leaderName,
      if (leaderPhone != null) 'leaderPhone': leaderPhone,
    };
  }
}

/// Entity for Tổ dân phố (Residential Group)
class ToDanPho {
  final String id;
  final String name;
  final String staffInCharge; // Cán bộ phụ trách
  final String staffPosition; // Chức vụ
  final String staffPhone;
  final String leader; // Tổ trưởng
  final String leaderPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  ToDanPho({
    required this.id,
    required this.name,
    this.staffInCharge = '',
    this.staffPosition = '',
    this.staffPhone = '',
    this.leader = '',
    this.leaderPhone = '',
    required this.createdAt,
    required this.updatedAt,
  });
  factory ToDanPho.fromJson(Map<String, dynamic> json) {
    // Helper function to parse timestamp
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;

      // Handle Firestore Timestamp
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }

      // Handle string
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return ToDanPho(
      id: json['id'] as String,
      name: json['name'] as String,
      staffInCharge: json['staffInCharge'] as String? ?? '',
      staffPosition: json['staffPosition'] as String? ?? '',
      staffPhone: json['staffPhone'] as String? ?? '',
      leader: json['leader'] as String? ?? '',
      leaderPhone: json['leaderPhone'] as String? ?? '',
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'staffInCharge': staffInCharge,
      'staffPosition': staffPosition,
      'staffPhone': staffPhone,
      'leader': leader,
      'leaderPhone': leaderPhone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() => 'ToDanPho(id: $id, name: $name)';
}

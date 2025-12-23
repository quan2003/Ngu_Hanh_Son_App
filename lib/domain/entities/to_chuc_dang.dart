/// Entity for Tổ chức Đảng (Party Organization)
class ToChucDang {
  final String id;
  final String type; // Chi bộ, Đảng bộ cơ sở, etc.
  final String name;
  final int stt; // Số thứ tự (order number)
  final String officerInCharge; // Ủy viên phụ trách
  final String officerPosition; // Chức vụ
  final String officerPhone;
  final String secretary; // Bí thư
  final String secretaryPhone;
  final int totalMembers; // Tổng số đảng viên
  final int officialMembers; // Số đảng viên chính thức
  final int probationaryMembers; // Số đảng viên dự bị
  final DateTime createdAt;
  final DateTime updatedAt;

  ToChucDang({
    required this.id,
    required this.type,
    required this.name,
    this.stt = 999, // Default high number for items without order
    this.officerInCharge = '',
    this.officerPosition = '',
    this.officerPhone = '',
    this.secretary = '',
    this.secretaryPhone = '',
    this.totalMembers = 0,
    this.officialMembers = 0,
    this.probationaryMembers = 0,
    required this.createdAt,
    required this.updatedAt,
  });
  factory ToChucDang.fromJson(Map<String, dynamic> json) {
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

    return ToChucDang(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'Chi bộ',
      name: json['name'] as String,
      stt: json['stt'] as int? ?? 999,
      officerInCharge: json['officerInCharge'] as String? ?? '',
      officerPosition: json['officerPosition'] as String? ?? '',
      officerPhone: json['officerPhone'] as String? ?? '',
      secretary: json['secretary'] as String? ?? '',
      secretaryPhone: json['secretaryPhone'] as String? ?? '',
      totalMembers: json['totalMembers'] as int? ?? 0,
      officialMembers: json['officialMembers'] as int? ?? 0,
      probationaryMembers: json['probationaryMembers'] as int? ?? 0,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'stt': stt,
      'officerInCharge': officerInCharge,
      'officerPosition': officerPosition,
      'officerPhone': officerPhone,
      'secretary': secretary,
      'secretaryPhone': secretaryPhone,
      'totalMembers': totalMembers,
      'officialMembers': officialMembers,
      'probationaryMembers': probationaryMembers,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() =>
      'ToChucDang(id: $id, stt: $stt, name: $name, type: $type)';
}

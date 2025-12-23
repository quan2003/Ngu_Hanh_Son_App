/// Entity representing a member of the Party Committee (Ban Chấp hành Đảng bộ)
class BanChapHanhMember {
  final int stt;
  final String name;
  final String position;
  final MemberType type;

  BanChapHanhMember({
    required this.stt,
    required this.name,
    required this.position,
    required this.type,
  });

  factory BanChapHanhMember.fromJson(Map<String, dynamic> json) {
    return BanChapHanhMember(
      stt: json['stt'] as int,
      name: json['name'] as String,
      position: json['position'] as String,
      type: MemberType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stt': stt,
      'name': name,
      'position': position,
      'type': type.value,
    };
  }

  bool get isThuongVu => type == MemberType.thuongVu;
  bool get isThuongTruc => type == MemberType.thuongTruc;
  bool get isBanChapHanh => type == MemberType.banChapHanh;

  @override
  String toString() {
    return 'BanChapHanhMember(stt: $stt, name: $name, type: ${type.value})';
  }
}

enum MemberType {
  thuongTruc('thuong_truc'),
  thuongVu('thuong_vu'),
  banChapHanh('ban_chap_hanh');

  final String value;
  const MemberType(this.value);

  static MemberType fromString(String value) {
    switch (value) {
      case 'thuong_truc':
        return MemberType.thuongTruc;
      case 'thuong_vu':
        return MemberType.thuongVu;
      case 'ban_chap_hanh':
        return MemberType.banChapHanh;
      default:
        return MemberType.banChapHanh;
    }
  }

  String get label {
    switch (this) {
      case MemberType.thuongTruc:
        return 'Thường trực Đảng ủy';
      case MemberType.thuongVu:
        return 'Ban Thường vụ Đảng ủy';
      case MemberType.banChapHanh:
        return 'Ban Chấp hành Đảng bộ';
    }
  }
}

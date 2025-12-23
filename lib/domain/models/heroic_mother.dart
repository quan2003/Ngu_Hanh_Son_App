/// Model for Heroic Mother (Mẹ Việt Nam Anh hùng)
class HeroicMother {
  final String name; // Tên Mẹ VNAH
  final String birthYear; // Năm sinh
  final String tdp; // Tổ dân phố

  const HeroicMother({
    required this.name,
    required this.birthYear,
    required this.tdp,
  });

  factory HeroicMother.fromJson(Map<String, dynamic> json) {
    return HeroicMother(
      name: json['name'] as String? ?? '',
      birthYear: json['birthYear'] as String? ?? '',
      tdp: json['tdp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthYear': birthYear,
      'tdp': tdp,
    };
  }

  HeroicMother copyWith({
    String? name,
    String? birthYear,
    String? tdp,
  }) {
    return HeroicMother(
      name: name ?? this.name,
      birthYear: birthYear ?? this.birthYear,
      tdp: tdp ?? this.tdp,
    );
  }
}

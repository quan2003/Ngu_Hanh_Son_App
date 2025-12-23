import 'heroic_mother.dart';

/// Model for household statistics (Số hộ gia đình)
class HouseholdStats {
  final String tdpId;
  final String tdpName;
  final int oldHouseholdCount;
  final int reportedHouseholdCount;
  final int populationCount;
  final int poorHouseholdCity;
  final int poorHouseholdCentral;
  final int nearPoorHouseholdCity;
  final int nearPoorHouseholdCentral;
  final List<HeroicMother> heroicMothers;
  final String? meetingLocationName;
  final String? meetingLocationAddress;

  const HouseholdStats({
    required this.tdpId,
    required this.tdpName,
    required this.oldHouseholdCount,
    required this.reportedHouseholdCount,
    required this.populationCount,
    this.poorHouseholdCity = 0,
    this.poorHouseholdCentral = 0,
    this.nearPoorHouseholdCity = 0,
    this.nearPoorHouseholdCentral = 0,
    this.heroicMothers = const [],
    this.meetingLocationName,
    this.meetingLocationAddress,
  });

  factory HouseholdStats.fromJson(Map<String, dynamic> json) {
    List<HeroicMother> mothers = [];
    if (json['heroicMothers'] != null) {
      mothers = (json['heroicMothers'] as List)
          .map((m) => HeroicMother.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return HouseholdStats(
      tdpId: json['tdpId'] as String? ?? '',
      tdpName: json['tdpName'] as String? ?? '',
      oldHouseholdCount: json['oldHouseholdCount'] as int? ?? 0,
      reportedHouseholdCount: json['reportedHouseholdCount'] as int? ?? 0,
      populationCount: json['populationCount'] as int? ?? 0,
      poorHouseholdCity: json['poorHouseholdCity'] as int? ?? 0,
      poorHouseholdCentral: json['poorHouseholdCentral'] as int? ?? 0,
      nearPoorHouseholdCity: json['nearPoorHouseholdCity'] as int? ?? 0,
      nearPoorHouseholdCentral: json['nearPoorHouseholdCentral'] as int? ?? 0,
      heroicMothers: mothers,
      meetingLocationName: json['meetingLocationName'] as String?,
      meetingLocationAddress: json['meetingLocationAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tdpId': tdpId,
      'tdpName': tdpName,
      'oldHouseholdCount': oldHouseholdCount,
      'reportedHouseholdCount': reportedHouseholdCount,
      'populationCount': populationCount,
      'poorHouseholdCity': poorHouseholdCity,
      'poorHouseholdCentral': poorHouseholdCentral,
      'nearPoorHouseholdCity': nearPoorHouseholdCity,
      'nearPoorHouseholdCentral': nearPoorHouseholdCentral,
      'heroicMothers': heroicMothers.map((m) => m.toJson()).toList(),
      if (meetingLocationName != null)
        'meetingLocationName': meetingLocationName,
      if (meetingLocationAddress != null)
        'meetingLocationAddress': meetingLocationAddress,
    };
  }

  HouseholdStats copyWith({
    String? tdpId,
    String? tdpName,
    int? oldHouseholdCount,
    int? reportedHouseholdCount,
    int? populationCount,
    int? poorHouseholdCity,
    int? poorHouseholdCentral,
    int? nearPoorHouseholdCity,
    int? nearPoorHouseholdCentral,
    List<HeroicMother>? heroicMothers,
    String? meetingLocationName,
    String? meetingLocationAddress,
  }) {
    return HouseholdStats(
      tdpId: tdpId ?? this.tdpId,
      tdpName: tdpName ?? this.tdpName,
      oldHouseholdCount: oldHouseholdCount ?? this.oldHouseholdCount,
      reportedHouseholdCount:
          reportedHouseholdCount ?? this.reportedHouseholdCount,
      populationCount: populationCount ?? this.populationCount,
      poorHouseholdCity: poorHouseholdCity ?? this.poorHouseholdCity,
      poorHouseholdCentral: poorHouseholdCentral ?? this.poorHouseholdCentral,
      nearPoorHouseholdCity:
          nearPoorHouseholdCity ?? this.nearPoorHouseholdCity,
      nearPoorHouseholdCentral:
          nearPoorHouseholdCentral ?? this.nearPoorHouseholdCentral,
      heroicMothers: heroicMothers ?? this.heroicMothers,
      meetingLocationName: meetingLocationName ?? this.meetingLocationName,
      meetingLocationAddress:
          meetingLocationAddress ?? this.meetingLocationAddress,
    );
  }
}

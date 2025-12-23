import '../../domain/entities/ban_chap_hanh_member.dart';

/// Static data source for Ban Chap Hanh members
class BanChapHanhData {
  static List<BanChapHanhMember> getAllMembers() {
    return [
      // Thường trực Đảng ủy (3 người)
      BanChapHanhMember(
        stt: 1,
        name: 'Mai Thị Ánh Hồng',
        position:
            'Thành ủy viên, Bí thư Đảng ủy, Chủ tịch Hội đồng nhân dân lâm thời phường',
        type: MemberType.thuongTruc,
      ),
      BanChapHanhMember(
        stt: 2,
        name: 'Lê Thị Thanh Duyên',
        position: 'Phó Bí thư Thường trực Đảng ủy phường',
        type: MemberType.thuongTruc,
      ),
      BanChapHanhMember(
        stt: 3,
        name: 'Nguyễn Hoà',
        position: 'Phó Bí thư Đảng ủy, Chủ tịch Ủy ban nhân dân phường',
        type: MemberType.thuongTruc,
      ),

      // Ban Thường vụ Đảng ủy (11 người, bao gồm 3 Thường trực)
      BanChapHanhMember(
        stt: 4,
        name: 'Đặng Văn Kỳ',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Chủ tịch Ủy ban Mặt trận Tổ quốc Việt Nam phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 5,
        name: 'Trần Thị Ngọc Lan',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Chánh Văn phòng Đảng ủy phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 6,
        name: 'Mai Niên',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Phó Chủ tịch Hội đồng nhân dân lâm thời phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 7,
        name: 'Hồ Thị Thanh Thuý',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Chủ nhiệm Ủy ban Kiểm tra Đảng ủy phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 8,
        name: 'Nguyễn Đức Việt',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Phó Chủ tịch Ủy ban nhân dân phường kiêm Giám đốc Trung tâm phục vụ hành chính công phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 9,
        name: 'Huỳnh Đức Vinh',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Trưởng Ban Xây dựng Đảng phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 10,
        name: 'Võ Trung Thành',
        position:
            'Ủy viên Ban Thường vụ Đảng ủy, Chỉ huy trưởng Ban Chỉ huy quân sự phường',
        type: MemberType.thuongVu,
      ),
      BanChapHanhMember(
        stt: 11,
        name: 'Nguyễn Thanh Tuấn',
        position: 'Ủy viên Ban Thường vụ Đảng ủy, Trưởng Công an phường',
        type: MemberType.thuongVu,
      ),

      // Ban Chấp hành Đảng bộ (32 người, bao gồm 11 Thường vụ)
      BanChapHanhMember(
        stt: 12,
        name: 'Tạ Tự Bình',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ tịch Ủy ban nhân dân phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 13,
        name: 'Hoàng Trân Châu',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ tịch Ủy ban Mặt trận Tổ quốc Việt Nam phường đồng thời là Chủ tịch Hội Liên hiệp Phụ nữ phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 14,
        name: 'Phan Thị Dinh',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Trưởng Phòng Kinh tế, Hạ tầng và Đô thị phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 15,
        name: 'Huỳnh Phước Đô',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ nhiệm Thường trực Ủy ban Kiểm tra Đảng ủy phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 16,
        name: 'Nguyễn Thành Linh',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Trưởng Ban Thường trực Ban Xây dựng Đảng phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 17,
        name: 'Nguyễn Văn Minh',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ tịch Ủy ban Mặt trận Tổ quốc Việt Nam phường đồng thời là Chủ tịch Công đoàn phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 18,
        name: 'Trần Văn Minh',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ tịch Ủy ban Mặt trận Tổ quốc Việt Nam phường đồng thời là Chủ tịch Hội Nông dân phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 19,
        name: 'Phạm Thị Lệ Thủy',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Trưởng Phòng Văn hoá - Xã hội phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 20,
        name: 'Nguyễn Văn Tiên',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Giám đốc Trung tâm cung ứng dịch vụ sự nghiệp công phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 21,
        name: 'Nguyễn Thị Hải Vân',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Trưởng Ban Xây dựng Đảng phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 22,
        name: 'Nguyễn Thị Vân Anh',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ nhiệm Ủy ban Kiểm tra Đảng ủy phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 23,
        name: 'Lê Thị Kim Hoa',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Trưởng Ban Xây dựng Đảng phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 24,
        name: 'Võ Thị Hoài',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Trưởng Phòng Kinh tế, Hạ tầng và Đô thị phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 25,
        name: 'Hồ Hồng Minh',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Trưởng Ban Kinh tế - Ngân sách Hội đồng nhân dân lâm thời phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 26,
        name: 'Nguyễn Thị Nga',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Chánh Văn phòng Hội đồng nhân dân và Ủy ban nhân dân phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 27,
        name: 'Lê Ngọc Nhất',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Giám đốc Trung tâm phục vụ hành chính công phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 28,
        name: 'Lê Xuân Thành',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chủ tịch Ủy ban Mặt trận Tổ quốc Việt Nam phường đồng thời là Bí thư Đoàn Thanh niên phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 29,
        name: 'Phùng Văn Thành',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Trưởng Ban Văn hóa - Xã hội Hội đồng nhân dân lâm thời phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 30,
        name: 'Hoàng Hải Thọ',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Chánh Văn phòng Đảng ủy phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 31,
        name: 'Trần Thị Vân',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Phó Giám đốc Trung tâm phục vụ hành chính công phường',
        type: MemberType.banChapHanh,
      ),
      BanChapHanhMember(
        stt: 32,
        name: 'Vũ Minh Nghĩa',
        position:
            'Ủy viên Ban Chấp hành Đảng bộ phường, Đồn Trưởng Đồn Biên phòng Non Nước',
        type: MemberType.banChapHanh,
      ),
    ];
  }

  static List<BanChapHanhMember> getThuongTruc() {
    return getAllMembers().where((m) => m.isThuongTruc).toList();
  }

  static List<BanChapHanhMember> getThuongVu() {
    return getAllMembers()
        .where((m) => m.isThuongVu || m.isThuongTruc)
        .toList();
  }

  static List<BanChapHanhMember> getBanChapHanh() {
    return getAllMembers();
  }

  static Map<String, dynamic> getStatistics() {
    final all = getAllMembers();
    final thuongTruc = getThuongTruc();
    final thuongVu = getThuongVu();

    return {
      'totalMembers': all.length,
      'thuongTrucCount': thuongTruc.length,
      'thuongVuCount': thuongVu.length,
      'banChapHanhCount': all.length,
      'femaleCount': 13, // Based on the data provided
      'thuongVuFemaleCount': 4, // Based on the data provided
      // Party members statistics
      'totalPartyMembers': 4905,
      'officialMembers': 4597,
      'probationaryMembers': 308,
    };
  }
}

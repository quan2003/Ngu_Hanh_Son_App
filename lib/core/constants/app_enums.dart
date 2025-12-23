/// User roles for authorization
enum UserRole {
  citizen,
  chiBo,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Người dân';
      case UserRole.chiBo:
        return 'Chi bộ';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  bool get canManageChiBo => this == UserRole.chiBo || this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin;
  bool get canApproveFeedback =>
      this == UserRole.chiBo || this == UserRole.admin;
}

/// Feedback status
enum FeedbackStatus {
  pending,
  processing,
  completed,
  rejected,
  cancelled, // Hủy xử lý
  deleted; // Đã xóa

  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Đã nhận';
      case FeedbackStatus.processing:
        return 'Đang xử lý';
      case FeedbackStatus.completed:
        return 'Hoàn tất';
      case FeedbackStatus.rejected:
        return 'Đã từ chối';
      case FeedbackStatus.cancelled:
        return 'Đã hủy';
      case FeedbackStatus.deleted:
        return 'Đã xóa';
    }
  }
}

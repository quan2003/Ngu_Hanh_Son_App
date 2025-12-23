enum NotificationType {
  info,
  warning,
  success,
  error,
  announcement,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
    this.metadata,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  } // Convert from JSON

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle createdAt - can be Timestamp or String
    DateTime createdAt;
    final createdAtValue = json['createdAt'];

    if (createdAtValue == null) {
      createdAt = DateTime.now();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else {
      // It's a Firestore Timestamp
      createdAt = (createdAtValue as dynamic).toDate();
    }

    // Handle different field names (body vs message)
    final String message = json['message'] as String? ??
        json['body'] as String? ??
        'Không có nội dung';

    // Handle type field - can be string directly or in data map
    String? typeString = json['type'] as String?;
    if (typeString == null && json['data'] is Map) {
      typeString = (json['data'] as Map<String, dynamic>)['type'] as String?;
    }

    final NotificationType type = typeString != null
        ? NotificationType.values.firstWhere(
            (e) => e.name == typeString,
            orElse: () => NotificationType.info,
          )
        : NotificationType.info;

    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Thông báo',
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: json['read'] as bool? ?? json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ??
          json['data'] as Map<String, dynamic>?,
    );
  }

  // Copy with
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Feedback Entity
class Feedback {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final List<String> images;
  final Map<String, double>? location; // {lat, lng}
  final String? response;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.images = const [],
    this.location,
    this.response,
    required this.createdAt,
    this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      location: json['location'] != null
          ? Map<String, double>.from(json['location'] as Map)
          : null,
      response: json['response'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'images': images,
      'location': location,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

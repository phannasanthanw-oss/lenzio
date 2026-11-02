class Todo {
  final int? id;
  final String? userId;
  final String title;
  final String? description;
  final bool isComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Todo({
    this.id,
    this.userId,
    required this.title,
    this.description,
    this.isComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a [Todo] instance from Supabase JSON map
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isComplete: json['is_complete'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  /// Convert to JSON map for Supabase insert / update operations
  ///
  /// Set [forInsert] to true to exclude the [id] and let Supabase auto-generate it.
  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'is_complete': isComplete,
    };

    if (!forInsert && id != null) {
      map['id'] = id;
    }
    if (userId != null) {
      map['user_id'] = userId;
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  /// Create a copy of [Todo] with updated fields
  Todo copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    bool? isComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, userId: $userId, title: $title, isComplete: $isComplete, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, title, description, isComplete);
  }
}

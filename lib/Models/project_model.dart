class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? videoUrl;
  final String status; // 'draft', 'processing', 'completed', 'failed'
  final String type; // 'avatar-based', 'text-based'
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final String? avatarId;
  final String? avatarImageUrl; // For avatar-based projects
  final int duration; // in seconds
  final String aspectRatio;
  final int resolution;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.avatarId,
    this.avatarImageUrl,
    required this.duration,
    this.aspectRatio = '720:1280',
    this.resolution = 1080,
  });

  // Helper getters
  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString().substring(2);
    return '$day/$month/$year';
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isFailed => status.toLowerCase() == 'failed';

  // Factory constructor from JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Handle populated avatarId (can be either String or Map)
    String? avatarIdValue;
    String? avatarImageUrlValue;
    if (json['avatarId'] != null) {
      if (json['avatarId'] is String) {
        avatarIdValue = json['avatarId'];
      } else if (json['avatarId'] is Map<String, dynamic>) {
        avatarIdValue = json['avatarId']['_id'] ?? json['avatarId']['id'];
        avatarImageUrlValue = json['avatarId']['imageUrl'];
      }
    }

    return ProjectModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Project',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail'] ?? '',
      videoUrl: json['videoUrl'] ?? json['video_url'],
      status: json['status'] ?? 'draft',
      type: json['type'] ?? 'text-based',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      metadata: json['metadata'],
      avatarId: avatarIdValue,
      avatarImageUrl: avatarImageUrlValue,
      duration: json['duration'] ?? json['configuration']?['duration'] ?? 30,
      aspectRatio:
          json['aspectRatio'] ??
          json['configuration']?['aspectRatio'] ??
          '720:1280',
      resolution:
          json['resolution'] ?? json['configuration']?['resolution'] ?? 1080,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'status': status,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'avatarId': avatarId,
      'duration': duration,
      'aspectRatio': aspectRatio,
      'resolution': resolution,
    };
  }

  // Copy with method for immutable updates
  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    String? status,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? avatarId,
    int? duration,
    String? aspectRatio,
    int? resolution,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      avatarId: avatarId ?? this.avatarId,
      duration: duration ?? this.duration,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  String toString() {
    return 'ProjectModel{id: $id, title: $title, status: $status, type: $type}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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
  final int duration; // in seconds
  final String? style;
  final String? voice;
  final String aspectRatio;
  final int resolution;
  final bool withAudio;
  final bool withSubtitles;
  final bool withLipSync;

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
    required this.duration,
    this.style,
    this.voice,
    this.aspectRatio = '9:16',
    this.resolution = 1080,
    this.withAudio = true,
    this.withSubtitles = true,
    this.withLipSync = true,
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
      avatarId: json['avatarId'],
      duration: json['duration'] ?? 30,
      style: json['style'],
      voice: json['voice'],
      aspectRatio: json['aspectRatio'] ?? '9:16',
      resolution: json['resolution'] ?? 1080,
      withAudio: json['withAudio'] ?? true,
      withSubtitles: json['withSubtitles'] ?? true,
      withLipSync: json['withLipSync'] ?? true,
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
      'style': style,
      'voice': voice,
      'aspectRatio': aspectRatio,
      'resolution': resolution,
      'withAudio': withAudio,
      'withSubtitles': withSubtitles,
      'withLipSync': withLipSync,
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
    String? style,
    String? voice,
    String? aspectRatio,
    int? resolution,
    bool? withAudio,
    bool? withSubtitles,
    bool? withLipSync,
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
      style: style ?? this.style,
      voice: voice ?? this.voice,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      resolution: resolution ?? this.resolution,
      withAudio: withAudio ?? this.withAudio,
      withSubtitles: withSubtitles ?? this.withSubtitles,
      withLipSync: withLipSync ?? this.withLipSync,
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

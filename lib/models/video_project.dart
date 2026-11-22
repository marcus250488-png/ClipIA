enum ProjectStatus { imported, queued, processing, completed, failed }

class VideoProject {
  const VideoProject({
    required this.id,
    required this.title,
    required this.sourcePath,
    required this.createdAt,
    this.status = ProjectStatus.imported,
    this.sourceType = 'file',
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String sourcePath;
  final DateTime createdAt;
  final ProjectStatus status;
  final String sourceType;
  final String? sourceUrl;

  Map<String, Object?> toMap() => {
    'id': id, 'title': title, 'sourcePath': sourcePath,
    'createdAt': createdAt.toIso8601String(), 'status': status.name,
    'sourceType': sourceType, 'sourceUrl': sourceUrl,
  };

  factory VideoProject.fromMap(Map<String, Object?> map) => VideoProject(
    id: map['id'] as String,
    title: map['title'] as String,
    sourcePath: map['sourcePath'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    status: ProjectStatus.values.firstWhere(
      (s) => s.name == map['status'], orElse: () => ProjectStatus.imported),
    sourceType: map['sourceType'] as String? ?? 'file',
    sourceUrl: map['sourceUrl'] as String?,
  );
}

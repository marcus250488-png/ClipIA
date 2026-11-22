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

  /// Original source URL, when the project was created from a supported link.
  final String? sourceUrl;
}

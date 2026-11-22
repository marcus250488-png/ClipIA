enum ProjectStatus { imported, queued, processing, completed, failed }

class VideoProject {
  const VideoProject({
    required this.id, required this.title, required this.sourcePath, required this.createdAt,
    this.status = ProjectStatus.imported, this.sourceType = 'file',
  });
  final String id;
  final String title;
  final String sourcePath;
  final DateTime createdAt;
  final ProjectStatus status;
  final String sourceType;
}

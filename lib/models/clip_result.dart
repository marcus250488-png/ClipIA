class ClipResult {
  const ClipResult({required this.id, required this.projectId, required this.title,
    required this.filePath, required this.startSeconds, required this.endSeconds,
    required this.aspectRatio, this.captionFilePath, this.score});
  final String id, projectId, title, filePath, aspectRatio;
  final double startSeconds, endSeconds;
  final String? captionFilePath;
  final double? score;
  double get durationSeconds => endSeconds - startSeconds;
}

import '../models/video_project.dart';

/// Armazenamento temporário; SQLite será adicionado em etapa própria.
class ProjectStore {
  final List<VideoProject> _projects = [];
  List<VideoProject> get projects => List.unmodifiable(_projects);
  void add(VideoProject project) => _projects.insert(0, project);
}

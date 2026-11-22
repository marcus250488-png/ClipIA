import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/video_project.dart';

class ProjectStore {
  ProjectStore._();
  static final ProjectStore instance = ProjectStore._();
  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'clipia_projects.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            sourcePath TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            status TEXT NOT NULL,
            sourceType TEXT NOT NULL,
            sourceUrl TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<VideoProject>> all() async {
    final db = await _database();
    final rows = await db.query('projects', orderBy: 'createdAt DESC');
    return rows.map(VideoProject.fromMap).toList();
  }

  Future<void> add(VideoProject project) async {
    final db = await _database();
    await db.insert('projects', project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _database();
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}

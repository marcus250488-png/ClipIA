import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/video_project.dart';
import '../services/project_store.dart';
import 'project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final _store = ProjectStore();
  bool _busy = false;
  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      final path = result?.files.single.path;
      if (path == null || !await File(path).exists()) return;
      final project = VideoProject(id: const Uuid().v4(), title: result!.files.single.name,
        sourcePath: path, createdAt: DateTime.now());
      _store.add(project);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: project)));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('✨ ClipIA')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Transforme vídeos longos em cortes curtos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Importe um vídeo, escolha o trecho e exporte seu primeiro corte. A seleção inteligente por IA virá em outra etapa.'),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: _busy ? null : _pick, icon: const Icon(Icons.video_library), label: Text(_busy ? 'Importando...' : 'Selecionar vídeo')),
      const SizedBox(height: 24),
      const Text('Meus projetos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ..._store.projects.map((p) => Card(child: ListTile(title: Text(p.title), subtitle: const Text('Vídeo importado'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: p))))),
      if (_store.projects.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Seus projetos aparecerão aqui.')),
    ]),
  );
}

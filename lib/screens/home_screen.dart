import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/youtube_url_validator.dart';
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
  final _linkController = TextEditingController();
  bool _busy = false;

  Future<void> _showLinkImport() async {
    _linkController.clear();
    final link = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importar link do YouTube'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=...',
              labelText: 'Link do vídeo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'O ClipIA aceita links de vídeos de qualquer canal. Nesta versão, o link fica associado ao projeto, mas a importação automática da mídia ainda está em desenvolvimento. Para começar a editar agora, selecione o arquivo de vídeo disponível no seu dispositivo.',
            style: TextStyle(fontSize: 12),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, _linkController.text.trim()), child: const Text('Continuar')),
        ],
      ),
    );
    if (!mounted || link == null || link.isEmpty) return;
    final normalizedLink = YouTubeUrlValidator.normalize(link);
    if (normalizedLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um link válido do YouTube.')));
      return;
    }
    await _pick(sourceUrl: normalizedLink);
  }

  Future<void> _pick({String? sourceUrl}) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      final path = result?.files.single.path;
      if (path == null || !await File(path).exists()) return;
      final project = VideoProject(
        id: const Uuid().v4(),
        title: result!.files.single.name,
        sourcePath: path,
        createdAt: DateTime.now(),
        sourceUrl: sourceUrl,
        sourceType: sourceUrl == null ? 'file' : 'youtube',
      );
      _store.add(project);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: project)));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('✨ ClipIA')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Transforme vídeos longos em cortes curtos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Cole um link do YouTube ou importe um vídeo da galeria para criar seus cortes.'),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _busy ? null : _pick,
        icon: const Icon(Icons.video_library),
        label: Text(_busy ? 'Importando...' : 'Selecionar vídeo da galeria'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _busy ? null : _showLinkImport,
        icon: const Icon(Icons.link),
        label: const Text('Colar link do YouTube'),
      ),
      const SizedBox(height: 24),
      const Text('Meus projetos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ..._store.projects.map((p) => Card(
        child: ListTile(
          title: Text(p.title),
          subtitle: Text(p.sourceUrl == null ? 'Vídeo importado' : 'Origem: YouTube'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: p))),
        ),
      )),
      if (_store.projects.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Seus projetos aparecerão aqui.')),
    ]),
  );
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/video_project.dart';
import '../services/project_store.dart';
import '../utils/youtube_url_validator.dart';
import 'project_screen.dart';

const _accent = Color(0xFFB99AFF);
const _panel = Color(0xFF171520);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = ProjectStore.instance;
  List<VideoProject> _projects = [];
  bool _busy = false, _loadingProjects = true;

  @override
  void initState() { super.initState(); _loadProjects(); }

  Future<void> _loadProjects() async {
    try {
      final projects = await _store.all();
      if (mounted) setState(() { _projects = projects; _loadingProjects = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Future<void> _showLinkImport() async {
    final controller = TextEditingController();
    String? error;
    final link = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _panel,
          title: const Text('Adicionar vídeo por link'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Cole um link de vídeo do YouTube. Use apenas conteúdo seu ou que você tenha autorização para editar.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller, autofocus: true, keyboardType: TextInputType.url, autocorrect: false,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...', labelText: 'Link do YouTube', errorText: error,
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  tooltip: 'Colar da área de transferência', icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!.trim();
                      setDialogState(() => error = null);
                    }
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (_) => setDialogState(() => error = null),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final normalized = YouTubeUrlValidator.normalize(controller.text);
                if (normalized == null) {
                  setDialogState(() => error = 'Link não reconhecido. Confira o endereço do YouTube.');
                  return;
                }
                Navigator.pop(dialogContext, normalized);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || link == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link validado. Para editar, importe o arquivo de vídeo autorizado correspondente.')));
    await _pick(sourceUrl: link);
  }

  Future<void> _pick({String? sourceUrl}) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      final selected = result?.files.single;
      if (selected?.path == null) return;
      final source = File(selected!.path!);
      if (!await source.exists()) throw Exception('O arquivo selecionado não foi encontrado.');
      final dir = await getApplicationDocumentsDirectory();
      final videos = Directory(p.join(dir.path, 'ClipIA', 'originais'));
      await videos.create(recursive: true);
      final safeName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(selected.name)}';
      final saved = await source.copy(p.join(videos.path, safeName));
      final project = VideoProject(
        id: const Uuid().v4(), title: selected.name, sourcePath: saved.path,
        createdAt: DateTime.now(), sourceUrl: sourceUrl,
        sourceType: sourceUrl == null ? 'file' : 'authorized-local-copy',
      );
      await _store.add(project);
      await _loadProjects();
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: project)));
      await _loadProjects();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível importar: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openProject(VideoProject project) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: project)));
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        Icon(Icons.auto_awesome, color: _accent), SizedBox(width: 8),
        Text('ClipIA', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2)),
      ]),
      backgroundColor: const Color(0xFF100E17),
    ),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF29213B), Color(0xFF171520), Color(0xFF111018)]),
            borderRadius: BorderRadius.circular(24), border: Border.all(color: _accent.withValues(alpha: .22)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)),
              child: const Text('SEU ESTÚDIO DE CORTES', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
            const SizedBox(height: 18),
            const Text('Transforme vídeos longos em conteúdo que prende atenção.',
              style: TextStyle(fontSize: 25, height: 1.16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Importe, encontre momentos, edite em 9:16 e prepare seus clipes para as redes sociais.',
              style: TextStyle(color: Colors.white70, height: 1.45)),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF211631),
                padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _busy ? null : _pick,
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.video_library_outlined),
              label: Text(_busy ? 'Importando e salvando...' : 'Selecionar vídeo do aparelho', style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: _accent, side: BorderSide(color: _accent.withValues(alpha: .65)),
                padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _busy ? null : _showLinkImport, icon: const Icon(Icons.link),
              label: const Text('Colar link do YouTube'),
            )),
          ]),
        ),
        const SizedBox(height: 28),
        Row(children: [
          const Expanded(child: Text('Meus projetos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
          Text('${_projects.length} projeto(s)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (_loadingProjects)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_projects.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: const Column(children: [
              Icon(Icons.video_collection_outlined, size: 38, color: Colors.white38), SizedBox(height: 10),
              Text('Sua biblioteca começa aqui', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 5),
              Text('Seus projetos ficam salvos mesmo depois de fechar o aplicativo.', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          )
        else
          ..._projects.map((p) => Card(
            color: _panel,
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF302642), child: Icon(Icons.movie_outlined, color: _accent)),
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(p.sourceUrl == null ? 'Vídeo salvo no aparelho' : 'Arquivo local • link associado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openProject(p),
            ),
          )),
        const SizedBox(height: 22),
        const Center(child: Text('CLIPIA  •  FERRAMENTAS DE CRIAÇÃO', style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1))),
      ]),
    ),
  );
}

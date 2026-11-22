import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _store = ProjectStore();
  bool _busy = false;

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
            const Text('Cole um link de vídeo do YouTube. Aceitamos vídeos, Shorts e transmissões públicas.',
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
                  setDialogState(() => error = 'Link não reconhecido. Confira se é um link de vídeo do YouTube.');
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
    await _showImportNotice(link);
  }

  Future<void> _showImportNotice(String link) async {
    final continueImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Link reconhecido'),
        content: const Text('O endereço foi validado. Nesta versão, a importação automática do vídeo pela URL ainda não está conectada. Você pode selecionar o arquivo de vídeo correspondente no aparelho para continuar editando.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Agora não')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selecionar arquivo')),
        ],
      ),
    );
    if (continueImport == true) await _pick(sourceUrl: link);
  }

  Future<void> _pick({String? sourceUrl}) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      final path = result?.files.single.path;
      if (path == null || !await File(path).exists()) return;
      final project = VideoProject(
        id: const Uuid().v4(), title: result!.files.single.name, sourcePath: path,
        createdAt: DateTime.now(), sourceUrl: sourceUrl,
        sourceType: sourceUrl == null ? 'file' : 'youtube',
      );
      _store.add(project);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: project)));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível importar: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            const Text('Importe um vídeo, encontre os melhores momentos e prepare seus clipes para redes sociais.',
              style: TextStyle(color: Colors.white70, height: 1.45)),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF211631),
                padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _busy ? null : _pick,
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.video_library_outlined),
              label: Text(_busy ? 'Aguarde...' : 'Selecionar vídeo do aparelho', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Text('${_store.projects.length} projeto(s)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (_store.projects.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: const Column(children: [
              Icon(Icons.video_collection_outlined, size: 38, color: Colors.white38), SizedBox(height: 10),
              Text('Sua biblioteca começa aqui', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 5),
              Text('Os vídeos que você importar aparecerão nesta área.', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          )
        else
          ..._store.projects.map((p) => Card(
            color: _panel,
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF302642), child: Icon(Icons.movie_outlined, color: _accent)),
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(p.sourceUrl == null ? 'Vídeo do aparelho' : 'Link do YouTube associado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(project: p))),
            ),
          )),
        const SizedBox(height: 22),
        const Center(child: Text('CLIPIA  •  FERRAMENTAS DE CRIAÇÃO', style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1))),
      ]),
    ),
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/video_project.dart';
import '../services/ffmpeg_video_service.dart';

const _accent = Color(0xFFB99AFF);

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key, required this.project});
  final VideoProject project;
  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  VideoPlayerController? _player;
  final _start = TextEditingController(text: '00:00');
  final _end = TextEditingController();
  final _caption = TextEditingController();
  final _ffmpeg = FfmpegVideoService();
  bool _loading = true, _exporting = false, _vertical = true;
  String _stage = 'Carregando vídeo';
  String? _error, _output;
  List<ClipSuggestion> _suggestions = [];

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    try {
      final p = VideoPlayerController.file(File(widget.project.sourcePath));
      await p.initialize();
      if (!mounted) { await p.dispose(); return; }
      setState(() {
        _player = p; _loading = false; _end.text = _fmt(p.value.duration);
        _suggestions = _ffmpeg.suggestClips(p.value.duration);
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Não foi possível abrir o vídeo: $e'; });
    }
  }

  String _fmt(Duration d) {
    final h=d.inHours, m=d.inMinutes.remainder(60), s=d.inSeconds.remainder(60);
    return h>0 ? '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}' : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Duration _parse(String value) {
    final parts=value.trim().split(':').map(int.parse).toList();
    if(parts.length==2) return Duration(minutes:parts[0],seconds:parts[1]);
    if(parts.length==3) return Duration(hours:parts[0],minutes:parts[1],seconds:parts[2]);
    throw const FormatException('Use MM:SS ou HH:MM:SS.');
  }

  void _selectSuggestion(ClipSuggestion suggestion) {
    setState(() {
      _start.text = _fmt(suggestion.start);
      _end.text = _fmt(suggestion.end);
    });
  }

  Future<void> _export() async {
    setState(() { _exporting=true; _error=null; _output=null; _stage='Validando trecho'; });
    try {
      final path=await _ffmpeg.exportClip(
        inputPath:widget.project.sourcePath,
        start:_parse(_start.text), end:_parse(_end.text),
        vertical:_vertical, caption:_caption.text,
        onStage:(s){if(mounted)setState(()=>_stage=s);},
      );
      if(mounted)setState(()=>_output=path);
    } catch(e) { if(mounted)setState(()=>_error=e.toString()); }
    finally { if(mounted)setState(()=>_exporting=false); }
  }

  Future<void> _share() async {
    final path = _output;
    if (path == null || !await File(path).exists()) return;
    await Share.shareXFiles([XFile(path)], text: 'Criado com ClipIA');
  }

  @override
  void dispose() {
    _player?.dispose(); _start.dispose(); _end.dispose(); _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Estúdio de edição')),
    body: _loading
      ? const Center(child:CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(18), children: [
        Text(widget.project.title, style: const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:5),
        Text('Vídeo original • ${_fmt(_player!.value.duration)}',
          style: const TextStyle(color:Colors.white54,fontSize:12)),
        const SizedBox(height:14),
        AspectRatio(aspectRatio:_player!.value.aspectRatio,
          child: ClipRRect(borderRadius:BorderRadius.circular(18),
            child:VideoPlayer(_player!))),
        const SizedBox(height:8),
        VideoProgressIndicator(_player!,allowScrubbing:true,padding:const EdgeInsets.symmetric(vertical:8)),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          IconButton(onPressed:()=>_player!.value.isPlaying?_player!.pause():_player!.play(),
            icon:Icon(_player!.value.isPlaying?Icons.pause_circle:Icons.play_circle,size:38,color:_accent)),
          const Text('Pré-visualização do vídeo'),
        ]),
        const SizedBox(height:18),
        _sectionTitle('Cortes sugeridos', Icons.auto_awesome),
        const SizedBox(height:5),
        const Text('Sugestões iniciais distribuídas pelo vídeo para acelerar a edição. Revise os momentos antes de exportar.',
          style:TextStyle(color:Colors.white60,fontSize:12,height:1.4)),
        const SizedBox(height:10),
        ..._suggestions.map((s)=>Card(
          color:const Color(0xFF171520),
          child:ListTile(
            leading:const CircleAvatar(backgroundColor:Color(0xFF302642),child:Icon(Icons.movie_filter_outlined,color:_accent)),
            title:Text(s.title),
            subtitle:Text('${_fmt(s.start)} – ${_fmt(s.end)} • ${s.duration.inSeconds}s'),
            trailing:TextButton(onPressed:()=>_selectSuggestion(s),child:const Text('Usar')),
          ),
        )),
        const SizedBox(height:18),
        _sectionTitle('Ajustar seu corte', Icons.tune),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:TextField(controller:_start,keyboardType:TextInputType.datetime,
            decoration:const InputDecoration(labelText:'Início',hintText:'00:00',border:OutlineInputBorder()))),
          const SizedBox(width:12),
          Expanded(child:TextField(controller:_end,keyboardType:TextInputType.datetime,
            decoration:const InputDecoration(labelText:'Fim',hintText:'01:30',border:OutlineInputBorder()))),
        ]),
        const SizedBox(height:18),
        _sectionTitle('Formato do vídeo', Icons.aspect_ratio),
        const SizedBox(height:8),
        SegmentedButton<bool>(
          segments:const [
            ButtonSegment(value:true,label:Text('Vertical 9:16'),icon:Icon(Icons.smartphone)),
            ButtonSegment(value:false,label:Text('Original'),icon:Icon(Icons.crop_original)),
          ],
          selected:{_vertical},
          onSelectionChanged:(v)=>setState(()=>_vertical=v.first),
        ),
        const SizedBox(height:18),
        _sectionTitle('Texto na tela', Icons.subtitles_outlined),
        const SizedBox(height:6),
        const Text('Adicione uma chamada ou título. A legenda será exibida durante todo o trecho exportado.',
          style:TextStyle(color:Colors.white60,fontSize:12)),
        const SizedBox(height:9),
        TextField(controller:_caption,maxLines:2,maxLength:90,
          decoration:const InputDecoration(hintText:'Ex.: 3 dicas que ninguém te contou...',border:OutlineInputBorder())),
        const SizedBox(height:18),
        FilledButton.icon(
          style:FilledButton.styleFrom(backgroundColor:_accent,foregroundColor:const Color(0xFF211631),
            padding:const EdgeInsets.symmetric(vertical:16)),
          onPressed:_exporting?_nullExport:null,
          icon:_exporting?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.movie_creation_outlined),
          label:Text(_exporting?'Renderizando...':'Exportar meu corte'),
        ),
        if(_exporting) Padding(padding:const EdgeInsets.only(top:12),child:Column(children:[
          const LinearProgressIndicator(),const SizedBox(height:8),Text(_stage,textAlign:TextAlign.center),
        ])),
        if(_error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,style:const TextStyle(color:Colors.redAccent))),
        if(_output!=null) Card(
          color:const Color(0xFF18251F),
          child:ListTile(
            leading:const Icon(Icons.check_circle,color:Colors.greenAccent),
            title:const Text('Corte exportado com sucesso'),
            subtitle:Text(_output!,maxLines:2,overflow:TextOverflow.ellipsis),
            trailing:IconButton(onPressed:_share,icon:const Icon(Icons.share,color:_accent),tooltip:'Compartilhar'),
          ),
        ),
        const SizedBox(height:22),
        const Text('As sugestões automáticas atuais são pontos de partida baseados na duração do vídeo. A análise semântica por IA e a transcrição automática serão conectadas em uma próxima camada de processamento.',
          style:TextStyle(color:Colors.white38,fontSize:11,height:1.4)),
      ]),
  );

  VoidCallback? _nullExport() => null;

  Widget _sectionTitle(String title, IconData icon) => Row(children:[
    Icon(icon,color:_accent,size:20),const SizedBox(width:8),
    Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
  ]);
}

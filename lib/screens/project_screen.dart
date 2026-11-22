import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_project.dart';
import '../services/ffmpeg_video_service.dart';

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
  final _ffmpeg = FfmpegVideoService();
  bool _loading = true, _exporting = false;
  String _stage = 'Carregando vídeo';
  String? _error, _output;

  @override
  void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    try {
      final p = VideoPlayerController.file(File(widget.project.sourcePath));
      await p.initialize();
      if (!mounted) { await p.dispose(); return; }
      setState(() { _player = p; _loading = false; _end.text = _fmt(p.value.duration); });
    } catch (_) { if (mounted) setState(() { _loading = false; _error = 'Não foi possível abrir o vídeo.'; }); }
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
  Future<void> _export() async {
    setState(() { _exporting=true; _error=null; _output=null; _stage='Validando trecho'; });
    try {
      final path=await _ffmpeg.cut(inputPath:widget.project.sourcePath,start:_parse(_start.text),end:_parse(_end.text),onStage:(s){if(mounted)setState(()=>_stage=s);});
      if(mounted)setState(()=>_output=path);
    } catch(e) { if(mounted)setState(()=>_error=e.toString()); }
    finally { if(mounted)setState(()=>_exporting=false); }
  }
  @override
  void dispose() { _player?.dispose(); _start.dispose(); _end.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editor de corte')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Text(widget.project.title, style: const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:14),
      AspectRatio(aspectRatio:_player?.value.isInitialized==true?_player!.value.aspectRatio:16/9,
        child: Container(color:Colors.black, child:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:Text(_error!)):VideoPlayer(_player!))),
      if(_player?.value.isInitialized==true) VideoProgressIndicator(_player!,allowScrubbing:true),
      const SizedBox(height:22),
      const Text('Corte manual',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      const Text('Informe os tempos no formato MM:SS ou HH:MM:SS. O corte preserva o codec original para evitar uma recompressão nesta primeira validação.'),
      const SizedBox(height:14),
      Row(children:[
        Expanded(child:TextField(controller:_start,decoration:const InputDecoration(labelText:'Início',hintText:'00:00',border:OutlineInputBorder()))),
        const SizedBox(width:12),
        Expanded(child:TextField(controller:_end,decoration:const InputDecoration(labelText:'Fim',hintText:'01:30',border:OutlineInputBorder()))),
      ]),
      const SizedBox(height:16),
      FilledButton.icon(onPressed:_exporting||_loading?null:_export,icon:_exporting?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.content_cut),label:Text(_exporting?'Processando...':'Exportar corte MP4')),
      if(_exporting) Padding(padding:const EdgeInsets.only(top:12),child:Text(_stage,textAlign:TextAlign.center)),
      if(_error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,style:const TextStyle(color:Colors.redAccent))),
      if(_output!=null) Card(child:ListTile(leading:const Icon(Icons.check_circle,color:Colors.green),title:const Text('Corte salvo no ClipIA'),subtitle:Text(_output!,maxLines:2,overflow:TextOverflow.ellipsis))),
    ]),
  );
}

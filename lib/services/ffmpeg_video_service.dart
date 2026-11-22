import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoProbe {
  const VideoProbe({required this.durationSeconds, required this.width, required this.height});
  final double durationSeconds;
  final int width;
  final int height;
}

class ClipSuggestion {
  const ClipSuggestion({required this.start, required this.end, required this.title});
  final Duration start;
  final Duration end;
  final String title;
  Duration get duration => end - start;
}

class FfmpegVideoService {
  String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  Future<VideoProbe> probe(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = session.getMediaInformation();
    if (info == null) throw Exception('Não foi possível ler as informações do vídeo.');
    final duration = double.tryParse(info.getDuration() ?? '');
    final streams = info.getStreams();
    final video = streams.firstWhere((s) => s.getType() == 'video');
    final width = video.getWidth() ?? 0;
    final height = video.getHeight() ?? 0;
    if (duration == null || duration <= 0) throw Exception('Duração do vídeo inválida.');
    return VideoProbe(durationSeconds: duration, width: width, height: height);
  }

  List<ClipSuggestion> suggestClips(Duration total, {int count = 3}) {
    final seconds = total.inSeconds;
    if (seconds < 12) throw Exception('O vídeo precisa ter pelo menos 12 segundos para sugerir cortes.');
    final length = seconds >= 90 ? 30 : (seconds / 3).floor().clamp(8, 30);
    final maxStart = seconds - length;
    return List.generate(count, (i) {
      final start = count == 1 ? 0 : (maxStart * i / (count - 1)).round();
      return ClipSuggestion(
        start: Duration(seconds: start),
        end: Duration(seconds: start + length),
        title: 'Sugestão ${i + 1}',
      );
    });
  }

  Future<String> exportClip({
    required String inputPath,
    required Duration start,
    required Duration end,
    required bool vertical,
    String? caption,
    required void Function(String stage) onStage,
  }) async {
    if (!await File(inputPath).exists()) throw Exception('Arquivo de origem não encontrado.');
    if (start.isNegative || end <= start) throw Exception('Confira os tempos inicial e final.');
    final info = await probe(inputPath);
    if (end.inMilliseconds > (info.durationSeconds * 1000).round()) {
      throw Exception('O tempo final ultrapassa a duração do vídeo.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/ClipIA/cortes');
    await outputDir.create(recursive: true);
    final output = '${outputDir.path}/clip_${DateTime.now().microsecondsSinceEpoch}.mp4';
    onStage('Preparando vídeo');
    final filters = <String>[];
    if (vertical) {
      filters.add('scale=1080:1920:force_original_aspect_ratio=increase');
      filters.add('crop=1080:1920');
    }
    if (caption != null && caption.trim().isNotEmpty) {
      final safe = caption.trim().replaceAll(r'\\', r'\\\\').replaceAll(':', r'\\:').replaceAll("'", r"\\'").replaceAll('%', r'\\%');
      filters.add("drawtext=text='$safe':fontcolor=white:fontsize=54:borderw=3:bordercolor=black:x=(w-text_w)/2:y=h*0.78");
    }
    final vf = filters.isEmpty ? '' : '-vf ${_quote(filters.join(','))}';
    final command = '-y -ss ${(start.inMilliseconds / 1000).toStringAsFixed(3)} '
      '-i ${_quote(inputPath)} -t ${((end - start).inMilliseconds / 1000).toStringAsFixed(3)} '
      '-map 0:v:0 -map 0:a? $vf -c:v ${filters.isEmpty ? 'copy' : 'libx264'} '
      '-preset veryfast -crf 23 -c:a aac -b:a 160k -movflags +faststart ${_quote(output)}';
    onStage(vertical ? 'Adaptando para 9:16 e renderizando' : 'Renderizando corte MP4');
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !await File(output).exists()) {
      final logs = await session.getOutput();
      throw Exception('Falha na exportação: ${logs ?? 'sem detalhes'}');
    }
    onStage('Corte concluído');
    return output;
  }

  Future<String> cut({
    required String inputPath,
    required Duration start,
    required Duration end,
    required void Function(String stage) onStage,
  }) => exportClip(inputPath: inputPath, start: start, end: end,
    vertical: false, onStage: onStage);
}

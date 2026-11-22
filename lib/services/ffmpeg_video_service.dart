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

class FfmpegVideoService {
  String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  Future<VideoProbe> probe(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = await session.getMediaInformation();
    if (info == null) throw Exception('Não foi possível ler as informações do vídeo.');
    final duration = double.tryParse(info.getDuration() ?? '');
    final streams = info.getStreams();
    final video = streams.firstWhere((s) => s.getType() == 'video');
    final width = video.getWidth() ?? 0;
    final height = video.getHeight() ?? 0;
    if (duration == null || duration <= 0) throw Exception('Duração do vídeo inválida.');
    return VideoProbe(durationSeconds: duration, width: width, height: height);
  }

  Future<String> cut({
    required String inputPath,
    required Duration start,
    required Duration end,
    required void Function(String stage) onStage,
  }) async {
    if (!await File(inputPath).exists()) throw Exception('Arquivo de origem não encontrado.');
    if (start.isNegative || end <= start) throw Exception('Confira os tempos inicial e final.');
    final probeInfo = await probe(inputPath);
    if (end.inMilliseconds > (probeInfo.durationSeconds * 1000).round()) {
      throw Exception('O tempo final ultrapassa a duração do vídeo.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/ClipIA/cortes');
    await outputDir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final output = '${outputDir.path}/corte_$stamp.mp4';
    onStage('Preparando corte');
    final command = '-y -ss ${(start.inMilliseconds / 1000).toStringAsFixed(3)} '
      '-to ${(end.inMilliseconds / 1000).toStringAsFixed(3)} '
      '-i ${_quote(inputPath)} -map 0:v:0 -map 0:a? -c copy '
      '-avoid_negative_ts make_zero -movflags +faststart ${_quote(output)}';
    onStage('Cortando vídeo com FFmpeg');
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !await File(output).exists()) {
      final logs = await session.getOutput();
      throw Exception('Falha no corte FFmpeg: ${logs ?? 'sem detalhes'}');
    }
    onStage('Corte concluído');
    return output;
  }
}

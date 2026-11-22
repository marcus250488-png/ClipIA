import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeImportException implements Exception {
  const YoutubeImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class YoutubeImportResult {
  const YoutubeImportResult({required this.path, required this.title});
  final String path;
  final String title;
}

/// Baixa o vídeo de um link do YouTube para a pasta privada do app.
/// Use apenas com conteúdo seu ou que você tenha autorização para editar.
class YoutubeImportService {
  String _q(String value) => "'${value.replaceAll("'", "'\\''")}'";

  String _safeName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'video_youtube';
    return String.fromCharCodes(cleaned.runes.take(60)).trim();
  }

  Future<StreamManifest> _loadManifest(YoutubeExplode yt, VideoId id) async {
    try {
      final manifest = await yt.videos.streams
          .getManifest(id, ytClients: [YoutubeApiClient.androidVr]);
      if (manifest.streams.isNotEmpty) return manifest;
    } catch (_) {
      // tenta o modo padrão abaixo
    }
    return yt.videos.streams.getManifest(id);
  }

  int _compareVideo(VideoOnlyStreamInfo a, VideoOnlyStreamInfo b) {
    final byHeight =
        a.videoResolution.height.compareTo(b.videoResolution.height);
    if (byHeight != 0) return byHeight;
    return a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond);
  }

  VideoOnlyStreamInfo? _pickVideo(StreamManifest manifest, int maxHeight) {
    final mp4 =
        manifest.videoOnly.where((s) => s.container.name == 'mp4').toList();
    if (mp4.isEmpty) return null;
    final h264 = mp4
        .where((s) => s.videoCodec.toLowerCase().startsWith('avc1'))
        .toList();
    final pool = h264.isNotEmpty ? h264 : mp4;
    pool.sort(_compareVideo);
    final fit =
        pool.where((s) => s.videoResolution.height <= maxHeight).toList();
    return fit.isNotEmpty ? fit.last : pool.first;
  }

  AudioOnlyStreamInfo? _pickAudio(StreamManifest manifest) {
    final all = manifest.audioOnly.toList();
    if (all.isEmpty) return null;
    final mp4 = all.where((s) => s.container.name == 'mp4').toList();
    final pool = mp4.isNotEmpty ? mp4 : all;
    pool.sort((a, b) =>
        a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
    return pool.last;
  }

  MuxedStreamInfo? _pickMuxed(StreamManifest manifest) {
    final all = manifest.muxed.toList();
    if (all.isEmpty) return null;
    all.sort((a, b) =>
        a.videoResolution.height.compareTo(b.videoResolution.height));
    return all.last;
  }

  Future<void> _save(YoutubeExplode yt, StreamInfo info, File file,
      void Function(int bytes) onBytes) async {
    final sink = file.openWrite();
    try {
      await for (final chunk in yt.videos.streams.get(info)) {
        sink.add(chunk);
        onBytes(chunk.length);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Future<YoutubeImportResult> download(
    String url, {
    required void Function(String stage, double? progress) onProgress,
  }) async {
    final yt = YoutubeExplode();
    final temps = <File>[];
    try {
      onProgress('Lendo informações do vídeo...', null);
      final video = await yt.videos.get(url);
      if (video.isLive) {
        throw const YoutubeImportException('Transmissões ao vivo em andamento ngão podem ser importadas.');
      }
      final long = (video.duration ?? Duration.zero) > const Duration(minutes: 45);
      final maxHeight = long ? 720 : 1080;
      onProgress('Buscando formatos disponíveis...', null);
      final manifest = await _loadManifest(yt, video.id);
      final docs = await getApplicationDocumentsDirectory();
      final outDir = Directory(p.join(docs.path, 'ClipIA', 'originais'));
      await outDir.create(recursive: true);
      final tmpDir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final finalPath = p.join(outDir.path, '${stamp}_${_safeName(video.title)}.mp4');
      final videoStream = _pickVideo(manifest, maxHeight);
      final audioStream = _pickAudio(manifest);
      if (videoStream != null && audioStream != null) {
        final videoFile = File(p.join(tmpDir.path, 'clipia_${stamp}_v.mp4'));
        final audioFile = File(p.join(tmpDir.path, 'clipia_${stamp}_a.bin'));
        temps.addAll([videoFile, audioFile]);
        final total = videoStream.size.totalBytes + audioStream.size.totalBytes;
        var done = 0;
        void tick(int n) {
          done += n;
          final ratio = total > 0 ? done / total : null;
          onProgress('Baixando vídeo do YouTube...', ratio == null ? null : (ratio * 0.92).clamp(0.0, 0.92));
        }
        await _save(yt, videoStream, videoFile, tick);
        await _save(yt, audioStream, audioFile, tick);
        onProgress('Juntando áudio e vídeo...', null);
        final command = '-y -i ${_q(videoFile.path)} -i ${_q(audioFile.path)} ' + '
           '-map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 160k ' +
          '-movflags +faststart ${_q(finalPath)}';
        final session = await FFmpegKit.execute(command);
        final code = await session.getReturnCode();
        if (!ReturnCode.isSuccess(code) || !await File(finalPath).exists()) {
          final logs = await session.getOutput();
          throw YoutubeImportException('Falha ao juntar áudio e vídeo: ${logs ?? 'sem detalhes'}');
        }
      } else {
        final muxed = _pickMuxed(manifest);
        if (muxed == null) throw const YoutubeImportException('Nenhum formato de vídeo disponível para este link.');
        final total = muxed.size.totalBytes;
        var done = 0;
        await _save(yt, muxed, File(finalPath), (n) {
          done += n;
          onProgress('Baixando vídeo do YouTube...', total > 0 ? (done / total).clamp(0.0, 1.0) : null);
        });
      }
      onProgress('Vídeo pronto', 1.0);
      return YoutubeImportResult(path: finalPath, title: video.title);
    } on YoutubeImportException {
      rethows;
    } catch (e) {
      throw YoutubeImportException('Não foi possível baixar este vídeo. Ele pode ser privado, ter restricção de idade ou de região, ou o YouTube pode ter mudado o accesso. ($e)');
    } finally {
      yt.close();
      for (final f in temps) {
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }
}

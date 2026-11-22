# ClipIA

App Flutter/Android para transformar vídeos longos em cortes curtos.

## Marco M2 — primeiro motor FFmpeg
- Importação de vídeo local.
- Prévia do arquivo.
- Corte manual por tempo inicial e final (MM:SS ou HH:MM:SS).
- Exportação MP4 para a pasta privada do app.
- Verificação de duração e dimensões via FFprobe.
- O corte usa stream copy para preservar a qualidade e evitar recodificação nesta primeira etapa.

## Dependência FFmpeg e licença
Usamos `ffmpeg_kit_flutter_new_full`, uma distribuição comunitária mantida do FFmpegKit, sem componentes GPL adicionais no pacote full. A licença do wrapper é LGPL-3.0; FFmpeg e bibliotecas incluídas mantêm suas licenças próprias. Verifique e distribua os avisos de licença exigidos antes de publicar o APK. Documentação: https://pub.dev/packages/ffmpeg_kit_flutter_new_full

## Preparar Android e executar
```bash
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter run
```

## Limitações conhecidas deste marco
- Não é ainda o gerador automático de cortes por IA.
- O corte por stream copy pode começar alguns frames antes/depois do timestamp solicitado, dependendo dos keyframes do vídeo.
- Não há ainda codificação/reframe 1080x1920, legendas, cancelamento, progresso percentual real, biblioteca persistente nem sincronização.
- O arquivo exportado fica no armazenamento privado do app; a ação de salvar/compartilhar para a galeria será adicionada em outra etapa.
- O projeto ainda precisa ser compilado e testado em dispositivo Android real.

Importe apenas conteúdo que você tem direito de editar. Não contorne DRM, paywalls ou controles de acesso.

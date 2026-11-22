# ClipIA

Aplicativo Flutter/Android de uso pessoal para transformar vídeos longos em cortes curtos com auxílio de IA. Não haverá cadastro de usuários, planos ou assinaturas.

## Objetivo de importação por link
A experiência desejada é: colar um link do YouTube (sem limitar ao canal do proprietário do app), identificar a origem, verificar se existe uma forma permitida de acessar a mídia, analisar o vídeo e gerar cortes curtos. O projeto guarda a URL de origem junto ao projeto quando o usuário seleciona o arquivo local correspondente.

**Estado atual:** a interface valida links do YouTube e associa a URL ao projeto, mas ainda não baixa/importa automaticamente a mídia a partir do link. Nesta etapa, o arquivo de vídeo precisa ser selecionado no dispositivo. O adaptador de importação automática ainda precisa ser implementado e testado.

A implementação futura deve separar identificação do link, resolução de fonte e ingestão de mídia. Só deve processar conteúdo quando houver uma via de acesso permitida e compatível com os termos e permissões aplicáveis; não deve contornar DRM, paywalls ou controles de acesso. Não limitar a arquitetura a vídeos do canal do usuário.

## Marco M2 — primeiro motor FFmpeg
- Importação de vídeo local.
- Prévia do arquivo.
- Corte manual por tempo inicial e final (MM:SS ou HH:MM:SS).
- Exportação MP4 para a pasta privada do app.
- Verificação de duração e dimensões via FFprobe.
- O corte usa stream copy para preservar a qualidade e evitar recompressão nesta primeira etapa.

## Dependência FFmpeg e licença
Usamos `ffmpeg_kit_flutter_new_full`, uma distribuição comunitária mantida do FFmpegKit. A licença do wrapper e as licenças das bibliotecas incluídas devem ser verificadas e seus avisos distribuídos antes de qualquer compartilhamento do APK. Documentação: https://pub.dev/packages/ffmpeg_kit_flutter_new_full

## Preparar Android e executar
```bash
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter test
flutter run
```

## Limitações conhecidas
- A importação automática a partir de links ainda não está implementada.
- A análise automática de melhores momentos por IA ainda não está conectada.
- O corte por stream copy pode começar alguns frames antes/depois do timestamp solicitado, dependendo dos keyframes.
- Ainda não há reframe 1080x1920, legendas, cancelamento, progresso percentual real, biblioteca persistente nem compartilhamento para a galeria.
- O projeto precisa ser compilado e testado em dispositivo Android real.

Importe apenas conteúdo que você tem direito de editar.

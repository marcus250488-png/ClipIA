# ClipIA

Aplicativo Flutter/Android de uso pessoal para transformar vídeos longos em cortes curtos com auxílio de IA. Não haverá cadastro de usuários, planos ou assinaturas.

## Objetivo de importação por link
A experiência desejada é: colar um link do YouTube (sem limitar ao canal do proprietário do app), identificar a origem, verificar se existe uma forma permitida de acessar a mídia, analisar o vídeo e gerar cortes curtos. O projeto guarda a URL de origem junto ao projeto quando o usuário seleciona o arquivo local correspondente.

**Estado atual:** ao colar um link do YouTube, o app valida o endereço, baixa o vídeo para a pasta privada do app (`youtube_explode_dart` + FFmpeg para juntar áudio e vídeo) e abre o editor. Se o download falhar, a mensagem de erro oferece o botão "Escolher arquivo" como alternativa. A análise automática de melhores momentos por IA ainda não está conectada.

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

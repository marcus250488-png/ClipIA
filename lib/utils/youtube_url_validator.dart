class YouTubeUrlValidator {
  static String? normalize(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;
    value = value.replaceAll(RegExp(r'^[<(["]+'), '');
    value = value.replaceAll(RegExp(r'[>)]",.!?]+$'), '');
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) || uri.userInfo.isNotEmpty) return null;
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    const allowed = {'youtube.com', 'm.youtube.com', 'music.youtube.com', 'youtu.be', 'youtube-nocookie.com'};
    if (!allowed.contains(host)) return null;
    final segments = uri.pathSegments;
    final watch = host.endsWith('youtube.com') && uri.path.toLowerCase() == '/watch' &&
        (uri.queryParameters['v']?.isNotEmpty ?? false);
    final shorts = host.endsWith('youtube.com') && segments.length >= 2 &&
        {'shorts', 'live', 'embed', 'v'}.contains(segments.first.toLowerCase()) && segments[1].isNotEmpty;
    final shortLink = host == 'youtu.be' && segments.isNotEmpty && segments.first.isNotEmpty;
    if (!(watch || shorts || shortLink)) return null;
    return uri.replace(scheme: 'https', fragment: '').toString();
  }
}

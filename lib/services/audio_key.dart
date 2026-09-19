/// Stable filesystem / CDN key for a speakable phrase.
///
/// Keep in sync with `tool/generate_audio.py` (`audio_key`).
String audioKey(String text) {
  final lower = text.trim().toLowerCase();
  if (lower.isEmpty) return '';
  final slug = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug;
}

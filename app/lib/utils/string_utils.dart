/// Formats a name so each word has its first letter capitalized and the remainder lowercased.
/// e.g. "eYAER" -> "Eyaer", "john doe" -> "John Doe", "sARAH" -> "Sarah".
String formatName(String? input) {
  if (input == null || input.trim().isEmpty) return '';
  return input
      .trim()
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return '';
        final first = word[0].toUpperCase();
        final rest = word.length > 1 ? word.substring(1).toLowerCase() : '';
        return '$first$rest';
      })
      .where((w) => w.isNotEmpty)
      .join(' ');
}

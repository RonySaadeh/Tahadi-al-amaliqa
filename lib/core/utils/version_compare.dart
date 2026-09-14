/// Compares two dotted version strings (`"1.12.3"`) numerically component by
/// component, rather than as plain strings — a lexical `"1.9" < "1.10"`
/// compare would get that backwards. Missing trailing components count as
/// zero (`"1.2" == "1.2.0"`), and anything non-numeric in a component is
/// treated as zero rather than throwing, so a malformed value entered in the
/// App Control panel fails safe instead of crashing the redirect logic that
/// calls this on every navigation.
///
/// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
int compareVersions(String a, String b) {
  final partsA = a.trim().split('.');
  final partsB = b.trim().split('.');
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;

  for (var i = 0; i < length; i++) {
    final numA = i < partsA.length ? int.tryParse(partsA[i]) ?? 0 : 0;
    final numB = i < partsB.length ? int.tryParse(partsB[i]) ?? 0 : 0;
    if (numA != numB) return numA - numB;
  }
  return 0;
}

/// True when [current] is strictly older than [minimum] — the condition
/// that should block the app behind the force-update screen. A blank
/// [minimum] (force update turned off, or never configured) never blocks.
bool isVersionBelow(String current, String minimum) {
  if (minimum.trim().isEmpty) return false;
  return compareVersions(current, minimum) < 0;
}

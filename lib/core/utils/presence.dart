import '../../l10n/app_localizations.dart';

/// A player counts as "online" if their device has heartbeat-pinged within
/// this window — see `presenceControllerProvider`'s 60-second interval.
/// Generous enough to survive a missed ping or two without flickering
/// between online/offline, tight enough to still mean "here right now".
const Duration onlineWindow = Duration(minutes: 2);

bool isOnline(DateTime? lastActiveAt) {
  if (lastActiveAt == null) return false;
  return DateTime.now().difference(lastActiveAt) < onlineWindow;
}

/// "Online" / "Last seen 12 minutes ago" / "Last seen 3 hours ago" / ... —
/// the label next to a friend's name on the friends list.
String lastSeenLabel(DateTime? lastActiveAt, AppLocalizations l10n) {
  if (isOnline(lastActiveAt)) return l10n.friendsOnline;
  if (lastActiveAt == null) return l10n.friendsLastSeenUnknown;

  final diff = DateTime.now().difference(lastActiveAt);
  if (diff.inMinutes < 60) return l10n.friendsLastSeenMinutes(diff.inMinutes.clamp(1, 59));
  if (diff.inHours < 24) return l10n.friendsLastSeenHours(diff.inHours);
  if (diff.inDays < 7) return l10n.friendsLastSeenDays(diff.inDays);
  return l10n.friendsLastSeenLongAgo;
}

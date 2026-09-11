/// Shared enums used across the app and mirrored (as plain strings) in the
/// Cloud Functions code. If you add a value here, add the matching string
/// in `functions/src/lib/types.ts` too.
library;

enum DuelStatus {
  pending, // created, waiting for the second player to accept / lobby to fill
  active, // both players present, rounds are being played
  completed,
  cancelled;

  static DuelStatus fromString(String value) {
    return DuelStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DuelStatus.pending,
    );
  }
}

enum RoundStatus {
  active, // question is live, waiting on one or both answers
  resolved; // both answers in (or time expired) and points awarded

  static RoundStatus fromString(String value) {
    return RoundStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoundStatus.active,
    );
  }
}

enum QuestionDifficulty {
  easy,
  medium,
  hard;

  static QuestionDifficulty fromString(String value) {
    return QuestionDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionDifficulty.medium,
    );
  }
}

/// Where a question came from. Kept for moderation/analytics — e.g. you may
/// want to review 'llm' questions before trusting them as much as 'api' ones.
enum QuestionSource {
  api, // bundled/seeded question bank
  llm, // hand-written/LLM-assisted starter pool (see functions/src/seed)
  user; // hand-written by a home-turf category owner

  static QuestionSource fromString(String value) {
    return QuestionSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionSource.api,
    );
  }
}

enum DuelInviteStatus {
  pending,
  accepted,
  declined,
  expired;

  static DuelInviteStatus fromString(String value) {
    return DuelInviteStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DuelInviteStatus.pending,
    );
  }
}

enum FriendshipStatus {
  pending,
  accepted,
  declined;

  static FriendshipStatus fromString(String value) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FriendshipStatus.pending,
    );
  }
}

enum NotificationType {
  friendRequest,
  duelChallenge;

  static NotificationType fromString(String value) {
    return switch (value) {
      'friend_request' => NotificationType.friendRequest,
      'duel_challenge' => NotificationType.duelChallenge,
      _ => NotificationType.friendRequest,
    };
  }
}

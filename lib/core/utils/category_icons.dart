import 'package:flutter/material.dart';

/// (icon, accent color) for a category or category-group's `iconKey` — a
/// plain string stored in Firestore, set once in
/// `functions/src/seed/categoryTaxonomy.ts`. One shared lookup table for
/// both: a "general" catch-all category typically reuses its own group's
/// key (e.g. `sports-general` → `"sports"`, the same key the "Sports" group
/// header uses), while a specific sub-category (e.g. `real-madrid`) gets
/// its own.
///
/// Kept as a lookup table rather than storing an [IconData]/[Color]
/// directly in Firestore, since neither is stable data to persist — the key
/// is just a short stable label the data seed and this map both agree on.
/// Falls back to a generic icon/color for any key this map doesn't
/// recognize, so adding a category in `categoryTaxonomy.ts` without also
/// updating this file degrades gracefully instead of crashing.
///
/// Every icon here is a generic Material glyph plus a themed accent color —
/// deliberately never a real team crest, studio logo, or game/franchise
/// mark. Bundling one of those would mean shipping someone else's
/// trademark, not just borrowing a "look".
({IconData icon, Color color}) categoryIcon(String iconKey) {
  return switch (iconKey) {
    // --- Shared with category groups (the picker's section headers) ---
    'sports' => (icon: Icons.sports_soccer_rounded, color: const Color(0xFF2E7D32)),
    'movies' => (icon: Icons.movie_rounded, color: const Color(0xFF6A1B9A)),
    'drama' => (icon: Icons.theater_comedy_rounded, color: const Color(0xFF6D4C41)),
    'music' => (icon: Icons.music_note_rounded, color: const Color(0xFF7B1FA2)),
    'history' => (icon: Icons.history_edu_rounded, color: const Color(0xFF6D4C41)),
    'geography' => (icon: Icons.public_rounded, color: const Color(0xFF0277BD)),
    'science' => (icon: Icons.science_rounded, color: const Color(0xFF00838F)),
    'games' => (icon: Icons.sports_esports_rounded, color: const Color(0xFF512DA8)),
    'literature' => (icon: Icons.menu_book_rounded, color: const Color(0xFF4E342E)),
    'puzzle' => (icon: Icons.extension_rounded, color: const Color(0xFFF57C00)),

    // --- Sports ---
    'football' => (icon: Icons.sports_soccer_rounded, color: const Color(0xFF1565C0)),
    'real-madrid' => (icon: Icons.shield_rounded, color: const Color(0xFFB8860B)),
    'barcelona' => (icon: Icons.shield_rounded, color: const Color(0xFF004D98)),
    'man-utd' => (icon: Icons.shield_rounded, color: const Color(0xFFDA291C)),
    'liverpool' => (icon: Icons.shield_rounded, color: const Color(0xFFC8102E)),
    'arab-teams' => (icon: Icons.flag_rounded, color: const Color(0xFF2E7D32)),
    'world-cup' => (icon: Icons.emoji_events_rounded, color: const Color(0xFFFFC107)),
    'basketball' => (icon: Icons.sports_basketball_rounded, color: const Color(0xFFE65100)),
    'tennis' => (icon: Icons.sports_tennis_rounded, color: const Color(0xFF9CCC65)),

    // --- Movies & TV ---
    'marvel' => (icon: Icons.bolt_rounded, color: const Color(0xFFD32F2F)),
    'harry-potter' => (icon: Icons.auto_fix_high_rounded, color: const Color(0xFF4A148C)),
    'star-wars' => (icon: Icons.rocket_launch_rounded, color: const Color(0xFF37474F)),
    'tv-shows' => (icon: Icons.tv_rounded, color: const Color(0xFF00838F)),
    'friends-show' => (icon: Icons.groups_rounded, color: const Color(0xFFF57C00)),
    'got' => (icon: Icons.castle_rounded, color: const Color(0xFF37474F)),
    'anime' => (icon: Icons.emoji_emotions_rounded, color: const Color(0xFFEC407A)),
    'one-piece' => (icon: Icons.sailing_rounded, color: const Color(0xFF1565C0)),
    'naruto' => (icon: Icons.whatshot_rounded, color: const Color(0xFFEF6C00)),

    // --- Arabic cinema & drama ---
    'classic-egyptian' => (icon: Icons.local_movies_rounded, color: const Color(0xFF8D6E63)),
    'ramadan' => (icon: Icons.nightlight_round, color: const Color(0xFF5E35B1)),
    'arabic-comedy' => (icon: Icons.sentiment_very_satisfied_rounded, color: const Color(0xFFFFA000)),
    'turkish-drama' => (icon: Icons.favorite_rounded, color: const Color(0xFFD81B60)),

    // --- Music ---
    'arabic-music' => (icon: Icons.piano_rounded, color: const Color(0xFF00695C)),
    'fairuz' => (icon: Icons.mic_external_on_rounded, color: const Color(0xFF00838F)),
    'umm-kulthum' => (icon: Icons.mic_rounded, color: const Color(0xFFAD1457)),
    'pop' => (icon: Icons.album_rounded, color: const Color(0xFFE91E63)),
    'rock' => (icon: Icons.graphic_eq_rounded, color: const Color(0xFFB71C1C)),

    // --- History ---
    'islamic-history' => (icon: Icons.mosque_rounded, color: const Color(0xFF00695C)),
    'ww2' => (icon: Icons.military_tech_rounded, color: const Color(0xFF5D4037)),
    'ancient-egypt' => (icon: Icons.account_balance_rounded, color: const Color(0xFFC9A227)),
    'lebanon' => (icon: Icons.terrain_rounded, color: const Color(0xFFC62828)),

    // --- Geography ---
    'capitals' => (icon: Icons.location_city_rounded, color: const Color(0xFF00838F)),
    'arab-geo' => (icon: Icons.map_rounded, color: const Color(0xFF2E7D32)),
    'wonders' => (icon: Icons.landscape_rounded, color: const Color(0xFFF9A825)),

    // --- Science & tech ---
    'space' => (icon: Icons.rocket_launch_rounded, color: const Color(0xFF1A237E)),
    'tech' => (icon: Icons.memory_rounded, color: const Color(0xFF37474F)),
    'body' => (icon: Icons.accessibility_new_rounded, color: const Color(0xFFC2185B)),

    // --- Video games ---
    'fifa' => (icon: Icons.sports_soccer_rounded, color: const Color(0xFF2E7D32)),
    'fortnite' => (icon: Icons.bolt_rounded, color: const Color(0xFF7B1FA2)),
    'minecraft' => (icon: Icons.view_in_ar_rounded, color: const Color(0xFF558B2F)),
    'lol' => (icon: Icons.gamepad_rounded, color: const Color(0xFF1565C0)),

    // --- Literature & general knowledge ---
    'general-knowledge' => (icon: Icons.lightbulb_rounded, color: const Color(0xFFFFB300)),
    'world-lit' => (icon: Icons.auto_stories_rounded, color: const Color(0xFF3949AB)),
    'arabic-lit' => (icon: Icons.edit_note_rounded, color: const Color(0xFF00695C)),
    'proverbs' => (icon: Icons.format_quote_rounded, color: const Color(0xFF6D4C41)),

    // --- Food & puzzles ---
    'food' => (icon: Icons.restaurant_rounded, color: const Color(0xFFEF6C00)),
    'arabic-food' => (icon: Icons.dinner_dining_rounded, color: const Color(0xFFD84315)),
    'riddles' => (icon: Icons.psychology_rounded, color: const Color(0xFF5E35B1)),
    'math' => (icon: Icons.calculate_rounded, color: const Color(0xFF1976D2)),

    _ => (icon: Icons.category_rounded, color: const Color(0xFF757575)),
  };
}

/// Icon-only accessor for category *groups* (the picker's section headers,
/// always shown in a fixed gold — see `CategoryCatalog`) — a thin wrapper
/// over [categoryIcon], which is the single source of truth for both groups
/// and individual categories.
IconData categoryGroupIcon(String iconKey) => categoryIcon(iconKey).icon;

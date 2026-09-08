import 'package:flutter/material.dart';

/// Maps a [CategoryGroupModel.iconKey] (a plain string stored in Firestore,
/// set once in `functions/src/seed/categoryTaxonomy.ts`) to the Material
/// icon shown next to that group's header in the category picker.
///
/// Kept as a lookup table rather than storing an [IconData] directly in
/// Firestore, since icon codepoints aren't stable data to persist — the key
/// is just a short stable label ("sports", "movies", ...) the data seed and
/// this map both agree on. Falls back to a generic icon for any key this
/// map doesn't recognize, so adding a category group in
/// `categoryTaxonomy.ts` without also updating this file degrades
/// gracefully instead of crashing.
IconData categoryGroupIcon(String iconKey) {
  return switch (iconKey) {
    'sports' => Icons.sports_soccer_rounded,
    'movies' => Icons.movie_rounded,
    'drama' => Icons.theater_comedy_rounded,
    'music' => Icons.music_note_rounded,
    'history' => Icons.history_edu_rounded,
    'geography' => Icons.public_rounded,
    'science' => Icons.science_rounded,
    'games' => Icons.sports_esports_rounded,
    'literature' => Icons.menu_book_rounded,
    'puzzle' => Icons.extension_rounded,
    _ => Icons.category_rounded,
  };
}

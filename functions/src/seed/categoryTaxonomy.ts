/**
 * The full starter category taxonomy: general knowledge groups, each
 * broken into a "General" category plus specific ones — the same
 * general-then-specific pattern QuizUp used (e.g. Sports → Football →
 * Real Madrid), scoped to what's actually sane to seed and maintain for a
 * friend-group app rather than QuizUp's own ~1,200 topics.
 *
 * This file is pure data — no Firestore calls here — consumed by
 * `seedPregeneratedQuestions.ts`. To add a category later, add a line here
 * and re-run the seed script; nothing else needs to change.
 *
 * `topic` is the (more specific/disambiguated) subject string — e.g.
 * "برشلونة" alone is ambiguous (city vs. club), so its `topic` spells out
 * "نادي برشلونة الإسباني لكرة القدم". `name` is what players actually see
 * in the app.
 *
 * `name`/`description` are Arabic (the primary/default locale); `nameEn`/
 * `descriptionEn` are the English display strings shown to players whose
 * `users/{uid}.locale` is `"en"` — see `CategoryModel.displayName` on the
 * Dart side and `resolveDisplayName` in `taxonomyFirestore.ts`. This is
 * purely about which language a category's NAME renders in; it's
 * independent of `language` below, which is which language pool of
 * *questions* this category seeds.
 */

export interface CategoryGroupSeed {
  id: string;
  name: string;
  nameEn: string;
  order: number;
  iconKey: string;
}

export interface CategorySeed {
  id: string;
  groupId: string;
  name: string;
  nameEn: string;
  description: string;
  descriptionEn: string;
  topic: string;
  language: "ar" | "en";
}

export const CATEGORY_GROUPS: CategoryGroupSeed[] = [
  { id: "sports", name: "رياضة", nameEn: "Sports", order: 0, iconKey: "sports" },
  { id: "movies-tv-global", name: "أفلام ومسلسلات عالمية", nameEn: "Movies & TV", order: 1, iconKey: "movies" },
  { id: "arabic-drama", name: "سينما ودراما عربية", nameEn: "Arabic Cinema & Drama", order: 2, iconKey: "drama" },
  { id: "music", name: "موسيقى", nameEn: "Music", order: 3, iconKey: "music" },
  { id: "history", name: "تاريخ", nameEn: "History", order: 4, iconKey: "history" },
  { id: "geography", name: "جغرافيا", nameEn: "Geography", order: 5, iconKey: "geography" },
  { id: "science-tech", name: "علوم وتكنولوجيا", nameEn: "Science & Tech", order: 6, iconKey: "science" },
  { id: "video-games", name: "ألعاب فيديو", nameEn: "Video Games", order: 7, iconKey: "games" },
  { id: "literature-gk", name: "أدب ومعرفة عامة", nameEn: "Literature & General Knowledge", order: 8, iconKey: "literature" },
  { id: "food-puzzles", name: "طعام وألغاز", nameEn: "Food & Puzzles", order: 9, iconKey: "puzzle" },
];

export const CATEGORIES: CategorySeed[] = [
  // --- رياضة (Sports) ---
  { id: "sports-general", groupId: "sports", name: "رياضة عامة", nameEn: "General Sports", description: "منوعات رياضية من كل الألعاب", descriptionEn: "A mix of sports trivia from every game", topic: "رياضة عامة ومنوعة من مختلف الألعاب الرياضية", language: "ar" },
  { id: "football-general", groupId: "sports", name: "كرة القدم عامة", nameEn: "Football General", description: "قوانين وتاريخ ونجوم كرة القدم", descriptionEn: "Football rules, history, and stars", topic: "كرة القدم بشكل عام: القوانين، التاريخ، والنجوم", language: "ar" },
  { id: "real-madrid", groupId: "sports", name: "ريال مدريد", nameEn: "Real Madrid", description: "تاريخ ولاعبو نادي ريال مدريد", descriptionEn: "Real Madrid's history and players", topic: "نادي ريال مدريد الإسباني لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "barcelona", groupId: "sports", name: "برشلونة", nameEn: "Barcelona", description: "تاريخ ولاعبو نادي برشلونة", descriptionEn: "Barcelona's history and players", topic: "نادي برشلونة الإسباني لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "man-utd", groupId: "sports", name: "مانشستر يونايتد", nameEn: "Manchester United", description: "تاريخ ولاعبو مانشستر يونايتد", descriptionEn: "Manchester United's history and players", topic: "نادي مانشستر يونايتد الإنكليزي لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "liverpool", groupId: "sports", name: "ليفربول", nameEn: "Liverpool", description: "تاريخ ولاعبو نادي ليفربول", descriptionEn: "Liverpool's history and players", topic: "نادي ليفربول الإنكليزي لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "arab-national-teams", groupId: "sports", name: "المنتخبات العربية", nameEn: "Arab National Teams", description: "منتخبات الدول العربية لكرة القدم", descriptionEn: "Arab countries' national football teams", topic: "منتخبات الدول العربية الوطنية لكرة القدم ومشاركاتها الدولية", language: "ar" },
  { id: "world-cup", groupId: "sports", name: "كأس العالم", nameEn: "World Cup", description: "تاريخ بطولة كأس العالم لكرة القدم", descriptionEn: "The history of the FIFA World Cup", topic: "بطولة كأس العالم FIFA لكرة القدم عبر تاريخها", language: "ar" },
  { id: "basketball-nba", groupId: "sports", name: "كرة السلة و NBA", nameEn: "Basketball & NBA", description: "دوري كرة السلة الأميركي ونجومه", descriptionEn: "The American basketball league and its stars", topic: "كرة السلة ودوري الـNBA الأميركي ونجومه", language: "ar" },
  { id: "tennis", groupId: "sports", name: "كرة المضرب", nameEn: "Tennis", description: "بطولات التنس الكبرى ونجومها", descriptionEn: "Major tennis tournaments and their stars", topic: "رياضة التنس (كرة المضرب) وبطولاتها الكبرى ونجومها", language: "ar" },

  // --- أفلام ومسلسلات عالمية (Global Movies & TV) ---
  { id: "movies-general", groupId: "movies-tv-global", name: "أفلام عامة", nameEn: "General Movies", description: "أفلام هوليوود والعالم", descriptionEn: "Hollywood and world cinema", topic: "أفلام السينما العالمية بشكل عام", language: "ar" },
  { id: "marvel", groupId: "movies-tv-global", name: "عالم مارفل", nameEn: "Marvel Universe", description: "أفلام وأبطال مارفل السينمائي", descriptionEn: "Marvel Cinematic Universe films and heroes", topic: "أفلام وشخصيات عالم مارفل السينمائي (MCU)", language: "ar" },
  { id: "harry-potter", groupId: "movies-tv-global", name: "هاري بوتر", nameEn: "Harry Potter", description: "سلسلة أفلام وروايات هاري بوتر", descriptionEn: "The Harry Potter book and film series", topic: "سلسلة هاري بوتر (الروايات والأفلام)", language: "ar" },
  { id: "star-wars", groupId: "movies-tv-global", name: "حرب النجوم", nameEn: "Star Wars", description: "سلسلة أفلام حرب النجوم", descriptionEn: "The Star Wars film series", topic: "سلسلة أفلام حرب النجوم Star Wars", language: "ar" },
  { id: "tv-shows-general", groupId: "movies-tv-global", name: "مسلسلات عامة", nameEn: "General TV Shows", description: "مسلسلات أجنبية متنوعة", descriptionEn: "A mix of foreign TV series", topic: "المسلسلات التلفزيونية الأجنبية بشكل عام", language: "ar" },
  { id: "friends", groupId: "movies-tv-global", name: "فريندز", nameEn: "Friends", description: "مسلسل Friends الكوميدي", descriptionEn: "The Friends sitcom", topic: "مسلسل Friends الكوميدي الأميركي", language: "ar" },
  { id: "got", groupId: "movies-tv-global", name: "صراع العروش", nameEn: "Game of Thrones", description: "مسلسل Game of Thrones", descriptionEn: "The Game of Thrones series", topic: "مسلسل صراع العروش Game of Thrones", language: "ar" },
  { id: "anime-general", groupId: "movies-tv-global", name: "أنمي عام", nameEn: "General Anime", description: "أنمي ياباني متنوع", descriptionEn: "A mix of Japanese anime", topic: "الأنمي الياباني بشكل عام", language: "ar" },
  { id: "one-piece", groupId: "movies-tv-global", name: "ون بيس", nameEn: "One Piece", description: "أنمي ومانغا ون بيس", descriptionEn: "The One Piece anime and manga", topic: "أنمي ومانغا One Piece", language: "ar" },
  { id: "naruto", groupId: "movies-tv-global", name: "ناروتو", nameEn: "Naruto", description: "أنمي ومانغا ناروتو", descriptionEn: "The Naruto anime and manga", topic: "أنمي ومانغا Naruto", language: "ar" },

  // --- سينما ودراما عربية (Arabic Cinema & Drama) ---
  { id: "arabic-drama-general", groupId: "arabic-drama", name: "دراما عربية عامة", nameEn: "General Arabic Drama", description: "مسلسلات وأفلام عربية متنوعة", descriptionEn: "A mix of Arabic series and films", topic: "الدراما والمسلسلات العربية بشكل عام", language: "ar" },
  { id: "classic-egyptian-films", groupId: "arabic-drama", name: "أفلام مصرية كلاسيكية", nameEn: "Classic Egyptian Films", description: "روائع السينما المصرية القديمة", descriptionEn: "Masterpieces of old Egyptian cinema", topic: "الأفلام المصرية الكلاسيكية القديمة ونجومها", language: "ar" },
  { id: "ramadan-series", groupId: "arabic-drama", name: "مسلسلات رمضان", nameEn: "Ramadan Series", description: "مسلسلات موسم رمضان الشهيرة", descriptionEn: "Famous Ramadan-season series", topic: "المسلسلات العربية الشهيرة التي عُرضت في موسم رمضان", language: "ar" },
  { id: "arabic-comedy", groupId: "arabic-drama", name: "كوميديا عربية", nameEn: "Arabic Comedy", description: "أفلام ومسلسلات كوميدية عربية", descriptionEn: "Arabic comedy films and series", topic: "الأفلام والمسلسلات الكوميدية العربية", language: "ar" },
  { id: "turkish-dubbed-drama", groupId: "arabic-drama", name: "دراما تركية مدبلجة", nameEn: "Dubbed Turkish Drama", description: "المسلسلات التركية المدبلجة الشهيرة", descriptionEn: "Famous Turkish series dubbed into Arabic", topic: "المسلسلات التركية المدبلجة للعربية والشهيرة في العالم العربي", language: "ar" },

  // --- موسيقى (Music) ---
  { id: "music-general", groupId: "music", name: "موسيقى عامة", nameEn: "General Music", description: "موسيقى عالمية وعربية متنوعة", descriptionEn: "A mix of world and Arabic music", topic: "الموسيقى بشكل عام، عالمية وعربية", language: "ar" },
  { id: "arabic-music", groupId: "music", name: "موسيقى عربية", nameEn: "Arabic Music", description: "الأغنية العربية عبر العصور", descriptionEn: "Arabic song through the ages", topic: "الموسيقى والأغنية العربية عبر العصور", language: "ar" },
  { id: "fairuz", groupId: "music", name: "فيروز", nameEn: "Fairuz", description: "أغاني وحياة السيدة فيروز", descriptionEn: "Fairuz's songs and life", topic: "الفنانة اللبنانية فيروز، حياتها وأغانيها", language: "ar" },
  { id: "umm-kulthum", groupId: "music", name: "أم كلثوم", nameEn: "Umm Kulthum", description: "أغاني وحياة أم كلثوم", descriptionEn: "Umm Kulthum's songs and life", topic: "الفنانة المصرية أم كلثوم، حياتها وأغانيها", language: "ar" },
  { id: "global-pop", groupId: "music", name: "بوب عالمي", nameEn: "Global Pop", description: "نجوم موسيقى البوب العالمية", descriptionEn: "Global pop music stars", topic: "موسيقى البوب العالمية ونجومها", language: "ar" },
  { id: "rock", groupId: "music", name: "روك", nameEn: "Rock", description: "فرق ونجوم موسيقى الروك", descriptionEn: "Rock bands and stars", topic: "موسيقى الروك وأشهر فرقها ونجومها", language: "ar" },

  // --- تاريخ (History) ---
  { id: "history-general", groupId: "history", name: "تاريخ عام", nameEn: "General History", description: "أحداث وشخصيات تاريخية عالمية", descriptionEn: "World historical events and figures", topic: "التاريخ العالمي بشكل عام", language: "ar" },
  { id: "arab-islamic-history", groupId: "history", name: "تاريخ عربي وإسلامي", nameEn: "Arab & Islamic History", description: "التاريخ العربي والإسلامي", descriptionEn: "Arab and Islamic history", topic: "التاريخ العربي والإسلامي عبر العصور", language: "ar" },
  { id: "ww2", groupId: "history", name: "الحرب العالمية الثانية", nameEn: "World War II", description: "أحداث الحرب العالمية الثانية", descriptionEn: "Events of World War II", topic: "أحداث ومعارك وشخصيات الحرب العالمية الثانية", language: "ar" },
  { id: "ancient-egypt", groupId: "history", name: "مصر القديمة", nameEn: "Ancient Egypt", description: "الحضارة الفرعونية القديمة", descriptionEn: "The ancient Pharaonic civilization", topic: "الحضارة المصرية القديمة (الفرعونية)", language: "ar" },
  { id: "lebanon-history", groupId: "history", name: "تاريخ لبنان", nameEn: "History of Lebanon", description: "تاريخ لبنان عبر العصور", descriptionEn: "Lebanon's history through the ages", topic: "تاريخ لبنان عبر العصور المختلفة", language: "ar" },

  // --- جغرافيا (Geography) ---
  { id: "geography-general", groupId: "geography", name: "جغرافيا عامة", nameEn: "General Geography", description: "جغرافيا العالم بشكل عام", descriptionEn: "World geography in general", topic: "الجغرافيا العالمية بشكل عام", language: "ar" },
  { id: "capitals-countries", groupId: "geography", name: "عواصم ودول العالم", nameEn: "World Capitals & Countries", description: "عواصم ودول ومعالم العالم", descriptionEn: "World capitals, countries, and landmarks", topic: "عواصم ودول العالم وأعلامها ومعالمها", language: "ar" },
  { id: "arab-world-geography", groupId: "geography", name: "جغرافيا الوطن العربي", nameEn: "Geography of the Arab World", description: "جغرافيا الدول العربية", descriptionEn: "The geography of Arab countries", topic: "جغرافيا الوطن العربي ودوله ومدنه", language: "ar" },
  { id: "world-wonders", groupId: "geography", name: "عجائب الدنيا", nameEn: "Wonders of the World", description: "عجائب الدنيا القديمة والحديثة", descriptionEn: "The ancient and modern wonders of the world", topic: "عجائب الدنيا القديمة والحديثة والمعالم الشهيرة", language: "ar" },

  // --- علوم وتكنولوجيا (Science & Tech) ---
  { id: "science-general", groupId: "science-tech", name: "علوم عامة", nameEn: "General Science", description: "فيزياء وكيمياء وأحياء عامة", descriptionEn: "General physics, chemistry, and biology", topic: "العلوم العامة: فيزياء، كيمياء، وأحياء لغير المتخصصين", language: "ar" },
  { id: "space-astronomy", groupId: "science-tech", name: "الفضاء والفلك", nameEn: "Space & Astronomy", description: "الكواكب والنجوم واستكشاف الفضاء", descriptionEn: "Planets, stars, and space exploration", topic: "علم الفلك واستكشاف الفضاء والكواكب والنجوم", language: "ar" },
  { id: "tech-computers", groupId: "science-tech", name: "التكنولوجيا والحواسيب", nameEn: "Technology & Computers", description: "الحواسيب والإنترنت والهواتف الذكية", descriptionEn: "Computers, the internet, and smartphones", topic: "التكنولوجيا والحواسيب والإنترنت والهواتف الذكية", language: "ar" },
  { id: "human-body", groupId: "science-tech", name: "جسم الإنسان", nameEn: "The Human Body", description: "أعضاء وأجهزة جسم الإنسان", descriptionEn: "The organs and systems of the human body", topic: "جسم الإنسان وأعضاؤه وأجهزته", language: "ar" },

  // --- ألعاب فيديو (Video Games) ---
  { id: "video-games-general", groupId: "video-games", name: "ألعاب فيديو عامة", nameEn: "General Video Games", description: "ألعاب الفيديو بشكل عام", descriptionEn: "Video games in general", topic: "ألعاب الفيديو بشكل عام وتاريخها", language: "ar" },
  { id: "fifa", groupId: "video-games", name: "فيفا", nameEn: "FIFA", description: "سلسلة ألعاب فيفا لكرة القدم", descriptionEn: "The FIFA football game series", topic: "سلسلة ألعاب فيديو FIFA لكرة القدم", language: "ar" },
  { id: "fortnite", groupId: "video-games", name: "فورتنايت", nameEn: "Fortnite", description: "لعبة فورتنايت", descriptionEn: "The game Fortnite", topic: "لعبة الفيديو Fortnite", language: "ar" },
  { id: "minecraft", groupId: "video-games", name: "ماين كرافت", nameEn: "Minecraft", description: "لعبة ماين كرافت", descriptionEn: "The game Minecraft", topic: "لعبة الفيديو Minecraft", language: "ar" },
  { id: "league-of-legends", groupId: "video-games", name: "ليغ أوف ليجيندز", nameEn: "League of Legends", description: "لعبة League of Legends", descriptionEn: "The game League of Legends", topic: "لعبة الفيديو League of Legends", language: "ar" },

  // --- أدب ومعرفة عامة (Literature & General Knowledge) ---
  { id: "general-knowledge", groupId: "literature-gk", name: "معلومات عامة", nameEn: "General Knowledge", description: "أسئلة معرفية متنوعة", descriptionEn: "A mix of general-knowledge questions", topic: "معلومات ومعارف عامة متنوعة", language: "ar" },
  { id: "world-literature", groupId: "literature-gk", name: "أدب عالمي", nameEn: "World Literature", description: "روايات وأدباء عالميون", descriptionEn: "World novels and authors", topic: "الأدب العالمي والروايات والأدباء المشهورون", language: "ar" },
  { id: "arabic-literature", groupId: "literature-gk", name: "أدب عربي وشعر", nameEn: "Arabic Literature & Poetry", description: "الشعر والأدب العربي", descriptionEn: "Arabic poetry and literature", topic: "الأدب العربي والشعر عبر العصور", language: "ar" },
  { id: "proverbs-sayings", groupId: "literature-gk", name: "أمثال وحكم", nameEn: "Proverbs & Sayings", description: "الأمثال الشعبية والحكم", descriptionEn: "Popular proverbs and sayings", topic: "الأمثال الشعبية العربية والحكم المشهورة", language: "ar" },

  // --- طعام وألغاز (Food & Puzzles) ---
  { id: "food-general", groupId: "food-puzzles", name: "طعام عام", nameEn: "General Food", description: "المطبخ العالمي والأطعمة", descriptionEn: "World cuisine and foods", topic: "الطعام والمطبخ العالمي بشكل عام", language: "ar" },
  { id: "arabic-cuisine", groupId: "food-puzzles", name: "مأكولات عربية", nameEn: "Arabic Cuisine", description: "أطباق المطبخ العربي", descriptionEn: "Dishes of Arabic cuisine", topic: "المطبخ العربي وأطباقه التقليدية", language: "ar" },
  { id: "riddles", groupId: "food-puzzles", name: "ألغاز وذكاء", nameEn: "Riddles & Puzzles", description: "ألغاز منطقية وأسئلة ذكاء", descriptionEn: "Logic riddles and brain teasers", topic: "الألغاز المنطقية وأسئلة الذكاء", language: "ar" },
  { id: "quick-math", groupId: "food-puzzles", name: "رياضيات سريعة", nameEn: "Quick Math", description: "أسئلة حساب ذهني سريع", descriptionEn: "Quick mental math questions", topic: "أسئلة رياضيات وحساب ذهني سريع وبسيط", language: "ar" },
];

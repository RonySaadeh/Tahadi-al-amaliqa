/**
 * The full starter category taxonomy: general knowledge groups, each
 * broken into a "General" category plus specific ones — the same
 * general-then-specific pattern QuizUp used (e.g. Sports → Football →
 * Real Madrid), scoped to what's actually sane to seed and maintain for a
 * friend-group app rather than QuizUp's own ~1,200 topics.
 *
 * This file is pure data — no Firestore/Claude calls here — consumed by
 * `seedCategoryTaxonomy.ts`. To add a category later, add a line here and
 * re-run the seed script; nothing else needs to change.
 *
 * `topic` is the (more specific/disambiguated) string handed to Claude as
 * the subject to write questions about — e.g. "برشلونة" alone is
 * ambiguous (city vs. club), so its `topic` spells out "نادي برشلونة
 * الإسباني لكرة القدم". `name` is what players actually see in the app.
 */

export interface CategoryGroupSeed {
  id: string;
  name: string;
  order: number;
  iconKey: string;
}

export interface CategorySeed {
  id: string;
  groupId: string;
  name: string;
  description: string;
  topic: string;
  language: "ar" | "en";
}

export const CATEGORY_GROUPS: CategoryGroupSeed[] = [
  { id: "sports", name: "رياضة", order: 0, iconKey: "sports" },
  { id: "movies-tv-global", name: "أفلام ومسلسلات عالمية", order: 1, iconKey: "movies" },
  { id: "arabic-drama", name: "سينما ودراما عربية", order: 2, iconKey: "drama" },
  { id: "music", name: "موسيقى", order: 3, iconKey: "music" },
  { id: "history", name: "تاريخ", order: 4, iconKey: "history" },
  { id: "geography", name: "جغرافيا", order: 5, iconKey: "geography" },
  { id: "science-tech", name: "علوم وتكنولوجيا", order: 6, iconKey: "science" },
  { id: "video-games", name: "ألعاب فيديو", order: 7, iconKey: "games" },
  { id: "literature-gk", name: "أدب ومعرفة عامة", order: 8, iconKey: "literature" },
  { id: "food-puzzles", name: "طعام وألغاز", order: 9, iconKey: "puzzle" },
];

export const CATEGORIES: CategorySeed[] = [
  // --- رياضة (Sports) ---
  { id: "sports-general", groupId: "sports", name: "رياضة عامة", description: "منوعات رياضية من كل الألعاب", topic: "رياضة عامة ومنوعة من مختلف الألعاب الرياضية", language: "ar" },
  { id: "football-general", groupId: "sports", name: "كرة القدم عامة", description: "قوانين وتاريخ ونجوم كرة القدم", topic: "كرة القدم بشكل عام: القوانين، التاريخ، والنجوم", language: "ar" },
  { id: "real-madrid", groupId: "sports", name: "ريال مدريد", description: "تاريخ ولاعبو نادي ريال مدريد", topic: "نادي ريال مدريد الإسباني لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "barcelona", groupId: "sports", name: "برشلونة", description: "تاريخ ولاعبو نادي برشلونة", topic: "نادي برشلونة الإسباني لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "man-utd", groupId: "sports", name: "مانشستر يونايتد", description: "تاريخ ولاعبو مانشستر يونايتد", topic: "نادي مانشستر يونايتد الإنكليزي لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "liverpool", groupId: "sports", name: "ليفربول", description: "تاريخ ولاعبو نادي ليفربول", topic: "نادي ليفربول الإنكليزي لكرة القدم، تاريخه ولاعبوه وبطولاته", language: "ar" },
  { id: "arab-national-teams", groupId: "sports", name: "المنتخبات العربية", description: "منتخبات الدول العربية لكرة القدم", topic: "منتخبات الدول العربية الوطنية لكرة القدم ومشاركاتها الدولية", language: "ar" },
  { id: "world-cup", groupId: "sports", name: "كأس العالم", description: "تاريخ بطولة كأس العالم لكرة القدم", topic: "بطولة كأس العالم FIFA لكرة القدم عبر تاريخها", language: "ar" },
  { id: "basketball-nba", groupId: "sports", name: "كرة السلة و NBA", description: "دوري كرة السلة الأميركي ونجومه", topic: "كرة السلة ودوري الـNBA الأميركي ونجومه", language: "ar" },
  { id: "tennis", groupId: "sports", name: "كرة المضرب", description: "بطولات التنس الكبرى ونجومها", topic: "رياضة التنس (كرة المضرب) وبطولاتها الكبرى ونجومها", language: "ar" },

  // --- أفلام ومسلسلات عالمية (Global Movies & TV) ---
  { id: "movies-general", groupId: "movies-tv-global", name: "أفلام عامة", description: "أفلام هوليوود والعالم", topic: "أفلام السينما العالمية بشكل عام", language: "ar" },
  { id: "marvel", groupId: "movies-tv-global", name: "عالم مارفل", description: "أفلام وأبطال مارفل السينمائي", topic: "أفلام وشخصيات عالم مارفل السينمائي (MCU)", language: "ar" },
  { id: "harry-potter", groupId: "movies-tv-global", name: "هاري بوتر", description: "سلسلة أفلام وروايات هاري بوتر", topic: "سلسلة هاري بوتر (الروايات والأفلام)", language: "ar" },
  { id: "star-wars", groupId: "movies-tv-global", name: "حرب النجوم", description: "سلسلة أفلام حرب النجوم", topic: "سلسلة أفلام حرب النجوم Star Wars", language: "ar" },
  { id: "tv-shows-general", groupId: "movies-tv-global", name: "مسلسلات عامة", description: "مسلسلات أجنبية متنوعة", topic: "المسلسلات التلفزيونية الأجنبية بشكل عام", language: "ar" },
  { id: "friends", groupId: "movies-tv-global", name: "فريندز", description: "مسلسل Friends الكوميدي", topic: "مسلسل Friends الكوميدي الأميركي", language: "ar" },
  { id: "got", groupId: "movies-tv-global", name: "صراع العروش", description: "مسلسل Game of Thrones", topic: "مسلسل صراع العروش Game of Thrones", language: "ar" },
  { id: "anime-general", groupId: "movies-tv-global", name: "أنمي عام", description: "أنمي ياباني متنوع", topic: "الأنمي الياباني بشكل عام", language: "ar" },
  { id: "one-piece", groupId: "movies-tv-global", name: "ون بيس", description: "أنمي ومانغا ون بيس", topic: "أنمي ومانغا One Piece", language: "ar" },
  { id: "naruto", groupId: "movies-tv-global", name: "ناروتو", description: "أنمي ومانغا ناروتو", topic: "أنمي ومانغا Naruto", language: "ar" },

  // --- سينما ودراما عربية (Arabic Cinema & Drama) ---
  { id: "arabic-drama-general", groupId: "arabic-drama", name: "دراما عربية عامة", description: "مسلسلات وأفلام عربية متنوعة", topic: "الدراما والمسلسلات العربية بشكل عام", language: "ar" },
  { id: "classic-egyptian-films", groupId: "arabic-drama", name: "أفلام مصرية كلاسيكية", description: "روائع السينما المصرية القديمة", topic: "الأفلام المصرية الكلاسيكية القديمة ونجومها", language: "ar" },
  { id: "ramadan-series", groupId: "arabic-drama", name: "مسلسلات رمضان", description: "مسلسلات موسم رمضان الشهيرة", topic: "المسلسلات العربية الشهيرة التي عُرضت في موسم رمضان", language: "ar" },
  { id: "arabic-comedy", groupId: "arabic-drama", name: "كوميديا عربية", description: "أفلام ومسلسلات كوميدية عربية", topic: "الأفلام والمسلسلات الكوميدية العربية", language: "ar" },
  { id: "turkish-dubbed-drama", groupId: "arabic-drama", name: "دراما تركية مدبلجة", description: "المسلسلات التركية المدبلجة الشهيرة", topic: "المسلسلات التركية المدبلجة للعربية والشهيرة في العالم العربي", language: "ar" },

  // --- موسيقى (Music) ---
  { id: "music-general", groupId: "music", name: "موسيقى عامة", description: "موسيقى عالمية وعربية متنوعة", topic: "الموسيقى بشكل عام، عالمية وعربية", language: "ar" },
  { id: "arabic-music", groupId: "music", name: "موسيقى عربية", description: "الأغنية العربية عبر العصور", topic: "الموسيقى والأغنية العربية عبر العصور", language: "ar" },
  { id: "fairuz", groupId: "music", name: "فيروز", description: "أغاني وحياة السيدة فيروز", topic: "الفنانة اللبنانية فيروز، حياتها وأغانيها", language: "ar" },
  { id: "umm-kulthum", groupId: "music", name: "أم كلثوم", description: "أغاني وحياة أم كلثوم", topic: "الفنانة المصرية أم كلثوم، حياتها وأغانيها", language: "ar" },
  { id: "global-pop", groupId: "music", name: "بوب عالمي", description: "نجوم موسيقى البوب العالمية", topic: "موسيقى البوب العالمية ونجومها", language: "ar" },
  { id: "rock", groupId: "music", name: "روك", description: "فرق ونجوم موسيقى الروك", topic: "موسيقى الروك وأشهر فرقها ونجومها", language: "ar" },

  // --- تاريخ (History) ---
  { id: "history-general", groupId: "history", name: "تاريخ عام", description: "أحداث وشخصيات تاريخية عالمية", topic: "التاريخ العالمي بشكل عام", language: "ar" },
  { id: "arab-islamic-history", groupId: "history", name: "تاريخ عربي وإسلامي", description: "التاريخ العربي والإسلامي", topic: "التاريخ العربي والإسلامي عبر العصور", language: "ar" },
  { id: "ww2", groupId: "history", name: "الحرب العالمية الثانية", description: "أحداث الحرب العالمية الثانية", topic: "أحداث ومعارك وشخصيات الحرب العالمية الثانية", language: "ar" },
  { id: "ancient-egypt", groupId: "history", name: "مصر القديمة", description: "الحضارة الفرعونية القديمة", topic: "الحضارة المصرية القديمة (الفرعونية)", language: "ar" },
  { id: "lebanon-history", groupId: "history", name: "تاريخ لبنان", description: "تاريخ لبنان عبر العصور", topic: "تاريخ لبنان عبر العصور المختلفة", language: "ar" },

  // --- جغرافيا (Geography) ---
  { id: "geography-general", groupId: "geography", name: "جغرافيا عامة", description: "جغرافيا العالم بشكل عام", topic: "الجغرافيا العالمية بشكل عام", language: "ar" },
  { id: "capitals-countries", groupId: "geography", name: "عواصم ودول العالم", description: "عواصم ودول ومعالم العالم", topic: "عواصم ودول العالم وأعلامها ومعالمها", language: "ar" },
  { id: "arab-world-geography", groupId: "geography", name: "جغرافيا الوطن العربي", description: "جغرافيا الدول العربية", topic: "جغرافيا الوطن العربي ودوله ومدنه", language: "ar" },
  { id: "world-wonders", groupId: "geography", name: "عجائب الدنيا", description: "عجائب الدنيا القديمة والحديثة", topic: "عجائب الدنيا القديمة والحديثة والمعالم الشهيرة", language: "ar" },

  // --- علوم وتكنولوجيا (Science & Tech) ---
  { id: "science-general", groupId: "science-tech", name: "علوم عامة", description: "فيزياء وكيمياء وأحياء عامة", topic: "العلوم العامة: فيزياء، كيمياء، وأحياء لغير المتخصصين", language: "ar" },
  { id: "space-astronomy", groupId: "science-tech", name: "الفضاء والفلك", description: "الكواكب والنجوم واستكشاف الفضاء", topic: "علم الفلك واستكشاف الفضاء والكواكب والنجوم", language: "ar" },
  { id: "tech-computers", groupId: "science-tech", name: "التكنولوجيا والحواسيب", description: "الحواسيب والإنترنت والهواتف الذكية", topic: "التكنولوجيا والحواسيب والإنترنت والهواتف الذكية", language: "ar" },
  { id: "human-body", groupId: "science-tech", name: "جسم الإنسان", description: "أعضاء وأجهزة جسم الإنسان", topic: "جسم الإنسان وأعضاؤه وأجهزته", language: "ar" },

  // --- ألعاب فيديو (Video Games) ---
  { id: "video-games-general", groupId: "video-games", name: "ألعاب فيديو عامة", description: "ألعاب الفيديو بشكل عام", topic: "ألعاب الفيديو بشكل عام وتاريخها", language: "ar" },
  { id: "fifa", groupId: "video-games", name: "فيفا", description: "سلسلة ألعاب فيفا لكرة القدم", topic: "سلسلة ألعاب فيديو FIFA لكرة القدم", language: "ar" },
  { id: "fortnite", groupId: "video-games", name: "فورتنايت", description: "لعبة فورتنايت", topic: "لعبة الفيديو Fortnite", language: "ar" },
  { id: "minecraft", groupId: "video-games", name: "ماين كرافت", description: "لعبة ماين كرافت", topic: "لعبة الفيديو Minecraft", language: "ar" },
  { id: "league-of-legends", groupId: "video-games", name: "ليغ أوف ليجيندز", description: "لعبة League of Legends", topic: "لعبة الفيديو League of Legends", language: "ar" },

  // --- أدب ومعرفة عامة (Literature & General Knowledge) ---
  { id: "general-knowledge", groupId: "literature-gk", name: "معلومات عامة", description: "أسئلة معرفية متنوعة", topic: "معلومات ومعارف عامة متنوعة", language: "ar" },
  { id: "world-literature", groupId: "literature-gk", name: "أدب عالمي", description: "روايات وأدباء عالميون", topic: "الأدب العالمي والروايات والأدباء المشهورون", language: "ar" },
  { id: "arabic-literature", groupId: "literature-gk", name: "أدب عربي وشعر", description: "الشعر والأدب العربي", topic: "الأدب العربي والشعر عبر العصور", language: "ar" },
  { id: "proverbs-sayings", groupId: "literature-gk", name: "أمثال وحكم", description: "الأمثال الشعبية والحكم", topic: "الأمثال الشعبية العربية والحكم المشهورة", language: "ar" },

  // --- طعام وألغاز (Food & Puzzles) ---
  { id: "food-general", groupId: "food-puzzles", name: "طعام عام", description: "المطبخ العالمي والأطعمة", topic: "الطعام والمطبخ العالمي بشكل عام", language: "ar" },
  { id: "arabic-cuisine", groupId: "food-puzzles", name: "مأكولات عربية", description: "أطباق المطبخ العربي", topic: "المطبخ العربي وأطباقه التقليدية", language: "ar" },
  { id: "riddles", groupId: "food-puzzles", name: "ألغاز وذكاء", description: "ألغاز منطقية وأسئلة ذكاء", topic: "الألغاز المنطقية وأسئلة الذكاء", language: "ar" },
  { id: "quick-math", groupId: "food-puzzles", name: "رياضيات سريعة", description: "أسئلة حساب ذهني سريع", topic: "أسئلة رياضيات وحساب ذهني سريع وبسيط", language: "ar" },
];

// INFO: This folder is exclusively for vanilla/ss13 bound languages.

// 'basic' language; spoken by default.
/datum/language/common
	name = "English"
	desc = "The most popular language in the world before the war, and likely still today."
	speech_verb = "says"
	whisper_verb = "whispers"
	key = "0"
	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_UNDERSTOOD
	default_priority = 100

	icon_state = "galcom"

//Syllable Lists
/*
	This list really long, mainly because I can't make up my mind about which mandarin syllables should be removed,
	and the english syllables had to be duplicated so that there is roughly a 50-50 weighting.

	Sources:
	http://www.sttmedia.com/syllablefrequency-english
	http://www.chinahighlights.com/travelguide/learning-chinese/pinyin-syllables.htm
*/
/datum/language/common/syllables = list(
"a", "ai", "an", "ang", "ao", "ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao",
"bie", "bin", "bing", "bo", "bu", "ca", "cai", "can", "cang", "cao", "ce", "cei", "cen", "ceng", "cha", "chai",
"chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong", "chou", "chu", "chua", "chuai", "chuan", "chuang", "chui", "chun",
"chuo", "ci", "cong", "cou", "cu", "cuan", "cui", "cun", "cuo", "da", "dai", "dan", "dang", "dao", "de", "dei",
"den", "deng", "di", "dian", "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo", "e",
"ei", "en", "er", "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu", "ga", "gai", "gan", "gang",
"gao", "ge", "gei", "gen", "geng", "gong", "gou", "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo", "ha",
"hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hm", "hng", "hong", "hou", "hu", "hua", "huai", "huan",
"huang", "hui", "hun", "huo", "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju", "juan",
"jue", "jun", "ka", "kai", "kan", "kang", "kao", "ke", "kei", "ken", "keng", "kong", "kou", "ku", "kua", "kuai",
"kuan", "kuang", "kui", "kun", "kuo", "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian",
"liang", "liao", "lie", "lin", "ling", "liu", "long", "lou", "lu", "luan", "lun", "luo", "ma", "mai", "man", "mang",
"mao", "me", "mei", "men", "meng", "mi", "mian", "miao", "mie", "min", "ming", "miu", "mo", "mou", "mu", "na",
"nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ng", "ni", "nian", "niang", "niao", "nie", "nin", "ning",
"niu", "nong", "nou", "nu", "nuan", "nuo", "o", "ou", "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng",
"pi", "pian", "piao", "pie", "pin", "ping", "po", "pou", "pu", "qi", "qia", "qian", "qiang", "qiao", "qie", "qin",
"qing", "qiong", "qiu", "qu", "quan", "que", "qun", "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou",
"ru", "rua", "ruan", "rui", "run", "ruo", "sa", "sai", "san", "sang", "sao", "se", "sei", "sen", "seng", "sha",
"shai", "shan", "shang", "shao", "she", "shei", "shen", "sheng", "shi", "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui",
"shun", "shuo", "si", "song", "sou", "su", "suan", "sui", "sun", "suo", "ta", "tai", "tan", "tang", "tao", "te",
"teng", "ti", "tian", "tiao", "tie", "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo", "wa", "wai", "wan",
"wang", "wei", "wen", "weng", "wo", "wu", "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu",
"xu", "xuan", "xue", "xun", "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yong", "you", "yu", "yuan",
"yue", "yun", "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zha", "zhai", "zhan", "zhang", "zhao",
"zhe", "zhei", "zhen", "zheng", "zhi", "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo", "zi",
"zong", "zou", "zuan", "zui", "zun", "zuo", "zu",
"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi",
"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi",
"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi",
"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi",
"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi",
"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi")

//Sign Language 

/datum/language/signlanguage
	name = "Sign Language"
	desc = "Those who cannot speak can learn this instead."
	speech_verb = "signs"
	whisper_verb = "gestures"
	key = "9"
	flags = TONGUELESS_SPEECH
	syllables = list(".")
	icon_state = "ssl"
	default_priority = 90

// Gibberish

/datum/language/aphasia
	name = "Gibbering"
	desc = "It is theorized that any sufficiently brain-damaged person can speak this language."
	speech_verb = "garbles"
	ask_verb = "mumbles"
	whisper_verb = "mutters"
	exclaim_verb = "screams incoherently"
	flags = LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD
	key = "i"
	syllables = list("m","n","gh","h","l","s","r","a","e","i","o","u")
	space_chance = 20
	default_priority = 10
	icon_state = "aphasia"

// Beachbum

/datum/language/beachbum
	name = "Beachtongue"
	desc = "An ancient language from the distant Beach Planet. People magically learn to speak it under the influence of space drugs."
	speech_verb = "mumbles"
	ask_verb = "grills"
	exclaim_verb = "hollers"
	key = "u"
	space_chance = 85
	default_priority = 90
	syllables = list("cowabunga", "rad", "radical", "dudes", "bogus", "weeed", "every",
					"dee", "dah", "woah", "surf", "blazed", "high", "heinous", "day",
					"brah", "bro", "blown", "catch", "body", "beach", "oooo", "twenty",
					"shiz", "phiz", "wizz", "pop", "chill", "awesome", "dude", "it",
					"wax", "stoked", "yes", "ding", "way", "no", "wicked", "aaaa",
					"cool", "hoo", "wah", "wee", "man", "maaaaaan", "mate", "wick",
					"oh", "ocean", "up", "out", "rip", "slide", "big", "stomp",
					"weed", "pot", "smoke", "four-twenty", "shove", "wacky", "hah",
					"sick", "slash", "spit", "stoked", "shallow", "gun", "party",
					"heavy", "stellar", "excellent", "triumphant", "babe", "four",
					"tail", "trim", "tube", "wobble", "roll", "gnarly", "epic")

	icon_state = "beach"

// Codespeak Syndicate

/datum/language/codespeak
	name = "Codespeak"
	desc = "Syndicate operatives can use a series of codewords to convey complex information, while sounding like random concepts and drinks to anyone listening in."
	key = "t"
	default_priority = 0
	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD
	icon_state = "codespeak"

/datum/language/codespeak/scramble(input)
	var/lookup = check_cache(input)
	if(lookup)
		return lookup

	. = ""
	var/list/words = list()
	while(length_char(.) < length_char(input))
		words += generate_code_phrase(return_list=TRUE)
		. = jointext(words, ", ")

	. = capitalize(.)

	var/input_ending = copytext_char(input, -1)

	var/static/list/endings
	if(!endings)
		endings = list("!", "?", ".")

	if(input_ending in endings)
		. += input_ending

	add_to_cache(input, .)

/obj/item/codespeak_manual
	name = "codespeak manual"
	desc = "The book's cover reads: \"Codespeak(tm) - Secure your communication with metaphors so elaborate, they seem randomly generated!\""
	icon = 'icons/obj/library.dmi'
	icon_state = "book2"
	var/charges = 1

/obj/item/codespeak_manual/attack_self(mob/living/user)
	if(!isliving(user))
		return

	if(user.has_language(/datum/language/codespeak))
		to_chat(user, span_boldannounce("You start skimming through [src], but you already know Codespeak."))
		return

	to_chat(user, span_boldannounce("You start skimming through [src], and suddenly your mind is filled with codewords and responses."))
	user.grant_language(/datum/language/codespeak, TRUE, TRUE, LANGUAGE_MIND)

	use_charge(user)

/obj/item/codespeak_manual/attack(mob/living/M, mob/living/user)
	if(!istype(M) || !istype(user))
		return
	if(M == user)
		attack_self(user)
		return

	playsound(loc, "punch", 25, 1, -1)

	if(M.stat == DEAD)
		M.visible_message(span_danger("[user] smacks [M]'s lifeless corpse with [src]."), span_userdanger("[user] smacks your lifeless corpse with [src]."), span_italic("You hear smacking."))
	else if(M.has_language(/datum/language/codespeak))
		M.visible_message(span_danger("[user] beats [M] over the head with [src]!"), span_userdanger("[user] beats you over the head with [src]!"), span_italic("You hear smacking."))
	else
		M.visible_message(span_notice("[user] teaches [M] by beating [M.p_them()] over the head with [src]!"), span_boldnotice("As [user] hits you with [src], codewords and responses flow through your mind."), span_italic("You hear smacking."))
		M.grant_language(/datum/language/codespeak, TRUE, TRUE, LANGUAGE_MIND)
		use_charge(user)

/obj/item/codespeak_manual/proc/use_charge(mob/user)
	charges--
	if(!charges)
		var/turf/T = get_turf(src)
		T.visible_message(span_warning("The cover and contents of [src] start shifting and changing!"))

		qdel(src)
		var/obj/item/book/manual/random/book = new(T)
		user.put_in_active_hand(book)

/obj/item/codespeak_manual/unlimited
	name = "deluxe codespeak manual"
	charges = INFINITY

///Lizard

/datum/language/draconic
	name = "Draconic"
	desc = "The common language of lizard-people, composed of sibilant hisses and rattles."
	speech_verb = "hisses"
	ask_verb = "hisses"
	exclaim_verb = "roars"
	key = "o"
	flags = TONGUELESS_SPEECH
	space_chance = 40
	syllables = list(
		"za", "az", "ze", "ez", "zi", "iz", "zo", "oz", "zu", "uz", "zs", "sz",
		"ha", "ah", "he", "eh", "hi", "ih", "ho", "oh", "hu", "uh", "hs", "sh",
		"la", "al", "le", "el", "li", "il", "lo", "ol", "lu", "ul", "ls", "sl",
		"ka", "ak", "ke", "ek", "ki", "ik", "ko", "ok", "ku", "uk", "ks", "sk",
		"sa", "as", "se", "es", "si", "is", "so", "os", "su", "us", "ss", "ss",
		"ra", "ar", "re", "er", "ri", "ir", "ro", "or", "ru", "ur", "rs", "sr",
		"a",  "a",  "e",  "e",  "i",  "i",  "o",  "o",  "u",  "u",  "s",  "s"
	)
	icon_state = "lizard"
	default_priority = 90


//Dronecore

/datum/language/drone
	name = "Drone"
	desc = "A heavily encoded damage control coordination stream, with special flags for hats."
	speech_verb = "chitters"
	ask_verb = "chitters inquisitively"
	exclaim_verb = "chitters loudly"
	spans = list(SPAN_ROBOT)
	key = "d"
	flags = NO_STUTTER
	syllables = list(".", "|")
	// ...|..||.||||.|.||.|.|.|||.|||
	space_chance = 0
	sentence_chance = 0
	default_priority = 20

	icon_state = "drone"

// The language of the Dwarves, based on Dwarf Fortress

/datum/language/dwarf
	name = "Dwarvish"
	desc = "The language of the dwarves"
	space_chance = 100 // Each 'syllable' is its own word
	key = "D"
	flags = TONGUELESS_SPEECH

	syllables = list("kulet", "alak", "bidok", "nicol", "anam", "gatal", "mabdug", "zustash", "sedil", "ustos", "emr", "izeg", "beming", "gost", "ntak", "tosid", "feb", "berim", "ibruk", "ermis", "thoth", "thatthil", "gistang", "libash", "lakish", "asdos", "roder", "nel", "biban", "ugog", "ish", "robek", "olmul", "nokzam", "emuth", "fer", "uvel", "dolush", "ag^k", "ucat", "ng rak", "enir", "ugath", "lisig", "etg", "erong", "osed", "lanlar", "udir", "tarmid", "s krith", "nural", "bugsud", "okag", "nazush", "nashon", "ftrid", "en''r", "dstik", "kogan", "ingish", "dudgoth", "stalk*b", "themor", "murak", "altth", "osod", "thcekut", "cog", "selsten", "egdoth", "othsin", "idek", "st", "suthmam", "im", "okab", "onlnl", "gasol", "tegir", "nam...sh", "noval", "shalig", "shin", "lek", ",,kim", "kfkdal", "stum,,m", "alud", "olom", "%lot", "rozsed", "thos", "okon", "n<ng", "ostar", "rorul", "kovath", "tblel", "stal", "girtol", "kit<g", "lokast", "reked", "comnith", "sidos", "setnek", "ethbesh", "nug", "mokez", "c''s", "idos", "ogcek", "utheg", "tilgil", "ebsas", "lurak", "tobul", "ilush", "d%nush", "rimtar", "kun", ",s", "kiror", "nicat", "onshen", "r%rith", "mafol", "sid", "ntdn", "tilat", "cetat", "egot", "dib", "oril", "bukog", "atot", "imik", "sudir", "odshith", "rag", "dodck", "sinsot", "es", "dostob", "gast", ",lmeth", "romlam", "av,d", "dartl", "fn", "oddom", "z,gel", "og", "shatag", "om", "gis%k", "balad", "nekik", "dakas", "dolek", "sog", "rafar", "laltur", "cekeng", "dan", "ozsit", "dunan", "uling", "dcebesh", "berath", "zangin", "shadkik", "innok", "vukcas", "metul", "than", "gesul", "ustir", "torish", "memrut", "usal", "''m", "angrir", "cagith", "momuz", "zas", "deshlir", "astesh", "''fid", "mothram", "rit", "nolthag", "matul", "irtir", "unul", "urist", "umom", "d%m", "lodel", "kodor", "alod", "n''kor", "asen", "rtsh", "ursas", "vakun", "thol", "kizbiz", "uthg£r", "''nor", "gar", "terstum", "zagith", "noshtath", "ub", "k", "amur", "minran", "idar", "rodnul", "nuggad", "okbod", "tun", "mtmgoz", "fak", "ogon", "r%mrit", "stidest", "zag", "kosak", "sub", "shegum", "addor", "talin", "zin", "tmmeb", "sakub", "tig", "edir", "tath", "vesh", "etest", "atir", "lors<th", "rir", "em", "deb", "shuthraz", "Sshgor", "rkal", "ac''b", "okir", "arngish", "zilir", "im", "<ssun", "ilus", "gedor", "ramtak", "sombith", "ker", "lcenem", "umid", "seth", "sogdol", "shis", "er", "odroz", "urem", "nist", "cdad", "lithrush", "zotir", "zikel", "zikfth", "stagshil", "at''l", "ck", "ziril", "uthar", "tatlosh", "ngitkar", "dur", "keshan", "ned", "eststek", "ar", "%tul", "ltluth", "totmon", "bem", "fenglel", "gigin", "atham", "amug", "cabnul", "nog", "fotthor", "nltang", "dumed", "geshud", "inglaz", ",zneth", "tiklom", "<sir", "eshim", "lumash", "gishdist", "thcedas", "enog", "dozeb", "muz", "fst", "dushig", "bakat", "shistat", "goral", "kSbmak", "inod", "zisur", "list", "olon", "%rtong", "ngotol", "kolad", "egen", "r£bal", "gintar", "figul", "fikod", "bebmal", "bavast", "kttdir", ",thes", "igest", "reg", "ubur", "belbez", "n*m", "bunsoth", "limul", "kurig", "ugzol", "erib", "cegam", "mas", "zugob", "mashus", "isin", "mond-l", "siz", "sar...m", "dal", "omer", "sumun", "gommuk", "usith", "nerrid", "z god", "mithmis", "enol", "munSst", "bol", "-z", "btl", "sitheb", "duthnur", "ilbtd", "rurast", "suton", "nuglush", "ulthush", "razes", "bist''k", "Szum", "nil", "nil", "otad", "oddet", "thetdel", "golud", "-d", "kadol", "lur", "dumur", "akn-n", "otel", "ser", "zanor", "ur", "bokbon", "Sfim", "shash", "zon", "obur", "banik", "seb<r", "lirlez", "erlin", "inen", "tmft", "goster", "kunon", "tarag", "kiron", "lilum", "oggez", "bom", "stet r", "sikel", "unnos", "kisul", "ikus", "sheget", "famthut", "rorung", "idor", "enur", "kur", "fok sh", "vostaz", "ushil", "gumr", "ular", "enen", "goshcest", "fzkob", "meb", "likot", "st%tnin", "zarut", "nelzur", "datan", "tabmik", "rinal", "ebgok", "soshosh", "bukshon", "stcegil", "lumen", "maton", "abol", "cim", "egath", "imketh", "ilned", "zuden", "emtan", "ed%m", "noscem", "vag£sh", "alis", "etar", "inshot", "zasit", "arzes", ",bor", "oth", "vakist", "ner", "bul", "nddor", "onam", "ulol", "toral", "omoth", "erar", "govos", "orab", "dalkam", "subol", "gomath", "cerol", "mingkil", "detthost", "rerik", "lolor", "os", "istam", "giken", "od", "mengmad", "fmid", "bungek", "zedot", "thak", "tetcth", "romek", "utir", "<lul", "uleng", "sosmil", "aval", "lush*b", "asin", "vunom", "vurtib", "gukil", "dimol", "lelgas", "nethg''n", "itur", "avan", "mingus", "aroth", "udos", "imust", "sh...mman", "rinmol", "muzish", "k''n", "stul", "thash", "kenis", "fathkal", "inob", "igril", "an", "unob", "nalthish", "ost%sh", "kel", "eddaz", "ekur", "arfl", "shar", "rimuk", "ottan", "shagul", "*nul", "egeth", "s''d", "dusak", "ovus", "gom*k", "stesok", "vanktb", "<lon", "od^s", "alen", "bobrur", "stoling", "dum", "zagstok", "ol", "gatis", "udler", "adesh", "usfn", "kavud", "kirun", "shasad", "shoveth", "lathon", "um", "thubil", "egom", "ugith", "ngutug", "kez", "l,rim", "ik-l", "semtom", "kib", "rotik", "ir", "stos^th", "kezol", "anan", "disuth", "rcethol", "tezul", "irol", "otam", "rod<m", "nunok", "umel", "ishlum", "kin", "mebzuth", "usib", "nar", "migrur", "egar", "dakon", "lod", "nir", "an''n", "muved", "am", "vab''k", " g", "ritas", "udril", "shigcs", "d thnes", "fgez", "m''rul", "zulash", "logem", "abal", "kulin", "lerom", "gatin", "ul", "monom", "biscl", "ginok", "rumred", "ugeth", "thuveg", "gor", "damol", "elcur", "erok", "tok", "cem", "rSt", "shoner", "inrus", "mist^m", "midor", "nilgin", "merir", "nikuz", "kamuk", "enal", "zSler", "stibbom", "vildang", "arkoth", "lash%d", "kasith", "ngathsesh", "tashem", "besmar", "furgig", "n''nub", "rushrul", "megob", "uvir", "shrir", "esrel", "bukSt", "nimak", "lestus", "fullut", "arkim", "imsal", "led", "unib", "ron", "udar", "borush", "detes", "umoz", "serkib", "vudthar", "razot", "atem", "ezuk", "vozbel", "toltot", "n,r", "stukos", "ang", "nuden", "ikud", "memad", "eshik", "emgash", "tirist", "athel", "seng", "osdin", "ethram", "kamut", "locun", "selor", "ig%r", "id", "astts", "fbir", "mosus", "omthel", "odur", "istbar", "zodost", "dumat", "relon", "notlith", "suthtn", "ilid", "tithleth", "kezar", "ast", "fath", "t''l£n", "nabid", "sibrek", "thining", "gasns", "noglesh", "aroz", "tfmol", "nanul", "urr<th", "kik%s", "askak", "kes", "abshoth", "ubas", "angish", "allas", "gembish", "urvad", "fel", "ingul", "nekut", "genlath", "shulmik", "lenod", "abras", "asol", "shethel", "urn-t", "zursul", "othsal", "shedim", "arak", "tiz''t", "taran", "bithit", "otik", "kerlceg", "l^ned", "sodel", "''nam", "zuglar", "keskal", "ntst", "uvcth", "mcevid", ",th", "kaffsh", "ngumrash", "zokun", "eshom", "nesteth", "thebil", "ammesh", "ral", "reksas", "gesis", "osal", "anir", "nabreth", "dak,l", "rungak", "nekol", "anriz", "kosh", "noth", "tharnas", "gansit", "b...goz", "bim", "themthir", "sakil", "tekmok", "rasuk", "g,zot", "toz''r", "tob", "kal", "eshtfn", "mezum", "umar", "zeber", "geles", "therleth", "tinan", "zekrim", "magel", "adur", "ezar", "bonun", "b-nem", "egur", "unol", "vod", "lal", "debish", "bushos", "lokum", "thortith", "omft", "sethal", "soshor", "thocit", "esesh", "l-rit", "ubal", "*stob", "lashid", "usur", "kob", "kigok", "bekom", "magak", "v%s", "estrith", "gongith", "dugud", "zat", "nomal", "oltud", "savot", "vcer", "dustcek", "shnstsak", "risid", "deler", "aztong", "g<non", "sholil", "ecut", "m%tin", "lam", "togal", "mot", "nceles", "nefast", "atith", "r^g", "emen", ",kig", "abod", "sat", "timad", "ibas", "othob", "f-beg", "tunur", "idgag", "eb", "omshit", "ibes", "oceg", "akuth", "isram", "ad", "imgoz", "nis", "stot", "''gred", "sined", "tec...k", "subet", "urmim", "obash", "dastot", "udib", "enkos", "kesh", "kidet", "ob", "thils,g", "asteb", "akmesh", "vim", "angzak", "gakit", "r%cus", "kurik", "unkil", "mez", "erith", "kalur", "arros", "amud", "nobgost", "tan", "l<d", "ashok", "nod", "nin", "rakust", "melbil", "nol", "raz", "dostust", "tat", "st<vut", "sigun", "urdim", "k,l n", "shelret", "<ggal", "r%dreg", "idr,th", "datlad", "ilral", "borik", "meden", "vafig", "tizen", "dizesh", "kobem", "cavor", "shilr...r", "segun", "messog", "bukith", "bufut", "nilim", "ingtak", "damor", "gim", "nob", "eknar", "mengib", "isrir", "ish%m", "ticek", "mer", "othfsh", "k''kdath", "distat", "nirur", "kiret", "thisrid", "vucar", "kizab", "tudrug", "s^gam", "amluth", "nozush", "mirstal", "zamoth", "bomik", "munsog", "razmer", "liruk", "geget", "zenon", "okol", "torir", "stodir", "''ggon", "tikis", "unos", "legon", "alnis", "<kor", "tathtak", "lidod", "azin", "isden", "uker", "kussad", "nilun", "bamg-s", "adril", "koshmot", "fl", "umgush", "senel", "sital", "kil", "kol", "bomrek", "boket", "atil", "iklist", "volal", "lish", "omrist", "ud", "fesh", "akath", "lim", "damced", "anur", "kulal", "lolum", "ducim", "vesrul", "urosh", "akith", "l^rush", "ethir", "ced", "budam", "inol", "okang", "ging", "rilem", "kizest", "keb''sh", "shesam", "ber", "zan", "zust", "enshal", "nastid", "ultSr", "ag", "zareth", "tislam", "doren", "rcth", "ntzom", "akrul", "gusil", "kilrud", "lolok", "lemlor", "ivom", "fikuk", "gulgun", "kast", "usir", "sodzul", "st*k<d", "etas", "otil", "sosad", "n<r", "anban", "dithbish", "ekir", "onol", "godum", "lcelar", "ib", "etur", "rithul", "cboth", "al", "zimkel", "bimmon", ",kil", "tezad", "lfven", "sashas", "sezuk", "saneb", "kik", "dasnast", "it^g", "okil", "esis", "buris", "ecem", "kekath", "nas", "nursher", "limfr", "sostet", "ken", "estil", "oram", "galthor", "nefek", "gabet", "idok", "tetthush", "ukath", "igang", "ushul", "sil", "kar", "thur", "nitom", "azzin", "selen", "gadan", "osor", "thalal", "onesh", "guz", "^sik", "thestar", "astis", "''tthat", "lisid", "nalish", "ozor", "ceshfot", "dok", "edos", "anzish", "l-k", "semor", "multsh", "fm", "kutam", "eges", "fimshel", "egul", "tesum", "cubor", "enseb", "idith", "edim", "vetek", "g,rig", "lecad", "sterus", "umtm", "anil", "nobang", "at^sh", "umril", "milol", "rig*th", "Srith", "thazor", "gashcoz", "bor", "f''ker", "megid", "elik", "tekkud", "olin", "nrlom", "stemel", "inem", "lulfr", "zolak", "g,rem", "gidur", "aban", "neb<n", "zasgim", "thclthod", "iden", "''ssek", "amkol", "l''bor", "shrrat", "k^dnath", "titthal", "stistr,s", "tetist", "riras", "t''ras", "gekur", "gudos", "durad", "z^vut", "adil", "ngesg,s", "stettad", "shos^l", "udil", "litast", "arel", "otin", "vel", "avuz", "rithlut", "tomus", "dugan", "kalal", "shoshin", "eser", "cebmat", "kebul", "asiz", "alm''sh", "rur", "rutod", "vumom", "orrun", "taron", "s rek", "ugosh", "esmul", "kisat", "il", "rinul", "mukar", "amkin", "mosos", "rith", "t*m", "bugud", "otung", "zoz", "umshad", "das%l", "lames", "lavath", "ozur", "zotthol", "nan", "rorash", "nguteg", "''sust", "um,m", "instol", "kesting", "ebbus", "bobet", "ong", "zokgen", "r,duk", "zunek", "kezat", "kad,n", "sar", "^lbem", "ertal", "rfmol", "girust", "nabas", "lozlok", "ongos", "shusug", "tongus", "tustzal", "kgneb", "gamil", "gingim", "arin", "gov-l", "vetor", "sharsid", "nakis", "lanir", "ikl", "nakbab", "nimem", "numol", "urol", "atul", "deg", "onul", ",gash", "bogsosh", "ushang", "emal", "ethzuth", "gathil", "kebon", "sutung", "nizdast", "mimkot", "vir", "tumam", "osstam", "kulsim", "gemis", "^r", "fenok", "igrish", "urus", "rodem", "zengod", "ister", "luskal", "knrar", "ilas", "an-z", "angen", "desis", "damSl", "assog", "usen", "babin", "tustem", "debben", "kabat", "ftast", "ebal", "lanzil", "belar", "solam", "cr", "nucam", "letom", "mengthul", "th^mnol", "lin*n", "vuthil", "rerscer", "oltar", "domas", "asmel", "nish", "mamot", "nakuth", "udist", "ost", "shadust", "morus", "akrel", "kith", "bomel", "orngim", "ngubmul", "mat", "nulom", "ustan", "buzat", "thob", "tilesh", "gecast", "aran", "st%lmith", "dolil", "amem", "kasben", "fashuk", "-bom", "mostod", "mangr*d", "keng", "odkish", "roduk", "eggut", "bumal", "kurel", "kithnn", "nurom", "shomad", "doshet", "ltl", "lun", "kugik", "tulon", "zoden", "nang^s", "rifot", "kastar", "zefon", "kovest", "madush", "ttrem", "shSrel", "goden", "birut", "shorast", "meng", "olthez", "litez", "miz^s", "nonshut", "ltrul", "tusung", "ullung", "minbaz", "zethruk", "k-buk", "kivish", "rithog", "rabed", "rusest", "omtug", "stektob", "zimun", "num", "oslan", "mis", "salul", "langgud", "mugshith", "l*r", "mishthem", "sibnir", "zansong", "or", "est", "thistus", "bot", "aned", "absam", "vuzded", "emet", "luzat", "duthal", "cugshil", "shasar", "emdush", "shungmag", "zar", "luror", "manthul", "sholkik", "sankest", "othud", "ngithol", "udesh", "afen", "dast", "nothis", "cem,z", "sosh", "zalud", "geth", "udiz", "nitig", "ziksis", "midrim", "urthaz", "vuknud", "s<sal", "thum", "ar''sh", "guthstak", "as%n", "neshast", "tenshed", "catten", "l^gan", "...lil", "nukad", "rakas", "bibar", "nitem", "vanel", "som", "gutid", "ros", "sestan", "ganad", "ardes", "tobot", "niral", "zavaz", "tellist", "umgan", "kesham", "azmol", "thokdeg", "dolok", "detgash", "zocuk", "gulnas", "arek", "rath", "ngot-n", "zocol", "evost", "lotol", "farash", "ruken", "enas", "isul", "miroth", "mor", ",srath", "shed", "tabar", "lush-t", "tm", "sut", "saruth", ",rged", "aral", "solon", "zulban", "stan<r", "lorbam", "stkzul", "kat", "teskom", "r,m", "koshosh", "moldath", "-losh", "k£d", "masos", "fastam", "isan", "betan", "thibam", "elol", "uvar", "rul", "zaled", "esar", "k...s", "znzcun", "vathem", "m<shak", "dubmen", "akam", "osram", "kuthd^ng", "assar", "shizek", "mingtuth", "rafum", "omet", "merseth", "cs", "itnet", "g<sstir", "dalem", "<dath", "gemsit", "ashzos", "enten", "nomes", "birir", "kukon", "fgoth", " gesh", "dalzat", "tad", "m%list", "ison", "rokel", "arceth", "rimad", "shigin", "kastol", "ruzos", "sharul", "omt,l", "eren", "sobnr", "noram", "dSg", "neth", "okin", "maskir", "dugal", "shagog", "shazak", "tin''th", "thir", "necak", "ital", "nulral", "nnal", "gomcm", "vumshar", "borlon", "ngobol", "gireth", "okun", "rovol", "thulom", "kanzud", "l*rtm", "rosat", "ottem", "duthtish", "thestkig", "thabost", "v£sh", "cugg n", "obok", "muthir", "rovod", "uzar", "kor", "amas", "ashm''n", "bisek", "zaneg", "gcsmer", "zimesh", "bothon", "losis", "ildom", "azuz", "golast", "edn...d", "evon", "arom", "ninur", "conngim", "fongbez", "arrug", "av-sh", "rimis", "thokit", "agseth", "sharast", "bardum", "givel", "tm", "nikot", "arist", "sheced", "stin", "zoluth", "mestthos", "ineth", "amost", "oklit", "deduk", "m-thkat", "kosoth", "cegbit", "oshgft", "tazuk", "imbit", "b%r-l", "sarvesh", "zuntcer", "sazir", "ekast", "desgir", "stfkud", "gonggash", "uzol", "moshn£n", "urir", "geshak", "lektad", "akir", "zalns", "teshkad", "kudust", "sastres", "becor", "nob''t", "tokthat", "gishgil", "lfndar", "karas", "etom", "thomal", "emad", "tangath", "ezost", "vath", "zakgol", "stibmer", "mnshos", "teling", "lased", "rintor", "cestlig", "tcerdug", "bab", "stingbol", "gethust", "maram", "nid*st", "bashnom", "ekzong", "thusest", "bocash", "dedros", "akur", "cecum", "etvuth", "t''mud", "datur", "tishis", "lir", "dard", "nugreth", "zim", "avum", "ishash", "tel", "ilrom", "unfl", "cilob", "<ngiz", "dakost", "kobel", "sheshek", "tolis", "gothum", "adek", "ibel", "lesast", ",tol", "adas", "custith", "minkot", "ceton", "sholSb", "deg%l", "uvash", "kumil", "fidgam", "lar", "stinth,d", "kemsor", "onrel", "sefol", "edzul", "nisgak", "dotir", "k...lreth", "alek", "resil", "umstiz", "k^shshak", "sirab", "shaketh", "tatek", "isos", "occeg", "atzul", "sebs£r", "odom", "arust", "g''tom", "sulus", "lensham", "geb", "ozon", "ngegdol", "storlut", "bekar", "gan", "zamnuth", "edt-l", "nol^th", "thabum", "astod", "ruth''sh", "lisat", "zagug", "gudas", "sesh", "osh,b", "olil", "ustuth", "tholtig", "medtob", "asob", "gtk<z", "shem", "nadak", "nirmek", "imush", "kogsak", "<teb", "dceshmab", "atces", "t''sed", "kikrost", "ngal k", "takth", "nunr", "vukrig", "rerras", "ar''l", "sosas", "r-l", "tholest", "tishak", "tharith", "vutram", "shotom", "<lun", "rfluk", "vosut", "s-bil", "ifin", "okosh", "zafal", "rulush", "gikut", "rem", "thikthog", "idash", "tathtat", "mesir", "lir,r", "celkeb", "adag", "isak", "kekim", "bfsen", "koman", "imesh", "shetb^th", "ultb", "dogik", "rodim", "kathil", "''ndin", "mekur", "enoz", "satneng", "rotig", "sof-sh", "asrer", "ozleb", "etath", "rumad", "es,st", "suvas", "bal", "oshot", "stelid", "med", "inir", "scebosh", "lunrud", "olum", "shuk", "''ler", "stizash", "gusgash", "<tsas", "edan", "ked", "ungSg", "merrang", "gudid", "kashez", "amal", "athncer", "shithath", "istik", "akmam", "timn,r", "elis", "kan", "lelum", "othil", "oth''s", "nentuk", "dural", "salir", "kulbet", "fazis", "thik,n", "-lmush", "mishar", "tastrod", "tod''r", "ostath", "thasdoth", "belal", "ston", "ribar", "tunom", "kudar", "g,bar", "nothok", "libad", "gemur", "elbel", "ennol", "amnek", "soloz", "mus''d", "samam", "ethad", "eshon", "etcm", "Srnam", "kethil", "enam", "inush", "atol", "''sir", "vathez", "fur...t", "kegeth", "cud<st", "laz", "kttfk", "thedak", "lumnum", "''sed", "orshar", "thad", "shan", "ellest", "odg£b", "inash", "steg%th", "zithis", "lerteth", "stistmig", "luslem", "sherik", "zukthist", "artob", "n%las", "zes", "n^cik", "-thir", "othlest", "ibesh", "fash", "anist", "*rdir", "rab", "orshet", "uzlir", "ginet", "eral", "ilash", "etn...r", "tom^m", "ins,l", "riril", "thimshur", "nokgol", "m''zir", "igath", "gasir", "bubnus", "<thod", "uthmik", "uben", "adbok", "ronush", "rikkir", "thiz", "lak...l", "r''ber", "egast", "akgos", "zatam", "sholid", "akest", "thun", "gidthur", "immast", "sanreb", "m<kstal", "vudnis", "estun", "ozkak", "tkum", "kacoth", "etost", "arban", "kurol", "agsal", "rethal", "oshur", "vathsith", "biths^st", "kezkig", "kir", "shadmal", " dol", "ablish", "shislug", "zutshosh", "ogtum", "bat''k", "izkil", "ireg", "ushlub", "deleth", "thetust", "stigaz", "ethab", "em,th", "konad", "shukar", "idrom", "gubel", "egeb", "astel", "boshut", "uzan", "ranzar", "rcesen", "nakas", "gatiz", "erush", "shameb", "ushesh", "katthir", "ikthag", "rnthar", "sizir", "tost", "al-th", "ator", "kad''l", "istrath", "shos", "ulzest", "kastaz", "kod", "etes", "nosing", "merig", "fushur", "avog", "oth''r", "midil", "fevil", "itt s", "bakust", "b%mbul", "duz", "zeg", "edcl", "kifed", "thet", "ostuk", "endok", "ushat", "ukosh", "lebes", "lim£r", "cd", "desor", "amith", "ilir", "ishol", "otsus", "mogshum", "ishen", "kiddir", "meban", "g£r", "rodum", "monang", "thosbut", "at^k", "edod", "astan", "tangak", "sacat", "d''bar", "komut", "dimshas", "olnen", "tathur", "evud", "oshosh", "orstist", "kab", "talul", "sokan", "nanir", "irid", "t''gum", "asd-g", "mes", "nasod", "lemis", "stukcn", "nanoth", "kokeb", "cruk", "zursl", "mozib", "gorroth", "egsttk", "as...s", "zalstom", "ikal", "esdor", "rilbet", "dezrem", "sebshos", "neb,l", "gethor", "ralfth", "baros", "iseth", "cen,th", "leshal", "san d", "rithzfm", "kordam", "roldeth", "ugut", "arbost", "sedish", "tadar", "azoth", "osresh", "eddud", "artum", "dallith", "siknug", "vashzud", "ngilok", "ilon", "nlud", "gemesh", "rashgur", "mothdast", "d k", "thukkan", "alron", "ung*b", "£tost", "bel", "sanus", "kith,l", "theb", "konos", "neb", "itred", "ecosh", "cegol", "luthoz", "thastith", "remang", "athser", "ngusham", "gingik", "rangab", "kontuth", "letmos", "mishim", "losush", "othbem", "b^ngeng", "lasgan", "utal", "sedur", "engig", "sunggor", "thistun", "k''shdes", "ngefel", "umer", "uleb", "n shas", "r''mab", "sezom", "shashdon", "m%bnith", "k n", "gitnuk", "daros", "nokim", "mostib", "thethrus", "kagmel", "bidnoz", "elbost", "oten", "ushdish", "kitung", "nubam", "onget", "d%ngstam", "nimar", "gelut", "nis-n", "tarem", "nam", "kozoth", "tokmek", "ed", "et", "thunen", "shokmug", "vutok", "zanos", "torad", "berdan", "nal", "mosol", "othduk", "kinem", "zatthud", "nabtr", "rirn''l", "lised", "danman", "nirk£n", "mubun")

	default_priority = 90
	icon_state = "dwarf"


//Machine

/datum/language/machine
	name = "Encoded Audio Language"
	desc = "An efficient language of encoded tones developed by synthetics and cyborgs."
	speech_verb = "whistles"
	ask_verb = "chirps"
	exclaim_verb = "whistles loudly"
	spans = list(SPAN_ROBOT)
	key = "6"
	flags = NO_STUTTER
	syllables = list("beep","beep","beep","beep","beep","boop","boop","boop","bop","bop","dee","dee","doo","doo","hiss","hss","buzz","buzz","bzz","ksssh","keey","wurr","wahh","tzzz")
	space_chance = 10
	default_priority = 90

	icon_state = "eal"

/datum/language/machine/get_random_name()
	if(prob(70))
		return "[pick(GLOB.posibrain_names)]-[rand(100, 999)]"
	return pick(GLOB.ai_names)

//Monkeee

/datum/language/monkey
	name = "Chimpanzee"
	desc = "Ook ook ook."
	speech_verb = "chimpers"
	ask_verb = "chimpers"
	exclaim_verb = "screeches"
	key = "1"
	space_chance = 100
	syllables = list("oop", "aak", "chee", "eek")
	default_priority = 80

	icon_state = "animal"

//Shroom

/datum/language/mushroom
	name = "Mushroom"
	desc = "A language that consists of the sound of periodic gusts of spore-filled air being released."
	speech_verb = "puffs"
	ask_verb = "puffs inquisitively"
	exclaim_verb = "poofs loudly"
	whisper_verb = "puffs quietly"
	key = "y"
	sentence_chance = 0
	default_priority = 80
	syllables = list("poof", "pff", "pFfF", "piff", "puff", "pooof", "pfffff", "piffpiff", "puffpuff", "poofpoof", "pifpafpofpuf")

//Cultist

/datum/language/narsie
	name = "Nar'Sian"
	desc = "The ancient, blood-soaked, impossibly complex language of Nar'Sian cultists."
	speech_verb = "intones"
	ask_verb = "inquires"
	exclaim_verb = "invokes"
	key = "n"
	sentence_chance = 8
	space_chance = 95 //very high due to the potential length of each syllable
	var/static/list/base_syllables = list(
		"h", "v", "c", "e", "g", "d", "r", "n", "h", "o", "p",
		"ra", "so", "at", "il", "ta", "gh", "sh", "ya", "te", "sh", "ol", "ma", "om", "ig", "ni", "in",
		"sha", "mir", "sas", "mah", "zar", "tok", "lyr", "nqa", "nap", "olt", "val", "qha",
		"fwe", "ath", "yro", "eth", "gal", "gib", "bar", "jin", "kla", "atu", "kal", "lig",
		"yoka", "drak", "loso", "arta", "weyh", "ines", "toth", "fara", "amar", "nyag", "eske", "reth", "dedo", "btoh", "nikt", "neth",
		"kanas", "garis", "uloft", "tarat", "khari", "thnor", "rekka", "ragga", "rfikk", "harfr", "andid", "ethra", "dedol", "totum",
		"ntrath", "keriam"
	) //the list of syllables we'll combine with itself to get a larger list of syllables
	syllables = list(
		"sha", "mir", "sas", "mah", "hra", "zar", "tok", "lyr", "nqa", "nap", "olt", "val",
		"yam", "qha", "fel", "det", "fwe", "mah", "erl", "ath", "yro", "eth", "gal", "mud",
		"gib", "bar", "tea", "fuu", "jin", "kla", "atu", "kal", "lig",
		"yoka", "drak", "loso", "arta", "weyh", "ines", "toth", "fara", "amar", "nyag", "eske", "reth", "dedo", "btoh", "nikt", "neth", "abis",
		"kanas", "garis", "uloft", "tarat", "khari", "thnor", "rekka", "ragga", "rfikk", "harfr", "andid", "ethra", "dedol", "totum",
		"verbot", "pleggh", "ntrath", "barhah", "pasnar", "keriam", "usinar", "savrae", "amutan", "tannin", "remium", "barada",
		"forbici"
	) //the base syllables, which include a few rare ones that won't appear in the mixed syllables
	icon_state = "narsie"
	default_priority = 10

/datum/language/narsie/New()
	for(var/syllable in base_syllables) //we only do this once, since there's only ever a single one of each language datum.
		for(var/target_syllable in base_syllables)
			if(syllable != target_syllable) //don't combine with yourself
				if(length(syllable) + length(target_syllable) > 8) //if the resulting syllable would be very long, don't put anything between it
					syllables += "[syllable][target_syllable]"
				else if(prob(80)) //we'll be minutely different each round.
					syllables += "[syllable]'[target_syllable]"
				else if(prob(25)) //5% chance of - instead of '
					syllables += "[syllable]-[target_syllable]"
				else //15% chance of no ' or - at all
					syllables += "[syllable][target_syllable]"
	..()

//Ratvarian 

/datum/language/ratvar
	name = "Ratvarian"
	desc = "A timeless language full of power and incomprehensible to the unenlightened."
	var/static/random_speech_verbs = list("clanks", "clinks", "clunks", "clangs")
	ask_verb = "requests"
	exclaim_verb = "proclaims"
	whisper_verb = "imparts"
	key = "r"
	default_priority = 10
	spans = list(SPAN_ROBOT)
	icon_state = "ratvar"

/datum/language/ratvar/scramble(input)
	. = text2ratvar(input)

/datum/language/ratvar/get_spoken_verb(msg_end)
	if(!msg_end)
		return pick(random_speech_verbs)
	return ..()

//Big Slime

/datum/language/slime
	name = "Slime"
	desc = "A melodic and complex language spoken by slimes. Some of the notes are inaudible to humans."
	speech_verb = "warbles"
	ask_verb = "warbles"
	exclaim_verb = "warbles"
	key = "k"
	flags = TONGUELESS_SPEECH
	syllables = list("qr","qrr","xuq","qil","quum","xuqm","vol","xrim","zaoo","qu-uu","qix","qoo","zix","*","!")
	default_priority = 70

	icon_state = "slime"

//Swarmers
/datum/language/swarmer
	name = "Swarmer"
	desc = "A language only consisting of musical notes."
	speech_verb = "tones"
	ask_verb = "tones inquisitively"
	exclaim_verb = "tones loudly"
	spans = list(SPAN_ROBOT)
	key = "s"
	flags = NO_STUTTER
	space_chance = 100
	sentence_chance = 0
	default_priority = 60

	icon_state = "swarmer"

	// since various flats and sharps are the same,
	// all non-accidental notes are doubled in the list
	/* The list with unicode symbols for the accents.
	syllables = list(
					"C", "C",
					"C♯", "D♭",
					"D", "D",
					"D♯", "E♭",
					"E", "E",
					"F", "F",
					"F♯", "G♭",
					"G", "G",
					"G♯", "A♭",
					"A", "A",
					"A♯", "B♭",
					"B", "B")
	*/
	syllables = list(
					"C", "C",
					"C#", "Db",
					"D", "D",
					"D#", "Eb",
					"E", "E",
					"F", "F",
					"F#", "Gb",
					"G", "G",
					"G#", "Ab",
					"A", "A",
					"A#", "Bb",
					"B", "B")

// The language of the vinebings. Yes, it's a shameless ripoff of elvish.
/datum/language/sylvan
	name = "Sylvan"
	desc = "A complicated, ancient language spoken by vine like beings."
	speech_verb = "expresses"
	ask_verb = "inquires"
	exclaim_verb = "declares"
	key = "h"
	space_chance = 20
	syllables = list(
		"fii", "sii", "rii", "rel", "maa", "ala", "san", "tol", "tok", "dia", "eres",
		"fal", "tis", "bis", "qel", "aras", "losk", "rasa", "eob", "hil", "tanl", "aere",
		"fer", "bal", "pii", "dala", "ban", "foe", "doa", "cii", "uis", "mel", "wex",
		"incas", "int", "elc", "ent", "aws", "qip", "nas", "vil", "jens", "dila", "fa",
		"la", "re", "do", "ji", "ae", "so", "qe", "ce", "na", "mo", "ha", "yu"
	)
	icon_state = "plant"
	default_priority = 90

//	BLOODSUCKER LANGUAGE //

/datum/language/vampiric
	name = "Blah-Sucker"
	desc = "The native language of the Bloodsucker elders, learned intuitively by Fledglings and as they pass from death into immortality. Thralls are also given the ability to speak this as apart of their conversion ritual."
	speech_verb = "growls"
	ask_verb = "growls"
	exclaim_verb = "snarls"
	whisper_verb = "hisses"
	key = "b"
	space_chance = 40
	default_priority = 90
	icon_state = "bloodsucker"

	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD // Hide the icon next to your text if someone doesn't know this language.
	syllables = list(
		"luk","cha","no","kra","pru","chi","busi","tam","pol","spu","och",		// Start: Vampiric
		"umf","ora","stu","si","ri","li","ka","red","ani","lup","ala","pro",
		"to","siz","nu","pra","ga","ump","ort","a","ya","yach","tu","lit",
		"wa","mabo","mati","anta","tat","tana","prol",
		"tsa","si","tra","te","ele","fa","inz",									// Start: Romanian
		"nza","est","sti","ra","pral","tsu","ago","esch","chi","kys","praz",	// Start: Custom
		"froz","etz","tzil",
		"t'","k'","t'","k'","th'","tz'"
		)

// One of these languages will actually work, I'm certain of it.

/datum/language/voltaic
	name = "Voltaic"
	desc = "A sparky language made by manipulating electrical discharge."
	key = "v"
	space_chance = 20
	syllables = list(
		"bzzt", "skrrt", "zzp", "mmm", "hzz", "tk", "shz", "k", "z",
		"bzt", "zzt", "skzt", "skzz", "hmmt", "zrrt", "hzzt", "hz",
		"vzt", "zt", "vz", "zip", "tzp", "lzzt", "dzzt", "zdt", "kzt",
		"zzzz", "mzz"
	)
	icon_state = "volt"
	default_priority = 90

//Xeno

/datum/language/xenocommon
	name = "Xenomorph"
	desc = "The common tongue of the xenomorphs."
	speech_verb = "hisses"
	ask_verb = "hisses"
	exclaim_verb = "hisses"
	key = "4"
	syllables = list("sss","sSs","SSS")
	default_priority = 50

	icon_state = "xeno"

// ============================================================
// WORD LISTS FOR TERMINAL HACKING BY DIFFICULTY
// ============================================================

// 4-letter words (Very Easy)
var/global/list/HACK_WORDS_4 = list(
	"ATOM","BUNK","CAPS","DART","ECHO","FUSE","GLOW","HACK",
	"IRON","JUNK","KERN","LOOT","MOLE","NUKE","OPEN","PERK",
	"QUIZ","RUST","SAFE","TUBE","UNIT","VENT","WATT","XRAY",
	"YARD","ZERO","ACID","BOLT","CHIP","DEAD","FIRE","GORE",
	"HIVE","IDOL","JADE","KILL","LAMP","MIRE","NODE","ORAL"
)

// 5-letter words (Easy)
var/global/list/HACK_WORDS_5 = list(
	"ALARM","BLEED","CRATE","DRONE","EMBER","FLARE","GHOUL","HAVOC",
	"IDEAL","JADED","KARMA","LASER","MUTIE","NINJA","OPTIC","PINCH",
	"QUOTA","RADON","SIREN","TURBO","ULTRA","VAULT","WASTE","XENON",
	"YIELD","ZONED","AMMO ","BRACE","CRAFT","DECAY","EXILE","FORGE",
	"GUARD","HAUNT","INGOT","JUICE","KNEEL","LANCE","METRO","NERVE"
)

// 6-letter words (Average)
var/global/list/HACK_WORDS_6 = list(
	"ATOMIC","BANDIT","CAPPED","DEACON","ENERGY","FUSION","GHETTO","HUNTER",
	"INMATE","JOCKEY","KILOTON","LAUNCH","MIASMA","NAPALM","OUTLAW","PISTOL",
	"QUARTZ","RADIUM","SENTRY","TURRET","UNDEAD","VENDOR","WANTED","XENIAL",
	"ZEALOT","AMBUSH","BLIGHT","CINDER","DUSTER","FAMINE","GAMBLE","HAVENS",
	"INTAKE","JACKAL","KETTLE","LETHAL","MUTANT","NOODLE","OFFSET","PLASMA"
)

// 8-letter words (Hard)
var/global/list/HACK_WORDS_8 = list(
	"ATOMFALL","BUNKERED","CAPSTONE","DEADZONE","ELECTRON","FIREBOMB",
	"GREYZONE","HALFLIFE","INFRARED","JUNKYARD","KILOWATT","LOCKDOWN",
	"MUTATION","NUKEFALL","OVERLOAD","PARTISAN","QUANTIZE","RADIATED",
	"SENTINEL","TERMINAL","ULTERIOR","VAULTBOY","WASTEFUL","XELERANT",
	"ZEROZONE","ABERRANT","BLACKOUT","CHEMICAL","DESERTER","ENDURING"
)

// 10-letter words (Very Hard)
var/global/list/HACK_WORDS_10 = list(
	"ABANDONWARE","BIOHAZARDLY","CONTAINMENT","DEADLOCKKEY","ENCLAVECODE",
	"FALLOUTZONE","GROUNDZEROS","HACKTHROUGH","IRRADIATION","JUNKPILEWAR",
	"KINETICALLY","LIQUIDATION","MILITIABASE","NEUTRALIZED","OUTCASTZONE",
	"PRIVATEERCO","QUARANTINED","RADIOACTIVE","SURVIVALIST","TURRETFIELD",
	"UNDERGROUND","VAULTDWELLR","WASTECRAFTER","XENOBIOLOGIC","ZEROTOLERAN"
)

// Junk characters for hex column padding
var/global/list/HACK_JUNK_CHARS = list(
	"!","@","#","$","%","^","&","*","=","+","-","_",
	"|","\\","/","?","~","`",":",";","'","\"",",","."
)

// Column rendering constants (lore-accurate Fallout layout)
// Words displayed spaced: "UNDEAD" -> "U N D E A D"
// Brackets also spaced: "{ : ^ }" - junk padding compensates for visual width
#define HACK_COLS 12  // Characters per line (excluding hex address)
#define HACK_ROWS 16  // Number of rows per column

// ============================================================

// ============================================================
// DOCUMENT DATUM SYSTEM
// ============================================================

/datum/terminal_document
	var/title = ""
	var/content = ""

// ============================================================

/obj/machinery/computer/terminal
	name = "desktop terminal"
	desc = "A RobCo Industries terminal, widely available for commercial and private use before the war."
	icon_state = "terminal"
	icon_keyboard = "terminal_key"
	icon_screen = "terminal_on_alt"
	connectable = FALSE
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/robco_terminal
	var/broken = FALSE // Used for pre-broken terminals
	var/prog_notekeeper = TRUE // Almost all consoles have the word processor installed, but we can remove it if we want to
	var/termtag = "Home" // We use this for flavor.
	var/termnumber = null // Flavor
	var/mode = 0 // What page we're on. 0 is the main menu.

// Document variables
	var/doc_title_1 = "readme"
	var/doc_content_1 = ""
	var/doc_title_2 = ""
	var/doc_content_2 = ""
	var/doc_title_3 = ""
	var/doc_content_3 = ""
	var/doc_title_4 = ""
	var/doc_content_4 = ""
	var/doc_title_5 = ""
	var/doc_content_5 = ""
	var/loaded_title = ""
	var/loaded_content = ""
	var/list/terminal_documents = null  // New datum-based document system

// Notekeeper vars
	var/notehtml = ""
	var/note = "ERR://null-data #236XF51"

// Hacking vars with SPECIAL integration
	var/locked              = FALSE    // Is this terminal password-locked?
	var/hack_difficulty     = 2        // 0–4 (Very Easy to Very Hard)
	var/hack_solved         = FALSE    // TRUE = successfully hacked
	var/hack_locked_out     = FALSE    // TRUE = too many failures, terminal locked
	var/hack_answer         = ""       // The correct word (chosen at runtime)
	var/list/hack_words     = null     // All displayed words this session
	var/list/hack_duds      = null     // Words that are still removable as duds
	var/list/hack_removed   = null     // Words that have been removed (for strikethrough display)
	var/list/hack_history   = null     // Stores guess feedback
	var/hack_attempts       = 4        // Attempts remaining
	var/hack_max            = 4        // Max attempts for this difficulty (set from INT)
	var/hack_dud_charges    = 2        // How many [REMOVE DUD] uses remain (from INT)
	var/hack_refill_charges = 1        // How many [REPLENISH TRIES] uses remain (from INT)
	var/on_hack_success     = null     // Optional: proc path to call on success

/obj/machinery/computer/terminal/Initialize()
	. = ..()

	if(!broken)
		desc = "[initial(desc)] Remarkably, it still works."
		termnumber = rand(69,420) // Unlikely to get two identical numbers.
//		write_documents()
	else
		desc = "[initial(desc)] Unfortunately, this one seems to have broken down."

/obj/machinery/computer/terminal/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	// Check for locked terminal and display hacking screen
	if(locked && !hack_solved)
		render_lock_screen(user)
		return

	var/dat = ""
	dat += "<head><style>body {padding: 0; margin: 15px; background-color: #062113; color: #4aed92; line-height: 170%;} a, button, a:link, a:visited, a:active, .linkOn, .linkOff {color: #4aed92; text-decoration: none; background: #062113; border: none; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a:hover {color: #062113; background: #4aed92; border: 1px solid #4aed92} a.white, a.white:link, a.white:visited, a.white:active {color: #4aed92; text-decoration: none; background: #4aed92; border: 1px solid #161616; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a.white:hover {color: #062113; background: #4aed92;} .linkOn, a.linkOn:link, a.linkOn:visited, a.linkOn:active, a.linkOn:hover {color: #4aed92; background: #062113; border-color: #062113;} .linkOff, a.linkOff:link, a.linkOff:visited, a.linkOff:active, a.linkOff:hover{color: #4aed92; background: #062113; border-color: #062113;}</style></head><font face='courier'>"
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"

	switch (mode)
		if (0) // If we're on the home page
			dat += "= [termtag] Terminal [termnumber] =</center>"
		if (1) // If we're in the word processor
			dat += "= RobCo Word Processor V.22 =</center>"
		if (2) // If we're viewing a document
			dat += "= [loaded_title] =</center>"
	dat += "<br>"
// The next line is the death of hope. Gaze not longer upon it than you need to.
	switch (mode)
		if (0)
			if(prog_notekeeper)
				dat += "TERMINAL FUNCTIONS"
				dat += "<br><a href='byond://?src=[REF(src)];choice=1'>&gt;  Word Processor</a>"
				dat += "<br><br>"
			dat += "FILE SYSTEM"
			dat += render_document_list()

		if (1)
			dat += "</center><font face=\"Courier\">[(!notehtml ? note : notehtml)]</font>"

		if (2)
			dat += "[loaded_content]"

	if (mode)
		dat += "<br><br><center>=============================================================================</center>"
		if(mode == 1)
			dat += "<a href='byond://?src=[REF(src)];choice=Edit'>\>  Edit</a><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=Return'>\>  Return</a>"


	dat += "</font></div>"

	var/datum/browser/popup = new(user, "terminal", null, 600, 400)
	popup.set_content(dat)
//	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/computer/terminal/Topic(href, href_list)
	..()
	var/mob/living/U = usr

	if(usr.canUseTopic(src) && !href_list["close"])
		add_fingerprint(U)
		U.set_machine(src)

		// Document loading (check first, outside switch)
		if(findtext(href_list["choice"], "doc_"))
			var/idx = text2num(copytext(href_list["choice"], 5))
			if(load_document(idx))
				mode = 2
			updateUsrDialog()
			return

		switch(href_list["choice"])

// Notekeeper

			if ("Edit")
				var/n = stripped_multiline_input(U, "Please enter message", name, note, max_length=MAX_MESSAGE_LEN * 4) //Probably not abusable?? I'd be surprised if anyone managed to crash anything with this
				if (in_range(src, U))
					if (mode == 1 && n)
						note = n
						notehtml = parsemarkdown(n, U)
				else
					return

// Return

			if("Return")
				if(mode) // If we're not on the home page...
					mode = 0 // Take us there

// Menu functions
			if ("1")
				mode = 1

// Hacking functions
			if("hack_word")
				process_hack_attempt(usr, href_list["word"])
				return
			if("hack_dud")
				remove_dud(usr)
				return
			if("hack_refill")
				refill_attempts(usr)
				return
			if("hack_junk")
				process_hack_junk_click(usr)
				return
			if("hack_reset")
				reset_hack(usr)
				return

	updateUsrDialog()
	return

// ============================================================
// TERMINAL HACKING PROCS WITH SPECIAL INTEGRATION
// ============================================================

// Difficulty config lookup
/obj/machinery/computer/terminal/proc/get_difficulty_config()
	// Returns: word_pool, word_count, base_attempts, min_int, diff_name
	switch(hack_difficulty)
		if(0) return list(HACK_WORDS_4,  8,  4, 1, "VERY EASY")
		if(1) return list(HACK_WORDS_5,  8,  4, 2, "EASY")
		if(2) return list(HACK_WORDS_6,  10, 4, 3, "AVERAGE")
		if(3) return list(HACK_WORDS_8,  12, 3, 5, "HARD")
		if(4) return list(HACK_WORDS_10, 12, 3, 7, "VERY HARD")
	return list(HACK_WORDS_6, 10, 4, 3, "AVERAGE") // fallback

// INT: How many attempts does this user get?
/obj/machinery/computer/terminal/proc/calc_attempts_from_int(mob/living/user)
	var/list/cfg = get_difficulty_config()
	var/base = cfg[3]
	if(!istype(user) || !user.special_i)
		return base
	switch(user.special_i)
		if(1 to 2)  return max(1, base - 2)
		if(3 to 4)  return max(1, base - 1)
		if(5 to 6)  return base
		if(7 to 8)  return base + 1
		if(9 to 10) return base + 2
	return base

// INT: How many dud removal charges?
/obj/machinery/computer/terminal/proc/calc_dud_charges_from_int(mob/living/user)
	if(!istype(user) || !user.special_i)
		return 2
	if(user.special_i >= 8) return 3
	if(user.special_i >= 5) return 2
	return 1

// INT: How many attempt refill charges?
/obj/machinery/computer/terminal/proc/calc_refill_charges_from_int(mob/living/user)
	if(!istype(user) || !user.special_i)
		return 1
	if(user.special_i >= 9) return 2
	return 1

// INT: Minimum intelligence gate
/obj/machinery/computer/terminal/proc/check_int_gate(mob/living/user)
	if(!istype(user) || !user.special_i)
		return TRUE // No SPECIAL system, allow access
	var/list/cfg = get_difficulty_config()
	var/min_int = cfg[4]
	if(user.special_i < min_int)
		to_chat(user, span_warning("You stare at the terminal blankly. You have no idea where to even begin."))
		return FALSE
	return TRUE

// PER 7+: position hint showing which characters matched
/obj/machinery/computer/terminal/proc/calc_position_hint_from_per(mob/living/user, guess, answer)
	if(!istype(user) || !user.special_p || user.special_p < 7)
		return null
	var/positions = ""
	for(var/i = 1 to length(guess))
		if(copytext(guess, i, i+1) == copytext(answer, i, i+1))
			positions += "[i] "
	if(!length(positions))
		return "No positional matches."
	return "Position[length(positions) > 2 ? "s" : ""]: [trim(positions)]"

// LCK: Critical failure check (double attempt loss)
/obj/machinery/computer/terminal/proc/check_luck_critfail(mob/living/user)
	if(!istype(user) || !user.special_l)
		return FALSE
	var/chance = user.get_luck_critfail_chance()
	if(!chance) return FALSE
	return prob(chance)

// LCK 8+: Critical success check (auto-solve)
/obj/machinery/computer/terminal/proc/check_luck_critsuccess(mob/living/user)
	if(!istype(user) || !user.special_l || user.special_l < 8)
		return FALSE
	return prob(user.special_l - 7) // 1% at LCK 8, 2% at 9, 3% at 10

// CHA: Flavour header text
/obj/machinery/computer/terminal/proc/get_cha_flavour_text(mob/living/user)
	if(!istype(user) || !user.special_c)
		return null
	if(user.special_c >= 8)
		return "<span class='dim'>&gt; The terminal seems almost happy to see you.</span>"
	if(user.special_c >= 7)
		return "<span class='dim'>&gt; The terminal seems welcoming somehow.</span>"
	if(user.special_c <= 2)
		return "<span class='dim'>&gt; The terminal seems cold and hostile.</span>"
	if(user.special_c <= 3)
		return "<span class='dim'>&gt; The terminal feels indifferent to your presence.</span>"
	return null

// Generate random junk characters for hex columns
/obj/machinery/computer/terminal/proc/gen_junk(len)
	var/result = ""
	for(var/i = 1 to len)
		result += pick(HACK_JUNK_CHARS)
	return result

// Generate a junk column with hidden bracket actions
// lines: how many lines to generate
// bracket_type: "dud" for dud removal, "refill" for attempt refill
/obj/machinery/computer/terminal/proc/gen_junk_column(lines, bracket_type)
	if(!lines || lines <= 0)
		return ""
	
	var/result = ""
	var/charges = 0
	
	// Determine how many bracket pairs to place
	if(bracket_type == "dud")
		charges = hack_dud_charges
	else if(bracket_type == "refill")
		charges = hack_refill_charges
	
	// Place 1-3 bracket pairs randomly if charges available
	var/bracket_count = 0
	if(charges > 0)
		bracket_count = rand(1, min(3, charges))
	
	var/list/bracket_lines = list()
	if(bracket_count > 0)
		for(var/i = 1 to bracket_count)
			var/line_num = rand(1, lines)
			bracket_lines[line_num] = TRUE
	
	// Generate each line
	for(var/line = 1 to lines)
		// Hex address (0xF000 + line offset)
		var/hex_addr = num2hex(0xF000 + (line - 1) * 16, 4)
		result += "0x[hex_addr] "
		
		// Junk padding
		var/junk_before = rand(2, 5)
		result += gen_junk(junk_before)
		
		// Place bracket pair if this line is selected
		if(bracket_lines[line])
			var/bracket_style = pick(list("()", "[]", "{}", "<>"))
			var/open_char = copytext(bracket_style, 1, 2)
			var/close_char = copytext(bracket_style, 2, 3)
			var/junk_inside = gen_junk(rand(3, 7))
			
			// Create clickable bracket action
			var/href_action = ""
			if(bracket_type == "dud")
				href_action = "hack_dud"
			else if(bracket_type == "refill")
				href_action = "hack_refill"
			
			result += "<a href='byond://?src=[REF(src)];choice=[href_action]'>[open_char][junk_inside][close_char]</a>"
		else
			result += gen_junk(rand(5, 10))
		
		// More junk padding
		var/junk_after = rand(2, 5)
		result += gen_junk(junk_after)
		
		if(line < lines)
			result += "<br>"
	
	return result

/obj/machinery/computer/terminal/proc/init_hack(mob/living/user)
	if(!locked || hack_solved || hack_locked_out)
		return

	var/list/cfg   = get_difficulty_config()
	var/list/pool  = cfg[1]
	var/word_count = cfg[2]

	// Apply INT modifiers if a user is provided
	if(user)
		hack_max            = calc_attempts_from_int(user)
		hack_dud_charges    = calc_dud_charges_from_int(user)
		hack_refill_charges = calc_refill_charges_from_int(user)
	else
		hack_max            = cfg[3]
		hack_dud_charges    = 2
		hack_refill_charges = 1

	hack_attempts = hack_max

	// Shuffle and pick words
	pool = shuffle(pool)
	hack_words = list()
	for(var/i = 1 to min(word_count, pool.len))
		hack_words += pool[i]

	// Pick the answer at random
	hack_answer = hack_words[rand(1, hack_words.len)]

	// All words start as potential duds (except the answer — never remove it)
	hack_duds = list()
	for(var/w in hack_words)
		if(w != hack_answer)
			hack_duds += w

	hack_removed = list()
	hack_history = list()

// ============================================================
// JUNK / BRACKET LINE BUILDER
// Returns list(line_string, bracket_start, bracket_end)
// Bracket spaces are FREE (same as word spaces).
// Junk budget = HACK_COLS - solid_chars (open + inner + close).
// If place_bracket, a bracket pair is embedded at a random position
// and its start/end indices are returned (1-based, inclusive).
// ============================================================
/obj/machinery/computer/terminal/proc/gen_junk_line(place_bracket)
	if(!place_bracket)
		var/line = ""
		for(var/i = 1 to HACK_COLS)
			line += pick(HACK_JUNK_CHARS)
		return list(line, 0, 0)

	// Bracket format: "OPEN SPACE inner SPACE CLOSE" e.g. ( % ) or [ @ # ]
	// Spaces inside are FREE — same trick as spaced words.
	// Junk budget = HACK_COLS - solid_chars_in_bracket
	// solid_chars = open(1) + inner_count + close(1) = inner_count + 2
	// Spaces (surrounding + between inner) don't count against the budget.
	var/inner_count = rand(1, 2)
	var/inner_chars = ""
	for(var/i = 1 to inner_count)
		inner_chars += pick(HACK_JUNK_CHARS)
		if(i < inner_count)
			inner_chars += " " // space between multiple inner chars — free

	var/bstyle  = pick("()", "[]", "{}", "<>")
	var/bopen   = copytext(bstyle, 1, 2)
	var/bclose  = copytext(bstyle, 2, 3)
	// Mandatory surrounding spaces make even single chars look like ( % )
	var/bracket_str    = bopen + " " + inner_chars + " " + bclose
	var/bracket_vis    = length(bracket_str)          // visual width incl spaces
	var/bracket_solid  = inner_count + 2              // open + inner chars + close

	// Junk budget based on solid chars only — spaces are free
	var/junk_budget = HACK_COLS - bracket_solid
	if(junk_budget < 0)
		var/line = ""
		for(var/i = 1 to HACK_COLS)
			line += pick(HACK_JUNK_CHARS)
		return list(line, 0, 0)

	var/pre_len  = round(rand(0, junk_budget))
	var/post_len = junk_budget - pre_len

	var/pre_junk = ""
	for(var/i = 1 to pre_len)
		pre_junk += pick(HACK_JUNK_CHARS)

	var/post_junk = ""
	for(var/i = 1 to post_len)
		post_junk += pick(HACK_JUNK_CHARS)

	var/full_line = pre_junk + bracket_str + post_junk
	return list(full_line, pre_len + 1, pre_len + bracket_vis)

// ============================================================
// WORD LINE BUILDER
// Returns list(pre_junk, display_word, post_junk, visual_word_width)
//
// display_word is the spaced version: "MUTANT" -> "M U T A N T"
// visual_word_width is how many characters that takes visually.
//
// The pre/post junk are sized so:
//   length(pre_junk) + visual_word_width + length(post_junk) == HACK_COLS
//
// If the spaced word doesn't fit, falls back to unspaced.
// If even unspaced doesn't fit (shouldn't happen with HACK_COLS=12 and
// word lengths 4-10), returns the word alone with no padding.
// ============================================================
/obj/machinery/computer/terminal/proc/gen_word_line(word)
	var/wlen = length(word)

	// Try spaced first: "WORD" -> "W O R D", visual width = 2*len - 1
	var/spaced_width = (wlen > 1) ? (2 * wlen - 1) : wlen
	var/display_word = ""
	var/vis_width    = 0

	if(spaced_width <= HACK_COLS)
		// Build spaced display string
		for(var/i = 1 to wlen)
			display_word += copytext(word, i, i + 1)
			if(i < wlen)
				display_word += " "
		vis_width = spaced_width
	else if(wlen <= HACK_COLS)
		// Spaced doesn't fit, use compact
		display_word = word
		vis_width    = wlen
	else
		// Word itself is too long (only happens with very long words + small HACK_COLS)
		display_word = copytext(word, 1, HACK_COLS + 1)
		vis_width    = HACK_COLS

	// Junk budget = HACK_COLS - len(word) [not vis_width].
	// Spaces inside "P I S T O L" are free/decorative and don't consume
	// junk slots. Word rows will be visually wider than junk rows — that's
	// correct and matches how Fallout terminals actually look.
	// A 6-letter word gets 6 junk chars scattered around it randomly.
	var/junk_budget = HACK_COLS - wlen
	var/pre_len     = round(rand(0, junk_budget))
	var/post_len    = junk_budget - pre_len

	var/pre_junk = ""
	for(var/i = 1 to pre_len)
		pre_junk += pick(HACK_JUNK_CHARS)

	var/post_junk = ""
	for(var/i = 1 to post_len)
		post_junk += pick(HACK_JUNK_CHARS)

	return list(pre_junk, display_word, post_junk, vis_width)

// ============================================================
// JUNK TO CLICKABLE
// Converts a plain junk string into per-character <a> links
// that fire hack_junk (failed attempt) when clicked.
// Safe to use inside <pre> — inline <a> tags don't affect char width.
// ============================================================
/obj/machinery/computer/terminal/proc/junk_to_clickable(str)
	if(!str || !length(str))
		return ""
	var/result = ""
	for(var/i = 1 to length(str))
		var/ch = copytext(str, i, i + 1)
		result += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[ch]</a>"
	return result

/obj/machinery/computer/terminal/proc/render_lock_screen(mob/user)
	// INT gate
	if(istype(user, /mob/living) && !hack_locked_out && !hack_solved)
		var/mob/living/L = user
		if(!check_int_gate(L))
			return

	// First visit: build the session
	if(!hack_words || !hack_words.len)
		if(istype(user, /mob/living))
			init_hack(user)
		else
			init_hack()

	var/list/cfg  = get_difficulty_config()
	var/diff_name = cfg[5]

	// ── CSS
	// Key insight: the <pre> tag + monospace font means every character
	// is the same width. We use inline-block <a> tags inside the <pre>
	// so links don't break the character grid.
	var/dat = "<head><style>"
	dat += "body{padding:0;margin:10px;background-color:#062113;color:#4aed92;"
	dat += "font-family:'Courier New',Courier,monospace;font-size:13px;line-height:1.3;}"

	// All links — default state looks identical to surrounding text
	dat += "a{color:#4aed92;text-decoration:none;background:transparent;"
	dat += "border:none;padding:0;margin:0;display:inline;cursor:default;}"
	dat += "a:hover{color:#062113;background:#4aed92;cursor:pointer;}"

	// pre block — preserves whitespace, guarantees monospace char width
	dat += "pre{margin:0;padding:0;font-family:'Courier New',Courier,monospace;"
	dat += "font-size:13px;line-height:1.3;display:inline-block;vertical-align:top;}"

	dat += ".dim{color:#2a7a52;}"
	dat += ".bad{color:#c0392b;font-weight:bold;}"
	dat += ".good{color:#4aed92;font-weight:bold;}"
	dat += ".addr{color:#2a7a52;}"  // hex address colour
	dat += ".removed{color:#1a5c35;text-decoration:line-through;}"
	dat += ".pip{display:inline-block;width:11px;height:11px;background:#4aed92;margin:0 1px;vertical-align:middle;}"
	dat += ".pip.used{background:#062113;border:1px solid #2a7a52;}"
	dat += ".hist{font-size:90%;color:#2a7a52;font-family:'Courier New',Courier,monospace;}"
	dat += ".hint{color:#4aed92;font-size:90%;font-family:'Courier New',Courier,monospace;}"
	dat += "</style></head>"

	// ── Header
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	dat += "= PASSWORD REQUIRED =</center><br>"

	// ── Locked out state
	if(hack_locked_out)
		dat += "<center><span class='bad'>!!! TERMINAL LOCKED — TOO MANY FAILED ATTEMPTS !!!</span><br><br>"
		dat += "<span class='dim'>A technician with a Repair Kit can bypass this lock.</span><br><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=hack_reset'>&gt; " + ascii2text(91) + "FORCE BYPASS" + ascii2text(93) + "</a>"
		dat += "</center>"

	else
		// CHA flavour line
		if(istype(user, /mob/living))
			var/mob/living/L = user
			var/cha_line = get_cha_flavour_text(L)
			if(cha_line) dat += "[cha_line]<br>"

		// Pips + difficulty
		dat += "<b>DIFFICULTY:</b> [diff_name] &nbsp; <b>ATTEMPTS:</b> "
		for(var/i = 1 to hack_max)
			dat += "<span class='pip [i <= hack_attempts ? "" : "used"]'></span>"
		dat += "<br>"

		// INT hint
		if(istype(user, /mob/living))
			var/mob/living/L = user
			if(L.special_i >= 7)
				dat += "<span class='dim'>&gt; Your intelligence grants additional attempts.</span><br>"
			else if(L.special_i <= 3)
				dat += "<span class='dim'>&gt; Your limited intelligence reduces your attempts.</span><br>"
		dat += "<br>"

		// ── Build column content
		// We split words evenly between left and right columns.
		// Each column is HACK_ROWS lines tall.
		// Each line = hex address + space + HACK_COLS content chars.
		//
		// Strategy per column:
		//   - Decide which rows will contain words vs pure junk
		//   - Decide which junk rows will contain bracket pairs
		//   - Build each line as a plain string + metadata
		//   - Render with <pre> and inject <a> tags for interactive elements

		var/mid = round(hack_words.len / 2)

		// Left column gets first half of words, right gets second half
		var/list/left_words  = list()
		var/list/right_words = list()
		for(var/i = 1 to hack_words.len)
			if(i <= mid)
				left_words  += hack_words[i]
			else
				right_words += hack_words[i]

		// How many dud bracket pairs to scatter in left column
		var/left_brackets  = hack_dud_charges > 0    ? rand(1, min(3, hack_dud_charges))    : 0
		var/right_brackets = hack_refill_charges > 0 ? rand(1, min(2, hack_refill_charges)) : 0

		dat += "<table style='border:0;border-spacing:8px 0;'><tr>"

		// ── Render one column as HTML
		// col_words: words to embed
		// bracket_count: how many bracket pairs to scatter
		// bracket_type: "dud" or "refill"
		// base_addr: starting hex address offset
		for(var/col = 1 to 2)
			var/list/col_words    = (col == 1) ? left_words  : right_words
			var/bracket_count     = (col == 1) ? left_brackets : right_brackets
			var/bracket_type      = (col == 1) ? "dud" : "refill"
			var/base_addr         = (col == 1) ? 0xF340 : 0xF3E0

			// Assign rows: pick random rows for words, random rows for brackets
			// remaining rows are pure junk
			var/list/row_types = list() // indexed 1..HACK_ROWS, value = "word_N", "bracket", or "junk"
			for(var/i = 1 to HACK_ROWS)
				row_types += "junk"

			// Place words at random rows (without collision)
			var/list/available_rows = list()
			for(var/i = 1 to HACK_ROWS) available_rows += i
			available_rows = shuffle(available_rows)

			var/word_slot = 1
			for(var/i = 1 to col_words.len)
				if(word_slot > available_rows.len) break
				row_types[available_rows[word_slot]] = "word_[i]"
				word_slot++

			// Place brackets at remaining rows
			var/bracket_placed = 0
			for(var/i = word_slot to available_rows.len)
				if(bracket_placed >= bracket_count) break
				row_types[available_rows[i]] = "bracket"
				bracket_placed++

			// Now render the column inside a <pre> block
			// We use <pre> so spaces are preserved and all chars are equal width
			dat += "<td style='vertical-align:top;padding:0;'><pre>"

			for(var/row = 1 to HACK_ROWS)
				// Hex address — always shown in dim colour
				var/hex_val = uppertext(num2hex(base_addr + (row - 1) * 12, 4))
				dat += "<span class='addr'>0x[hex_val]</span> "

				var/rtype = row_types[row]

				if(findtext(rtype, "word_"))
					// ── WORD ROW
					var/widx = text2num(copytext(rtype, 6))
					if(widx < 1 || widx > col_words.len)
						// Bad index fallback — pure junk
						for(var/j = 1 to HACK_COLS)
							dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
					else
						var/w          = col_words[widx]
						var/list/parts = gen_word_line(w)
						// parts[1] = pre_junk  (plain string, length = pre chars)
						// parts[2] = display_word (spaced or compact, plain string)
						// parts[3] = post_junk (plain string)
						// parts[4] = visual width of display_word

						dat += junk_to_clickable(parts[1])

						if(w in hack_removed)
							dat += "<span class='removed'>[parts[2]]</span>"
						else
							// The word itself is clickable and highlighted on hover
							dat += "<a href='byond://?src=[REF(src)];choice=hack_word;word=[w]'>[parts[2]]</a>"

						dat += junk_to_clickable(parts[3])

				else if(rtype == "bracket")
					// ── BRACKET ROW
					var/list/jline = gen_junk_line(TRUE)
					var/line_str   = jline[1]
					var/bstart     = jline[2]
					var/bend       = jline[3]

					if(!bstart)
						// Bracket placement failed — whole line is clickable junk
						dat += junk_to_clickable(line_str)
					else
						var/pre_part    = copytext(line_str, 1, bstart)
						var/bracket_str = copytext(line_str, bstart, bend + 1)
						var/post_part   = copytext(line_str, bend + 1)

						var/href_action = (bracket_type == "dud") ? "hack_dud" : "hack_refill"
						dat += junk_to_clickable(pre_part)
						dat += "<a href='byond://?src=[REF(src)];choice=[href_action]'>[bracket_str]</a>"
						dat += junk_to_clickable(post_part)

				else
					// ── PURE JUNK ROW — all chars clickable for failed attempt
					var/list/jline = gen_junk_line(FALSE)
					dat += junk_to_clickable(jline[1])

				dat += "\n"

			dat += "</pre></td>"

		dat += "</tr></table>"

		// Charges indicator
		dat += "<span class='dim'>&gt; DUD REMOVALS: [hack_dud_charges] | ATTEMPT REFILLS: [hack_refill_charges]</span><br><br>"

		// History log
		if(hack_history && hack_history.len)
			dat += "<b>ENTRY LOG:</b><br>"
			for(var/line in hack_history)
				dat += "<span class='hist'>[line]</span><br>"

	dat += "</font>"

	var/datum/browser/popup = new(user, "terminal", null, 620, 540)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/terminal/proc/process_hack_attempt(mob/living/user, word)
	if(!locked || hack_solved || hack_locked_out || !user)
		return
	// Safety: reject if word isn't in the master list or has been removed
	if(!word || !(word in hack_words) || (word in hack_removed))
		return
	if(!(word in hack_duds) && word != hack_answer)
		return // Already removed dud, shouldn't be clickable but safety check

	if(!hack_history)
		hack_history = list()

	// ── Lucky break check (LCK 8+)
	if(word != hack_answer && check_luck_critsuccess(user))
		hack_history += "&gt;Lucky break! System accepted entry."
		word = hack_answer // treat it as correct this once

	if(word == hack_answer)
		// ── SUCCESS
		hack_solved = TRUE
		locked      = FALSE
		hack_history += "&gt;Entry: [word]"
		hack_history += "<span class='good'>&gt;Exact match. ACCESS GRANTED.</span>"

		to_chat(user, span_nicegreen("ACCESS GRANTED."))

		if(on_hack_success)
			call(on_hack_success)(src, user)

		// Return to normal terminal
		mode = 0
		ui_interact(user)
		return

	// ── WRONG GUESS
	var/likeness = get_likeness(word, hack_answer)
	hack_history += "&gt;Entry: [word]"
	hack_history += "&gt;Likeness: [likeness]/[length(hack_answer)]"

	// PER 7+ position hint
	var/pos_hint = calc_position_hint_from_per(user, word, hack_answer)
	if(pos_hint)
		hack_history += "<span class='hint'>&gt;[pos_hint]</span>"

	// LCK critfail — lose an extra attempt
	if(check_luck_critfail(user))
		hack_attempts--
		hack_history += "<span class='bad'>&gt;System spike! Lost an additional attempt.</span>"

	hack_attempts--

	if(hack_attempts <= 0)
		hack_locked_out = TRUE
		hack_history += "<span class='bad'>&gt;!!! TERMINAL LOCKED !!!</span>"
		to_chat(user, span_warning("The terminal locks you out."))

	updateUsrDialog()

/obj/machinery/computer/terminal/proc/get_likeness(guess, answer)
	// Count matching characters at matching positions
	var/matches = 0
	var/len     = min(length(guess), length(answer))
	for(var/i = 1 to len)
		if(copytext(guess, i, i+1) == copytext(answer, i, i+1))
			matches++
	return matches

/obj/machinery/computer/terminal/proc/process_hack_junk_click(mob/living/user)
	if(!locked || hack_solved || hack_locked_out || !user)
		return
	
	if(!hack_history)
		hack_history = list()
	
	// Just a failed attempt, no likeness
	hack_history += "&gt;Entry denied."
	hack_history += "&gt;Invalid selection."
	
	// LCK critfail — lose an extra attempt
	if(check_luck_critfail(user))
		hack_attempts--
		hack_history += "<span class='bad'>&gt;System spike! Lost an additional attempt.</span>"
	
	hack_attempts--
	
	if(hack_attempts <= 0)
		hack_locked_out = TRUE
		hack_history += "<span class='bad'>&gt;!!! TERMINAL LOCKED !!!</span>"
		to_chat(user, span_warning("The terminal locks you out."))
	
	updateUsrDialog()

/obj/machinery/computer/terminal/proc/remove_dud(mob/living/user)
	if(hack_dud_charges <= 0 || !hack_duds || hack_duds.len < 1)
		to_chat(user, span_warning("No dud removals remaining."))
		return

	// ── FIX: only remove from hack_duds, which never contains the answer
	var/removed = hack_duds[rand(1, hack_duds.len)]
	hack_duds.Remove(removed)
	hack_removed += removed  // for strikethrough display
	hack_dud_charges--

	if(!hack_history) hack_history = list()
	hack_history += "&gt;Dud removed: [removed]"

	updateUsrDialog()

/obj/machinery/computer/terminal/proc/refill_attempts(mob/living/user)
	if(hack_refill_charges <= 0)
		to_chat(user, span_warning("No attempt refills remaining."))
		return
	if(hack_attempts >= hack_max)
		to_chat(user, span_warning("Attempts are already at maximum."))
		return

	hack_attempts = hack_max
	hack_refill_charges--

	if(!hack_history) hack_history = list()
	hack_history += "&gt;Tries replenished."

	updateUsrDialog()

/obj/machinery/computer/terminal/proc/reset_hack(mob/living/user)
	// TODO: Check user has repair kit / appropriate skill/perk
	// Example:
	// var/obj/item/tool/repair_kit/K = user.get_active_held_item()
	// if(!istype(K))
	//     to_chat(user, span_warning("You need a Repair Kit to bypass this lock."))
	//     return

	hack_locked_out     = FALSE
	hack_solved         = FALSE
	hack_words          = null
	hack_duds           = null
	hack_removed        = null
	hack_answer         = ""
	hack_history        = list()
	init_hack(user) // Re-init applies fresh INT modifiers
	updateUsrDialog()

// Migrate legacy document variables into datum list
/obj/machinery/computer/terminal/proc/write_documents()
	build_document_list()
	return

/obj/machinery/computer/terminal/grognak2 // original story by skubblers, #1 jerry reed fan

/obj/machinery/computer/terminal/grognak2/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	var/dat = ""
	dat += "<head><style>body {padding: 0; margin: 15px; background-color: #062113; color: #4aed92; line-height: 170%;} a, button, a:link, a:visited, a:active, .linkOn, .linkOff {color: #4aed92; text-decoration: none; background: #062113; border: none; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a:hover {color: #062113; background: #4aed92; border: 1px solid #4aed92} a.white, a.white:link, a.white:visited, a.white:active {color: #4aed92; text-decoration: none; background: #4aed92; border: 1px solid #161616; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a.white:hover {color: #062113; background: #4aed92;} .linkOn, a.linkOn:link, a.linkOn:visited, a.linkOn:active, a.linkOn:hover {color: #4aed92; background: #062113; border-color: #062113;} .linkOff, a.linkOff:link, a.linkOff:visited, a.linkOff:active, a.linkOff:hover{color: #4aed92; background: #062113; border-color: #062113;}</style></head><font face='courier'>"
	dat += "<center><b>GROGNAK THE BARBARIAN: THROWING THE DAGGER INTO THE HEART OF THE INVOKER</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 HUBRIS COMICS</b><br>"
	dat += "<br>"

	switch (mode)
		if (0) // If we're on the home page
			dat += "Dark incantations reverberate far overhead in the halls of the dreaded Invoker, and your vengeful gaze is drawn to the jeering, demonic murals painted on the apse towering above... their laughter mingles with the INVOKER'S LITANY, as he imbues his putrid congregation with LIES!"
		if (1) // If we're in the word processor
			dat += "Dark incantations reverberate far overhead in the halls of the dreaded Invoker, and your vengeful gaze is drawn to the jeering, demonic murals painted on the apse towering above... their laughter mingles with the INVOKER'S LITANY, as he imbues his putrid congregation with LIES!"
		if (2) // If we're viewing a document
			dat += "[loaded_title]"
	dat += "<br>"

/obj/machinery/computer/terminal/grognak
	name = "desktop terminal"
	desc = "A RobCo Industries terminal, widely available for commercial and private use before the war."
	icon_state = "terminal"
	icon_keyboard = "terminal_key"
	icon_screen = "terminal_on_alt"
	connectable = FALSE
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/robco_terminal

/obj/machinery/computer/terminal/grognak/Initialize()
	. = ..()

	if(!broken)
		desc = "[initial(desc)] Remarkably, it still works."
		termnumber = rand(69,420) // Unlikely to get two identical numbers.
//		write_documents()
	else
		desc = "[initial(desc)] Unfortunately, this one seems to have broken down."

/obj/machinery/computer/terminal/grognak/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	var/dat = ""
	dat += "<head><style>body {padding: 0; margin: 15px; background-color: #062113; color: #4aed92; line-height: 170%;} a, button, a:link, a:visited, a:active, .linkOn, .linkOff {color: #4aed92; text-decoration: none; background: #062113; border: none; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a:hover {color: #062113; background: #4aed92; border: 1px solid #4aed92} a.white, a.white:link, a.white:visited, a.white:active {color: #4aed92; text-decoration: none; background: #4aed92; border: 1px solid #161616; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a.white:hover {color: #062113; background: #4aed92;} .linkOn, a.linkOn:link, a.linkOn:visited, a.linkOn:active, a.linkOn:hover {color: #4aed92; background: #062113; border-color: #062113;} .linkOff, a.linkOff:link, a.linkOff:visited, a.linkOff:active, a.linkOff:hover{color: #4aed92; background: #062113; border-color: #062113;}</style></head><font face='courier'>"
	dat += "<center><b>GROGNAK THE BARBARIAN: FROM THE DEPTHS OF DOOMTOPIA</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 HUBRIS COMICS</b><br>"
	dat += "<br>"

	switch (mode)
		if (0) // If we're on the home page
			dat += "The Goblin war party watches you with trepidation, only the Goblin War Chief seems to possess no fear of you, he chitters arrogantly and his men begin approaching you. You feel the need, the need to cleave."
		if (1) // If we're in the word processor
			dat += "The Goblin war party watches you with trepidation, only the Goblin War Chief seems to possess no fear of you, he chitters arrogantly and his men begin approaching you. You feel the need, the need to cleave."
		if (2) // If we're viewing a document
			dat += "[loaded_title]"
	dat += "<br>"
// The next line is the death of hope. Gaze not longer upon it than you need to.
	switch (mode)
		if (0)

			dat += render_document_list()

		if (1)
			dat += "</center><font face=\"Courier\">[(!notehtml ? note : notehtml)]</font>"

		if (2)
			dat += "[loaded_content]"

	if (mode)
		dat += "<br><br><center>=============================================================================</center>"
		if(mode == 1)
			dat += "<a href='byond://?src=[REF(src)];choice=Edit'>\>  Edit</a><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=Return'>\>  Return</a>"


	dat += "</font></div>"

	var/datum/browser/popup = new(user, "terminal", null, 600, 400)
	popup.set_content(dat)
//	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/computer/terminal/grognak/Topic(href, href_list)
	..()
	var/mob/living/U = usr

	if(usr.canUseTopic(src) && !href_list["close"])
		add_fingerprint(U)
		U.set_machine(src)

		// Document loading (check first, outside switch)
		if(findtext(href_list["choice"], "doc_"))
			var/idx = text2num(copytext(href_list["choice"], 5))
			if(load_document(idx))
				mode = 2
			updateUsrDialog()
			return

		switch(href_list["choice"])
	
	// Notekeeper

			if ("Edit")
				var/n = stripped_multiline_input(U, "Please enter message", name, note, max_length=MAX_MESSAGE_LEN * 4) //Probably not abusable?? I'd be surprised if anyone managed to crash anything with this
				if (in_range(src, U))
					if (mode == 1 && n)
						note = n
						notehtml = parsemarkdown(n, U)
				else
					return

// Return

			if("Return")
				if(mode) // If we're not on the home page...
					mode = 0 // Take us there

// Menu functions
			if ("1")
				mode = 1

	updateUsrDialog()
	return

// ============================================================
// DOCUMENT SYSTEM HELPERS
// ============================================================

// Build document list from legacy 5-slot vars during write_documents()
/obj/machinery/computer/terminal/proc/build_document_list()
	if(!terminal_documents)
		terminal_documents = list()
	
	// Migrate any legacy doc_title_N / doc_content_N into datum list
	if(doc_title_1)
		var/datum/terminal_document/doc = new()
		doc.title = doc_title_1
		doc.content = doc_content_1
		terminal_documents += doc
	if(doc_title_2)
		var/datum/terminal_document/doc = new()
		doc.title = doc_title_2
		doc.content = doc_content_2
		terminal_documents += doc
	if(doc_title_3)
		var/datum/terminal_document/doc = new()
		doc.title = doc_title_3
		doc.content = doc_content_3
		terminal_documents += doc
	if(doc_title_4)
		var/datum/terminal_document/doc = new()
		doc.title = doc_title_4
		doc.content = doc_content_4
		terminal_documents += doc
	if(doc_title_5)
		var/datum/terminal_document/doc = new()
		doc.title = doc_title_5
		doc.content = doc_content_5
		terminal_documents += doc

// Render the document list for the main menu
/obj/machinery/computer/terminal/proc/render_document_list()
	if(!terminal_documents || !terminal_documents.len)
		return ""
	
	var/result = ""
	for(var/i = 1 to terminal_documents.len)
		var/datum/terminal_document/doc = terminal_documents[i]
		result += "<br><a href='byond://?src=[REF(src)];choice=doc_[i]'>&gt;  [doc.title]</a>"
	
	return result

// Load a document by index (1-based)
/obj/machinery/computer/terminal/proc/load_document(index)
	if(!terminal_documents || index < 1 || index > terminal_documents.len)
		return FALSE
	
	var/datum/terminal_document/doc = terminal_documents[index]
	loaded_title = doc.title
	loaded_content = doc.content
	return TRUE

// ============================================================
// LOCKED TERMINAL SUBTYPES
// ============================================================

/obj/machinery/computer/terminal/locked
	name         = "locked terminal"
	desc         = "A RobCo Industries terminal. The screen shows a password prompt."
	locked       = TRUE
	hack_difficulty = 2 // Average

/obj/machinery/computer/terminal/locked/Initialize()
	. = ..()
	init_hack() // No user yet; INT modifiers apply on first examine

/obj/machinery/computer/terminal/locked/ui_interact(mob/user)
	if(locked && !hack_solved)
		render_lock_screen(user)
		return
	. = ..() // Falls through to normal terminal ui_interact once solved

// Easy difficulty
/obj/machinery/computer/terminal/locked/easy
	name = "security terminal"
	hack_difficulty = 1

// Hard difficulty
/obj/machinery/computer/terminal/locked/hard
	name = "military terminal"
	desc = "A hardened military-grade RobCo terminal. The screen shows a password prompt."
	hack_difficulty = 3

// Very Hard difficulty
/obj/machinery/computer/terminal/locked/very_hard
	name = "vault security terminal"
	desc = "A high-security Vault-Tec terminal. Access restricted."
	hack_difficulty = 4

// Hard terminal — Vault security door controller example
/obj/machinery/computer/terminal/locked/vault_security
	name            = "VAULT-TEC SECURITY TERMINAL"
	desc            = "A high-security Vault-Tec terminal. Access is strictly restricted."
	hack_difficulty = 3
	on_hack_success = /proc/vault_terminal_hacked

/proc/vault_terminal_hacked(obj/machinery/computer/terminal/T, mob/living/user)
	// Broadcast an alert; hook up your airlock or door here
	for(var/mob/M in world)
		M << "<span style='color:#c0392b'>[T.name]: SECURITY PROTOCOLS BYPASSED. INTRUDER ALERT.</span>"
	// T.linked_door?.open()

// Very Hard terminal — Enclave comms array
/obj/machinery/computer/terminal/locked/enclave_comms
	name            = "ENCLAVE COMMUNICATIONS ARRAY"
	desc            = "An Enclave-grade communications terminal. Heavily encrypted."
	hack_difficulty = 4
	on_hack_success = /proc/enclave_terminal_hacked

/proc/enclave_terminal_hacked(obj/machinery/computer/terminal/T, mob/living/user)
	for(var/mob/M in world)
		M << "<span style='color:#c0392b'>ENCLAVE ALERT: COMMUNICATIONS ARRAY COMPROMISED.</span>"


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

/obj/machinery/computer/terminal/proc/render_lock_screen(mob/user)
	// INT gate — if they fail it, don't even show the screen
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

	var/dat = ""

	// ── Shared CSS (matches your existing terminal style)
	dat += "<head><style>"
	dat += "body{padding:0;margin:15px;background-color:#062113;color:#4aed92;line-height:170%;font-family:courier,monospace;}"
	dat += "a,button{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;cursor:default;}"
	dat += "a:hover{color:#062113;background:#4aed92;}"
	dat += ".dim{color:#2a7a52;} .bad{color:#c0392b;} .good{color:#4aed92;font-weight:bold;}"
	dat += ".word-btn{display:inline-block;padding:1px 3px;letter-spacing:2px;}"
	dat += ".word-btn:hover{color:#062113;background:#4aed92;cursor:pointer;}"
	dat += ".removed{color:#1a5c35;text-decoration:line-through;cursor:default;}"
	dat += ".col{display:inline-block;vertical-align:top;width:48%;}"
	dat += ".pip{display:inline-block;width:12px;height:12px;background:#4aed92;margin:0 2px;}"
	dat += ".pip.used{background:#062113;border:1px solid #2a7a52;}"
	dat += ".hist{font-size:85%;color:#2a7a52;}"
	dat += ".hint{color:#4aed92;font-size:85%;}"
	dat += "</style></head>"

	// ── Header
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	dat += "= PASSWORD REQUIRED =</center><br>"

	if(hack_locked_out)
		dat += "<center><span class='bad'>!!! TERMINAL LOCKED — TOO MANY FAILED ATTEMPTS !!!</span><br><br>"
		dat += "<span class='dim'>A technician with a Repair Kit can bypass this lock.</span><br><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=hack_reset'>&gt; " + ascii2text(91) + "FORCE BYPASS" + ascii2text(93) + "</a>"
		dat += "</center>"
	else
		// ── CHA flavour line
		if(istype(user, /mob/living))
			var/mob/living/L = user
			var/cha_line = get_cha_flavour_text(L)
			if(cha_line)
				dat += "[cha_line]<br>"

		// ── Difficulty + attempt pips
		dat += "<b>DIFFICULTY: [diff_name]</b><br>"
		dat += "ATTEMPTS REMAINING: "
		for(var/i = 1 to hack_max)
			dat += "<span class='pip [i <= hack_attempts ? "" : "used"]'></span>"
		dat += "<br>"

		// ── INT-based attempt count hint
		if(istype(user, /mob/living))
			var/mob/living/L = user
			if(L.special_i && L.special_i >= 7)
				dat += "<span class='dim'>&gt; Your intelligence has granted you additional attempts.</span><br>"
			else if(L.special_i && L.special_i <= 3)
				dat += "<span class='dim'>&gt; Your limited intelligence has reduced your attempts.</span><br>"

		dat += "<br>"

		// ── Word grid with hex junk columns (authentic Fallout style)
		// Words are embedded within junk, not in separate columns
		var/mid = round(hack_words.len / 2)
		
		// Create word queue for each column
		var/list/left_words = hack_words.Copy(1, mid + 1)
		var/list/right_words = hack_words.Copy(mid + 1)
		
		// Calculate lines needed (ensure enough for all words + junk spacing)
		var/lines_per_col = max(mid * 2, 12)
		
		dat += "<table style='width:100%;'><tr>"
		
		// ── LEFT COLUMN ──
		dat += "<td style='width:50%;vertical-align:top;font-family:courier,monospace;white-space:nowrap;'>"
		var/left_word_idx = 1
		for(var/line = 1 to lines_per_col)
			var/hex_addr = uppertext(num2hex(0xF340 + (line - 1) * 16, 4))
			dat += "0x[hex_addr] "
			
			// Decide if this line gets a word or just junk
			var/has_word = (left_word_idx <= left_words.len && (line == left_word_idx * 2 || prob(40)))
			
			if(has_word && left_word_idx <= left_words.len)
				// Embed word in junk
				var/junk_before = rand(2, 5)
				for(var/j = 1 to junk_before)
					dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
				
				// Add the word
				var/w = left_words[left_word_idx]
				if(w in hack_removed)
					dat += "<span class='removed'>[w]</span>"
				else if(w == hack_answer)
					dat += "<a class='word-btn' href='byond://?src=[REF(src)];choice=hack_word;word=[w]'>[w]</a>"
				else if(w in hack_duds)
					dat += "<a class='word-btn' href='byond://?src=[REF(src)];choice=hack_word;word=[w]'>[w]</a>"
				else
					dat += "<span class='removed'>[w]</span>"
				
				// Junk after word
				var/junk_after = rand(2, 5)
				for(var/j = 1 to junk_after)
					dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
				
				left_word_idx++
			else
				// Just junk with possible bracket pairs
				var/junk_count = rand(10, 16)
				var/bracket_pos = rand(4, 8)
				
				for(var/j = 1 to junk_count)
					if(j == bracket_pos && hack_dud_charges > 0 && prob(25))
						var/bracket_style = pick("()", "[]", "{}", "<>")
						var/open_char = copytext(bracket_style, 1, 2)
						var/close_char = copytext(bracket_style, 2, 3)
						var/junk_inside = ""
						for(var/k = 1 to rand(3, 5))
							junk_inside += pick(HACK_JUNK_CHARS)
						dat += "<a href='byond://?src=[REF(src)];choice=hack_dud'>[open_char][junk_inside][close_char]</a>"
						j += rand(3, 5) // Skip ahead
					else
						dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
			
			dat += "<br>"
		dat += "</td>"
		
		// ── RIGHT COLUMN ──
		dat += "<td style='width:50%;vertical-align:top;font-family:courier,monospace;white-space:nowrap;'>"
		var/right_word_idx = 1
		for(var/line = 1 to lines_per_col)
			var/hex_addr = uppertext(num2hex(0xF3E0 + (line - 1) * 16, 4))
			dat += "0x[hex_addr] "
			
			// Decide if this line gets a word or just junk
			var/has_word = (right_word_idx <= right_words.len && (line == right_word_idx * 2 || prob(40)))
			
			if(has_word && right_word_idx <= right_words.len)
				// Embed word in junk
				var/junk_before = rand(2, 5)
				for(var/j = 1 to junk_before)
					dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
				
				// Add the word
				var/w = right_words[right_word_idx]
				if(w in hack_removed)
					dat += "<span class='removed'>[w]</span>"
				else if(w == hack_answer)
					dat += "<a class='word-btn' href='byond://?src=[REF(src)];choice=hack_word;word=[w]'>[w]</a>"
				else if(w in hack_duds)
					dat += "<a class='word-btn' href='byond://?src=[REF(src)];choice=hack_word;word=[w]'>[w]</a>"
				else
					dat += "<span class='removed'>[w]</span>"
				
				// Junk after word
				var/junk_after = rand(2, 5)
				for(var/j = 1 to junk_after)
					dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
				
				right_word_idx++
			else
				// Just junk with possible bracket pairs
				var/junk_count = rand(10, 16)
				var/bracket_pos = rand(4, 8)
				
				for(var/j = 1 to junk_count)
					if(j == bracket_pos && hack_refill_charges > 0 && prob(25))
						var/bracket_style = pick("()", "[]", "{}", "<>")
						var/open_char = copytext(bracket_style, 1, 2)
						var/close_char = copytext(bracket_style, 2, 3)
						var/junk_inside = ""
						for(var/k = 1 to rand(3, 5))
							junk_inside += pick(HACK_JUNK_CHARS)
						dat += "<a href='byond://?src=[REF(src)];choice=hack_refill'>[open_char][junk_inside][close_char]</a>"
						j += rand(3, 5) // Skip ahead
					else
						dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(HACK_JUNK_CHARS)]</a>"
			
			dat += "<br>"
		dat += "</td>"
		
		dat += "</tr></table>"

		dat += "<br>"

		// ── Charges display (informational only, brackets are in junk columns)
		dat += "<span class='dim'>&gt; DUD REMOVALS: [hack_dud_charges] | REFILLS: [hack_refill_charges]</span><br>"
		dat += "<br>"

		// ── History log
		if(hack_history && hack_history.len)
			dat += "<b>ENTRY LOG:</b><br>"
			for(var/line in hack_history)
				dat += "<span class='hist'>[line]</span><br>"

	dat += "</font>"

	var/datum/browser/popup = new(user, "terminal", null, 600, 520)
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


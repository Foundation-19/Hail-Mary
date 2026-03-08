// ============================================================
// WORD LISTS FOR TERMINAL HACKING BY DIFFICULTY
// ============================================================

// 4-letter words (Very Easy)
GLOBAL_LIST_INIT(HACK_WORDS_4, list(
	"ATOM","BUNK","CAPS","DART","ECHO","FUSE","GLOW","HACK",
	"IRON","JUNK","KERN","LOOT","MOLE","NUKE","OPEN","PERK",
	"QUIZ","RUST","SAFE","TUBE","UNIT","VENT","WATT","XRAY",
	"YARD","ZERO","ACID","BOLT","CHIP","DEAD","FIRE","GORE",
	"HIVE","IDOL","JADE","KILL","LAMP","MIRE","NODE","ORAL"
))

// 5-letter words (Easy)
GLOBAL_LIST_INIT(HACK_WORDS_5, list(
	"ALARM","BLEED","CRATE","DRONE","EMBER","FLARE","GHOUL","HAVOC",
	"IDEAL","JADED","KARMA","LASER","MUTIE","NINJA","OPTIC","PINCH",
	"QUOTA","RADON","SIREN","TURBO","ULTRA","VAULT","WASTE","XENON",
	"YIELD","ZONED","AMMON","BRACE","CRAFT","DECAY","EXILE","FORGE",
	"GUARD","HAUNT","INGOT","JUICE","KNEEL","LANCE","METRO","NERVE"
))

// 6-letter words (Average)
GLOBAL_LIST_INIT(HACK_WORDS_6, list(
	"ATOMIC","BANDIT","CAPPED","DEACON","ENERGY","FUSION","GHETTO","HUNTER",
	"INMATE","JOCKEY","RADWST","LAUNCH","MIASMA","NAPALM","OUTLAW","PISTOL",
	"QUARTZ","RADIUM","SENTRY","TURRET","UNDEAD","VENDOR","WANTED","XENIAL",
	"ZEALOT","AMBUSH","BLIGHT","CINDER","DUSTER","FAMINE","GAMBLE","HAVENS",
	"INTAKE","JACKAL","KETTLE","LETHAL","MUTANT","NOODLE","OFFSET","PLASMA"
))

// 8-letter words (Hard)
GLOBAL_LIST_INIT(HACK_WORDS_8, list(
	"ATOMFALL","BUNKERED","CAPSTONE","DEADZONE","ELECTRON","FIREBOMB",
	"GREYZONE","HALFLIFE","INFRARED","JUNKYARD","KILOWATT","LOCKDOWN",
	"MUTATION","NUKEFALL","OVERLOAD","PARTISAN","QUANTIZE","RADIATED",
	"SENTINEL","TERMINAL","ULTERIOR","VAULTBOY","WASTEFUL","XELERANT",
	"ZEROZONE","ABERRANT","BLACKOUT","CHEMICAL","DESERTER","ENDURING"
))

// 10-letter words (Very Hard)
GLOBAL_LIST_INIT(HACK_WORDS_10, list(
	"ABANDONWAR","BIOHAZARDS","CONTAINMEN","DEADLOCKED","ENCLAVECOD",
	"FALLOUTZON","GROUNDZERO","HACKTHRUGH","IRRADIATON","JUNKPILWAR",
	"KINETICALY","LIQUIDATON","MILITIABAS","NEUTRALIZE","OUTCASTZON",
	"PRIVATEERZ","QUARANTINE","RADIOACTIV","SURVIVALIS","TURRETFILD",
	"UNDERGROND","VAULTDWELR","WASTECRAFR","XENOBIOLGC","ZEROTOLERC"
))

// Junk characters for hex column padding
GLOBAL_LIST_INIT(HACK_JUNK_CHARS, list(
	"!","@","#","$","%","^","&","*","=","+","-","_",
	"|","\\","/","?","~","`",":",";","'","\"",",","."
))

// Column rendering constants (lore-accurate Fallout layout)
#define HACK_COLS 12  // Characters per line (excluding hex address)
#define HACK_ROWS 16  // Number of rows per column

// ============================================================
// DOCUMENT DATUM SYSTEM
// ============================================================

/datum/terminal_document
	var/title = ""
	var/content = ""

// ============================================================
// TERMINAL BASE TYPE
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

	var/broken = FALSE
	var/prog_notekeeper = TRUE
	var/termtag = "Home"
	var/termnumber = null
	var/mode = 0
	// mode 0 = home, 1 = word processor, 2 = document view,
	// 3 = door control, 4 = turret list, 5 = turret detail,
	// 6 = admin panel (lock/set difficulty)

	// ── Document vars (legacy 5-slot, migrated to datum list on init)
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
	var/list/terminal_documents = null

	// ── Notekeeper
	var/notehtml = ""
	var/note = "ERR://null-data #236XF51"

	// ── Hacking vars
	var/locked              = FALSE
	var/hack_difficulty     = 2
	var/hack_solved         = FALSE
	var/hack_locked_out     = FALSE
	var/hack_answer         = ""
	var/list/hack_words     = null
	var/list/hack_duds      = null
	var/list/hack_removed   = null
	var/list/hack_history   = null
	var/hack_attempts       = 4
	var/hack_max            = 4
	var/hack_dud_charges    = 2
	var/hack_refill_charges = 1
	var/on_hack_success     = null

	// ── Security linkage
	var/list/linked_door_ids  = null  // List of airlock id strings — set in map editor
	var/list/linked_buttons   = null  // Live button refs — populated at runtime
	var/list/linked_turrets   = null  // Live turret refs — populated at runtime
	var/turret_detail_ref     = null

	// ── Map-editor linkage vars (resolved to live refs in Initialize)
	/// Comma-separated button IDs to auto-link on init, e.g. "btn_vault,btn_armory"
	var/map_button_ids  = null
	/// Comma-separated turret tag strings to auto-link on init, e.g. "turret_guard,turret_east"
	var/map_turret_tags = null
	/// When non-null, the next ID card swiped will be registered to this turret's whitelist
	var/pending_whitelist_tref = null
	/// When non-null, the next ID card swiped will register its faction to this turret
	var/pending_faction_tref = null

/obj/machinery/computer/terminal/Initialize()
	. = ..()
	if(!broken)
		desc = "[initial(desc)] Remarkably, it still works."
		termnumber = rand(69,420)
	else
		desc = "[initial(desc)] Unfortunately, this one seems to have broken down."
	write_documents()
	resolve_map_links()

/* 

MAPPER EXAMPLE: DO NOT DELETE FOR FUTURE MAPPERS

/obj/machinery/computer/terminal/vault_security{
	// Hacking difficulty and tag
	termtag = "Security"
	hack_difficulty = 3          // HARD

	// Airlocks — matched by their var/id
	linked_door_ids = list("vault_main", "vault_armory")

	// Buttons — matched by their var/id (same id as the airlocks they control)
	map_button_ids = "btn_main,btn_armory"

	// Turrets — matched by their var/tag (set tag on each turret in the map editor)
	map_turret_tags = "turret_entrance,turret_east_hall"

	// Documents
	doc_title_1 = "SECURITY PROTOCOLS"
	doc_content_1 = "All personnel must be screened..."
}

*/

/obj/machinery/computer/terminal/proc/resolve_map_links()
	// Resolve map_button_ids -> linked_buttons
	// Accepts a comma-separated list of button id strings matching var/id on /obj/machinery/button/door
	if(map_button_ids && length(map_button_ids))
		if(!linked_buttons) linked_buttons = list()
		var/list/ids = splittext(map_button_ids, ",")
		for(var/raw_id in ids)
			var/target_id = trim(raw_id)
			if(!length(target_id)) continue
			for(var/obj/machinery/button/door/B in world)
				if(B.vars["id"] == target_id)
					if(!(B in linked_buttons))
						linked_buttons += B

	// Resolve map_turret_tags -> linked_turrets
	// Accepts a comma-separated list of strings matching var/tag on porta_turret
	if(map_turret_tags && length(map_turret_tags))
		if(!linked_turrets) linked_turrets = list()
		var/list/tags = splittext(map_turret_tags, ",")
		for(var/raw_tag in tags)
			var/target_tag = trim(raw_tag)
			if(!length(target_tag)) continue
			for(var/obj/machinery/porta_turret/T in world)
				if(T.tag == target_tag)
					if(!(T in linked_turrets))
						linked_turrets += T

// ============================================================
// SHARED CSS HELPER
// ============================================================

/obj/machinery/computer/terminal/proc/get_terminal_css()
	var/css = "<head><style>"
	css += "body{padding:0;margin:15px;background-color:#062113;color:#4aed92;line-height:170%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;cursor:default;}"
	css += "a:hover{color:#062113;background:#4aed92;}"
	css += "table{border-spacing:6px 3px;}"
	css += ".good{color:#4aed92;font-weight:bold;}"
	css += ".bad{color:#c0392b;font-weight:bold;}"
	css += ".dim{color:#2a7a52;}"
	css += ".warn{color:#e8a020;}"
	css += "</style></head>"
	return css

/obj/machinery/computer/terminal/proc/get_terminal_header(title_line)
	var/h = "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	h += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	h += "= [title_line] =</center><br>"
	return h

/obj/machinery/computer/terminal/proc/get_terminal_footer(extra)
	var/f = "<br><center>=====================================================================</center>"
	if(extra)
		f += extra
	f += "<br><a href='byond://?src=[REF(src)];choice=Return'>&gt;  Return</a>"
	return f

// ============================================================
// MAIN ui_interact
// ============================================================

/obj/machinery/computer/terminal/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	if(locked && !hack_solved)
		render_lock_screen(user)
		return

	var/dat = get_terminal_css()

	switch(mode)
		if(0)
			dat += get_terminal_header("[termtag] Terminal [termnumber]")
			if(prog_notekeeper)
				dat += "TERMINAL FUNCTIONS"
				dat += "<br><a href='byond://?src=[REF(src)];choice=1'>&gt;  Word Processor</a>"
				dat += "<br>"
			if(terminal_documents && terminal_documents.len)
				dat += "<br>FILE SYSTEM"
				dat += render_document_list()
			dat += render_security_menu_items()
			dat += render_admin_menu_item(user)

		if(1)
			dat += get_terminal_header("RobCo Word Processor V.22")
			dat += "<br><font face='Courier'>[(!notehtml ? note : notehtml)]</font>"
			dat += get_terminal_footer("<a href='byond://?src=[REF(src)];choice=Edit'>&gt;  Edit</a><br>")

		if(2)
			dat += get_terminal_header(loaded_title)
			dat += "[loaded_content]"
			dat += get_terminal_footer()

		if(3)
			dat += get_terminal_header("Door Control")
			dat += render_door_page()
			dat += get_terminal_footer()

		if(4)
			dat += get_terminal_header("Automated Defense Network")
			dat += render_turret_list_page()
			dat += get_terminal_footer()

		if(5)
			var/obj/machinery/porta_turret/T = get_linked_turret(turret_detail_ref)
			dat += get_terminal_header("Unit Configuration")
			dat += render_turret_detail_page(T)
			dat += get_terminal_footer("<a href='byond://?src=[REF(src)];choice=goto_turrets'>&gt;  Back to Defense List</a><br>")

		if(6)
			dat += get_terminal_header("Terminal Administration")
			dat += render_admin_page(user)
			dat += get_terminal_footer()

	if(!mode)
		dat += "</font></div>"

	var/datum/browser/popup = new(user, "terminal", null, 640, 460)
	popup.set_content(dat)
	popup.open()

// ============================================================
// TOPIC
// ============================================================

/obj/machinery/computer/terminal/Topic(href, href_list)
	..()
	var/mob/living/U = usr

	if(!usr.canUseTopic(src) || href_list["close"])
		return

	add_fingerprint(U)
	U.set_machine(src)

	// Document loading
	if(findtext(href_list["choice"], "doc_"))
		var/idx = text2num(copytext(href_list["choice"], 5))
		if(load_document(idx))
			mode = 2
		updateUsrDialog()
		return

	switch(href_list["choice"])

		// ── Notekeeper
		if("Edit")
			var/n = stripped_multiline_input(U, "Please enter message", name, note, max_length=MAX_MESSAGE_LEN * 4)
			if(in_range(src, U) && mode == 1 && n)
				note = n
				notehtml = parsemarkdown(n, U)

		// ── Navigation
		if("Return")
			if(mode) mode = 0
		if("1")
			mode = 1
		if("goto_doors")
			mode = 3
		if("goto_turrets")
			mode = 4
		if("goto_admin")
			// Only allow if terminal is unlocked/solved
			if(!locked || hack_solved)
				mode = 6

		// ── Hacking
		if("hack_word")
			process_hack_attempt(U, href_list["word"])
			return
		if("hack_dud")
			remove_dud(U)
			return
		if("hack_refill")
			refill_attempts(U)
			return
		if("hack_junk")
			process_hack_junk_click(U)
			return
		if("hack_reset")
			reset_hack(U)
			return

		// ── Door controls
		if("door_pulse")
			door_pulse_button(U, href_list["btn"])
		if("door_lock")
			door_lock_by_id(U, href_list["id"])
		if("door_unlock")
			door_unlock_by_id(U, href_list["id"])

		// ── Turret list
		if("turret_toggle")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.toggle_on()
		if("turret_mode")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.setState(T.on, !T.mode)
		if("turret_all_on")
			if(linked_turrets)
				for(var/obj/machinery/porta_turret/T in linked_turrets)
					T.toggle_on(TRUE)
		if("turret_all_off")
			if(linked_turrets)
				for(var/obj/machinery/porta_turret/T in linked_turrets)
					T.toggle_on(FALSE)
		if("turret_detail")
			turret_detail_ref = href_list["tref"]
			mode = 5

		// ── Turret detail / ownership
		if("turret_add_faction")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T)
				pending_faction_tref = REF(T)
				to_chat(U, span_notice("Swipe an ID card on the terminal to register its faction to [T.name]."))
			mode = 5
		if("turret_remove_faction")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T && T.faction)
				T.faction -= href_list["faction"]
				to_chat(U, span_notice("Faction '[href_list["faction"]]' removed."))
		if("turret_clear_faction")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T)
				T.faction = list()
				to_chat(U, span_notice("Faction registry cleared — unit hostile to all."))
		if("turret_flag_players")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_SHOOT_PLAYERS
		if("turret_flag_wildlife")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_SHOOT_WILDLIFE
		if("turret_flag_raiders")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_SHOOT_RAIDERS
		if("turret_flag_robots")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_SHOOT_ROBOTS
		if("turret_flag_faction")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_IGNORE_FACTION
		if("turret_flag_laser")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_USE_LASER_POINTER
		if("turret_flag_loud")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T) T.turret_flags ^= TF_BE_REALLY_LOUD

		// ── Turret whitelist
		if("turret_whitelist_add")
			pending_whitelist_tref = href_list["tref"]
			to_chat(U, span_notice("Ready to register. Swipe an ID card on the terminal."))
		if("turret_whitelist_cancel")
			pending_whitelist_tref = null
		if("turret_faction_cancel")
			pending_faction_tref = null
		if("turret_whitelist_remove")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T)
				turret_whitelist_remove(T, href_list["entry"], U)
		if("turret_whitelist_toggle")
			var/obj/machinery/porta_turret/T = get_linked_turret(href_list["tref"])
			if(T)
				turret_whitelist_toggle(T, U)

		// ── Admin panel actions
		if("admin_lock")
			admin_lock_terminal(U)
		if("admin_set_difficulty")
			admin_set_difficulty(U, href_list["diff"])

	updateUsrDialog()
	return

// ============================================================
// ATTACKBY — multitool linkage
// ============================================================

/obj/machinery/computer/terminal/attackby(obj/item/W, mob/user, params)
	// Hacking device — used to bypass lockouts
	if(istype(W, /obj/item/hacking_device))
		reset_hack(user)
		return
	// ID card — register to turret whitelist if pending
	if(istype(W, /obj/item/card/id))
		register_id_to_whitelist(W, user)
		return
	// Multitool — used for door/turret linking
	if(istype(W, /obj/item/multitool))
		var/obj/item/multitool/M = W
		// Correct direction: buffer has button/turret, swipe terminal to link
		if(istype(M.buffer, /obj/machinery/button/door))
			link_button_from_multitool(M, user)
			return
		if(istype(M.buffer, /obj/machinery/porta_turret))
			link_turret_from_multitool(M, user)
			return
		// Wrong direction: buffer has the terminal itself (player hit terminal first)
		// Just tell them what to do instead of silently overwriting
		if(M.buffer == src)
			to_chat(user, span_warning("The terminal is already in the buffer. Swipe a door button or turret first, then swipe this terminal."))
			return
		// Buffer has something else or is empty — store the terminal
		M.buffer = src
		to_chat(user, span_notice("You add [src] to multitool buffer. Now swipe a door button or turret, then swipe this terminal again to link it."))
		return
	return ..()

// ── Reverse-direction linking: multitool buffer has terminal, swipe the button
/obj/machinery/button/door/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/multitool))
		var/obj/item/multitool/M = W
		if(istype(M.buffer, /obj/machinery/computer/terminal))
			var/obj/machinery/computer/terminal/T = M.buffer
			if(!T.linked_buttons) T.linked_buttons = list()
			if(src in T.linked_buttons)
				T.linked_buttons -= src
				to_chat(user, span_notice("Unlinked [name] from [T.name]."))
			else
				T.linked_buttons += src
				to_chat(user, span_notice("Linked [name] to [T.name]."))
			M.buffer = null
			return
	return ..()

// ── Reverse-direction linking: multitool buffer has terminal, swipe the turret
/obj/machinery/porta_turret/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/multitool))
		var/obj/item/multitool/M = W
		if(istype(M.buffer, /obj/machinery/computer/terminal))
			var/obj/machinery/computer/terminal/T = M.buffer
			if(!T.linked_turrets) T.linked_turrets = list()
			if(src in T.linked_turrets)
				T.linked_turrets -= src
				to_chat(user, span_notice("Unlinked [name] from [T.name]."))
			else
				T.linked_turrets += src
				to_chat(user, span_notice("Linked [name] to [T.name]."))
			M.buffer = null
			return
	return ..()

// ============================================================
// ADMIN PANEL — lock / password display / difficulty
// ============================================================

/// Returns whether to show the admin menu item at all.
/// Shown if: terminal is already unlocked/solved, or has no lock.
/obj/machinery/computer/terminal/proc/render_admin_menu_item(mob/user)
	if(locked && !hack_solved)
		return ""
	return "<br><br>ADMINISTRATION<br><a href='byond://?src=[REF(src)];choice=goto_admin'>&gt;  Terminal Settings</a>"

/obj/machinery/computer/terminal/proc/render_admin_page(mob/user)
	var/dat = ""
	var/list/cfg = get_difficulty_config()
	var/diff_name = cfg[5]

	dat += "<b>TERMINAL ADMINISTRATION</b><br><br>"

	// ── Lock status
	if(!locked || hack_solved)
		dat += "<span class='good'>&gt; STATUS: UNLOCKED</span><br>"
	else
		dat += "<span class='bad'>&gt; STATUS: LOCKED</span><br>"

	// ── Current password (only visible when unlocked)
	if(!locked || hack_solved)
		if(hack_answer && length(hack_answer))
			dat += "<span class='dim'>&gt; CURRENT PASSWORD: </span><span class='warn'>[hack_answer]</span><br>"
		else
			dat += "<span class='dim'>&gt; CURRENT PASSWORD: </span><span class='dim'>(not generated yet)</span><br>"

	dat += "<br>"

	// ── Difficulty display + change (gated by INT)
	dat += "<b>SECURITY DIFFICULTY</b><br>"
	dat += "<span class='dim'>&gt; Current difficulty: </span><b>[diff_name]</b> (level [hack_difficulty])<br>"

	// Show what difficulties are available to this user
	if(istype(user, /mob/living))
		var/mob/living/L = user
		var/int_val = L.special_i
		dat += "<span class='dim'>&gt; Your Intelligence: [int_val] — unlocks difficulties up to: "
		var/max_diff = get_max_settable_difficulty(L)
		switch(max_diff)
			if(0) dat += "VERY EASY"
			if(1) dat += "EASY"
			if(2) dat += "AVERAGE"
			if(3) dat += "HARD"
			if(4) dat += "VERY HARD"
		dat += "</span><br><br>"
	else
		dat += "<br>"

	dat += "SET DIFFICULTY:<br>"
	var/list/diff_labels = list("VERY EASY","EASY","AVERAGE","HARD","VERY HARD")
	var/list/diff_min_int = list(1, 3, 5, 7, 9)  // INT required to set each tier
	for(var/i = 0 to 4)
		var/can_set = TRUE
		var/locked_txt = ""
		if(istype(user, /mob/living))
			var/mob/living/L = user
			if(L.special_i < diff_min_int[i+1])
				can_set = FALSE
				locked_txt = " <span class='dim'>(INT [diff_min_int[i+1]]+ required)</span>"
		var/selected_txt = (hack_difficulty == i) ? " <span class='good'>\[SELECTED\]</span>" : ""
		if(can_set)
			dat += "&gt; <a href='byond://?src=[REF(src)];choice=admin_set_difficulty;diff=[i]'>[diff_labels[i+1]]</a>[selected_txt]<br>"
		else
			dat += "&gt; <span class='dim'>[diff_labels[i+1]]</span>[locked_txt][selected_txt]<br>"

	dat += "<br><b>LOCK CONTROL</b><br>"
	if(!locked || hack_solved)
		dat += "<a href='byond://?src=[REF(src)];choice=admin_lock'>&gt; Lock terminal (generate new password)</a><br>"
	else
		dat += "<span class='dim'>&gt; Terminal is locked. Hack it to regain access.</span><br>"

	return dat

/// Max difficulty a user can set based on INT
/obj/machinery/computer/terminal/proc/get_max_settable_difficulty(mob/living/user)
	if(!istype(user)) return 4
	var/i = user.special_i
	if(i >= 9) return 4
	if(i >= 7) return 3
	if(i >= 5) return 2
	if(i >= 3) return 1
	return 0

/// Lock the terminal and generate a fresh password
/obj/machinery/computer/terminal/proc/admin_lock_terminal(mob/user)
	locked = TRUE
	hack_solved = FALSE
	hack_locked_out = FALSE
	hack_words = null
	hack_duds = null
	hack_removed = null
	hack_answer = ""
	hack_history = list()
	init_hack(user)  // generates password with user's INT modifiers applied
	to_chat(user, span_notice("Terminal locked. Password set to: <b>[hack_answer]</b>"))
	mode = 0

/// Set difficulty — regenerates the hack session. new_diff passed as 0-4 from Topic href
/obj/machinery/computer/terminal/proc/admin_set_difficulty(mob/user, new_diff)
	new_diff = text2num(new_diff)
	if(isnull(new_diff) || new_diff < 0 || new_diff > 4)
		to_chat(user, span_warning("Invalid difficulty."))
		return
	// INT gate
	var/list/diff_min_int = list(1, 3, 5, 7, 9)
	if(istype(user, /mob/living))
		var/mob/living/L = user
		if(L.special_i < diff_min_int[new_diff + 1])
			to_chat(user, span_warning("Your Intelligence is too low to configure this security tier."))
			return
	hack_difficulty = new_diff
	// Reset hack session so next lock uses new difficulty
	hack_words = null
	hack_duds = null
	hack_removed = null
	hack_answer = ""
	hack_history = list()
	var/list/cfg = get_difficulty_config()
	to_chat(user, span_notice("Difficulty set to [cfg[5]]."))

// ============================================================
// SECURITY MENU ITEMS (door/turret links on home page)
// ============================================================

/obj/machinery/computer/terminal/proc/render_security_menu_items()
	var/has_doors   = (linked_buttons && linked_buttons.len) || (linked_door_ids && linked_door_ids.len)
	var/has_turrets = (linked_turrets && linked_turrets.len)
	if(!has_doors && !has_turrets)
		return ""
	var/dat = "<br><br>SECURITY SYSTEMS"
	if(has_doors)
		dat += "<br><a href='byond://?src=[REF(src)];choice=goto_doors'>&gt;  Door Control</a>"
	if(has_turrets)
		dat += "<br><a href='byond://?src=[REF(src)];choice=goto_turrets'>&gt;  Automated Defense</a>"
	return dat

// ============================================================
// DOOR / BUTTON LINKAGE
// ============================================================

/obj/machinery/computer/terminal/proc/render_door_page()
	var/dat = "<b>DOOR / SHUTTER CONTROL</b><br><br>"

	if(linked_buttons && linked_buttons.len)
		dat += "<b>LINKED CONTROLS</b><br>"
		for(var/obj/machinery/button/door/B in linked_buttons)
			if(!B || QDELETED(B)) continue
			var/door_state = "UNKNOWN"
			if(istype(B.device, /obj/item/assembly/control/airlock))
				var/obj/item/assembly/control/airlock/A = B.device
				for(var/obj/machinery/door/airlock/D in world)
					if(D.vars["id"] == A.id)
						door_state = D.density ? "CLOSED" : "OPEN"
						break
				if(door_state == "UNKNOWN")
					for(var/obj/machinery/door/firedoor/D in world)
						if(D.vars["id"] == A.id)
							door_state = D.density ? "CLOSED" : "OPEN"
							break
			dat += "&gt; [B.name] — <span class='[door_state == "OPEN" ? "good" : "dim"]'>[door_state]</span> "
			dat += "<a href='byond://?src=[REF(src)];choice=door_pulse;btn=[REF(B)]'>\[PULSE\]</a><br>"
	else
		dat += "<span class='dim'>&gt; No buttons linked. Multitool a door button then swipe this terminal.</span><br>"

	if(linked_door_ids && linked_door_ids.len)
		dat += "<br><b>DOOR IDs</b><br>"
		for(var/id in linked_door_ids)
			dat += "&gt; ID: [id] "
			dat += "<a href='byond://?src=[REF(src)];choice=door_lock;id=[id]'>\[LOCK\]</a> "
			dat += "<a href='byond://?src=[REF(src)];choice=door_unlock;id=[id]'>\[UNLOCK\]</a><br>"

	return dat

/obj/machinery/computer/terminal/proc/door_pulse_button(mob/user, btn_ref)
	if(!linked_buttons) return
	var/obj/machinery/button/door/B = locate(btn_ref)
	if(!istype(B) || !(B in linked_buttons))
		to_chat(user, span_warning("Button not found or not linked."))
		return
	if(B.device)
		B.device.pulsed()
		to_chat(user, span_notice("Pulsed: [B.name]"))

/obj/machinery/computer/terminal/proc/door_lock_by_id(mob/user, id)
	var/count = 0
	for(var/obj/machinery/door/airlock/D in world)
		var/atom/door_atom = D
		if(door_atom.vars["id"] == id)
			D.lock()
			count++
	to_chat(user, span_notice("Locked [count] door\s with id '[id]'."))

/obj/machinery/computer/terminal/proc/door_unlock_by_id(mob/user, id)
	var/count = 0
	for(var/obj/machinery/door/airlock/D in world)
		var/atom/door_atom = D
		if(door_atom.vars["id"] == id)
			D.unlock()
			count++
	to_chat(user, span_notice("Unlocked [count] door\s with id '[id]'."))

/obj/machinery/computer/terminal/proc/link_button_from_multitool(obj/item/multitool/M, mob/user)
	if(!istype(M.buffer, /obj/machinery/button/door))
		to_chat(user, span_warning("No door button in multitool buffer."))
		return
	if(!linked_buttons) linked_buttons = list()
	var/obj/machinery/button/door/B = M.buffer
	if(B in linked_buttons)
		linked_buttons -= B
		to_chat(user, span_notice("Unlinked [B.name] from terminal."))
	else
		linked_buttons += B
		to_chat(user, span_notice("Linked [B.name] to terminal."))
	M.buffer = null

// ============================================================
// TURRET MANAGEMENT
// ============================================================

/obj/machinery/computer/terminal/proc/render_turret_list_page()
	var/dat = "<b>AUTOMATED DEFENSE NETWORK</b><br><br>"

	if(!linked_turrets || !linked_turrets.len)
		dat += "<span class='dim'>&gt; No turrets linked. Multitool a turret then swipe this terminal.</span><br>"
		return dat

	dat += "<table style='border-spacing:4px 2px;'>"
	dat += "<tr><td><b>UNIT</b></td><td><b>STATUS</b></td><td><b>MODE</b></td><td><b>FACTION</b></td><td><b>ACTIONS</b></td></tr>"
	for(var/obj/machinery/porta_turret/T in linked_turrets)
		if(!T || QDELETED(T)) continue
		var/status_txt  = T.on ? "<span class='good'>ONLINE</span>"  : "<span class='bad'>OFFLINE</span>"
		var/mode_txt    = T.mode == TURRET_LETHAL ? "<span class='bad'>LETHAL</span>" : "<span class='dim'>STUN</span>"
		var/broken_txt  = (T.stat & BROKEN) ? " <span class='bad'>\[BROKEN\]</span>" : ""
		var/faction_txt = (T.faction && T.faction.len) ? jointext(T.faction, ",") : "NONE"
		dat += "<tr>"
		dat += "<td>[T.name][broken_txt]</td>"
		dat += "<td>[status_txt]</td>"
		dat += "<td>[mode_txt]</td>"
		dat += "<td><span class='dim'>[faction_txt]</span></td>"
		dat += "<td>"
		dat += "<a href='byond://?src=[REF(src)];choice=turret_toggle;tref=[REF(T)]'>[T.on ? "OFF" : "ON"]</a> "
		dat += "<a href='byond://?src=[REF(src)];choice=turret_mode;tref=[REF(T)]'>[T.mode == TURRET_LETHAL ? "STUN" : "LETHAL"]</a> "
		dat += "<a href='byond://?src=[REF(src)];choice=turret_detail;tref=[REF(T)]'>MANAGE</a>"
		dat += "</td></tr>"
	dat += "</table>"
	dat += "<br><a href='byond://?src=[REF(src)];choice=turret_all_on'>&gt; ALL ONLINE</a>  "
	dat += "<a href='byond://?src=[REF(src)];choice=turret_all_off'>&gt; ALL OFFLINE</a>"
	return dat

/obj/machinery/computer/terminal/proc/render_turret_detail_page(obj/machinery/porta_turret/T)
	if(!T || QDELETED(T))
		return "<span class='bad'>ERROR: Unit not found.</span><br>"

	var/dat = ""
	dat += "<b>UNIT: [T.name]</b><br>"
	dat += "<span class='dim'>&gt; Location: ([T.x],[T.y],[T.z])</span><br>"
	dat += "<span class='dim'>&gt; Integrity: [T.obj_integrity]/[T.max_integrity]</span><br>"
	dat += "<span class='dim'>&gt; Mode: [T.mode == TURRET_LETHAL ? "LETHAL" : "STUN"]</span><br>"
	dat += "<span class='dim'>&gt; Status: [T.on ? "ONLINE" : "OFFLINE"]</span><br>"
	dat += "<span class='dim'>&gt; Activity: [T.activity_state]</span><br>"
	dat += "<br>"

	dat += "<b>FACTION REGISTRY</b><br>"
	if(T.faction && T.faction.len)
		for(var/f in T.faction)
			dat += "&gt; [f] <a href='byond://?src=[REF(src)];choice=turret_remove_faction;tref=[REF(T)];faction=[f]'>\[REMOVE\]</a><br>"
	else
		dat += "<span class='dim'>&gt; No faction — unit hostile to all.</span><br>"
	dat += "<a href='byond://?src=[REF(src)];choice=turret_add_faction;tref=[REF(T)]'>&gt; Add faction</a><br>"
	dat += "<a href='byond://?src=[REF(src)];choice=turret_clear_faction;tref=[REF(T)]'>&gt; CLEAR ALL FACTIONS</a><br>"
	dat += "<br>"

	dat += "<b>TARGET PROFILE</b><br>"
	var/list/flag_defs = list(
		list("Shoot Players",  TF_SHOOT_PLAYERS,     "turret_flag_players"),
		list("Shoot Wildlife", TF_SHOOT_WILDLIFE,    "turret_flag_wildlife"),
		list("Shoot Raiders",  TF_SHOOT_RAIDERS,     "turret_flag_raiders"),
		list("Shoot Robots",   TF_SHOOT_ROBOTS,      "turret_flag_robots"),
		list("Ignore Faction", TF_IGNORE_FACTION,    "turret_flag_faction"),
		list("Laser Pointer",  TF_USE_LASER_POINTER, "turret_flag_laser"),
		list("Loud Alerts",    TF_BE_REALLY_LOUD,    "turret_flag_loud"),
	)
	for(var/list/fd in flag_defs)
		var/enabled = (T.turret_flags & fd[2]) ? TRUE : FALSE
		dat += "&gt; [fd[1]]: <span class='[enabled ? "good" : "dim"]'>[enabled ? "YES" : "NO"]</span> "
		dat += "<a href='byond://?src=[REF(src)];choice=[fd[3]];tref=[REF(T)]'>\[TOGGLE\]</a><br>"

	dat += "<br>"

	dat += "<b>PERSONNEL WHITELIST</b><br>"
	// Read whitelist off the turret's vars (stored as a list of name strings)
	var/list/wl = T.vars["id_whitelist"]
	if(wl && wl.len)
		var/wl_active = T.vars["whitelist_active"]
		dat += "<span class='dim'>&gt; Enforcement: </span><span class='[wl_active ? "bad" : "dim"]'>[wl_active ? "ACTIVE — unlisted targets shot" : "INACTIVE — whitelist ignored"]</span> "
		dat += "<a href='byond://?src=[REF(src)];choice=turret_whitelist_toggle;tref=[REF(T)]'>\[TOGGLE\]</a><br>"
		for(var/entry in wl)
			dat += "&gt; [entry] <a href='byond://?src=[REF(src)];choice=turret_whitelist_remove;tref=[REF(T)];entry=[entry]'>\[REMOVE\]</a><br>"
	else
		dat += "<span class='dim'>&gt; No personnel registered.</span><br>"
	if(pending_whitelist_tref == REF(T))
		dat += "<span class='warn'>&gt; AWAITING ID CARD — swipe a card on this terminal to register the holder.</span><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=turret_whitelist_cancel'>&gt; Cancel</a><br>"
	else
		dat += "<a href='byond://?src=[REF(src)];choice=turret_whitelist_add;tref=[REF(T)]'>&gt; Register ID card...</a><br>"

	dat += "<br>"
	dat += "<a href='byond://?src=[REF(src)];choice=turret_toggle;tref=[REF(T)]'>&gt; [T.on ? "SHUT DOWN UNIT" : "ACTIVATE UNIT"]</a><br>"
	dat += "<a href='byond://?src=[REF(src)];choice=turret_mode;tref=[REF(T)]'>&gt; Switch to [T.mode == TURRET_LETHAL ? "STUN" : "LETHAL"] mode</a><br>"
	return dat

/obj/machinery/computer/terminal/proc/link_turret_from_multitool(obj/item/multitool/M, mob/user)
	if(!istype(M.buffer, /obj/machinery/porta_turret))
		to_chat(user, span_warning("No turret in multitool buffer."))
		return
	if(!linked_turrets) linked_turrets = list()
	var/obj/machinery/porta_turret/T = M.buffer
	if(T in linked_turrets)
		linked_turrets -= T
		to_chat(user, span_notice("Unlinked [T.name] from terminal."))
	else
		linked_turrets += T
		to_chat(user, span_notice("Linked [T.name] to terminal."))
	M.buffer = null

/obj/machinery/computer/terminal/proc/get_linked_turret(tref)
	if(!linked_turrets) return null
	var/obj/machinery/porta_turret/T = locate(tref)
	if(!istype(T) || !(T in linked_turrets)) return null
	return T

// ============================================================
// TURRET WHITELIST HELPERS
// ============================================================

/// Called when an ID card is swiped on the terminal.
/// Handles both whitelist registration and faction registration depending on pending state.
/obj/machinery/computer/terminal/proc/register_id_to_whitelist(obj/item/card/id/card, mob/user)
	// Faction registration takes priority
	if(pending_faction_tref)
		register_id_faction(card, user)
		return
	if(!pending_whitelist_tref)
		to_chat(user, span_warning("No turret is waiting for an ID card. Use the terminal UI to start registration."))
		return
	var/obj/machinery/porta_turret/T = get_linked_turret(pending_whitelist_tref)
	if(!T)
		to_chat(user, span_warning("The target turret is no longer linked."))
		pending_whitelist_tref = null
		return
	var/person_name = card.registered_name
	if(!person_name || !length(person_name))
		to_chat(user, span_warning("This ID card has no registered name. Assign a name to it first."))
		return
	var/list/wl = T.vars["id_whitelist"]
	if(!wl)
		T.vars["id_whitelist"] = list()
		wl = T.vars["id_whitelist"]
	if(person_name in wl)
		to_chat(user, span_warning("[person_name] is already on the whitelist for [T.name]."))
	else
		wl += person_name
		to_chat(user, span_nicegreen("Registered [person_name] to [T.name]'s personnel whitelist."))
	pending_whitelist_tref = null
	updateUsrDialog()

/// Called when an ID card is swiped to register its faction to a turret.
/// Maps the card's assignment (job title) to a Fallout 13 faction define.
/obj/machinery/computer/terminal/proc/register_id_faction(obj/item/card/id/card, mob/user)
	var/obj/machinery/porta_turret/T = get_linked_turret(pending_faction_tref)
	pending_faction_tref = null
	if(!T)
		to_chat(user, span_warning("Target turret no longer linked."))
		return
	// Map card assignment to faction tag using the Fallout 13 defines
	var/faction_tag = get_faction_from_card(card)
	if(!faction_tag)
		to_chat(user, span_warning("Could not determine faction from this ID card. The assignment '[card.assignment ? card.assignment : "(blank)"]' is not recognised."))
		return
	if(!T.faction) T.faction = list()
	if(faction_tag in T.faction)
		to_chat(user, span_warning("[faction_tag] is already in [T.name]'s faction list."))
		return
	T.faction += faction_tag
	to_chat(user, span_nicegreen("Registered faction '[faction_tag]' to [T.name] based on ID card: [card.registered_name ? card.registered_name : "(unnamed)"] ([card.assignment])."))
	updateUsrDialog()

/// Maps a card's assignment string to a canonical Fallout 13 faction tag.
/// Returns null if the assignment doesn't match any known faction.
/obj/machinery/computer/terminal/proc/get_faction_from_card(obj/item/card/id/card)
	if(!card.assignment) return null
	var/assign = lowertext(trim(card.assignment))
	// NCR / Rangers
	if(findtext(assign, "ncr") || findtext(assign, "republic") || findtext(assign, "trooper") || findtext(assign, "ranger") && !findtext(assign, "veteran"))
		return FACTION_NCR
	if(findtext(assign, "veteran ranger") || findtext(assign, "vet ranger"))
		return FACTION_RANGER
	// Legion
	if(findtext(assign, "legion") || findtext(assign, "centurion") || findtext(assign, "prime") || findtext(assign, "recruit medallion") || findtext(assign, "veteran medallion") || findtext(assign, "auxilia"))
		return FACTION_LEGION
	// Brotherhood of Steel
	if(findtext(assign, "brotherhood") || findtext(assign, "bos") || findtext(assign, "paladin") || findtext(assign, "knight") || findtext(assign, "scribe") || findtext(assign, "elder"))
		return FACTION_BROTHERHOOD
	// Enclave
	if(findtext(assign, "enclave") || findtext(assign, "us officer") || findtext(assign, "us dogtag") || findtext(assign, "american"))
		return FACTION_ENCLAVE
	// Town / Eastwood
	if(findtext(assign, "citizen") || findtext(assign, "settler") || findtext(assign, "mayor") || findtext(assign, "deputy") || findtext(assign, "sheriff") || findtext(assign, "deputy"))
		return FACTION_EASTWOOD
	// Raiders
	if(findtext(assign, "raider") || findtext(assign, "outlaw") || findtext(assign, "bandit"))
		return FACTION_RAIDERS
	// Great Khans
	if(findtext(assign, "khan"))
		return FACTION_KHAN
	// Super Mutants
	if(findtext(assign, "mutant"))
		return FACTION_SMUTANT
	// Vault
	if(findtext(assign, "vault") || findtext(assign, "overseer") || findtext(assign, "dweller"))
		return FACTION_VAULT
	// Followers
	if(findtext(assign, "follower"))
		return FACTION_FOLLOWERS
	// Tribe
	if(findtext(assign, "tribe") || findtext(assign, "tribal") || findtext(assign, "talisman"))
		return FACTION_TRIBE
	// Wastelander catch-all
	if(findtext(assign, "waster") || findtext(assign, "wastelander") || findtext(assign, "survivor") || findtext(assign, "scavenger"))
		return FACTION_WASTELAND
	return null

/// Remove a name from a turret's whitelist.
/obj/machinery/computer/terminal/proc/turret_whitelist_remove(obj/machinery/porta_turret/T, entry, mob/user)
	var/list/wl = T.vars["id_whitelist"]
	if(!wl || !(entry in wl))
		to_chat(user, span_warning("Entry not found."))
		return
	wl -= entry
	to_chat(user, span_notice("Removed [entry] from [T.name]'s whitelist."))

/// Toggle enforcement of the whitelist on/off.
/obj/machinery/computer/terminal/proc/turret_whitelist_toggle(obj/machinery/porta_turret/T, mob/user)
	var/current = T.vars["whitelist_active"]
	T.vars["whitelist_active"] = !current
	to_chat(user, span_notice("[T.name] whitelist enforcement [!current ? "ENABLED — unlisted players will be targeted" : "DISABLED — whitelist ignored"]."))

// ============================================================
// DOCUMENT SYSTEM
// ============================================================

/obj/machinery/computer/terminal/proc/build_document_list()
	if(!terminal_documents)
		terminal_documents = list()
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

/obj/machinery/computer/terminal/proc/write_documents()
	build_document_list()

/obj/machinery/computer/terminal/proc/render_document_list()
	if(!terminal_documents || !terminal_documents.len)
		return ""
	var/result = ""
	for(var/i = 1 to terminal_documents.len)
		var/datum/terminal_document/doc = terminal_documents[i]
		result += "<br><a href='byond://?src=[REF(src)];choice=doc_[i]'>&gt;  [doc.title]</a>"
	return result

/obj/machinery/computer/terminal/proc/load_document(index)
	if(!terminal_documents || index < 1 || index > terminal_documents.len)
		return FALSE
	var/datum/terminal_document/doc = terminal_documents[index]
	loaded_title = doc.title
	loaded_content = doc.content
	return TRUE

// ============================================================
// HACKING — SPECIAL INTEGRATION
// ============================================================

/obj/machinery/computer/terminal/proc/get_difficulty_config()
	switch(hack_difficulty)
		if(0) return list(GLOB.HACK_WORDS_4,  8,  4, 1, "VERY EASY")
		if(1) return list(GLOB.HACK_WORDS_5,  8,  4, 2, "EASY")
		if(2) return list(GLOB.HACK_WORDS_6,  10, 4, 3, "AVERAGE")
		if(3) return list(GLOB.HACK_WORDS_8,  12, 3, 5, "HARD")
		if(4) return list(GLOB.HACK_WORDS_10, 12, 3, 7, "VERY HARD")
	return list(GLOB.HACK_WORDS_6, 10, 4, 3, "AVERAGE")

/obj/machinery/computer/terminal/proc/calc_attempts_from_int(mob/living/user)
	var/list/cfg = get_difficulty_config()
	var/base = cfg[3]
	if(!istype(user) || !user.special_i) return base
	switch(user.special_i)
		if(1 to 2)  return max(1, base - 2)
		if(3 to 4)  return max(1, base - 1)
		if(5 to 6)  return base
		if(7 to 8)  return base + 1
		if(9 to 10) return base + 2
	return base

/obj/machinery/computer/terminal/proc/calc_dud_charges_from_int(mob/living/user)
	if(!istype(user) || !user.special_i) return 2
	if(user.special_i >= 8) return 3
	if(user.special_i >= 5) return 2
	return 1

/obj/machinery/computer/terminal/proc/calc_refill_charges_from_int(mob/living/user)
	if(!istype(user) || !user.special_i) return 1
	if(user.special_i >= 9) return 2
	return 1

/obj/machinery/computer/terminal/proc/check_int_gate(mob/living/user)
	if(!istype(user) || !user.special_i) return TRUE
	var/list/cfg = get_difficulty_config()
	var/min_int = cfg[4]
	if(user.special_i < min_int)
		to_chat(user, span_warning("You stare at the terminal blankly. You have no idea where to even begin."))
		return FALSE
	return TRUE

/obj/machinery/computer/terminal/proc/calc_position_hint_from_per(mob/living/user, guess, answer)
	if(!istype(user) || !user.special_p || user.special_p < 7) return null
	var/positions = ""
	for(var/i = 1 to length(guess))
		if(copytext(guess, i, i+1) == copytext(answer, i, i+1))
			positions += "[i] "
	if(!length(positions)) return "No positional matches."
	return "Position[length(positions) > 2 ? "s" : ""]: [trim(positions)]"

/obj/machinery/computer/terminal/proc/check_luck_critfail(mob/living/user)
	if(!istype(user) || !user.special_l) return FALSE
	var/chance = user.get_luck_critfail_chance()
	if(!chance) return FALSE
	return prob(chance)

/obj/machinery/computer/terminal/proc/check_luck_critsuccess(mob/living/user)
	if(!istype(user) || !user.special_l || user.special_l < 8) return FALSE
	return prob(user.special_l - 7)

/obj/machinery/computer/terminal/proc/get_cha_flavour_text(mob/living/user)
	if(!istype(user) || !user.special_c) return null
	if(user.special_c >= 8) return "<span class='dim'>&gt; The terminal seems almost happy to see you.</span>"
	if(user.special_c >= 7) return "<span class='dim'>&gt; The terminal seems welcoming somehow.</span>"
	if(user.special_c <= 2) return "<span class='dim'>&gt; The terminal seems cold and hostile.</span>"
	if(user.special_c <= 3) return "<span class='dim'>&gt; The terminal feels indifferent to your presence.</span>"
	return null

/obj/machinery/computer/terminal/proc/gen_junk(len)
	var/result = ""
	for(var/i = 1 to len)
		result += pick(GLOB.HACK_JUNK_CHARS)
	return result

/obj/machinery/computer/terminal/proc/gen_junk_column(lines, bracket_type)
	if(!lines || lines <= 0) return ""
	var/result = ""
	var/charges = 0
	if(bracket_type == "dud")         charges = hack_dud_charges
	else if(bracket_type == "refill") charges = hack_refill_charges
	var/bracket_count = 0
	if(charges > 0) bracket_count = rand(1, min(3, charges))
	var/list/bracket_lines = list()
	if(bracket_count > 0)
		for(var/i = 1 to bracket_count)
			var/line_num = rand(1, lines)
			bracket_lines[line_num] = TRUE
	for(var/line = 1 to lines)
		var/hex_addr = num2hex(0xF000 + (line - 1) * 16, 4)
		result += "0x[hex_addr] "
		var/junk_before = rand(2, 5)
		result += gen_junk(junk_before)
		if(bracket_lines[line])
			var/bracket_style = pick(list("()", "[]", "{}", "<>"))
			var/open_char  = copytext(bracket_style, 1, 2)
			var/close_char = copytext(bracket_style, 2, 3)
			var/junk_inside = gen_junk(rand(3, 7))
			var/href_action = (bracket_type == "dud") ? "hack_dud" : "hack_refill"
			result += "<a href='byond://?src=[REF(src)];choice=[href_action]'>[open_char][junk_inside][close_char]</a>"
		else
			result += gen_junk(rand(5, 10))
		var/junk_after = rand(2, 5)
		result += gen_junk(junk_after)
		if(line < lines) result += "<br>"
	return result

/obj/machinery/computer/terminal/proc/init_hack(mob/living/user)
	if(!locked || hack_solved || hack_locked_out) return
	var/list/cfg   = get_difficulty_config()
	var/list/pool  = cfg[1]
	var/word_count = cfg[2]
	if(user)
		hack_max            = calc_attempts_from_int(user)
		hack_dud_charges    = calc_dud_charges_from_int(user)
		hack_refill_charges = calc_refill_charges_from_int(user)
	else
		hack_max            = cfg[3]
		hack_dud_charges    = 2
		hack_refill_charges = 1
	hack_attempts = hack_max
	pool = shuffle(pool)
	hack_words = list()
	for(var/i = 1 to min(word_count, pool.len))
		hack_words += pool[i]
	hack_answer = hack_words[rand(1, hack_words.len)]
	hack_duds = list()
	for(var/w in hack_words)
		if(w != hack_answer) hack_duds += w
	hack_removed = list()
	hack_history = list()

// ── Junk / bracket line builder
/obj/machinery/computer/terminal/proc/gen_junk_line(place_bracket)
	if(!place_bracket)
		var/line = ""
		for(var/i = 1 to HACK_COLS)
			line += pick(GLOB.HACK_JUNK_CHARS)
		return list(line, 0, 0)
	var/inner_count = rand(1, 2)
	var/inner_chars = ""
	for(var/i = 1 to inner_count)
		inner_chars += pick(GLOB.HACK_JUNK_CHARS)
		if(i < inner_count) inner_chars += " "
	var/bstyle  = pick("()", "[]", "{}", "<>")
	var/bopen   = copytext(bstyle, 1, 2)
	var/bclose  = copytext(bstyle, 2, 3)
	var/bracket_str   = bopen + " " + inner_chars + " " + bclose
	var/bracket_vis   = length(bracket_str)
	var/bracket_solid = inner_count + 2
	var/junk_budget = HACK_COLS - bracket_solid
	if(junk_budget < 0)
		var/line = ""
		for(var/i = 1 to HACK_COLS)
			line += pick(GLOB.HACK_JUNK_CHARS)
		return list(line, 0, 0)
	var/pre_len  = round(rand(0, junk_budget))
	var/post_len = junk_budget - pre_len
	var/pre_junk = ""
	for(var/i = 1 to pre_len)
		pre_junk += pick(GLOB.HACK_JUNK_CHARS)
	var/post_junk = ""
	for(var/i = 1 to post_len)
		post_junk += pick(GLOB.HACK_JUNK_CHARS)
	var/full_line = pre_junk + bracket_str + post_junk
	return list(full_line, pre_len + 1, pre_len + bracket_vis)

// ── Word line builder
/obj/machinery/computer/terminal/proc/gen_word_line(word)
	var/wlen = length(word)

	// Always space letters: "LETHAL" -> "L E T H A L "
	// Spaces are free — junk budget is based on wlen, not visual width.
	// Long words (8+) just have zero junk padding, which is fine.
	var/spaced_width = (wlen > 1) ? (2 * wlen - 1) : wlen
	var/display_word = ""
	for(var/i = 1 to wlen)
		display_word += copytext(word, i, i + 1)
		display_word += " " // trailing space after every letter, including last
	var/vis_width = spaced_width

	// Junk budget = HACK_COLS - wlen (spaces are free, don't eat junk slots)
	var/junk_budget = max(0, HACK_COLS - wlen)
	var/pre_len     = junk_budget ? round(rand(0, junk_budget)) : 0
	var/post_len    = junk_budget - pre_len

	var/pre_junk = ""
	for(var/i = 1 to pre_len)
		pre_junk += pick(GLOB.HACK_JUNK_CHARS)
	var/post_junk = ""
	for(var/i = 1 to post_len)
		post_junk += pick(GLOB.HACK_JUNK_CHARS)

	return list(pre_junk, display_word, post_junk, vis_width)

// ── Junk to clickable
/obj/machinery/computer/terminal/proc/junk_to_clickable(str)
	if(!str || !length(str)) return ""
	var/result = ""
	for(var/i = 1 to length(str))
		var/ch = copytext(str, i, i + 1)
		result += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[ch]</a>"
	return result

// ============================================================
// LOCK SCREEN RENDER
// ============================================================

/obj/machinery/computer/terminal/proc/render_lock_screen(mob/user)
	if(istype(user, /mob/living) && !hack_locked_out && !hack_solved)
		var/mob/living/L = user
		if(!check_int_gate(L))
			// Show a proper ACCESS DENIED screen instead of silently doing nothing
			var/list/cfg = get_difficulty_config()
			var/min_int = cfg[4]
			var/denied_dat = get_terminal_css()
			denied_dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
			denied_dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
			denied_dat += "= [termtag ? termtag : "BUSINESS"] TERMINAL [termnumber] =</center><br>"
			denied_dat += "<center><span class='bad'>*** ACCESS DENIED ***</span><br><br>"
			denied_dat += "<span class='dim'>THIS TERMINAL REQUIRES INTELLIGENCE [min_int] OR HIGHER.</span><br>"
			denied_dat += "<span class='dim'>YOUR CURRENT INTELLIGENCE IS INSUFFICIENT.</span><br><br>"
			denied_dat += "<span class='dim'>&gt; AUTHORIZATION FAILURE. INCIDENT LOGGED.</span></center>"
			var/datum/browser/denied_popup = new(user, "terminal", null, 620, 540)
			denied_popup.set_content(denied_dat)
			denied_popup.open()
			return

	if(!hack_words || !hack_words.len)
		if(istype(user, /mob/living)) init_hack(user)
		else init_hack()

	var/list/cfg  = get_difficulty_config()
	var/diff_name = cfg[5]
	var/dat = "<head><style>"
	dat += "body{padding:0;margin:10px;background-color:#062113;color:#4aed92;"
	dat += "font-family:'Courier New',Courier,monospace;font-size:13px;line-height:1.3;}"
	dat += "a{color:#4aed92;text-decoration:none;background:transparent;"
	dat += "border:none;padding:0;margin:0;display:inline;cursor:default;}"
	dat += "a:hover{color:#062113;background:#4aed92;cursor:pointer;}"
	dat += "pre{margin:0;padding:0;font-family:'Courier New',Courier,monospace;"
	dat += "font-size:13px;line-height:1.3;display:inline-block;vertical-align:top;}"
	dat += ".dim{color:#2a7a52;}"
	dat += ".bad{color:#c0392b;font-weight:bold;}"
	dat += ".good{color:#4aed92;font-weight:bold;}"
	dat += ".addr{color:#2a7a52;}"
	dat += ".removed{color:#1a5c35;text-decoration:line-through;}"
	dat += ".pip{display:inline-block;width:11px;height:11px;background:#4aed92;margin:0 1px;vertical-align:middle;}"
	dat += ".pip.used{background:#062113;border:1px solid #2a7a52;}"
	dat += ".hist{font-size:90%;color:#2a7a52;font-family:'Courier New',Courier,monospace;}"
	dat += ".hint{color:#4aed92;font-size:90%;font-family:'Courier New',Courier,monospace;}"
	dat += "</style></head>"

	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	dat += "= PASSWORD REQUIRED =</center><br>"

	if(hack_locked_out)
		dat += "<center><span class='bad'>!!! TERMINAL LOCKED — TOO MANY FAILED ATTEMPTS !!!</span><br><br>"
		dat += "<span class='dim'>Use a <b>hacking device</b> on this terminal to attempt a bypass.</span><br>"
		dat += "<span class='dim'>Higher Intelligence improves your speed and success chance.</span><br><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=hack_reset'>&gt; \[ATTEMPT BYPASS\]</a>"
		dat += "</center>"
	else
		if(istype(user, /mob/living))
			var/mob/living/L = user
			var/cha_line = get_cha_flavour_text(L)
			if(cha_line) dat += "[cha_line]<br>"

		dat += "<b>DIFFICULTY:</b> [diff_name] &nbsp; <b>ATTEMPTS:</b> "
		for(var/i = 1 to hack_max)
			dat += "<span class='pip [i <= hack_attempts ? "" : "used"]'></span>"
		dat += "<br>"

		if(istype(user, /mob/living))
			var/mob/living/L = user
			if(L.special_i >= 7)
				dat += "<span class='dim'>&gt; Your intelligence grants additional attempts.</span><br>"
			else if(L.special_i <= 3)
				dat += "<span class='dim'>&gt; Your limited intelligence reduces your attempts.</span><br>"
		dat += "<br>"

		// ── Build columns

		var/mid = round(hack_words.len / 2)
		var/list/left_words  = list()
		var/list/right_words = list()
		for(var/i = 1 to hack_words.len)
			if(i <= mid) left_words  += hack_words[i]
			else         right_words += hack_words[i]

		var/left_brackets  = hack_dud_charges    > 0 ? rand(1, min(3, hack_dud_charges))    : 0
		var/right_brackets = hack_refill_charges > 0 ? rand(1, min(2, hack_refill_charges)) : 0

		dat += "<table style='border:0;border-spacing:8px 0;'><tr>"

		for(var/col = 1 to 2)
			var/list/col_words  = (col == 1) ? left_words  : right_words
			var/bracket_count   = (col == 1) ? left_brackets : right_brackets
			var/bracket_type    = (col == 1) ? "dud" : "refill"
			var/base_addr       = (col == 1) ? 0xF340 : 0xF3E0

			var/list/row_types = list()
			for(var/i = 1 to HACK_ROWS)
				row_types += "junk"

			var/list/available_rows = list()
			for(var/i = 1 to HACK_ROWS) available_rows += i
			available_rows = shuffle(available_rows)

			var/word_slot = 1
			for(var/i = 1 to col_words.len)
				if(word_slot > available_rows.len) break
				row_types[available_rows[word_slot]] = "word_[i]"
				word_slot++

			var/bracket_placed = 0
			for(var/i = word_slot to available_rows.len)
				if(bracket_placed >= bracket_count) break
				row_types[available_rows[i]] = "bracket"
				bracket_placed++

			dat += "<td style='vertical-align:top;padding:0;'><pre>"

			for(var/row = 1 to HACK_ROWS)
				var/hex_val = uppertext(num2hex(base_addr + (row - 1) * 12, 4))
				dat += "<span class='addr'>0x[hex_val]</span> "
				var/rtype = row_types[row]

				if(findtext(rtype, "word_"))
					var/widx = text2num(copytext(rtype, 6))
					if(widx < 1 || widx > col_words.len)
						for(var/j = 1 to HACK_COLS)
							dat += "<a href='byond://?src=[REF(src)];choice=hack_junk'>[pick(GLOB.HACK_JUNK_CHARS)]</a>"
					else
						var/w          = col_words[widx]
						var/list/parts = gen_word_line(w)
						dat += junk_to_clickable(parts[1])
						if(w in hack_removed)
							dat += "<span class='removed'>[parts[2]]</span>"
						else
							dat += "<a href='byond://?src=[REF(src)];choice=hack_word;word=[w]'>[parts[2]]</a>"
						dat += junk_to_clickable(parts[3])

				else if(rtype == "bracket")
					var/list/jline = gen_junk_line(TRUE)
					var/line_str   = jline[1]
					var/bstart     = jline[2]
					var/bend       = jline[3]
					if(!bstart)
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
					var/list/jline = gen_junk_line(FALSE)
					dat += junk_to_clickable(jline[1])

				dat += "\n"

			dat += "</pre></td>"

		dat += "</tr></table>"
		dat += "<span class='dim'>&gt; DUD REMOVALS: [hack_dud_charges] | ATTEMPT REFILLS: [hack_refill_charges]</span><br><br>"

		if(hack_history && hack_history.len)
			dat += "<b>ENTRY LOG:</b><br>"
			for(var/line in hack_history)
				dat += "<span class='hist'>[line]</span><br>"

	dat += "</font>"

	var/datum/browser/popup = new(user, "terminal", null, 620, 540)
	popup.set_content(dat)
	popup.open()

// ============================================================
// HACK PROCESSING
// ============================================================

/obj/machinery/computer/terminal/proc/process_hack_attempt(mob/living/user, word)
	if(!locked || hack_solved || hack_locked_out || !user) return
	if(!check_int_gate(user)) return
	if(!word || !(word in hack_words) || (word in hack_removed)) return
	if(!(word in hack_duds) && word != hack_answer) return

	if(!hack_history) hack_history = list()

	if(word != hack_answer && check_luck_critsuccess(user))
		hack_history += "&gt;Lucky break! System accepted entry."
		word = hack_answer

	if(word == hack_answer)
		hack_solved = TRUE
		locked      = FALSE
		hack_history += "&gt;Entry: [word]"
		hack_history += "<span class='good'>&gt;Exact match. ACCESS GRANTED.</span>"
		to_chat(user, span_nicegreen("ACCESS GRANTED."))
		if(on_hack_success)
			call(on_hack_success)(src, user)
		mode = 0
		ui_interact(user)
		return

	var/likeness = get_likeness(word, hack_answer)
	hack_history += "&gt;Entry: [word]"
	hack_history += "&gt;Likeness: [likeness]/[length(hack_answer)]"

	var/pos_hint = calc_position_hint_from_per(user, word, hack_answer)
	if(pos_hint) hack_history += "<span class='hint'>&gt;[pos_hint]</span>"

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
	var/matches = 0
	var/len     = min(length(guess), length(answer))
	for(var/i = 1 to len)
		if(copytext(guess, i, i+1) == copytext(answer, i, i+1))
			matches++
	return matches

/obj/machinery/computer/terminal/proc/process_hack_junk_click(mob/living/user)
	if(!locked || hack_solved || hack_locked_out || !user) return
	if(!check_int_gate(user)) return
	if(!hack_history) hack_history = list()
	hack_history += "&gt;Entry denied."
	hack_history += "&gt;Invalid selection."
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
	var/removed = hack_duds[rand(1, hack_duds.len)]
	hack_duds.Remove(removed)
	hack_removed += removed
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

// ── Reset / repair the lockout.
// Requires the user to be holding a /obj/item/hacking_device AND pass an INT check.
// INT 4 or below: cannot attempt at all.
// INT 5-6: 30s, 40% chance of success per attempt.
// INT 7-8: 20s, 65% chance.
// INT 9-10: 10s, 90% chance.
// On failure the lockout stays. On success the hack session resets.
/obj/machinery/computer/terminal/proc/reset_hack(mob/living/user)
	if(!user)
		return

	// Must be holding a hacking device — use untyped var to avoid forward-reference errors
	// (hacking_device.dm may be compiled after terminal.dm)
	var/obj/item/H = user.get_active_held_item()
	if(!istype(H, /obj/item/hacking_device))
		to_chat(user, span_warning("You need a hacking device to bypass the lockout."))
		return

	// INT gate — too dumb to even try
	var/int_val = istype(user) ? user.special_i : 5
	if(int_val <= 4)
		to_chat(user, span_warning("You wave the hacking device at the terminal helplessly. You have no idea what you're doing."))
		call(H, "play_denied_anim")()
		return

	// Determine time and success chance from INT
	var/repair_time    = 30 SECONDS
	var/success_chance = 40
	if(int_val >= 9)
		repair_time    = 10 SECONDS
		success_chance = 90
	else if(int_val >= 7)
		repair_time    = 20 SECONDS
		success_chance = 65

	call(H, "start_working_anim")()
	user.visible_message(
		span_notice("[user] connects a hacking device to the terminal and starts working..."),
		span_notice("You start attempting to bypass the terminal lockout. This will take a moment.")
	)

	if(!do_after(user, repair_time, target = src))
		call(H, "stop_working_anim")()
		to_chat(user, span_warning("You were interrupted."))
		return

	call(H, "stop_working_anim")()

	if(!prob(success_chance))
		call(H, "play_denied_anim")()
		playsound(src, 'sound/machines/terminal_alert.ogg', 50, FALSE)
		to_chat(user, span_warning("The terminal rejects the bypass. Try again."))
		if(!hack_history) hack_history = list()
		hack_history += "<span class='bad'>&gt;Bypass attempt rejected.</span>"
		updateUsrDialog()
		return

	// Success
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	user.visible_message(
		span_notice("[user] successfully bypasses the terminal lockout."),
		span_nicegreen("You bypass the lockout. The terminal is ready to be hacked again.")
	)
	hack_locked_out     = FALSE
	hack_solved         = FALSE
	hack_words          = null
	hack_duds           = null
	hack_removed        = null
	hack_answer         = ""
	hack_history        = list()
	init_hack(user)
	updateUsrDialog()

// ============================================================
// LOCKED TERMINAL SUBTYPES
// ============================================================

/obj/machinery/computer/terminal/locked
	name         = "locked terminal"
	desc         = "A RobCo Industries terminal. The screen shows a password prompt."
	locked       = TRUE
	hack_difficulty = 2

/obj/machinery/computer/terminal/locked/Initialize()
	. = ..()
	init_hack()

/obj/machinery/computer/terminal/locked/ui_interact(mob/user)
	if(locked && !hack_solved)
		render_lock_screen(user)
		return
	. = ..()

/obj/machinery/computer/terminal/locked/easy
	name = "security terminal"
	hack_difficulty = 1

/obj/machinery/computer/terminal/locked/hard
	name = "military terminal"
	desc = "A hardened military-grade RobCo terminal. The screen shows a password prompt."
	hack_difficulty = 3

/obj/machinery/computer/terminal/locked/very_hard
	name = "vault security terminal"
	desc = "A high-security Vault-Tec terminal. Access restricted."
	hack_difficulty = 4

/obj/machinery/computer/terminal/locked/vault_security
	name            = "VAULT-TEC SECURITY TERMINAL"
	desc            = "A high-security Vault-Tec terminal. Access is strictly restricted."
	hack_difficulty = 3
	on_hack_success = /proc/vault_terminal_hacked

/proc/vault_terminal_hacked(obj/machinery/computer/terminal/T, mob/living/user)
	for(var/mob/M in world)
		M << "<span style='color:#c0392b'>[T.name]: SECURITY PROTOCOLS BYPASSED. INTRUDER ALERT.</span>"

/obj/machinery/computer/terminal/locked/enclave_comms
	name            = "ENCLAVE COMMUNICATIONS ARRAY"
	desc            = "An Enclave-grade communications terminal. Heavily encrypted."
	hack_difficulty = 4
	on_hack_success = /proc/enclave_terminal_hacked

/proc/enclave_terminal_hacked(obj/machinery/computer/terminal/T, mob/living/user)
	for(var/mob/M in world)
		M << "<span style='color:#c0392b'>ENCLAVE ALERT: COMMUNICATIONS ARRAY COMPROMISED.</span>"

// ============================================================
// GROGNAK TERMINALS
// ============================================================

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
		termnumber = rand(69,420)
	else
		desc = "[initial(desc)] Unfortunately, this one seems to have broken down."

/obj/machinery/computer/terminal/grognak/ui_interact(mob/user)
	. = ..()
	if(broken) return

	var/dat = get_terminal_css()
	dat += "<center><b>GROGNAK THE BARBARIAN: FROM THE DEPTHS OF DOOMTOPIA</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 HUBRIS COMICS</b><br><br>"

	switch(mode)
		if(0)
			dat += "The Goblin war party watches you with trepidation, only the Goblin War Chief seems to possess no fear of you, he chitters arrogantly and his men begin approaching you. You feel the need, the need to cleave."
			dat += "<br><br>FILE SYSTEM"
			dat += render_document_list()
		if(1)
			dat += "The Goblin war party watches you with trepidation, only the Goblin War Chief seems to possess no fear of you, he chitters arrogantly and his men begin approaching you. You feel the need, the need to cleave."
			dat += "<br><br><font face='Courier'>[(!notehtml ? note : notehtml)]</font>"
			dat += get_terminal_footer("<a href='byond://?src=[REF(src)];choice=Edit'>&gt;  Edit</a><br>")
		if(2)
			dat += "[loaded_title]"
			dat += get_terminal_footer()

	dat += "</font></div>"
	var/datum/browser/popup = new(user, "terminal", null, 600, 400)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/terminal/grognak/Topic(href, href_list)
	..()
	var/mob/living/U = usr
	if(!usr.canUseTopic(src) || href_list["close"]) return
	add_fingerprint(U)
	U.set_machine(src)

	if(findtext(href_list["choice"], "doc_"))
		var/idx = text2num(copytext(href_list["choice"], 5))
		if(load_document(idx)) mode = 2
		updateUsrDialog()
		return

	switch(href_list["choice"])
		if("Edit")
			var/n = stripped_multiline_input(U, "Please enter message", name, note, max_length=MAX_MESSAGE_LEN * 4)
			if(in_range(src, U) && mode == 1 && n)
				note = n
				notehtml = parsemarkdown(n, U)
		if("Return")
			if(mode) mode = 0
		if("1")
			mode = 1

	updateUsrDialog()

/obj/machinery/computer/terminal/grognak2
	// Original story by skubblers, #1 jerry reed fan

/obj/machinery/computer/terminal/grognak2/ui_interact(mob/user)
	. = ..()
	if(broken) return

	var/dat = get_terminal_css()
	dat += "<center><b>GROGNAK THE BARBARIAN: THROWING THE DAGGER INTO THE HEART OF THE INVOKER</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 HUBRIS COMICS</b><br><br>"

	switch(mode)
		if(0)
			dat += "Dark incantations reverberate far overhead in the halls of the dreaded Invoker, and your vengeful gaze is drawn to the jeering, demonic murals painted on the apse towering above... their laughter mingles with the INVOKER'S LITANY, as he imbues his putrid congregation with LIES!"
			dat += "<br><br>FILE SYSTEM"
			dat += render_document_list()
		if(1)
			dat += "Dark incantations reverberate far overhead in the halls of the dreaded Invoker, and your vengeful gaze is drawn to the jeering, demonic murals painted on the apse towering above... their laughter mingles with the INVOKER'S LITANY, as he imbues his putrid congregation with LIES!"
			dat += "<br><br><font face='Courier'>[(!notehtml ? note : notehtml)]</font>"
			dat += get_terminal_footer("<a href='byond://?src=[REF(src)];choice=Edit'>&gt;  Edit</a><br>")
		if(2)
			dat += "[loaded_title]"
			dat += get_terminal_footer()

	dat += "</font></div>"
	var/datum/browser/popup = new(user, "terminal", null, 600, 400)
	popup.set_content(dat)
	popup.open()

/**
 * lockpick_minigame.dm
 *
 * Semi-interactive lockpicking mini-game with full depth mechanics.
 *
 * Features:
 *  1. Pin tension: too many moves on one pin snaps the pick and jams the lock
 *  2. Pin decay: tier 3+ locks may shake loose a set pin when advancing
 *  3. Move skill check: low Agility may add extra tension per move
 *  4. False zones: tier 4+ locks have a deceptive fake "set" position
 *  5. Specialized picks: tension wrench, bobby pin, electronic pick
 *  6. Pick degradation: heavy use consumes extra pick durability on end
 *  7. Locksmith bonus: Agility 8+ widens each pin's correct zone
 *  8. Sound cues: distinct sounds for hot/cold, false set, and snap
 *  9. Interruption: dying while picking jams the lock if attempts were made
 * 10. Jammed locks: use a crowbar to reset a jammed lock mechanism
 * 11. Partial credit: give_up saves set pins for the next pick attempt
 */

// =====================================================
// GLOBAL STATE
// =====================================================

/// Stores partial pin progress between lockpick attempts. Key = "\ref[target]".
GLOBAL_LIST_EMPTY(lockpick_partial_states)

// =====================================================
// LOCKPICK SET VARIANTS
// =====================================================

/// Standard master set — more uses and better zone widening.
/obj/item/lockpick_set/master
	name = "master lockpicking set"
	desc = "A high-quality set of picks and tension wrenches favored by experienced thieves. More durable than a basic set."
	icon_state = "basic_lockpick"
	uses_left = 10

/obj/item/lockpick_set/master/Initialize()
	. = ..()
	uses_left = rand(6, initial(src.uses_left))

/// Tension wrench kit — halves pin decay chance. Good for stubborn higher-tier locks.
/obj/item/lockpick_set/tension_wrench
	name = "tension wrench kit"
	desc = "Specialized interchangeable tension wrenches. Keeps pins in place better than a full set, but offers no other advantages."
	icon_state = "basic_lockpick"
	uses_left = 8

/obj/item/lockpick_set/tension_wrench/Initialize()
	. = ..()
	uses_left = rand(4, initial(src.uses_left))

/// Bobby pin — improvised, fragile, only works on tier 1–2 locks.
/obj/item/lockpick_set/bobby_pin
	name = "bobby pin"
	desc = "A bent hairpin pressed into service as a lockpick. Barely holds together, but it can open simple locks in a pinch."
	icon_state = "basic_lockpick"
	uses_left = 3

/obj/item/lockpick_set/bobby_pin/Initialize()
	. = ..()
	uses_left = rand(1, initial(src.uses_left))

/// Electronic pick — auto-sets the first pin via vibration. Expensive and fragile.
/obj/item/lockpick_set/electronic_pick
	name = "electronic lock pick"
	desc = "A motorized pick that vibrates to find the first pin's position automatically. Batteries included; discretion sold separately."
	icon_state = "basic_lockpick"
	uses_left = 4

/obj/item/lockpick_set/electronic_pick/Initialize()
	. = ..()
	uses_left = rand(2, initial(src.uses_left))

// =====================================================
// LOCKPICKING MINI-GAME DATUM
// =====================================================

/datum/lockpicking_minigame
	/// The object being lockpicked (door or locked_box)
	var/atom/target
	/// The player performing the lockpick
	var/mob/user
	/// The lockpick set being used
	var/obj/item/lockpick_set/pick
	/// Lock difficulty tier 1–5
	var/lock_tier = 1
	/// User's Luck SPECIAL stat (1–10)
	var/luck = 5
	/// User's Agility SPECIAL stat (1–10)
	var/agility = 5
	/// User's Perception SPECIAL stat (1–10) — controls hint detail level
	var/perception = 5
	/// TRUE if the target turf is unlit (reduces effective zone size by 1)
	var/dark_penalty = FALSE
	/// TRUE if user has heavy injuries (adds extra tension chance per move)
	var/pain_penalty = FALSE
	/// TRUE if user is wearing gloves (treats Agility as 1 lower for tension)
	var/glove_penalty = FALSE
	/// Whether a master lockpick is being used
	var/is_master_pick = FALSE
	/// Whether a tension wrench is being used (halves pin decay chance)
	var/is_tension_wrench = FALSE
	/// Whether a bobby pin is being used (tier cap: 2)
	var/is_bobby_pin = FALSE
	/// Whether an electronic pick is being used (auto-sets pin 1)
	var/is_electronic_pick = FALSE

	/// List of assoc lists per pin:
	///   "pos", "min", "max", "set", "hint", "last_dir", "last_move",
	///   "moves" (tension counter), "false_min", "false_max",
	///   "tried" (list of positions attempted), "tried_hints" (pos->hint map),
	///   "last_pos" (pos at last failed set_pin), "spool", "security", "decayed"
	var/list/pins = null
	/// Index of the currently active pin (1-indexed)
	var/current_pin = 1
	/// Maximum attempts before game over
	var/max_attempts = 5
	/// Remaining failed set_pin attempts
	var/attempts_left = 5
	/// Total moves made across all pins (for pick degradation)
	var/total_moves = 0
	/// TRUE after the first set_pin attempt is made (for interruption jamming)
	var/attempt_made = FALSE
	/// Ref string of target, stored for partial-state timer cleanup
	var/partial_state_ref = ""

	/// Set TRUE when the UI window closes, ending wait()
	var/closed = FALSE
	/// Game phase: "picking", "success", "failed"
	var/phase = "picking"
	/// Last feedback message shown in the UI
	var/feedback = ""
	/// null = in progress, TRUE = success, FALSE = fail/cancel
	var/result = null
	/// Whether the user was anchored before lockpicking began (restored on Destroy)
	var/was_anchored = FALSE

/datum/lockpicking_minigame/New(atom/the_target, mob/the_user, obj/item/lockpick_set/the_pick, tier)
	target    = the_target
	user      = the_user
	pick      = the_pick
	lock_tier = clamp(tier, 1, 5)
	luck      = the_user.special_l
	if(isliving(the_user))
		agility    = the_user.special_a
		perception = the_user.special_p
		// Injury penalty: shaking hands if badly hurt
		var/mob/living/L = the_user
		var/total_dmg = L.getBruteLoss() + L.getFireLoss()
		if(total_dmg > 60)
			pain_penalty = TRUE
	// Environmental penalties — computed once at game start
	var/turf/target_turf = get_turf(the_target)
	if(target_turf && target_turf.is_softly_lit())
		dark_penalty = TRUE
	if(iscarbon(the_user))
		var/mob/living/carbon/C = the_user
		if(C.gloves)
			glove_penalty = TRUE
	is_master_pick     = istype(the_pick, /obj/item/lockpick_set/master)
	is_tension_wrench  = istype(the_pick, /obj/item/lockpick_set/tension_wrench)
	is_bobby_pin       = istype(the_pick, /obj/item/lockpick_set/bobby_pin)
	is_electronic_pick = istype(the_pick, /obj/item/lockpick_set/electronic_pick)

	// Bobby pin cannot handle tier 3+ locks
	if(is_bobby_pin && lock_tier > 2)
		feedback = "Your bobby pin is too flimsy for this lock — it needs a proper pick."
		phase = "failed"
		result = FALSE
		ui_interact(the_user)
		addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
		return

	generate_pins()

	// Warn about active penalties
	var/list/penalty_warnings = list()
	if(dark_penalty)
		penalty_warnings += "darkness"
	if(pain_penalty)
		penalty_warnings += "your injuries"
	if(glove_penalty)
		penalty_warnings += "your gloves"
	if(penalty_warnings.len)
		to_chat(the_user, span_warning("WARNING: [english_list(penalty_warnings)] will make this harder."))

	// Electronic pick auto-sets pin 1
	if(is_electronic_pick && pins.len >= 1)
		pins[1]["set"] = TRUE
		current_pin = 2
		feedback = "The electronic pick buzzes — pin 1 located automatically! Handle the rest manually."
		playsound(get_turf(target), 'sound/machines/button1.ogg', 50, FALSE, -3)
	else
		feedback = "Insert your pick and find the correct position for each pin. You can focus any pin freely."

	// Load partial save state from a previous give_up (tension wrench only), if any
	var/ref = "\ref[the_target]"
	if(GLOB.lockpick_partial_states[ref])
		var/list/saved = GLOB.lockpick_partial_states[ref]
		GLOB.lockpick_partial_states -= ref
		// Restore set-pin indices
		var/list/set_indices = saved["set"]
		for(var/idx in set_indices)
			if(idx <= pins.len && !pins[idx]["set"])
				pins[idx]["set"] = TRUE
		// Restore per-pin memory (tried positions, hints)
		var/list/pin_memory = saved["memory"]
		if(pin_memory)
			for(var/key in pin_memory)
				var/idx2 = text2num(key)
				if(idx2 >= 1 && idx2 <= pins.len)
					var/list/mem = pin_memory[key]
					var/list/tried_restore = mem["tried"]
					pins[idx2]["hint"]     = mem["hint"]
					pins[idx2]["last_dir"] = mem["last_dir"]
					pins[idx2]["last_pos"] = mem["last_pos"]
					if(tried_restore)
						pins[idx2]["tried"] = tried_restore
					if(mem["tried_hints"])
						pins[idx2]["tried_hints"] = mem["tried_hints"]
		// Advance current_pin to the first unset pin
		current_pin = 1
		while(current_pin <= pins.len && pins[current_pin]["set"])
			current_pin++
		var/loaded = set_indices.len
		if(current_pin <= pins.len)
			feedback = "Your tension wrench held — [loaded] [loaded == 1 ? "pin" : "pins"] already set. You remember your previous attempts."

	// Anchor the user — prevents Move() from being called at all by the BYOND
	// client, which stops bump sounds when pressing movement keys near the door.
	was_anchored = user.anchored
	user.anchored = TRUE

	// Register death signal for interruption handling
	RegisterSignal(user, COMSIG_MOB_DEATH, PROC_REF(on_user_death))
	// Block movement while picking — prevents WASD from walking away
	RegisterSignal(user, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(block_user_move))
	// Interrupt picking when struck — getting hit breaks concentration
	RegisterSignal(user, COMSIG_MOB_ATTACK_HAND, PROC_REF(on_user_hit))
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_user_hit))

	ui_interact(the_user)

/datum/lockpicking_minigame/Destroy()
	if(user && !QDELETED(user))
		user.anchored = was_anchored
		UnregisterSignal(user, list(COMSIG_MOB_DEATH, COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOB_ATTACK_HAND, COMSIG_MOB_ITEM_ATTACK))
	SStgui.close_uis(src)
	return ..()

/// Blocks player movement and restores facing toward the target while picking.
/datum/lockpicking_minigame/proc/block_user_move(datum/source)
	SIGNAL_HANDLER
	var/face_dir = get_dir(user, target)
	if(face_dir)
		user.setDir(face_dir)
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/**
 * Generates the pin array based on lock tier, Luck, Agility, and pick type.
 * Tier 4+ pins also get a false zone — a deceptive fake "correct" position.
 */
/datum/lockpicking_minigame/proc/generate_pins()
	var/num_pins
	var/base_zone_size
	switch(lock_tier)
		if(1)
			num_pins = 2
			base_zone_size = 4
		if(2)
			num_pins = 3
			base_zone_size = 3
		if(3)
			num_pins = 3
			base_zone_size = 3  // was 2 — spool pins add difficulty on tier 3+
		if(4)
			num_pins = 4
			base_zone_size = 2
		if(5)
			num_pins = 5
			base_zone_size = 2  // was 1 — spool/security/false zones add enough difficulty

	// Luck bonus: (1–3) = -1, (4–6) = 0, (7–8) = +1, (9–10) = +2
	var/luck_bonus      = clamp(round((luck - 4.5) / 2), -1, 2)
	// Locksmith bonus: Agility 8+ widens zones by 1
	var/locksmith_bonus = (agility >= 8) ? 1 : 0
	// Pick bonus: master or electronic pick widens zones by 1
	var/pick_bonus      = (is_master_pick || is_electronic_pick) ? 1 : 0
	// Darkness penalty: can't see the lock well
	var/dark_mod        = dark_penalty ? -1 : 0
	var/zone_size = clamp(base_zone_size + luck_bonus + locksmith_bonus + pick_bonus + dark_mod, 1, 7)

	// Attempts: base 7, minus tier, plus luck/pick bonuses; minimum 2
	max_attempts  = max(7 - lock_tier + luck_bonus + (pick_bonus * 2), 2)
	attempts_left = max_attempts

	pins = list()
	for(var/i in 1 to num_pins)
		var/max_start = max(10 - zone_size, 1)
		var/min_pos   = rand(1, max_start)
		var/max_pos   = min(min_pos + zone_size - 1, 10)
		// False zone for tier 4+ — a single non-overlapping decoy position
		var/false_min = 0
		var/false_max = 0
		if(lock_tier >= 4)
			var/tries = 10
			while(tries > 0)
				var/candidate = rand(1, 10)
				if(candidate < min_pos - 1 || candidate > max_pos + 1)
					false_min = candidate
					false_max = candidate
					break
				tries--
		// Spool pins (tier 3+): must be approached from below (last move upward) to set.
		var/is_spool = FALSE
		if(lock_tier >= 3 && !is_bobby_pin)
			var/spool_chance = (lock_tier - 2) * 20  // 20% / 40% / 60% for tiers 3/4/5
			if(prob(spool_chance))
				is_spool = TRUE
				min_pos = max(min_pos, 3)  // ensure room to approach from below
				max_pos = min(min_pos + zone_size - 1, 10)
		// Security pins (tier 4+): a failed set attempt jars loose a neighboring set pin.
		// A pin cannot be both spool and security.
		var/is_security = FALSE
		if(lock_tier >= 4 && !is_spool && !is_bobby_pin)
			var/sec_chance = (lock_tier - 3) * 30  // 30% / 60% for tiers 4/5
			is_security = prob(sec_chance)
		pins += list(list(
			"pos"         = 5,
			"min"         = min_pos,
			"max"         = max_pos,
			"set"         = FALSE,
			"hint"        = -1,         // distance from real zone on last attempt; -1 = no attempt
			"last_dir"    = 0,          // 1 = go up, -1 = go down
			"last_pos"    = 0,          // pin position at time of last failed set attempt
			"last_move"   = 0,          // direction of last move on this pin (1 = up, -1 = down)
			"moves"       = 0,          // move count for tension mechanic
			"false_min"   = false_min,
			"false_max"   = false_max,
			"tried"       = list(),     // positions that produced a failed set_pin
			"tried_hints" = list(),     // assoc: position string -> hint distance
			"spool"       = is_spool,   // must approach from below to set correctly
			"security"    = is_security,// failed set jars loose a neighboring set pin
			"decayed"     = FALSE       // was previously set then vibrated loose
		))

/// Sleeps until the mini-game is fully resolved (closed = TRUE).
/datum/lockpicking_minigame/proc/wait()
	while(!closed && !QDELETED(src))
		if(!QDELETED(user) && user.stat >= UNCONSCIOUS && phase == "picking")
			on_user_incapacitated()
		stoplag(1)

/// Called when the user goes unconscious mid-pick (detected in wait loop).
/datum/lockpicking_minigame/proc/on_user_incapacitated()
	if(phase != "picking")
		return
	phase  = "failed"
	result = FALSE
	if(attempt_made)
		feedback = "You fall unconscious! Your pick jams the lock as you slump."
		jam_target()
	else
		feedback = "You fall unconscious! Your pick slips free of the lock."
	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(close_ui)), 1.5 SECONDS)

/// Signal handler — fires when the user is struck while picking.
/datum/lockpicking_minigame/proc/on_user_hit(datum/source)
	SIGNAL_HANDLER
	if(phase != "picking")
		return
	phase  = "failed"
	result = FALSE
	save_partial_state()  // saves pins only if using tension_wrench or master pick
	if(is_tension_wrench || is_master_pick)
		feedback = "You're struck! The shock breaks your focus, but your tension wrench holds the pins."
	else
		feedback = "You're struck! The blow jolts your hand and the pick slips free."
	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(close_ui)), 1.5 SECONDS)

/// Signal handler — fires when the user mob dies.
/datum/lockpicking_minigame/proc/on_user_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(phase != "picking")
		return
	phase  = "failed"
	result = FALSE
	if(attempt_made)
		jam_target()
		feedback = "You die! Your pick jams the lock as you collapse."
	else
		feedback = "You die! Your pick clatters away from the lock."
	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(close_ui)), 1.5 SECONDS)

/// Marks the target lock as jammed (requires crowbar to reset).
/datum/lockpicking_minigame/proc/jam_target()
	if(istype(target, /obj/structure/simple_door))
		var/obj/structure/simple_door/D = target
		D.lockpick_jammed = TRUE
		D.visible_message(span_warning("The lock of [D] grinds and jams solid!"))
	else if(istype(target, /obj/item/locked_box))
		var/obj/item/locked_box/B = target
		B.lockpick_jammed = TRUE
		if(!QDELETED(user))
			to_chat(user, span_warning("The lock jams completely. Use a crowbar to reset the mechanism before trying again."))
	else if(istype(target, /obj/machinery/door))
		var/obj/machinery/door/D = target
		D.lockpick_jammed = TRUE
		D.visible_message(span_warning("The lock of [D] grinds and jams solid!"))

/**
 * Saves the current set pins to the global partial state for this target.
 * Called on give_up so the next pick attempt can resume from here.
 * The state expires after 60 seconds.
 */
/datum/lockpicking_minigame/proc/save_partial_state()
	// Only tension wrenches (and master sets) can hold pins after give_up
	if(!is_tension_wrench && !is_master_pick)
		return
	var/list/set_indices = list()
	for(var/i in 1 to length(pins))
		if(pins[i]["set"])
			set_indices += i
	if(!set_indices.len)
		return
	// Collect per-pin memory (tried positions and last hint) for lock memory
	var/list/pin_memory = list()
	for(var/i in 1 to length(pins))
		var/list/pin = pins[i]
		var/list/pin_tried = pin["tried"]
		if(pin_tried && length(pin_tried) > 0 || pin["hint"] >= 0)
			pin_memory[num2text(i)] = list(
				"hint"        = pin["hint"],
				"last_dir"    = pin["last_dir"],
				"last_pos"    = pin["last_pos"],
				"tried"       = pin_tried,
				"tried_hints" = pin["tried_hints"]
			)
	partial_state_ref = "\ref[target]"
	GLOB.lockpick_partial_states[partial_state_ref] = list("set" = set_indices, "memory" = pin_memory)
	addtimer(CALLBACK(src, PROC_REF(expire_partial_state)), 60 SECONDS)
	var/n = set_indices.len
	if(!QDELETED(user))
		to_chat(user, span_notice("You ease your [is_master_pick ? "tension wrench" : "pick"] to hold the pins — [n] [n == 1 ? "pin stays" : "pins stay"] set. Continue within 60 seconds."))

/datum/lockpicking_minigame/proc/expire_partial_state()
	if(partial_state_ref)
		GLOB.lockpick_partial_states -= partial_state_ref

/**
 * Finalizes pick durability at the end of the game.
 * Handles in_use = FALSE, one standard use, plus extra uses from heavy play.
 * Call this instead of pick.in_use = FALSE + pick.use_pick(user) in calling code.
 */
/datum/lockpicking_minigame/proc/finalize(mob/finalize_user)
	if(QDELETED(pick))
		return
	pick.in_use = FALSE
	// Extra durability drain: every 5 total moves = 1 extra use beyond the standard 1
	var/extra_uses = max(0, round(total_moves / 5) - 1)
	for(var/i in 1 to extra_uses)
		if(QDELETED(pick))
			break
		pick.use_pick(finalize_user)
	if(!QDELETED(pick))
		pick.use_pick(finalize_user)

/datum/lockpicking_minigame/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Lockpicking", "Lock Picking")
		ui.open()

/datum/lockpicking_minigame/ui_state(mob/user)
	return GLOB.always_state

/datum/lockpicking_minigame/ui_data(mob/user)
	var/list/data = list()
	var/list/pin_data = list()
	var/pins_set = 0
	for(var/i in 1 to pins.len)
		var/list/pin = pins[i]
		if(pin["set"])
			pins_set++
		// Tension: 0–5 scale (moves / 2, clamped)
		var/tension = clamp(round(pin["moves"] / 2.0), 0, 5)
		var/list/pin_tried_ui = pin["tried"]
		pin_data += list(list(
			"pos"        = pin["pos"],
			"set"        = pin["set"],
			"active"     = (i == current_pin && phase == "picking" && !pin["set"]),
			"hint"       = pin["hint"],
			"lastDir"    = pin["last_dir"],
			"lastPos"    = pin["last_pos"],
			"lastMove"   = pin["last_move"],
			"tension"    = tension,
			"tried"      = pin_tried_ui,
			"triedHints" = pin["tried_hints"],
			"spool"      = pin["spool"],
			"security"   = pin["security"],
			"decayed"    = pin["decayed"]
		))
	data["pins"]         = pin_data
	data["pinsSet"]      = pins_set
	data["currentPin"]   = current_pin
	data["attemptsLeft"] = attempts_left
	data["maxAttempts"]  = max_attempts
	data["phase"]        = phase
	data["feedback"]     = feedback
	data["lockTier"]     = lock_tier
	data["luck"]         = luck
	data["perception"]    = perception
	data["isMasterPick"]  = is_master_pick
	data["totalPins"]     = pins.len
	data["isDark"]        = dark_penalty
	data["isHurt"]        = pain_penalty
	data["wearingGloves"] = glove_penalty
	return data

/datum/lockpicking_minigame/ui_close(mob/user)
	. = ..()
	closed = TRUE
	if(isnull(result))
		result = FALSE

/datum/lockpicking_minigame/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(phase != "picking")
		return

	// Guard: after non-linear play current_pin may sit past the end of the list.
	var/list/cur_pin = (current_pin >= 1 && current_pin <= pins.len) ? pins[current_pin] : null

	switch(action)
		if("move_up")
			// Tension snap check before moving
			if(cur_pin["moves"] >= 10)
				snap_pick()
				return TRUE
			var/up_cost = agility_tension_cost()
			// Electronic pick motor stall: pins 3+ have a 15% chance of extra tension per move
			if(is_electronic_pick && current_pin >= 3 && prob(15))
				up_cost++
				feedback = "The pick's motor stutters — extra tension!"
			cur_pin["moves"] = min(cur_pin["moves"] + up_cost, 10)
			if(cur_pin["pos"] < 10)
				cur_pin["pos"]++
			cur_pin["last_move"] = 1
			total_moves++
			update_tension_feedback(cur_pin["moves"])
			. = TRUE

		if("move_down")
			// Tension snap check before moving
			if(cur_pin["moves"] >= 10)
				snap_pick()
				return TRUE
			var/down_cost = agility_tension_cost()
			// Electronic pick motor stall: pins 3+ have a 15% chance of extra tension per move
			if(is_electronic_pick && current_pin >= 3 && prob(15))
				down_cost++
				feedback = "The pick's motor stutters — extra tension!"
			cur_pin["moves"] = min(cur_pin["moves"] + down_cost, 10)
			if(cur_pin["pos"] > 1)
				cur_pin["pos"]--
			cur_pin["last_move"] = -1
			total_moves++
			update_tension_feedback(cur_pin["moves"])
			. = TRUE

		if("select_pin")
			// Non-linear pin focus: player can work on any unset pin freely
			var/pin_idx = text2num(params["pin"])
			if(!pin_idx || pin_idx < 1 || pin_idx > pins.len)
				return
			if(pins[pin_idx]["set"])
				return  // already set, nothing to do
			current_pin = pin_idx
			var/list/tpin = pins[pin_idx]
			if(tpin["hint"] >= 0)
				feedback = "Focusing pin [pin_idx]. You remember it last went [tpin["last_dir"] > 0 ? "too low" : "too high"]."
			else
				feedback = "Focusing pin [pin_idx]."
			. = TRUE

		if("set_pin")
			var/pos = cur_pin["pos"]
			attempt_made = TRUE

			// --- False zone check (tier 4+ only) ---
			if(cur_pin["false_min"] > 0 && pos >= cur_pin["false_min"] && pos <= cur_pin["false_max"])
				attempts_left--
				cur_pin["pos"]   = 5
				cur_pin["moves"] = 0
				// Brief success click then a rejection scrape
				playsound(get_turf(target), 'sound/machines/button1.ogg', 40, FALSE, -3)
				playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 50, TRUE, -4)
				if(attempts_left <= 0)
					feedback = "The false groove fools you once too often — you're out of attempts."
					phase    = "failed"
					result   = FALSE
					jam_target()
					addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
				else
					feedback = "The pin clicks firmly... then springs back out! A false groove — don't be tricked again."
					if(attempts_left == 1)
						feedback += " (WARNING: One attempt left!)"
				. = TRUE
				return .

			// --- Real zone check ---
			if(pos >= cur_pin["min"] && pos <= cur_pin["max"])
				// Spool pin: must be approached from below (last_move upward).
				// Descending into the zone creates a false click that springs back out.
				if(cur_pin["spool"] && cur_pin["last_move"] == -1)
					cur_pin["pos"]   = max(cur_pin["min"] - 2, 1)
					cur_pin["moves"] = 0
					cur_pin["last_move"] = 0
					playsound(get_turf(target), 'sound/machines/button1.ogg', 40, FALSE, -3)
					playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 45, TRUE, -4)
					feedback = "The pin clicks... then springs back! It's a spool pin — approach from lower positions (move up into the zone)."
					. = TRUE
					return .
				cur_pin["set"]   = TRUE
				cur_pin["moves"] = 0
				playsound(get_turf(target), 'sound/machines/button1.ogg', 50, FALSE, -3)
				// Advance past already-set pins
				var/just_set = current_pin
				current_pin++
				while(current_pin <= pins.len && pins[current_pin]["set"])
					current_pin++
				// If we overshot (non-linear play left earlier pins unset), wrap to first unset pin
				if(current_pin > pins.len)
					for(var/j in 1 to pins.len)
						if(!pins[j]["set"])
							current_pin = j
							break
				// Check for pin decay on tier 3+ locks
				var/decayed = maybe_decay_pins(just_set)
				if(all_pins_set())
					phase    = "success"
					feedback = "The lock clicks open!"
					result   = TRUE
					playsound(get_turf(target), 'sound/machines/BoltsUp.ogg', 60, FALSE, -4)
					addtimer(CALLBACK(src, PROC_REF(close_ui)), 1.5 SECONDS)
				else if(decayed > 0)
					current_pin = decayed
					feedback = "Pin [just_set] set — but pin [decayed] vibrates loose and slips back! Refocus."
					playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 40, TRUE, -4)
				else
					feedback = "Pin [just_set] set. Moving to pin [current_pin]..."

			else
				// Wrong position — spring back and consume an attempt
				attempts_left--
				var/dist_to_zone
				var/direction
				if(pos < cur_pin["min"])
					dist_to_zone = cur_pin["min"] - pos
					direction    = 1
				else
					dist_to_zone = pos - cur_pin["max"]
					direction    = -1
				cur_pin["hint"]     = dist_to_zone
				cur_pin["last_dir"] = direction
				cur_pin["last_pos"] = pos
				if(!(cur_pin["tried"] ~! pos))  // only add to tried if not already there
					cur_pin["tried"] += pos
					cur_pin["tried_hints"]["[pos]"] = dist_to_zone
				cur_pin["pos"]      = 5
				cur_pin["moves"]    = 0  // reset tension after a set attempt

				// Warmer sound for close attempts, colder thud for far misses
				if(dist_to_zone <= 2)
					playsound(get_turf(target), 'sound/items/screwdriver2.ogg', 45, TRUE, -4)
				else
					playsound(get_turf(target), 'sound/items/screwdriver.ogg', 55, TRUE, -4)

				var/dir_text = direction == 1 ? "too low — try going higher" : "too high — try going lower"
				switch(dist_to_zone)
					if(1)
						feedback = "Almost! The pin nearly catches — [dir_text] by just one notch!"
					if(2)
						feedback = "The pin gives slightly — [dir_text]. Getting warmer..."
					if(3)
						feedback = "The pick slips — [dir_text]. Not quite there."
					else
						feedback = "The pin springs back hard — [dir_text]. Way off the mark."

				// Security pin: a failed set attempt jars loose the nearest set pin
				if(cur_pin["security"])
					var/nearest_dist = 999
					var/reset_idx = 0
					for(var/j in 1 to pins.len)
						if(j != current_pin && pins[j]["set"])
							var/d = abs(j - current_pin)
							if(d < nearest_dist)
								nearest_dist = d
								reset_idx = j
					if(reset_idx > 0)
						pins[reset_idx]["set"]     = FALSE
						pins[reset_idx]["pos"]     = 5
						pins[reset_idx]["moves"]   = 0
						pins[reset_idx]["decayed"] = TRUE
						if(current_pin > pins.len || pins[current_pin]["set"])
							current_pin = reset_idx
						feedback += " The serrated pin catches — pin [reset_idx] jolts loose!"
						playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 60, TRUE, -3)

				// Bobby pin breakage: 25% chance to snap on each failed attempt
				if(is_bobby_pin && attempts_left > 0 && prob(25))
					feedback += " The bobby pin snaps!"
					phase  = "failed"
					result = FALSE
					if(!QDELETED(pick))
						qdel(pick)
					addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
					. = TRUE
					return .
				if(attempts_left <= 0)
					phase    = "failed"
					result   = FALSE
					feedback = "You've exhausted your attempts. The lock defeats you."
					jam_target()
					addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
				else if(attempts_left == 1)
					feedback += " (WARNING: One attempt left!)"
			. = TRUE

		if("give_up")
			save_partial_state()
			phase    = "failed"
			feedback = "You carefully withdraw your lockpick."
			result   = FALSE
			addtimer(CALLBACK(src, PROC_REF(close_ui)), 0.5 SECONDS)
			. = TRUE

/**
 * Returns the tension cost for a single move.
 * Low Agility has a chance to add extra tension (clumsy handling).
 */
/datum/lockpicking_minigame/proc/agility_tension_cost()
	// Glove penalty: treat agility as 1 lower (less fine motor control)
	var/eff_agility = glove_penalty ? max(1, agility - 1) : agility
	// Pain penalty: extra 15% chance of double tension (shaking hands)
	var/pain_mod = pain_penalty ? 15 : 0
	if(eff_agility <= 3)
		return prob(30 + pain_mod) ? 2 : 1
	if(eff_agility < 6)
		return prob(15 + pain_mod) ? 2 : 1
	if(pain_mod && prob(pain_mod))
		return 2  // Even skilled hands tremble when badly hurt
	return 1

/// Updates feedback with tension warnings when pins are near snapping.
/datum/lockpicking_minigame/proc/update_tension_feedback(moves)
	if(moves >= 9)
		feedback = "WARNING: The pick is about to snap — set it now or you'll jam the lock!"
	else if(moves >= 6)
		feedback = "The tension is building... set the pin soon or risk snapping the pick!"

/// Snaps the pick from excessive tension. Jams the lock and destroys the pick.
/datum/lockpicking_minigame/proc/snap_pick()
	phase    = "failed"
	result   = FALSE
	feedback = "You overtorque the pick — SNAP! The mechanism jams. You'll need a crowbar."
	playsound(get_turf(target), 'sound/items/Wirecutter.ogg', 100, TRUE, -2)
	jam_target()
	if(!QDELETED(pick))
		qdel(pick)
	addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)

/// Returns TRUE if every pin in the list is set.
/datum/lockpicking_minigame/proc/all_pins_set()
	for(var/list/pin in pins)
		if(!pin["set"])
			return FALSE
	return TRUE

/**
 * After advancing past a freshly-set pin, checks if any previously set pin
 * vibrates loose (tier 3+ mechanic). Tension wrenches halve the chance.
 * Returns the index of the decayed pin (0 if none decayed).
 */
/datum/lockpicking_minigame/proc/maybe_decay_pins(just_set_pin)
	if(lock_tier < 3 || just_set_pin <= 1)
		return 0
	var/decay_chance = (lock_tier - 2) * 10  // 10% / 20% / 30% for tiers 3/4/5
	if(is_tension_wrench)
		decay_chance = round(decay_chance * 0.5)
	decay_chance = max(0, decay_chance - luck * 2)  // Luck reduces decay
	for(var/i in 1 to just_set_pin - 1)
		if(pins[i]["set"] && prob(decay_chance))
			pins[i]["set"]     = FALSE
			pins[i]["pos"]     = 5
			pins[i]["moves"]   = 0
			pins[i]["decayed"] = TRUE
			// Keep hint/last_dir so the player retains positional memory
			return i
	return 0

/// Closes the TGUI after a short delay so the player can read the outcome.
/datum/lockpicking_minigame/proc/close_ui()
	SStgui.close_uis(src)

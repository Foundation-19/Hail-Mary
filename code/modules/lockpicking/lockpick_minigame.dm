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
	/// Whether a master lockpick is being used
	var/is_master_pick = FALSE
	/// Whether a tension wrench is being used (halves pin decay chance)
	var/is_tension_wrench = FALSE
	/// Whether a bobby pin is being used (tier cap: 2)
	var/is_bobby_pin = FALSE
	/// Whether an electronic pick is being used (auto-sets pin 1)
	var/is_electronic_pick = FALSE

	/// List of assoc lists per pin:
	///   "pos", "min", "max", "set", "hint", "last_dir",
	///   "moves" (tension counter), "false_min", "false_max"
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

	/// Game phase: "picking", "success", "failed"
	var/phase = "picking"
	/// Last feedback message shown in the UI
	var/feedback = ""
	/// null = in progress, TRUE = success, FALSE = fail/cancel
	var/result = null
	/// Set TRUE when the UI window closes, ending wait()
	var/closed = FALSE

/datum/lockpicking_minigame/New(atom/the_target, mob/the_user, obj/item/lockpick_set/the_pick, tier)
	target    = the_target
	user      = the_user
	pick      = the_pick
	lock_tier = clamp(tier, 1, 5)
	luck      = the_user.special_l
	if(isliving(the_user))
		agility = the_user.special_a
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

	// Electronic pick auto-sets pin 1
	if(is_electronic_pick && pins.len >= 1)
		pins[1]["set"] = TRUE
		current_pin = 2
		feedback = "The electronic pick buzzes — pin 1 located automatically! Handle the rest manually."
		playsound(get_turf(target), 'sound/machines/button1.ogg', 50, FALSE, -3)
	else
		feedback = "Insert your pick and find the correct position for each pin."

	// Load partial save state from a previous give_up, if any
	var/ref = "\ref[the_target]"
	if(GLOB.lockpick_partial_states[ref])
		var/list/saved = GLOB.lockpick_partial_states[ref]
		GLOB.lockpick_partial_states -= ref
		for(var/idx in saved)
			if(idx <= pins.len && !pins[idx]["set"])
				pins[idx]["set"] = TRUE
		// Advance current_pin past already-set pins
		current_pin = 1
		while(current_pin <= pins.len && pins[current_pin]["set"])
			current_pin++
		var/loaded = saved.len
		if(current_pin <= pins.len)
			feedback = "Your tension wrench held — [loaded] [loaded == 1 ? "pin" : "pins"] already set. Continue!"

	// Register death signal for interruption handling
	RegisterSignal(user, COMSIG_MOB_DEATH, PROC_REF(on_user_death))

	ui_interact(the_user)

/datum/lockpicking_minigame/Destroy()
	if(user && !QDELETED(user))
		UnregisterSignal(user, COMSIG_MOB_DEATH)
	SStgui.close_uis(src)
	return ..()

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
			base_zone_size = 2
		if(4)
			num_pins = 4
			base_zone_size = 2
		if(5)
			num_pins = 5
			base_zone_size = 1

	// Luck bonus: (1–3) = -1, (4–6) = 0, (7–8) = +1, (9–10) = +2
	var/luck_bonus      = clamp(round((luck - 4.5) / 2), -1, 2)
	// Locksmith bonus: Agility 8+ widens zones by 1
	var/locksmith_bonus = (agility >= 8) ? 1 : 0
	// Pick bonus: master or electronic pick widens zones by 1
	var/pick_bonus      = (is_master_pick || is_electronic_pick) ? 1 : 0
	var/zone_size = clamp(base_zone_size + luck_bonus + locksmith_bonus + pick_bonus, 1, 7)

	// Attempts: base 6, minus tier, plus luck/pick bonuses; minimum 2
	max_attempts  = max(6 - lock_tier + luck_bonus + (pick_bonus * 2), 2)
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
		pins += list(list(
			"pos"       = 5,
			"min"       = min_pos,
			"max"       = max_pos,
			"set"       = FALSE,
			"hint"      = -1,       // distance from real zone on last attempt; -1 = no attempt
			"last_dir"  = 0,        // 1 = go up, -1 = go down
			"moves"     = 0,        // move count for tension mechanic
			"false_min" = false_min,
			"false_max" = false_max
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
	var/list/set_indices = list()
	for(var/i in 1 to pins.len)
		if(pins[i]["set"])
			set_indices += i
	if(set_indices.len)
		partial_state_ref = "\ref[target]"
		GLOB.lockpick_partial_states[partial_state_ref] = set_indices
		addtimer(CALLBACK(src, PROC_REF(expire_partial_state)), 60 SECONDS)
		var/n = set_indices.len
		if(!QDELETED(user))
			to_chat(user, span_notice("You leave your tension wrench in the lock — [n] [n == 1 ? "pin stays" : "pins stay"] set. Continue within 60 seconds to keep your progress."))

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
		pin_data += list(list(
			"pos"     = pin["pos"],
			"set"     = pin["set"],
			"active"  = (i == current_pin && phase == "picking" && !pin["set"]),
			"hint"    = pin["hint"],
			"lastDir" = pin["last_dir"],
			"tension" = tension
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
	data["isMasterPick"] = is_master_pick
	data["totalPins"]    = pins.len
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

	var/list/cur_pin = pins[current_pin]

	switch(action)
		if("move_up")
			// Tension snap check before moving
			if(cur_pin["moves"] >= 10)
				snap_pick()
				return TRUE
			cur_pin["moves"] = min(cur_pin["moves"] + agility_tension_cost(), 10)
			if(cur_pin["pos"] < 10)
				cur_pin["pos"]++
			total_moves++
			update_tension_feedback(cur_pin["moves"])
			. = TRUE

		if("move_down")
			// Tension snap check before moving
			if(cur_pin["moves"] >= 10)
				snap_pick()
				return TRUE
			cur_pin["moves"] = min(cur_pin["moves"] + agility_tension_cost(), 10)
			if(cur_pin["pos"] > 1)
				cur_pin["pos"]--
			total_moves++
			update_tension_feedback(cur_pin["moves"])
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
				cur_pin["set"]   = TRUE
				cur_pin["moves"] = 0
				playsound(get_turf(target), 'sound/machines/button1.ogg', 50, FALSE, -3)
				// Advance past already-set pins
				var/just_set = current_pin
				current_pin++
				while(current_pin <= pins.len && pins[current_pin]["set"])
					current_pin++
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
	if(agility <= 3)
		return prob(30) ? 2 : 1  // Very clumsy: 30% chance of double tension
	if(agility < 6)
		return prob(15) ? 2 : 1  // Somewhat clumsy: 15% chance
	return 1                     // Agility 6+ is always clean

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
			pins[i]["set"]   = FALSE
			pins[i]["pos"]   = 5
			pins[i]["hint"]  = -1
			pins[i]["moves"] = 0
			return i
	return 0

/// Closes the TGUI after a short delay so the player can read the outcome.
/datum/lockpicking_minigame/proc/close_ui()
	SStgui.close_uis(src)

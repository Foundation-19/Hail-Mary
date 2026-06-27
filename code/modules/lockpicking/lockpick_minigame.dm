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
	/// Set to TRUE when the player voluntarily gives up (vs. actual failure)
	var/gave_up = FALSE
	/// world.time of last processed ui_act — gates click spam (2-tick cooldown)
	var/last_action_time = 0
	/// Whether the user was anchored before lockpicking began (restored on Destroy)
	var/was_anchored = FALSE
	/// Noise emitted per failed set attempt: 0=silent, 1=quiet, 2=loud, 3=jangling
	var/pick_noise_level = 1
	/// Accumulated noise tally — resets to 0 after alerting nearby listeners
	var/accumulated_noise = 0
	/// world.time when the minigame began (for tension-fatigue timer)
	var/timer_start = 0
	/// Total timer duration in ticks (0 = no timer; only tier 3+ locks)
	var/timer_duration = 0
	/// TRUE once the 30-second cramp warning has been issued
	var/timer_warning_sent = FALSE
	/// Fractional tick accumulator for sneak-cramp drain (30% faster fatigue while sneaking)
	var/sneak_drain_accum = 0
	/// Whether the user has TRAIT_LOCKPICKING
	var/has_lockpick_trait = FALSE
	/// Shuffled list of pin indices determining binding order for this lock
	var/list/bind_order = null
	/// uses_left when the pick was first inserted (baseline for wear calculation)
	var/pick_initial_uses = 0
	/// Reference to the lockable object — used to persist pin solution.
	/// May be a /obj/item/lock_construct (padlock) or /obj/machinery/door (faction door).
	var/atom/the_lock = null
	/// Overhead icon overlay displayed above the user's mob while picking
	var/mutable_appearance/pick_overlay = null

/datum/lockpicking_minigame/New(atom/the_target, mob/the_user, obj/item/lockpick_set/the_pick, tier, atom/lock_ref = null)
	target    = the_target
	user      = the_user
	pick      = the_pick
	lock_tier = clamp(tier, 1, 5)
	the_lock  = lock_ref
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

	// Noise per failed event — masters are near-silent; bobby pins jangle
	if(is_bobby_pin)
		pick_noise_level = 3
	else if(is_master_pick)
		pick_noise_level = 0
	else
		pick_noise_level = 1

	// Record initial uses for pick wear calculation
	pick_initial_uses = pick.uses_left

	// TRAIT_LOCKPICKING: professional muscle memory — wider feel, quieter work
	if(isliving(the_user) && HAS_TRAIT(the_user, TRAIT_LOCKPICKING))
		has_lockpick_trait = TRUE
		luck       = min(10, luck + 2)
		perception = min(10, perception + 2)

	// Bobby pin cannot handle tier 3+ locks
	if(is_bobby_pin && lock_tier > 2)
		feedback = "Your bobby pin is too flimsy for this lock — it needs a proper pick."
		phase = "failed"
		result = FALSE
		ui_interact(the_user)
		addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
		return

	// Broken pick fragment check — a snapped tip jams the lock until fished out
	var/turf/frag_turf = get_turf(the_target)
	for(var/obj/item/pick_fragment/frag in frag_turf)
		if(frag.stuck_in == the_target)
			feedback = "A broken pick tip is jammed in the lock. Fish it out with a screwdriver first."
			phase = "failed"
			result = FALSE
			ui_interact(the_user)
			addtimer(CALLBACK(src, PROC_REF(close_ui)), 2.5 SECONDS)
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

	// Electronic pick auto-sets the first binding pin (vibration finds the most-stressed tumbler)
	if(is_electronic_pick && pins.len >= 1)
		var/auto_pin = bind_order[1]
		pins[auto_pin]["set"] = TRUE
		current_pin = get_binding_pin()
		feedback = "The electronic pick buzzes — pin [auto_pin] auto-set! Pin [current_pin] is now binding."
		playsound(get_turf(target), 'sound/machines/button1.ogg', 50, FALSE, -14)
	else
		current_pin = get_binding_pin()
		feedback = "Pin [current_pin] is binding — the cylinder presses on it. Find the right height and set it."

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
		// Advance current_pin to the binding pin (skips already-restored set pins)
		var/restored_binding = get_binding_pin()
		current_pin = restored_binding ? restored_binding : pins.len
		var/loaded = set_indices.len
		if(current_pin <= pins.len)
			feedback = "Tension held — [loaded] [loaded == 1 ? "pin" : "pins"] still set. Pin [current_pin] is now binding."

	// Tension-fatigue timer: tier 3+ locks require sustained hand pressure.
	// Your grip eventually cramps, dropping set pins.
	timer_start = world.time
	var/base_timer = 0
	switch(lock_tier)
		if(3) base_timer = 1800  // 180 s
		if(4) base_timer = 1200  // 120 s
		if(5) base_timer = 900   // 90 s
	if(base_timer > 0)
		if(has_lockpick_trait) base_timer += 600  // +60 s
		if(is_master_pick)     base_timer += 300  // +30 s (ergonomic grip)
		timer_duration = base_timer

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

	// Overhead icon above the picker — bystanders see who is working the lock.
	// TILE_BOUND clamps the overlay's interactive area to the picker's tile so clicks
	// on the portion extending above the head don't register as the northern tile
	// (same technique used by the sneak indicator).
	// Alpha scales with picker skill: clumsy pickers fidget visibly; skilled pickers
	// move with precision and draw less attention.
	// Range: alpha 180 (low skill, clearly visible) to 60 (max skill, subtle but seeable).
	// ABOVE_MOB_LAYER as third arg ensures the overlay renders above the mob sprite.
	pick_overlay = mutable_appearance('icons/mob/actions/actions_flightsuit.dmi', "flightsuit_lock", ABOVE_MOB_LAYER)
	pick_overlay.pixel_y = 28
	pick_overlay.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pick_overlay.appearance_flags = RESET_COLOR | PIXEL_SCALE
	pick_overlay.alpha = clamp(190 - (perception + agility - 2) * 7, 60, 190)
	var/matrix/M = matrix()
	M.Scale(0.55)
	pick_overlay.transform = M
	user.add_overlay(pick_overlay)

	ui_interact(the_user)

/datum/lockpicking_minigame/Destroy()
	if(user && !QDELETED(user))
		user.anchored = was_anchored
		if(pick_overlay)
			user.cut_overlay(pick_overlay)
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
	// If the lock already has a stored solution (same pin count), reuse it so
	// the combination stays consistent across attempts.  Per-picker stats still
	// affect zone_size, attempts_left, and hint detail — only the raw
	// positions/types are fixed to the physical lock.
	var/list/stored_sol  = the_lock ? the_lock.vars["pin_solution"]  : null
	var/list/stored_bind = the_lock ? the_lock.vars["pin_bind_order"] : null
	var/use_stored = islist(stored_sol) && (stored_sol.len == num_pins)
	for(var/i in 1 to num_pins)
		var/min_pos
		var/max_pos
		var/false_min = 0
		var/false_max = 0
		var/is_spool = FALSE
		var/is_security = FALSE
		var/stack_height
		if(use_stored)
			var/list/sp = stored_sol[i]
			stack_height = sp["stack_height"]
			false_min    = sp["false_min"]
			false_max    = sp["false_max"]
			is_spool     = sp["spool"]
			is_security  = sp["security"]
			// Recompute zone around the stored center using THIS picker's zone_size.
			// This keeps the combination fixed while still rewarding skilled pickers
			// with a more forgiving window.
			var/true_center = sp["true_center"]
			var/max_start   = max(10 - zone_size + 1, 1)
			min_pos = clamp(true_center - zone_size / 2, 1, max_start)
			max_pos = min(min_pos + zone_size - 1, 10)
		else
			// Zone placed uniformly across the full 1–10 range — no center bias.
			stack_height = rand(1, 5)  // cosmetic: kept for TGUI stack-height display
			var/max_start = max(10 - zone_size + 1, 1)
			min_pos = rand(1, max_start)
			max_pos = min(min_pos + zone_size - 1, 10)
			// False zone for tier 4+ — a single non-overlapping decoy position
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
			if(lock_tier >= 3 && !is_bobby_pin)
				var/spool_chance = (lock_tier - 2) * 20  // 20% / 40% / 60% for tiers 3/4/5
				if(prob(spool_chance))
					is_spool = TRUE
					min_pos = max(min_pos, 2)  // ensure one position below for upward approach
					max_pos = min(min_pos + zone_size - 1, 10)
			// Security pins (tier 4+): a failed set attempt jars loose a neighboring set pin.
			// A pin cannot be both spool and security.
			if(lock_tier >= 4 && !is_spool && !is_bobby_pin)
				var/sec_chance = (lock_tier - 3) * 30  // 30% / 60% for tiers 4/5
				is_security = prob(sec_chance)
		pins += list(list(
			"pos"          = 1,
			"min"          = min_pos,
			"max"          = max_pos,
			"set"          = FALSE,
			"hint"         = -1,
			"last_dir"     = 0,
			"last_pos"     = 0,
			"last_move"    = 0,
			"moves"        = 0,
			"false_min"    = false_min,
			"false_max"    = false_max,
			"tried"        = list(),
			"tried_hints"  = list(),
			"spool"        = is_spool,
			"security"     = is_security,
			"decayed"      = FALSE,
			"overset"      = FALSE,
			"stack_height" = stack_height,
			"pin_attempts" = 2
		))

	// Binding order
	if(use_stored)
		bind_order = stored_bind.Copy()
	else
		bind_order = list()
		for(var/j in 1 to pins.len)
			bind_order += j
		bind_order = shuffle(bind_order)
		// Persist solution on the lock for all future attempts
		if(the_lock)
			var/list/solution = list()
			for(var/k in 1 to pins.len)
				solution += list(list(
					"true_center"  = pins[k]["min"] + zone_size / 2,
					"false_min"    = pins[k]["false_min"],
					"false_max"    = pins[k]["false_max"],
					"spool"        = pins[k]["spool"],
					"security"     = pins[k]["security"],
					"stack_height" = pins[k]["stack_height"]
				))
			the_lock.vars["pin_solution"]   = solution
			the_lock.vars["pin_bind_order"] = bind_order.Copy()

/**
 * Returns the 1-indexed number of the currently binding pin.
 * The binding pin is the first unset pin in bind_order — the one
 * the cylinder's rotational force is pressing against under tension.
 * Returns 0 when all pins are set.
 */
/datum/lockpicking_minigame/proc/get_binding_pin()
	if(!pins || !bind_order)
		return 0
	for(var/i in 1 to bind_order.len)
		if(!pins[bind_order[i]]["set"])
			return bind_order[i]
	return 0

/// Sleeps until the mini-game is fully resolved (closed = TRUE).
/datum/lockpicking_minigame/proc/wait()
	while(!closed && !QDELETED(src))
		if(!QDELETED(user) && user.stat >= UNCONSCIOUS && phase == "picking")
			on_user_incapacitated()
		if(phase == "picking" && timer_duration > 0)
			// Sneaking posture (walk intent) tenses the shoulders and forearms —
			// the timer burns 30% faster, draining in whole-tick increments.
			if(isliving(user) && !QDELETED(user) && user:m_intent == MOVE_INTENT_WALK)
				sneak_drain_accum += 0.3
				if(sneak_drain_accum >= 1)
					var/drain = round(sneak_drain_accum)
					sneak_drain_accum -= drain
					timer_start -= drain  // shift start backward = more elapsed time
			var/elapsed = world.time - timer_start
			var/remaining = timer_duration - elapsed
			if(remaining <= 300 && !timer_warning_sent)
				timer_warning_sent = TRUE
				var/cramp_msg = "WARNING: Your hand is cramping — you have about 30 seconds before tension slips!"
				if(isliving(user) && !QDELETED(user) && user:m_intent == MOVE_INTENT_WALK)
					cramp_msg += " (Sneaking is tensing your whole arm — stand normally if you can.)"
				feedback = cramp_msg
				SStgui.update_uis(src)
			if(remaining <= 0)
				on_tension_fatigue()
		stoplag(1)

/**
 * Fires when the tension-fatigue timer expires.
 * Realistically: your wrist cramps from holding the wrench — pins slip.
 */
/datum/lockpicking_minigame/proc/on_tension_fatigue()
	if(phase != "picking")
		return
	// Reset the timer for the next round of fatigue
	timer_start = world.time
	timer_warning_sent = FALSE
	attempts_left--
	// Every set pin drops — the spring overcomes the tension wrench
	var/lost = 0
	for(var/list/pin in pins)
		if(pin["set"])
			pin["set"]   = FALSE
			pin["pos"]   = 1
			pin["moves"] = 0
			pin["decayed"] = TRUE
			lost++
	playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 70, TRUE, -11)
	if(lost > 0)
		feedback = "Your hand cramps! The tension wrench slips — [lost] pin[lost != 1 ? "s" : ""] drop[lost == 1 ? "s" : ""]!"
	else
		feedback = "Your hand cramps but you barely hold tension — nothing drops."
	if(attempts_left <= 0)
		phase  = "failed"
		result = FALSE
		feedback = "Your grip gives out completely. The lock defeats you."
		jam_target()
		SStgui.update_uis(src)
		addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
	else
		SStgui.update_uis(src)

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
	if(pins)
		for(var/i in 1 to pins.len)
			var/list/pin = pins[i]
			if(pin["set"])
				pins_set++
			// Tension: 0–5 scale (moves / 2, clamped)
			var/tension = clamp(round(pin["moves"] / 2.0), 0, 5)
			var/list/pin_tried_ui = pin["tried"]
			pin_data += list(list(
				"pos"         = pin["pos"],
				"set"         = pin["set"],
				"active"      = (i == current_pin && phase == "picking" && !pin["set"]),
				"hint"        = pin["hint"],
				"lastDir"     = pin["last_dir"],
				"lastPos"     = pin["last_pos"],
				"lastMove"    = pin["last_move"],
				"tension"     = tension,
				"tried"       = pin_tried_ui,
				"triedHints"  = pin["tried_hints"],
				"spool"       = pin["spool"],
				"security"    = pin["security"],
				"decayed"     = pin["decayed"],
				"overset"     = pin["overset"],
				"spoolFeel"   = pin["spool"] && !pin["set"] && pin["pos"] >= pin["min"] && pin["pos"] <= pin["max"] && pin["last_move"] == -1,
				"stackHeight" = pin["stack_height"],
				"pinAttempts" = pin["pin_attempts"]
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
	data["totalPins"]     = pins ? pins.len : 0
	data["isDark"]        = dark_penalty
	data["isHurt"]        = pain_penalty
	data["wearingGloves"] = glove_penalty
	data["hasTrait"]      = has_lockpick_trait
	data["noiseLevel"]    = accumulated_noise
	data["timerDuration"] = timer_duration
	data["timerElapsed"]  = (timer_duration > 0) ? min(timer_duration, world.time - timer_start) : 0
	data["bindingPin"]    = get_binding_pin()
	var/pick_wear = 0
	if(!QDELETED(pick) && pick_initial_uses > 0)
		var/wear_ratio = 1.0 - (pick.uses_left / pick_initial_uses)
		pick_wear = clamp(round(wear_ratio * 4), 0, 3)
	data["pickWear"]      = pick_wear
	var/is_sneaking = FALSE
	if(isliving(user))
		var/mob/living/L = user
		is_sneaking = (L.m_intent == MOVE_INTENT_WALK)
	data["isSneaking"] = is_sneaking
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
	if(world.time - last_action_time < 2)  // 2-tick (0.2s) cooldown — prevents click spam consuming multiple attempts
		return
	last_action_time = world.time

	// Guard: after non-linear play current_pin may sit past the end of the list.
	var/list/cur_pin = (current_pin >= 1 && current_pin <= pins.len) ? pins[current_pin] : null
	// Sneak (walk intent) muffles the picker's physical sounds — checked once per action.
	var/sneaking = isliving(user) && (user:m_intent == MOVE_INTENT_WALK)

	switch(action)
		if("move_up")
			var/binding_num = get_binding_pin()
			var/is_binding  = (binding_num > 0 && current_pin == binding_num)
			// Non-binding pins feel loose — no cylinder pressure, no pick stress
			var/up_cost = is_binding ? agility_tension_cost() : 0
			// Electronic pick stall only applies to the binding pin
			if(is_binding && is_electronic_pick && current_pin >= 3 && prob(10))
				up_cost++
				feedback = "The pick's motor stutters — extra tension!"
			// Snap only possible under cylinder pressure
			if(is_binding && cur_pin["moves"] >= 10)
				snap_pick()
				return TRUE
			if(up_cost > 0)
				cur_pin["moves"] = min(cur_pin["moves"] + up_cost, 10)
			if(cur_pin["pos"] < 10)
				cur_pin["pos"]++
			else if(is_binding && !cur_pin["overset"])
				// Overset: driver pin slides below the shear line, jamming the pin
				cur_pin["overset"] = TRUE
				feedback = "Overdriven! The driver pin drops below the shear line — lower the pin all the way to free it."
			cur_pin["last_move"] = 1
			total_moves++
			if(is_binding)
				update_tension_feedback(cur_pin["moves"])
			. = TRUE

		if("move_down")
			var/binding_num = get_binding_pin()
			var/is_binding  = (binding_num > 0 && current_pin == binding_num)
			var/down_cost   = is_binding ? agility_tension_cost() : 0
			if(is_binding && is_electronic_pick && current_pin >= 3 && prob(10))
				down_cost++
				feedback = "The pick's motor stutters — extra tension!"
			if(is_binding && cur_pin["moves"] >= 10)
				snap_pick()
				return TRUE
			if(down_cost > 0)
				cur_pin["moves"] = min(cur_pin["moves"] + down_cost, 10)
			if(cur_pin["pos"] > 1)
				cur_pin["pos"]--
				// Clear overset once fully lowered — driver pin is free again
				if(cur_pin["overset"] && cur_pin["pos"] <= 1)
					cur_pin["overset"] = FALSE
					feedback = "The driver pin pops free — you can set this pin again."
			// Spool false-set feel: entering the zone from above creates a subtle
			// counter-rotation — the cylinder gives slightly, then the spool catches.
			if(cur_pin["spool"] && !cur_pin["set"] && !cur_pin["overset"] \
				&& cur_pin["pos"] >= cur_pin["min"] && cur_pin["pos"] <= cur_pin["max"] \
				&& cur_pin["last_move"] != 1)
				playsound(get_turf(target), 'sound/machines/button1.ogg', 25, FALSE, -15)
				if(is_binding)
					feedback = "The cylinder gives slightly... then catches. Something's different about this pin."
			cur_pin["last_move"] = -1
			total_moves++
			if(is_binding)
				update_tension_feedback(cur_pin["moves"])
			. = TRUE

		if("select_pin")
			// Non-linear pin focus: player can scout any unset pin
			var/pin_idx = text2num(params["pin"])
			if(!pin_idx || pin_idx < 1 || pin_idx > pins.len)
				return
			if(pins[pin_idx]["set"])
				return  // already set, nothing to do
			current_pin = pin_idx
			var/binding_sel = get_binding_pin()
			var/list/tpin   = pins[pin_idx]
			if(pin_idx == binding_sel)
				if(tpin["hint"] >= 0)
					feedback = "Pin [pin_idx] (BINDING). Last attempt: [tpin["last_dir"] > 0 ? "too low" : "too high"]."
				else
					feedback = "Pin [pin_idx] is binding — this is your target. Work it carefully."
			else
				if(tpin["hint"] >= 0)
					feedback = "Pin [pin_idx] is loose. (Last: [tpin["last_dir"] > 0 ? "needed higher" : "needed lower"]) Binding pin is [binding_sel]."
				else
					feedback = "Pin [pin_idx] is loose — not binding right now. Binding pin is pin [binding_sel]."
			. = TRUE

		if("set_pin")
			// Non-binding pin: springs back instantly, no attempt consumed.
			// The cylinder isn't pressing on it — it has nothing to catch on.
			var/binding_check = get_binding_pin()
			if(binding_check > 0 && current_pin != binding_check)
				cur_pin["pos"]       = 1
				cur_pin["last_move"] = 0
				feedback = "The pin springs free — it's loose under current tension. The binding pin is pin [binding_check]."
				. = TRUE
				return .
			// Overset: driver pin is jammed below the shear line.
			if(cur_pin["overset"])
				feedback = "The pin is overdriven — lower it all the way to position 1 to free the driver pin."
				. = TRUE
				return .
			var/pos = cur_pin["pos"]
			attempt_made = TRUE

			// Electronic pick: vibration sensors detect false grooves before committing
			if(is_electronic_pick && cur_pin["false_min"] > 0 && pos >= cur_pin["false_min"] && pos <= cur_pin["false_max"])
				cur_pin["pos"]   = 1
				cur_pin["moves"] = 0
				feedback = "The pick's frequency shifts — the electronics detect a false groove! No attempt wasted."
				playsound(get_turf(target), 'sound/machines/button1.ogg', 30, FALSE, -15)
				. = TRUE
				return .

			// --- False zone check (tier 4+ only) ---
			if(cur_pin["false_min"] > 0 && pos >= cur_pin["false_min"] && pos <= cur_pin["false_max"])
				attempts_left--
				cur_pin["pos"]   = 1
				cur_pin["moves"] = 0
				// Brief success click then a rejection scrape
				playsound(get_turf(target), 'sound/machines/button1.ogg', 40, FALSE, -14)
				playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 50, TRUE, -14)
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
					playsound(get_turf(target), 'sound/machines/button1.ogg', 40, FALSE, -14)
					playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), 45, TRUE, -14)
					feedback = "The pin clicks... then springs back! It's a spool pin — approach from lower positions (move up into the zone)."
					. = TRUE
					return .
				cur_pin["set"]   = TRUE
				cur_pin["moves"] = 0
				playsound(get_turf(target), 'sound/machines/button1.ogg', 50, FALSE, -14)
				var/just_set = current_pin
				// Advance focus to the next binding pin in the shuffled bind_order
				var/next_binding = get_binding_pin()
				current_pin = (next_binding > 0) ? next_binding : 1
				// Check for pin decay on tier 3+ locks
				var/decayed = maybe_decay_pins(just_set)
				// Observers with good hearing catch the clean set-click
				broadcast_pin_attempt(just_set, 0, TRUE)
				if(all_pins_set())
					phase    = "success"
					feedback = "The lock clicks open!"
					result   = TRUE
					// Final click: quiet enough that only nearby listeners catch it.
					// Sneaking makes it even subtler — just a faint mechanical release.
					playsound(get_turf(target), 'sound/machines/BoltsUp.ogg', sneaking ? 20 : 35, FALSE, -14)
					addtimer(CALLBACK(src, PROC_REF(close_ui)), 1.5 SECONDS)
				else if(decayed > 0)
					current_pin = decayed
					feedback = "Pin [just_set] set — but pin [decayed] vibrates loose and slips back! Refocus."
					playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), sneaking ? 20 : 40, TRUE, -14)
				else
					feedback = "Pin [just_set] set. Moving to pin [current_pin]..."

			else
				// Wrong position — spring back and consume this pin's one allowed attempt
				cur_pin["pin_attempts"]--
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
				cur_pin["pos"]      = 1
				cur_pin["moves"]    = 0  // reset tension after a set attempt

				// Warmer sound for close attempts, colder thud for far misses
				if(dist_to_zone <= 2)
					playsound(get_turf(target), 'sound/items/screwdriver2.ogg', sneaking ? 22 : 45, TRUE, -14)
				else
					playsound(get_turf(target), 'sound/items/screwdriver.ogg', sneaking ? 28 : 55, TRUE, -14)
				// Noise alert: failed sets scrape and click. Loud picks alert bystanders.
				check_noise(dist_to_zone <= 2 ? 1 : 2)
				// Perception-gated detail for nearby observers
				broadcast_pin_attempt(current_pin, dist_to_zone, FALSE)

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
						pins[reset_idx]["pos"]     = 1
						pins[reset_idx]["moves"]   = 0
						pins[reset_idx]["decayed"] = TRUE
						if(current_pin > pins.len || pins[current_pin]["set"])
							current_pin = reset_idx
						feedback += " The serrated pin catches — pin [reset_idx] jolts loose!"
						playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), sneaking ? 30 : 60, TRUE, -12)

				// Bobby pin breakage: 25% chance to snap on each failed attempt
				if(is_bobby_pin && prob(25))
					feedback += " The bobby pin snaps!"
					phase  = "failed"
					result = FALSE
					if(!QDELETED(pick))
						qdel(pick)
					addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
					. = TRUE
					return .
				if(cur_pin["pin_attempts"] <= 0)
					// All pins spring back — cylinder drops. Lose one global attempt.
					attempts_left--
					for(var/j in 1 to pins.len)
						pins[j]["set"]          = FALSE
						pins[j]["pos"]          = 1
						pins[j]["moves"]        = 0
						pins[j]["decayed"]      = FALSE
						pins[j]["overset"]      = FALSE
						pins[j]["last_move"]    = 0
						pins[j]["pin_attempts"] = 2
					current_pin = get_binding_pin()
					playsound(get_turf(target), pick('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg'), sneaking ? 32 : 65, TRUE, -12)
					if(attempts_left <= 0)
						feedback = "The cylinder slams shut — you're out of attempts."
						phase    = "failed"
						result   = FALSE
						jam_target()
						addtimer(CALLBACK(src, PROC_REF(close_ui)), 2 SECONDS)
					else
						feedback = "You botch pin [current_pin] badly — the cylinder drops and all pins spring back! ([attempts_left] attempt[attempts_left == 1 ? "" : "s"] left.)"
				else if(cur_pin["pin_attempts"] == 1)
					feedback += " (WARNING: Last chance on this pin before the cylinder drops!)"
			. = TRUE

		if("give_up")
			save_partial_state()
			phase    = "failed"
			feedback = "You carefully withdraw your lockpick."
			result   = FALSE
			gave_up  = TRUE
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

/// Snaps the pick from excessive tension. Leaves a fragment in the lock.
/datum/lockpicking_minigame/proc/snap_pick()
	phase    = "failed"
	result   = FALSE
	feedback = "You overtorque the pick — SNAP! A fragment is stuck in the lock. Fish it out before trying again."
	playsound(get_turf(target), 'sound/items/Wirecutter.ogg', 100, TRUE, -10)
	// Spawn pick fragment — physically blocks the lock until removed
	var/obj/item/pick_fragment/frag = new(get_turf(target))
	frag.stuck_in = target
	target.visible_message(span_warning("A piece of [user ? user.name + "'s" : "a"] pick snaps off inside [target]'s lock!"))
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
			pins[i]["pos"]     = 1
			pins[i]["moves"]   = 0
			pins[i]["decayed"] = TRUE
			// Keep hint/last_dir so the player retains positional memory
			return i
	return 0

/**
 * Accumulates noise from failed attempts and loud picks.
 * When the tally passes the alert threshold, nearby bystanders hear the
 * scraping and get a chat message — the volume and range scale with pick type.
 */
/datum/lockpicking_minigame/proc/check_noise(events)
	var/effective = pick_noise_level * events
	// Sneaking (walk intent) muffles the sounds of picking
	if(isliving(user))
		var/mob/living/L = user
		if(L.m_intent == MOVE_INTENT_WALK)
			effective = round(effective * 0.25)  // sneaking cuts noise to 25% — very hard to hear
	if(has_lockpick_trait)
		effective = max(0, effective - 1)  // trained hands are quieter
	accumulated_noise += effective
	if(accumulated_noise < 5)
		return
	accumulated_noise = 0
	// Range and message scale with noise level; closer listeners get more precise alerts
	var/alert_range
	var/near_msg  // within 2 tiles — source is identifiable
	var/far_msg   // at the outer edge — vague, hard to place
	switch(pick_noise_level)
		if(3)  // bobby pin — jangling metal, hard to miss
			alert_range = 5
			near_msg = span_warning("There's loud metallic scraping coming from [target]!")
			far_msg  = span_notice("You catch a distant scraping sound.")
		if(2)
			alert_range = 3
			near_msg = span_warning("You hear suspicious scraping near [target].")
			far_msg  = span_notice("You barely make out a faint click nearby.")
		if(1)
			alert_range = 3
			near_msg = span_notice("There's a faint metallic click from [target].")
			far_msg  = null  // at the edge, too quiet to be distinct
		else  // master pick: silent, no alert
			return
	for(var/mob/M in view(alert_range, get_turf(target)))
		if(M == user)
			continue
		if(!isliving(M))
			continue
		var/dist = get_dist(M, get_turf(target))
		var/obs_perc = M.special_p
		// Distance degrades effective perception: each tile beyond 2 costs 1 point.
		// Bobby pin noise (level 3) is obvious enough that perception only matters
		// at the far edge. Quieter picks require more attentiveness to notice at all.
		var/perc_needed
		if(dist <= 2)
			perc_needed = (pick_noise_level >= 3) ? 1 : 2  // loud = anyone; quiet = basic awareness
		else
			perc_needed = (pick_noise_level >= 3) ? 2 : 4  // loud far = needs some awareness; quiet far = needs good senses
		if(obs_perc < perc_needed)
			continue
		var/msg = (dist <= 2) ? near_msg : far_msg
		if(msg)
			to_chat(M, msg)

/**
 * Broadcasts a perception-gated message to observers when the picker makes a
 * pin set attempt (hit or miss). In real life a trained ear can tell which pin
 * is being worked and roughly how close the picker is to setting it — the pin
 * produces a distinct click when it reaches shear-line height, and the quality
 * of that click changes as the picker homes in on the correct position.
 *
 * obs_perception tiers:
 *   1–3  — Hear a vague metallic click; can't tell anything more.
 *   4–5  — Can tell whether the picked pin is in the front or back half of the cylinder.
 *   6–7  — Can identify the pin number by the relative position of the sound
 *           along the lock body and the effort the picker exerts.
 *   8–10 — Also distinguishes a "near miss" click (crisp and clean) from a
 *           "far miss" scrape (dull grind), and hears a firm click on success.
 *
 * Range: 4 tiles (must be nearby to hear the subtle sound).
 */
/datum/lockpicking_minigame/proc/broadcast_pin_attempt(pin_num, dist_to_zone, was_set)
	var/turf/T = get_turf(target)
	var/total_pins = pins ? pins.len : 1
	// Categorise the pin's position in the cylinder as "front" or "back"
	// so mid-perception observers get useful directional context.
	var/half = (pin_num <= round(total_pins / 2)) ? "front" : "back"
	// Sneaking (walk intent) makes the picker's movements quieter — the sounds are
	// physically softer, so the effective range AND detail level drop for observers.
	var/sneak_penalty = (isliving(user) && user:m_intent == MOVE_INTENT_WALK) ? 3 : 0
	// Successful pin sets (the pin quietly drops into the shear line) are the
	// QUIETEST moment — no spring-back, no scrape. Only close observers catch it.
	// Failed sets (spring-back scraping) carry further; Joseph's longer-range
	// awareness reward applies to those, not to the subtle success click.
	var/broadcast_range = was_set ? 4 : (sneak_penalty ? 5 : 8)
	var/far_threshold   = was_set ? 2 : (sneak_penalty ? 2 : 4)
	for(var/mob/M in view(broadcast_range, T))
		if(M == user)
			continue
		if(!isliving(M))
			continue
		var/obs_perc = M.special_p
		if(obs_perc <= 0)
			continue
		var/obs_dist = get_dist(M, T)
		if(obs_dist > far_threshold && obs_perc < 7)
			continue
		// Distance penalty: each tile beyond 2 costs 2 effective perception.
		if(obs_dist > 2)
			obs_perc -= (obs_dist - 2) * 2
		// Sneak penalty: quieter sounds = harder to extract detail from them.
		obs_perc -= sneak_penalty
		if(obs_perc <= 0)
			continue
		// Identifying the picker by name requires line of sight — you need to see
		// their face. If the observer can't see the user mob, they only know "someone".
		var/picker_name = (user in view(M)) ? "[user]" : "someone"
		var/msg
		if(obs_perc <= 3)
			// Just the raw sound — no interpretation possible.
			msg = span_notice("You hear a faint metallic click from [target].")
		else if(obs_perc <= 5)
			// Front/back of the lock cylinder.
			msg = span_notice("You hear a [was_set ? "firm" : "dry"] click from the [half] of [target]'s lock.")
		else if(obs_perc <= 7)
			// Pin number identifiable from sound position along the cylinder.
			if(was_set)
				msg = span_notice("A crisp click — pin [pin_num] of [total_pins] in [target] just fell into place.")
			else
				msg = span_notice("You pick out pin [pin_num] of [total_pins] in [target] — [picker_name] is working it.")
		else
			// Near/far miss distinguishable; success is unmistakable.
			if(was_set)
				msg = span_notice("A clean, deliberate click — [picker_name] just set pin [pin_num] of [total_pins] in [target].")
			else if(dist_to_zone <= 2)
				msg = span_notice("Almost — you hear a near-miss scrape on pin [pin_num] of [total_pins]. [picker_name] is close.")
			else
				msg = span_notice("A dull grinding scrape: [picker_name] is far off on pin [pin_num] of [total_pins] in [target].")
		to_chat(M, msg)

/// Closes the TGUI after a short delay so the player can read the outcome.
/datum/lockpicking_minigame/proc/close_ui()
	SStgui.close_uis(src)

// =====================================================
// PICK FRAGMENT ITEM
// =====================================================

/**
 * A broken pick tip wedged inside a lock cylinder.
 * Blocks all further picking attempts until removed with a screwdriver
 * or similar fine tool. Spawned when snap_pick() fires.
 */
/obj/item/pick_fragment
	name = "pick fragment"
	desc = "A jagged metal shard snapped from a lockpick inside the lock cylinder. \
			You could fish it out with a screwdriver."
	icon = 'icons/obj/fallout/lockbox.dmi'
	icon_state = "basic_lockpick"
	w_class = WEIGHT_CLASS_TINY
	/// The lock object this fragment is stuck inside (null once removed).
	var/atom/stuck_in = null

/obj/item/pick_fragment/examine(mob/user)
	. = ..()
	if(stuck_in)
		. += span_warning("It's lodged inside [stuck_in]'s lock mechanism. Use a screwdriver to extract it.")

/// A screwdriver extracts the fragment from the lock.
/obj/item/pick_fragment/attackby(obj/item/tool, mob/user, params)
	if(istype(tool, /obj/item/screwdriver))
		if(stuck_in)
			to_chat(user, span_notice("You carefully work the pick fragment free from [stuck_in]."))
			stuck_in = null
		else
			to_chat(user, span_notice("You pry the fragment loose."))
		user.put_in_hands(src)
		return
	return ..()

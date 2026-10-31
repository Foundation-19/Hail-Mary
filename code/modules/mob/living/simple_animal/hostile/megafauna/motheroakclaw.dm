/mob/living/simple_animal/hostile/megafauna/motheroakclaw
	name = "Oak Mother deathclaw"
	desc = "A deathclaw so overrun by the tree minders' sap that it is more tree than beast: a full oak has grown through its back and shoulders, with roots dragging behind it. Whatever mind the sap once gave it is long gone. It moves slowly. Nothing else about it is weak."
	icon = 'icons/mob/monsters/oakclaw.dmi'
	icon_state = "oakclaw"
	icon_living = "oakclaw"
	icon_dead = "oakclaw"

	health = 2200
	maxHealth = 2200
	mob_armor = ARMOR_VALUE_OAK_MOTHER
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 5)
	loot = list(/obj/item/stack/f13Cash/random/med) //THIS IS FOR DUNGEON ACCESS STUFF: CHANGE IF NEEDED
	armour_penetration = 0.7
	damage_threshold_penetration_mob = 10
	melee_damage_lower = 50
	melee_damage_upper = 70
	vision_range = 9
	aggro_vision_range = 18
	speed = 10
	move_to_delay = 10
	melee_queue_distance = 20 // as far as possible really, need this because of charging
	ranged = TRUE
	stat_attack = CONSCIOUS
	pixel_x = -16
	wander = FALSE
	movement_type = GROUND
	blood_volume = BLOOD_VOLUME_NORMAL
	deathmessage = "Becomes stills. Its not moving anymore."
	deathsound = 'sound/effects/gravhit.ogg'
	attack_verb_continuous = "slams"
	attack_verb_simple = "slams"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	weather_immunities = list("snow")
	speak_emote = list("roars")
	attack_action_types = list(/datum/action/innate/megafauna_attack/heavy_stomp,
								/datum/action/innate/megafauna_attack/disorienting_scream,
								/datum/action/innate/megafauna_attack/root_burst)
	/// Saves the turf the megafauna was created at (spawns exit portal here)
	var/turf/starting
	/// Range for motheroakclaw stomping when it moves
	var/stomp_range = 1
	/// Stores directions the mob is moving, then calls that a move has fully ended when these directions are removed in moved
	var/stored_move_dirs = 0
	/// If the motheroakclaw is allowed to move
	var/can_move = TRUE

	// --- phases. Index 1 = whole, 2 = below 50%, 3 = below 25%. All still slower than a deathclaw (2.75).
	var/phase = 1
	var/list/phase_move_delay = list(10, 6, 4)
	var/list/phase_stomp_range = list(1, 2, 2)
	/// Deciseconds between ranged attacks (stomp and scream set their own recovery, see their procs)
	var/list/phase_ranged_cooldown = list(100, 80, 60)
	/// How many targets Root Burst picks per phase
	var/list/phase_root_targets = list(1, 2, 3)
	/// Root Burst wind-up in deciseconds per phase: the time players have to step out
	var/list/phase_root_delay = list(14, 11, 8)
	var/root_damage = 30
	var/last_attack = 0

	// --- kin. Called once on entering phase 2 and once on entering phase 3.
	var/kin_type = /mob/living/simple_animal/hostile/deathclaw/inteligent/inflicted/reverted
	var/kin_per_call = 2
	var/kin_max_alive = 4
	var/list/kin = list()
	var/list/phase_kin_called = list(FALSE, FALSE, FALSE)

	// --- sap regeneration, out of combat only
	var/regen_fraction = 0.02
	var/regen_next = 0
	var/last_combat = 0

/datum/action/innate/megafauna_attack/heavy_stomp
	name = "Heavy Stomp"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = span_colossus("You are now stomping the ground around you.")
	chosen_attack_num = 1

/datum/action/innate/megafauna_attack/disorienting_scream
	name = "Disorienting Scream"
	icon_icon = 'icons/turf/walls/wall.dmi'
	button_icon_state = "wall"
	chosen_message = span_colossus("You are now screeching, disorienting targets around you.")
	chosen_attack_num = 2 // was 3, which OpenFire never handled for a player-controlled boss

/datum/action/innate/megafauna_attack/root_burst
	name = "Root Burst"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = span_colossus("You are now calling roots up under your targets.")
	chosen_attack_num = 3

/mob/living/simple_animal/hostile/megafauna/motheroakclaw/Initialize()
	. = ..()
	starting = get_turf(src)
	last_combat = world.time

// ============================================================
// PHASES
// ============================================================

/// Works out the phase from current health and applies it. Entering a higher phase for the first time
/// since a full heal announces it and calls kin.
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/update_phase()
	var/fraction = health / maxHealth
	var/new_phase = 1
	if(fraction <= 0.25)
		new_phase = 3
	else if(fraction <= 0.5)
		new_phase = 2
	move_to_delay = phase_move_delay[new_phase]
	speed = phase_move_delay[new_phase]
	stomp_range = phase_stomp_range[new_phase]
	if(new_phase == phase)
		return
	var/went_up = new_phase > phase
	phase = new_phase
	if(went_up && !phase_kin_called[phase] && phase >= 2)
		phase_kin_called[phase] = TRUE
		visible_message(span_userdanger("\The [src] shudders as the oak through her back bursts into new growth!"))
		INVOKE_ASYNC(src, PROC_REF(call_kin), kin_per_call)

/// Tears loose overgrown deathclaws from the roots around her (never more than kin_max_alive at once).
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/call_kin(count)
	for(var/mob/living/simple_animal/hostile/K in kin.Copy())
		if(QDELETED(K) || K.stat == DEAD)
			kin -= K
	var/list/spots = list()
	for(var/turf/T in view(3, src))
		if(!T.density)
			spots += T
	if(!spots.len)
		return
	for(var/i in 1 to count)
		if(kin.len >= kin_max_alive)
			break
		var/mob/living/simple_animal/hostile/K = new kin_type(pick(spots))
		kin += K
		K.visible_message(span_danger("\The [K] tears itself loose from the roots around \the [src]!"))

// ============================================================
// ATTACK SELECTION
// ============================================================

/mob/living/simple_animal/hostile/megafauna/motheroakclaw/OpenFire()
	update_phase()
	SetRecoveryTime(0, phase_ranged_cooldown[phase])

	if(client)
		switch(chosen_attack)
			if(1)
				heavy_stomp()
			if(2)
				disorienting_scream()
			if(3)
				root_burst()
		return

	chosen_attack = pick_attack()
	last_attack = chosen_attack
	switch(chosen_attack)
		if(1)
			heavy_stomp()
		if(2)
			disorienting_scream()
		if(3)
			root_burst()

/// Weighted random pick that never repeats the previous attack twice in a row.
/// Stomp 35, scream 20, root burst 45 (the stomp only reaches what is close, so Root Burst is how she punishes kiting).
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/pick_attack()
	var/list/options = list(1, 2, 3)
	var/list/weights = list(35, 20, 45)
	var/total = 0
	for(var/i in 1 to options.len)
		if(options[i] == last_attack)
			continue
		total += weights[i]
	var/roll = rand(1, total)
	for(var/i in 1 to options.len)
		if(options[i] == last_attack)
			continue
		roll -= weights[i]
		if(roll <= 0)
			return options[i]
	return 1

// ============================================================
// MOVEMENT
// ============================================================

/mob/living/simple_animal/hostile/megafauna/motheroakclaw/Move(atom/newloc, direct)
	if(!can_move)
		return
	stored_move_dirs |= direct
	return ..()

/mob/living/simple_animal/hostile/megafauna/motheroakclaw/Moved(atom/oldloc, direct)
	. = ..()
	stored_move_dirs &= ~direct
	if(!stored_move_dirs)
		INVOKE_ASYNC(src, PROC_REF(ground_slam), stomp_range, 1, FALSE)

// ============================================================
// SAP REGENERATION AND RESET
// ============================================================

/mob/living/simple_animal/hostile/megafauna/motheroakclaw/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	if(stat != CONSCIOUS)
		return
	if(target)
		last_combat = world.time
		return
	if(world.time < last_combat + 15 SECONDS || health >= maxHealth)
		return
	if(world.time < regen_next)
		return
	regen_next = world.time + 5 SECONDS
	adjustBruteLoss(-(maxHealth * regen_fraction))
	if(health >= maxHealth)
		// fully healed: the encounter resets, kin can be called again
		phase = 1
		phase_kin_called = list(FALSE, FALSE, FALSE)
		update_phase()

// ============================================================
// ATTACKS
// ============================================================

/// Slams the ground around the motheroakclaw throwing back enemies caught nearby
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/ground_slam(range, delay, do_damage)
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(range, orgin)
	for(var/i = 0 to range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			playsound(T,'sound/effects/bamf.ogg', 600, TRUE, 10)
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T)
				var/obj/item/bodypart/affecting = L.get_bodypart(BODY_ZONE_CHEST)
				var/armor_block = L.run_armor_check(affecting, "melee")
				if(L == src || L.throwing)
					continue
				to_chat(L, span_userdanger("[src]'s ground slam shockwave sends you flying!"))
				var/turf/thrownat = get_ranged_target_turf_direct(src, L, 8, rand(-10, 10))
				L.throw_at(thrownat, 4, 1, src, TRUE)		//, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
				if(do_damage)
					L.apply_damage(40, BRUTE, BODY_ZONE_CHEST, armor_block, wound_bonus = CANT_WOUND) //This takes into count armor now. Also makes it damage the chest first, so he can't break your legs instantly.
				shake_camera(L, 2, 1)
			all_turfs -= T
		sleep(delay)


/// Larger but slower ground stomp
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/heavy_stomp()
	can_move = FALSE
	ground_slam(5, 2, TRUE)
	SetRecoveryTime(0, 0)
	can_move = TRUE


/// Shakes all nearby enemies screens and animates the motheroakclaw shaking up and down
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/disorienting_scream()
	can_move = FALSE
	playsound(src, 'sound/magic/demon_dies.ogg', 600, FALSE, 10)
	animate(src, pixel_z = rand(5, 15), time = 1, loop = 6)
	animate(pixel_z = 0, time = 1)
	for(var/mob/living/L in get_hearers_in_view(7, src) - src)
		shake_camera(L, 30, 1)
		to_chat(L, span_danger("The motheroakclaw screams loudly!"))
	SetRecoveryTime(30, 0)
	SLEEP_CHECK_DEATH(12)
	can_move = TRUE
	return

/// Roots erupt under the nearest targets. Telegraphed: smoke on the ground and a warning for the
/// wind-up time (14 / 11 / 8 deciseconds by phase), then the marked tiles hit whoever is still standing on them.
/// She stands still while she casts.
/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/root_burst()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(9, src))
		if(H.stat != DEAD)
			candidates += H
	if(!candidates.len)
		return
	// pick the nearest targets for this phase
	var/list/chosen = list()
	for(var/n in 1 to min(phase_root_targets[phase], candidates.len))
		var/mob/living/carbon/human/best
		for(var/mob/living/carbon/human/H in candidates)
			if(!best || get_dist(src, H) < get_dist(src, best))
				best = H
		chosen += best
		candidates -= best
	var/list/marked = list()
	for(var/mob/living/carbon/human/H in chosen)
		var/turf/T = get_turf(H)
		if(!T)
			continue
		marked |= T
		for(var/d in list(NORTH, SOUTH, EAST, WEST))
			var/turf/N = get_step(T, d)
			if(N && !N.density)
				marked |= N
		to_chat(H, span_userdanger("Roots churn under your feet! Move!"))
	if(!marked.len)
		return
	can_move = FALSE
	playsound(src, 'sound/effects/bamf.ogg', 200, TRUE, 10)
	for(var/turf/T in marked)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	addtimer(CALLBACK(src, PROC_REF(root_burst_hit), marked), phase_root_delay[phase])

/mob/living/simple_animal/hostile/megafauna/motheroakclaw/proc/root_burst_hit(list/marked)
	can_move = TRUE
	if(QDELETED(src) || stat == DEAD)
		return
	for(var/turf/T in marked)
		playsound(T, 'sound/effects/bamf.ogg', 300, TRUE, 10)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(L == src || L.stat == DEAD)
				continue
			var/obj/item/bodypart/affecting = L.get_bodypart(BODY_ZONE_CHEST)
			var/armor_block = L.run_armor_check(affecting, "melee")
			to_chat(L, span_userdanger("Roots tear up out of the ground and slam into you!"))
			L.apply_damage(root_damage, BRUTE, BODY_ZONE_CHEST, armor_block, wound_bonus = CANT_WOUND)
			L.Knockdown(15)
			shake_camera(L, 2, 1)

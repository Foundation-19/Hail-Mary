/*IN THIS FILE:
-Hellpigs: runt, common, tusker, sow
*/

// Mutated wasteland boars. They are not smart, they are fast and angry: a hellpig squares up, paws the ground, then
// drives itself into its target and gores it. A charge that misses leaves it overextended, a charge that hits knocks
// the target down. Thick hide and fat make it hard to put down with small arms but laser and plasma work fine.
// Below a third of its health it goes into a frenzy and hits harder and faster.
// The sprite is already a very large animal, so the common hellpig is the baseline (scale 1). Every variant is sized
// against it and each individual rolls a little size variance on top, with health and damage following the roll.

/mob/living/simple_animal/hostile/hellpig
	affix_pool_type = "beast"
	affix_chance = 5
	name = "hellpig"
	desc = "A mutated American boar the size of a cow, sporting razor sharp tusks and a nasty temper. It will charge anything that moves."
	icon = 'icons/mob/hellpig.dmi'
	icon_state = "hellpig"
	icon_living = "hellpig"
	icon_dead = "hellpig_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_HELLPIG
	maxHealth = 280
	health = 280
	speed = 1
	move_to_delay = 2.5
	melee_damage_lower = 18
	melee_damage_upper = 30
	armour_penetration = 0.1
	damage_threshold_penetration_mob = 3
	obj_damage = 60
	wound_bonus = 5
	bare_wound_bonus = 25
	sharpness = SHARP_POINTY
	a_intent = INTENT_HARM
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	footstep_type = FOOTSTEP_MOB_HEAVY
	faction = list("hellpig", "yaoguai")
	gold_core_spawnable = HOSTILE_SPAWN

	attack_verb_simple = "gores"
	attack_sound = 'sound/weapons/bite.ogg'
	response_help_simple = "pets"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	speak_emote = list("squeals", "grunts")
	emote_hear = list("snorts.", "grunts.")
	emote_taunt = list("squeals", "paws the ground")
	speak_chance = 5
	taunt_chance = 25
	emote_taunt_sound = list('sound/f13npc/deathclaw/taunt.ogg')
	aggrosound = list('sound/f13npc/deathclaw/aggro1.ogg', 'sound/f13npc/deathclaw/aggro2.ogg')
	idlesound = list('sound/f13npc/deathclaw/idle.ogg')
	death_sound = list('sound/f13npc/hellpig/hellpigdead.ogg')

	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 5, /obj/item/stack/sheet/bone = 2)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 2, /obj/item/stack/sheet/sinew = 1)
	butcher_difficulty = 1

	environment_smash = ENVIRONMENT_SMASH_NONE
	can_open_doors = FALSE
	can_climb_ladders = FALSE
	has_low_light_vision = TRUE

	// Pure melee. The charge is what closes the gap, not kiting.
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

	low_health_threshold = 0.33

	/// Runts and anything else that should only ever bite sets this to FALSE
	var/can_charge = TRUE
	var/charging = FALSE
	var/winding_up = FALSE
	var/charge_cooldown = 0
	var/charge_cooldown_time = 9 SECONDS
	var/charge_min_range = 3
	var/charge_max_range = 7
	var/charge_windup = 0.6 SECONDS
	/// Gore damage as a multiple of a normal swing
	var/charge_damage_mult = 1.3
	var/charge_knockdown = 25
	/// How long a hellpig that rams a wall or obstacle is stunned for
	var/charge_daze_time = 2 SECONDS
	var/frenzy_speed_mult = 0.8
	var/frenzy_damage_mult = 1.25
	var/frenzy_lower_bonus = 0
	var/frenzy_upper_bonus = 0

	/// Scale of this type against the sprite. The stat block of the type already accounts for it
	var/size_scale = 1
	/// Each pig rolls its scale within +/- this fraction of size_scale
	var/size_variance = 0.1
	/// How far this individual is from its type's average size, 1 is average
	var/size_roll = 1

/mob/living/simple_animal/hostile/hellpig/Initialize(mapload)
	. = ..()
	apply_size()

/// Rolls this pig's size and moves health, damage and the sprite with it
/mob/living/simple_animal/hostile/hellpig/proc/apply_size()
	size_roll = 1 + (rand(-100, 100) / 100) * size_variance
	var/final_scale = size_scale * size_roll
	if(final_scale != 1)
		// Scaling pivots on the middle of the 64x64 sprite, so lift or drop it to keep the feet on the tile
		pixel_y += round(32 * (final_scale - 1))
		resize = final_scale
		update_transform()
	if(size_roll != 1)
		var/hp_mult = size_roll * size_roll
		maxHealth = round(maxHealth * hp_mult)
		health = round(health * hp_mult)
		melee_damage_lower = round(melee_damage_lower * size_roll)
		melee_damage_upper = round(melee_damage_upper * size_roll)
		obj_damage = round(obj_damage * size_roll)

/mob/living/simple_animal/hostile/hellpig/examine(mob/user)
	. = ..()
	if(size_roll >= 1.06)
		. += span_notice("It is big even for a [initial(name)].")
	else if(size_roll <= 0.94)
		. += span_notice("It is small for a [initial(name)].")

/mob/living/simple_animal/hostile/hellpig/handle_automated_action()
	. = ..()
	try_start_charge()

/// Starts a charge if the target is in the open, at a distance worth charging across and the cooldown is up
/mob/living/simple_animal/hostile/hellpig/proc/try_start_charge()
	if(!can_charge || charging || winding_up || stat != CONSCIOUS || AIStatus != AI_ON || ckey || !target || QDELETED(target))
		return
	if(world.time < charge_cooldown || !CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE) || target.z != z)
		return
	var/dist = get_dist(src, target)
	if(dist < charge_min_range || dist > charge_max_range)
		return
	if(!isturf(loc) || !can_see(src, target, get_effective_vision_range(target)))
		return
	if(!shot_is_clear(get_turf(src), get_turf(target)))
		return
	winding_up = TRUE
	walk(src, 0)
	setDir(get_dir(src, target))
	visible_message(span_warning("[src] lowers its head and paws the ground!"))
	if(length(aggrosound))
		playsound(src, pick(aggrosound), 60, TRUE, SOUND_DISTANCE(10))
	addtimer(CALLBACK(src, PROC_REF(charge)), charge_windup, TIMER_DELETE_ME)

/mob/living/simple_animal/hostile/hellpig/proc/charge()
	winding_up = FALSE
	if(QDELETED(src) || stat != CONSCIOUS || AIStatus != AI_ON || !target || QDELETED(target))
		return
	var/turf/goal = get_turf(target)
	if(!goal || goal.z != z || goal == loc || get_dist(src, goal) > charge_max_range + 2)
		return
	if(!CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		return
	charging = TRUE
	charge_cooldown = world.time + (is_low_health ? charge_cooldown_time * 0.5 : charge_cooldown_time)
	ai_debug_log("hellpig_charge target=[target] dist=[get_dist(src, goal)]")
	visible_message(span_danger("[src] charges at [target]!"))
	walk(src, 0)
	setDir(get_dir(src, goal))
	// One tile past the target so a charge at a moving target still carries through
	throw_at(goal, get_dist(src, goal) + 1, 2, src, FALSE, callback = CALLBACK(src, PROC_REF(charge_end)))

/mob/living/simple_animal/hostile/hellpig/proc/charge_end()
	charging = FALSE
	if(!QDELETED(src) && stat == CONSCIOUS && target)
		Goto(target, move_to_delay, minimum_distance)

/mob/living/simple_animal/hostile/hellpig/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
	return ..()

/mob/living/simple_animal/hostile/hellpig/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!charging)
		return ..()
	charging = FALSE
	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(faction_check_mob(L))
			return
		if(L.mob_run_block(src, 90, "[name]", ATTACK_TYPE_TACKLE, 0, src, null, null) & BLOCK_SUCCESS)
			visible_message(span_warning("[L] turns [src]'s charge aside!"))
			return
		L.visible_message(span_danger("[src] gores [L] with its tusks!"), span_userdanger("[src] slams into you and gores you with its tusks!"))
		L.apply_damage(round(rand(melee_damage_lower, melee_damage_upper) * charge_damage_mult), BRUTE)
		L.Knockdown(charge_knockdown)
		playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 60, TRUE)
		shake_camera(L, 3, 2)
		return
	if(hit_atom && hit_atom.density)
		visible_message(span_danger("[src] rams into [hit_atom] and staggers!"))
		playsound(src, 'sound/effects/meteorimpact.ogg', 40, TRUE)
		COOLDOWN_START(src, melee_cooldown, charge_daze_time)
		if(isobj(hit_atom))
			var/obj/O = hit_atom
			O.take_damage(obj_damage, BRUTE, "melee", FALSE)

/mob/living/simple_animal/hostile/hellpig/Goto(target, delay, minimum_distance)
	if(winding_up || charging)
		return
	return ..()

/mob/living/simple_animal/hostile/hellpig/AttackingTarget()
	if(winding_up || charging)
		return
	return ..()

/mob/living/simple_animal/hostile/hellpig/make_low_health()
	if(!target)
		return
	..()
	visible_message(span_danger("[src] squeals in a frenzied rage!"))
	if(length(aggrosound))
		playsound(src, pick(aggrosound), 100, TRUE, SOUND_DISTANCE(15))
	speed *= frenzy_speed_mult
	move_to_delay *= frenzy_speed_mult
	frenzy_lower_bonus = round(melee_damage_lower * (frenzy_damage_mult - 1))
	frenzy_upper_bonus = round(melee_damage_upper * (frenzy_damage_mult - 1))
	melee_damage_lower += frenzy_lower_bonus
	melee_damage_upper += frenzy_upper_bonus
	is_low_health = TRUE

/mob/living/simple_animal/hostile/hellpig/make_high_health()
	if(!is_low_health)
		return
	speed /= frenzy_speed_mult
	move_to_delay /= frenzy_speed_mult
	melee_damage_lower -= frenzy_lower_bonus
	melee_damage_upper -= frenzy_upper_bonus
	frenzy_lower_bonus = 0
	frenzy_upper_bonus = 0
	is_low_health = FALSE

/mob/living/simple_animal/hostile/hellpig/LoseTarget(reason)
	. = ..()
	winding_up = FALSE
	if(is_low_health)
		make_high_health()

// ============================================================
// HELLPIG RUNT
// Half-grown and scrawny. Quick, bites, and never charges.
// ============================================================

/mob/living/simple_animal/hostile/hellpig/runt
	name = "hellpig runt"
	desc = "A scrawny, half-grown hellpig. Its tusks are still stubs but it bites like it means it."
	mob_armor = ARMOR_VALUE_HELLPIG_RUNT
	maxHealth = 90
	health = 90
	move_to_delay = 2
	melee_damage_lower = 8
	melee_damage_upper = 14
	armour_penetration = 0
	damage_threshold_penetration_mob = 0
	obj_damage = 20
	wound_bonus = 0
	bare_wound_bonus = 10
	footstep_type = FOOTSTEP_MOB_CLAW
	attack_verb_simple = "bites"
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 2)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 1)
	can_charge = FALSE
	low_health_threshold = 0
	size_scale = 0.55
	size_variance = 0.12

// ============================================================
// HELLPIG TUSKER
// Old boar, scarred and enormous. Charges more often, hits through a lot of armor and
// shrugs off a little more than a common hellpig.
// ============================================================

/mob/living/simple_animal/hostile/hellpig/tusker
	affix_chance = 3
	name = "hellpig tusker"
	desc = "A gigantic old hellpig, hide scarred and thick as plate, tusks as long as a man's arm. It has killed before and plans to again."
	mob_armor = ARMOR_VALUE_HELLPIG_TUSKER
	maxHealth = 480
	health = 480
	move_to_delay = 2.75
	melee_damage_lower = 28
	melee_damage_upper = 42
	armour_penetration = 0.2
	damage_threshold_penetration_mob = 6
	obj_damage = 120
	wound_bonus = 10
	bare_wound_bonus = 35
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	move_resist = MOVE_FORCE_STRONG
	color = "#d6b8ae"
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 8, /obj/item/stack/sheet/bone = 4, /obj/item/stack/sheet/sinew = 2)
	charge_cooldown_time = 7 SECONDS
	charge_max_range = 8
	charge_damage_mult = 1.5
	charge_knockdown = 40
	size_scale = 1.2
	size_variance = 0.08

// ============================================================
// HELLPIG SOW
// The biggest of a sty and the mother of half of it. Slower to build up a charge than a tusker but she is
// bigger, tougher and when she goes down to a frenzy she squeals for every pig in earshot.
// ============================================================

/mob/living/simple_animal/hostile/hellpig/sow
	affix_chance = 3
	name = "hellpig sow"
	desc = "A monstrous matriarch, bigger than a brahmin and twice as mean. She will tear apart anything that gets between her and her sty."
	mob_armor = ARMOR_VALUE_HELLPIG_TUSKER
	maxHealth = 420
	health = 420
	move_to_delay = 3
	melee_damage_lower = 24
	melee_damage_upper = 36
	armour_penetration = 0.15
	damage_threshold_penetration_mob = 5
	obj_damage = 100
	wound_bonus = 10
	bare_wound_bonus = 30
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	move_resist = MOVE_FORCE_STRONG
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 8, /obj/item/stack/sheet/bone = 3, /obj/item/stack/sheet/sinew = 2)
	charge_cooldown_time = 12 SECONDS
	charge_damage_mult = 1.4
	charge_knockdown = 30
	size_scale = 1.35
	size_variance = 0.05

/mob/living/simple_animal/hostile/hellpig/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/hellpig/sow/make_low_health()
	var/was_low = is_low_health
	. = ..()
	if(was_low || !is_low_health || !target)
		return
	// Her frenzy squeal is louder than the usual aggro call and pulls in pigs that already have the cooldown spent
	COOLDOWN_RESET(src, ding_spam_cooldown)
	summon_backup(10)

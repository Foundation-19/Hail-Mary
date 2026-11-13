/obj/structure/alien/resin/flower_bud_enemy //inheriting basic attack/damage stuff from alien structures
	name = "flower bud"
	desc = "A large pulsating plant..."
	icon = 'icons/effects/spacevines.dmi'
	icon_state = "flower_bud"
	layer = SPACEVINE_MOB_LAYER
	opacity = 0
	canSmoothWith = list()
	smooth = SMOOTH_FALSE
	/// The amount of time it takes to create a venus human trap, in deciseconds
	var/growth_time = 1200

/obj/structure/alien/resin/flower_bud_enemy/Initialize()
	. = ..()
	var/list/anchors = list()
	anchors += locate(x-2,y+2,z)
	anchors += locate(x+2,y+2,z)
	anchors += locate(x-2,y-2,z)
	anchors += locate(x+2,y-2,z)

	for(var/turf/T in anchors)
		var/datum/beam/B = Beam(T, "vine", time=INFINITY, maxdistance=5, beam_type=/obj/effect/ebeam/vine)
		B.sleep_time = 10 //these shouldn't move, so let's slow down updates to 1 second (any slower and the deletion of the vines would be too slow)
	addtimer(CALLBACK(src, PROC_REF(bear_fruit)), growth_time, TIMER_DELETE_ME)

/**
 * Spawns a venus human trap, then qdels itself.
 *
 * Displays a message, spawns a human venus trap, then qdels itself.
 */
/obj/structure/alien/resin/flower_bud_enemy/proc/bear_fruit()
	visible_message(span_danger("The plant has borne fruit!"))
	new /mob/living/simple_animal/hostile/venus_human_trap(get_turf(src))
	qdel(src)

/obj/effect/ebeam/vine
	name = "thick vine"
	mouse_opacity = MOUSE_OPACITY_ICON
	desc = "A thick vine, painful to the touch."

/obj/effect/ebeam/vine/Initialize()
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)


/obj/effect/ebeam/vine/proc/on_entered(atom/movable/AM)
	SIGNAL_HANDLER
	if(isliving(AM))
		var/mob/living/L = AM
		if(!isvineimmune(L) && !("trog" in L.faction))
			L.adjustBruteLoss(5)
			to_chat(L, span_alert("You cut yourself on the thorny vines."))

/**
 * Venus Human Trap
 *
 * The result of a kudzu flower bud, these enemies use vines to drag prey close to them for attack.
 *
 * A carnivorious plant which uses vines to catch and ensnare prey.  Spawns from kudzu flower buds.
 * Each one has a maximum of four vines, which can be attached to a variety of things.  Carbons are stunned when a vine is attached to them, and movable entities are pulled closer over time.
 * Attempting to attach a vine to something with a vine already attached to it will pull all movable targets closer on command.
 * Once the prey is in melee range, melee attacks from the venus human trap heals itself for 10% of its max health, assuming the target is alive.
 * Akin to certain spiders, venus human traps can also be possessed and controlled by ghosts.
 *
 */
/mob/living/simple_animal/hostile/venus_human_trap
	name = "venus human trap"
	desc = "Now you know how the fly feels."
	icon = 'icons/mob/monsters/freaks.dmi'	
	icon_state = "venus_human_trap"
	icon_dead = "venus_human_trap_d"

	mob_armor = ARMOR_VALUE_TRIBAL
	health = 110
	maxHealth = 110
	obj_damage = 60
	melee_damage_lower = 25
	melee_damage_upper = 25
	harm_intent_damage = 5

	layer = SPACEVINE_MOB_LAYER
	ranged = TRUE
	a_intent = INTENT_HARM
	attack_sound = 'sound/weapons/bladeslice.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 0
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	faction = list("hostile","vines","plants","jungle","trog")
	stat_attack = CONSCIOUS
	initial_language_holder = /datum/language_holder/venus
	del_on_death = TRUE
	/// A list of all the plant's vines
	var/list/vines = list()
	/// The maximum amount of vines a plant can have at one time
	var/max_vines = 4
	/// How far away a plant can attach a vine to something
	var/vine_grab_distance = 5
	/// Whether or not this plant is ghost possessable
	var/playable_plant = FALSE //Normal plants can **not** have players.
	/// Paralyze duration in deciseconds when a vine latches on. 0 means the vine only pulls
	var/vine_stun_ds = 20
	/// Extra deciseconds after the stun ends during which no plant can stun the same target again
	var/vine_lockout_ds = 60

/// Shared by all jungle/plant crowd control so two plants can't chain stuns. Returns TRUE if the target may be stunned now, and starts the lockout
/proc/plant_cc_try(mob/living/L, lockout_ds)
	var/static/list/locked_until = list()
	var/key = REF(L)
	if(locked_until[key] > world.time)
		return FALSE
	locked_until[key] = world.time + lockout_ds
	if(length(locked_until) > 30)
		for(var/stale in locked_until)
			if(locked_until[stale] <= world.time)
				locked_until -= stale
	return TRUE

/// Weak, short ranged ambusher that only drags prey and never stuns
/mob/living/simple_animal/hostile/venus_human_trap/sapling
	name = "venus trap sapling"
	desc = "A young man-eating plant. It can't hold much, but it will drag you toward its elders."
	mob_armor = ARMOR_VALUE_ZERO
	health = 45
	maxHealth = 45
	melee_damage_lower = 10
	melee_damage_upper = 14
	max_vines = 1
	vine_grab_distance = 3
	vine_stun_ds = 0

/// Large, tough plant that holds several vines at once and stuns a little longer
/mob/living/simple_animal/hostile/venus_human_trap/elder
	name = "elder venus human trap"
	desc = "An overgrown, thick-stemmed man-eater. Whatever it grabs does not get away easily."
	health = 260
	maxHealth = 260
	mob_armor = ARMOR_VALUE_TUNNELER
	mob_size = MOB_SIZE_LARGE
	melee_damage_lower = 28
	melee_damage_upper = 36
	max_vines = 3
	vine_grab_distance = 6
	vine_stun_ds = 25
	vine_lockout_ds = 80

/mob/living/simple_animal/hostile/venus_human_trap/ghost_playable
	playable_plant = TRUE //For admins that want to buss some harmless plants

/mob/living/simple_animal/hostile/venus_human_trap/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	pull_vines()

/mob/living/simple_animal/hostile/venus_human_trap/AttackingTarget()
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat != DEAD)
			adjustHealth(-maxHealth * 0.1)

/mob/living/simple_animal/hostile/venus_human_trap/OpenFire(atom/the_target)
	for(var/datum/beam/B in vines)
		if(B.target == the_target)
			pull_vines()
			ranged_cooldown = world.time + (ranged_cooldown_time * 0.5)
			return
	if(get_dist(src,the_target) > vine_grab_distance || vines.len == max_vines)
		return
	for(var/turf/T in getline(src,target))
		if (T.density)
			return
		for(var/obj/O in T)
			if(O.density)
				return
	if(isliving(the_target))
		var/mob/living/prey = the_target
		// Agility check: nimble prey slip the lash entirely
		if(!ckey && prob(clamp((prey.special_a - 4) * 7, 0, 60)))
			prey.visible_message(span_warning("[prey] dodges the lashing vine!"), span_notice("You dodge the lashing vine!"))
			ranged_cooldown = world.time + ranged_cooldown_time
			return

	var/datum/beam/newVine = Beam(the_target, "vine", time=INFINITY, maxdistance = vine_grab_distance, beam_type=/obj/effect/ebeam/vine)
	RegisterSignal(newVine, COMSIG_PARENT_QDELETING, PROC_REF(remove_vine), newVine)
	vines += newVine
	if(isliving(the_target))
		ensnare(the_target)
	ranged_cooldown = world.time + ranged_cooldown_time

/// Stuns a vined target. Endurance shortens the stun, and a target that was just stunned by any plant can't be stunned again until the lockout ends
/mob/living/simple_animal/hostile/venus_human_trap/proc/ensnare(mob/living/L)
	if(vine_stun_ds <= 0)
		return
	var/stun_time = clamp(vine_stun_ds - (L.special_e - 5) * 2, 6, vine_stun_ds + 10)
	if(!plant_cc_try(L, stun_time + vine_lockout_ds))
		return
	L.Paralyze(stun_time)

/mob/living/simple_animal/hostile/venus_human_trap/Login()
	. = ..()
	to_chat(src, span_boldwarning("You a venus human trap!  Protect the kudzu at all costs, and feast on those who oppose you!"))

/mob/living/simple_animal/hostile/venus_human_trap/attack_ghost(mob/user)
	. = ..()
	if(.)
		return
	humanize_plant(user)

/**
 * Sets a ghost to control the plant if the plant is eligible
 *
 * Asks the interacting ghost if they would like to control the plant.
 * If they answer yes, and another ghost hasn't taken control, sets the ghost to control the plant.
 * Arguments:
 * * mob/user - The ghost to possibly control the plant
 */

/mob/living/simple_animal/hostile/venus_human_trap/proc/humanize_plant(mob/user)
	if(key || !playable_plant || stat)
		return
	var/plant_ask = alert("Become a venus human trap?", "Are you reverse vegan?", "Yes", "No")
	if(plant_ask == "No" || QDELETED(src))
		return
	if(key)
		to_chat(user, span_warning("Someone else already took this plant!"))
		return
	key = user.key
	log_game("[key_name(src)] took control of [name].")

/**
 * Manages how the vines should affect the things they're attached to.
 *
 * Pulls all movable targets of the vines closer to the plant
 * If the target is on the same tile as the plant, destroy the vine
 * Removes any QDELETED vines from the vines list.
 */
/mob/living/simple_animal/hostile/venus_human_trap/proc/pull_vines()
	for(var/datum/beam/B in vines)
		if(isliving(B.target))
			var/mob/living/prey = B.target
			// Strength check: strong prey rip the vine out
			if(!prey.IsParalyzed() && prob(clamp((prey.special_s - 4) * 6, 0, 45)))
				prey.visible_message(span_warning("[prey] tears free of the vine!"), span_notice("You tear free of the vine!"))
				B.End()
				continue
		if(istype(B.target, /atom/movable))
			var/atom/movable/AM = B.target
			if(!AM.anchored)
				step(AM,get_dir(AM,src))
		if(get_dist(src,B.target) == 0)
			B.End()

/**
 * Removes a vine from the list.
 *
 * Removes the vine from our list.
 * Called specifically when the vine is about to be destroyed, so we don't have any null references.
 * Arguments:
 * * datum/beam/vine - The vine to be removed from the list.
 */
mob/living/simple_animal/hostile/venus_human_trap/proc/remove_vine(datum/beam/vine, force)
	vines -= vine

// Fallout 13 - RANDOM MOB AFFIXES
// A chance for a hostile mob to spawn with one random modifier: swift, brutal, hardy, regenerating,
// vampiric, toxic or volatile. Adds variety to every family without writing new mobs, and the
// "brutal" affix also carries AP / DT penetration, which helps against armor creep.
//
// Each family draws from its own pool (see get_affix_pool), and the prefix and description wording
// change with the family, so a soldier is "hardened" and a robot is "plated" for the same effect.
//
// Off by default: affix_chance is 0 on every mob. apply_penetration_pass.py sets a small chance and a
// pool on selected families, and injects the two hooks this file needs into hostile.dm:
//   - roll_affix() at the end of /hostile/Initialize()
//   - affix_death() at the start of /hostile/death()
// Without those hooks nothing in this file ever runs, so adding the file alone is safe.
//
// Player-controlled mobs never roll (ckey is empty at spawn time, so playable subtypes are also set
// to chance 0 by the script). Admin-spawned mobs CAN roll, because the admin-spawned flag is set after
// Initialize(); varedit affix_chance to 0 before spawning if you want a vanilla one.

/mob/living/simple_animal/hostile
	/// 0-100. Chance for this mob to spawn with a random affix. 0 = never.
	var/affix_chance = 0
	/// The affix this mob has, if any ("swift", "brutal", ...).
	var/affix = null
	/// Which affix pool this family draws from (see get_affix_pool). Set per family by the script.
	var/affix_pool_type = "beast"
	/// How many seconds a "volatile" mob keeps ticking after it dies before it goes off.
	var/affix_fuse_seconds = 3

// Affix pools by family, so a mob only rolls things that fit what it is:
//   human       - people: faster, harder hitting, tougher. No poison, no blood drinking, no bursting.
//   ghoul       - rad-fed regeneration is classic ghoul lore; rot makes them toxic; irradiated ones can burst.
//   mutant      - FEV: tougher, stronger, regenerating, and the odd one carrying something explosive.
//   beast       - ordinary predators and herd animals: fast, strong, tough, a little regeneration.
//   venomous    - stalkers, scorpions, centipedes, aradnids: toxic is their thing.
//   insect      - bugs: fast, strong, tough.
//   bloodsucker - bloodbugs: the only family that gets vampiric.
//   robot       - machines: tuned, overcharged, plated, self-repairing, or with an unstable power cell.
// Edit the weights here to rebalance. Unknown pool names fall back to "beast".
/mob/living/simple_animal/hostile/proc/get_affix_pool()
	var/static/list/pools = list(
		"human" = list("swift" = 30, "brutal" = 40, "hardy" = 30),
		"ghoul" = list("swift" = 15, "brutal" = 20, "hardy" = 20, "regenerating" = 30, "toxic" = 15, "volatile" = 5),
		"mutant" = list("hardy" = 30, "brutal" = 30, "regenerating" = 30, "volatile" = 5),
		"beast" = list("swift" = 30, "brutal" = 30, "hardy" = 30, "regenerating" = 10),
		"venomous" = list("swift" = 20, "brutal" = 15, "hardy" = 20, "toxic" = 45),
		"insect" = list("swift" = 35, "brutal" = 30, "hardy" = 35),
		"bloodsucker" = list("swift" = 25, "brutal" = 25, "vampiric" = 50),
		"robot" = list("swift" = 20, "brutal" = 25, "hardy" = 30, "regenerating" = 15, "volatile" = 5)
	)
	var/list/pool = pools[affix_pool_type]
	if(!pool)
		pool = pools["beast"]
	return pool

// Name prefix per family. Anything not listed here falls back to the affix id itself.
/mob/living/simple_animal/hostile/proc/get_affix_label(affix_id)
	var/static/list/labels = list(
		"human" = list("swift" = "quick", "brutal" = "vicious", "hardy" = "hardened"),
		"ghoul" = list("swift" = "quick", "brutal" = "savage", "hardy" = "tough", "regenerating" = "rad-fed", "toxic" = "rotting", "volatile" = "bloated"),
		"mutant" = list("hardy" = "hulking", "brutal" = "savage", "regenerating" = "regenerating", "volatile" = "ticking"),
		"beast" = list("swift" = "swift", "brutal" = "savage", "hardy" = "massive", "regenerating" = "relentless"),
		"venomous" = list("swift" = "swift", "brutal" = "savage", "hardy" = "armored", "toxic" = "venomous"),
		"insect" = list("swift" = "swift", "brutal" = "savage", "hardy" = "armored"),
		"bloodsucker" = list("swift" = "swift", "brutal" = "savage", "vampiric" = "blood-gorged"),
		"robot" = list("swift" = "tuned", "brutal" = "overcharged", "hardy" = "plated", "regenerating" = "self-repairing", "volatile" = "ticking")
	)
	var/list/set_labels = labels[affix_pool_type]
	if(set_labels && set_labels[affix_id])
		return set_labels[affix_id]
	return affix_id

// Description line per family where the generic one would read wrong.
/mob/living/simple_animal/hostile/proc/get_affix_blurb(affix_id)
	var/static/list/robot_blurbs = list(
		"swift" = "Its servos have been tuned well past spec.",
		"brutal" = "Its actuators are running overcharged, and every blow lands like a piston.",
		"hardy" = "Extra plating has been bolted over its chassis.",
		"regenerating" = "Its repair routines patch damage almost as fast as you cause it.",
		"volatile" = "Its power cell is unstable. When it dies it keeps ticking for a few seconds, then goes off. Back away from the wreck."
	)
	var/static/list/generic_blurbs = list(
		"swift" = "It moves faster than others of its kind.",
		"brutal" = "It hits harder and its blows punch through armor.",
		"hardy" = "It is much tougher than others of its kind.",
		"regenerating" = "Its wounds close up almost as fast as you make them.",
		"vampiric" = "It heals itself when it bites into prey.",
		"toxic" = "Its attacks leave poison behind.",
		"volatile" = "When it dies it keeps ticking for a few seconds, then goes off. Back away from the body."
	)
	if(affix_pool_type == "robot" && robot_blurbs[affix_id])
		return robot_blurbs[affix_id]
	return generic_blurbs[affix_id]

/mob/living/simple_animal/hostile/proc/roll_affix()
	if(!affix_chance || affix || ckey || QDELETED(src))
		return
	if(!prob(affix_chance))
		return
	var/list/pool = get_affix_pool()
	var/total = 0
	for(var/key in pool)
		total += pool[key]
	var/roll = rand(1, total)
	for(var/key in pool)
		roll -= pool[key]
		if(roll <= 0)
			apply_affix(key)
			return

/mob/living/simple_animal/hostile/proc/apply_affix(affix_id)
	affix = affix_id
	switch(affix_id)
		if("swift")
			move_to_delay = max(1, move_to_delay * 0.8)
			speed = max(0.5, speed * 0.85)
		if("brutal")
			melee_damage_lower = round(melee_damage_lower * 1.25)
			melee_damage_upper = round(melee_damage_upper * 1.25)
			armour_penetration = min(1, armour_penetration + 0.1)
			damage_threshold_penetration_mob += 2
		if("hardy")
			maxHealth = round(maxHealth * 1.5)
			health = maxHealth
		if("regenerating")
			addtimer(CALLBACK(src, PROC_REF(affix_regen_tick)), 5 SECONDS)
		if("vampiric")
			RegisterSignal(src, COMSIG_HOSTILE_ATTACKINGTARGET, PROC_REF(affix_on_attack))
		if("toxic")
			RegisterSignal(src, COMSIG_HOSTILE_ATTACKINGTARGET, PROC_REF(affix_on_attack))
		if("volatile")
			affix = "volatile" // nothing to set up here, affix_death() handles the blast
		else
			affix = null
			return
	var/label = get_affix_label(affix_id)
	var/blurb = get_affix_blurb(affix_id)
	name = "[label] [name]"
	if(blurb)
		desc = "[desc]<br><i>[blurb]</i>"

/mob/living/simple_animal/hostile/proc/affix_regen_tick()
	if(QDELETED(src) || stat == DEAD)
		return
	if(health < maxHealth)
		adjustBruteLoss(-(maxHealth * 0.02))
	addtimer(CALLBACK(src, PROC_REF(affix_regen_tick)), 5 SECONDS)

/mob/living/simple_animal/hostile/proc/affix_on_attack(datum/source, atom/attacked)
	SIGNAL_HANDLER
	if(QDELETED(src) || stat == DEAD)
		return
	switch(affix)
		if("vampiric")
			if(isliving(attacked) && health < maxHealth)
				adjustBruteLoss(-6)
		if("toxic")
			if(ishuman(attacked))
				var/mob/living/carbon/human/H = attacked
				H.reagents.add_reagent(/datum/reagent/toxin, 5)

/// Called from /hostile/death() by the hook the script injects.
/// "Volatile" is a martyrdom timer, not an instant blast: the body keeps ticking for a few seconds
/// (beeps and a message every second) and only then goes off with a small light blast. Anyone who
/// backs away when it dies is never hit. Leave "volatile" out of the pools in get_affix_pool() to
/// turn the affix off entirely.
/mob/living/simple_animal/hostile/proc/affix_death()
	if(affix != "volatile")
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	visible_message(span_danger("\The [src] starts to tick! Back away!"))
	new /obj/effect/affix_fuse(T, affix_fuse_seconds)

/// Invisible fuse left where a volatile mob died. Separate object so the countdown still runs even if
/// the mob deletes itself on death. Blast is light only: it hurts what is standing next to it and does
/// not breach walls.
/obj/effect/affix_fuse
	name = "ticking"
	anchored = TRUE
	var/seconds_left = 3

/obj/effect/affix_fuse/Initialize(mapload, fuse_seconds = 3)
	. = ..()
	seconds_left = max(1, fuse_seconds)
	addtimer(CALLBACK(src, PROC_REF(tick)), 1 SECONDS)

/obj/effect/affix_fuse/proc/tick()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return
	seconds_left--
	if(seconds_left > 0)
		playsound(T, 'sound/machines/triple_beep.ogg', 60, TRUE)
		T.visible_message(span_warning("The body ticks louder..."))
		addtimer(CALLBACK(src, PROC_REF(tick)), 1 SECONDS)
		return
	T.visible_message(span_danger("The body goes off in a small, violent blast!"))
	SSexplosion_spam.queue_explosion(T, 0, 0, 2, flash = 0, flame_range = 1, source = null)
	qdel(src)

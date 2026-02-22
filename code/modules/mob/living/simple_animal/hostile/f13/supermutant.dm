// Fallout 13 super mutants

// ============================================================
// BASE SUPER MUTANT
// ============================================================

/mob/living/simple_animal/hostile/supermutant
	name = "super mutant"
	desc = "A gigantic, green, angry-looking humanoid wrapped in a jumpsuit that may have fit him... her? at some point. \
		They're a mountain of furry muscle, and their fists look like they could punch through solid steel. Have fun!"
	icon = 'icons/fallout/mobs/supermutant.dmi'
	icon_state = "hulk_113_s"
	icon_living = "hulk_113_s"
	icon_dead = "hulk_113_s"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_SUPERMUTANT_BASE
	sentience_type = SENTIENCE_BOSS
	maxHealth = 110
	health = 110
	stat_attack = CONSCIOUS
	robust_searching = 1
	check_friendly_fire = FALSE
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES

	speak_chance = 10
	speak = list("GRRRRRR!", "ARGH!", "NNNNNGH!", "HMPH!", "ARRRRR!")
	speak_emote = list("shouts", "yells")
	emote_taunt = list("yells")
	emote_taunt_sound = list(
		'sound/f13npc/supermutant/attack1.ogg',
		'sound/f13npc/supermutant/attack2.ogg',
		'sound/f13npc/supermutant/attack3.ogg'
	)
	taunt_chance = 30

	turns_per_move = 5
	move_to_delay = 4
	response_help_simple = "touches"
	response_disarm_simple = "pushes"
	response_harm_simple = "hits"

	faction = list("hostile", "supermutant")

	melee_damage_lower = 20
	melee_damage_upper = 35

	aggro_vision_range = 7
	vision_range = 8

	mob_size = MOB_SIZE_LARGE
	move_resist = MOVE_FORCE_OVERPOWERING
	attack_verb_simple = "smashes"
	attack_sound = "punch"
	a_intent = INTENT_GRAB

	idlesound = list(
		'sound/f13npc/supermutant/idle1.ogg',
		'sound/f13npc/supermutant/idle2.ogg',
		'sound/f13npc/supermutant/idle3.ogg',
		'sound/f13npc/supermutant/idle4.ogg'
	)
	death_sound = list(
		'sound/f13npc/supermutant/death1.ogg',
		'sound/f13npc/supermutant/death2.ogg'
	)
	aggrosound = list(
		'sound/f13npc/supermutant/alert1.ogg',
		'sound/f13npc/supermutant/alert2.ogg',
		'sound/f13npc/supermutant/alert3.ogg',
		'sound/f13npc/supermutant/alert4.ogg'
	)

	wound_bonus = 0
	bare_wound_bonus = 0
	footstep_type = FOOTSTEP_MOB_HEAVY

	// Rage mode vars
	low_health_threshold = 0.4
	var/color_rage = "#ff9999"

	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE

	can_open_doors = TRUE
	can_open_airlocks = FALSE

	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

// FIX: Consolidated death() icon swap here so all subtypes inherit it.
// Previously every subtype copy-pasted: icon = dead_dmi, icon_state = icon_dead, anchored = FALSE.
// Now they all inherit this single override.
/mob/living/simple_animal/hostile/supermutant/death(gibbed)
	icon = 'icons/fallout/mobs/supermutant_dead.dmi'
	icon_state = icon_dead
	. = ..()

// FIX: Added if(.) return guard. Previously summon_backup fired unconditionally,
// meaning player-controlled supermutants would also call for backup on aggro.
/mob/living/simple_animal/hostile/supermutant/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

// Friendly fire resistance
/mob/living/simple_animal/hostile/supermutant/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/supermutant))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

/// RAGE MODE - faster, harder hitting, can smash through walls
/mob/living/simple_animal/hostile/supermutant/make_low_health()
	visible_message(span_danger("[src] roars with primal fury!!!"))
	playsound(src, pick(aggrosound), 100, 1, SOUND_DISTANCE(15))
	color = color_rage
	speed *= 0.8
	melee_damage_lower = round(melee_damage_lower * 1.3)
	melee_damage_upper = round(melee_damage_upper * 1.3)
	obj_damage *= 1.5
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES | ENVIRONMENT_SMASH_WALLS
	sound_pitch = -30
	is_low_health = TRUE

/// Calming down from rage
/mob/living/simple_animal/hostile/supermutant/make_high_health()
	visible_message(span_notice("[src]'s rage subsides."))
	color = initial(color)
	speed = initial(speed)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	obj_damage = initial(obj_damage)
	environment_smash = initial(environment_smash)
	sound_pitch = initial(sound_pitch)
	is_low_health = FALSE

/mob/living/simple_animal/hostile/supermutant/Move()
	if(is_low_health && health > 0)
		DestroySurroundings()
	. = ..()

// ============================================================
// PLAYABLE SUPERMUTANT
// ============================================================

/mob/living/simple_animal/hostile/supermutant/playable
	maxHealth = 110
	health = 110
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = 0
	anchored = FALSE
	dextrous = TRUE
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

// ============================================================
// BRAH-MIN WATCHER
// ============================================================

/mob/living/simple_animal/pet/dog/mutant
	name = "Brah-Min"
	desc = "A large, docile supermutant. Adopted by Shale's Army as a sort of watch dog for their brahmin herd."
	icon = 'icons/fallout/mobs/supermutant.dmi'
	icon_state = "hulk_113_s"
	icon_living = "hulk_113_s"
	icon_dead = "hulk_113_s"
	maxHealth = 240
	health = 240
	speak_chance = 7
	move_resist = MOVE_FORCE_OVERPOWERING
	mob_size = MOB_SIZE_LARGE
	speak = list(
		"Hey! These my brahmins!",
		"And I say, HEY-YEY-AAEYAAA-EYAEYAA! HEY-YEY-AAEYAAA-EYAEYAA! I SAID HEY, what's going on?",
		"What do you want from my brahmins?!",
		"Me gonna clean brahmin poop again now!",
		"I love brahmins, brahmins are good, just poop much!",
		"Do not speak to my brahmins ever again, you hear?!",
		"Bad raiders come to steal my brahmins - I crush with shovel!",
		"Do not come to my brahmins! Do not touch my brahmins! Do not look at my brahmins!",
		"I'm watching you, and my brahmins watch too!",
		"Brahmins say moo, and I'm saying - hey, get your ugly face out of my way!",
		"I... I remember, before the fire... THERE WERE NO BRAHMINS!",
		"No! No wind brahmin here! Wind brahmin lie!"
	)
	speak_emote = list("shouts", "yells")
	emote_hear = list("yawns", "mumbles", "sighs")
	emote_see = list("raises his shovel", "shovels some dirt away", "waves his shovel above his head angrily")
	response_help_simple = "pat"
	response_disarm_simple = "push"
	response_harm_simple = "punch"

/mob/living/simple_animal/pet/dog/mutant/death(gibbed)
	icon = 'icons/fallout/mobs/supermutant_dead.dmi'
	icon_state = icon_dead
	if(!gibbed)
		visible_message(span_danger("\the [src] shouts something incoherent about brahmins for the last time and stops moving..."))
	. = ..()

// ============================================================
// MELEE SUPERMUTANT
// ============================================================

/mob/living/simple_animal/hostile/supermutant/meleemutant
	name = "sledgehammer supermutant"
	desc = "An enormous, green tank of a humanoid wrapped in thick sheets of metal and boiled leather from hopefully a brahmin or two. \
		They're a mountain of furry muscle, and their fists look like they could punch through solid steel. \
		If that wasn't bad enough, this monstrous critter is wielding a sledgehammer. Lovely."
	icon_state = "hulk_melee_s"
	icon_living = "hulk_melee_s"
	icon_dead = "hulk_melee_s"
	mob_armor = ARMOR_VALUE_SUPERMUTANT_MELEE
	maxHealth = 110
	health = 110
	mob_armor_tokens = list(
		ARMOR_MODIFIER_UP_MELEE_T1,
		ARMOR_MODIFIER_DOWN_LASER_T2,
		ARMOR_MODIFIER_UP_DT_T2
	)
	melee_damage_lower = 18
	melee_damage_upper = 44
	attack_sound = "hit_swing"

// ============================================================
// RANGED SUPERMUTANT
// ============================================================

/mob/living/simple_animal/hostile/supermutant/rangedmutant
	desc = "An enormous green mass of a humanoid wrapped in thick sheets of metal and boiled leather from hopefully a brahmin or two. \
		They're a mountain of furry muscle, and their fists look like they could punch through solid steel. \
		If that wasn't bad enough, this monstrous critter is wielding a crude shotgun. Lovely."
	icon_state = "hulk_ranged_s"
	icon_living = "hulk_ranged_s"
	icon_dead = "hulk_ranged_s"
	mob_armor = ARMOR_VALUE_SUPERMUTANT_RANGER
	maxHealth = 110
	health = 110

	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1

	casingtype = /obj/item/ammo_casing/shotgun/improvised
	projectiletype = null
	projectilesound = 'sound/f13weapons/shotgun.ogg'
	sound_after_shooting = 'sound/weapons/shotguninsert.ogg'
	sound_after_shooting_delay = 1 SECONDS
	extra_projectiles = 1
	auto_fire_delay = GUN_BURSTFIRE_DELAY_FAST
	ranged_cooldown_time = 4 SECONDS

	loot = list(
		/obj/item/ammo_box/shotgun/improvised,
		/obj/item/gun/ballistic/revolver/widowmaker
	)

	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(SHOTGUN_VOLUME),
		SP_VOLUME_SILENCED(SHOTGUN_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(SHOTGUN_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(SHOTGUN_DISTANT_SOUND),
		SP_DISTANT_RANGE(SHOTGUN_RANGE_DISTANT)
	)

// Varmint rifle variant
/mob/living/simple_animal/hostile/supermutant/rangedmutant/varmint
	desc = "An enormous green mass of a humanoid wrapped in thick sheets of metal and boiled leather from hopefully a brahmin or two. \
		They're a mountain of furry muscle, and their fists look like they could punch through solid steel. \
		If that wasn't bad enough, this monstrous critter is wielding some kind of rifle. Lovely."
	casingtype = null
	projectiletype = /obj/item/projectile/bullet/a556/simple
	projectilesound = 'sound/f13weapons/assaultrifle_fire.ogg'
	sound_after_shooting = null
	extra_projectiles = 0
	ranged_cooldown_time = 2 SECONDS
	loot = list(/obj/item/gun/ballistic/automatic/varmint)

// ============================================================
// LEGENDARY SUPERMUTANT
// ============================================================

/mob/living/simple_animal/hostile/supermutant/legendary
	name = "legendary super mutant"
	desc = "A huge and ugly mutant humanoid. He has a faint yellow glow to him, scars adorn his body. This super mutant is a grizzled veteran of combat. Look out!"
	color = "#FFFF00"
	color_rage = "#ffcc66"
	mob_armor = ARMOR_VALUE_SUPERMUTANT_LEGEND
	maxHealth = 130
	health = 130
	icon_state = "hulk_113_s"
	icon_living = "hulk_113_s"
	icon_dead = "hulk_113_s"
	melee_damage_lower = 27
	melee_damage_upper = 57
	mob_size = MOB_SIZE_HUGE // FIX: was raw 5

// ============================================================
// NIGHTKIN
// Semi-invisible supermutant variants
// ============================================================

/mob/living/simple_animal/hostile/supermutant/nightkin
	name = "nightkin"
	desc = "A blue variant of the standard Super Mutant, equipped with stealth boys."
	icon_state = "night_s"
	icon_living = "night_s"
	icon_dead = "night_s"
	mob_armor = ARMOR_VALUE_SUPERMUTANT_MELEE
	maxHealth = 120
	health = 120
	alpha = 80
	force_threshold = 15
	melee_damage_lower = 27
	melee_damage_upper = 50
	attack_verb_simple = "slashes"
	attack_sound = "sound/weapons/bladeslice.ogg"
	color_rage = "#9999ff"
	
	// Nightkin have excellent night vision for stealth operations
	has_low_light_vision = TRUE

/mob/living/simple_animal/hostile/supermutant/nightkin/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)
	alpha = 255

/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant
	name = "nightkin veteran"
	desc = "A blue variant of the standard Super Mutant, equipped with stealth boys. This one is holding an Assault Rifle."
	icon_state = "night_ranged_s"
	icon_living = "night_ranged_s"
	icon_dead = "night_ranged_s"
	mob_armor = ARMOR_VALUE_SUPERMUTANT_RANGER
	maxHealth = 120
	health = 120
	alpha = 80
	force_threshold = 15
	melee_damage_lower = 25
	melee_damage_upper = 37
	attack_verb_simple = "smashes"
	attack_sound = "punch"

	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 4

	extra_projectiles = 1
	projectiletype = /obj/item/projectile/bullet/a556/simple
	projectilesound = 'sound/f13weapons/assaultrifle_fire.ogg'
	loot = list(/obj/item/ammo_box/magazine/m556/rifle)

	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(RIFLE_LIGHT_VOLUME),
		SP_VOLUME_SILENCED(RIFLE_LIGHT_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(RIFLE_LIGHT_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(RIFLE_LIGHT_DISTANT_SOUND),
		SP_DISTANT_RANGE(RIFLE_LIGHT_RANGE_DISTANT)
	)

/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)
	alpha = 255

/mob/living/simple_animal/hostile/supermutant/nightkin/elitemutant
	name = "nightkin elite"
	desc = "A blue variant of the standard Super Mutant, and a remnant of the Masters Army."
	icon_state = "night_boss_s"
	icon_living = "night_boss_s"
	icon_dead = "night_boss_s"
	mob_armor = ARMOR_VALUE_SUPERMUTANT_LEGEND
	maxHealth = 110
	health = 110
	alpha = 80
	force_threshold = 15
	melee_damage_lower = 20
	melee_damage_upper = 47
	attack_verb_simple = "smashes"
	attack_sound = "punch"

	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 5

	projectiletype = /obj/item/projectile/f13plasma/repeater
	projectilesound = 'sound/f13weapons/plasma_rifle.ogg'
	loot = list(/obj/item/stock_parts/cell/ammo/mfc)

	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PLASMA_VOLUME),
		SP_VOLUME_SILENCED(PLASMA_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PLASMA_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(PLASMA_DISTANT_SOUND),
		SP_DISTANT_RANGE(PLASMA_RANGE_DISTANT)
	)

/mob/living/simple_animal/hostile/supermutant/nightkin/elitemutant/Aggro()
	. = ..()
	if(.) // FIX: same guard as nightkin/Aggro
		return
	summon_backup(10)
	alpha = 255

// ============================================================
// CULT OF RAIN VARIANTS
// ============================================================

/mob/living/simple_animal/hostile/supermutant/meleemutant/rain
	name = "super mutant rain cultist"
	desc = "A super mutant covered in blue markings that has been indoctrinated into the Cult Of Rain. This one wields a sledgehammer blessed by the rain gods."
	color = "#6B87C0"
	color_rage = "#4488cc"
	speak_chance = 10
	speak = list("The rain cleanses!", "Sacrifices for the rain gods!", "The thunder guides my fury!", "I am become the storm, destroyer of all heretics!", "The priests will be pleased with my sacrifices!")
	maxHealth = 140
	health = 140
	damage_coeff = list(BRUTE = 0.9, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	melee_damage_lower = 24
	melee_damage_upper = 48

/mob/living/simple_animal/hostile/supermutant/rangedmutant/rain
	name = "super mutant rain cultist"
	desc = "A super mutant covered in blue markings that has been indoctrinated into the Cult Of Rain. This one wields a hunting rifle blessed by the rain gods."
	color = "#6B87C0"
	color_rage = "#4488cc"
	speak_chance = 10
	speak = list("The rain cleanses!", "Sacrifices for the rain gods!", "The thunder guides my fury!", "I am become the storm, destroyer of all heretics!", "The priests will be pleased with my sacrifices!")
	maxHealth = 140
	health = 140
	damage_coeff = list(BRUTE = 1, BURN = 0.9, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	melee_damage_lower = 24
	melee_damage_upper = 48

// Berserker nightkin - charges when shot, leaves destruction in its wake
/mob/living/simple_animal/hostile/supermutant/nightkin/rain
	name = "nightkin berserker rain priest"
	desc = "A nightkin that spreads the word of the Cult Of Rain. They are covered in dark blue markings, indicating that they have been blessed by the rain god Odile."
	color = "#6666FF"
	color_rage = "#3333ff"
	speak_chance = 10
	speak = list("The rain speaks through me!", "Witness the gifts of rain!", "The great flood will come upon us! Do not fear it!", "My life for the rain gods!", "The rain gods can always use more sacrifices!")
	maxHealth = 180
	health = 180
	damage_coeff = list(BRUTE = 0.8, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	melee_damage_lower = 24
	melee_damage_upper = 48
	var/charging = FALSE
	var/charge_cooldown = 0
	var/charge_cooldown_time = 8 SECONDS

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		return

	if(!charging && world.time > charge_cooldown && prob(20))
		visible_message(span_danger("\The [src] lets out a vicious war cry!"))
		addtimer(CALLBACK(src, PROC_REF(Charge)), 0.3 SECONDS)

	if(prob(85) || Proj.damage > 30)
		return ..()
	visible_message(span_danger("\The [Proj] is absorbed by \the [src]'s thick skin!"))
	return 0

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!charging)
		. = ..()

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/AttackingTarget()
	if(!charging)
		. = ..()

// Blocks pathfinding during charge throw so AI doesn't fight the physics
/mob/living/simple_animal/hostile/supermutant/nightkin/rain/Goto(target, delay, minimum_distance)
	if(!charging)
		. = ..()

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/Move()
	if(charging || (is_low_health && health > 0))
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		DestroySurroundings()
	. = ..()

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/proc/Charge()
	if(!target)
		return

	var/turf/T = get_turf(target)
	if(!T || T == loc)
		return

	charging = TRUE
	charge_cooldown = world.time + charge_cooldown_time

	visible_message(span_danger("[src] charges with terrifying fury!"))
	DestroySurroundings()
	walk(src, 0)
	setDir(get_dir(src, T))

	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc, src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix() * 2, time = 0.1 SECONDS)

	throw_at(T, get_dist(src, T), 2, src, FALSE, callback = CALLBACK(src, PROC_REF(charge_end)))

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/proc/charge_end(atom/hit_atom)
	charging = FALSE
	if(target)
		Goto(target, move_to_delay, minimum_distance)

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/Bump(atom/A)
	if(charging)
		if((isturf(A) || isobj(A)) && A.density)
			A.ex_act(EXPLODE_HEAVY)
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
		DestroySurroundings()
	. = ..()

/mob/living/simple_animal/hostile/supermutant/nightkin/rain/throw_impact(atom/A)
	if(!charging)
		return ..()

	if(isliving(A))
		var/mob/living/L = A
		L.visible_message(span_danger("[src] slams into [L]!"), span_userdanger("[src] slams into you!"))
		L.apply_damage(melee_damage_upper, BRUTE)
		playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, 1)
		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)
		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
		L.throw_at(throwtarget, 3, 2)

	charging = FALSE

// Guardian nightkin - ranged fire-release aura when hit
/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/rain
	name = "nightkin guardian rain priest"
	desc = "A nightkin that spreads the word of the Cult Of Rain. They are covered in dark blue markings, indicating that they have been blessed by the rain god Ignacio."
	color = "#6666FF"
	color_rage = "#3333ff"
	speak_chance = 10
	speak = list("The rain speaks through me!", "Witness the gifts of rain!", "The great flood will come upon us! Do not fear it!", "My life for the rain gods!", "The rain gods can always use more sacrifices!")
	maxHealth = 160
	health = 160
	damage_coeff = list(BRUTE = 1, BURN = 0.8, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	melee_damage_lower = 35
	melee_damage_upper = 60
	extra_projectiles = 2

	combat_mode = COMBAT_MODE_RANGED
	retreat_distance = 4
	minimum_distance = 4

/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/rain/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/glow_heal, chosen_targets = /mob/living/simple_animal/hostile/supermutant, allow_revival = FALSE, restrict_faction = null, type_healing = BRUTELOSS | FIRELOSS)

/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/rain/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		return
	if(prob(15))
		visible_message(span_danger("\The [src] lets out a vicious war cry!"))
		fire_release()
	if(prob(85) || Proj.damage > 30)
		return ..()
	visible_message(span_danger("\The [Proj] is absorbed by \the [src]'s thick skin!"))
	return 0

/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/rain/proc/fire_release()
	playsound(get_turf(src), 'sound/magic/fireball.ogg', 200, 1)
	for(var/d in GLOB.cardinals)
		INVOKE_ASYNC(src, PROC_REF(fire_release_wall), d)

/mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/rain/proc/fire_release_wall(dir)
	var/list/hit_things = list(src)
	var/turf/E = get_edge_target_turf(src, dir)
	var/range = 10
	var/turf/previousturf = get_turf(src)
	for(var/turf/J in getline(src, E))
		if(!range || (J != previousturf && (!previousturf.atmos_adjacent_turfs || !previousturf.atmos_adjacent_turfs[J])))
			break
		range--
		new /obj/effect/hotspot(J)
		J.hotspot_expose(500, 500, 1)
		for(var/mob/living/L in J.contents - hit_things)
			if(istype(L, /mob/living/simple_animal/hostile/supermutant/nightkin/rangedmutant/rain))
				continue
			L.adjustFireLoss(20)
			to_chat(L, span_userdanger("You're hit by the nightkin's release of energy!"))
			hit_things += L
		previousturf = J
		sleep(1) // FIX: was addtimer(1) with no callback - invalid call that would runtime

// Rain lord nightkin - most powerful, dual resistance, healing aura
/mob/living/simple_animal/hostile/supermutant/nightkin/elitemutant/rain
	name = "nightkin rain lord"
	desc = "A nightkin that writes the word of the Cult Of Rain. They are covered in dark blue markings and are adorned in pieces of bone armor, indicating that they are blessed by the rain god Hyacinth."
	color = "#6666FF"
	color_rage = "#3333ff"
	speak_chance = 10
	speak = list("The great flood will come, I will make sure of it!", "Rain god Odile, I call upon you for wrath!", "Rain god Hyacinth, I call upon you for a tranquil mind!", "Rain god Ignacio, I call upon you for protection!", "The storm rages within!")
	maxHealth = 200
	health = 200
	damage_coeff = list(BRUTE = 0.8, BURN = 0.8, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	melee_damage_lower = 28
	melee_damage_upper = 62
	extra_projectiles = 1

/mob/living/simple_animal/hostile/supermutant/nightkin/elitemutant/rain/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/glow_heal, chosen_targets = /mob/living/simple_animal/hostile/supermutant, allow_revival = FALSE, restrict_faction = null, type_healing = BRUTELOSS | FIRELOSS)

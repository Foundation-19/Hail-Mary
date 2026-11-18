// In this document: Freaks - Centaur, Abomination, Horror

/// Mutation flare states for the "failed experiment" (abomhorror) - see the HORROR section below.
#define ABOM_FLARE_NORMAL 0
#define ABOM_FLARE_FERAL 1
#define ABOM_FLARE_RUPTURE 2

//////////////
// CENTAUR //
//////////////

// BASE CENTAUR - FEV mutation, ranged poison spitter
/mob/living/simple_animal/hostile/centaur
	affix_pool_type = "mutant"
	affix_chance = 5
	name = "centaur"
	desc = "The result of infection by FEV gone horribly wrong."
	icon = 'icons/mob/monsters/freaks.dmi'
	icon_state = "centaur"
	icon_living = "centaur"
	icon_dead = "centaur_dead"
	icon_gib = "centaur_g"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_CENTAUR
	
	maxHealth = 105 // bumped - TTK vs melee was too short
	health = 105
	speed = 2
	move_to_delay = 4  // Slower than average
	turns_per_move = 5
	
	melee_damage_lower = 4
	melee_damage_upper = 20
	harm_intent_damage = 8
	wound_bonus = 0
	
	aggro_vision_range = 7
	vision_range = 7
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/human/centaur = 3,
		/obj/item/stack/sheet/animalhide/human = 2,
		/obj/item/stack/sheet/bone = 2
	)
	
	footstep_type = FOOTSTEP_MOB_CRAWL
	tastes = list("sadness" = 1, "nastyness" = 1)
	
	speak_emote = list("growls")
	emote_see = list("screeches", "screams", "howls", "bellows", "flails", "fidgets", "festers")
	attack_verb_simple = list("whipped", "whacked", "whomped", "wailed on", "smacked", "smashed", "bapped")
	attack_sound = 'sound/f13npc/centaur/lash.ogg'
	
	emote_taunt = list("grunts", "gurgles", "wheezes", "flops", "scrabbles")
	emote_taunt_sound = list('sound/f13npc/centaur/taunt.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/centaur/aggro1.ogg')
	idlesound = list('sound/f13npc/centaur/idle1.ogg', 'sound/f13npc/centaur/idle2.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 20
	
	faction = list("hostile", "supermutant")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	sentience_type = SENTIENCE_BOSS
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Mixed combat - poison spit + melee
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1
	
	ranged_message = "spits poison"
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/f13npc/centaur/spit.ogg'

/mob/living/simple_animal/hostile/centaur/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/centaur/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - centaurs fight together
/mob/living/simple_animal/hostile/centaur/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/centaur))
		// Friendly fire from another centaur - take only 20% damage
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// NEUROTOXIN PROJECTILE
/obj/item/projectile/neurotox
	name = "poison spit"
	damage = 25
	icon_state = "toxin"

/obj/item/projectile/neurotox/on_hit(atom/target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.reagents.add_reagent(/datum/reagent/toxin, 3)

// STRONG CENTAUR - for FEV mutation event
/mob/living/simple_animal/hostile/centaur/strong
	maxHealth = 500 // bumped - TTK vs melee was too short
	health = 500
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 35
	melee_damage_upper = 35
	armour_penetration = 0.1
	damage_threshold_penetration_mob = 4
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS

// LARVAL CENTAUR - immature, weaker, no real spit
/mob/living/simple_animal/hostile/centaur/larval
	name = "larval centaur"
	desc = "A still-forming FEV mass that is mostly limbs and teeth. Smaller than the full-grown abominations, but no less angry."
	affix_chance = 2

	maxHealth = 55
	health = 55
	speed = 1.5
	move_to_delay = 3

	melee_damage_lower = 3
	melee_damage_upper = 10
	ranged_cooldown_time = 5 SECONDS

	sentience_type = SENTIENCE_ORGANIC
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/centaur/larval/Initialize()
	. = ..()
	resize = 0.75
	update_transform()

// FEV-PERFECTED CENTAUR - stabilized strain above the strong centaur
/mob/living/simple_animal/hostile/centaur/perfected
	name = "perfected centaur"
	desc = "A centaur where the FEV finally took hold cleanly. Corded muscle, steady hands, and a spit that burns."

	mob_armor = ARMOR_VALUE_CENTAUR_PERFECTED

	maxHealth = 650
	health = 650
	speed = 1.5
	move_to_delay = 3
	stat_attack = UNCONSCIOUS

	melee_damage_lower = 40
	melee_damage_upper = 40
	armour_penetration = 0.2
	damage_threshold_penetration_mob = 6
	ranged_cooldown_time = 2 SECONDS

	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/centaur/perfected/Initialize()
	. = ..()
	resize = 1.15
	update_transform()

// DOUG - friendly pet centaur
/mob/living/simple_animal/pet/dog/centaur
	name = "Doug"
	desc = "A docile centaur. Was brought here along with the warband. Isn't he adorable?"
	icon = 'icons/mob/monsters/freaks.dmi'
	icon_state = "centaur"
	icon_living = "centaur"
	icon_dead = "centaur_dead"
	icon_gib = "centaur_g"
	
	maxHealth = 200
	health = 200
	turns_per_move = 5
	
	speak_emote = list("growls")
	emote_see = list("screeches", "screams", "howls", "bellows", "flails", "fidgets", "festers")
	
	idlesound = list('sound/f13npc/centaur/idle1.ogg', 'sound/f13npc/centaur/idle2.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'
	
	response_help_simple = "pet"
	response_disarm_simple = "push"
	response_harm_simple = "punch"

/////////////////
// ABOMINATION //
/////////////////

// BASE ABOMINATION - FEV nightmare, wall smasher
/mob/living/simple_animal/hostile/abomination
	affix_pool_type = "mutant"
	affix_chance = 5
	name = "abomination"
	desc = "A horrible fusion of man, animal, and something entirely different. It quakes and shudders, looking to be in an immense amount of pain. Blood and other fluids oo ze from various gashes and lacerations on its body, punctuated by mouths that gnash and scream."
	icon = 'icons/mob/monsters/freaks.dmi'
	icon_state = "abomination"
	icon_living = "abomination"
	icon_dead = "abomination_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_ABOMINATION
	
	maxHealth = 1250 // bumped - TTK vs melee was too short
	health = 1250
	speed = -0.5  // Fast
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 30
	melee_damage_upper = 40
	harm_intent_damage = 8
	armour_penetration = 0.1
	damage_threshold_penetration_mob = 6
	
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	robust_searching = TRUE
	
	speak_emote = list("screams", "clicks", "chitters", "barks", "moans", "growls", "meows", "reverberates", "roars", "squeaks", "rattles", "exclaims", "yells", "remarks", "mumbles", "jabbers", "stutters", "seethes")
	attack_verb_simple = "eviscerates"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	death_sound = 'sound/voice/abomburning.ogg'
	deathmessage = "wails as its form shudders and violently comes to a stop."
	
	faction = list("hostile")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE  // Too ANGRY to despawn
	
	// METASTASIS - the "successful" FEV strain actually taking hold. Unlike a deathclaw's rage (which calms back
	// down once you break off), this is a one-way trip: cross the threshold once and it's permanent for the
	// rest of the fight. Hits harder and keeps slowly knitting itself back together, so stalling it out or
	// trying to outlast it just makes the problem worse - you need to finish it.
	low_health_threshold = 0.4
	var/metastasized = FALSE
	var/metastasize_regen_next = 0
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee - wall smashing tank
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	// Sound system
	var/static/list/abom_sounds

/mob/living/simple_animal/hostile/abomination/Initialize()
	. = ..()
	abom_sounds = list('sound/voice/abomination1.ogg', 'sound/voice/abomscream.ogg', 'sound/voice/abommoan.ogg', 'sound/voice/abomscream2.ogg', 'sound/voice/abomscream3.ogg')

/mob/living/simple_animal/hostile/abomination/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(12)

/mob/living/simple_animal/hostile/abomination/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/abomination/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		var/choice = pick(1, 1, 2, 2, 3, 4)
		H.reagents.add_reagent(/datum/reagent/toxin/FEV_solution, choice)

/mob/living/simple_animal/hostile/abomination/say(message, datum/language/language = null, list/spans = list(), sanitize, ignore_spam, forced = null, just_chat)
	. = ..()
	if(stat)
		return
	var/chosen_sound = pick(abom_sounds)
	playsound(src, chosen_sound, 50, TRUE)

/mob/living/simple_animal/hostile/abomination/Life()
	. = ..()
	if(stat)
		return
	if(prob(10))
		var/chosen_sound = pick(abom_sounds)
		playsound(src, chosen_sound, 70, TRUE)
	// Metastasis keeps slowly knitting it back together even mid-fight - stalling just buys it more regen.
	if(metastasized && health < maxHealth && world.time >= metastasize_regen_next)
		metastasize_regen_next = world.time + 4 SECONDS
		adjustBruteLoss(-(maxHealth * 0.015))

// One-way trip past the health threshold - the "successful" FEV strain finally takes hold for good.
/mob/living/simple_animal/hostile/abomination/make_low_health()
	..()
	if(metastasized)
		return
	metastasized = TRUE
	visible_message(span_danger("[src]'s wounds burst and writhe - the mutation is finally taking hold!"), span_userdanger("Something inside you finally gives way - and gives in."))
	if(length(abom_sounds))
		playsound(src, pick(abom_sounds), 100, TRUE)
	color = "#6b0000"  // deep bloody red - a visible, permanent tell that it's past the point of no return
	melee_damage_lower = round(initial(melee_damage_lower) * 1.3)
	melee_damage_upper = round(initial(melee_damage_upper) * 1.3)
	armour_penetration = initial(armour_penetration) + 0.15
	wound_bonus = initial(wound_bonus) + 15
	bare_wound_bonus = initial(bare_wound_bonus) + 15

// Metastasis does not reverse - once it takes hold, it's permanent for the rest of the fight.
/mob/living/simple_animal/hostile/abomination/make_high_health()
	return

// A last violent thrash as it dies, true to its deathmessage - don't let your guard down on the kill.
/mob/living/simple_animal/hostile/abomination/death(gibbed)
	visible_message(span_danger("[src] thrashes violently in its death throes!"))
	for(var/mob/living/L in range(1, src))
		if(L == src || L.stat == DEAD)
			continue
		L.apply_damage(8, TOX)
		L.Knockdown(10)
	return ..()

// WEAK ABOMINATION - for FEV mutation event
/mob/living/simple_animal/hostile/abomination/weak
	armour_penetration = 0
	damage_threshold_penetration_mob = 0
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES  // Can't break walls
	
	maxHealth = 625 // bumped - TTK vs melee was too short
	health = 625
	speed = 2  // Slower
	
	melee_damage_lower = 20
	melee_damage_upper = 30
	
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS

////////////
// HORROR //
////////////

// BASE HORROR - weaker FEV fusion, unstable instead of just a flat stat-stick
/mob/living/simple_animal/hostile/abomhorror
	armour_penetration = 0.15
	damage_threshold_penetration_mob = 6
	name = "failed experiment"
	desc = "A terrible fusion of man, animal, and something else entirely. It looks to be in great pain, its body twitching and spasming unpredictably."
	icon = 'icons/mob/monsters/freaks.dmi'
	icon_state = "horror"
	icon_living = "horror"
	icon_dead = "horror_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_HORROR
	
	// Rebalanced down from 875 - this was tankier than an alpha deathclaw (850 HP) despite being a regular,
	// non-unique spawn, not a boss. See player feedback: it was out-tanking content well above its weight class.
	maxHealth = 550
	health = 550
	speed = -0.5  // Fast
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 30
	melee_damage_upper = 40
	harm_intent_damage = 8
	
	robust_searching = TRUE
	
	speak_emote = list("screams", "clicks", "chitters", "barks", "moans", "growls", "meows", "reverberates", "roars", "squeaks", "rattles", "exclaims", "yells", "remarks", "mumbles", "jabbers", "stutters", "seethes")
	attack_verb_simple = "eviscerates"
	attack_sound = 'sound/weapons/punch1.ogg'
	deathmessage = "wails as its form shudders and violently comes to a stop."
	
	faction = list("hostile")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	var/static/list/abom_sounds
	
	// MUTATION FLARE - unlike the full abomination (stable until wounded, then unstoppable) or a deathclaw
	// (calm until low health), this thing's own failing biology is never stable: it flares unpredictably,
	// all fight long, between frenzied surges and bouts where its ruined hide can't hold together.
	var/flare_state = ABOM_FLARE_NORMAL
	var/flare_timer_id
	var/datum/armor/mob_armor_ruptured
	var/datum/armor/mob_armor_normal

/mob/living/simple_animal/hostile/abomhorror/Initialize(mapload)
	. = ..()
	// mob_armor is only a /datum/armor after the parent Initialize converts it, so both variants are built here
	mob_armor_normal = mob_armor
	mob_armor_ruptured = getArmor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 100, rad = 100, fire = 0, acid = 0, wound = 0, damage_threshold = 0)
	schedule_next_flare()

/mob/living/simple_animal/hostile/abomhorror/Destroy()
	deltimer(flare_timer_id)
	return ..()

/mob/living/simple_animal/hostile/abomhorror/proc/schedule_next_flare()
	flare_timer_id = addtimer(CALLBACK(src, PROC_REF(trigger_flare)), rand(8 SECONDS, 15 SECONDS), TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/abomhorror/proc/trigger_flare()
	if(QDELETED(src) || stat == DEAD)
		return
	// Nothing to flare for - check back later instead of wasting the show on an empty room
	if(!target || flare_state != ABOM_FLARE_NORMAL)
		schedule_next_flare()
		return
	if(prob(50))
		start_feral_surge()
	else
		start_rupture()

/// Danger window - its muscles lock up with adrenaline. Hits much harder and faster for a few seconds.
/mob/living/simple_animal/hostile/abomhorror/proc/start_feral_surge()
	flare_state = ABOM_FLARE_FERAL
	color = "#ff9933"
	visible_message(span_danger("[src]'s muscles bulge and spasm - it's surging with feral strength!"), span_userdanger("Your muscles bulge and burn with sudden, unnatural strength!"))
	playsound(src, pick('sound/voice/abomscream.ogg', 'sound/voice/abomscream2.ogg', 'sound/voice/abomscream3.ogg'), 100, TRUE)
	melee_damage_lower = round(initial(melee_damage_lower) * 1.4)
	melee_damage_upper = round(initial(melee_damage_upper) * 1.4)
	armour_penetration = initial(armour_penetration) + 0.15
	speed = initial(speed) - 0.5
	addtimer(CALLBACK(src, PROC_REF(end_flare)), 4 SECONDS)

/// Opportunity window - its failing body can't hold its shape together. Hits softer, but is wide open.
/mob/living/simple_animal/hostile/abomhorror/proc/start_rupture()
	flare_state = ABOM_FLARE_RUPTURE
	color = "#88ffdd"
	visible_message(span_warning("[src]'s hide splits and ruptures - its failing body is exposed!"), span_warning("Your hide splits open - you're exposed!"))
	playsound(src, pick('sound/voice/abommoan.ogg', 'sound/voice/abomination1.ogg'), 100, TRUE)
	mob_armor = mob_armor_ruptured
	melee_damage_lower = round(initial(melee_damage_lower) * 0.7)
	melee_damage_upper = round(initial(melee_damage_upper) * 0.7)
	addtimer(CALLBACK(src, PROC_REF(end_flare)), 5 SECONDS)

/mob/living/simple_animal/hostile/abomhorror/proc/end_flare()
	if(QDELETED(src) || stat == DEAD)
		return
	color = initial(color)
	mob_armor = mob_armor_normal
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	armour_penetration = initial(armour_penetration)
	speed = initial(speed)
	flare_state = ABOM_FLARE_NORMAL
	if(stat != DEAD)
		schedule_next_flare()

/mob/living/simple_animal/hostile/abomhorror/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/abomhorror/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// A diluted, failed dose compared to the full abomination's - still a mutation risk, just a smaller one.
/mob/living/simple_animal/hostile/abomhorror/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/FEV_solution, 1)

// True to its deathmessage - a last violent thrash as it dies.
/mob/living/simple_animal/hostile/abomhorror/death(gibbed)
	visible_message(span_danger("[src] convulses violently in its death throes!"))
	for(var/mob/living/L in range(1, src))
		if(L == src || L.stat == DEAD)
			continue
		L.apply_damage(5, TOX)
		L.Knockdown(10)
	return ..()

// NSB HORROR - bunker variant, elite but no longer a mother-deathclaw-tier bulletsponge
/mob/living/simple_animal/hostile/abomhorror/nsb
	armour_penetration = 0.2
	damage_threshold_penetration_mob = 8
	desc = "A terrible fusion of man, animal, and something else entirely. It looks to be in great pain, constantly shuddering violently and seeming relatively docile to the robots and raiders of the bunker. Huh."
	
	// Rebalanced down from 1000 - that matched Mother Deathclaw's HP on a mob that appears as a repeatable
	// dungeon elite across multiple maps, not a unique boss encounter.
	maxHealth = 700
	health = 700
	speed = -1  // Even faster
	
	melee_damage_lower = 40
	melee_damage_upper = 50
	obj_damage = 300
	wound_bonus = 20
	
	// Sharing the raiders' faction keeps them from shooting it on sight (it "seems docile" to them), but unlike
	// the bunker's reprogrammed robots it isn't actually loyal to anyone - attack_same lets it turn on them too.
	faction = list("raider")
	attack_same = TRUE
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE

/mob/living/simple_animal/hostile/abomhorror/nsb/Initialize()
	. = ..()
	abom_sounds = list('sound/voice/abomination1.ogg', 'sound/voice/abomscream.ogg', 'sound/voice/abommoan.ogg', 'sound/voice/abomscream2.ogg', 'sound/voice/abomscream3.ogg')

/mob/living/simple_animal/hostile/abomhorror/nsb/CanAttack(atom/the_target)
	// attack_same exists so it can turn on raiders and robots, not so the bunker's horrors maul each other
	if(istype(the_target, /mob/living/simple_animal/hostile/abomhorror))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abomhorror/nsb/say(message, datum/language/language = null, list/spans = list(), sanitize, ignore_spam, forced = null, just_chat)
	. = ..()
	if(stat)
		return
	var/chosen_sound = pick(abom_sounds)
	playsound(src, chosen_sound, 50, TRUE)

/mob/living/simple_animal/hostile/abomhorror/nsb/Life()
	. = ..()
	if(stat)
		return
	if(prob(10))
		var/chosen_sound = pick(abom_sounds)
		playsound(src, chosen_sound, 70, TRUE)

// In this document: Freaks - Centaur, Abomination, Horror

//////////////
// CENTAUR //
//////////////

// BASE CENTAUR - FEV mutation, ranged poison spitter
/mob/living/simple_animal/hostile/centaur
	name = "centaur"
	desc = "The result of infection by FEV gone horribly wrong."
	icon = 'icons/fallout/mobs/monsters/freaks.dmi'
	icon_state = "centaur"
	icon_living = "centaur"
	icon_dead = "centaur_dead"
	icon_gib = "centaur_g"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_CENTAUR
	
	maxHealth = 80
	health = 80
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
	maxHealth = 400
	health = 400
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 35
	melee_damage_upper = 35
	armour_penetration = 0.1
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS

// DOUG - friendly pet centaur
/mob/living/simple_animal/pet/dog/centaur
	name = "Doug"
	desc = "A docile centaur. Was brought here along with the warband. Isn't he adorable?"
	icon = 'icons/fallout/mobs/monsters/freaks.dmi'
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
	name = "abomination"
	desc = "A horrible fusion of man, animal, and something entirely different. It quakes and shudders, looking to be in an immense amount of pain. Blood and other fluids oo ze from various gashes and lacerations on its body, punctuated by mouths that gnash and scream."
	icon = 'icons/fallout/mobs/monsters/freaks.dmi'
	icon_state = "abomination"
	icon_living = "abomination"
	icon_dead = "abomination_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_ABOMINATION
	
	maxHealth = 1000
	health = 1000
	speed = -0.5  // Fast
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 30
	melee_damage_upper = 40
	harm_intent_damage = 8
	armour_penetration = 0.1
	
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

// WEAK ABOMINATION - for FEV mutation event
/mob/living/simple_animal/hostile/abomination/weak
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES  // Can't break walls
	
	maxHealth = 500
	health = 500
	speed = 2  // Slower
	
	melee_damage_lower = 20
	melee_damage_upper = 30
	
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS

////////////
// HORROR //
////////////

// BASE HORROR - weaker FEV fusion
/mob/living/simple_animal/hostile/abomhorror
	name = "failed experiment"
	desc = "A terrible fusion of man, animal, and something else entirely. It looks to be in great pain."
	icon = 'icons/fallout/mobs/monsters/freaks.dmi'
	icon_state = "horror"
	icon_living = "horror"
	icon_dead = "horror_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_HORROR
	
	maxHealth = 700
	health = 700
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

// NSB HORROR - bunker variant, bulletsponge
/mob/living/simple_animal/hostile/abomhorror/nsb
	desc = "A terrible fusion of man, animal, and something else entirely. It looks to be in great pain, constantly shuddering violently and seeming relatively docile to the robots and raiders of the bunker. Huh."
	
	maxHealth = 1000
	health = 1000
	speed = -1  // Even faster
	
	melee_damage_lower = 40
	melee_damage_upper = 50
	obj_damage = 300
	wound_bonus = 20
	
	faction = list("raider")
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE

/mob/living/simple_animal/hostile/abomhorror/nsb/Initialize()
	. = ..()
	abom_sounds = list('sound/voice/abomination1.ogg', 'sound/voice/abomscream.ogg', 'sound/voice/abommoan.ogg', 'sound/voice/abomscream2.ogg', 'sound/voice/abomscream3.ogg')

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

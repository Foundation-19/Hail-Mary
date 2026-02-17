///////////
// GECKO //
///////////

// BASE GECKO - all shared properties
/mob/living/simple_animal/hostile/gecko
	name = "gecko"
	desc = "A large mutated reptile with sharp teeth."
	icon = 'icons/fallout/mobs/animals/wasteanimals.dmi'
	icon_state = "gekko"
	icon_living = "gekko"
	icon_dead = "gekko_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 35
	health = 35
	speed = 0
	move_to_delay = 2.5
	turns_per_move = 5
	
	melee_damage_lower = 4
	melee_damage_upper = 12
	harm_intent_damage = 8
	obj_damage = 20
	
	aggro_vision_range = 7
	vision_range = 8
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/gecko = 2,
		/obj/item/stack/sheet/animalhide/gecko = 1,
		/obj/item/stack/sheet/bone = 1
	)
	butcher_difficulty = 1
	
	waddle_amount = 3
	waddle_up_time = 1
	waddle_side_time = 2
	pass_flags = PASSTABLE
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("squeaks", "cackles", "snickers", "shrieks", "screams", "warbles", "chirps", "cries", "kyaas", "chortles", "gecks")
	emote_see = list("screeches", "licks its eyes", "twitches", "scratches its frills", "gonks", "honks", "sniffs", "gecks")
	attack_verb_simple = list("bites", "claws", "tears at", "scratches", "gnaws", "chews", "chomps", "lunges", "gecks")
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("gecko", "critter-friend")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW
	
	emote_taunt = list("screeches")
	emote_taunt_sound = list('sound/f13npc/gecko/gecko_charge1.ogg', 'sound/f13npc/gecko/gecko_charge2.ogg', 'sound/f13npc/gecko/gecko_charge3.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/gecko/gecko_alert.ogg')
	idlesound = list('sound/f13npc/gecko/geckocall1.ogg', 'sound/f13npc/gecko/geckocall2.ogg', 'sound/f13npc/gecko/geckocall3.ogg', 'sound/f13npc/gecko/geckocall4.ogg', 'sound/f13npc/gecko/geckocall5.ogg')
	death_sound = 'sound/f13npc/gecko/gecko_death.ogg'
	
	can_ghost_into = TRUE
	desc_short = "Short, angry, and as confused as they are tasty."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 40

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	variation_list = list(
		MOB_COLOR_VARIATION(50, 50, 50, 255, 255, 255),
		MOB_SPEED_LIST(1.5, 1.8, 2.0, 2.2, 2.6, 3.0, 3.3, 3.7),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(50),
		MOB_HEALTH_LIST(30, 35, 40, 45),
	)

/mob/living/simple_animal/hostile/gecko/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/gecko/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/gecko/become_the_mob(mob/user)
	make_a_nest = /obj/effect/proc_holder/mob_common/make_nest/gecko
	call_backup = /obj/effect/proc_holder/mob_common/summon_backup/small_critter
	send_mobs = /obj/effect/proc_holder/mob_common/direct_mobs/small_critter
	. = ..()

// FIRE GECKO - ranged variant that spits fire
/mob/living/simple_animal/hostile/gecko/fire
	name = "fire gecko"
	desc = "A large mutated reptile with sharp teeth and a warm disposition. Sorta smells like sulphur."
	
	maxHealth = 30
	health = 30
	
	// Mixed combat - fire spit + melee
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1
	
	check_friendly_fire = TRUE
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/item/projectile/geckofire
	projectilesound = 'sound/magic/fireball.ogg'
	ranged_message = "spits fire"
	
	variation_list = list(
		MOB_COLOR_VARIATION(200, 40, 40, 255, 45, 45),
		MOB_SPEED_LIST(2.6, 3.0, 3.3, 3.7),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(50),
		MOB_HEALTH_LIST(28, 30, 32),
	)

/mob/living/simple_animal/hostile/gecko/fire/Initialize()
	. = ..()
	resize = 0.8
	update_transform()

// LEGACY GECKO (NEWT) - smaller, faster, aggressive
/mob/living/simple_animal/hostile/gecko/legacy
	name = "newt"
	desc = "A large dog-sized amphibious biped with an oddly large mouth for its size. Probably related to geckos in some way."
	icon = 'icons/fallout/mobs/legacymobs.dmi'
	icon_state = "legacy_gecko"
	icon_living = "legacy_gecko"
	icon_dead = "legacy_gecko_dead"
	
	sidestep_per_cycle = 2
	dodging = TRUE
	
	melee_damage_lower = 7
	melee_damage_upper = 18
	
	waddle_amount = 5
	sound_pitch = 70
	vary_pitches = list(40, 80)

// ALPHA NEWT - stronger variant with stamina damage
/mob/living/simple_animal/hostile/gecko/legacy/alpha
	name = "alpha newt"
	desc = "A large dog-sized amphibious biped with an oddly large mouth for its size. This one's drooling a lot and looks sort of tired."
	icon_state = "legacy_gecko2"
	icon_living = "legacy_gecko2"
	
	vision_range = 9
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/gecko = 3,
		/obj/item/stack/sheet/animalhide/gecko = 1,
		/obj/item/stack/sheet/bone = 1
	)
	
	variation_list = list(
		MOB_COLOR_VARIATION(180, 255, 255, 255, 255, 255),
		MOB_SPEED_LIST(1.8, 2.0, 2.2),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(80),
		MOB_HEALTH_LIST(30, 35, 40),
	)

/mob/living/simple_animal/hostile/gecko/legacy/alpha/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/staminatoxin, 1)

// BIG GECKO - slow, heavy hitter, poor vision
/mob/living/simple_animal/hostile/gecko/big
	name = "big gecko"
	desc = "A large mutated reptile with sharp teeth. This one's pretty big, but its eyes seem clouded and it moves a bit clumsily."
	
	maxHealth = 110
	health = 110
	
	melee_damage_lower = 12
	melee_damage_upper = 24
	
	aggro_vision_range = 4
	vision_range = 4
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/gecko = 6,
		/obj/item/stack/sheet/animalhide/gecko = 2,
		/obj/item/stack/sheet/bone = 2
	)
	
	footstep_type = FOOTSTEP_MOB_HEAVY
	sound_pitch = -75
	vary_pitches = list(-100, -80)
	
	variation_list = list(
		MOB_COLOR_VARIATION(120, 80, 80, 250, 100, 100),
		MOB_SPEED_LIST(2.5, 2.8, 3.0),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(80),
		MOB_HEALTH_LIST(100, 110, 120),
	)

/mob/living/simple_animal/hostile/gecko/big/Initialize()
	. = ..()
	resize = 1.5
	update_transform()

// PLAYABLE GECKO - for ghost roles
/mob/living/simple_animal/hostile/gecko/playable
	maxHealth = 40
	health = 40
	melee_damage_lower = 8
	melee_damage_upper = 12
	
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = 0

// DEBUG GECKOS - for testing
/mob/living/simple_animal/hostile/gecko/debug
	sound_pitch = 100
	vary_pitches = list(-200, 200)
	variation_list = list(
		"varied_global_names" = list(
			MOB_RANDOM_NAME(MOB_NAME_RANDOM_MALE, 2),
			MOB_RANDOM_NAME(MOB_NAME_RANDOM_LIZARD_FEMALE, 1),
			MOB_RANDOM_NAME(MOB_NAME_RANDOM_ALL_OF_THEM, 5)
		),
		MOB_COLOR_VARIATION(20, 190, 0, 255, 2, 0),
		MOB_SPEED_LIST(1.5, 1.8, 2.0, 2.2, 2.6, 3.0, 3.3, 3.7),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(100),
		MOB_HEALTH_LIST(2, 3, 5, 7, 30, 35, 37, 38, 40, 45, 48, 49, 2000),
	)

/mob/living/simple_animal/hostile/gecko/debug/stamcrit
	variation_list = list(
		MOB_NAME_FROM_GLOBAL_LIST(MOB_RANDOM_NAME(MOB_NAME_RANDOM_LIZARD_FEMALE, 1)),
		MOB_HEALTH_LIST(50),
	)

/mob/living/simple_animal/hostile/gecko/debug/stamcrit/Initialize()
	. = ..()
	new /obj/item/gun/energy/disabler/debug(get_turf(src))

// GECKO FIRE PROJECTILE
/obj/item/projectile/geckofire
	name = "flaming gecko spit"
	icon = 'icons/effects/fire.dmi'
	icon_state = "3"
	range = 4
	light_range = LIGHT_RANGE_FIRE
	light_color = LIGHT_COLOR_FIRE
	
	damage = BULLET_DAMAGE_SHOTGUN_PELLET * BULLET_DAMAGE_FIRE
	stamina = BULLET_STAMINA_SHOTGUN_PELLET * BULLET_STAMINA_FIRE
	spread = BULLET_SPREAD_SURPLUS
	recoil = BULLET_RECOIL_SHOTGUN_PELLET
	wound_bonus = BULLET_WOUND_SHOTGUN_PELLET * BULLET_WOUND_FIRE
	bare_wound_bonus = BULLET_WOUND_SHOTGUN_PELLET_NAKED_MULT * BULLET_NAKED_WOUND_FIRE
	wound_falloff_tile = BULLET_WOUND_FALLOFF_PISTOL_LIGHT
	pixels_per_second = BULLET_SPEED_SHOTGUN_PELLET * 0.35
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_LIGHT
	sharpness = SHARP_NONE
	zone_accuracy_type = ZONE_WEIGHT_SHOTGUN

/obj/item/projectile/geckofire/on_hit(atom/target)
	. = ..()
	if(prob(1))
		name = "flaming gecko yartz"
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(2)
		if(M.fire_stacks > 2)
			M.IgniteMob()

//////////////////////////
// NIGHTSTALKERS & PELT //
//////////////////////////

// BASE NIGHTSTALKER
/mob/living/simple_animal/hostile/stalker
	name = "nightstalker"
	desc = "A crazed genetic hybrid of rattlesnake and coyote DNA."
	icon = 'icons/fallout/mobs/animals/nightstalker.dmi'
	icon_state = "nightstalker"
	icon_living = "nightstalker"
	icon_dead = "nightstalker-dead"
	icon_gib = null
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 80
	health = 80
	speed = 1
	move_to_delay = 2.5
	turns_per_move = 5
	
	melee_damage_lower = 4
	melee_damage_upper = 12
	harm_intent_damage = 8
	obj_damage = 15
	
	aggro_vision_range = 7
	vision_range = 8
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/nightstalker_meat = 2,
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/stack/sheet/bone = 2
	)
	butcher_results = list(
		/obj/item/clothing/head/f13/stalkerpelt = 1,
		/obj/item/reagent_containers/food/snacks/meat/slab/nightstalker_meat = 1
	)
	butcher_difficulty = 3
	
	waddle_amount = 3
	waddle_up_time = 1
	waddle_side_time = 1
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "bites"
	
	speak_emote = list("growls")
	attack_verb_simple = "bites"
	attack_sound = 'sound/creatures/nightstalker_bite.ogg'
	
	emote_taunt = list("growls")
	emote_taunt_sound = list('sound/f13npc/nightstalker/taunt1.ogg', 'sound/f13npc/nightstalker/taunt2.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/nightstalker/aggro1.ogg', 'sound/f13npc/nightstalker/aggro2.ogg', 'sound/f13npc/nightstalker/aggro3.ogg')
	idlesound = list('sound/f13npc/nightstalker/idle1.ogg')
	death_sound = 'sound/f13npc/nightstalker/death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("nightstalkers")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 40

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee - venomous bite
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/stalker/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/stalker/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/stalker/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/cazador_venom, 6)

// PLAYABLE NIGHTSTALKER
/mob/living/simple_animal/hostile/stalker/playable
	maxHealth = 80
	health = 80
	melee_damage_lower = 10
	melee_damage_upper = 15
	
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = 0

/mob/living/simple_animal/hostile/stalker/playable/legion
	name = "legionstalker"
	desc = "A nightstalker bred specifically for the legion for combat and companionship. Legionstalkers have the body and loyalty of a canine but the agility and deadliness of a rattlesnake."
	icon_state = "nightstalker-legion"
	icon_living = "nightstalker-legion"
	icon_dead = "nightstalker-legion-dead"

// NIGHTSTALKER CUB
/mob/living/simple_animal/hostile/stalkeryoung
	name = "young nightstalker"
	desc = "A juvenile crazed genetic hybrid of rattlesnake and coyote DNA."
	icon = 'icons/fallout/mobs/animals/wasteanimals.dmi'
	icon_state = "nightstalker_cub"
	icon_living = "nightstalker_cub"
	icon_dead = "nightstalker_cub_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 50
	health = 50
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	harm_intent_damage = 8
	obj_damage = 15
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/nightstalker_meat = 2,
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/stack/sheet/bone = 1
	)
	butcher_results = list(
		/obj/item/clothing/head/f13/stalkerpelt = 1,
		/obj/item/reagent_containers/food/snacks/meat/slab/nightstalker_meat = 1
	)
	
	waddle_amount = 4
	waddle_up_time = 1
	waddle_side_time = 2
	
	response_help_simple = "pets"
	response_disarm_simple = "pushes aside"
	response_harm_simple = "kicks"
	
	speak_emote = list("howls")
	attack_verb_simple = "bites"
	attack_sound = 'sound/f13npc/nightstalker/attack1.ogg'
	
	emote_taunt = list("growls", "snarls")
	emote_taunt_sound = list('sound/f13npc/nightstalker/taunt1.ogg', 'sound/f13npc/nightstalker/taunt2.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/nightstalker/aggro1.ogg', 'sound/f13npc/nightstalker/aggro2.ogg', 'sound/f13npc/nightstalker/aggro3.ogg')
	idlesound = list('sound/f13npc/nightstalker/idle1.ogg')
	death_sound = 'sound/f13npc/nightstalker/death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("nightstalkers", "critter-friend")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Pure melee - runs away and calls for help
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/stalkeryoung/Aggro()
	..()
	summon_backup(12)

/mob/living/simple_animal/hostile/stalkeryoung/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/cazador_venom, 2)

/mob/living/simple_animal/hostile/stalkeryoung/playable
	maxHealth = 80
	health = 80
	melee_damage_lower = 5
	melee_damage_upper = 10
	
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = 0

// NIGHTSTALKER ITEMS
/obj/item/clothing/head/f13/stalkerpelt
	name = "nightstalker pelt"
	desc = "A hat made from nightstalker pelt which makes the wearer feel both comfortable and elegant."
	icon_state = "stalkerpelt"
	item_state = "stalkerpelt"

/obj/structure/stalkeregg
	name = "nightstalker egg"
	desc = "A shiny egg coming from a nightstalker."
	icon = 'icons/mob/wastemobsdrops.dmi'
	icon_state = "stalker-egg"
	density = 1
	anchored = 0

/obj/item/reagent_containers/food/snacks/meat/slab/nightstalker_meat
	name = "nightstalker meat"
	desc = "Could taste like rich red meat or flavorful chicken, depending on where the cut comes from."
	list_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	bitesize = 4
	filling_color = "#FA8072"
	tastes = list("rich meat" = 3)
	cooked_type = /obj/item/reagent_containers/food/snacks/meat/steak/nightstalker_meat
	foodtype = RAW | MEAT

/obj/item/reagent_containers/food/snacks/meat/steak/nightstalker_meat
	name = "nightstalker steak"
	desc = "A surprisingly high quality steak that could come in a variety of textures and may taste of either good chicken or rich beef."

/////////////
// MOLERAT //
/////////////

/mob/living/simple_animal/hostile/molerat
	name = "molerat"
	desc = "A large mutated rat-mole hybrid that finds its way everywhere. Common in caves and underground areas."
	icon = 'icons/fallout/mobs/animals/wasteanimals.dmi'
	icon_state = "molerat"
	icon_living = "molerat"
	icon_dead = "molerat_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 25
	health = 25
	speed = 2
	turns_per_move = 5
	
	melee_damage_lower = 4
	melee_damage_upper = 10
	harm_intent_damage = 8
	obj_damage = 15
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/molerat = 2,
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/stack/sheet/animalhide/molerat = 1,
		/obj/item/stack/sheet/bone = 1
	)
	butcher_difficulty = 1.5
	
	waddle_amount = 3
	waddle_up_time = 1
	waddle_side_time = 2
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("chitters")
	attack_verb_simple = "bites"
	attack_sound = 'sound/creatures/molerat_attack.ogg'
	
	emote_taunt = list("hisses")
	emote_taunt_sound = list('sound/f13npc/molerat/taunt.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/molerat/aggro1.ogg', 'sound/f13npc/molerat/aggro2.ogg')
	idlesound = list('sound/f13npc/molerat/idle.ogg')
	death_sound = 'sound/f13npc/molerat/death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("hostile", "gecko")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	desc_short = "Small, squishy, and numerous."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 40

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	variation_list = list(
		MOB_COLOR_VARIATION(50, 50, 50, 255, 255, 255),
		MOB_SPEED_LIST(2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(5),
		MOB_HEALTH_LIST(15, 20, 25, 26),
	)

/mob/living/simple_animal/hostile/molerat/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/molerat/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/molerat/become_the_mob(mob/user)
	call_backup = /obj/effect/proc_holder/mob_common/summon_backup/small_critter
	send_mobs = /obj/effect/proc_holder/mob_common/direct_mobs/small_critter
	make_a_nest = /obj/effect/proc_holder/mob_common/make_nest/molerat
	. = ..()

//////////////////
// GELATIN CUBE //
//////////////////

/mob/living/simple_animal/hostile/gelcube
	name = "gelatinous cube"
	desc = "A big green radioactive cube creature. It jiggles with menacing wiggles and is making some sort of goofy face at you."
	icon = 'fallout/icons/mob/vatgrowing.dmi'
	icon_state = "gelatinous"
	icon_living = "gelatinous"
	icon_dead = "gelatinous_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 850
	health = 850
	speed = 8
	move_to_delay = 6
	turns_per_move = 10
	
	melee_damage_lower = 35
	melee_damage_upper = 45
	harm_intent_damage = 30
	obj_damage = 15
	
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/soup/amanitajelly = 2)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/soup/amanitajelly = 1)
	butcher_difficulty = 1.5
	
	loot = list(/obj/item/stack/f13Cash/random/med)
	loot_drop_amount = 10
	loot_amount_random = TRUE
	var/random_trash_loot = TRUE
	
	waddle_amount = 4
	waddle_up_time = 3
	waddle_side_time = 2
	
	response_help_simple = "jiggles"
	response_disarm_simple = "wiggles"
	response_harm_simple = "shakes"
	
	speak_emote = list("glorbles")
	attack_verb_simple = "goops"
	attack_sound = 'sound/effects/attackblob.ogg'
	
	emote_taunt = list("blorgles")
	emote_taunt_sound = list('sound/effects/bubbles.ogg')
	taunt_chance = 30
	aggrosound = list('sound/misc/splort.ogg')
	idlesound = list('sound/vore/prey/squish_01.ogg')
	death_sound = 'sound/misc/crack.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("the tungsten cube")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	desc_short = "Big, squishy, and gelatinous."
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 80  // Very slow

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/gelcube/Initialize()
	. = ..()
	if(random_trash_loot)
		loot = GLOB.trash_ammo + GLOB.trash_chem + GLOB.trash_clothing + GLOB.trash_craft + GLOB.trash_gun + GLOB.trash_misc + GLOB.trash_money + GLOB.trash_mob + GLOB.trash_part + GLOB.trash_tool + GLOB.trash_attachment

/mob/living/simple_animal/hostile/gelcube/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/gelcube/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

////////////
// T-BIRD //
////////////

/mob/living/simple_animal/hostile/bloodbird
	name = "blood bird"
	desc = "A large mutated turkey vulture."
	icon = 'icons/fallout/mobs/animals/bloodbird.dmi'
	icon_state = "bloodbird"
	icon_living = "bloodbird"
	icon_dead = "bloodbird_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 100
	health = 100
	speed = 0
	move_to_delay = 2.5
	turns_per_move = 5
	
	melee_damage_lower = 25
	melee_damage_upper = 35
	harm_intent_damage = 8
	obj_damage = 20
	
	aggro_vision_range = 9
	vision_range = 8
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/chicken = 4,
		/obj/item/feather = 3,
		/obj/item/stack/sheet/bone = 2
	)
	butcher_difficulty = 1
	
	waddle_amount = 5
	waddle_up_time = 1
	waddle_side_time = 1
	pass_flags = PASSTABLE
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("cackles", "squawks", "clacks")
	emote_see = list("screeches", "gonks")
	attack_verb_simple = list("bites", "claws", "rends", "mutilates")
	
	emote_taunt = list("screeches")
	emote_taunt_sound = list('sound/creatures/terrorbird/hoot1.ogg', 'sound/creatures/terrorbird/hoot2.ogg', 'sound/creatures/terrorbird/hoot3.ogg', 'sound/creatures/terrorbird/hoot4.ogg')
	taunt_chance = 30
	aggrosound = list('sound/creatures/terrorbird/growl1.ogg', 'sound/creatures/terrorbird/growl2.ogg', 'sound/creatures/terrorbird/growl3.ogg')
	idlesound = list('sound/creatures/terrorbird/clack1.ogg', 'sound/creatures/terrorbird/clack2.ogg', 'sound/creatures/terrorbird/clack3.ogg')
	death_sound = list('sound/creatures/terrorbird/groan1.ogg', 'sound/creatures/terrorbird/groan2.ogg')
	
	faction = list("terror bird")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	footstep_type = FOOTSTEP_MOB_HEAVY
	
	can_ghost_into = FALSE
	desc_short = "What a terrifying bird."
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30  // Faster

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	variation_list = list(
		MOB_COLOR_VARIATION(50, 50, 50, 255, 255, 255),
		MOB_SPEED_LIST(1.5, 1.8, 2.0, 2.2),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(50),
		MOB_HEALTH_LIST(80, 90, 100, 110),
	)

/mob/living/simple_animal/hostile/bloodbird/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/bloodbird/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

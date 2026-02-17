// INSECTS - In this document: Giant ant, Radscorpion, Cazador, Radroach, Bloatfly, cazador venom

///////////////
// GIANT ANT //
///////////////

// BASE GIANT ANT
/mob/living/simple_animal/hostile/giantant
	name = "giant ant"
	desc = "A giant ant with twitching, darting antennae. Its outsides are a mixture of crusted, unrotting rock and chitin that bounce off bullets and melee weapons. Hardened insides compact once valueless sand and dirt to gemstones. Can be butchered down the thorax for minerals and shinies."
	icon = 'icons/fallout/mobs/animals/insects.dmi'
	icon_state = "GiantAnt"
	icon_living = "GiantAnt"
	icon_dead = "GiantAnt_dead"
	icon_gib = "GiantAnt_gib"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_ANTS
	
	maxHealth = 110
	health = 110
	speed = 1
	move_to_delay = 3
	turns_per_move = 5
	
	melee_damage_lower = 6
	melee_damage_upper = 20
	harm_intent_damage = 8
	obj_damage = 20
	
	aggro_vision_range = 4  // Poor eyesight
	vision_range = 5
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/reagent_containers/food/snacks/meat/slab/ant_meat = 2,
		/obj/item/stack/sheet/animalhide/chitin = 1,
		/obj/item/stack/sheet/bone = 1
	)
	butcher_difficulty = 1.5
	
	waddle_amount = 2
	waddle_up_time = 1
	waddle_side_time = 1
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("skitters", "clacks", "chitters", "snips", "snaps")
	emote_see = list("waggles its antenna", "clicks its mandibles", "picks up your scent", "goes on the hunt")
	attack_verb_simple = list("rips", "tears", "stings")
	attack_sound = 'sound/creatures/radroach_attack.ogg'
	
	emote_taunt = list("chitters")
	emote_taunt_sound = 'sound/creatures/radroach_chitter.ogg'
	taunt_chance = 30
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("ant")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	blood_volume = 0
	decompose = FALSE
	tastes = list("dirt" = 1, "sand" = 1, "metal?" = 1)
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 40

	// Can open doors
	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/giantant/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/giantant/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// FIRE ANT - applies burning reagent
/mob/living/simple_animal/hostile/fireant
	name = "fire ant"
	desc = "A large reddish ant. The furnace it holds inside itself blasts intruders and the dirt it chews with flaming heat. Its insides contain more gemstones than its unremarkable kin."
	icon = 'icons/fallout/mobs/animals/insects.dmi'
	icon_state = "FireAnt"
	icon_living = "FireAnt"
	icon_dead = "FireAnt_dead"
	icon_gib = "FireAnt_gib"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_ANTS
	
	maxHealth = 90
	health = 90
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 8
	melee_damage_upper = 16
	harm_intent_damage = 8
	obj_damage = 20
	
	aggro_vision_range = 4
	vision_range = 5
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/reagent_containers/food/snacks/meat/slab/fireant_meat = 2,
		/obj/item/reagent_containers/food/snacks/rawantbrain = 1,
		/obj/item/stack/sheet/animalhide/chitin = 2,
		/obj/item/stack/sheet/bone = 1
	)
	butcher_difficulty = 1.5
	
	waddle_amount = 2
	waddle_up_time = 1
	waddle_side_time = 1
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("skitters")
	attack_verb_simple = "stings"
	attack_sound = 'sound/creatures/radroach_attack.ogg'
	
	emote_taunt = list("chitters")
	emote_taunt_sound = 'sound/creatures/radroach_chitter.ogg'
	taunt_chance = 30
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("ant")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	decompose = FALSE
	blood_volume = 0
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 40

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/fireant/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/fireant/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/fireant/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/hellwater, 1)

// ANT QUEEN - boss variant, spawns ants
/mob/living/simple_animal/hostile/giantantqueen
	name = "giant ant queen"
	desc = "The queen of a giant ant colony. Butchering it seems like a good way to make a pretty penny."
	icon = 'icons/fallout/mobs/animals/antqueen.dmi'
	icon_state = "antqueen"
	icon_living = "antqueen"
	icon_dead = "antqueen_dead"
	icon_gib = "GiantAnt_gib"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_ANTS_QUEEN
	
	maxHealth = 350  // Reduced from 560
	health = 350
	speed = 5  // Slow
	turns_per_move = 5
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 15
	melee_damage_upper = 25  // Increased from 15
	harm_intent_damage = 8
	obj_damage = 20
	
	aggro_vision_range = 5
	vision_range = 6
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/sinew = 3,
		/obj/item/reagent_containers/food/snacks/meat/slab/ant_meat = 6,
		/obj/item/stack/sheet/animalhide/chitin = 8,
		/obj/item/reagent_containers/food/snacks/rawantbrain = 1,
		/obj/item/stack/sheet/bone = 3
	)
	butcher_difficulty = 1.5
	
	loot = list(/obj/item/reagent_containers/food/snacks/f13/giantantegg = 10)
	loot_drop_amount = 10
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("skitters")
	attack_verb_simple = "stings"
	attack_sound = 'sound/creatures/radroach_attack.ogg'
	
	emote_taunt = list("chitters")
	emote_taunt_sound = 'sound/creatures/radroach_chitter.ogg'
	taunt_chance = 30
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("ant")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	decompose = FALSE
	blood_volume = 0
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 60

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Mixed combat - bile spit + melee
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_message = "spits bile"
	ranged_cooldown_time = 4 SECONDS
	projectiletype = /obj/item/projectile/bile
	projectilesound = 'sound/f13npc/centaur/spit.ogg'
	extra_projectiles = 2
	
	// Spawner vars
	var/max_mobs = 2
	var/mob_types = list(/mob/living/simple_animal/hostile/giantant)
	var/spawn_time = 30 SECONDS
	var/spawn_text = "hatches from"

/mob/living/simple_animal/hostile/giantantqueen/Initialize()
	. = ..()
	AddComponent(/datum/component/spawner, mob_types, spawn_time, faction, spawn_text, max_mobs, _range = 7)
	resize = 1.2
	update_transform()

/mob/living/simple_animal/hostile/giantantqueen/death()
	RemoveComponentByType(/datum/component/spawner)
	. = ..()

/mob/living/simple_animal/hostile/giantantqueen/Destroy()
	RemoveComponentByType(/datum/component/spawner)
	. = ..()

/mob/living/simple_animal/hostile/giantantqueen/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/giantantqueen/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// BILE PROJECTILE
/obj/item/projectile/bile
	name = "bile spit"
	damage = 20
	icon_state = "toxin"

/obj/item/projectile/bile/on_hit(atom/target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.reagents.add_reagent(/datum/reagent/toxin, 2)

/////////////////
// RADSCORPION //
/////////////////

// BASE RADSCORPION
/mob/living/simple_animal/hostile/radscorpion
	name = "giant radscorpion"
	desc = "A mutated arthropod with an armored carapace and a powerful sting."
	icon = 'icons/fallout/mobs/animals/insects.dmi'
	icon_state = "radscorpion"
	icon_living = "radscorpion"
	icon_dead = "radscorpion_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_RADSCORPION
	
	maxHealth = 120
	health = 120
	speed = 1.25
	move_to_delay = 3
	turns_per_move = 5
	
	melee_damage_lower = 15
	melee_damage_upper = 28
	harm_intent_damage = 8
	obj_damage = 20
	
	aggro_vision_range = 4  // Poor eyesight
	vision_range = 5
	
	butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/radscorpion_meat = 2,
		/obj/item/stack/sheet/bone = 1
	)
	
	waddle_amount = 3
	waddle_up_time = 1
	waddle_side_time = 1
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("hisses")
	attack_verb_simple = "stings"
	attack_sound = 'sound/creatures/radscorpion_attack.ogg'
	
	emote_taunt = list("snips")
	emote_taunt_sound = list('sound/f13npc/scorpion/taunt1.ogg', 'sound/f13npc/scorpion/taunt2.ogg', 'sound/f13npc/scorpion/taunt3.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/scorpion/aggro.ogg')
	idlesound = list('sound/creatures/radscorpion_snip.ogg')
	death_sound = 'sound/f13npc/scorpion/death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("radscorpion")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	blood_volume = 0
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
	
	// Pure melee - venomous sting
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	// Color randomization
	var/scorpion_color = "radscorpion"
	var/list/icon_sets = list("radscorpion", "radscorpion_blue", "radscorpion_black")

/mob/living/simple_animal/hostile/radscorpion/Initialize()
	. = ..()
	scorpion_randomify()
	update_icons()

/mob/living/simple_animal/hostile/radscorpion/proc/scorpion_randomify()
	scorpion_color = pick(icon_sets)
	icon_state = "[scorpion_color]"
	icon_living = "[scorpion_color]"
	icon_dead = "[scorpion_color]_dead"

/mob/living/simple_animal/hostile/radscorpion/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/radscorpion/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/radscorpion/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 5)

// BLACK RADSCORPION - tougher, slower
/mob/living/simple_animal/hostile/radscorpion/black
	name = "black radscorpion"
	desc = "A giant irradiated scorpion with a black exoskeleton. Its appearance makes you shudder in fear. This one has giant pincers."
	icon_state = "radscorpion_black"
	icon_living = "radscorpion_black"
	icon_dead = "radscorpion_black_d"
	
	mob_armor = ARMOR_VALUE_RADSCORPION_BLACK
	
	maxHealth = 160
	health = 160
	speed = 1.2
	
	melee_damage_lower = 10
	melee_damage_upper = 28

// BLUE RADSCORPION - weaker, faster
/mob/living/simple_animal/hostile/radscorpion/blue
	name = "blue radscorpion"
	desc = "A giant irradiated scorpion with a bluish exoskeleton. Slightly smaller and faster than its reddish cousin."
	icon_state = "radscorpion_blue"
	icon_living = "radscorpion_blue"
	icon_dead = "radscorpion_blue_d"
	icon_gib = "radscorpion_blue_gib"
	
	maxHealth = 110
	health = 110
	speed = 1.35

/////////////
// CAZADOR //
/////////////

// BASE CAZADOR - flying venomous terror
/mob/living/simple_animal/hostile/cazador
	name = "cazador"
	desc = "A mutated insect known for its fast speed, deadly sting, and being huge bastards."
	icon = 'icons/fallout/mobs/animals/insects.dmi'
	icon_state = "cazador"
	icon_living = "cazador"
	icon_dead = "cazador_dead1"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_CAZADOR
	
	maxHealth = 24
	health = 24
	speed = 1
	move_to_delay = 2.5
	turns_per_move = 5
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	harm_intent_damage = 8
	obj_damage = 20
	rapid_melee = 2
	
	aggro_vision_range = 7
	vision_range = 8
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/cazador_meat = 2,
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/stack/sheet/animalhide/chitin = 2
	)
	butcher_difficulty = 1.5
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("buzzes")
	attack_verb_simple = "stings"
	attack_sound = 'sound/creatures/cazador_attack.ogg'
	
	emote_taunt = list("buzzes")
	emote_taunt_sound = list('sound/f13npc/cazador/cazador_alert.ogg')
	taunt_chance = 30
	aggrosound = list('sound/f13npc/cazador/cazador_charge1.ogg', 'sound/f13npc/cazador/cazador_charge2.ogg', 'sound/f13npc/cazador/cazador_charge3.ogg')
	idlesound = list('sound/creatures/cazador_buzz.ogg')
	death_sound = 'sound/f13npc/cazador/cazador_death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("cazador")
	a_intent = INTENT_HARM
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	gold_core_spawnable = HOSTILE_SPAWN
	blood_volume = 0
	
	movement_type = FLYING
	pass_flags = PASSTABLE | PASSMOB
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement - can fly
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 20  // Fast flier

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee - flying ambush
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/cazador/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/cazador/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/cazador/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/cazador_venom, 4)

/mob/living/simple_animal/hostile/cazador/death(gibbed)
	icon_dead = "cazador_dead[rand(1,5)]"
	. = ..()

/mob/living/simple_animal/hostile/cazador/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		return
	if(prob(50))
		visible_message(span_danger("[src] dodges [Proj]!"))
		return BULLET_ACT_FORCE_PIERCE
	return ..()

// YOUNG CAZADOR - smaller, weaker
/mob/living/simple_animal/hostile/cazador/young
	name = "young cazador"
	desc = "A mutated insect known for its fast speed, deadly sting, and being huge bastards. This one's little."
	
	maxHealth = 20
	health = 20
	speed = 1
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/cazador_meat = 1,
		/obj/item/stack/sheet/animalhide/chitin = 1,
		/obj/item/stack/sheet/sinew = 1
	)
	
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/cazador/young/Initialize()
	. = ..()
	resize = 0.8
	update_transform()

// CAZADOR VENOM
/datum/reagent/toxin/cazador_venom
	name = "Cazador venom"
	description = "A potent toxin resulting from cazador stings that quickly kills if too much remains in the body."
	color = "#801E28"
	toxpwr = 1
	taste_description = "pain"
	taste_mult = 1.3

/datum/reagent/toxin/cazador_venom/on_mob_life(mob/living/M)
	if(volume >= 15)
		M.adjustToxLoss(5, 0)
	..()

/datum/reagent/toxin/cazador_venom/on_mob_life_synth(mob/living/M)
	if(volume >= 15)
		M.adjustFireLoss(5, 0)
	..()

//////////////
// BLOATFLY //
//////////////

/mob/living/simple_animal/hostile/bloatfly
	name = "bloatfly"
	desc = "A common mutated pest resembling an oversized blow-fly."
	icon = 'icons/fallout/mobs/animals/insects.dmi'
	icon_state = "bloatfly"
	icon_living = "bloatfly"
	icon_dead = "bloatfly_dead"
	icon_gib = null
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 20
	health = 20
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 4
	melee_damage_upper = 7
	harm_intent_damage = 8
	obj_damage = 15
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/bloatfly_meat = 2,
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/stack/sheet/animalhide/chitin = 1
	)
	butcher_difficulty = 1.5
	
	waddle_amount = 4
	waddle_up_time = 3
	waddle_side_time = 2
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "bites"
	
	speak_emote = list("chitters")
	attack_verb_simple = "bites"
	attack_sound = 'sound/creatures/bloatfly_attack.ogg'
	
	emote_taunt = list("buzzes")
	taunt_chance = 30
	idlesound = list('sound/f13npc/bloatfly/fly.ogg')
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("hostile", "gecko", "critter-friend")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	blood_volume = 0
	
	movement_type = FLYING
	pass_flags = PASSTABLE | PASSMOB
	density = FALSE
	
	can_ghost_into = TRUE
	desc_short = "A gigantic fly that's more disgusting than actually threatening. Tends to dodge bullets."
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement - can fly
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 20

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure ranged - flies and shoots maggots
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_cooldown_time = 3 SECONDS
	auto_fire_delay = GUN_BURSTFIRE_DELAY_NORMAL
	casingtype = /obj/item/ammo_casing/shotgun/bloatfly
	projectiletype = null
	projectilesound = 'sound/f13npc/bloatfly/shoot2.ogg'
	extra_projectiles = 1
	
	variation_list = list(
		MOB_COLOR_VARIATION(200, 200, 200, 255, 255, 255),
		"varied_projectile" = list(
			/obj/item/ammo_casing/shotgun/bloatfly = 4,
			/obj/item/ammo_casing/shotgun/bloatfly/two = 3,
			/obj/item/ammo_casing/shotgun/bloatfly/three = 3
		)
	)

/mob/living/simple_animal/hostile/bloatfly/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(6)

/mob/living/simple_animal/hostile/bloatfly/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloatfly/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		return
	if(prob(50))
		visible_message(span_danger("[src] dodges [Proj]!"))
		return BULLET_ACT_FORCE_PIERCE
	return ..()

/mob/living/simple_animal/hostile/bloatfly/become_the_mob(mob/user)
	call_backup = /obj/effect/proc_holder/mob_common/summon_backup/small_critter
	send_mobs = /obj/effect/proc_holder/mob_common/direct_mobs/small_critter
	. = ..()

//////////////
// RADROACH //
//////////////

/mob/living/simple_animal/hostile/radroach
	name = "radroach"
	desc = "A large mutated insect that finds its way everywhere."
	icon = 'icons/fallout/mobs/animals/insects.dmi'
	icon_state = "radroach"
	icon_living = "radroach"
	icon_dead = "radroach_dead"
	icon_gib = "radroach_gib"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 20
	health = 20
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 4
	melee_damage_upper = 6
	harm_intent_damage = 8
	obj_damage = 20
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/radroach_meat = 2,
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/stack/sheet/animalhide/chitin = 1
	)
	butcher_difficulty = 1.5
	
	waddle_amount = 1
	waddle_up_time = 1
	waddle_side_time = 1
	
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "hits"
	
	speak_emote = list("skitters")
	attack_verb_simple = "nips"
	attack_sound = 'sound/creatures/radroach_attack.ogg'
	
	aggrosound = list('sound/creatures/radroach_chitter.ogg')
	idlesound = list('sound/f13npc/roach/idle1.ogg', 'sound/f13npc/roach/idle2.ogg', 'sound/f13npc/roach/idle3.ogg')
	death_sound = 'sound/f13npc/roach/roach_death.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("gecko", "critter-friend")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	pass_flags = PASSTABLE | PASSMOB
	density = FALSE
	randpixel = 12
	
	can_ghost_into = TRUE
	desc_short = "One of countless bugs that move in gross hordes."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	variation_list = list(
		MOB_COLOR_VARIATION(50, 50, 50, 255, 255, 255),
		MOB_SPEED_LIST(2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(100),
		MOB_HEALTH_LIST(5, 10, 15, 20),
	)

/mob/living/simple_animal/hostile/radroach/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(6)

/mob/living/simple_animal/hostile/radroach/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/radroach/become_the_mob(mob/user)
	call_backup = /obj/effect/proc_holder/mob_common/summon_backup/small_critter
	send_mobs = /obj/effect/proc_holder/mob_common/direct_mobs/small_critter
	. = ..()

// JUNGLE RADROACH - friendly variant
/mob/living/simple_animal/hostile/radroach/jungle
	faction = list("gecko", "critter-friend", "jungle")

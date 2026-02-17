/* IN THIS FILE
- Ghouls
*/

// ============================================================
// BASE GHOUL
// ============================================================

/mob/living/simple_animal/hostile/ghoul
	name = "feral ghoul"
	desc = "A ghoul that has lost its mind and become aggressive."
	icon = 'icons/fallout/mobs/humans/ghouls.dmi'
	icon_state = "feralghoul"
	icon_living = "feralghoul"
	icon_dead = "feralghoul_dead"
	can_ghost_into = TRUE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_GHOUL_NAKED
	maxHealth = 40
	health = 40
	robust_searching = 1
	move_to_delay = 3
	turns_per_move = 5
	waddle_amount = 2
	waddle_up_time = 1
	waddle_side_time = 1

	speak_emote = list("growls")
	emote_see = list("sniffs the air", "growls", "foams at the mouth")

	a_intent = INTENT_HARM
	speed = 1
	harm_intent_damage = 8
	melee_damage_lower = 6
	melee_damage_upper = 12

	attack_verb_simple = list("claws", "maims", "bites", "mauls", "slashes", "thrashes", "bashes", "glomps")
	attack_sound = 'sound/hallucinations/growl1.ogg'

	atmos_requirements = list(
		"min_oxy" = 5,
		"max_oxy" = 0,
		"min_tox" = 0,
		"max_tox" = 1,
		"min_co2" = 0,
		"max_co2" = 5,
		"min_n2" = 0,
		"max_n2" = 0
	)

	unsuitable_atmos_damage = 20
	gold_core_spawnable = HOSTILE_SPAWN
	faction = list("hostile", "ghoul")
	decompose = TRUE
	sharpness = SHARP_EDGED

	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/human/ghoul = 2,
		/obj/item/stack/sheet/animalhide/human = 1,
		/obj/item/stack/sheet/bone = 1
	)

	emote_taunt_sound = list('sound/f13npc/ghoul/taunt.ogg')
	emote_taunt = list("gurgles", "stares", "foams at the mouth", "groans", "growls", "jibbers", "howls madly", "screeches", "charges")

	tastes = list("decay" = 1, "mud" = 1)
	taunt_chance = 30
	aggrosound = list('sound/f13npc/ghoul/aggro1.ogg', 'sound/f13npc/ghoul/aggro2.ogg')
	idlesound = list('sound/f13npc/ghoul/idle.ogg', 'sound/effects/scrungy.ogg')
	death_sound = 'sound/f13npc/ghoul/ghoul_death.ogg'

	loot = list(/obj/item/stack/f13Cash/random/low/lowchance)
	loot_drop_amount = 1
	loot_amount_random = TRUE
	var/random_trash_loot = TRUE

	footstep_type = FOOTSTEP_MOB_BAREFOOT
	desc_short = "A flimsy creature that may or may not be a reanimated corpse."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS

	variation_list = list(
		MOB_COLOR_VARIATION(150, 150, 150, 255, 255, 255),
		MOB_SPEED_LIST(2.3, 2.5, 2.8, 2.9, 3.0),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(10),
		MOB_HEALTH_LIST(30, 35, 40, 40, 40, 40, 41),
		MOB_RETREAT_DISTANCE_LIST(0, 0, 1),
		MOB_RETREAT_DISTANCE_CHANGE_PER_TURN_CHANCE(5),
		MOB_MINIMUM_DISTANCE_LIST(0, 1),
		MOB_MINIMUM_DISTANCE_CHANGE_PER_TURN_CHANCE(10)
	)

	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	can_open_doors = TRUE
	can_open_airlocks = FALSE

	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/ghoul/Initialize()
	. = ..()
	if(random_trash_loot)
		loot = GLOB.trash_ammo + GLOB.trash_chem + GLOB.trash_clothing + GLOB.trash_craft + GLOB.trash_gun + GLOB.trash_misc + GLOB.trash_money + GLOB.trash_mob + GLOB.trash_part + GLOB.trash_tool + GLOB.trash_attachment

/mob/living/simple_animal/hostile/ghoul/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)
	if(!ckey)
		say(pick("*scrungy", "*mbark"))

// Friendly fire resistance - ghouls are tough and fight in packs
/mob/living/simple_animal/hostile/ghoul/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/ghoul))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// The parent /hostile already handles stat_attack = CONSCIOUS correctly.
// The override was also incorrectly blocking legendary ghoul's stat_attack = UNCONSCIOUS
// from working, since it ran before the parent check.

/mob/living/simple_animal/hostile/ghoul/become_the_mob(mob/user)
	call_backup = /obj/effect/proc_holder/mob_common/summon_backup/ghoul
	send_mobs = /obj/effect/proc_holder/mob_common/direct_mobs/ghoul
	. = ..()

// ============================================================
// GHOUL REAVER
// Armored, throws rocks at range, stronger than base ghoul
// ============================================================

/mob/living/simple_animal/hostile/ghoul/reaver
	name = "feral ghoul reaver"
	desc = "A ghoul that has lost its mind and become aggressive. This one is strapped with metal armor, and appears far stronger."
	icon_state = "ghoulreaver"
	icon_living = "ghoulreaver"
	icon_dead = "ghoulreaver_dead"
	speed = 2
	mob_armor = ARMOR_VALUE_GHOUL_REAVER
	maxHealth = 50
	health = 50
	rapid_melee = 2
	move_to_delay = 2.5

	harm_intent_damage = 8
	melee_damage_lower = 8
	melee_damage_upper = 14

	loot = list(/obj/item/stack/f13Cash/random/low/medchance)
	loot_drop_amount = 2
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	desc_short = "A beefy creature that may or may not be a reanimated corpse."

	variation_list = list(
		MOB_COLOR_VARIATION(200, 200, 200, 255, 255, 255),
		MOB_SPEED_LIST(2.5, 2.6, 2.7, 2.8, 2.9),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(10),
		MOB_HEALTH_LIST(41, 45, 50, 50, 50, 50, 51),
		MOB_RETREAT_DISTANCE_LIST(0, 1, 1),
		MOB_RETREAT_DISTANCE_CHANGE_PER_TURN_CHANCE(5),
		MOB_MINIMUM_DISTANCE_LIST(1, 2),
		MOB_MINIMUM_DISTANCE_CHANGE_PER_TURN_CHANCE(10),
		MOB_PROJECTILE_LIST(\
			MOB_PROJECTILE_ENTRY(/obj/item/projectile/bullet/ghoul_rock, 10),\
			MOB_PROJECTILE_ENTRY(/obj/item/projectile/bullet/ghoul_rock/blunt_rock, 10),\
			MOB_PROJECTILE_ENTRY(/obj/item/projectile/bullet/ghoul_rock/jagged_scrap, 1)\
		)
	)

	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1
	ranged_message = "throws a rock"
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/item/projectile/bullet/ghoul_rock
	projectilesound = 'sound/weapons/punchmiss.ogg'

/mob/living/simple_animal/hostile/ghoul/reaver/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

// Military ghoul variants - former US Army, can't be ghost-inhabited
/mob/living/simple_animal/hostile/ghoul/reaver/ncr
	name = "feral ghoul soldier"
	desc = "A former US Army combatant, now ghoulified and insane. The armor that failed it in life still packs some good defense."
	maxHealth = 60
	health = 60
	can_ghost_into = FALSE

/mob/living/simple_animal/hostile/ghoul/reaver/ncr_helmet
	name = "plated feral ghoul soldier"
	desc = "A former US Army combatant, now ghoulified and insane. The armor that failed it in life still packs some good defense."
	maxHealth = 60
	health = 60
	can_ghost_into = FALSE

/mob/living/simple_animal/hostile/ghoul/reaver/ncr_officer
	name = "feral ghoul officer"
	desc = "A former US Army officer, now ghoulified and insane. The armor that failed it in life still packs some good defense."
	maxHealth = 60
	health = 60
	speed = 3
	can_ghost_into = FALSE

// ============================================================
// COLD / FROZEN GHOULS
// FIX: frozenreaver now inherits from coldferal to avoid duplication
// NOTE: Neither has atmos_requirements override - they still need oxygen.
//       Add vacuum-safe atmos list here if they're meant for cold/airless maps.
// ============================================================

/mob/living/simple_animal/hostile/ghoul/coldferal
	name = "cold ghoul feral"
	desc = "A ghoul that has lost its mind and become aggressive. This one is strapped with metal armor, and appears far stronger."
	icon_state = "cold_feral"
	icon_living = "cold_feral"
	icon_dead = "cold_feral_dead"
	speed = 1.5
	maxHealth = 80
	health = 80
	harm_intent_damage = 8
	melee_damage_lower = 10
	melee_damage_upper = 15
	loot = list(/obj/item/stack/f13Cash/random/low/medchance)
	loot_drop_amount = 2
	can_ghost_into = FALSE

/mob/living/simple_animal/hostile/ghoul/coldferal/frozenreaver
	name = "frozen ghoul reaver"
	desc = "A ghoul that has lost its mind and become aggressive. This one is strapped with metal armor, and appears far stronger."
	icon_state = "frozen_reaver"
	icon_living = "frozen_reaver"
	icon_dead = "frozen_reaver_dead"
	loot_drop_amount = 4

// ============================================================
// LEGENDARY GHOUL
// Enrages at 30% HP - faster and more dangerous
// ============================================================

/mob/living/simple_animal/hostile/ghoul/legendary
	name = "legendary ghoul"
	desc = "A ghoul that has lost its mind and become aggressive. This one has exceptionally large, bulging muscles. It looks quite strong."
	icon_state = "glowinghoul"
	icon_living = "glowinghoul"
	icon_dead = "glowinghoul_dead"
	color = "#FFFF00"
	mob_armor = ARMOR_VALUE_GHOUL_LEGEND
	can_ghost_into = FALSE
	maxHealth = 160
	health = 160
	stat_attack = UNCONSCIOUS // Can attack downed players
	speed = 2.5
	harm_intent_damage = 8
	melee_damage_lower = 20
	melee_damage_upper = 35
	mob_size = MOB_SIZE_HUGE // FIX: was raw 5, use the defined constant
	wound_bonus = 0
	bare_wound_bonus = 0
	loot = list(/obj/item/stack/f13Cash/random/med)
	loot_drop_amount = 5
	loot_amount_random = FALSE
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	desc_short = "A deadly creature that may or may not be reanimated jerky."

	low_health_threshold = 0.3 // Enrages at 30% HP
	var/color_rage = "#ff6666"

/mob/living/simple_animal/hostile/ghoul/legendary/become_the_mob(mob/user)
	call_backup = null
	send_mobs = null
	. = ..()

/// RAGE MODE - legendary ghoul becomes faster and deadlier at low health
/mob/living/simple_animal/hostile/ghoul/legendary/make_low_health()
	visible_message(span_danger("[src] howls with primal fury!!!"))
	playsound(src, pick(aggrosound), 100, 1, SOUND_DISTANCE(15))
	color = color_rage
	speed *= 0.7
	melee_damage_lower = round(melee_damage_lower * 1.4)
	melee_damage_upper = round(melee_damage_upper * 1.4)
	wound_bonus += 15
	bare_wound_bonus += 30
	is_low_health = TRUE

/// Calming down from rage (health recovered above threshold)
/mob/living/simple_animal/hostile/ghoul/legendary/make_high_health()
	visible_message(span_notice("[src]'s fury subsides."))
	color = initial(color)
	speed = initial(speed)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	wound_bonus = initial(wound_bonus)
	bare_wound_bonus = initial(bare_wound_bonus)
	is_low_health = FALSE

// ============================================================
// GLOWING GHOUL
// Ranged radiation attacker, heals nearby ghouls passively
// ============================================================

/mob/living/simple_animal/hostile/ghoul/glowing
	name = "glowing feral ghoul"
	desc = "A feral ghoul that has absorbed massive amounts of radiation, causing them to glow in the dark and radiate constantly."
	icon_state = "glowinghoul"
	icon_living = "glowinghoul"
	icon_dead = "glowinghoul_dead"
	mob_armor = ARMOR_VALUE_GHOUL_GLOWING
	maxHealth = 40
	health = 40
	speed = 2
	harm_intent_damage = 8
	melee_damage_lower = 10
	melee_damage_upper = 22
	light_system = MOVABLE_LIGHT
	light_range = 2
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	desc_short = "A glowing creature that may or may not be a reanimated corpse."
	loot_drop_amount = 2

	variation_list = list(
		MOB_COLOR_VARIATION(150, 150, 150, 255, 255, 255),
		MOB_SPEED_LIST(2.6, 2.7, 2.8, 2.9),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(10),
		MOB_HEALTH_LIST(38, 40, 42, 44),
		MOB_RETREAT_DISTANCE_LIST(0, 2, 4),
		MOB_RETREAT_DISTANCE_CHANGE_PER_TURN_CHANCE(50),
		MOB_MINIMUM_DISTANCE_LIST(2, 3, 4),
		MOB_MINIMUM_DISTANCE_CHANGE_PER_TURN_CHANCE(50)
	)

	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 4
	ranged_message = "emits radiation"
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/radiation_thing
	projectilesound = 'sound/weapons/etherealhit.ogg'

/mob/living/simple_animal/hostile/ghoul/glowing/Initialize(mapload)
	. = ..()
	// restrict_faction = null means ALL nearby ghouls benefit from the aura
	AddComponent(/datum/component/glow_heal, chosen_targets = /mob/living/simple_animal/hostile/ghoul, allow_revival = FALSE, restrict_faction = null, type_healing = BRUTELOSS)

/mob/living/simple_animal/hostile/ghoul/glowing/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/ghoul/glowing/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.apply_effect(20, EFFECT_IRRADIATE, 0)

// FEV-mutated glowing ghoul - much tougher
/mob/living/simple_animal/hostile/ghoul/glowing/strong
	maxHealth = 180
	health = 180
	speed = 1.4
	can_ghost_into = FALSE
	melee_damage_lower = 25
	melee_damage_upper = 30
	armour_penetration = 0.1

// ============================================================
// SOLDIER GHOULS (living/allied)
// ============================================================

/mob/living/simple_animal/hostile/ghoul/soldier
	name = "ghoul soldier"
	desc = "Have you ever seen a living ghoul before?<br>Ghouls are necrotic post-humans - decrepit, rotting, zombie-like mutants."
	icon_state = "soldier_ghoul"
	icon_living = "soldier_ghoul"
	icon_dead = "soldier_ghoul_d"
	icon_gib = "syndicate_gib"
	maxHealth = 60
	health = 60
	loot = list(/obj/item/stack/f13Cash/random/low/medchance)
	loot_drop_amount = 2
	can_ghost_into = FALSE

/mob/living/simple_animal/hostile/ghoul/soldier/armored
	name = "armored ghoul soldier"
	desc = "Have you ever seen a living ghoul before?<br>Ghouls are necrotic post-humans - decrepit, rotting, zombie-like mutants."
	icon_state = "soldier_ghoul_a"
	icon_living = "soldier_ghoul_a"
	icon_dead = "soldier_ghoul_a_d"
	icon_gib = "syndicate_gib"
	maxHealth = 80
	health = 80
	loot_drop_amount = 3

// ============================================================
// SCORCHED GHOULS
// Faction "scorched" - separate from base ghoul faction
// ============================================================

/mob/living/simple_animal/hostile/ghoul/scorched
	name = "scorched ghoul soldier"
	desc = "Have you ever seen a living ghoul before?<br>Ghouls are necrotic post-humans - decrepit, rotting, zombie-like mutants."
	icon_state = "scorched_m"
	icon_living = "scorched_m"
	icon_dead = "scorched_m_d"
	icon_gib = "syndicate_gib"
	speak_chance = 1
	environment_smash = 0 // Scorched don't smash furniture unlike feral ghouls
	response_help_simple = "hugs"
	response_disarm_simple = "pushes aside"
	response_harm_simple = "growl"
	move_to_delay = 3
	faction = list("scorched", "hostile")
	death_sound = null
	melee_damage_upper = 20
	aggro_vision_range = 10
	attack_verb_simple = "punches"
	attack_sound = "punch"
	can_ghost_into = FALSE
	loot_drop_amount = 4

/mob/living/simple_animal/hostile/ghoul/scorched/ranged
	name = "ranged ghoul soldier"
	desc = "Have you ever seen a living ghoul before?<br>Ghouls are necrotic post-humans - decrepit, rotting, zombie-like mutants."
	icon_state = "scorched_r"
	icon_living = "scorched_r"
	icon_dead = "scorched_r_d"
	icon_gib = "syndicate_gib"
	turns_per_move = 5
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_verb_simple = "shoots"
	loot_drop_amount = 5

	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/bullet/c9mm/simple
	projectilesound = 'sound/f13weapons/hunting_rifle.ogg'

// ============================================================
// WYOMING GHOST SOLDIER
// NOTE: faction includes "supermutant" intentionally - this mob is
// allied with both supermutants and ghouls as a Sunset event enemy.
// ============================================================

/mob/living/simple_animal/hostile/ghoul/wyomingghost
	name = "ghost soldier"
	desc = "A figure clad in armor that stands silent except for the slight wheezing coming from them, a dark orange and black liquid pumps through a clear tube into the gas mask. The armor they wear seems to be sealed to their skin."
	icon_state = "wyomingghost"
	icon_living = "wyomingghost"
	icon_dead = "wyomingghost_dead"
	robust_searching = 1
	turns_per_move = 5
	speak_emote = list("wheezes")
	emote_see = list("stares")
	maxHealth = 140
	health = 140
	speed = 2
	harm_intent_damage = 8
	melee_damage_lower = 15
	melee_damage_upper = 15
	attack_verb_simple = "attacks"
	faction = list("supermutant", "ghoul") // Allied with both factions - intentional for Sunset event
	decompose = FALSE
	can_ghost_into = FALSE
	loot_drop_amount = 5

// ============================================================
// ZOMBIE GHOULS (Halloween event)
// Infect humans on hit - spreads ghoulification
// ============================================================

/mob/living/simple_animal/hostile/ghoul/zombie
	name = "ravenous feral ghoul"
	desc = "A ferocious feral ghoul, hungry for human meat."
	faction = list("ghoul")
	stat_attack = CONSCIOUS
	maxHealth = 170
	health = 170
	can_ghost_into = FALSE

/mob/living/simple_animal/hostile/ghoul/zombie/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		try_to_ghoul_zombie_infect(H) // Defined in disease/infection code

/mob/living/simple_animal/hostile/ghoul/zombie/reaver
	name = "ravenous feral ghoul reaver"
	desc = "A ferocious feral ghoul, hungry for human meat. This one is strapped with metal armor, and appears far stronger."
	icon_state = "ghoulreaver"
	icon_living = "ghoulreaver"
	icon_dead = "ghoulreaver_dead"
	speed = 2
	maxHealth = 130
	health = 130
	harm_intent_damage = 8
	melee_damage_lower = 30
	melee_damage_upper = 30
	can_ghost_into = FALSE

	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1
	ranged_message = "throws a rock"
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/item/projectile/bullet/ghoul_rock
	projectilesound = 'sound/weapons/punchmiss.ogg'

/mob/living/simple_animal/hostile/ghoul/zombie/glowing
	name = "ravenous glowing feral ghoul"
	desc = "A ferocious feral ghoul, hungry for human meat. This one has absorbed massive amounts of radiation, causing them to glow in the dark and radiate constantly."
	icon_state = "glowinghoul"
	icon_living = "glowinghoul"
	icon_dead = "glowinghoul_dead"
	maxHealth = 120
	health = 120
	speed = 2
	harm_intent_damage = 8
	melee_damage_lower = 30
	melee_damage_upper = 30
	light_system = MOVABLE_LIGHT
	light_range = 2
	can_ghost_into = FALSE

	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 4
	ranged_message = "emits radiation"
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/radiation_thing
	projectilesound = 'sound/weapons/etherealhit.ogg'

/mob/living/simple_animal/hostile/ghoul/zombie/glowing/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/glow_heal, chosen_targets = /mob/living/simple_animal/hostile/ghoul, allow_revival = FALSE, restrict_faction = null, type_healing = BRUTELOSS)

/mob/living/simple_animal/hostile/ghoul/zombie/glowing/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/ghoul/zombie/glowing/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.apply_effect(20, EFFECT_IRRADIATE, 0)

/mob/living/simple_animal/hostile/ghoul/zombie/legendary
	name = "legendary ravenous ghoul"
	desc = "A ferocious feral ghoul, hungry for human meat. This one has exceptionally large, bulging muscles. It looks quite strong."
	icon_state = "glowinghoul"
	icon_living = "glowinghoul"
	icon_dead = "glowinghoul_dead"
	color = "#FFFF00"
	maxHealth = 170
	health = 170
	speed = 2.5
	harm_intent_damage = 8
	melee_damage_lower = 30
	melee_damage_upper = 35
	mob_size = MOB_SIZE_HUGE
	wound_bonus = 0
	bare_wound_bonus = 0
	can_ghost_into = FALSE

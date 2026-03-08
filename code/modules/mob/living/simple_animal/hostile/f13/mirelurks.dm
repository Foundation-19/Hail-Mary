// In this document: Mirelurks

///////////////
// MIRELURKS //
///////////////

// BASE MIRELURK - shared properties
/mob/living/simple_animal/hostile/mirelurk
	name = "mirelurk"
	desc = "A giant mutated crustacean, with a hardened exo-skeleton."
	icon = 'icons/fallout/mobs/animals/mirelurks.dmi'
	icon_state = "mirelurk"
	icon_living = "mirelurk"
	icon_dead = "mirelurk_d"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_MIRELURK  // Hard shell - resistant to bullets
	
	maxHealth = 120
	health = 120
	speed = 1
	move_to_delay = 3
	turns_per_move = 5
	
	melee_damage_lower = 5
	melee_damage_upper = 18
	harm_intent_damage = 8
	rapid_melee = 1
	
	aggro_vision_range = 7
	vision_range = 8
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 2,
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/stack/sheet/bone = 1
	)
	butcher_results = list(/obj/item/stack/sheet/bone = 1)
	butcher_difficulty = 2
	
	speak_emote = list("foams", "clacks", "chitters", "snips", "snaps")
	emote_see = list("clacks its claws", "foams at the mouth", "woobs", "extends its eyestalks")
	attack_verb_simple = list("pinches", "rends", "snips", "snaps", "snibbity-snaps", "clonks", "dissects")
	
	waddle_amount = 2
	waddle_up_time = 1
	waddle_side_time = 1
	
	faction = list("mirelurk")
	gold_core_spawnable = HOSTILE_SPAWN
	blood_volume = 0
	footstep_type = FOOTSTEP_MOB_CLAW
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement - can climb stairs
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	// Can't open doors - but can smash them
	can_open_doors = FALSE
	can_open_airlocks = FALSE
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	
	// Pure melee ambusher - hides and rushes
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	// Sound effects - using existing crustacean/creature sounds
	emote_taunt_sound = list('sound/creatures/radscorpion_snip.ogg')
	emote_taunt = list("clacks menacingly", "snaps its claws")
	taunt_chance = 30
	aggrosound = list('sound/creatures/radscorpion_attack.ogg')
	idlesound = list('sound/creatures/radroach_chitter.ogg')
	death_sound = 'sound/creatures/rattle.ogg'
	attack_sound = 'sound/creatures/radscorpion_snip.ogg'
	
	variation_list = list(
		MOB_COLOR_VARIATION(100, 100, 100, 255, 255, 255),
		MOB_SPEED_LIST(3.3, 3.4, 3.5),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(10),
		MOB_HEALTH_LIST(110, 115, 120, 130),
	)

/mob/living/simple_animal/hostile/mirelurk/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

// Override CanAttack to ignore unconscious/dead targets
/mob/living/simple_animal/hostile/mirelurk/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// MIRELURK HUNTER - bigger, meaner, faster
/mob/living/simple_animal/hostile/mirelurk/hunter
	name = "mirelurk hunter"
	desc = "A giant mutated crustacean, with a hardened exoskeleton. Its appearance makes you shudder in fear. This one has giant, razor-sharp claw pincers."
	icon_state = "mirelurkhunter"
	icon_living = "mirelurkhunter"
	icon_dead = "mirelurkhunter_d"
	icon_gib = "gib"
	
	mob_armor = ARMOR_VALUE_MIRELURK_HUNTER  // Even tougher shell
	
	maxHealth = 160
	health = 160
	speed = 1
	
	melee_damage_lower = 15
	melee_damage_upper = 28
	rapid_melee = 2  // Attacks faster
	
	stat_attack = UNCONSCIOUS  // Will attack downed targets
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 4,
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/stack/sheet/bone = 2
	)
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	
	variation_list = list(
		MOB_COLOR_VARIATION(100, 100, 100, 255, 255, 255),
		MOB_SPEED_LIST(3.0, 3.1, 3.2),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(10),
		MOB_HEALTH_LIST(140, 150, 160, 170),
	)

// MIRELURK BABY - small, weak, calls for help
/mob/living/simple_animal/hostile/mirelurk/baby
	name = "mirelurk baby"
	desc = "A neophyte mirelurk baby, mostly harmless. Adults respond to their chittering if distressed."
	icon_state = "mirelurkbaby"
	icon_living = "mirelurkbaby"
	icon_dead = "mirelurkbaby_d"
	icon_gib = "gib"
	
	mob_armor = ARMOR_VALUE_MIRELURK_BABY  // Softer shell
	
	maxHealth = 40
	health = 40
	speed = 1
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	rapid_melee = 1
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 1,
		/obj/item/stack/sheet/sinew = 1
	)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 1)
	
	waddle_amount = 3
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Babies run away and call for help
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1
	
	variation_list = list(
		MOB_COLOR_VARIATION(100, 100, 100, 255, 255, 255),
		MOB_SPEED_LIST(2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(100),
		MOB_HEALTH_LIST(35, 39, 40, 41),
	)

/mob/living/simple_animal/hostile/mirelurk/baby/Aggro()
	..()
	summon_backup(12)  // Babies call louder for help
	if(!ckey)
		visible_message(span_warning("[src] chitters frantically for help!"))

// MIRELURK QUEEN - rare, powerful, spawns babies
/mob/living/simple_animal/hostile/mirelurk/queen
	name = "mirelurk queen"
	desc = "A massive mirelurk matriarch. Her hardened carapace glistens with toxic secretions, and she guards her brood fiercely."
	icon_state = "mirelurk"
	icon_living = "mirelurk"
	icon_dead = "mirelurk_d"
	color = "#88ccaa"  // Greenish-teal coloration for breeding female
	
	mob_armor = ARMOR_VALUE_MIRELURK_QUEEN  // Nearly impenetrable
	
	maxHealth = 400
	health = 400
	speed = 2.5  // Slower but tankier
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 20
	melee_damage_upper = 35
	rapid_melee = 1
	obj_damage = 150
	
	environment_smash = ENVIRONMENT_SMASH_WALLS  // Can break through walls
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 8,
		/obj/item/stack/sheet/sinew = 4,
		/obj/item/stack/sheet/bone = 4
	)
	
	loot = list(/obj/item/stack/f13Cash/random/high)
	loot_drop_amount = 5
	
	// Mixed combat - acid spit at range, claw up close
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1
	
	ranged_message = "spits acid"
	ranged_cooldown_time = 4 SECONDS
	projectiletype = /obj/item/projectile/mirelurk_acid
	projectilesound = 'sound/effects/splat.ogg'
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE
	
	// Spawner component
	var/max_babies = 3
	var/baby_types = list(/mob/living/simple_animal/hostile/mirelurk/baby)
	var/spawn_time = 20 SECONDS
	var/spawn_text = "emerges from"

/mob/living/simple_animal/hostile/mirelurk/queen/Initialize()
	. = ..()
	AddComponent(/datum/component/spawner, baby_types, spawn_time, faction, spawn_text, max_babies, _range = 5)
	resize = 1.3
	update_transform()

/mob/living/simple_animal/hostile/mirelurk/queen/death()
	RemoveComponentByType(/datum/component/spawner)
	. = ..()

/mob/living/simple_animal/hostile/mirelurk/queen/Destroy()
	RemoveComponentByType(/datum/component/spawner)
	. = ..()

/mob/living/simple_animal/hostile/mirelurk/queen/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(15)
	if(!ckey)
		visible_message(span_danger("[src] screeches, calling the brood!"))

/mob/living/simple_animal/hostile/mirelurk/queen/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 3)

// SOFTSHELL MIRELURK - weaker variant, less armor
/mob/living/simple_animal/hostile/mirelurk/softshell
	name = "softshell mirelurk"
	desc = "A mirelurk that hasn't fully hardened its shell yet. Still dangerous, but more vulnerable."
	icon_state = "mirelurk"
	icon_living = "mirelurk"
	icon_dead = "mirelurk_d"
	color = "#ffaa99"  // Reddish-pink for vulnerable molting state
	
	mob_armor = ARMOR_VALUE_MIRELURK_SOFT  // Much weaker armor
	
	maxHealth = 80
	health = 80
	speed = 0.8  // Faster to compensate
	
	melee_damage_lower = 8
	melee_damage_upper = 15
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 3,
		/obj/item/stack/sheet/sinew = 2
	)
	
	variation_list = list(
		MOB_COLOR_VARIATION(150, 150, 150, 200, 200, 200),
		MOB_SPEED_LIST(2.8, 2.9, 3.0),
		MOB_SPEED_CHANGE_PER_TURN_CHANCE(10),
		MOB_HEALTH_LIST(70, 75, 80, 85),
	)

// KING MIRELURK - rare boss variant
/mob/living/simple_animal/hostile/mirelurk/king
	name = "mirelurk king"
	desc = "A towering humanoid mirelurk with a distinctive crown-like crest. Highly intelligent and extremely dangerous."
	icon_state = "mirelurkhunter"
	icon_living = "mirelurkhunter"
	icon_dead = "mirelurkhunter_d"
	color = "#6633aa"  // Dark purple for intimidating alpha male
	
	mob_armor = ARMOR_VALUE_MIRELURK_KING
	
	maxHealth = 350
	health = 350
	speed = 1.5
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 25
	melee_damage_upper = 40
	rapid_melee = 2
	obj_damage = 200
	
	environment_smash = ENVIRONMENT_SMASH_WALLS
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/mirelurk = 6,
		/obj/item/stack/sheet/sinew = 3,
		/obj/item/stack/sheet/bone = 3
	)
	
	loot = list(/obj/item/stack/f13Cash/random/high)
	loot_drop_amount = 8
	
	// Mixed combat - sonic scream at range
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_message = "unleashes a sonic scream"
	ranged_cooldown_time = 5 SECONDS
	projectiletype = /obj/item/projectile/mirelurk_sonic
	projectilesound = 'sound/effects/supermatter.ogg'  // Sonic scream sound
	extra_projectiles = 2
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE
	
	// Low health rage mode
	low_health_threshold = 0.35
	var/color_rage = "#FF4444"

/mob/living/simple_animal/hostile/mirelurk/king/Initialize()
	. = ..()
	resize = 1.4
	update_transform()

/mob/living/simple_animal/hostile/mirelurk/king/make_low_health()
	visible_message(span_danger("[src] roars with fury, its crest glowing red!"))
	playsound(src, pick(aggrosound), 100, 1, SOUND_DISTANCE(15))
	color = color_rage
	speed *= 0.75  // Faster
	melee_damage_lower = round(melee_damage_lower * 1.3)
	melee_damage_upper = round(melee_damage_upper * 1.3)
	rapid_melee = 3
	is_low_health = TRUE

/mob/living/simple_animal/hostile/mirelurk/king/make_high_health()
	visible_message(span_notice("[src]'s fury subsides."))
	color = initial(color)
	speed = initial(speed)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	rapid_melee = initial(rapid_melee)
	is_low_health = FALSE

/mob/living/simple_animal/hostile/mirelurk/king/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(15)
	if(!ckey)
		visible_message(span_danger("[src] bellows a deafening challenge!"))

/mob/living/simple_animal/hostile/mirelurk/king/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 5)
		H.Knockdown(20)  // Powerful hits knock down

// PROJECTILES
/obj/item/projectile/mirelurk_acid
	name = "acid spit"
	damage = 20
	icon_state = "toxin"
	
/obj/item/projectile/mirelurk_acid/on_hit(atom/target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.reagents.add_reagent(/datum/reagent/toxin, 3)
		M.emote("scream")

/obj/item/projectile/mirelurk_sonic
	name = "sonic blast"
	damage = 15
	stamina = 30
	icon_state = "sound"
	
/obj/item/projectile/mirelurk_sonic/on_hit(atom/target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.Stun(20)
		M.soundbang_act(1, 4, 10, 5)

// LEGACY EGG STRUCTURE (marked for removal)
/obj/structure/mirelurkegg
	name = "mirelurk eggs"
	desc = "A fresh clutch of mirelurk eggs. They pulse with life."
	icon = 'icons/mob/wastemobsdrops.dmi'
	icon_state = "mirelurkeggs"
	density = 1
	anchored = 0
	max_integrity = 50
	
/obj/structure/mirelurkegg/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	to_chat(user, span_notice("You crack open [src]."))
	new /obj/item/reagent_containers/food/snacks/mirelurk_egg(get_turf(src))
	qdel(src)

/obj/structure/mirelurkegg/attackby(obj/item/I, mob/user, params)
	if(I.force >= 5)
		visible_message(span_warning("[src] cracks open!"))
		new /obj/item/reagent_containers/food/snacks/mirelurk_egg(get_turf(src))
		qdel(src)
		return
	return ..()

// MIRELURK EGG FOOD ITEM
/obj/item/reagent_containers/food/snacks/mirelurk_egg
	name = "mirelurk egg"
	desc = "A large, protein-rich egg from a mirelurk."
	icon = 'icons/obj/food/egg.dmi'
	icon_state = "egg"
	list_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/consumable/nutriment/vitamin = 2)
	filling_color = "#FFCC99"
	tastes = list("egg" = 1, "ocean" = 1)
	foodtype = MEAT | RAW
	cooked_type = /obj/item/reagent_containers/food/snacks/mirelurk_egg/cooked

/obj/item/reagent_containers/food/snacks/mirelurk_egg/cooked
	name = "cooked mirelurk egg"
	desc = "A perfectly cooked mirelurk egg. Delicious and nutritious."
	icon_state = "egg"
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/nutriment/vitamin = 3)
	foodtype = MEAT

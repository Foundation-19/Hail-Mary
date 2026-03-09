// In this document: Vault Dwellers, Enclave, Brotherhood, NCR, Legion, Tribals

///////////////
// VAULT NPC //
///////////////

// BASE VAULT DWELLER
/mob/living/simple_animal/hostile/vault
	name = "Vault Dweller"
	desc = "Just a Vault Dweller."
	icon = 'icons/fallout/mobs/humans/fallout_npc.dmi'
	icon_state = "vault_dweller"
	icon_living = "vault_dweller"
	icon_dead = "vault_dweller"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	
	maxHealth = 100
	health = 100
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	harm_intent_damage = 8
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "punches"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	
	faction = list("vault", "city")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	status_flags = CANPUSH
	del_on_death = TRUE
	speak_chance = 1
	despawns_when_lonely = FALSE
	
	loot = list(/obj/effect/mob_spawn/human/corpse/vault)
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/vault/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - vault dwellers work together
/mob/living/simple_animal/hostile/vault/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/vault))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// VAULT DWELLER VARIANTS - flee when attacked
/mob/living/simple_animal/hostile/vault/dweller
	// Cowardly melee - flees when attacked
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = 10
	minimum_distance = 1
	
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE

/mob/living/simple_animal/hostile/vault/dweller/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)
	say("HELP!!")

/mob/living/simple_animal/hostile/vault/dweller/dweller1
	icon_state = "vault_dweller1"
	icon_living = "vault_dweller1"
	icon_dead = "vault_dweller1"

/mob/living/simple_animal/hostile/vault/dweller/dweller2
	icon_state = "vault_dweller2"
	icon_living = "vault_dweller2"
	icon_dead = "vault_dweller2"

/mob/living/simple_animal/hostile/vault/dweller/dweller3
	icon_state = "vault_dweller3"
	icon_living = "vault_dweller3"
	icon_dead = "vault_dweller3"

/mob/living/simple_animal/hostile/vault/dweller/dweller4
	icon_state = "vault_dweller4"
	icon_living = "vault_dweller4"
	icon_dead = "vault_dweller4"

/mob/living/simple_animal/hostile/vault/dweller/dweller5
	icon_state = "vault_dweller5"
	icon_living = "vault_dweller5"
	icon_dead = "vault_dweller5"

// VAULT SECURITY - armed guards
/mob/living/simple_animal/hostile/vault/security
	name = "Vault Security"
	desc = "Just a Vault Security officer."
	icon_state = "vault_dweller_sec"
	icon_living = "vault_dweller_sec"
	icon_dead = "vault_dweller_sec"
	
	maxHealth = 160
	health = 160
	
	loot = list(/obj/effect/mob_spawn/human/corpse/vault/security)
	healable = TRUE
	
	// Pure ranged - laser pistol
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/beam
	projectilesound = 'sound/weapons/resonator_fire.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(LASER_VOLUME),
		SP_VOLUME_SILENCED(LASER_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(LASER_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(LASER_DISTANT_SOUND),
		SP_DISTANT_RANGE(LASER_RANGE_DISTANT)
	)

/mob/living/simple_animal/hostile/vault/security/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

// VAULT CORPSES
/obj/effect/mob_spawn/human/corpse/vault
	name = "Vault Dweller"
	gloves = /obj/item/pda
	uniform = /obj/item/clothing/under/f13/vault/v13
	shoes = /obj/item/clothing/shoes/jackboots

/obj/effect/mob_spawn/human/corpse/vault/security
	name = "Vault Security"
	gloves = /obj/item/pda
	glasses = /obj/item/clothing/glasses/sunglasses
	uniform = /obj/item/clothing/under/f13/vault/v13
	suit = /obj/item/clothing/suit/armor/medium/vest
	shoes = /obj/item/clothing/shoes/jackboots
	head = /obj/item/clothing/head/helmet/riot/vaultsec

/////////////////
// ENCLAVE NPC //
/////////////////

// BASE ENCLAVE
/mob/living/simple_animal/hostile/enclave
	name = "enclave specialist"
	desc = "An Enclave soldier with combat armor and a G-11 rifle."
	icon = 'icons/fallout/mobs/humans/fallout_npc.dmi'
	icon_state = "enclave_specialist"
	icon_living = "enclave_specialist"
	icon_dead = "enclave_specialist"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_ENCLAVE
	
	maxHealth = 200
	health = 200
	speed = 0
	turns_per_move = 5
	
	melee_damage_lower = 15
	melee_damage_upper = 35
	harm_intent_damage = 8
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	healable = TRUE
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "pistol-whips"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	speak = list("For the Enclave!", "Stars and Stripes!", "Liberty or death!")
	speak_emote = list("pulls out a weapon", "shouts")
	speak_chance = 0
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	
	faction = list("enclave")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	status_flags = CANPUSH
	del_on_death = TRUE
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure ranged - G-11
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 6
	minimum_distance = 1
	
	ranged_cooldown_time = 22
	extra_projectiles = 2
	projectiletype = /obj/item/projectile/bullet/c46x30mm
	projectilesound = 'sound/weapons/gunshot_smg.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PISTOL_LIGHT_VOLUME),
		SP_VOLUME_SILENCED(PISTOL_LIGHT_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PISTOL_LIGHT_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(PISTOL_LIGHT_DISTANT_SOUND),
		SP_DISTANT_RANGE(PISTOL_LIGHT_RANGE_DISTANT)
	)

/mob/living/simple_animal/hostile/enclave/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/enclave/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - enclave soldiers are well-trained
/mob/living/simple_animal/hostile/enclave/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/enclave))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// ENCLAVE SCIENTIST - cowardly ranged
/mob/living/simple_animal/hostile/enclave/scientist
	name = "enclave scientist"
	desc = "An Enclave Scientist wearing an advanced radiation suit. While they may run from you, that does not exempt them from the evil they have committed."
	icon_state = "enclave_scientist"
	icon_living = "enclave_scientist"
	icon_dead = "enclave_scientist"
	
	maxHealth = 120
	health = 120
	
	melee_damage_lower = 5
	melee_damage_upper = 15
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	
	loot = list(/obj/effect/mob_spawn/human/corpse/enclavescientist)
	
	// Pure ranged - flees when threatened
	combat_mode = COMBAT_MODE_RANGED
	retreat_distance = 10
	minimum_distance = 1
	
	ranged_cooldown_time = 30
	extra_projectiles = 0
	attack_verb_simple = "thrusts"
	projectiletype = /obj/item/projectile/f13plasma/pistol/adam
	projectilesound = 'sound/weapons/wave.ogg'
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

// ENCLAVE ARMORED INFANTRY - heavy trooper
/mob/living/simple_animal/hostile/enclave/soldier
	name = "enclave armored infantry"
	desc = "An Enclave Soldier wearing Advanced Power Armor and a plasma multi-caster. Play time's over, mutie."
	icon_state = "enclave_armored"
	icon_living = "enclave_armored"
	icon_dead = "enclave_armored"
	
	mob_armor = ARMOR_VALUE_ENCLAVE_APA
	
	maxHealth = 560
	health = 560
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 20
	melee_damage_upper = 47
	
	loot = list(/obj/effect/mob_spawn/human/corpse/enclave/soldier)
	
	// Pure ranged - aggressive
	combat_mode = COMBAT_MODE_RANGED
	retreat_distance = 3
	minimum_distance = 1
	
	ranged_cooldown_time = 12
	extra_projectiles = 2
	attack_verb_simple = "power-fists"
	projectiletype = /obj/item/projectile/f13plasma/repeater
	projectilesound = 'sound/f13weapons/plasmarifle.ogg'
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

// ENCLAVE CORPSES
/obj/effect/mob_spawn/human/corpse/enclavescientist
	name = "enclave scientist"
	uniform = /obj/item/clothing/under/f13/enclave/science
	suit = /obj/item/clothing/suit/bio_suit/enclave
	shoes = /obj/item/clothing/shoes/f13/enclave/serviceboots
	gloves = /obj/item/clothing/gloves/color/latex/nitrile
	head = /obj/item/clothing/head/helmet/f13/envirosuit

/obj/effect/mob_spawn/human/corpse/enclave
	name = "enclave specialist"
	uniform = /obj/item/clothing/under/f13/enclave/peacekeeper
	shoes = /obj/item/clothing/shoes/f13/enclave/serviceboots
	gloves = /obj/item/clothing/gloves/f13/military
	mask = /obj/item/clothing/mask/gas/enclave
	head = /obj/item/clothing/head/f13/enclave/peacekeeper

/obj/effect/mob_spawn/human/corpse/enclave/soldier
	name = "enclave armored infantry"
	uniform = /obj/item/clothing/under/f13/enclave/peacekeeper
	shoes = /obj/item/clothing/shoes/f13/enclave/serviceboots
	gloves = /obj/item/clothing/gloves/f13/military
	mask = /obj/item/clothing/mask/gas/enclave

/////////////////////
// BROTHERHOOD NPC //
/////////////////////

// BASE BROTHERHOOD
/mob/living/simple_animal/hostile/bs
	name = "Brotherhood Knight"
	desc = "The brotherhood never fails."
	icon = 'icons/fallout/mobs/humans/fallout_npc.dmi'
	icon_state = "bs_knight"
	icon_living = "bs_knight"
	icon_dead = "bs_knight"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_BOS
	
	maxHealth = 200
	health = 200
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 7
	melee_damage_upper = 15
	harm_intent_damage = 8
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "pistol-whips"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	speak = list("Semper Invicta!")
	speak_emote = list("rushes")
	speak_chance = 1
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	
	faction = list("BOS")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	status_flags = CANPUSH
	del_on_death = TRUE
	
	loot = list(/obj/effect/mob_spawn/human/corpse/bs)
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/bs/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/bs/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - brotherhood members are well-trained
/mob/living/simple_animal/hostile/bs/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/bs))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// BROTHERHOOD KNIGHT - laser pistol
/mob/living/simple_animal/hostile/bs/knight
	name = "Brotherhood Knight"
	desc = "A Brotherhood Knight wielding a laser pistol and older issue Brotherhood combat armor."
	
	healable = TRUE
	
	// Pure ranged
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/beam/laser/pistol/hitscan
	projectilesound = 'sound/f13weapons/aep7fire.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(LASER_VOLUME),
		SP_VOLUME_SILENCED(LASER_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(LASER_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(LASER_DISTANT_SOUND),
		SP_DISTANT_RANGE(LASER_RANGE_DISTANT)
	)

// BROTHERHOOD PALADIN - laser rifle + power armor
/mob/living/simple_animal/hostile/bs/paladin
	name = "Brotherhood Paladin"
	desc = "A Paladin equipped with an AER9 and T-51b power armor. The Brotherhood has arrived."
	icon_state = "bs_paladin"
	icon_living = "bs_paladin"
	icon_dead = "bs_paladin"
	
	mob_armor = ARMOR_VALUE_BOS_PALADIN
	
	maxHealth = 480
	health = 480
	stat_attack = UNCONSCIOUS
	
	loot = list(/obj/effect/mob_spawn/human/corpse/bs/paladin)
	healable = TRUE
	
	// Pure ranged
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/beam/laser/lasgun/hitscan
	projectilesound = 'sound/f13weapons/aer9fire.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(LASER_VOLUME),
		SP_VOLUME_SILENCED(LASER_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(LASER_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(LASER_DISTANT_SOUND),
		SP_DISTANT_RANGE(LASER_RANGE_DISTANT)
	)

// BROTHERHOOD CORPSES
/obj/effect/mob_spawn/human/corpse/bs
	name = "Brotherhood Knight"
	uniform = /obj/item/clothing/under/syndicate/brotherhood
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/combat
	belt = /obj/item/storage/belt/army/assault
	mask = /obj/item/clothing/mask/gas/sechailer
	head = /obj/item/clothing/head/helmet/f13/combat/brotherhood

/obj/effect/mob_spawn/human/corpse/bs/paladin
	name = "Brotherhood Paladin"
	uniform = /obj/item/clothing/under/f13/recon
	suit = /obj/item/clothing/suit/armor/power_armor/t51b/bos
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/combat
	belt = /obj/item/storage/belt/army/assault
	mask = /obj/item/clothing/mask/gas/sechailer
	head = /obj/item/clothing/head/helmet/f13/power_armor/t51b/bos

///////////////
// NCR = NPC //
///////////////

// BASE NCR
/mob/living/simple_animal/hostile/ncr
	name = "NCR Trooper"
	desc = "For the Republic!"
	icon = 'icons/fallout/mobs/humans/fallout_npc.dmi'
	icon_state = "ncr_trooper"
	icon_living = "ncr_trooper"
	icon_dead = "ncr_trooper"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_NCR
	
	maxHealth = 120
	health = 120
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 8
	melee_damage_upper = 15
	harm_intent_damage = 8
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "attacks"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	speak = list("Patrolling the Mojave almost makes you wish for a nuclear winter.", "When I got this assignment I was hoping there would be more gambling.", "It's been a long tour, all I can think about now is going back home.", "You know, if you were serving, you'd probably be halfway to general by now.", "You oughtta think about enlisting. We need you here.")
	speak_emote = list("says")
	speak_chance = 1
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	
	faction = list("NCR")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	status_flags = CANPUSH
	del_on_death = TRUE
	
	loot = list(/obj/effect/mob_spawn/human/corpse/ncr)
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/ncr/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/ncr/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - NCR troopers are trained soldiers
/mob/living/simple_animal/hostile/ncr/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/ncr))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// NCR TROOPER - service rifle
/mob/living/simple_animal/hostile/ncr/trooper
	name = "NCR Trooper"
	desc = "A standard NCR Trooper wielding a service rifle and equipped with a patrol vest."
	
	healable = TRUE
	
	// Pure ranged
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/bullet/a556/simple
	projectilesound = 'sound/f13weapons/varmint_rifle.ogg'
	casingtype = /obj/item/ammo_casing/a556
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

// NCR RANGER - revolver
/mob/living/simple_animal/hostile/ncr/ranger
	name = "NCR Ranger"
	desc = "A Ranger of the NCRA, wielding a big iron on his hip and equipped with a ranger patrol vest."
	icon_state = "ncr_sergeant"
	icon_living = "ncr_sergeant"
	icon_dead = "ncr_sergeant"
	
	mob_armor = ARMOR_VALUE_NCR_RANGER
	
	maxHealth = 160
	health = 160
	
	loot = list(/obj/effect/mob_spawn/human/corpse/ncr/ranger)
	healable = TRUE
	
	// Pure ranged
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/bullet/m44/simple
	projectilesound = 'sound/f13weapons/44mag.ogg'
	casingtype = /obj/item/ammo_casing/m44
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PISTOL_HEAVY_VOLUME),
		SP_VOLUME_SILENCED(PISTOL_HEAVY_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PISTOL_HEAVY_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(PISTOL_HEAVY_DISTANT_SOUND),
		SP_DISTANT_RANGE(PISTOL_HEAVY_RANGE_DISTANT)
	)

// NCR CORPSES
/obj/effect/mob_spawn/human/corpse/ncr
	name = "NCR Trooper"
	uniform = /obj/item/clothing/under/f13/ncr
	suit = /obj/item/clothing/suit/armor/ncrarmor
	belt = /obj/item/storage/belt/army/assault/ncr
	shoes = /obj/item/clothing/shoes/f13/military/ncr
	head = /obj/item/clothing/head/f13/ncr

/obj/effect/mob_spawn/human/corpse/ncr/ranger
	name = "NCR Ranger"
	uniform = /obj/item/clothing/under/f13/ranger/patrol
	suit = /obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol
	shoes = /obj/item/clothing/shoes/f13/military/leather
	gloves = /obj/item/clothing/gloves/patrol
	head = /obj/item/clothing/head/f13/ranger

////////////////
// LEGION NPC //
////////////////

// BASE LEGION
/mob/living/simple_animal/hostile/legion
	name = "Legion Prime"
	desc = "True to Caesar."
	icon = 'icons/fallout/mobs/humans/fallout_npc.dmi'
	icon_state = "legion_prime"
	icon_living = "legion_prime"
	icon_dead = "legion_prime"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_LEGION
	
	maxHealth = 120
	health = 120
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 8
	melee_damage_upper = 15
	harm_intent_damage = 8
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "attacks"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	speak = list("Ave, true to Caesar.", "True to Caesar.", "Ave, Amicus.", "The new slave girls are quite beautiful.", "Give me cause, Profligate.", "Degenerates like you belong on a cross.")
	speak_emote = list("says")
	speak_chance = 1
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	
	faction = list("Legion")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	status_flags = CANPUSH
	del_on_death = TRUE
	
	loot = list(/obj/effect/mob_spawn/human/corpse/legion)
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/legion/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/legion/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - legion soldiers fight in formation
/mob/living/simple_animal/hostile/legion/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/legion))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// LEGION PRIME - hunting rifle
/mob/living/simple_animal/hostile/legion/prime
	name = "Legion Prime"
	desc = "A Prime Legionary, equipped with a hunting rifle."
	
	healable = TRUE
	
	// Pure ranged
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/bullet/a762/sport/simple
	projectilesound = 'sound/f13weapons/hunting_rifle.ogg'
	casingtype = /obj/item/ammo_casing/a308
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(RIFLE_MEDIUM_VOLUME),
		SP_VOLUME_SILENCED(RIFLE_MEDIUM_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(RIFLE_MEDIUM_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(RIFLE_MEDIUM_DISTANT_SOUND),
		SP_DISTANT_RANGE(RIFLE_MEDIUM_RANGE_DISTANT)
	)

// LEGION DECANUS - veteran officer
/mob/living/simple_animal/hostile/legion/decan
	name = "Legion Decanus"
	desc = "A Prime Decanus, equipped with a hunting rifle."
	icon_state = "legion_decan"
	icon_living = "legion_decan"
	icon_dead = "legion_decan"
	icon_gib = "legion_decan"
	
	mob_armor = ARMOR_VALUE_LEGION_VETERAN
	
	maxHealth = 180
	health = 180
	
	loot = list(/obj/effect/mob_spawn/human/corpse/legion/decan)
	healable = TRUE
	
	// Pure ranged
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/bullet/a762/sport/simple
	projectilesound = 'sound/f13weapons/hunting_rifle.ogg'
	casingtype = /obj/item/ammo_casing/a308
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(RIFLE_MEDIUM_VOLUME),
		SP_VOLUME_SILENCED(RIFLE_MEDIUM_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(RIFLE_MEDIUM_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(RIFLE_MEDIUM_DISTANT_SOUND),
		SP_DISTANT_RANGE(RIFLE_MEDIUM_RANGE_DISTANT)
	)

// LEGION CORPSES
/obj/effect/mob_spawn/human/corpse/legion
	name = "Legion Prime"
	uniform = /obj/item/clothing/under/f13/legskirt
	suit = /obj/item/clothing/suit/armor/legion/prime
	shoes = /obj/item/clothing/shoes/f13/military/legion
	head = /obj/item/clothing/head/helmet/f13/legion/prime

/obj/effect/mob_spawn/human/corpse/legion/decan
	name = "Legion Decanus"
	uniform = /obj/item/clothing/under/f13/legskirt
	suit = /obj/item/clothing/suit/armor/legion/vet
	shoes = /obj/item/clothing/shoes/f13/military/legion
	gloves = /obj/item/clothing/gloves/legion
	head = /obj/item/clothing/head/helmet/f13/legion/prime/decan

////////////////
// TRIBAL NPC //
////////////////

/mob/living/simple_animal/hostile/tribe
	name = "Wayfarer Hunter"
	desc = "A hunter of the wayfarer tribe, wielding a glaive."
	icon = 'icons/fallout/mobs/humans/fallout_npc.dmi'
	icon_state = "tribal_raider"
	icon_living = "tribal_raider"
	icon_dead = "tribal_raider_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mob_armor = ARMOR_VALUE_TRIBAL
	
	maxHealth = 160
	health = 160
	speed = 1
	turns_per_move = 5
	
	melee_damage_lower = 22
	melee_damage_upper = 47
	harm_intent_damage = 8
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "attacks"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	
	speak = list("For our kin!", "This will be a good hunt.", "The gods look upon me today.")
	speak_emote = list("says")
	speak_chance = 1
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	
	faction = list("Tribe")
	a_intent = INTENT_HARM
	status_flags = CANPUSH
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee - glaive fighter
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/tribe/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/tribe/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

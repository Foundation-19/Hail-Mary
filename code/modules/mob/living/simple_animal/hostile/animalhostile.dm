/*Common East Coast hostile critters -Pebbles
- Ghoul Rotter		/mob/living/simple_animal/hostile/ghoulrotter
	Just trying to make a new ghoul sprite thats less ass
- Skolf				/mob/living/simple_animal/hostile/skolf
	Packs, pretty deadly to lightly armored people, dont place in low threat areas. Sort of glass cannons?

Uncommon critters
- Yao Guai 			/mob/living/simple_animal/hostile/yaoguai
	Really tough beast packing a punch. Must be dangerous to PA people.
- Aradnid			/mob/living/simple_animal/hostile/aradnid
	Injects rads. Only map near toxic sites.
- Scolopendra		/mob/living/simple_animal/hostile/scolopendra
	Tunnel critter, very fast, modest brute, high toxin damage, decently tough. Supposed to make narrow tunnels scary.

Stuff not supposed to be in East coast (to differentiate, give flavour. Less is more. Don't listen to Bethesda.)
- Cazador
- Feral dog (Coyotes)
- Geckos
- Nightstalkers

General thoughts: More traits possible to add? Like resists to energy weapons/ballistics? Armor so AP is useful? Ability
to produce smoke or slow down victims? Stuff like that added to a couple would be fun.
*/

/mob/living/simple_animal/hostile/ghoulrotter
	affix_pool_type = "ghoul"
	affix_chance = 4
	mob_armor = ARMOR_VALUE_GHOUL_NAKED
	name = "rotting ghoul"
	desc = "A bloated ghoul that has lost its mind and become aggressive."
	icon = 'icons/mob/humans/ghouls.dmi'
	icon_state = "ghoulrotter"
	icon_living = "ghoulrotter"
	icon_dead = "ghoulrotter_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = 1
	turns_per_move = 5
	speak_emote = list("growls")
	emote_see = list("screeches")
	a_intent = INTENT_HARM
	maxHealth = 80
	health = 80
	speed = 2.5
	harm_intent_damage = 8
	melee_damage_lower = 15
	melee_damage_upper = 20
	armour_penetration = 0.05
	damage_threshold_penetration_mob = 2
	attack_verb_simple = "claw"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 20
	gold_core_spawnable = HOSTILE_SPAWN
	faction = list("ghoul")
	decompose = TRUE
	sharpness = SHARP_EDGED //They need to cut their finger nails
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/human/ghoul = 2,
							/obj/item/stack/sheet/animalhide/human = 1,
							/obj/item/stack/sheet/bone = 1)
	emote_taunt_sound = list('sound/f13npc/ghoul/taunt.ogg')
	emote_taunt = list("gurgles", "stares")
	taunt_chance = 30
	aggrosound = list('sound/f13npc/ghoul/aggro1.ogg', 'sound/f13npc/ghoul/aggro2.ogg')
	idlesound = list('sound/f13npc/ghoul/idle.ogg')
	death_sound = 'sound/f13npc/ghoul/ghoul_death.ogg'


/mob/living/simple_animal/hostile/skolf
	affix_pool_type = "beast"
	affix_chance = 4
	mob_armor = ARMOR_VALUE_BEAST_HIDE
	name = "skull wolf"
	desc = "Half rotted by radiation, blind, hunting by smell and sound."
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	turns_per_move = 1
	response_help_simple = "pets"
	response_disarm_simple = "pushes aside"
	response_harm_simple = "kicks"
	maxHealth = 70
	health = 70
	faction = list("hostile", "wolf")
	environment_smash = 0
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 1, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 1,/obj/item/stack/sheet/bone = 1)
	melee_damage_lower = 20
	melee_damage_upper = 25
	armour_penetration = 0.05
	damage_threshold_penetration_mob = 2
	aggro_vision_range = 15
	attack_verb_simple = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	move_to_delay = 2
	speed = 2.5
	emote_taunt_sound = list('sound/f13npc/dog/dog_charge1.ogg', 'sound/f13npc/dog/dog_charge2.ogg', 'sound/f13npc/dog/dog_charge3.ogg', 'sound/f13npc/dog/dog_charge4.ogg', 'sound/f13npc/dog/dog_charge5.ogg', 'sound/f13npc/dog/dog_charge6.ogg', 'sound/f13npc/dog/dog_charge7.ogg',)
	emote_taunt = list("growls", "barks", "snarls")
	taunt_chance = 30
	aggrosound = list('sound/f13npc/dog/dog_alert1.ogg', 'sound/f13npc/dog/dog_alert2.ogg', 'sound/f13npc/dog/dog_alert3.ogg')
	idlesound = list('sound/f13npc/dog/dog_bark1.ogg', 'sound/f13npc/dog/dog_bark2.ogg', 'sound/f13npc/dog/dog_bark3.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'


// Uncommon beasts

/mob/living/simple_animal/hostile/yaoguai
	affix_pool_type = "beast"
	affix_chance = 5
	mob_armor = ARMOR_VALUE_YAOGUAI
	name = "Yao Guai"
	desc = "Radiation has caused the brown bear to lose its pelt, grow large with ulcers and a rage fueled by agony. The chinese name for them has stuck."
	icon_gib = null
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 0
	turns_per_move = 5
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4, /obj/item/stack/sheet/sinew = 2, /obj/item/stack/sheet/bone = 2)
	butcher_results = list(/obj/item/clothing/head/f13/stalkerpelt = 1)
	butcher_difficulty = 3
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "bites"
	emote_taunt = list("growls")
	taunt_chance = 30
	speed = 1
	maxHealth = 350
	health = 350
	harm_intent_damage = 8
	obj_damage = 15
	melee_damage_lower = 20
	melee_damage_upper = 45
	armour_penetration = 0.25
	damage_threshold_penetration_mob = 8
	attack_verb_simple = "bites"
	attack_sound = 'sound/creatures/nightstalker_bite.ogg'
	speak_emote = list("growls")
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	faction = list("yaoguai") // was list("gecko")
	gold_core_spawnable = HOSTILE_SPAWN
	a_intent = INTENT_HARM

//Want to make these cause like 100 rads or so per bite plus their damage, maybe a little less. Instead of toxins. Remove comment if able to solve it.
/mob/living/simple_animal/hostile/aradnid
	affix_pool_type = "venomous"
	affix_chance = 4
	mob_armor = ARMOR_VALUE_ARADNID
	name = "aradnid"
	desc = "Deeply disturbing creature, they can only consume radiated meat and drag their prey to contaminated areas to tenderize them."
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	speak_emote = list("chitters")
	emote_hear = list("chitters")
	speak_chance = 5
	turns_per_move = 5
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/spider = 2, /obj/item/reagent_containers/food/snacks/spiderleg = 8)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	maxHealth = 150
	health = 150
	obj_damage = 60
	melee_damage_lower = 15
	melee_damage_upper = 25
	armour_penetration = 0.05
	damage_threshold_penetration_mob = 2
	faction = list("spiders")
	pass_flags = PASSTABLE
	move_to_delay = 6
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	unique_name = 1
	gold_core_spawnable = HOSTILE_SPAWN
	see_in_dark = 4
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	footstep_type = FOOTSTEP_MOB_CLAW
	has_field_of_vision = FALSE // 360° vision.


/mob/living/simple_animal/hostile/aradnid/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.apply_effect(20, EFFECT_IRRADIATE, 0) // was polonium; real radiation, as the design note asked




/mob/living/simple_animal/hostile/scolopendra
	affix_pool_type = "venomous"
	affix_chance = 4
	move_to_delay = 2
	mob_armor = ARMOR_VALUE_SCOLOPENDRA
	name = "Scolopendra"
	desc = "The clicking of chitin and multitudes of legs is all you hear before the huge centipede rushes in to catch its prey."
	icon_gib = null
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 0
	turns_per_move = 5
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4, /obj/item/stack/sheet/sinew = 2, /obj/item/stack/sheet/bone = 2)
	butcher_results = list(/obj/item/clothing/head/f13/stalkerpelt = 1)
	butcher_difficulty = 3
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "bites"
	emote_taunt = list("growls")
	taunt_chance = 30
	speed = 2 // was 4
	maxHealth = 300
	health = 300
	harm_intent_damage = 8
	obj_damage = 15
	melee_damage_lower = 15
	melee_damage_upper = 25
	armour_penetration = 0.1
	damage_threshold_penetration_mob = 4
	attack_verb_simple = "bites"
	attack_sound = 'sound/creatures/nightstalker_bite.ogg'
	speak_emote = list("growls")
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	faction = list("scolopendra") // was list("gecko")
	gold_core_spawnable = HOSTILE_SPAWN
	a_intent = INTENT_HARM


/mob/living/simple_animal/hostile/scolopendra/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 20)

// ============================================================
// SKOLF ALPHA
// Pack leader. Tougher, calls the pack on aggro (same backup call the wolves use).
// ============================================================

/mob/living/simple_animal/hostile/skolf/alpha
	name = "skolf alpha"
	desc = "A bigger, heavier skull wolf with more bone showing than hide. The rest of the pack takes its cue from this one."
	color = "#c9b8a0"
	maxHealth = 110
	health = 110
	melee_damage_lower = 22
	melee_damage_upper = 30
	armour_penetration = 0.1
	damage_threshold_penetration_mob = 4

/mob/living/simple_animal/hostile/skolf/alpha/Initialize(mapload)
	. = ..()
	resize = 1.15
	update_transform()

/mob/living/simple_animal/hostile/skolf/alpha/Aggro()
	. = ..()
	if(!ckey)
		summon_backup(10)

// ============================================================
// SKOLF RABID
// Glass cannon. Very fast, very fragile, bites open wounds. Never retreats.
// ============================================================

/mob/living/simple_animal/hostile/skolf/rabid
	name = "rabid skolf"
	desc = "A skull wolf in the last stages of sickness, foaming and thrashing. It has stopped caring whether it survives."
	color = "#b36b6b"
	maxHealth = 45
	health = 45
	move_to_delay = 1.5
	melee_damage_lower = 18
	melee_damage_upper = 26
	armour_penetration = 0.05
	damage_threshold_penetration_mob = 2
	sharpness = SHARP_EDGED
	wound_bonus = 20
	bare_wound_bonus = 25

// ============================================================
// YAO GUAI - shared grief response
// When a cub dies, adult yao guai nearby go into a short fury: faster and harder hitting.
// Defined on the base type so the matriarch and scarred variants react too.
// ============================================================

/mob/living/simple_animal/hostile/yaoguai/var/cub_fury_active = FALSE

/mob/living/simple_animal/hostile/yaoguai/proc/cub_fury(duration = 10 SECONDS)
	if(stat == DEAD || QDELETED(src) || cub_fury_active)
		return
	cub_fury_active = TRUE
	visible_message(span_danger("\The [src] roars in grief and fury!"))
	melee_damage_lower = round(melee_damage_lower * 1.25)
	melee_damage_upper = round(melee_damage_upper * 1.25)
	move_to_delay = max(1, move_to_delay - 1)
	addtimer(CALLBACK(src, PROC_REF(end_cub_fury)), duration)

/mob/living/simple_animal/hostile/yaoguai/proc/end_cub_fury()
	if(QDELETED(src))
		return
	cub_fury_active = FALSE
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	move_to_delay = initial(move_to_delay)

// ============================================================
// YAO GUAI CUB
// Small and weak alone. Its death sends nearby adults into a fury.
// ============================================================

/mob/living/simple_animal/hostile/yaoguai/cub
	name = "Yao Guai cub"
	desc = "A half-grown yao guai, patchy and thin, already surprisingly strong for its size. Its mother is rarely far."
	mob_armor = ARMOR_VALUE_BEAST_HIDE
	maxHealth = 80
	health = 80
	melee_damage_lower = 10
	melee_damage_upper = 18
	armour_penetration = 0
	damage_threshold_penetration_mob = 0
	butcher_results = list()
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 2, /obj/item/stack/sheet/bone = 1)

/mob/living/simple_animal/hostile/yaoguai/cub/Initialize(mapload)
	. = ..()
	resize = 0.6
	update_transform()

/mob/living/simple_animal/hostile/yaoguai/cub/death(gibbed)
	. = ..()
	for(var/mob/living/simple_animal/hostile/yaoguai/Y in oview(7, src))
		if(Y != src)
			Y.cub_fury()

// ============================================================
// YAO GUAI MATRIARCH
// Rare. Must be dangerous to power armor: high AP and DT penetration (set in the pen pass),
// stronger hide, and a roar on aggro that shakes screens and calls nearby yao guai.
// ============================================================

/mob/living/simple_animal/hostile/yaoguai/matriarch
	name = "Yao Guai matriarch"
	desc = "An enormous yao guai, scarred from decades of fights. When it roars, the rest of the pack comes running."
	mob_armor = ARMOR_VALUE_YAOGUAI_MATRIARCH
	maxHealth = 600
	health = 600
	melee_damage_lower = 28
	melee_damage_upper = 55
	armour_penetration = 0.35
	damage_threshold_penetration_mob = 10
	obj_damage = 30
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	var/roar_range = 7

/mob/living/simple_animal/hostile/yaoguai/matriarch/Initialize(mapload)
	. = ..()
	resize = 1.2
	update_transform()

/mob/living/simple_animal/hostile/yaoguai/matriarch/Aggro()
	. = ..()
	if(ckey)
		return
	visible_message(span_danger("\The [src] lets out a thunderous roar!"))
	playsound(src, 'sound/f13npc/deathclaw/aggro1.ogg', 100, TRUE, 10) // placeholder roar
	for(var/mob/living/carbon/human/H in view(roar_range, src))
		shake_camera(H, 3, 2)
	summon_backup(12)

// ============================================================
// SCARRED YAO GUAI
// Thick scar-tissue plates. Slower, but bullets do far less: AP and heavy rounds matter.
// ============================================================

/mob/living/simple_animal/hostile/yaoguai/scarred
	armour_penetration = 0.25
	damage_threshold_penetration_mob = 8
	name = "scarred Yao Guai"
	desc = "A yao guai whose hide has healed over in thick, knotted plates of scar tissue. Bullets seem to slow it more than hurt it."
	mob_armor = ARMOR_VALUE_YAOGUAI_SCARRED
	speed = 1.5
	maxHealth = 350
	health = 350
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS

// ============================================================
// ARADNID BROODMOTHER
// Nest boss. Slow, tougher bite, spawns hatchlings. Same spawner component as the
// mirelurk queen and nesting deathclaw. Stops spawning when she dies.
// NOTE: the base aradnid has no Initialize() of its own, so this one is safe.
// NOTE: dragging downed prey toward radiation (design doc idea) is not implemented, it needs
// movement AI I cannot see.
// ============================================================

/mob/living/simple_animal/hostile/aradnid/broodmother
	name = "aradnid broodmother"
	desc = "A swollen, pale aradnid dragging an egg sac that glows faintly. Smaller ones skitter out from under it."
	mob_armor = ARMOR_VALUE_ARADNID
	maxHealth = 300
	health = 300
	move_to_delay = 7
	melee_damage_lower = 20
	melee_damage_upper = 30
	armour_penetration = 0.1
	damage_threshold_penetration_mob = 4
	unique_name = 0
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	var/max_hatchlings = 3
	var/hatchling_types = list(/mob/living/simple_animal/hostile/aradnid_hatchling)
	var/hatchling_spawn_time = 30 SECONDS
	var/hatchling_spawn_text = "skitters out from under"

/mob/living/simple_animal/hostile/aradnid/broodmother/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/spawner, hatchling_types, hatchling_spawn_time, faction, hatchling_spawn_text, max_hatchlings, _range = 5)

/mob/living/simple_animal/hostile/aradnid/broodmother/death(gibbed)
	RemoveComponentByType(/datum/component/spawner)
	. = ..()

/mob/living/simple_animal/hostile/aradnid/broodmother/Destroy()
	RemoveComponentByType(/datum/component/spawner)
	. = ..()

// ============================================================
// ARADNID HATCHLING
// Separate (sibling) type, not a child of aradnid, so it does not inherit the full-strength
// radiation bite. Weak swarm bug, tiny dose.
// ============================================================

/mob/living/simple_animal/hostile/aradnid_hatchling
	name = "aradnid hatchling"
	desc = "A foot-long pale spider-thing. Alone it is a nuisance. In numbers, it is not."
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	mob_armor = ARMOR_VALUE_ZERO
	speak_emote = list("chitters")
	emote_hear = list("chitters")
	speak_chance = 5
	turns_per_move = 5
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	maxHealth = 25
	health = 25
	obj_damage = 10
	melee_damage_lower = 5
	melee_damage_upper = 10
	armour_penetration = 0
	damage_threshold_penetration_mob = 0
	faction = list("spiders")
	pass_flags = PASSTABLE
	move_to_delay = 3
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	gold_core_spawnable = HOSTILE_SPAWN
	see_in_dark = 4
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	footstep_type = FOOTSTEP_MOB_CLAW
	has_field_of_vision = FALSE

/mob/living/simple_animal/hostile/aradnid_hatchling/Initialize(mapload)
	. = ..()
	resize = 0.5
	update_transform()

/mob/living/simple_animal/hostile/aradnid_hatchling/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.apply_effect(5, EFFECT_IRRADIATE, 0)

// ============================================================
// SCOLOPENDRA GIANT
// Tunnel boss. Hidden until it reveals itself, venom builds up with repeated bites
// (stacks naturally because the reagent accumulates in the victim).
// ============================================================

/mob/living/simple_animal/hostile/scolopendra/giant
	name = "giant Scolopendra"
	desc = "A centipede the length of a truck, flowing through the tunnel as if the walls were not there. You hear it long before you see it."
	mob_armor = ARMOR_VALUE_SCOLOPENDRA
	color = "#7a4a3a"
	maxHealth = 450
	health = 450
	melee_damage_lower = 20
	melee_damage_upper = 32
	armour_penetration = 0.2
	damage_threshold_penetration_mob = 6
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	var/cloak_alpha = 110

/mob/living/simple_animal/hostile/scolopendra/giant/Initialize(mapload)
	. = ..()
	alpha = cloak_alpha
	resize = 1.2
	update_transform()

/mob/living/simple_animal/hostile/scolopendra/giant/Aggro()
	. = ..()
	alpha = 255

/mob/living/simple_animal/hostile/scolopendra/giant/LoseTarget()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(recloak)), 5 SECONDS)

/mob/living/simple_animal/hostile/scolopendra/giant/proc/recloak()
	if(QDELETED(src) || stat == DEAD || target)
		return
	alpha = cloak_alpha

/mob/living/simple_animal/hostile/scolopendra/giant/death(gibbed)
	alpha = 255
	. = ..()

// ============================================================
// SCOLOPENDRA YOUNG
// Narrow-tunnel scare: fast, fragile, comes in groups. Sibling type (not a child of
// scolopendra) so it does not inherit the full 20-unit toxin bite.
// ============================================================

/mob/living/simple_animal/hostile/scolopendra_young
	name = "young Scolopendra"
	desc = "A forearm-long centipede, all legs and speed. They come in clusters."
	icon_gib = null
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_ZERO
	speak_chance = 0
	turns_per_move = 5
	response_help_simple = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple = "bites"
	speed = 2
	move_to_delay = 2
	maxHealth = 60
	health = 60
	harm_intent_damage = 8
	obj_damage = 10
	melee_damage_lower = 8
	melee_damage_upper = 14
	armour_penetration = 0
	damage_threshold_penetration_mob = 0
	attack_verb_simple = "bites"
	attack_sound = 'sound/creatures/nightstalker_bite.ogg'
	speak_emote = list("clicks")
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	faction = list("scolopendra")
	pass_flags = PASSTABLE
	gold_core_spawnable = HOSTILE_SPAWN
	a_intent = INTENT_HARM

/mob/living/simple_animal/hostile/scolopendra_young/Initialize(mapload)
	. = ..()
	resize = 0.6
	update_transform()

/mob/living/simple_animal/hostile/scolopendra_young/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 8)

// ============================================================
// GHOUL ROTTER BLOATER
// Slow, swollen, ruptures into toxic gas when killed. Kill it from range.
// ============================================================

/mob/living/simple_animal/hostile/ghoulrotter/bloater
	name = "bloated rotting ghoul"
	desc = "A rotter swollen with gas, skin stretched thin and wet. It does not look like it will survive being hit."
	color = "#a9b583"
	maxHealth = 100
	health = 100
	speed = 3.5
	melee_damage_lower = 12
	melee_damage_upper = 18
	armour_penetration = 0.05
	damage_threshold_penetration_mob = 2

/mob/living/simple_animal/hostile/ghoulrotter/bloater/Initialize(mapload)
	. = ..()
	resize = 1.15
	update_transform()

/mob/living/simple_animal/hostile/ghoulrotter/bloater/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	if(!T)
		return
	visible_message(span_danger("\The [src] ruptures, releasing a cloud of rancid gas!"))
	playsound(T, 'sound/effects/splat.ogg', 75, TRUE)
	for(var/mob/living/carbon/human/H in view(2, T))
		H.reagents.add_reagent(/datum/reagent/toxin, 15)

// ============================================================
// GHOUL ROTTER CRAWLER
// Low, fast ambusher. Fragile, slips under tables.
// ============================================================

/mob/living/simple_animal/hostile/ghoulrotter/crawler
	name = "crawling ghoul"
	desc = "A rotter that lost the use of its legs and learned to move without them. It is fast, and low, and very hard to see coming."
	color = "#8c8c78"
	maxHealth = 50
	health = 50
	speed = 1.5
	pass_flags = PASSTABLE
	melee_damage_lower = 12
	melee_damage_upper = 18
	armour_penetration = 0
	damage_threshold_penetration_mob = 0

/mob/living/simple_animal/hostile/ghoulrotter/crawler/Initialize(mapload)
	. = ..()
	resize = 0.75
	update_transform()

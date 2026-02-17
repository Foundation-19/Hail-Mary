// In this document: Trogs, Spore Carriers, Tunnelers, Blind One

/////////////
// TROGS //
/////////////

// BASE TROG
/mob/living/simple_animal/hostile/trog
	name = "trog"
	desc = "A human who has mutated and regressed back to a primal, cannibalistic state. Rumor says they're poisonous as well. Want to find out?"
	icon = 'icons/fallout/mobs/monsters/tunnelers.dmi'
	icon_state = "troglodyte"
	icon_living = "troglodyte"
	icon_dead = "trog_dead"
	
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	
	maxHealth = 40
	health = 40
	speed = 2
	move_to_delay = 3
	turns_per_move = 5
	
	melee_damage_lower = 5
	melee_damage_upper = 12
	harm_intent_damage = 5
	obj_damage = 30
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	waddle_amount = 2
	waddle_up_time = 1
	waddle_side_time = 1
	
	speak_emote = list("growls")
	emote_see = list("screeches")
	attack_verb_simple = "lunges at"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 20
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/human = 2,
		/obj/item/stack/sheet/animalhide/human = 1,
		/obj/item/stack/sheet/bone = 1
	)
	
	faction = list("trog")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee - swarm ambusher
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/trog/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/trog/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// SPORE CARRIER - fungal zombie
/mob/living/simple_animal/hostile/trog/sporecarrier
	name = "spore carrier"
	desc = "A victim of the beauveria mordicana fungus. This corpse's sole purpose is to spread its spores."
	icon_state = "spore_carrier"
	icon_living = "spore_carrier"
	icon_dead = "spore_dead"
	
	maxHealth = 80
	health = 80
	
	melee_damage_lower = 10
	melee_damage_upper = 25
	
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 0
	
	faction = list("plants")
	
	guaranteed_butcher_results = list(/obj/item/stack/sheet/bone = 1)
	
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/trog/sporecarrier/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/spore_toxin, 2)

/mob/living/simple_animal/hostile/trog/sporecarrier/death(gibbed)
	// Release spores on death
	if(!gibbed)
		visible_message(span_warning("[src]'s body ruptures, releasing a cloud of spores!"))
		var/datum/effect_system/smoke_spread/chem/S = new
		S.set_up(1, get_turf(src))
		S.start()
	. = ..()

///////////////
// TUNNELERS //
///////////////

// BASE TUNNELER - deadly swarm creature
/mob/living/simple_animal/hostile/trog/tunneler
	name = "tunneler"
	desc = "A mutated creature that is sensitive to light, but can swarm and kill even Deathclaws."
	icon_state = "tunneler"
	icon_living = "tunneler"
	icon_dead = "tunneler_dead"
	
	mob_armor = ARMOR_VALUE_TUNNELER
	
	maxHealth = 144
	health = 144
	speed = 1
	
	melee_damage_lower = 18
	melee_damage_upper = 32
	armour_penetration = 0.25
	obj_damage = 150
	
	see_in_dark = 8
	
	attack_sound = 'sound/weapons/bladeslice.ogg'
	death_sound = 'sound/f13npc/ghoul/ghoul_death.ogg'
	
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = -1, CLONE = 0, STAMINA = 0, OXY = 0)  // Immune to toxins
	
	faction = list("tunneler")
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/bone = 1,
		/obj/item/stack/sheet/sinew = 1
	)
	
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/trog/tunneler/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/trog/tunneler/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 5)

// BLIND ONE - boss tunneler
/mob/living/simple_animal/hostile/trog/tunneler/blindone
	name = "Blind One"
	desc = "A...tunneler? Her scales reflect the light oddly, almost making her transparent, but her eyes are solid. She moves blindingly quickly, darting in and out of view despite her size. Overfilled, swelling venom-sacs line her throat."
	icon_state = "blindone"
	icon_living = "blindone"
	icon_dead = "trog_dead"
	
	mob_armor = ARMOR_VALUE_DEATHCLAW_MOTHER
	
	gender = FEMALE
	alpha = 150  // Semi-transparent
	
	maxHealth = 150
	health = 150
	speed = 1
	
	melee_damage_lower = 18
	melee_damage_upper = 40
	obj_damage = 30  // Reduced from 150
	
	vision_range = 9
	aggro_vision_range = 18
	has_field_of_vision = FALSE  // 360 degree vision
	
	speak_emote = list("mumbles incoherently")
	attack_sound = 'sound/hallucinations/veryfar_noise.ogg'
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	despawns_when_lonely = FALSE
	
	// Rage mode at low health
	low_health_threshold = 0.3
	var/color_rage = "#FF3333"

/mob/living/simple_animal/hostile/trog/tunneler/blindone/Initialize()
	. = ..()
	resize = 1.3
	update_transform()

/mob/living/simple_animal/hostile/trog/tunneler/blindone/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(12)
	if(!ckey)
		visible_message(span_danger("[src] lets out an otherworldly screech!"))

/mob/living/simple_animal/hostile/trog/tunneler/blindone/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin, 3)
		H.reagents.add_reagent(/datum/reagent/toxin/venom, 5)
		H.reagents.add_reagent(/datum/reagent/toxin/mindbreaker, 3)

// RAGE MODE - Blind One becomes faster and more aggressive
/mob/living/simple_animal/hostile/trog/tunneler/blindone/make_low_health()
	visible_message(span_danger("[src] writhes in pain, moving with renewed fury!"))
	playsound(src, 'sound/hallucinations/veryfar_noise.ogg', 100, 1)
	alpha = 100  // More transparent
	speed *= 0.75  // Faster
	melee_damage_lower = round(melee_damage_lower * 1.3)
	melee_damage_upper = round(melee_damage_upper * 1.3)
	armour_penetration = 0.35  // Increased from 0.25
	is_low_health = TRUE

/mob/living/simple_animal/hostile/trog/tunneler/blindone/make_high_health()
	visible_message(span_notice("[src]'s movements slow slightly."))
	alpha = initial(alpha)
	speed = initial(speed)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	armour_penetration = initial(armour_penetration)
	is_low_health = FALSE

// TUNNELER SWARM - weak but numerous
/mob/living/simple_animal/hostile/trog/tunneler/swarm
	name = "tunneler spawn"
	desc = "A young tunneler, still developing its deadly capabilities."
	
	maxHealth = 60
	health = 60
	speed = 0.8  // Faster
	
	melee_damage_lower = 10
	melee_damage_upper = 18
	armour_penetration = 0.1
	obj_damage = 50
	
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/trog/tunneler/swarm/Initialize()
	. = ..()
	resize = 0.7
	update_transform()

/mob/living/simple_animal/hostile/trog/tunneler/swarm/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(15)  // Call for MORE help

// REAGENTS
/datum/reagent/toxin/spore_toxin
	name = "Fungal Spores"
	description = "Airborne spores from the beauveria mordicana fungus."
	color = "#228B22"
	toxpwr = 0.5
	taste_description = "decay"

/datum/reagent/toxin/spore_toxin/on_mob_life(mob/living/M)
	if(volume >= 10)
		M.adjustToxLoss(2, 0)
		if(prob(5))
			to_chat(M, span_warning("You feel strange spores growing in your lungs..."))
	..()

// In this document: Texas Rattler
// Less powerful directly than deathclaws, but faster and venom is rough.

///////////////////
// TEXAS RATTLER //
///////////////////

/mob/living/simple_animal/hostile/texas_rattler
	name = "texas rattler"
	desc = "Keratin gleams and articulates over its massive sixty-foot body. Distended venom glands behind its upper pterygoid shudder and pressure deadly venom into its victims. A coil of thick muscle allows it to pounce. In layman's terms: don't get bit."
	icon = 'icons/mob/texas_rattler.dmi'
	icon_state = "texasrattler"
	icon_living = "texasrattler"
	icon_dead = "texasrattler_dead"
	icon_gib = "texasrattler_gib"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mob_armor = ARMOR_VALUE_ANTS  // Lightly armored - speed is the threat
	
	maxHealth = 150
	health = 150
	speed = -1  // Very fast
	move_to_delay = 2.5
	stat_attack = UNCONSCIOUS
	
	reach = 2  // Long striking range
	see_in_dark = 8
	
	melee_damage_lower = 18
	melee_damage_upper = 38
	
	speak_emote = list("hisses", "shakes its rattle")
	emote_hear = list("flicks its tongue")
	emote_taunt = list("flicks its tongue", "hisses and shakes its rattle")
	attack_verb_simple = "bites and constricts"
	
	speak_chance = 10
	taunt_chance = 25
	
	tastes = list("weird oil" = 5, "dirt" = 1)
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab = 4,
		/obj/item/stack/sheet/sinew = 3,
		/obj/item/stack/sheet/animalhide = 2
	)
	butcher_difficulty = 2
	
	faction = list("hostile", "wastebot", "ghoul", "cazador", "supermutant", "bighorner")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee - ambush predator with reach
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/texas_rattler/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/texas_rattler/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/texas_rattler/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.reagents.add_reagent(/datum/reagent/toxin/cazador_venom, 6)
		H.adjustStaminaLoss(7)

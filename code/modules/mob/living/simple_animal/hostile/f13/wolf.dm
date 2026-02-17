// In this document: Feral dogs, Alpha dogs, Wolves, Unique named dogs

///////////////
// FERAL DOG //
///////////////

// BASE FERAL DOG
/mob/living/simple_animal/hostile/wolf
	name = "feral dog"
	desc = "The dogs that survived the Great War are a larger, and tougher breed, size of a wolf.<br>This one seems to be severely malnourished and its eyes are bloody red."
	icon = 'icons/fallout/mobs/animals/dogs.dmi'
	icon_state = "dog_feral"
	icon_living = "dog_feral"
	icon_dead = "dog_feral_dead"
	icon_gib = "gib"
	
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	
	maxHealth = 50
	health = 50
	move_to_delay = 2.5
	turns_per_move = 1
	
	melee_damage_lower = 8
	melee_damage_upper = 16
	
	aggro_vision_range = 15
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/animalhide/wolf = 1,
		/obj/item/reagent_containers/food/snacks/meat/slab/wolf = 1,
		/obj/item/stack/sheet/bone = 1
	)
	
	waddle_amount = 2
	waddle_up_time = 0  // Dogs can't look up
	waddle_side_time = 1
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	
	response_help_simple = "pets"
	response_disarm_simple = "pushes aside"
	response_harm_simple = "kicks"
	attack_verb_simple = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	
	emote_taunt = list("growls", "barks", "snarls")
	emote_taunt_sound = list(
		'sound/f13npc/dog/dog_charge1.ogg',
		'sound/f13npc/dog/dog_charge2.ogg',
		'sound/f13npc/dog/dog_charge3.ogg',
		'sound/f13npc/dog/dog_charge4.ogg',
		'sound/f13npc/dog/dog_charge5.ogg',
		'sound/f13npc/dog/dog_charge6.ogg',
		'sound/f13npc/dog/dog_charge7.ogg'
	)
	taunt_chance = 30
	aggrosound = list(
		'sound/f13npc/dog/dog_alert1.ogg',
		'sound/f13npc/dog/dog_alert2.ogg',
		'sound/f13npc/dog/dog_alert3.ogg'
	)
	idlesound = list(
		'sound/f13npc/dog/dog_bark1.ogg',
		'sound/f13npc/dog/dog_bark2.ogg',
		'sound/f13npc/dog/dog_bark3.ogg'
	)
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'
	
	faction = list("hostile", "wolf")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 20  // Fast runner

	can_open_doors = FALSE
	can_open_airlocks = FALSE
	
	// Pure melee - rush and bite
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/wolf/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(8)

/mob/living/simple_animal/hostile/wolf/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// PLAYABLE FERAL DOG
/mob/living/simple_animal/hostile/wolf/playable
	maxHealth = 150
	health = 150
	see_in_dark = 8
	wander = FALSE
	anchored = FALSE
	del_on_death = FALSE
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

// ALPHA DOG - pack leader
/mob/living/simple_animal/hostile/wolf/alpha
	name = "alpha feral dog"
	desc = "The dogs that survived the Great War are a larger, and tougher breed, size of a wolf.<br>Wait... This one's a wolf!"
	icon_state = "dog_alpha"
	icon_living = "dog_alpha"
	icon_dead = "dog_alpha_dead"
	
	maxHealth = 70
	health = 70
	
	melee_damage_lower = 12
	melee_damage_upper = 28
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/animalhide/wolf = 2,
		/obj/item/reagent_containers/food/snacks/meat/slab/wolf = 3,
		/obj/item/stack/sheet/bone = 2
	)
	
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS

/mob/living/simple_animal/hostile/wolf/alpha/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(12)  // Alpha calls more backup

// PLAYABLE ALPHA DOG
/mob/living/simple_animal/hostile/wolf/alpha/playable
	see_in_dark = 8
	wander = FALSE
	anchored = FALSE
	del_on_death = FALSE
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

//////////
// WOLF //
//////////

// WOLF - proper wolf, tougher than a feral dog
/mob/living/simple_animal/hostile/wolf/cold
	name = "wolf"
	desc = "A mangy wolf."
	icon_state = "wolf"
	icon_living = "wolf"
	icon_dead = "wolf_dead"
	
	maxHealth = 100
	health = 100
	
	melee_damage_lower = 20
	melee_damage_upper = 28
	
	guaranteed_butcher_results = list(
		/obj/item/stack/sheet/animalhide/wolf = 2,
		/obj/item/reagent_containers/food/snacks/meat/slab/wolf = 3,
		/obj/item/stack/sheet/bone = 2
	)
	
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS

/////////////////
// UNIQUE DOGS //
/////////////////

// Unique named dogs - playable characters.
// Guerilla (Khan) = Rottweiler, Brutus/Lupa = German Shepherds, Sniffs-the-Earth = Sheepdog.

/mob/living/simple_animal/hostile/wolf/playable/rottweiler
	icon_state = "rottweiler"
	icon_living = "rottweiler"
	icon_dead = "rottweiler_dead"
	icon_gib = "gib"

/mob/living/simple_animal/hostile/wolf/playable/sheepdog
	icon_state = "tippen"
	icon_living = "tippen"
	icon_dead = "tippen_dead"
	icon_gib = "gib"

/mob/living/simple_animal/hostile/wolf/playable/shepherd
	icon_state = "shepherd"
	icon_living = "shepherd"
	icon_dead = "shepherd_dead"
	icon_gib = "gib"

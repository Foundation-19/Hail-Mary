//Fallout 13 canine directory

// Feral dog - visually some sort of mutt, at some point a coyote style dog can be made from the previous dog sprite, saved as coyote
/mob/living/simple_animal/hostile/wolf
	name = "feral dog"
	desc = "The dogs that survived the Great War are a larger, and tougher breed, size of a wolf.<br>This one seems to be severely malnourished and its eyes are bloody red."
	icon = 'icons/fallout/mobs/animals/dogs.dmi'
	icon_state = "dog_feral"
	icon_living = "dog_feral"
	icon_dead = "dog_feral_dead"
	icon_gib = "gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	turns_per_move = 1
	response_help_simple = "pets"
	response_disarm_simple = "pushes aside"
	response_harm_simple = "kicks"
	maxHealth = 50
	health = 50
	faction = list("hostile", "wolf", "critter-friend")
	environment_smash = 0
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 1, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 1,/obj/item/stack/sheet/bone = 1)
	melee_damage_lower = 8
	melee_damage_upper = 16
	aggro_vision_range = 15
	waddle_amount = 2
	waddle_up_time = 0 //Dogs can't look up ~TK
	waddle_side_time = 1
//	idle_vision_range = 7
	attack_verb_simple = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	move_to_delay = 2
	footstep_type = FOOTSTEP_MOB_BAREFOOT

	emote_taunt_sound = list('sound/f13npc/dog/dog_charge1.ogg', 'sound/f13npc/dog/dog_charge2.ogg', 'sound/f13npc/dog/dog_charge3.ogg', 'sound/f13npc/dog/dog_charge4.ogg', 'sound/f13npc/dog/dog_charge5.ogg', 'sound/f13npc/dog/dog_charge6.ogg', 'sound/f13npc/dog/dog_charge7.ogg',)
	emote_taunt = list("growls", "barks", "snarls")
	taunt_chance = 30
	aggrosound = list('sound/f13npc/dog/dog_alert1.ogg', 'sound/f13npc/dog/dog_alert2.ogg', 'sound/f13npc/dog/dog_alert3.ogg')
	idlesound = list('sound/f13npc/dog/dog_bark1.ogg', 'sound/f13npc/dog/dog_bark2.ogg', 'sound/f13npc/dog/dog_bark3.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'

/mob/living/simple_animal/hostile/wolf/playable
	health = 150
	maxHealth = 150
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = 0
	anchored = FALSE
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	footstep_type = FOOTSTEP_MOB_BAREFOOT

// Alpha dog
/mob/living/simple_animal/hostile/wolf/alpha
	name = "alpha feral dog"
	desc = "The dogs that survived the Great War are a larger, and tougher breed, size of a wolf.<br>Wait... This one's a wolf!"
	icon_state = "dog_alpha"
	icon_living = "dog_alpha"
	icon_dead = "dog_alpha_dead"
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 2, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 3,/obj/item/stack/sheet/bone = 2)
	maxHealth = 70
	health = 70
	melee_damage_lower = 12
	melee_damage_upper = 28
	footstep_type = FOOTSTEP_MOB_BAREFOOT
/mob/living/simple_animal/hostile/wolf/alpha/playable
	health = 70
	maxHealth = 70
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = 0
	anchored = FALSE
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	footstep_type = FOOTSTEP_MOB_BAREFOOT
// The first proper wolf, got to love just relabels without repathing.
/mob/living/simple_animal/hostile/wolf/cold
	name = "wolf"
	desc = "A mangy wolf."
	icon_state = "wolf"
	icon_living = "wolf"
	icon_dead = "wolf_dead"
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 2, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 3,/obj/item/stack/sheet/bone = 2)
	maxHealth = 100
	health = 100
	melee_damage_lower = 20
	melee_damage_upper = 28
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	
//Unique Dogs - Guerilla for Khans is a Rottweiler, Brutus and Lupa german shepherds, Sniffs-the-Earth a sheepdog.
//Feel free to move or add code for different behaviours like sleep, some unused sprites prepped for that sort of thing.

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

/mob/living/simple_animal/hostile/retaliate/legionhound
	name = "Legion Hound"
	desc = "War Hounds Hailing from Denver, This breed is slightly smaller then the popular Mongrel, But they're just as deadly, And don't leave around as much fur."
	icon = 'icons/fallout/mobs/animals/dogs.dmi'
	icon_state = "legiondog"
	icon_living = "legiondog"
	icon_dead = "legiondog_dead"
	icon_gib = "gib"
	can_ghost_into = TRUE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	turns_per_move = 3
	response_help_simple = "pet"
	response_disarm_simple = "push aside"
	response_harm_simple = "kick"
	maxHealth = 85
	health = 85
	faction = list(FACTION_LEGION)
	friends = list(FACTION_LEGION)
	environment_smash = 1
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 1, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 1,/obj/item/stack/sheet/bone = 1)
	melee_damage_lower = 8
	melee_damage_upper = 20
	aggro_vision_range = 25
	waddle_amount = 2
	waddle_up_time = 0 
	waddle_side_time = 1
	aggro_vision_range = 7
	attack_verb_simple = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	move_to_delay = 2
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	emote_taunt_sound = list('sound/f13npc/dog/dog_charge1.ogg', 'sound/f13npc/dog/dog_charge2.ogg', 'sound/f13npc/dog/dog_charge3.ogg', 'sound/f13npc/dog/dog_charge4.ogg', 'sound/f13npc/dog/dog_charge5.ogg', 'sound/f13npc/dog/dog_charge6.ogg', 'sound/f13npc/dog/dog_charge7.ogg',)
	emote_taunt = list("growls", "barks", "snarls")
	taunt_chance = 30
	aggrosound = list('sound/f13npc/dog/dog_alert1.ogg', 'sound/f13npc/dog/dog_alert2.ogg', 'sound/f13npc/dog/dog_alert3.ogg')
	idlesound = list('sound/f13npc/dog/dog_bark1.ogg', 'sound/f13npc/dog/dog_bark2.ogg', 'sound/f13npc/dog/dog_bark3.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'

/mob/living/simple_animal/hostile/retaliate/ncrguarddog
	name = "NCR Guard Dog"
	desc = "NCR Sheepdogs used for guard duty, Law enforcement, And escort missions, They are known for their intelligence and have worked alongside humans for thousands of years."
	icon = 'icons/fallout/mobs/animals/dogs.dmi'
	icon_state = "tippen"
	icon_living = "tippen"
	icon_dead = "tippen_dead"
	icon_gib = "gib"
	can_ghost_into = TRUE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	turns_per_move = 2
	response_help_simple = "pet"
	response_disarm_simple = "push aside"
	response_harm_simple = "kick"
	maxHealth = 70
	health = 70
	faction = list(FACTION_NCR)
	friends = list(FACTION_NCR)
	environment_smash = 1
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 1, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 1,/obj/item/stack/sheet/bone = 1)
	melee_damage_lower = 15
	melee_damage_upper = 20
	aggro_vision_range = 10
	waddle_amount = 3
	waddle_up_time = 0 
	waddle_side_time = 1
	aggro_vision_range = 7
	attack_verb_simple = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	move_to_delay = 2
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	emote_taunt_sound = list('sound/f13npc/dog/dog_charge1.ogg', 'sound/f13npc/dog/dog_charge2.ogg', 'sound/f13npc/dog/dog_charge3.ogg', 'sound/f13npc/dog/dog_charge4.ogg', 'sound/f13npc/dog/dog_charge5.ogg', 'sound/f13npc/dog/dog_charge6.ogg', 'sound/f13npc/dog/dog_charge7.ogg',)
	emote_taunt = list("growls", "barks", "snarls")
	taunt_chance = 30
	aggrosound = list('sound/f13npc/dog/dog_alert1.ogg', 'sound/f13npc/dog/dog_alert2.ogg', 'sound/f13npc/dog/dog_alert3.ogg')
	idlesound = list('sound/f13npc/dog/dog_bark1.ogg', 'sound/f13npc/dog/dog_bark2.ogg', 'sound/f13npc/dog/dog_bark3.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'

/mob/living/simple_animal/hostile/retaliate/ncrattackdog
	name = "NCR Attack Dog"
	desc = "NCR Attack Dogs are purpose-built for war, They were brought into the NCRA along with the rangers, Loyal and ferocious."
	icon = 'icons/fallout/mobs/animals/dogs.dmi'
	icon_state = "shepherd"
	icon_living = "shepherd"
	icon_dead = "shepherd_dead"
	icon_gib = "gib"
	can_ghost_into = TRUE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	turns_per_move = 3
	response_help_simple = "pet"
	response_disarm_simple = "push aside"
	response_harm_simple = "kick"
	maxHealth = 90
	health = 90
	faction = list(FACTION_NCR)
	friends = list(FACTION_NCR)
	environment_smash = 1
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/wolf = 1, /obj/item/reagent_containers/food/snacks/meat/slab/wolf = 1,/obj/item/stack/sheet/bone = 1)
	melee_damage_lower = 25
	melee_damage_upper = 30
	aggro_vision_range = 15
	waddle_amount = 2
	waddle_up_time = 0 
	waddle_side_time = 1
	aggro_vision_range = 7
	attack_verb_simple = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	move_to_delay = 2
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	emote_taunt_sound = list('sound/f13npc/dog/dog_charge1.ogg', 'sound/f13npc/dog/dog_charge2.ogg', 'sound/f13npc/dog/dog_charge3.ogg', 'sound/f13npc/dog/dog_charge4.ogg', 'sound/f13npc/dog/dog_charge5.ogg', 'sound/f13npc/dog/dog_charge6.ogg', 'sound/f13npc/dog/dog_charge7.ogg',)
	emote_taunt = list("growls", "barks", "snarls")
	taunt_chance = 30
	aggrosound = list('sound/f13npc/dog/dog_alert1.ogg', 'sound/f13npc/dog/dog_alert2.ogg', 'sound/f13npc/dog/dog_alert3.ogg')
	idlesound = list('sound/f13npc/dog/dog_bark1.ogg', 'sound/f13npc/dog/dog_bark2.ogg', 'sound/f13npc/dog/dog_bark3.ogg')
	death_sound = 'sound/f13npc/centaur/centaur_death.ogg'



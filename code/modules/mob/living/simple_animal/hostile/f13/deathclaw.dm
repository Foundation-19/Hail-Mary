/*IN THIS FILE:
-Deathclaws
*/

//Base Deathclaw
/mob/living/simple_animal/hostile/deathclaw
	name = "deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match."
	icon = 'icons/fallout/mobs/monsters/deathclaw.dmi'
	icon_state = "deathclaw"
	icon_living = "deathclaw"
	icon_dead = "deathclaw_dead"
	icon_gib = "deathclaw_gib"
	mob_armor = ARMOR_VALUE_DEATHCLAW_COMMON
	sentience_type = SENTIENCE_BOSS
	maxHealth = 500 // Reduced from 600
	health = 500
	stat_attack = UNCONSCIOUS
	reach = 2
	speed = 1
	obj_damage = 200
	melee_damage_lower = 30
	melee_damage_upper = 40
	footstep_type = FOOTSTEP_MOB_HEAVY
	move_to_delay = 2.75
	gender = MALE
	a_intent = INTENT_HARM
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	robust_searching = TRUE
	
	// Apex predator with excellent vision in low light
	has_low_light_vision = TRUE
	low_light_bonus = 4
	
	speak = list("ROAR!","Rawr!","GRRAAGH!","Growl!")
	speak_emote = list("growls", "roars")
	emote_hear = list("grumbles.","grawls.")
	emote_taunt = list("stares ferociously", "stomps")
	speak_chance = 10
	taunt_chance = 25
	
	tastes = list("a bad time" = 5, "dirt" = 1)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES  // Only structures, not walls normally
	var/color_mad = "#ffc5c5"
	see_in_dark = 8
	decompose = FALSE
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_EDGED
	
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/deathclaw = 4,
		/obj/item/stack/sheet/animalhide/deathclaw = 2,
		/obj/item/stack/sheet/bone = 4
	)
	
	response_help_simple  = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple   = "hits"
	attack_verb_simple = "claws"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	faction = list("deathclaw")
	gold_core_spawnable = HOSTILE_SPAWN
	move_resist = MOVE_FORCE_OVERPOWERING
	
	emote_taunt_sound = list('sound/f13npc/deathclaw/taunt.ogg')
	aggrosound = list('sound/f13npc/deathclaw/aggro1.ogg', 'sound/f13npc/deathclaw/aggro2.ogg')
	idlesound = list('sound/f13npc/deathclaw/idle.ogg')
	death_sound = 'sound/f13npc/deathclaw/death.ogg'
	
	low_health_threshold = 0.5
	despawns_when_lonely = FALSE
	
	// Charge mechanic vars
	var/charging = FALSE
	var/charge_cooldown = 0
	var/charge_cooldown_time = 10 SECONDS
	
	variation_list = list(
		MOB_RETREAT_DISTANCE_LIST(0, 0, 0, 3, 3),
		MOB_RETREAT_DISTANCE_CHANGE_PER_TURN_CHANCE(65),
		MOB_MINIMUM_DISTANCE_LIST(0, 0, 0, 1),
		MOB_MINIMUM_DISTANCE_CHANGE_PER_TURN_CHANCE(30),
	)

	// Z-movement
	can_z_move = TRUE
	can_climb_ladders = FALSE  // Too big!
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 20  // Fast pursuit

	can_open_doors = FALSE

	// Pure melee
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/deathclaw/playable
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	see_in_dark = 8
	wander = FALSE

// Override to ignore unconscious/dead targets
/mob/living/simple_animal/hostile/deathclaw/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

/// RAGE MODE - when going from high health to low health
/mob/living/simple_animal/hostile/deathclaw/make_low_health()
	visible_message(span_danger("[src] lets out a vicious roar and enters a berserker rage!!!"))
	playsound(src, 'sound/f13npc/deathclaw/aggro2.ogg', 100, 1, SOUND_DISTANCE(20))
	color = color_mad
	reach += 1
	speed *= 1.25
	obj_damage += 200
	melee_damage_lower = round(melee_damage_lower * 1.5)
	melee_damage_upper = round(melee_damage_upper * 1.4)
	see_in_dark += 8
	// RAGE MODE: Can now smash through walls!
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES | ENVIRONMENT_SMASH_WALLS | ENVIRONMENT_SMASH_RWALLS
	wound_bonus += 25
	bare_wound_bonus += 50
	sound_pitch = -50
	alternate_attack_prob = 75
	is_low_health = TRUE

/// Calming down when going from low health to high health
/mob/living/simple_animal/hostile/deathclaw/make_high_health()
	visible_message(span_danger("[src] calms down."))
	color = initial(color)
	reach = initial(reach)
	speed = initial(speed)
	obj_damage = initial(obj_damage)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	see_in_dark = initial(see_in_dark)
	environment_smash = initial(environment_smash)
	wound_bonus = initial(wound_bonus)
	bare_wound_bonus = initial(bare_wound_bonus)
	alternate_attack_prob = initial(alternate_attack_prob)
	sound_pitch = initial(sound_pitch)
	is_low_health = FALSE

/mob/living/simple_animal/hostile/deathclaw/AlternateAttackingTarget(atom/the_target)
	if(!ismovable(the_target))
		return
	var/atom/movable/throwee = the_target
	if(throwee.anchored)
		return
	var/atom/throw_target = get_ranged_target_turf(throwee, get_dir(src, the_target), rand(2,10), 4)
	throwee.safe_throw_at(throw_target, 10, 1, src, TRUE)
	playsound(get_turf(throwee), 'sound/effects/Flesh_Break_1.ogg', 50, 1)
	visible_message(span_danger("[src] hurls [the_target] across the room!"))

// CHARGE MECHANIC - trigger on getting shot
/mob/living/simple_animal/hostile/deathclaw/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		return
	
	// Chance to charge when shot, if not on cooldown
	if(!charging && world.time > charge_cooldown && prob(30))
		visible_message(span_danger("\The [src] roars in rage!"))
		addtimer(CALLBACK(src, PROC_REF(Charge)), 0.3 SECONDS)
	
	return ..()

/mob/living/simple_animal/hostile/deathclaw/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/deathclaw/AttackingTarget()
	if(!charging)
		return ..()

/mob/living/simple_animal/hostile/deathclaw/Goto(target, delay, minimum_distance)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/deathclaw/Move()
	if(is_low_health && health > 0)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()
	. = ..()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()

/mob/living/simple_animal/hostile/deathclaw/proc/Charge()
	if(!target)
		return
	
	var/turf/T = get_turf(target)
	if(!T || T == loc)
		return
	
	charging = TRUE
	charge_cooldown = world.time + charge_cooldown_time
	
	visible_message(span_danger("[src] charges with terrifying speed!"))
	DestroySurroundings()
	walk(src, 0)
	setDir(get_dir(src, T))
	
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 0.1 SECONDS)
	
	throw_at(T, get_dist(src, T), 2, src, FALSE, callback = CALLBACK(src, PROC_REF(charge_end)))

/mob/living/simple_animal/hostile/deathclaw/proc/charge_end(list/effects_to_destroy)
	charging = FALSE
	if(target)
		Goto(target, move_to_delay, minimum_distance)

/mob/living/simple_animal/hostile/deathclaw/Bump(atom/A)
	if(charging)
		if((isturf(A) || isobj(A)) && A.density)
			A.ex_act(EXPLODE_HEAVY)
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
			
			// Chance to die on wall impact if low health
			if(is_low_health && health < (maxHealth * 0.2) && prob(25))
				playsound(get_turf(src), 'sound/effects/Flesh_Break_2.ogg', 100, 1, ignore_walls = TRUE)
				visible_message(span_danger("[src] smashes into \the [A] with such force that it explodes in a violent spray of gore! Holy shit!"))
				gib()
				return
		DestroySurroundings()
	..()

/mob/living/simple_animal/hostile/deathclaw/throw_impact(atom/A)
	if(!charging)
		return ..()
	
	if(isliving(A))
		var/mob/living/L = A
		L.visible_message(span_danger("[src] slams into [L] with incredible force!"), span_userdanger("[src] slams into you!"))
		L.apply_damage(melee_damage_upper, BRUTE)
		playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, 1)
		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)
		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
		L.throw_at(throwtarget, 3, 2)
	
	charging = FALSE

// Mother deathclaw
/mob/living/simple_animal/hostile/deathclaw/mother
	name = "mother deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one is an angry mother."
	gender = FEMALE
	mob_armor = ARMOR_VALUE_DEATHCLAW_MOTHER
	maxHealth = 1000  // Reduced from 1500
	health = 1000
	stat_attack = CONSCIOUS
	melee_damage_lower = 25
	melee_damage_upper = 55
	color = rgb(95,104,94)
	color_mad = rgb(113, 105, 100)
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/deathclaw = 6,
		/obj/item/stack/sheet/animalhide/deathclaw = 3
	)

/mob/living/simple_animal/hostile/deathclaw/butter
	name = "butterclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one is...made out of butter?"
	icon_state = "deathclaw_butter"
	icon_living = "deathclaw_butter"
	icon_dead = "deathclaw_butter_dead"
	color_mad = rgb(133, 98, 87)
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/butter = 10,
		/obj/item/stack/sheet/animalhide/deathclaw = 3
	)

//Legendary Deathclaw
/mob/living/simple_animal/hostile/deathclaw/legendary
	name = "legendary deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one is a legendary enemy."
	mob_armor = ARMOR_VALUE_DEATHCLAW_MOTHER
	maxHealth = 1800 // Reduced from 2400
	health = 1800
	color = "#FFFF00"
	color_mad = rgb(133, 98, 87)
	stat_attack = CONSCIOUS
	melee_damage_lower = 25
	melee_damage_upper = 55

/mob/living/simple_animal/hostile/deathclaw/legendary/death(gibbed)
	var/turf/T = get_turf(src)
	if(prob(60))
		new /obj/item/melee/unarmed/deathclawgauntlet(T)
	. = ..()

//Power Armor Deathclaw - the tankiest deathclaw
/mob/living/simple_animal/hostile/deathclaw/power_armor
	name = "power armored deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. Someone had managed to put power armor on him."
	icon_state = "combatclaw"
	icon_living = "combatclaw"
	icon_dead = "combatclaw_dead"
	mob_armor = ARMOR_VALUE_DEATHCLAW_PA
	maxHealth = 2000 // Reduced from 3000
	health = 2000
	stat_attack = CONSCIOUS
	melee_damage_lower = 40
	melee_damage_upper = 60

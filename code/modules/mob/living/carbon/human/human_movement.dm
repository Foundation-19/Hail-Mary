// Sneak mode movement slowdown - makes player move 2x slower
/datum/movespeed_modifier/sneak_mode
	multiplicative_slowdown = 1 // 2x slower (base movement + 1 = 2x the delay)

/mob/living/carbon/human/get_movespeed_modifiers()
	var/list/considering = ..()
	if(HAS_TRAIT(src, TRAIT_IGNORESLOWDOWN))
		. = list()
		for(var/id in considering)
			var/datum/movespeed_modifier/M = considering[id]
			if(M.flags & IGNORE_NOSLOW || M.multiplicative_slowdown < 0)
				.[id] = M
		return
	return considering

/mob/living/carbon/human/movement_delay()
	. = ..()
	if(CHECK_MOBILITY(src, MOBILITY_STAND) && m_intent == MOVE_INTENT_RUN && (combat_flags & COMBAT_FLAG_SPRINT_ACTIVE))
		. -= calc_sprint_speed_mod_from_special()
	if(m_intent == MOVE_INTENT_WALK && HAS_TRAIT(src, TRAIT_SPEEDY_STEP))
		. -= 1.25
	if(HAS_TRAIT(src, TRAIT_SMUTANT))
		. += 0
	
	// Apply strength-based armor penalties to base movement
	if(istype(wear_suit))
		var/obj/item/clothing/suit/armor = wear_suit
		var/str_requirement = 0
		var/armor_type = ""
		var/is_penalized = FALSE
		
		if(armor.slowdown == ARMOR_SLOWDOWN_SALVAGE)
			str_requirement = 6
			armor_type = "salvaged plate"
			if(special_s < 6)
				. += 0.5
				is_penalized = TRUE
				
		else if(armor.slowdown == ARMOR_SLOWDOWN_PA)
			str_requirement = 4
			armor_type = "power armor frame"
			if(special_s < 4)
				. += 0.4
				is_penalized = TRUE
				
		else if(armor.slowdown == ARMOR_SLOWDOWN_HEAVY)
			str_requirement = 6
			armor_type = "heavy plating"
			if(special_s < 6)
				. += 0.4
				is_penalized = TRUE
				
		else if(armor.slowdown == ARMOR_SLOWDOWN_MEDIUM)
			str_requirement = 4
			armor_type = "combat armor"
			if(special_s < 4)
				. += 0.3
				is_penalized = TRUE
				
		else if(armor.slowdown == ARMOR_SLOWDOWN_LIGHT)
			str_requirement = 3
			armor_type = "light armor"
			if(special_s < 3)
				. += 0.3
				is_penalized = TRUE
		
		// Only warn if penalized AND haven't warned recently
		if(is_penalized && (last_armor_warning_time == 0 || world.time > last_armor_warning_time + 3000))
			last_armor_warning_time = world.time
			
			// Themed warning messages based on armor type
			var/message = ""
			switch(armor_type)
				if("salvaged plate")
					message = "<span class='warning'>The [armor] drags on you like a corpse. Your muscles scream. You need [str_requirement] STR to move like you're alive.</span>"
				if("power armor frame")
					message = "<span class='warning'>The [armor]'s servos whine uselessly without the strength to guide them. [str_requirement] STR would let the machine work with you, not against you.</span>"
				if("heavy plating")
					message = "<span class='warning'>Every step in the [armor] feels like dragging yourself out of a grave. [str_requirement] STR would make this wearable instead of a punishment.</span>"
				if("combat armor")
					message = "<span class='warning'>The [armor] fights you with every movement. Your frame can't quite fill it. [str_requirement] STR would let you wear this like it was meant to be worn.</span>"
				if("light armor")
					message = "<span class='warning'>Even this [armor] weighs you down. The straps dig in wrong. [str_requirement] STR and it'd sit right.</span>"
			
			if(message)
				to_chat(src, message)

	var/current_time = world.time
	var/fatigue_cap = 0.3

	if(special_a >= 7)
		fatigue_cap = 0.5

	if(current_time - last_move_time < 10)
		movement_fatigue = min(movement_fatigue + 0.05, fatigue_cap)
		last_move_time = current_time
	else
		movement_fatigue = max(movement_fatigue - 0.1, 0)
		last_move_time = current_time

	. += movement_fatigue

	if(special_a >= 7)
		. += 0
	else
		. += 0.2 // Standard slowdown

/mob/living/carbon/human/slip(knockdown_amount, obj/O, lube)
	if(HAS_TRAIT(src, TRAIT_NOSLIPALL))
		return 0
	if (!(lube & GALOSHES_DONT_HELP))
		if(HAS_TRAIT(src, TRAIT_NOSLIPWATER))
			return 0
		if(shoes && istype(shoes, /obj/item/clothing))
			var/obj/item/clothing/CS = shoes
			if (CS.clothing_flags & NOSLIP)
				return 0
	if (lube & SLIDE_ICE)
		if(shoes && istype(shoes, /obj/item/clothing))
			var/obj/item/clothing/CS = shoes
			if (CS.clothing_flags & NOSLIP_ICE)
				return FALSE
	return ..()

/mob/living/carbon/human/experience_pressure_difference(pressure_difference, direction, pressure_resistance_prob_delta = 0, throw_target)
	if(prob(pressure_difference * 2.5))
		playsound(src, 'sound/effects/space_wind.ogg', 50, 1)
	if(shoes && istype(shoes, /obj/item/clothing))
		var/obj/item/clothing/S = shoes
		if (S.clothing_flags & NOSLIP)
			return 0
	return ..()

/mob/living/carbon/human/mob_has_gravity()
	. = ..()
	if(!.)
		if(mob_negates_gravity())
			. = 1

/mob/living/carbon/human/mob_negates_gravity()
	return ((shoes && shoes.negates_gravity()) || (dna.species.negates_gravity(src)))

/mob/living/carbon/human/Move(NewLoc, direct)
	var/oldpseudoheight = pseudo_z_axis
	. = ..()
	for(var/datum/mutation/human/HM in dna.mutations)
		HM.on_move(NewLoc)
	if(. && (combat_flags & COMBAT_FLAG_SPRINT_ACTIVE) && !(movement_type & FLYING) && CHECK_ALL_MOBILITY(src, MOBILITY_MOVE|MOBILITY_STAND) && m_intent == MOVE_INTENT_RUN && has_gravity(loc) && (!pulledby || (pulledby.pulledby == src)))
		if(!HAS_TRAIT(src, TRAIT_FREESPRINT))
			doSprintLossTiles(1)
		if((oldpseudoheight - pseudo_z_axis) >= 8)
			to_chat(src, span_warning("You trip off of the elevated surface!"))
			for(var/obj/item/I in held_items)
				accident(I)
			DefaultCombatKnockdown(80)
	
	// Update vision cones when player moves in sneak mode
	if(. && sneaking)
		update_vision_cones() // Update vision cones when we move
	
	if(shoes)
		if(!lying && !buckled)
			if(loc == NewLoc)
				if(!has_gravity(loc))
					return
				var/obj/item/clothing/shoes/S = shoes

				//Bloody footprints
				var/turf/T = get_turf(src)
				if(S.bloody_shoes && S.bloody_shoes[S.blood_state])
					var/obj/effect/decal/cleanable/blood/footprints/oldFP = locate(/obj/effect/decal/cleanable/blood/footprints) in T
					if(oldFP && (oldFP.blood_state == S.blood_state && oldFP.color == S.last_blood_color))
						return
					S.bloody_shoes[S.blood_state] = max(0, S.bloody_shoes[S.blood_state] - BLOOD_LOSS_PER_STEP)
					var/obj/effect/decal/cleanable/blood/footprints/FP = new /obj/effect/decal/cleanable/blood/footprints(T)
					FP.blood_state = S.blood_state
					FP.entered_dirs |= dir
					FP.bloodiness = S.bloody_shoes[S.blood_state]
					if(S.last_bloodtype && S.last_blood_color)
						FP.blood_DNA[S.last_blood_DNA] = S.last_bloodtype
						if(!FP.blood_DNA["color"])
							FP.blood_DNA["color"] = S.last_blood_color
						else
							FP.blood_DNA["color"] = BlendRGB(FP.blood_DNA["color"], S.last_blood_color)
					FP.update_icon()
					update_inv_shoes()
				//End bloody footprints

				S.step_action()
	if(m_intent == MOVE_INTENT_RUN)
		src.handle_movement_recoil()

/mob/living/carbon/human/Process_Spacemove(movement_dir = 0, continuous_move) //Temporary laziness thing. Will change to handles by species reee.
	if(dna.species.space_move(src))
		return TRUE
	return ..()

/mob/living/carbon/human/Moved()
	. = ..()
	if(.)
		update_turf_movespeed(loc)
		if(HAS_TRAIT(src, TRAIT_NOHUNGER)) // Let's pretend this trait responds for everything
			set_thirst(THIRST_LEVEL_FULL)
		else if(thirst && stat != DEAD)
			var/loss = THIRST_FACTOR/10
			if(m_intent == MOVE_INTENT_RUN)
				loss *= 2
			adjust_thirst(-loss)

/mob/living/carbon/human/handle_movement_recoil()
	deltimer(recoil_reduction_timer)

	var/base_recoil = 1

	var/mob/living/carbon/human/H = src
	var/suit_stiffness = 0
	var/uniform_stiffness = 0
	if(H.wear_suit)
		suit_stiffness = H.wear_suit.stiffness
	if(H.w_uniform)
		uniform_stiffness = H.w_uniform.stiffness

	base_recoil += suit_stiffness + suit_stiffness * uniform_stiffness // Wearing it under actual armor, or anything too thick is extremely uncomfortable.

	add_recoil(base_recoil)

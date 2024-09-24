/obj/mecha/proc/get_armour_facing(relative_dir)
	switch(relative_dir)
		if(180) // BACKSTAB!
			return facing_modifiers[BACK_ARMOUR]
		if(0, 45) // direct or 45 degrees off
			return facing_modifiers[FRONT_ARMOUR]
	return facing_modifiers[SIDE_ARMOUR] //if its not a front hit or back hit then assume its from the side

/obj/mecha/proc/attack_dir_for_modules(relative_dir)
	if(relative_dir  > -45 && relative_dir < 45)
		return 1
	else if(relative_dir < -45 && relative_dir > -135)
		return 2
	else if(relative_dir > 45 && relative_dir < 135)
		return 3
	else if(relative_dir >= -180 && relative_dir <= 180)
		return 4

/obj/mecha/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0, atom/attacked_by)

	. = ..()
	if(. && obj_integrity > 0)
		spark_system.start()
		switch(damage_flag)
			if("fire")
				check_for_internal_damage(list(MECHA_INT_FIRE,MECHA_INT_TEMP_CONTROL))
			if("melee")
				check_for_internal_damage(list(MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH,MECHA_INT_CONTROL_LOST))
			else
				check_for_internal_damage(list(MECHA_INT_FIRE,MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH,MECHA_INT_CONTROL_LOST,MECHA_INT_SHORT_CIRCUIT))
		if(. >= 5 || prob(33))
			occupant_message(span_userdanger("Taking damage!"))
			var/integrity = obj_integrity*100/max_integrity
			if(. && integrity < 20)
				to_chat(occupant, "[icon2html(src, occupant)][span_userdanger("HULL DAMAGE CRITICAL!")]")
				playsound(loc, 'sound/mecha/mecha_critical.ogg', 40, 1, -1)
		log_append_to_last("Took [damage_amount] points of damage. Damage type: \"[damage_type]\".",1)

/obj/mecha/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	. = ..()
	if(!damage_amount)
		return 0
	var/booster_deflection_modifier = 1
	var/booster_damage_modifier = 1
	if(damage_flag == "bullet" || damage_flag == "laser" || damage_flag == "energy")
		for(var/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster/B in equipment)
			if(B.projectile_react())
//				booster_deflection_modifier = B.deflect_coeff
				booster_damage_modifier = B.damage_coeff
				break
	else if(damage_flag == "melee")
		for(var/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster/B in equipment)
			if(B.attack_react())
//				booster_deflection_modifier *= B.deflect_coeff
				booster_damage_modifier *= B.damage_coeff
				break

	if(attack_dir)
		var/facing_modifier = get_armour_facing(abs(dir2angle(dir) - dir2angle(attack_dir)))
			
		booster_damage_modifier /= facing_modifier
		booster_deflection_modifier *= facing_modifier
	if(prob(deflect_chance * booster_deflection_modifier) && damage_flag != "bomb")
		visible_message(span_danger("[src]'s armour deflects the attack!"))
		log_append_to_last("Armor saved.")
		return 0
	/*if(damage_flag == "bomb")
		. *= (booster_damage_modifier*1.25)*/
	if(.)
		. *= booster_damage_modifier


/obj/mecha/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	playsound(loc, 'sound/weapons/tap.ogg', 40, 1, -1)
	user.visible_message(span_danger("[user] hits [name]. Nothing happens"), null, null, COMBAT_MESSAGE_RANGE)
	mecha_log_message("Attack by hand/paw. Attacker - [user].", color="red")
	log_append_to_last("Armor saved.")

/obj/mecha/attack_paw(mob/user as mob)
	return attack_hand(user)


/obj/mecha/attack_alien(mob/living/user)
	mecha_log_message("Attack by alien. Attacker - [user].", color="red")
	playsound(src.loc, 'sound/weapons/slash.ogg', 100, 1)
	attack_generic(user, 15, BRUTE, "melee", 0)

/obj/mecha/attack_animal(mob/living/simple_animal/user)
	mecha_log_message("Attack by simple animal. Attacker - [user].", color="red")
	if(!user.melee_damage_upper && !user.obj_damage)
		user.emote("custom", message = "[user.friendly_verb_continuous] [src].")
		return 0
	else
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		log_combat(user, src, "attacked")
		var/animal_damage = rand(user.melee_damage_lower,user.melee_damage_upper)
		attack_generic(user, animal_damage, user.melee_damage_type, "melee")
		return 1


/obj/mecha/hulk_damage()
	return 15

/obj/mecha/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		mecha_log_message("Attack by hulk. Attacker - [user].", color="red")
		log_combat(user, src, "punched", "hulk powers")

/obj/mecha/blob_act(obj/structure/blob/B)
	take_damage(30, BRUTE, "melee", 0, get_dir(src, B), attacked_by = B)

/obj/mecha/attack_tk()
	return

/obj/mecha/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum) //wrapper
	mecha_log_message("Hit by [AM].", color="red")
	. = ..()


/obj/mecha/bullet_act(obj/item/projectile/Proj) //wrapper
	mecha_log_message("Hit by projectile. Type: [Proj.name]([Proj.flag]).", color="red")
	if(!(Proj.damage_type in list(BRUTE, BURN)))
		return BULLET_ACT_BLOCK	
	var/attack_dir = get_dir(src, Proj)
	var/facing_modifier = get_armour_facing(abs(dir2angle(dir) - dir2angle(attack_dir)))
	var/true_armor = 0
	if(armor.linebullet)
		true_armor = min(0,armor["linebullet"] * facing_modifier - Proj.armour_penetration - Proj.damage / 4)
	else if(armor.bullet)
		true_armor = min(0,armor["bullet"] * facing_modifier - Proj.armour_penetration - Proj.damage / 4)

	var/true_damage = Proj.damage * (1 - true_armor)
	if(prob(true_armor/2))
		Proj.setAngle(SIMPLIFY_DEGREES(Proj.Angle + rand(40,150)))
		return BULLET_ACT_FORCE_PIERCE
	if(true_damage < 1)
		return BULLET_ACT_BLOCK
	Proj.damage = true_damage
	var/modules_index = attack_dir_for_modules(dir2angle(attack_dir) - dir2angle(dir))
	for(var/i=1 to length(directional_comps[modules_index]))
		if(!prob(directional_comps[modules_index][1]))
			continue
		var/damage_mult = directional_comps[modules_index][2]
		var/ap_threshold = directional_comps[modules_index][3]
		var/armor_rating = directional_comps[modules_index][4]
		damage_mult = min(0.15,(Proj.damage + Proj.armour_penetration) / (Proj.damage + armor_rating))
		directional_comps[modules_index][4] -= damage_mult * Proj.damage
		take_damage(true_damage * damage_mult, Proj.damage_type, null, null, attack_dir, Proj.armour_penetration, Proj)
		if(Proj.armour_penetration < ap_threshold)
			return BULLET_ACT_BLOCK
		else
			Proj.armour_penetration -= ap_threshold

	if(prob(80) && occupant)
		. = occupant.bullet_act(Proj, Proj.def_zone)

	. = ..()

/obj/mecha/ex_act(severity, target)
	severity-- // MORE DAMAGE
	mecha_log_message("Affected by explosion of severity: [severity].", color="red")
	/*if(prob(deflect_chance))
		severity++
		log_append_to_last("Armor saved, changing severity to [severity].") NO BOMB REFLECTION*/
	. = ..()

/obj/mecha/contents_explosion(severity, target)
	severity++
	for(var/X in equipment)
		var/obj/item/mecha_parts/mecha_equipment/ME = X
		ME.ex_act(severity,target)
	for(var/Y in trackers)
		var/obj/item/mecha_parts/mecha_tracking/MT = Y
		MT.ex_act(severity, target)
	if(occupant)
		occupant.ex_act(severity,target)

/obj/mecha/handle_atom_del(atom/A)
	if(A == occupant)
		occupant = null
		icon_state = initial(icon_state)+"-open"
		setDir(dir_in)

/obj/mecha/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(get_charge())
		use_power(fuel_holder.reagents.total_volume*severity/100)
		take_damage(severity/3, BURN, "energy", 1)
	mecha_log_message("EMP detected", color="red")

	if(istype(src, /obj/mecha/combat))
		mouse_pointer = 'icons/mecha/mecha_mouse-disable.dmi'
		occupant?.update_mouse_pointer()
	if(!equipment_disabled && occupant) //prevent spamming this message with back-to-back EMPs
		to_chat(occupant, "<span=danger>Error -- Connection to equipment control unit has been lost.</span>")
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/mecha, restore_equipment)), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	equipment_disabled = 1

/obj/mecha/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature>max_temperature)
		mecha_log_message("Exposed to dangerous temperature.", color="red")
		take_damage(5, BURN, 0, 1)

/obj/mecha/attackby(obj/item/W as obj, mob/user as mob, params)

	if(istype(W, /obj/item/mmi))
		if(mmi_move_inside(W,user))
			to_chat(user, "[src]-[W] interface initialized successfully.")
		else
			to_chat(user, "[src]-[W] interface initialization failed.")
		return

	if(istype(W, /obj/item/mecha_ammo))
		ammo_resupply(W, user)
		return

	if(istype(W, /obj/item/mecha_parts/mecha_equipment))
		var/obj/item/mecha_parts/mecha_equipment/E = W
		spawn()
			if(E.can_attach(src))
				if(!user.temporarilyRemoveItemFromInventory(W))
					return
				E.attach(src)
				user.visible_message("[user] attaches [W] to [src].", span_notice("You attach [W] to [src]."))
			else
				to_chat(user, span_warning("You were unable to attach [W] to [src]!"))
		return
	if(W.GetID())
		if(add_req_access || maint_access)
			if(internals_access_allowed(user))
				var/obj/item/card/id/id_card
				if(istype(W, /obj/item/card/id))
					id_card = W
				else
					var/obj/item/pda/pda = W
					id_card = pda.id
				output_maintenance_dialog(id_card, user)
				return
			else
				to_chat(user, span_warning("Invalid ID: Access denied."))
		else
			to_chat(user, span_warning("Maintenance protocols disabled by operator."))
	else if(istype(W, /obj/item/wrench))
		if(state==1)
			state = 2
			to_chat(user, span_notice("You undo the securing bolts."))
		else if(state==2)
			state = 1
			to_chat(user, span_notice("You tighten the securing bolts."))
		return
	else if(istype(W, /obj/item/crowbar))
		if(state==2)
			state = 3
			to_chat(user, span_notice("You open the hatch to the power unit."))
		else if(state==3)
			state=2
			to_chat(user, span_notice("You close the hatch to the power unit."))
		return
	else if(istype(W, /obj/item/stack/cable_coil))
		if(state == 3 && (internal_damage & MECHA_INT_SHORT_CIRCUIT))
			if(W.use_tool(src, user, 0, 2))
				clearInternalDamage(MECHA_INT_SHORT_CIRCUIT)
				to_chat(user, span_notice("You replace the fused wires."))
			else
				to_chat(user, span_warning("You need two lengths of cable to fix this mech!"))
		return
	else if(istype(W, /obj/item/screwdriver) && user.a_intent != INTENT_HARM)
		if(internal_damage & MECHA_INT_TEMP_CONTROL)
			clearInternalDamage(MECHA_INT_TEMP_CONTROL)
			to_chat(user, span_notice("You repair the damaged temperature controller."))
		else if(state==3 && fuel_holder)
			fuel_holder.forceMove(loc)
			fuel_holder = null
			state = 4
			to_chat(user, span_notice("You unsecure the fuel tank."))
			mecha_log_message("Fuel tank removed")
		else if(state==4 && fuel_holder)
			state=3
			to_chat(user, span_notice("You secure the fuel_tank in place."))
		return

	else if(istype(W, /obj/item/reagent_containers/fuel_tank))
		if(state==4)
			if(!fuel_holder)
				if(!user.transferItemToLoc(W, src))
					return
				var/obj/item/reagent_containers/fuel_tank/C = W
				to_chat(user, span_notice("You install the fuel tank."))
				fuel_holder = C
				mecha_log_message("Fuel Tank installed")
			else
				to_chat(user, span_notice("There's already a fuel tank installed."))
		return

	else if(istype(W, /obj/item/weldingtool) && user.a_intent != INTENT_HARM)
		user.DelayNextAction(CLICK_CD_MELEE)
		if(obj_integrity < max_integrity)
			if(W.use_tool(src, user, 0, volume=50, amount=1))
				if (internal_damage & MECHA_INT_TANK_BREACH)
					clearInternalDamage(MECHA_INT_TANK_BREACH)
					to_chat(user, span_notice("You repair the damaged gas tank."))
				else
					user.visible_message(span_notice("[user] repairs some damage to [name]."), span_notice("You repair some damage to [src]."))
					obj_integrity += min(10, max_integrity-obj_integrity)
					if(obj_integrity == max_integrity)
						to_chat(user, span_notice("It looks to be fully repaired now."))
			return 1
		else
			to_chat(user, span_warning("The [name] is at full integrity!"))
		return 1

	else if(istype(W, /obj/item/mecha_parts/mecha_tracking))
		var/obj/item/mecha_parts/mecha_tracking/tracker = W
		tracker.try_attach_part(user, src)
		return
	else
		return ..()

/obj/mecha/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	mecha_log_message("Attacked by [I]. Attacker - [user]")
	return ..()

/obj/mecha/proc/mech_toxin_damage(mob/living/target)
	playsound(src, 'sound/effects/spray2.ogg', 50, 1)
	if(target.reagents)
		if(target.reagents.get_reagent_amount(/datum/reagent/cryptobiolin) + force < force*2)
			target.reagents.add_reagent(/datum/reagent/cryptobiolin, force/2)
		if(target.reagents.get_reagent_amount(/datum/reagent/toxin) + force < force*2)
			target.reagents.add_reagent(/datum/reagent/toxin, force/2.5)


/obj/mecha/mech_melee_attack(obj/mecha/M)
	if(!has_charge(melee_energy_drain))
		return 0
	use_power(melee_energy_drain)
	if(M.damtype == BRUTE || M.damtype == BURN)
		log_combat(M.occupant, src, "attacked", M, "(INTENT: [uppertext(M.occupant.a_intent)]) (DAMTYPE: [uppertext(M.damtype)])")
		. = ..()

/obj/mecha/proc/full_repair(refill_tank)
	obj_integrity = max_integrity
	if(fuel_holder && refill_tank)
		fuel_holder.reagents.add_reagent("welding_fuel", fuel_holder.volume)
	if(internal_damage & MECHA_INT_FIRE)
		clearInternalDamage(MECHA_INT_FIRE)
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clearInternalDamage(MECHA_INT_TEMP_CONTROL)
	if(internal_damage & MECHA_INT_SHORT_CIRCUIT)
		clearInternalDamage(MECHA_INT_SHORT_CIRCUIT)
	if(internal_damage & MECHA_INT_TANK_BREACH)
		clearInternalDamage(MECHA_INT_TANK_BREACH)
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		clearInternalDamage(MECHA_INT_CONTROL_LOST)

/obj/mecha/narsie_act()
	emp_act(100)

/obj/mecha/ratvar_act()
	if((GLOB.ratvar_awakens || GLOB.clockwork_gateway_activated) && occupant)
		if(is_servant_of_ratvar(occupant)) //reward the minion that got a mech by repairing it
			full_repair(TRUE)
		else
			var/mob/living/L = occupant
			go_out(TRUE)
			if(L)
				L.ratvar_act()

/obj/mecha/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect)
		if(selected)
			used_item = selected
		else if(!visual_effect_icon)
			visual_effect_icon = ATTACK_EFFECT_SMASH
			if(damtype == BURN)
				visual_effect_icon = ATTACK_EFFECT_MECHFIRE
			else if(damtype == TOX)
				visual_effect_icon = ATTACK_EFFECT_MECHTOXIN
	..()

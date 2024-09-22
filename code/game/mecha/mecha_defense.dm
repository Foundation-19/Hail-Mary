/obj/mecha/proc/get_armour_facing(relative_dir)
	switch(relative_dir)
		if(180) // BACKSTAB!
			return facing_modifiers[BACK_ARMOUR]
		if(0, 45) // direct or 45 degrees off
			return facing_modifiers[FRONT_ARMOUR]
	return facing_modifiers[SIDE_ARMOUR] //if its not a front hit or back hit then assume its from the side

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
/*	else if(istype(W, /obj/item/wrench))
		if(state==1)
			state = 2
			to_chat(user, span_notice("You undo the securing bolts."))
		else if(state==2)
			state = 1
			to_chat(user, span_notice("You tighten the securing bolts."))
		return*/

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

/obj/mecha/crowbar_act(mob/user, obj/item/I)
	if(user.a_intent != INTENT_HELP)
		switch(maintenance_panel_status)
			if(MECHA_PANEL_1)
				to_chat(user, "<span class='notice'>You begin bending the hatches on \the [src] out of place</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You bend the hatches on \the [src], you can now heat up the security screws.</span>")
					maintenance_panel_status = MECHA_PANEL_2
					return TRUE
			if(MECHA_PANEL_2)
				to_chat(user, "<span class='notice'>You begin repairing the hatches on \the [src]</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You repair the hatches on \the [src].</span>")
					maintenance_panel_status = MECHA_PANEL_0
					return TRUE
			if(MECHA_PANEL_3)
				to_chat(user, "<span class='notice'>You begin removing the security pins on [src]'s hatch</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You remove the security pins on \the [src].</span>")
					maintenance_panel_status = MECHA_PANEL_5
					return TRUE
			if(MECHA_PANEL_4)
				to_chat(user, "<span class='notice'>You begin replacing the security pins on [src]'s hatch</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You replace the security pins on \the [src]'s hatch.</span>")
					maintenance_panel_status = MECHA_PANEL_2
					return TRUE
			if(MECHA_PANEL_6)
				if(state != MECHA_OPEN_HATCH && state != MECHA_BATTERY_UNSCREW)
					to_chat(user, "<span class='notice'>You begin opening [src]'s hatch</span>")
					if(I.use_tool(src, user, 3 SECONDS, volume = 50))
						to_chat(user, "<span class='notice'>You open [src]'s hatch.</span>")
						state = MECHA_OPEN_HATCH
						return TRUE
				else if(state == MECHA_OPEN_HATCH)
					to_chat(user, "<span class='notice'>You begin closing [src]'s hatch</span>")
					if(I.use_tool(src, user, 3 SECONDS, volume = 50))
						to_chat(user, "<span class='notice'>You close [src]'s hatch.</span>")
						state = MECHA_MAINT_OFF
						return TRUE

	if(state != MECHA_BOLTS_UP && state != MECHA_OPEN_HATCH && !(state == MECHA_BATTERY_UNSCREW && occupant))
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = 50))
		return
	if(state == MECHA_BOLTS_UP)
		state = MECHA_OPEN_HATCH
		to_chat(user, "You open the hatch to the power unit")
	else if(state == MECHA_OPEN_HATCH)
		state = MECHA_BOLTS_UP
		to_chat(user, "You close the hatch to the power unit")
	else if(ishuman(occupant))
		user.visible_message("<span class='notice'>[user] begins levering out the driver from the [src].</span>", "<span class='notice'>You begin to lever out the driver from the [src].</span>")
		to_chat(occupant, "<span class='warning'>[user] is prying you out of the exosuit!</span>")
		if(I.use_tool(src, user, 8 SECONDS, volume = 50))
			user.visible_message("<span class='notice'>[user] pries the driver out of the [src]!</span>", "<span class='notice'>You finish removing the driver from the [src]!</span>")
			go_out()
	else
		// Since having maint protocols available is controllable by the MMI, I see this as a consensual way to remove an MMI without destroying the mech
		user.visible_message("<span class='notice'>[user] begins levering out the MMI from [src].</span>", "<span class='notice'>You begin to lever out the MMI from [src].</span>")
		to_chat(occupant, "<span class='warning'>[user] is prying you out of the exosuit!</span>")
		if(I.use_tool(src, user, 8 SECONDS, volume = 50) && occupant == mmi_as_oc)
			user.visible_message("<span class='notice'>[user] pries the MMI out of [src]!</span>", "<span class='notice'>You finish removing the MMI from [src]!</span>")
			go_out()

/obj/mecha/screwdriver_act(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return
	if(!(state == MECHA_OPEN_HATCH && fuel_holder) && !(state == MECHA_BATTERY_UNSCREW && fuel_holder))
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = 50))
		return
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clearInternalDamage(MECHA_INT_TEMP_CONTROL)
		to_chat(user, "<span class='notice'>You repair the damaged temperature controller.</span>")
	else if(state == MECHA_OPEN_HATCH && fuel_holder)
		fuel_holder.forceMove(loc)
		fuel_holder = null
		state = MECHA_BATTERY_UNSCREW
		to_chat(user, "<span class='notice'>You unscrew and pry out the fuel holder.</span>")
		log_message("Fuel cell removed")
	else if(state == MECHA_BATTERY_UNSCREW && fuel_holder)
		state = MECHA_OPEN_HATCH
		to_chat(user, "<span class='notice'>You screw the fuel holder in place.</span>")
/obj/mecha/wrench_act(mob/user, obj/item/I)
	if(state != MECHA_MAINT_ON && state != MECHA_BOLTS_UP)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = 50))
		return
	if(state == MECHA_MAINT_ON)
		state = MECHA_BOLTS_UP
		to_chat(user, "You undo the securing bolts.")
	else
		state = MECHA_MAINT_ON
		to_chat(user, "You tighten the securing bolts.")
/obj/mecha/welder_act(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return
	if(user.a_intent != INTENT_HELP)
		switch(maintenance_panel_status)
			if(MECHA_PANEL_0)
				to_chat(user, "<span class='notice'>You begin heating up the hatches on \the [src]</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You heat up the hatches on \the [src], they can now be pried out of place.</span>")
					maintenance_panel_status = MECHA_PANEL_1
					return TRUE
			if(MECHA_PANEL_2)
				to_chat(user, "<span class='notice'>You begin softening the security pins on \the [src]</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You soften the security pins on \the [src], they can now be pried out</span>")
					maintenance_panel_status = MECHA_PANEL_3
					return TRUE
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	if((obj_integrity >= max_integrity) && !internal_damage)
		to_chat(user, "<span class='notice'>[src] is at full integrity!</span>")
		return
	if(repairing)
		to_chat(user, "<span class='notice'>[src] is currently being repaired!</span>")
		return
	if(state == MECHA_MAINT_OFF) // If maint protocols are not active, the state is zero
		to_chat(user, "<span class='warning'>[src] can not be repaired without maintenance protocols active!</span>")
		return
	WELDER_ATTEMPT_REPAIR_MESSAGE
	repairing = TRUE
	if(I.use_tool(src, user, 15, volume = 50))
		if(internal_damage & MECHA_INT_TANK_BREACH)
			clearInternalDamage(MECHA_INT_TANK_BREACH)
			user.visible_message("<span class='notice'>[user] repairs the damaged gas tank.</span>", "<span class='notice'>You repair the damaged gas tank.</span>")
		else if(obj_integrity < max_integrity)
			user.visible_message("<span class='notice'>[user] repairs some damage to [name].</span>", "<span class='notice'>You repair some damage to [name].</span>")
			obj_integrity += min(10, max_integrity - obj_integrity)
		else
			to_chat(user, "<span class='notice'>[src] is at full integrity!</span>")
	repairing = FALSE

/obj/mecha/wirecutter_act(mob/living/user, obj/item/I)
	if(user.a_intent != INTENT_HELP)
		switch(maintenance_panel_status)
			if(MECHA_PANEL_5)
				to_chat(user, "<span class='notice'>You begin cutting the [src]'s locking mechanism.</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You cut \the [src]'s locking mechanism apart. The maintenance hatch can be opened by prying it!</span>")
					maintenance_panel_status = MECHA_PANEL_6
					return TRUE
			if(MECHA_PANEL_6)
				to_chat(user, "<span class='notice'>You begin repairing the [src]'s locking mechanism.</span>")
				if(I.use_tool(src, user, 12 SECONDS, volume = 50))
					to_chat(user, "<span class='notice'>You repair \the [src]'s locking mechanism . The maintenance hatch is no longer openable by prying.</span>")
					maintenance_panel_status = MECHA_PANEL_4
					return TRUE

	if(state != MECHA_OPEN_HATCH && maintenance_panel_status != MECHA_PANEL_6)
		return
//	internal_wiring.attempt_wire_interaction(user)
	return TRUE

/obj/mecha/multitool_act(mob/living/user, obj/item/I)
	if(state != MECHA_OPEN_HATCH && maintenance_panel_status != MECHA_PANEL_6)
		return
//	internal_wiring.attempt_wire_interaction(user)
	return TRUE

/obj/mecha/_try_interact(mob/user)
	if(state == MECHA_OPEN_HATCH && maintenance_panel_status != MECHA_PANEL_6)
		return TRUE
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

/*
	Heat & malfunction system for laser-family energy weapons only (scoped to /obj/item/gun/energy/laser,
	not the base /obj/item/gun/energy used by tasers/tools/specials). Mirrors the ballistic
	gun_malfunction.dm system 1:1 - same defines, same timing, same SPECIAL hooks - just re-flavored
	for a capacitor/lens weapon instead of a mechanical action:
	- "jam"         -> an overheat lockout (safety interlock trips, needs a quick vent)
	- "cook-off"    -> a capacitor surge (dumps charge/heat on its own, can burn the user)
	- "double-feed" -> a thermal runaway (needs the full bleed-purge-reset drill)
*/

/obj/item/gun/energy/laser
	/// Current accumulated heat, 0 to GUN_HEAT_MAX
	var/gun_heat = 0
	/// world.time heat was last settled - used to catch up decay in real time
	var/heat_last_update = 0
	/// 0-100 overall condition. Degrades from overheats/runaways, restored with a screwdriver recalibration
	var/gun_condition = GUN_CONDITION_MAX
	/// Multiplies heat gained per shot
	var/heat_per_shot_mult = 1
	/// Multiplies the jam/surge heat thresholds and GUN_HEAT_MAX
	var/heat_capacity_mult = 1
	/// Multiplies final malfunction chance once heat is past threshold, independent of heat capacity
	var/jam_chance_mult = 1

/obj/item/gun/energy/laser/add_heat(amount)
	decay_heat()
	if(amount)
		gun_heat = min(gun_heat + (amount * heat_per_shot_mult), GUN_HEAT_MAX * heat_capacity_mult)

/// Settles accumulated heat back down based on real time elapsed, same catch-up approach as ballistic's decay_heat()
/obj/item/gun/energy/laser/proc/decay_heat()
	if(!gun_heat)
		heat_last_update = world.time
		return
	var/steps = round((world.time - heat_last_update) / GUN_HEAT_DECAY_TICK)
	if(steps <= 0)
		return
	steps = min(steps, GUN_HEAT_DECAY_MAX_CATCHUP)
	for(var/i in 1 to steps)
		if(gun_heat <= GUN_HEAT_DECAY_FLAT)
			gun_heat = 0
			break
		gun_heat = (gun_heat - GUN_HEAT_DECAY_FLAT) * GUN_HEAT_DECAY_MULT
	heat_last_update = world.time

/// How much worse heat-driven malfunction chance gets as gun_condition drops below GUN_CONDITION_DEGRADED_THRESHOLD - up to 3x at 0 condition
/obj/item/gun/energy/laser/proc/get_condition_jam_multiplier()
	if(gun_condition >= GUN_CONDITION_DEGRADED_THRESHOLD)
		return 1
	return 1 + ((GUN_CONDITION_DEGRADED_THRESHOLD - gun_condition) / GUN_CONDITION_DEGRADED_THRESHOLD) * 2

/obj/item/gun/energy/laser/check_malfunction(mob/living/user)
	if(jammed)
		return TRUE
	var/luck_mult = user ? user.get_luck_gun_jam_multiplier() : 1
	var/eff_cookoff_threshold = GUN_HEAT_COOKOFF_THRESHOLD * heat_capacity_mult
	if(gun_heat > eff_cookoff_threshold && cell && cell.charge > 0)
		if(prob((gun_heat - eff_cookoff_threshold) * GUN_HEAT_COOKOFF_CHANCE_PER_POINT * jam_chance_mult * luck_mult))
			capacitor_surge(user)
			return TRUE
	var/eff_jam_threshold = GUN_HEAT_JAM_THRESHOLD * heat_capacity_mult
	if(gun_heat > eff_jam_threshold)
		var/perception_mult = user ? user.get_perception_gun_jam_multiplier() : 1
		var/chance = (gun_heat - eff_jam_threshold) * GUN_HEAT_JAM_CHANCE_PER_POINT * get_condition_jam_multiplier() * jam_chance_mult * luck_mult * perception_mult
		if(prob(chance))
			// a badly worn weapon can choke into a full thermal runaway instead of just a simple lockout
			if(gun_condition < GUN_CONDITION_DOUBLEFEED_THRESHOLD && prob((GUN_CONDITION_DOUBLEFEED_THRESHOLD - gun_condition) / GUN_CONDITION_DOUBLEFEED_THRESHOLD * 100))
				become_overheated(user, "[src]'s coils choke hard - a thermal runaway locks the action solid!", GUN_MALFUNCTION_DOUBLEFEED)
			else
				become_overheated(user)
			return TRUE
	return FALSE

/obj/item/gun/energy/laser/proc/become_overheated(mob/living/user, custom_message, malfunction = GUN_MALFUNCTION_JAM)
	jammed = TRUE
	malfunction_type = malfunction
	gun_condition = max(0, gun_condition - (malfunction == GUN_MALFUNCTION_DOUBLEFEED ? GUN_CONDITION_LOSS_DOUBLEFEED : GUN_CONDITION_LOSS_JAM))
	if(user)
		user.visible_message(span_warning("[user]'s [src] overheats!"), span_userdanger(custom_message || "[src] overheats and locks up!"))
	do_sparks(1, FALSE, src)

/// A capacitor surge from excess heat - dumps a chunk of charge on its own, no aiming/targeting involved
/obj/item/gun/energy/laser/proc/capacitor_surge(mob/living/user)
	gun_condition = max(0, gun_condition - GUN_CONDITION_LOSS_COOKOFF)
	if(user)
		user.visible_message(span_userdanger("[src] surges with excess heat in [user]'s hands!"), span_userdanger("[src]'s capacitor surges from the heat!"))
		if(prob(40))
			user.apply_damage(rand(2, 6) * user.get_strength_cookoff_burn_multiplier(), BURN, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
	do_sparks(3, TRUE, src)
	if(cell)
		cell.use(min(cell.charge, cell.maxcharge * 0.15)) // venting the surge burns off a chunk of the cell
	gun_heat = GUN_HEAT_JAM_THRESHOLD * heat_capacity_mult // venting sheds a big chunk of the built-up heat
	update_icon()

/// Maintenance pass - recalibrating a laser weapon's optics/capacitor bank restores some condition
/obj/item/gun/energy/laser/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(gun_condition >= GUN_CONDITION_MAX)
		to_chat(user, span_notice("[src] is already in good condition."))
		return TRUE
	if(!I.use_tool(src, user, 40, volume = 50))
		return TRUE
	gun_condition = min(GUN_CONDITION_MAX, gun_condition + (GUN_CONDITION_REPAIR_AMOUNT * user.get_intelligence_gun_repair_multiplier()))
	to_chat(user, span_notice("You recalibrate [src], improving its condition."))
	return TRUE

/obj/item/gun/energy/laser/attack_self(mob/living/user)
	if(jammed)
		try_clear_jam(user)
		return
	return ..()

/// Interruptible action to clear whatever's stopping the gun from firing - severity picks the flow,
/// but either way it's ONE triggered action off a single click, not several manual steps.
/obj/item/gun/energy/laser/proc/try_clear_jam(mob/living/user)
	if(!jammed)
		return
	if(malfunction_type == GUN_MALFUNCTION_DOUBLEFEED)
		clear_thermal_runaway(user)
	else
		clear_overheat_lockout(user)

/obj/item/gun/energy/laser/proc/clear_overheat_lockout(mob/living/user)
	to_chat(user, span_notice("You begin venting [src]'s excess heat..."))
	if(!do_after(user, GUN_JAM_CLEAR_TIME * user.get_agility_gun_speed_multiplier(), TRUE, src))
		to_chat(user, span_warning("You were interrupted while venting [src]!"))
		return
	jammed = FALSE
	to_chat(user, span_notice("You vent [src]'s excess heat, clearing the lockout."))
	playsound(src, 'sound/f13weapons/equipsounds/laserreload.ogg', 50, TRUE)
	update_icon()

/// A thermal runaway needs the full drill - bleed the primary capacitor, then purge and reset the coil -
/// chained as two back-to-back do_afters off a single attack_self, interruptible under fire the whole way through.
/obj/item/gun/energy/laser/proc/clear_thermal_runaway(mob/living/user)
	to_chat(user, span_warning("[src] has gone into thermal runaway - you'll need to bleed it down properly!"))
	if(!do_after(user, (GUN_DOUBLEFEED_CLEAR_TIME * 0.4) * user.get_agility_gun_speed_multiplier(), TRUE, src))
		to_chat(user, span_warning("You were interrupted while bleeding down [src]!"))
		return
	if(cell)
		cell.use(min(cell.charge, cell.maxcharge * 0.1))
	to_chat(user, span_notice("You bleed the primary capacitor and purge the coil..."))
	if(!do_after(user, (GUN_DOUBLEFEED_CLEAR_TIME * 0.6) * user.get_agility_gun_speed_multiplier(), TRUE, src))
		to_chat(user, span_warning("You were interrupted while resetting [src]!"))
		return
	jammed = FALSE
	to_chat(user, span_notice("You reset [src], clearing the thermal runaway."))
	playsound(src, 'sound/f13weapons/equipsounds/laserreload.ogg', 50, TRUE)
	update_icon()

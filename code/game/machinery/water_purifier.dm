/obj/machinery/f13_grid_gated/water_purifier
	name = "water purifier"
	desc = "An advanced pre-War water purifier. Removes radiation and contaminants from impure water. Requires fuel and regular maintenance to function properly."
	icon = 'icons/obj/waterpurifier.dmi'
	icon_state = "purifier"

	flags_1 = NODECONSTRUCT_1
	move_resist = INFINITY
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	density = TRUE

	// Power behavior (match SS13 machinery expectations)
	use_power = ACTIVE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 100

	/// The beaker/container currently in the machine
	var/obj/item/reagent_containers/output = null

	/// How many units it processes per tick (total throughput for contaminants+conversion)
	var/speed = 5

	/// What reagent it outputs as "clean water"
	var/datum/reagent/reagent_type = /datum/reagent/water/purified

	/// Reagents we consider contaminants and will strip out
	var/list/contaminants = list(
		/datum/reagent/radium
	)

	/// Also convert normal water into purified water
	var/convert_water = TRUE

	// --- Fuel + maintenance ---
	/// Current fuel (0-100). If this hits 0, the purifier stops working.
	var/fuel = 100
	/// Current condition (0-100). Low condition reduces effective speed. Too low stalls.
	var/condition = 100

	/// How much fuel is consumed per processing tick (when actually doing work)
	var/fuel_cost_per_tick = 1
	/// How fast condition decays per processing tick (when actually doing work)
	var/condition_decay_per_tick = 0.25

	/// Minimum condition where it still functions (below this, it stalls)
	var/min_condition_to_run = 10

	/// Item type accepted as fuel (set to null to disable refueling)
	var/refuel_item_type = /obj/item/stack/sheet/metal
	/// Item type accepted for repairs (set to null to disable repairs)
	var/repair_item_type = /obj/item/stack/sheet/metal


/obj/machinery/f13_grid_gated/water_purifier/Initialize()
	. = ..()
	START_PROCESSING(SSmachines, src)
	update_icon()

/obj/machinery/f13_grid_gated/water_purifier/Destroy()
	STOP_PROCESSING(SSmachines, src)
	QDEL_NULL(output)
	return ..()

// Make it react immediately when area power changes OR the grid flips (your setter calls power_change() on f13_grid_gated)
/obj/machinery/f13_grid_gated/water_purifier/power_change()
	. = ..()
	// If we lost operational state, hard-stop visuals
	if(!is_operational())
		set_light(0) // safe even if you don't use it; no-op in most forks
	update_icon()

/obj/machinery/f13_grid_gated/water_purifier/process()
	// grid gate + area power gate lives inside is_operational()/powered()
	if(!is_operational())
		return

	// Only draw power when we're actually able to do something
	use_power = IDLE_POWER_USE

	if(fuel <= 0)
		update_icon()
		return

	if(condition < min_condition_to_run)
		update_icon()
		return

	if(!output || !output.reagents)
		update_icon()
		return

	// No "free water" — must have something inside to purify.
	if(output.reagents.total_volume <= 0)
		update_icon()
		return

	// Scale throughput by condition. (100% = full speed, 50% = half speed, etc.)
	var/effective_speed = max(1, round(speed * (condition / 100)))

	var/remaining = effective_speed
	var/removed_total = 0

	// 1) Strip contaminants first (radium etc.)
	for(var/path in contaminants)
		if(remaining <= 0)
			break
		var/amt = output.reagents.get_reagent_amount(path)
		if(amt > 0)
			var/rm = min(remaining, amt)
			output.reagents.remove_reagent(path, rm)
			removed_total += rm
			remaining -= rm

	// 2) Convert plain water into purified water
	if(convert_water && remaining > 0)
		var/wamt = output.reagents.get_reagent_amount(/datum/reagent/water)
		if(wamt > 0)
			var/rm2 = min(remaining, wamt)
			output.reagents.remove_reagent(/datum/reagent/water, rm2)
			removed_total += rm2
			remaining -= rm2

	// If we didn't do any real work, don't burn fuel/condition.
	if(removed_total <= 0)
		update_icon()
		return

	// We are actively working -> draw power
	use_power = ACTIVE_POWER_USE

	// 3) Replace removed/converted volume with purified water (keeps total volume stable)
	// NOTE: removing then adding usually leaves volume stable; this is just a safe cap.
	var/space = output.reagents.maximum_volume - output.reagents.total_volume
	if(space > 0)
		output.reagents.add_reagent(reagent_type, min(removed_total, space))

	// --- Fuel + maintenance drain (only when actually purifying) ---
	fuel = max(fuel - fuel_cost_per_tick, 0)
	condition = max(condition - condition_decay_per_tick, 0)

	update_icon()

/obj/machinery/f13_grid_gated/water_purifier/attackby(obj/item/O, mob/user, params)
	if(user && user.a_intent == INTENT_HARM)
		return ..()

	// --- Refuel ---
	if(refuel_item_type && istype(O, refuel_item_type))
		if(fuel >= 100)
			to_chat(user, span_notice("The purifier's fuel tank is already full."))
			return TRUE

		var/obj/item/stack/S = O
		if(S && S.use(1))
			fuel = min(fuel + 25, 100)
			to_chat(user, span_notice("You refuel [src]."))
			update_icon()
		return TRUE

	// --- Repair / maintenance ---
	if(repair_item_type && istype(O, repair_item_type))
		if(condition >= 100)
			to_chat(user, span_notice("[src] is already in top condition."))
			return TRUE

		var/obj/item/stack/R = O
		if(R && R.use(1))
			condition = min(condition + 20, 100)
			to_chat(user, span_notice("You tighten fittings and patch worn parts on [src]."))
			update_icon()
		return TRUE

	// --- Install container ---
	if(istype(O, /obj/item/reagent_containers))
		. = TRUE // no afterattack
		if(output)
			to_chat(user, span_warning("Remove [output] from the machine first."))
			return
		if(!user.transferItemToLoc(O, src))
			return
		to_chat(user, span_notice("You install [O] in the slot."))
		output = O
		update_icon()
		return

	to_chat(user, span_warning("You cannot use [O] on [src]."))
	return TRUE

/obj/machinery/f13_grid_gated/water_purifier/on_attack_hand(mob/living/carbon/user)
	. = ..()
	if(output && user && Adjacent(user))
		output.forceMove(drop_location())
		if(user.can_hold_items())
			user.put_in_hands(output)
		output = null
		update_icon()
		return TRUE
	return

/obj/machinery/f13_grid_gated/water_purifier/update_icon()
	. = ..()
	// You can expand these icon states if your dmi has them.
	// For now just flip between "running/offline/empty" style logic.
	if(!is_operational())
		icon_state = "purifier"
		return
	if(fuel <= 0 || condition < min_condition_to_run)
		icon_state = "purifier"
		return
	if(!output || !output.reagents || output.reagents.total_volume <= 0)
		icon_state = "purifier"
		return
	icon_state = "purifier"

/obj/machinery/f13_grid_gated/water_purifier/update_overlays()
	. = ..()
	if(!output || !output.reagents)
		return

	if(output.reagents.total_volume <= 0)
		return

	var/maxv = output.reagents.maximum_volume
	if(maxv <= 0)
		return

	var/percent = round((output.reagents.total_volume / maxv) * 100)

	var/mutable_appearance/filling_overlay = mutable_appearance(icon, "output-0")
	switch(percent)
		if(0 to 12)         filling_overlay.icon_state = "output-0"
		if(13 to 24)        filling_overlay.icon_state = "output-12-5"
		if(25 to 37)        filling_overlay.icon_state = "output-25"
		if(38 to 49)        filling_overlay.icon_state = "output-37-5"
		if(50 to 62)        filling_overlay.icon_state = "output-50"
		if(63 to 74)        filling_overlay.icon_state = "output-62-5"
		if(75 to 87)        filling_overlay.icon_state = "output-75"
		if(88 to 99)        filling_overlay.icon_state = "output-87-5"
		if(100 to INFINITY) filling_overlay.icon_state = "output-100"

	filling_overlay.color = list(mix_color_from_reagents(output.reagents.reagent_list))
	. += filling_overlay

/obj/machinery/f13_grid_gated/water_purifier/examine(mob/user)
	. = ..()

	if(!is_operational())
		. += span_danger("It’s offline. The wasteland grid is down, or this area has no power.")
		return

	// Fuel readout
	if(fuel > 60)
		. += span_notice("Fuel levels are stable.")
	else if(fuel > 20)
		. += span_warning("Fuel levels are low.")
	else
		. += span_danger("Fuel is critically low.")

	// Condition readout
	if(condition > 60)
		. += span_notice("The purifier appears to be in good condition.")
	else if(condition > 30)
		. += span_warning("The purifier rattles and leaks steam.")
	else
		. += span_danger("The purifier sparks and struggles to operate.")

	// Container readout
	if(output && output.reagents)
		var/maxv = output.reagents.maximum_volume
		var/percent = (maxv > 0) ? round((output.reagents.total_volume / maxv) * 100) : 0
		. += span_notice("[output] is [percent]% full.")

		var/rads = output.reagents.get_reagent_amount(/datum/reagent/radium)
		if(rads > 0)
			. += span_warning("Detected contamination: radium ([round(rads, 0.1)]u).")
	else
		. += span_notice("No reagent container is installed.")

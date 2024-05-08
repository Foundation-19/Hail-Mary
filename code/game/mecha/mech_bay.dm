/turf/open/floor/mech_bay_recharge_floor               //        Whos idea it was
	name = "mech bay recharge station"                      //        Recharging turfs
	desc = "Parking a mech on this station will recharge its internal power cell."
	icon = 'icons/turf/floors.dmi'                          //		  That are set in stone to check the west turf for recharge port
	icon_state = "recharge_floor"                           //        Some people just want to watch the world burn i guess

/turf/open/floor/mech_bay_recharge_floor/break_tile()
	ScrapeAway()

/turf/open/floor/mech_bay_recharge_floor/airless
	icon_state = "recharge_floor_asteroid"
	initial_gas_mix = AIRLESS_ATMOS

/obj/machinery/mech_bay_recharge_port
	name = "mech bay power port"
	desc = "This port recharges a mech's internal power cell."
	density = TRUE
	dir = EAST
	icon = 'icons/mecha/mech_bay.dmi'
	icon_state = "recharge_port"
	circuit = /obj/item/circuitboard/machine/mech_recharger
	var/obj/mecha/recharging_mech
	var/obj/machinery/computer/mech_bay_power_console/recharge_console
	var/max_charge = 50
	var/on = FALSE
	var/repairability = 0
	var/turf/recharging_turf = null

/obj/machinery/mech_bay_recharge_port/Initialize()
	. = ..()
	recharging_turf = get_step(loc, dir)

/obj/machinery/mech_bay_recharge_port/RefreshParts()
	var/MC
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		MC += C.rating
	max_charge = MC * 25

/obj/machinery/mech_bay_recharge_port/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Base recharge rate at <b>[max_charge]J</b> per cycle.</span>"

/obj/machinery/mech_bay_recharge_port/process()
	if(stat & NOPOWER || !recharge_console)
		return
	if(!recharging_mech)
		recharging_mech = locate(/obj/mecha) in recharging_turf
		if(recharging_mech)
			recharge_console.update_icon()
	if(recharging_mech && recharging_mech.fuel_holder)
		if(recharging_mech.fuel_holder.reagents.total_volume < recharging_mech.fuel_holder.volume)
			var/delta = min(max_charge, recharging_mech.fuel_holder.volume - recharging_mech.fuel_holder.reagents.total_volume)
			recharging_mech.give_power(delta)
			use_power(delta*150)
		else
			recharge_console.update_icon()
		if(recharging_mech.loc != recharging_turf)
			recharging_mech = null
			recharge_console.update_icon()


/obj/machinery/mech_bay_recharge_port/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "recharge_port-o", "recharge_port", I))
		return

	if(default_change_direction_wrench(user, I))
		recharging_turf = get_step(loc, dir)
		return

	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/computer/mech_bay_power_console
	name = "mech bay power control console"
	desc = "Displays the status of mechs connected to the recharge station."
	icon_screen = "recharge_comp"
	icon_keyboard = "rd_key"
	circuit = /obj/item/circuitboard/computer/mech_bay_power_console
	var/obj/machinery/mech_bay_recharge_port/recharge_port
	light_color = LIGHT_COLOR_PINK

/obj/machinery/computer/mech_bay_power_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MechBayPowerConsole", name)
		ui.open()

/obj/machinery/computer/mech_bay_power_console/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("reconnect")
			reconnect()
			. = TRUE
			update_icon()

/obj/machinery/computer/mech_bay_power_console/ui_data(mob/user)
	var/list/data = list()
	if(recharge_port && !QDELETED(recharge_port))
		data["recharge_port"] = list("mech" = null)
		if(recharge_port.recharging_mech && !QDELETED(recharge_port.recharging_mech))
			data["recharge_port"]["mech"] = list("health" = recharge_port.recharging_mech.obj_integrity, "maxhealth" = recharge_port.recharging_mech.max_integrity, "cell" = null, "name" = recharge_port.recharging_mech.name,)
			if(recharge_port.recharging_mech.fuel_holder && !QDELETED(recharge_port.recharging_mech.fuel_holder))
				data["recharge_port"]["mech"]["Fuel Tank"] = list(
				"fuel tank" = recharge_port.recharging_mech.fuel_holder.reagents.total_volume,
				"capacity" = recharge_port.recharging_mech.fuel_holder.volume
				)
	return data


/obj/machinery/computer/mech_bay_power_console/proc/reconnect()
	if(recharge_port)
		return
	recharge_port = locate(/obj/machinery/mech_bay_recharge_port) in range(1)
	if(!recharge_port )
		for(var/D in GLOB.cardinals)
			var/turf/A = get_step(src, D)
			A = get_step(A, D)
			recharge_port = locate(/obj/machinery/mech_bay_recharge_port) in A
			if(recharge_port)
				break
	if(recharge_port)
		if(!recharge_port.recharge_console)
			recharge_port.recharge_console = src
		else
			recharge_port = null

/obj/machinery/computer/mech_bay_power_console/update_overlays()
	. = ..()
	if(!recharge_port || !recharge_port.recharging_mech || !recharge_port.recharging_mech.fuel_holder || !(recharge_port.recharging_mech.fuel_holder.reagents.total_volume < recharge_port.recharging_mech.fuel_holder.volume) || stat & (NOPOWER|BROKEN))
		return
	. += "recharge_comp_on"

/obj/machinery/computer/mech_bay_power_console/Initialize()
	. = ..()
	reconnect()

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station
	name = "Gas Station"
	desc = "an old world Gasoline station, for comercial distribution of fue."
	density = TRUE
	dir = NORTH
	icon = 'icons/obj/objects.dmi';
	icon_state = "retrofuelpumppe"
	var/obj/item/fuel_nozzle/deez_nozz = null
	var/on = FALSE
	var/isopen = FALSE
	tank_volume = 10000 //In units, how much the dispenser can hold
	reagent_id = /datum/reagent/fuel
	var/obj/item/key/station_key = new()
	anchored =  TRUE

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/Initialize()
	. = ..()
	deez_nozz = new(src)
	deez_nozz.main_station = src
	deez_nozz.forceMove(src)
	station_key = new(loc)

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It has a [on == 1 ? "green" : "red"] light turned on"
	. += "<span class='notice'>the tank access is  [isopen == 1 ? "colsed tight" : "loose and open"]"

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/proc/get_percent()
	return 100*reagents.total_volume/tank_volume

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/attackby(obj/item/I, mob/living/user, attackchain_flags, damage_multiplier, damage_addition)
	if(I == station_key)
		playsound('sound/machines/click.ogg')
		if(on)
			to_chat(user, span_notice("The gas station turns off!"))
		else
			to_chat(user, span_notice("The gas station powers on!"))
		on = !on
		return FALSE
	. = ..()

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/boom()
	return

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/on_attack_hand(mob/living/user, act_intent, unarmed_attack_flags)
	if(!deez_nozz.holder)
		if(user.IsAdvancedToolUser())
			user.put_in_active_hand(deez_nozz)
			deez_nozz.holder = user
			RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(nozzle_check))
	. = ..()
	
/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/proc/nozzle_check()
	var/turf/here = get_turf(deez_nozz)
	if(!here.Adjacent(src))
		return_nozzle()

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/proc/return_nozzle()
	if(deez_nozz.holder)
		UnregisterSignal(deez_nozz.holder, COMSIG_MOVABLE_MOVED)
	deez_nozz.forceMove(src)
	deez_nozz.holder = null

/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/attackby(obj/item/W, mob/user, params)
	if(W == deez_nozz)
		return_nozzle()
		return
	if(W.tool_behaviour == TOOL_WRENCH && !on)
		isopen = !isopen
		playsound('sound/items/ratchet.ogg')
		to_chat(user, span_notice("You [isopen == 1 ? "open" : "close"] the storage!"))
		return
	if(W.is_refillable() && isopen)
		return 0 //so we can refill them via their afterattack.else
	else
		return ..()

/obj/item/fuel_nozzle
	name = "Gas Station fuel nuzzle"
	desc = "an old world Gasoline station, for comercial distribution of fue."
	icon = 'icons/mecha/mech_bay.dmi'
	icon_state = "fuel_nozzle"
	var/obj/structure/reagent_dispensers/fueltank/vehicle_gas_station/main_station = null
	var/list/possible_transfer_amounts = list(10, 20, 25, 50, 75, 100, 150, 200)
	var/amount_per_transfer_from_this = 10
	var/dispensing = FALSE
	var/mob/holder = null

/obj/item/fuel_nozzle/examine(mob/user)
	. = ..()
	if(main_station.on)
		. += "The lock on trigger is disengaged"
	else 
		. += "the lock on the trigger is engaged"
		return
	if(length(possible_transfer_amounts) > 1)
		. += "Currently transferring [amount_per_transfer_from_this] units per use."


/obj/item/fuel_nozzle/attack_self(mob/user)
	. = ..()
	if(possible_transfer_amounts.len)
		var/i=0
		for(var/A in possible_transfer_amounts)
			i++
			if(A == amount_per_transfer_from_this)
				if(i<possible_transfer_amounts.len)
					amount_per_transfer_from_this = possible_transfer_amounts[i+1]
				else
					amount_per_transfer_from_this = possible_transfer_amounts[1]
				to_chat(user, span_notice("[src]'s transfer amount is now [amount_per_transfer_from_this] units."))
				return

/obj/item/fuel_nozzle/dropped(mob/user)
	. = ..()
	main_station.return_nozzle()


/obj/item/fuel_nozzle/attack_obj(obj/O, mob/living/carbon/user)
	if(istype(O, /obj/mecha))
		var/obj/mecha/car = O
		if(car.get_fuel_tank())
			var/obj/item/reagent_containers/fuel_tank/F = car.get_fuel_tank()
			if(dispensing)
				return TRUE
			else
				dispensing = TRUE
			if(F)
				var/done_any = FALSE
				if(F.reagents.total_volume >= F.volume)
					to_chat(user, span_notice("[F] is Full!"))
					dispensing = FALSE
					return TRUE
				user.visible_message("[user] starts pumping Fuel into [F] with [src].",span_notice("You start pumping fuel into [F] with [src]."))
				while(F.reagents.total_volume < F.volume)
					if(do_after(user, 10, target = user))
						done_any = TRUE
						main_station.reagents.trans_to(F, min((F.volume - F.reagents.total_volume), amount_per_transfer_from_this))
						playsound('sound/effects/bubbles.ogg', 5, 1, 5)
					else
						break
				if(done_any) // Only show a message if we succeeded at least once
					user.visible_message("[user] pumped gas into [F]!",span_notice("You pumped gas into [F]!"))
				dispensing = FALSE
				return TRUE
		else
			to_chat(user, span_warning("This vehicle has no fuel tank!"))
			return FALSE
	. = ..()

/obj/item/fuel_nozzle/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(target.is_refillable() || istype(target, /obj/item/reagent_containers/fuel_tank))
		var/obj/item/reagent_containers/output = target
		if(main_station.on)
			if(dispensing)
				return TRUE
			else
				dispensing = TRUE
			if(output)
				var/done_any = FALSE
				if(output.reagents.total_volume >= output.volume)
					to_chat(user, span_notice("[output] is Full!"))
					dispensing = FALSE
					return TRUE
				user.visible_message("[user] starts pumping Fuel into [output] with [src].",span_notice("You start pumping fuel into [output] with [src]."))
				while(output.reagents.total_volume < output.volume)
					if(do_after(user, 10, target = user))
						done_any = TRUE
						main_station.reagents.trans_to(output, min((output.volume - output.reagents.total_volume), amount_per_transfer_from_this))
						playsound('sound/effects/bubbles.ogg')
					else
						break
				if(done_any) // Only show a message if we succeeded at least once
					user.visible_message("[user] pumped gas into [target]!",span_notice("You pumped gas into [target]!"))
				dispensing = FALSE
				return TRUE
		else
			to_chat(user, span_notice("the fuel station is off!"))
			return

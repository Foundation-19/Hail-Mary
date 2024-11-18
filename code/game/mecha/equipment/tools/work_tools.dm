
//Hydraulic clamp, Kill clamp, Extinguisher, RCD, Cable layer.


/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp
	name = "hydraulic clamp"
	desc = "Equipment for engineering exosuits. Lifts objects and loads them into cargo."
	icon_state = "mecha_clamp"
	equip_cooldown = 15
	energy_drain = 10
	tool_behaviour = TOOL_RETRACTOR
	toolspeed = 0.8
	var/dam_force = 20
	var/obj/mecha/working/ripley/cargo_holder
	harmful = TRUE
	mech_flags = EXOSUIT_MODULE_RIPLEY

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/can_attach(obj/mecha/working/ripley/M as obj)
	if(..())
		if(istype(M))
			return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/attach(obj/mecha/M as obj)
	..()
	cargo_holder = M
	return

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/detach(atom/moveto = null)
	..()
	cargo_holder = null

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/action(atom/target)
	if(!action_checks(target))
		return
	if(!cargo_holder)
		return
	if(ismecha(target))
		var/obj/mecha/M = target
		var/have_ammo
		for(var/obj/item/mecha_ammo/box in cargo_holder.cargo)
			if(istype(box, /obj/item/mecha_ammo) && box.rounds)
				have_ammo = TRUE
				if(M.ammo_resupply(box, chassis.occupant, TRUE))
					return
		if(have_ammo)
			to_chat(chassis.occupant, "No further supplies can be provided to [M].")
		else
			to_chat(chassis.occupant, "No providable supplies found in cargo hold")
		return
	if(isobj(target))
		var/obj/O = target
		if(!O.anchored)
			if(cargo_holder.cargo.len < cargo_holder.cargo_capacity)
				chassis.visible_message("[chassis] lifts [target] and starts to load it into cargo compartment.")
				O.anchored = TRUE
				if(do_after_cooldown(target))
					cargo_holder.cargo += O
					O.forceMove(chassis)
					O.anchored = FALSE
					occupant_message(span_notice("[target] successfully loaded."))
					mecha_log_message("Loaded [O]. Cargo compartment capacity: [cargo_holder.cargo_capacity - cargo_holder.cargo.len]")
				else
					O.anchored = initial(O.anchored)
			else
				occupant_message(span_warning("Not enough room in cargo compartment!"))
		else
			occupant_message(span_warning("[target] is firmly secured!"))

	else if(isliving(target))
		var/mob/living/M = target
		if(M.stat == DEAD)
			return
		if(chassis.occupant.a_intent == INTENT_HARM)
			M.take_overall_damage(dam_force)
			if(!M)
				return
			M.adjustOxyLoss(round(dam_force/2))
			M.updatehealth()
			target.visible_message(span_danger("[chassis] squeezes [target]."), \
								span_userdanger("[chassis] squeezes [target]."),\
								span_italic("You hear something crack."))
			log_combat(chassis.occupant, M, "attacked", "[name]", "(INTENT: [uppertext(chassis.occupant.a_intent)]) (DAMTYE: [uppertext(damtype)])")
		else
			step_away(M,chassis)
			occupant_message("You push [target] out of the way.")
			chassis.visible_message("[chassis] pushes [target] out of the way.")
		return 1



//This is pretty much just for the death-ripley
/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill
	name = "\improper KILL CLAMP"
	desc = "They won't know what clamped them!"
	energy_drain = 0
	dam_force = 0
	var/real_clamp = FALSE

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill/real
	desc = "They won't know what clamped them! This time for real!"
	energy_drain = 10
	dam_force = 20
	real_clamp = TRUE

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill/action(atom/target)
	if(!action_checks(target))
		return
	if(!cargo_holder)
		return
	if(isobj(target))
		var/obj/O = target
		if(!O.anchored)
			if(cargo_holder.cargo.len < cargo_holder.cargo_capacity)
				chassis.visible_message("[chassis] lifts [target] and starts to load it into cargo compartment.")
				O.anchored = TRUE
				if(do_after_cooldown(target))
					cargo_holder.cargo += O
					O.forceMove(chassis)
					O.anchored = FALSE
					occupant_message(span_notice("[target] successfully loaded."))
					mecha_log_message("Loaded [O]. Cargo compartment capacity: [cargo_holder.cargo_capacity - cargo_holder.cargo.len]")
				else
					O.anchored = initial(O.anchored)
			else
				occupant_message(span_warning("Not enough room in cargo compartment!"))
		else
			occupant_message(span_warning("[target] is firmly secured!"))

	else if(isliving(target))
		var/mob/living/M = target
		if(M.stat == DEAD)
			return
		if(chassis.occupant.a_intent == INTENT_HARM)
			if(real_clamp)
				M.take_overall_damage(dam_force)
				if(!M)
					return
				M.adjustOxyLoss(round(dam_force/2))
				M.updatehealth()
				target.visible_message(span_danger("[chassis] destroys [target] in an unholy fury."), \
									span_userdanger("[chassis] destroys [target] in an unholy fury."))
				log_combat(chassis.occupant, M, "attacked", "[name]", "(INTENT: [uppertext(chassis.occupant.a_intent)]) (DAMTYE: [uppertext(damtype)])")
			else
				target.visible_message(span_danger("[chassis] destroys [target] in an unholy fury."), \
									span_userdanger("[chassis] destroys [target] in an unholy fury."))
		else if(chassis.occupant.a_intent == INTENT_DISARM)
			if(real_clamp)
				var/mob/living/carbon/C = target
				var/play_sound = FALSE
				var/limbs_gone = ""
				var/obj/item/bodypart/affected = C.get_bodypart(BODY_ZONE_L_ARM)
				if(affected != null)
					affected.dismember(damtype)
					play_sound = TRUE
					limbs_gone = ", [affected]"
				affected = C.get_bodypart(BODY_ZONE_R_ARM)
				if(affected != null)
					affected.dismember(damtype)
					play_sound = TRUE
					limbs_gone = "[limbs_gone], [affected]"
				if(play_sound)
					playsound(src, get_dismember_sound(), 80, TRUE)
					target.visible_message(span_danger("[chassis] rips [target]'s arms off."), \
								   span_userdanger("[chassis] rips [target]'s arms off."))
					log_combat(chassis.occupant, M, "dismembered of[limbs_gone],", "[name]", "(INTENT: [uppertext(chassis.occupant.a_intent)]) (DAMTYE: [uppertext(damtype)])")
			else
				target.visible_message(span_danger("[chassis] rips [target]'s arms off."), \
								   span_userdanger("[chassis] rips [target]'s arms off."))
		else
			step_away(M,chassis)
			target.visible_message("[chassis] tosses [target] like a piece of paper.")
		return 1



/obj/item/mecha_parts/mecha_equipment/extinguisher
	name = "exosuit extinguisher"
	desc = "Equipment for engineering exosuits. A rapid-firing high capacity fire extinguisher."
	icon_state = "mecha_exting"
	equip_cooldown = 5
	energy_drain = 0
	range = MELEE|RANGED
	mech_flags = EXOSUIT_MODULE_WORKING

/obj/item/mecha_parts/mecha_equipment/extinguisher/Initialize()
	. = ..()
	create_reagents(1000)
	reagents.add_reagent(/datum/reagent/water, 1000)

/obj/item/mecha_parts/mecha_equipment/extinguisher/action(atom/target) //copypasted from extinguisher. TODO: Rewrite from scratch.
	if(!action_checks(target) || get_dist(chassis, target)>3)
		return

	if(istype(target, /obj/structure/reagent_dispensers/watertank) && get_dist(chassis,target) <= 1)
		var/obj/structure/reagent_dispensers/watertank/WT = target
		WT.reagents.trans_to(src, 1000)
		occupant_message(span_notice("Extinguisher refilled."))
		playsound(chassis, 'sound/effects/refill.ogg', 50, 1, -6)
	else
		if(reagents.total_volume > 0)
			playsound(chassis, 'sound/effects/extinguish.ogg', 75, 1, -3)
			var/direction = get_dir(chassis,target)
			var/turf/T = get_turf(target)
			var/turf/T1 = get_step(T,turn(direction, 90))
			var/turf/T2 = get_step(T,turn(direction, -90))

			var/list/the_targets = list(T,T1,T2)
			spawn(0)
				for(var/a=0, a<5, a++)
					var/obj/effect/particle_effect/water/W = new /obj/effect/particle_effect/water(get_turf(chassis))
					if(!W)
						return
					var/turf/my_target = pick(the_targets)
					var/datum/reagents/R = new/datum/reagents(5)
					W.reagents = R
					R.my_atom = W
					reagents.trans_to(W,1)
					for(var/b=0, b<4, b++)
						if(!W)
							return
						step_towards(W,my_target)
						if(!W)
							return
						var/turf/W_turf = get_turf(W)
						W.reagents.reaction(W_turf)
						for(var/atom/atm in W_turf)
							W.reagents.reaction(atm)
						if(W.loc == my_target)
							break
						sleep(2)
		return 1

/obj/item/mecha_parts/mecha_equipment/extinguisher/get_equip_info()
	return "[..()] \[[src.reagents.total_volume]\]"

/obj/item/mecha_parts/mecha_equipment/extinguisher/can_attach(obj/mecha/working/M as obj)
	if(..())
		if(istype(M))
			return 1
	return 0



/obj/item/mecha_parts/mecha_equipment/rcd
	name = "mounted RCD"
	desc = "An exosuit-mounted Rapid Construction Device."
	icon_state = "mecha_rcd"
	equip_cooldown = 10
	energy_drain = 250
	range = MELEE|RANGED
	item_flags = NO_MAT_REDEMPTION
	mech_flags = EXOSUIT_MODULE_RIPLEY
	var/mode = 0 //0 - deconstruct, 1 - wall or floor, 2 - airlock.

/obj/item/mecha_parts/mecha_equipment/rcd/Initialize()
	. = ..()
	GLOB.rcd_list += src

/obj/item/mecha_parts/mecha_equipment/rcd/Destroy()
	GLOB.rcd_list -= src
	return ..()

/obj/item/mecha_parts/mecha_equipment/rcd/action(atom/target)
	if(istype(target, /turf/open/space/transit))//>implying these are ever made -Sieve
		return

	if(!isturf(target) && !istype(target, /obj/machinery/door/airlock))
		target = get_turf(target)
	if(!action_checks(target) || get_dist(chassis, target)>3)
		return
	playsound(chassis, 'sound/machines/click.ogg', 50, 1)

	switch(mode)
		if(0)
			if(iswallturf(target))
				var/turf/closed/wall/W = target
				occupant_message("Deconstructing [W]...")
				if(do_after_cooldown(W))
					chassis.spark_system.start()
					W.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
					playsound(W, 'sound/items/deconstruct.ogg', 50, 1)
			else if(isfloorturf(target))
				var/turf/open/floor/F = target
				occupant_message("Deconstructing [F]...")
				if(do_after_cooldown(target))
					chassis.spark_system.start()
					F.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
					playsound(F, 'sound/items/deconstruct.ogg', 50, 1)
			else if (istype(target, /obj/machinery/door/airlock))
				occupant_message("Deconstructing [target]...")
				if(do_after_cooldown(target))
					chassis.spark_system.start()
					qdel(target)
					playsound(target, 'sound/items/deconstruct.ogg', 50, 1)
		if(1)
			if(isspaceturf(target))
				var/turf/open/space/S = target
				occupant_message("Building Floor...")
				if(do_after_cooldown(S))
					S.PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
					playsound(S, 'sound/items/deconstruct.ogg', 50, 1)
					chassis.spark_system.start()
			else if(isfloorturf(target))
				var/turf/open/floor/F = target
				occupant_message("Building Wall...")
				if(do_after_cooldown(F))
					F.PlaceOnTop(/turf/closed/wall)
					playsound(F, 'sound/items/deconstruct.ogg', 50, 1)
					chassis.spark_system.start()
		if(2)
			if(isfloorturf(target))
				occupant_message("Building Airlock...")
				if(do_after_cooldown(target))
					chassis.spark_system.start()
					var/obj/machinery/door/airlock/T = new /obj/machinery/door/airlock(target)
					T.autoclose = TRUE
					playsound(target, 'sound/items/deconstruct.ogg', 50, 1)
					playsound(target, 'sound/effects/sparks2.ogg', 50, 1)



/obj/item/mecha_parts/mecha_equipment/rcd/do_after_cooldown(atom/target)
	. = ..()

/obj/item/mecha_parts/mecha_equipment/rcd/Topic(href,href_list)
	..()
	if(href_list["mode"])
		mode = text2num(href_list["mode"])
		switch(mode)
			if(0)
				occupant_message("Switched RCD to Deconstruct.")
				energy_drain = initial(energy_drain)
			if(1)
				occupant_message("Switched RCD to Construct.")
				energy_drain = 2*initial(energy_drain)
			if(2)
				occupant_message("Switched RCD to Construct Airlock.")
				energy_drain = 2*initial(energy_drain)
	return

/obj/item/mecha_parts/mecha_equipment/rcd/get_equip_info()
	return "[..()] \[<a href='?src=[REF(src)];mode=0'>D</a>|<a href='?src=[REF(src)];mode=1'>C</a>|<a href='?src=[REF(src)];mode=2'>A</a>\]"




/obj/item/mecha_parts/mecha_equipment/cable_layer
	name = "cable layer"
	desc = "Equipment for engineering exosuits. Lays cable along the exosuit's path."
	icon_state = "mecha_wire"
	var/datum/callback/event
	var/turf/old_turf
	var/obj/structure/cable/last_piece
	var/obj/item/stack/cable_coil/cable
	var/max_cable = 1000

/obj/item/mecha_parts/mecha_equipment/cable_layer/Initialize()
	. = ..()
	cable = new(src, 0)

/obj/item/mecha_parts/mecha_equipment/cable_layer/can_attach(obj/mecha/working/M)
	if(..())
		if(istype(M))
			return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/cable_layer/attach()
	..()
	event = chassis.events.addEvent("onMove", CALLBACK(src, PROC_REF(layCable)))
	return

/obj/item/mecha_parts/mecha_equipment/cable_layer/detach()
	chassis.events.clearEvent("onMove",event)
	return ..()

/obj/item/mecha_parts/mecha_equipment/cable_layer/Destroy()
	if(chassis)
		chassis.events.clearEvent("onMove",event)
	return ..()

/obj/item/mecha_parts/mecha_equipment/cable_layer/action(obj/item/stack/cable_coil/target)
	if(!action_checks(target))
		return
	if(istype(target) && target.amount)
		var/cur_amount = cable? cable.amount : 0
		var/to_load = max(max_cable - cur_amount,0)
		if(to_load)
			to_load = min(target.amount, to_load)
			if(!cable)
				cable = new(src, 0)
			cable.amount += to_load
			target.use(to_load)
			occupant_message(span_notice("[to_load] meters of cable successfully loaded."))
			send_byjax(chassis.occupant,"exosuit.browser","[REF(src)]",src.get_equip_info())
		else
			occupant_message(span_warning("Reel is full."))
	else
		occupant_message(span_warning("Unable to load [target] - no cable found."))


/obj/item/mecha_parts/mecha_equipment/cable_layer/Topic(href,href_list)
	..()
	if(href_list["toggle"])
		set_ready_state(!equip_ready)
		occupant_message("[src] [equip_ready?"dea":"a"]ctivated.")
		mecha_log_message("[equip_ready?"Dea":"A"]ctivated.")
		return
	if(href_list["cut"])
		if(cable && cable.amount)
			var/m = round(input(chassis.occupant,"Please specify the length of cable to cut","Cut cable",min(cable.amount,30)) as num, 1)
			m = min(m, cable.amount)
			if(m)
				use_cable(m)
				new /obj/item/stack/cable_coil(get_turf(chassis), m)
		else
			occupant_message("There's no more cable on the reel.")
	return

/obj/item/mecha_parts/mecha_equipment/cable_layer/get_equip_info()
	var/output = ..()
	if(output)
		return "[output] \[Cable: [cable ? cable.amount : 0] m\][(cable && cable.amount) ? "- <a href='?src=[REF(src)];toggle=1'>[!equip_ready?"Dea":"A"]ctivate</a>|<a href='?src=[REF(src)];cut=1'>Cut</a>" : null]"
	return

/obj/item/mecha_parts/mecha_equipment/cable_layer/proc/use_cable(amount)
	if(!cable || cable.amount<1)
		set_ready_state(1)
		occupant_message("Cable depleted, [src] deactivated.")
		mecha_log_message("Cable depleted, [src] deactivated.")
		return
	if(cable.amount < amount)
		occupant_message("No enough cable to finish the task.")
		return
	cable.use(amount)
	update_equip_info()
	return 1

/obj/item/mecha_parts/mecha_equipment/cable_layer/proc/reset()
	last_piece = null

/obj/item/mecha_parts/mecha_equipment/cable_layer/proc/dismantleFloor(turf/new_turf)
	if(isfloorturf(new_turf))
		var/turf/open/floor/T = new_turf
		if(!isplatingturf(T))
			if(!T.broken && !T.burnt)
				new T.floor_tile(T)
			T.make_plating()
	return !new_turf.intact

/obj/item/mecha_parts/mecha_equipment/cable_layer/proc/layCable(turf/new_turf)
	if(equip_ready || !istype(new_turf) || !dismantleFloor(new_turf))
		return reset()
	var/fdirn = turn(chassis.dir,180)
	for(var/obj/structure/cable/LC in new_turf)		// check to make sure there's not a cable there already
		if(LC.d1 == fdirn || LC.d2 == fdirn)
			return reset()
	if(!use_cable(1))
		return reset()
	var/obj/structure/cable/NC = new(new_turf, "red")
	NC.d1 = 0
	NC.d2 = fdirn
	NC.update_icon()

	var/datum/powernet/PN
	if(last_piece && last_piece.d2 != chassis.dir)
		last_piece.d1 = min(last_piece.d2, chassis.dir)
		last_piece.d2 = max(last_piece.d2, chassis.dir)
		last_piece.update_icon()
		PN = last_piece.powernet

	if(!PN)
		PN = new()
		GLOB.powernets += PN
	NC.powernet = PN
	PN.cables += NC
	NC.mergeConnectedNetworks(NC.d2)

	//NC.mergeConnectedNetworksOnTurf()
	last_piece = NC
	return 1

/obj/item/mecha_parts/mecha_equipment/trunk
	name = "Modular Trunk"
	desc = "Equipment made to hold and transport big ammounts of cargo."
	icon_state = "car_trunk"
	equip_cooldown = 15
	energy_drain = 0
	harmful = FALSE
	mech_flags = EXOSUIT_MODULE_PHAZON
	var/component_type = /datum/component/storage/concrete/trunk
	var/in_use = FALSE
	w_class = WEIGHT_CLASS_GIGANTIC
	resistance_flags = NONE
	max_integrity = 1000
	var/datum/component/storage/concrete/trunk/storagespace

/obj/item/mecha_parts/mecha_equipment/trunk/get_dumping_location(/obj/item/mecha_parts/mecha_equipment/trunk/source,mob/user)
	return src

/obj/item/mecha_parts/mecha_equipment/trunk/Initialize()
	. = ..()
	PopulateContents()

/obj/item/mecha_parts/mecha_equipment/trunk/ComponentInitialize()
	AddComponent(component_type)
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	//STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_combined_w_class = 2100
	STR.max_w_class = WEIGHT_CLASS_GIGANTIC
	STR.max_items = 2100
	storagespace = STR


/obj/item/mecha_parts/mecha_equipment/trunk/AllowDrop()
	return !QDELETED(src)

/obj/item/mecha_parts/mecha_equipment/trunk/contents_explosion(severity, target)
	var/in_storage = istype(loc, /obj/item/storage)? (max(0, severity - 1)) : (severity)
	for(var/atom/A in contents)
		A.ex_act(in_storage, target)
		CHECK_TICK

//Cyberboss says: "USE THIS TO FILL IT, NOT INITIALIZE OR NEW"

/obj/item/mecha_parts/mecha_equipment/trunk/proc/PopulateContents()

/obj/item/mecha_parts/mecha_equipment/trunk/attach()
	. = ..()
	chassis.mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	storagespace.RegisterSignal(chassis, COMSIG_MOUSEDROP_ONTO, /datum/component/storage/concrete/trunk.proc/mousedrop_onto)
	storagespace.RegisterSignal(chassis, COMSIG_CONTAINS_STORAGE, /datum/component/storage/concrete/trunk.proc/on_check)
	storagespace.RegisterSignal(chassis, COMSIG_IS_STORAGE_LOCKED, /datum/component/storage/concrete/trunk.proc/check_locked)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_SHOW, /datum/component/storage/concrete/trunk.proc/signal_show_attempt)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_INSERT, /datum/component/storage/concrete/trunk.proc/signal_insertion_attempt)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_CAN_INSERT, /datum/component/storage/concrete/trunk.proc/signal_can_insert)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE_TYPE, /datum/component/storage/concrete/trunk.proc/signal_take_type)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_FILL_TYPE, /datum/component/storage/concrete/trunk.proc/signal_fill_type)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_SET_LOCKSTATE, /datum/component/storage/concrete/trunk.proc/set_locked)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE, /datum/component/storage/concrete/trunk.proc/signal_take_obj)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_QUICK_EMPTY, /datum/component/storage/concrete/trunk.proc/signal_quick_empty)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_FROM, /datum/component/storage/concrete/trunk.proc/signal_hide_attempt)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_ALL, /datum/component/storage/concrete/trunk.proc/close_all)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_RETURN_INVENTORY, /datum/component/storage/concrete/trunk.proc/signal_return_inv)
	storagespace.RegisterSignal(chassis, COMSIG_PARENT_ATTACKBY, /datum/component/storage/concrete/trunk.proc/attackby)
	storagespace.RegisterSignal(chassis, COMSIG_ATOM_EMP_ACT, /datum/component/storage/concrete/trunk.proc/emp_act)
	storagespace.RegisterSignal(chassis, COMSIG_ATOM_ATTACK_GHOST, /datum/component/storage/concrete/trunk.proc/show_to_ghost)
	storagespace.RegisterSignal(chassis, COMSIG_ATOM_ENTERED, /datum/component/storage/concrete/trunk.proc/refresh_mob_views)
	storagespace.RegisterSignal(chassis, COMSIG_ATOM_EXITED, /datum/component/storage/concrete/trunk.proc/_remove_and_refresh)
	storagespace.RegisterSignal(chassis, COMSIG_ITEM_PRE_ATTACK, /datum/component/storage/concrete/trunk.proc/preattack_intercept)
	storagespace.RegisterSignal(chassis, COMSIG_ITEM_ATTACK_SELF, /datum/component/storage/concrete/trunk.proc/attack_self)
	storagespace.RegisterSignal(chassis, COMSIG_ITEM_PICKUP, /datum/component/storage/concrete/trunk.proc/signal_on_pickup)
	storagespace.RegisterSignal(chassis, COMSIG_MOVABLE_POST_THROW, /datum/component/storage/concrete/trunk.proc/close_all)
	storagespace.RegisterSignal(chassis, COMSIG_MOVABLE_MOVED, /datum/component/storage/concrete/trunk.proc/check_views)
	storagespace.RegisterSignal(chassis, COMSIG_CLICK_ALT, /datum/component/storage/concrete/trunk.proc/on_alt_click)
	storagespace.RegisterSignal(chassis, COMSIG_MOUSEDROPPED_ONTO, /datum/component/storage/concrete/trunk.proc/mousedrop_receive)

/obj/item/mecha_parts/mecha_equipment/trunk/detach()
	storagespace.UnregisterSignal(chassis, COMSIG_MOUSEDROP_ONTO)
	storagespace.UnregisterSignal(chassis, COMSIG_CONTAINS_STORAGE)
	storagespace.UnregisterSignal(chassis, COMSIG_IS_STORAGE_LOCKED)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_SHOW)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_INSERT)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_CAN_INSERT)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE_TYPE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_FILL_TYPE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_SET_LOCKSTATE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_QUICK_EMPTY)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_FROM)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_ALL)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_RETURN_INVENTORY)
	storagespace.UnregisterSignal(chassis, COMSIG_PARENT_ATTACKBY)
	storagespace.UnregisterSignal(chassis, COMSIG_ATOM_EMP_ACT)
	storagespace.UnregisterSignal(chassis, COMSIG_ATOM_ATTACK_GHOST)
	storagespace.UnregisterSignal(chassis, COMSIG_ATOM_ENTERED)
	storagespace.UnregisterSignal(chassis, COMSIG_ATOM_EXITED)
	storagespace.UnregisterSignal(chassis, COMSIG_ITEM_PRE_ATTACK)
	storagespace.UnregisterSignal(chassis, COMSIG_ITEM_ATTACK_SELF)
	storagespace.UnregisterSignal(chassis, COMSIG_ITEM_PICKUP)
	storagespace.UnregisterSignal(chassis, COMSIG_MOVABLE_POST_THROW)
	storagespace.UnregisterSignal(chassis, COMSIG_MOVABLE_MOVED)
	storagespace.UnregisterSignal(chassis, COMSIG_CLICK_ALT)
	storagespace.UnregisterSignal(chassis, COMSIG_MOUSEDROPPED_ONTO)
	chassis.mouse_drag_pointer = MOUSE_INACTIVE_POINTER
	. = ..()


/obj/item/mecha_parts/mecha_equipment/stereo
	name = "exosuit Stereo System"
	desc = "a stereo system hooked up a jukebox, modified for easy transport."
	icon_state = "mecha_stereo"
	range = MELEE
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/volume = 70
	var/datum/track/selection = null
	var/open_tray = TRUE
	var/list/obj/item/record_disk/record_disks = list()
	var/obj/item/record_disk/selected_disk = null

/obj/item/mecha_parts/mecha_equipment/stereo/attach(obj/mecha/M)
	. = ..()
	bypass_interactions = TRUE

/obj/item/mecha_parts/mecha_equipment/stereo/detach(obj/mecha/M)
	. = ..()
	bypass_interactions = FALSE

/obj/item/mecha_parts/mecha_equipment/stereo/attackby(obj/item/O, mob/user, params)
	. = ..()
	if(!active)
		if(istype(O, /obj/item/record_disk)) //this one checks for a record disk and if the jukebox is open, it adds it to the machine
			if(open_tray == FALSE)
				to_chat(usr, "The Disk Tray is not open!")
				return
			var/obj/item/record_disk/I = O
			if(!I.R.song_associated_id)
				to_chat(user, span_warning("This record is empty!"))
				return
			for(var/datum/track/RT in SSjukeboxes.songs)
				if(I.R.song_associated_id == RT.song_associated_id)
					to_chat(user, span_warning("this track is already added to the jukebox!"))
					return
			record_disks += I
			O.forceMove(src)
			playsound(src, 'sound/effects/plastic_click.ogg', 100, 0)
			if(I.R.song_path)
				SSjukeboxes.add_song(I.R)
			return

/obj/item/mecha_parts/mecha_equipment/stereo/proc/eject_record(obj/item/record_disk/M) //BIG IRON EDIT -start- ejects a record as defined and removes it's song from the list
	if(!M)
		visible_message("no disk to eject")
		return
	playsound(src, 'sound/effects/disk_tray.ogg', 100, 0)
	src.visible_message("<span class ='notice'> ejected the [selected_disk] from the [src]!</span>")
	M.forceMove(get_turf(src))
	SSjukeboxes.remove_song(M.R)
	record_disks -= M
	selected_disk = null

/obj/item/mecha_parts/mecha_equipment/stereo/ui_status(mob/user)
	if(!SSjukeboxes.songs.len && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue.</span>")
		playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/obj/item/mecha_parts/mecha_equipment/stereo/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Jukebox", name)
		ui.open()

/obj/item/mecha_parts/mecha_equipment/stereo/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	data["songs"] = list()
	for(var/datum/track/S in SSjukeboxes.songs)
		var/list/track_data = list(
			name = S.song_name
		)
		data["songs"] += list(track_data)
	data["track_selected"] = null
	data["track_length"] = null
	data["track_beat"] = null
	data["disks"] = list()
	for(var/obj/item/record_disk/RD in record_disks)
		var/list/tracks_data = list(
			name = RD.name
		)
		data["disks"] += list(tracks_data)
	data["disk_selected"] = null //BIG IRON EDIT- start more tracks data
	data["disk_selected_lenght"] = null
	data["disk_beat"] = null //BIG IRON EDIT -end
	if(selection)
		data["track_selected"] = selection.song_name
		data["track_length"] = DisplayTimeText(selection.song_length)
		data["track_beat"] = selection.song_beat
	if(selected_disk)
		data["disk_selected"] = selected_disk
		data["disk_selected_length"] = DisplayTimeText(selected_disk.R.song_length)
		data["disk_selected_beat"] = selected_disk.R.song_beat
	data["volume"] = volume
	return data

/obj/item/mecha_parts/mecha_equipment/stereo/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			if(QDELETED(src))
				return
			if(!active)
				if(stop > world.time)
					to_chat(usr, "<span class='warning'>Error: The device is still resetting from the last activation, it will be ready again in [DisplayTimeText(stop-world.time)].</span>")
					playsound(src, 'sound/misc/compiler-failure.ogg', 50, TRUE)
					return
				activate_music()
				START_PROCESSING(SSobj, src)
				return TRUE
			else
				stop = 0
				return TRUE
		if("select_track")
			if(active)
				to_chat(usr, "<span class='warning'>Error: You cannot change the song until the current one is over.</span>")
				return
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selection = available[selected]
			return TRUE
		if("select_record")
			if(!record_disks.len)
				to_chat(usr, "<span class='warning'>Error: no tracks on the bin!.</span>")
				return
			var/list/obj/item/record_disk/availabledisks = list()
			for(var/obj/item/record_disk/RR in record_disks)
				availabledisks[RR.name] = RR
			var/selecteddisk = params["record"]
			if(QDELETED(src) || !selecteddisk)
				return
			selected_disk = availabledisks[selecteddisk]
			updateUsrDialog()
		if("eject_disk") // sanity check for the disk ejection
			if(!record_disks.len)
				to_chat(usr, "<span class='warning'>Error: no disks in trays.</span>")
				return
			if(!selected_disk)
				to_chat(usr,"<span class='warning'>Error: no disk chosen.</span>" )
				return
			if(selection == selected_disk.R)
				selection = null
			eject_record(selected_disk)
			return TRUE
		if("set_volume")
			var/new_volume = params["volume"]
			if(new_volume  == "reset")
				volume = initial(volume)
				return TRUE
			else if(new_volume == "min")
				volume = 0
				return TRUE
			else if(new_volume == "max")
				volume = 100
				return TRUE
			else if(text2num(new_volume) != null)
				volume = text2num(new_volume)
				return TRUE

/obj/item/mecha_parts/mecha_equipment/stereo/proc/activate_music()
	if(!selection)
		visible_message("Track is no longer avaible")
		return
	var/jukeboxslottotake = SSjukeboxes.addjukebox(src, selection, 2)
	if(jukeboxslottotake)
		active = TRUE
		update_icon()
		START_PROCESSING(SSobj, src)
		stop = world.time + selection.song_length
		return TRUE
	else
		return FALSE

/obj/item/mecha_parts/mecha_equipment/stereo/get_equip_info()
	var/output = ..()
	if(output)
		var/temp = ""
		temp = "<a href='?src=[REF(src)];dashboard=1'>Dashboard</a>"
		return "[output] [temp]"
	return

/obj/item/mecha_parts/mecha_equipment/stereo/Topic(href,href_list)
	..()
	if(href_list["dashboard"])
		var/mob/user = chassis.occupant
		ui_interact(user)
		return

/obj/item/mecha_parts/mecha_equipment/stereo/process()
	if(active && world.time >= stop)
		active = FALSE
		dance_over()
		playsound(src,'sound/machines/terminal_off.ogg',50,1)
		update_icon()
		stop = world.time + 100

/obj/item/mecha_parts/mecha_equipment/stereo/proc/dance_over()
	var/position = SSjukeboxes.findjukeboxindex(src)
	if(!position)
		return
	SSjukeboxes.removejukebox(position)
	STOP_PROCESSING(SSobj, src)
	rangers = list()


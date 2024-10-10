/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/fallout13
	name = "crane hook"
	desc = "The hooking system of a vehicle-mounted crane, capable of hoisting multiple heavy items with ease."
	icon_state = "vehicle_crane"
	equip_cooldown = 15
	energy_drain = 10
	tool_behaviour = null
	detachable = FALSE

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/fallout13/can_attach(obj/mecha/M as obj)
	if(..())
		if (!M.cargo_capacity)
			return 0
	return 1

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/fallout13/vehicle_straps
	name = "cargo securing kit"
	desc = "An assortment of cables and straps to secure heavy items on the back of a ute's tray."
	equip_cooldown = 30
	energy_drain = 0
	tool_behaviour = null
	dam_force = 0

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

/obj/item/kinetic_crusher/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/mecha_parts/mecha_equipment/trunk/get_dumping_location(/obj/item/mecha_parts/mecha_equipment/trunk/source,mob/user)
	return src

/obj/item/mecha_parts/mecha_equipment/trunk/Initialize()
	. = ..()
	PopulateContents()

/obj/item/mecha_parts/mecha_equipment/trunk/Destroy()
	for(var/atom/movable/A in contents)
		A.forceMove(drop_location())
		return ..()

/obj/item/mecha_parts/mecha_equipment/trunk/ComponentInitialize()
	AddComponent(component_type)
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	//STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_combined_w_class = 10
	STR.max_w_class = WEIGHT_CLASS_HUGE
	STR.max_items = 20
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
//	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_CAN_INSERT, /datum/component/storage/concrete/trunk.proc/signal_can_insert)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE_TYPE, /datum/component/storage/concrete/trunk.proc/signal_take_type)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_FILL_TYPE, /datum/component/storage/concrete/trunk.proc/signal_fill_type)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_SET_LOCKSTATE, /datum/component/storage/concrete/trunk.proc/set_locked)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE, /datum/component/storage/concrete/trunk.proc/signal_take_obj)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_QUICK_EMPTY, /datum/component/storage/concrete/trunk.proc/signal_quick_empty)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_FROM, /datum/component/storage/concrete/trunk.proc/signal_hide_attempt)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_ALL, /datum/component/storage/concrete/trunk.proc/close_all)
	storagespace.RegisterSignal(chassis, COMSIG_TRY_STORAGE_RETURN_INVENTORY, /datum/component/storage/concrete/trunk.proc/signal_return_inv)
//	storagespace.RegisterSignal(chassis, COMSIG_PARENT_ATTACKBY, /datum/component/storage/concrete/trunk.proc/attackby)
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
//	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_INSERT)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_CAN_INSERT)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE_TYPE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_FILL_TYPE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_SET_LOCKSTATE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_TAKE)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_QUICK_EMPTY)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_FROM)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_HIDE_ALL)
	storagespace.UnregisterSignal(chassis, COMSIG_TRY_STORAGE_RETURN_INVENTORY)
//	storagespace.UnregisterSignal(chassis, COMSIG_PARENT_ATTACKBY)
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

//////Passenger seat

/obj/item/mecha_parts/mecha_equipment/seat
	name = "Mounted seat"
	desc = "A seat. Yup, looks hi-tec eh ? Well, its just a seat"
	icon = 'icons/obj/bus.dmi'
	icon_state = "backseat"
	energy_drain = 5
	range = MELEE
	equip_cooldown = 5
	var/mob/living/carbon/patient = null
	salvageable = 0
	mech_flags = EXOSUIT_MODULE_COMBAT

/obj/item/mecha_parts/mecha_equipment/seat/Destroy()
	for(var/atom/movable/AM in src)
		AM.forceMove(get_turf(src))
	return ..()

/obj/item/mecha_parts/mecha_equipment/seat/Exit(atom/movable/O)
	return 0

/obj/item/mecha_parts/mecha_equipment/seat/action(mob/living/carbon/target)
	if(!action_checks(target))
		return
	if(!istype(target))
		return
	if(!patient_insertion_check(target))
		return
	occupant_message(span_notice("You start putting [target] into [src]..."))
	chassis.visible_message(span_warning("[chassis] starts putting [target] into \the [src]."))
	if(do_after_cooldown(target))
		if(!patient_insertion_check(target))
			return
		target.forceMove(src)
		patient = target
		START_PROCESSING(SSobj, src)
		update_equip_info()
		occupant_message(span_notice("[target] successfully loaded into [src]. Life support functions engaged... I mean, the seatbelt."))
		chassis.visible_message(span_warning("[chassis] loads [target] into [src]."))
		mecha_log_message("[target] loaded. Seatbelt engaged.")

/obj/item/mecha_parts/mecha_equipment/seat/proc/patient_insertion_check(mob/living/carbon/target)
	if(target.buckled)
		occupant_message(span_warning("[target] will not fit into the seat because [target.p_theyre()] buckled to [target.buckled]!"))
		return
	if(target.has_buckled_mobs())
		occupant_message(span_warning("[target] will not fit into the seat because of the creatures attached to it!"))
		return
	if(patient)
		occupant_message(span_warning("The seat is already occupied!"))
		return
	return 1

/obj/item/mecha_parts/mecha_equipment/seat/proc/go_out()
	if(!patient)
		return
	patient.forceMove(get_turf(src))
	occupant_message("[patient] is out, removing the seatbelt.")
	mecha_log_message("[patient] ejected. Seatbelt disabled.")
	STOP_PROCESSING(SSobj, src)
	patient = null
	update_equip_info()

/obj/item/mecha_parts/mecha_equipment/seat/detach()
	if(patient)
		occupant_message(span_warning("Unable to detach [src] - equipment occupied!"))
		return
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/seat/get_equip_info()
	var/output = ..()
	if(output)
		var/temp = ""
		if(patient)
			temp = "<br />\[Occupant: [patient] ([patient.stat > 1 ? "*DECEASED*" : "Health: [patient.health]%"])\]<br /><a href='?src=[REF(src)];view_stats=1'>View stats</a>|<a href='?src=[REF(src)];eject=1'>Eject</a>"
		return "[output] [temp]"
	return

/obj/item/mecha_parts/mecha_equipment/seat/Topic(href,href_list)
	..()
	if(href_list["eject"])
		go_out()
		return

/obj/item/mecha_parts/mecha_equipment/seat/container_resist(mob/living/user)
	go_out()

/obj/item/mecha_parts/mecha_equipment/seat/process()
	if(..())
		return
	if(!chassis.has_charge(energy_drain))
		set_ready_state(1)
		mecha_log_message("Deactivated.")
		occupant_message("[src] deactivated - no power.")
		STOP_PROCESSING(SSobj, src)
		return
	var/mob/living/carbon/M = patient
	if(!M)
		return
	chassis.use_power(energy_drain)
	update_equip_info()

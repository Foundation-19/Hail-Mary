/obj/mecha/working/normalvehicle
	name = "not supposed to be here"
	desc = "not supposed to be here.Delete please."
	anchored = FALSE
	pixel_x = -32
	obj_integrity = 600
	max_integrity = 600
	max_buckled_mobs = 2 // this does nothing and max occupants allows more mobs to buckle but breaks movement
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	var/crash_all = FALSE //CHAOS
	var/car_traits = NONE //Bitflag for special behavior such as kidnapping
	var/engine_sound_length = 20 //Set this to the length of the engine sound

/obj/mecha/working/normalvehicle/Bump(atom/movable/A)
	. = ..()
	if(A.density && has_buckled_mobs())
		var/atom/throw_target = get_edge_target_turf(A, dir)
		if(crash_all)
			A.throw_at(throw_target, 4, 3)
			visible_message("<span class='danger'>[src] crashes into [A]!</span>")
			playsound(src, 'sound/effects/bang.ogg', 50, 1)
		if(ishuman(A))
			var/mob/living/carbon/human/H = A
			H.DefaultCombatKnockdown(50)
			H.adjustStaminaLoss(15)
			H.apply_damage(rand(10,15), BRUTE)
			if(!crash_all)
				H.throw_at(throw_target, 2, 3)
				visible_message("<span class='danger'>[src] crashes into [H]!</span>")
				playsound(src, 'sound/effects/bang.ogg', 50, 1)
		if(isliving(A))
			var/mob/living/W = A
			W.apply_damage(10, BRUTE)
			if(!crash_all)
				W.throw_at(throw_target, 1, 2)
				visible_message("<span class='danger'>[src] crashes into [W]!</span>")
				playsound(src, 'sound/effects/bang.ogg', 50, 1)

/obj/mecha/working/normalvehicle/vertibird
	name = "\improper Cargo Vertibird"
	desc = "A real useable, and working vertibird, maintained with luck, sweat, and ducktape. This one seems to be more focused toward combat."
	icon = 'icons/mecha/vb-vertibird.dmi'
	icon_state = "vb"
	pixel_x = -138
	pixel_y = -138
	layer = ABOVE_MOB_LAYER
	can_be_locked = TRUE
	dna_lock
	step_in = 0.6
	dir_in = 2
	normal_step_energy_drain = 0.75
	step_energy_drain = 0.75
	max_integrity = 150
	deflect_chance = 30
	armor = ARMOR_VALUE_LIGHT
	max_temperature = 25000
	infra_luminosity = 1
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	max_equip = 6
	opacity = 0
	canstrafe = TRUE
	movement_type = FLYING
	stepsound = 'sound/f13machines/vertibird_loop.ogg'
	turnsound = 'sound/f13machines/vertibird_loop.ogg'
	
	
	

/obj/structure/mecha_wreckage/vertibird
	name = "\improper Vertibird Wreck"
	desc = "Mayday, Mayday, Vertibird going down... IN STYLE."
	icon = 'icons/mecha/vb-vertibird.dmi'
	icon_state = "vb-broken"
	pixel_x = -138
	pixel_y = -138
 
/obj/mecha/working/normalvehicle/vertibird/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/working/normalvehicle/vertibird/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/working/normalvehicle/vertibird/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/working/normalvehicle/vertibird/proc/go_critical()
	explosion(get_turf(loc))
	Destroy(src)

/obj/mecha/working/normalvehicle/vertibird/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new 
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

///NCR VERTIBIRD

/obj/mecha/working/normalvehicle/vertibird/ncr
	name = "\improper NCR Cargo Vertibird"
	desc = "A real useable, and working vertibird, maintained with luck, sweat, and ducktape. This one seems to be more focused toward Troop transport, and his painted in the colors of the NCR."
	icon = 'icons/mecha/vb-vertibird-ncr.dmi'
	icon_state = "vb"
	pixel_x = -138
	pixel_y = -138
	layer = ABOVE_MOB_LAYER
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	dir_in = 2
	normal_step_energy_drain = 0.7
	step_energy_drain = 0.7
	max_integrity = 200
	deflect_chance = 30
	armor = ARMOR_VALUE_LIGHT
	max_temperature = 25000
	infra_luminosity = 1
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	max_equip = 8
	opacity = 0
	canstrafe = TRUE
	movement_type = FLYING
	stepsound = 'sound/f13machines/vertibird_loop.ogg'
	turnsound = 'sound/f13machines/vertibird_loop.ogg'
	
	
	

/obj/mecha/working/normalvehicle/vertibird/ncr/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	smoke_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/working/normalvehicle/vertibird/ncr/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	smoke_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/working/normalvehicle/vertibird/ncr/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/working/normalvehicle/vertibird/ncr/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new 
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

///VERTIBIRD ENCLAVE

/obj/mecha/working/normalvehicle/vertibird/enclave
	name = "\improper Enclave Naval Cargo Vertibird"
	desc = "A real useable, and working vertibird, maintained with luck, sweat, and ducktape. This one seems to be more focused toward combat, and be stored in a ship. Thats peak Enclave tech."
	icon = 'icons/mecha/vb-vertibird-enclave.dmi'
	icon_state = "vb"
	pixel_x = -138
	pixel_y = -138
	layer = ABOVE_MOB_LAYER
	can_be_locked = TRUE
	dna_lock
	step_in = 0.6
	dir_in = 2
	normal_step_energy_drain = 0.75
	step_energy_drain = 0.75
	max_integrity = 150
	deflect_chance = 30
	armor = ARMOR_VALUE_LIGHT
	max_temperature = 25000
	infra_luminosity = 1
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	max_equip = 6
	opacity = 0
	canstrafe = TRUE
	movement_type = FLYING
	stepsound = 'sound/f13machines/vertibird_loop.ogg'
	turnsound = 'sound/f13machines/vertibird_loop.ogg'

/obj/mecha/working/normalvehicle/vertibird/enclave/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/working/normalvehicle/vertibird/enclave/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/working/normalvehicle/vertibird/enclave/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/working/normalvehicle/vertibird/enclave/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new 
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

/// BOS Vertibird

/obj/mecha/working/normalvehicle/vertibird/brotherhood
	name = "\improper Brotherhood Cargo Vertibird"
	desc = "A real useable, and working vertibird, maintained with luck, sweat, and ducktape. This one seems to be more focused toward combat, and marked with brotherhood markings."
	icon = 'icons/mecha/vb-vertibird-bos.dmi'
	icon_state = "vb"
	pixel_x = -138
	pixel_y = -138
	layer = ABOVE_MOB_LAYER
	can_be_locked = TRUE
	dna_lock
	step_in = 0.6
	dir_in = 2
	normal_step_energy_drain = 0.75
	step_energy_drain = 0.75
	max_integrity = 150
	deflect_chance = 30
	armor = ARMOR_VALUE_LIGHT
	max_temperature = 25000
	infra_luminosity = 1
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	max_equip = 6
	opacity = 0
	canstrafe = TRUE
	movement_type = FLYING
	stepsound = 'sound/f13machines/vertibird_loop.ogg'
	turnsound = 'sound/f13machines/vertibird_loop.ogg'

/obj/mecha/working/normalvehicle/vertibird/brotherhood/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/working/normalvehicle/vertibird/brotherhood/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/working/normalvehicle/vertibird/brotherhood/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, it's going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/working/normalvehicle/vertibird/brotherhood/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new 
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

///Legion balloon

/obj/mecha/working/normalvehicle/vertibird/balloon
	name = "\improper Legion Transport balloon"
	desc = "The legion maybe doesn't have fancy birds, but will still by the will of Caesar, get wings... And hot air."
	icon = 'icons/mecha/legionballoon.dmi'
	icon_state = "legionballoon"
	pixel_x = -138
	pixel_y = 0
	layer = ABOVE_MOB_LAYER
	can_be_locked = TRUE
	dna_lock
	step_in = 4
	dir_in = 2
	step_energy_drain = 0.05
	max_integrity = 100
	deflect_chance = 0
	armor = ARMOR_VALUE_SALVAGE
	max_temperature = 25000
	infra_luminosity = 1
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	max_equip = 4
	opacity = 0
	canstrafe = TRUE
	movement_type = FLYING
	stepsound = 'sound/f13ambience/ambigen_15.ogg'
	turnsound = 'sound/f13ambience/ambigen_15.ogg'

/obj/mecha/working/normalvehicle/vertibird/balloon/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	smoke_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/working/normalvehicle/vertibird/balloon/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	smoke_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/working/normalvehicle/vertibird/balloon/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, "<span class='brass'> The balloon is going to crash!</span>")
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message("<span class = 'userdanger'>The balloon's burner is about to blow!</span>")
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/working/normalvehicle/vertibird/balloon/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new 
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

// NCR TRUCK

/obj/mecha/working/normalvehicle/ncrtruck
	name = "\improper NCR Truck"
	desc = "A truck running on fuel. Nice eh? Still a wreck, though."
	icon = 'icons/mecha/ncrtruck.dmi'
	icon_state = "ncrtruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.9
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 600
	armor = ARMOR_VALUE_HEAVY
	max_equip = 8
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/ncrtruck
	var/list/cargo = new
	var/cargo_capacity = 30
	var/hides = 0
	

/obj/structure/mecha_wreckage/ncrtruck
	name = "\improper Salvageable wreckage"
	desc = "It's a broken vehicule."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "derelict"

/obj/structure/mecha_wreckage/ncrtruck/engine
	name = "\improper Wreck under repair"
	desc = "A engine and battery are inside."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "repairstep1"
	anchored = 1

/obj/structure/mecha_wreckage/ncrtruck/seat
	name = "\improper Soon finished car"
	desc = "A seat, a engine and battery are inside."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "repairstep1"
	anchored = 1

/obj/mecha/working/normalvehicle/ncrtruck/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/ncrtruck/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/ncrtruck/Destroy()
	for(var/atom/movable/A in cargo)
		A.forceMove(drop_location())
		step_rand(A)
	cargo.Cut()
	return ..()

/obj/mecha/working/normalvehicle/ncrtruck/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/ncrtruck/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/ncrtruck/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)
	
//////////// NCR TRUCK MP //////////////

/obj/mecha/working/normalvehicle/ncrtruck/mp
	name = "\improper NCR MP Truck"
	desc = "A truck running on fuel. Nice eh? Still a wreck, though. This truck has been given to the NCR MPs, and has been modified to go a bit faster. But, it has less seats and is a bit less solid."
	icon = 'icons/mecha/ncrtruck-mp.dmi'
	icon_state = "ncrtruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.9
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 600
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/ncrtruck
	
	
	

/obj/mecha/working/normalvehicle/ncrtruck/mp/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/ncrtruck/mp/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/ncrtruck/mp/Destroy()
	for(var/atom/movable/A in cargo)
		A.forceMove(drop_location())
		step_rand(A)
	cargo.Cut()
	return ..()

/obj/mecha/working/normalvehicle/ncrtruck/mp/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/working/normalvehicle/ncrtruck/mp/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/working/normalvehicle/ncrtruck/mp/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

	//pickuptruck

/obj/mecha/working/normalvehicle/pickuptruck
	name = "\improper pickup truck"
	desc = "A old vehicle, running on fuel."
	icon = 'icons/mecha/pickuptruck.dmi'
	icon_state = "pickuptruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.4
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/pickuptruck/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/pickuptruck/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/pickuptruck/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck blue

/obj/mecha/working/normalvehicle/pickuptruck/blue
	name = "\improper pickup truck"
	desc = "A old vehicle, running on fuel."
	icon = 'icons/mecha/pickuptruck-blue.dmi'
	icon_state = "pickuptruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.4
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/pickuptruck/blue/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/blue/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/blue/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/pickuptruck/blue/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/pickuptruck/blue/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//pickuptruck bos

/obj/mecha/working/normalvehicle/pickuptruck/bos
	name = "\improper BoS pickup truck"
	desc = "A old vehicle, running on fuel."
	icon = 'icons/mecha/pickuptruck-bos.dmi'
	icon_state = "pickuptruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.4
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/pickuptruck/bos/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/bos/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/bos/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/pickuptruck/bos/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/pickuptruck/bos/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//truckcaravan

/obj/mecha/working/normalvehicle/truckcaravan
	name = "\improper Truck caravan"
	desc = "A vehicle, not very powerful or solid, running on fuel... Okay, that's a lie. It's pulled by two brahmins...The fuel is here to make sure that some component of the buggy half works."
	icon = 'icons/mecha/truckcaravan.dmi'
	icon_state = "truckcaravan"
	pixel_x = -20
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.6
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 250
	armor = ARMOR_VALUE_HEAVY
	max_equip = 2
	stepsound = 'sound/effects/footstep/gallop2.ogg'
	turnsound = 'sound/effects/footstep/gallop1.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/truckcaravan/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/truckcaravan/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/truckcaravan/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/truckcaravan/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/truckcaravan/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//pickuptruck mechanic

/obj/mecha/working/normalvehicle/pickuptruck/mechanic
	name = "\improper mechanic pickup truck"
	desc = "A old vehicule, with a crane runing on fuel."
	icon = 'icons/mecha/pickuptruck-mechanics.dmi'
	icon_state = "pickuptruckmechanic"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.4
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 150
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/pickuptruck/mechanic/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/mechanic/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/pickuptruck/mechanic/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/pickuptruck/mechanic/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/pickuptruck/mechanic/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

	//Ambulance 

/obj/mecha/working/normalvehicle/ambulance
	name = "\improper Ambulance"
	desc = "A Modified vehicule made to carry people in need to a hospital."
	icon = 'icons/mecha/ambulance.dmi'
	icon_state = "ambulance"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.15
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.5
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_HEAVY
	max_equip = 6
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	
	
	

/obj/mecha/working/normalvehicle/ambulance/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/ambulance/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()


/obj/mecha/working/normalvehicle/ambulance/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/working/normalvehicle/ambulance/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/working/normalvehicle/ambulance/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/medical/sleeper
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/medical/sleeper
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Buggy 

/obj/mecha/working/normalvehicle/buggy
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggygreen"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.4
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/structure/mecha_wreckage/buggy
	name = "\improper Buggy wreckage"
	desc = "Its a buggy! Won't bug you anymore."
	icon_state = "buggy-broken"

/obj/mecha/working/normalvehicle/buggy/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Buggydune

/obj/mecha/working/normalvehicle/buggy/dune
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggydune"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.4
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/buggy/dune/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/dune/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/dune/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/dune/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/dune/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Buggyred

/obj/mecha/working/normalvehicle/buggy/red
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyred"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.4
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/buggy/red/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/red/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/red/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/red/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/red/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyblue

/obj/mecha/working/normalvehicle/buggy/blue
	name = "\improper Minutemen Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyblue"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.4
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/buggy/blue/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/blue/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/blue/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/blue/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/blue/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Buggyflame

/obj/mecha/working/normalvehicle/buggy/flamme
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyflame"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.4
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/buggy/flamme/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/flamme/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/flamme/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/flamme/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/flamme/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Buggy Ranger

/obj/mecha/working/normalvehicle/buggy/ranger
	name = "\improper Ranger Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel. This one has been recolored by the Rangers."
	icon = 'icons/mecha/hanlonbuggy.dmi'
	icon_state = "hanlonbuggy"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.8
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.4
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/buggy/ranger/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/ranger/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/ranger/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/ranger/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/ranger/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Legion Chariot

/obj/mecha/working/normalvehicle/buggy/legion
	name = "\improper Legion Chariot"
	desc = "A light vehicle, not very powerful or solid, running on fuel... Okay, that's a lie. It's actually run on power generated by the horse... The fuel is here to make sure that some component of the buggy half works."
	icon = 'icons/mecha/buggy-legion.dmi'
	icon_state = "legionbuggy"
	pixel_x = -18
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.2
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.1
	max_temperature = 20000
	max_integrity = 250
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 2
	stepsound = 'sound/effects/footstep/gallop2.ogg'
	turnsound = 'sound/effects/footstep/gallop1.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/buggy/legion/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/legion/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/buggy/legion/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/buggy/legion/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/buggy/legion/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//jeep

/obj/mecha/working/normalvehicle/jeep
	name = "\improper pickup truck"
	desc = "A old vehicule, runing on fuel."
	icon = 'icons/mecha/jeep.dmi'
	icon_state = "jeep"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.35
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/jeep/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/jeep/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/jeep/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/jeep/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/jeep/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//jeep Enclave

/obj/mecha/working/normalvehicle/jeep/enclave
	name = "\improper pickup truck"
	desc = "A old military vehicule, runing on fuel., and recolored"
	icon = 'icons/mecha/jeepenclave.dmi'
	icon_state = "jeepenclave"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.35
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/jeep/enclave/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/jeep/enclave/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/jeep/enclave/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/jeep/enclave/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/jeep/enclave/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

///jeep BOS

/obj/mecha/working/normalvehicle/jeep/bos
	name = "\improper pickup truck"
	desc = "A old military vehicule, runing on fuel, and recolored"
	icon = 'icons/mecha/jeepbos.dmi'
	icon_state = "jeepbos"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.35
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/jeep/bos/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/jeep/bos/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/jeep/bos/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/jeep/bos/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/jeep/bos/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//Highwayman

/obj/mecha/working/normalvehicle/highwayman
	name = "\improper highwayman eco"
	desc = "A fast vehicle, running on fuel. YUP! IT'S THE HIGHWAYMAN! Kinda. It's not the original, but a budget version."
	icon = 'icons/mecha/highwayman.dmi'
	icon_state = "highwayman"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.7
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 250
	armor = list("melee" = 30, "bullet" = 25, "laser" = 20, "energy" = 20, "bomb" = 40, "bio" = 0, "rad" = 100, "fire" = 100, "acid" = 100)
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/highwayman/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/highwayman/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/highwayman/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/highwayman/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/highwayman/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//corvega

/obj/mecha/working/normalvehicle/corvega
	name = "\improper Corvega"
	desc = "A old vehicle, running on fuel."
	icon = 'icons/mecha/corvega.dmi'
	icon_state = "corvega"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.75
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 280
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 3
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/corvega/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/corvega/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/corvega/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/working/normalvehicle/corvega/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/working/normalvehicle/corvega/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

//corvega police

/obj/mecha/working/normalvehicle/corvega/police
	name = "\improper Police Corvega"
	desc = "A old vehicle, running on fuel. Seems to have been the proprety of the pre-war Yuma PD."
	icon = 'icons/mecha/corvega-police.dmi'
	icon_state = "corvega"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 0.75
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 280
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 3
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	
	
	

/obj/mecha/working/normalvehicle/corvega/police/go_out()
	..()
	update_icon()

/obj/mecha/working/normalvehicle/corvega/police/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/working/normalvehicle/corvega/police/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/working/normalvehicle/corvega/police/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/working/normalvehicle/corvega/police/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/trunk
	ME.attach(src)

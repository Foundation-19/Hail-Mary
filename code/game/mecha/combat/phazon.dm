/obj/mecha/combat/phazon
	name = "\improper Phazon"
	desc = "This is a Phazon exosuit. The pinnacle of scientific research and pride of Nanotrasen, it uses cutting edge bluespace technology and expensive materials."
	icon_state = "phazon"
	step_in = 2
	dir_in = 2 //Facing South.
	step_energy_drain = 3
	max_integrity = 200
	deflect_chance = 30
	armor = ARMOR_VALUE_HEAVY
	max_temperature = 25000
	infra_luminosity = 3
	wreckage = /obj/structure/mecha_wreckage/phazon
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	max_equip = 3
	phase_state = "phazon-phase"

/obj/mecha/combat/phazon/GrantActions(mob/living/user, human_occupant = 0)
	..()
	switch_damtype_action.Grant(user, src)
	phasing_action.Grant(user, src)


/obj/mecha/combat/phazon/RemoveActions(mob/living/user, human_occupant = 0)
	..()
	switch_damtype_action.Remove(user)
	phasing_action.Remove(user)

//////////// VERTIBIRD //////////////

/obj/mecha/combat/phazon/vertibird
	name = "\improper Vertibird"
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
 
/obj/mecha/combat/phazon/vertibird/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/combat/phazon/vertibird/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/combat/phazon/vertibird/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/proc/go_critical()
	explosion(get_turf(loc))
	Destroy(src)

/obj/mecha/combat/phazon/vertibird/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/medical/sleeper
	ME.attach(src)
	max_ammo()

///NCR VERTIBIRD

/obj/mecha/combat/phazon/vertibird/ncr
	name = "\improper NCR Vertibird"
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

/obj/mecha/combat/phazon/vertibird/ncr/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	smoke_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/combat/phazon/vertibird/ncr/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	smoke_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/combat/phazon/vertibird/ncr/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/ncr/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
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
	max_ammo()

///VERTIBIRD ENCLAVE

/obj/mecha/combat/phazon/vertibird/enclave
	name = "\improper Enclave Naval Vertibird"
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

/obj/mecha/combat/phazon/vertibird/enclave/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/combat/phazon/vertibird/enclave/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/combat/phazon/vertibird/enclave/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/enclave/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	max_ammo()

/// BOS Vertibird

/obj/mecha/combat/phazon/vertibird/brotherhood
	name = "\improper Brotherhood Vertibird"
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

/obj/mecha/combat/phazon/vertibird/brotherhood/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/combat/phazon/vertibird/brotherhood/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/combat/phazon/vertibird/brotherhood/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("The vertibird is going to crash!"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, it's going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/brotherhood/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	max_ammo()

///Legion balloon

/obj/mecha/combat/phazon/vertibird/balloon
	name = "\improper Legion Recon balloon"
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
	step_energy_drain = 0.2
	max_integrity = 100
	deflect_chance = 0
	armor = ARMOR_VALUE_HEAVY
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

/obj/mecha/combat/phazon/vertibird/balloon/GrantActions(mob/living/user, human_occupant = 0) 
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	zoom_action.Grant(user, src)
	eject_action.Grant(user, src)
	smoke_action.Grant(user, src)
	landing_action.Grant(user, src)

/obj/mecha/combat/phazon/vertibird/balloon/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	zoom_action.Remove(user)
	eject_action.Remove(user)
	smoke_action.Remove(user)
	landing_action.Remove(user)

/obj/mecha/combat/phazon/vertibird/balloon/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, "<span class='brass'> The balloon is going to crash!</span>")
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message("<span class = 'userdanger'>The balloon's burner is about to blow!</span>")
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/balloon/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat

//////////// NCR TRUCK //////////////

/obj/mecha/combat/phazon/ncrtruck
	name = "\improper NCR Truck"
	desc = "A truck running on fuel. Nice eh? Still a wreck, though."
	icon = 'icons/mecha/ncrtruck.dmi'
	icon_state = "ncrtruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1
	opacity = 0
	dir_in = 8
	step_energy_drain = 1
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
	name = "\improper NCR Truck wreckage"
	desc = "It's a truck! BROKEN TRUCK."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "derelict"

/obj/mecha/combat/phazon/ncrtruck/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/ncrtruck/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/ncrtruck/Destroy()
	for(var/atom/movable/A in cargo)
		A.forceMove(drop_location())
		step_rand(A)
	cargo.Cut()
	return ..()

/obj/mecha/combat/phazon/ncrtruck/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/ncrtruck/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/ncrtruck/loaded/Initialize()
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

//////////// NCR TRUCK MP //////////////

/obj/mecha/combat/phazon/ncrtruck/mp
	name = "\improper NCR MP Truck"
	desc = "A truck running on fuel. Nice eh? Still a wreck, though. This truck has been given to the NCR MPs, and has been modified to go a bit faster. But, it has less seats and is a bit less solid."
	icon = 'icons/mecha/ncrtruck-mp.dmi'
	icon_state = "ncrtruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1
	opacity = 0
	dir_in = 8
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 600
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/ncrtruck

/obj/mecha/combat/phazon/ncrtruck/mp/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/ncrtruck/mp/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/ncrtruck/mp/Destroy()
	for(var/atom/movable/A in cargo)
		A.forceMove(drop_location())
		step_rand(A)
	cargo.Cut()
	return ..()

/obj/mecha/combat/phazon/ncrtruck/mp/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/combat/phazon/ncrtruck/mp/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/combat/phazon/ncrtruck/mp/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy 

/obj/mecha/combat/phazon/buggy
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
	step_energy_drain = 1
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

/obj/mecha/combat/phazon/buggy/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggydune

/obj/mecha/combat/phazon/buggy/dune
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/dune/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/dune/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/dune/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/dune/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/dune/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyred

/obj/mecha/combat/phazon/buggy/red
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/red/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/red/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/red/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/red/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/red/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyblue

/obj/mecha/combat/phazon/buggy/blue
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/blue/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/blue/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/blue/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/blue/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/blue/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyflame

/obj/mecha/combat/phazon/buggy/flamme
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/flamme/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/flamme/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/flamme/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/flamme/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/flamme/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Ranger

/obj/mecha/combat/phazon/buggy/ranger
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/ranger/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/ranger/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/ranger/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/ranger/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/ranger/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Ranger AND RICO

/obj/mecha/combat/phazon/buggy/rangerarmed
	name = "\improper Vet Ranger Buggy with gunner"
	desc = "A light vehicle, not very powerful or solid, running on fuel. This one has been recolored by the Rangers... And Ranger Rico ''Gunner'' Davberger is gonna shoot with his shotgun."
	icon = 'icons/mecha/buggyrangergun.dmi'
	icon_state = "rangergun"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1
	opacity = 0
	dir_in = 8
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	max_equip = 3
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/rangerarmed/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/rangerarmed/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/rangerarmed/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	smoke_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/rangerarmed/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	smoke_action.Remove(user)

/obj/mecha/combat/phazon/buggy/rangerarmed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	ME.attach(src)
	max_ammo()

//Legion Chariot

/obj/mecha/combat/phazon/buggy/legion
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
	step_energy_drain = 0.8
	max_temperature = 20000
	max_integrity = 250
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 2
	stepsound = 'sound/effects/footstep/gallop2.ogg'
	turnsound = 'sound/effects/footstep/gallop1.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/legion/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/legion/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/legion/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/legion/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/buggy/legion/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Legion AND MESALLA

/obj/mecha/combat/phazon/buggy/legionarmed
	name = "\improper Legion Chariot with gunner"
	desc = "A light vehicle, not very powerful or solid, running on fuel... Okay, that's a lie. It's actually run on power generated by the horse...The fuel is here to make sure that some component of the buggy half works. This one has been recolored by the Legion... And Prime Decanus Messala ''Gunner'' Davius is gonna shoot with his shotgun."
	icon = 'icons/mecha/buggy-legiongun.dmi'
	icon_state = "legiongun"
	pixel_x = -18
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.2
	opacity = 0
	dir_in = 8
	step_energy_drain = 0.8
	max_temperature = 20000
	max_integrity = 250
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 3
	stepsound = 'sound/effects/footstep/gallop2.ogg'
	turnsound = 'sound/effects/footstep/gallop1.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/legionarmed/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/legionarmed/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/buggy/legionarmed/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	smoke_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/legionarmed/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	smoke_action.Remove(user)

/obj/mecha/combat/phazon/buggy/legionarmed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	ME.attach(src)
	max_ammo()

//Highwayman

/obj/mecha/combat/phazon/highwayman
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 250
	armor = list("melee" = 30, "bullet" = 25, "laser" = 20, "energy" = 20, "bomb" = 40, "bio" = 0, "rad" = 100, "fire" = 100, "acid" = 100)
	max_equip = 2
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/highwayman/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/highwayman/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/highwayman/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/highwayman/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/highwayman/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//corvega

/obj/mecha/combat/phazon/corvega
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 280
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 3
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/corvega/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/corvega/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/corvega/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/corvega/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/corvega/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//corvega police

/obj/mecha/combat/phazon/corvega/police
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
	step_energy_drain = 1.3
	max_temperature = 20000
	max_integrity = 280
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 3
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/corvega/police/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/corvega/police/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/corvega/police/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/combat/phazon/corvega/police/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/combat/phazon/corvega/police/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck

/obj/mecha/combat/phazon/pickuptruck
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/pickuptruck/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/pickuptruck/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck blue

/obj/mecha/combat/phazon/pickuptruck/blue
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/blue/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/blue/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/blue/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/pickuptruck/blue/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/pickuptruck/blue/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck bos

/obj/mecha/combat/phazon/pickuptruck/bos
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/bos/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/bos/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/bos/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/pickuptruck/bos/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/pickuptruck/bos/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck bos AND Kiana

/obj/mecha/combat/phazon/pickuptruck/bos/armed
	name = "\improper BoS pickup truck with gunner"
	desc = "A old vehicle, running on fuel. Its a modified brotherhood truck, with the addition of a laser rifle at the back, manned by Paladin Kiana Davberg. Consumes more fuel and is more fragile."
	icon = 'icons/mecha/pickuptruck-gunbos.dmi'
	icon_state = "pickuptruck"
	pixel_x = -15
	pixel_y = 0
	can_be_locked = TRUE
	dna_lock
	step_in = 1.4
	opacity = 0
	dir_in = 8
	step_energy_drain = 1.5
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/bos/armed/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/bos/armed/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/bos/armed/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/pickuptruck/bos/armed/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/pickuptruck/bos/armed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	
//truckcaravan

/obj/mecha/combat/phazon/truckcaravan
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
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 250
	armor = ARMOR_VALUE_HEAVY
	max_equip = 2
	stepsound = 'sound/effects/footstep/gallop2.ogg'
	turnsound = 'sound/effects/footstep/gallop1.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/truckcaravan/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/truckcaravan/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/truckcaravan/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/truckcaravan/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/truckcaravan/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck mechanic

/obj/mecha/combat/phazon/pickuptruck/mechanic
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
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 150
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/mechanic/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/mechanic/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/mechanic/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/pickuptruck/mechanic/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/pickuptruck/mechanic/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//jeep

/obj/mecha/combat/phazon/jeep
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

/obj/mecha/combat/phazon/jeep/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/jeep/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/jeep/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/jeep/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/jeep/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//jeep Enclave

/obj/mecha/combat/phazon/jeep/enclave
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

/obj/mecha/combat/phazon/jeep/enclave/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/jeep/enclave/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/jeep/enclave/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/jeep/enclave/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/jeep/enclave/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

///jeep BOS

/obj/mecha/combat/phazon/jeep/bos
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

/obj/mecha/combat/phazon/jeep/bos/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/jeep/bos/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/jeep/bos/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/jeep/bos/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/jeep/bos/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

	//Ambulance 

/obj/mecha/combat/phazon/ambulance
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
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_HEAVY
	max_equip = 5
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'

/obj/mecha/combat/phazon/ambulance/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/ambulance/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()


/obj/mecha/combat/phazon/ambulance/GrantActions(mob/living/user, human_occupant = 0) 
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/combat/phazon/ambulance/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/combat/phazon/ambulance/loaded/Initialize()
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

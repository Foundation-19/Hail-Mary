//////////// NCR TRUCK //////////////

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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 600
	armor = ARMOR_VALUE_HEAVY
	max_equip = 8
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/ncrtruck
	bound_width = 64
	bound_height = 64
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
	desc = "A engine and batery are inside."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "repairstep1"
	anchored = 1

/obj/structure/mecha_wreckage/ncrtruck/seat
	name = "\improper Soon finished car"
	desc = "A seat, a engine and batery are inside."
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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 600
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/ncrtruck
	bound_width = 64
	bound_height = 64

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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	bound_width = 64
	bound_height = 64

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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	bound_width = 64
	bound_height = 64

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
	step_energy_drain = 1
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_MEDIUM
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	bound_width = 64
	bound_height = 64

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
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 250
	armor = ARMOR_VALUE_HEAVY
	max_equip = 2
	stepsound = 'sound/effects/footstep/gallop2.ogg'
	turnsound = 'sound/effects/footstep/gallop1.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	bound_width = 64
	bound_height = 64

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
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 150
	armor = ARMOR_VALUE_HEAVY
	max_equip = 4
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy
	bound_width = 64
	bound_height = 64

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
	step_energy_drain = 0.6
	max_temperature = 20000
	max_integrity = 300
	armor = ARMOR_VALUE_HEAVY
	max_equip = 5
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	bound_width = 64
	bound_height = 64

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

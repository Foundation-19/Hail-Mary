//////////// VERTIBIRD //////////////

/obj/mecha/combat/phazon/vertibird
	name = "\improper Vertibird"
	desc = "A real useable, and working vertibird, maintained with luck, sweat, and ducktape. This one seems to be more focused toward combat."
	icon = 'icons/mecha/vb-vertibird.dmi'
	icon_state = "vb"
	pixel_x = -122
	pixel_y = -122
	layer = ABOVE_MOB_LAYER
	step_in = 0.6
	dir_in = 2
	step_energy_drain = 0.75
	max_integrity = 150
	armor = ARMOR_VALUE_VEHICLE_MEDIUM
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	internal_damage_threshold = 25
	max_utility_equip = 4
	max_weapons_equip = 4
	max_misc_equip = 2
	canstrafe = TRUE
	movement_type = FLYING
	stepsound = 'sound/f13machines/vertibird_loop.ogg'
	turnsound = 'sound/f13machines/vertibird_loop.ogg'

	facing_modifiers = list(FRONT_ARMOUR = 1, SIDE_ARMOUR = 1, BACK_ARMOUR = 1)

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
		to_chat(M, span_brass("The vertibird is going to Crash"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/proc/go_critical()
	explosion(get_turf(loc))
	Destroy(src)

/obj/mecha/combat/phazon/vertibird/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
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
	step_in = 0.8
	step_energy_drain = 0.7
	max_integrity = 200
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	max_utility_equip = 8
	max_weapons_equip = 1

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

/obj/mecha/combat/phazon/vertibird/ncr/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
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
	step_in = 0.6
	step_energy_drain = 0.75
	max_integrity = 150
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	max_utility_equip = 4
	max_weapons_equip = 4
	max_misc_equip = 2

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
		to_chat(M, span_brass(" The vertibird is going to Crash !"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/enclave/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
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
	step_in = 0.6
	step_energy_drain = 0.75
	max_integrity = 150
	wreckage = /obj/structure/mecha_wreckage/vertibird
	add_req_access = 1
	max_utility_equip = 4
	max_weapons_equip = 4
	max_misc_equip = 2

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
		to_chat(M, span_brass(" The vertibird is going to Crash !"))
		M.dust()
	playsound(src, 'sound//f13machines//vertibird_crash.ogg', 100, 0)
	src.visible_message(span_userdanger("The reactor has gone critical, its going to blow!"))
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/phazon/vertibird/brotherhood/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
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
	pixel_x = -125
	pixel_y = 0
	step_in = 4
	step_energy_drain = 0.2
	max_integrity = 100
	armor = ARMOR_VALUE_VEHICLE_HEAVY
	max_utility_equip = 6
	max_weapons_equip = 1
	max_misc_equip = 1
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

// Enclave Extraction Beacon
// Smoke grenade that signals vertibirds for extraction

/obj/item/extraction_beacon
	name = "Extraction Beacon"
	desc = "A smoke grenade that signals Enclave vertibirds for extraction."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "grenade"
	item_state = "flashbang"
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL

	var/activation_time = 30
	var/activated = FALSE
	var/activated_by = null

/obj/item/extraction_beacon/attack_self(mob/user)
	if(activated)
		to_chat(user, span_warning("Beacon is already activated!"))
		return

	if(!is_enclave_member(user))
		to_chat(user, span_warning("This beacon only responds to Enclave signals."))
		return

	to_chat(user, span_notice("You prime the extraction beacon. It will activate in [activation_time] seconds."))

	activated = TRUE
	activated_by = user.ckey
	icon_state = "grenade_active"

	addtimer(CALLBACK(src, PROC_REF(activate)), activation_time * 10)

/obj/item/extraction_beacon/proc/activate()
	if(!activated)
		return

	GLOB.active_beacons += src

	playsound(loc, 'sound/effects/smoke.ogg', 50)
	new /obj/effect/particle_effect/smoke(loc)

	visible_message(span_warning("Red smoke begins billowing from the beacon!"))

/obj/item/extraction_beacon/Destroy()
	GLOB.active_beacons -= src
	return ..()

/obj/item/extraction_beacon/proc/is_enclave_member(mob/user)
	if(!user.mind)
		return FALSE
	if(!user.mind.assigned_role)
		return FALSE

	var/list/enclave_roles = list(
		"Enclave Soldier",
		"Enclave Scientist",
		"Enclave Officer",
		"Enclave Commander"
	)

	return user.mind.assigned_role in enclave_roles

// Supply Drop Beacon

/obj/item/supply_beacon
	name = "Supply Drop Beacon"
	desc = "A smoke grenade that signals Enclave vertibirds for supply drops."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "smokewhite"
	item_state = "flashbang"
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL

	var/activation_time = 20
	var/activated = FALSE
	var/activated_by = null

/obj/item/supply_beacon/attack_self(mob/user)
	if(activated)
		to_chat(user, span_warning("Beacon is already activated!"))
		return

	if(!is_enclave_member(user))
		to_chat(user, span_warning("This beacon only responds to Enclave signals."))
		return

	to_chat(user, span_notice("You prime the supply beacon. It will activate in [activation_time] seconds."))

	activated = TRUE
	activated_by = user.ckey
	icon_state = "grenade_active"

	addtimer(CALLBACK(src, PROC_REF(activate)), activation_time * 10)

/obj/item/supply_beacon/proc/activate()
	if(!activated)
		return

	GLOB.active_beacons += src

	playsound(loc, 'sound/effects/smoke.ogg', 50)
	new /obj/effect/particle_effect/smoke(loc)

	visible_message(span_warning("Green smoke begins billowing from the beacon!"))

/obj/item/supply_beacon/Destroy()
	GLOB.active_beacons -= src
	return ..()

/obj/item/supply_beacon/proc/is_enclave_member(mob/user)
	if(!user.mind)
		return FALSE
	if(!user.mind.assigned_role)
		return FALSE

	var/list/enclave_roles = list(
		"Enclave Soldier",
		"Enclave Scientist",
		"Enclave Officer",
		"Enclave Commander"
	)

	return user.mind.assigned_role in enclave_roles

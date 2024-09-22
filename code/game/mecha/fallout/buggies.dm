//Buggy

/obj/mecha/combat/phazon/buggy
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggygreen"
	pixel_x = -15
	pixel_y = -5
	max_integrity = 200
	step_in = 0.8
	armor = ARMOR_VALUE_LIGHT
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/structure/mecha_wreckage/buggy
	name = "\improper Buggy wreckage"
	desc = "Its a buggy ! Won't bug you anymore."
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
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggydune"
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/dune/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyred

/obj/mecha/combat/phazon/buggy/red
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyred"
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/red/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyflame

/obj/mecha/combat/phazon/buggy/flamme
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyflame"
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/flamme/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Ranger

/obj/mecha/combat/phazon/buggy/ranger
	name = "\improper Ranger Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell. This one as been recolored by the Rangers."
	icon = 'icons/mecha/hanlonbuggy.dmi'
	icon_state = "hanlonbuggy"
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/buggy/ranger/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Ranger AND RICO

/obj/mecha/combat/phazon/buggy/rangerarmed
	name = "\improper Vet Ranger Buggy with gunner"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell. This one as been recolored by the Rangers... And Ranger Rico ''Gunner'' Davberger is gonna shoot with his shotgun."
	icon = 'icons/mecha/buggyrangergun.dmi'
	icon_state = "rangergun"
	max_integrity = 200
	armor = ARMOR_VALUE_LIGHT
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

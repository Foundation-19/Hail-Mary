//Fallout 13 decorative billboards directory

/obj/structure/billboard
	name = "billboard"
	desc = "Shitspawn detected!<br>Please report the admin abuse immediately!<br>Just kidding, nevermind."
	icon_state = "null"
	density = 1
	anchored = 1
	layer = 5
	icon = 'icons/obj/Ritas.dmi'
	bound_width = 64
	resistance_flags = INDESTRUCTIBLE

/obj/structure/billboard/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 1, y_size = 1)


/obj/structure/billboard/ritas
	name = "Rita's Cafe billboard"
	desc = "A defaced pre-War ad for Rita's Cafe.<br>The wasteland has taken its toll on the board."
	icon_state = "ritas1"

/obj/structure/billboard/ritas/New()
	..()
	icon_state = pick("ritas2","ritas3","ritas4")

/obj/structure/billboard/ritas/pristine
	name = "pristine Rita's Cafe billboard"
	desc = "A pre-War ad for Rita's Cafe.<br>Oddly enough, it's good as new."
	icon_state = "ritas1"

/obj/structure/billboard/ritas/pristine/New()
	..()
	icon_state = "ritas1"

/obj/structure/billboard/cola
	name = "Nuka-Cola billboard"
	desc = "A defaced pre-War ad for Nuka-Cola.<br>The wasteland has taken its toll on the board."
	icon_state = "cola1"

/obj/structure/billboard/cola/New()
	..()
	icon_state = pick("cola2","cola3","cola4")

/obj/structure/billboard/cola/pristine
	name = "pristine Nuka-Cola billboard"
	desc = "A pre-War ad for Nuka-Cola.<br>Oddly enough, it's good as new."
	icon_state = "cola1"

/obj/structure/billboard/cola/pristine/New()
	..()
	icon_state = "cola1"

/obj/structure/billboard/cola/cola_shop
	name = "pristine Nuka-Cola billboard"
	desc = "A pre-War ad for Nuka-Cola.<br>Oddly enough, it's good as new."
	icon_state = "cola_shop"

/obj/structure/billboard/cola/cola_shop/New()
	..()
	icon_state = "cola_shop"

//Taken from removed F13billboards.dm
/obj/structure/billboard/den
	name = "\improper The Den sign"
	desc =  "A sprayed metal sheet that says \"The Den \"."
	icon_state = "den"

/obj/structure/billboard/klamat
	name = "Klamat sign"
	desc =  "A ruined sign that says \"Klamat \"."
	icon_state = "klamat"

/obj/structure/tarphorizontal
	name = "tarp tent"
	desc = "Tarp, sweet tarp."
	icon_state = "1"
	density = FALSE
	anchored = TRUE
	layer = FLY_LAYER
	icon = 'icons/fallout/objects/tarpaulinhorizontal.dmi'
	bound_width = 64
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

/*obj/structure/tarphorizontal/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 2, y_size = 1)*/

/obj/structure/tarphorizontalbase
	name = "tarp tent"
	desc = "Tarp, sweet tarp."
	icon_state = "base"
	density = FALSE
	anchored = TRUE
	layer = 3.9
	icon = 'icons/fallout/objects/tarpaulinhorizontal.dmi'
	bound_width = 96
	bound_height = 96
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

 /*obj/structure/tarphorizontalbase/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 3, y_size = 2) */

/obj/structure/tarpvertical
	name = "tarp tent"
	desc = "Tarp, sweet tarp."
	icon_state = "1"
	density = FALSE
	anchored = TRUE
	layer = FLY_LAYER
	icon = 'icons/fallout/objects/tarpaulin.dmi'
	bound_width = 96
	bound_height = 96
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

/obj/structure/tarpvertical/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 2, y_size = 2)

/obj/structure/fukbus
	name = "Fuk Bus"
	desc = "An old school bus with a REPCONN rocket attached to it."
	density = FALSE
	anchored = TRUE
	layer = FLY_LAYER
	icon = 'icons/fallout/objects/fukbus.dmi'
	icon_state = "fukbus"
	bound_width = 256
	bound_height = 64
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

/obj/structure/fukbus/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 6, y_size = 1)

/obj/structure/fukbusreverse
	name = "Fuk Bus"
	desc = "An old school bus with a REPCONN rocket attached to it."
	density = FALSE
	anchored = TRUE
	layer = FLY_LAYER
	icon = 'icons/fallout/objects/fukbus.dmi'
	icon_state = "fukbus"
	bound_width = 64
	resistance_flags = INDESTRUCTIBLE

/obj/structure/fukbusreverse/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = -5, y_size = 1)

/obj/structure/redrocketroof
	name = "Red Rocket"
	desc = "Drive in, fly out!"
	density = FALSE
	anchored = TRUE
	layer = FLY_LAYER
	icon = 'icons/fallout/objects/redrocketredux.dmi'
	icon_state = "redrocketbits"
	bound_width = 448
	bound_height = 160
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

/obj/structure/driveinscreen
	name = "drive-in screen"
	desc = "A blank projector screen."
	density = TRUE
	anchored = TRUE
	layer = LATTICE_LAYER
	icon = 'icons/fallout/objects/redrocketredux.dmi'
	icon_state = "drivein"
	bound_width = 224
	bound_height = 64
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1
	var/mutable_appearance/driveinscreenoverlay

/obj/structure/driveinscreen/Initialize()
	. = ..()
	driveinscreenoverlay = mutable_appearance(icon, "[icon_state]overlay", ABOVE_ALL_MOB_LAYER)
	add_overlay(driveinscreenoverlay)

/obj/structure/bustransparency
	name = "wrecked bus"
	desc = "An old pre-war vehicle, rusted and destroyed with age and weathering."
	density = FALSE
	anchored = TRUE
	layer = FLY_LAYER
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "bus"
	bound_width = 64
	bound_height = 32
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

/obj/structure/bustransparency/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 1, y_size = 0)

/obj/structure/billboardstatic
	name = "billboard"
	icon_state = "null"
	density = TRUE
	anchored = TRUE
	layer = LATTICE_LAYER
	icon = 'icons/obj/Ritas.dmi'
	bound_width = 64
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1
	var/mutable_appearance/billboardstaticoverlay

/obj/structure/billboardstatic/Initialize()
	. = ..()
	billboardstaticoverlay = mutable_appearance(icon, "[icon_state]overlay", ABOVE_ALL_MOB_LAYER)
	add_overlay(billboardstaticoverlay)

// ID locked Fallout doors, CANNOT be padlocked. Its a sort of simulated key and lock system for semi-public areas.
// Unpowered being as the name says, simple mechanical doors. Works exactly like airlocks, and less space age, so better.

/obj/machinery/door/unpowered
	icon = 'icons/fallout/structures/doors.dmi'
	armor = ARMOR_VALUE_LIGHT
	autoclose = 5 SECONDS // Difficulty: Monkey to reduce amount of secure doors left open.
	max_integrity = 500
	obj_integrity = 500
	req_one_access_txt = null // Add the channel for the ID you want to lock this door to, check defines.

/obj/machinery/door/unpowered/Bumped(atom/movable/AM)
	if(src.locked)
		return
	..()
	return

/obj/machinery/door/unpowered/attackby(obj/item/I, mob/user, params)
	if(locked)
		return
	else
		return ..()


// ------------------------------------
// SECURE DOOR

/obj/machinery/door/unpowered/securedoor
	name = "secure door"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "secure"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	opacity = TRUE
	explosion_block = TRUE

/obj/machinery/door/unpowered/securedoor/update_icon()
	if(density)
		icon_state = "secure"
	else
		icon_state = "secureopen"

/obj/machinery/door/unpowered/securedoor/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("secure_opening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("secure_closing", src)


// SECURE DOOR - LEGION

/obj/machinery/door/unpowered/securedoor/legion
	name = "Legion Castrum"
	req_access_txt = "123"

//khoor
/obj/machinery/door/unpowered/securedoor/khandoor
	name = "khan door"
	req_access_txt = "125"

//bikoor
/obj/machinery/door/unpowered/securedoor/bikerdoor
	name = "Hell's Nomad door"
	req_access = list(ACCESS_BIKER)


// ------------------------------------
// NCR SECURE REINFORCED DOOR - tough airlock replacement

/obj/machinery/door/unpowered/secure_NCR
	name = "reinforced door"
	desc = "Solid oak and metal reinforcements make this style of door a favoured method to secure Republic buildings. Has a built in lock."
	icon_state = "secure_NCR"
	assemblytype = /obj/item/stack/sheet/metal/ten
	max_integrity = 800
	obj_integrity = 800
	explosion_block = TRUE
	req_access_txt = "121"

/obj/machinery/door/unpowered/secure_NCR/update_icon()
	if(density)
		icon_state = "secure_NCR"
	else
		icon_state = "secure_NCR_open"

/obj/machinery/door/unpowered/secure_NCR/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("secure_NCR_opening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("secure_NCR_closing", src)


// ------------------------------------
// SECURE STEEL DOOR - tougher

/obj/machinery/door/unpowered/secure_steeldoor
	name = "locked steel door"
	desc = "Steel-plated door with a built-in lock. Can't be padlocked."
	icon_state = "secure_steel"
	assemblytype = /obj/item/stack/sheet/metal/ten
	max_integrity = 1000
	obj_integrity = 1000
	explosion_block = TRUE

/obj/machinery/door/unpowered/secure_steeldoor/update_icon()
	if(density)
		icon_state = "secure_steel"
	else
		icon_state = "secure_steel_open"

/obj/machinery/door/unpowered/secure_steeldoor/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("secure_steel_opening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("secure_steel_closing", src)


// ------------------------------------
// CELL DOOR

/obj/machinery/door/unpowered/celldoor
	name = "cell door"
	desc = "Celldoor with a built-in lock. Can't be padlocked."
	icon_state = "cell"
	max_integrity = 1000
	obj_integrity = 1000
	assemblytype = /obj/item/stack/rods
	visible = FALSE
	explosion_block = FALSE
	pass_flags = LETPASSTHROW  // would be great but the var is not functional for some reason.
	proj_pass_rate = 95

/obj/machinery/door/unpowered/celldoor/update_icon()
	if(density)
		icon_state = "cell"
	else
		icon_state = "cellopen"

/obj/machinery/door/unpowered/celldoor/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/f13machines/doorchainlink_open.ogg',40,1)
			flick("cell_opening", src)
		if("closing")
			playsound(src,'sound/f13machines/doorchainlink_close.ogg',40,1)
			flick("cell_closing", src)


// CELL DOOR - LEGION

/obj/machinery/door/unpowered/celldoor/legion
	name = "Prison door"
	req_access_txt = "123"


// ------------------------------------
// LEGION SECURE REINFORCED DOOR - tough airlock replacement

/obj/machinery/door/unpowered/secure_legion
	name = "iron gate"
	desc = "Thick iron rods with sharp tips make for a fearsome gate."
	icon_state = "secure_legion"
	max_integrity = 800
	obj_integrity = 800
	assemblytype = /obj/item/stack/rods
	visible = FALSE
	explosion_block = FALSE
	proj_pass_rate = 95
	req_access_txt = "123"

/obj/machinery/door/unpowered/secure_legion/update_icon()
	if(density)
		icon_state = "secure_legion"
	else
		icon_state = "secure_legion_open"

/obj/machinery/door/unpowered/secure_legion/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/f13machines/doorchainlink_open.ogg',40,1)
			flick("secure_legion_opening", src)
		if("closing")
			playsound(src,'sound/f13machines/doorchainlink_close.ogg',40,1)
			flick("secure_legion_closing", src)


// ------------------------------------
// BOS SECURE REINFORCED DOOR - tough airlock replacement

/obj/machinery/door/unpowered/secure_bos
	name = "steel security door"
	desc = "Hard steel makes a statement. The statement in this case is stay out."
	icon_state = "secure_bos"
	max_integrity = 1000
	obj_integrity = 1000
	assemblytype = /obj/item/stack/sheet/metal/ten
	req_access_txt = "120"

/obj/machinery/door/unpowered/secure_bos/update_icon()
	if(density)
		icon_state = "secure_bos"
	else
		icon_state = "secure_bos_open"

/obj/machinery/door/unpowered/secure_bos/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("secure_bos_opening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("secure_bos_closing", src)

/obj/machinery/door/unpowered/uspsdoor
	name = "secure door"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "glass"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	visible = FALSE
	explosion_block = TRUE

/obj/machinery/door/unpowered/uspsdoor/update_icon()
	if(density)
		icon_state = "glass"
	else
		icon_state = "glassopen"

/obj/machinery/door/unpowered/uspsdoor/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("glassopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("glassclosing", src)

/obj/machinery/door/unpowered/uspsdoortwo
	name = "secure door"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "brokenglass"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	visible = FALSE
	explosion_block = TRUE

/obj/machinery/door/unpowered/uspsdoortwo/update_icon()
	if(density)
		icon_state = "brokenglass"
	else
		icon_state = "brokenglassopen"

/obj/machinery/door/unpowered/uspsdoortwo/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("brokenglassopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("brokenglassclosing", src)


/obj/machinery/door/unpowered/uspsdoorthree
	name = "secure door"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "dirtyglass"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	visible = FALSE
	explosion_block = TRUE

/obj/machinery/door/unpowered/uspsdoorthree/update_icon()
	if(density)
		icon_state = "dirtyglass"
	else
		icon_state = "dirtyglassopen"

/obj/machinery/door/unpowered/uspsdoorthree/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("dirtyglassopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("dirtyglassclosing", src)

/obj/machinery/door/unpowered/latterdaysaints // a door with transparency for a specific part of the map's visuals
	name = "temple door"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "houseclean"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	visible = FALSE
	explosion_block = TRUE

/obj/machinery/door/unpowered/latterdaysaints/update_icon()
	if(density)
		icon_state = "houseclean"
	else
		icon_state = "housecleanopen"

/obj/machinery/door/unpowered/latterdaysaints/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("housecleanopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("housecleanclosing", src)

/obj/machinery/door/unpowered/house
	name = "white door"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "houseclean"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	explosion_block = TRUE

/obj/machinery/door/unpowered/house/update_icon()
	if(density)
		icon_state = "houseclean"
	else
		icon_state = "housecleanopen"

/obj/machinery/door/unpowered/house/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("housecleanopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("housecleanclosing", src)

/obj/machinery/door/unpowered/employeedoor
	name = "employees only"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "metal"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	opacity = TRUE
	explosion_block = TRUE

/obj/machinery/door/unpowered/employeedoor/update_icon()
	if(density)
		icon_state = "metal"
	else
		icon_state = "metalopen"

/obj/machinery/door/unpowered/employeedoor/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("metalopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("metalclosing", src)

/obj/machinery/door/unpowered/montegobay
	name = "employees only"
	desc = "Door with a built-in lock. Can't be padlocked."
	icon_state = "room"
	assemblytype = /obj/item/stack/sheet/mineral/wood/five
	opacity = TRUE
	explosion_block = TRUE

/obj/machinery/door/unpowered/montegobay/update_icon()
	if(density)
		icon_state = "room"
	else
		icon_state = "roomopen"

/obj/machinery/door/unpowered/montegobay/do_animate(animation)
	switch(animation)
		if("opening")
			playsound(src,'sound/machines/door_open.ogg',40,1)
			flick("roomopening", src)
		if("closing")
			playsound(src,'sound/machines/door_close.ogg',40,1)
			flick("roomclosing", src)

GLOBAL_LIST_EMPTY(vault_doors)

/obj/structure/vaultdoor
	name = "vault door 113"
	icon = 'icons/obj/doors/gear.dmi'
	icon_state = "closed"
	density = TRUE
	opacity = 1
	layer = WALL_OBJ_LAYER
	anchored = TRUE

	var/is_busy = FALSE
	var/destroyed = FALSE
	var/isworn = FALSE
	var/is_open = FALSE
	max_integrity = 1000
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF | INDESTRUCTIBLE  //it's a fucking steel blast door
	armor = list("melee" = 95, "bullet" = 75, "laser" = 75, "energy" = 75, "bomb" = 95, "bio" = 100, "rad" = 100, "fire" = 99, "acid" = 100) //it's a fucking steel door 2.0

/obj/structure/vaultdoor/Initialize()
	. = ..()
	LAZYADD(GLOB.vault_doors, src)

/obj/structure/vaultdoor/Destroy()
	LAZYREMOVE(GLOB.vault_doors, src)
	return ..()

/obj/structure/vaultdoor/blob_act()
	ex_act(4)
	return

/obj/structure/vaultdoor/ex_act(severity, target)
	// if(severity == 2) // Removing the 1/4th chance for vaults to explode open, this is not a funny meeme.
	// 	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	// 	s.set_up(2, 1, src)
	// 	s.start()
	// 	if(prob(25)) //Get memed
	// 		destroy()
	// 	return
	return

/obj/structure/vaultdoor/proc/repair()
	icon_state = "open"
	set_opacity(1)
	src.density = FALSE
	is_busy = FALSE
	is_open = TRUE
	obj_integrity = 50
	destroyed = FALSE
	isworn = FALSE

/obj/structure/vaultdoor/proc/destroy()
	icon_state = "empty"
	set_opacity(0)
	src.density = FALSE
	destroyed = TRUE

/obj/structure/vaultdoor/obj_destruction() //No you can't just shoot it and expect it to break
	destroy()

/obj/structure/vaultdoor/proc/open()
	is_busy = TRUE
	flick("opening", src)
	icon_state = "open"
	playsound(loc, 'sound/f13machines/doorgear_open.ogg', 50, 0, 10)
	sleep(30)
	set_opacity(0)
	src.density = FALSE
	is_busy = FALSE
	is_open = TRUE

/obj/structure/vaultdoor/proc/close()
	is_busy = TRUE
	flick("closing", src)
	icon_state = "closed"
	playsound(loc, 'sound/f13machines/doorgear_close.ogg', 50, 0, 10)
	sleep(30)
	set_opacity(1)
	src.density = TRUE
	is_busy = FALSE
	is_open = FALSE

/obj/structure/vaultdoor/proc/vaultactivate()
	if(destroyed)
		to_chat(usr, span_warning("[src] is broken"))
		return
	if(is_busy)
		to_chat(usr, span_warning("[src] is busy"))
		return
	if(density)
		open()
		return
	close()

/obj/structure/vaultdoor/attackby(obj/item/I, mob/living/user, params)
	add_fingerprint(user)
	if(icon_state == "empty") //Its brok, fix it
		if(istype(I, /obj/item/weldingtool) && user.a_intent == INTENT_HELP)
			if(I.use_tool(src, user, 40, volume=50))
				repair()
	if(istype(I, /obj/item/weldingtool) && user.a_intent == INTENT_HELP)
		if(obj_integrity < max_integrity)
			if(!I.tool_start_check(user, amount=0))
				return

			to_chat(user, span_notice("You begin repairing [src]..."))
			if(I.use_tool(src, user, 40, volume=50))
				obj_integrity += 50 //Only heal it slightly
				to_chat(user, span_notice("You repair [src]."))
		else
			to_chat(user, span_warning("[src] is already in good condition!"))
		return

//ß íå õî÷ó ïåðåäåëûâàòü ýòî äåðüìî  - Google translate tells me that from Russian to english this is "Do not move your arms around this way." so dont.





/obj/machinery/doorButtons/vaultButton
	name = "vault access"
	icon = 'icons/obj/lever.dmi'
	icon_state = "lever0"
	anchored = TRUE
	density = TRUE
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF | INDESTRUCTIBLE

/obj/machinery/doorButtons/vaultButton/proc/activate()
	for(var/obj/structure/vaultdoor/vdoor in world)
		vdoor.vaultactivate()

/obj/machinery/doorButtons/vaultButton/attackby(obj/item/weapon/W, mob/user, params)
	activate()

/obj/machinery/doorButtons/vaultButton/attack_hand(mob/user)
	activate()
	message_admins("[ADMIN_LOOKUPFLW(user)] pressed the vault door button at [ADMIN_VERBOSEJMP(user.loc)].")

//new vault door button
/obj/machinery/doorButtons/wornvaultButton
	name = "worn vault access"
	icon = 'icons/obj/lever.dmi'
	icon_state = "lever0"
	anchored = TRUE
	density = TRUE
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF | INDESTRUCTIBLE

/obj/machinery/doorButtons/wornvaultButton/proc/activate()
	for(var/obj/structure/vaultdoor/vdoor in world)
		if(vdoor.isworn == TRUE)
			vdoor.vaultactivate()

/obj/machinery/doorButtons/wornvaultButton/attackby(obj/item/weapon/W, mob/user, params)
	activate()

/obj/machinery/doorButtons/wornvaultButton/attack_hand(mob/user)
	activate()


// ==================== Merged from fallout (code\modules\fallout\obj\structures\vault_door.dm) ====================
//Fallout 13 Vault blast doors and controls directory

/obj/structure/vault_door
	name = "Vault 113 blast door"
	desc = "A conventional Vault blast door of \"Nine cog\" model.<br>A blast door design incorporates proper sealants against radiation and other hazardous elements that may be created in the event of a nuclear war, to properly protect its inhabitants."
	icon = 'icons/machines/gear.dmi'
	icon_state = "113closed"
	density = 1
	opacity = 1
	plane = MOB_PLANE
	layer = ABOVE_ALL_MOB_LAYER
	anchored = 1
	var/is_busy = 0
	var/destroyed = 0
	var/id = 1
	var/close_state = "113closed"
	var/open_state = "113open"
	var/closing_state = "113closing"
	var/opening_state = "113opening"
	var/broken_state = "113empty"
	pixel_x = -32
	pixel_y = -32
	obj_integrity = -1
	max_integrity = -1
	integrity_failure = 0

/obj/structure/vault_door/old
	name = "\proper ancient Vault blast door"
	icon_state = "oldclosed"
	close_state = "oldclosed"
	open_state = "oldopen"
	closing_state = "oldclosing"
	opening_state = "oldopening"
	broken_state = "oldempty"

/obj/structure/vault_door/obj_break(damage_flag)
	icon_state = broken_state
	src.set_opacity(0)
	src.density = 0
	destroyed = 1

/obj/structure/vault_door/proc/open()
	is_busy = 1
	flick(opening_state, src)
	icon_state = open_state
	spawn(11)
		playsound(loc, 'sound/f13machines/doorgear_open.ogg', 50, 0, 10)
		spawn(19)
			src.set_opacity(0)
			src.density = 0
			is_busy = 0
/obj/structure/vault_door/proc/close()
	is_busy = 1
	flick(closing_state, src)
	icon_state = close_state
	spawn(11)
		playsound(loc, 'sound/f13machines/doorgear_close.ogg', 50, 0, 10)
		spawn(19)
			src.set_opacity(1)
			src.density = 1
			is_busy = 0

/obj/structure/vault_door/proc/toggle()
	if(destroyed)
		usr << span_warning("[src] is broken.")
		return
	if(is_busy)
		usr << span_warning("[src] is busy.")
		return
	if (density)
		open()
		return
	close()

//Lever

/obj/machinery/doorButtons/vaultButton
	name = "Vault access panel"
	desc = "Pull the lever to open the door - it's that simple."
	icon = 'icons/machines/lever.dmi'
	icon_state = "lever"
	anchored = 1
	density = 1
	var/id = 1

/obj/machinery/doorButtons/vaultButton/proc/toggle_door()
	var/opened
	icon_state = "lever0"
	for(var/obj/structure/vault_door/door in GLOB.vault_doors)
		if(door.id == id)
			door.toggle()
			opened = !door.density
	spawn(50)
		if(opened)
			icon_state = "lever2"
		else
			icon_state = "lever"

/obj/machinery/doorButtons/vaultButton/attackby(obj/item/weapon/W, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	attack_hand(user)

/obj/machinery/doorButtons/vaultButton/attack_hand(mob/user)
	..()
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(C.handcuffed)
			return
	toggle_door()

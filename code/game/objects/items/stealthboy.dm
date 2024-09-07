/obj/item/stealthboy
	name = "Stealth Boy MK1"
	desc = "The RobCo Stealth Boy 3001 is a personal stealth device, this one is designed to be worn on your belt and the battery can be taken out if you can find an ALTERNATIVE way to CLICK the back open and take the battery out. (alt click to take the battery out and recharge it)"
	icon = 'icons/fallout/objects/stealthboy.dmi'
	icon_state = "stealth_boy"
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_SMALL
	var/obj/item/stock_parts/cell/cell = /obj/item/stock_parts/cell/high
	var/use_per_tick = 400 // normal cell has 10000 charge, 200 charge/second = 50 seconds of stealth
	var/on = FALSE
	actions_types = list(/datum/action/item_action/stealthboy_cloak)


// Below are Variants of stealth boys that should be increased power usage and less below that one. However I dont know how to make that happen, so they are all the same.
/obj/item/stealthboy/makeshift
	name = "Makeshift Stealth Boy"
	icon_state = "makeshift_stealth"
	use_per_tick = 800

/obj/item/stealthboy/mk2
	name = "Stealth Boy MK2"
	icon_state = "stealth_boy_mk"
	use_per_tick = 200

/obj/item/stealthboy/Initialize()
	. = ..()
	if(ispath(cell))
		cell = new cell(src)

/obj/item/stealthboy/Destroy()
	. = ..()
	var/mob/living/carbon/human/user = loc
	if(ishuman(user))
		user.alpha = initial(user.alpha)

/obj/item/stealthboy/ui_action_click(mob/user)
	if(!ishuman(user))
		return
	if(user.get_item_by_slot(SLOT_BELT) == src)
		on = !on
		if(on)
			Activate(user)
		else
			Deactivate(user)
	return

/obj/item/stealthboy/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return ..()
	eject_cell(user)
	return

/obj/item/stealthboy/proc/eject_cell(mob/living/user)
	if(!cell)
		to_chat(user, span_warning("[src] has no cell installed."))
		return
	if(on && user.get_item_by_slot(SLOT_BELT) == src)
		Deactivate(user)
	cell.add_fingerprint(user)
	user.put_in_hands(cell)
	user.show_message(span_notice("You remove [cell]."))
	cell = null

/obj/item/stealthboy/proc/insert_cell(mob/living/user, obj/item/stock_parts/cell/new_cell)
	if(cell)
		eject_cell(user)
	if(user.transferItemToLoc(new_cell, src))
		cell = new_cell
		to_chat(user, span_notice("You successfully install \the [cell] into [src]."))

/obj/item/stealthboy/attackby(obj/item/I, mob/living/carbon/human/user, params)
	if(istype(I, /obj/item/stock_parts/cell))
		insert_cell(user, I)
		return
	. = ..()

/obj/item/stealthboy/item_action_slot_check(slot, mob/user)
	if(slot == SLOT_BELT)
		return 1

/obj/item/stealthboy/examine(mob/user)
	. = ..()
	if(istype(cell))
		. += "The charge meter reads [round(cell.percent() )]%."

/obj/item/stealthboy/proc/Activate(mob/living/carbon/human/user)
	if(!user)
		Deactivate(FALSE)
		return
	if(!istype(cell))
		user.show_message(span_alert("There's no cell in [src]!"))
		Deactivate(FALSE)
		return
	if(!cell.use(use_per_tick))
		user.show_message(span_alert("There's not enough power in [src]'s [cell.name]!"))
		Deactivate(FALSE)
		return
	to_chat(user, span_notice("You activate \The [src]."))
	animate(user, alpha = 60, time = 3 SECONDS)
	START_PROCESSING(SSobj, src)
	on = TRUE

/obj/item/stealthboy/proc/Deactivate(mob/living/carbon/human/user)
	if(!ishuman(user))
		user = loc
		if(!ishuman(user))
			return
	animate(user, alpha = initial(user.alpha), time = 3 SECONDS)
	to_chat(user, span_notice("You deactivate \The [src]."))
	STOP_PROCESSING(SSobj, src)
	on = FALSE

/obj/item/stealthboy/dropped(mob/user)
	..()
	Deactivate(user)

/obj/item/stealthboy/equipped(mob/user, slot)
	. = ..()
	if(user?.get_item_by_slot(SLOT_BELT) != src)
		Deactivate(user)

/obj/item/stealthboy/process()
	var/mob/living/carbon/human/user = loc
	if(!ishuman(user) || user.get_item_by_slot(SLOT_BELT) != src)
		Deactivate()
		return
	if((!istype(cell) || !cell?.use(use_per_tick)))
		Deactivate(user)
		return

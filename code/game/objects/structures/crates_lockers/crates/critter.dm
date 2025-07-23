/obj/structure/closet/critter
	name = "animal carrier"
	desc = "A crate designed for safe transport of animals."
	icon = 'icons/obj/crates.dmi'
	icon_state = "crittercrate"
	horizontal = FALSE
	allow_objects = FALSE
	breakout_time = 600
	material_drop = /obj/item/stack/sheet/mineral/wood
	material_drop_amount = 4
	delivery_icon = "deliverybox"
	max_mob_size = MOB_SIZE_LARGE

/obj/structure/closet/critter/update_icon_state()
	return

/obj/structure/closet/critter/closet_update_overlays(list/new_overlays)
	. = new_overlays
	if(opened)
		. += "crittercrate_door_open"
	else
		. += "crittercrate_door"

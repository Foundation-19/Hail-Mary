/obj/structure/sign
	icon = 'icons/obj/decals.dmi'
	anchored = TRUE
	opacity = 0
	density = FALSE
	plane = ABOVE_WALL_PLANE
	layer = SIGN_LAYER
	max_integrity = 100
	armor = ARMOR_VALUE_MEDIUM
	var/buildable_sign = 1 //unwrenchable and modifiable
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/structure/sign/basic
	name = "blank sign"
	desc = "How can signs be real if our eyes aren't real?"
	icon_state = "backing"

//////////
//LEGION//
//////////

/obj/structure/sign/legion
	name = "war room"
	desc = "For planning the next great victory!"
	icon = 'icons/obj/clothing/icons_legion.dmi'
	icon_state = "sign"
	layer = SIGN_LAYER

/obj/structure/sign/legion/radio
	name = "radio room"
	desc = "Spare radios and radio linking equipment are kept here"

/obj/structure/sign/legion/medicus
	name = "medicus tent"
	desc = "Caesar approves the methods used here. Degenerates not welcome."
	icon_state = "sign_medicus"
	layer = BELOW_MOB_LAYER

/obj/structure/sign/legion/recruit
	name = "recruit barracks"
	desc = "The decanus sleeps with his men and keeps track of them."
	icon_state = "sign_ground"

/obj/structure/sign/legion/smithy
	name = "smithy"
	desc = "Where weapons are forged and tools stored"

/obj/structure/sign/legion/armory
	name = "armory"
	desc = "Great amounts of weapons and equipment are stored here"

/obj/structure/sign/legion/prime
	name = "prime barracks"
	desc = "Primes and their decanus live here"
	icon_state = "sign_ground"

/obj/structure/sign/legion/veteran
	name = "veteran barracks"
	desc = "Experienced troops live here in comparable comfort."

/obj/structure/sign/legion/mess
	name = "mess pavillion"
	desc = "Food and a place to talk to brothers in arms."
	icon_state = "sign_ground"

/obj/structure/sign/legion/gym
	name = "the temple"
	desc = "Build your body or use it as a speaking platform."

/obj/structure/sign/legion/latrine
	name = "latrine"
	desc = "Has a certain odor."
	icon_state = "sign_ground"

/obj/structure/sign/legion/mines
	name = "mines"
	desc = "Put slave here"
	icon_state = "sign_chain"

/obj/structure/sign/legion/prison
	name = "prison"
	desc = "Lets the prisoner enjoy the local climate without interfering roofing."
	icon_state = "sign_ground"

/obj/structure/sign/legion/storeroom
	name = "storeroom"
	desc = "a place to store low-value goods and slaving equipment."

/obj/structure/sign/legion/records
	name = "office of records"
	desc = "Where the Treasurer and other nerds store paperwork about stores and payrolls, and maybe the treasury."

/obj/structure/sign/legion/stronghold
	name = "stronghold"
	desc = "Main building, fortified."

/obj/structure/sign/legion/guardhouse
	name = "guardhouse"
	desc = "Sit in the gloom and wait for something to happen."

/obj/structure/sign/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(src.loc, 'sound/weapons/slash.ogg', 80, 1)
			else
				playsound(loc, 'sound/weapons/tap.ogg', 50, 1)
		if(BURN)
			playsound(loc, 'sound/items/welder.ogg', 80, 1)

/obj/structure/sign/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/wrench) && buildable_sign)
		user.visible_message(span_notice("[user] starts removing [src]..."), \
							span_notice("You start unfastening [src]."))
		I.play_tool_sound(src)
		if(I.use_tool(src, user, 40))
			playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
			user.visible_message(span_notice("[user] unfastens [src]."), \
								span_notice("You unfasten [src]."))
			var/obj/item/sign_backing/SB = new (get_turf(user))
			SB.icon_state = icon_state
			SB.set_custom_materials(custom_materials) //This is here so picture frames and wooden things don't get messed up.
			SB.sign_path = type
			SB.setDir(dir)
			qdel(src)
		return
	else if(istype(I, /obj/item/pen) && buildable_sign)
		var/list/sign_types = list("Secure Area", "Biohazard", "High Voltage", "Radiation", "Hard Vacuum Ahead", "Disposal: Leads To Space", "Danger: Fire", "No Smoking", "Medbay", "Science", "Chemistry", \
		"Hydroponics", "Xenobiology")
		var/obj/structure/sign/sign_type
		switch(input(user, "Select a sign type.", "Sign Customization") as null|anything in sign_types)
			if("Blank")
				sign_type = /obj/structure/sign/basic
			if("Secure Area")
				sign_type = /obj/structure/sign/warning/securearea
			if("Biohazard")
				sign_type = /obj/structure/sign/warning/biohazard
			if("High Voltage")
				sign_type = /obj/structure/sign/warning/electricshock
			if("Radiation")
				sign_type = /obj/structure/sign/warning/radiation
			if("Hard Vacuum Ahead")
				sign_type = /obj/structure/sign/warning/vacuum
			if("Disposal: Leads To Space")
				sign_type = /obj/structure/sign/warning/deathsposal
			if("Danger: Fire")
				sign_type = /obj/structure/sign/warning/fire
			if("No Smoking")
				sign_type = /obj/structure/sign/warning/nosmoking/circle
			if("Medbay")
				sign_type = /obj/structure/sign/departments/medbay/alt
			if("Science")
				sign_type = /obj/structure/sign/departments/science
			if("Chemistry")
				sign_type = /obj/structure/sign/departments/chemistry
			if("Hydroponics")
				sign_type = /obj/structure/sign/departments/botany
			if("Xenobiology")
				sign_type = /obj/structure/sign/departments/xenobio

		//Make sure user is adjacent still
		if(!Adjacent(user))
			return

		if(!sign_type)
			return

		//It's import to clone the pixel layout information
		//Otherwise signs revert to being on the turf and
		//move jarringly
		var/obj/structure/sign/newsign = new sign_type(get_turf(src))
		newsign.pixel_x = pixel_x
		newsign.pixel_y = pixel_y
		qdel(src)
	else
		return ..()

/obj/item/sign_backing
	name = "sign backing"
	desc = "A sign with adhesive backing."
	icon = 'icons/obj/decals.dmi'
	icon_state = "backing"
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE
	var/sign_path = /obj/structure/sign/basic //the type of sign that will be created when placed on a turf

/obj/item/sign_backing/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(isturf(target) && proximity)
		var/turf/T = target
		user.visible_message(span_notice("[user] fastens [src] to [T]."), \
							span_notice("You attach the sign to [T]."))
		playsound(T, 'sound/items/deconstruct.ogg', 50, 1)
		var/obj/structure/sign/S = new sign_path(T)
		S.setDir(dir)
		qdel(src)

/obj/item/sign_backing/Move(atom/new_loc, direct = 0)
	// pulling, throwing, or conveying a sign backing does not rotate it
	var/old_dir = dir
	. = ..()
	setDir(old_dir)

/obj/item/sign_backing/attack_self(mob/user)
	. = ..()
	setDir(turn(dir, 90))

/obj/structure/sign/nanotrasen
	name = "\improper Navitron Logo"
	desc = "A sign with the Navitron Logo on it. Why save Earth, when we have space!"
	icon_state = "nanotrasen"

/obj/structure/sign/logo
	name = "nanotrasen logo"
	desc = "The Nanotrasen corporate logo."
	icon_state = "nanotrasen_sign1"

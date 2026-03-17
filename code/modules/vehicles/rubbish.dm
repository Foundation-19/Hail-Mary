/obj/structure/statue_fal
	name = "Ranger statue"
	desc = "A big ranger statue."
	icon = 'icons/fallout/objects/structures/statue.dmi'
	icon_state = "statue1"
	bound_width = 64
	bound_height = 64
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE

/obj/structure/statue_fal/Initialize()
	. = ..()
	AddComponent(/datum/component/largetransparency, x_size = 1, y_size = 2)

//Fallout 13 rubish decoration

/obj/structure/car
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This car is damaged beyond repair."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "car_rubish1"
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE
	bound_height = 64
	bound_width = 64
	var/uses_left = 2
	var/inuse = FALSE



/obj/structure/car/welder_act(mob/living/user, obj/item/I)
	. = TRUE

	if(inuse || uses_left <= 0) //this means that if mappers or admins want an nonharvestable version, set the uses_left to 0
		return
	inuse = TRUE //one at a time boys, this isn't some kind of weird party
	if(!I.tool_start_check(user, amount=0)) //this seems to be called everywhere, so for consistency's sake
		inuse = FALSE
		return //the tool fails this check, so stop
	user.visible_message("[user] starts disassembling [src].")
	if(!I.use_tool(src, user, 10 SECONDS, volume=100))
		user.visible_message("[user] stops disassembling [src].")
		inuse = FALSE
		return //you did something, like moving, so stop
	var/fake_dismantle = pick("plating", "rod", "rim", "part of the frame")
	user.visible_message("[user] slices through a [fake_dismantle].")

	var/turf/usr_turf = get_turf(user) //Bellow are the changes made by PR#256
	var/modifier = 0
	if(HAS_TRAIT(user,TRAIT_TECHNOPHREAK))
		modifier += rand(1,3)
	var/obj/item/l = user.get_inactive_held_item()
	if(istype(l,/obj/item/weldingtool))
		var/obj/item/weldingtool/WO = l
		if(WO.tool_start_check(user, amount=3))
			WO.use(3)
			modifier++
	for(var/i2 in 1 to (2+modifier))
		new /obj/item/salvage/low(usr_turf)
	for(var/i3 in 1 to (1+modifier)) //this is just less lines for the same thing
		if(prob(6))
			new /obj/item/salvage/high(usr_turf)
	uses_left--
	inuse = FALSE //putting this after the -- because the first check prevents cheesing
	if(uses_left <= 0) //I prefer to put any qdel stuff at the very end, with src being the very last thing
		visible_message("[src] falls apart, the final components having been removed.")
		qdel(src)


/obj/structure/car/rubbish1
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This car is damaged beyond repair."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "car_rubish1"
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE

/obj/structure/car/rubbish1alt
	icon_state = "car_rubish12"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish2
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This car is damaged beyond repair."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "car_rubish2"
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE

/obj/structure/car/rubbish2alt
	icon_state = "car_rubish22"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish3
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This car might be repairable."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "car_rubish3"
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE

/obj/structure/car/rubbish3alt
	icon_state = "car_rubish32"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish4
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This car is damaged beyond repair."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "car_rubish4"
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE

/obj/structure/car/rubbish5
	icon_state = "car_rubish5"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish6
	icon_state = "car_rubish6"
	bound_width = 32
	bound_height = 32
	layer = WALL_OBJ_LAYER

/obj/structure/car/rubbish7
	icon_state = "car_rubish7"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish8
	icon_state = "notsorubbish"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish9_1
	icon_state = "rubbish_lights"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish9_2
	icon_state = "rubbish_lights2"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish10
	icon = 'icons/fallout/objects/structures/car_light.dmi'
	icon_state = "rubbish10"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish11
	icon_state = "rubbish11"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/rubbish_lights
	icon = 'icons/fallout/objects/structures/car_light.dmi'
	icon_state = "rubbish_lights"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/derelict
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "derelict"
	bound_height = 32
	pixel_y = -4
	layer = LATTICE_LAYER

/obj/structure/car/derelict/alt
	icon_state = "derelict2"

/obj/structure/car/motoryclevert
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This motorcycle is damaged beyond repair."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "bike_rust_med_no_wheels"
	bound_height = 32
	bound_width = 32
	layer = ABOVE_MOB_LAYER

/obj/structure/car/motoryclevert/light
	icon_state = "rust_light_no_wheels"

/obj/structure/car/motoryclevert/green
	icon_state = "bike_no_wheels"

/obj/structure/car/motoryclevert/med
	icon_state = "bike_rust_med_no_wheels"

/obj/structure/car/motoryclehor
	name = "pre-War rubbish"
	desc = "A rusty pre-War automobile carcass.<br>This motorcycle is damaged beyond repair."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "rust_light_no_wheels"
	bound_height = 32
	layer = ABOVE_MOB_LAYER

/obj/structure/car/motoryclehor/light
	icon_state = "rust_light_no_wheels"

/obj/structure/car/motoryclehor/green
	icon_state = "bike_no_wheels"

/obj/structure/car/motoryclehor/med
	icon_state = "bike_rust_med_no_wheels"

/obj/structure/car/totaledbuggy
	name = "totaled buggy"
	desc = "A totaled buggy."
	icon = 'icons/fallout/vehicles/centeredsmaller.dmi'
	icon_state = "junk_red"
	layer = ABOVE_MOB_LAYER

/obj/structure/car/totaledbuggy/dune
	icon_state = "junk_dune"

/obj/structure/car/totaledbuggy/olive
	icon_state = "junk_olive"

/obj/structure/car/totaledbuggy/hot
	icon_state = "junk_hot"

/obj/structure/car/junk
	desc = "Old pre-war junk, salvageable for parts with a welder."
	bound_width = 32
	bound_height = 32

/obj/structure/car/junk/pod
	name = "Empty Protectron Pod"
	icon = 'icons/mob/nest_new.dmi'
	icon_state = "scanner_modified"

/obj/structure/car/junk/generator
	name = "generator"
	icon = 'icons/obj/machines/gravity_generator.dmi'
	icon_state = "fix2_6"

/obj/structure/car/junk/generator/alt
	icon_state = "fix2_4"

/obj/structure/car/junk/emitter
	name = "Prototype Emitter"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "protoemitter"

/obj/structure/car/junk/focuser
	name = "Particle Focusing EM Lens"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "power_box"

/obj/structure/car/junk/smes
	name = "broken electrical equipment"
	icon = 'icons/obj/power.dmi'
	icon_state = "smes"

/obj/structure/car/junk/computer
	name = "strange device"
	icon = 'icons/obj/computer.dmi'
	icon_state = "lunar"

/obj/structure/car/junk/atm
	name = "strange device"
	icon = 'icons/obj/money_machine.dmi'
	icon_state = "bogdanoff"

/obj/structure/car/junk/airfilt
	name = "air filtration system"
	icon = 'icons/fallout/turfs/walls/subway.dmi'
	icon_state = "subwaytopmiddlealt"
	density = FALSE
	layer = LATTICE_LAYER
	pixel_y = 29

/obj/structure/car/junk/panel
	name = "pipe panel"
	icon = 'icons/fallout/objects/structures/wallmounts.dmi'
	icon_state = "pipes_1"
	density = FALSE
	layer = LATTICE_LAYER
	pixel_y = 32

/obj/structure/car/junk/xray
	name = "film viewer"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "xray"
	density = FALSE
	layer = LATTICE_LAYER
	pixel_y = 32


/obj/structure/debris/v1
	name = "pre-War building debris"
	desc = "A pre-War building debris."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "debris1"
	bound_width = 64
	bound_height = 64
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE


/obj/structure/debris/v2
	name = "pre-War building debris"
	desc = "A pre-War building debris."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "debris2"
	bound_width = 64
	bound_height = 64
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE


/obj/structure/debris/v3
	name = "pre-War building debris"
	desc = "A pre-War building debris."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "debris3"
	bound_width = 64
	bound_height = 64
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE


/obj/structure/debris/v4
	name = "pre-War building debris"
	desc = "A pre-War building debris."
	icon = 'icons/fallout/objects/structures/rubish.dmi'
	icon_state = "debris4"
	bound_width = 64
	bound_height = 64
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE

//Fallout 13 dune buggy directory

/obj/vehicle/ridden/motorcycle/buggy
	name = "dune buggy"
	desc = "An 80s war buggy."
	icon = 'icons/fallout/vehicles/centeredsmaller.dmi'
	icon_state = "buggy_dune"
	layer = VEHICLE_FRAME_LAYER
	anchored = FALSE
	pixel_x = -32
	obj_integrity = 600
	max_integrity = 600
	key_type = /obj/item/key/buggy
	max_buckled_mobs = 2 // this does nothing and max occupants allows more mobs to buckle but breaks movement
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	var/crash_all = FALSE //CHAOS
	var/car_traits = NONE //Bitflag for special behavior such as kidnapping
	var/engine_sound = 'sound/vehicles/carrev.ogg'
	var/last_enginesound_time
	var/engine_sound_length = 20 //Set this to the length of the engine sound

/obj/vehicle/ridden/motorcycle/buggy/Initialize()
	. = ..()
	var/datum/component/riding/D = LoadComponent(/datum/component/riding)
	D.vehicle_move_delay = 1.25
	D.set_riding_offsets(1, list(TEXT_NORTH = list(0, 9), TEXT_SOUTH = list(0, 11), TEXT_EAST = list(-3, 8), TEXT_WEST = list(7, 8)))
	D.set_riding_offsets(2, list(TEXT_NORTH = list(0, 9), TEXT_SOUTH = list(0, 11), TEXT_EAST = list(-3, 8), TEXT_WEST = list(7, 8)))
	D.set_vehicle_dir_layer(SOUTH, VEHICLE_FRAME_LAYER)
	D.set_vehicle_dir_layer(NORTH, VEHICLE_FRAME_LAYER)
	D.set_vehicle_dir_layer(EAST, VEHICLE_FRAME_LAYER)
	D.set_vehicle_dir_layer(WEST, VEHICLE_FRAME_LAYER)
	D.directional_vehicle_offsets = list(TEXT_NORTH = list(-32, 0), TEXT_SOUTH = list(-32, 0), TEXT_EAST = list(-32, 0), TEXT_WEST = list(-32, 0))
	D.set_vehicle_bound_width(bound_width, list(TEXT_NORTH = 32, TEXT_SOUTH = 32, TEXT_EAST = 64, TEXT_WEST = 64))
	D.set_vehicle_bound_height(bound_height, list(TEXT_NORTH = 64, TEXT_SOUTH = 64, TEXT_EAST = 32, TEXT_WEST = 32))
	D.allow_one_away_from_valid_turf = FALSE
	D.buckled_layer = VEHICLE_MOB_LAYER
	carunderlay = mutable_appearance(icon, "[icon_state]_underlay", VEHICLE_LAYER)
	wheelunderlay = mutable_appearance(icon, "[icon_state]wheels", VEHICLE_WHEEL_LAYER)
	add_overlay(carunderlay)
	add_overlay(wheelunderlay)

/obj/vehicle/ridden/motorcycle/buggy/Moved()
	. = ..()
	if(world.time < last_enginesound_time + engine_sound_length)
		return
	last_enginesound_time = world.time
	playsound(src, engine_sound, 100, TRUE)
	if(has_buckled_mobs())
		for(var/atom/A in range(0, src)) // set this back to 1 if 0 doesn't have intended effect urist
			if(!(A in buckled_mobs))
				Bump(A)

obj/vehicle/ridden/motorcycle/buggy/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(user != buckled_mob)
		visible_message("<span class='warning'>[user] starts to unbuckle [buckled_mob] from [src]!</span>")
		if(do_after(user, 50, 1, target = buckled_mob, required_mobility_flags = MOBILITY_RESIST))
			return ..()
		else
			visible_message("<span class='warning'>[user] fails to unbuckle [buckled_mob] from [src]!</span>")
			return
	if(user == buckled_mob)
		unbuckle_mob(buckled_mob, user)
	return

/obj/vehicle/ridden/motorcycle/buggy/post_buckle_mob(mob/living/M)
	. = ..()
	var/datum/component/riding/D = LoadComponent(/datum/component/riding)
	D.equip_buckle_inhands(M, 1, M)

/*obj/vehicle/ridden/motorcycle/buggy/driver_move(mob/user, direction)
	if(world.time < last_enginesound_time + engine_sound_length)
		return
	last_enginesound_time = world.time
	playsound(src, engine_sound, 100, TRUE)

/obj/vehicle/ridden/motorcycle/buggy/MouseDrop_T(atom/dropping, mob/living/M)
	if(!istype(M) || !CHECK_MOBILITY(M, MOBILITY_USE))
		return FALSE
	if(isliving(dropping) && M != dropping)
		var/mob/living/L = dropping
		L.visible_message("<span class='warning'>[M] starts forcing [L] into [src]!</span>")
		mob_try_forced_enter(M, L)
	return ..()

/obj/vehicle/ridden/motorcycle/buggy/mob_try_exit(mob/M, mob/user, silent = FALSE)
	if(M == user && (occupants[M] & VEHICLE_CONTROL_KIDNAPPED))
		to_chat(user, "<span class='notice'>You push against the back of [src] trunk to try and get out.</span>")
		if(!do_after(user, escape_time, target = src))
			return FALSE
		to_chat(user,"<span class='danger'>[user] gets out of [src]</span>")
		mob_exit(M, silent)
		return TRUE
	mob_exit(M, silent)
	return TRUE

/obj/vehicle/ridden/motorcycle/buggy/proc/mob_try_forced_enter(mob/forcer, mob/M, silent = FALSE)
	if(!istype(M))
		return FALSE
	if(occupant_amount() >= max_occupants)
		return FALSE
	if(do_mob(forcer, get_enter_delay(M), target = src))
		mob_forced_enter(M, silent)
		return TRUE
	return FALSE

/obj/vehicle/ridden/motorcycle/buggy/proc/mob_forced_enter(mob/M, silent = FALSE)
	if(!silent)
		M.visible_message("<span class='warning'>[M] is forced into \the [src]!</span>")
	M.forceMove(src)
	add_occupant(M, VEHICLE_CONTROL_KIDNAPPED)*/

/obj/item/key/buggy
	name = "car key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'

/obj/item/key/buggy/tugbug
	name = "Tugbug key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'
	icon_state = "key"

/obj/item/key/buggy/greenmachine
	name = "Green Machine key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'
	icon_state = "key-bike-g"

/obj/item/key/buggy/rustbucket
	name = "Rustbucket key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'
	icon_state = "key-buggy-b"

/obj/item/key/buggy/rezrocket
	name = "Fender Bender key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'
	icon_state = "key-buggy-r"

/obj/item/key/buggy/bluebird
	name = "Bluebird key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'
	icon_state = "key-bike-b"

/obj/item/key/buggy/hotrod
	name = "Hotrod key"
	desc = "A keyring with a small steel key.<br>By the look of the key cuts, it likely belongs to an automobile."
	icon = 'icons/fallout/vehicles/small_vehicles.dmi'
	icon_state = "key-bike-y"

/obj/item/key/buggy/New()
	..()
	icon_state = pick("key-buggy-r","key-buggy-y","key-buggy-g","key-buggy-b")

/obj/item/key/buggy/wheel //I am the man... Who grabs the sun... RIDING TO VALHALLA!
	name = "steering wheel"
	desc = "A vital part of an automobile that is made of metal and decorated with a freaky skull.<br>Oh, what a day... What a lovely day for taking a ride!"
	icon_state = "wheel"

/obj/item/key/buggy/wheel/New()
	..()
	icon_state = "wheel"

/obj/vehicle/ridden/motorcycle/buggy/Bump(atom/movable/A)
	. = ..()
	if(A.density && has_buckled_mobs())
		var/atom/throw_target = get_edge_target_turf(A, dir)
		if(crash_all)
			A.throw_at(throw_target, 4, 3)
			visible_message("<span class='danger'>[src] crashes into [A]!</span>")
			playsound(src, 'sound/effects/bang.ogg', 50, 1)
		if(ishuman(A))
			var/mob/living/carbon/human/H = A
			H.DefaultCombatKnockdown(50)
			H.adjustStaminaLoss(15)
			H.apply_damage(rand(10,15), BRUTE)
			if(!crash_all)
				H.throw_at(throw_target, 2, 3)
				visible_message("<span class='danger'>[src] crashes into [H]!</span>")
				playsound(src, 'sound/effects/bang.ogg', 50, 1)
		if(isliving(A))
			var/mob/living/W = A
			W.apply_damage(10, BRUTE)
			if(!crash_all)
				W.throw_at(throw_target, 1, 2)
				visible_message("<span class='danger'>[src] crashes into [W]!</span>")
				playsound(src, 'sound/effects/bang.ogg', 50, 1)

/obj/vehicle/ridden/motorcycle/buggy/red
	icon_state = "buggy_red"
	key_type = /obj/item/key/janitor

/obj/vehicle/ridden/motorcycle/buggy/olive
	icon_state = "buggy_olive"
	key_type = /obj/item/key/buggy/greenmachine

/obj/vehicle/ridden/motorcycle/buggy/hot
	icon_state = "buggy_hot"
	key_type = /obj/item/key/buggy/hotrod

/obj/vehicle/ridden/motorcycle/buggy/dune
	icon_state = "buggy_dune"
	key_type = /obj/item/key/buggy/rustbucket

/obj/vehicle/ridden/motorcycle/buggy/tug
	icon_state = "buggy_tug"
	key_type = /obj/item/key/buggy/tugbug

/obj/vehicle/ridden/motorcycle/buggy/rezrocket
	icon_state = "buggy_rez"
	key_type = /obj/item/key/buggy/tugbug

/obj/vehicle/ridden/motorcycle/buggy/bluebird
	icon_state = "buggy_blue"
	key_type = /obj/item/key/buggy/bluebird

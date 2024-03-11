/obj/machinery/abductor/pad
	name = "Alien Telepad"
	desc = "Use this to transport to and from the humans' habitat."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "alien-pad-idle"
	var/turf/teleport_target

TYPE_PROC_REF(/obj/machinery/abductor/pad, Warp)(mob/living/target)
	if(!target.buckled)
		target.forceMove(get_turf(src))

TYPE_PROC_REF(/obj/machinery/abductor/pad, Send)()
	if(teleport_target == null)
		teleport_target = GLOB.teleportlocs[pick(GLOB.teleportlocs)]
	flick("alien-pad", src)
	for(var/mob/living/target in loc)
		target.forceMove(teleport_target)
		new /obj/effect/temp_visual/dir_setting/ninja(get_turf(target), target.dir)
		to_chat(target, span_warning("The instability of the warp leaves you disoriented!"))
		target.Stun(60)

TYPE_PROC_REF(/obj/machinery/abductor/pad, Retrieve)(mob/living/target)
	flick("alien-pad", src)
	new /obj/effect/temp_visual/dir_setting/ninja(get_turf(target), target.dir)
	Warp(target)

TYPE_PROC_REF(/obj/machinery/abductor/pad, doMobToLoc)(place, atom/movable/target)
	flick("alien-pad", src)
	target.forceMove(place)
	new /obj/effect/temp_visual/dir_setting/ninja(get_turf(target), target.dir)

TYPE_PROC_REF(/obj/machinery/abductor/pad, MobToLoc)(place,mob/living/target)
	new /obj/effect/temp_visual/teleport_abductor(place)
	addtimer(CALLBACK(src, PROC_REF(doMobToLoc), place, target), 80)

TYPE_PROC_REF(/obj/machinery/abductor/pad, doPadToLoc)(place)
	flick("alien-pad", src)
	for(var/mob/living/target in get_turf(src))
		target.forceMove(place)
		new /obj/effect/temp_visual/dir_setting/ninja(get_turf(target), target.dir)

TYPE_PROC_REF(/obj/machinery/abductor/pad, PadToLoc)(place)
	new /obj/effect/temp_visual/teleport_abductor(place)
	addtimer(CALLBACK(src, PROC_REF(doPadToLoc), place), 80)

/obj/effect/temp_visual/teleport_abductor
	name = "Huh"
	icon = 'icons/obj/abductor.dmi'
	icon_state = "teleport"
	duration = 80

/obj/effect/temp_visual/teleport_abductor/Initialize()
	. = ..()
	var/datum/effect_system/spark_spread/S = new
	S.set_up(10,0,loc)
	S.start()

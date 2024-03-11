GLOBAL_LIST_INIT(valid_blobstrains, subtypesof(/datum/blobstrain) - list(/datum/blobstrain/reagent, /datum/blobstrain/multiplex))

/datum/blobstrain
	var/name
	var/description
	var/color = "#000000"
	var/complementary_color = "#000000" //a color that's complementary to the normal blob color
	var/shortdesc = null //just damage and on_mob effects, doesn't include special, blob-tile only effects
	var/effectdesc = null //any long, blob-tile specific effects
	var/analyzerdescdamage = "Unknown. Report this bug to a coder, or just adminhelp."
	var/analyzerdesceffect = "N/A"
	var/blobbernaut_message = "slams" //blobbernaut attack verb
	var/message = "The blob strikes you" //message sent to any mob hit by the blob
	var/message_living = null //extension to first mob sent to only living mobs i.e. silicons have no skin to be burnt
	var/core_regen = 2
	var/resource_delay = 0
	var/point_rate = 2
	var/mob/camera/blob/overmind

/datum/blobstrain/New(mob/camera/blob/new_overmind)
	if (!istype(new_overmind))
		stack_trace("blobstrain created without overmind")
	overmind = new_overmind

TYPE_PROC_REF(/datum/blobstrain, on_gain)()
	overmind.color = complementary_color
	for(var/BL in GLOB.blobs)
		var/obj/structure/blob/B = BL
		B.update_icon()
	for(var/BLO in overmind.blob_mobs)
		var/mob/living/simple_animal/hostile/blob/BM = BLO
		BM.update_icons() //If it's getting a new strain, tell it what it does!
		to_chat(BM, "Your overmind's blob strain is now: <b><font color=\"[color]\">[name]</b></font>!")
		to_chat(BM, "The <b><font color=\"[color]\">[name]</b></font> strain [shortdesc ? "[shortdesc]" : "[description]"]")

TYPE_PROC_REF(/datum/blobstrain, on_lose)()

TYPE_PROC_REF(/datum/blobstrain, on_sporedeath)(mob/living/spore)

TYPE_PROC_REF(/datum/blobstrain, send_message)(mob/living/M)
	var/totalmessage = message
	if(message_living && !issilicon(M))
		totalmessage += message_living
	totalmessage += "!"
	to_chat(M, span_userdanger("[totalmessage]"))

TYPE_PROC_REF(/datum/blobstrain, core_process)()
	if(resource_delay <= world.time)
		resource_delay = world.time + 10 // 1 second
		overmind.add_points(point_rate)
	overmind.blob_core.obj_integrity = min(overmind.blob_core.max_integrity, overmind.blob_core.obj_integrity+core_regen)

TYPE_PROC_REF(/datum/blobstrain, attack_living)(mob/living/L) // When the blob attacks people
	send_message(L)

TYPE_PROC_REF(/datum/blobstrain, blobbernaut_attack)(mob/living/L) // When this blob's blobbernaut attacks people

TYPE_PROC_REF(/datum/blobstrain, damage_reaction)(obj/structure/blob/B, damage, damage_type, damage_flag, coefficient = 1) //when the blob takes damage, do this
	return coefficient*damage

TYPE_PROC_REF(/datum/blobstrain, death_reaction)(obj/structure/blob/B, damage_flag, coefficient = 1) //when a blob dies, do this
	return

TYPE_PROC_REF(/datum/blobstrain, expand_reaction)(obj/structure/blob/B, obj/structure/blob/newB, turf/T, mob/camera/blob/O, coefficient = 1) //when the blob expands, do this
	return

TYPE_PROC_REF(/datum/blobstrain, tesla_reaction)(obj/structure/blob/B, power, coefficient = 1) //when the blob is hit by a tesla bolt, do this
	return 1 //return 0 to ignore damage

TYPE_PROC_REF(/datum/blobstrain, extinguish_reaction)(obj/structure/blob/B, coefficient = 1) //when the blob is hit with water, do this
	return

TYPE_PROC_REF(/datum/blobstrain, emp_reaction)(obj/structure/blob/B, severity, coefficient = 1) //when the blob is hit with an emp, do this
	return

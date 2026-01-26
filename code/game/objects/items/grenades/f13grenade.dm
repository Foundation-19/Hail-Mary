/obj/item/grenade/f13
	name = "testing grenade"
	desc = "If you are seeing this something went wrong."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "syndicate"
	item_state = "flashbang"
	ex_dev = 0
	ex_heavy = 0
	ex_light = 0
	ex_flame = 0

/obj/item/grenade/f13/Destroy()
	if(active)
		GLOB.active_explosion_spam = max(0, GLOB.active_explosion_spam - 1)
	return ..()

// Override attack_self to add spam protection
/obj/item/grenade/f13/attack_self(mob/user)
	// Check global limit
	if(GLOB.active_explosion_spam >= 30)
		to_chat(user, span_warning("[src] fails to arm - too many explosives active!"))
		return
	
	// Per-player spam protection
	if(user && user.ckey)
		var/player_key = user.ckey
		var/player_count = 0
		var/recent_time = world.time - 10 SECONDS
		
		for(var/entry in GLOB.recent_primers)
			var/list/data = GLOB.recent_primers[entry]
			if(data["time"] < recent_time)
				GLOB.recent_primers -= entry
			else if(data["ckey"] == player_key)
				player_count++
		
		if(player_count >= 5)
			to_chat(user, span_warning("You're arming explosives too quickly!"))
			return
		
		GLOB.recent_primers["[user.ckey]_[world.time]"] = list("ckey" = player_key, "time" = world.time)
	
	// Spam detection
	if(world.time - GLOB.last_explosion_spam_time < 0.5 SECONDS)
		if(prob(40))
			to_chat(user, span_warning("[src] fails to arm properly!"))
			return
	
	// Increment counter and update time
	GLOB.active_explosion_spam++
	GLOB.last_explosion_spam_time = world.time
	
	// Call parent to actually arm
	return ..()

/obj/item/grenade/f13/prime(mob/living/lanced_by)
	if(QDELETED(src))
		return
	
	. = ..()
	update_mob()
	
	// Decrement counter
	GLOB.active_explosion_spam = max(0, GLOB.active_explosion_spam - 1)
	
	// Store location before deletion
	var/turf/epicenter = get_turf(src)
	
	// Queue explosion if there are any damage values
	if(ex_dev || ex_heavy || ex_light || ex_flame)
		SSexplosion_spam.queue_explosion(epicenter, ex_dev, ex_heavy, ex_light, flash = 0, flame_range = ex_flame, source = null)
	
	qdel(src)

/obj/item/grenade/f13/stinger
	name = "stinger grenade"
	desc = "A nonlethal sting-pellet grenade used for riot suppression pre-war."
	icon_state = "stinger"
	throw_speed = 4
	throw_range = 7
	ex_dev = 0
	ex_heavy = 0
	ex_light = 0
	ex_flame = 0
	shrapnel_type = /obj/item/projectile/bullet/pellet/stingball
	shrapnel_radius = 8

/obj/item/grenade/f13/frag
	name = "frag grenade"
	desc = "A prewar military-grade fragmentation grenade with short fuse. Useless against hard armor."
	icon_state = "frag_new"
	throw_speed = 4
	throw_range = 7
	ex_dev = 0
	ex_heavy = 0
	ex_light = 2
	ex_flame = 0
	shrapnel_type = /obj/item/projectile/bullet/shrapnel
	shrapnel_radius = 6

/obj/item/grenade/f13/plasma
	name = "plasma grenade"
	desc = "A prewar military-grade plasma grenade, used for permanent riot suppression pre-war."
	icon_state = "plasma"
	throw_speed = 4
	throw_range = 7
	ex_dev = 0
	ex_heavy = 1
	ex_light = 4
	ex_flame = 4
	shrapnel_type = /obj/item/projectile/bullet/shrapnel/plasma
	shrapnel_radius = 10
	var/rad_damage = 300

/obj/item/grenade/f13/plasma/prime(mob/living/lanced_by)
	if(QDELETED(src))
		return
	
	. = ..()
	update_mob()
	
	// Decrement counter
	GLOB.active_explosion_spam = max(0, GLOB.active_explosion_spam - 1)
	
	// Store location before deletion
	var/turf/epicenter = get_turf(src)
	
	playsound(epicenter, 'sound/effects/empulse.ogg', 50, 1)
	radiation_pulse(src, 300)
	
	// Queue explosion
	SSexplosion_spam.queue_explosion(epicenter, ex_dev, ex_heavy, ex_light, flash = 0, flame_range = ex_flame, source = null)
	
	qdel(src)

/obj/item/grenade/f13/incendiary
	name = "incendinary grenade"
	desc = "A prewar police supression grenade designed to cause as much agony as possible against large crowds of protestors, very hot."
	icon_state = "incendinary"
	throw_speed = 4
	throw_range = 7
	ex_dev = 0
	ex_heavy = 0
	ex_light = 0
	ex_flame = 5
	shrapnel_radius = 6
	var/fire_stacks = 4
	var/range = 4

/obj/item/grenade/f13/incendiary/prime(mob/living/lanced_by)
	if(QDELETED(src))
		return
	
	. = ..()
	update_mob()
	
	// Decrement counter
	GLOB.active_explosion_spam = max(0, GLOB.active_explosion_spam - 1)
	
	// Store location and do fire effects
	var/turf/epicenter = get_turf(src)
	
	for(var/turf/T in view(range, epicenter))
		if(isfloorturf(T))
			var/turf/open/floor/F = T
			F.hotspot_expose(700, 50, 1)
			for(var/mob/living/carbon/C in T)
				C.adjust_fire_stacks(fire_stacks)
				C.IgniteMob()
				to_chat(C, span_userdanger("The incendiary grenade sets you ablaze!"))
				C.emote("scream")
	
	// Queue explosion
	SSexplosion_spam.queue_explosion(epicenter, ex_dev, ex_heavy, ex_light, flash = 0, flame_range = ex_flame, source = null)
	
	qdel(src)

/obj/item/grenade/f13/radiation
	name = "radiation grenade"
	desc = "A grenade designed to release a strong pulse of gamma radiation through complex pre-war science or...something."
	icon_state = "bluefrag"
	throw_speed = 4
	throw_range = 7
	var/rad_damage = 1500
	var/range = 4
	shrapnel_type = /obj/item/projectile/energy/nuclear_particle/grenade
	shrapnel_radius = 6

/obj/item/grenade/f13/radiation/prime(mob/living/lanced_by)
	if(QDELETED(src))
		return
	
	. = ..()
	update_mob()
	
	// Decrement counter
	GLOB.active_explosion_spam = max(0, GLOB.active_explosion_spam - 1)
	
	// Store location and do radiation
	var/turf/epicenter = get_turf(src)
	
	playsound(epicenter, 'sound/effects/empulse.ogg', 50, 1)
	radiation_pulse(src, rad_damage)
	
	// These don't have normal explosions, so don't queue one
	qdel(src)

/obj/item/grenade/f13/dynamite
	name = "stick of dynamite"
	desc = "A stick of good old-fashioned black-powder dynamite. While it doesnt pack as much of a punch as anything else, it'll give rock walls something to think about."
	icon = 'icons/fallout/objects/guns/explosives.dmi'
	icon_state = "dynamite"
	preprime_sound = 'sound/effects/fuse.ogg'
	ex_dev = 0
	ex_heavy = 0
	ex_light = 3
	ex_flame = 0

/obj/item/storage/box/dynamite_box
	name = "dynamite crate"
	desc = "A box full of dynamite!"
	icon_state = "box_brown"
	illustration = "loose_ammo"

/obj/item/storage/box/dynamite_box/PopulateContents()
	. = ..()
	new /obj/item/grenade/f13/dynamite(src)
	new /obj/item/grenade/f13/dynamite(src)
	new /obj/item/grenade/f13/dynamite(src)
	new /obj/item/grenade/f13/dynamite(src)
	new /obj/item/grenade/f13/dynamite(src)
	new /obj/item/grenade/f13/dynamite(src)
	new /obj/item/grenade/f13/dynamite(src)

/obj/item/gun/flintlock
	name = "flintlock pistol"
	desc = "An ancient but well kept blackpowder pistol."
	icon_state = "flintlock"
	item_state = "flintlock"
	weapon_class = WEAPON_CLASS_SMALL // yarr harr fiddle dee dee, something something gundolier
	weapon_weight = GUN_ONE_HAND_AKIMBO //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball
	var/cocked = TRUE
	var/my_caliber = CALIBER_FLINTLOCK // Wretched
	var/load_time = FLINTLOCK_PISTOL_RELOAD_TIME // copilot suggested this
	var/prefire_time = FLINTLOCK_PISTOL_PREFIRE_TIME // copilot suggested this
	var/prefire_randomness = FLINTLOCK_PISTOL_PREFIRE_RANDOMNESS // copilot suggested this
	var/datum/looping_sound/musket_load/load_loop // for the loading sound
	var/datum/looping_sound/musket_fuse/fuse_loop // for the loading sound

/obj/item/gun/flintlock/Initialize()
	. = ..()
	load_loop = new(list(src), FALSE)
	fuse_loop = new(list(src), FALSE)
	chambered = new /obj/item/ammo_casing/caseless/flintlock(src)

/obj/item/gun/flintlock/attack_self(mob/living/user)
	cock(user)

/obj/item/gun/flintlock/AltClick(mob/user)
	unload(user)

/obj/item/gun/flintlock/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(istype(I, /obj/item/ammo_box))
		load_from_box(user, I)
	if(istype(I, /obj/item/ammo_casing))
		load_casing(user, I)

/obj/item/gun/flintlock/update_icon_state()
	return

/// Scans the box, takes a casing if possible
/obj/item/gun/flintlock/proc/load_from_box(mob/living/user, obj/item/ammo_box/bawx)
	if(!user)
		return
	if(chambered)
		to_chat(user, span_alert("[src] is already loaded!"))
		return
	if(!istype(bawx, /obj/item/ammo_box))
		return
	var/obj/item/ammo_casing/to_load
	for(var/obj/item/ammo_casing/bluuet in bawx.stored_ammo) // magazine procs suck (I should know, i wrote em)
		if(bluuet.caliber != my_caliber)
			continue
		to_load = bluuet
		break
	if(!to_load)
		to_chat(user, span_alert("Couldn't find anything in [bawx] that fits in [src]."))
		return
	if(!load_casing(user, to_load)) //load the ammo casing into the gun
		to_chat(user, span_alert("You can't seem to load [to_load] into [src].")) //tell the user the gun cannot be loaded
		return //return
	bawx.stored_ammo -= to_load //remove the ammo casing from the box

/// Forcemoves bluuet into the gun, and sets its chambered to the bluuet
/obj/item/gun/flintlock/proc/load_casing(mob/living/user, obj/item/ammo_casing/bluuet)
	if(!user) //if there is no user
		return //return
	if(chambered) //if the gun is already loaded
		to_chat(user, span_alert("[src] is already loaded!")) //tell the user the gun is already loaded
		return //return
	if(!istype(bluuet, /obj/item/ammo_casing)) //if the thing you are trying to load is not an ammo casing
		return //return
	if(bluuet.caliber != my_caliber) //if the gun and the ammo casing do not share the same caliber
		to_chat(user, span_alert("[bluuet] doesn't fit in [src].")) //tell the user the casing does not fit
		return //return
	load_loop.start()
	to_chat(user, span_notice("You begin loading [bluuet] into [src].")) //tell the user the gun is being loaded
	if(!do_after(user, load_time, TRUE, src, allow_movement = TRUE)) //do after for loading the gun
		load_loop.stop()
		to_chat(user, span_alert("You were interrupted!")) //tell the user they stopped loading the gun
		return //return
	load_loop.stop()
	if(!user.transferItemToLoc(bluuet, src)) //if the user cannot transfer the item to the location of the gun
		to_chat(user, span_alert("You can't seem to load [bluuet] into [src].")) //tell the user the gun cannot be loaded
		return //return
	chambered = bluuet //set the chambered variable to the ammo casing being loaded
	to_chat(user, span_notice("You load [bluuet] into [src].")) //tell the user the gun is loaded
	playsound(get_turf(src), 'sound/weapons/stuff_casing_end.ogg', 80, TRUE)
	update_icon()
	return TRUE

/// Ejects chambered into the user's hands, and sets chambered to null, and sets cocked to FALSE, and plays a ka-ta-click noise, and updates the icon, and returns TRUE
/obj/item/gun/flintlock/proc/unload(mob/living/user)
	if(!user)
		return
	if(!chambered)
		to_chat(user, span_alert("[src] is not loaded!"))
		return
	chambered = null
	cocked = FALSE
	playsound(get_turf(src), 'sound/weapons/stuff_casing.ogg', 80, TRUE)
	playsound(get_turf(src), 'sound/weapons/hammer_click2.ogg', 90, 1)
	to_chat(user, span_notice("You unload [src]."))
	update_icon()
	if(!user.put_in_hands(chambered))
		chambered.forceMove(get_turf(src))
		return
	return TRUE

/// Sets cocked to TRUE, and plays a ka-ta-click noise
/obj/item/gun/flintlock/proc/cock(mob/living/user)
	if(!user)
		return FALSE
	if(cocked)
		uncock(user)
		return
	cocked = TRUE
	playsound(get_turf(src), 'sound/weapons/hammer_cock.ogg', 80, TRUE)
	user.visible_message(span_alert("[user] pulls back [src]'s hammer!"))
	update_icon()

/// Sets cocked to FALSE, and plays a ka-ta-click noise
/obj/item/gun/flintlock/proc/uncock(mob/living/user)
	if(!user)
		return FALSE
	if(!cocked)
		cock(user)
		return
	cocked = FALSE
	playsound(get_turf(src), 'sound/weapons/hammer_click2.ogg', 90, 1)
	user.visible_message(span_notice("[user] gently releases [src]'s hammer back down."))
	update_icon()

/// Plays a click-sound, then a half-second later, shoots whatever's under the user's cursor. or the mob's direction if the cursor's params are null
/obj/item/gun/flintlock/pre_fire(mob/user, atom/target, params, zone_override, stam_cost, message = TRUE)
	if(!user?.client)
		return FALSE
	if(!cocked)
		to_chat(user, span_alert("[src] isn't cocked!"))
		playsound(get_turf(src), 'sound/weapons/tap.ogg', 90, 1)
		return TRUE
	playsound(get_turf(src), 'sound/weapons/hammer_click.ogg', 90, 1)
	playsound(get_turf(src), 'sound/weapons/strike_sizzle.ogg', 45, 1)
	firing = TRUE
	var/rand_low = prefire_time - (prefire_time * prefire_randomness)
	var/rand_high = prefire_time + (prefire_time * prefire_randomness)
	var/shoot_delay = rand(rand_low, rand_high)
	fuse_loop.start()
	addtimer(CALLBACK(src, PROC_REF(fire_at_cursor), user), shoot_delay)
	update_icon()
	return TRUE

/// shoots whatever's under the user's cursor. or the user's direction if the cursor's params are null
/obj/item/gun/flintlock/proc/fire_at_cursor(mob/user)
	firing = FALSE // the gun's firing btw
	cocked = FALSE
	fuse_loop.stop()
	if(!user)
		return FALSE // cus shit like this could happen
	if(!chambered)
		shoot_with_empty_chamber(user)
		return FALSE
	var/atom/tar_get = user.client?.mouseObject
	if(!tar_get) // if the user disconnected before firing, just lob it somewhere
		tar_get = get_step(user, user.dir)
	user.face_atom(tar_get)
	do_fire(tar_get, user, TRUE, user.client.mouseParams)
	SSeffects.do_effect(EFFECT_SMOKE_CONE, get_turf(user), get_turf(tar_get))
	chambered = null // the caseless casing thing deletes itself
	update_icon()

/obj/item/gun/flintlock/laser
	name = "flintlock laser pistol"
	desc = "An old sport shooting pistol that utilizes a compact explosively pumped ferroelectric generator to create a burst of capacitor energy out of a blackpowder charge."
	icon_state = "flintlock_laser"
	item_state = "flintlock_laser"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO	
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_0

/obj/item/gun/flintlock/laser/post_modify_projectile(obj/item/projectile/BB) //thurr. I turned a regular bullet into a laser bullet.
	BB.name = "musket bolt"
	BB.icon = 'icons/obj/projectiles.dmi'
	BB.icon_state = "emitter"
	BB.pass_flags = PASSTABLE| PASSGLASS
	BB.light_range = 2
	BB.damage_type = BURN
	BB.flag = "laser"
	BB.impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	BB.light_color = LIGHT_COLOR_GREEN
	BB.is_reflectable = TRUE
	BB.hitsound = 'sound/weapons/sear.ogg'
	BB.hitsound_wall = 'sound/weapons/effects/searwall.ogg'
	playsound(src, 'sound/weapons/emitter.ogg', 25, 1)

/obj/item/gun/ballistic/bow/chamber_round()
	chambered = magazine.stored_ammo[1]


//Fenny begins being evil here

/obj/item/gun/flintlock/musket
	name = "ancient musket"
	desc = "An ancient but well kept blackpowder musket."
	icon = 'fallout/icons/objects/ancient.dmi'
	icon_state = "musket1"
	item_state = "308"
	mob_overlay_icon = 'fallout/icons/objects/back.dmi'
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_T4
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball
	load_time = FLINTLOCK_MUSKET_RELOAD_TIME
	prefire_time = FLINTLOCK_MUSKET_PREFIRE_TIME
	prefire_randomness = FLINTLOCK_MUSKET_PREFIRE_RANDOMNESS

/obj/item/gun/flintlock/musketoon
	name = "ancient musketoon"
	desc = "An ancient but well kept blackpowder musketoon; handy!"
	icon = 'fallout/icons/objects/ancient.dmi'
	icon_state = "musketoon"
	item_state = "308"
	mob_overlay_icon = 'fallout/icons/objects/back.dmi'
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_TWO_HAND_ONLY //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_T3
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball
	load_time = FLINTLOCK_MINIMUSKET_RELOAD_TIME
	prefire_time = FLINTLOCK_MINIMUSKET_PREFIRE_TIME
	prefire_randomness = FLINTLOCK_MINIMUSKET_PREFIRE_RANDOMNESS

/obj/item/gun/flintlock/musket/jezail
	name = "ancient jezail"
	desc = "An ancient but well kept blackpowder jezail; handy!"
	icon = 'fallout/icons/objects/ancient.dmi'
	icon_state = "jezail"
	item_state = "308"
	mob_overlay_icon = 'fallout/icons/objects/back.dmi'
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_T5
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball

/obj/item/gun/flintlock/musket/tanegashima
	name = "ancient tanegashima"
	desc = "A matchlock rifle handmade by a craftsman some time after the fall of the old world."
	icon = 'fallout/icons/objects/ancient.dmi'
	icon_state = "tanegashima"
	item_state = "308"
	mob_overlay_icon = 'fallout/icons/objects/back.dmi'
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_T5
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball

/obj/item/gun/flintlock/musketoon/spingarda
	name = "ancient spingarda"
	desc = "An ancient but well kept blackpowder rock chucker!"
	icon = 'fallout/icons/objects/ancient.dmi'
	icon_state = "spingarda"
	item_state = "308"
	mob_overlay_icon = 'fallout/icons/objects/back.dmi'
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_TWO_HAND_ONLY //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_T3
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball

/obj/item/gun/flintlock/musketoon/mosquete
	name = "ancient mosquete"
	desc = "An ancient but well kept blackpowder musket, lighter and handier than a full sized musket with a beautiful ebony stock."
	icon = 'fallout/icons/objects/ancient.dmi'
	icon_state = "mosquete1752"
	item_state = "308"
	mob_overlay_icon = 'fallout/icons/objects/back.dmi'
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_TWO_HAND_ONLY //need both hands to fire
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_T3
	fire_sound = 'sound/f13weapons/44revolver.ogg'
	trigger_guard = TRIGGER_GUARD_NORMAL //hate to break it to ya, flintlocks require more technical skill to operate than a cartridge loaded firearm
	dryfire_text = "*not loaded*"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow //slow for the sake of macros, but not toooo slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_AUTOMATIC //smoothbore short barrel round ball

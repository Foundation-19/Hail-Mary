//IN THIS DOCUMENT: Automatic template, SMGs, Carbines, Semi-auto rifles, Assault rifles, Machineguns and Misc.
// See gun.dm for keywords and the system used for gun balance



//////////////////////
//AUTOMATIC TEMPLATE//
//////////////////////


/obj/item/gun/ballistic/automatic
	name = "automatic gun template"
	desc = "should not be here, bugreport."
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE

	var/auto_eject = 0 //for en blocs
	var/auto_eject_sound = null
	//var/alarmed = 0 //for a funky, annoying sound when ammo runs out. broken code
	can_suppress = FALSE
	equipsound = 'sound/f13weapons/equipsounds/riflequip.ogg'
	init_recoil = SMG_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/faster
	)

	/* code for digitally displaying fire select. ancient code
	var/automatic_burst_overlay = TRUE
	var/select = 1
	/obj/item/gun/ballistic/automatic/update_overlays()
		. = ..()
		if(automatic_burst_overlay)
			if(!select)
				. += ("[initial(icon_state)]semi")
			if(select == 1)
				. += "[initial(icon_state)]burst"
	*/

/obj/item/gun/ballistic/automatic/update_icon_state()
	icon_state = "[initial(icon_state)][magazine ? "-[magazine.max_ammo]" : ""][chambered ? "" : "-e"]"

/* /obj/item/gun/ballistic/automatic/attackby(obj/item/A, mob/user, params)
	. = ..()
	if(.)
		return
	if(istype(A, /obj/item/ammo_box/magazine))
		var/obj/item/ammo_box/magazine/new_mag = A
		if(istype(new_mag, mag_type))
			var/obj/item/ammo_box/magazine/oldmag = magazine
			if(user.transferItemToLoc(new_mag, src))
				magazine = new_mag
				if(oldmag)
					to_chat(user, span_notice("You perform a tactical reload on \the [src], replacing the magazine."))
					oldmag.forceMove(get_turf(src.loc))
					oldmag.update_icon()
				else
					to_chat(user, span_notice("You insert the magazine into \the [src]."))

				playsound(user, 'sound/weapons/autoguninsert.ogg', 60, 1)
				chamber_round()
				A.update_icon()
				update_icon()
				return 1
			else
				to_chat(user, span_warning("You cannot seem to get \the [src] out of your hands!")) */

/obj/item/gun/ballistic/automatic/can_shoot()
	return get_ammo()

/*
/obj/item/gun/ballistic/automatic/proc/empty_alarm()
	if(!chambered && !get_ammo() && !alarmed)
		playsound(src.loc, 'sound/weapons/smg_empty_alarm.ogg', 40, 1)
		update_icon()
		alarmed = 1
	return
*/
/obj/item/gun/ballistic/automatic/afterattack(atom/target, mob/living/user)
	..()
	if(auto_eject && magazine && magazine.stored_ammo && !magazine.stored_ammo.len && !chambered)
		magazine.dropped()
		user.visible_message(
			"[magazine] falls out and clatters on the floor!",
			span_notice("[magazine] falls out and clatters on the floor!")
		)
		if(auto_eject_sound)
			playsound(user, auto_eject_sound, 40, 1)
		magazine.forceMove(get_turf(src.loc))
		magazine.update_icon()
		magazine = null
		update_icon()



/* * * * *
 * SMGs  *
 * * * * */

/* * * * * * * * * * *
 * Pistols, but faster
 * More magazine space
 * One handed
 * Some can be akimboed
 * Generally poor accuracy
 * Lot of recoil
 * Long recoil cooldown
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/
	name = "SMG TEMPLATE"
	desc = "should not exist"
	icon = 'icons/obj/guns/projectile.dmi'
	icon_prefix = "uzi"
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	weapon_class = WEAPON_CLASS_CARBINE

/* * * * * * * * * * *
 * American 180 SMG
 * Spraycan SMG
 * .22LC
 * Huge magazine
 * Low damage
 * Two-handed
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/american180
	name = "American 180"
	desc = "An integrally suppressed submachinegun chambered in the common .22 long rifle. Top loaded drum magazine."
	icon_state = "smg22"
	item_state = "shotgun"
	mag_type = /obj/item/ammo_box/magazine/m22smg
	init_mag_type = /obj/item/ammo_box/magazine/m22smg
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(0.7)
	init_firemodes = list(
		/datum/firemode/automatic/rpm300,
		/datum/firemode/semi_auto/faster
	)
	silenced = TRUE
	fire_sound_silenced = 'sound/f13weapons/american180.ogg'

/obj/item/gun/ballistic/automatic/smg/american180/b180
	name = "American 18-bee"
	desc = "They used to call the gun a swarm of angry bees. in this case, it's literal."
	mag_type = /obj/item/ammo_box/magazine/b180
	extra_mag_types = /obj/item/ammo_box/magazine/m22smg //lets you use it as a standard .22 when you run out of unobtainable bees.
	init_mag_type = /obj/item/ammo_box/magazine/b180

/* * * * * * * * * * *
 * 14mm SMG
 * Heavy SMG
 * 14mm
 * Massive damage
 * Massive recoil
 * Slower shooting
 * Two-handed
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/smg14
	name = "14mm SMG"
	desc = "A heavy-duty SMG designed to tear through most forms of armor."
	icon_state = "12smg"
	item_state = "14toploader"
	mag_type = /obj/item/ammo_box/magazine/smg14
	init_mag_type = /obj/item/ammo_box/magazine/smg14
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/burst/three/slow,
		/datum/firemode/semi_auto/faster
	)
	fire_sound = 'sound/f13weapons/magnum_fire.ogg'

/* * * * * * * * * * *
 * Greasegun SMG!
 * Easy-handle .45ACP SMG
 * .45 ACP
 * One-handed
 * No akimbo
 * Slowish autofire
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/greasegun
	name = "m3a1 greasegun"
	desc = "This submachine gun filled National Guard arsenals after the Army replaced it with newer weapons."
	icon_state = "grease_gun"
	item_state = "smg9mm"
	fire_sound = 'sound/f13weapons/greasegun.ogg'
	mag_type = /obj/item/ammo_box/magazine/greasegun
	init_mag_type = /obj/item/ammo_box/magazine/greasegun
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/faster
	)
	suppressor_state = "uzi_suppressor"
	suppressor_x_offset = 26
	suppressor_y_offset = 19

/* * * * * * * * * * *
 * Worn greasegun SMG
 * Cruddy .45 SMG
 * .45
 * One-handed
 * No akimbo
 * Less accuracy
 * Less damage
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/greasegun/worn
	name = "beat up .45ACP submachine gun"
	desc = "What was once an inexpensive, but reliable submachine gun is now an inexpensive piece of shit. It's impressive this thing still fires at all."
	damage_multiplier = GUN_LESS_DAMAGE_T2
	init_recoil = SMG_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150
	)

/* * * * * * * * * * *
 * 10mm SMG
 * Baseline 10mm SMG
 * 10mm
 * Slower firing
 * Heavier recoil
 * One-handed
 * No akimbo
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/smg10mm
	name = "10mm submachine gun"
	desc = "One of the most common personal-defense weapons of the Great War, a sturdy and reliable open-bolt 10mm submachine gun."
	icon_state = "smg10mm"
	item_state = "smg10mm"
	icon_prefix = "smg10mm"
	mag_type = /obj/item/ammo_box/magazine/m10mm
	init_mag_type = /obj/item/ammo_box/magazine/m10mm/adv/ext
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/faster
	)
	suppressor_state = "10mm_suppressor" //activate if sprited
	suppressor_x_offset = 30
	suppressor_y_offset = 16
	fire_sound = 'sound/f13weapons/10mm_fire_03.ogg'

/* * * * * * * * * * *
 * Worn 10mm SMG
 * Poor Baseline 10mm SMG
 * 10mm
 * Slower firing
 * Less damage
 * One-handed
 * No akimbo
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/smg10mm/worn
	name = "worn-out 10mm submachine gun"
	desc = "Mass-produced weapon from the Great War, this one has seen use ever since. Grip is wrapped in tape to keep the plastic from crumbling, the metals are oxidizing, but the gun still works."
	worn_out = TRUE //a lazy way to overlay the worn sprite variant onto the gun
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = SMG_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/faster
	)


/* * * * * * * * * * *
 * Uzi 9mm SMG
 * Light 9mm SMG
 * 9mm
 * Faster firing
 * Less damage
 * One-handed
 * Akimbo!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/mini_uzi
	name = "9mm Uzi"
	desc = "A lightweight, burst-fire submachine gun, for when you really want someone dead. Uses 9mm rounds."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "uzi"
	item_state = "uzi"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm
	disallowed_mags = list(/obj/item/ammo_box/magazine/uzim9mm/rockwell) //so I don't have to assign a ton of new sprite names
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)
	can_suppress = TRUE
	suppressor_state = "uzi_suppressor"
	suppressor_x_offset = 29
	suppressor_y_offset = 16

/* * * * * * * * * * *
 * Uzi .22 SMG
 * Lighter .22 SMG
 * .22
 * Faster firing
 * Less damage
 * One-handed
 * Akimbo!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/mini_uzi/smg22
	name = ".22 Uzi"
	desc = "A very lightweight submachine gun, for when you really want to politely ask someone to be dead. Uses .22LR rounds."
	icon_state = "uzi22"
	item_state = "uzi"
	mag_type = /obj/item/ammo_box/magazine/m22/extended
	init_mag_type = /obj/item/ammo_box/magazine/m22/extended
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(0.75)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/faster
	)
	can_suppress = TRUE
	suppressor_state = "uzi_suppressor"
	suppressor_x_offset = 29
	suppressor_y_offset = 16

//MP40: a uzi but with different flavor
/obj/item/gun/ballistic/automatic/smg/mini_uzi/mp40
	name = "Maschinenpistole 40"
	desc = "An open bolt blowback submachine gun that served in the German Army. It's a long way from home."
	icon = 'fallout/icons/objects/automatic.dmi'
	icon_state = "mp40"
	item_state = "smg9mm"

//compact modernize MP5
/obj/item/gun/ballistic/automatic/smg/mini_uzi/mp5
	name = "HK MP-5"
	desc = "A lightweight submachine gun that earned its place as one of the most popular SMGs in the world"
	icon = 'fallout/icons/objects/automatic.dmi'
	icon_state = "mp5"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm
	weapon_class = WEAPON_CLASS_NORMAL //high class, one of the few smol smgs
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION // Accurate semiauto fire

//tec-9 but in .22, compared to .22 pistol, is automatic, but less damage, not silenced
/obj/item/gun/ballistic/automatic/smg/mini_uzi/smg22/tec22
	name = ".22 machine pistol"
	desc = "A compact, lightweight way to put a lot of bullets downrange."
	icon = 'fallout/icons/objects/automatic.dmi'
	icon_state = "tec9"
	mag_type = /obj/item/ammo_box/magazine/m22
	init_mag_type = /obj/item/ammo_box/magazine/m22
	disallowed_mags = list(/obj/item/ammo_box/magazine/m22/extended)
	weapon_class = WEAPON_CLASS_SMALL	
	damage_multiplier = GUN_LESS_DAMAGE_T1
	can_suppress = FALSE

//rockwell: starter tier bad quality 9mm smg
/obj/item/gun/ballistic/automatic/smg/mini_uzi/rockwell
	name = "9mm Rockwell SMG"
	desc = "A crudely handmade reincarnation of the Australian Owen gun. It shoots, at least."
	icon_state = "rockwell"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm/rockwell
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm/rockwell
	disallowed_mags = null
	weapon_class = WEAPON_CLASS_CARBINE	
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/fast
	)
	can_suppress = FALSE

/obj/item/gun/ballistic/automatic/smg/mini_uzi/owengun
	name = "9mm Owen Gun"
	desc = "The Owen gun, known officially as the Owen machine carbine, was an Australian submachine gun designed by Evelyn Owen in 1938. Its a common design out in the wastes due to its portability weight and ability to never jam."
	icon_state = "owengun"
	item_state = "rockwell"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm/rockwell
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm/rockwell
	disallowed_mags = null
	weapon_class = WEAPON_CLASS_CARBINE	
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/fast
	)
	can_suppress = FALSE


//mac-10: uzi, but compact, softer hitting, harder to control. needs suppressor location adjusted
/obj/item/gun/ballistic/automatic/smg/mini_uzi/mac10
	name = "Ingram Model 10" //I like naming things quirkily
	desc = "A compact machine pistol with a blistering fire rate."
	icon = 	'fallout/icons/objects/automatic.dmi'
	icon_state = "mac10"
	weapon_class = WEAPON_CLASS_NORMAL //kinda bulky for a compact gun
	damage_multiplier = GUN_LESS_DAMAGE_T2 //this spits lots of bullets and is compact and can be dual wielded
	init_recoil = SMG_RECOIL(2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm300,
		/datum/firemode/semi_auto/faster
	)

/* * * * * * * * * * *
 * Carl Gustaf 10mm SMG
 * Another 10mm SMG
 * 10mm
 * Slower firing
 * Less damage
 * No akimbo
 * Common? ive never seen one
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/cg45
	name = "Carl Gustaf 10mm"
	desc = "Post-war submachine gun made in workshops in Phoenix, a copy of a simple old foreign design."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "cg45"
	item_state = "cg45"
	mag_type = /obj/item/ammo_box/magazine/cg45
	init_mag_type = /obj/item/ammo_box/magazine/cg45
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/faster
	)
	fire_sound = 'sound/f13weapons/10mm_fire_03.ogg'

/* * * * * * * * * * *
 * Thompson SMG
 * Baseline .45 SMG
 * .45ACP
 * Two-handed
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/tommygun
	name = "Thompson SMG"
	desc = "A powerful submachinegun chambered in .45 ACP, this weapon fires at a blistering rate with a heavy pistol cartridge, and can accept very high capacity magazines, to boot."
	icon_state = "thomson"
	item_state = "shotgun"
	mag_type = /obj/item/ammo_box/magazine/tommygunm45
	init_mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)

	fire_sound = 'sound/weapons/gunshot_smg.ogg'

/* * * * * * * * * * *
 * Whitelegs Thompson SMG
 * Tribal .45 SMG
 * .45ACP
 * More damage
 * Two-handed
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/tommygun/whitelegs
	name = "Storm Drum"
	desc = "A recovered ancient Thompson from an armory far up North. Commonly used by raiders of the White Legs tribe."
	mag_type = /obj/item/ammo_box/magazine/tommygunm45
	init_mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	damage_multiplier = GUN_LESS_DAMAGE_T1


/* * * * * * * * * * *
 * P90c SMG
 * Light 10mm SMG
 * 10mm
 * Huge magazine
 * Less damage
 * One-handed
 * Akimbo!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/p90
	name = "FN P90c"
	desc = "The Fabrique Nationale P90c was just coming into use at the time of the war. The weapon's bullpup layout, and compact design, make it easy to control. The durable P90c is prized for its reliability, and high firepower in a ruggedly-compact package. Chambered in 10mm."
	icon_state = "p90"
	item_state = "m90"
	mag_type = /obj/item/ammo_box/magazine/m10mm_p90
	init_mag_type = /obj/item/ammo_box/magazine/m10mm_p90
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = SMG_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/burst/three/fast,
		/datum/firemode/semi_auto/fast
	)
	can_suppress = TRUE
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 29
	suppressor_y_offset = 16
	fire_sound = 'sound/f13weapons/10mm_fire_03.ogg'

/* * * * * * * * * * *
 * Worn P90c SMG
 * Light 10mm SMG
 * 10mm
 * Huge magazine
 * Even Less damage
 * Less accurate
 * One-handed
 * Akimbo!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/p90/worn
	name = "Worn FN P90c"
	desc = "A FN P90 manufactured by Fabrique Nationale. This one is beat to hell but still works."
	damage_multiplier = GUN_LESS_DAMAGE_T3
	init_firemodes = list(
		/datum/firemode/burst/five/slow,
		/datum/firemode/semi_auto/fast
	)

/* * * * * * * * * * *
 * MP-5 SD SMG
 * Silent 9mm SMG
 * 9mm
 * Quiet
 * Accurate
 * Slightly more damage
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/mp5
	name = "MP-5 SD"
	desc = "An integrally suppressed submachinegun chambered in 9mm."
	icon_state = "mp5"
	item_state = "fnfal"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION // Accurate semiauto fire
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/faster
	)
	silenced = TRUE
	fire_sound = 'sound/weapons/Gunshot_silenced.ogg'
	fire_sound_silenced = 'sound/weapons/Gunshot_silenced.ogg'

/* * * * * * * * * * *
 * PPSh SMG
 * Spraycan 9mm SMG
 * 9mm
 * Huge magazine
 * Low damage
 * Two-handed
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/ppsh
	name = "Ppsh-41"
	desc = "An extremely fast firing, inaccurate submachine gun from World War 2. Low muzzle velocity. Uses 9mm rounds."
	icon_state = "pps"
	mag_type = /obj/item/ammo_box/magazine/pps9mm
	init_mag_type = /obj/item/ammo_box/magazine/pps9mm
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/automatic/rpm300,
		/datum/firemode/semi_auto/fast
	)
	scope_state = "AEP7_scope"
	scope_x_offset = 9
	scope_y_offset = 21
	can_scope = TRUE

/* * * * * * * * * * *
 * Sidewinder SMG
 * Multiammo SMG
 * 9mm / 10mm / .45 / .22
 * Click a button while its empty to change what mags it accepts!
 * Low damage
 * Two-handed
 * Slow firing
 * Inaccurate
 * Uncommon?
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/smg/sidewinder
	name = "multi-caliber smg"
	desc = "The answer to all your ammo-scrounging problems! The TwisTactical Spindoctor SMMG (sub-machine multi-gun) integrates \
			rotation-reactive metalmers in the upper assembly to change what ammunition it accepts, from .22LR to .45ACP with a \
			simple twist of the mechanism. Surprisingly easy to maintain and assemble, given the right high-tech Rotosteel parts, \
			making it a common sight for Boxcar Vixens in the Heap, where the short sightlines more than make up for the gun's \
			inherently poor accuracy. Doesn't accept awkwardly shaped magazines, though. That's for the PRO model, which isn't \
			available out here."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "sidewinder"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm
	extra_mag_types = /obj/item/ammo_box/magazine/m9mm
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	var/current_caliber = "9mm"
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	added_spread = GUN_SPREAD_POOR
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto/fast,
		/datum/firemode/burst/three/fast
	)

	can_scope = TRUE
	scope_state = "AEP7_scope"
	scope_x_offset = 10
	scope_y_offset = 22
	can_flashlight = TRUE

	can_flashlight = TRUE
	scope_state = "flight"
	flight_x_offset = 16
	flight_y_offset = 18

	can_suppress = TRUE
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 31
	suppressor_y_offset = 17

	actions_types = list(/datum/action/item_action/toggle_sidewinder)
	//fire_sound = 'sound/f13weapons/9mm.ogg'
	use_casing_sounds = TRUE

/obj/item/gun/ballistic/automatic/smg/sidewinder/update_icon_state()
	icon_state = "[initial(icon_state)][magazine ? "-[current_caliber]" : ""][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/automatic/smg/sidewinder/proc/change_ammo(mob/user)
	if(user)
		if(magazine)
			user.show_message(span_alert("[src] needs to be completely unloaded before working the TwistForm mechanism!"))
			return
		if(chambered)
			user.show_message(span_alert("[src] needs to be <u>completely</u> unloaded before working the TwistForm mechanism!"))
			return

	allowed_mags = list()
	change_the_ammo(user)

/obj/item/gun/ballistic/automatic/smg/sidewinder/proc/change_the_ammo(mob/user)
	var/message2self = "You wrench the upper receiver of [src] out of its socket and give it one full turn."
	var/message2everyone = "[user] spins [user.p_their()] their gun around. It makes a wierd click."
	switch(current_caliber)
		if("22LR")
			current_caliber = "9mm"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/m9mm, /obj/item/ammo_box/magazine/uzim9mm)
			message2self += "The panel on the side now reads: \"9mm Mode\""

		if("9mm")
			current_caliber = "10mm"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/m10mm, /obj/item/ammo_box/magazine/cg45)
			message2self += "The panel on the side now reads: \"10mm Mode\""

		if("10mm")
			current_caliber = "45ACP"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/greasegun, /obj/item/ammo_box/magazine/m45, /obj/item/ammo_box/magazine/tommygunm45/stick)
			message2self += "The panel on the side now reads: \".45ACP Mode\""

		if("45ACP")
			current_caliber = "22LR"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/m22)
			message2self += "The panel on the side now reads: \".22LR Mode\""

	playsound(get_turf(src), 'sound/f13weapons/equipsounds/riflequip.ogg', 60, 1)
	if(user)
		user.visible_message(message2everyone,span_notice(message2self))

/obj/item/gun/ballistic/automatic/smg/sidewinder/examine(mob/user)
	. = ..()
	switch(current_caliber)
		if("22LR")
			. += "<br><span class='notice'>The readout displays \".22LR Mode\", indicating it'll accept most .22 SMG and pistol mags.</span>"
		if("9mm")
			. += "<br><span class='notice'>The readout displays \"9mm Mode\", indicating it'll accept most 9mm SMG and pistol mags.</span>"
		if("10mm")
			. += "<br><span class='notice'>The readout displays \"10mm Mode\", indicating it'll accept most 10mm SMG and pistol mags.</span>"
		if("45ACP")
			. += "<br><span class='notice'>The readout displays \".45ACP Mode\", indicating it'll accept most .45 SMG and pistol mags.</span>"
	. += "<br><span class='notice'>Unload the gun and click the action button to change the caliber.</span>"

//worn sidewinder

/obj/item/gun/ballistic/automatic/smg/sidewinder/worn
	name = "multi-caliber carbine"
	desc = "The answer to all your ammo-scrounging problems! The TwisTactical Spindoctor MGC (multi-gun carbine) integrates \
			rotation-reactive metalmers in the upper assembly to change what ammunition it accepts, from .22LR to .45ACP with a \
			simple twist of the mechanism. Surprisingly easy to maintain and assemble, given the right high-tech Rotosteel parts, \
			making it a common sight for Boxcar Vixens in the Heap, where the short sightlines more than make up for the gun's \
			inherently poor accuracy. Doesn't accept awkwardly shaped magazines, though. That's for the PRO model, which isn't \
			available out here. This model is locked to semi-auto!"
	icon_state = "sidewinder"
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)

/// multical-magnum
/obj/item/gun/ballistic/automatic/smg/sidewinder/magnum
	name = "multi-caliber magnum"
	desc = "A heavier, more robust multi-caliber carbine! The TwisTactical Magnum uses a thicker-walled roto-mechanism that allows its \
			rotation-reactive metalmers to withstand higher pressures, now able to safely fire anything from .45ACP to 14mm with a \
			simple twist of the mechanism. Surprisingly easy to maintain and assemble, given the right high-tech Rotosteel parts, \
			making it a common sight for Boxcar Vixens in the Heap, where the short sightlines more than make up for the gun's \
			inherently poor accuracy. Only accepts small magazines. This model is locked to semi-auto!"
	icon_state = "sidewinder-magnum"
	mag_type = /obj/item/ammo_box/magazine/m44
	extra_mag_types = /obj/item/ammo_box/magazine/m44/automag
	init_mag_type = /obj/item/ammo_box/magazine/m44
	current_caliber = "44"
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	//fire_sound = 'sound/f13weapons/44mag.ogg'

/obj/item/gun/ballistic/automatic/smg/sidewinder/magnum/change_the_ammo(mob/user)
	var/message2self = "You wrench the upper receiver of [src] out of its socket and give it one full turn. "
	var/message2everyone = "[user] spins [user.p_their()] their gun around. It makes a wierd click."
	switch(current_caliber)
		if("44")
			current_caliber = "14mm"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/m14mm)
			//fire_sound = 'sound/f13weapons/magnum_fire.ogg'
			message2self += "The panel on the side now reads: \"14mm Mode\""

		if("14mm")
			current_caliber = "45ACP"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/m45)
			//fire_sound = 'sound/weapons/gunshot_smg.ogg'
			message2self += "The panel on the side now reads: \".45ACP Mode\""

		if("45ACP")
			current_caliber = "44"
			allowed_mags |= typesof(/obj/item/ammo_box/magazine/m44)
			//fire_sound = 'sound/f13weapons/44mag.ogg'
			message2self += "The panel on the side now reads: \".44 Magnum Mode\""

	playsound(get_turf(src), 'sound/f13weapons/revolverspin.ogg', 60, 1)
	if(user)
		user.visible_message(message2everyone,span_notice(message2self))


/* * * * * * *
 * Carbines  *
 * * * * * * */

/* * * * * * * * * * *
 * Pistols, but longer
 * Two handed
 * Generally good accuracy
 * Lower recoil
 * Slightly higher damage
 * Common
 * * * * * * * * * * */

/* * * * * * * * * * *
 * M1 Carbine
 * 10mm
 * Can take extendomags
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1carbine
	name = "M1 carbine"
	desc = "The M1 Carbine was mass produced during some old war, and at some point NCR found stockpiles and rechambered them to 10mm to make up for the fact their service rifle production can't keep up with demand."
	icon_state = "m1carbine"
	item_state = "rifle"
	mag_type = /obj/item/ammo_box/magazine/m10mm
	init_mag_type = /obj/item/ammo_box/magazine/m10mm/adv
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE) //need to check what this do
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION

	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	can_scope = TRUE
	scope_state = "scope_medium"
	scope_x_offset = 5
	scope_y_offset = 14
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 26
	suppressor_y_offset = 31
	fire_sound = 'sound/f13weapons/varmint_rifle.ogg'

/* * * * * * * * * * *
 * M2 Carbine
 * 10mm
 * lower fire rate than a 10mm smg, but scope and bayonet compatible
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1carbine/m2
	name = "M2 carbine"
	desc = "An M2 Carbine with faded military markings. Looks beat up but functional."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "ncr-m1carbine"
	item_state = "rifle"
	init_mag_type = /obj/item/ammo_box/magazine/m10mm/adv/ext
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = CARBINE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto
	)

/* * * * * * * * * * *
 * M1A1 Carbine
 * 10mm
 * Folds up!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1carbine/compact
	name = "M1A1 carbine"
	desc = "The M1A1 carbine is an improvement of the original, with this particular model having a folding stock allowing for greater mobility. Chambered in 10mm."
	icon_state = "m1a1carbine"
	var/stock = FALSE
	weapon_class = WEAPON_CLASS_CARBINE
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(1.2)

/obj/item/gun/ballistic/automatic/m1carbine/compact/AltClick(mob/user)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	toggle_stock(user)

/obj/item/gun/ballistic/automatic/m1carbine/compact/examine(mob/user)
	. = ..()
	. += "<br><span class='notice'>The stock is [stock ? "open" : "folded"].</span>"
	. += "<br><span class='notice'>Alt-click to toggle the stock.</span>"

/obj/item/gun/ballistic/automatic/m1carbine/compact/proc/toggle_stock(mob/living/user)
	stock = !stock
	if(stock)
		w_class = WEIGHT_CLASS_BULKY
		to_chat(user, "You unfold the stock.")
		recoil_dat = getRecoil(CARBINE_RECOIL(1)[1],CARBINE_RECOIL(1)[2],CARBINE_RECOIL(1)[3])
	else
		w_class = WEIGHT_CLASS_NORMAL
		to_chat(user, "You fold the stock.")
		recoil_dat = getRecoil(init_recoil[1],init_recoil[2],init_recoil[3])
	update_icon()

/obj/item/gun/ballistic/automatic/m1carbine/compact/update_icon_state()
	icon_state = "[initial(icon_state)][magazine ? "-[magazine.max_ammo]" : ""][chambered ? "" : "-e"][stock ? "" : "-f"]"

/* * * * * * * * * * *
 * De Lisle Carbine
 * Silent 9mm carbine
 * Silent!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/delisle
	name = "De Lisle carbine"
	desc = "A integrally suppressed carbine, known for being one of the quietest firearms ever made. Chambered in 9mm."
	icon_state = "delisle"
	item_state = "varmintrifle"
	mag_type = /obj/item/ammo_box/magazine/m9mm
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(1.1)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION // tacticool
	can_scope = TRUE
	silenced = TRUE
	fire_sound_silenced = 'sound/weapons/Gunshot_large_silenced.ogg'

/* * * * * * * * * * *
 * Commando Carbine
 * Silent .45 carbine
 * Silent!
 * Common?
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/delisle/commando
	name = "commando carbine"
	desc = "A integrally suppressed carbine, known for being one of the quietest firearms ever made. This modified version is often used by the Brotherhood of Steel. Its stock has been replaced by post-war polymer furniture, with space to mount a scope. Chambered in .45 ACP."
	icon_state = "commando"
	item_state = "commando"
	mag_type = /obj/item/ammo_box/magazine/m45
	init_mag_type = /obj/item/ammo_box/magazine/m45/socom
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	silenced = TRUE
	can_scope = TRUE
	scope_state = "scope_medium"
	scope_x_offset = 6
	scope_y_offset = 14

/* * * * * * * * * * *
 * Combat Carbine
 * Baseline .45 carbine
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/combat
	name = "American Commonwealth Carbine"
	desc = "A .45 semi-automatic combat carbine, produced pre-war for National Guard forces."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "c_rifle"
	item_state = "combatrifle"
	icon_prefix = "combatrifle"
	mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	init_mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_tags = list(GUN_FA_MODDABLE)
	fire_sound = 'sound/f13weapons/combatrifle.ogg'

/* * * * * * * * * * *
 * Trusty Combat Carbine
 * Slightly softer .45 carbine
 * Less damage
 * less accurate
 * Powerful melee
 * With love
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/combat/worn/brim
	name = "Trusty Combat Carbine"
	desc = "A well loved .45 semi-automatic combat carbine, with so many parts replaced and fixed up that it wouldn't give the artisan who \
		maintained this thing enough credit to say it's a pre-war design. Covered in forge marks where repairs were needed. While everything \
		looks to be of high-quality crafting, the precision of such parts look a bit... off, like a master swordsmith were asked to forge a \
		gun by hand. As such, the internal mechanisms and rifling are not <i>quite</i> the right size for a .45ACP round, and the sight \
		picture is a bit <i>Fuzzy</i>. Every part is, however, built as rugged as its maker, and can be used as a very effective melee \
		weapon without any risk of damaging it."
	icon_state = "combat_rifle"
	item_state = "combatrifle"
	icon_prefix = "combatrifle"
	mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	init_mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	weapon_class = WEAPON_CLASS_CARBINE
	force = GUN_MELEE_FORCE_RIFLE_HEAVIER
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = CARBINE_RECOIL(1)
	added_spread = GUN_SPREAD_POOR

/* * * * * * * * * * *
 * Worn Combat Carbine
 * Slightly softer .45 carbine
 * Less damage
 * less accurate
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/combat/worn
	name = "Combat Carbine"
	desc = "A .45 semi-automatic combat carbine, produced pre-war for National Guard forces. This one seems aged..."
	icon_state = "combat_rifle"
	item_state = "combatrifle"
	icon_prefix = "combatrifle"
	mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	init_mag_type = /obj/item/ammo_box/magazine/tommygunm45/stick
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(1)

/* * * * * * * * * * *
 * 10/22ish carbine
 * .22 LR
 * Higher damage
 * Found all over the place
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/sportcarbine
	name = "sport carbine"
	desc = "One of the many .22 LR carbines that were all the rage before the war. While lacking in firepower, it more than makes up for it with its modularity and cheapness to fire."
	icon_state = "surplus"
	item_state = "rifle"
	mag_type = /obj/item/ammo_box/magazine/m22
	init_mag_type = /obj/item/ammo_box/magazine/m22/extended
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_T3 // its a weakass cartridge
	init_recoil = CARBINE_RECOIL(0.5)
	init_firemodes = list(
		/datum/firemode/semi_auto/faster
	)
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	max_upgrades = 5 // moddable to fuck and fack
	can_bayonet = TRUE
	bayonet_state = "bayonetstraight"
	knife_x_offset = 22
	knife_y_offset = 21
	can_scope = TRUE
	scope_state = "leveraction_scope"
	scope_x_offset = 5
	scope_y_offset = 14
	can_suppress = TRUE
	suppressor_state = "suppressor"
	suppressor_x_offset = 26
	suppressor_y_offset = 31
	fire_sound = 'sound/weapons/Gunshot2.ogg'

/* * * * * * * * * * *
 * M1-22 carbine
 * .22 LR
 * Higher damage
 * One, owned by a fox
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/sportcarbine/m1_22
	name = "M1-22 carbine"
	desc = "A one-of-a-kind M1 carbine chambered in .22 LR. Where it lacks in stopping power, it more than makes up for it with modularity and full auto support. Looks well cared for, if a bit fuzzy."
	icon_state = "m1carbine"
	item_state = "rifle"
	mag_type = /obj/item/ammo_box/magazine/m22
	init_mag_type = /obj/item/ammo_box/magazine/m22/extended
	weapon_class = WEAPON_CLASS_CARBINE
	damage_multiplier = GUN_EXTRA_DAMAGE_T1 // its a weakass cartridge
	init_recoil = CARBINE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto,
		/datum/firemode/automatic/rpm200
	)
	max_upgrades = 3
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	can_scope = TRUE
	scope_state = "scope_medium"
	scope_x_offset = 5
	scope_y_offset = 14
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 26
	suppressor_y_offset = 31
	fire_sound = 'sound/f13weapons/varmint_rifle.ogg'

/* * * * * * * * * * *
 * Semi-auto Rifles  *
 * * * * * * * * * * */

/* * * * * * * * * * *
 * Long arms
 * Two handed
 * Generally good accuracy
 * Lower recoil
 * Common
 * * * * * * * * * * */

/* * * * * * * * * * *
 * Varmint Rifle
 * Light semi-auto rifle
 * .223 / 5.56mm
 * Slow to fire
 *
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/varmint
	name = "varmint rifle"
	desc = "A simple bolt action rifle in 5.56mm calibre. Easy to use and maintain."
	icon_state = "varmint"
	item_state = "varmintrifle"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle/small
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	scope_state = "scope_short"
	scope_x_offset = 4
	scope_y_offset = 12
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 27
	suppressor_y_offset = 31
	fire_sound = 'sound/f13weapons/varmint_rifle.ogg'
	can_scope = TRUE

/* * * * * * * * * * *
 * Varmint Rifle w/ 20rd mag
 * Light semi-auto rifle
 * .223 / 5.56mm
 * Slow to fire
 * Literally the above, but it spawns with a bigger magazine
 *
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/varmint/extended
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle

/* * * * * * * * * * *
 * Verminkiller Rifle
 * Tricked out semi-auto rifle
 * .223 / 5.56mm
 * Scoped
 * Silent
 * More damage
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/varmint/verminkiller
	name = "verminkiller rifle"
	desc = "Legends are told of the \"Ratslayer\", a custom-made souped-up varmint rifle with a sick paintjob. This is a pale imitation, made of chopped-up bits of other guns."
	icon_state = "verminrifle"
	item_state = "ratslayer"
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	gun_tags = list()
	silenced = TRUE
	can_scope = FALSE
	zoom_factor = 1.5
	suppressor_state = "none"
	fire_sound_silenced = 'sound/weapons/Gunshot_large_silenced.ogg'

/* * * * * * * * * * *
 * Ratslayer Rifle
 * Tricked out semi-auto rifle
 * .223 / 5.56mm
 * Scoped
 * Silent
 * More damage
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/varmint/ratslayer
	name = "Ratslayer"
	desc = "A modified varmint rifle with better stopping power, a scope, and suppressor. Oh, don't forget the sick paint job."
	icon_state = "ratslayer"
	item_state = "ratslayer"
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_T3 //some extra oomf
	gun_tags = list()
	silenced = TRUE
	can_scope = FALSE
	zoom_factor = 1.5
	fire_sound_silenced = 'sound/weapons/Gunshot_large_silenced.ogg'

/* * * * * * * * * * *
 * Bushmaster Arm Gun
 * Light semi-auto rifle... pistol thing
 * .223 / 5.56mm
 * Slow to fire
 * Inaccurate
 * Kicks all over the place
 * Suuuuuucks
 * But it makes a click!
 * And is tactical!
 * Unique (thankfully)
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/varmint/bushmaster_arm_gun
	name = ".223 arm pistol"
	desc = "Be the envy of your platoon with comfortable firepower in a compact form factor, \
		the Operator's Choice Arm Pistol tactically molds its bullpup feed system to the user's physique, \
		able to swivel the patented Twistical Receivest to accommodate being held with its recommended \
		Point'N'Clik SwampWarrior stance. Arm yourself with the Arm Pistol!"
	icon_state = "arm_rifle"
	item_state = "m90"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	/// sets if the gun is turnt
	var/turnt = FALSE
	max_upgrades = 6
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_LESS_DAMAGE_T2
	init_recoil = RIFLE_RECOIL(3)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_SEMI_AUTO

	gun_tags = list(GUN_SCOPE)
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 18
	knife_y_offset = 17

	can_scope = TRUE
	scope_state = "scope_long"
	scope_x_offset = 4
	scope_y_offset = 12

	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 22
	suppressor_y_offset = 24

	can_flashlight = TRUE
	gunlight_state = "flightangle"
	flight_x_offset = 12
	flight_y_offset = 16
	actions_types = list(/datum/action/item_action/toggle_armgun)
	fire_sound = 'sound/f13weapons/ServiceRifle.ogg'

/// Silly proc that makes a click
/obj/item/gun/ballistic/automatic/varmint/bushmaster_arm_gun/proc/rotate_the_stupid_gun(mob/user)
	if(user)
		if(turnt)
			user.visible_message(
				"[user] snaps [user.p_their()] [src.name] back into place.",
				span_notice("With a quick, professional slap of the base of your palm, you deliver a precise karate-chop to the rear of your Arm Gun and snap that sucker back into place!")
			)
		else
			user.visible_message(
				"[user] clicks [user.p_their()] [src.name] to the side.",
				span_notice("With a tactical flourish, you grip the rear assembly of your Arm Gun and wrench that sucker to the side, snapping the receiver into comfortable operator mode!")
			)
	playsound(get_turf(src), 'sound/f13weapons/equipsounds/riflequip.ogg', 60, 1)
	turnt = !turnt

/* * * * * * * * * * *
 * Service Rifle
 * Baseline semi-auto rifle
 * .223 / 5.56mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/service
	name = "service rifle"
	desc = "A 5.56x45 semi-automatic service rifle manufactured by the NCR and issued to all combat personnel."
	icon_state = "service_rifle"
	item_state = "servicerifle"
	icon_prefix = "servicerifle"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	fire_sound = 'sound/f13weapons/varmint_rifle.ogg'

/* * * * * * * * * * *
 * ALR15 Rifle
 * Tacticool semi-auto rifle
 * .223 / 5.56mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/service/alr
	name = "ALR15"
	desc = "A 5.56x45mm rifle custom built off of a reproduction model AR15-style weapon. Sports a fancy holographic sight picture, forward grip, and a comfortable synthetic thumbhole stock. Bang bang."
	icon_state = "armalite-20"
	item_state = "alr15"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	fire_sound = 'sound/f13weapons/varmint_rifle.ogg'

/* * * * * * * * * * *
 * Scout carbine
 * Scopeable semi-auto rifle
 * .223 / 5.56mm
 * Scope!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/service/carbine
	name = "scout carbine"
	desc = "A cut down version of the standard-issue service rifle tapped with mounting holes for a scope. Shorter barrel, lower muzzle velocity."
	icon_state = "scout_carbine"
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(0.8)
	can_scope = TRUE
	scope_state = "scope_short"
	scope_x_offset = 4
	scope_y_offset = 15
	suppressor_x_offset = 26
	suppressor_y_offset = 28

/* * * * * * * * * * *
 * Marksman carbine
 * Scoped semi-auto rifle
 * .223 / 5.56mm
 * Scope!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/marksman
	name = "marksman carbine"
	desc = "A marksman carbine built off the AR platform chambered in 5.56x45. Seen heavy usage in pre-war conflicts. This particular model is a civilian version and is semi-auto only."
	icon_state = "marksman_carbine"
	item_state = "marksman"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	gun_tags = list(GUN_FA_MODDABLE)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = FALSE
	zoom_factor = 1
	can_bayonet = FALSE
	bayonet_state = "rifles"
	knife_x_offset = 22
	knife_y_offset = 12
	can_suppress = TRUE
	suppressor_state = "suppressor"
	suppressor_x_offset = 31
	suppressor_y_offset = 15
	fire_sound = 'sound/f13weapons/marksman_rifle.ogg'

// Worn Marksman Carbine

/obj/item/gun/ballistic/automatic/marksman/worn
	name = "battle-worn marksman carbine"
	desc = "A marksman carbine built off the AR platform chambered in 5.56x45. Seen heavy usage in pre-war conflicts. This particular model is a civilian version and is semi-auto only. This one seems worn with time..."
	icon_state = "marksman_rifle"
	item_state = "marksman"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T2
	init_recoil = RIFLE_RECOIL(1.4)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_tags = list(GUN_FA_MODDABLE)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = FALSE
	zoom_factor = 1
	can_bayonet = FALSE
	bayonet_state = "rifles"
	knife_x_offset = 22
	knife_y_offset = 12
	can_suppress = TRUE
	suppressor_state = "suppressor"
	suppressor_x_offset = 31
	suppressor_y_offset = 15
	fire_sound = 'sound/f13weapons/marksman_rifle.ogg'

/* * * * * * * * * * *
 * Police Rifle
 * Cool semi-auto rifle
 * .223 / 5.56mm
 * Scope!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/marksman/policerifle
	name = "Police Rifle"
	desc = "A pre-war Rifle that has been constantly repaired and rebuilt by the Eastwood Police Department. Held together by duct tape and prayers, it somehow still shoots."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	icon_prefix = "assault_carbine"
	icon_state = "rifle-police"
	item_state = "assault_carbine"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1)
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE)
	can_suppress = FALSE
	can_scope = TRUE
	zoomable = FALSE

/* * * * * * * * * * *
 * Rangemaster Rifle
 * Baseline semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/rangemaster
	name = "Colt Rangemaster"
	desc = "A Colt Rangemaster semi-automatic rifle, chambered for 7.62x51. Single-shot only."
	icon_state = "colt_rangermaster"
	item_state = "308"
	icon_prefix = "308"
	force = 20
	mag_type = /obj/item/ammo_box/magazine/w3006
	init_mag_type = /obj/item/ammo_box/magazine/w3006
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 24
	knife_y_offset = 21
	scope_state = "scope_long"
	scope_x_offset = 4
	scope_y_offset = 11
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'

/* * * * * * * * * * *
 * Enfield SLR Rifle
 * Baseline semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/slr
	name = "Enfield SLR"
	desc = "A self-loading rifle in 7.62mm NATO. Semi-auto only."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	icon_state = "slr"
	item_state = "slr"
	mag_type = /obj/item/ammo_box/magazine/m308
	init_mag_type = /obj/item/ammo_box/magazine/m308
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	gun_tags = list(GUN_FA_MODDABLE, GUN_SCOPE)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 24
	knife_y_offset = 21
	scope_state = "scope_long"
	scope_x_offset = 4
	scope_y_offset = 11
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'

/* * * * * * * * * * *
 * M1 Garand Rifle
 * Heavy semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * More damage
 * Scope!
 * Bayonet!
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1garand
	name = "M1 Garand"
	desc = "The WWII American Classic. Still has that satisfiying ping."
	icon_state = "m1garand"
	item_state = "rifle"
	icon_prefix = "308"
	mag_type = /obj/item/ammo_box/magazine/garand3006
	init_mag_type = /obj/item/ammo_box/magazine/garand3006
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	gun_tags = list(GUN_SCOPE)
	en_bloc = 1
	auto_eject = 1
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	can_scope = TRUE
	scope_state = "scope_long"
	scope_x_offset = 5
	scope_y_offset = 14
	auto_eject_sound = 'sound/f13weapons/garand_ping.ogg'
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'

/obj/item/gun/ballistic/automatic/m1garand/update_icon()
	..()
	icon_state = "[initial(icon_state)]"

/obj/item/gun/ballistic/automatic/m1garand/attackby(obj/item/A, mob/user, params)
	. = ..()
	if(.)
		return

/* * * * * * * * * * *
 * Old Glory Rifle
 * Heavier semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Even more damage
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1garand/oldglory
	name = "Old Glory"
	desc = "This Machine kills communists!"
	icon_state = "oldglory"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1)

/* * * * * * * * * * *
 * Republic's Pride Rifle
 * Heavy semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * More damage
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1garand/republicspride
	name = "Republic's Pride"
	desc = "A well-tuned scoped M1C rifle crafted by master gunsmith from the Gunrunners. Chambered in 7.62x51."
	icon_state = "republics_pride"
	item_state = "scoped308"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1)

	zoom_factor = 1.2
	can_scope = FALSE

/* * * * * * * * * * *
 * SKS Rifle
 * Soviet semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1garand/sks
	name = "SKS"
	desc = "Old hunting rifle taken from disovered stockpiles and refurbished in Phoenix workshops. The standard heavy rifle of the Legion, still rare. .308, semi-auto only, internal magazine."
	icon = 'icons/obj/guns/projectile.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	icon_state = "sks"
	item_state = "sks"
	mag_type = /obj/item/ammo_box/magazine/sks
	init_mag_type = /obj/item/ammo_box/magazine/sks
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(1)

	bayonet_state = "bayonet"
	knife_x_offset = 24
	knife_y_offset = 23
	scope_state = "scope_mosin"
	scope_x_offset = 4
	scope_y_offset = 12
	auto_eject_sound = 'sound/weapons/magout.ogg'
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'

/* * * * * * * * * * *
 * Sniper Rifle
 * Sniper semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Sloooow to fire
 * Lot more damage
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/marksman/sniper
	name = "sniper rifle"
	desc = "A DKS 501, chambered in .308 Springfield.  With a light polymer body, it's suited for long treks through the desert."
	icon_prefix = "sniperrifle"
	icon_state = "sniper_rifle"
	item_state = "sniper_rifle"
	mag_type = /obj/item/ammo_box/magazine/w3006
	init_mag_type = /obj/item/ammo_box/magazine/w3006
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(1)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(/datum/firemode/semi_auto/slower)

	can_bayonet = FALSE
	can_scope = FALSE
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'
	zoom_factor = 2

/* * * * * * * * * * *
 * Gold Sniper Rifle
 * Pretty Sniper semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Stylish!
 * Scope!
 * Bayonet!
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/marksman/sniper/gold
	name = "golden sniper rifle"
	desc = "A DKS 501, chambered in .30-06 Springfield. This one has a gold trim and the words 'Old Cassius' engraved into the stock."
	icon_state = "gold_sniper"
	item_state = "gold_sniper"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2

/* * * * * * * * * * *
 * Explorer Sniper Rifle
 * Legion Sniper semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Less damage
 * Less slowdown
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/marksman/sniper/snipervenator
	name = "Centurion sniper rifle"
	desc = "The customized sniper rifle, fitted with a telescopic sight for extreme accuracy and chambered for a high-ballistic performance centerfire cartridge. It is a superior version of the regular sniper rifle and is decorated with the flag of the bull and tokens of a hunt."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/backslot_weapon.dmi'
	icon_state = "venator_sniper"
	item_state = "venator_sniper"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0

/* * * * * * * * * * *
 * Compact Sniper Rifle
 * Sniper semi-auto 7.62mm rifle
 * .308 / 7.62mm
 * Less damage
 * Less slowdown
 * Scope!
 * Bayonet!
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/marksman/sniper/sniperranger
	name = "compact sniper rifle"
	desc = "A DKS 501, chambered in .308 Winchester.  With a light polymer body, it's suited for long treks through the desert. This particular model is lighter and faster."
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0

/* * * * * * * * * * *
 * Automatic Rifles  *
 * * * * * * * * * * */

/* * * * * * * * * * *
 * Long rifles, but faster
 * Two handed
 * Generally poor accuracy
 * Lot more recoil
 * Lot harder to control
 * Deadly in the right hands
 * Common
 * * * * * * * * * * */

/* * * * * * * * * * *
 * R82 heavy service rifle
 * Baseline 5.56mm autorifle
 * .223 / 5.56mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/service/r82
	name = "R82 heavy service rifle"
	desc = "The assault rifle variant of the R84, based off the pre-war FN FNC. Issued to high-ranking troopers and specialized units. Chambered in 5.56."
	icon_state = "R82"
	item_state = "R84"
	icon_prefix = "r82"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto
	)
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 27
	suppressor_y_offset = 28

/* * * * * * * * * * *
 * R91 assault rifle
 * Baseline 5.56mm autorifle
 * .223 / 5.56mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/assault_rifle
	name = "r91 assault rifle"
	desc = "The R91 was the standard US Army assault rifle, and so saw wide-spread use after the war. Most are worn out by now."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "assault_rifle"
	item_state = "fnfal"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T1
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)
	can_bayonet = FALSE
	bayonet_state = "rifles"
	knife_x_offset = 23
	knife_y_offset = 11
	can_suppress = TRUE
	suppressor_x_offset = 32
	suppressor_y_offset = 15
	suppressor_state = "ar_suppressor"
	fire_sound = 'sound/f13weapons/varmint_rifle.ogg'

/* * * * * * * * * * *
 * Infiltrator service rifle
 * Quiet 5.56mm autorifle
 * .223 / 5.56mm
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/assault_rifle/infiltrator
	name = "infiltrator"
	desc = "A customized R91 assault rifle, with an integrated suppressor, small scope, cut down stock and polymer furniture. The supressor takes away stopping-power, but a cleaner action allows it to fire faster."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "infiltrator"
	item_state = "fnfal"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2 //needs a lil edge at least
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto
	)
	can_suppress = FALSE
	silenced = TRUE
	can_bayonet = FALSE
	can_scope = FALSE
	fire_sound_silenced = 'sound/weapons/Gunshot_large_silenced.ogg'
	zoom_factor = 0.8

/* * * * * * * * * * *
 * R93 PDW rifle
 * Baseline 5.56mm autorifle
 * .223 / 5.56mm
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/r93
	name = "R93 PDW"
	desc = "A lightweight assault rifle manufactured by the Brotherhood of Steel with a folding stock, based on weapons from the R-series platforms. It is generally issued to Brotherhood Knights for scouting missions."
	icon_state = "r93"
	item_state = "r93"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)
	can_scope = FALSE
	can_bayonet = FALSE
	fire_sound = 'sound/weapons/Gunshot_large_silenced.ogg'

/* * * * * * * * * * *
 * Type 93 assault rifle
 * Chinese 5.56mm AN-94-like rifle
 * .223 / 5.56mm
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/type93
	name = "type 93 assault rifle"
	desc = "The Type 93 Chinese assault rifle was designed and manufactured by a Chinese industrial conglomerate for the People's Liberation Army during the Resource Wars. Has a unique burst-fire mechanism, where it fires two bullets very quickly, staying accurate, but leading to an increased pause between follow-up shots. Chambered in 5.56x45."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "chinese_ar"
	item_state = "handmade_rifle"
	icon_prefix = "handmade_rifle"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/burst/two/fastest,
	)
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 27
	suppressor_y_offset = 27
	fire_sound = 'sound/f13weapons/assaultrifle_fire.ogg'

/* * * * * * * * * * *
 * Worn Type 93 assault rifle
 * Chinese 5.56mm autorifle
 * .223 / 5.56mm
 * Less damage
 * Less accuracy
 * Slower to shoot
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/type93/worn //24dmg
	name = "\improper Worn Type 93"
	desc = "This Type 93 Chinese assault rifle looks like it has been restored in a garage. The bore is shot to hell, the threading is destroyed, and so is the burst fire mechanism- it seems to fire unevenly, spraying more bullets than before."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "handmade_rifle"
	item_state = "handmade_rifle"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T2
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(3.4)
	init_firemodes = list(
		/datum/firemode/burst/five/slow
	)

	can_suppress = FALSE

/* * * * * * * * * * *
 * BOZAR
 * Heavy 5.56mm autorifle
 * .223 / 5.56mm
 * More damage
 * More accurate
 * Scope!
 * Slower to shoot
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/bozar
	name = "Bozar"
	desc = "The ultimate refinement of the sniper's art, the Bozar is a scoped, accurate, light machine gun that will make nice big holes in your enemy. Uses 5.56."
	icon_state = "bozar"
	item_state = "sniper"
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/automatic/rpm300,
		/datum/firemode/burst/two/fast
	)
	zoomable = TRUE
	fire_sound = 'sound/f13weapons/bozar_fire.ogg'
	zoom_factor = 1.2

/* * * * * * * * * * *
 * Assault Carbine Rifle
 * Baseline 5mm autorifle
 * 5mm
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/assault_carbine
	name = "assault carbine"
	desc = "The U.S. army carbine version of the R91, made by Colt and issued to special forces."
	icon_state = "assault_carbine"
	item_state = "assault_carbine"
	icon_prefix = "assault_carbine"
	mag_type = /obj/item/ammo_box/magazine/m5mm
	init_mag_type = /obj/item/ammo_box/magazine/m5mm
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = CARBINE_RECOIL(1)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/burst/three,
		/datum/firemode/semi_auto
	)
	can_scope = FALSE
	scope_state = "scope_short"
	scope_x_offset = 4
	scope_y_offset = 15
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 26
	suppressor_y_offset = 28
	can_flashlight = TRUE
	gunlight_state = "flightangle"
	flight_x_offset = 21
	flight_y_offset = 21
	fire_sound = 'sound/f13weapons/assault_carbine.ogg'

/* * * * * * * * * * *
 * Police Assault Rifle
 * Baseline 5mm autorifle
 * 5mm
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/assault_carbine/policerifle
	name = "Police Assault Rifle"
	desc = "A pre-war Rifle that has been constantly repaired and rebuilt by the Eastwood Police Department. Held together by duct tape and prayers, it somehow still shoots."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	icon_state = "rifle-police"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto
	)
	can_scope = FALSE

/* * * * * * * * * * *
 * Police Assault Rifle
 * Baseline 5mm autorifle
 * 5mm
 * Less damage
 * Less accurate
 * Slower to shoot
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/assault_carbine/worn
	name = "worn assault carbine"
	desc = "The U.S. army carbine version of the R91, made by Colt and issued to special forces. This one is beat-up and falling apart."
	icon_state = "assault_carbine"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T2
	init_recoil = CARBINE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/burst/five/fast,
		/datum/firemode/semi_auto
	)

/* * * * * * * * * * *
 * FN FAL Rifle
 * Baseline 7.62 autorifle
 * .308 / 7.62
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/fnfal
	name = "FN FAL"
	desc = "This rifle has been more widely used by armed forces than any other rifle in history. It's a reliable assault weapon for any terrain or tactical situation."
	icon_state = "fal"
	item_state = "fnfal"
	mag_type = /obj/item/ammo_box/magazine/m308
	init_mag_type = /obj/item/ammo_box/magazine/m308
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/automaticrifle_BAR.ogg'


/* * * * * * * * * * *
 * AR-10 Armalite
 * .308 semi-auto rifle
 * .308 / 7.62
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/armalite
	name = "AR-10 Armalite"
	desc = "A blast from the past as a ruggled, reliable rifle. Accurate and packs a punch, but recoil picks up quick, and it's heavy. Makes it suitable for bashing skulls, at least..."
	icon_state = "armalite"
	item_state = "assault_carbine"
	mag_type = /obj/item/ammo_box/magazine/m308
	init_mag_type = /obj/item/ammo_box/magazine/m308
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)


/* * * * * * * * * * *
 * L1A1 Self Loading Rifle
 * .308 semi-auto rifle
 * .308 / 7.62
 * Uncommoner
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/l1a1
	name = "L1A1"
	desc = "The L1A1 Self-Loading Rifle, The standard issue rifle of All Commonwealth Nations."
	icon_state = "l1a1"
	item_state = "slr"
	mag_type = /obj/item/ammo_box/magazine/m308
	init_mag_type = /obj/item/ammo_box/magazine/m308
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)



/* * * * * * * * * * *
 * Browning Automatic BAR Rifle
 * Baseline 7.62 autorifle
 * .308 / 7.62
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/bar
	name = "automatic rifle (.308)"
	desc = "An ancient machine gun that looks like outdated even by pre-war standards. It has Colt etched on one-side and Sierra Madre on the other. It is alarmingly heavy for a rifle."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "auto_rifle"
	item_state = "BAR"
	icon_prefix = "rifle"
	mag_type = /obj/item/ammo_box/magazine/m308
	init_mag_type = /obj/item/ammo_box/magazine/m308/ext
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1.3)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	fire_sound = 'sound/f13weapons/automaticrifle_BAR.ogg'

/* * * * * * * * * * *
 * G11 Rifle
 * Fancy 4.73mm autorifle
 * 4.73mm caseless
 * Fast firing!
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/g11
	name = "G11"
	desc = "This experimental gun fires a caseless cartridge consisting of a block of propellant with a bullet buried inside. The weight and space savings allows for a very high magazine capacity. Chambered in 4.73mm."
	icon_state = "g11"
	item_state = "arg"
	mag_type = /obj/item/ammo_box/magazine/m473
	init_mag_type = /obj/item/ammo_box/magazine/m473
	disallowed_mags = list(/obj/item/ammo_box/magazine/m473/small, /obj/item/ammo_box/magazine/m473/small/empty)
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/burst/three/fastest,
		/datum/firemode/semi_auto
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE

//worn g11

/obj/item/gun/ballistic/automatic/g11/tox
	name = "Tox's G11M"
	desc = "A unique G11. With a built in scope and semi-automatic only option, this G11 was bought and repurposed by a wealthy felid named Tox Mckit. Etched on the reciever is a lovely motif of moths and felines surrounding one singular feline under a full moon. On the scope is a engraving that says 'To the sands we stride on'"
	icon_state = "g11"
	item_state = "arg"
	mag_type = /obj/item/ammo_box/magazine/m473
	init_mag_type = /obj/item/ammo_box/magazine/m473
	disallowed_mags = list(/obj/item/ammo_box/magazine/m473/small, /obj/item/ammo_box/magazine/m473/small/empty)
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T2
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = FALSE
	zoom_factor = 1
/* * * * * * * * * * *
 * WT-550 Carbine
 * 4.73mm caseless
 * Spaceman gun
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/wt550
	name = "4.73mm carbine"
	desc = "A WT-550 Personal Defense Weapon, manufactured by West Tek. It fires 4.73mm caseless rounds."
	item_state = "m90"
	icon_state = "WT550"
	mag_type = /obj/item/ammo_box/magazine/m473/small
	init_mag_type = /obj/item/ammo_box/magazine/m473/small
	weapon_class = WEAPON_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = CARBINE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)
	can_bayonet = TRUE
	knife_x_offset = 25
	knife_y_offset = 12

/* * * * *
 * LMGs  *
 * * * * */

/* * * * * * * * * * *
 * Automatic rifles, but bigger
 * Two handed
 * Generally poor accuracy
 * Lot more recoil
 * Lot harder to control
 * Deadly in the right hands
 * Quick to cool down recoil
 * Rare
 * * * * * * * * * * */

/* * * * * * * * * * *
 * R84 LMG
 * Baseline 5.56mm LMG
 * .223 / 5.56mm
 * Rare
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/r84
	name = "R84 LMG"
	desc = "A light machinegun using 60 round belts fed from an ammobox, its one of the few heavy weapons designs still commonly found."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "R84"
	item_state = "R84"
	mag_type = /obj/item/ammo_box/magazine/lmg
	init_mag_type = /obj/item/ammo_box/magazine/lmg
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = LMG_RECOIL(1)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG
	init_firemodes = list(
		/datum/firemode/automatic/rpm200
	)
	fire_sound = 'sound/f13weapons/assaultrifle_fire.ogg'

/* * * * * * * * * * *
 * LSW LMG
 * Mobile 5.56mm LMG
 * .223 / 5.56mm
 * Lighter!
 * Rare
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/lsw
	name = "Light Support Weapon"
	desc = "This squad-level support weapon has a bullpup design. The bullpup design makes it difficult to use while lying down. Because of this it was remanded to National Guard units. It, however, earned a reputation as a reliable weapon that packs a lot of punch for its size."
	icon = 'icons/obj/guns/projectile.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	icon_state = "lmg"
	item_state = "lsw"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = LMG_RECOIL(1)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG
	init_firemodes = list(
		/datum/firemode/automatic/rpm200
	)
	zoom_factor = 1
	can_scope = FALSE
	fire_sound = 'sound/f13weapons/assaultrifle_fire.ogg'

//hefty and clonky
/obj/item/gun/ballistic/automatic/lewis
	name = "Lewis automatic rifle"
	desc = "A relic of a gun, featuring an obscenely heavy watercooled barrel and a high capacity pan magazine."
	icon = 'icons/fallout/objects/guns/longguns.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/64x64_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/64x64_righthand.dmi'
	icon_state = "lewis"
	item_state = "lewis"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	mag_type = /obj/item/ammo_box/magazine/lewis
	init_mag_type = /obj/item/ammo_box/magazine/lewis/l47
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = LMG_RECOIL(1.2)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG * 1.5
	init_firemodes = list(
		/datum/firemode/automatic/rpm150
	)

//less damage than the M1919, but more compact magazines that hold more
/obj/item/gun/ballistic/automatic/lewis/lanoe
	name = "Lewis Mark II"
	desc = "This machinegun came right off a fightercraft from the first world war. It trades an extra heavy cooling system for an extra heavy magazine."
	icon = 'icons/fallout/objects/guns/longguns.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/64x64_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/64x64_righthand.dmi'
	icon_state = "lanoe"
	item_state = "lanoe"
	mag_type = /obj/item/ammo_box/magazine/lewis
	init_mag_type = /obj/item/ammo_box/magazine/lewis
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = LMG_RECOIL(1.2)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG * 1.5
	init_firemodes = list(
		/datum/firemode/automatic/rpm150
	)

/obj/item/gun/ballistic/automatic/bren
	name = "Bren gun"
	desc = "A rather heavy gun that served as the primary British infantry LMG throughout the second world war."
	icon = 'icons/fallout/objects/guns/longguns.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/64x64_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/64x64_righthand.dmi'
	icon_state = "bren"
	item_state = "bren"
	mag_type = /obj/item/ammo_box/magazine/bren
	init_mag_type = /obj/item/ammo_box/magazine/bren
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = LMG_RECOIL(1.2)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG * 1.5
	init_firemodes = list(
		/datum/firemode/automatic/rpm200
	)

/* * * * * * * * * * *
 * Browning M1919 MMG
 * Big 7.62mm LMG
 * .308 / 7.62mm
 * The big gun
 * Terrible overall
 * Except that it shoots a lot of 7.62
 * Rare
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m1919
	name = "Browning M1919"
	desc = "This ancient machine gun has been dug up and put into working order by local forces. It's loud, heavy and terrifying."
	icon_state = "M38"
	item_state = "M38"
	slot_flags = 0
	mag_type = /obj/item/ammo_box/magazine/mm308
	init_mag_type = /obj/item/ammo_box/magazine/mm308
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	slowdown = GUN_SLOWDOWN_RIFLE_LMG * 1.5
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = LMG_RECOIL(1.2)
	slowdown = GUN_SLOWDOWN_RIFLE_LMG * 1.5
	init_firemodes = list(
		/datum/firemode/automatic/rpm200
	)
	var/cover_open = FALSE
	var/require_twohands = FALSE
	fire_sound = 'sound/f13weapons/assaultrifle_fire.ogg'

/obj/item/gun/ballistic/automatic/m1919/update_icon()
	icon_state = "M38[cover_open ? "open" : "closed"][magazine ? CEILING(get_ammo(0)/20, 1)*20 : "-empty"]"
	item_state = "M38[cover_open ? "open" : "closed"][magazine ? "mag" : "nomag"]"

/obj/item/gun/ballistic/automatic/m1919/examine(mob/user)
	. = ..()
	if(cover_open && magazine)
		. += "<span class='notice'>It seems like you could use an <b>empty hand</b> to remove the magazine.</span>"

/obj/item/gun/ballistic/automatic/m1919/attack_self(mob/user)
	cover_open = !cover_open
	to_chat(user, span_notice("You [cover_open ? "open" : "close"] [src]'s cover."))
	if(cover_open)
		playsound(user, 'sound/weapons/sawopen.ogg', 60, 1)
	else
		playsound(user, 'sound/weapons/sawclose.ogg', 60, 1)
	update_icon()

/obj/item/gun/ballistic/automatic/m1919/afterattack(atom/target as mob|obj|turf, mob/living/user as mob|obj, flag, params) //what I tried to do here is just add a check to see if the cover is open or not and add an icon_state change because I can't figure out how c-20rs do it with overlays
	if(cover_open)
		to_chat(user, span_warning("[src]'s cover is open! Close it before firing!"))
	else
		. = ..()
		update_icon()

/obj/item/gun/ballistic/automatic/m1919/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(loc != user)
		..()
		return	//let them pick it up
	if(!cover_open || (cover_open && !magazine))
		..()
	else if(cover_open && magazine)
		//drop the mag
		magazine.update_icon()
		magazine.forceMove(drop_location())
		user.put_in_hands(magazine)
		magazine = null
		update_icon()
		to_chat(user, span_notice("You remove the magazine from [src]."))
		playsound(user, 'sound/weapons/magout.ogg', 60, 1)

/obj/item/gun/ballistic/automatic/m1919/attackby(obj/item/A, mob/user, params)
	if(!cover_open && istype(A, mag_type))
		to_chat(user, span_warning("[src]'s cover is closed! You can't insert a new mag."))
		return
	..()



////////
//MISC//
////////

/* * * * * * * * * * *
 * M72 Gauss Rifle
 * Biggest Baddest Superrifle
 * 2mmEC
 * Rare
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/m72
	name = "\improper M72 gauss rifle"
	desc = "The M72 rifle is of German design. It uses an electromagnetic field to propel rounds at tremendous speed... and pierce almost any obstacle. Its range, accuracy and stopping power is almost unparalleled."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "gaussf2"
	item_state = "sniper"
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/m2mm
	init_mag_type = /obj/item/ammo_box/magazine/m2mm
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION // obviously

	can_scope = FALSE
	zoom_factor = 1.2
	fire_sound = 'sound/f13weapons/gauss_rifle.ogg'

/* * * * * * * * * * *
 * xl70e3
 * Fancy 5.56mm autorifle
 * .308 / 5.56mm
 * Rare
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/xl70e3
	name = "xl70e3"
	desc = "This was an experimental weapon at the time of the war. Manufactured, primarily, from high-strength polymers, the weapon is almost indestructible. It's light, fast firing, accurate, and can be broken down without the use of any tools. Chamebered in 5.56mm."
	icon_state = "xl70e3"
	item_state = "xl70e3"
	mag_type = /obj/item/ammo_box/magazine/m556/rifle
	init_mag_type = /obj/item/ammo_box/magazine/m556/rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(0.6)
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/burst/three,
		/datum/firemode/semi_auto
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	zoom_factor = 1.2
	can_scope = FALSE

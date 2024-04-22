//IN THIS DOCUMENT: Rifle template, Lever-action rifles, Bolt-action rifles, Magazine-fed bolt-action rifles
// See gun.dm for keywords and the system used for gun balance

/// Main thing that makes boltie guns are:
///  INTERNAL MAG and CASING_EJECTOR = FALSE
/// the internal mag makes it be loaded from a box or strip
/// the casing ejector = FALSE makes it pumped after each shot
/// enjoy!

////////////////////
// RIFLE TEMPLATE //
////////////////////


/obj/item/gun/ballistic/rifle
	name = "rifle template"
	desc = "Should not exist"
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	icon_state = "shotgun"
	item_state = "shotgun"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	init_recoil = RIFLE_RECOIL(2.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)

	gun_skill_check = AFFECTED_BY_FAST_PUMP | AFFECTED_BY_AUTO_PUMP
	casing_ejector = FALSE // THIS makes it require manual cocking of the gun!!!
	spawnwithmagazine = TRUE
	fire_sound = 'sound/f13weapons/shotgun.ogg'
	cock_sound = 'sound/weapons/shotgunpump.ogg'

/* /obj/item/gun/ballistic/rifle/process_chamber(mob/living/user, empty_chamber = 0)
	return ..() //changed argument value

/obj/item/gun/ballistic/rifle/can_shoot()
	return !!chambered?.BB

/obj/item/gun/ballistic/rifle/attack_self(mob/living/user)
	pump(user, TRUE) */

/obj/item/gun/ballistic/rifle/blow_up(mob/user)
	. = 0
	if(chambered && chambered.BB)
		process_fire(user, user, FALSE)
		. = 1

/* * * * * * *
 * Repeaters *
 * * * * * * */

/* * * * * * * * * * *
 * Revolvers, but bigger
 * More magazine space
 * Little more damage
 * Two handed
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater
	name = "repeater template"
	desc = "should not exist"
	can_scope = TRUE
	scope_state = "scope_long"
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_BASE
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	scope_x_offset = 5
	scope_y_offset = 13
	cock_sound = 'sound/f13weapons/cowboyrepeaterreload.ogg'

/* * * * * * * * * * *
 * Cowboy Repeater
 * Baseline Repeater
 * .357 Magnum
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/cowboy
	name = "cowboy repeater"
	desc = "A lever action rifle chambered in .357 Magnum. Smells vaguely of whiskey and cigarettes."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "cowboy_repeater"
	item_state = "cowboyrepeater"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube357
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/cowboyrepeaterfire.ogg'

/* * * * * * * * * * *
 * Coyote Repeater
 * Baseline Repeater Tribal Skin
 * .357 Magnum
 * Tribal Only
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/cowboy/tribal
	name = "coyote repeater"
	desc = "A sanctified .357 lever action rifle, bearing a paw print, teeth painted on the handguard and what appears to be a severed paw."
	icon_state = "cowboyrepeatert"
	item_state = "cowboyrepeater"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube357
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(3)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/cowboyrepeaterfire.ogg'

/* * * * * * * * * * *
 * Trail Repeater
 * Big Repeater
 * .44 Magnum
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/trail
	name = "trail carbine"
	desc = "A lever action rifle chambered in .44 Magnum."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "lincoln_repeater"
	item_state = "trailcarbine"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube44
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3.3)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/44mag.ogg'

/* * * * * * * * * * *
 * Trail Repeater Tribal
 * Rain Stick
 * .44 Magnum
 * Tribal Only
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/trail/tribal
	name = "rainstick"
	desc = "A sactified .44 lever action rifle, coated in detailed markings and a carved bead chain that sounds like rain."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "trailcarbinet"
	item_state = "trailcarbine"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube44
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(3.3)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/44mag.ogg'

/* * * * * * * * * * *
 * Brush Repeater
 * Bigger Repeater
 * .45-70 Bigboy
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/brush
	name = "brush gun"
	desc = "A heavy Lever-action rifle chambered in .45-70. its sturdy design lets it handle the largest cartridges and largest game."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "brush_gun"
	item_state = "brushgun"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube4570
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3.6)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/brushgunfire.ogg'

/* * * * * * * * * * *
 * Brush Repeater Tribal
 * Medicine Stick
 * .45-70 Bigboy
 * Tribal Only
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/brush/tribal
	name = "medicine stick"
	desc = "A heavy .45-70 Lever-action rifle. Beautiful paintings coat the fine weapon, a bead that whistles when spun hangs from a hand woven cord."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "brushgunt"
	item_state = "brushgun"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube4570
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3.6)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/brushgunfire.ogg'

/* * * * * * * * * * *
 * Ranger repeater
 * Biggest repeater
 * .308
 * Medium rarity
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/ranger
	name = "long ranger repeater"
	desc = "A lever action chambered in .308. Shares lots of characteristics with lever actions, but also the clunkiness of bolt actions, Best of both worlds, or master of none?"
	icon_state = "308-lever"
	item_state = "brushgun"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube380
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(2.4)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/brushgunfire.ogg'

/* * * * * * * * * * *
 * Ranger repeater tribal
 * Smell-The-Roses
 * .308
 * Tribal Only
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/ranger/tribal
	name = "Smell-The-Roses"
	desc = "A .308 lever action. Clunky, Heavy and decorated by someone with a sick sense of humor. A flowering rose around the bore, it's stem trailing along and petals on a string."
	icon_state = "smell-the-roses"
	item_state = "brushgun"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube380
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(2.4)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/brushgunfire.ogg'

/* * * * * * * * * * *
 * Three oh hate
 * unique repeater
 * .308
 * unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/repeater/ranger/threeohate
	name = "Three Oh Hate"
	desc = "placeholder"

/* * * * * * * * * * * *
 * Bolt-Action Rifles  *
 * * * * * * * * * * * */

/* * * * * * * * * * *
 * Slow rifles
 * Low magazine space
 * More damage
 * Higher caliber
 * Accurate
 * Generally scopeable
 * Common
 * * * * * * * * * * */

/* * * * * * * * * * *
 * Hunting Bolt-Action Rifle
 * Baseline Bolt-Action Rifle
 * .308 / 7.62
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/hunting
	name = "hunting rifle"
	desc = "A sturdy hunting rifle, chambered in .30-06. and in use before the war."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "hunting_rifle"
	item_state = "308"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/hunting
	sawn_desc = "A hunting rifle, crudely shortened with a saw. It's far from accurate, but the short barrel makes it quite portable."
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	scope_state = "scope_long"
	scope_x_offset = 4
	scope_y_offset = 12
	cock_sound = 'sound/weapons/boltpump.ogg'
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'

	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)

/obj/item/gun/ballistic/rifle/hunting/attackby(obj/item/A, mob/user, params)
	..()
	if(istype(A, /obj/item/circular_saw) || istype(A, /obj/item/gun/energy/plasmacutter))
		sawoff(user)
	if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			sawoff(user)

/obj/item/gun/ballistic/rifle/hunting/special
	name = "hypocritical oath"
	desc = "An old, worn-in hunting rifle with leather wrapping the stock. Do (no) harm."
	icon_state = "308special"
	item_state = "308special"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/hunting
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(3)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	scope_state = "scope_long"
	scope_x_offset = 4
	scope_y_offset = 12
	cock_sound = 'sound/weapons/boltpump.ogg'
	fire_sound = 'sound/f13weapons/hunting_rifle.ogg'

	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)


/* * * * * * * * * * *
 * Remmington Bolt-Action Rifle
 * Accurate Bolt-Action Rifle
 * .308 / 7.62
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/hunting/remington
	name = "Remington rifle"
	desc = "A militarized hunting rifle rechambered to 7.62. This one has had the barrel floated with shims to increase accuracy."
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/hunting/remington
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0

/obj/item/gun/ballistic/rifle/hunting/remington/attackby(obj/item/A, mob/user, params) //DO NOT BUBBA YOUR STANDARD ISSUE RIFLE SOLDIER!
	if(istype(A, /obj/item/circular_saw) || istype(A, /obj/item/gun/energy/plasmacutter))
		return
	else if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			return
	else
		..()

/* * * * * * * * * * *
 * Paciencia Bolt-Action Rifle
 * Superstrong Bolt-Action Rifle
 * .308 / 7.62
 * More damage
 * Less magazine
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/hunting/paciencia
	name = "Paciencia"
	desc = "A modified .30-06 hunting rifle with a reduced magazine but an augmented receiver. A Mexican flag is wrapped around the stock. You only have three shots- make them count."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "paciencia"
	item_state = "paciencia"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/hunting/paciencia
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T5
	init_recoil = RIFLE_RECOIL(2.2)

	zoomable = TRUE
	zoom_amt = 10
	zoom_out_amt = 13
	can_scope = FALSE

/obj/item/gun/ballistic/rifle/hunting/paciencia/attackby(obj/item/A, mob/user, params) //no sawing off this one
	if(istype(A, /obj/item/circular_saw) || istype(A, /obj/item/gun/energy/plasmacutter))
		return
	else if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			return
	else
		..()

/* * * * * * * * * * *
 * Mosin Bolt-Action Rifle
 * Moist Bolt-Action Rifle
 * .308 / 7.62
 * Can bayonet
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/mosin
	name = "Mosin-Nagant m38"
	desc = "A rusty old Russian bolt action chambered in 7.62."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "mosin"
	item_state = "308"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T3
	init_recoil = RIFLE_RECOIL(2.5)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	scope_state = "scope_mosin"
	scope_x_offset = 3
	scope_y_offset = 13
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	cock_sound = 'sound/weapons/boltpump.ogg'
	fire_sound = 'sound/f13weapons/boltfire.ogg'

	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)
/* * * * * * * * * * *
 * SMLE Bolt-Action Rifle
 * Quick Bolt-Action Rifle
 * .308 / 7.62
 * Faster cock
 * More tiring cock
 * Can bayonet
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/enfield
	name = "Lee-Enfield rifle"
	desc = "A british rifle sometimes known as the SMLE. It seems to have been re-chambered in .308. Can be sawn off."
	sawn_desc = "This accursed abomination was a common modification for trench warfare. Now some waster is likely using it for close quarters."
	icon = 'fallout/icons/objects/rifles.dmi'
	icon_state = "smle"
	item_state = "smle"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/enfield
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = RIFLE_RECOIL(2.8)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	scope_state = "scope_mosin"
	scope_x_offset = 3
	scope_y_offset = 13
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	cock_sound = 'sound/weapons/boltpump.ogg'
	fire_sound = 'sound/f13weapons/boltfire.ogg'
	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)

/obj/item/gun/ballistic/rifle/enfield/attackby(obj/item/A, mob/user, params)
	..()
	if(istype(A, /obj/item/circular_saw) || istype(A, /obj/item/gun/energy/plasmacutter))
		sawoff(user)
	if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			sawoff(user)

/obj/item/gun/ballistic/rifle/enfield/jungle
	name = "Jungle Carbine"
	desc = "The Rifle No. 5 Mk I, made by the Australian army at Lithgow Small Arms in Australia, its a shortened Enfield used for secondary service in the Australian and New zealand army for jungle warfare other then the L1A1 battle rifle,  made from an SMLE its bolt action holds 10 rounds and sadly cannot fit a scope."
	icon = 'fallout/icons/objects/rifles.dmi'
	icon_state = "junglecarbine"
	item_state = "308"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/enfield
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	cock_delay = GUN_COCK_RIFLE_FAST
	init_recoil = RIFLE_RECOIL(2.8)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = FALSE
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 22
	knife_y_offset = 21
	cock_sound = 'sound/weapons/boltpump.ogg'
	fire_sound = 'sound/f13weapons/boltfire.ogg'
	init_firemodes = list(
		/datum/firemode/semi_auto/slower

	)

/obj/item/gun/ballistic/rifle/antique/gras
	name = "Gras"
	desc = "A very old black powder cartridge gun of French lineage. How has it gotten here? Or survived this long?"
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "gras"
	item_state = "308"
	mag_type = /obj/item/ammo_box/magazine/internal/gras
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T5 // will see if it's too much
	init_recoil = RIFLE_RECOIL(2.5)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	can_scope = TRUE
	scope_state = "scope_mosin"
	scope_x_offset = 3
	scope_y_offset = 13
	can_bayonet = TRUE
	bayonet_state = "bayonet"
	knife_x_offset = 24
	knife_y_offset = 25
	cock_sound = 'sound/f13weapons/grasbolt.ogg'
	fire_sound = 'sound/f13weapons/gras.ogg'
	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)

/* * * * * * * * * * *
 * Salvaged Eastern Rifle
 * Fixed-mag semi-auto rifle
 * .223 / 5.56mm / 5mm
 * Loads 556 and 5mm!
 * loaded one at a time
 *
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/salvaged_eastern_rifle
	name = "salvaged eastern rifle"
	desc = "A clever design adapted out of salvaged surplus eastern rifles and wasteland scarcity. It features a complex loading mechanism \
		and barrel capable of using both 5mm and 5.56mm rifle ammunition with reasonable success. \
		The magazine is welded to the frame, and the loading port angled <i>just enough</i> to make stripper clips not work. \
		Apparently these 'features' to the design, being on every instance of this gun."
	icon = 'fallout/icons/objects/churroguns.dmi'
	icon_state = "salvaged_eastern_rifle"
	item_state = "marksman"
	mag_type = /obj/item/ammo_box/magazine/internal/salvaged_eastern_rifle
	init_mag_type = /obj/item/ammo_box/magazine/internal/salvaged_eastern_rifle
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = RIFLE_RECOIL(0.95)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION

	scope_state = "scope_short"
	scope_x_offset = 4
	scope_y_offset = 12
	can_suppress = TRUE
	suppressor_state = "rifle_suppressor"
	suppressor_x_offset = 27
	suppressor_y_offset = 31
	fire_sound = 'sound/f13weapons/salvaged.ogg'
	can_scope = TRUE
	casing_ejector = TRUE

/* * * * * * * * * * * * * * * * * *
 * Magazine-Fed Bolt-Action Rifles *
 * * * * * * * * * * * * * * * * * */

/* * * * * * * * * * *
 * Slower rifles
 * Low magazine space
 * More damage
 * Higher caliber
 * Accurate
 * Generally scopeable
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/mag
	name = "magazine fed bolt-action rifle template"
	desc = "should not exist."
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
/obj/item/gun/ballistic/rifle/mag/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click to remove the magazine.")

/obj/item/gun/ballistic/rifle/mag/AltClick(mob/living/user)
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(magazine)
		magazine.forceMove(drop_location())
		user.put_in_hands(magazine)
		magazine.update_icon()
		if(magazine.ammo_count())
			playsound(src, 'sound/weapons/gun_magazine_remove_full.ogg', 70, 1)
		else
			playsound(src, "gun_remove_empty_magazine", 70, 1)
		magazine = null
		to_chat(user, span_notice("You pull the magazine out of \the [src]."))
	else if(chambered)
		AC.forceMove(drop_location())
		AC.bounce_away()
		chambered = null
		to_chat(user, span_notice("You unload the round from \the [src]'s chamber."))
		playsound(src, "gun_slide_lock", 70, 1)
	else
		to_chat(user, span_notice("There's no magazine in \the [src]."))
	update_icon()
	return

/obj/item/gun/ballistic/rifle/mag/update_icon_state()
	icon_state = "[initial(icon_state)][magazine ? "-[magazine.max_ammo]" : ""][chambered ? "" : "-e"]"

/* * * * * * * * * * *
 * Anti-Materiel Rifle
 * Huge Bolt-Action Rifle
 * .50MG
 * Slow to fire
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/rifle/mag/antimateriel
	name = "anti-materiel rifle"
	desc = "The Hecate II is a heavy, high-powered bolt action sniper rifle chambered in .50 caliber ammunition. Lacks an iron sight."
	icon = 'icons/fallout/objects/guns/longguns.dmi'
	icon_state = "amr"
	item_state = "amr"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	lefthand_file = 'icons/fallout/onmob/weapons/64x64_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/64x64_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/amr
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HMG_RECOIL(3)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)
	can_scope = FALSE
	zoom_factor = 1
	fire_sound = 'sound/f13weapons/antimaterielfire.ogg'
	cock_sound = 'sound/f13weapons/antimaterielreload.ogg'

//no scope, less capacity, more common
/obj/item/gun/ballistic/rifle/mag/boys
	name = "Boys anti-tank rifle"
	desc = "A heavy british rifle boasting a strong kick and an even stronger punch."
	icon = 'icons/fallout/objects/guns/longguns.dmi'
	icon_state = "boys"
	item_state = "boys"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	lefthand_file = 'icons/fallout/onmob/weapons/64x64_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/64x64_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/boys
	weapon_class = WEAPON_CLASS_RIFLE
	weapon_weight = GUN_TWO_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HMG_RECOIL(3)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION
	init_firemodes = list(
		/datum/firemode/semi_auto/slower
	)
	can_scope = FALSE
	fire_sound = 'sound/f13weapons/antimaterielfire.ogg'
	cock_sound = 'sound/f13weapons/antimaterielreload.ogg'

// BETA // Obsolete
/obj/item/gun/ballistic/rifle/rifletesting
	name = "hunting"
	mag_type = /obj/item/ammo_box/magazine/testbullet
	damage_multiplier = 30

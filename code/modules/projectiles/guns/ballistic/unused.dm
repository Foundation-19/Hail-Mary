//for guns that dont belong in fallout
//WW2 guns, modern guns, reference guns, etc.
//base SS13 weapons dont go here, since they are used as parents for the fallout guns

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

//hefty and clonky
/obj/item/gun/ballistic/automatic/lewis
	name = "Lewis automatic rifle"
	desc = "A relic of a gun, featuring an obscenely heavy watercooled barrel and a high capacity pan magazine."
	icon = 'icons/fallout/objects/guns/longguns.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/64x64_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/64x64_righthand.dmi'
	icon_state = "lewis"
	item_state = "lewis"
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


//scorpion machine pistol. like the M93R, but full auto instead of burst, for better or worse
/obj/item/gun/ballistic/automatic/pistol/ninemil/skorpion
	name = "Skorpion 9mm"
	desc = "A Czech machine pistol developed in the 60s"
	icon = 'fallout/icons/objects/automatic.dmi'
	icon_state = "skorpion"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)

//C93 pistol. damage bonus but single stack magazine. not the best gun, but hey, it's old
/obj/item/gun/ballistic/automatic/pistol/ninemil/c93
	name = "9mm Borchardt"
	desc = "The first mass produced semiautomatic pistol, designed before doublestack magazines existed."
	icon = 'fallout/icons/objects/pistols.dmi'
	icon_state = "borchardt"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm
	mag_type = /obj/item/ammo_box/magazine/m9mm
	disallowed_mags = list(/obj/item/ammo_box/magazine/m9mm/doublestack)
	damage_multiplier = GUN_EXTRA_DAMAGE_T3

//Luger. pretty much the same as a C93, same smol magazine, same semi-auto old gun
/obj/item/gun/ballistic/automatic/pistol/ninemil/c93/luger
	name = "9mm Luger"
	desc = "A classy german 9mm pistol, which takes single stack magazines."
	icon_state = "luger"

//9mm carbine: pistol capacity, but two shot burst. needs suppressor set correctly
/obj/item/gun/ballistic/automatic/pistol/beretta/carbine
	name = "9mm carbine"
	desc = "A lightweight carbine manufactured by Hi-Point, takes pistol magazines."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "citykiller" //old citykiller sprite looks close enough to a hi-point carbine
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	weapon_class = WEAPON_CLASS_CARBINE
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_firemodes = list(
		/datum/firemode/burst/two/fast,
		/datum/firemode/semi_auto/fast
	)

/obj/item/gun/ballistic/automatic/pistol/sig/trusty //wiggles x 2
	name = "Trusty Sig P220"
	desc = "The P220 Sig Sauer. A Swiss designed pistol that is compact and has an average rate of fire for a pistol. A trusty copy valued for its reliability."
	icon_state = "sig"
	init_mag_type = /obj/item/ammo_box/magazine/m45/rubber
	mag_type = /obj/item/ammo_box/magazine/m45
	disallowed_mags = list(/obj/item/ammo_box/magazine/m45/socom, /obj/item/ammo_box/magazine/m45/socom/empty)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(1.1)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 20
	fire_sound = 'sound/f13weapons/45revolver.ogg'

/obj/item/gun/ballistic/automatic/pistol/sig/worn //wiggles x 3
	name = "Sig P220"
	desc = "The P220 Sig Sauer. A Swiss designed pistol that is compact and has an average rate of fire for a pistol."
	icon_state = "sig"
	init_mag_type = /obj/item/ammo_box/magazine/m45
	mag_type = /obj/item/ammo_box/magazine/m45
	disallowed_mags = list(/obj/item/ammo_box/magazine/m45/socom, /obj/item/ammo_box/magazine/m45/socom/empty)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = HANDGUN_RECOIL(1.1)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 20
	fire_sound = 'sound/f13weapons/45revolver.ogg'

/obj/item/gun/ballistic/automatic/pistol/sig/blackkite
	name = "Black Kite"
	desc = "These large Sig Sauer pistols have seen much wear, and have been kept maintained with parts from the more common P220, necessitating the rechambering to .45ACP."
	icon_state = "pistol14"
	item_state = "gun"
	init_mag_type = /obj/item/ammo_box/magazine/m45
	mag_type = /obj/item/ammo_box/magazine/m45
	disallowed_mags = list(/obj/item/ammo_box/magazine/m45/socom, /obj/item/ammo_box/magazine/m45/socom/empty)

	auto_eject_sound = 'sound/weapons/gun_magazine_remove_full.ogg'
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 20
	fire_sound = 'sound/f13weapons/combatrifle.ogg'

/* * * * * * * * * * *
 * Schmeisser
 * Mid-tier auto pistol
 * 10mm
 * No accuracy
 * Less damage
 * Mid rarity
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/schmeisser
	name = "Schmeisser Classic"
	desc = "An obscure pistol that fits a 10mm magazine and is capable of full auto. Fires from an open bolt. Innacurate on the first shot, but it doesn't get much worse. Or better."
	icon_state = "bornheim"
	item_state = "pistolchrome"
	icon_prefix = "bornheim"
	fire_sound = 'sound/f13weapons/10mm_fire_02.ogg'
	init_mag_type = /obj/item/ammo_box/magazine/m10mm/adv/simple
	mag_type = /obj/item/ammo_box/magazine/m10mm // load any 10mm pistol ammos
	init_recoil = HANDGUN_RECOIL(2.3)
	disallowed_mags = list(
		/obj/item/ammo_box/magazine/m10mm/adv/ext,
		/obj/item/ammo_box/magazine/m10mm/adv/ext/empty,
		/obj/item/ammo_box/magazine/m10mm/rifle)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast,
	)

/* * * * * * * * * * *
 * Mk. 23 Semi-Auto
 * Tacticool Medium pistol
 * .45ACP
 * More accurate
 * Lighter
 * Less recoil
 * Faster to shoot
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/mk23
	name = "Mk. 23"
	desc = "A very tactical pistol chambered in .45 ACP with a built in laser sight and attachment point for a seclite."
	icon_state = "mk23"
	init_mag_type = /obj/item/ammo_box/magazine/m45/socom
	mag_type = /obj/item/ammo_box/magazine/m45 // load any .45 pistol ammos
	weapon_class = WEAPON_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = HANDGUN_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	can_flashlight = TRUE
	gunlight_state = "flight"
	flight_x_offset = 16
	flight_y_offset = 13
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 28
	suppressor_y_offset = 20
	fire_sound = 'sound/f13weapons/45revolver.ogg'
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION // Tacticool

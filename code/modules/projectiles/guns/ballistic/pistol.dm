//IN THIS DOCUMENT: Pistol template, Light pistols, Heavy pistols
// See gun.dm for keywords and the system used for gun balance



///////////////////
//PISTOL TEMPLATE//
///////////////////


/obj/item/gun/ballistic/automatic/pistol
	name = "pistol template"
	desc = "should not be here. Bugreport."
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	lefthand_file = 'icons/fallout/onmob/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/fallout/onmob/weapons/guns_righthand.dmi'
	item_state = "gun"
	weapon_class = WEAPON_CLASS_SMALL
	mag_type = /obj/item/ammo_box/magazine/m10mm/adv/simple
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	can_suppress = TRUE
	equipsound = 'sound/f13weapons/equipsounds/pistolequip.ogg'
	init_recoil = HANDGUN_RECOIL(1)
	dualwield_spread_mult = 2.5
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)

/obj/item/gun/ballistic/automatic/pistol/no_mag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/pistol/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"


/* * * * * * * * *
 * LIGHT PISTOLS *
 * * * * * * * * */

/* * * * * * * * * * *
 * .22 pistol
 * Extra light pistol
 * .22LC
 * Accurate
 * Quiet
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/pistol22
	name = ".22 pistol"
	desc = "The silenced .22 pistol is a sporting handgun with an integrated silencer."
	icon_state = "silenced22"
	mag_type = /obj/item/ammo_box/magazine/m22
	disallowed_mags = list(/obj/item/ammo_box/magazine/m22/extended)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(0.6)
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION // plug em in the skull!
	init_firemodes = list(
		/datum/firemode/semi_auto/fastest
	)
	can_suppress = FALSE
	silenced = TRUE
	fire_sound_silenced = 'sound/f13weapons/22pistol.ogg'

/* * * * * * * * * * *
 * Browning Hi-Power
 * Baseline Light pistol
 * 9mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/ninemil
	name = "Browning Hi-power"
	desc = "A mass produced pre-war Browning Hi-power 9mm pistol."
	icon_state = "ninemil"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	mag_type = /obj/item/ammo_box/magazine/m9mm // load any 9mm pistol ammos
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 19
	fire_sound = 'sound/f13weapons/ninemil.ogg'

//9mm automatic pistol. smol magazine, zippy gun
/obj/item/gun/ballistic/automatic/pistol/ninemil/auto
	name = "9mm autopistol"
	desc = "A compact 9mm pistol with an autoseer installed. only accepts single stack magazines."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "pistol"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm
	mag_type = /obj/item/ammo_box/magazine/m9mm
	disallowed_mags = list(/obj/item/ammo_box/magazine/m9mm/doublestack)
	init_firemodes = list(
		/datum/firemode/automatic/rpm150,
		/datum/firemode/semi_auto/fast
	)

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

//ruby pistol. single stack bootgun, otherwise unexceptional
/obj/item/gun/ballistic/automatic/pistol/ninemil/ruby
	name = "Ruby"
	desc = "A petite pocket pistol designed by Colt and used extensively by the French Army until the late '50s"
	icon = 'fallout/icons/objects/pistols.dmi'
	icon_state = "ruby"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm
	mag_type = /obj/item/ammo_box/magazine/m9mm
	disallowed_mags = list(/obj/item/ammo_box/magazine/m9mm/doublestack)
	weapon_class = WEAPON_CLASS_TINY

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

/* * * * * * * * * * *
 * Maria
 * Gaudy Light pistol
 * 9mm
 * +10% damage
 * Accurate
 * No recoil
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/ninemil/maria
	name = "Maria"
	desc = "An ornately-decorated pre-war Browning Hi-power 9mm pistol with pearl grips and a polished nickel finish. The firing mechanism has been upgraded, so for anyone on the receiving end, it must seem like an eighteen-karat run of bad luck."
	icon_state = "maria"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_firemodes = list(
		/datum/firemode/semi_auto/faster
	)

/* * * * * * * * * * *
 * Beretta M9FS Semi-Auto
 * Another Light pistol
 * 9mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/beretta
	name = "Beretta M9FS"
	desc = "One of the more common 9mm pistols, the Beretta is popular due to its reliability, 15 round magazine and good looks."
	icon_state = "beretta"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	mag_type = /obj/item/ammo_box/magazine/m9mm // load any 9mm pistol ammos
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_AKIMBO
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	can_suppress = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 20
	fire_sound = 'sound/f13weapons/9mm.ogg'

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

/* * * * * * * * * * *
 * Beretta M9R Burst
 * Burst Light pistol
 * 9mm
 * Rare
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/beretta/automatic
	name = "Beretta M93R"
	desc = "A rare select fire variant of the M93R."
	icon_state = "m93r"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	mag_type = /obj/item/ammo_box/magazine/m9mm // load any 9mm pistol ammos
	//extra_mag_types = list(/obj/item/ammo_box/magazine/uzim9mm) //as sad as it is to remove, want to bring the power level down slightly so it can be common
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/faster,
		/datum/firemode/burst/three/faster,
	)

/* * * * * * * * * * *
 * Worn Beretta M9R Burst
 * Burst Light pistol
 * 9mm
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/beretta/automatic/worn
	name = "Trusty Beretta M93R"
	desc = "A rare select fire variant of the M93R. Aged and reliable, but still with that strong punch!"
	icon_state = "m93r"
	init_mag_type = /obj/item/ammo_box/magazine/m9mm/doublestack
	mag_type = /obj/item/ammo_box/magazine/m9mm // load any 9mm pistol ammos
	//extra_mag_types = list(/obj/item/ammo_box/magazine/uzim9mm) // let it take smg mags
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/faster,
		/datum/firemode/burst/three/faster
	)

/* * * * * * * * * *
 * MEDIUM PISTOLS  *
 * * * * * * * * * */

/* * * * * * * * * * *
 * N99 Pistol Semi-Auto
 * Baseline Medium pistol
 * 10mm
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/n99
	name = "10mm pistol"
	desc = "A large, pre-war styled, gas-operated 10mm pistol."
	icon_state = "n99"
	init_mag_type = /obj/item/ammo_box/magazine/m10mm/adv/simple
	mag_type = /obj/item/ammo_box/magazine/m10mm // load any 10mm pistol ammos
	disallowed_mags = list(
		/obj/item/ammo_box/magazine/m10mm/adv/ext,
		/obj/item/ammo_box/magazine/m10mm/adv/ext/empty,
		/obj/item/ammo_box/magazine/m10mm/rifle)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	suppressor_state = "n99_suppressor"
	suppressor_x_offset = 29
	suppressor_y_offset = 15
	fire_sound = 'sound/f13weapons/10mm_fire_02.ogg'

/* * * * * * * * * * *
 * Executive Pistol Burst Only
 * Burst Medium pistol
 * 10mm
 * Burst
 * +10% damage
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/n99/executive
	name = "the Executive"
	desc = "A modified N99 pistol with an accurate two-round-burst and a blue Vault-Tec finish, a status symbol for some Overseers."
	icon_state = "executive"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_firemodes = list(
		/datum/firemode/semi_auto,
		/datum/firemode/burst/three
	)

/obj/item/gun/ballistic/automatic/pistol/n99/executive/worn
	name = "the Executive"
	desc = "A modified N99 pistol with an accurate two-round-burst and a blue Vault-Tec finish, a status symbol for some Overseers."
	icon_state = "executive"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto
	)

/* * * * * * * * * * *
 * Crusader Pistol Semi-Auto
 * Cool Medium pistol
 * 10mm
 * Flavorful
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/n99/crusader
	name = "\improper Crusader pistol"
	desc = "A large-framed N99 pistol emblazoned with the colors and insignia of the Brotherhood of Steel. It feels heavy in your hand."
	icon_state = "crusader"
	item_state = "crusader"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto
	)

/obj/item/gun/ballistic/automatic/pistol/n99/crusader/thingpony
	name = "\improper Painted pistol"
	desc = "A variant of the n99 with a custom paint job done on it. The paint used is of the highest quality!"
	icon = 'icons/fallout/objects/guns/ballistic.dmi'
	icon_state = "ponycrusader"
	item_state = "ponycrusader"
	init_recoil = HANDGUN_RECOIL(0.8)

/* * * * * * * * * * *
 * Type 17 Semi-Auto
 * Cheap Medium pistol
 * 10mm
 * Less accurate
 * Less damage
 * Common
 * * * * * * * * * * */
/obj/item/gun/ballistic/automatic/pistol/type17
	name = "Type 17"
	desc = "Chinese military sidearm at the time of the Great War. The ones around are old and worn, but somewhat popular due to the long barrel and rechambered in 10mm after the original ammo ran dry decades ago."
	icon_state = "chinapistol"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_LESS_DAMAGE_T1
	init_recoil = HANDGUN_RECOIL(0.6)

	can_suppress = FALSE
	fire_sound = 'sound/f13weapons/10mm_fire_02.ogg'
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)

//automatic 9mm, compact and high performance
/obj/item/gun/ballistic/automatic/pistol/type17/c96auto
	name = "Mauser M712"
	desc = "A late model of the classic Mauser C96, featuring a removable box magazine and automatic fire select. takes 20 round stick magazines."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "mauser"
	mag_type = /obj/item/ammo_box/magazine/uzim9mm/rockwell
	init_mag_type = /obj/item/ammo_box/magazine/uzim9mm/rockwell
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast
	)

// Tox's C96. slightly less damage for a 9mm pistol, but bigger magazine and better recoil
/obj/item/gun/ballistic/automatic/pistol/type17/c96auto/tox
	name = "Tox's C96"
	desc = "A unique C96 Mauser found and maintained by a sand-cat named Tox Mckit. The C96 depicted is engraved with silver Baroque Motifs. The handle is made of ivory and on the bolt is an engraving that says 'Ange'."
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)

/* * * * * * * * * * *
 * Sig P220
 * Light Mediumer pistol
 * .45
 * Less recoil
 * faster shooting
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/sig //wiggles
	name = "Sig P220"
	desc = "The P220 Sig Sauer. A Swiss designed pistol that is compact and has an average rate of fire for a pistol."
	icon_state = "sig"
	init_mag_type = /obj/item/ammo_box/magazine/m45
	mag_type = /obj/item/ammo_box/magazine/m45
	disallowed_mags = list(/obj/item/ammo_box/magazine/m45/socom, /obj/item/ammo_box/magazine/m45/socom/empty)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(1.1)
	init_firemodes = list(
		/datum/firemode/semi_auto/fast
	)
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 20
	fire_sound = 'sound/f13weapons/45revolver.ogg'

/obj/item/gun/ballistic/automatic/pistol/sig/trusty //never fucking use 'wiggles' as a comment ever again you fucking degenerate
	name = "Trusty Sig P220"
	desc = "The P220 Sig Sauer. A Swiss designed pistol that is compact and has an average rate of fire for a pistol. A trusty copy valued for its reliability."
	icon_state = "sig"
	init_mag_type = /obj/item/ammo_box/magazine/m45/rubber
	mag_type = /obj/item/ammo_box/magazine/m45
	disallowed_mags = list(/obj/item/ammo_box/magazine/m45/socom, /obj/item/ammo_box/magazine/m45/socom/empty)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
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
	weapon_weight = GUN_ONE_HAND_ONLY
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
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/automatic/rpm200,
		/datum/firemode/semi_auto/fast,
	)

/* * * * * * * * * * *
 * M1911 Semi-Auto
 * Light Medium pistol
 * .45ACP
 * Less melee force
 * More accurate
 * Common
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/m1911
	name = "M1911"
	desc = "A classic .45 handgun with a small magazine capacity."
	icon_state = "m1911"
	item_state = "pistolchrome"
	init_mag_type = /obj/item/ammo_box/magazine/m45
	mag_type = /obj/item/ammo_box/magazine/m45
	disallowed_mags = list(/obj/item/ammo_box/magazine/m45/socom, /obj/item/ammo_box/magazine/m45/socom/empty)
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto
	)
	suppressor_state = "pistol_suppressor"
	suppressor_x_offset = 30
	suppressor_y_offset = 21
	fire_sound = 'sound/f13weapons/45revolver.ogg'

/* * * * * * * * * * *
 * M1911 Custom Semi-Auto
 * Lighter Medium pistol
 * .45ACP
 * Lighter
 * Less recoil
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/m1911/custom
	name = "M1911 Custom"
	desc = "A well-maintained stainless-steel frame 1911, with genuine wooden grips."
	icon_state = "m1911_custom"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_firemodes = list(
		/datum/firemode/semi_auto
	)

/obj/item/gun/ballistic/automatic/pistol/m1911/custom/jackal
	name = "Santa Muerte"
	desc = "A custom built 1911 with a brushed brass plated grip, a shiny chrome finish, and a custom muzzle brake.. It has an excerpt of a prayer to lady death etched neatly in it's slide, evoking her protection from evil forces."
	icon_state = "santa_muerte"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2
	init_firemodes = list(
		/datum/firemode/semi_auto
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
	weapon_weight = GUN_ONE_HAND_ONLY
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

/* * * * * * * * * * * * * *
 * HEAVY SEMI-AUTO PISTOLS *
 * * * * * * * * * * * * * */

/* * * * * * * * * * *
 * Desert Eagle Semi-Auto
 * Baseline Heavy pistol
 * .44 Magnum
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/deagle
	name = "Desert Eagle"
	desc = "A robust .44 magnum semi-automatic handgun."
	icon_state = "deagle"
	item_state = "deagle"
	init_mag_type = /obj/item/ammo_box/magazine/m44
	mag_type = /obj/item/ammo_box/magazine/m44 // load any .44 pistol ammos
	weapon_class = WEAPON_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	can_suppress = FALSE
	fire_sound = 'sound/f13weapons/44mag.ogg'

/* * * * * * * * * * *
 * El Capitan Semi-Auto
 * Big Heavy pistol
 * 14mm
 * More damage
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/deagle/elcapitan
	name = "El Capitan"
	desc = "The Captain loves his gun, despite some silly gunsmith adding some gas venting to the barrel after his second visit to the surgeon for recoil-related wrist injuries."
	icon_state = "elcapitan"
	item_state = "deagle"
	mag_type = /obj/item/ammo_box/magazine/m14mm
	init_mag_type = /obj/item/ammo_box/magazine/m14mm
	weapon_class = WEAPON_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T2 //T3 might've been a lil much. will see
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	fire_sound = 'sound/f13weapons/magnum_fire.ogg'

/* * * * * * * * * * *
 * Automag Semi-Auto
 * Cooler Heavy pistol
 * .44 magnum
 * More accurate
 * Less recoil
 * More damage
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/automag
	name = "Automag"
	desc = "A long-barreled .44 magnum semi-automatic handgun."
	icon_state = "automag"
	item_state = "deagle"
	init_mag_type = /obj/item/ammo_box/magazine/m44/automag
	mag_type = /obj/item/ammo_box/magazine/m44/automag
	weapon_class = WEAPON_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	can_suppress = FALSE
	fire_sound = 'sound/f13weapons/44mag.ogg'
	gun_accuracy_zone_type = ZONE_WEIGHT_PRECISION

/* * * * * * * * * * *
 * 14mm Semi-Auto
 * Super Heavy pistol
 * 14mm
 * Less accurate
 * Shoots slower
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/pistol14
	name = "14mm pistol"
	desc = "A Swiss SIG-Sauer 14mm handgun, powerful but a little inaccurate"
	icon_state = "pistol14"
	mag_type = /obj/item/ammo_box/magazine/m14mm
	init_mag_type = /obj/item/ammo_box/magazine/m14mm
	weapon_class = WEAPON_CLASS_NORMAL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
	can_suppress = FALSE
	fire_sound = 'sound/f13weapons/magnum_fire.ogg'

/* * * * * * * * * * *
 * 14mm Compact Semi-Auto
 * super Heavy pistol
 * 14mm
 * Even less accurate
 * Shoots slower
 * Slower to recover recoil
 * Less melee damage
 * Uncommon
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/pistol14/compact
	name = "compact 14mm pistol"
	desc = "A Swiss SIG-Sauer 14mm handgun, this one is a compact model for concealed carry."
	icon_state = "pistol14_compact"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_0
	init_recoil = HANDGUN_RECOIL(1.2)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
/* * * * * * * * * * *
 * Little Devil Semi-Auto
 * Super Duper Heavy pistol
 * 14mm
 * More accurate
 * Shoots slower
 * More damage
 * Less recoil
 * Unique
 * * * * * * * * * * */

/obj/item/gun/ballistic/automatic/pistol/pistol14/lildevil
	name= "Little Devil 14mm pistol"
	desc = "A Swiss SIG-Sauer 14mm handgun, this one is a finely tuned custom firearm from the Gunrunners."
	icon_state = "lildev"
	weapon_class = WEAPON_CLASS_SMALL
	weapon_weight = GUN_ONE_HAND_ONLY
	damage_multiplier = GUN_EXTRA_DAMAGE_T1
	init_recoil = HANDGUN_RECOIL(0.8)
	init_firemodes = list(
		/datum/firemode/semi_auto/slow
	)
/////////////////////////////////
// TEMPORARY REMOVE AFTER BETA //
/////////////////////////////////obsolete

/obj/item/gun/ballistic/automatic/pistol/pistoltesting
	name = "pistol"
	damage_multiplier = 18
	mag_type = /obj/item/ammo_box/magazine/testbullet

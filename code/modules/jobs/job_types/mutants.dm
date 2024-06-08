/datum/job/smutant
	title = "Super Mutant"
	flag = F13SMUTANT
	faction = FACTION_SMUTANT
	selection_color = "#26bf47"
	total_positions = 2
	spawn_positions = 2
	description = "You are one of Shale's Super Mutants sent to help secure a foothold in this region, Your main goal is the strengthening of your Warband, Do NOT fraternize with non Super Mutants, Secure weapons and supplies, Get Human subjects for your Warband, Follow your leader, And help The Army restore The Unity's former glory."
	supervisors = "Your Super Mutant Leader"
	display_order = JOB_DISPLAY_ORDER_F13SMUTANT
	outfit = /datum/outfit/job/smutant

	loadout_options = list(
	/datum/outfit/loadout/smutantbrute,
	/datum/outfit/loadout/smutantsoldier,
	/datum/outfit/loadout/smutantogre,
	)

/datum/outfit/job/smutant
	name = "Super Mutant"
	jobtype = /datum/job/smutant
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/explorer
	uniform = /obj/item/clothing/under/f13/raider_leather
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit
	box_two = /obj/item/storage/survivalkit/medical

/datum/outfit/loadout/smutantbrute
	name = "Brute"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/light/leather = 1,
		/obj/item/clothing/head/helmet/f13/raidermetal = 1,
		/obj/item/twohanded/sledgehammer/simple = 1,
		/obj/item/grenade/f13/frag = 2
	)

/datum/outfit/loadout/smutantsoldier
	name = "Soldier"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/heavy/metal = 1,
		/obj/item/clothing/head/helmet/knight/f13/metal = 1,
		/obj/item/gun/ballistic/rifle/hunting/obrez = 1,
		/obj/item/ammo_box/a308 = 2
	)

/datum/outfit/loadout/smutantogre
	name = "Ogre"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/raider/raidercombat = 1,
		/obj/item/clothing/head/helmet/f13/raidercombathelmet = 1,
		/obj/item/melee/unarmed/brass/spiked = 1,
		/obj/item/restraints/legcuffs/bola = 3
	)

/datum/job/smutant_boss
	title = "Super Mutant Leader"
	flag = F13SMUTANTLEADER
	faction = FACTION_SMUTANT
	selection_color = "#26bf47"
	total_positions = 1
	spawn_positions = 1
	description = "You are the Super Mutant Master in charge of this area's Warband, A seasoned killer, Your main goal is the strengthening of your Warband, Do NOT fraternize with non Super Mutants, Organize your men, Gather supplies, Bolster your numbers, And help The Army restore The Unity's Former Glory."
	supervisors = "Shale's Army"
	display_order = JOB_DISPLAY_ORDER_F13SMUTANTLEADER
	outfit = /datum/outfit/job/smutant_boss

	loadout_options = list(
	/datum/outfit/loadout/smutantassassin,
	/datum/outfit/loadout/smutantsergeant,
	/datum/outfit/loadout/smutantboar,
	)

/datum/outfit/job/smutant_boss
	name = "Super Mutant Leader"
	jobtype = /datum/job/smutant_boss
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/explorer
	uniform = /obj/item/clothing/under/f13/raiderharness
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit
	box_two = /obj/item/storage/survivalkit/medical

/datum/outfit/loadout/smutantassassin
	name = "Assassin"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/light/leather/leathermk2 = 1,
		/obj/item/clothing/head/helmet/f13/deathskull = 1,
		/obj/item/clothing/mask/balaclava = 1,
		/obj/item/twohanded/fireaxe/bmprsword = 1,
		/obj/item/grenade/smokebomb = 1,
		/obj/item/stealthboy = 1
	)

/datum/outfit/loadout/smutantsergeant
	name = "Sergeant"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/heavy/metal/reinforced = 1,
		/obj/item/clothing/head/helmet/knight/f13/metal/reinforced = 1,
		/obj/item/clothing/mask/facewrap = 1,
		/obj/item/gun/ballistic/automatic/bar = 1,
		/obj/item/ammo_box/magazine/m308/ext = 2
	)

/datum/outfit/loadout/smutantboar
	name = "Raging Boar"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/combat/dark = 1,
		/obj/item/clothing/head/helmet/f13/combat/dark = 1,
		/obj/item/clothing/mask/pig = 1,
		/obj/item/melee/unarmed/lacerator = 1,
		/obj/item/book/granter/martial/raging_boar = 1
	)


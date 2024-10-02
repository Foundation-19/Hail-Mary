/datum/job/rebels
	department_flag = REBELS
	selection_color = "#323232"
	faction = FACTION_REBEL

	access = list(ACCESS_ENCLAVE)
	minimal_access = list(ACCESS_ENCLAVE)

/datum/outfit/job/rebels
	id = null
	ears = /obj/item/radio/headset/headset_sec

/datum/outfit/job/rebels
	id = /obj/item/card/id/dogtag/town
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/army/assault/ncr
	r_pocket = /obj/item/flashlight/seclite
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/survivalkit = 1,
		/obj/item/storage/survivalkit/medical = 1
	)

/datum/outfit/job/rebels/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/settler, \
		/obj/item/clothing/under/f13/brahminm, \
		/obj/item/clothing/under/f13/machinist, \
		/obj/item/clothing/under/f13/lumberjack, \
		/obj/item/clothing/under/f13/roving)

/datum/outfit/job/rebels/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)

//Rebel soldier
/datum/job/rebels/soldier
	title = "Roguewave Rebel Soldier"
	flag = F13REBELSOLDIER
	total_positions = 5
	spawn_positions = 5
	access = list(ACCESS_ENCLAVE)
	display_order = JOB_DISPLAY_ORDER_F13REBELSOLDIER
	description = "When the Legion arrived and conquered the region, you knew that you had to do something. Maybe you are a NCR soldier wanting to bring the fight to their soil. Maybe raider wanting to spill some legion blood. Maybe you are Enclave Remnant crewing the ship and assuring your survival. What ever you are, your ennemy is the legion."
	supervisors = "The captain."
	outfit = /datum/outfit/job/rebels

	loadout_options = list(
		/datum/outfit/loadout/ncrfunded,		
		/datum/outfit/loadout/survivingenclave,	
		/datum/outfit/loadout/stolenraider,	
		)

/datum/outfit/job/rebels/soldier
	name = "Roguewave Rebel Soldier"
	jobtype = /datum/job/rebels/soldier
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
		/obj/item/grenade/flashbang = 1,
		/obj/item/pda = 1,
		/obj/item/ammo_box/magazine/m308 = 2,
		/obj/item/gun/ballistic/automatic/pistol/deagle = 1,
		/obj/item/ammo_box/magazine/m44 = 2
		)

/datum/outfit/loadout/survivingenclave
	name = "Surviving Enclave Gear"
	suit = /obj/item/clothing/suit/armor/medium/vest/enclave
	head = /obj/item/clothing/head/f13/enclave/peacekeeper
	suit_store = /obj/item/gun/ballistic/rifle/hobo/plasmacaster
	backpack_contents = list(
		/obj/item/ammo_box/plasmamusket = 4,
		/obj/item/clothing/shoes/f13/enclave/serviceboots = 1,
		/obj/item/clothing/under/f13/exile/enclave =1,
		)

/datum/outfit/loadout/stolenraider
	name = "Stolen Raider gear"
	suit = /obj/item/clothing/suit/armor/light/raider/badlands
	head = /obj/item/clothing/head/helmet/f13/raidercombathelmet
	suit_store = /obj/item/shield/riot/tower/scrap
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/melee/powered/ripper =1,
		)

/datum/outfit/loadout/ncrfunded
	name = "NCR Funded Gear"
	suit = /obj/item/clothing/suit/armor/medium/vest/ncr/mant
	head = /obj/item/clothing/head/f13/ncr/goggles
	suit_store = /obj/item/gun/ballistic/automatic/service/carbine
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m556/rifle/assault = 3,
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/clothing/under/f13/ncr/torn =1,
		)

/datum/outfit/job/rebels/medic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)


// REBEL MEDIC


/datum/job/rebels/medic
	title = "Roguewave Rebel medic"
	flag = F13REBELMEDIC
	total_positions = 2
	spawn_positions = 2
	access = list(ACCESS_ENCLAVE)
	display_order = JOB_DISPLAY_ORDER_F13REBELMEDIC
	description = "When the Legion arrived and conquered the region, you knew that you had to do something. Maybe you are a NCR medic wanting to bring the fight to their soil. Maybe raider wanting to spill some legion blood. Maybe you are Enclave Remnant crewing the ship and assuring your survival. What ever you are, your ennemy is the legion."
	supervisors = "The captain."
	outfit = /datum/outfit/job/rebels/medic

	loadout_options = list(
		/datum/outfit/loadout/ncrmedicfunded,		
		/datum/outfit/loadout/survivingmedicenclave,	
		/datum/outfit/loadout/stolenmedicraider,	
		)

/datum/outfit/job/rebels/medic
	name = "Roguewave Rebel medic"
	id = /obj/item/card/id/dogtag/town
	jobtype = /datum/job/rebels/medic
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/army/assault/ncr
	r_pocket = /obj/item/flashlight/seclite
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/survivalkit = 1,
		/obj/item/storage/survivalkit/medical = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
		/obj/item/grenade/flashbang = 1,
		/obj/item/pda = 1,
		/obj/item/melee/onehanded/knife/survival = 1
		)

/datum/outfit/loadout/survivingmedicenclave
	name = "Surviving Enclave Medical Gear"
	suit = /obj/item/clothing/suit/armor/medium/vest/enclave
	head = /obj/item/clothing/head/f13/enclave/peacekeeper
	suit_store = /obj/item/gun/energy/laser/plasma/pistol
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/ec = 4,
		/obj/item/clothing/shoes/f13/enclave/serviceboots = 1,
		/obj/item/clothing/under/f13/exile/enclave =1,
		)

/datum/outfit/loadout/stolenmedicraider
	name = "Quack Medic"
	suit = /obj/item/clothing/suit/armor/light/raider/badlands
	head = /obj/item/clothing/head/helmet/f13/raidercombathelmet
	suit_store = /obj/item/shield/riot/tower/scrap
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/melee/powered/ripper =1,
		)

/datum/outfit/loadout/ncrmedicfunded
	name = "NCR CM Gear"
	suit = /obj/item/clothing/suit/armor/medium/vest/ncr/mant
	head = /obj/item/clothing/head/f13/ncr/steelpot_med
	suit_store = /obj/item/gun/ballistic/automatic/service/carbine
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m556/rifle/assault = 3,
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/clothing/under/f13/ncr/torn =1,
		)

/datum/outfit/job/rebels/medic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/jet)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/turbo)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/psycho)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/stimpak/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/stimpak5/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/buffout)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steady)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_SURGERY_MID, src)
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)

// 
// REBEL CAPTAIN
// 

/datum/job/rebels/captain
	title = "Roguewave Rebel Captain"
	flag = F13REBELCAPTAIN
	total_positions = 1
	spawn_positions = 1
	access = list(ACCESS_ENCLAVE, ACCESS_CHANGE_IDS)
	display_order = JOB_DISPLAY_ORDER_F13REBELCAPTAIN
	description = "You lead this team of soldiers of fortune. Your gear is from old enclave supply, and gifts from the NCR... And a few stolen goods."
	outfit = /datum/outfit/job/rebels/captain

	loadout_options = list(
		/datum/outfit/loadout/capncrfunded,		
		/datum/outfit/loadout/capsurvivingenclave,	
		/datum/outfit/loadout/capstolenraider,	
		)

/datum/outfit/job/rebels/captain
	name = "Roguewave Rebel Captain"
	jobtype = /datum/job/enclave/enclavecpt

	suit_store = /obj/item/gun/ballistic/automatic/fnfal
	accessory = /obj/item/clothing/accessory/ncr/CPT
	id = /obj/item/card/id/dogtag/enclave/officer
	ears = /obj/item/radio/headset/headset_sec/com

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
		/obj/item/grenade/flashbang = 1,
		/obj/item/pda = 1,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/ammo_box/magazine/m308 = 2,
		/obj/item/gun/ballistic/automatic/pistol/deagle = 1,
		/obj/item/ammo_box/magazine/m44 = 2
		)

/datum/outfit/job/rebels/captain/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	if(H.mind)
		var/obj/effect/proc_holder/spell/terrifying_presence/S = new /obj/effect/proc_holder/spell/terrifying_presence
		H.mind.AddSpell(S)

/datum/outfit/loadout/capsurvivingenclave
	name = "Captain's Heritage"
	suit = /obj/item/clothing/suit/armor/medium/combat/enclave
	head = /obj/item/clothing/head/helmet/f13/enclave/usmcriot
	suit_store = /obj/item/gun/energy/laser/plasma/glock
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/ec = 4,
		/obj/item/clothing/shoes/f13/enclave/serviceboots = 1,
		/obj/item/clothing/under/f13/enclave_officer =1,
		)

/datum/outfit/loadout/capstolenraider
	name = "Raider boss gear"
	suit = /obj/item/clothing/suit/armor/medium/combat/mk2/raider
	head = /obj/item/clothing/head/helmet/f13/combat/mk2/raider
	suit_store = /obj/item/twohanded/chainsaw
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/melee/powered/ripper =1,
		)

/datum/outfit/loadout/capncrfunded
	name = "Desert Ranger Stash"
	suit = /obj/item/clothing/suit/armor/rangercombat/foxcustom
	head = /obj/item/clothing/head/helmet/f13/ncr/rangercombat/desert
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/clothing/under/f13/ranger/modif_ranger =1,
		)

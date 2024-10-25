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
	uniform = /obj/item/clothing/under/f13/bdu
	shoes = /obj/item/clothing/shoes/jackboots
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/survivalkit = 1,
		/obj/item/storage/survivalkit/medical = 1
	)

/datum/outfit/job/rebels/citizen/pre_equip(mob/living/carbon/human/H)
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
	title = "Roguewave Den Marines"
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
	suit_store = /obj/item/gun/energy/laser/aer9/focused
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc = 3,
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
	title = "Roguewave Den Doctor"
	flag = F13REBELMEDIC
	total_positions = 2
	spawn_positions = 2
	access = list(ACCESS_ENCLAVE)
	display_order = JOB_DISPLAY_ORDER_F13REBELMEDIC
	description = "When the Legion arrived and conquered the region, you knew that you had to do something. Maybe you are a NCR medic wanting to bring the fight to their soil. Maybe raider wanting to spill some legion blood. Maybe you are Enclave Remnant crewing the ship and assuring your survival. Your job is to heal people of the carrier."
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
	title = "Roguewave Den Captain"
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
	suit_store = /obj/item/melee/powered/ripper
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		)

/datum/outfit/loadout/capncrfunded
	name = "Desert Ranger Stash"
	suit = /obj/item/clothing/suit/armor/rangercombat/foxcustom
	head = /obj/item/clothing/head/helmet/f13/ncr/rangercombat/desert
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/clothing/under/f13/ranger/modif_ranger =1,
		)

//Rebel Guard
/datum/job/rebels/guard
	title = "Roguewave Den Guard"
	flag = F13REBELGUARD
	total_positions = 3
	spawn_positions = 3
	access = list(ACCESS_ENCLAVE)
	display_order = JOB_DISPLAY_ORDER_F13REBELGUARD
	description = "While marines head out in the field, you stay inside the carrier and make sure its defended, and in a relative orders. You follow orders from the captain only."
	supervisors = "The captain."
	outfit = /datum/outfit/job/rebels

	loadout_options = list(
		/datum/outfit/loadout/ncrgardfunded,		
		/datum/outfit/loadout/survivingcopenclave,	
		/datum/outfit/loadout/stolencopraider,	
		)

/datum/outfit/loadout/survivingcopenclave
	name = "Surviving Enclave Gear"
	suit = /obj/item/clothing/suit/armor/medium/vest/enclave
	uniform = /obj/item/clothing/under/f13/police/swat
	head = /obj/item/clothing/head/beret/enclave
	suit_store = /obj/item/gun/energy/laser/aer9/focused
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc = 4,
		/obj/item/gun/energy/laser/complianceregulator = 2,
		/obj/item/stock_parts/cell/ammo/ec = 4,
		/obj/item/clothing/shoes/f13/enclave/serviceboots = 1,
		/obj/item/clothing/under/f13/exile/enclave =1,
		/obj/item/storage/box/handcuffs =1,
		)

/datum/outfit/loadout/stolencopraider
	name = "Stolen Raider gear"
	suit = /obj/item/clothing/suit/armor/medium/raider/combatduster
	head = /obj/item/clothing/head/helmet/riot/vaultsec
	suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat/auto5
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/ammo_box/shotgun/improvised =4,
		/obj/item/storage/box/handcuffs =1
		)

/datum/outfit/loadout/ncrgardfunded
	name = "Embassy Funded Gear"
	suit = /obj/item/clothing/suit/armor/medium/vest/ncr/mant
	head = /obj/item/clothing/head/f13/ncr/steelpot_mp
	suit_store = /obj/item/melee/baton/cattleprod
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		/obj/item/clothing/under/f13/ncr/torn =1,
		/obj/item/storage/box/handcuffs =1
		)

/datum/outfit/job/rebels/medic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)

//Rebel Citizen  
/datum/job/rebels/citizen
	title = "Roguewave Den Citizen"
	flag = F13REBELCITIZEN
	total_positions = -1
	spawn_positions = -1
	display_order = JOB_DISPLAY_ORDER_F13REBELCITIZEN
	description = "When the legion arrived, you fled, and started living in the only place safe enough arround, the Roguewave rebel carrier. You are not a fighter, but can defend this Den."
	supervisors = "The captain, the armed forced."
	outfit = /datum/outfit/job/rebels/citizen

	loadout_options = list(
		/datum/outfit/loadout/denshopkeep,
		/datum/outfit/loadout/denforgekeep,
		/datum/outfit/loadout/denbartender,
		/datum/outfit/loadout/dencivilian,
		/datum/outfit/loadout/dencasnio,
		/datum/outfit/loadout/denfarmer,
		/datum/outfit/loadout/denprospector,
		/datum/outfit/loadout/denremnant,
	)
/datum/outfit/job/rebels/citizen
	name = "Roguewave Civilian"
	id = /obj/item/card/id/dogtag/town
	jobtype = /datum/job/rebels/citizen
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	r_pocket = /obj/item/flashlight/seclite
	suit_store = /obj/item/gun/ballistic/automatic/pistol/ninemil
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/survivalkit = 1,
		/obj/item/storage/survivalkit/medical = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/pda = 1,
		/obj/item/ammo_box/magazine/m9mm/doublestack = 3,
		/obj/item/melee/onehanded/knife/survival = 1
		)

/datum/outfit/loadout/denshopkeep
	name = "Den Roguewave shopkeep"
	neck = /obj/item/clothing/neck/mantle/treasurer
	shoes = /obj/item/clothing/shoes/f13/explorer
	suit = /obj/item/clothing/suit/bomber
	gloves = /obj/item/clothing/gloves/f13/leather
	shoes = /obj/item/clothing/shoes/f13/explorer
	backpack_contents = list(
	/obj/item/reagent_containers/food/drinks/flask = 1,
	/obj/item/storage/medical/ancientfirstaid = 1,
	/obj/item/reagent_containers/food/drinks/flask/survival = 1,
	/obj/item/book/granter/crafting_recipe/blueprint/combatrifle = 1,
	/obj/item/book/granter/crafting_recipe/blueprint/commando = 1,
	/obj/item/book/granter/crafting_recipe/blueprint/rangerrepeater = 1,
	/obj/item/book/granter/crafting_recipe/blueprint/smg10mm = 1,
	/obj/item/book/granter/crafting_recipe/blueprint/aer9/focused =1,
	/obj/item/book/granter/crafting_recipe/blueprint/greasegun =1,
	/obj/item/book/granter/crafting_recipe/blueprint/m1carbine =1,
	/obj/item/book/granter/crafting_recipe/blueprint/greasegun =1,
	)

/datum/outfit/loadout/denforgekeep
	name = "Den Roguewave forgemaster"
	glasses = /obj/item/clothing/glasses/welding
	belt = /obj/item/storage/belt/utility/waster/forgemaster
	neck = /obj/item/clothing/neck/apron/labor/forge
	shoes = /obj/item/clothing/shoes/workboots/mining
	r_pocket = /obj/item/flashlight/lantern
	backpack_contents = list(
		/obj/item/stack/sheet/metal/twenty = 2,
		/obj/item/stack/sheet/mineral/wood/twenty = 1,
		/obj/item/stack/sheet/leather/twenty = 1,
		/obj/item/stack/sheet/cloth/thirty = 1,
		/obj/item/stack/sheet/prewar/twenty = 1,
		/obj/item/weldingtool = 1,
		/obj/item/book/granter/trait/explosives = 1,
		/obj/item/book/granter/trait/explosives_advanced = 1
		)

/datum/outfit/loadout/denbartender
	name = "Den Roguewave bartender"
	uniform = /obj/item/clothing/under/f13/cowboyg
	belt = /obj/item/storage/belt/utility/mining/alt
	gloves = /obj/item/clothing/gloves/f13/blacksmith
	shoes = /obj/item/clothing/shoes/f13/military/leather
	neck = /obj/item/storage/belt/shoulderholster
	backpack_contents = list(
		/obj/item/clothing/shoes/roman = 1,
		/obj/item/flashlight/lantern = 1,
		/obj/item/reagent_containers/food/condiment/flour = 2,
		/obj/item/storage/box/bowls = 4,
		/obj/item/book/manual/nuka_recipes = 1,
		/obj/item/storage/box/drinkingglasses = 1,
		/obj/item/book/manual/wiki/barman_recipes = 1,
		/obj/item/book/manual/chef_recipes = 1,
		/obj/item/melee/onehanded/knife/cosmicdirty = 1,
		/obj/item/soap/homemade = 1,
		/obj/item/lighter = 1,
		)


/datum/outfit/loadout/dencasnio
	name = "Roguewave Casino Worker"
	head = /obj/item/clothing/head/helmet/f13/marlowhat
	belt = /obj/item/melee/onehanded/knife/bowie
	uniform = /obj/item/clothing/under/f13/densuit
	shoes = /obj/item/clothing/shoes/f13/peltboots
	backpack_contents = list(
	/obj/item/stack/f13Cash/caps/threezerozero = 1,
	/obj/item/binoculars = 1,
	/obj/item/storage/box/drinkingglasses = 1,
	/obj/item/storage/box/dice = 1,
	/obj/item/toy/cards/deck = 1,
	)

/datum/outfit/loadout/dencivilian
	name = "Roguewave Civilian"
	suit = /obj/item/clothing/suit/armor/medium/vest/breastplate
	gloves = /obj/item/clothing/gloves/f13/leather
	shoes = /obj/item/clothing/shoes/f13/military
	belt = /obj/item/storage/belt/bandolier
	backpack_contents = list(
	/obj/item/stack/f13Cash/caps/onefivezero =1,
	/obj/item/shovel/trench =1,
	/obj/item/binoculars = 1,
	)

/datum/outfit/loadout/densinger
	name = "Roguewave Den singer"
	shoes = /obj/item/clothing/shoes/laceup
	backpack_contents = list(/obj/item/clothing/under/f13/classdress = 1,
	/obj/item/clothing/under/suit/black_really = 1,
	/obj/item/clothing/gloves/evening = 1,
	/obj/item/clothing/gloves/color/white = 1,
	/obj/item/instrument/guitar = 1,
	/obj/item/grenade/smokebomb = 2,
	/obj/item/clothing/accessory/pocketprotector/full = 1,
	/obj/item/choice_beacon/music = 1,
	)

/datum/outfit/loadout/denfarmer
	name = "Roguewave Botanist"
	backpack_contents = list(/obj/item/clothing/head/helmet/f13/brahmincowboyhat = 1,
	/obj/item/clothing/under/f13/rustic = 1,
	/obj/item/clothing/suit/toggle/labcoat/followers = 1,
	/obj/item/clothing/gloves/botanic_leather = 1,
	/obj/item/twohanded/fireaxe= 1,
	/obj/item/storage/belt/utility/gardener = 1,
	/obj/item/shovel/spade = 1,
	/obj/item/cultivator = 1,
	/obj/item/reagent_containers/glass/bucket/plastic = 1,
	/obj/item/storage/bag/plants/portaseeder= 1,
	/obj/item/seeds/bamboo = 1,
	/obj/item/seeds/apple/gold = 1,
	/obj/item/seeds/cannabis = 1
	)

/datum/outfit/loadout/denprospector
	name = "Roguewave Repairman and Prospector"
	backpack_contents = list(/obj/item/clothing/head/hardhat = 1,
	/obj/item/clothing/under/overalls = 1,
	/obj/item/clothing/suit/armor/light/leather/rig = 1,
	/obj/item/clothing/gloves/patrol = 1,
	/obj/item/clothing/shoes/workboots = 1,
	/obj/item/storage/belt/utility/waster = 1,
	/obj/item/shovel/spade = 1,
	/obj/item/pickaxe/silver = 1,
	/obj/item/clothing/glasses/welding = 1,
	/obj/item/t_scanner/adv_mining_scanner = 1,
	/obj/item/storage/belt/utility/full = 1
	)

/datum/outfit/loadout/denremnant
	name = "Crewmember"
	backpack_contents = list(
	/obj/item/clothing/head/f13/enclave/peacekeeper = 1,
	/obj/item/card/id/dogtag/enclave/trooper = 1,
	/obj/item/stock_parts/cell/ammo/ec = 3,
	/obj/item/gun/energy/laser/pistol = 1,
	)

/datum/outfit/job/rebels/citizen/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)

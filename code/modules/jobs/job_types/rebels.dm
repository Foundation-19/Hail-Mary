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
		/obj/item/clothing/under/f13/densuit)

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
	title = "Captured Outlaw"
	flag = F13REBELSOLDIER
	total_positions = 5
	spawn_positions = 5
	display_order = JOB_DISPLAY_ORDER_F13REBELSOLDIER
	description = "Well damn it. You go caught by the legion forces. Now you are at their mercy. Before ? You were a warrior. Rebel, NCR, Legion renegade... Now, you must survive."
	supervisors = "No one, but you may try to flee toward the rebels or the vault."
	outfit = /datum/outfit/job/CaesarsLegion/slave

	loadout_options = list(
		/datum/outfit/loadout/capturedncr,	
		/datum/outfit/loadout/capturedranger,
		/datum/outfit/loadout/capturedraider,
		/datum/outfit/loadout/capturedvaulty,
		/datum/outfit/loadout/capturedlegion
		)

/datum/outfit/loadout/capturedncr
	name = "Captured NCR"
	head = /obj/item/clothing/head/f13/ncr/standard
	r_pocket = /obj/item/storage/box/ration/menu_ten
	uniform = /obj/item/clothing/under/f13/ncr


/datum/outfit/loadout/capturedranger
	name = "Captured ranger"
	head = /obj/item/clothing/head/helmet/f13/ncr/rangercombat

/datum/outfit/loadout/capturedraider
	name = "Captured ranger"
	head = /obj/item/clothing/head/helmet/f13/raidercombathelmet

/datum/outfit/loadout/capturedvaulty
	name = "Captured vault dweller"
	suit = /obj/item/clothing/suit/armor/light/kit
	uniform = /obj/item/clothing/under/f13/vault

/datum/outfit/loadout/capturedlegion
	name = "Captured legion renegade"
	suit = /obj/item/clothing/suit/armor/light/kit
	uniform = /obj/item/clothing/under/f13/exile/legion


// REBEL MEDIC


/datum/job/rebels/medic
	title = "Ironwave Den Doctor"
	flag = F13REBELMEDIC
	total_positions = 1
	spawn_positions = 1
	access = list(ACCESS_ENCLAVE)
	display_order = JOB_DISPLAY_ORDER_F13REBELMEDIC
	description = "Your diploma isn't reconized anywhere else. Good thing the Den doesn't care. Your job is to heal people of the carrier."
	supervisors = "The captain."
	outfit = /datum/outfit/job/rebels/medic

	loadout_options = list(
		/datum/outfit/loadout/ncrmedicfunded,	
		/datum/outfit/loadout/stolenmedicraider,	
		)

/datum/outfit/job/rebels/medic
	name = "Ironwave Rebel medic"
	id = /obj/item/card/id/dogtag/town
	jobtype = /datum/job/rebels/medic
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	suit = /obj/item/clothing/suit/toggle/labcoat/followers
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

/datum/outfit/loadout/stolenmedicraider
	name = "Quack Medic"
	head = /obj/item/clothing/head/helmet/f13/raidercombathelmet
	suit_store = /obj/item/gun/energy/laser/badlands
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/ec = 3,
		/obj/item/melee/powered/ripper =1,
		)

/datum/outfit/loadout/ncrmedicfunded
	name = "NCR CM Gear"
	head = /obj/item/clothing/head/f13/ncr/steelpot_med
	suit_store = /obj/item/gun/ballistic/automatic/service/carbine
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m556/rifle/assault = 3
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
	title = "Ironwave Den Captain"
	flag = F13REBELCAPTAIN
	total_positions = 1
	spawn_positions = 1
	access = list(ACCESS_ENCLAVE, ACCESS_CHANGE_IDS)
	display_order = JOB_DISPLAY_ORDER_F13REBELCAPTAIN
	description = "You lead this team of soldiers of fortune. Your gear is from old supplies, and gifts from the NCR... And a few stolen goods."
	outfit = /datum/outfit/job/rebels/captain

	loadout_options = list(
		/datum/outfit/loadout/capncrfunded,	
		/datum/outfit/loadout/capstolenraider,	
		)

/datum/outfit/job/rebels/captain
	name = "Ironwave Den Captain"
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

/datum/outfit/loadout/capstolenraider
	name = "Raider boss gear"
	suit = /obj/item/clothing/suit/armor/power_armor/t45b/raider
	head = /obj/item/clothing/head/helmet/f13/power_armor/t45b/raider
	suit_store = /obj/item/gun/ballistic/automatic/smg/tommygun
	backpack_contents = list(
		/obj/item/ammo_box/magazine/tommygunm45 = 2,
		)

/datum/outfit/loadout/capncrfunded
	name = "Desert Ranger Stash"
	suit = /obj/item/clothing/suit/armor/rangercombat/foxcustom
	head = /obj/item/clothing/head/helmet/f13/ncr/rangercombat/desert
	suit_store = /obj/item/gun/ballistic/rifle/repeater/brush
	backpack_contents = list(
		/obj/item/ammo_box/c4570box = 2,
		)

//Rebel Guard
/datum/job/rebels/guard
	title = "Ironwave Raider"
	flag = F13REBELGUARD
	total_positions = 2
	spawn_positions = 2
	access = list(ACCESS_ENCLAVE)
	display_order = JOB_DISPLAY_ORDER_F13REBELGUARD
	description = "You are part of the dedicated warriors and that works on the USS Emminant domain. You defend the den, follow the orders of you captain, and kick some ass."
	supervisors = "The captain."
	outfit = /datum/outfit/job/rebels

	loadout_options = list(
		/datum/outfit/loadout/ncrgardfunded,	
		/datum/outfit/loadout/stolencopraider,
		/datum/outfit/loadout/stolenraider,
		/datum/outfit/loadout/ncrfunded,
		/datum/outfit/loadout/raider_sadist,
		/datum/outfit/loadout/raider_tribal,
		/datum/outfit/loadout/raider_supafly,
		/datum/outfit/loadout/raider_yankee,
		/datum/outfit/loadout/raider_blast,
		/datum/outfit/loadout/raider_painspike,
		/datum/outfit/loadout/raider_badlands,
		/datum/outfit/loadout/raider_vault,
		/datum/outfit/loadout/raider_ncr,
		/datum/outfit/loadout/raider_legion,
		/datum/outfit/loadout/raider_bos,
		/datum/outfit/loadout/quack_doctor
		)

/datum/outfit/job/rebels/guard
	name = "Ironwave Soldier"
	jobtype = /datum/job/rebels/soldier
	suit = /obj/item/clothing/suit/armor/exile/ncrexile/ironwave
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
		/obj/item/grenade/flashbang = 1,
		)

/datum/outfit/loadout/stolencopraider
	name = "Stolen Raider gear"
	head = /obj/item/clothing/head/helmet/riot/vaultsec
	suit_store = /obj/item/gun/energy/laser/wattz2k/extended
	backpack_contents = list(
		/obj/item/ammo_box/shotgun/improvised =4,
		/obj/item/storage/box/handcuffs =1
		)

/datum/outfit/loadout/ncrgardfunded
	name = "Embassy Funded Gear"
	head = /obj/item/clothing/head/f13/ncr/steelpot_mp
	suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat/auto5
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc =3,
		/obj/item/storage/box/handcuffs =1,
		/obj/item/ammo_box/shotgun/bean =2
		)

/datum/outfit/loadout/stolenraider
	name = "Ripper gear"
	head = /obj/item/clothing/head/helmet/f13/raidercombathelmet
	suit_store = /obj/item/shield/riot/tower/scrap
	backpack_contents = list(
		/obj/item/clothing/shoes/f13/military/ncr = 1,
		)

/datum/outfit/loadout/ncrfunded
	name = "NCR Funded Gear"
	head = /obj/item/clothing/head/f13/ncr/goggles
	suit_store = /obj/item/gun/ballistic/automatic/service/carbine
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m556/rifle/assault = 3,
		)

/datum/outfit/loadout/raider_sadist
	name = "Sadist"
	suit = /obj/item/clothing/suit/armor/light/raider/sadist
	head = /obj/item/clothing/head/helmet/f13/raider/arclight
	backpack_contents = list(
		/obj/item/restraints/legcuffs/bola=5,
		/obj/item/clothing/mask/gas/explorer/folded=1,
		/obj/item/storage/belt = 1,
		/obj/item/restraints/legcuffs/beartrap = 2,
		/obj/item/reverse_bear_trap = 1,
		/obj/item/melee/unarmed/lacerator = 1,
		)

/datum/outfit/loadout/raider_supafly
	name = "Supa-fly"
	suit = /obj/item/clothing/suit/armor/light/raider/supafly
	head = /obj/item/clothing/head/helmet/f13/raider/supafly
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/varmint = 1,
		/obj/item/ammo_box/magazine/m556/rifle/assault = 1,
		/obj/item/gun/ballistic/revolver/hobo/knucklegun = 1,
		/obj/item/ammo_box/c45rev = 2,
		/obj/item/gun_upgrade/scope/watchman = 1,
		/obj/item/reagent_containers/food/drinks/bottle/f13nukacola/radioactive = 1,
		/obj/item/grenade/smokebomb = 2,
		)

/datum/outfit/loadout/raider_yankee
	name = "Yankee"
	suit = /obj/item/clothing/suit/armor/medium/raider/yankee
	head = /obj/item/clothing/head/helmet/f13/raider/yankee
	backpack_contents = list(
		/obj/item/shishkebabpack = 1,
		/obj/item/storage/fancy/cigarettes/cigpack_cannabis=1,
		/obj/item/megaphone=1,
		/obj/item/storage/pill_bottle/chem_tin/buffout = 1)

/datum/outfit/loadout/raider_blast
	name = "Blastmaster"
	suit = /obj/item/clothing/suit/armor/medium/raider/blastmaster
	head = /obj/item/clothing/head/helmet/f13/raider/blastmaster
	backpack_contents = list(
		/obj/item/kitchen/knife/butcher = 1,
		/obj/item/grenade/homemade/firebomb = 4,
		/obj/item/bottlecap_mine = 1,
		/obj/item/grenade/homemade/coffeepotbomb = 4,
		/obj/item/book/granter/crafting_recipe/blueprint/trapper = 1,
		/obj/item/book/granter/trait/explosives = 1
		)

/datum/outfit/loadout/raider_badlands
	name = "Fiend"
	suit = /obj/item/clothing/suit/armor/medium/raider/badlands
	head = /obj/item/clothing/head/helmet/f13/fiend
	backpack_contents = list(
		///obj/item/gun/energy/laser/wattzs = 1,
		/obj/item/gun/energy/laser/wattz = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2,
		/obj/item/reagent_containers/hypospray/medipen/psycho = 3,
		/obj/item/reagent_containers/pill/patch/turbo = 2,
		/obj/item/reagent_containers/hypospray/medipen/medx = 1,
		)

/datum/outfit/loadout/raider_painspike
	name = "Painspike"
	suit = /obj/item/clothing/suit/armor/light/raider/painspike
	head = /obj/item/clothing/head/helmet/f13/raider/psychotic
	backpack_contents = list(
		/obj/item/gun/ballistic/shotgun/automatic/combat/shotgunlever = 1,
		/obj/item/ammo_box/shotgun/buck = 1,
		/obj/item/ammo_box/shotgun/bean = 1,
		/obj/item/melee/onehanded/club/fryingpan = 1,
		/obj/item/grenade/chem_grenade/cleaner = 1,
		)

/datum/outfit/loadout/quack_doctor
	name = "Quack Doctor"
	suit = /obj/item/clothing/suit/toggle/labcoat
	l_hand = /obj/item/storage/backpack/duffelbag/med/surgery
	r_hand = /obj/item/book/granter/trait/midsurgery
	//suit_store = /obj/item/gun/energy/laser/wattzs
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/ec = 1,
		/obj/item/reagent_containers/pill/patch/jet = 3,
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/storage/pill_bottle/aranesp = 1,
		/obj/item/storage/pill_bottle/happy = 1,
		/obj/item/book/granter/trait/chemistry = 1,
		/obj/item/stack/sheet/mineral/silver=2,
		/obj/item/clothing/accessory/pocketprotector/full = 1,
		)

/datum/outfit/loadout/raider_ncr
	name = "Outlaw Ranger"
	suit = /obj/item/clothing/suit/armor/medium/raider/combatduster
	uniform = /obj/item/clothing/under/f13/raider_leather
	id = /obj/item/card/id/rusted
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/m1carbine = 1,
		/obj/item/ammo_box/magazine/m10mm/adv/simple=2,
		/obj/item/melee/onehanded/knife/bayonet = 1,
		/obj/item/storage/box/ration/ranger_breakfast = 1,
		/obj/item/book/granter/crafting_recipe/blueprint/service = 1)


/datum/outfit/loadout/raider_legion
	name = "Disgraced Legionnaire"
	suit = /obj/item/clothing/suit/armor/exile/legexile
	uniform = /obj/item/clothing/under/f13/exile/legion
	id = /obj/item/card/id/rusted/rustedmedallion
	backpack_contents = list(
		/obj/item/melee/onehanded/machete/gladius = 1,
		/obj/item/storage/backpack/spearquiver = 1,
		/obj/item/gun/ballistic/automatic/smg/greasegun = 1,
		/obj/item/ammo_box/magazine/greasegun = 1,
		/obj/item/book/granter/trait/trekking = 1
		)

/datum/outfit/loadout/raider_bos
	name = "Brotherhood Exile"
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood/exile
	id = /obj/item/card/id/rusted/brokenholodog
	backpack_contents = list(
		/obj/item/gun/energy/laser/wattzs = 1,
		/obj/item/stock_parts/cell/ammo/ec = 1,
		/obj/item/book/granter/crafting_recipe/blueprint/aep7 = 1,
		/obj/item/grenade/f13/frag = 2,
		)


/datum/outfit/loadout/raider_vault
	name = "Vault Renegade"
	suit = /obj/item/clothing/suit/armor/medium/vest/bulletproof/big
	uniform = /obj/item/clothing/under/f13/exile/vault
	id = /obj/item/card/id/selfassign
	gloves = /obj/item/pda
	backpack_contents = list(
		/obj/item/gun/ballistic/revolver/thatgun = 1,
		/obj/item/pda=1,
		)

/datum/outfit/loadout/raider_tribal
	name = "Tribal Outcast"
	uniform = /obj/item/clothing/under/f13/exile/tribal
	suit = /obj/item/clothing/suit/hooded/outcast/tribal
	suit_store = /obj/item/twohanded/spear/bonespear
	shoes = /obj/item/clothing/shoes/sandal
	belt = /obj/item/storage/backpack/spearquiver
	back = /obj/item/storage/backpack/satchel/explorer
	box = /obj/item/storage/survivalkit/tribal
	box_two = /obj/item/storage/survivalkit/medical/tribal
	backpack_contents = list(
		/obj/item/book/granter/trait/tribaltraditions =1,
		/obj/item/clothing/mask/cigarette/pipe = 1,
		/obj/item/melee/onehanded/knife/bone = 1,
		)

/datum/outfit/job/rebels/medic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)


//Rebel Citizen  
/datum/job/rebels/citizen
	title = "Ironwave Den Settlers"
	flag = F13REBELCITIZEN
	total_positions = 5
	spawn_positions = 5
	display_order = JOB_DISPLAY_ORDER_F13REBELCITIZEN
	description = "When the legion arrived, you fled, and started living in the only place safe enough arround, the Ironwave carrier. You are not a fighter, but can defend this Den."
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
	name = "Ironwave Civilian"
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
	name = "Den Ironwave shopkeep"
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
	name = "Den Ironwave forgemaster"
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
	name = "Den Ironwave bartender"
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
	name = "Ironwave Casino Worker"
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
	name = "Ironwave Civilian"
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
	name = "Ironwave Den singer"
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
	name = "Ironwave Botanist"
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
	name = "Ironwave Repairman and Prospector"
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


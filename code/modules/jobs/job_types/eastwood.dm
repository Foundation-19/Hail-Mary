/*
Town access doors
Sheriff/Deputy, Gatehouse etc: 62 ACCESS_GATEWAY
General access: 25 ACCESS_BAR
Clinic surgery/storage: 68 ACCESS_CLONING
Shopkeeper: 34 ACCESS_CARGO_BOT
Barkeep : 28 ACCESS_KITCHEN - you jebronis made default bar for no reason bruh
Prospector : 48 ACCESS_MINING
Detective : 4 ACCESS_FORENSICS_LOCKERS
here's a tip, go search DEFINES/access.dm
*/

// Headsets for everyone!!
/datum/outfit/job/den
	name = "Eastwood Default Template"
	ears = /obj/item/radio/headset/headset_town
	id = /obj/item/card/id/dogtag/town
	uniform = /obj/item/clothing/under/f13/settler
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/wallet/stash/low = 1,
		/obj/item/melee/onehanded/knife/hunting = 1
		)

/datum/outfit/job/den/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)
	
/*
Mayor
*/

/datum/job/eastwood
	exp_type = EXP_TYPE_EASTWOOD
	faction = FACTION_EASTWOOD

/datum/job/eastwood/f13mayor// /obj/item/card/id/captains_spare for any elected mayors. - Blue
	/*
	objectivesList = list(
		"Maintain a safe and prosperous town that allows for your citizens to thrive",
		"Secure safety from the wastes through arming the people, forging treaties or reinforcing the town.",
		"Make a treaty with one major faction, whether this be for protection, trade or more",
		"Maintain order within the walls."
		)
		*/

	title = "Warden"
	flag = F13MAYOR
	department_flag = DEP_EASTWOOD
	total_positions = 1
	spawn_positions = 1
	supervisors = "Eastwood"
	description = "You are the Warden appointed to guide the people, chosen by the people through elections. You guide the people to a better tomorrow as you manage and maintain the town. Some say you are a greed filled man, some say you are a merciful leader. But only you will write your story."
	enforces = "The Head of the Watch is your replacement, may you fall he shall step in to maintain order."
	selection_color = "#d7b088"

	exp_requirements = 600

	outfit = /datum/outfit/job/den/f13mayor
	access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_CLINIC, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	minimal_access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_KITCHEN, ACCESS_CLINIC, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

	loadout_options = list(
		/datum/outfit/loadout/mayoral, //revolver cowboy
		/datum/outfit/loadout/dictator, //1911 unique general uniform
		/datum/outfit/loadout/firstcitizen, //baretta vaultie
		/datum/outfit/loadout/highroller, //mk23 suit (gambler)
		/datum/outfit/loadout/clinicdirector, //wattz magneto followers attire
		/datum/outfit/loadout/richman, //1911 unique + grease gun and lever action blueprint 
		/datum/outfit/loadout/eastchief, //tribal warmace
		/datum/outfit/loadout/lord //medieval prep, bola + sword
		)


/datum/outfit/job/den/f13mayor/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/datum/outfit/job/den/f13mayor
	name = "Mayor"
	jobtype = /datum/job/eastwood/f13mayor
	id = /obj/item/card/id/silver/mayor
	ears = /obj/item/radio/headset/headset_town/mayor
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	l_pocket = /obj/item/storage/wallet/stash/high
	r_pocket = /obj/item/flashlight/seclite
	shoes = /obj/item/clothing/shoes/f13/tan
	uniform = /obj/item/clothing/under/f13/gentlesuit
	head = /obj/item/clothing/head/f13/town/big
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/box/citizenship_permits = 1,
		/obj/item/pen/fountain/captain = 1
		)



/datum/outfit/loadout/dictator
	name = "Mayor for Life"
	backpack_contents = list(
	/obj/item/clothing/under/f13/general/eastwood = 1,
	/obj/item/clothing/head/f13/army/general = 1,
	/obj/item/gun/ballistic/automatic/pistol/m1911/custom/jackal = 1,
	/obj/item/ammo_box/magazine/m45 = 2,
	/obj/item/clothing/shoes/jackboots = 1,
	/obj/item/clothing/mask/cigarette/pipe/cobpipe = 1
	)

/datum/outfit/loadout/mayoral
	name = "Frontier Leader"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/duster/town/mayor = 1,
		/obj/item/clothing/head/f13/town/mayor = 1,
		/obj/item/gun/ballistic/revolver/m29/peacekeeper = 1,
		/obj/item/ammo_box/m44 = 2,
		/obj/item/clothing/shoes/f13/cowboy = 1,
		/obj/item/clothing/mask/cigarette/cigar = 1
		)

/datum/outfit/loadout/firstcitizen
	name = "First Citizen"
	backpack_contents = list(
		/obj/item/clothing/under/f13/vault = 1,
		/obj/item/clothing/shoes/jackboots = 1,
		/obj/item/clothing/suit/armor/light/duster/battlecoat/vault/overseer = 1,
		/obj/item/reagent_containers/food/drinks/flask/vault113 = 1,
		/obj/item/gun/ballistic/automatic/pistol/beretta/automatic = 1,
		/obj/item/ammo_box/magazine/m9mm/doublestack = 1
		)

/datum/outfit/loadout/highroller
	name = "High Roller"
	backpack_contents = list(
		/obj/item/clothing/glasses/orange = 1,
		/obj/item/clothing/suit/armor/outfit/vest = 1,
		/obj/item/clothing/under/f13/sleazeball = 1,
		/obj/item/clothing/shoes/laceup = 1,
		/obj/item/toy/cards/deck/unum = 1,
		/obj/item/gun/ballistic/automatic/pistol/mk23 = 1,
		/obj/item/ammo_box/magazine/m45/socom = 2
	)

/datum/outfit/loadout/clinicdirector
	name = "Doctor In Chief"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/duster/follower = 1,
		/obj/item/book/granter/trait/midsurgery = 1,
		/obj/item/storage/belt/medical/surgery_belt_adv = 1,
		/obj/item/storage/box/medicine/stimpaks/stimpaks5 = 1,
		/obj/item/clipboard = 1,
		/obj/item/pen = 1,
		/obj/item/gun/energy/laser/wattz/magneto = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2
	)

/datum/outfit/loadout/richman
	name = "Nightstalker Of Eastwood"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/duster/armoredcoat = 1,
		/obj/item/stack/f13Cash/caps/twozerozero = 1,
		/obj/item/gun/ballistic/automatic/pistol/m1911/custom/jackal = 1,
		/obj/item/ammo_box/magazine/m45 = 2,
		/obj/item/pda = 1,
		/obj/item/book/granter/crafting_recipe/blueprint/greasegun = 1,
		/obj/item/book/granter/crafting_recipe/blueprint/leveraction  = 1
	)

/datum/outfit/loadout/eastchief
	name = "Cheif of the East"
	backpack_contents = list(
		/obj/item/clothing/suit/hooded/cloak/hhunter = 1,
		/obj/item/clothing/under/f13/exile/tribal = 1,
		/obj/item/twohanded/sledgehammer/warmace = 1,
		/obj/item/storage/box/medicine/poultice5 = 1
	)
	
/datum/outfit/loadout/lord
	name = "Lord of the Land"
	backpack_contents = list(
		/obj/item/restraints/legcuffs/bola/tactical = 2,
		/obj/item/melee/coyote/oldlongsword/broadsword = 1,
		/obj/item/storage/belt/sword = 1,
		/obj/item/storage/box/medicine/poultice5 = 1
	)
/*--------------------------------------------------------------*/

/datum/job/eastwood/f13secretary
	title = "Secretary"
	flag = F13SECRETARY
	department_flag = DEP_EASTWOOD
	total_positions = 1
	spawn_positions = 1
	supervisors = "The Mayor"
	description = "The settlement of Eastwood is a busy place, and the Mayor often can't handle everything by themselves. You are here to help them with anything and everything they require, and make sure the more trivial problems do not concern them. You handle clerical work, hear complaints, and set meetings within the manor. An efficient and smooth running town means a happy Mayor - just remember that if things go wrong, you're a convenient scapegoat."
	enforces = "You are the stand-in leader of Eastwood if a Mayor does not exist."
	selection_color = "#d7b088"
	exp_requirements = 0

	outfit = /datum/outfit/job/den/f13secretary

	loadout_options = list(
	/datum/outfit/loadout/pr,
	/datum/outfit/loadout/pw
	)

	access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_CLINIC, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	minimal_access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_KITCHEN, ACCESS_CLINIC, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

/datum/outfit/job/den/f13secretary
	name = "Secretary"
	jobtype = /datum/job/eastwood/f13secretary
	id = /obj/item/card/id/silver
	belt = /obj/item/kit_spawner/townie/mayor
	ears = /obj/item/radio/headset/headset_town/mayor
	glasses = /obj/item/clothing/glasses/regular/hipster
	gloves = /obj/item/clothing/gloves/color/white
	backpack = /obj/item/storage/backpack/satchel/leather
	satchel = /obj/item/storage/backpack/satchel/leather
	r_hand = /obj/item/storage/briefcase/secretary
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/seclite
	shoes = /obj/item/clothing/shoes/f13/fancy
	uniform = /obj/item/clothing/under/suit/black
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/ammo_box/magazine/m9mm = 1,
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/pda = 1
		)

/datum/outfit/loadout/pr
	name = "Public Relations"
	backpack_contents = list(
		/obj/item/megaphone = 1,
		/obj/item/reagent_containers/food/snacks/store/cake/birthday = 1,
		/obj/item/clothing/accessory/medal/ribbon = 1,
		/obj/item/clothing/gloves/color/latex/nitrile = 1,
		/obj/item/camera = 1,
		/obj/item/storage/crayons = 1,
		/obj/item/choice_beacon/box/carpet = 1
		)

/datum/outfit/loadout/pw
	name = "Public Works"
	backpack_contents = list(
		/obj/item/clothing/head/hardhat = 1,
		/obj/item/clothing/suit/hazardvest = 1,
		/obj/item/stack/sheet/metal/twenty = 2,
		/obj/item/stack/sheet/glass/ten = 2,
		/obj/item/stack/sheet/mineral/concrete/ten = 2
		)

/datum/outfit/job/den/f13secretary/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policepistol)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policerifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steelbib/heavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/armyhelmetheavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_SELF_AWARE, src)

/*--------------------------------------------------------------*/

/datum/job/eastwood/f13sheriff
	title = "Head of the Watch"
	flag = F13SHERIFF
	department_flag = DEP_EASTWOOD
	head_announce = list("Security")
	total_positions = 1
	spawn_positions = 1
	supervisors = "The Warden"
	description = "You are the head of the Watch, appointed by the warden and entrusted with protecting the town. You are second to the Warden, should he fall you will take his place."
	enforces = "You are the stand-in leader of Eastwood if a warden should fall."
	selection_color = "#d7b088"
	exp_requirements = 400

	outfit = /datum/outfit/job/den/f13sheriff

	loadout_options = list(
	/datum/outfit/loadout/thelaw, //brush gun + scope
	/datum/outfit/loadout/thechief, //citykiller + ranger45
	/datum/outfit/loadout/medieval //Mauler melee + bolas + poultice
	)

	access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_CLINIC, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	minimal_access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_CLINIC, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_CLINIC, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

/datum/outfit/job/den/f13sheriff
	name = "Sheriff"
	jobtype = /datum/job/eastwood/f13sheriff
	id = /obj/item/card/id/dogtag/sheriff
	ears = /obj/item/radio/headset/headset_town/lawman
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	uniform = /obj/item/clothing/under/f13/sheriff
	shoes = /obj/item/clothing/shoes/f13/cowboy
	glasses = /obj/item/clothing/glasses/sunglasses
	l_pocket = /obj/item/storage/wallet/stash/high
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/box/deputy_badges = 1,
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/classic_baton = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
		/obj/item/grenade/flashbang = 1,
		/obj/item/storage/belt/army = 1
		)

/datum/outfit/loadout/thelaw
	name = "The Law Man"
	suit = /obj/item/clothing/suit/armor/medium/duster/town/sheriff
	head = /obj/item/clothing/head/f13/town/sheriff
	uniform = /obj/item/clothing/under/f13/police/formal
	neck = /obj/item/storage/belt/shoulderholster
	r_hand = /obj/item/gun/ballistic/rifle/repeater/brush
	shoes = /obj/item/clothing/shoes/f13/military/plated
	backpack_contents = list(
		/obj/item/ammo_box/tube/c4570 = 3,
		/obj/item/gun_upgrade/scope/watchman = 1
		)

/datum/outfit/loadout/thechief
	name = "The Chief"
	uniform = /obj/item/clothing/under/f13/police/chief
	suit = /obj/item/clothing/suit/armor/medium/duster/town/chief
	head = /obj/item/clothing/head/f13/town/chief
	neck = /obj/item/storage/belt/shoulderholster/ranger45
	shoes = /obj/item/clothing/shoes/combat
	r_hand = /obj/item/gun/ballistic/shotgun/automatic/combat/citykiller
	backpack_contents = list(/obj/item/ammo_box/shotgun/slug = 1,
		/obj/item/ammo_box/shotgun/buck = 2
		)

/datum/outfit/loadout/medieval
	name = "Head of the Watch"
	backpack_contents = list(
		/obj/item/melee/coyote/mauler = 1,
		/obj/item/restraints/legcuffs/bola/tactical = 2,
		/obj/item/storage/box/medicine/poultice5 = 1
		)


/datum/outfit/job/den/f13sheriff/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policepistol)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policerifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steelbib/heavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/armyhelmetheavy)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	ADD_TRAIT(H, TRAIT_SELF_AWARE, src)


/*--------------------------------------------------------------*/

/datum/job/eastwood/f13deputy
	title = "Watchmen"
	flag = F13DEPUTY
	department_flag = DEP_EASTWOOD
	total_positions = 4
	spawn_positions = 4
	supervisors = "The Head of the Watch"
	description = "You are a loyal protector of Eastwood who enforces the local laws. Working under the Head of the Watch you protect the town from threats foreign and domestic."
	enforces = "You may be elected temporary Head of the Watch should none exist."
	selection_color = "#dcba97"
	exp_type = EXP_TYPE_EASTWOOD
	exp_requirements = 0

	loadout_options = list(
	/datum/outfit/loadout/frontierjustice, //Trail Carbine + Revolver
	/datum/outfit/loadout/police, //police shotgun + bulletproof
	/datum/outfit/loadout/swat, //police rifle + swat gear
	/datum/outfit/loadout/energy, //aer9 + metal armor
	/datum/outfit/loadout/watchmen, //bola + poultice + riot shield
	)

	outfit = /datum/outfit/job/den/f13deputy
	access = list(ACCESS_BAR, ACCESS_GATEWAY, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC)
	minimal_access = list(ACCESS_BAR, ACCESS_GATEWAY, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

/datum/outfit/job/den/f13deputy
	name = "Deputy"
	jobtype = /datum/job/eastwood/f13deputy
	id = /obj/item/card/id/dogtag/deputy
	ears = /obj/item/radio/headset/headset_town/lawman
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	suit_store = /obj/item/storage/belt/legholster
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/flare
	shoes = /obj/item/clothing/shoes/f13/explorer
	uniform = /obj/item/clothing/under/f13/cowboyb
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
		/obj/item/grenade/flashbang = 1,
		/obj/item/flashlight/seclite = 1,
		/obj/item/storage/belt/army/assault = 1
		)

/datum/outfit/loadout/frontierjustice
	name = "Frontier Justice"
	suit = /obj/item/clothing/suit/armor/medium/duster/town/deputy
	head = /obj/item/clothing/head/f13/town/deputy
	neck = /obj/item/storage/belt/shoulderholster
	r_hand = /obj/item/gun/ballistic/rifle/repeater/trail
	backpack_contents = list(
		/obj/item/ammo_box/tube/m44 = 2,
		/obj/item/ammo_box/m44 = 2,
		/obj/item/gun/ballistic/revolver/m29 = 1,
		)

/datum/outfit/loadout/police
	name = "Eastwood PD"
	uniform = /obj/item/clothing/under/f13/police/officer
	suit = /obj/item/clothing/suit/armor/heavy/vest/bulletproof
	head = /obj/item/clothing/head/f13/town/officer
	belt = /obj/item/storage/belt/legholster
	r_hand = /obj/item/gun/ballistic/shotgun/police
	shoes = /obj/item/clothing/shoes/jackboots
	backpack_contents = list(
		/obj/item/ammo_box/shotgun/bean = 1,
		/obj/item/ammo_box/shotgun/buck = 1,
		/obj/item/ammo_box/a357 = 3,
		/obj/item/flashlight/seclite = 1,
		/obj/item/gun/ballistic/revolver/police = 1
	)

/datum/outfit/loadout/swat
	name = "S.W.A.T. Officer"
	uniform = /obj/item/clothing/under/f13/police/swat
	suit = /obj/item/clothing/suit/armor/heavy/vest/bulletproof
	head = /obj/item/clothing/head/helmet/alt
	mask = /obj/item/clothing/mask/balaclava
	gloves = /obj/item/clothing/gloves/f13/military
	suit_store = /obj/item/gun/ballistic/automatic/assault_carbine/policerifle
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m45/socom=2,
		/obj/item/gun/ballistic/automatic/pistol/mk23=1,
		/obj/item/ammo_box/magazine/m5mm=1,
		/obj/item/flashlight/seclite = 1
		)

/datum/outfit/loadout/energy
	name = "High Tech Officer"
	uniform = /obj/item/clothing/under/f13/police/officer
	suit = /obj/item/clothing/suit/armor/heavy/metal/polished
	gloves = /obj/item/clothing/gloves/f13/military
	suit_store = /obj/item/gun/energy/laser/aer9
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc = 1
		)

/datum/outfit/loadout/watchmen
	name = "Watchmen"
	backpack_contents = list(
		/obj/item/restraints/legcuffs/bola/tactical = 1,
		/obj/item/storage/box/medicine/poultice5 = 1,
		/obj/item/shield/riot = 1
	)

/*--------------------------------------------------------------*/

/datum/job/eastwood/f13farmer
	title = "Farmer"
	flag = F13FARMER
	department_flag = DEP_EASTWOOD
	total_positions = 4
	spawn_positions = 4
	supervisors = "Eastwood laws"
	description = "You are a farmer living in Eastwood. Treat your town with respect and make sure to follow the laws in place, as your premium status may be revoked if you are considered a danger to the populace."
	enforces = "Farming is a public service, and you are under control of local governance - and you are expected to produce food."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/den/f13farmer

	access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV)
	minimal_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood,
		),
	)

	loadout_options = list(
	/datum/outfit/loadout/abiotic,
	/datum/outfit/loadout/pomologist,
	/datum/outfit/loadout/zany,)

/datum/outfit/job/den/f13farmer
	name = "Farmer"
	jobtype = /datum/job/eastwood/f13farmer

	id = /obj/item/card/id/dogtag/town

	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	belt = /obj/item/storage/bag/plants
	backpack_contents = list(
		/obj/item/cultivator=1, \
		/obj/item/hatchet=1,
		/obj/item/shovel/spade=1, \
		/obj/item/gun/ballistic/automatic/pistol/n99, \
		/obj/item/ammo_box/magazine/m10mm/adv/simple=2)
	shoes = 		/obj/item/clothing/shoes/workboots

/datum/outfit/job/den/f13settler/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/settler, \
		/obj/item/clothing/under/f13/brahminm, \
		/obj/item/clothing/under/f13/machinist, \
		/obj/item/clothing/under/f13/lumberjack, \
		/obj/item/clothing/under/f13/roving)

/datum/outfit/loadout/abiotic
	name = "Abiotic"
	backpack_contents = list(
		/obj/item/seeds/bamboo = 1,
		/obj/item/seeds/glowshroom = 1,
		/obj/item/seeds/tower = 1,
		)

/datum/outfit/loadout/pomologist
	name = "Pomologist"
	backpack_contents = list(
		/obj/item/seeds/grape/green = 1,
		/obj/item/seeds/apple/gold = 1,
		/obj/item/seeds/cherry/blue = 1,
		)

/datum/outfit/loadout/zany
	name = "Zany"
	backpack_contents = list(
		/obj/item/clothing/mask/cigarette/pipe = 1,
		/obj/item/seeds/cannabis = 1,
		/obj/item/seeds/tea/catnip = 1,
		)

/*--------------------------------------------------------------*/

/datum/job/eastwood/f13prospector
	title = "Blacksmith"
	flag = F13PROSPECTOR
	department_flag = DEP_EASTWOOD
	total_positions = 4
	spawn_positions = 4
	supervisors = "The Warden"
	description = "You are the miner and blacksmith of the town. Forge a better tomorrow with the materials you find underground."
	enforces = "Mining and smithery is a public service, and you are under control of local governance - but by default you are expected to work with private businesses and individual clients."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/den/f13prospector

	access = list(ACCESS_BAR, ACCESS_MINING, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_PROSP, ACCESS_TOWN_MERCH)
	minimal_access = list(ACCESS_BAR, ACCESS_MINING, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_PROSP, ACCESS_TOWN_MERCH)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood,
		),
	)

	loadout_options = list(
	/datum/outfit/loadout/engineer, //mini pickaxe and full toolbelt
	/datum/outfit/loadout/miner,) //silver pickaxe + advanced mining scanner

/datum/outfit/job/den/f13prospector
	name = "Prospector"
	jobtype = /datum/job/eastwood/f13prospector

	id = /obj/item/card/id/dogtag/town
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/lantern
	belt = /obj/item/storage/bag/ore
	shoes = /obj/item/clothing/shoes/jackboots
	backpack_contents = list(
		/obj/item/mining_scanner,
		/obj/item/melee/onehanded/knife/hunting,
		/obj/item/gun/ballistic/automatic/pistol/n99,
		/obj/item/ammo_box/magazine/m10mm/adv/simple = 2
		)

/datum/outfit/job/den/f13settler/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/machinist,
		/obj/item/clothing/under/f13/roving,
		/obj/item/clothing/under/f13/cowboyt)

/datum/outfit/job/den/f13prospector/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/datum/outfit/loadout/engineer
	name = "Engineer"
	suit = /obj/item/clothing/suit/apron/overalls
	glasses = /obj/item/clothing/glasses/welding
	uniform = /obj/item/clothing/under/misc/overalls
	belt = /obj/item/storage/belt/utility/full
	shoes = /obj/item/clothing/shoes/workboots
	backpack_contents = list(
		/obj/item/pickaxe/mini = 1,
		/obj/item/shovel/spade = 1,
		)

/datum/outfit/loadout/miner
	name = "Miner"
	suit = /obj/item/clothing/suit/armor/light/leather/rig
	uniform = /obj/item/clothing/under/f13/lumberjack
	head = /obj/item/clothing/head/hardhat
	belt = /obj/item/storage/belt/utility/mining/alt
	shoes = /obj/item/clothing/shoes/f13/miner
	backpack_contents = list(
		/obj/item/t_scanner/adv_mining_scanner = 1,
		/obj/item/pickaxe/silver = 1,
		/obj/item/shovel = 1,
		)
/*--------------------------------------------------------------*/

/datum/job/eastwood/f13dendoc
	title = "Apothecary"
	flag = F13DENDOC
	department_flag = DEP_EASTWOOD
	total_positions = 3
	spawn_positions = 3
	supervisors = "The Warden"
	description = "Handy with a scalpel and scanner, your expertise in the practice of medicine makes you an indispensible asset to the settlement of Eastwood. Just remember that you're not a Follower - medicine doesn't come for free, and you aren't here out of the kindness of your heart. Make sure to turn a profit on your services, or the Mayor might reconsider your position, if you're bad enough the Warden might even kick you out!"
	enforces = "Medicine is a public service, and you are under control of local governance - but remember public doesn't equate to free."
	selection_color = "#dcba97"

	loadout_options = list(
	/datum/outfit/loadout/rescueranger, //auto5 shotgun
	/datum/outfit/loadout/stitcher, //primitive med + limbgrower circuit board
	/datum/outfit/loadout/mixer,//big beakers + bloodgen circuit
	/datum/outfit/loadout/holidaydoc) //revolver + firstaidkit

	outfit = /datum/outfit/job/den/f13dendoc
	access = list(ACCESS_BAR, ACCESS_CLINIC, ACCESS_CLONING, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_DOC, ACCESS_TOWN_SCIENCE)
	minimal_access = list(ACCESS_BAR, ACCESS_CLINIC, ACCESS_CLONING, ACCESS_FOLLOWER, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_DOC, ACCESS_TOWN_SCIENCE)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

/datum/outfit/job/den/f13dendoc
	name = "Doctor"
	jobtype = /datum/job/eastwood/f13dendoc
	chemwhiz = TRUE
	ears = /obj/item/radio/headset/headset_town/medical
	uniform = /obj/item/clothing/under/f13/medic
	neck = /obj/item/clothing/neck/stethoscope
	suit = /obj/item/clothing/suit/toggle/labcoat
	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	shoes = /obj/item/clothing/shoes/sneakers/white
	id = /obj/item/card/id/dendoctor
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/reagent_containers/hypospray/medipen/stimpak=2,
		/obj/item/storage/firstaid/regular,
		/obj/item/clothing/accessory/armband/medblue
		)
/datum/outfit/job/den/f13dendoc/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(GLOB.chemwhiz_recipes)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_SURGERY_HIGH, src)

/datum/outfit/loadout/rescueranger
	name = "Search and Rescue"
	backpack_contents = list(/obj/item/clothing/head/f13/police/sergeant = 1,
		/obj/item/gun/ballistic/shotgun/automatic/combat/auto5 = 1,
		/obj/item/ammo_box/shotgun/buck = 1,
		/obj/item/clothing/suit/toggle/labcoat/paramedic = 1,
		/obj/item/folder/white = 1,
		/obj/item/flashlight/pen/paramedic = 1
		)

/datum/outfit/loadout/stitcher
	name = "Stitcher"
	backpack_contents = list(/obj/item/clothing/head/hardhat/white = 1,
		/obj/item/grenade/flashbang = 1,
		/obj/item/clothing/glasses/welding = 1,
		/obj/item/storage/belt/medical/primitive = 1,
		/obj/item/storage/medical/ancientfirstaid = 1,
		/obj/item/circuitboard/machine/limbgrower = 1,
		/obj/item/healthanalyzer/advanced = 1,
		/obj/item/storage/belt/legholster/police = 1
		)

/datum/outfit/loadout/mixer
	name = "Mixer"
	backpack_contents = list(/obj/item/clothing/head/beret/chem = 1,
		/obj/item/melee/classic_baton/police = 1,
		/obj/item/pen/sleepy = 1,
		/obj/item/reagent_containers/glass/beaker/plastic = 1,
		/obj/item/reagent_containers/glass/beaker/meta = 1,
		/obj/item/reagent_containers/hypospray = 1,
		/obj/item/circuitboard/machine/bloodbankgen = 1
		)

/datum/outfit/loadout/holidaydoc
	name = "Holiday Doc"
	backpack_contents = list(/obj/item/vending_refill/medical = 1,
		/obj/item/pda/medical = 1,
		/obj/item/clothing/suit/hooded/surgical = 1,
		/obj/item/storage/medical/ancientfirstaid = 1,
		/obj/item/ammo_box/m44 = 1,
			/obj/item/gun/ballistic/revolver/m29/snub = 1
		)
/*--------------------------------------------------------------*/

/datum/job/eastwood/f13barkeep
	title = "Tavern Keeper"
	flag = F13BARKEEP
	department_flag = DEP_EASTWOOD
	total_positions = 2
	spawn_positions = 2
	supervisors = "the free market and Eastwood's Laws"
	description = "As a proprietor of the tavern, you are responsible for ensuring both citizens and travellers in Eastwood can get some food, drink and rest. Speak to the farmers for fresh produce!"
	enforces = " The tavern is a private business and you can decide who is welcome there. However, you are still subject to the overarching laws of Eastwood."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/den/f13barkeep

	loadout_options = list(
	/datum/outfit/loadout/rugged, //cowboy appearance
	/datum/outfit/loadout/frontier,//Suit with fake moustache
	/datum/outfit/loadout/richmantender,//fedora and suit
	/datum/outfit/loadout/diner)//brahmin clothing + chefs apron

	access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR)
	minimal_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)


/datum/outfit/job/den/f13barkeep
	name = "Barkeep"
	jobtype = /datum/job/eastwood/f13barkeep
	uniform = /obj/item/clothing/under/f13/bartenderalt
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town/commerce
	belt = /obj/item/kit_spawner/townie/barkeep
	shoes = /obj/item/clothing/shoes/workboots/mining
	backpack = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/wallet/stash/mid = 1,
	//	/obj/item/ammo_box/shotgun/bean = 2,
		/obj/item/book/manual/nuka_recipes = 1,
		/obj/item/stack/f13Cash/caps/onezerozero = 1,
		/obj/item/reagent_containers/food/drinks/bottle/rotgut = 1
		)

/datum/outfit/loadout/rugged
	name = "Rugged"
	head = /obj/item/clothing/head/helmet/f13/brahmincowboyhat
	uniform = /obj/item/clothing/under/f13/cowboyb
	suit = /obj/item/clothing/suit/armor/outfit/vest/cowboy
	gloves = /obj/item/clothing/gloves/color/brown
	shoes = /obj/item/clothing/shoes/f13/brownie

/datum/outfit/loadout/frontier
	name = "Frontier"
	head = /obj/item/clothing/head/bowler
	mask = /obj/item/clothing/mask/fakemoustache
	uniform = /obj/item/clothing/under/f13/westender
	suit = /obj/item/clothing/suit/armor/outfit/vest/bartender
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/f13/fancy

/datum/outfit/loadout/richmantender
	name = "Fancy"
	head = /obj/item/clothing/head/fedora
	glasses = /obj/item/clothing/glasses/sunglasses
	uniform = /obj/item/clothing/under/rank/bartender
	suit = /obj/item/clothing/suit/toggle/lawyer/black
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/f13/fancy
	neck = /obj/item/clothing/neck/tie/black

/datum/outfit/loadout/diner
	name = "Diner"
	glasses = /obj/item/clothing/glasses/orange
	uniform = /obj/item/clothing/under/f13/brahminf
	neck = /obj/item/clothing/neck/apron/chef
	gloves = /obj/item/clothing/gloves/color/white
	shoes = /obj/item/clothing/shoes/f13/military/ncr

/*--------------------------------------------------------------*/
/datum/job/eastwood/f13settler
	title = "Citizen"
	flag = F13SETTLER
	department_flag = DEP_EASTWOOD
	total_positions = -1
	spawn_positions =-1
	supervisors = "Eastwood's laws"
	description = "You are a citizen within the town. Under the watch of the Warden and his guard you try best to earn your keep. You live within the safety of the walls."

	outfit = /datum/outfit/job/den/f13settler

	
	loadout_options = list(
		/datum/outfit/loadout/provisioner, //first aid kit 
		/datum/outfit/loadout/groundskeeper,//janitor
		/datum/outfit/loadout/artisan,//welding gear + sledge
		/datum/outfit/loadout/outdoorsman,//hunting rifle + ammo
		/datum/outfit/loadout/militia,//combat rifle .45
		/datum/outfit/loadout/singer,//2 smoke bombs
		/datum/outfit/loadout/farmer,//weed + farming gear
		/datum/outfit/loadout/prospector,//snub revolver + mining gear
		// /datum/outfit/loadout/remnant
	)
	access = list(ACCESS_BAR, ACCESS_TOWN, ACCESS_TOWN_CIV)
	minimal_access = list(ACCESS_BAR, ACCESS_TOWN, ACCESS_TOWN_CIV)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)


/datum/outfit/job/den/f13settler
	name = "Citizen"
	jobtype = /datum/job/eastwood/f13settler
	belt = /obj/item/kit_spawner/townie
	//suit_store = /obj/item/kit_spawner/tools //suit store not workin for some reason
	id = /obj/item/card/id/dogtag/town
	uniform = /obj/item/clothing/under/f13/settler
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/wallet/stash/low = 1,
		/obj/item/kit_spawner/tools,
		///obj/item/melee/onehanded/knife/hunting = 1 //you already got a knife
		)

/datum/outfit/job/den/f13settler/pre_equip(mob/living/carbon/human/H)
	. = ..()
	/*people generally find their own hats
	head = pick(/obj/item/clothing/head/f13/ranger_hat/tan,
		/obj/item/clothing/head/soft/mime,
		/obj/item/clothing/head/soft/black,
		/obj/item/clothing/head/soft/grey,
		/obj/item/clothing/head/f13/gambler,
		/obj/item/clothing/head/f13/cowboy,
		/obj/item/clothing/head/f13/ranger_hat/banded,
		/obj/item/clothing/head/cowboyhat/white,
		/obj/item/clothing/head/beret/headband,
		/obj/item/clothing/head/cowboyhat/pink,
		/obj/item/clothing/head/f13/police/trooper,
		/obj/item/clothing/head/fedora/curator,
		/obj/item/clothing/head/fedora/det_hat,
		/obj/item/clothing/head/bowler)
		*/ //they do need a uniform tho
	uniform = pick(
		/obj/item/clothing/under/f13/gentlesuit,
		/obj/item/clothing/under/f13/formal,
		/obj/item/clothing/under/f13/spring,
		/obj/item/clothing/under/f13/relaxedwear,
		/obj/item/clothing/under/f13/machinist,
		/obj/item/clothing/under/f13/brahminf,
		/obj/item/clothing/under/f13/cowboyb,
		/obj/item/clothing/under/f13/cowboyg,
		/obj/item/clothing/under/f13/cowboyt)


/datum/outfit/loadout/provisioner
	name = "Provisioner"
	neck = /obj/item/clothing/neck/scarf/cptpatriot
	suit = /obj/item/clothing/suit/jacket/miljacket
	neck = /obj/item/clothing/ears/headphones
	gloves = /obj/item/pda
	shoes = /obj/item/clothing/shoes/f13/explorer
	uniform = /obj/item/clothing/under/f13/merca
	gloves = /obj/item/clothing/gloves/f13/leather
	shoes = /obj/item/clothing/shoes/f13/explorer
	backpack_contents = list(/obj/item/reagent_containers/food/drinks/flask = 1,
	/obj/item/storage/medical/ancientfirstaid = 1,
	/obj/item/reagent_containers/food/drinks/flask/survival = 1,
	)

/datum/outfit/loadout/groundskeeper
	name = "Groundskeeper"
	head = /obj/item/clothing/head/soft/grey
	belt = /obj/item/storage/belt/utility/waster
	suit = /obj/item/clothing/under/f13/mechanic
	gloves = /obj/item/clothing/gloves/color/black
	shoes = /obj/item/clothing/shoes/sneakers/noslip
	neck = /obj/item/storage/belt/shoulderholster/
	backpack_contents = list(/obj/item/storage/bag/trash = 1,
	/obj/item/reagent_containers/spray/cleaner = 1,
	/obj/item/mop = 1,
	/obj/item/reagent_containers/glass/bucket/plastic = 1,
	/obj/item/broom = 1,
	/obj/item/stack/sheet/metal/fifty = 1,
	/obj/item/lightreplacer = 1,
	/obj/item/reagent_containers/spray/cleaner = 1
	)

/datum/outfit/loadout/artisan
	name = "Artisan"
	uniform = /obj/item/clothing/under/f13/cowboyg
	belt = /obj/item/storage/belt/utility/mining/alt
	gloves = /obj/item/clothing/gloves/f13/blacksmith
	shoes = /obj/item/clothing/shoes/f13/military/leather
	neck = /obj/item/storage/belt/shoulderholster
	backpack_contents = list(/obj/item/twohanded/sledgehammer/simple = 1,
	/obj/item/book/granter/crafting_recipe/ODF = 1,
	/obj/item/clothing/glasses/welding = 1,
	/obj/item/storage/belt/utility/mining/alt = 1,
	/obj/item/melee/smith/hammer/premade = 1,
	/obj/item/stack/sheet/mineral/titanium = 15,
	/obj/item/pickaxe/mini = 1,
	/obj/item/mining_scanner = 1
	)

/datum/outfit/loadout/outdoorsman
	name = "Outdoorsman"
	head = /obj/item/clothing/head/helmet/f13/marlowhat
	suit = /obj/item/clothing/suit/armor/light/leather/tanvest
	belt = /obj/item/melee/onehanded/knife/bowie
	uniform = /obj/item/clothing/under/f13/cowboyt
	gloves = /obj/item/clothing/gloves/botanic_leather
	shoes = /obj/item/clothing/shoes/f13/peltboots
	backpack_contents = list(
	/obj/item/gun/ballistic/rifle/hunting = 1,
	/obj/item/ammo_box/a3006box = 2,
	/obj/item/gun_upgrade/scope/watchman = 1,
	/obj/item/fishingrod = 1,
	/obj/item/binoculars = 1,
	/obj/item/crafting/campfirekit = 1,
	/obj/item/storage/fancy/rollingpapers/makeshift = 1
	)

/datum/outfit/loadout/militia
	name = "Militia"
	head = /obj/item/clothing/head/helmet/armyhelmet
	suit = /obj/item/clothing/suit/armor/medium/vest/breastplate
	uniform = /obj/item/clothing/under/f13/combat/militia
	gloves = /obj/item/clothing/gloves/f13/leather
	shoes = /obj/item/clothing/shoes/f13/military
	belt = /obj/item/storage/belt/bandolier
	backpack_contents = list(
	/obj/item/gun/ballistic/automatic/combat/worn = 1,
	/obj/item/ammo_box/magazine/tommygunm45/stick = 2,
	/obj/item/shovel/trench =1,
	/obj/item/binoculars = 1,
	)

/datum/outfit/loadout/singer
	name = "Singer"
	shoes = /obj/item/clothing/shoes/laceup
	backpack_contents = list(/obj/item/clothing/under/f13/classdress = 1,
	/obj/item/clothing/under/suit/black_really = 1,
	/obj/item/clothing/gloves/evening = 1,
	/obj/item/clothing/gloves/color/white = 1,
	/obj/item/melee/classic_baton/militarypolice = 1,
	/obj/item/grenade/smokebomb = 2,
	/obj/item/clothing/accessory/pocketprotector/full = 1,
	/obj/item/choice_beacon/music = 1,
	)

/datum/outfit/loadout/farmer
	name = "Farmer"
	backpack_contents = list(/obj/item/clothing/head/helmet/f13/brahmincowboyhat = 1,
	/obj/item/clothing/under/f13/rustic = 1,
	/obj/item/clothing/suit/armor/light/duster/battlecoat = 1,
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

/datum/outfit/loadout/prospector
	name = "Prospector"
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
	/obj/item/ammo_box/m44 = 2,
	/obj/item/gun/ballistic/revolver/m29/snub = 1
	)

/* /datum/outfit/loadout/remnant
	name = "Enclave Remnant"
	backpack_contents = list(
	/obj/item/clothing/head/f13/enclave/peacekeeper = 1,
	/obj/item/card/id/dogtag/enclave/trooper = 1,
	/obj/item/stock_parts/cell/ammo/ec = 3,
	/obj/item/gun/energy/laser/pistol/worn = 1,
	) */

/*--------------------------------------------------------------*/
 
/datum/job/eastwood/f13radio_host
	title = "Jester"
	flag = F13RADIOHOST
	department_flag = DEP_EASTWOOD
	total_positions = 1
	spawn_positions = 1
	supervisors = "Eastwood laws"
	description = "You are the Jester of Eastwood. You are expected to risk neck and reputation to get the latest scoop in the region. and since news alone don't pay the bills you can move around as the towns clown. Pranking and Clowning on through history to make your mark. Should you choose."
	enforces = "Although very independant and vocal  you are still under control of local governance - try to keep a good relationship with them but don't risk your journalist integrity to please the boss."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/den/f13radio_host

	access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_RADIO)
	minimal_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_RADIO)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		),
	)
/datum/outfit/job/den/f13radio_host
	name = "Radio Host"
	jobtype = /datum/job/eastwood/f13radio_host
	id = /obj/item/card/id/dogtag/town
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	belt = /obj/item/pda/detective
	backpack_contents = list(
		/obj/item/camera, \
		/obj/item/camera_film=1,
		/obj/item/taperecorder=1, \
		/obj/item/gun/ballistic/automatic/pistol/n99, \
		/obj/item/ammo_box/magazine/m10mm/adv/simple=2)
	shoes = /obj/item/clothing/shoes/workboots

/datum/outfit/job/den/f13settler/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/settler, \
		/obj/item/clothing/under/f13/brahminm, \
		/obj/item/clothing/under/f13/machinist, \
		/obj/item/clothing/under/f13/lumberjack, \
		/obj/item/clothing/under/f13/roving)

/*--------------------------------------------------------------*/
/*----------------------------------------------------------------
--							Detective							--
----------------------------------------------------------------*/

/datum/job/eastwood/f13detective
	title = "Detective"
	flag = F13DETECTIVE
	total_positions = 0
	spawn_positions = 0
	supervisors = "paying clients and Eastwood's laws"
	selection_color = "#dcba97"
	outfit = /datum/outfit/job/eastwood/f13detective

	access = list(ACCESS_BAR, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_SEC)
	minimal_access = list(ACCESS_BAR, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_SEC)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/wasteland/f13wastelander,
			/datum/job/eastwood/f13detective
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/wasteland/f13wastelander,
			/datum/job/eastwood/f13detective
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/wasteland/f13wastelander
		)
	)


/datum/outfit/job/eastwood/f13detective
	name = "Detective"
	jobtype = /datum/job/eastwood/f13detective
	belt = /obj/item/kit_spawner/lawman
	suit = /obj/item/clothing/suit/det_suit/grey
	uniform = /obj/item/clothing/under/f13/detectivealt
	head = /obj/item/clothing/head/f13/det_hat_alt
	ears = /obj/item/radio/headset/headset_town/lawman
	shoes = /obj/item/clothing/shoes/laceup
	id = /obj/item/card/id/silver
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/flare
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	suit_store = /obj/item/gun/ballistic/revolver/colt357
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/pda/detective=1,
		/obj/item/camera/detective=1,
		/obj/item/toy/crayon/white=1,
		/obj/item/detective_scanner=1,
		/obj/item/storage/box/gloves=1,
		/obj/item/storage/box/evidence=1)
		///obj/item/ammo_box/a357=2)

/*--------------------------------------------------------------*/

/datum/job/eastwood/f13banker
	title = "Banker"
	flag = F13BANKER
	department_flag = DEP_EASTWOOD
	total_positions = 0
	spawn_positions = 0
	supervisors = "The Mayor"
	description = "No matter the nature of society, fortune and profit are there to be made! It is up to you to make deals, distribute caps and earn interest - an easy first venture might be safekeeping possessions in the strongboxes of your vault within the First Bank of Eastwood. Ensure you make a profit and retain enough capital for your day-to-day operations. You are under the governance of Eastwood, but perhaps deal-making will take you into other alliances."
	enforces = "Your bank is a private business and you are not under direct control of local governance, but are subject to their laws."
	selection_color = "#dcba97"
	outfit = /datum/outfit/job/den/f13banker

	loadout_options = list(
	/datum/outfit/loadout/classy,
	/datum/outfit/loadout/loanshark,
	/datum/outfit/loadout/investor
	)

	access = list(ACCESS_BAR, ACCESS_MINT_VAULT)
	minimal_access = list(ACCESS_BAR, ACCESS_MINT_VAULT)

/datum/outfit/job/den/f13banker
	name = "Banker"
	jobtype = /datum/job/eastwood/f13banker
	belt = /obj/item/kit_spawner/lawman

	uniform = /obj/item/clothing/under/lawyer/blacksuit
	id = /obj/item/card/id/silver
	ears = /obj/item/radio/headset/headset_town/commerce
	shoes = /obj/item/clothing/shoes/f13/fancy
	backpack = /obj/item/storage/backpack/satchel/leather
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/wallet/stash/banker = 1)

/datum/outfit/loadout/classy
	name = "Classy"
	head = /obj/item/clothing/head/collectable/tophat
	glasses = /obj/item/clothing/glasses/monocle
	uniform = /obj/item/clothing/under/suit_jacket/charcoal
	suit = /obj/item/clothing/suit/armor/outfit/jacket/banker
	gloves = /obj/item/clothing/gloves/color/white
	shoes = /obj/item/clothing/shoes/laceup
	backpack_contents = list(/obj/item/cane=1,
		///obj/item/storage/belt/shoulderholster/ranger45 =1,
		/obj/item/storage/fancy/cigarettes/cigpack_bigboss=1,
		/obj/item/reagent_containers/food/drinks/bottle/whiskey=1,
		/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass=1,
		/obj/item/lighter/gold = 1
		)

/datum/outfit/loadout/loanshark
	name = "Loanshark"
	glasses = /obj/item/clothing/glasses/orange
	mask = /obj/item/clothing/mask/cigarette/cigar
	suit = /obj/item/clothing/suit/armor/outfit/vest
	uniform = /obj/item/clothing/under/f13/sleazeball
	shoes = /obj/item/clothing/shoes/sandal
	backpack_contents = list(/obj/item/reagent_containers/food/drinks/bottle/whiskey=1,
		/obj/item/storage/box/matches=1,
		///obj/item/gun/ballistic/automatic/smg/mini_uzi=1,
		/obj/item/instrument/violin/golden = 1
		)

/datum/outfit/loadout/investor
	name = "Investor"
	glasses = /obj/item/clothing/glasses/sunglasses
	suit = /obj/item/clothing/suit/toggle/lawyer/black
	uniform = /obj/item/clothing/under/f13/bennys
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/laceup
	backpack_contents = list(/obj/item/storage/fancy/cigarettes/cigpack_bigboss=1,
		/obj/item/storage/box/matches=1,
		/obj/item/blacksmith/ingot/gold = 1,
		///obj/item/gun/ballistic/shotgun/automatic/combat/shotgunlever = 1
		)
/*--------------------------------------------------------------*/

//The Quartermaster
/datum/job/eastwood/f13quartermaster
	title = "Merchant"
	flag = F13QUARTERMASTER
	department_flag = DEP_EASTWOOD
	total_positions = 1
	spawn_positions = 1
	supervisors = "the free market and Eastwood's laws"
	description = "You are the team leader for your various workers in the shop. Guide them as you see fit towards a profitable future."
	enforces = "The Eastwood store is part of your workplace, but it is not your workplace alone. You should try to work with your team in order to turn a profit."
	selection_color = "#dcba97"
	exp_requirements = 0

	loadout_options = list(
	/datum/outfit/loadout/laser_master, //plasma rifle blueprint
	/datum/outfit/loadout/ballistic_master //armalite blueprint
	)

	outfit = /datum/outfit/job/den/f13quartermaster
	access = list(ACCESS_BAR, ACCESS_CARGO_BOT, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_MERCH)
	minimal_access = list(ACCESS_BAR, ACCESS_CARGO_BOT, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_MERCH)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

/datum/outfit/job/den/f13quartermaster
	name = "Quartermaster"
	jobtype = /datum/job/eastwood/f13quartermaster
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town/commerce
	belt = /obj/item/kit_spawner/townie
	uniform = /obj/item/clothing/under/f13/roving
	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	duffelbag = /obj/item/storage/backpack/duffelbag
	gloves = /obj/item/clothing/gloves/fingerless
	l_pocket = /obj/item/storage/wallet/stash/high
	r_pocket = /obj/item/flashlight/glowstick
	shoes = /obj/item/clothing/shoes/f13/explorer
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/pda/quartermaster,
		/obj/item/stack/f13Cash/caps/twofivezero)

/datum/outfit/loadout/laser_master
	name = "Laser Master"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/plasmarifle = 1
	)

/datum/outfit/loadout/ballistic_master
	name = "Ballistic Master"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/armalite = 1
	)

/datum/outfit/job/den/f13quartermaster/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policepistol)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policerifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steelbib/heavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/armyhelmetheavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/trail_carbine)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/lever_action)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/a180)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/huntingrifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/varmintrifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/huntingshotgun)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/thatgun)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/uzi)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/smg10mm)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/frag_shrapnel)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/concussion)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/explosive/shrapnelmine)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)

/datum/outfit/job/den/f13quartermaster/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return

//The Trade Workers
/datum/job/eastwood/f13shopkeeper
	title = "Merchants Mercenary"
	flag = F13SHOPKEEPER
	department_flag = DEP_EASTWOOD
	total_positions = 4
	spawn_positions = 4
	supervisors = "the free market and Eastwood's laws"
	description = "You are one of the many workers who live in the city of Eastwood. Working with the town council you have rented out a space in the shop for you to make your living."
	enforces = "The Eastwood store is part of your workplace, but it is not your workplace alone. You should try work with the other trade workers to try and turn a profit."
	selection_color = "#dcba97"
	exp_requirements = 0

	loadout_options = list(
	/datum/outfit/loadout/energy_specialist, //AER9 + light plasma pistol blueprint
	/datum/outfit/loadout/ballistic_specialist, //riotshotgun + deagle blueprint
	/datum/outfit/loadout/jackofall_specialist //AEP7 + Uzi blueprint
	)

	outfit = /datum/outfit/job/den/f13shopkeeper
	access = list(ACCESS_BAR, ACCESS_CARGO_BOT, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_MERCH)
	minimal_access = list(ACCESS_BAR, ACCESS_CARGO_BOT, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_MERCH)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)

/datum/outfit/job/den/f13shopkeeper
	name = "Shopkeeper"
	jobtype = /datum/job/eastwood/f13shopkeeper
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town/commerce
	belt = /obj/item/kit_spawner/townie
	uniform = /obj/item/clothing/under/f13/roving
	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	duffelbag = /obj/item/storage/backpack/duffelbag
	gloves = /obj/item/clothing/gloves/fingerless
	l_pocket = /obj/item/storage/wallet/stash/high
	r_pocket = /obj/item/flashlight/glowstick
	shoes = /obj/item/clothing/shoes/f13/explorer
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx)

/datum/outfit/loadout/energy_specialist
	name = "Energy Specialist"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/aer9=1,
		/obj/item/book/granter/crafting_recipe/blueprint/lightplasmapistol=1
	)

/datum/outfit/loadout/ballistic_specialist
	name = "Ballistic Specialist"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/riotshotgun=1,
		/obj/item/book/granter/crafting_recipe/blueprint/deagle=1
	)

/datum/outfit/loadout/jackofall_specialist
	name = "Jack-Of-All Trade"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/aep7=1,
		/obj/item/book/granter/crafting_recipe/blueprint/uzi=1
	)

/datum/outfit/job/den/f13shopkeeper/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policepistol)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policerifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steelbib/heavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/armyhelmetheavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/trail_carbine)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/lever_action)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/a180)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/huntingrifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/varmintrifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/huntingshotgun)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/thatgun)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/uzi)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/smg10mm)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/frag_shrapnel)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/concussion)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/explosive/shrapnelmine)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)

/datum/outfit/job/den/f13shopkeeper/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return


//pilot job, bare basics rn, but we can add as needed
/datum/job/eastwood/f13pilot
	title = "Vertibird Pilot"
	flag = F13PILOT
	department_flag = DEP_EASTWOOD
	total_positions = 0
	spawn_positions = 0
	supervisors = "Eastwood's laws"
	description = "You are a pilot, hired to drive the town's vertibird. Your job is to provide transport for people and aid in search and rescue. Don't forget to charge a fare."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/den/f13pilot

	access = list(ACCESS_BAR, ACCESS_EVA)
	minimal_access = list(ACCESS_BAR, ACCESS_EVA)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eastwood
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eastwood
		)
	)


/datum/outfit/job/den/f13pilot
	name = "Vertibird Pilot"
	jobtype = /datum/job/eastwood/f13pilot
	belt = /obj/item/kit_spawner/townie
	id = /obj/item/card/id/dogtag/town
	uniform = /obj/item/clothing/under/f13/settler
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx,
		/obj/item/storage/wallet/stash/low = 1,
		)

/datum/outfit/job/den/f13pilot/pre_equip(mob/living/carbon/human/H)
	. = ..()
	uniform = pick(
		/obj/item/clothing/under/f13/gentlesuit,
		/obj/item/clothing/under/f13/formal,
		/obj/item/clothing/under/f13/spring,
		/obj/item/clothing/under/f13/relaxedwear,
		/obj/item/clothing/under/f13/machinist,
		/obj/item/clothing/under/f13/brahminf,
		/obj/item/clothing/under/f13/cowboyb,
		/obj/item/clothing/under/f13/cowboyg,
		/obj/item/clothing/under/f13/cowboyt)

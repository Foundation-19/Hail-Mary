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
/datum/outfit/job/locust
	name = "Locust Point Town Default Template"
	ears = /obj/item/radio/headset/headset_town
	id = /obj/item/card/id/dogtag/town
	uniform = /obj/item/clothing/under/f13/settler
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/storage/wallet/stash/low = 1,
		/obj/item/melee/onehanded/knife/hunting = 1
		)

/datum/outfit/job/locust/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)
	
/*
Mayor
*/

/datum/job/locust_point
	faction = FACTION_LOCUST

/datum/job/locust_point/f13baltimoredockmaster   // /obj/item/card/id/captains_spare for any elected mayors. - Blue
	title = "Dockmaster of Locust Point"
	flag = F13BALTIMOREDOCKMASTER
	department_flag = DEP_LOCUST
	total_positions = 1
	spawn_positions = 1
	supervisors = "Locust Point Town"
	description = "Long time ago, your ancestor, the first dockmaster, created the now safeheaven town you lead. You were not voted in, and other of the many descendants are also entrusted to be the leader. You have the power of making the laws."
	enforces = "The port councelors are your stand-in replacement and works under you. Under this is the constable."
	selection_color = "#d7b088"

	outfit = /datum/outfit/job/locust/f13baltimoredockmaster
	access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_CLINIC, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	minimal_access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_KITCHEN, ACCESS_CLINIC, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)


/datum/outfit/job/locust/f13baltimoredockmaster/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
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

/datum/outfit/job/locust/f13baltimoredockmaster
	name = "Dockmaster of Locust Point"
	jobtype = /datum/job/locust_point/f13baltimoredockmaster
	id = /obj/item/card/id/silver/mayor
	ears = /obj/item/radio/headset/headset_town/mayor
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	l_pocket = /obj/item/storage/wallet/stash/high
	belt = /obj/item/kit_spawner/townie/mayor
	r_pocket = /obj/item/flashlight/seclite
	shoes = /obj/item/clothing/shoes/f13/fancy
	uniform = /obj/item/clothing/under/rank/civilian/victorian_vest
	head = /obj/item/clothing/head/f13/town/big
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx =1,
		/obj/item/storage/box/citizenship_permits = 1,
		/obj/item/pen/fountain/captain = 1,
		/obj/item/gun/ballistic/revolver/revolver45/gunslinger = 1,
		/obj/item/storage/box/funds = 2,
		/obj/item/ammo_box/a45lcbox = 2
		)

/*--------------------------------------------------------------*/

/datum/job/locust_point/f13baltimorecouncil
	title = "Port Councelor"
	flag = F13BALTIMORECONCELOR
	department_flag = DEP_LOCUST
	total_positions = 2
	spawn_positions = 2
	supervisors = "The Mayor"
	description = "A mix between secretary and town agent, you are the second in command. You make sure everything in town runs correctly, making sure everyone gets paid."
	enforces = "You are the stand-in leader of locust point if the Dockmaster isn't here does not exist."
	selection_color = "#d7b088"

	outfit = /datum/outfit/job/locust/f13baltimorecouncil

	access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_CLINIC, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	minimal_access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_KITCHEN, ACCESS_CLINIC, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)

/datum/outfit/job/locust/f13baltimorecouncil
	name = "Port Councelor"
	jobtype = /datum/job/locust_point/f13baltimorecouncil
	id = /obj/item/card/id/silver
	belt = /obj/item/kit_spawner/townie/mayor
	ears = /obj/item/radio/headset/headset_town/mayor
	glasses = /obj/item/clothing/glasses/sunglasses/big
	gloves = /obj/item/clothing/gloves/combat
	backpack = /obj/item/storage/backpack/satchel/leather
	satchel = /obj/item/storage/backpack/satchel/leather
	r_hand = /obj/item/storage/briefcase/secretary
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/seclite
	shoes = /obj/item/clothing/shoes/f13/fancy
	uniform = /obj/item/clothing/under/suit/charcoal
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx =1,
		/obj/item/ammo_box/magazine/m9mm = 2,
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/pda = 1
		)

/datum/outfit/job/locust/f13baltimorecouncil/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
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

/datum/job/locust_point/f13baltimoreconstable
	title = "Police Constable"
	flag = F13BALTIMORECONSTABLE
	department_flag = DEP_LOCUST
	head_announce = list("Security")
	total_positions = 0
	spawn_positions = 0
	supervisors = "The Dockmaster"
	description = "You are the civil enforcer of Locust Point, keeping the settlement within firm control under the authority of the Mayor. With your loyal patrolmen, you maintain your claim to authority by keeping the peace, managing disputes, and protecting the citizens from threats within and without. Never leave Locust Point undefended, and don't let its people die out. If this town falls, new conquerors don't tend to look kindly upon the old law."
	enforces = "You are the stand-in leader of Locust Point if a Mayor or Secretary does not exist."
	selection_color = "#d7b088"
	exp_requirements = 400

	outfit = /datum/outfit/job/locust/f13baltimoreconstable

	
	access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_CLINIC, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	minimal_access = list(ACCESS_BAR, ACCESS_CLONING, ACCESS_GATEWAY, ACCESS_CARGO_BOT, ACCESS_MINT_VAULT, ACCESS_CLINIC, ACCESS_KITCHEN, ACCESS_MINING, ACCESS_FORENSICS_LOCKERS, ACCESS_CLINIC, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_MERCH, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC, ACCESS_TOWN_HOS, ACCESS_TOWN_CMO, ACCESS_TOWN_COMMAND)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)

/datum/outfit/job/locust/f13baltimoreconstable
	name = "Sheriff"
	jobtype = /datum/job/locust_point/f13baltimoreconstable
	id = /obj/item/card/id/dogtag/sheriff
	ears = /obj/item/radio/headset/headset_town/lawman
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	uniform = /obj/item/clothing/under/f13/sheriff
	shoes = /obj/item/clothing/shoes/f13/cowboy
	glasses = /obj/item/clothing/glasses/sunglasses
	l_pocket = /obj/item/storage/wallet/stash/high
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/storage/box/deputy_badges = 1,
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/classic_baton = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
		/obj/item/grenade/flashbang = 1,
		/obj/item/storage/belt/army = 1
		)


/datum/outfit/job/locust/f13baltimoreconstable/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
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

/datum/job/locust_point/f13baltimorepolice
	title = "Locust Point Police Officer"
	flag = F13BALTIMOREPOLICE
	department_flag = DEP_LOCUST
	total_positions = 3
	spawn_positions = 3
	supervisors = "The dockmaster, the port councelors"
	description = "Welcome to the LPPD. Your job ? Make sure the town is peacefull. Get your guns ready, and make people respect the laws written by the dockmaster. The citizens are counting on you. You may also search for missing laborer if they are missing the call."
	enforces = "You work with other organisation : The Minutemens, and the Atlantic Cross Marines. However, the laws by the dockmaster takes priority."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/locust/f13baltimorepolice
	access = list(ACCESS_BAR, ACCESS_GATEWAY, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC)
	minimal_access = list(ACCESS_BAR, ACCESS_GATEWAY, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR, ACCESS_TOWN_PROSP, ACCESS_TOWN_PREACH, ACCESS_TOWN_SCIENCE, ACCESS_TOWN_DOC, ACCESS_TOWN_SEC)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)

/datum/outfit/job/locust/f13baltimorepolice
	name = "Locust Point Police Officer"
	jobtype = /datum/job/locust_point/f13baltimorepolice
	id = /obj/item/card/id/dogtag/deputy
	ears = /obj/item/radio/headset/headset_town/lawman
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	suit_store = /obj/item/storage/belt/legholster
	glasses = /obj/item/clothing/glasses/sunglasses
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/flare
	shoes = /obj/item/clothing/shoes/f13/explorer
	head = /obj/item/clothing/head/helmet/f13/goner/officer/blue
	uniform = /obj/item/clothing/under/f13/police/officer
	suit_store = /obj/item/gun/ballistic/automatic/marksman/policerifle
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/restraints/handcuffs = 1,
		/obj/item/gun/ballistic/revolver/police =1,
		/obj/item/ammo_box/a357box =1,
		/obj/item/melee/onehanded/knife/bowie = 1,
		/obj/item/grenade/flashbang = 1,
		/obj/item/flashlight/seclite = 2,
		/obj/item/storage/belt/army/assault = 1
		)


/*--------------------------------------------------------------*/

/datum/job/locust_point/f13baltimorefarmer
	title = "Servant workers of town"
	flag = F13BALTIMOREFARMER
	department_flag = DEP_LOCUST
	total_positions = -1
	spawn_positions = -1
	supervisors = "Dockmaster, Portcouncelor, Shopclercs, bartender, even citizens..."
	description = "A case of... voluntary service, where you get paid next to nothing to live in a relatively safe town. You are the very lowest point in the social hierachy. Not totaly and legaly a slave, since you have some form of freedom of movement... If it ain't too far from town."
	enforces = "You are under control of local governance, and you are expected to produce food or be used in labor task. If you try to flee away, the police can try to get you back."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/locust/f13baltimorefarmer

	access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV)
	minimal_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point,
		),
	)

	loadout_options = list(
	/datum/outfit/loadout/farmer,
	/datum/outfit/loadout/defence,
	/datum/outfit/loadout/salvager,
	/datum/outfit/loadout/dendoc,)

/datum/outfit/job/locust/f13baltimorefarmer
	name = "baltimore"
	jobtype = /datum/job/locust_point/f13baltimorefarmer
	id = /obj/item/card/id/legionbrand
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	shoes = /obj/item/clothing/shoes/workboots


/datum/outfit/job/locust/baltimorecitizen/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/ravenharness, \
		/obj/item/clothing/under/f13/brahminm, \
		/obj/item/clothing/under/f13/machinist, \
		/obj/item/clothing/under/f13/female/brahmin, \
		/obj/item/clothing/under/f13/roving)

/datum/outfit/loadout/farmer
	name = "Farmer"
	backpack_contents = list(
		/obj/item/storage/bag/plants=1,
		/obj/item/cultivator=1, \
		/obj/item/hatchet=1,
		/obj/item/shovel/spade=1, \
		/obj/item/seeds/bamboo = 1,
		/obj/item/seeds/glowshroom = 1,
		/obj/item/seeds/tower = 1,
		/obj/item/seeds/grape/green = 1,
		/obj/item/seeds/apple/gold = 1,
		/obj/item/seeds/cherry/blue = 1,
		/obj/item/clothing/mask/cigarette/pipe = 1,
		/obj/item/seeds/cannabis = 1,
		/obj/item/seeds/tea/catnip = 1,
		/obj/item/storage/belt/utility/gardener = 1,
		)

/datum/outfit/loadout/defence
	name = "Defence maker"
	backpack_contents = list(
		/obj/item/stack/sheet/mineral/concrete/ten = 2,
		/obj/item/stack/sheet/metal/fifty = 1,
		/obj/item/storage/belt/utility/waster = 1,
		/obj/item/stack/rods/fifty = 2,
		/obj/item/restraints/legcuffs/beartrap = 3,
		/obj/item/clothing/suit/hazardvest = 1,
		)

/datum/outfit/loadout/salvager
	name = "Town salvager"
	backpack_contents = list(
		/obj/item/clothing/head/welding = 1,
		/obj/item/weldingtool/largetank = 1,
		/obj/item/storage/bag/salvage = 1,
		/obj/item/book/granter/trait/techno = 1,
		/obj/item/pickaxe/drill = 1,
		/obj/item/mining_scanner = 1,
		/obj/item/storage/belt/utility/mining/alt =1,
		/obj/item/clothing/suit/hazardvest = 1,
		)

/datum/outfit/loadout/dendoc
	name = "Medical Helper"
	backpack_contents = list(
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/storage/survivalkit/medical/follower = 1,
		/obj/item/reagent_containers/medspray/synthflesh = 2,
		/obj/item/storage/backpack/duffelbag/med/surgery/primitive = 1,
		/obj/item/book/granter/trait/lowsurgery= 1,
		/obj/item/healthanalyzer = 1,
		)

/*--------------------------------------------------------------*/

/datum/job/locust_point/f13baltimorebarkeep
	title = "Casablanca Barkeep"
	flag = F13BALTIMOREBARKEEP
	department_flag = DEP_LOCUST
	total_positions = 2
	spawn_positions = 2
	supervisors = "Locust Town Laws"
	description = "Welcome on the NCS Casablanca. This unsinkable ship was transformed to a floating bar. And you work on it. You tend the bar and restaurant on it. if you aren't a fan of the ship, you still have the Inn, south of the docks."
	enforces = " The bar is a private business and you can decide who is welcome there. However, you are still subject to the overarching laws of Locust point.."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/locust/f13baltimorebarkeep

	loadout_options = list(
	/datum/outfit/loadout/baltrugged,
	/datum/outfit/loadout/baltfrontier,
	/datum/outfit/loadout/baltrichmantender,
	/datum/outfit/loadout/baltdiner)

	access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR)
	minimal_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_BAR)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)


/datum/outfit/job/locust/f13baltimorebarkeep
	name = "Casablanca Barkeep"
	jobtype = /datum/job/locust_point/f13baltimorebarkeep
	uniform = /obj/item/clothing/under/civ/french_sailor
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town/commerce
	belt = /obj/item/kit_spawner/townie/barkeep
	shoes = /obj/item/clothing/shoes/workboots/mining
	backpack = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/storage/wallet/stash/mid = 1,
		/obj/item/ammo_box/shotgun/bean = 2,
		/obj/item/book/manual/nuka_recipes = 1,
		/obj/item/stack/f13Cash/caps/onezerozero = 1,
		/obj/item/reagent_containers/food/drinks/bottle/rotgut = 1
		)

/datum/outfit/loadout/baltrugged
	name = "Rugged"
	head = /obj/item/clothing/head/helmet/f13/brahmincowboyhat
	uniform = /obj/item/clothing/under/f13/cowboyb
	suit = /obj/item/clothing/suit/armor/outfit/vest/cowboy
	gloves = /obj/item/clothing/gloves/color/brown
	shoes = /obj/item/clothing/shoes/f13/brownie

/datum/outfit/loadout/baltfrontier
	name = "Frontier"
	head = /obj/item/clothing/head/bowler
	mask = /obj/item/clothing/mask/fakemoustache
	uniform = /obj/item/clothing/under/f13/westender
	suit = /obj/item/clothing/suit/armor/outfit/vest/bartender
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/f13/fancy

/datum/outfit/loadout/baltrichmantender
	name = "Fancy"
	head = /obj/item/clothing/head/fedora
	glasses = /obj/item/clothing/glasses/sunglasses
	uniform = /obj/item/clothing/under/rank/bartender
	suit = /obj/item/clothing/suit/toggle/lawyer/black
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/f13/fancy
	neck = /obj/item/clothing/neck/tie/black

/datum/outfit/loadout/baltdiner
	name = "Diner"
	glasses = /obj/item/clothing/glasses/orange
	uniform = /obj/item/clothing/under/f13/brahminf
	neck = /obj/item/clothing/neck/apron/chef
	gloves = /obj/item/clothing/gloves/color/white
	shoes = /obj/item/clothing/shoes/f13/military/ncr

/*--------------------------------------------------------------*/
/datum/job/locust_point/baltimorecitizen
	title = "Locust Point Citizen"
	flag = F13BALTIMORECITIZEN
	department_flag = DEP_LOCUST
	total_positions = -1
	spawn_positions =-1
	supervisors = "Locust point laws"
	description = "Either you are the descendant of one of the first to arrive inside this settlement, or arrived on your own when the town opened, you are one of the first "
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/locust/baltimorecitizen

	
	loadout_options = list(
		/datum/outfit/loadout/provisioner2,
		/datum/outfit/loadout/groundskeeper2,
		/datum/outfit/loadout/artisan2,
		/datum/outfit/loadout/outdoorsman2,
		/datum/outfit/loadout/militia2,
		/datum/outfit/loadout/singer2,
		/datum/outfit/loadout/prospector2
	)
	access = list(ACCESS_BAR, ACCESS_TOWN, ACCESS_TOWN_CIV)
	minimal_access = list(ACCESS_BAR, ACCESS_TOWN, ACCESS_TOWN_CIV)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)


/datum/outfit/job/locust/baltimorecitizen
	name = "Locust Point Citizen"
	jobtype = /datum/job/locust_point/baltimorecitizen
	belt = /obj/item/kit_spawner/townie
	//suit_store = /obj/item/kit_spawner/tools //suit store not workin for some reason
	id = /obj/item/card/id/dogtag/town
	uniform = /obj/item/clothing/under/f13/settler
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/storage/wallet/stash/low = 1,
		/obj/item/kit_spawner/tools,
		
		)

/datum/outfit/job/locust/baltimorecitizen/pre_equip(mob/living/carbon/human/H)
	. = ..()

	uniform = pick(
		/obj/item/clothing/under/f13/gentlesuit,
		/obj/item/clothing/under/f13/formal,
		/obj/item/clothing/under/f13/spring,
		/obj/item/clothing/under/f13/relaxedwear,
		/obj/item/clothing/under/civ/portuguese_sailor2,
		/obj/item/clothing/under/civ/sailor_port,
		/obj/item/clothing/under/civ/spanish_sailor,
		/obj/item/clothing/under/costume/sailor,
		/obj/item/clothing/under/f13/cowboyg,
		/obj/item/clothing/under/f13/cowboyt)


/datum/outfit/loadout/provisioner2
	name = "provisioner2"
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

/datum/outfit/loadout/groundskeeper2
	name = "groundskeeper2"
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

/datum/outfit/loadout/artisan2
	name = "artisan2"
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

/datum/outfit/loadout/outdoorsman2
	name = "outdoorsman2"
	head = /obj/item/clothing/head/helmet/f13/marlowhat
	suit = /obj/item/clothing/suit/armor/light/leather/tanvest
	belt = /obj/item/melee/onehanded/knife/bowie
	uniform = /obj/item/clothing/under/f13/cowboyt
	gloves = /obj/item/clothing/gloves/botanic_leather
	shoes = /obj/item/clothing/shoes/f13/peltboots
	backpack_contents = list(
	/obj/item/gun/ballistic/rifle/hunting = 1,
	/obj/item/ammo_box/a308 = 2,
	/obj/item/gun_upgrade/scope/watchman = 1,
	/obj/item/fishingrod = 1,
	/obj/item/binoculars = 1,
	/obj/item/crafting/campfirekit = 1,
	/obj/item/storage/fancy/rollingpapers/makeshift = 1
	)

/datum/outfit/loadout/militia2
	name = "militia2"
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

/datum/outfit/loadout/singer2
	name = "singer2"
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

/datum/outfit/loadout/prospector2
	name = "prospector2"
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

/*--------------------------------------------------------------*/
 
/datum/job/locust_point/f13baltimoreradiohort
	title = "Pirate Radio Host"
	flag = F13BALTIMORERADIOHOST
	department_flag = DEP_LOCUST
	total_positions = 2
	spawn_positions = 2
	supervisors = "No. One. Well except the town laws."
	description = "On board the Rusted Becket, a Ship known for being a Pirate Radio even before the great war. And you, are free to make anykind of show you want."
	enforces = "Although very independant and vocal  you are still under control of local governance - try to keep a good relationship with them but don't risk your journalist integrity to please the boss."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/locust/f13baltimoreradiohort

	access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV)
	minimal_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_TOWN, ACCESS_TOWN_CIV)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		),
	)
/datum/outfit/job/locust/f13baltimoreradiohort
	name = "Independant Radio Host"
	jobtype = /datum/job/locust_point/f13baltimoreradiohort
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

/datum/outfit/job/locust/baltimorecitizen/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/pirate, \
		/obj/item/clothing/under/sailor)

/*--------------------------------------------------------------*/
/*----------------------------------------------------------------
--							PRIEST							--
----------------------------------------------------------------*/

/datum/job/locust_point/f13baltimorepreacher
	title = "Locust Point Priest"
	flag = F13BALTIMOREPREACHER
	total_positions = 1
	spawn_positions = 1
	supervisors = "paying clients and Locust Point's laws"
	description = "May it be in the undergrounds of Locust Point, or in the gardens just behind the townhall, you are here. Preaching and sermoning for what ever gun you bealive in. But you have put your faith in a other thing : This town. Your goal is to help. Feed the poor, bless the rich, help folks arround... And fight bad guys."

	selection_color = "#dcba97"
	outfit = /datum/outfit/job/locust_point/f13baltimorepreacher

	access = list(ACCESS_BAR, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_SEC)
	minimal_access = list(ACCESS_BAR, ACCESS_FORENSICS_LOCKERS, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_SEC)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/wasteland/f13wastelander,
			/datum/job/locust_point/f13baltimorepreacher
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/wasteland/f13wastelander,
			/datum/job/locust_point/f13baltimorepreacher
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/wasteland/f13wastelander
		)
	)


/datum/outfit/job/locust_point/f13baltimorepreacher
	name = "Locust Point Priest"
	jobtype = /datum/job/locust_point/f13baltimorepreacher
	belt = /obj/item/kit_spawner/preacher
	suit = /obj/item/clothing/suit/det_suit/grey
	uniform = /obj/item/clothing/under/f13/chaplain
	ears = /obj/item/radio/headset/headset_town/lawman
	shoes = /obj/item/clothing/shoes/laceup
	id = /obj/item/card/id/silver
	l_pocket = /obj/item/storage/wallet/stash/mid
	r_pocket = /obj/item/flashlight/flare
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	suit_store = /obj/item/gun/ballistic/revolver/colt357
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/toy/crayon/white=1,
		/obj/item/detective_scanner=1,
		/obj/item/camera/spooky = 1,
		/obj/item/reagent_containers/food/drinks/flask=1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak=2,
		/obj/item/storage/fancy/candle_box=1,
		/obj/item/storage/wallet/stash/mid=1,
		/obj/item/storage/box/evidence=1,
		/obj/item/ammo_box/shotgun/buck=2)


/*--------------------------------------------------------------*/

/datum/job/locust_point/f13baltimoremechanic
	title = "Gas station Mechanics"
	flag = F13BALTIMOREMECHANIC
	department_flag = DEP_LOCUST
	total_positions = 3
	spawn_positions = 3
	supervisors = "No one !"
	description = "While you are linked to town... You aren't infact in town. You are a Big's Bill Mechanics, and have a car garage south of town. Previously a band of raider yelling insults at ... Everything related to Baltimore, you are now... A member of society, yelling insults."
	enforces = "Your shop is a private business and you are not under direct control of local governance. You have the right to yell insults tho. And sell cars."
	selection_color = "#dcba97"
	outfit = /datum/outfit/job/locust/f13baltimoremechanic

	access = list(ACCESS_BAR, ACCESS_MINT_VAULT)
	minimal_access = list(ACCESS_BAR, ACCESS_MINT_VAULT)

/datum/outfit/job/locust/f13baltimoremechanic
	name = "Mechanics"
	jobtype = /datum/job/locust_point/f13baltimoremechanic
	uniform = /obj/item/clothing/under/f13/mechanic
	suit = /obj/item/clothing/suit/armor/outfit/jacket/mfp/raider
	suit_store = /obj/item/gun/ballistic/automatic/smg/greasegun
	belt = /obj/item/storage/belt/utility/full/engi
	id = /obj/item/card/id/silver
	ears = /obj/item/radio/headset/headset_town/commerce
	shoes = /obj/item/clothing/shoes/f13/fancy
	backpack = /obj/item/storage/backpack/satchel/leather
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/ammo_box/magazine/greasegun = 3,
		/obj/item/storage/wallet/stash/low = 1
		)


/*--------------------------------------------------------------*/

//The Trade Workers
/datum/job/locust_point/f13baltimoreshopclerc
	title = "Dealmaker Shopclerc"
	flag = F13BALTIMORESHOPCLERC
	department_flag = DEP_LOCUST
	total_positions = 3
	spawn_positions = 3
	supervisors = "the free market and locust point's laws"
	description = "Welcome onboard the Dealmaker. Your task is to main the shop. Resupply is a job for the servants, but you can get the deal down. You can also craft guns."
	enforces = "The Locust Point store is part of your workplace, but it is not your workplace alone. You should try work with the other trade workers to try and turn a profit."
	selection_color = "#dcba97"
	exp_requirements = 0

	loadout_options = list(
	/datum/outfit/loadout/energy_specialist2,
	/datum/outfit/loadout/ballistic_specialist2,
	/datum/outfit/loadout/jackofall_specialist2
	)

	outfit = /datum/outfit/job/locust/f13baltimoreshopclerc
	access = list(ACCESS_BAR, ACCESS_CARGO_BOT, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_MERCH)
	minimal_access = list(ACCESS_BAR, ACCESS_CARGO_BOT, ACCESS_TOWN, ACCESS_TOWN_CIV, ACCESS_TOWN_MERCH)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)

/datum/outfit/job/locust/f13baltimoreshopclerc
	name = "Shopkeeper"
	jobtype = /datum/job/locust_point/f13baltimoreshopclerc
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
		/obj/item/storage/pill_bottle/chem_tin/radx = 1)

/datum/outfit/loadout/energy_specialist2
	name = "Energy Specialist"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/aer9=1,
		/obj/item/book/granter/crafting_recipe/blueprint/lightplasmapistol=1
	)

/datum/outfit/loadout/ballistic_specialist2
	name = "Ballistic Specialist"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/riotshotgun=1,
		/obj/item/book/granter/crafting_recipe/blueprint/deagle=1
	)

/datum/outfit/loadout/jackofall_specialist2
	name = "Jack-Of-All Trade"
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/blueprint/aep7=1,
		/obj/item/book/granter/crafting_recipe/blueprint/uzi=1
	)

/datum/outfit/job/locust/f13baltimoreshopclerc/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
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
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policepistol)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/policerifle)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steelbib/heavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/armyhelmetheavy)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)


/datum/outfit/job/locust/f13baltimoreshopclerc/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return


/datum/job/locust_point/f13baltimorepilot
	title = "Airpoint Transport Pilot"
	flag = F13BALTIMOREPILOT
	department_flag = DEP_LOCUST
	total_positions = 2
	spawn_positions = 2
	supervisors = "Locust Point's laws"
	description = "This town vertibirds is quite the old one. Flew for and protected the Mary's Fleet, a fleet of ships that survived the great war, including the Casablanca until they arrived here. You, are a pilot. Either a descendant or fan of the first pilots of this craft, or simply here for a other reason. Its used by a small company that gets paid to fly the bird arround, called Airpoint Transport."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/locust/f13baltimorepilot

	access = list(ACCESS_BAR, ACCESS_EVA)
	minimal_access = list(ACCESS_BAR, ACCESS_EVA)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/locust_point
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/locust_point
		)
	)


/datum/outfit/job/locust/f13baltimorepilot
	name = "Vertibird Pilot"
	jobtype = /datum/job/locust_point/f13baltimorepilot
	id = /obj/item/card/id/dogtag/town
	head = /obj/item/clothing/head/helmet/f13/combat
	uniform = /obj/item/clothing/under/f13/bodyguard
	suit = /obj/item/clothing/suit/hazardvest
	glasses = /obj/item/clothing/glasses/sunglasses/big
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/storage/wallet/stash/low = 1,
		/obj/item/clothing/suit/armor/medium/vest/flak = 1,
		/obj/item/gun/ballistic/automatic/smg/greasegun = 1,
		/obj/item/ammo_box/magazine/greasegun = 3
	)

/datum/job/locust/f13minutemen
	title = "Minuteman"
	flag = F13MINUTEMEN
	faction = DEP_LOCUST
	total_positions = 4
	spawn_positions = 4
	description = "A beacon of liberty and light in the wastes. The Minutemen are freedom-fighters that aim to keep the wastes a safer and more just place."
	supervisors = "minutemen superiors"

	outfit = /datum/outfit/job/locust/f13minutemen

	access = list(ACCESS_TOWN_SEC)
	minimal_access = list(ACCESS_TOWN_SEC)
	matchmaking_allowed = list(
	/datum/matchmaking_pref/friend = list(
		/datum/job/wasteland/f13wastelander,
	),
	/datum/matchmaking_pref/rival = list(
		/datum/job/wasteland/f13wastelander,
	),
	)

/datum/outfit/job/locust/f13minutemen
	ears = /obj/item/radio/headset/headset_town
	shoes = /obj/item/clothing/shoes/f13/minutemen
	head = /obj/item/clothing/head/helmet/f13/rustedcowboyhat/minutemen
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	belt = /obj/item/storage/belt/army/assault
	uniform = /obj/item/clothing/under/f13/minutemen
	suit = /obj/item/clothing/suit/armor/medium/duster/trenchcoat/minutemen
	suit_store = /obj/item/gun/ballistic/rifle/hobo/lasmusket
	r_pocket = /obj/item/flashlight/seclite
	gloves = /obj/item/clothing/gloves/f13/minutemen
	neck = /obj/item/clothing/neck/scarf/f13/minutemen
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/ammo_box/lasmusket = 3
	)

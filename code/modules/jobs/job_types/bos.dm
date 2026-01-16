/*
BoS access:
Main doors: ACCESS_BOS 120
*/

/datum/job/bos //do NOT use this for anything, it's just to store faction datums.
	department_flag = BOS
	selection_color = "#95a5a6"
	faction = FACTION_BROTHERHOOD
	exp_type = EXP_TYPE_BROTHERHOOD

	access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	forbids = "The Brotherhood of Steel Forbids: Unethical human experimentation. Violence beyond what is needed to accomplish Brotherhood goals, and cruel torture or experiments on the minds or bodies of prisoners."
	enforces = "The Brotherhood of Steel Expects: Obeying the Paladin in charge of this expedition. Collection and safeguarding of technology from the wasteland. Experimentation and research."
	outfit = /datum/outfit/job/bos/

	objectivesList = list(
		"Leadership recommends the following goal for this week: enlighten the blinded. Attempt to show them your ways.",
		"Leadership recommends the following goal for this week: seek and destroy those who follow the old brotherhood's foolish ways.",
		"Leadership recommends the following goal for this week: collect artifacts and blueprints from before the annihilation of the Old World.",
		"Leadership recommends the following goal for this week: remember the sacrifice of Elder Wossner. Hold fesitivies or ceremonies in his honor."
		)

/datum/outfit/job/bos
	name = "bosdatums"
	jobtype = /datum/job/bos
	backpack = /obj/item/storage/backpack/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	ears = /obj/item/radio/headset/headset_bos
	uniform = /obj/item/clothing/under/syndicate/brotherhood
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/combat
	id = /obj/item/card/id/dogtag
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
	)

/datum/outfit/job/bos/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return

/datum/outfit/job/bos/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/set_vrboard/bos)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/gate_bos)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bosoutcastlight)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/*
Elder Envoy
*/

/datum/job/bos/f13envoy
	title = "Elder Envoy"
	flag = F13ENVOY
	head_announce = list("Security")
	total_positions = 0
	spawn_positions = 0
	selection_color = "#7f8c8d"
	outfit = /datum/outfit/job/bos/f13envoy
	req_admin_notify = 1

	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_MINERAL_STOREROOM, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_MINERAL_STOREROOM, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)

/datum/outfit/job/bos/f13sentinel/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/jet)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/turbo)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/psycho)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/buffout)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steady)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)

/datum/outfit/job/bos/f13envoy
	name = "Elder Envoy"
	jobtype = /datum/job/bos/f13envoy
	suit = /obj/item/clothing/suit/armor/light/duster/bos/scribe/elder
	glasses = /obj/item/clothing/glasses/night
	accessory = /obj/item/clothing/accessory/bos/elder
	suit_store = /obj/item/gun/energy/laser/pistol
	neck = /obj/item/clothing/neck/mantle/bos/right
	ears = /obj/item/radio/headset/headset_bos/command
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc = 2,
		/obj/item/melee/onehanded/knife/hunting = 1

	)

/*
Sentinel
*/

/datum/job/bos/f13sentinel
	title = "Sentinel"
	flag = F13SENTINEL
	display_order = JOB_DISPLAY_ORDER_SENTINEL
	head_announce = list("Security")
	total_positions = 0
	spawn_positions = 0
	description = "You are the Sentinel of this local chapter of the Brotherhood of Steel. You may be a veteran of warfare, an experienced commander or even a genius Scribe, and you command all the men within this bunker. Your main goals are to lead the Brotherhood, to solve conflicts inbetween castes and to manage the Paladin Commander, Knight-Captain and Proctor."
	supervisors = "the Council of Sentinels"
	selection_color = "#7f8c8d"
	outfit = /datum/outfit/job/bos/f13sentinel
	exp_requirements = 3000
	req_admin_notify = 1

	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_MINERAL_STOREROOM, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_MINERAL_STOREROOM, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)

/datum/outfit/job/bos/f13sentinel/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/jet)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/turbo)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/psycho)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/buffout)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steady)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)

/datum/outfit/job/bos/f13sentinel
	name = "Sentinel"
	jobtype = /datum/job/bos/f13sentinel
	suit = /obj/item/clothing/suit/armor/light/duster/bos/scribe/elder
	glasses = /obj/item/clothing/glasses/night
	accessory = /obj/item/clothing/accessory/bos/elder
	suit_store = /obj/item/gun/energy/laser/solar
	neck = /obj/item/clothing/neck/mantle/bos/right
	ears = /obj/item/radio/headset/headset_bos/command
	backpack_contents = list(
		/obj/item/melee/powerfist/f13 = 1,
		/obj/item/melee/onehanded/knife/hunting = 1

	)

/*
Paladin Commander
*/

/datum/job/bos/f13paladincommander
	title = "Paladin Commander"
	flag = F13PALADINCOMMANDER
	head_announce = list("Security")
	total_positions = 1
	spawn_positions = 1
	description = "You are the Paladin Commander, leader of the expedition. Work with your small expeditionary force to secure the land and remove the enemy. You are in charge of the expedition and as such you are in-charge of the faction. You should not attempt to fight everyone you see but rather use your rank and skill to secure the land and remove your enemy. "
	supervisors = "the Elders or their Envoys"
	selection_color = "#7f8c8d"
	display_order = JOB_DISPLAY_ORDER_COMMANDER
	outfit = /datum/outfit/job/bos/f13commander
	exp_requirements = 2280

	/*loadout_options = list(
	/datum/outfit/loadout/sentheavy, //Gauss + Glock
	/datum/outfit/loadout/sentmini //Minigun
	)*/

	min_required_special = list(
		"special_c" = 4,
		)


	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)

/datum/outfit/job/bos/f13commander/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)

/datum/outfit/job/bos/f13commander/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/jet)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/turbo)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/psycho)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/buffout)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	ADD_TRAIT(H, TRAIT_IRONFIST, src)
	if(H.mind)
		var/obj/effect/proc_holder/spell/terrifying_presence/S = new /obj/effect/proc_holder/spell/terrifying_presence
		H.mind.AddSpell(S)

/datum/outfit/job/bos/f13commander
	name = "Paladin Commander"
	jobtype = /datum/job/bos/f13paladincommander
	uniform = /obj/item/clothing/under/f13/recon
	belt = /obj/item/storage/belt/army/assault
	accessory = /obj/item/clothing/accessory/bos/sentinel
	glasses = /obj/item/clothing/glasses/sunglasses
	mask = /obj/item/clothing/mask/gas/sechailer
	ears = /obj/item/radio/headset/headset_bos/command
	suit = /obj/item/clothing/suit/armor/power_armor/t51b/hardened
	suit_store = /obj/item/gun/energy/laser/aer12
	head = /obj/item/clothing/head/helmet/f13/power_armor/t51b/bos
	neck = /obj/item/storage/belt/shoulderholster
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/hunting = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 3,
		/obj/item/ammo_box/magazine/m10mm/adv/simple = 5,
		/obj/item/melee/powered/ripper/prewar = 1,
		/obj/item/gun/ballistic/automatic/pistol/n99/crusader = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 3
		)

/*
/datum/outfit/loadout/palcomheavy
	name = "Heavy Paladin Commander"
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/lewis = 1,
		/obj/item/ammo_box/magazine/lewis/l47 = 3
	)

/datum/outfit/loadout/palcomlaser
	name = "Energy Paladin Commander"
	backpack_contents = list(
		/obj/item/gun/energy/laser/aer12 = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 3
	)

/datum/outfit/loadout/palcomhitter
	name = "Heavy Force Paladin Commander"
	backpack_contents = list(
		/obj/item/twohanded/sledgehammer/supersledge = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
	)
*/
/*
Proctor
*/

/datum/job/bos/f13headscribe
	title = "Head Scribe"
	flag = F13HEADSCRIBE
	head_announce = list("Security")
	total_positions = 0
	spawn_positions = 0
	description = "You are the foremost experienced scribe remaining in this bunker. Your role is to ensure the safekeeping and proper usage of technology within the Brotherhood. You are also the lead medical expert in this Chapter. Delegate your tasks to your Scribes."
	supervisors = "the Elders or the Paladin Commander if he is present."
	selection_color = "#7f8c8d"
	display_order = JOB_DISPLAY_ORDER_HEADSCRIBE
	outfit = /datum/outfit/job/bos/f13headscribe
	exp_requirements = 1500

	loadout_options = list(
	/datum/outfit/loadout/hsstand,
	/datum/outfit/loadout/hspract
	)

	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_CHANGE_IDS)

/datum/outfit/job/bos/f13headscribe/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/jet)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/turbo)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/psycho)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/medx/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/buffout)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steady)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_t51helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	ADD_TRAIT(H, TRAIT_MEDICALEXPERT, src)
	ADD_TRAIT(H, TRAIT_CYBERNETICIST_EXPERT, src)
	ADD_TRAIT(H, TRAIT_CYBERNETICIST, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_SURGERY_HIGH, src)

/datum/outfit/job/bos/f13headscribe
	name = "Head Scribe"
	jobtype = /datum/job/bos/f13headscribe
	chemwhiz = TRUE
	accessory = /obj/item/clothing/accessory/bos/headscribe
	glasses = /obj/item/clothing/glasses/sunglasses
	suit = /obj/item/clothing/suit/armor/light/duster/bos/scribe/headscribe
	belt = /obj/item/storage/belt/utility/full/engi
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 3,
		/obj/item/storage/box/gun/energy/wornaep7 = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2
		)

/datum/outfit/loadout/hsstand
	name = "Medicinal Expert"
	backpack_contents = list(
		/obj/item/gun/medbeam = 1,
		/obj/item/reagent_containers/hypospray/CMO = 1
		)

/datum/outfit/loadout/hspract
	name = "Administrative Leader"
	backpack_contents = list(
		/obj/item/gun/energy/laser/plasma/pistol = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2
		)

/*
Knight-Captain
*/

/datum/job/bos/f13knightcap
	title = "Knight-Captain"
	flag = F13KNIGHTCAPTAIN
	head_announce = list("Security")
	total_positions = 1
	spawn_positions = 1
	description = "You are the Knight-Captain, one of the leaders of your group of outcasts. After the attempted coup by the late Paladin Commander Wossner, you have been wandering the wastes, looking for a new home, and have now found a barely-acceptable place to construct your new chapters' bunker. Your knowledge of pre-war materials and engineering is almost unparalleled, and you have basic combat training and experience. You are in charge of establishing a working foothold, and your Knights and initiates. Delegate to them as necessary. As Chief Armorer, you are also in charge of the armory."
	supervisors = "The Elders or the Paladin Commander if he is present."
	selection_color = "#7f8c8d"
	display_order = JOB_DISPLAY_ORDER_KNIGHTCAPTAIN
	outfit = /datum/outfit/job/bos/f13knightcap
	exp_requirements = 1920

	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_ARMORY, ACCESS_BRIG, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS, ACCESS_ARMORY, ACCESS_BRIG, ACCESS_CHANGE_IDS)

	min_required_special = list(
		"special_c" = 4,
		)

/datum/outfit/job/bos/f13knightcap/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_st45_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)


/datum/outfit/job/bos/f13knightcap
	name = "Knight-Captain"
	jobtype = /datum/job/bos/f13knightcap
	gunsmith_one = TRUE
	gunsmith_two = TRUE
	gunsmith_three = TRUE
	gunsmith_four = TRUE
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood/captain
	suit_store = /obj/item/gun/energy/laser/aer9
	glasses = /obj/item/clothing/glasses/night
	accessory =	/obj/item/clothing/accessory/bos/knightcaptain
	l_pocket = /obj/item/storage/belt/sabre/heavy
	mask = /obj/item/clothing/mask/gas/sechailer
	head = /obj/item/clothing/head/helmet/f13/combat/brotherhood/captain
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/hunting = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 3,
		/obj/item/storage/belt/army/security/full = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 3,
		/obj/item/melee/powered/ripper/prewar = 1,
		/obj/item/storage/box/bos/knightcaptain = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_one = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_two = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_three = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_four = 1,

		)
/*
/datum/outfit/loadout/capalt
	name = "Warden-Defender"
	backpack_contents = list(
		/obj/item/gun/ballistic/shotgun/hunting = 1,
		/obj/item/ammo_box/shotgun/buck = 3,
	)
*/

/*
Star Paladin
*/

/datum/job/bos/f13seniorpaladin
	title = "Star Paladin"
	flag = F13SENIORPALADIN
	total_positions = 0
	spawn_positions = 0
	description = "As the Chapter's senior offensive warrior, you have proven your service and dedication to the Brotherhood over your time as a Paladin. As your skills gained, however, you were deigned to be more useful as a commander and trainer. Your job is to coordinate the Paladins and ensure they work as a team, instilling discipline as you go."
	supervisors = "the Paladin Commander"
	display_order = JOB_DISPLAY_ORDER_SENIORPALADIN
	outfit = /datum/outfit/job/bos/f13seniorpaladin
	exp_requirements = 1500 //Not used right now anyways. Slot disabled.
/*
	loadout_options = list(
		/datum/outfit/loadout/spaladina, //5mm Minigun
		/datum/outfit/loadout/spaladind //Super Sledge and Powerfist
		)
*/
	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)


/datum/outfit/job/bos/f13seniorpaladin/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)

/datum/outfit/job/bos/f13seniorpaladin
	name =	"Star Paladin"
	jobtype = /datum/job/bos/f13seniorpaladin
	suit = /obj/item/clothing/suit/armor/power_armor/t51b
	suit_store = /obj/item/gun/energy/laser/aer12
	head = /obj/item/clothing/head/helmet/f13/power_armor/t51b
	accessory =	/obj/item/clothing/accessory/bos/seniorpaladin
	uniform = /obj/item/clothing/under/f13/recon
	belt = /obj/item/storage/belt/army/assault
	mask = /obj/item/clothing/mask/gas/sechailer
	neck = /obj/item/clothing/neck/mantle/bos/paladin
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 4,
		/obj/item/melee/onehanded/knife/hunting = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 5,
	)
/*
/datum/outfit/loadout/spaladina
	name = "Firesupport Star Paladin"
	backpack_contents = list(
		/obj/item/minigunpackbal5mm = 1,
	)

/datum/outfit/loadout/spaladind
	name = "Melee Star Specialist"
	backpack_contents = list(
		/obj/item/melee/powerfist/f13 = 1,
		/obj/item/twohanded/sledgehammer/supersledge = 1,
		)
*/

/*
Paladin
*/

/datum/job/bos/f13paladin
	title = "Paladin"
	flag = F13PALADIN
	total_positions = 1
	spawn_positions = 1
	description = "You are a paladin. Assigned to the expeditionary force through sheer luck or skill. You're one of two power-armor wearers within the force and as such you're to treat it with care. Your posting as a paladin allows you rank over the senior knights and senior scribes. But the Head-Knight, as assigned Second In Command, is above you in rank."
	supervisors = "the Elders or the Paladin Commander if he is present"
	display_order = JOB_DISPLAY_ORDER_PALADIN
	outfit = /datum/outfit/job/bos/f13paladin
	exp_requirements = 1680
/*
	loadout_options = list(
	/datum/outfit/loadout/paladina, //Minigun
	/datum/outfit/loadout/paladind //Sledge and fists
	)
*/
	access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/bos/f13initiate,
		),
		/datum/matchmaking_pref/disciple = list(
			/datum/job/bos/f13seniorpaladin,
		),
	)

	min_required_special = list(
		"special_c" = 4,
		)

/datum/outfit/job/bos/f13paladin/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)

/datum/outfit/job/bos/f13paladin
	name =	"Paladin"
	jobtype =	/datum/job/bos/f13paladin
	suit =	/obj/item/clothing/suit/armor/power_armor/t45d/bos
	suit_store = /obj/item/gun/energy/laser/aer9
	head =	/obj/item/clothing/head/helmet/f13/power_armor/t45d/bos
	uniform =	/obj/item/clothing/under/f13/recon
	belt = /obj/item/storage/belt/army/assault
	mask =	/obj/item/clothing/mask/gas/sechailer
	neck =	/obj/item/clothing/neck/mantle/bos/paladin
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 6,
		/obj/item/melee/onehanded/knife/hunting = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 5,
		/obj/item/melee/powered/ripper/prewar = 1,
	)
/*
/datum/outfit/loadout/paladina
	name = "Firesupport Paladin"
	backpack_contents = list(
		/obj/item/minigunpackbal5mm = 1,
		/obj/item/clothing/accessory/bos/paladin = 1
	)

/datum/outfit/loadout/paladind
	name = "Melee Specialist"
	backpack_contents = list(
		/obj/item/melee/powerfist/f13 = 1,
		/obj/item/twohanded/sledgehammer/supersledge = 1,
		/obj/item/clothing/accessory/bos/paladin = 1
		)
*/

/*
Senior Scribe
*/

/datum/job/bos/f13seniorscribe
	title = "Senior Scribe"
	flag = F13SENIORSCRIBE
	total_positions = 1
	spawn_positions = 1
	description = "You are the bunker's seniormost medical and scientific expert in the bunker, sans the Proctor themselves. You are trained in both medicine and engineering, while also having extensive studies of the old world to assist in pinpointing what technology would be useful to the Brotherhood and its interests."
	supervisors = "Head Scribe, Paladins, Sarge and Head Knights Paladin and Commander."
	display_order = JOB_DISPLAY_ORDER_SENIORSCRIBE
	outfit = /datum/outfit/job/bos/f13seniorscribe
	exp_requirements = 1200

	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/bos/f13scribe,
		),
	)

/datum/outfit/job/bos/f13seniorscribe/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	H.mind.teach_crafting_recipe(GLOB.chemwhiz_recipes)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_SURGERY_HIGH, src)
	ADD_TRAIT(H, TRAIT_CYBERNETICIST, src)

/datum/outfit/job/bos/f13seniorscribe
	name =	"Senior Scribe"
	jobtype = /datum/job/bos/f13seniorscribe
	chemwhiz =	TRUE
	belt = /obj/item/storage/belt/utility/full/engi
	shoes =	/obj/item/clothing/shoes/combat
	accessory =	/obj/item/clothing/accessory/bos/seniorscribe
	suit = /obj/item/clothing/suit/armor/light/duster/bos/scribe/seniorscribe
	suit_store = /obj/item/gun/ballistic/automatic/pistol/ninemil
	glasses = /obj/item/clothing/glasses/sunglasses/big
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m9mm = 2,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/storage/firstaid/regular = 1,
		/obj/item/reagent_containers/hypospray/CMO = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 7,
		/obj/item/storage/box/bos/scribe/senior = 1
	)

/*
Scribe
*/

/datum/job/bos/f13scribe
	title = "Scribe"
	flag = F13SCRIBE
	total_positions = 2
	spawn_positions = 2
	description = "You answer to senior members, tasked with researching and reverse-engineering recovered technologies from the old world, while maintaining the brotherhoods scientific archives. You may also be given a trainee to assign duties to."
	supervisors = "the Head and Senior Scribe, Knights, Paladins and ultimately the Paladin Commander"
	display_order = JOB_DISPLAY_ORDER_SCRIBE
	outfit = /datum/outfit/job/bos/f13scribe
	exp_requirements = 30

	loadout_options = list(
	/datum/outfit/loadout/scribea, //Junior Scribe
	/datum/outfit/loadout/scribeb, //Scribe
	)

	access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/bos/f13initiate,
		),
		/datum/matchmaking_pref/disciple = list(
			/datum/job/bos/f13seniorscribe,
		),
	)

/datum/outfit/job/bos/f13scribe
	name = "Scribe"
	jobtype = /datum/job/bos/f13scribe
	chemwhiz = TRUE
	belt = /obj/item/storage/belt/utility/full/engi
	shoes = /obj/item/clothing/shoes/combat
	suit = /obj/item/clothing/suit/armor/light/duster/bos/scribe
	glasses = /obj/item/clothing/glasses/sunglasses/big
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/storage/firstaid/regular = 1,
		/obj/item/gun/energy/laser/pistol = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 3,
		/obj/item/storage/box/bos/scribe = 1
		)


/datum/outfit/loadout/scribea
	name = "Junior Scribe"
	backpack_contents = list(
		/obj/item/clothing/accessory/bos/juniorscribe = 1
		)

/datum/outfit/loadout/scribeb
	name = "Scribe"
	backpack_contents = list(
		/obj/item/clothing/accessory/bos/scribe = 1
		)

/datum/outfit/job/bos/f13scribe/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	H.mind.teach_crafting_recipe(GLOB.chemwhiz_recipes)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_SURGERY_HIGH, src)
	ADD_TRAIT(H, TRAIT_CYBERNETICIST, src)

/* 
Knight Sarge
*/

/datum/job/bos/f13knightsarge
	title = "Knight Sergeant"
	flag = F13KNIGHTSARGE
	total_positions = 2
	spawn_positions = 2
	description = " You are the Knight Sergeant of the Brotherhood Of Steel Expeditionary force, your goal is to maintain order within the ranks, above the scribes and knights you are below the paladin. Your duty is to maintain order within the knights, infantry work and primary grunt work as well as train the lower ranking knights and aspirants."
	supervisors = "the Head Scribe, Knight-Captain and Paladin Commander"
	display_order = JOB_DISPLAY_ORDER_KNIGHTSARGE
	outfit = /datum/outfit/job/bos/f13knightsarge
	exp_requirements = 1440
/*
	loadout_options = list(
	/datum/outfit/loadout/sknightb, //Police Shotgun
	/datum/outfit/loadout/sknightc, //R93
	/datum/outfit/loadout/sknightd, //Pre-war Ripper
	)
*/
	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/bos/f13knight,
		),
	)

/datum/outfit/job/bos/f13knightsarge/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/AER9)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/AEP7)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/R93)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)

/datum/outfit/job/bos/f13knightsarge
	name = "KnightSarge"
	jobtype = /datum/job/bos/f13knightsarge
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood/sarge
	suit_store = /obj/item/gun/energy/laser/aer9
	accessory = /obj/item/clothing/accessory/bos/knightsarge
	glasses = /obj/item/clothing/glasses/night
	mask = /obj/item/clothing/mask/gas/sechailer
	belt = /obj/item/storage/belt/army/assault
	l_pocket = /obj/item/storage/belt/shoulderholster
	head = /obj/item/clothing/head/helmet/f13/combat/brotherhood/senior
	gunsmith_one = TRUE
	gunsmith_two = TRUE
	gunsmith_three = TRUE
	gunsmith_four = TRUE
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/hunting = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/storage/box/bos/senior = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_one = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_two = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_three = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_four = 1,
		/obj/item/gun/ballistic/automatic/pistol/mk23 = 1,
		/obj/item/ammo_box/magazine/m45/socom = 3,
		)
/*
Senior Knight
*/

/datum/job/bos/f13seniorknight
	title = "Senior Knight"
	flag = F13SENIORKNIGHT
	total_positions = 0
	spawn_positions = 0
	description = "You report directly to the Knight-Captain. You are the Brotherhood Knight-Sergeant. Having served the Knight Caste for some time now, you are versatile and experienced in both basic combat and repairs, and also a primary maintainer of the Bunker's facilities. As your seniormost Knight, you may be assigned initiates or Junior Knights to mentor."
	supervisors = "the Knight-Captain"
	display_order = JOB_DISPLAY_ORDER_SENIORKNIGHT
	outfit = /datum/outfit/job/bos/f13seniorknight
	exp_requirements = 900
/*
	loadout_options = list(
	/datum/outfit/loadout/sknightb, //Police Shotgun
	/datum/outfit/loadout/sknightc, //R93
	/datum/outfit/loadout/sknightd, //Pre-war Ripper
	)
*/
	access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_BROTHERHOOD_COMMAND, ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/bos/f13knight,
		),
	)

/datum/outfit/job/bos/f13seniorknight/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/AER9)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/AEP7)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/R93)

/datum/outfit/job/bos/f13seniorknight
	name = "Senior Knight"
	jobtype = /datum/job/bos/f13seniorknight
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood/senior
	suit_store = /obj/item/gun/energy/laser/aer9
	accessory = /obj/item/clothing/accessory/bos/seniorknight
	glasses = /obj/item/clothing/glasses/night
	mask = /obj/item/clothing/mask/gas/sechailer
	belt = /obj/item/storage/belt/army/assault
	l_pocket = /obj/item/storage/belt/shoulderholster
	head = /obj/item/clothing/head/helmet/f13/combat/brotherhood/senior
	gunsmith_one = TRUE
	gunsmith_two = TRUE
	gunsmith_three = TRUE
	gunsmith_four = TRUE
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/hunting = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 3,
		/obj/item/storage/box/bos/senior = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_one = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_two = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_three = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_four = 1,
		)
/*
/datum/outfit/loadout/sknightb
	name = "Knight-Defender"
	backpack_contents = list(
		/obj/item/gun/ballistic/shotgun/police = 1,
		/obj/item/ammo_box/shotgun/buck = 2,
		/obj/item/gun/energy/laser/pistol = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2
		)

/datum/outfit/loadout/sknightc
	name = "Recon"
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/r93 = 1,
		/obj/item/ammo_box/magazine/m556/rifle = 2,
		/obj/item/gun/energy/laser/pistol = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2
		)

/datum/outfit/loadout/sknightd
	name = "Knight-Sergeant-Cavalry"
	backpack_contents = list(
		/obj/item/clothing/accessory/bos/juniorknight = 1,
		/obj/item/melee/powered/ripper/prewar = 1,
		/obj/item/shield/riot/bullet_proof = 1
		)
*/

/*
Knight
*/

/datum/job/bos/f13knight
	title = "Knight"
	flag = F13KNIGHT
	total_positions = 5
	spawn_positions = 5
	description = "You are the Brotherhood Knight, the veritable lifeblood of your organization. You are a versatile and adaptably trained person: from your primary duties of weapon & armor repair to basic combat, survival and stealth skills, the only thing you lack is proper experience. You are also in charge of Initiates."
	supervisors = "the Head and Knight-Sergeant, Senior and Head Scribes, Paladins and ultimately the Paladin Commander"
	display_order = JOB_DISPLAY_ORDER_KNIGHT
	outfit = /datum/outfit/job/bos/f13knight
	exp_requirements = 300

	access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/bos/f13initiate,
		),
		/datum/matchmaking_pref/disciple = list(
			/datum/job/bos/f13seniorknight,
		),
	)


/datum/outfit/job/bos/f13knight/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/AER9)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/AEP7)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_ca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_helm_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_rca_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_convert)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bos_riot_helm_convert)


/datum/outfit/job/bos/f13knight
	name = "Knight"
	jobtype = /datum/job/bos/f13knight
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood
	suit_store = /obj/item/gun/energy/laser/aer9
	mask = /obj/item/clothing/mask/gas/sechailer
	l_pocket = /obj/item/storage/belt/shoulderholster
	belt = /obj/item/storage/belt/army/assault
	head = /obj/item/clothing/head/helmet/f13/combat/brotherhood
	gunsmith_one = TRUE
	gunsmith_two = TRUE
	gunsmith_three = TRUE
	gunsmith_four = TRUE
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_one = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_two = 1,
		/obj/item/storage/box/bos = 1
		)
/*
/datum/outfit/loadout/knighte
	name = "Knight-Defender"
	backpack_contents = list(
		/obj/item/clothing/accessory/bos/knight = 1,
		/obj/item/gun/ballistic/automatic/r93 = 1,
		/obj/item/ammo_box/magazine/m556/rifle  = 2,
		/obj/item/gun/ballistic/automatic/pistol/ninemil = 1,
		/obj/item/ammo_box/magazine/m9mm = 2
		)

/datum/outfit/loadout/knightf
	name = "Knight-Cavalry"
	backpack_contents = list(
		/obj/item/clothing/accessory/bos/knight = 1,
		/obj/item/melee/powered/ripper = 1,
		/obj/item/shield/riot/bullet_proof = 1
		)
*/

/*
Initiate
*/

/datum/job/bos/f13initiate
	title = "Initiate"
	flag = F13INITIATE
	total_positions = 5
	spawn_positions = 5
	description = "Either recently inducted or born into the Brotherhood, you have since proven yourself worthy of assignment to the Chapter. You are to assist your superiors and receive training how they deem fit. You are NEVER allowed to leave the bunker without the direct supervision of a superior; doing so may result in exile."
	supervisors = "the Scribes, Knights and Paladins"
	display_order = JOB_DISPLAY_ORDER_INITIATE
	outfit = /datum/outfit/job/bos/f13initiate
	exp_requirements = 0

	loadout_options = list(
	/datum/outfit/loadout/initiatek, //Wattz and Engibelt with armor, helmet
	/datum/outfit/loadout/initiates, //chem knowledge
	)

	access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_BOS, ACCESS_ENGINE_EQUIP, ACCESS_ENGINE, ACCESS_HYDROPONICS, ACCESS_KITCHEN, ACCESS_BAR, ACCESS_SEC_DOORS)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/bos,
		),
		/datum/matchmaking_pref/disciple = list(
			/datum/job/bos/f13knight,
			/datum/job/bos/f13scribe,
		),
	)

/datum/outfit/job/bos/f13initiate
	name = "Initiate"
	jobtype = /datum/job/bos/f13initiate
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/survival = 1
		)

/*
/datum/outfit/job/bos/f13initiate/post_equip(mob/living/carbon/human/H, visualsOnly)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_SURGERY_LOW, src)
*/

/datum/outfit/loadout/initiatek
	name = "Knight-Aspirant"
	belt = /obj/item/storage/belt/utility
	suit = /obj/item/clothing/suit/armor/medium/combat/brotherhood
	head = /obj/item/clothing/head/helmet/f13/combat/brotherhood/initiate
	backpack_contents = list(
		/obj/item/gun/energy/laser/aer9 = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 2,
		/obj/item/clothing/accessory/bos/initiateK = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_one = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_two = 1
		)

/datum/outfit/loadout/initiates
	name = "Scribe-Aspirant"
	belt = /obj/item/storage/belt/medical
	suit = /obj/item/clothing/suit/toggle/labcoat
	glasses = /obj/item/clothing/glasses/science
	gloves = /obj/item/clothing/gloves/color/latex
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/book/granter/trait/chemistry = 1,
		/obj/item/clothing/accessory/bos/initiateS = 1
		)

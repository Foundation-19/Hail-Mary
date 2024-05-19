/datum/job/atlantic //do NOT use this for anything, it's just to store faction datums
	department_flag = ATLANTIC
	selection_color = "#ffeeaa"
	access = list(ACCESS_FOLLOWER)
	minimal_access = list(ACCESS_FOLLOWER)
	forbids = null
	enforces = "You are a member of the Atlantic Cross fleet. A fleet of hospital ship that helps people on the northen eastcoast. You are good people, but require payment."
	objectivesList = null

/datum/outfit/job/atlantic
	name =		"ATLANTICdatums"
	jobtype =	/datum/job/atlantic/
	shoes =		/obj/item/clothing/shoes/sneakers/black
	belt = /obj/item/kit_spawner/follower
	id =		null
	ears =		/obj/item/radio/headset/headset_town/medical
	uniform =	/datum/outfit/job/atlantic/f13followers

/datum/outfit/job/atlantic/f13followers
	name =		"Atlantic Cross"
	uniform =	/obj/item/clothing/under/f13/follower

/datum/outfit/job/atlantic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/set_vrboard/followers)

//datum/outfit/job/atlantic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
//	..()
//	if(visualsOnly)
//		return
	//ADD_TRAIT(H, TRAIT_TECHNOPHREAK, TRAIT_GENERIC)

/*
Administrator
*/
/datum/job/atlantic/f13atlanticcap
	title = "Atlantic Cross Doctor"
	flag = F13ATLANTICCAP
	department_flag = ATLANTIC
	head_announce = list("Security")
	faction = "Atlantic"
	total_positions = 1
	spawn_positions = 1
	supervisors = "You one of the many leaders of the Atlantic Cross. You are in charge. But it happends that a Fleet Captain have to come down. You also work with the dockmaster."
	description = "You are the captain of the ACS Aegis, and its escort. You make sure your hospital runs well, make sure people pay, make sure your doctors ain't doing mad shit or unethical things, provide education for the new people, organise the ressources of the ship. You also make sure there is no competition to your business, by sending Marines or Guards."
	enforces = "Based on a christan association, and remants of the navy, the Atlantic Cross tries to fight against drugs and slavery."
	selection_color = "#FF95FF"
	exp_requirements = 0

	outfit = /datum/outfit/job/atlantic/f13atlanticcap

	access = list(ACCESS_FOLLOWER, ACCESS_COMMAND, ACCESS_MILITARY, ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS)
	minimal_access = list(ACCESS_FOLLOWER, ACCESS_COMMAND, ACCESS_MILITARY, ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS)


/datum/outfit/job/atlantic/f13atlanticcap/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/stimpak/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/stimpak5/chemistry)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/rechargerpistol)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_MEDICALEXPERT, src)
	ADD_TRAIT(H, TRAIT_SURGERY_MID, src)

/datum/outfit/job/atlantic/f13atlanticcap
	name =	"Atlantic cap"
	jobtype =	/datum/job/atlantic/f13atlanticcap
	id =	/obj/item/card/id/silver
	chemwhiz =	TRUE
	uniform =	/obj/item/clothing/under/f13/atlantic/uniform/captain
	head = /obj/item/clothing/head/beret/atlantic
	suit= /obj/item/clothing/suit/armor/light/leather/rig
	shoes =	/obj/item/clothing/shoes/jackboots
	belt = /obj/item/kit_spawner/follower/admin
	backpack_contents = list(
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/gun/ballistic/automatic/pistol/automag = 1,
		/obj/item/ammo_box/magazine/m44/automag = 2,
		/obj/item/storage/survivalkit/medical/follower = 1,
		/obj/item/reagent_containers/medspray/synthflesh = 2,
		/obj/item/book/granter/trait/techno = 1,
		/obj/item/healthanalyzer/advanced = 1,
		/obj/item/storage/wallet/stash/high = 1,
		/obj/item/hypospray/mkii/CMO = 1
	)


/*
Doctor
*/
/datum/job/atlantic/f13atlanticdoc
	title = "Atlantic Cross Doctor"
	flag = F13ATLANTICDOC
	department_flag = ATLANTIC
	faction = "Atlantic"
	total_positions = 3
	spawn_positions = 3
	supervisors = "The Atlantic Cross Captain."
	description = "You are a doctor on board the Atlantic Cross Ship Aegis. Your goal is to help people."
	enforces = "Based on a christan association, and remants of the navy, the Atlantic Cross tries to fight against drugs and slavery. Don't forget to ask for a pay ! Revival is arround 100 caps, And healing people arround 50 caps. Why ? Maintaining those ship are a pain !."
	selection_color = "#FFDDFF"
	exp_requirements = 0

	outfit = /datum/outfit/job/atlantic/f13atlanticdoc
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/atlantic/f13atlanticdoc,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/atlantic/f13atlanticdoc,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/atlantic/f13followervolunteer,
		),
	)


/datum/outfit/job/atlantic/f13atlanticdoc/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
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
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/pico_manip)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_matter_bin)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/phasic_scanning)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/super_capacitor)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ultra_micro_laser)
	ADD_TRAIT(H, TRAIT_MEDICALGRADUATE, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_SURGERY_MID, src)
	ADD_TRAIT(H, TRAIT_CYBERNETICIST, src)

	//the follower practitioner doesn't need access because it's already set in the /datum/job/follower
	//personally, I don't think a practitioner should have more access than a volunteer.


/datum/outfit/job/atlantic/f13atlanticdoc
	name =	"Town Doctor"
	jobtype =	/datum/job/atlantic/f13atlanticdoc
	uniform =	/obj/item/clothing/under/f13/atlantic/sailor/sweater
	id =	/obj/item/card/id/silver
	chemwhiz =	TRUE
	backpack =	/obj/item/storage/backpack/medic
	belt = /obj/item/kit_spawner/follower/doctor
	satchel =	/obj/item/storage/backpack/satchel/med
	shoes = /obj/item/clothing/shoes/jackboots
	duffelbag =	/obj/item/storage/backpack/duffelbag/med
	backpack_contents = list(
		/obj/item/storage/survivalkit/medical/follower = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/reagent_containers/medspray/synthflesh = 1,
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/gun/energy/laser/complianceregulator = 1,
		/obj/item/storage/wallet/stash/mid = 1,
	)


/*
Follower Volunteer
*/

/datum/job/atlantic/f13atlanticsailor
	title = "Atlantic Cross Sailor"
	flag = F13ATLANTICSAILOR
	department_flag = ATLANTIC
	faction = "Atlantic"
	total_positions = 4
	spawn_positions = 4
	supervisors = "The Atlantic Cross captain, the Atlantic Cross Doctors, and the Atlantic Cross Marines."
	description = "You are one of the many sailors of the Atlantic Cross Fleet. Either born in fleet, or joined when they started good deeds. As a Sailor, you have options : Be guard, focusing more on defences. Be a nurse, assisting doctors. Be a Expeditioner, salvaging for the ship, and rescue people far from the coast. Or even somethings completly else. Obey the captain, doctors and the marines tho."
	enforces = "Based on a christan association, and remants of the navy, the Atlantic Cross tries to fight against drugs and slavery. Don't forget to ask for a pay ! Revival is arround 100 caps, And healing people arround 50 caps. Why ? Maintaining those ship are a pain !
	selection_color = "#FFDDFF"
	outfit = /datum/outfit/job/atlantic/f13atlanticsailor
	loadout_options = list(
	/datum/outfit/loadout/sailor_guard,
	/datum/outfit/loadout/sailor_expedition,
	/datum/outfit/loadout/sailor_nurse,
	/datum/outfit/loadout/sailor_student
	)
	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/atlantic/f13atlanticsailor,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/atlantic/f13atlanticsailor,
		),
		/datum/matchmaking_pref/disciple = list(
			/datum/job/atlantic/f13atlanticdoc,
		),
	)

	//the follower volunteer doesn't need more access as it is already stored in the /datum/job/atlantic

/datum/outfit/job/atlantic/f13atlanticsailor
	name = "Nurse"
	jobtype = /datum/job/atlantic/f13atlanticsailor
	id = 		/obj/item/card/id/silver
	belt = /obj/item/kit_spawner/follower
	uniform = 	/obj/item/clothing/under/f13/atlantic/sailor
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = 	/obj/item/storage/backpack/explorer
	satchel = 	/obj/item/storage/backpack/satchel/explorer
	backpack_contents =  list(
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/storage/wallet/stash/mid = 1,
	)

/datum/outfit/loadout/sailor_guard
	name = "Atlantic Cross Guard"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/vest/atlantic = 1,
		/obj/item/clothing/head/helmet/f13/combat/atlantic = 1,
		/obj/item/healthanalyzer = 1,
		/obj/item/reagent_containers/medspray/synthflesh = 1,
		/obj/item/gun/ballistic/rifle/salvaged_eastern_rifle = 1,
		/obj/item/ammo_box/a556/rubber = 1,
		/obj/item/ammo_box/a556 = 2,
	)

/datum/outfit/loadout/sailor_mechanic
	name =	"Mechanic"
	neck =	/obj/item/clothing/neck/apron/labor
	head =	/obj/item/clothing/head/hardhat/orange
	belt =	/obj/item/storage/belt/utility/full
	gloves =	/obj/item/clothing/gloves/color/yellow
	glasses =	/obj/item/clothing/glasses/welding
	backpack_contents = list(
		/obj/item/flashlight/pen = 1,
		/obj/item/reagent_containers/jerrycan,
	)

/datum/outfit/loadout/sailor_nurse
	name =	"Atlantic Cross Nurse"
	backpack_contents = list(
	/obj/item/healthanalyzer = 1,
	/obj/item/reagent_containers/medspray/synthflesh = 1,
	/obj/item/storage/firstaid/ancient = 1,
	/obj/item/clothing/under/f13/atlantic/sailor/nurse = 1, 
	)

/datum/outfit/loadout/sailor_student
	name = "Student"
	backpack_contents = list(
		/obj/item/taperecorder = 1,
		/obj/item/clothing/accessory/pocketprotector/full = 1,
		/obj/item/clipboard = 1,
		/obj/item/pen/fourcolor = 1,
		/obj/item/pda = 1,
	)


// AC MARINES

/datum/job/atlantic/f13atlanticmarines
	title = "Atlantic Cross Marines"
	flag = F13ATLANTICMARINES
	department_flag = ATLANTIC
	faction = "Atlantic"
	total_positions = 3
	spawn_positions = 3
	supervisors = "The Captain orders takes priority, but for town security, the Dockmaster and the Port Councelor."
	description = "You are a Atlantic Cross Marines. The elite soldiers of the fleet, that must defend town and the hospital ship, and also work for the interses of the Atlantic Cross."
	enforces = "Based on a christan association, and remants of the navy, the Atlantic Cross tries to fight against drugs and slavery."
	selection_color = "#FFDDFF"

	outfit = /datum/outfit/job/atlantic/f13atlanticmarines


	loadout_options = list(
		/datum/outfit/loadout/marines_ranged,
		/datum/outfit/loadout/marines_energy
	)
	
	access = list(ACCESS_FOLLOWER, ACCESS_MILITARY)
	minimal_access = list(ACCESS_FOLLOWER, ACCESS_MILITARY)

/datum/outfit/job/atlantic/f13atlanticmarines
	name =	"Atlantic Cross Marines"
	jobtype =	/datum/job/atlantic/f13atlanticmarines
	belt = /obj/item/kit_spawner/follower/guard
	id =	/obj/item/card/id/silver
	uniform =	/obj/item/clothing/under/f13/atlantic/uniform
	suit =	/obj/item/clothing/suit/armor/medium/combat/atlanticmarines
	head =	/obj/item/clothing/head/helmet/f13/atlanticmarines
	glasses =	/obj/item/clothing/glasses/sunglasses
	shoes =	/obj/item/clothing/shoes/combat
	l_pocket =	/obj/item/storage/belt/shoulderholster
	backpack =	/obj/item/storage/backpack/explorer
	satchel =	/obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/storage/survivalkit/medical/follower = 1,
		/obj/item/gun/energy/laser/complianceregulator = 1,
		/obj/item/flashlight/seclite = 1,
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2,
		/obj/item/storage/belt/army/followers = 1,
		/obj/item/storage/wallet/stash/mid = 1,
	)


/datum/outfit/loadout/guard_ranged
	name = "Rifle"
	suit_store = /obj/item/gun/ballistic/automatic/service/alr
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m556/rifle = 3,
		/obj/item/gun_upgrade/scope/watchman = 1,
	)

/datum/outfit/loadout/guard_energy
	name = "Laser"
	suit_store = /obj/item/gun/energy/laser/wattz2k
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc = 3,
	)


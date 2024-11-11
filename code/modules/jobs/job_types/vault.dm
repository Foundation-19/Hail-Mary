/*
Vault access doors
Overseer/Chief of security: 19 ACCESS_HEADS
Security: 1 ACCESS_SECURITY
General access: 31 ACCESS_CARGO
Engineering: 10, 11 ACCESS_ENGINE_EQUIP, ACCESS_ENGINE
Science: 47 ACCESS_RESEARCH
// here's a tip, go search DEFINES/access.dm
*/

// I swear to god stop copy-pasting you damn snowflakes
/datum/job/vault
	department_flag = VAULT
	exp_type = EXP_TYPE_VAULT
	faction = FACTION_VAULT

/datum/outfit/job/vault
	gloves = /obj/item/pda

/datum/outfit/job/vault/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/vault/v44,
		/obj/item/clothing/under/f13/vault/v44/half,
		/obj/item/clothing/under/f13/vault/v44/tribal,
		/obj/item/clothing/under/f13/vault/v44/tribal/female)

/datum/outfit/job/vault/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)


/*
Overseer
*/

/datum/job/vault/f13overseer
	title = "Overseer"
	flag = F13OVERSEER
	head_announce = list("Security")
	total_positions = 1 //was 1-1
	spawn_positions = 1
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations."
	description = "You are the leader of the Vault, and your word is law. Working with the Security team and your fellow Vault Dwellers, your goal is to ensure the continued prosperity and survival of the vault, through any and all means necessary."
	supervisors = "the God AI"
	selection_color = "#ccffcc"
	req_admin_notify = 1
	exp_requirements = 750

	outfit = /datum/outfit/job/vault/f13overseer

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_WEAPONS,ACCESS_FORENSICS_LOCKERS,
						ACCESS_MORGUE, ACCESS_MAINT_TUNNELS, ACCESS_ALL_PERSONAL_LOCKERS, ACCESS_MINING, ACCESS_MEDICAL,
						ACCESS_CARGO, ACCESS_HEADS, ACCESS_HOS, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_WEAPONS, ACCESS_FORENSICS_LOCKERS,
						ACCESS_MORGUE, ACCESS_ALL_PERSONAL_LOCKERS, ACCESS_MINING, ACCESS_MEDICAL, ACCESS_CARGO, ACCESS_HEADS,
						ACCESS_HOS, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_MINERAL_STOREROOM)

/datum/outfit/job/vault/f13overseer
	name = "Overseer"
	jobtype = /datum/job/vault/f13overseer

	implants = list(/obj/item/implant/mindshield)

	id = 			/obj/item/card/id/gold
	uniform = 		/obj/item/clothing/under/f13/vault/v44
	shoes = 		/obj/item/clothing/shoes/jackboots
	glasses = 		/obj/item/clothing/glasses/sunglasses
	ears = 			/obj/item/radio/headset/headset_overseer
	suit = 			/obj/item/clothing/suit/armor/light/duster/battlecoat/vault/overseer
	suit_store = 	/obj/item/gun/energy/laser/aer9/vault
	backpack = 		/obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/storage/box/ids = 1,
		/obj/item/gun/ballistic/automatic/pistol/n99/executive = 1,
		/obj/item/ammo_box/magazine/m10mm/adv/simple = 3,
		/obj/item/book/granter/trait/chemistry = 1,
		/obj/item/crowbar = 1)

/*
Head of Security
*/

/datum/job/vault/f13hos
	title = "Vault 44 Master Warrior"
	flag = F13HOS
	department_head = list("Overseer")
	department_flag = VAULT
	head_announce = list("Security")
	total_positions = 1 //was 1-1
	spawn_positions = 1
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations. Participation in special projects, as ordered by the God AI."
	description = "You answer directly to the God AI. You are tasked with organising the safety, security and readiness of the Tribe, as well as managing the warrior cast. It is also your duty to secure the Vault against outside invasion. At your discretion, you are encouraged to train capable dwellers in the usage of firearms and issue weapon permits accordingly."
	supervisors = "the God AI"
	selection_color = "#ccffcc"
	req_admin_notify = 1
	exp_requirements = 750

	outfit = /datum/outfit/job/vault/f13masterwarrior

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_WEAPONS,ACCESS_FORENSICS_LOCKERS,
						ACCESS_MORGUE, ACCESS_MAINT_TUNNELS, ACCESS_ALL_PERSONAL_LOCKERS, ACCESS_MINING, ACCESS_MEDICAL,
						ACCESS_CARGO, ACCESS_HEADS, ACCESS_HOS, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_WEAPONS, ACCESS_FORENSICS_LOCKERS,
						ACCESS_MORGUE, ACCESS_ALL_PERSONAL_LOCKERS, ACCESS_MINING, ACCESS_MEDICAL, ACCESS_CARGO, ACCESS_HEADS,
						ACCESS_HOS, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_MINERAL_STOREROOM)

/datum/outfit/job/vault/f13masterwarrior
	name = "Chief of Security"

	id = /obj/item/card/id/chief
	//pda
	ears = 			/obj/item/radio/headset/headset_vault_hos/alt
	uniform = 		/obj/item/clothing/under/f13/vault/v44/half
	shoes = 		/obj/item/clothing/shoes/jackboots
	suit = 			/obj/item/clothing/suit/armor/power_armor/vault
	suit_store = 	/obj/item/gun/energy/laser/aer9/vault
	head = 			/obj/item/clothing/head/helmet/f13/heavy/salvaged_pa/vault
	belt = 			/obj/item/storage/belt/army/security
	glasses = 		/obj/item/clothing/glasses/sunglasses
	r_hand =		/obj/item/gun/ballistic/automatic/pistol/n99
	r_pocket = 		/obj/item/assembly/flash/handheld
	l_pocket = 		/obj/item/restraints/handcuffs
	backpack = 		/obj/item/storage/backpack/security
	satchel = 		/obj/item/storage/backpack/satchel/sec
	duffelbag = 	/obj/item/storage/backpack/duffelbag/sec
	box = 			/obj/item/storage/box/security
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 2,
		/obj/item/stock_parts/cell/ammo/mfc = 3,
		/obj/item/ammo_box/magazine/m10mm/adv/simple = 2,
		/obj/item/crowbar = 1)

	implants = list(/obj/item/implant/mindshield)

/*
Medical Doctor
*/
/datum/job/vault/f13doctor
	title = "Vault 44 Shaman"
	flag = F13DOCTOR
	department_head = list("Overseer")
	total_positions = 2 //was 5-4
	spawn_positions = 2
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations. Participation in special projects, as ordered by the God AI."
	description = "You answer directly to the God AI. You are tasked with providing medical care to Vault Dwellers and ensuring the medical well-being of everyone in the Vault."
	supervisors = "the God AI"
	selection_color = "#ddffdd"

	outfit = /datum/outfit/job/vault/f13doctor

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CHEMISTRY, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CHEMISTRY, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO)

/datum/outfit/job/vault/f13doctor
	name = "Medical Doctor"
	jobtype = /datum/job/vault/f13doctor
	chemwhiz = TRUE
	//pda
	uniform = 		/obj/item/clothing/under/f13/vault13
	ears = 			/obj/item/radio/headset/headset_vault
	shoes = 		/obj/item/clothing/shoes/jackboots
	suit =			/obj/item/clothing/suit/armor/light/kit/punk/labcoat
	l_hand = 		/obj/item/storage/firstaid/regular
	suit_store = 	/obj/item/twohanded/spear/scrapspear
	backpack = 		/obj/item/storage/backpack/medic
	satchel = 		/obj/item/storage/backpack/satchel/med
	duffelbag = 	/obj/item/storage/backpack/duffelbag/med
	backpack_contents = list(
		/obj/item/crowbar = 1)

/datum/outfit/job/vault/f13doctor/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_MEDICALEXPERT, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_SURGERY_HIGH, src)

/*
Scientist
*/
/datum/job/vault/f13vaultscientist
	title = "Vault 44 Scientist"
	flag = F13VAULTSCIENTIST
	department_head = list("Overseer")
	total_positions = 2 //was 5-5
	spawn_positions = 2
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations. Participation in special projects, as ordered by the God AI."
	description = "You answer directly to the God AI. You are tasked with researching new technologies, conducting mining expeditions (with the approval of Security or the God AI), and upgrading the machinery of the Vault."
	supervisors = "the God AI"
	selection_color = "#ddffdd"

	outfit = /datum/outfit/job/vault/f13vaultscientist

	access = list(ACCESS_ROBOTICS, ACCESS_RESEARCH, ACCESS_MINERAL_STOREROOM, ACCESS_TECH_STORAGE, ACCESS_CARGO)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_RESEARCH, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO)

/datum/outfit/job/vault/f13vaultscientist
	name = "Scientist"
	jobtype = /datum/job/vault/f13vaultscientist
	chemwhiz = TRUE

	//pda
	uniform = 		/obj/item/clothing/under/f13/vault13
	ears = 			/obj/item/radio/headset/headset_vault
	shoes = 		/obj/item/clothing/shoes/jackboots
	suit_store = 	/obj/item/twohanded/spear/scrapspear
	suit =			/obj/item/clothing/suit/armor/light/kit/punk/labcoat
	backpack = 		/obj/item/storage/backpack/science
	satchel = 		/obj/item/storage/backpack/satchel/tox
	backpack_contents = list(/obj/item/crowbar = 1)

/datum/outfit/job/vault/f13vaultscientist/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_SURGERY_MID, src) //they need this for dissections

/*
Security Officer
*/
/datum/job/vault/f13officer
	title = "Vault 44 Warriors"
	flag = F13OFFICER
	department_head = list("Chief of Security")
	total_positions = 4 
	spawn_positions = 4 
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations. Participation in special projects, as ordered by the God AI."
	description = "You answer directly to the Master Warrior, and in their absence, the God AI. You are the first line of defense against civil unrest and outside intrusion. It is your duty to enforce the laws created by the God AI and proactively seek out potential threats to the safety of Vault residents."
	supervisors = "the Master Warrior"
	selection_color = "#ddffdd"
	exp_requirements = 300

	outfit = /datum/outfit/job/vault/f13vaultwarrior

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_WEAPONS,ACCESS_FORENSICS_LOCKERS,
						ACCESS_MORGUE, ACCESS_MAINT_TUNNELS, ACCESS_ALL_PERSONAL_LOCKERS, ACCESS_MINING, ACCESS_MEDICAL,
						ACCESS_CARGO, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_WEAPONS, ACCESS_FORENSICS_LOCKERS,
						ACCESS_MORGUE, ACCESS_ALL_PERSONAL_LOCKERS, ACCESS_MINING, ACCESS_MEDICAL, ACCESS_CARGO,
						ACCESS_MINERAL_STOREROOM)

/datum/outfit/job/vault/f13vaultwarrior
	name = "Vault-tec Security"
	id = /obj/item/card/id/sec
	//pda
	ears = 			/obj/item/radio/headset/headset_vaultsec
	uniform = 		/obj/item/clothing/under/f13/vault/v44/half
	head = 			/obj/item/clothing/head/helmet/riot/vaultsec
	suit =			/obj/item/clothing/suit/armor/medium/vest/bulletproof/armor
	glasses = 		/obj/item/clothing/glasses/sunglasses
	suit_store = 	/obj/item/gun/energy/laser/aer9/vault
	shoes = 		/obj/item/clothing/shoes/jackboots
	belt = 			/obj/item/storage/belt/army/security
	r_hand =		/obj/item/gun/ballistic/automatic/pistol/n99
	l_pocket = 		/obj/item/restraints/handcuffs
	r_pocket = 		/obj/item/assembly/flash/handheld
	backpack = 		/obj/item/storage/backpack/security
	satchel = 		/obj/item/storage/backpack/satchel/sec
	duffelbag = 	/obj/item/storage/backpack/duffelbag/sec
	box = 			/obj/item/storage/box/security
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 3,
		/obj/item/ammo_box/magazine/m10mm/adv/simple = 2,
		/obj/item/crowbar = 1)

	implants = list(/obj/item/implant/mindshield)


/*
Vault Engineer
*/

/datum/job/vault/f13vaultengineer
	title = "Vault 44 Engineer"
	flag = F13VAULTENGINEER
	department_head = list("Overseer")
	total_positions = 2 //was 4-4
	spawn_positions = 2
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations. Participation in special projects, as ordered by the God AI."
	description = "You answer directly to the God AI. You are tasked with overseeing the Reactor, maintaining Vault defenses and machinery, and engaging in construction projects to improve the Vault as a whole."
	supervisors = "the God AI"
	selection_color = "#ddffdd"

	outfit = /datum/outfit/job/vault/f13vaultengineer

	access = list(ACCESS_CARGO, ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_ATMOSPHERICS, ACCESS_TCOMSAT, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_CARGO, ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_MINERAL_STOREROOM)

/datum/outfit/job/vault/f13vaultengineer
	name = "Vault-tec Engineer"
	jobtype = /datum/job/vault/f13vaultengineer

	//pda
	ears = 			/obj/item/radio/headset/headset_vault
	uniform = 		/obj/item/clothing/under/f13/vault13
	belt = 			/obj/item/storage/belt/utility/full/engi
	shoes = 		/obj/item/clothing/shoes/sneakers/red
	head = 			/obj/item/clothing/head/hardhat
	r_pocket = 		/obj/item/t_scanner
	backpack = 		/obj/item/storage/backpack/industrial
	satchel = 		/obj/item/storage/backpack/satchel/eng
	duffelbag = 	/obj/item/storage/backpack/duffelbag/engineering
	box = 			/obj/item/storage/box/engineer
	backpack_contents = list(/obj/item/crowbar = 1)

/datum/job/vault/f13vaultDweller
	title = "Vault 44 Dweller"
	flag = ASSISTANT
	total_positions = 8 //was 12-11
	spawn_positions = 8
	forbids = "The Vault forbids: Disobeying the God AI. Deserting the Vault unless it is rendered unhospitable. Killing fellow Vault Dwellers. Betraying the Vault and its people."
	enforces = "The Vault expects: Contributing to Vault society. Adherence to Vault-tec Corporate Regulations. Participation in special projects, as ordered by the God AI."
	description = "You answer directly to the God AI, being assigned to fulfill whatever menial tasks are required. You lack an assignment, but may be given one the God AI if required or requested. You should otherwise busy yourself with assisting personnel with tasks around the Vault."
	supervisors = "absolutely everyone"
	selection_color = "#ddffdd"
	access = list()			
	minimal_access = list()	

	outfit = /datum/outfit/job/vault/f13vaultDweller

/datum/job/vault/f13vaultDweller/get_access()
	access = list(ACCESS_CARGO)
	minimal_access = list(ACCESS_CARGO)

/datum/outfit/job/vault/f13vaultDweller
	name = "Vault Dweller"
	jobtype = /datum/job/vault/f13vaultDweller
	backpack = 		/obj/item/storage/backpack/satchel/leather
	suit_store = 	/obj/item/twohanded/spear/scrapspear
	backpack_contents = list(/obj/item/crowbar = 1)

/datum/outfit/job/vault/f13vaultDweller/pre_equip(mob/living/carbon/human/H)
	..()
	if (CONFIG_GET(flag/grey_assistants))
		uniform = /obj/item/clothing/under/f13/vault13
		ears = /obj/item/radio/headset/headset_vault
		shoes = /obj/item/clothing/shoes/jackboots
	else
		uniform = /obj/item/clothing/under/f13/vault13
		ears = /obj/item/radio/headset/headset_vault
		shoes = /obj/item/clothing/shoes/jackboots


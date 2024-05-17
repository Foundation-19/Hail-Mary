//It looks like var/faction controls what becomes visible on setup. Should likely be fixed or something, but I'm not doing it.
/datum/job/enclave
	department_flag = ENCLAVE
	selection_color = "#323232"
	faction = FACTION_ENCLAVE
	exp_type = EXP_TYPE_ENCLAVE

	access = list(ACCESS_ENCLAVE)
	minimal_access = list(ACCESS_ENCLAVE)
	forbids = "Betraying your brothers and sisters."
	enforces = "Survive. Move on. Protect your home, the USS Eminent Domain. Try to good in the wasteland, or get revenge. Stay discret. Hide your past, many of you are still wanted."
	objectivesList = list("Admiral Torres advises the crew to survive and stay discret.")

/datum/outfit/job/enclave
	id = null
	ears = /obj/item/radio/headset/headset_enclave

/datum/outfit/job/enclave/peacekeeper
	id = /obj/item/card/id/dogtag/enclave/trooper
	mask = /obj/item/clothing/mask/gas/enclave
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack/enclave
	satchel = /obj/item/storage/backpack/satchel/enclave
	belt = /obj/item/storage/belt/army/assault/enclave
	uniform = /obj/item/clothing/under/f13/enclave/peacekeeper
	r_pocket = /obj/item/flashlight/seclite
	shoes = /obj/item/clothing/shoes/f13/enclave/serviceboots
	gloves = /obj/item/clothing/gloves/f13/military
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/survivalkit = 1,
		/obj/item/storage/survivalkit/medical = 1
	)

/datum/outfit/job/enclave/noncombat
	id = /obj/item/card/id/dogtag/enclave/noncombatant
	backpack = /obj/item/storage/backpack/enclave
	satchel = /obj/item/storage/backpack/satchel/enclave
	belt = /obj/item/storage/belt/army/assault/enclave
	uniform = /obj/item/clothing/under/f13/enclave/science
	r_pocket = /obj/item/flashlight/seclite
	shoes = /obj/item/clothing/shoes/f13/enclave/serviceboots
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
	)

/datum/outfit/job/enclave/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalradio)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/durathread_vest)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)

//Captain
/datum/job/enclave/enclavecpt
	title = "Enclave Captain"
	flag = F13USCPT
	total_positions = 0
	spawn_positions = 0
	access = list(ACCESS_ENCLAVE, ACCESS_CHANGE_IDS)
	display_order = JOB_DISPLAY_ORDER_F13USCPT
	description = "You are probably the last operating cell of the Enclave in the US, as far as you know. Now that the lore is out of the way, just make the round fun. You set the policies and the attitude of the Enclave this week."
	supervisors = "Enclave Department of the Army."
	outfit = /datum/outfit/job/enclave/peacekeeper/enclavecpt
	exp_requirements = 1500

/datum/outfit/job/enclave/peacekeeper/enclavecpt
	name = "Enclave Captain"
	jobtype = /datum/job/enclave/enclavecpt

	head = /obj/item/clothing/head/helmet/f13/enclave/officer
	uniform = /obj/item/clothing/under/f13/enclave/officer
	suit = /obj/item/clothing/suit/armor/medium/duster/enclave
	suit_store = /obj/item/gun/ballistic/automatic/fnfal
	accessory = /obj/item/clothing/accessory/ncr/CPT
	id = /obj/item/card/id/dogtag/enclave/officer
	ears = /obj/item/radio/headset/headset_enclave/command

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
		/obj/item/grenade/flashbang = 1,
		/obj/item/pda = 1,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/ammo_box/magazine/m308 = 2,
		/obj/item/gun/ballistic/automatic/pistol/deagle = 1,
		/obj/item/ammo_box/magazine/m44 = 2
		)

/datum/outfit/job/enclave/peacekeeper/enclavelt/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	if(H.mind)
		var/obj/effect/proc_holder/spell/terrifying_presence/S = new /obj/effect/proc_holder/spell/terrifying_presence
		H.mind.AddSpell(S)



//Lieutenant
/datum/job/enclave/enclavelt
	title = "Enclave Lieutenant"
	flag = F13USLT
	total_positions = 0
	spawn_positions = 0
	access = list(ACCESS_ENCLAVE, ACCESS_CHANGE_IDS)
	display_order = JOB_DISPLAY_ORDER_F13USLT
	description = "You are probably the last operating cell of the Enclave in the US, as far as you know. Now that the lore is out of the way, just make the round fun. You set the policies and the attitude of the Enclave this week."
	supervisors = "Enclave Department of the Army."
	outfit = /datum/outfit/job/enclave/peacekeeper/enclavelt
	exp_requirements = 1500

/datum/outfit/job/enclave/peacekeeper/enclavelt
	name = "Enclave Lieutenant"
	jobtype = /datum/job/enclave/enclavelt

	uniform = /obj/item/clothing/under/f13/enclave/officer
	suit = /obj/item/clothing/suit/armor/medium/duster/enclave
	suit_store = /obj/item/gun/ballistic/automatic/fnfal
	accessory = /obj/item/clothing/accessory/ncr/LT1
	id = /obj/item/card/id/dogtag/enclave/officer
	ears = /obj/item/radio/headset/headset_enclave/command

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 3,
		/obj/item/grenade/flashbang = 1,
		/obj/item/pda = 1,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/gun/energy/laser/plasma/glock = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2,
		/obj/item/ammo_box/magazine/m308 = 2
		)

/datum/outfit/job/enclave/peacekeeper/enclavelt/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)


//Sergeant

/datum/job/enclave/enclavesgt
	title = "Enclave Sergeant"
	flag = F13USSGT
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_F13USSGT
	description = "Entrusted with the command of the squads assigned to the bunker, your job is to assist the Lieutenant alongside the scientists."
	supervisors = "The Lieutenant and the Gunnery Sergeant."
	outfit = /datum/outfit/job/enclave/peacekeeper/enclavesgt
	exp_requirements = 1200

/datum/outfit/job/enclave/peacekeeper/enclavesgt
	name = "Enclave Sergeant"
	jobtype = /datum/job/enclave/enclavesgt
	suit = /obj/item/clothing/suit/armor/power_armor/advanced
	suit_store = /obj/item/gun/ballistic/automatic/lsw
	head = /obj/item/clothing/head/helmet/f13/power_armor/advanced
	accessory = /obj/item/clothing/accessory/enclave/sergeant

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/grenade/frag = 1,
		/obj/item/pda = 1,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/clothing/head/f13/enclave/peacekeeper = 1,
		/obj/item/ammo_box/magazine/m556/rifle = 3
		)

/datum/outfit/job/enclave/peacekeeper/enclavesgt/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_PA_WEAR, src)
	ADD_TRAIT(H, TRAIT_HARD_YARDS, src)

//corporal

/datum/job/enclave/enclavecpl
	title = "Enclave Corporal"
	flag = F13USCPL
	display_order = F13USCPL
	total_positions = 0
	spawn_positions = 0
	description = "Entrusted with the command of the squads assigned to the bunker, your job is to assist the Lieutenant alongside the scientists."
	supervisors = "The Lieutenant and the Gunnery Sergeant."
	outfit = /datum/outfit/job/enclave/peacekeeper/enclavecpl
	display_order = JOB_DISPLAY_ORDER_F13USCPL
	exp_requirements = 1200

/datum/outfit/job/enclave/peacekeeper/enclavecpl
	name = "Enclave Corporal"
	jobtype = /datum/job/enclave/enclavecpl
	head = /obj/item/clothing/head/helmet/f13/combat/swat
	suit = /obj/item/clothing/suit/armor/medium/combat/swat
	suit_store = /obj/item/gun/ballistic/automatic/assault_carbine
	accessory = /obj/item/clothing/accessory/enclave/specialist

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/grenade/frag = 1,
		/obj/item/pda = 1,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/clothing/head/f13/enclave/peacekeeper = 1,
		/obj/item/ammo_box/magazine/m5mm = 3
		)

/datum/outfit/job/enclave/peacekeeper/enclavecpl/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_HARD_YARDS, src)


//Specialist

/datum/job/enclave/f13specialist
	title = "Enclave Specialist"
	flag = F13USSPECIALIST
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_F13USSPC
	description = "You are an operative for the remnants of the Enclave. You, unlike the normal privates, have recieved specialist training in either engineering or medicine."
	supervisors = "The Lieutenant and the Sergeants."
	outfit = /datum/outfit/job/enclave/peacekeeper/f13specialist
	exp_requirements = 700

	loadout_options = list(
		/datum/outfit/loadout/combatmedic, // Medical Equipment
		/datum/outfit/loadout/combatengie, // Grenade Launcher
		)

/datum/outfit/job/enclave/peacekeeper/f13specialist
	name = "Enclave Specialist"
	jobtype = /datum/job/enclave/f13specialist
	suit = /obj/item/clothing/suit/armor/heavy/vest/bulletproof
	suit_store = /obj/item/gun/ballistic/automatic/smg/mp5
	accessory = /obj/item/clothing/accessory/enclave/specialist

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/pda = 1,
		/obj/item/ammo_box/magazine/uzim9mm = 2,
		/obj/item/melee/onehanded/knife/survival = 1
		)

/datum/outfit/loadout/combatmedic
	name = "Combat Medic"
	mask = /obj/item/clothing/mask/surgical
	gloves = /obj/item/clothing/gloves/color/latex/nitrile
	head = /obj/item/clothing/head/beret/enclave/science
	backpack_contents = list(
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/gun/medbeam = 1,
		/obj/item/book/granter/trait/chemistry = 1,
		/obj/item/book/granter/trait/midsurgery = 1
		)

/datum/outfit/loadout/combatengie
	name = "Combat Engineer"
	mask = /obj/item/clothing/mask/gas/welding
	gloves = /obj/item/clothing/gloves/color/yellow
	head = /obj/item/clothing/head/hardhat/orange
	suit_store = /obj/item/gun/ballistic/revolver/grenadelauncher
	backpack_contents = list(
		/obj/item/storage/belt/utility = 1,
		/obj/item/ammo_box/a40mm = 2,
		/obj/item/shovel/trench = 1
	)


//Private
/datum/job/enclave/enclavespy
	title = "Enclave Private"
	flag = F13USPRIVATE
	display_order = JOB_DISPLAY_ORDER_F13USPVT
	total_positions = 0
	spawn_positions = 0
	description = "You are an operative for the remnants of the Enclave. Obey your Lieutenant. He sets the Enclave's policies."
	supervisors = "The Lieutenant and the Sergeants"
	outfit = /datum/outfit/job/enclave/peacekeeper/enclavespy
	exp_type = EXP_TYPE_FALLOUT
	exp_requirements = 600

/datum/outfit/job/enclave/peacekeeper/enclavespy
	name = "Enclave Private"
	jobtype = /datum/job/enclave/enclavespy
	head = /obj/item/clothing/head/helmet/f13/combat/swat
	suit = /obj/item/clothing/suit/armor/medium/combat/swat
	suit_store =  /obj/item/gun/ballistic/automatic/assault_carbine/worn
	accessory = /obj/item/clothing/accessory/enclave

	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/grenade/smokebomb = 1,
		/obj/item/pda = 1,
		/obj/item/ammo_box/magazine/m5mm = 2,
		/obj/item/melee/onehanded/knife/survival = 1,
		)


//NON-COMBATANTS

//Scientist
/datum/job/enclave/enclavesci
	title = "Enclave Scientist"
	flag = F13USSCIENTIST
	display_order = JOB_DISPLAY_ORDER_F13USSCI
	total_positions = 0
	spawn_positions = 0
	description = "You're responsible for the maintenance of the base, the knowledge you've accumulated over the years is the only thing keeping the remnants alive. You've dabbled in enough to be considered a Professor in your field of research, but they call you Doctor. Support your dwindling forces and listen to the Lieutenant."
	supervisors = "Enclave Research and Development Division."
	outfit = /datum/outfit/job/enclave/noncombat/enclavesci
	exp_requirements = 1000

/datum/outfit/job/enclave/noncombat/enclavesci
	name = "Enclave Scientist"
	jobtype = /datum/job/enclave/enclavesci
	head = /obj/item/clothing/head/helmet/f13/envirosuit
	mask =/obj/item/clothing/mask/breath/medical
	gloves = /obj/item/clothing/gloves/color/latex/nitrile
	suit = /obj/item/clothing/suit/bio_suit/enclave
	belt = /obj/item/storage/belt/medical
	suit_store =  /obj/item/tank/internals/oxygen

	backpack_contents = list(
		/obj/item/storage/survivalkit/medical = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/grenade/chem_grenade/cleaner = 1,
		/obj/item/pda = 1,
		/obj/item/gun/ballistic/automatic/pistol/m1911 = 1,
		/obj/item/ammo_box/magazine/m45 = 3,
		/obj/item/melee/onehanded/knife/survival = 1,
		/obj/item/clothing/head/beret/enclave/science = 1,
		)

/datum/outfit/job/enclave/noncombat/enclavesci/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
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
	ADD_TRAIT(H, TRAIT_MEDICALEXPERT, src)
	ADD_TRAIT(H, TRAIT_CYBERNETICIST_EXPERT, src)
	ADD_TRAIT(H, TRAIT_SURGERY_HIGH, src)
	ADD_TRAIT(H, TRAIT_CHEMWHIZ, src)
	ADD_TRAIT(H, TRAIT_UNETHICAL_PRACTITIONER, src) // Brainwashing

//Last Americans
/datum/job/enclave/enclaveremnant
	title = "US Citizen Remnant"
	flag = F13USCIT
	display_order = JOB_DISPLAY_ORDER_F13USCIT
	total_positions = 7
	spawn_positions = 3
	description = "Don't get things wrong. The enclave is dead and burried. You are the one of the many childrens or survivors of the once feared organisations, now laying low and trying to survive. The last pillar of the enclave is now the Ship called the USS Eminent Domain, on the coast of the Californian Golf, in Mexico. More than a Ship, its your home. Military organisation are a thing of the past. You and the others are the last US citizens."
	supervisors = "The hierachy in place."
	outfit = /datum/outfit/job/enclave/enclaveremnant
	exp_type = EXP_TYPE_FALLOUT
	exp_requirements = 0

	loadout_options = list(
		/datum/outfit/loadout/encivilian,
		/datum/outfit/loadout/encrew,
		/datum/outfit/loadout/endoc,
		/datum/outfit/loadout/ensoldier,
		/datum/outfit/loadout/enofficer,
	)

/datum/outfit/job/enclave/enclaveremnant/pre_equip(mob/living/carbon/human/H)
	..()
	uniform = pick(
		/obj/item/clothing/under/f13/bodyguard, \
		/obj/item/clothing/under/f13/navy, \
		/obj/item/clothing/under/f13/exile/enclave, \
		/obj/item/clothing/under/f13/doctorm, \
		/obj/item/clothing/under/f13/combat, \
		/obj/item/clothing/under/f13/roving)
	shoes = /obj/item/clothing/shoes/f13/enclave/serviceboots
	ears = /obj/item/radio/headset/headset_enclave
	

/datum/outfit/job/enclave/enclaveremnant
	name = "US Citizen Remnant"
	jobtype = /datum/job/enclave/enclaveremnant
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/melee/onehanded/knife/survival = 1
	)

/datum/outfit/loadout/encivilian
	name = "Civilian"
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/ninemil = 1,
		/obj/item/ammo_box/magazine/m9mm/doublestack = 2,
		/obj/item/stack/f13Cash/caps/fivezero = 2,
		/obj/item/clothing/neck/apron/housewife = 1,
		/obj/item/reagent_containers/spray/cleaner = 1,
		/obj/item/fishingrod = 1
	)

/datum/outfit/loadout/encrew
	name = "Crewmember"
	backpack_contents = list(
		/obj/item/stack/f13Cash/caps/fivezero = 1,
		/obj/item/gun/ballistic/automatic/combat = 1,
		/obj/item/ammo_box/magazine/tommygunm45/stick = 2,
		/obj/item/clothing/under/f13/navy = 1,
		/obj/item/clothing/suit/armor/outfit/vest/utility = 1,
		/obj/item/storage/belt/utility/full = 1,
		/obj/item/clothing/head/f13/enclave/peacekeeper = 1
	)	

/datum/outfit/loadout/endoc
	name = "Doctor"
	backpack_contents = list(
		/obj/item/gun/energy/laser/wattzs = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2,
		/obj/item/stack/f13Cash/caps/fivezero = 1,
		/obj/item/clothing/under/f13/navy = 1,
		/obj/item/clothing/suit/armor/medium/duster/follower = 1,
		/obj/item/book/granter/trait/midsurgery = 1,
		/obj/item/storage/belt/medical/surgery_belt_adv = 1,
		/obj/item/storage/box/medicine/stimpaks/stimpaks5 = 1,
		/obj/item/clipboard = 1,
		/obj/item/pen = 1,
		/obj/item/clothing/head/beret/enclave/science = 1
	)	

/datum/outfit/loadout/ensoldier
	name = "Soldier"
	backpack_contents = list(
		/obj/item/gun/energy/laser/aer9/focused = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 2,
		/obj/item/clothing/under/f13/navy = 1,
		/obj/item/clothing/suit/armor/medium/vest/enclave = 1,
		/obj/item/clothing/head/helmet/f13/combat = 1
	)

/datum/outfit/loadout/enofficer
	name = "Officer"
	backpack_contents = list(
		/obj/item/clothing/under/f13/navy/officer = 1,
		/obj/item/clothing/suit/armor/light/duster/autumn = 1,
		/obj/item/clothing/head/helmet/f13/enclave/officer = 1,
		/obj/item/clothing/head/beret/enclave = 1,
		/obj/item/gun/energy/laser/wattzs = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2
	)

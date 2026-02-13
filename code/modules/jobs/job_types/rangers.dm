/*
Ranger Design Notes:
Trail Carbine + .45 for all rangers outside of the veteran.
*/


/datum/job/ranger //do NOT use this for anything, it's just to store faction datums
	department_flag = RANGER
	selection_color = "#f3c400"
	faction = FACTION_RANGER
	exp_type = EXP_TYPE_RANGER

	access = list(ACCESS_NCR)
	minimal_access = list(ACCESS_NCR)
	forbids = "The NCR Rangers forbids: Chem and drug use such as jet or alcohol while on duty. Execution of unarmed or otherwise subdued targets without authorisation."
	enforces = "The NCR Rangers expects: Obeying the lawful orders of superiors. Proper treatment of prisoners.  Good conduct within the Republic's laws. Wearing the uniform."
	objectivesList = list("Leadership recommends the following goal for this week: Establish an outpost at the radio tower","Leadership recommends the following goal for this week: Neutralize and capture dangerous criminals", "Leadership recommends the following goal for this week: Free slaves and establish good relations with unaligned individuals.")

/datum/outfit/job/ranger
	name = "rangersdatums"
	jobtype = /datum/job/ncr
	backpack = /obj/item/storage/backpack/trekker
	satchel = /obj/item/storage/backpack/satchel/trekker
	ears = /obj/item/radio/headset/headset_ranger
	uniform	= /obj/item/clothing/under/f13/ranger/trail
	belt = /obj/item/storage/belt/army/assault/ncr
	neck = /obj/item/storage/belt/shoulderholster
	shoes = /obj/item/clothing/shoes/f13/military/ncr
	l_pocket = /obj/item/book/manual/ncr/jobguide
	box = /obj/item/storage/survivalkit
	box_two = /obj/item/storage/survivalkit/medical

/datum/outfit/job/ranger/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/ncrgate)

// VETERAN RANGER

/datum/job/ranger/f13vetranger
	title = "NCR Veteran Ranger"
	flag = F13VETRANGER
	total_positions = 1
	spawn_positions = 1
	description = "You answer directly to the Captain, working either independently or in a team to complete your mission objectives however required, operating either alone, in a squad or with the NCR Army. Your primary mission is to improve general opinion of the Republic and to neutralize slavers and raiders operating in the area."
	supervisors = "NCRA Captain, High Command"
	selection_color = "#f3c400"
	display_order = JOB_DISPLAY_ORDER_VETRANGE
	access = list(ACCESS_NCR, ACCESS_NCR_ARMORY, ACCESS_NCR_COMMAND)
	outfit = /datum/outfit/job/ranger/f13vetranger
	exp_requirements = 1800

	min_required_special = list(
		"special_c" = 4,
		)

/datum/outfit/job/ranger/f13vetranger/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_SILENT_STEP, src)
	ADD_TRAIT(H, TRAIT_FAST_PUMP, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	var/datum/martial_art/rangertakedown/RT = new
	RT.teach(H)

/datum/outfit/job/ranger/f13vetranger
	name = "NCR Veteran Ranger"
	jobtype	= /datum/job/ranger/f13vetranger
	id = /obj/item/card/id/dogtag/ncrvetranger
	uniform	= /obj/item/clothing/under/f13/ranger/vet
	suit = /obj/item/clothing/suit/armor/rangercombat
	head = /obj/item/clothing/head/helmet/f13/ncr/rangercombat
	gloves = /obj/item/clothing/gloves/rifleman
	shoes =	/obj/item/clothing/shoes/f13/military/leather
	glasses	= /obj/item/clothing/glasses/sunglasses
	neck = /obj/item/storage/belt/shoulderholster/ranger4570
	ears = /obj/item/radio/headset/headset_ranger
	mask = /obj/item/clothing/mask/gas/ranger
	suit_store =	/obj/item/gun/ballistic/rifle/repeater/cowboy
	box = /obj/item/storage/survivalkit
	box_two = /obj/item/storage/survivalkit/medical
	r_pocket = /obj/item/binoculars
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bowie = 1,
	//	/obj/item/storage/bag/money/small/ncrofficers = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak/super = 1,
		/obj/item/stack/medical/gauze/bloodleaf = 2,
		/obj/item/grenade/smokebomb = 1
		)


// NCR Patrol Ranger

/datum/job/ranger/f13rangerpatrol
	title = "NCR Patrol Ranger"
	flag = F13PATROLRANGER
	total_positions = 3
	spawn_positions = 3
	description = "As an NCR Ranger, you are the premier special forces unit of the NCR. You are the forward observations and support the Army in it's campaigns, as well as continuing the tradition of stopping slavery in it's tracks."
	supervisors = "Veteran Ranger"
	selection_color = "#fff5cc"
	display_order = JOB_DISPLAY_ORDER_PATROLRANGER
	outfit = /datum/outfit/job/ranger/f13rangerpatrol
	exp_requirements = 600

/datum/outfit/job/ranger/f13rangerpatrol/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIGHT_STEP, src)
	ADD_TRAIT(H, TRAIT_FAST_PUMP, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	var/datum/martial_art/rangertakedown/RT = new
	RT.teach(H)


/datum/outfit/job/ranger/f13rangerpatrol
	name = "NCR Parol Ranger"
	jobtype	=		/datum/job/ranger/f13rangerpatrol
	id =			/obj/item/card/id/dogtag/ncrranger
	uniform	=		/obj/item/clothing/under/f13/ranger/patrol
	suit =			/obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol
	head =			/obj/item/clothing/head/helmet/f13/combat/ncr_patrol
	gloves =		/obj/item/clothing/gloves/patrol
	shoes =			/obj/item/clothing/shoes/f13/military/leather
	glasses	=		/obj/item/clothing/glasses/sunglasses
	ears =			/obj/item/radio/headset/headset_ranger
	r_pocket = 		/obj/item/binoculars
	suit_store =	/obj/item/gun/ballistic/rifle/repeater/trail
	neck = 			/obj/item/storage/belt/shoulderholster/ranger45
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
	//	/obj/item/storage/bag/money/small/ncrofficers = 1,
		/obj/item/clothing/mask/gas/ranger = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/stack/medical/gauze/bloodleaf = 2,
		/obj/item/grenade/smokebomb = 1
		)


//NCR Scout Ranger
/datum/job/ranger/f13rangerscout
	title = "NCR Scout Ranger"
	flag = F13RANGERSCOUT
	total_positions = 2
	spawn_positions = 2
	description = "As a Scout Ranger, you perform reconnaissance and assist in special operations for the Republic. Your reason for being sent here is to identify and neutralize threats to the Republic and to assist Patrol Rangers in identifying slavers and raiders so that they can be brought to justice."
	supervisors = "Veteran Ranger"
	selection_color = "#fff5cc"
	display_order = JOB_DISPLAY_ORDER_SCOUTRANGER
	exp_type = EXP_TYPE_FALLOUT
	exp_requirements = 360

	outfit = /datum/outfit/job/ranger/f13rangerscout

/datum/outfit/job/ranger/f13rangerscout/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIGHT_STEP, src)
	ADD_TRAIT(H, TRAIT_FAST_PUMP, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	var/datum/martial_art/rangertakedown/RT = new
	RT.teach(H)

/datum/outfit/job/ranger/f13rangerscout
	name = "NCR Scout Ranger"
	jobtype = 		/datum/job/ranger/f13rangerscout
	id = 			/obj/item/card/id/dogtag/ncrranger
	uniform = 		/obj/item/clothing/under/f13/ranger/trail
	suit =			/obj/item/clothing/suit/toggle/armor/rangerrecon
	gloves = 		/obj/item/clothing/gloves/color/latex/nitrile
	shoes = 		/obj/item/clothing/shoes/f13/military/leather
	glasses = 		/obj/item/clothing/glasses/sunglasses
	head =			/obj/item/clothing/head/beret/ncr_recon_ranger
	ears =			/obj/item/radio/headset/headset_ranger
	r_pocket = 		/obj/item/binoculars
	suit_store =	/obj/item/gun/ballistic/rifle/repeater/trail
	neck = 			/obj/item/storage/belt/shoulderholster/ranger45
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
	//	/obj/item/storage/bag/money/small/ncrofficers = 1,
		/obj/item/clothing/mask/gas/ranger = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/stack/medical/gauze/bloodleaf = 2,
		/obj/item/grenade/smokebomb = 1
		)

// Specialist Rangers

//NCR Medic Ranger
/datum/job/ranger/f13rangermedic
	title = "NCR Medic Ranger"
	flag = F13RANGERMEDIC
	total_positions = 2
	spawn_positions = 2
	description = "As a Medic Ranger, you perform medical duties in special operations for the Republic."
	supervisors = "Veteran Ranger"
	selection_color = "#fff5cc"
	display_order = JOB_DISPLAY_ORDER_MEDICRANGER
	exp_requirements = 900

	outfit = /datum/outfit/job/ranger/f13rangermedic

/datum/outfit/job/ranger/f13rangermedic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
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
	ADD_TRAIT(H, TRAIT_SURGERY_MID, src)
	ADD_TRAIT(H, TRAIT_LIGHT_STEP, src)
	ADD_TRAIT(H, TRAIT_FAST_PUMP, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	var/datum/martial_art/rangertakedown/RT = new
	RT.teach(H)


/datum/outfit/job/ranger/f13rangermedic
	name = "NCR Medic Ranger"
	jobtype = /datum/job/ranger/f13rangermedic
	id = 			/obj/item/card/id/dogtag/ncrranger
	uniform = 		/obj/item/clothing/under/f13/ranger/trail
	suit =			/obj/item/clothing/suit/armor/trailranger
	gloves = 		/obj/item/clothing/gloves/color/latex/nitrile
	r_hand = 		/obj/item/storage/backpack/duffelbag/med/surgery
	shoes = 		/obj/item/clothing/shoes/f13/military/leather
	glasses = 		/obj/item/clothing/glasses/hud/health/sunglasses
	head =			/obj/item/clothing/head/f13/trailranger
	ears =			/obj/item/radio/headset/headset_ranger
	mask = 			/obj/item/clothing/mask/surgical
	r_pocket = 		/obj/item/binoculars
	suit_store =	/obj/item/gun/ballistic/rifle/repeater/trail
	accessory = 	/obj/item/clothing/accessory/armband/med/ncr
	neck = 			/obj/item/storage/belt/shoulderholster/ranger45
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
	//	/obj/item/storage/bag/money/small/ncrofficers = 1,
		/obj/item/clothing/mask/gas/ranger = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/stack/medical/gauze/bloodleaf = 2,
		/obj/item/storage/firstaid/regular = 1
		)

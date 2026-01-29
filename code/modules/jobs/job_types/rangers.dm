/*
NCRA/RANGERS Design notes:
Standard issue stuff to keep the theme visually and gameplay and avoid watering down.
Gloves		Officers - Leather glovesl, fingerless leather gloves for sergeants. Bayonet standard issue knife. Sidearms mostly for officers, 9mm is the standard. MP gets nonstandard pot helm, the exception to prove the rule.
			NCOs -		Fingerless gloves
			Rest -		No gloves
Knives		Army -		Bayonet
			Ranger -	Bowie knife
Money		Commanding Officer (LT and CAP) - "small" money bag
			Officers and Rangers - /obj/item/storage/bag/money/small/ncrofficers
			Rest - /obj/item/storage/bag/money/small/ncrenlisted
Sidearm		Officers & a few specialists - 9mm pistol
Weapons		Service Rifle, Grease Gun, 9mm pistol, all good.
			Don't use Greaseguns, Lever shotguns, Police shotguns, Berettas, Hunting knives
*/

/datum/job/ranger //do NOT use this for anything, it's just to store faction datums
	department_flag = RANGER
	selection_color = "#f3c400"
	faction = FACTION_RANGER
	exp_type = EXP_TYPE_NCR

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
	exp_requirements = 1750

	loadout_options = list( // ALL: Binoculars, Bowie knife
		/datum/outfit/loadout/vrclassic, // Sequoia
		/datum/outfit/loadout/vrlite, // Brush
		/datum/outfit/loadout/vrshotgunner, // Unique Lever-Action
		/datum/outfit/loadout/vrcqc // 2 x .45 Long colt revolvers
		)

	min_required_special = list(
		"special_c" = 4,
		)

/datum/outfit/job/ranger/f13vetranger/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_SILENT_STEP, src)
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
	neck = /obj/item/storage/belt/shoulderholster
	ears = /obj/item/radio/headset/headset_ranger
	mask = /obj/item/clothing/mask/gas/ranger
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

/datum/outfit/loadout/vrclassic
	name = "The Classic"
	suit_store = /obj/item/gun/ballistic/revolver/sequoia
	backpack_contents = list(
		/obj/item/ammo_box/c4570box = 3,
		/obj/item/ammo_box/c4570box/knockback = 1
		)

/datum/outfit/loadout/vrlite
	name = "The Rifleman"
	suit_store = /obj/item/gun/ballistic/rifle/repeater/brush
	backpack_contents = list(
		/obj/item/ammo_box/c4570 = 3,
		/obj/item/book/granter/trait/rifleman = 1,
		)

/datum/outfit/loadout/vrshotgunner
	name = "The Shotgunner"
	suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat/shotgunlever/stock
	backpack_contents = list(
		/obj/item/ammo_box/shotgun/buck = 3,
		/obj/item/ammo_box/shotgun/trainshot = 1
		)

/datum/outfit/loadout/vrcqc
	name = "The Gunslinger"
	mask = /obj/item/clothing/mask/cigarette/cigar/havana
	backpack_contents = list(
		/obj/item/book/granter/trait/gunslinger = 1,
		/obj/item/gun/ballistic/revolver/revolver45/gunslinger = 2,
		/obj/item/ammo_box/a45lcbox = 1,
		/obj/item/lighter = 1
		)


// NCR Ranger

/datum/job/ranger/f13ranger
	title = "NCR Ranger"
	flag = F13RANGER
	total_positions = 2
	spawn_positions = 2
	description = "As an NCR Ranger, you are the premier special forces unit of the NCR. You are the forward observations and support the Army in it's campaigns, as well as continuing the tradition of stopping slavery in it's tracks."
	supervisors = "Veteran Ranger"
	selection_color = "#f3c400"
	display_order = JOB_DISPLAY_ORDER_RANGER
	outfit = /datum/outfit/job/ranger/f13ranger
	exp_requirements = 500

	loadout_options = list( // ALL: Binoculars, Bowie knife
	/datum/outfit/loadout/rangerrecon, // DKS Sniper rifle, .45 Revolver
	/datum/outfit/loadout/rangertrail, // Trail Carbine, 2 x .357 Revolvers
	/datum/outfit/loadout/rangerpatrolcqb, // Lever-Action Shotgun, .44 Snubnose revolver
	)

/datum/outfit/job/ranger/f13ranger/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIGHT_STEP, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	var/datum/martial_art/rangertakedown/RT = new
	RT.teach(H)


/datum/outfit/job/ranger/f13ranger
	name = "NCR Ranger"
	jobtype	= /datum/job/ranger/f13ranger
	id = /obj/item/card/id/dogtag/ncrranger
	uniform	= /obj/item/clothing/under/f13/ranger/trail
	head = /obj/item/clothing/head/f13/trailranger
	gloves = /obj/item/clothing/gloves/patrol
	shoes = /obj/item/clothing/shoes/f13/military/leather
	glasses	= /obj/item/clothing/glasses/sunglasses
	ears = /obj/item/radio/headset/headset_ranger
	r_pocket = /obj/item/binoculars
	neck = /obj/item/storage/belt/shoulderholster
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 1,
		/obj/item/melee/onehanded/knife/bowie = 1,
	//	/obj/item/storage/bag/money/small/ncrofficers = 1,
		/obj/item/clothing/mask/gas/ranger = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/stack/medical/gauze/bloodleaf = 2,
		/obj/item/grenade/smokebomb = 1
		)

/datum/outfit/loadout/rangerrecon
	name = "Recon Ranger"
	suit = /obj/item/clothing/suit/toggle/armor/rangerrecon
	belt = /obj/item/storage/belt/military/reconbandolier
	head = /obj/item/clothing/head/beret/ncr_recon_ranger
	neck = /obj/item/clothing/neck/mantle/ranger
	suit_store = /obj/item/gun/ballistic/automatic/marksman/sniper/sniperranger
	backpack_contents = list(
		/obj/item/ammo_box/magazine/w3006 = 3,
		/obj/item/gun/ballistic/revolver/colt357 = 1,
		/obj/item/ammo_box/a357 = 2
		)

/datum/outfit/loadout/rangertrail
	name = "Trail Ranger"
	suit = /obj/item/clothing/suit/armor/trailranger
	belt = /obj/item/storage/belt/military/NCR_Bandolier
	neck = /obj/item/clothing/neck/mantle/ranger
	suit_store = /obj/item/gun/ballistic/rifle/repeater/trail
	backpack_contents = list(
		/obj/item/ammo_box/m44box = 1,
		/obj/item/gun/ballistic/revolver/colt357 = 1,
		/obj/item/ammo_box/a357 = 2
		)

/datum/outfit/loadout/rangerpatrolcqb
	name = "Patrol Ranger"
	suit = /obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol
	head = /obj/item/clothing/head/f13/ranger
	uniform	= /obj/item/clothing/under/f13/ranger/patrol
	belt = /obj/item/storage/belt/army/assault/ncr
	suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat/shotgunlever/stock
	backpack_contents = list(
		/obj/item/ammo_box/shotgun/buck = 2,
		/obj/item/clothing/head/helmet/f13/combat/ncr_patrol = 1,
		/obj/item/gun/ballistic/revolver/colt357 = 1,
		/obj/item/ammo_box/a357 = 2
		)

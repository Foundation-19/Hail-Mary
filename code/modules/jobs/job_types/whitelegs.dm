/*
White Legs Design Notes:
Sidearms are 45mm.
*/

/datum/job/whitelegs
	department_flag = WHITELEGS
	selection_color = "#8e7272"
	faction = FACTION_WHITELEGS

	forbids = "Your tribe forbids: Hunting, gathering, fishing, farming, shoes, strenuous thinking."
	enforces = "Your tribe desires: Glory, plunder, the approval of Caesar, the death of the Kuna-man, food, comfort and ease."
	objectivesList = list("Sack the New Canaanite temple, bring their golden statue home to your camp.","Sack the 80s' compound, seize or destroy their precious war buggies.","Sack the NCR embassy, present their flags as gifts to the esteem representatives of Caesar.")
	exp_type = EXP_TYPE_WHITELEGS

	access = list(ACCESS_LEGION)
	minimal_access = list(ACCESS_LEGION)

	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/whitelegs,
			/datum/job/CaesarsLegion,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/eighties,
			/datum/job/latterdaysaints,
		),
		/datum/matchmaking_pref/patron = list(
			/datum/job/CaesarsLegion,
		),
		/datum/matchmaking_pref/outlaw = list(
			/datum/job/latterdaysaints,
			/datum/job/wasteland/f13wastelander,
		),
		/datum/matchmaking_pref/bounty_hunter = list(
			/datum/job/wasteland,
			/datum/job/latterdaysaints,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/CaesarsLegion,
		),
	)

/datum/outfit/job/whitelegs
	belt = /obj/item/storage/belt/military/legion
	id = /obj/item/card/id/whiteleg
	shoes = /obj/item/clothing/shoes/f13/whitelegshoes	// NO shoes NO shirt NO service
	l_pocket = /obj/item/flashlight/flare/torch
	r_pocket = /obj/item/radio/whiteleg
	backpack = /obj/item/storage/backpack/trekker
	satchel = /obj/item/storage/backpack/satchel/trekker
	backpack_contents = list(
		/obj/item/reagent_containers/pill/healingpowder = 1,
		/obj/item/restraints/handcuffs/sinew = 1,
		//obj/item/storage/wallet/stash = 1,
		/obj/item/reagent_containers/food/drinks/bottle/f13nukacola = 1,
		/obj/item/clothing/mask/bandana/gold = 1,
		)


/datum/outfit/job/whitelegs/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	if(H.gender == FEMALE)
		uniform = /obj/item/clothing/under/f13/female/whitelegs

	if(H.gender == MALE)
		uniform = /obj/item/clothing/under/f13/whitelegs

/datum/outfit/job/whitelegs/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TRIBAL, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_LIGHT_STEP, src)
	ADD_TRAIT(H, TRAIT_FREERUNNING, src)
	H.dna.add_mutation(WHITELEGLANGUAGE)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/whitelegs/lightarmour)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/whitelegs/armour)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/whitelegs/heavyarmour)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/whitelegs/garb)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/whitelegs/femalegarb)
	H.underwear = "Nude"
	H.undershirt = "Nude"
	H.socks = "Nude"
	H.warpaint = "whitelegs-[H.gender]"
	H.warpaint_color = "#FFFFFF"
	H.update_body()

/datum/job/whitelegs/f13warchief
	title = "War Chief"
	flag = F13WARCHIEF
	head_announce = list("Security")
	supervisors = "the annals of history"
	description = "Your people have long lived off robbing the trade that flowed through the I-80, favoring it over the less glorious ways of hunting and gathering, or confusing methods like farming. However, your tribe has proven to be too good at warfare and your recent successes against the New Canaanites have brought that trade to a halt, jeopardizing your future. Caesar is wise and his lands are rich, and he has offered to let the White Legs join the Legion if they aid him against his enemies. Lead your people to victory once more. Tihda yoo sinhai, baika-dems!"
	total_positions = 1
	spawn_positions = 1
	selection_color = "#7a3f3f"
	outfit = /datum/outfit/job/whitelegs/f13warchief
	display_order = JOB_DISPLAY_ORDER_WARCHIEF
	access = list(ACCESS_LEGION, ACCESS_CHANGE_IDS, ACCESS_LEGION_COMMAND)
	minimal_access = list(ACCESS_LEGION, ACCESS_CHANGE_IDS, ACCESS_LEGION_COMMAND)

	loadout_options = list(
		/datum/outfit/loadout/powerfist,	// i can't believe you've done this
		/datum/outfit/loadout/osmanoglu,	// shishkebab
		)

/datum/outfit/job/whitelegs/f13warchief/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	ADD_TRAIT(H, TRAIT_IRONFIST, src)
	ADD_TRAIT(H, TRAIT_BIG_LEAGUES, src)
	if(H.mind)
		var/obj/effect/proc_holder/spell/terrifying_presence/S = new /obj/effect/proc_holder/spell/terrifying_presence
		H.mind.AddSpell(S)

/datum/outfit/job/whitelegs/f13warchief
	name = "War Chief"
	jobtype = /datum/job/whitelegs/f13warchief
	suit = /obj/item/clothing/suit/armor/heavy/tribal/whitelegs
	head = /obj/item/clothing/head/helmet/f13/wayfarer/shamanred
	box = /obj/item/storage/survivalkit/tribal/chief
	backpack = /obj/item/storage/backpack/satchel/bone

/datum/outfit/loadout/powerfist
	name = "Headturner"
	gloves = /obj/item/melee/powerfist/f13/
	suit_store = /obj/item/storage/backpack/spearquiver
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/buffout = 1,
		/obj/item/clothing/gloves/bracer = 1,
		/obj/item/gun/ballistic/automatic/smg/smg10mm = 1,
		/obj/item/ammo_box/magazine/m10mm/adv/ext = 2,
		)

/datum/outfit/loadout/osmanoglu
	name = "Firestarter"
	gloves = /obj/item/clothing/gloves/bracer
	suit_store = /obj/item/storage/backpack/spearquiver
	backpack_contents = list(
		/obj/item/shishkebabpack = 1,
		/obj/item/gun/ballistic/automatic/smg/smg10mm = 1,
		/obj/item/ammo_box/magazine/m10mm/adv/ext = 2,
		/obj/item/reagent_containers/food/drinks/bottle/molotov/filled = 3,
		)


/*--------------------------------------------------------------*/

/datum/job/whitelegs/f13lightbringer
	title = "Light-bringer"
	flag = F13LIGHTBRINGER
	total_positions = 2
	spawn_positions = 2
	description = "You are the kuna-boomber. You boomb kunas. Your role in battle is to soften up your enemies and their defenses with the wide variety of improvised explosive devices at your disposal. Though your tribe shuns industry, or perhaps can't understand it, you have the rare talent of making explosives. Just remember to stand back."
	supervisors = "your War Chief"
	display_order = JOB_DISPLAY_ORDER_LIGHTBRINGER
	outfit = /datum/outfit/job/whitelegs/f13lightbringer

	access = list(ACCESS_LEGION)
	minimal_access = list(ACCESS_LEGION)

/datum/outfit/job/whitelegs/f13lightbringer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TECHNOPHOBE, src)
	ADD_TRAIT(H, TRAIT_EXPLOSIVE_CRAFTING, src)

/datum/outfit/job/whitelegs/f13lightbringer
	name = "Light-bringer"
	jobtype = /datum/job/whitelegs/f13lightbringer
	box = /obj/item/storage/survivalkit/tribal
	suit = /obj/item/clothing/suit/armor/heavy/tribal/whitelegs
	suit_store = /obj/item/gun/ballistic/automatic/m1carbine
	satchel = /obj/item/storage/backpack/satchel/bone
	backpack = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bone = 1,
		/obj/item/ammo_box/magazine/m10mm/adv = 2,
		/obj/item/reagent_containers/food/drinks/bottle/molotov/filled = 1,
		/obj/item/grenade/homemade/firebomb = 1,
		/obj/item/grenade/f13/dynamite = 1,
		)


/*--------------------------------------------------------------*/

/datum/job/whitelegs/f13sapper
	title = "Sapper"
	flag = F13SAPPER
	total_positions = 2
	spawn_positions = 2
	description = "You are an unusually handy White Leg. A quiet click and a loud scream, your traps can humble even the strongest opponent, incapacitating them while you move in for the kill. Your grasp of technology is second to none within your tribe, and it's thanks to you that the lifespan of each Storm Drum is as long as it is."
	supervisors = "your War Chief"
	display_order = JOB_DISPLAY_ORDER_SAPPER
	outfit = /datum/outfit/job/whitelegs/f13sapper

	access = list(ACCESS_LEGION, ACCESS_CHANGE_IDS, ACCESS_LEGION_COMMAND)
	minimal_access = list(ACCESS_LEGION, ACCESS_CHANGE_IDS, ACCESS_LEGION_COMMAND)

/datum/outfit/job/whitelegs/f13sapper/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/punji_sticks)

/datum/outfit/job/whitelegs/f13sapper
	name = "Sapper"
	jobtype = /datum/job/whitelegs/f13sapper
	suit = /obj/item/clothing/under/f13/whitelegs
	suit_store = /obj/item/gun/ballistic/automatic/pistol/m1911/custom
	neck = /obj/item/storage/belt/holster
	box = /obj/item/storage/survivalkit/tribal
	satchel = /obj/item/storage/backpack/marching_satchel
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bone = 1,
		/obj/item/restraints/legcuffs/beartrap = 3,
		/obj/item/ammo_box/magazine/m45 = 3,
		/obj/item/binoculars = 1,
		)


/*--------------------------------------------------------------*/

/datum/job/whitelegs/f13bonebreaker
	title = "Bone-breaker"
	flag = F13BONEBREAKER
	total_positions = -1
	spawn_positions = -1
	description = "You could have had class, you could have been a contender, you could have been somebody. But the bright lights of Reno weren't in the cards, and your exceptional talent at punching people will have to go uncelebrated by all but your tribe."
	supervisors = "your War Chief"
	display_order = JOB_DISPLAY_ORDER_BONEBREAKER
	outfit = /datum/outfit/job/whitelegs/f13bonebreaker

	access = list(ACCESS_LEGION)
	minimal_access = list(ACCESS_LEGION)

/datum/outfit/job/whitelegs/f13bonebreaker/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TECHNOPHOBE, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)

/datum/outfit/job/whitelegs/f13bonebreaker
	name = "Bone-breaker"
	jobtype = /datum/job/whitelegs/f13bonebreaker
	box = /obj/item/storage/survivalkit/tribal
	suit = /obj/item/clothing/suit/armor/light/tribal/whitelegs
	satchel = /obj/item/storage/backpack/satchel/bone
	backpack = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bone = 1,
		/obj/item/reagent_containers/pill/buffout = 1,
		)

/datum/outfit/job/whitelegs/f13bonebreaker/pre_equip(mob/living/carbon/human/H)
	. = ..()
	gloves = pick(
		/obj/item/melee/unarmed/sappers, \
		/obj/item/melee/unarmed/brass, \
		/obj/item/melee/unarmed/brass/spiked, \
		/obj/item/melee/unarmed/punchdagger, \
		/obj/item/melee/unarmed/lacerator, \
		/obj/item/melee/unarmed/maceglove, \
		/obj/item/melee/unarmed/tigerclaw \
		)

/*--------------------------------------------------------------*/

/datum/job/whitelegs/f13painmaker
	title = "Pain-maker"
	flag = F13PAINMAKER
	total_positions = -1
	spawn_positions = -1
	description = "You are a Pain-maker, the purest distillation of your people's aspirations. Bring pain to the outsiders and bring their wealth home to your family."
	supervisors = "your War Chief"
	display_order = JOB_DISPLAY_ORDER_PAINMAKER
	outfit = /datum/outfit/job/whitelegs/f13painmaker

	access = list(ACCESS_LEGION)
	minimal_access = list(ACCESS_LEGION)

/datum/outfit/job/whitelegs/f13painmaker/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TECHNOPHOBE, src)

/datum/outfit/job/whitelegs/f13painmaker
	name = "Pain-maker"
	jobtype = /datum/job/whitelegs/f13painmaker
	box = /obj/item/storage/survivalkit/tribal
	suit = /obj/item/clothing/suit/armor/light/tribal/whitelegs
	satchel = /obj/item/storage/backpack/satchel/bone
	backpack = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bone = 1,
		/obj/item/throwing_star/tomahawk = 1,
		)

/datum/outfit/job/whitelegs/f13painmaker/pre_equip(mob/living/carbon/human/H)
	. = ..()
	suit_store = pick(
		/obj/item/twohanded/fireaxe, \
		/obj/item/twohanded/fireaxe/bmprsword, \
		/obj/item/twohanded/fireaxe/boneaxe, \
		/obj/item/melee/onehanded/club/tireiron, \
		/obj/item/melee/onehanded/machete, \
		/obj/item/melee/onehanded/machete/scrapsabre, \
		/obj/item/melee/onehanded/club/warclub, \
		/obj/item/kitchen/knife/butcher \
		)

/*--------------------------------------------------------------*/

/datum/job/whitelegs/f13stormdrummer
	title = "Storm-drummer"
	flag = F13STORMDRUMMER
	total_positions = 2
	spawn_positions = 2
	description = "You wield the mighty Storm Drum, the symbol of your tribe and key to your people's greatness."
	supervisors = "your War Chief"
	display_order = JOB_DISPLAY_ORDER_STORMDRUMMER
	outfit = /datum/outfit/job/whitelegs/f13stormdrummer

	access = list(ACCESS_LEGION)
	minimal_access = list(ACCESS_LEGION)

/datum/outfit/job/whitelegs/f13stormdrummer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TECHNOPHOBE, src)

/datum/outfit/job/whitelegs/f13stormdrummer
	name = "Storm-drummer"
	jobtype = /datum/job/whitelegs/f13stormdrummer
	box = /obj/item/storage/survivalkit/tribal
	suit = /obj/item/clothing/suit/armor/light/tribal/whitelegs
	suit_store = /obj/item/gun/ballistic/automatic/smg/tommygun/whitelegs
	satchel = /obj/item/storage/backpack/satchel/bone
	backpack = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bone = 1,
		/obj/item/ammo_box/magazine/tommygunm45/stick = 2,
		/obj/item/throwing_star/tomahawk = 1,
		)


/*--------------------------------------------------------------*/

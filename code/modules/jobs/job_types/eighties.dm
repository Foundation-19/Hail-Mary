/*
Eighties Design Notes:
Sidearms are 10mm.
*/

/datum/job/eighties//do NOT use this for anything, it's just to store faction datums
	department_flag = EIGHTIES
	selection_color = "#8393b1"
	faction = FACTION_EIGHTIES

	forbids = "The 80s love: excitement, chems, raiding, ransoming, showmanship, arena fights, races, the open road."
	enforces = "The 80s hate: walking, townies, cowards, hard work, the New California Republic, Rustwalkers, flat tires."
	objectivesList = list("Amass an army and dislodge the White Legs from their camp.","Sack Wendover to enrich the compound.","Get the Mormons to do something funny.","Remind the NCR you haven't forgotten the flight from Sactown, make an example of their ambassador.","Host fights in the arena, stock up on slaves or thrill seekers and invite the wastes to a show.")
	exp_type = EXP_TYPE_EIGHTIES

	access = list(ACCESS_80S)
	minimal_access = list(ACCESS_80S)

	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/eighties,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/whitelegs,
		),
		/datum/matchmaking_pref/mentor = list(
			/datum/job/eighties,
		),
		/datum/matchmaking_pref/disciple = list(
			/datum/job/eighties,
			/datum/job/outlaw/outlaws,
		),
		/datum/matchmaking_pref/outlaw = list(
			/datum/job/wasteland/f13wastelander,
		),
		/datum/matchmaking_pref/bounty_hunter = list(
			/datum/job/wasteland/f13wastelander,
		),
	)

/datum/outfit/job/eighties
	backpack_contents = list(
		/obj/item/reagent_containers/pill/healingpowder = 1,
		/obj/item/restraints/handcuffs = 1,
		/obj/item/storage/wallet/stash = 1,
		)

/datum/outfit/job/eighties/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TRIBAL, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_LIGHT_STEP, src)
	ADD_TRAIT(H, TRAIT_FREERUNNING, src)
	H.grant_language(/datum/language/tribal)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/eighties/lightarmour)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/eighties/armour)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/eighties/heavyarmour)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/eighties/garb)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/tribalwar/eighties/femalegarb)


/datum/job/eighties/f13warboss
	title = "Warboss"
	flag = F13WARBOSS
	head_announce = list("Security")
	supervisors = "no one."
	description = "You are the Warboss. Operating from your compound in the salt flats, you send your raiding parties out in their buggies to terrorize the land. Lead your people well or you may find yourself as the codpiece of the next warboss."
	selection_color = "#536996"
	total_positions = 1
	spawn_positions = 1
	outfit = /datum/outfit/job/eighties/f13warboss
	display_order = JOB_DISPLAY_ORDER_WARBOSS
	exp_requirements = 900
	access = list(ACCESS_80S, ACCESS_80SB, ACCESS_80SR, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_80S, ACCESS_80SB, ACCESS_80SR, ACCESS_CHANGE_IDS)

	loadout_options = list(
		/datum/outfit/loadout/brawny,	//
		/datum/outfit/loadout/brainy,	//
		/datum/outfit/loadout/brazen,	//
		)

/datum/outfit/job/eighties/f13warboss/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	ADD_TRAIT(H, TRAIT_IRONFIST, src)
	ADD_TRAIT(H, TRAIT_BIG_LEAGUES, src)
	if(H.mind)
		var/obj/effect/proc_holder/spell/terrifying_presence/S = new /obj/effect/proc_holder/spell/terrifying_presence
		H.mind.AddSpell(S)

/datum/outfit/job/eighties/f13warboss
	name = "Warboss"
	jobtype = /datum/job/eighties/f13warboss

	id = /obj/item/card/id/dogtag/eighties/leadership
	ears = /obj/item/radio/headset/headset_80sc
	uniform = /obj/item/clothing/under/jabroni
	accessory = /obj/item/clothing/accessory/skullcodpiece
	suit = /obj/item/clothing/suit/armor/medium/tribal/eighties/blue
	shoes = /obj/item/clothing/shoes/jackboots
	box = /obj/item/storage/survivalkit/tribal/chief
	satchel = /obj/item/storage/backpack/satchel/old
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/binoculars = 1,
		)

/datum/outfit/job/eighties/f13warboss/pre_equip(mob/living/carbon/human/H)
	. = ..()
	head = pick(
		/obj/item/clothing/head/helmet/f13/raider/yankee, \
		/obj/item/clothing/head/helmet/f13/raidercombathelmet, \
		/obj/item/clothing/head/helmet/f13/raidermetal, \
		/obj/item/clothing/head/helmet/f13/raider/wastehound, \
		/obj/item/clothing/head/helmet/f13/raider/psychotic, \
		/obj/item/clothing/head/helmet/f13/raider/eyebot, \
		/obj/item/clothing/head/helmet/f13/raider/blastmaster, \
		/obj/item/clothing/head/helmet/f13/raider/supafly, \
		/obj/item/clothing/head/helmet/f13/raider/arclight, \
		/obj/item/clothing/head/helmet/f13/fiend \
		)

/datum/outfit/loadout/brawny
	name = "The Strongest"
	gloves = /obj/item/melee/powerfist/f13/
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/buffout =1,
		/obj/item/gun/ballistic/automatic/smg/greasegun = 1,
		/obj/item/ammo_box/magazine/greasegun = 2,
		)

/datum/outfit/loadout/brainy
	name = "The Smartest"
	gloves = /obj/item/clothing/gloves/f13/military
	suit_store = /obj/item/gun/energy/laser/wattz2k/extended
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/mfc = 2,
		/obj/item/melee/baton/boomerang = 1,
		/obj/item/ammo_box/c4570 = 2,
		/obj/item/gun/ballistic/revolver/hunting = 1,
		/obj/item/gun_upgrade/scope/watchman = 1,
		/obj/item/stock_parts/cell/high = 1,
		)

/datum/outfit/loadout/brazen
	name = "The Sawiest"
	gloves = /obj/item/clothing/gloves/f13/military
	suit_store = /obj/item/twohanded/chainsaw
	backpack_contents = list(
		/obj/item/reagent_containers/hypospray/medipen/psycho = 1,
		/obj/item/reagent_containers/pill/patch/turbo = 1,
		/obj/item/gun/ballistic/automatic/smg/greasegun = 1,
		/obj/item/ammo_box/magazine/greasegun = 2,
		)


/*--------------------------------------------------------------*/

/datum/job/eighties/f13arenamaster
	title = "Arena Master"
	flag = F13ARENAMASTER
	total_positions = 1
	spawn_positions = 1
	description = "You are the master of ceremonies, leader of the two arena teams and unofficial second in command of the 80s. Put on a good show."
	supervisors = "the Warboss"
	display_order = JOB_DISPLAY_ORDER_ARENAMASTER
	exp_requirements = 600
	outfit = /datum/outfit/job/eighties/f13arenamaster

	access = list(ACCESS_80S, ACCESS_80SB, ACCESS_80SR, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_80S, ACCESS_80SB, ACCESS_80SR, ACCESS_CHANGE_IDS)

	loadout_options = list(
		/datum/outfit/loadout/punk,	//
		/datum/outfit/loadout/ringleader,	//
		/*/datum/outfit/loadout/tbd,	*/ //
		)

/datum/outfit/job/eighties/f13arenamaster/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	if(H.gender == FEMALE)
		uniform = /obj/item/clothing/under/f13/female/eighties
	if(H.gender == MALE)
		uniform = /obj/item/clothing/under/f13/eighties


/datum/outfit/job/eighties/f13arenamaster/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)

/datum/outfit/job/eighties/f13arenamaster
	name = "Arena Master"
	jobtype = /datum/job/eighties/f13arenamaster

	id = /obj/item/card/id/dogtag/eighties/leadership
	ears = /obj/item/radio/headset/headset_80sc
	box = /obj/item/storage/survivalkit/tribal
	accessory = /obj/item/clothing/accessory/armband/science
	suit = /obj/item/clothing/suit/armor/medium/tribal/eighties/green
	shoes = /obj/item/clothing/shoes/jackboots
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/storage/bag/chemistry = 1,
		/obj/item/reagent_containers/pill/patch/jet = 2,
		/obj/item/reagent_containers/pill/patch/turbo = 2,
		/obj/item/reagent_containers/hypospray/medipen/psycho = 2,
		/obj/item/storage/pill_bottle/chem_tin/buffout = 1,
		/obj/item/storage/belt/champion = 1,
		)

/datum/outfit/loadout/punk
	name = "Business Loop"
	suit_store = /obj/item/gun/ballistic/automatic/smg/smg10mm
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m10mm = 2,
		/obj/item/jammer = 1,
		/obj/item/restraints/legcuffs/bola/tactical = 1,
		/obj/item/restraints/legcuffs = 2,
		/obj/item/restraints/handcuffs = 2,
		/obj/item/electropack/shockcollar = 2,
		/obj/item/assembly/signaler/advanced = 1,
		/obj/item/megaphone = 1,
		/obj/item/binoculars = 1,
		/obj/item/stock_parts/cell/high = 1,
		)

/datum/outfit/loadout/ringleader
	name = "Grandstander"
	head = /obj/item/clothing/head/f13/beaver
	gloves = /obj/item/clothing/gloves/fingerless
	backpack_contents = list(
		/obj/item/clothing/suit/armor/medium/vest/bulletproof = 1,
		/obj/item/ammo_box/c4570 = 4,
		/obj/item/gun/ballistic/revolver/hunting = 1,
		/obj/item/gun_upgrade/scope/watchman = 1,
		/obj/item/melee/onehanded/slavewhip = 1,
		/obj/item/toy/crayon/spraycan = 1,
		/obj/item/assembly/signaler/advanced = 1,
		/obj/item/megaphone = 1,
		/obj/item/binoculars = 1,
		)

/datum/outfit/job/eighties/f13arenamaster/pre_equip(mob/living/carbon/human/H)
	. = ..()
	head = pick(
		/obj/item/clothing/head/helmet/f13/raider/yankee, \
		/obj/item/clothing/head/helmet/f13/raidercombathelmet, \
		/obj/item/clothing/head/helmet/f13/raidermetal, \
		/obj/item/clothing/head/helmet/f13/raider/wastehound, \
		/obj/item/clothing/head/helmet/f13/raider/psychotic, \
		/obj/item/clothing/head/helmet/f13/raider/eyebot, \
		/obj/item/clothing/head/helmet/f13/raider/blastmaster, \
		/obj/item/clothing/head/helmet/f13/raider/supafly, \
		/obj/item/clothing/head/helmet/f13/raider/arclight, \
		/obj/item/clothing/head/helmet/f13/fiend \
		)

/*datum/outfit/loadout/tbd
	name = "The Sawiest"
	gloves = /obj/item/clothing/gloves/f13/military
	suit_store = /obj/item/twohanded/chainsaw
	backpack_contents = list(
		/obj/item/stack/crafting/armor_plate/five = 1,
		/obj/item/reagent_containers/hypospray/medipen/psycho = 3,
		/obj/item/reagent_containers/pill/patch/turbo = 3,
		)
*/

/*--------------------------------------------------------------*/

/datum/job/eighties/f13laymechanic
	title = "Lay Mechanic"
	flag = F13LAYMECHANIC
	total_positions = 2
	spawn_positions = 2
	description = "You are skilled in the maintenance and repair of the human body, the most complicated machine around. Blackfingers may pride themselves on keeping the war buggies in working order, but it's you who keeps them up. Patch up scrapes, set bones and prescribe your tribe with the latest in alternative medicines."
	supervisors = "the Warboss"
	display_order = JOB_DISPLAY_ORDER_LAYMECHANIC
	outfit = /datum/outfit/job/eighties/f13laymechanic

	access = list(ACCESS_80S)
	minimal_access = list(ACCESS_80S)

	loadout_options = list(
		/datum/outfit/loadout/bonesetter,	// mid surgery
		/datum/outfit/loadout/mixer,	// chemistry
		)

/datum/outfit/job/eighties/f13laymechanic/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	if(H.gender == FEMALE)
		uniform = /obj/item/clothing/under/f13/female/eighties
	if(H.gender == MALE)
		uniform = /obj/item/clothing/under/f13/eighties


/datum/outfit/job/eighties/f13laymechanic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_MACHINE_SPIRITS, src)

/datum/outfit/job/eighties/f13laymechanic
	name = "Lay Mechanic"
	jobtype = /datum/job/eighties/f13laymechanic
	id = /obj/item/card/id/dogtag/eighties
	ears = /obj/item/radio/headset/headset_80s
	suit = /obj/item/clothing/suit/armor/medium/tribal/eighties/green
	suit_store = /obj/item/gun/ballistic/automatic/m1carbine
	box = /obj/item/storage/survivalkit/tribal
	shoes = /obj/item/clothing/shoes/jackboots
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/med
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/storage/firstaid = 1,
		/obj/item/ammo_box/magazine/m10mm = 2,
		)

/datum/outfit/loadout/bonesetter
	name = "Bonesetter"
	backpack_contents = list(
		/obj/item/book/granter/trait/lowsurgery = 1,
		/obj/item/storage/belt/medical/surgery_belt_adv = 1,
		)

/datum/outfit/loadout/mixer
	name = "Mixer"
	backpack_contents = list(
		/obj/item/book/granter/trait/chemistry = 1,
		/obj/item/storage/bag/chemistry/tribal = 1,
		/obj/item/reagent_containers/glass/beaker/plastic = 1,
		/obj/item/reagent_containers/glass/beaker/large = 2,
		/obj/item/reagent_containers/dropper = 1,
		)

/datum/outfit/job/eighties/f13laymechanic/pre_equip(mob/living/carbon/human/H)
	. = ..()
	head = pick(
		/obj/item/clothing/head/helmet/f13/raider/yankee, \
		/obj/item/clothing/head/helmet/f13/raidercombathelmet, \
		/obj/item/clothing/head/helmet/f13/raidermetal, \
		/obj/item/clothing/head/helmet/f13/raider/wastehound, \
		/obj/item/clothing/head/helmet/f13/raider/psychotic, \
		/obj/item/clothing/head/helmet/f13/raider/eyebot, \
		/obj/item/clothing/head/helmet/f13/raider/blastmaster, \
		/obj/item/clothing/head/helmet/f13/raider/supafly, \
		/obj/item/clothing/head/helmet/f13/raider/arclight, \
		/obj/item/clothing/head/helmet/f13/fiend \
		)

/*--------------------------------------------------------------*/

/datum/job/eighties/f13blackfinger
	title = "Blackfinger"
	flag = F13BLACKFINGER
	total_positions = 2
	spawn_positions = 2
	description = "You are one of the prized mechanics of your tribe, entrusted with the care of your people's famous war buggies. Your technical skills also make you the best suited for making and improving your tribe's weapons and armor, constructing defenses or whatever else you think of."
	supervisors = "the Warboss"
	display_order = JOB_DISPLAY_ORDER_BLACKFINGER
	outfit = /datum/outfit/job/eighties/f13blackfinger

	access = list(ACCESS_80S)
	minimal_access = list(ACCESS_80S)

	loadout_options = list(
		/datum/outfit/loadout/roadmender,	// construction
		/datum/outfit/loadout/rigger,	// crafting
		)

/datum/outfit/job/eighties/f13blackfinger/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	if(H.gender == FEMALE)
		uniform = /obj/item/clothing/under/f13/female/eighties
	if(H.gender == MALE)
		uniform = /obj/item/clothing/under/f13/eighties

/datum/outfit/job/eighties/f13blackfinger/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_TECHNOPHREAK, src)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/chainsaw)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/steeltower)

/datum/outfit/job/eighties/f13blackfinger
	name = "Blackfinger"
	jobtype = /datum/job/eighties/f13blackfinger
	id = /obj/item/card/id/dogtag/eighties
	suit = /obj/item/clothing/suit/armor/medium/tribal/eighties/green
	ears = /obj/item/radio/headset/headset_80s
	box = /obj/item/storage/survivalkit/tribal
	shoes = /obj/item/clothing/shoes/jackboots
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/bone = 1,
		)

/datum/outfit/loadout/roadmender
	name = "Roadmender"
	belt = /obj/item/storage/belt/utility
	glasses = /obj/item/clothing/glasses/welding
	suit_store = /obj/item/twohanded/sledgehammer/simple
	backpack_contents = list(
		/obj/item/weldingtool/largetank = 1,
		/obj/item/wrench/power = 1,
		/obj/item/wirecutters/power = 1,
		/obj/item/rcl/ghetto = 1,
		/obj/item/gun/ballistic/automatic/smg/greasegun/worn = 1,
		/obj/item/ammo_box/magazine/greasegun = 2,
		)

/datum/outfit/loadout/rigger
	name = "Rigger"
	glasses = /obj/item/clothing/glasses/welding
	suit_store = /obj/item/gun/ballistic/automatic/smg/greasegun/worn
	backpack_contents = list(
		/obj/item/book/granter/trait/explosives = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_one = 1,
		/obj/item/book/granter/crafting_recipe/gunsmith_two = 1,
		/obj/item/ammo_box/magazine/greasegun = 2,
		/obj/item/storage/bag/salvage = 2,
		)

/datum/outfit/job/eighties/f13blackfinger/pre_equip(mob/living/carbon/human/H)
	. = ..()
	head = pick(
		/obj/item/clothing/head/helmet/f13/raider/yankee, \
		/obj/item/clothing/head/helmet/f13/raidercombathelmet, \
		/obj/item/clothing/head/helmet/f13/raidermetal, \
		/obj/item/clothing/head/helmet/f13/raider/wastehound, \
		/obj/item/clothing/head/helmet/f13/raider/psychotic, \
		/obj/item/clothing/head/helmet/f13/raider/eyebot, \
		/obj/item/clothing/head/helmet/f13/raider/blastmaster, \
		/obj/item/clothing/head/helmet/f13/raider/supafly, \
		/obj/item/clothing/head/helmet/f13/raider/arclight, \
		/obj/item/clothing/head/helmet/f13/fiend \
		)

/*--------------------------------------------------------------*/

/datum/job/eighties/f13eighty
	title = "80"
	flag = F13EIGHTY
	total_positions = -1
	spawn_positions = -1
	description = "You are a run of the mill 80. Your tribe (or gang depending on who you ask) roams the I-80, raiding, kidnapping and ransoming whoever they can. Whether you were born into it or joined up later in life, this group is the closest thing you have to a family."
	supervisors = "the Warboss"
	display_order = JOB_DISPLAY_ORDER_EIGHTY
	outfit = /datum/outfit/job/eighties/f13eighty

	access = list(ACCESS_80S)
	minimal_access = list(ACCESS_80S)

/datum/outfit/job/eighties/f13eighty/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	if(H.gender == FEMALE)
		uniform = /obj/item/clothing/under/f13/female/eighties
	if(H.gender == MALE)
		uniform = /obj/item/clothing/under/f13/eighties

	suit = pick(
		/obj/item/clothing/suit/armor/heavy/tribal/eighties, \
		/obj/item/clothing/suit/armor/medium/tribal/eighties, \
		/obj/item/clothing/suit/armor/light/tribal/eighties, \
		)

/datum/outfit/job/eighties/f13eighty/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/datum/outfit/job/eighties/f13eighty
	name = "Eighty"
	jobtype = /datum/job/eighties/f13eighty
	id = /obj/item/card/id/dogtag/eighties
	ears = /obj/item/radio/headset/headset_80s
	box = /obj/item/storage/survivalkit/tribal
	shoes = /obj/item/clothing/shoes/jackboots
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/n99 = 1,
		/obj/item/ammo_box/magazine/m10mm = 3,
		/obj/item/melee/onehanded/knife/switchblade = 1,
		)

/datum/outfit/job/eighties/f13eighty/pre_equip(mob/living/carbon/human/H)
	. = ..()
	head = pick(
		/obj/item/clothing/head/helmet/f13/raider/yankee, \
		/obj/item/clothing/head/helmet/f13/raidercombathelmet, \
		/obj/item/clothing/head/helmet/f13/raidermetal, \
		/obj/item/clothing/head/helmet/f13/raider/wastehound, \
		/obj/item/clothing/head/helmet/f13/raider/psychotic, \
		/obj/item/clothing/head/helmet/f13/raider/eyebot, \
		/obj/item/clothing/head/helmet/f13/raider/blastmaster, \
		/obj/item/clothing/head/helmet/f13/raider/supafly, \
		/obj/item/clothing/head/helmet/f13/raider/arclight, \
		/obj/item/clothing/head/helmet/f13/fiend \
		)

/*--------------------------------------------------------------*/

/datum/job/eighties/f13blueteam
	title = "Blue Team"
	flag = F13BLUETEAM
	total_positions = 0
	spawn_positions = 0
	description = "You are a member of the 80s arena BLUE team. Look out for your teammates and help the Arena Master put on a good show."
	supervisors = "The Arena Master and the Warboss"
	display_order = JOB_DISPLAY_ORDER_BLUETEAM
	outfit = /datum/outfit/job/eighties/f13blueteam

	access = list(ACCESS_80S, ACCESS_80SB)
	minimal_access = list(ACCESS_80S, ACCESS_80SB)

	loadout_options = list(
		/datum/outfit/loadout/nitro,	// 80 with a death wish
		/datum/outfit/loadout/glory,	// gladiator
		/datum/outfit/loadout/captive,	// slave fighter
		/datum/outfit/loadout/dweeb,	// captured follower
		)


/datum/outfit/job/eighties/f13blueteam/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/datum/outfit/job/eighties/f13blueteam
	name = "Blue Team"
	jobtype = /datum/job/eighties/f13blueteam
	box = /obj/item/storage/survivalkit/tribal
	id = /obj/item/card/id/dogtag/eighties/blueteam
	ears = /obj/item/radio/headset/headset_80sb
	uniform = /obj/item/clothing/under/pants/jeanripped
	shoes = /obj/item/clothing/shoes/jackboots
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/clothing/mask/bandana/blue = 1,
		/obj/item/clothing/accessory/armband/blue = 1,
		/obj/item/gun/ballistic/automatic/smg/greasegun/worn = 1,
		/obj/item/ammo_box/magazine/greasegun = 2,
		)

/datum/outfit/loadout/nitro
	name = "Adrenaline Junkie"
	gloves = /obj/item/clothing/gloves/fingerless
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/ninemil = 1,
		/obj/item/ammo_box/magazine/m9mm = 2,
		/obj/item/book/granter/crafting_recipe/tribal/eighties = 1,
		/obj/item/reagent_containers/pill/patch/turbo = 1,
		)

/datum/outfit/loadout/glory
	name = "Glory Hound"
	uniform = /obj/item/clothing/under/gladiator
	gloves = /obj/item/clothing/gloves/bracer
	shoes = /obj/item/clothing/shoes/roman
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/clothing/head/helmet/gladiator = 1,
		)

/datum/outfit/loadout/captive
	name = "Slave"
	uniform = /obj/item/clothing/under/pants/f13/ghoul
	gloves = /obj/item/clothing/gloves/f13/handwraps
	neck = /obj/item/electropack/shockcollar
	shoes = /obj/item/clothing/shoes/f13/raidertreads

/datum/outfit/loadout/dweeb
	name = "Egghead"
	uniform = /obj/item/clothing/under/pants/f13/ghoul
	suit = /obj/item/clothing/suit/toggle/labcoat
	glasses = /obj/item/clothing/glasses/regular/jamjar
	mask = /obj/item/clothing/mask/muzzle
	neck = /obj/item/electropack/shockcollar
	shoes = /obj/item/clothing/shoes/laceup

/*--------------------------------------------------------------*/

/datum/job/eighties/f13redteam
	title = "Red Team"
	flag = F13BLUETEAM
	total_positions = 0
	spawn_positions = 0
	description = "You are a member of the 80s arena RED team. Look out for your teammates and help the Arena Master put on a good show."
	supervisors = "The Arena Master and the Warboss"
	display_order = JOB_DISPLAY_ORDER_REDTEAM
	outfit = /datum/outfit/job/eighties/f13redteam

	access = list(ACCESS_80S, ACCESS_80SR)
	minimal_access = list(ACCESS_80S, ACCESS_80SR)

	loadout_options = list(
		/datum/outfit/loadout/huffer,	// 80 with a death wish
		/datum/outfit/loadout/psycho,	// raider
		/datum/outfit/loadout/rusted,	// rustwalker
		/datum/outfit/loadout/bear,	// californian
		)


/datum/outfit/job/eighties/f13redteam/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/datum/outfit/job/eighties/f13redteam
	name = "Red Team"
	jobtype = /datum/job/eighties/f13redteam
	box = /obj/item/storage/survivalkit/tribal
	id = /obj/item/card/id/dogtag/eighties/redteam
	ears = /obj/item/radio/headset/headset_80sr
	uniform = /obj/item/clothing/under/pants/red
	shoes = /obj/item/clothing/shoes/jackboots
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/clothing/mask/bandana/red = 1,
		/obj/item/clothing/accessory/armband = 1,
		/obj/item/gun/ballistic/automatic/smg/greasegun/worn = 1,
		/obj/item/ammo_box/magazine/greasegun = 2,
		)

/datum/outfit/loadout/huffer
	name = "Paint Huffer"
	gloves = /obj/item/clothing/gloves/fingerless
	backpack_contents = list(
		/obj/item/paint/red = 1,
		/obj/item/toy/crayon/spraycan = 1,
		/obj/item/gun/ballistic/automatic/pistol/ninemil = 1,
		/obj/item/ammo_box/magazine/m9mm = 2,
		/obj/item/book/granter/crafting_recipe/tribal/eighties = 1,
		)

/datum/outfit/loadout/psycho
	name = "Pitfighter"
	uniform = /obj/item/clothing/under/pants/chaps
	belt = /obj/item/storage/belt/military/alt
	backpack_contents = list(
		/obj/item/clothing/neck/mantle/peltfur = 1,
		/obj/item/clothing/shoes/cowboyboots/black = 1,
		)

/datum/outfit/loadout/rusted
	name = "Rustwalker"
	uniform = /obj/item/clothing/under/f13/rustwalkers
	neck = /obj/item/electropack/shockcollar
	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/tribal/rustwalkers = 1,
		/obj/item/clothing/under/f13/female/rustwalkers = 1,
		)

/datum/outfit/loadout/bear
	name = "Dancing Bear"
	uniform = /obj/item/clothing/under/pants/blackjeans
	neck = /obj/item/electropack/shockcollar
	backpack_contents = list(
		/obj/item/clothing/under/f13/exile = 1,
		/obj/item/card/id/rusted = 1,
		/obj/item/card/id/dogtag/town/ncr = 1,
		/obj/item/clothing/suit/jacket/flannel/red = 1,
		/obj/item/clothing/head/cowboyhat = 1,
		/obj/item/clothing/shoes/workboots/mining = 1,
		)

/*--------------------------------------------------------------*/

/datum/job/eighties/f13roadie
	title = "Roadie"
	flag = F13ROADIE
	total_positions = 0
	spawn_positions = 0
	description = "You're one of the many hangers-on of the 80s. Whether you're a raider hoping to join up, a scavver working the graveyard, a hopeful revhead or just lost, you're under the protection of the 80s."
	supervisors = "the Warboss."
	display_order = JOB_DISPLAY_ORDER_ROADIE
	outfit = /datum/outfit/job/eighties/f13roadie

	access = list(ACCESS_80S)
	minimal_access = list(ACCESS_80S)

/datum/outfit/job/eighties/f13roadie/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_GENERIC, src)

/datum/outfit/job/eighties/f13roadie
	name = "Roadie"
	jobtype = /datum/job/eighties/f13roadie
	box = /obj/item/storage/survivalkit/tribal
	satchel = /obj/item/storage/backpack/satchel/leather
	backpack = /obj/item/storage/backpack/satchel/explorer
	backpack_contents = list(
		/obj/item/melee/onehanded/knife/switchblade = 1,
		/obj/item/reagent_containers/pill/healingpowder = 1,
		)

/datum/outfit/job/eighties/f13roadie/pre_equip(mob/living/carbon/human/H)
	. = ..()
	uniform = pick(
		/obj/item/clothing/under/f13/ravenharness, \
		/obj/item/clothing/under/f13/atomwitchunder, \
		/obj/item/clothing/under/f13/raiderharness, \
		/obj/item/clothing/under/f13/raider_leather, \
		/obj/item/clothing/under/f13/raiderrags, \
		/obj/item/clothing/under/pants/f13/ghoul, \
		/obj/item/clothing/under/jabroni, \
		/obj/item/clothing/under/f13/merca, \
		/obj/item/clothing/under/f13/bearvest, \
		/obj/item/clothing/under/pants/chaps, \
		/obj/item/clothing/under/f13/rag \
		)

	head = pick(
		/obj/item/clothing/head/helmet/f13/raider/yankee, \
		/obj/item/clothing/head/helmet/f13/raidercombathelmet, \
		/obj/item/clothing/head/helmet/f13/raidermetal, \
		/obj/item/clothing/head/helmet/f13/raider/wastehound, \
		/obj/item/clothing/head/helmet/f13/raider/psychotic, \
		/obj/item/clothing/head/helmet/f13/raider/eyebot, \
		/obj/item/clothing/head/helmet/f13/raider/blastmaster, \
		/obj/item/clothing/head/helmet/f13/raider/supafly, \
		/obj/item/clothing/head/helmet/f13/raider/arclight, \
		/obj/item/clothing/head/helmet/f13/fiend \
		)

	suit = pick(
		/obj/item/clothing/suit/armor/light/raider/supafly,\
		/obj/item/clothing/suit/armor/medium/raider/yankee, \
		/obj/item/clothing/suit/armor/light/raider/sadist, \
		/obj/item/clothing/suit/armor/medium/raider/blastmaster, \
		/obj/item/clothing/suit/armor/medium/raider/badlands, \
		/obj/item/clothing/suit/armor/light/raider/painspike, \
		)

	suit_store = pick(
		/obj/item/gun/ballistic/revolver/detective, \
		/obj/item/gun/ballistic/automatic/pistol/ninemil,\
		/obj/item/gun/ballistic/automatic/pistol/m1911, \
		/obj/item/gun/ballistic/automatic/pistol/type17, \
		/obj/item/twohanded/fireaxe, \
		/obj/item/twohanded/fireaxe/bmprsword, \
		/obj/item/twohanded/fireaxe/boneaxe, \
		/obj/item/melee/onehanded/club/tireiron, \
		/obj/item/melee/onehanded/machete, \
		/obj/item/melee/onehanded/machete/scrapsabre, \
		/obj/item/melee/onehanded/club/warclub, \
		/obj/item/kitchen/knife/butcher \
		)

	shoes = pick(
		/obj/item/clothing/shoes/jackboots,\
		/obj/item/clothing/shoes/f13/diesel,\
		/obj/item/clothing/shoes/f13/diesel/alt,\
		/obj/item/clothing/shoes/f13/raidertreads \
		)

/datum/job/CaesarsLegiontown
	faction = FACTION_LEGIONTOWN
	total_positions = 0
	spawn_positions = 0
	selection_color = "#810505"

	forbids = "The Legion forbids: Using drugs such as stimpacks. Subject are allowed to drink alcohol, depending of who is in charge. Ostia aren't fans of ghouls. Slaves carrying weapons. Killing Legion members in secret, only if according to law and in public is it acceptable, only if a Decanus, Centurion, or Governor accept it. You are to respect your fellow subjects."

/datum/job/CaesarsLegiontown/subject
	title = "Legion Subject"
	flag = F13OSTIASUBJECT
	department_flag = OSTIA
	total_positions = -1
	spawn_positions = -1
	description = "A citizen of the Legion port of Ostia. You are not a slave, but freedom is a concept quite far from you. You are not part of the legion military (ain't an off duty role), and live a comfy life. You can manage the shop, the inn, or just help the legion arround. You can also become a Gladiator in the arena. As a subject, you must have a Latin name."
	supervisors = "You obey the Governor, and the legion military, whom you are also loyal to."
	display_order = JOB_DISPLAY_ORDER_F13OSTIASUBJECT 
	exp_requirements = 0
	outfit = /datum/outfit/job/CaesarsLegiontown/subject

	loadout_options = list(
		/datum/outfit/loadout/subjectoflegion,
		/datum/outfit/loadout/legiongladiator,
		/datum/outfit/loadout/legionbarkeep,
		)

	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/CaesarsLegion,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/CaesarsLegion,
		),
	)

	access = list(ACCESS_BAR, ACCESS_TOWN)
	minimal_access = list(ACCESS_BAR, ACCESS_TOWN)

/datum/outfit/job/CaesarsLegiontown/subject/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_MARS_TEACH, src)

/datum/outfit/job/CaesarsLegiontown/subject
	name = "Legion Subject"
	jobtype = /datum/outfit/job/CaesarsLegiontown/subject
	id = /obj/item/card/id/dogtag/legimmune
	uniform = /obj/item/clothing/under/civ/roman_centurion
	shoes =	/obj/item/clothing/shoes/roman
	ears = /obj/item/radio


/datum/outfit/loadout/subjectoflegion
	name = "Legion Subject"
	backpack_contents = list(		
		/obj/item/ammo_box/a357 = 1,
		/obj/item/gun/ballistic/revolver/colt357 = 1,
		/obj/item/stack/f13Cash/random/denarius/low = 2,
		/obj/item/flashlight/lantern = 1,
	)

/datum/outfit/loadout/legiongladiator
	name = "Legion Gladiator"
	backpack_contents = list(
		/obj/item/clothing/head/helmet/gladiator = 1,
		/obj/item/clothing/under/gladiator = 1,
		/obj/item/clothing/shoes/roman = 1,
		/obj/item/flashlight/lantern = 1,
		/obj/item/melee/onehanded/machete = 1,
		/obj/item/stack/f13Cash/random/denarius/low = 1,
		/obj/item/book/granter/trait/bigleagues = 1,
		/obj/item/shield/riot/buckler = 1,
		/obj/item/lighter = 1,
		)

/datum/outfit/loadout/legionbarkeep
	name = "Legion Innkeeper"
	backpack_contents = list(
		/obj/item/clothing/head/f13/servant = 2,
		/obj/item/clothing/under/civ/spanish_sailor = 2,
		/obj/item/clothing/gloves/f13/crudemedical = 2,
		/obj/item/clothing/shoes/roman = 2,
		/obj/item/flashlight/lantern = 2,
		/obj/item/reagent_containers/food/condiment/flour = 2,
		/obj/item/storage/box/bowls = 2,
		/obj/item/melee/onehanded/knife/cosmicdirty = 1,
		/obj/item/soap/homemade = 1,
		/obj/item/lighter = 1,
		)

/datum/job/CaesarsLegiontown/governor
	title = "Legion Governor of Ostia"
	flag = F13OSTIAGOVERNOR
	total_positions = 1
	spawn_positions = 1
	description = "The Civilian Leader of the Legion port of Ostia. You organize this city, make sure everything is in order, arrest troublemakers, organize slave sales with the Slave Master... You have only a limited power over slaves, and have no say in the military. You must have a Latin name."
	supervisors = "You have authority over non military matters."
	display_order = JOB_DISPLAY_ORDER_F13OSTIAGOVERNOR
	exp_requirements = 0
	outfit = /datum/outfit/job/CaesarsLegiontown/governor

	loadout_options = list(
		/datum/outfit/loadout/legionhero,
		/datum/outfit/loadout/legiontrust,
		)

	access = list(ACCESS_LEGION, ACCESS_CHANGE_IDS, ACCESS_LEGION_COMMAND, ACCESS_LEGION_CENTURION, ACCESS_TOWN_MERCH, ACCESS_TOWN)
	minimal_access = list(ACCESS_LEGION, ACCESS_CHANGE_IDS, ACCESS_LEGION_COMMAND, ACCESS_LEGION_CENTURION, ACCESS_TOWN_MERCH, ACCESS_TOWN)

/datum/outfit/job/CaesarsLegiontown/governor
	id = /obj/item/card/id/dogtag/legion/centurion
	ears = /obj/item/radio/headset/headset_legion
	neck = /obj/item/storage/belt/holster
	uniform = /obj/item/clothing/under/civ/roman_centurion
	shoes = /obj/item/clothing/shoes/f13/military/plated
	r_pocket = /obj/item/storage/survivalkit/medical/legion
	l_pocket = /obj/item/flashlight/lantern
	box = /obj/item/storage/survivalkit/tribal/chief
	box_two = /obj/item/storage/survivalkit/medical/tribal
	backpack_contents = list(
		/obj/item/restraints/legcuffs/bola = 1,
		/obj/item/warpaint_bowl = 1,
		/obj/item/ammo_box/c4570box = 2,
		/obj/item/gun/ballistic/revolver/hunting = 1,
		/obj/item/stack/f13Cash/aureus = 5,
		/obj/item/binoculars = 1,
		)

/datum/outfit/loadout/legionhero
	name = "Legion Hero"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/legion/palacent/ostia = 1,
		/obj/item/flashlight/lantern = 1,
		/obj/item/twohanded/spear/lance = 1,
		/obj/item/book/granter/trait/bigleagues = 1,
		/obj/item/gun/ballistic/shotgun/automatic/combat/shotgunlever = 1,
		/obj/item/ammo_box/shotgun/improvised = 2,
		/obj/item/shield/riot/legion = 1,
		/obj/item/clothing/neck/mantle/legion = 1,
		/obj/item/lighter = 1,
		)

/datum/outfit/loadout/legiontrust
	name = "Trusted by Caesar"
	backpack_contents = list(
		/obj/item/clothing/suit/armor/legion/praetorian = 1,
		/obj/item/flashlight/lantern = 1,
		/obj/item/melee/powerfist/f13 = 1,
		/obj/item/book/granter/trait/bigleagues = 1,
		/obj/item/clothing/neck/mantle/legion = 1,
		/obj/item/lighter = 1,
		/obj/item/clothing/glasses/sunglasses/big = 1,
		)

/datum/outfit/job/CaesarsLegiontown/governor/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_MARS_TEACH, src)
	ADD_TRAIT(H, TRAIT_LIFEGIVER, src)
	ADD_TRAIT(H, TRAIT_IRONFIST, src)
	if(H.mind)
		var/obj/effect/proc_holder/spell/terrifying_presence/S = new /obj/effect/proc_holder/spell/terrifying_presence
		H.mind.AddSpell(S)

//Shopkeep

/datum/job/CaesarsLegiontown/legionshopkeeper
	title = "Ostia Shopkeeper"
	flag = F13OSTIASHOPKEEP
	department_flag = OSTIA
	total_positions = 2
	spawn_positions = 2
	supervisors = "The Gouvernor, the Legion"
	description = "You are one of the many workers who live in the city of Ostia, and in the good grace of the Legion."
	enforces = "The Ostia trading place is part of your workplace, but it is not your workplace alone. You should try work with the other shopkeeper to try and turn a profit. You also sell slaves."
	selection_color = "#dcba97"
	exp_requirements = 0
	display_order = JOB_DISPLAY_ORDER_F13OSTIASHOPKEEP
	outfit = /datum/outfit/job/CaesarsLegiontown/legionshopkeeper
	
	access = list(ACCESS_LEGION, ACCESS_TOWN_MERCH, ACCESS_TOWN)
	minimal_access = list(ACCESS_LEGION, ACCESS_TOWN_MERCH, ACCESS_TOWN)

	matchmaking_allowed = list(
		/datum/matchmaking_pref/friend = list(
			/datum/job/CaesarsLegion,
		),
		/datum/matchmaking_pref/rival = list(
			/datum/job/CaesarsLegion,
		),
	)

/datum/outfit/job/CaesarsLegiontown/legionshopkeeper
	name = "Ostia Shopkeeper"
	jobtype = /datum/job/CaesarsLegiontown/legionshopkeeper
	id = /obj/item/card/id/dogtag/legimmune
	ears = /obj/item/radio/headset
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
			/obj/item/clothing/head/f13/servant = 1,
		/obj/item/clothing/under/civ/spanish_sailor = 1,
		/obj/item/clothing/gloves/f13/crudemedical = 1,
		/obj/item/clothing/shoes/roman = 1,
		/obj/item/flashlight/lantern = 1,
		/obj/item/ammo_box/shotgun/improvised = 2,
		/obj/item/stack/f13Cash/random/denarius/med = 1,
		/obj/item/soap/homemade = 1,
		/obj/item/gun/ballistic/revolver/widowmaker = 1,
		/obj/item/lighter = 1,
		)

/datum/outfit/job/CaesarsLegiontown/legionshopkeeper/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
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

/datum/outfit/job/CaesarsLegiontown/legionshopkeeper/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
//
// RADIO HOST
// 
/datum/job/CaesarsLegiontown/legionradiohost
	title = "Ostia Radio Host"
	flag = F13OSTIARADIOHOST
	display_order = JOB_DISPLAY_ORDER_F13OSTIARADIOHOST
	department_flag = OSTIA
	total_positions = 2
	spawn_positions = 2
	supervisors = "The Legion, the Gouvernor"
	description = "You are the Radio Host of Ostia. While under legion rule, you still have a bit of freedom in the music... Just... Don't anger the Legion or the Governor if you wish to live..."
	enforces = "Although very independant and vocal you are still under control of local governance - try to keep a good relationship with them."
	selection_color = "#dcba97"

	outfit = /datum/outfit/job/den/f13radio_host

	access = list(ACCESS_TOWN_CIV)
	minimal_access = list(ACCESS_TOWN_CIV)

/datum/outfit/job/CaesarsLegiontown/legionradiohost
	name = "Ostia Radio Host"
	jobtype = /datum/job/eastwood/f13radio_host
	id = /obj/item/card/id/dogtag/town
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	belt = /obj/item/pda/detective
	backpack_contents = list(
		/obj/item/camera, \
		/obj/item/clothing/under/f13/legskirt=1,
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

/// Subsection of Outlaws.dm is for wasteland-ish raiders / outlaws.

/datum/job/baltimore_outlaw //do NOT use this for anything, it's just to store faction datums
	department_flag = NONE
	faction = FACTION_RAIDERS
	exp_type = EXP_TYPE_OUTLAW

/datum/job/baltimore_outlaw/baltimoreoutlaws
	title = "Outlaw"
	flag = F13BALTIMORERAIDER
	department_head = list("Captain")
	head_announce = list("Security")
	total_positions = 10
	spawn_positions = 10
	description = "You are an Outlaw - the choice of why is up to you. While you are free to do what ever you want."
	supervisors = "your conscious if you have one"
	selection_color = "#df80af"
	exp_requirements = 0
	exp_type = EXP_TYPE_OUTLAW

	outfit = /datum/outfit/job/baltimore_outlaw

	access = list()
	minimal_access = list()
	matchmaking_allowed = list(
		/datum/matchmaking_pref/patron = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/protegee = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/outlaw = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/bounty_hunter = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
	)
	loadout_options = list(
		/datum/outfit/loadout/raider_sadist,
		/datum/outfit/loadout/raider_tribal,
		/datum/outfit/loadout/raider_supafly,
		/datum/outfit/loadout/raider_yankee,
		/datum/outfit/loadout/raider_blast,
		/datum/outfit/loadout/raider_painspike,
		/datum/outfit/loadout/raider_badlands,
		/datum/outfit/loadout/raider_smith,
		/datum/outfit/loadout/raider_bos,
		/datum/outfit/loadout/raider_minutemen,
		/datum/outfit/loadout/quack_doctor
	)
	


/datum/outfit/job/baltimore_outlaw
	name = "Outlaw"
	jobtype = /datum/job/baltimore_outlaw
	id = null
	ears = null
	belt = null
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	gloves = /obj/item/clothing/gloves/f13/handwraps
	l_pocket = /obj/item/radio/outlaw
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit/outlaw
	box_two = /obj/item/storage/survivalkit/medical
	backpack_contents = list(
		/obj/item/restraints/handcuffs = 2,
		/obj/item/melee/onehanded/club = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 1,
		/obj/item/radio = 1,
		/obj/item/kit_spawner/tools,
		/obj/item/kit_spawner/tools,
		)

/datum/outfit/job/baltimore_outlaw/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/bloodleaf)	

/datum/outfit/job/baltimore_outlaw/pre_equip(mob/living/carbon/human/H)
	. = ..()
	uniform = pick(
		/obj/item/clothing/under/f13/merca, \
		/obj/item/clothing/under/f13/mercc, \
		/obj/item/clothing/under/f13/cowboyb, \
		/obj/item/clothing/under/f13/cowboyg, \
		/obj/item/clothing/under/f13/raider_leather, \
		/obj/item/clothing/under/f13/raiderrags, \
		/obj/item/clothing/under/pants/f13/ghoul, \
		/obj/item/clothing/under/jabroni)
	suit = pick(
		/obj/item/clothing/suit/armor/light/raider/supafly,\
		/obj/item/clothing/suit/armor/medium/raider/yankee, \
		/obj/item/clothing/suit/armor/light/raider/sadist, \
		/obj/item/clothing/suit/armor/medium/raider/blastmaster, \
		/obj/item/clothing/suit/armor/medium/raider/badlands, \
		/obj/item/clothing/suit/armor/light/raider/painspike)
	if(prob(10))
		mask = pick(
			/obj/item/clothing/mask/bandana/red,\
			/obj/item/clothing/mask/bandana/blue,\
			/obj/item/clothing/mask/bandana/green,\
			/obj/item/clothing/mask/bandana/gold,\
			/obj/item/clothing/mask/bandana/black,\
			/obj/item/clothing/mask/bandana/skull)
	if(prob(50))
		neck = pick(
			/obj/item/clothing/neck/mantle/peltfur,\
			/obj/item/clothing/neck/mantle/peltmountain,\
			/obj/item/clothing/neck/mantle/poncho,\
			/obj/item/clothing/neck/mantle/ragged,\
			/obj/item/clothing/neck/mantle/brown,\
			/obj/item/clothing/neck/mantle/gecko,\
			/obj/item/clothing/neck/garlic_necklace)
	head = pick(
		/obj/item/clothing/head/sombrero,\
		/obj/item/clothing/head/helmet/f13/raider,\
		/obj/item/clothing/head/helmet/f13/raider/eyebot,\
		/obj/item/clothing/head/helmet/f13/raider/arclight,\
		/obj/item/clothing/head/helmet/f13/raider/blastmaster,\
		/obj/item/clothing/head/helmet/f13/raider/yankee,\
		/obj/item/clothing/head/helmet/f13/raider/psychotic,\
		/obj/item/clothing/head/helmet/f13/fiend,\
		/obj/item/clothing/head/helmet/f13/hoodedmask,\
			/obj/item/clothing/head/helmet/f13/motorcycle,\
			/obj/item/clothing/head/helmet/f13/wastewarhat,\
			/obj/item/clothing/head/helmet/f13/fiend,\
			/obj/item/clothing/head/f13/bandit,\
			/obj/item/clothing/head/f13/ranger_hat/banded,\
			/obj/item/clothing/head/helmet/rus_ushanka,\
			/obj/item/clothing/head/helmet/skull,\
			/obj/item/clothing/head/collectable/petehat/gang,\
			/obj/item/clothing/head/hunter,\
			/obj/item/clothing/head/rice_hat,\
			/obj/item/clothing/head/papersack/smiley,\
			/obj/item/clothing/head/f13/pot,\
			/obj/item/clothing/head/cone,\
			/obj/item/clothing/head/kabuto,\
			/obj/item/clothing/head/cowboyhat/sec,\
			/obj/item/clothing/head/bomb_hood,\
			/obj/item/clothing/head/cardborg,\
			/obj/item/clothing/head/assu_helmet,\
			/obj/item/clothing/head/chefhat,\
			/obj/item/clothing/head/beret/headband,\
			/obj/item/clothing/head/fedora,\
			/obj/item/clothing/head/bowler,\
		)
	shoes = pick(
			/obj/item/clothing/shoes/jackboots,\
			/obj/item/clothing/shoes/f13/raidertreads)

	H.social_faction = FACTION_RAIDERS
	add_verb(H, /mob/living/proc/creategang)

/datum/outfit/job/wasteland/f13raider/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LONGPORKLOVER, src)


/datum/outfit/loadout/raider_sadist
	name = "Sadist"
	suit = /obj/item/clothing/suit/armor/light/raider/sadist
	head = /obj/item/clothing/head/helmet/f13/raider/arclight
	backpack_contents = list(
		/obj/item/restraints/legcuffs/bola=5,
		/obj/item/clothing/mask/gas/explorer/folded=1,
		/obj/item/storage/belt = 1,
		/obj/item/restraints/legcuffs/beartrap = 2,
		/obj/item/reverse_bear_trap = 1,
		/obj/item/melee/unarmed/lacerator = 1,
		)

/datum/outfit/loadout/raider_supafly
	name = "Supa-fly"
	suit = /obj/item/clothing/suit/armor/light/raider/supafly
	head = /obj/item/clothing/head/helmet/f13/raider/supafly
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/varmint = 1,
		/obj/item/ammo_box/magazine/m556/rifle/assault = 1,
		/obj/item/gun/ballistic/revolver/hobo/knucklegun = 1,
		/obj/item/ammo_box/c45rev = 2,
		/obj/item/gun_upgrade/scope/watchman = 1,
		/obj/item/reagent_containers/food/drinks/bottle/f13nukacola/radioactive = 1,
		/obj/item/grenade/smokebomb = 2,
		)

/datum/outfit/loadout/raider_yankee
	name = "Yankee"
	suit = /obj/item/clothing/suit/armor/medium/raider/yankee
	head = /obj/item/clothing/head/helmet/f13/raider/yankee
	backpack_contents = list(
		/obj/item/shishkebabpack = 1,
		/obj/item/storage/fancy/cigarettes/cigpack_cannabis = 1,
		/obj/item/megaphone = 1,
		/obj/item/storage/pill_bottle/chem_tin/buffout = 1)

/datum/outfit/loadout/raider_blast
	name = "Blastmaster"
	suit = /obj/item/clothing/suit/armor/medium/raider/blastmaster
	head = /obj/item/clothing/head/helmet/f13/raider/blastmaster
	backpack_contents = list(
		/obj/item/kitchen/knife/butcher = 1,
		/obj/item/grenade/homemade/firebomb = 4,
		/obj/item/bottlecap_mine = 1,
		/obj/item/grenade/homemade/coffeepotbomb = 4,
		/obj/item/book/granter/crafting_recipe/blueprint/trapper = 1,
		)

/datum/outfit/loadout/raider_badlands
	name = "Fiend"
	suit = /obj/item/clothing/suit/armor/medium/raider/badlands
	head = /obj/item/clothing/head/helmet/f13/fiend
	backpack_contents = list(
		/obj/item/gun/energy/laser/wattz = 1,
		/obj/item/stock_parts/cell/ammo/ec = 2,
		/obj/item/reagent_containers/hypospray/medipen/psycho = 3,
		/obj/item/reagent_containers/pill/patch/turbo = 2,
		/obj/item/reagent_containers/hypospray/medipen/medx = 1,
		)

/datum/outfit/loadout/raider_painspike
	name = "Painspike"
	suit = /obj/item/clothing/suit/armor/light/raider/painspike
	head = /obj/item/clothing/head/helmet/f13/raider/psychotic
	backpack_contents = list(
		/obj/item/gun/ballistic/shotgun/automatic/combat/shotgunlever = 1,
		/obj/item/ammo_box/shotgun/buck = 1,
		/obj/item/ammo_box/shotgun/bean = 1,
		/obj/item/melee/onehanded/club/fryingpan = 1,
		/obj/item/grenade/chem_grenade/cleaner = 1,
		)

/datum/outfit/loadout/quack_doctor
	name = "Quack Doctor"
	suit = /obj/item/clothing/suit/toggle/labcoat
	l_hand = /obj/item/storage/backpack/duffelbag/med/surgery
	suit_store = /obj/item/gun/energy/laser/wattz
	backpack_contents = list(
		/obj/item/stock_parts/cell/ammo/ec = 1,
		/obj/item/reagent_containers/pill/patch/jet = 3,
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/storage/pill_bottle/aranesp = 1,
		/obj/item/storage/pill_bottle/happy = 1,
		/obj/item/stack/sheet/mineral/silver = 2,
		/obj/item/clothing/accessory/pocketprotector/full = 1,
		)

/datum/outfit/loadout/raider_bos
	name = "Brotherhood Exile"
	suit = /obj/item/clothing/suit/armor/exile/bosexile
	id = /obj/item/card/id/rusted/brokenholodog
	backpack_contents = list(
		/obj/item/gun/energy/laser/wattz = 1,
		/obj/item/stock_parts/cell/ammo/ec = 1,
		/obj/item/book/granter/crafting_recipe/blueprint/aep7 = 1,
		/obj/item/grenade/f13/frag = 2,
		)

/datum/outfit/loadout/raider_smith
	name = "Raider Smith"
	suit = /obj/item/clothing/suit/armor/medium/raider/slam
	uniform = /obj/item/clothing/under/f13/raider_leather
	head = /obj/item/clothing/head/helmet/f13/raider/arclight
	gloves = /obj/item/clothing/gloves/f13/blacksmith
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/m1911/custom = 1,
		/obj/item/ammo_box/magazine/m45 = 1,
		/obj/item/twohanded/steelsaw = 1,
		/obj/item/melee/smith/hammer = 1,
		/obj/item/stack/sheet/mineral/sandstone = 50,
		/obj/item/book/granter/crafting_recipe/scav_one = 1,
		)

/datum/outfit/loadout/raider_vault
	name = "Vault Renegade"
	suit = /obj/item/clothing/suit/armor/medium/vest/bulletproof/big
	uniform = /obj/item/clothing/under/f13/exile/vault
	id = /obj/item/card/id/selfassign
	gloves = /obj/item/pda
	backpack_contents = list(
		/obj/item/gun/ballistic/revolver/thatgun = 1,
		/obj/item/pda = 1,
		)

/datum/outfit/loadout/raider_tribal
	name = "Tribal Outcast"
	uniform = /obj/item/clothing/under/f13/exile/tribal
	suit = /obj/item/clothing/suit/hooded/outcast/tribal
	suit_store = /obj/item/twohanded/spear/bonespear
	shoes = /obj/item/clothing/shoes/sandal
	belt = /obj/item/storage/backpack/spearquiver
	back = /obj/item/storage/backpack/satchel/explorer
	box = /obj/item/storage/survivalkit/tribal
	box_two = /obj/item/storage/survivalkit/medical/tribal
	backpack_contents = list(
		/obj/item/book/granter/trait/tribaltraditions = 1,
		/obj/item/clothing/mask/cigarette/pipe = 1,
		/obj/item/melee/onehanded/knife/bone = 1,
		)

/datum/outfit/loadout/raider_minutemen
	name = "Minutemen Traitor"
	suit = /obj/item/clothing/suit/armor/harpercoat
	uniform = /obj/item/clothing/under/f13/sleazeball
	head = /obj/item/clothing/head/helmet/f13/rustedcowboyhat/minutemen
	backpack_contents = list(
		/obj/item/gun/ballistic/rifle/hobo/lasmusket = 1,
		/obj/item/ammo_box/lasmusket = 2,
		/obj/item/radio/headset = 1
		)

/datum/job/baltimore_outlaw/warlord
	title = "Mercenary Warlord"
	flag = F13WARLORD
	department_head = list("Captain")
	head_announce = list("Security")
	total_positions = 1
	spawn_positions = 1
	description = "From the depth of Vault 125, you are the one chosen by your peers to lead the warband. Be carefull, some raiders may try to split, but it is your duty to bring order, and then bring chaos on wastelanders, making slaves and selling them."
	supervisors = "Your Employer, the Overseer of Vault 125"
	selection_color = "#df80af"
	exp_requirements = 0
	exp_type = EXP_TYPE_OUTLAW
	min_required_special = list(
		"special_c" = 5,
		)

	outfit = /datum/outfit/job/baltimore_outlaw/warlord

	access = list()
	minimal_access = list()
	matchmaking_allowed = list(
		/datum/matchmaking_pref/patron = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/protegee = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/outlaw = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/bounty_hunter = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
	)

	loadout_options = list(
		/datum/outfit/loadout/gunnerlord,
		/datum/outfit/loadout/talonlord,
		/datum/outfit/loadout/vaultlord,
		/datum/outfit/loadout/slaverlord
	)

/datum/outfit/job/baltimore_outlaw/warlord
	name =	"Warlord"
	jobtype = /datum/job/baltimore_outlaw/warlord
	uniform =	/obj/item/clothing/under/f13/combat
	ears = /obj/item/radio/headset/headset_vault
	shoes =	/obj/item/clothing/shoes/jackboots
	l_pocket = /obj/item/radio/outlaw
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit/outlaw
	backpack_contents = list(
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/gun/ballistic/automatic/pistol/automag = 1,
		/obj/item/ammo_box/magazine/m44/automag = 2,
		/obj/item/storage/survivalkit/medical/follower = 1,
		/obj/item/reagent_containers/medspray/synthflesh = 2,
		/obj/item/storage/wallet/stash/high = 1
	)

/datum/outfit/job/baltimore_outlaw/warlord/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LONGPORKLOVER, src)
	ADD_TRAIT(H, TRAIT_TRIBAL, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_FEARLESS, src)
	ADD_TRAIT(H, TRAIT_BERSERKER, src)

/datum/outfit/loadout/gunnerlord
	name = "Gunner Colonel"
	suit = /obj/item/clothing/suit/armor/heavy/salvaged_pa/gunner
	uniform = /obj/item/clothing/under/f13/gunner
	head = /obj/item/clothing/head/helmet/armyhelmet/heavy
	backpack_contents = list(
		/obj/item/gun/energy/laser/aer9 = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 3,
		)

/datum/outfit/loadout/talonlord
	name = "Talon Chief"
	suit = /obj/item/clothing/suit/armor/medium/combat/mk2/talon
	uniform = /obj/item/clothing/under/f13/locust
	head = /obj/item/clothing/head/helmet/f13/combat/dark
	backpack_contents = list(
		/obj/item/gun/ballistic/rifle/salvaged_eastern_rifle = 1,
		/obj/item/ammo_box/a556 = 2,
		)

/datum/outfit/loadout/vaultlord
	name = "Vault 125 Head of security"
	suit = /obj/item/clothing/suit/armor/light/duster/battlecoat/vault/raider
	uniform = /obj/item/clothing/under/f13/vault
	head = /obj/item/clothing/head/helmet/riot/vaultsec/vc
	backpack_contents = list(
		/obj/item/shishkebabpack = 1,
		/obj/item/gun/ballistic/automatic/lewis = 1,
		/obj/item/ammo_box/magazine/lewis/l47 = 2,
		)

/datum/outfit/loadout/slaverlord
	name = "Slave master"
	suit = /obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/raider
	uniform = /obj/item/clothing/under/f13/raiderrags
	head = /obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/raider
	backpack_contents = list(
		/obj/item/shishkebabpack = 1,
		/obj/item/gun/ballistic/automatic/smg/smg10mm = 1,
		/obj/item/ammo_box/magazine/m10mm/adv/ext = 2,
		)



// MERCENARY //


/datum/job/baltimore_outlaw/mercenary
	title = "Mercenary Soldier"
	flag = F13MERCENARY
	department_head = list("Captain")
	head_announce = list("Security")
	total_positions = 5
	spawn_positions = 5
	description = "Either a slaver, a Gunner, a Talon or even a Vault 125 vault dweller, your goal ? Distabilise the region."
	supervisors = "Your employer, Vault 125 overseer or the Mercenary War lord."
	selection_color = "#df80af"
	exp_requirements = 0
	exp_type = EXP_TYPE_OUTLAW
	faction = FACTION_MERCENARY

	outfit = /datum/outfit/job/mercenary

	access = list()
	minimal_access = list()
	matchmaking_allowed = list(
		/datum/matchmaking_pref/patron = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/protegee = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/outlaw = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
		/datum/matchmaking_pref/bounty_hunter = list(
			/datum/job/baltimore_outlaw/baltimoreoutlaws,
		),
	)

	loadout_options = list(
		/datum/outfit/loadout/gunner,
		/datum/outfit/loadout/talon,
		/datum/outfit/loadout/slaver
	)

/datum/outfit/job/mercenary
	name =	"Mercenary"
	jobtype =	/datum/job/baltimore_outlaw/mercenary
	uniform =	/obj/item/clothing/under/f13/combat
	ears = /obj/item/radio/headset/headset_vault
	shoes =	/obj/item/clothing/shoes/jackboots
	l_pocket = /obj/item/radio/outlaw
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit/outlaw
	backpack_contents = list(
		/obj/item/storage/firstaid/ancient = 1,
		/obj/item/storage/survivalkit/medical/follower = 1,
		/obj/item/reagent_containers/medspray/synthflesh = 2
	)

/datum/outfit/job/baltimore_outlaw/warlord/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()
	if(visualsOnly)
		return
	ADD_TRAIT(H, TRAIT_LONGPORKLOVER, src)
	ADD_TRAIT(H, TRAIT_TRIBAL, src)
	ADD_TRAIT(H, TRAIT_GENERIC, src)
	ADD_TRAIT(H, TRAIT_FEARLESS, src)
	ADD_TRAIT(H, TRAIT_BERSERKER, src)

/datum/outfit/loadout/gunner
	name = "Gunner"
	suit = /obj/item/clothing/suit/armor/medium/combat
	uniform = /obj/item/clothing/under/f13/gunner
	head = /obj/item/clothing/head/helmet/armyhelmet
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/combat = 1,
		/obj/item/ammo_box/magazine/tommygunm45/stick = 3,
		)

/datum/outfit/loadout/talon
	name = "Talon"
	suit = /obj/item/clothing/suit/armor/medium/combat/mk2/raider/talon_inferior
	uniform = /obj/item/clothing/under/f13/locust
	head = /obj/item/clothing/head/helmet/f13/combat/mk2/raider
	backpack_contents = list(
		/obj/item/gun/energy/laser/aer9 = 1,
		/obj/item/stock_parts/cell/ammo/mfc = 3,
		)
	
/datum/outfit/loadout/slaver
	name = "Slaver"
	suit = /obj/item/clothing/suit/armor/light/raider/badlands
	uniform = /obj/item/clothing/under/f13/raiderrags
	head = /obj/item/clothing/head/helmet/f13/raidercombathelmet
	backpack_contents = list(
		/obj/item/shishkebabpack = 1,
		/obj/item/gun/ballistic/automatic/pistol/ninemil/c93 = 1,
		/obj/item/ammo_box/magazine/m9mm = 4,
		)

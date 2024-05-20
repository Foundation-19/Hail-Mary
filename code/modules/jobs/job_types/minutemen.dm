/datum/job/wasteland/f13minutemen
	title = "Minuteman"
	flag = F13WASTELANDER
	faction = FACTION_WASTELAND
	total_positions = 4
	spawn_positions = 4
	description = "A beacon of liberty and light in the wastes. The Minutemen are freedom-fighters that aim to keep the wastes a safer and more just place."
	supervisors = "minutemen superiors"

	outfit = /datum/outfit/job/wasteland/f13minutemen

	access = list(ACCESS_TOWN_SEC)
	minimal_access = list(ACCESS_TOWN_SEC)
	matchmaking_allowed = list(
	/datum/matchmaking_pref/friend = list(
		/datum/job/wasteland/f13wastelander,
	),
	/datum/matchmaking_pref/rival = list(
		/datum/job/wasteland/f13wastelander,
	),
	)

/datum/outfit/job/wasteland/f13minutemen
	ears = /obj/item/radio/headset/headset_town
	shoes = /obj/item/clothing/shoes/f13/minutemen
	head = /obj/item/clothing/head/helmet/f13/rustedcowboyhat/minutemen
	l_pocket = /obj/item/storage/belt/legholster
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	belt = /obj/item/storage/belt/army/assault
	uniform = /obj/item/clothing/under/f13/minutemen
	suit = /obj/item/clothing/suit/armor/medium/duster/trenchcoat/minutemen
	suit_store = /obj/item/gun/ballistic/rifle/hobo/lasmusket
	r_pocket = /obj/item/flashlight/seclite
	gloves = /obj/item/clothing/gloves/f13/minutemen
	neck = /obj/item/clothing/neck/scarf/f13/minutemen
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimpak = 2,
		/obj/item/storage/survivalkit = 1,
		/obj/item/storage/survivalkit/medical = 1,
		/obj/item/ammo_box/lasmusket = 3
	)


/datum/job/smutant
	title = "Super Mutant"
	department_flag = SMUTANT
	selection_color = "#26bf47"
	faction = FACTION_SMUTANT
	total_positions = 10 
	spawn_positions = 10
	outfit = /datum/outfit/job/smutant

/datum/job/smutant/boss
	title = "Super Mutant Leader"
	department_flag = SMUTANT
	selection_color = "#26bf47"
	faction = FACTION_MUTANT
	total_positions = 1
	spawn_positions = 1

/datum/outfit/job/smutant
	name = "Super Mutant"
	jobtype = /datum/job/smutant
	suit = /obj/item/clothing/suit/armor/medium/vest
	suit_store = /obj/item/gun/ballistic/rifle/hunting
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/twohanded/fireaxe/bmprsword
	uniform = /obj/item/clothing/under/f13/tribe
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit
	box_two = /obj/item/storage/survivalkit/medical

/datum/outfit/job/smutant/boss
	name = "Super Mutant Leader"
	jobtype = /datum/job/smutant/boss
	suit = /obj/item/clothing/suit/armor/medium/vest
	suit_store = /obj/item/gun/ballistic/automatic/bar
	shoes = /obj/item/clothing/shoes/jackboots
	backpack = /obj/item/twohanded/fireaxe/bmprsword
	uniform = /obj/item/clothing/under/f13/tribe
	r_pocket = /obj/item/flashlight/flare
	box = /obj/item/storage/survivalkit
	box_two = /obj/item/storage/survivalkit/medical

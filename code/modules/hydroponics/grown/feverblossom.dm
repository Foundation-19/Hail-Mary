/obj/item/seeds/fever_blossom
	name = "pack of fever blossom seeds"
	desc = "These seeds grow into fever blossoms."
	icon_state = "seed-blossom"
	species = "feverblossom"
	plantname = "Fever Blossoms"
	product = /obj/item/reagent_containers/food/snacks/grown/fever_blossom
	endurance = 10
	maturation = 8
	yield = 6
	potency = 20
	growthstages = 4
	genes = list(/datum/plant_gene/trait/repeated_harvest, /datum/plant_gene/trait/glow/purple)
	growing_icon = 'icons/obj/hydroponics/growing_flowers.dmi'
	icon_grow = "feverblossom-grow"
	icon_dead = "feverblossom-dead"
	mutatelist = list()
	reagents_add = list(
		/datum/reagent/consumable/nutriment = 0.05,
		/datum/reagent/medicine/medx = 0.01,
		/datum/reagent/drug/psycho = 0.01,
		/datum/reagent/drug/jet = 0.04,
		/datum/reagent/uranium = 0.05
	)

/obj/item/reagent_containers/food/snacks/grown/fever_blossom
	seed = /obj/item/seeds/fever_blossom
	name = "fever blossom"
	desc = "A glowing flower of intricate design and a rich scent. It is a known hallucinogen and numbing agent. It is also highly radioactive."
	icon_state = "fever_blossom"
	slot_flags = ITEM_SLOT_HEAD
	filling_color = "#8000ff"
	bitesize_mod = 3
	tastes = list("pleasant flora" = 1)
	foodtype = VEGETABLES
	juice_results = list(/datum/reagent/consumable/fever_blossom_juice = 0)
	distill_reagent = /datum/reagent/consumable/ethanol/feverdream

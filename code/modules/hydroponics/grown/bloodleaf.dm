// Blood Leaf
/obj/item/seeds/bloodleaf
	name = "Bloodleaf Seeds"
	desc = "These seeds grow into bloodleaf."
	icon_state = "seed-bloodleaf"
	species = "bloodleaf"
	plantname = "Blood Leaf"
	product = /obj/item/reagent_containers/food/snacks/grown/bloodleaf
	icon_state = "seed-bloodleaf"
	lifespan = 25 
	endurance = 6
	yield = 2
	growthstages = 3
	production = 3
	maturation = 4
	growing_icon = 'icons/obj/hydroponics/growing_flowers.dmi'
	icon_harvest = "bloodleaf-harvest"
	icon_grow = "bloodleaf-grow"
	icon_dead = "bloodleaf-dead"
	reagents_add = list(
		/datum/reagent/blood/synthetics = 0.2,
		/datum/reagent/medicine/salglu_solution = 0.05,
		/datum/reagent/medicine/silver_sulfadiazine = 0.05,
		/datum/reagent/consumable/nutriment = 0.1,
	)

/obj/item/reagent_containers/food/snacks/grown/bloodleaf
	seed = /obj/item/seeds/bloodleaf
	name = "bloodleaf plant"
	desc = "Bloodleafs are large flowers that contain a unique healing property when mixed with water."
	icon_state = "bloodleaf"
	juice_results = list(/datum/reagent/consumable/bloodleafjuice = 0)
	distill_reagent = /datum/reagent/consumable/ethanol/bloodwine

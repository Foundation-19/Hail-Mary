/datum/crafting_recipe/jerrycan
	name = "Jerrycan"
	result = /obj/item/reagent_containers/jerrycan
	reqs = list(/obj/item/stack/sheet/plastic = 5)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 80
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS


/datum/crafting_recipe/fuel_tank
	name = "Fuel Tank"
	result = /obj/item/reagent_containers/fuel_tank
	reqs = list(/obj/item/stack/sheet/plastic = 10,
				/obj/item/stack/crafting/metalparts = 2)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 80
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/adv_fuel_tank
	name = "Upgrade Fuel Tank"
	result = /obj/item/reagent_containers/fuel_tank/upgraded
	reqs = list(/obj/item/reagent_containers/fuel_tank = 1,
				/obj/item/stack/crafting/goodparts = 2,
				/obj/item/stack/sheet/mineral/titanium = 5)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 80
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/hyper_fuel_tank
	name = "Hyper Fuel Tank"
	result = /obj/item/reagent_containers/fuel_tank/hyper
	reqs = list(/obj/item/reagent_containers/fuel_tank/upgraded = 1,
				/obj/item/stack/crafting/goodparts = 10,
				/obj/item/stack/sheet/mineral/diamond = 5)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 80
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS



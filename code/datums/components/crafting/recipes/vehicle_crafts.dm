// Caravan
/datum/crafting_recipe/carbase/truckcaravan
	name = "Carvan engineless Pickup"
	result = /obj/mecha/working/normalvehicle/truckcaravan
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck,
				/obj/item/stack/sheet/metal = 20,
				/obj/item/stack/cable_coil = 8)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLECOREPARTS


//Vertibird combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Combat Vertibird"
	result = /obj/mecha/combat/combatvehicle/vertibird
	reqs = list(/obj/mecha/working/normalvehicle/vertibird,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_CARS
	always_available = FALSE

//Vertibird NCR combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "NCR Combat Vertibird"
	result = /obj/mecha/combat/combatvehicle/vertibird/ncr
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/ncr,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_VERTIBIRD
	always_available = FALSE

//Vertibird BOS combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Brotherhood Combat Vertibird"
	result = /obj/mecha/combat/combatvehicle/vertibird/brotherhood
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/brotherhood,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_VERTIBIRD
	always_available = FALSE

//Vertibird Enclave combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Enclave Combat Vertibird"
	result = /obj/mecha/combat/combatvehicle/vertibird/enclave
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/enclave,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_VERTIBIRD
	always_available = FALSE

//Lebgion balloon combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Legion Balloon"
	result = /obj/mecha/combat/combatvehicle/vertibird/balloon
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/balloon,
				/obj/item/stack/sheet/metal = 50,
				/obj/item/stack/crafting/electronicparts = 25,
				/obj/item/reagent_containers/pill/bitterdrink = 1,
				/obj/item/stack/sheet/prewar = 25)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_VERTIBIRD
	always_available = FALSE

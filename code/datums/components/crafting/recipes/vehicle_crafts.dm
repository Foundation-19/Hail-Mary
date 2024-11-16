/datum/crafting_recipe/carbase/step1
	name = "Repair car carcass (Step 1)"
	result = /obj/structure/mecha_wreckage/ncrtruck
	reqs = list(/obj/structure/car/rubbish3,
				/obj/item/stack/crafting/goodparts = 8,
				/obj/item/stack/sheet/metal = 2,
				/obj/item/stack/sheet/prewar = 4,
				/obj/item/stack/sheet/mineral/silver = 2)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

/datum/crafting_recipe/carbase/step2
	name = "Add a car battery and engine (Step 2)"
	result = /obj/structure/mecha_wreckage/ncrtruck/engine
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck,
				/obj/item/vehiclecorepart/tires = 1,
				/obj/item/vehiclecorepart/engine = 1,
				/obj/item/defibrillator/primitive = 1,
				/obj/item/stack/cable_coil = 5)
	tools = list(TOOL_SCREWDRIVER, TOOL_WRENCH)
	time = 40

/datum/crafting_recipe/carbase/step3
	name = "Add a car seat, and electronics (Step 3)"
	result = /obj/structure/mecha_wreckage/ncrtruck/seat
	reqs = list(/obj/item/mecha_parts/mecha_equipment/seat = 1,
				/obj/item/stack/cable_coil = 10,
				/obj/item/stack/crafting/electronicparts = 15)
	tools = list(TOOL_SCREWDRIVER, TOOL_WRENCH)
	time = 20

// Caravan
/datum/crafting_recipe/carbase/truckcaravan
	name = "Carvan Pickup (Skipped Step 2 and 3)"
	result = /obj/mecha/working/normalvehicle/truckcaravan
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck,
				/obj/item/stack/sheet/metal = 20,
				/obj/item/stack/cable_coil = 8,)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Red Truck
/datum/crafting_recipe/carbase/truck
	name = "Red Pickup Truck (Final Step)"
	result = /obj/mecha/working/normalvehicle/pickuptruck/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 10,
				/obj/item/stack/sheet/metal = 30,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 4)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Blue Truck
/datum/crafting_recipe/carbase/truck/blue
	name = "Blue Pickup Truck (Final Step)"
	result = /obj/mecha/working/normalvehicle/pickuptruck/blue/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 10,
				/obj/item/stack/sheet/metal = 30,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 4)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//BOS Truck
/datum/crafting_recipe/carbase/truck/bos
	name = "BOS Pickup Truck (Final Step)"
	result = /obj/mecha/working/normalvehicle/pickuptruck/bos/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 10,
				/obj/item/stack/sheet/metal = 30,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 4)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Buggy 
/datum/crafting_recipe/carbase/buggy
	name = "Buggy (Final Step)"
	result = /obj/mecha/working/normalvehicle/buggy/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 5,
				/obj/item/stack/sheet/metal = 15,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 10)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Buggy Dune
/datum/crafting_recipe/carbase/buggy/dune
	name = "Dune Buggy (Final Step)"
	result = /obj/mecha/working/normalvehicle/buggy/dune/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 5,
				/obj/item/stack/sheet/metal = 15,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 10)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Buggy Blue
/datum/crafting_recipe/carbase/buggy/blue
	name = "Blue Buggy (Final Step)"
	result = /obj/mecha/working/normalvehicle/buggy/blue/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 5,
				/obj/item/stack/sheet/metal = 15,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 10)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//buggy flamme
/datum/crafting_recipe/carbase/buggy/flamme
	name = "Flamme Buggy (Final Step)"
	result = /obj/mecha/working/normalvehicle/buggy/flamme/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 5,
				/obj/item/stack/sheet/metal = 15,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 10)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Corvega
/datum/crafting_recipe/carbase/corvega
	name = "Corvega (Final Step)"
	result = /obj/mecha/working/normalvehicle/corvega/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 15,
				/obj/item/stack/sheet/metal = 35,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 15)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Buggy Ranger
/datum/crafting_recipe/carbase/buggy/ranger
	name = "NCR Ranger Buggy (Final Step)"
	result = /obj/mecha/working/normalvehicle/buggy/ranger/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 5,
				/obj/item/stack/sheet/metal = 15,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 10)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	always_available = FALSE

//Buggy legion
/datum/crafting_recipe/carbase/buggy/legion
	name = "Legion Chariot Buggy (Final Step)"
	result = /obj/mecha/working/normalvehicle/buggy/legion/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 5,
				/obj/item/stack/sheet/metal = 15,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 10)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	always_available = FALSE

//Highwayman
/datum/crafting_recipe/carbase/highwayman
	name = "Highwayman (Final Step)"
	result = /obj/mecha/working/normalvehicle/highwayman/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 15,
				/obj/item/stack/sheet/metal = 35,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 15)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100


//Highwayman
/datum/crafting_recipe/carbase/highwayman
	name = "Highwayman (Final Step)"
	result = /obj/mecha/working/normalvehicle/highwayman/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 15,
				/obj/item/stack/sheet/metal = 35,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 15)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//jeep

/datum/crafting_recipe/carbase/jeep
	name = "Jeep (Final Step)"
	result = /obj/mecha/working/normalvehicle/jeep/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 10,
				/obj/item/stack/sheet/metal = 40,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 25)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Jeep enclave

/datum/crafting_recipe/carbase/jeep/enclave
	name = "Enclave Jeep (Final Step)"
	result = /obj/mecha/working/normalvehicle/jeep/enclave/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 10,
				/obj/item/stack/sheet/metal = 40,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 25)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Jeep BOS

/datum/crafting_recipe/carbase/jeep/enclave
	name = "Enclave Jeep (Final Step)"
	result = /obj/mecha/working/normalvehicle/jeep/bos/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 10,
				/obj/item/stack/sheet/metal = 40,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 25)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	always_available = FALSE

//NCR Truck

/datum/crafting_recipe/carbase/ncrtruck
	name = "NCR MP Truck (Final Step)"
	result = /obj/mecha/working/normalvehicle/ncrtruck/mp/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 20,
				/obj/item/stack/sheet/metal = 50,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 30)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

/datum/crafting_recipe/carbase/ncrtruck/mp
	name = "NCR Truck (Final Step)"
	result = /obj/mecha/working/normalvehicle/ncrtruck/loaded
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 20,
				/obj/item/stack/sheet/metal = 50,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 30)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100
	always_available = FALSE


//BOS Truck ARMED
/datum/crafting_recipe/carbase/truck/bos/armed
	name = "BOS Truck Gunner station (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/pickuptruck/bos/armed
	reqs = list(/obj/mecha/working/normalvehicle/pickuptruck/bos,
				/obj/item/stack/sheet/metal = 20,
				/obj/item/trash/f13/electronic/toaster =1,
				/obj/item/stack/sheet/prewar = 4)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Ranger buggy ARMED
/datum/crafting_recipe/carbase/buggy/ranger/armed
	name = "Ranger buggy gunner station (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/buggy/rangerarmed
	reqs = list(/obj/mecha/working/normalvehicle/buggy/ranger,
				/obj/item/stack/sheet/metal = 20,
				/obj/item/reagent_containers/food/drinks/bottle/whiskey = 1,
				/obj/item/stack/sheet/prewar = 4)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//legion buggy ARMED
/datum/crafting_recipe/carbase/buggy/legion/armed
	name = "Legion buggy gunner station (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/buggy/legionarmed
	reqs = list(/obj/mecha/working/normalvehicle/buggy/legion,
				/obj/item/stack/sheet/metal = 20,
				/obj/item/reagent_containers/pill/bitterdrink = 1,
				/obj/item/stack/sheet/prewar = 4)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Vertibird combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Combat Vertibird (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/vertibird
	reqs = list(/obj/mecha/working/normalvehicle/vertibird,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Vertibird NCR combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Combat NCR Vertibird (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/vertibird/ncr
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/ncr,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Vertibird BOS combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Combat BOS Vertibird (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/vertibird/brotherhood
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/brotherhood,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Vertibird Enclave combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Combat Enclave Vertibird (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/vertibird/enclave
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/enclave,
				/obj/item/stack/sheet/metal = 100,
				/obj/item/stack/crafting/electronicparts = 50,
				/obj/item/stack/sheet/prewar = 50)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

//Lebgion balloon combat conversion
/datum/crafting_recipe/carbase/vertibird/armed
	name = "Legion Balloon (Arming Step - REMOVE ALL MODULE FROM CAR BEFORE MODIFYING)"
	result = /obj/mecha/combat/combatvehicle/vertibird/balloon
	reqs = list(/obj/mecha/working/normalvehicle/vertibird/balloon,
				/obj/item/stack/sheet/metal = 50,
				/obj/item/stack/crafting/electronicparts = 25,
				/obj/item/reagent_containers/pill/bitterdrink = 1,
				/obj/item/stack/sheet/prewar = 25)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

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

//Buggy 
/datum/crafting_recipe/carbase/buggy
	name = "Buggy (Final Step)"
	result = /obj/mecha/combat/combatvehicle/buggy
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
	result = /obj/mecha/combat/combatvehicle/buggy/dune
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
	result = /obj/mecha/combat/combatvehicle/buggy/blue
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
	result = /obj/mecha/combat/combatvehicle/buggy/flamme
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
	result = /obj/mecha/combat/combatvehicle/corvega
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
	result = /obj/mecha/combat/combatvehicle/highwayman
	reqs = list(/obj/structure/mecha_wreckage/ncrtruck/seat,
				/obj/item/stack/sheet/glass = 15,
				/obj/item/stack/sheet/metal = 35,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/stack/sheet/prewar = 15)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 100

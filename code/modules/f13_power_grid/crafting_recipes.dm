// Crafting recipes for the F13 faction power grid.
// Machines spawn unanchored so they can be carried to the install site; wrench to anchor.

/obj/machinery/f13/power_relay/CheckParts(list/parts_list, datum/crafting_recipe/R)
	. = ..()
	if(R) anchored = FALSE

/obj/machinery/f13/junction_box/CheckParts(list/parts_list, datum/crafting_recipe/R)
	. = ..()
	if(R) anchored = FALSE

/obj/machinery/f13/faction_generator/wastelander/CheckParts(list/parts_list, datum/crafting_recipe/R)
	. = ..()
	if(R)
		anchored = FALSE
		grounded = FALSE

// A grounding rod consumes on use; no crafted item carries a machine ID.
/obj/item/f13/grounding_rod
	name = "grounding rod"
	desc = "A copper-clad steel spike with a bonding terminal and a length of bare copper wire. Drive it into earth beside a generator and connect the wire to ground the chassis — prevents stray leakage current from energising the frame."
	icon = 'icons/obj/tools.dmi'
	icon_state = "crowbar"
	w_class = WEIGHT_CLASS_SMALL
	force = 3

/datum/crafting_recipe/f13_power_grid
	category = CAT_SETTLEMENT
	subcategory = CAT_ELECTRICAL

/datum/crafting_recipe/f13_power_grid/wastelander_generator
	name = "Jury-rigged Generator"
	result = /obj/machinery/f13/faction_generator/wastelander
	reqs = list(
		/obj/item/stack/sheet/metal = 20,
		/obj/item/stack/crafting/metalparts = 10,
		/obj/item/stack/crafting/electronicparts = 5,
		/obj/item/stack/cable_coil = 5,
	)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_WRENCH)
	time = 120

/datum/crafting_recipe/f13_power_grid/power_relay
	name = "Power Relay Post"
	result = /obj/machinery/f13/power_relay
	reqs = list(
		/obj/item/stack/sheet/metal = 5,
		/obj/item/stack/crafting/metalparts = 5,
		/obj/item/stack/crafting/electronicparts = 3,
		/obj/item/stack/cable_coil = 5,
	)
	tools = list(TOOL_WORKBENCH, TOOL_SCREWDRIVER)
	time = 60

/datum/crafting_recipe/f13_power_grid/junction_box
	name = "Junction Box"
	result = /obj/machinery/f13/junction_box
	reqs = list(
		/obj/item/stack/sheet/metal = 10,
		/obj/item/stack/crafting/metalparts = 8,
		/obj/item/stack/crafting/electronicparts = 5,
		/obj/item/stack/cable_coil = 10,
	)
	tools = list(TOOL_WORKBENCH, TOOL_SCREWDRIVER)
	time = 80

/datum/crafting_recipe/f13_power_grid/junction_box_small
	name = "Small Junction Box"
	result = /obj/machinery/f13/junction_box/small
	reqs = list(
		/obj/item/stack/sheet/metal = 5,
		/obj/item/stack/crafting/metalparts = 4,
		/obj/item/stack/crafting/electronicparts = 3,
		/obj/item/stack/cable_coil = 5,
	)
	tools = list(TOOL_WORKBENCH, TOOL_SCREWDRIVER)
	time = 60

/datum/crafting_recipe/f13_power_grid/junction_box_large
	name = "Large Junction Box"
	result = /obj/machinery/f13/junction_box/large
	reqs = list(
		/obj/item/stack/sheet/metal = 15,
		/obj/item/stack/crafting/metalparts = 12,
		/obj/item/stack/crafting/electronicparts = 8,
		/obj/item/stack/cable_coil = 15,
	)
	tools = list(TOOL_WORKBENCH, TOOL_SCREWDRIVER, TOOL_WRENCH)
	time = 100

/datum/crafting_recipe/f13_power_grid/breaker_box
	name = "Breaker Box"
	result = /obj/machinery/f13/power_relay/breaker_box
	reqs = list(
		/obj/item/stack/sheet/metal = 5,
		/obj/item/stack/crafting/metalparts = 4,
		/obj/item/stack/crafting/electronicparts = 2,
		/obj/item/stack/cable_coil = 5,
	)
	tools = list(TOOL_WORKBENCH, TOOL_SCREWDRIVER)
	time = 60

/datum/crafting_recipe/f13_power_grid/power_logic_gate
	name = "Power Logic Gate"
	result = /obj/machinery/f13/logic_gate
	reqs = list(
		/obj/item/stack/sheet/metal = 3,
		/obj/item/stack/crafting/metalparts = 2,
		/obj/item/stack/crafting/electronicparts = 5,
		/obj/item/stack/cable_coil = 3,
	)
	tools = list(TOOL_WORKBENCH, TOOL_MULTITOOL)
	time = 40

/datum/crafting_recipe/f13_power_grid/grounding_rod
	name = "Grounding Rod"
	result = /obj/item/f13/grounding_rod
	reqs = list(
		/obj/item/stack/sheet/metal = 2,
		/obj/item/stack/cable_coil = 2,
	)
	tools = list(TOOL_WIRECUTTER)
	time = 15

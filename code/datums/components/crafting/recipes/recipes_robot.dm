
/datum/crafting_recipe/ed209
	name = "ED209"
	result = /mob/living/simple_animal/bot/ed209
	reqs = list(/obj/item/robot_suit = 1,
				/obj/item/clothing/head/helmet = 1,
				/obj/item/clothing/suit/armor/medium/vest = 1,
				/obj/item/bodypart/l_leg/robot = 1,
				/obj/item/bodypart/r_leg/robot = 1,
				/obj/item/stack/sheet/metal = 1,
				/obj/item/stack/cable_coil = 1,
				/obj/item/gun/energy/e_gun/advtaser = 1,
				/obj/item/stock_parts/cell = 1,
				/obj/item/assembly/prox_sensor = 1)
	tools = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 60
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/secbot
	name = "Secbot"
	result = /mob/living/simple_animal/bot/secbot
	reqs = list(/obj/item/assembly/signaler = 1,
				/obj/item/clothing/head/helmet/sec = 1,
				/obj/item/melee/baton = 1,
				/obj/item/assembly/prox_sensor = 1,
				/obj/item/bodypart/r_arm/robot = 1)
	tools = list(TOOL_WELDER)
	time = 60
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/cleanbot
	name = "Cleanbot"
	result = /mob/living/simple_animal/bot/cleanbot
	reqs = list(/obj/item/reagent_containers/glass/bucket = 1,
				/obj/item/assembly/prox_sensor = 1,
				/obj/item/bodypart/r_arm/robot = 1)
	time = 40
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/floorbot
	name = "Floorbot"
	result = /mob/living/simple_animal/bot/floorbot
	reqs = list(/obj/item/storage/toolbox/mechanical = 1,
				/obj/item/stack/tile/plasteel = 1,
				/obj/item/assembly/prox_sensor = 1,
				/obj/item/bodypart/r_arm/robot = 1)
	time = 40
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/*/datum/crafting_recipe/medbot
	name = "Medbot"
	result = /mob/living/simple_animal/bot/medbot
	reqs = list(/obj/item/healthanalyzer = 1,
				/obj/item/storage/firstaid = 1,
				/obj/item/assembly/prox_sensor = 1,
				/obj/item/bodypart/r_arm/robot = 1)
	time = 40
		subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC
	*/

/datum/crafting_recipe/Firebot
	name = "Firebot"
	result = /mob/living/simple_animal/bot/firebot
	reqs = list(/obj/item/extinguisher = 1,
				/obj/item/bodypart/r_arm/robot = 1,
				/obj/item/assembly/prox_sensor = 1,
				/obj/item/clothing/head/hardhat/red = 1)
	time = 40
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

// -- CYBORG BODYPARTS --
// Blueprint-gated recipes replacing the absent mechfab path.
// Crafted at an Advanced Workbench; assemble all six onto a robot_suit
// endoskeleton via the existing click-assembly mechanic, then insert an MMI.

/datum/crafting_recipe/cyborg_robot_suit
	name = "Cyborg Endoskeleton"
	result = /obj/item/robot_suit
	reqs = list(
				/obj/item/stack/sheet/metal = 8,
				/obj/item/stack/crafting/metalparts = 2,
				/obj/item/stack/crafting/goodparts = 1
				)
	tools = list(TOOL_AWORKBENCH)
	time = 120
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/cyborg_torso
	name = "Cyborg Torso"
	result = /obj/item/bodypart/chest/robot
	reqs = list(
				/obj/item/stack/sheet/metal = 15,
				/obj/item/stack/crafting/metalparts = 3,
				/obj/item/stack/crafting/electronicparts = 2,
				/obj/item/stack/crafting/goodparts = 1
				)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/cyborg_head
	name = "Cyborg Head"
	result = /obj/item/bodypart/head/robot
	reqs = list(
				/obj/item/stack/sheet/metal = 5,
				/obj/item/stack/crafting/metalparts = 1,
				/obj/item/stack/crafting/electronicparts = 3
				)
	tools = list(TOOL_AWORKBENCH)
	time = 120
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/cyborg_l_arm
	name = "Cyborg Left Arm"
	result = /obj/item/bodypart/l_arm/robot
	reqs = list(
				/obj/item/stack/sheet/metal = 5,
				/obj/item/stack/crafting/metalparts = 2
				)
	tools = list(TOOL_AWORKBENCH)
	time = 90
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/cyborg_r_arm
	name = "Cyborg Right Arm"
	result = /obj/item/bodypart/r_arm/robot
	reqs = list(
				/obj/item/stack/sheet/metal = 5,
				/obj/item/stack/crafting/metalparts = 2
				)
	tools = list(TOOL_AWORKBENCH)
	time = 90
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/cyborg_l_leg
	name = "Cyborg Left Leg"
	result = /obj/item/bodypart/l_leg/robot
	reqs = list(
				/obj/item/stack/sheet/metal = 5,
				/obj/item/stack/crafting/metalparts = 2
				)
	tools = list(TOOL_AWORKBENCH)
	time = 90
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/cyborg_r_leg
	name = "Cyborg Right Leg"
	result = /obj/item/bodypart/r_leg/robot
	reqs = list(
				/obj/item/stack/sheet/metal = 5,
				/obj/item/stack/crafting/metalparts = 2
				)
	tools = list(TOOL_AWORKBENCH)
	time = 90
	category = CAT_MISC
	subcategory = CAT_MISCELLANEOUS
	always_available = FALSE

/datum/crafting_recipe/aitater
	name = "intelliTater"
	result = /obj/item/aicard/aitater
	time = 30
	tools = list(TOOL_WIRECUTTER)
	reqs = list(/obj/item/aicard = 1,
				/obj/item/reagent_containers/food/snacks/grown/potato = 1,
				/obj/item/stack/cable_coil = 5)
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/aispook
	name = "intelliLantern"
	result = /obj/item/aicard/aispook
	time = 30
	tools = list(TOOL_WIRECUTTER)
	reqs = list(/obj/item/aicard = 1,
					/obj/item/reagent_containers/food/snacks/grown/pumpkin = 1,
					/obj/item/stack/cable_coil = 5)
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

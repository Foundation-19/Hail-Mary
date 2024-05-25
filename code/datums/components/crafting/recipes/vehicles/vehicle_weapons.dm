/datum/crafting_recipe/lmgammo
	name = "LMG Ammo for vehicules"
	result = /obj/item/mecha_ammo/lmg/craftable
	reqs = list(/obj/item/ammo_box/a556 = 1)
	tools = list(TOOL_WORKBENCH)
	time = 5
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEAMMO

/datum/crafting_recipe/gun/LMGvehicule
	name = "Improvised LMG (for vehicules)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/hobo
	reqs = list(/obj/item/gun/ballistic/automatic/autopipe = 2,
	/obj/item/stack/crafting/metalparts = 10,
	/obj/item/stack/sheet/prewar = 8,
	/obj/item/stack/sheet/mineral/titanium = 8,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEWEAPONS

/datum/crafting_recipe/gun/lasermount_vehicle
	name = "vehicle-mounted laser rifle"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	reqs = list(/obj/item/stock_parts/scanning_module/phasic = 3,
	/obj/item/stack/crafting/goodparts = 5,
	/obj/item/stack/sheet/prewar = 10,
	/obj/item/stack/sheet/mineral/titanium = 5,
	/obj/item/stack/sheet/mineral/gold = 3,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEWEAPONS

/datum/crafting_recipe/gun/heavylasermount_vehicle
	name = "vehicle-mounted heavy laser rifle"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy
	reqs = list(/obj/item/stock_parts/scanning_module/phasic = 6,
	/obj/item/stack/crafting/goodparts = 10,
	/obj/item/stack/sheet/prewar = 10,
	/obj/item/stack/sheet/mineral/titanium = 10,
	/obj/item/stack/sheet/mineral/gold = 5,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEWEAPONS

/datum/crafting_recipe/gun/plasmamount_vehicle
	name = "vehicle-mounted Plasma caster"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/plasma
	reqs = list(/obj/item/stock_parts/micro_laser/ultra = 6,
	/obj/item/stack/crafting/goodparts = 10,
	/obj/item/stack/sheet/prewar = 10,
	/obj/item/stack/sheet/mineral/titanium = 10,
	/obj/item/stack/sheet/mineral/diamond = 5,
	/obj/item/stack/sheet/mineral/gold = 10,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEWEAPONS

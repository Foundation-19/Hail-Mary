/datum/crafting_recipe/jerrycan
	name = "Jerrycan"
	result = /obj/item/reagent_containers/jerrycan
	reqs = list(/obj/item/stack/sheet/plastic = 5)
	tools = list(TOOL_WELDER, TOOL_WRENCH)
	time = 80
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/mountedseat
	name = "Mounted seat"
	result = /obj/item/mecha_parts/mecha_equipment/seat
	reqs = list(/obj/item/stack/sheet/plastic = 2,
				/obj/item/stack/sheet/cloth = 4)
	time = 20
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

//HMG

/datum/crafting_recipe/gun/HMGvehicle
	name = "Improvised HMG (for vehicles)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/hobo
	reqs = list(/obj/item/gun/ballistic/automatic/autopipe = 2,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 5,
	/obj/item/stack/sheet/mineral/titanium = 5,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/HMGvehicle/normal
	name = "Normal HMG (for vehicles)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/hobo = 1,
	/obj/item/stack/crafting/metalparts = 2,
	/obj/item/stack/sheet/prewar = 6,
	/obj/item/stack/sheet/mineral/titanium = 6,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/HMGvehicle/upgraded
	name = "Upgraded HMG (for vehicles)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/auto
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg = 1,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 8,
	/obj/item/stack/sheet/mineral/titanium = 8,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/lmgammo
	name = "LMG Ammo for vehicles"
	result = /obj/item/mecha_ammo/lmg/craftable
	reqs = list(/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 5,
	/obj/item/stack/ore/blackpowder = 1,
	/obj/item/stack/sheet/mineral/titanium = 1,
	)
	tools = list(TOOL_WORKBENCH)
	time = 5
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/*/datum/crafting_recipe/gun/minigunVehicle
	name = "Minigun"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun
	reqs = list(/obj/item/stack/crafting/metalparts = 10,
	/obj/item/stack/crafting/goodparts = 5,
	/obj/item/stack/crafting/electronicparts = 5,
	/obj/item/stack/sheet/metal = 10,
	/obj/item/stack/sheet/mineral/titanium = 20,
	/obj/item/stack/rods = 6,
	/obj/item/advanced_crafting_components/assembly = 1,
	/obj/item/advanced_crafting_components/receiver = 1,
	/obj/item/advanced_crafting_components/alloys = 1)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON*/

/*

/datum/crafting_recipe/gun/PheumonicLauncherVehicle
	name = "Mounted Pheumonic launcher"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind
	reqs = list(/obj/item/stack/crafting/metalparts = 20,
	/obj/item/stack/crafting/goodparts = 10,
	/obj/item/stack/crafting/electronicparts = 5,
	/obj/item/stack/sheet/metal = 30,
	/obj/item/stack/sheet/mineral/titanium = 20,
	/obj/item/stack/rods = 8,
	/obj/item/advanced_crafting_components/assembly = 1,
	/obj/item/advanced_crafting_components/receiver = 1)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

*/

/*/datum/crafting_recipe/mech_ammo/brm8_missiles
	name = "Minigun Ammo Pack"
	result = /obj/item/mecha_ammo/minigun
	reqs = list(/obj/item/ammo_box/magazine/ammobelt/m1919 = 3,
	/obj/item/stack/sheet/metal = 10,
	/obj/item/stack/sheet/mineral/titanium = 20,
	/obj/item/stack/crafting/powder = 30)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_WEAPONRY
	subcategory = CAT_AMMO*/

//shotgun

/datum/crafting_recipe/gun/shotgunvehicle
	name = "Improvised Shotgun (for vehicles)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/hobo
	reqs = list(/obj/item/gun/ballistic/revolver/hobo/single_shotgun = 2,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 5,
	/obj/item/stack/sheet/mineral/titanium = 5,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/shotgunvehicle/normal
	name = "Shotgun (for vehicles)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/hobo = 1,
	/obj/item/stack/crafting/metalparts = 2,
	/obj/item/stack/sheet/prewar = 6,
	/obj/item/stack/sheet/mineral/titanium = 6,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/HMGvehicle/upgraded
	name = "Upgraded Shotgun (for vehicles)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/auto
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot = 1,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 8,
	/obj/item/stack/sheet/mineral/titanium = 8,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/lmgammo
	name = "Shotgun Ammo for vehicles"
	result = /obj/item/mecha_ammo/scattershot
	reqs = list(/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 5,
	/obj/item/stack/ore/blackpowder = 1,
	/obj/item/stack/sheet/mineral/titanium = 1,
	)
	tools = list(TOOL_WORKBENCH)
	time = 5
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

//laser weaponery

/datum/crafting_recipe/gun/laserlight
	name = "Laser Weapon, light (for vehicles) (AEP)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	reqs = list(/obj/item/stack/sheet/metal = 15,
				/obj/item/advanced_crafting_components/lenses = 1,
				/obj/item/gun/energy/laser/pistol = 2,
				/obj/item/stack/crafting/electronicparts = 3,
				/obj/item/stack/rods = 2
				)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/laserlight/wattz
	name = "Laser Weapon, light (for vehicles) (Wattz1k)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	reqs = list(/obj/item/stack/sheet/metal = 15,
				/obj/item/advanced_crafting_components/lenses = 1,
				/obj/item/gun/energy/laser/wattz = 3,
				/obj/item/stack/crafting/electronicparts = 3,
				/obj/item/stack/rods = 2
				)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/laserheavy
	name = "Laser Weapon, Heavy (for vehicles) (AER9)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	reqs = list(/obj/item/stack/sheet/metal = 30,
				/obj/item/advanced_crafting_components/lenses = 1,
				/obj/item/gun/energy/laser/aer9 = 2,
				/obj/item/stack/crafting/electronicparts = 6,
				/obj/item/stack/rods = 4
				)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/laserheavy/wattz
	name = "Laser Weapon, Heavy (for vehicles) (AER9)"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	reqs = list(/obj/item/stack/sheet/metal = 30,
				/obj/item/advanced_crafting_components/lenses = 1,
				/obj/item/gun/energy/laser/wattz2k = 1,
				/obj/item/stack/crafting/electronicparts = 6,
				/obj/item/stack/rods = 4
				)
	tools = list(TOOL_AWORKBENCH)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/repaireyebot
	name = "Repair eyebot"
	result = /obj/item/mecha_parts/mecha_equipment/repair_droid
	reqs = list(/obj/item/stack/crafting/electronicparts = 10,
				/obj/item/stack/crafting/metalparts = 8,
				/obj/item/weldingtool/basic = 5,
				/obj/item/advanced_crafting_components/alloys = 1,
				/obj/item/stack/crafting/goodparts = 4)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/vehiculearmor
	name = "Armor booster module (Close Combat Weaponry)"
	result = /obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster
	reqs = list(/obj/item/stack/crafting/electronicparts = 40,
				/obj/item/stack/crafting/metalparts = 10,
				/obj/item/advanced_crafting_components/alloys = 2,
				/obj/item/stack/crafting/goodparts = 4)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/vehiculearmor/distance
	name = "Armor booster module (Ranged Weaponry)"
	result = /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster
	reqs = list(/obj/item/stack/crafting/electronicparts = 40,
				/obj/item/stack/crafting/metalparts = 10,
				/obj/item/advanced_crafting_components/alloys = 2,
				/obj/item/stack/crafting/goodparts = 4)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 180
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/carpart/trunk
	name = "Modular Trunk"
	result = /obj/item/mecha_parts/mecha_equipment/trunk
	reqs = list(/obj/item/stack/sheet/metal = 5,
	/obj/item/stack/crafting/metalparts = 10,
	/obj/item/stack/sheet/plastic = 5,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 90
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

//Core parts

/datum/crafting_recipe/engine
	name = "Repaired Engine"
	result = /obj/item/vehiclecorepart/engine
	reqs = list(/obj/structure/wreck/trash/engine,
				/obj/item/stack/crafting/metalparts = 10,
				/obj/item/stack/crafting/goodparts = 4)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 100
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLECOREPARTS

/datum/crafting_recipe/tires
	name = "Repaired tires"
	result = /obj/item/vehiclecorepart/tires
	reqs = list(/obj/structure/tires,
				/obj/item/stack/sheet/plastic = 4)
	tools = list(TOOL_WELDER)
	time = 20
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLECOREPARTS

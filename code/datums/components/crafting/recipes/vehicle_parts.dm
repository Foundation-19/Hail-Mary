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

//LMG

/datum/crafting_recipe/gun/vehicle/lmg_improvised
	name = "Improvised vehicular LMG"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/improvised
	reqs = list(/obj/item/gun/ballistic/automatic/autopipe = 2,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 5,
	/obj/item/stack/sheet/mineral/titanium = 5,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 1
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/vehicle/lmg_normal
	name = "Standard vehicular LMG"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/improvised = 1,
	/obj/item/stack/crafting/metalparts = 2,
	/obj/item/stack/sheet/prewar = 6,
	/obj/item/stack/sheet/mineral/titanium = 6,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 1
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/vehicle/lmg_rapid
	name = "Rapid-fire vehicular LMG"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg = 1,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 8,
	/obj/item/stack/sheet/mineral/titanium = 8,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 1
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/lmg_ammo
	name = "Vehicular LMG ammunition"
	result = /obj/item/mecha_ammo/lmg/craftable
	reqs = list(/obj/item/stack/crafting/metalparts = 3,
	/obj/item/stack/sheet/prewar = 3,
	/obj/item/stack/ore/blackpowder = 1,
	/obj/item/stack/sheet/mineral/titanium = 1,
	)
	tools = list(TOOL_WORKBENCH)
	time = 5
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

// Minigun and Ammo

/datum/crafting_recipe/gun/vehicle/minigun
	name = "Vehicular Minigun"
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
	time = 1 // test test!!
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/datum/crafting_recipe/mech_ammo/minigun_ammo
	name = "Vehicular Minigun ammunition"
	result = /obj/item/mecha_ammo/minigun
	reqs = list(/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/metal = 5,
	/obj/item/stack/sheet/mineral/titanium = 5,
	/obj/item/stack/ore/blackpowder = 5)
	tools = list(TOOL_WORKBENCH)
	time = 1
	category = CAT_WEAPONRY
	subcategory = CAT_AMMO


/datum/crafting_recipe/box/lotsofgoodstuff
	name = "testing box o truth and goodies"
	result = /obj/item/box/allsortsofgoodstuff
	reqs = list(/obj/item/stack/rods = 1)
	tools = list(TOOL_WORKBENCH)
	time = 1
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/obj/item/box/allsortsofgoodstuff #warn // remove this
	name = "good box"

/obj/item/storage/box/allsortsofgoodstuff/PopulateContents() 	//less uranium because radioactive
	var/static/items_inside = list(
		/obj/item/stack/sheet/metal/fifty=1,\
		/obj/item/stack/sheet/glass/fifty=1,\
		/obj/item/stack/sheet/rglass=50,\
		/obj/item/stack/sheet/plasmaglass=50,\
		/obj/item/stack/sheet/titaniumglass=50,\
		/obj/item/stack/sheet/plastitaniumglass=50,\
		/obj/item/stack/sheet/plasteel=50,\
		/obj/item/stack/sheet/mineral/plastitanium=50,\
		/obj/item/stack/sheet/mineral/titanium=50,\
		/obj/item/stack/sheet/mineral/gold=50,\
		/obj/item/stack/sheet/mineral/silver=50,\
		/obj/item/stack/sheet/mineral/plasma=50,\
		/obj/item/stack/sheet/mineral/uranium=50,\
		/obj/item/stack/sheet/mineral/diamond=50,\
		/obj/item/stack/sheet/mineral/wood=50,\
		/obj/item/stack/sheet/plastic/fifty=1,\
		/obj/item/stack/sheet/runed_metal/fifty=1,
		/obj/item/stack/sheet/prewar = 50,
		/obj/item/stack/crafting/metalparts = 50,
		/obj/item/stack/sheet/prewar = 50,
		/obj/item/stack/crafting/goodparts = 50,
		/obj/item/stack/crafting/electronicparts = 50,
		/obj/item/stack/rods = 50,
		/obj/item/stack/ore/blackpowder = 50,
		/obj/item/advanced_crafting_components/alloys = 1
		)
	generate_items_inside(items_inside, src)

// Pneumatic launcher

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
	time = 1
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

// Shotgun

/datum/crafting_recipe/gun/vehicle/shotgun_improvised
	name = "Improvised vehicular shotgun"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/improvised
	reqs = list(/obj/item/gun/ballistic/revolver/hobo/single_shotgun = 2,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 5,
	/obj/item/stack/sheet/mineral/titanium = 5,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 1
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/vehicle/shotgun_normal
	name = "Standard vehicular shotgun"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/improvised = 1,
	/obj/item/stack/crafting/metalparts = 2,
	/obj/item/stack/sheet/prewar = 6,
	/obj/item/stack/sheet/mineral/titanium = 6,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_WORKBENCH)
	time = 1
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/gun/vehicle/shotgun_upgraded
	name = "Upgraded vehicular shotgun"
	result = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/rapid
	reqs = list(/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot = 1,
	/obj/item/stack/crafting/metalparts = 5,
	/obj/item/stack/sheet/prewar = 8,
	/obj/item/stack/sheet/mineral/titanium = 8,
	/obj/item/stack/rods = 2)
	tools = list(TOOL_AWORKBENCH)
	time = 1
	category = CAT_VEHICLES
	subcategory = CAT_VEHICLEPARTS

/datum/crafting_recipe/shotgun_ammo
	name = "Vehicular shotgun ammunition"
	result = /obj/item/mecha_ammo/scattershot
	reqs = list(/obj/item/stack/crafting/metalparts = 3,
	/obj/item/stack/sheet/prewar = 3,
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
	subcategory = CAT_VEHICLES
	category = CAT_VEHICLEPARTS

/datum/crafting_recipe/vehiculearmor
	name = "Armor booster module (Close Combat Weaponry)"
	result = /obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster
	reqs = list(/obj/item/stack/sheet/prewar = 10,
				/obj/item/stack/crafting/metalparts = 10,
				/obj/item/advanced_crafting_components/alloys = 2,
				/obj/item/stack/crafting/goodparts = 4)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 180
	subcategory = CAT_VEHICLES
	category = CAT_VEHICLEPARTS

/datum/crafting_recipe/vehiculearmor/distance
	name = "Armor booster module (Ranged Weaponry)"
	result = /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster
	reqs = list(/obj/item/stack/sheet/prewar = 10,
				/obj/item/stack/crafting/metalparts = 10,
				/obj/item/advanced_crafting_components/alloys = 2,
				/obj/item/stack/crafting/goodparts = 4)
	tools = list(TOOL_WORKBENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 180
	subcategory = CAT_VEHICLES
	category = CAT_VEHICLEPARTS

// Brotherhood of Steel Techweb Nodes
// BOS-specific research progression

/datum/techweb_node/bos_basic
	id = "bos_basic"
	display_name = "Brotherhood Basic Training"
	description = "Foundational knowledge for Brotherhood operations."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 0)
	category = list("Brotherhood")
	starting_node = TRUE

/datum/techweb_node/bos_energy_weapons
	id = "bos_energy_weapons"
	display_name = "Advanced Energy Weapons"
	description = "Brotherhood laser and plasma weapon improvements."
	prereq_ids = list("bos_basic")
	design_ids = list(
		"bos_laser_focus",
		"bos_laser_sight",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
	category = list("Brotherhood")

/datum/techweb_node/bos_power_armor
	id = "bos_power_armor"
	display_name = "Power Armor Technology"
	description = "Advanced power armor modifications and maintenance."
	prereq_ids = list("bos_basic")
	design_ids = list(
		"bos_pa_kit",
		"bos_pa_repair",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)
	category = list("Brotherhood")

/datum/techweb_node/bos_power_armor_advanced
	id = "bos_power_armor_advanced"
	display_name = "Advanced Power Armor Systems"
	description = "Cutting-edge power armor enhancements."
	prereq_ids = list("bos_power_armor")
	design_ids = list(
		"bos_pa_jetpack",
		"bos_pa_medical",
		"bos_pa_targeting",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
	category = list("Brotherhood")

/datum/techweb_node/bos_combat_armor
	id = "bos_combat_armor"
	display_name = "Combat Armor Standard"
	description = "Improved combat armor manufacturing."
	prereq_ids = list("bos_basic")
	design_ids = list(
		"bos_combat_armor_mk2",
		"bos_helmet_mk2",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1000)
	category = list("Brotherhood")

/datum/techweb_node/bos_field_tech
	id = "bos_field_tech"
	display_name = "Field Technology"
	description = "Portable technology for field operations."
	prereq_ids = list("bos_basic")
	design_ids = list(
		"bos_stealth_boy_improved",
		"bos_sensor_suite",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	category = list("Brotherhood")

/datum/techweb_node/bos_heavy_weapons
	id = "bos_heavy_weapons"
	display_name = "Heavy Weapons Systems"
	description = "Advanced heavy weapon technology."
	prereq_ids = list("bos_energy_weapons")
	design_ids = list(
		"bos_gatling_laser_mod",
		"bos_plasma_caster_mod",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 4000)
	category = list("Brotherhood")

/datum/techweb_node/bos_vertibird
	id = "bos_vertibird"
	display_name = "Vertibird Technology"
	description = "Vertical takeoff and landing craft systems."
	prereq_ids = list("bos_power_armor_advanced")
	design_ids = list(
		"bos_vertibird_armor",
		"bos_vertibird_weapon",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	category = list("Brotherhood")

/datum/techweb_node/bos_tesla
	id = "bos_tesla"
	display_name = "Tesla Technology"
	description = "Advanced electromagnetic weapon systems."
	prereq_ids = list("bos_heavy_weapons")
	design_ids = list(
		"bos_tesla_coil",
		"bos_tesla_armor_mod",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 6000)
	category = list("Brotherhood")

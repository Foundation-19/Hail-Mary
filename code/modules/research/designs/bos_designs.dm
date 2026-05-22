// Brotherhood of Steel Designs
// BOS-specific craftable items

// ============ ENERGY WEAPONS ============

/datum/design/bos_laser_focus
	name = "Laser Weapon Focus Mod"
	desc = "A modification that focuses laser beams for increased damage."
	id = "bos_laser_focus"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 500, /datum/material/glass = 200, /datum/material/gold = 100)
	build_path = /obj/item/bos_module/laser_focus
	category = list("Brotherhood", "Weapons")

/datum/design/bos_laser_sight
	name = "Laser Sight Module"
	desc = "A laser sighting system for improved accuracy."
	id = "bos_laser_sight"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 300, /datum/material/glass = 100)
	build_path = /obj/item/bos_module/laser_sight
	category = list("Brotherhood", "Weapons")

/datum/design/bos_gatling_laser_mod
	name = "Gatling Laser Capacitor Upgrade"
	desc = "Increases gatling laser capacity and fire rate."
	id = "bos_gatling_laser_mod"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 500, /datum/material/gold = 300)
	build_path = /obj/item/bos_module/gatling_capacitor
	category = list("Brotherhood", "Weapons")

/datum/design/bos_plasma_caster_mod
	name = "Plasma Caster Magnetic Accelerator"
	desc = "Increases plasma caster projectile velocity."
	id = "bos_plasma_caster_mod"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1200, /datum/material/glass = 400, /datum/material/plasma = 200)
	build_path = /obj/item/bos_module/plasma_accelerator
	category = list("Brotherhood", "Weapons")

// ============ POWER ARMOR ============

/datum/design/bos_pa_kit
	name = "Power Armor Maintenance Kit"
	desc = "A kit containing tools and parts for power armor repair."
	id = "bos_pa_kit"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 300, /datum/material/silver = 200)
	build_path = /obj/item/bos_module/pa_kit
	category = list("Brotherhood", "Power Armor")

/datum/design/bos_pa_repair
	name = "Power Armor Repair Plates"
	desc = "Replacement armor plates for power armor suits."
	id = "bos_pa_repair"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/titanium = 500)
	build_path = /obj/item/stack/sheet/bos_pa_plating
	category = list("Brotherhood", "Power Armor")

/datum/design/bos_pa_jetpack
	name = "Power Armor Jetpack Module"
	desc = "A jetpack attachment for power armor."
	id = "bos_pa_jetpack"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 500, /datum/material/plasma = 500, /datum/material/titanium = 1000)
	build_path = /obj/item/bos_module/pa_jetpack
	category = list("Brotherhood", "Power Armor")

/datum/design/bos_pa_medical
	name = "Power Armor Medical System"
	desc = "An integrated medical system for power armor."
	id = "bos_pa_medical"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 500, /datum/material/gold = 300, /datum/material/silver = 300)
	build_path = /obj/item/bos_module/pa_medical
	category = list("Brotherhood", "Power Armor")

/datum/design/bos_pa_targeting
	name = "Power Armor Targeting System"
	desc = "An advanced targeting HUD for power armor."
	id = "bos_pa_targeting"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 800, /datum/material/gold = 400)
	build_path = /obj/item/bos_module/pa_targeting
	category = list("Brotherhood", "Power Armor")

// ============ COMBAT ARMOR ============

/datum/design/bos_combat_armor_mk2
	name = "Combat Armor MK2 Blueprint"
	desc = "Improved combat armor manufacturing specifications."
	id = "bos_combat_armor_mk2"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2500, /datum/material/titanium = 500, /datum/material/glass = 300)
	build_path = /obj/item/bos_blueprint/combat_armor
	category = list("Brotherhood", "Armor")

/datum/design/bos_helmet_mk2
	name = "Combat Helmet MK2 Blueprint"
	desc = "Improved combat helmet specifications."
	id = "bos_helmet_mk2"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 500, /datum/material/gold = 100)
	build_path = /obj/item/bos_blueprint/combat_helmet
	category = list("Brotherhood", "Armor")

// ============ FIELD TECH ============

/datum/design/bos_stealth_boy_improved
	name = "Improved Stealth Boy"
	desc = "A stealth field generator with extended duration."
	id = "bos_stealth_boy_improved"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 1000, /datum/material/plasma = 500, /datum/material/silver = 300)
	build_path = /obj/item/bos_module/stealth_improved
	category = list("Brotherhood", "Equipment")

/datum/design/bos_sensor_suite
	name = "Portable Sensor Suite"
	desc = "A handheld sensor array for detecting technology."
	id = "bos_sensor_suite"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 800, /datum/material/gold = 200)
	build_path = /obj/item/bos_module/sensor_suite
	category = list("Brotherhood", "Equipment")

// ============ VERTIBIRD ============

/datum/design/bos_vertibird_armor
	name = "Vertibird Armor Plating"
	desc = "Reinforced armor plating for vertibird craft."
	id = "bos_vertibird_armor"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/titanium = 2000)
	build_path = /obj/item/stack/sheet/bos_vertibird_armor
	category = list("Brotherhood", "Vehicles")

/datum/design/bos_vertibird_weapon
	name = "Vertibird Weapon Mount"
	desc = "A weapon mount system for vertibird armament."
	id = "bos_vertibird_weapon"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 500, /datum/material/gold = 300)
	build_path = /obj/item/bos_module/vertibird_weapon
	category = list("Brotherhood", "Vehicles")

// ============ TESLA ============

/datum/design/bos_tesla_coil
	name = "Tesla Coil Weapon"
	desc = "An electromagnetic coil weapon system."
	id = "bos_tesla_coil"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1000, /datum/material/gold = 500, /datum/material/silver = 500)
	build_path = /obj/item/bos_module/tesla_coil
	category = list("Brotherhood", "Weapons")

/datum/design/bos_tesla_armor_mod
	name = "Tesla Armor Enhancement"
	desc = "A module that adds tesla damage to power armor."
	id = "bos_tesla_armor_mod"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/gold = 800, /datum/material/silver = 500)
	build_path = /obj/item/bos_module/pa_tesla
	category = list("Brotherhood", "Power Armor")

// ============ BOS ITEMS ============

/obj/item/bos_module
	name = "BOS module"
	desc = "A Brotherhood of Steel technology module."
	icon = 'icons/obj/module.dmi'
	icon_state = "boris_module"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/bos_module/laser_focus
	name = "laser focus mod"
	desc = "A focusing lens for laser weapons."
	icon_state = "boris_module"

/obj/item/bos_module/laser_sight
	name = "laser sight"
	desc = "A laser sight attachment."
	icon_state = "boris_module"

/obj/item/bos_module/gatling_capacitor
	name = "gatling laser capacitor"
	desc = "A high-capacity capacitor for gatling lasers."
	icon_state = "boris_module"

/obj/item/bos_module/plasma_accelerator
	name = "plasma accelerator"
	desc = "A magnetic accelerator for plasma weapons."
	icon_state = "boris_module"

/obj/item/bos_module/pa_kit
	name = "power armor maintenance kit"
	desc = "A kit for repairing power armor."
	icon_state = "boris_module"

/obj/item/bos_module/pa_jetpack
	name = "power armor jetpack"
	desc = "A jetpack module for power armor."
	icon_state = "boris_module"

/obj/item/bos_module/pa_medical
	name = "power armor medical system"
	desc = "A medical module for power armor."
	icon_state = "boris_module"

/obj/item/bos_module/pa_targeting
	name = "power armor targeting system"
	desc = "A targeting HUD module."
	icon_state = "boris_module"

/obj/item/bos_module/pa_tesla
	name = "tesla armor module"
	desc = "A tesla weapon module for power armor."
	icon_state = "boris_module"

/obj/item/bos_module/sensor_suite
	name = "portable sensor suite"
	desc = "Detects nearby technology."
	icon_state = "boris_module"

/obj/item/bos_module/vertibird_weapon
	name = "vertibird weapon mount"
	desc = "A weapon mounting system."
	icon_state = "boris_module"

/obj/item/bos_module/stealth_improved
	name = "improved stealth boy"
	desc = "A stealth field generator with extended duration."
	icon_state = "boris_module"

/obj/item/bos_module/tesla_coil
	name = "tesla coil"
	desc = "An electromagnetic weapon component."
	icon_state = "boris_module"

/obj/item/bos_blueprint
	name = "BOS blueprint"
	desc = "A Brotherhood of Steel technology blueprint."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "docs_generic"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/bos_blueprint/combat_armor
	name = "combat armor MK2 blueprint"
	desc = "Specifications for improved combat armor."

/obj/item/bos_blueprint/combat_helmet
	name = "combat helmet MK2 blueprint"
	desc = "Specifications for improved combat helmet."

/obj/item/stack/sheet/bos_pa_plating
	name = "power armor plating"
	desc = "Replacement armor plating."
	singular_name = "armor plate"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	max_amount = 10
	merge_type = /obj/item/stack/sheet/bos_pa_plating

/obj/item/stack/sheet/bos_vertibird_armor
	name = "vertibird armor plating"
	desc = "Heavy armor plating for aircraft."
	singular_name = "armor plate"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	max_amount = 5
	merge_type = /obj/item/stack/sheet/bos_vertibird_armor

/*
Mass Fusion plant crew.
Small specialist faction focused on reactor operations and field salvage.
*/

/datum/job/mass_fusion
	department_flag = DEP_MASS_FUSION
	selection_color = "#8da86e"
	faction = FACTION_MASS_FUSION
	exp_type = EXP_TYPE_WASTELAND
	social_faction = "massfusion"

	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS)
	forbids = "Mass Fusion forbids reckless reactor operation, abandoning critical systems, and hoarding plant parts while the core is unstable."
	enforces = "Mass Fusion expects continuous reactor upkeep, grid reliability, and salvage recovery for plant maintenance."

/datum/outfit/job/mass_fusion
	name = "Mass Fusion Base"
	jobtype = /datum/job/mass_fusion
	ears = /obj/item/radio/headset/headset_town
	id = /obj/item/card/id/dogtag/town
	uniform = /obj/item/clothing/under/f13/machinist
	shoes = /obj/item/clothing/shoes/workboots
	belt = /obj/item/storage/belt/utility/full
	backpack = /obj/item/storage/backpack/satchel/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	r_pocket = /obj/item/flashlight/flare
	backpack_contents = list(
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/reagent_containers/blood/radaway = 1,
		/obj/item/storage/wallet/stash/low = 1,
		/obj/item/melee/onehanded/knife/hunting = 1
	)

/datum/job/mass_fusion/supervisor
	title = "Mass Fusion Supervisor"
	flag = F13MASSFUSIONSUPERVISOR
	total_positions = 1
	spawn_positions = 1
	supervisors = "the Mass Fusion board"
	description = "You lead the plant team. Keep the reactor stable, direct district routing from the plant, and coordinate salvage priorities."
	enforces = "Maintain reliable power output, prioritize safety, and assign scavenging targets when components run low."
	outfit = /datum/outfit/job/mass_fusion/supervisor
	loadout_options = list(
		/datum/outfit/loadout/mass_fusion_supervisor_control,
		/datum/outfit/loadout/mass_fusion_supervisor_emergency
	)
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_CHANGE_IDS)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_CHANGE_IDS)

/datum/outfit/job/mass_fusion/supervisor
	name = "Mass Fusion Supervisor"
	jobtype = /datum/job/mass_fusion/supervisor
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town/mayor
	uniform = /obj/item/clothing/under/f13/machinist
	glasses = /obj/item/clothing/glasses/welding
	belt = /obj/item/storage/belt/utility/full
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/reagent_containers/blood/radaway = 1,
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/duct_tape = 2,
		/obj/item/crafting/board = 2,
		/obj/item/crafting/transistor = 4,
		/obj/item/crafting/diode = 4,
		/obj/item/storage/wallet/stash/mid = 1,
		/obj/item/melee/onehanded/knife/hunting = 1
	)

/datum/job/mass_fusion/scavenger
	title = "Mass Fusion Scavenger"
	flag = F13MASSFUSIONSCAVENGER
	total_positions = 3
	spawn_positions = 3
	supervisors = "the Mass Fusion Supervisor"
	description = "You recover parts, fuel support supplies, and maintenance consumables for plant operations."
	enforces = "Run salvage routes, return with usable components, and support emergency repairs during reactor incidents."
	outfit = /datum/outfit/job/mass_fusion/scavenger
	loadout_options = list(
		/datum/outfit/loadout/mass_fusion_scavenger_reactor_runner,
		/datum/outfit/loadout/mass_fusion_scavenger_salvage_runner
	)
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_MINING)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_MINING)

/datum/outfit/job/mass_fusion/scavenger
	name = "Mass Fusion Scavenger"
	jobtype = /datum/job/mass_fusion/scavenger
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town
	uniform = /obj/item/clothing/under/f13/machinist
	head = /obj/item/clothing/head/hardhat
	belt = /obj/item/storage/belt/utility/waster
	backpack_contents = list(
		/obj/item/reagent_containers/food/snacks/f13/mre = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/reagent_containers/blood/radaway = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/duct_tape = 2,
		/obj/item/crafting/board = 1,
		/obj/item/crafting/transistor = 2,
		/obj/item/crafting/diode = 2,
		/obj/item/storage/wallet/stash/low = 1
	)

/datum/job/mass_fusion/reactor_operator
	title = "Mass Fusion Reactor Operator"
	flag = F13MASSFUSIONREACTOROP
	total_positions = 2
	spawn_positions = 2
	supervisors = "the Mass Fusion Supervisor"
	description = "You run the core. Balance rods, coolant chemistry, purge procedures, and emergency trips."
	enforces = "Keep output stable, manage additives, and prevent unstable starts."
	outfit = /datum/outfit/job/mass_fusion/reactor_operator
	loadout_options = list(
		/datum/outfit/loadout/mass_fusion_reactor_operator_shift,
		/datum/outfit/loadout/mass_fusion_reactor_operator_hotloop
	)
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS)

/datum/outfit/job/mass_fusion/reactor_operator
	name = "Mass Fusion Reactor Operator"
	jobtype = /datum/job/mass_fusion/reactor_operator
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town
	uniform = /obj/item/clothing/under/f13/machinist
	glasses = /obj/item/clothing/glasses/welding
	belt = /obj/item/storage/belt/utility/full
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/reagent_containers/blood/radaway = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/crafting/transistor = 3,
		/obj/item/crafting/diode = 3,
		/obj/item/crafting/board = 1
	)

/datum/job/mass_fusion/grid_technician
	title = "Mass Fusion Grid Technician"
	flag = F13MASSFUSIONGRIDTECH
	total_positions = 2
	spawn_positions = 2
	supervisors = "the Mass Fusion Supervisor"
	description = "You maintain turbines, pumps, instrumentation, and breaker systems."
	enforces = "Prevent wear cascades, complete maintenance queue tasks, and keep diagnostics clean."
	outfit = /datum/outfit/job/mass_fusion/grid_technician
	loadout_options = list(
		/datum/outfit/loadout/mass_fusion_grid_tech_maintenance,
		/datum/outfit/loadout/mass_fusion_grid_tech_breaker
	)
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS)

/datum/outfit/job/mass_fusion/grid_technician
	name = "Mass Fusion Grid Technician"
	jobtype = /datum/job/mass_fusion/grid_technician
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town
	uniform = /obj/item/clothing/under/f13/machinist
	head = /obj/item/clothing/head/hardhat
	belt = /obj/item/storage/belt/utility/full
	backpack_contents = list(
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/duct_tape = 2,
		/obj/item/crafting/board = 2,
		/obj/item/crafting/transistor = 3,
		/obj/item/crafting/diode = 3,
		/obj/item/storage/wallet/stash/low = 1
	)

/datum/job/mass_fusion/relay_engineer
	title = "Mass Fusion Relay Engineer"
	flag = F13MASSFUSIONRELAYENG
	total_positions = 2
	spawn_positions = 2
	supervisors = "the Mass Fusion Supervisor"
	description = "You keep district relays online, respond to sabotage, and restore remote power routes."
	enforces = "Prioritize relay uptime, route restoration, and field repairs under pressure."
	outfit = /datum/outfit/job/mass_fusion/relay_engineer
	loadout_options = list(
		/datum/outfit/loadout/mass_fusion_relay_engineer_field,
		/datum/outfit/loadout/mass_fusion_relay_engineer_sabotage_response
	)
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_MINING)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_MINING)

/datum/outfit/job/mass_fusion/relay_engineer
	name = "Mass Fusion Relay Engineer"
	jobtype = /datum/job/mass_fusion/relay_engineer
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town
	uniform = /obj/item/clothing/under/f13/machinist
	head = /obj/item/clothing/head/hardhat
	belt = /obj/item/storage/belt/utility/full
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/duct_tape = 2,
		/obj/item/storage/wallet/stash/low = 1
	)

/datum/job/mass_fusion/hazard_recovery
	title = "Mass Fusion Hazard Recovery Tech"
	flag = F13MASSFUSIONHAZREC
	total_positions = 1
	spawn_positions = 1
	supervisors = "the Mass Fusion Supervisor"
	description = "You handle spent fuel cask logistics and hazard-zone extraction operations."
	enforces = "Keep waste hazard under control and recover high-value materials from danger windows."
	outfit = /datum/outfit/job/mass_fusion/hazard_recovery
	loadout_options = list(
		/datum/outfit/loadout/mass_fusion_hazrec_cask_ops,
		/datum/outfit/loadout/mass_fusion_hazrec_extraction
	)
	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_MINING)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS, ACCESS_MAINT_TUNNELS, ACCESS_MINING)

/datum/outfit/job/mass_fusion/hazard_recovery
	name = "Mass Fusion Hazard Recovery Tech"
	jobtype = /datum/job/mass_fusion/hazard_recovery
	id = /obj/item/card/id/dogtag/town
	ears = /obj/item/radio/headset/headset_town
	uniform = /obj/item/clothing/under/f13/machinist
	head = /obj/item/clothing/head/hardhat
	belt = /obj/item/storage/belt/utility/waster
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/reagent_containers/blood/radaway = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/storage/bag/ore = 1,
		/obj/item/storage/wallet/stash/low = 1
	)

/datum/outfit/loadout/mass_fusion_supervisor_control
	name = "Control-Room Lead"
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1
	)

/datum/outfit/loadout/mass_fusion_supervisor_emergency
	name = "Emergency Stabilization"
	backpack_contents = list(
		/obj/item/stack/sheet/metal/ten = 2,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/board = 2,
		/obj/item/crafting/transistor = 4,
		/obj/item/crafting/diode = 4,
		/obj/item/crafting/duct_tape = 3
	)

/datum/outfit/loadout/mass_fusion_scavenger_reactor_runner
	name = "Reactor Repair Runner"
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/board = 1,
		/obj/item/crafting/transistor = 2,
		/obj/item/crafting/diode = 2,
		/obj/item/crafting/duct_tape = 2
	)

/datum/outfit/loadout/mass_fusion_scavenger_salvage_runner
	name = "Salvage Route Runner"
	backpack_contents = list(
		/obj/item/pickaxe/silver = 1,
		/obj/item/t_scanner/adv_mining_scanner = 1,
		/obj/item/storage/bag/ore = 1,
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1
	)

/datum/outfit/loadout/mass_fusion_reactor_operator_shift
	name = "Reactor Shift Operator"
	backpack_contents = list(
		/obj/item/geiger_counter = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/reagent_containers/blood/radaway = 1
	)

/datum/outfit/loadout/mass_fusion_reactor_operator_hotloop
	name = "Hot-Loop Response Operator"
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/crafting/duct_tape = 2,
		/obj/item/crafting/transistor = 2,
		/obj/item/crafting/diode = 2
	)

/datum/outfit/loadout/mass_fusion_grid_tech_maintenance
	name = "Maintenance Rotation"
	backpack_contents = list(
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/stack/cable_coil/thirty = 1,
		/obj/item/crafting/board = 2,
		/obj/item/crafting/duct_tape = 2
	)

/datum/outfit/loadout/mass_fusion_grid_tech_breaker
	name = "Breaker & Instrumentation"
	backpack_contents = list(
		/obj/item/crafting/transistor = 4,
		/obj/item/crafting/diode = 4,
		/obj/item/crafting/board = 1,
		/obj/item/geiger_counter = 1
	)

/datum/outfit/loadout/mass_fusion_relay_engineer_field
	name = "Field Relay Patrol"
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/stack/cable_coil/thirty = 1
	)

/datum/outfit/loadout/mass_fusion_relay_engineer_sabotage_response
	name = "Sabotage Response Kit"
	backpack_contents = list(
		/obj/item/stack/sheet/metal/ten = 1,
		/obj/item/crafting/board = 1,
		/obj/item/crafting/transistor = 2,
		/obj/item/crafting/diode = 2,
		/obj/item/crafting/duct_tape = 2
	)

/datum/outfit/loadout/mass_fusion_hazrec_cask_ops
	name = "Cask Operations"
	backpack_contents = list(
		/obj/item/clothing/suit/radiation = 1,
		/obj/item/clothing/head/radiation = 1,
		/obj/item/storage/pill_bottle/chem_tin/radx = 1,
		/obj/item/reagent_containers/blood/radaway = 1
	)

/datum/outfit/loadout/mass_fusion_hazrec_extraction
	name = "Hazard Extraction"
	backpack_contents = list(
		/obj/item/pickaxe/silver = 1,
		/obj/item/t_scanner/adv_mining_scanner = 1,
		/obj/item/storage/bag/ore = 1,
		/obj/item/geiger_counter = 1
	)

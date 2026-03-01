// ====================================================
// CPU CERT FABRICATOR
// Lathe-style machine for printing cert cards and
// behavior assemblies.
//
// Behavior assembly printing requires:
//   1. TRAIT_ROBOT_WHISPERER on the user
//   2. special_i >= required_int (min 6)
//
// Builder's SPECIAL is snapshotted at print time:
//   - PER → sensor_range on the assembly (base 5 + bonus)
//   - LCK → chance of +1 circuit slot (LCK 7+)
//
// File: code/modules/research/cpu_fabricator.dm
// ====================================================


/obj/machinery/cpu_fabricator
	name = "CPU Certification Fabricator"
	desc = "A specialized fabricator for printing CPU certification cards and upgrade modules."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "protolathe"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 20
	active_power_usage = 200

	/// All printable designs
	var/list/designs = list()

	/// Currently busy printing
	var/printing = FALSE


/obj/machinery/cpu_fabricator/Initialize(mapload)
	. = ..()
	_build_design_list()


/obj/machinery/cpu_fabricator/proc/_build_design_list()
	// Base cert cards
	designs += new /datum/cpu_fab_design/base/standard()
	designs += new /datum/cpu_fab_design/base/combat()
	designs += new /datum/cpu_fab_design/base/medical()
	designs += new /datum/cpu_fab_design/base/engineering()

	// Upgrade cards
	designs += new /datum/cpu_fab_design/upgrade/vtec()
	designs += new /datum/cpu_fab_design/upgrade/armor_plating()
	designs += new /datum/cpu_fab_design/upgrade/thrusters()
	designs += new /datum/cpu_fab_design/upgrade/disabler_cooler()
	designs += new /datum/cpu_fab_design/upgrade/targeting_system()
	designs += new /datum/cpu_fab_design/upgrade/emp_shielding()
	designs += new /datum/cpu_fab_design/upgrade/hacking_module()

	// Behavior assemblies — gated behind Robot Whisperer + INT
	designs += new /datum/cpu_fab_design/behavior/sentry()
	designs += new /datum/cpu_fab_design/behavior/guardian()
	designs += new /datum/cpu_fab_design/behavior/medic()
	designs += new /datum/cpu_fab_design/behavior/watchdog()
	designs += new /datum/cpu_fab_design/behavior/deadman()
	designs += new /datum/cpu_fab_design/behavior/fortress()


/obj/machinery/cpu_fabricator/Destroy()
	designs.Cut()
	return ..()


/obj/machinery/cpu_fabricator/interact(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return
	ui_interact(user)


/obj/machinery/cpu_fabricator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CpuFabricator", name)
		ui.open()


/obj/machinery/cpu_fabricator/ui_data(mob/user)
	var/list/data = list()
	var/list/design_data = list()

	for(var/datum/cpu_fab_design/D in designs)
		// Hide behavior assemblies from users without the quirk
		if(D.requires_robot_whisperer && !HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
			continue
		var/list/costs = list()
		for(var/mat in D.cost)
			costs += list(list("material" = mat, "amount" = D.cost[mat]))
		design_data += list(list(
			"name"     = D.design_name,
			"desc"     = D.design_desc,
			"id"       = D.id,
			"tier"     = D.required_tier,
			"costs"    = costs,
			"behavior" = D.requires_robot_whisperer
		))

	data["designs"]  = design_data
	data["printing"] = printing
	return data


/obj/machinery/cpu_fabricator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("print")
			var/design_id = params["id"]
			var/datum/cpu_fab_design/D = _get_design(design_id)
			if(!D)
				return FALSE
			_print_card(D, ui.user)
			return TRUE


/obj/machinery/cpu_fabricator/proc/_get_design(id)
	for(var/datum/cpu_fab_design/D in designs)
		if(D.id == id)
			return D
	return null


/obj/machinery/cpu_fabricator/proc/_print_card(datum/cpu_fab_design/D, mob/user)
	if(printing)
		to_chat(user, span_warning("The fabricator is already printing."))
		return

	// Behavior assembly gates
	if(D.requires_robot_whisperer)
		if(!HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
			to_chat(user, span_warning("You don't have the knowledge to program behavior assemblies."))
			return
		if(!ishuman(user))
			to_chat(user, span_warning("Behavior assembly programming requires a human operator."))
			return
		var/mob/living/carbon/human/H = user
		if(H.special_i < D.required_int)
			to_chat(user, span_warning("Your Intelligence is too low to program this assembly. (Requires [D.required_int])"))
			return

	// TODO: wire material cost check into your materials system here

	printing = TRUE
	use_power(active_power_usage * 10)

	// Snapshot builder SPECIAL for behavior assemblies
	var/builder_per  = 5
	var/builder_lck  = 5
	var/builder_ckey = ""
	if(D.requires_robot_whisperer && ishuman(user))
		var/mob/living/carbon/human/H = user
		builder_per  = H.special_p
		builder_lck  = H.special_l
		builder_ckey = key_name(H)

	addtimer(CALLBACK(src, PROC_REF(_finish_print), D, get_turf(src), builder_per, builder_lck, builder_ckey), 30, TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_print(datum/cpu_fab_design/D, turf/T, builder_per, builder_lck, builder_ckey)
	printing = FALSE

	var/atom/movable/result = new D.output_path(T)

	// Apply SPECIAL snapshot to behavior assemblies
	if(D.requires_robot_whisperer && istype(result, /obj/item/behavior_assembly))
		var/obj/item/behavior_assembly/A = result
		// PER → sensor range: base 5, +1 per PER above 5, max 10
		A.sensor_range = clamp(5 + max(0, builder_per - 5), 5, 10)
		// LCK 7+ → prob chance of +1 circuit slot
		if(builder_lck >= 7 && prob((builder_lck - 6) * 15))
			A.max_circuits++
			visible_message(span_notice("[src] hums with unusual efficiency — an extra circuit slot was configured!"))
		A.builder_ckey = builder_ckey
		log_game("Behavior assembly '[D.design_name]' printed by [builder_ckey] — sensor_range:[A.sensor_range] max_circuits:[A.max_circuits]")

	visible_message(span_notice("[src] finishes printing [D.design_name]."))


// ====================================================
// CPU FAB DESIGN DATUM
// ====================================================


/datum/cpu_fab_design
	var/design_name = "Unknown Design"
	var/design_desc = "An unconfigured fabricator design."
	var/id = "unknown"
	var/required_tier = CERT_TIER_BASIC
	var/required_int = 0
	var/output_path = /obj/item/cert_card
	var/list/cost = list()
	/// If TRUE, requires TRAIT_ROBOT_WHISPERER + INT check
	var/requires_robot_whisperer = FALSE


// ---- Base cert designs ----

/datum/cpu_fab_design/base

/datum/cpu_fab_design/base/standard
	design_name = "Standard Chassis Cert"
	design_desc = "A general-purpose robotic chassis certification card."
	id = "cert_base_standard"
	output_path = /obj/item/cert_card/base
	cost = list("iron" = 500, "glass" = 200)

/datum/cpu_fab_design/base/combat
	design_name = "Combat Chassis Cert"
	design_desc = "A military-grade combat chassis certification card."
	id = "cert_base_combat"
	required_tier = CERT_TIER_MILITARY
	output_path = /obj/item/cert_card/base/combat
	cost = list("iron" = 1000, "glass" = 200, "gold" = 300)

/datum/cpu_fab_design/base/medical
	design_name = "Medical Chassis Cert"
	design_desc = "A medical chassis certification card."
	id = "cert_base_medical"
	output_path = /obj/item/cert_card/base/medical
	cost = list("iron" = 500, "glass" = 400)

/datum/cpu_fab_design/base/engineering
	design_name = "Engineering Chassis Cert"
	design_desc = "An engineering chassis certification card."
	id = "cert_base_engineering"
	output_path = /obj/item/cert_card/base/engineering
	cost = list("iron" = 700, "glass" = 200)


// ---- Upgrade designs ----

/datum/cpu_fab_design/upgrade

/datum/cpu_fab_design/upgrade/vtec
	design_name = "VTEC Sprint System"
	design_desc = "Overclocks locomotion servos for burst speed capability."
	id = "cert_upgrade_vtec"
	output_path = /obj/item/cert_card/upgrade/vtec
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/upgrade/armor_plating
	design_name = "Reinforced Armor Plating"
	design_desc = "Heavy plating upgrade. Tough but sluggish."
	id = "cert_upgrade_armor"
	output_path = /obj/item/cert_card/upgrade/armor_plating
	cost = list("iron" = 800)

/datum/cpu_fab_design/upgrade/thrusters
	design_name = "Ion Thruster System"
	design_desc = "Energy-fed thrusters for traversal and jump assists."
	id = "cert_upgrade_thrusters"
	output_path = /obj/item/cert_card/upgrade/thrusters
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/upgrade/disabler_cooler
	design_name = "Energy Weapon Cooling System"
	design_desc = "Active cooling for energy weapons, increasing recharge rate."
	id = "cert_upgrade_cooler"
	output_path = /obj/item/cert_card/upgrade/disabler_cooler
	cost = list("iron" = 300, "glass" = 300)

/datum/cpu_fab_design/upgrade/targeting_system
	design_name = "Advanced Targeting System"
	design_desc = "Improves weapon tracking and targeting calculations."
	id = "cert_upgrade_targeting"
	output_path = /obj/item/cert_card/upgrade/targeting_system
	cost = list("iron" = 300, "glass" = 200, "gold" = 100)

/datum/cpu_fab_design/upgrade/emp_shielding
	design_name = "EMP Shielding Array"
	design_desc = "Faraday shielding woven into chassis internals."
	id = "cert_upgrade_emp"
	output_path = /obj/item/cert_card/upgrade/emp_shielding
	cost = list("iron" = 500, "gold" = 200)

/datum/cpu_fab_design/upgrade/hacking_module
	design_name = "Intrusion Countermeasure Suite"
	design_desc = "Military-grade hacking suite. Requires Tier 2 chassis."
	id = "cert_upgrade_hacking"
	required_tier = CERT_TIER_MILITARY
	output_path = /obj/item/cert_card/upgrade/hacking_module
	cost = list("iron" = 400, "glass" = 200, "gold" = 400)


// ---- Behavior assembly designs ----
// All require Robot Whisperer quirk + INT 6 minimum

/datum/cpu_fab_design/behavior
	requires_robot_whisperer = TRUE
	required_int = 6
	cost = list("iron" = 400, "glass" = 300, "gold" = 100)

/datum/cpu_fab_design/behavior/sentry
	design_name = "Sentry Protocol Assembly"
	design_desc = "Automatically enters combat mode when a hostile mob is detected in sensor range."
	id = "behavior_sentry"
	output_path = /obj/item/behavior_assembly/sentry

/datum/cpu_fab_design/behavior/guardian
	design_name = "Guardian Protocol Assembly"
	design_desc = "Broadcasts a distress signal when the robot takes damage."
	id = "behavior_guardian"
	output_path = /obj/item/behavior_assembly/guardian

/datum/cpu_fab_design/behavior/medic
	design_name = "Medic Protocol Assembly"
	design_desc = "Activates self-repair subroutines when the robot takes damage. Requires CERT_CAN_REPAIR."
	id = "behavior_medic"
	output_path = /obj/item/behavior_assembly/medic
	cost = list("iron" = 400, "glass" = 400, "gold" = 100)

/datum/cpu_fab_design/behavior/watchdog
	design_name = "Watchdog Protocol Assembly"
	design_desc = "Broadcasts a power warning when the robot's cell runs low."
	id = "behavior_watchdog"
	output_path = /obj/item/behavior_assembly/watchdog

/datum/cpu_fab_design/behavior/deadman
	design_name = "Deadman Protocol Assembly"
	design_desc = "Broadcasts a distress signal with location when the robot is destroyed."
	id = "behavior_deadman"
	output_path = /obj/item/behavior_assembly/deadman

/datum/cpu_fab_design/behavior/fortress
	design_name = "Fortress Protocol Assembly"
	design_desc = "Initiates emergency lockdown when the robot takes heavy damage."
	id = "behavior_fortress"
	required_int = 7
	output_path = /obj/item/behavior_assembly/fortress
	cost = list("iron" = 600, "glass" = 300, "gold" = 200)

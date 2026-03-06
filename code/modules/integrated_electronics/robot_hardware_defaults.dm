// ====================================================
// ROBOT HARDWARE DEFAULTS
// Per-robot-type recommended hardware configurations.
// Used by the workshop "USE RECOMMENDED" button to
// pre-fill hardware slots for newbie builders.
//
// Also defines the SPECIAL snapshot system and CORE
// budget tracking for hardware-equipped robots.
//
// File: code/modules/integrated_electronics/robot_hardware_defaults.dm
// ====================================================


// ====================================================
// SPECIAL SNAPSHOT
// Taken at build time, baked into the robot.
// Influences hardware via apply_special() procs.
// ====================================================

/// Applies the builder's SPECIAL to all installed hardware.
/// Called once at _finish_robot() in robot_workshop.dm.
/proc/apply_special_to_hardware(mob/living/carbon/human/builder, mob/living/silicon/robot/R)
	if(!builder || !R.installed_hardware)
		return

	var/list/snap = list(
		"STR" = builder.special_s,
		"PER" = builder.special_p,
		"END" = builder.special_e,
		"CHA" = builder.special_c,
		"INT" = builder.special_i,
		"AGI" = builder.special_a,
		"LCK" = builder.special_l
	)

	// Store snapshot on robot for examination/logs
	R.builder_special = snap

	// Apply to hardware
	for(var/datum/robot_hardware/H in R.installed_hardware)
		H.apply_special(snap)

	// Apply direct robot stat bonuses from SPECIAL
	_apply_robot_special_bonuses(snap, R)


/proc/_apply_robot_special_bonuses(list/S, mob/living/silicon/robot/R)
	// STR bonus is applied via weapon hardware apply_special() instead
	// (weapon fire_range, throw_force, grab_strength all scale with STR)

	// END -> bonus HP
	var/end_bonus = max(0, S["END"] - 5)
	R.maxHealth += end_bonus * 10
	R.health    += end_bonus * 10

	// AGI -> move speed
	var/agi_bonus = max(0, S["AGI"] - 5)
	R.speed = max(0.1, R.speed - (agi_bonus * 0.1))

	// CHA -> faction tolerance (stored for behavior circuits to read)
	R.cert_cha_modifier = S["CHA"]


// ====================================================
// CORE BUDGET TRACKING
// Hardware draws from the robot's CORE budget.
// Called after all hardware is installed.
// ====================================================

/// Checks if the proposed hardware list fits within the cert's CORE budget.
/// Returns list of error strings (empty = OK).
/proc/check_hardware_core_budget(list/hardware_list, datum/cpu_cert/cert)
	var/list/errors = list()
	if(!cert)
		return errors
	var/total_compute    = 0
	var/total_ops        = 0
	var/total_resilience = 0
	var/total_energy     = 0
	for(var/datum/robot_hardware/H in hardware_list)
		total_compute    += H.core_compute
		total_ops        += H.core_operations
		total_resilience += H.core_resilience
		total_energy     += H.core_energy
	var/avail_compute    = cert.get_compute()
	var/avail_operations = cert.get_operations()
	var/avail_resilience = cert.get_resilience()
	var/avail_energy     = cert.get_energy()
	if(total_compute > avail_compute)
		errors += "Compute overbudget: need [total_compute], have [avail_compute]."
	if(total_ops > avail_operations)
		errors += "Operations overbudget: need [total_ops], have [avail_operations]."
	if(total_resilience > avail_resilience)
		errors += "Resilience overbudget: need [total_resilience], have [avail_resilience]."
	if(total_energy > avail_energy)
		errors += "Energy overbudget: need [total_energy], have [avail_energy]."
	return errors


/// Returns a human-readable CORE usage summary string for the workshop UI.
/proc/get_core_usage_display(list/hardware_list, datum/cpu_cert/cert)
	var/tc = 0
	var/top = 0
	var/tr = 0
	var/te = 0
	for(var/datum/robot_hardware/H in hardware_list)
		tc  += H.core_compute
		top += H.core_operations
		tr  += H.core_resilience
		te  += H.core_energy
	if(!cert)
		return "C.O.R.E: C[tc] O[top] R[tr] E[te]  <span class='warn'>(no cert)</span>"
	var/ac = cert.get_compute()
	var/ao = cert.get_operations()
	var/ar = cert.get_resilience()
	var/ae = cert.get_energy()
	var/c_ok = tc  <= ac
	var/o_ok = top <= ao
	var/r_ok = tr  <= ar
	var/e_ok = te  <= ae
	var/out = "C.O.R.E: "
	out += "<span class='[c_ok ? "good" : "warn"]'>C[tc]/[ac]</span> "
	out += "<span class='[o_ok ? "good" : "warn"]'>O[top]/[ao]</span> "
	out += "<span class='[r_ok ? "good" : "warn"]'>R[tr]/[ar]</span> "
	out += "<span class='[e_ok ? "good" : "warn"]'>E[te]/[ae]</span>"
	return out


// ====================================================
// LCK MATERIAL DISCOUNT
// Applied at build time in robot_workshop.dm.
// LCK 5 = 5% off, +5% per point. LCK 10 = 25% off.
// Separate from fabricator LCK (which gives bonus slot).
// ====================================================

/proc/get_workshop_lck_discount(mob/living/carbon/human/builder)
	if(!builder)
		return 0
	var/lck = builder.special_l
	if(lck < 5)
		return 0
	return min((lck - 4) * 5, 25)  // cap at 25%

/proc/apply_lck_discount(list/mat_cost, discount_pct)
	if(!discount_pct)
		return mat_cost
	var/list/discounted = mat_cost.Copy()
	for(var/mat in discounted)
		discounted[mat] = max(0, round(discounted[mat] * (1 - discount_pct / 100)))
	return discounted


// ====================================================
// INT HARDWARE GATE
// Checked at workshop build time against builder INT.
// ====================================================

/proc/check_int_gate(mob/living/carbon/human/builder, datum/robot_hardware/H)
	if(!builder || !H)
		return TRUE
	var/int = builder.special_i
	if(int < H.min_int)
		return FALSE
	return TRUE

/proc/get_int_gate_label(min_int_val)
	switch(min_int_val)
		if(RH_INT_BASIC)    return ""
		if(RH_INT_STANDARD) return "<span class='dim'>\[INT 5+\]</span>"
		if(RH_INT_ADVANCED) return "<span class='warn'>\[INT 7+\]</span>"
		if(RH_INT_MASTER)   return "<span class='bad'>\[INT 9+\]</span>"
	return ""


// ====================================================
// RECOMMENDED HARDWARE CONFIGS
// One entry per robot build design type.
// Format: list of list(hardware_type, assoc_config)
// where assoc_config overrides specific vars on the datum.
// ====================================================

/datum/recommended_hardware_config
	var/design_type = null
	var/list/hardware_entries = list()

/// Returns the recommended hardware list for a given design type path.
/// Each entry: list(hardware_datum_type, list/config_overrides)
/proc/get_recommended_hardware(design_path)
	for(var/T in subtypesof(/datum/recommended_hardware_config))
		var/datum/recommended_hardware_config/RHC = new T()
		if(RHC.design_type == design_path)
			return RHC.hardware_entries
		qdel(RHC)
	return list()


// -- MR. HANDY ----------------------------------------

/datum/recommended_hardware_config/handy
	design_type = /datum/robot_build_design/handy

/datum/recommended_hardware_config/handy/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,          list("tick_interval" = 20)),
		list(/datum/robot_hardware/grabber,        list("max_items" = 8)),
		list(/datum/robot_hardware/harvester,      list("harvest_range" = 3, "auto_replant" = TRUE)),
		list(/datum/robot_hardware/reagent_tank,   list("tank_capacity" = 60, "reagent_type" = /datum/reagent/water, "prefill_volume" = 60)),
		list(/datum/robot_hardware/injector,       list("dose_per_use" = 5, "target_friendly" = TRUE)),
		list(/datum/robot_hardware/speaker,        list("tts_mode" = TRUE, "tts_text" = "How may I assist you?")),
		list(/datum/robot_hardware/light,          list("light_brightness" = 2, "start_on" = TRUE)),
		list(/datum/robot_hardware/locomotion,     list("patrol_mode" = "random"))
	)


// -- LIBERATOR ----------------------------------------

/datum/recommended_hardware_config/liberator
	design_type = /datum/robot_build_design/liberator

/datum/recommended_hardware_config/liberator/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,          list("tick_interval" = 20)),
		list(/datum/robot_hardware/weapon,         list("gun_type" = /obj/item/gun/energy/laser, "lethal_mode" = TRUE, "fire_range" = 7)),
		list(/datum/robot_hardware/light,          list("light_brightness" = 3, "start_on" = TRUE)),
		list(/datum/robot_hardware/locomotion,     list("speed_modifier" = -0.5, "patrol_mode" = "random")),
		list(/datum/robot_hardware/health_scanner, list("scan_range" = 5, "critical_threshold" = 30))
	)


// -- PROTECTRON ----------------------------------------

/datum/recommended_hardware_config/protectron
	design_type = /datum/robot_build_design/protectron

/datum/recommended_hardware_config/protectron/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,          list("tick_interval" = 20)),
		list(/datum/robot_hardware/weapon,         list("gun_type" = /obj/item/gun/energy/laser, "lethal_mode" = FALSE, "fire_range" = 6)),
		list(/datum/robot_hardware/stun_module,    list("stun_duration" = 30, "stun_range" = 1)),
		list(/datum/robot_hardware/health_scanner, list("scan_range" = 5, "scan_target" = "all")),
		list(/datum/robot_hardware/speaker,        list("tts_mode" = TRUE, "tts_text" = "Halt. Violators will be prosecuted.")),
		list(/datum/robot_hardware/locomotion,     list("patrol_mode" = "random"))
	)


// -- MR. GUTSY ----------------------------------------

/datum/recommended_hardware_config/gutsy
	design_type = /datum/robot_build_design/gutsy

/datum/recommended_hardware_config/gutsy/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,           list("tick_interval" = 20)),
		list(/datum/robot_hardware/weapon,          list("gun_type" = /obj/item/gun/energy/laser, "lethal_mode" = TRUE, "fire_range" = 8)),
		list(/datum/robot_hardware/stun_module,     list("stun_duration" = 40)),
		list(/datum/robot_hardware/speaker,         list("tts_mode" = TRUE, "tts_text" = "You call that running, maggot?")),
		list(/datum/robot_hardware/light,           list("light_brightness" = 3)),
		list(/datum/robot_hardware/locomotion,      list("speed_modifier" = -0.3, "patrol_mode" = "random"))
	)


// -- SECURITRON ----------------------------------------

/datum/recommended_hardware_config/securitron
	design_type = /datum/robot_build_design/securitron

/datum/recommended_hardware_config/securitron/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,               list("tick_interval" = 20)),
		list(/datum/robot_hardware/weapon,              list("gun_type" = /obj/item/gun/energy/laser, "lethal_mode" = TRUE, "fire_range" = 9)),
		list(/datum/robot_hardware/air_cannon,          list("knockback_force" = 4)),
		list(/datum/robot_hardware/health_scanner,      list("scan_range" = 7, "scan_target" = "all")),
		list(/datum/robot_hardware/environment_scanner, list("scan_radius" = 6, "detect_radiation" = TRUE, "detect_fire" = TRUE)),
		list(/datum/robot_hardware/speaker,             list("tts_mode" = TRUE, "tts_text" = "Citizen. Please comply.")),
		list(/datum/robot_hardware/locomotion,          list("patrol_mode" = "random"))
	)


// -- ASSAULTRON ----------------------------------------

/datum/recommended_hardware_config/assaultron
	design_type = /datum/robot_build_design/assaultron

/datum/recommended_hardware_config/assaultron/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,           list("tick_interval" = 15)),
		list(/datum/robot_hardware/weapon,          list("gun_type" = /obj/item/gun/energy/laser, "lethal_mode" = TRUE, "fire_range" = 10)),
		list(/datum/robot_hardware/stun_module,     list("stun_duration" = 50, "stun_range" = 1)),
		list(/datum/robot_hardware/grabber,         list("max_items" = 3)),
		list(/datum/robot_hardware/locomotion,      list("speed_modifier" = -1.0, "can_sprint" = TRUE, "patrol_mode" = "random")),
		list(/datum/robot_hardware/health_scanner,  list("scan_range" = 8))
	)


// -- SENTRY BOT ----------------------------------------

/datum/recommended_hardware_config/sentrybot
	design_type = /datum/robot_build_design/sentrybot

/datum/recommended_hardware_config/sentrybot/New()
	hardware_entries = list(
		list(/datum/robot_hardware/clock,               list("tick_interval" = 10)),
		list(/datum/robot_hardware/weapon,              list("gun_type" = /obj/item/gun/energy/laser, "lethal_mode" = TRUE, "fire_range" = 12)),
		list(/datum/robot_hardware/grenade_launcher,    list("grenade_type" = /obj/item/grenade, "fuse_time" = 30, "grenade_count" = 2)),
		list(/datum/robot_hardware/air_cannon,          list("knockback_force" = 6)),
		list(/datum/robot_hardware/environment_scanner, list("scan_radius" = 8, "detect_radiation" = TRUE, "detect_fire" = TRUE, "detect_bodies" = TRUE)),
		list(/datum/robot_hardware/health_scanner,      list("scan_range" = 10, "scan_target" = "all")),
		list(/datum/robot_hardware/light,               list("light_brightness" = 5, "start_on" = TRUE)),
		list(/datum/robot_hardware/locomotion,          list("speed_modifier" = 0.5))
	)


// ====================================================
// HARDWARE INSTANTIATION HELPER
// Called by robot_workshop._finish_robot() to build
// and install the hardware list into the robot.
// ====================================================

/proc/instantiate_hardware_list(list/hardware_entries, mob/living/silicon/robot/R, mob/living/carbon/human/builder)
	if(!hardware_entries || !hardware_entries.len)
		return

	var/lck_discount = builder ? get_workshop_lck_discount(builder) : 0

	for(var/list/entry in hardware_entries)
		if(!islist(entry) || entry.len < 1)
			continue
		var/hw_type    = entry[1]
		var/list/config = entry.len >= 2 ? entry[2] : list()

		// INT gate check
		var/datum/robot_hardware/test = new hw_type()
		if(builder && !check_int_gate(builder, test))
			qdel(test)
			continue
		qdel(test)

		// Instantiate
		var/datum/robot_hardware/H = new hw_type()
		// config_defs set at New() time

		// Apply config overrides
		for(var/key in config)
			if(key in H.config_defs)
				H.vars[key] = config[key]

		// Apply LCK discount to material cost (for display/logging only at this stage)
		if(lck_discount)
			H.mat_cost = apply_lck_discount(H.mat_cost, lck_discount)

		// Apply SPECIAL
		if(builder)
			H.apply_special(list(
				"STR" = builder.special_s,
				"PER" = builder.special_p,
				"END" = builder.special_e,
				"CHA" = builder.special_c,
				"INT" = builder.special_i,
				"AGI" = builder.special_a,
				"LCK" = builder.special_l
			))

		// Install into robot
		H.install(R)

	// Apply robot-level SPECIAL bonuses after all hardware is in
	if(builder)
		apply_special_to_hardware(builder, R)

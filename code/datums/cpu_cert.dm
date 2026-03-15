// ====================================================
// CPU CERT DATUM
// Defines what a robot/machine/AI *is* and *can do*.
// Held by the robot mob or machine obj, read-only
// from the outside — all mutation goes through procs.
//
// File: code/datums/cpu_cert.dm
// ====================================================


/datum/cpu_cert
	var/cert_name = "Unknown Chassis"
	var/cert_desc = "An unconfigured CPU certification."
	var/cert_tier = CERT_TIER_BASIC

	/// Bitfield of CERT_CAN_* and CERT_* flags
	var/capability_flags = CERT_FLAGS_PLAYER_BORG

	/// Currently installed upgrades. List of /datum/cert_upgrade
	var/list/upgrade_slots = list()

	/// How many upgrades can be installed at once
	var/max_upgrade_slots = 3

	/// Whitelist of allowed /datum/cert_upgrade subtypes. null = accept anything
	var/list/allowed_upgrade_types = null

	// ---- C.O.R.E. base values (before upgrade modifiers) ----
	var/base_compute    = 5
	var/base_operations = 5
	var/base_resilience = 5
	var/base_energy     = 5

	/// Weakref to the robot mob or machine obj holding this cert
	var/datum/weakref/owner_ref = null


// ====================================================
// STAT READING
// ====================================================

/// Returns the total value of a CORE_ stat including all installed upgrade modifiers
/datum/cpu_cert/proc/get_core_stat(stat_type)
	var/base = 0
	switch(stat_type)
		if(CORE_COMPUTE)
			base = base_compute
		if(CORE_OPERATIONS)
			base = base_operations
		if(CORE_RESILIENCE)
			base = base_resilience
		if(CORE_ENERGY)
			base = base_energy
		else
			return 0

	var/total = base
	for(var/datum/cert_upgrade/U in upgrade_slots)
		switch(stat_type)
			if(CORE_COMPUTE)
				total += U.compute_mod
			if(CORE_OPERATIONS)
				total += U.operations_mod
			if(CORE_RESILIENCE)
				total += U.resilience_mod
			if(CORE_ENERGY)
				total += U.energy_mod

	return clamp(total, 1, 10)


// ====================================================
// CAPABILITY CHECKS
// ====================================================

/// Returns TRUE if this cert has the given capability flag(s)
/datum/cpu_cert/proc/has_capability(flag)
	return (capability_flags & flag)

/// Adds a capability flag. Used by upgrades in on_apply()
/datum/cpu_cert/proc/grant_capability(flag)
	capability_flags |= flag

/// Removes a capability flag. Used by upgrades in on_remove()
/datum/cpu_cert/proc/revoke_capability(flag)
	capability_flags &= ~flag


// ====================================================
// UPGRADE MANAGEMENT
// ====================================================

/// Returns TRUE if the upgrade can be legally installed into this cert
/datum/cpu_cert/proc/can_install_upgrade(datum/cert_upgrade/U)
	// NPC lock — hard block, no exceptions
	if(capability_flags & CERT_LOCKED)
		return FALSE

	// Slot limit
	if(upgrade_slots.len >= max_upgrade_slots)
		return FALSE

	// Already installed
	if(U in upgrade_slots)
		return FALSE

	// Type whitelist check
	if(allowed_upgrade_types && !is_type_in_list(U, allowed_upgrade_types))
		return FALSE

	// Tier check
	if(U.required_tier > cert_tier)
		return FALSE

	// Required capability flags on the cert
	if(U.required_capability_flags && !(capability_flags & U.required_capability_flags))
		return FALSE

	// Exclusivity conflict check
	if(U.exclusive_with.len)
		for(var/datum/cert_upgrade/installed in upgrade_slots)
			if(is_type_in_list(installed, U.exclusive_with))
				return FALSE

	// Cert type check
	if(U.required_cert_type && !istype(src, U.required_cert_type))
		return FALSE

	return TRUE

/// Installs an upgrade into this cert. Returns TRUE on success.
/// holder is the robot mob or machine obj — passed to on_apply()
/datum/cpu_cert/proc/install_upgrade(datum/cert_upgrade/U, atom/holder)
	if(!can_install_upgrade(U))
		return FALSE

	upgrade_slots += U
	U.on_apply(src, holder)
	recalculate_stats(holder)
	return TRUE

/// Removes an upgrade from this cert. Returns TRUE on success.
/datum/cpu_cert/proc/remove_upgrade(datum/cert_upgrade/U, atom/holder)
	if(!(U in upgrade_slots))
		return FALSE

	if(capability_flags & CERT_LOCKED)
		return FALSE

	upgrade_slots -= U
	U.on_remove(src, holder)
	recalculate_stats(holder)
	return TRUE

/// Removes all upgrades. Used on robot destruction or module reset.
/// If drop_location is provided, upgrades are moved there as cert_card items.
/datum/cpu_cert/proc/strip_all_upgrades(atom/holder, atom/drop_location)
	for(var/datum/cert_upgrade/U in upgrade_slots)
		U.on_remove(src, holder)
		if(drop_location)
			var/obj/item/cert_card/card = new(drop_location)
			card.upgrade = U
			card.name = "cert card - [U.upgrade_name]"
	upgrade_slots.Cut()
	recalculate_stats(holder)


// ====================================================
// STAT APPLICATION
// ====================================================

/// Recalculates and pushes stats to the holder after any upgrade change.
/// This is the ONLY place stats should be written to the holder.
/datum/cpu_cert/proc/recalculate_stats(atom/holder)
	if(!holder)
		var/atom/resolved = owner_ref?.resolve()
		if(!resolved)
			return
		holder = resolved

	_apply_resilience(holder)
	_apply_operations(holder)
	_apply_compute(holder)
	// Energy is read on-demand via get_core_stat(), no direct mob var to push

/// Applies resilience → maxHealth
/datum/cpu_cert/proc/_apply_resilience(atom/holder)
	if(!ismob(holder))
		return
	var/mob/living/M = holder
	var/res = get_core_stat(CORE_RESILIENCE)
	// Each point above/below 5 = +/- 10 maxHealth. Base robot health stays as-is.
	M.maxHealth = initial(M.maxHealth) + ((res - 5) * 10)
	M.health = clamp(M.health, -M.maxHealth, M.maxHealth)

/// Applies operations → robot speed
/datum/cpu_cert/proc/_apply_operations(atom/holder)
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	var/ops = get_core_stat(CORE_OPERATIONS)
	// Each point above 5 = -0.1 speed (faster). Each point below = +0.1 (slower).
	R.speed = (5 - ops) * 0.1

/// Applies compute → sensor/sight range
/datum/cpu_cert/proc/_apply_compute(atom/holder)
	if(!istype(holder, /mob/living/silicon/robot))
		return
	// Compute gates hacking and sensor interactions.
	// Direct sight modification is handled by the hacking system reading get_core_stat(CORE_COMPUTE).
	// Nothing to push here yet — placeholder for future sensor range expansion.
	return


/// Called during robot/machine Initialize() to stamp the cert onto the holder.
/// Sets owner_ref and pushes all stats.
/datum/cpu_cert/proc/apply_to_holder(atom/holder)
	owner_ref = WEAKREF(holder)
	recalculate_stats(holder)


// ====================================================
// CERT SUBTYPES — ROBOT
// ====================================================

/datum/cpu_cert/robot
	cert_name = "Standard Chassis"
	cert_desc = "A general-purpose robotic chassis certification."
	capability_flags = CERT_FLAGS_PLAYER_BORG | CERT_IS_HACKABLE
	max_upgrade_slots = 3
	base_compute    = 5
	base_operations = 5
	base_resilience = 5
	base_energy     = 5

/datum/cpu_cert/robot/combat
	cert_name = "Combat Chassis"
	cert_desc = "A military-grade combat certified chassis. Built to fight."
	cert_tier = CERT_TIER_MILITARY
	capability_flags = CERT_FLAGS_COMBAT  // no CERT_IS_HACKABLE — hardened
	max_upgrade_slots = 4
	base_compute    = 4
	base_operations = 7
	base_resilience = 7
	base_energy     = 6

/datum/cpu_cert/robot/medical
	cert_name = "Medical Chassis"
	cert_desc = "A chassis certified for field medicine and triage support."
	capability_flags = CERT_FLAGS_PLAYER_BORG | CERT_CAN_REPAIR | CERT_IS_HACKABLE
	max_upgrade_slots = 4
	base_compute    = 6
	base_operations = 5
	base_resilience = 5
	base_energy     = 6

/datum/cpu_cert/robot/engineering
	cert_name = "Engineering Chassis"
	cert_desc = "A chassis certified for construction, repair, and infrastructure work."
	capability_flags = CERT_FLAGS_PLAYER_BORG | CERT_CAN_REPAIR | CERT_CAN_INTERFACE | CERT_IS_HACKABLE
	max_upgrade_slots = 4
	base_compute    = 6
	base_operations = 4
	base_resilience = 6
	base_energy     = 7

/datum/cpu_cert/robot/npc
	cert_name = "NPC Chassis"
	cert_desc = "A locked chassis. Not player-controlled. Do not tamper."
	cert_tier = CERT_TIER_BASIC
	capability_flags = CERT_FLAGS_NPC_BASIC
	max_upgrade_slots = 0  // NPCs get no slots — cert is baked at spawn


// ====================================================
// CERT SUBTYPES — AI
// ====================================================

/datum/cpu_cert/ai
	cert_name = "Standard AI Core"
	cert_desc = "A standard artificial intelligence core certification."
	capability_flags = CERT_CAN_INTERFACE | CERT_CAN_BROADCAST | CERT_CAN_DEPLOY
	max_upgrade_slots = 2
	base_compute    = 8
	base_operations = 5
	base_resilience = 3
	base_energy     = 7

/datum/cpu_cert/ai/military
	cert_name = "Military AI Core"
	cert_desc = "An AI core with military-grade software unlocks. Handle with caution."
	cert_tier = CERT_TIER_MILITARY
	capability_flags = CERT_CAN_INTERFACE | CERT_CAN_BROADCAST | CERT_CAN_DEPLOY | CERT_MILITARY_GRADE
	max_upgrade_slots = 3
	base_compute    = 9
	base_operations = 7
	base_resilience = 3
	base_energy     = 8


// ====================================================
// CERT SUBTYPES — DEVICE
// ====================================================

/datum/cpu_cert/device
	cert_name = "Device Controller"
	cert_desc = "A generic machine controller certification."
	capability_flags = CERT_FLAGS_DEVICE
	max_upgrade_slots = 2
	base_compute    = 4
	base_operations = 5
	base_resilience = 4
	base_energy     = 5

/datum/cpu_cert/device/turret
	cert_name = "Turret Controller"
	cert_desc = "Certified for automated weapons emplacement."
	capability_flags = CERT_FLAGS_DEVICE | CERT_CAN_SHOOT | CERT_LOCKED
	max_upgrade_slots = 0
	base_operations = 6
	base_resilience = 6

/datum/cpu_cert/device/fabricator
	cert_name = "Fabricator Controller"
	cert_desc = "Certified for automated manufacturing."
	capability_flags = CERT_CAN_INTERFACE | CERT_LOCKED
	max_upgrade_slots = 0
	base_compute    = 7
	base_energy     = 8

/datum/cpu_cert/device/sensor
	cert_name = "Sensor Controller"
	cert_desc = "Certified for environmental monitoring and detection."
	capability_flags = CERT_CAN_INTERFACE | CERT_CAN_BROADCAST | CERT_LOCKED
	max_upgrade_slots = 0
	base_compute    = 8
	base_operations = 7

// ====================================================
// HACKING TOOL CERT
// Installed inside a /obj/item/hacking_device.
// CERT_CAN_HACK on this cert gates minigame access.
// core_compute scales attempts and timer.
// Military-grade variant is world-found only — not
// printable at the CPU Cert Fabricator.
// ====================================================

/datum/cpu_cert/device/hacking_tool
	cert_name       = "Hacking Tool Certificate"
	cert_desc       = "A RobCo intrusion countermeasure certificate. Slots into a hacking device."
	cert_tier       = CERT_TIER_BASIC
	capability_flags = CERT_CAN_HACK
	max_upgrade_slots = 0
	base_compute    = 2   // attempts + time window
	base_operations = 1

/datum/cpu_cert/device/hacking_tool/advanced
	cert_name       = "Military Hacking Certificate"
	cert_desc       = "A hardened military-grade ICE cert. Masks operator identity on success."
	cert_tier       = CERT_TIER_MILITARY
	capability_flags = CERT_CAN_HACK | CERT_MILITARY_GRADE
	base_compute    = 5

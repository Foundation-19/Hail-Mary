// ====================================================
// CERT UPGRADE DATUM
// Modular capability additions to a cpu_cert.
// Physically carried as cert_card items in the world.
// Installed/removed freely unless cert is CERT_LOCKED.
//
// File: code/datums/cert_upgrade.dm
// ====================================================


/datum/cert_upgrade
	var/upgrade_name = "Unknown Upgrade"
	var/upgrade_desc = "An unconfigured upgrade module."

	/// If set, this upgrade only installs into this cert type or its subtypes
	var/required_cert_type = null

	/// Minimum cert tier required
	var/required_tier = CERT_TIER_BASIC

	/// Capability flags the cert must ALREADY have before this installs
	var/required_capability_flags = NONE

	/// Flags added to the cert when this upgrade is installed
	var/capability_flag_add = NONE

	/// Flags removed from the cert when this upgrade is installed
	var/capability_flag_remove = NONE

	// ---- C.O.R.E. modifiers applied while this upgrade is installed ----
	var/compute_mod    = 0
	var/operations_mod = 0
	var/resilience_mod = 0
	var/energy_mod     = 0  // positive = draws more power (costs from energy ceiling)

	/// List of /datum/cert_upgrade types that cannot coexist with this upgrade
	var/list/exclusive_with = list()


// ====================================================
// UPGRADE HOOKS
// Override these in subtypes for actual effects.
// ====================================================

/// Called when this upgrade is installed into a cert.
/// C = the cpu_cert datum, holder = the robot mob or machine obj
/datum/cert_upgrade/proc/on_apply(datum/cpu_cert/C, atom/holder)
	if(capability_flag_add)
		C.grant_capability(capability_flag_add)
	if(capability_flag_remove)
		C.revoke_capability(capability_flag_remove)

/// Called when this upgrade is removed from a cert.
/datum/cert_upgrade/proc/on_remove(datum/cpu_cert/C, atom/holder)
	if(capability_flag_add)
		C.revoke_capability(capability_flag_add)
	if(capability_flag_remove)
		C.grant_capability(capability_flag_remove)


// ====================================================
// ROBOT UPGRADES
// ====================================================

/datum/cert_upgrade/robot
	required_cert_type = /datum/cpu_cert/robot


// --- VTEC ---
/datum/cert_upgrade/robot/vtec
	upgrade_name = "VTEC Sprint System"
	upgrade_desc = "Overclocks locomotion servos for burst speed capability."
	capability_flag_add = CERT_CAN_SPRINT
	operations_mod = 1
	energy_mod     = 2
	exclusive_with = list(/datum/cert_upgrade/robot/armor_plating)

/datum/cert_upgrade/robot/vtec/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(R.cansprint)
		R.AddAbility(new /obj/effect/proc_holder/silicon/cyborg/vtecControl)
		R.cansprint = FALSE

/datum/cert_upgrade/robot/vtec/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.speed = initial(R.speed)
	R.cansprint = TRUE


// --- ARMOR PLATING ---
// Uses cert_armor_bonus var on the robot mob to reduce incoming brute damage.
// Checked in bullet_act and melee damage via the bonus var.
/datum/cert_upgrade/robot/armor_plating
	upgrade_name = "Reinforced Armor Plating"
	upgrade_desc = "Heavy plating bolted over chassis joints. Tough but sluggish."
	resilience_mod  =  2
	operations_mod  = -2
	energy_mod      =  1
	exclusive_with = list(/datum/cert_upgrade/robot/vtec)

/datum/cert_upgrade/robot/armor_plating/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.cert_armor_bonus = 25

/datum/cert_upgrade/robot/armor_plating/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.cert_armor_bonus = 0


// --- ION THRUSTERS ---
/datum/cert_upgrade/robot/thrusters
	upgrade_name = "Ion Thruster System"
	upgrade_desc = "Energy-fed thrusters for microgravity traversal and jump assists."
	required_capability_flags = CERT_CAN_MOVE
	capability_flag_add = CERT_CAN_IONPULSE
	energy_mod = 2

/datum/cert_upgrade/robot/thrusters/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.ionpulse = TRUE

/datum/cert_upgrade/robot/thrusters/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.ionpulse = FALSE
	if(R.ionpulse_on)
		R.toggle_ionpulse()


// --- DISABLER COOLER ---
/datum/cert_upgrade/robot/disabler_cooler
	upgrade_name = "Energy Weapon Cooling System"
	upgrade_desc = "Active cooling for energy-based weapons, increasing recharge rate."
	required_capability_flags = CERT_CAN_SHOOT
	operations_mod = 1
	energy_mod     = 1
	exclusive_with = list(/datum/cert_upgrade/robot/disabler_cooler)

/datum/cert_upgrade/robot/disabler_cooler/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(!R.module)
		return
	for(var/obj/item/gun/energy/T in R.module.modules)
		T.charge_delay = max(2, T.charge_delay - 4)

/datum/cert_upgrade/robot/disabler_cooler/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(!R.module)
		return
	for(var/obj/item/gun/energy/T in R.module.modules)
		T.charge_delay = initial(T.charge_delay)


// --- TARGETING SYSTEM ---
/datum/cert_upgrade/robot/targeting_system
	upgrade_name = "Advanced Targeting System"
	upgrade_desc = "Improves weapon tracking and reaction targeting calculations."
	required_capability_flags = CERT_CAN_SHOOT
	operations_mod = 2
	energy_mod     = 1


// --- EMP SHIELDING ---
/datum/cert_upgrade/robot/emp_shielding
	upgrade_name = "EMP Shielding Array"
	upgrade_desc = "Faraday shielding woven into chassis internals."
	capability_flag_add = CERT_EMP_HARDENED
	resilience_mod = 1
	energy_mod     = 1

/datum/cert_upgrade/robot/emp_shielding/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.AddElement(/datum/element/empprotection, EMP_PROTECT_WIRES | EMP_PROTECT_CONTENTS)

/datum/cert_upgrade/robot/emp_shielding/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.RemoveElement(/datum/element/empprotection)


// --- HACKING MODULE ---
/datum/cert_upgrade/robot/hacking_module
	upgrade_name = "Intrusion Countermeasure Suite"
	upgrade_desc = "Military-grade hacking suite. Allows interfacing with hardened electronic systems."
	required_tier = CERT_TIER_MILITARY
	required_capability_flags = CERT_MILITARY_GRADE
	capability_flag_add = CERT_CAN_HACK
	compute_mod = 2
	energy_mod  = 2


// ====================================================
// AI UPGRADES
// ====================================================

/datum/cert_upgrade/ai
	required_cert_type = /datum/cpu_cert/ai


// --- MALF PACKAGE ---
/datum/cert_upgrade/ai/malf_package
	upgrade_name = "Combat Software Package"
	upgrade_desc = "Highly illegal. Grants the AI access to malfunction-class combat routines."
	required_cert_type = /datum/cpu_cert/ai/military
	required_tier = CERT_TIER_MILITARY
	capability_flag_add = CERT_CAN_MALF
	compute_mod = 1
	energy_mod  = 2

/datum/cert_upgrade/ai/malf_package/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/ai))
		return
	var/mob/living/silicon/ai/AI = holder
	if(AI.malf_picker)
		AI.malf_picker.processing_time += 50
	else
		AI.add_malf_picker()
		AI.hack_software = TRUE
	to_chat(AI, span_userdanger("Combat software integration complete. Malfunction routines now available."))

/datum/cert_upgrade/ai/malf_package/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	// Malf is not reversible once installed — intentional.
	return


// --- SURVEILLANCE PACKAGE ---
/datum/cert_upgrade/ai/surveillance
	upgrade_name = "Surveillance Software Package"
	upgrade_desc = "Allows the AI to hear through cameras via lip-reading and hidden microphones."
	capability_flag_add = CERT_CAN_SURVEIL
	compute_mod = 1

/datum/cert_upgrade/ai/surveillance/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/ai))
		return
	var/mob/living/silicon/ai/AI = holder
	if(AI.eyeobj)
		AI.eyeobj.relay_speech = TRUE
	to_chat(AI, span_userdanger("Surveillance integration complete. Camera audio relay active."))

/datum/cert_upgrade/ai/surveillance/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/ai))
		return
	var/mob/living/silicon/ai/AI = holder
	if(AI.eyeobj)
		AI.eyeobj.relay_speech = FALSE


// ====================================================
// DEVICE UPGRADES
// ====================================================

/datum/cert_upgrade/device
	required_cert_type = /datum/cpu_cert/device

/datum/cert_upgrade/device/extended_range
	upgrade_name = "Extended Sensor Array"
	upgrade_desc = "Boosts detection and targeting range."
	required_cert_type = null
	compute_mod    = 1
	operations_mod = 1
	energy_mod     = 1

/datum/cert_upgrade/device/hardened
	upgrade_name = "Hardened Casing"
	upgrade_desc = "Reinforced housing resistant to EMP and physical damage."
	required_cert_type = null
	capability_flag_add = CERT_EMP_HARDENED
	resilience_mod = 2
	energy_mod     = 1

/datum/cert_upgrade/device/auto_reload
	upgrade_name = "Automated Throughput System"
	upgrade_desc = "Speeds up fabrication cycles."
	required_cert_type = /datum/cpu_cert/device/fabricator
	compute_mod = 1
	energy_mod  = 2

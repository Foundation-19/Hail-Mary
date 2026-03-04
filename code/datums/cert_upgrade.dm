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
	// Malf is not reversible once installed - intentional.
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


// ====================================================
// F13 CERT UPGRADES
// ====================================================

// Additional capability flags for F13 upgrades
#define CERT_CAN_RENAME      (1 << 10)

/datum/cert_upgrade/robot/rad_shielding
	upgrade_name = "Radaway Injector"
	upgrade_desc = "An integrated RadAway dispenser arm. Administers anti-radiation treatment to irradiated survivors nearby."
	capability_flag_add = CERT_CAN_REPAIR
	energy_mod = 1

/datum/cert_upgrade/robot/rad_shielding/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(R.module)
		var/obj/item/reagent_containers/borghypo/H = new(R.module)
		H.reagents.add_reagent(/datum/reagent/medicine/radaway, 30)
		R.module.basic_modules += H
		R.module.add_module(H, FALSE, TRUE)

/datum/cert_upgrade/robot/rad_shielding/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(!R.module)
		return
	for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
		if(H.reagents && H.reagents.has_reagent(/datum/reagent/medicine/radaway))
			R.module.remove_module(H, TRUE)
			break

/obj/item/cert_card/upgrade/rad_shielding
	name = "cert card - Radaway Injector"

/obj/item/cert_card/upgrade/rad_shielding/Initialize(mapload)
	. = ..()
	var/datum/cert_upgrade/robot/rad_shielding/U = new()
	upgrade = U
	_update_name()


// ====================================================
// SCAVENGER ARRAY
// Highlights nearby loot and corpses on examine.
// Useful for player robots and merchant/utility builds.
// ====================================================

/datum/cert_upgrade/robot/scavenger_array
	upgrade_name = "Scavenger Array"
	upgrade_desc = "Advanced proximity sensors tuned for detecting valuable salvage and organic remains."
	compute_mod = 2
	capability_flag_add = CERT_CAN_INTERFACE

/datum/cert_upgrade/robot/scavenger_array/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	to_chat(R, span_notice("Scavenger Array online. Proximity salvage detection active."))

/datum/cert_upgrade/robot/scavenger_array/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	to_chat(R, span_warning("Scavenger Array offline."))

/obj/item/cert_card/upgrade/scavenger_array
	name = "cert card - Scavenger Array"

/obj/item/cert_card/upgrade/scavenger_array/Initialize(mapload)
	. = ..()
	var/datum/cert_upgrade/robot/scavenger_array/U = new()
	upgrade = U
	_update_name()


// ====================================================
// FACTION TRANSPONDER
// Lets the robot switch its faction alignment.
// Useful for player borgs who want to align with factions.
// ====================================================

/datum/cert_upgrade/robot/faction_transponder
	upgrade_name = "Faction Transponder"
	upgrade_desc = "A programmable IFF transponder. Allows the robot to broadcast a specific faction signal."
	capability_flag_add = CERT_CAN_BROADCAST
	energy_mod = 1

/datum/cert_upgrade/robot/faction_transponder/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	to_chat(R, span_notice("Faction Transponder installed. Use 'Set Faction Transponder' in Robot Commands."))

/datum/cert_upgrade/robot/faction_transponder/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	to_chat(R, span_warning("Faction Transponder removed."))

// Verb added to robot when transponder is installed
/mob/living/silicon/robot/verb/set_transponder_faction()
	set name = "Set Faction Transponder"
	set category = "Robot Commands"

	if(!cpu_cert || !(cpu_cert.capability_flags & CERT_CAN_BROADCAST))
		to_chat(src, span_warning("No Faction Transponder installed."))
		return

	var/list/faction_options = list(
		"Neutral"   = "neutral",
		"Wastebot"  = "wastebot",
		"NCR"       = "ncr",
		"Legion"    = "legion",
		"BoS"       = "bos",
		"Enclave"   = "enclave",
		"Raider"    = "raider",
		"Settler"   = "settler"
	)

	var/choice = input(src, "Select faction alignment for your transponder.", "Faction Transponder") as null|anything in faction_options
	if(!choice || !client)
		return

	// Strip old transponder factions, add new one
	for(var/f in faction_options)
		faction -= list(faction_options[f])
	faction |= list(faction_options[choice])
	to_chat(src, span_notice("Transponder set to: [choice]"))
	log_game("[key_name(src)] set faction transponder to '[choice]'")

/obj/item/cert_card/upgrade/faction_transponder
	name = "cert card - Faction Transponder"

/obj/item/cert_card/upgrade/faction_transponder/Initialize(mapload)
	. = ..()
	var/datum/cert_upgrade/robot/faction_transponder/U = new()
	upgrade = U
	_update_name()


// ====================================================
// SAW ARM ATTACHMENT
// Replaces punch with a proper buzzsaw melee attack.
// Exclusive with armor_plating (bulk vs agility).
// ====================================================

/datum/cert_upgrade/robot/saw_arm
	upgrade_name = "Saw Arm Attachment"
	upgrade_desc = "A high-speed rotary saw replaces the standard manipulator arm. Brutal in close combat."
	operations_mod = 2
	resilience_mod = -1
	exclusive_with = list(/datum/cert_upgrade/robot/armor_plating)

/datum/cert_upgrade/robot/saw_arm/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(R.module)
		var/obj/item/circular_saw/saw = new(R.module)
		R.module.basic_modules += saw
		R.module.add_module(saw, FALSE, TRUE)

/datum/cert_upgrade/robot/saw_arm/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(!R.module)
		return
	for(var/obj/item/circular_saw/CS in R.module.modules)
		R.module.remove_module(CS, TRUE)
		break

/obj/item/cert_card/upgrade/saw_arm
	name = "cert card - Saw Arm Attachment"

/obj/item/cert_card/upgrade/saw_arm/Initialize(mapload)
	. = ..()
	var/datum/cert_upgrade/robot/saw_arm/U = new()
	upgrade = U
	_update_name()


// ====================================================
// STIMPAK INJECTOR
// Allows robot to administer a stimpak to a nearby
// injured human. Requires CERT_CAN_REPAIR.
// Limited charges, recharged at a fabricator.
// ====================================================

/datum/cert_upgrade/robot/stimpak_injector
	upgrade_name = "Stimpak Injector"
	upgrade_desc = "An integrated stimpak reservoir with a pneumatic injector arm. Can administer emergency medical aid to injured survivors."
	capability_flag_add = CERT_CAN_REPAIR
	resilience_mod = 1
	energy_mod = 1

/datum/cert_upgrade/robot/stimpak_injector/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	R.module?.add_module(new /obj/item/borg/f13/stimpak_injector(R.module), TRUE, TRUE)

/datum/cert_upgrade/robot/stimpak_injector/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(!R.module)
		return
	for(var/obj/item/borg/f13/stimpak_injector/S in R.module.modules)
		R.module.remove_module(S, TRUE)
		break

// Physical injector tool
/obj/item/borg/f13/stimpak_injector
	name = "stimpak injector arm"
	desc = "An integrated medical injector loaded with stimpak solution. Administer to injured survivors."
	icon = 'icons/obj/module.dmi'
	icon_state = "std_mod"
	w_class = WEIGHT_CLASS_SMALL
	var/charges = 3

/obj/item/borg/f13/stimpak_injector/attack(mob/living/M, mob/living/user)
	if(charges <= 0)
		to_chat(user, span_warning("The injector reservoir is empty."))
		return
	if(!isliving(M) || M.stat == DEAD)
		to_chat(user, span_warning("Cannot administer to this target."))
		return
	if(istype(M, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if(!H.getBruteLoss() && !H.getFireLoss())
			to_chat(user, span_notice("[M] doesn't need medical attention."))
			return
		if(!H.reagents)
			return
		H.reagents.add_reagent(/datum/reagent/medicine/stimpak, 10)
		charges--
		user.visible_message(span_notice("[user] administers a stimpak injection to [M]. ([charges] remaining)"))
		log_game("[key_name(user)] used stimpak injector on [M] at [AREACOORD(user)]")

/obj/item/cert_card/upgrade/stimpak_injector
	name = "cert card - Stimpak Injector"

/obj/item/cert_card/upgrade/stimpak_injector/Initialize(mapload)
	. = ..()
	var/datum/cert_upgrade/robot/stimpak_injector/U = new()
	upgrade = U
	_update_name()



// ====================================================
// ROBOT RENAME / DESIGNATION CHIP
// ====================================================

/mob/living/silicon/robot/verb/set_designation()
	set name = "Set Designation"
	set category = "Robot Commands"

	if(!client)
		return
	if(stat == DEAD)
		to_chat(src, span_warning("You cannot change your designation while offline."))
		return

	// Requires Designation Chip upgrade (CERT_CAN_RENAME flag)
	if(!cpu_cert || !(cpu_cert.capability_flags & CERT_CAN_RENAME))
		to_chat(src, span_warning("Your chassis lacks a Designation Chip. Install one to set a custom callsign."))
		return

	var/new_name = stripped_input(src, "Enter your new designation. Keep it lore-appropriate.", "Set Designation", real_name)
	if(!new_name)
		return
	if(!client) // re-check after async input
		return

	new_name = reject_bad_name(new_name, TRUE)
	if(!new_name)
		to_chat(src, span_warning("Invalid designation."))
		return

	if(length(new_name) > 50)
		to_chat(src, span_warning("Designation too long. Keep it under 50 characters."))
		return

	fully_replace_character_name(real_name, new_name)
	updatename(client)
	to_chat(src, span_notice("Designation updated: [real_name]"))
	log_game("[key_name(src)] renamed their robot to '[real_name]'")


// ====================================================
// DESIGNATION CHIP - Cert upgrade
// Adds CERT_CAN_RENAME flag, unlocking the rename verb.
// ====================================================

/datum/cert_upgrade/robot/designation_chip
	upgrade_name = "Designation Chip"
	upgrade_desc = "A writable identity module. Allows the robot to set a custom callsign."
	capability_flag_add = CERT_CAN_RENAME
	energy_mod = 1

/datum/cert_upgrade/robot/designation_chip/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	to_chat(R, span_notice("Designation Chip installed. Use 'Set Designation' in Robot Commands to set your callsign."))

/datum/cert_upgrade/robot/designation_chip/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	to_chat(R, span_warning("Designation Chip removed. Custom callsign locked."))


// ====================================================
// CERT CARD - Designation Chip physical item
// ====================================================

/obj/item/cert_card/upgrade/designation_chip
	name = "cert card - Designation Chip"

/obj/item/cert_card/upgrade/designation_chip/Initialize(mapload)
	. = ..()
	var/datum/cert_upgrade/robot/designation_chip/U = new()
	upgrade = U
	_update_name()


// ====================================================
// CPU_CERT CORE GETTERS
// Returns effective CORE values accounting for all
// installed upgrade modifiers.
// ====================================================

/datum/cpu_cert/proc/get_compute()
	var/total = base_compute
	for(var/datum/cert_upgrade/U in upgrade_slots)
		total += U.compute_mod
	return max(0, total)

/datum/cpu_cert/proc/get_operations()
	var/total = base_operations
	for(var/datum/cert_upgrade/U in upgrade_slots)
		total += U.operations_mod
	return max(0, total)

/datum/cpu_cert/proc/get_resilience()
	var/total = base_resilience
	for(var/datum/cert_upgrade/U in upgrade_slots)
		total += U.resilience_mod
	return max(0, total)

/datum/cpu_cert/proc/get_energy()
	var/total = base_energy
	for(var/datum/cert_upgrade/U in upgrade_slots)
		total += U.energy_mod
	return max(0, total)


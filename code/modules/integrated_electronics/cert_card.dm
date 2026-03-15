// ====================================================
// CERT CARD
// Physical item that carries either a base cpu_cert
// OR a single cert_upgrade into the world.
// Used to install/swap upgrades on robots and machines,
// or to stamp a base cert onto a blank chassis.
//
// File: code/modules/integrated_electronics/cert_card.dm
// ====================================================


/obj/item/cert_card
	name = "cert card"
	desc = "A certification card. Scan it to read its contents."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"
	lefthand_file  = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'

	/// If this card carries a base cert, it lives here.
	var/datum/cpu_cert/base_cert = null

	/// If this card carries a single upgrade, it lives here.
	var/datum/cert_upgrade/upgrade = null


// ====================================================
// INITIALIZATION
// ====================================================

/obj/item/cert_card/Initialize(mapload)
	. = ..()
	_update_name()

/obj/item/cert_card/Destroy()
	if(base_cert)
		qdel(base_cert)
	base_cert = null
	if(upgrade)
		qdel(upgrade)
	upgrade = null
	return ..()

/obj/item/cert_card/proc/_update_name()
	if(base_cert)
		name = "cert card - [base_cert.cert_name]"
		desc = "A base chassis certification card. [base_cert.cert_desc]"
	else if(upgrade)
		name = "cert card - [upgrade.upgrade_name]"
		desc = "An upgrade certification card. [upgrade.upgrade_desc]"
	else
		name = "cert card (blank)"
		desc = "A blank certification card. It hasn't been programmed yet."


// ====================================================
// EXAMINE
// ====================================================

/obj/item/cert_card/examine(mob/user)
	. = ..()
	if(base_cert)
		. += span_notice("--- Base Certification ---")
		. += span_notice("Name: [base_cert.cert_name]")
		. += span_notice("Tier: [base_cert.cert_tier]")
		. += span_notice("Upgrade Slots: [base_cert.max_upgrade_slots]")
		. += span_notice("C.O.R.E: C[base_cert.base_compute] O[base_cert.base_operations] R[base_cert.base_resilience] E[base_cert.base_energy]")
	else if(upgrade)
		. += span_notice("--- Upgrade Module ---")
		. += span_notice("Name: [upgrade.upgrade_name]")
		if(upgrade.required_tier > CERT_TIER_BASIC)
			. += span_warning("Requires: Tier [upgrade.required_tier] chassis or higher.")
		if(upgrade.required_cert_type)
			. += span_warning("Compatible chassis only.")
		var/list/stat_lines = list()
		if(upgrade.compute_mod)
			var/c_sign = upgrade.compute_mod > 0 ? "+" : ""
			stat_lines += "Compute [c_sign][upgrade.compute_mod]"
		if(upgrade.operations_mod)
			var/o_sign = upgrade.operations_mod > 0 ? "+" : ""
			stat_lines += "Operations [o_sign][upgrade.operations_mod]"
		if(upgrade.resilience_mod)
			var/r_sign = upgrade.resilience_mod > 0 ? "+" : ""
			stat_lines += "Resilience [r_sign][upgrade.resilience_mod]"
		if(upgrade.energy_mod)
			var/e_sign = upgrade.energy_mod > 0 ? "+" : ""
			stat_lines += "Energy [e_sign][upgrade.energy_mod]"
		if(upgrade.exclusive_with && upgrade.exclusive_with.len)
			. += span_warning("Conflicts with: [upgrade.exclusive_with.Join(", ")]")
		if(upgrade.required_capability_flags)
			. += span_warning("Requires chassis capability flag: [upgrade.required_capability_flags]")
		if(stat_lines.len)
			. += span_notice("C.O.R.E. delta: [english_list(stat_lines)]")
		if(upgrade.tutorial_text && upgrade.tutorial_text != "No documentation available.")
			. += span_notice("[upgrade.tutorial_text]")
	else
		. += span_warning("This card is blank and unprogrammed.")


// ====================================================
// INTERACTION — USE ON ROBOT/MACHINE
// ====================================================

/obj/item/cert_card/attack(atom/target, mob/living/user)
	if(istype(target, /mob/living/silicon/robot))
		try_apply_to_robot(target, user)
		return
	if(istype(target, /mob/living/silicon/ai))
		try_apply_to_ai(target, user)
		return
	return ..()

/obj/item/cert_card/attack_self(mob/user)
	examine(user)


// ====================================================
// ROBOT APPLICATION
// ====================================================

/obj/item/cert_card/proc/try_apply_to_robot(mob/living/silicon/robot/R, mob/living/user)
	if(!R.opened)
		to_chat(user, span_warning("You need to open [R]'s panel first."))
		return

	// --- BASE CERT ---
	if(base_cert)
		if(R.cpu_cert)
			to_chat(user, span_warning("[R] already has a certification installed. Remove it first."))
			return
		// Soft warning: check if cert role matches the robot's module tags
		if(R.module)
			var/cert_role = _get_cert_role_hint(base_cert)
			var/module_tags = R.module.module_tags
			if(cert_role && module_tags != ROBOT_ROLE_ANY)
				if(cert_role == "combat" && !(module_tags & (ROBOT_ROLE_COMBAT | ROBOT_ROLE_SECURITY | ROBOT_ROLE_APEX)))
					to_chat(user, span_warning("Warning: Combat cert is designed for combat/security chassis. This module is a [R.module.name]. It will install, but the cert may not suit this chassis."))
				else if(cert_role == "support" && !(module_tags & ROBOT_ROLE_SUPPORT))
					to_chat(user, span_warning("Warning: Medical cert is best suited for support chassis like Mr. Handy. This module is a [R.module.name]. It will install, but you may want Standard or Engineering instead."))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return
		R.cpu_cert = base_cert
		base_cert = null
		R.cpu_cert.apply_to_holder(R)
		to_chat(user, span_notice("You install the [R.cpu_cert.cert_name] certification into [R]."))
		log_game("[key_name(user)] installed cert '[R.cpu_cert.cert_name]' into [R] at [AREACOORD(R)]")
		_update_name()
		return

	// --- UPGRADE ---
	if(upgrade)
		if(!R.cpu_cert)
			to_chat(user, span_warning("[R] has no base certification installed. Install a base cert first."))
			return

		var/datum/cpu_cert/C = R.cpu_cert
		var/datum/cert_upgrade/conflict = _find_conflict(C, upgrade)
		if(conflict)
			to_chat(user, span_warning("Upgrade conflicts with installed [conflict.upgrade_name]. Remove it first."))
			return

		if(!C.can_install_upgrade(upgrade))
			_explain_rejection(C, upgrade, user)
			return

		if(!user.temporarilyRemoveItemFromInventory(src))
			return

		var/datum/cert_upgrade/held_upgrade = upgrade
		upgrade = null
		if(C.install_upgrade(held_upgrade, R))
			to_chat(user, span_notice("You install [held_upgrade.upgrade_name] into [R]."))
			log_game("[key_name(user)] installed upgrade '[held_upgrade.upgrade_name]' into [R] at [AREACOORD(R)]")
			qdel(src)
		else
			upgrade = held_upgrade
			to_chat(user, span_warning("Installation failed."))
			forceMove(user.drop_location())
		return

	to_chat(user, span_warning("This card is blank — nothing to install."))


/// Returns a short role string for a cpu_cert datum so try_apply_to_robot
/// can warn when the cert seems mismatched to the robot's module.
/// Returns "combat", "support", or null (no opinion).
/obj/item/cert_card/proc/_get_cert_role_hint(datum/cpu_cert/C)
	if(istype(C, /datum/cpu_cert/robot/combat))
		return "combat"
	if(istype(C, /datum/cpu_cert/robot/medical))
		return "support"
	return null


// ====================================================
// AI APPLICATION
// ====================================================

/obj/item/cert_card/proc/try_apply_to_ai(mob/living/silicon/ai/AI, mob/living/user)
	if(!upgrade)
		to_chat(user, span_warning("This card carries no upgrade."))
		return

	if(!AI.cpu_cert)
		to_chat(user, span_warning("[AI] has no base certification installed."))
		return

	var/datum/cpu_cert/C = AI.cpu_cert

	if(!C.can_install_upgrade(upgrade))
		_explain_rejection(C, upgrade, user)
		return

	if(!user.temporarilyRemoveItemFromInventory(src))
		return

	var/datum/cert_upgrade/held_upgrade = upgrade
	upgrade = null
	if(C.install_upgrade(held_upgrade, AI))
		to_chat(user, span_notice("You install [held_upgrade.upgrade_name] into [AI]."))
		log_game("[key_name(user)] installed upgrade '[held_upgrade.upgrade_name]' into [AI] at [AREACOORD(AI)]")
		qdel(src)
	else
		upgrade = held_upgrade
		to_chat(user, span_warning("Installation failed."))
		forceMove(user.drop_location())


// ====================================================
// UPGRADE STRIPPING
// ====================================================

/obj/item/cert_card/proc/strip_upgrade_from(mob/living/silicon/robot/R, datum/cert_upgrade/U, mob/living/user)
	if(!R.opened)
		to_chat(user, span_warning("You need to open [R]'s panel first."))
		return FALSE

	if(!R.cpu_cert)
		to_chat(user, span_warning("[R] has no certification installed."))
		return FALSE

	if(!(U in R.cpu_cert.upgrade_slots))
		to_chat(user, span_warning("[U.upgrade_name] is not installed in [R]."))
		return FALSE

	if(R.cpu_cert.capability_flags & CERT_LOCKED)
		to_chat(user, span_warning("[R]'s certification is locked and cannot be modified."))
		return FALSE

	// Behavior assemblies are physical items - hand the assembly back directly,
	// don't wrap it in a new cert card.
	if(istype(U, /datum/cert_upgrade/robot/behavior_assembly))
		var/datum/cert_upgrade/robot/behavior_assembly/BA = U
		R.cpu_cert.remove_upgrade(U, R)
		var/obj/item/behavior_assembly/A = BA.assembly
		if(A)
			A.forceMove(user.drop_location())
			to_chat(user, span_notice("You remove [A.assembly_label] from [R]."))
			log_game("[key_name(user)] stripped behavior assembly '[A.assembly_label]' from [R] at [AREACOORD(R)]")
		BA.assembly = null
		qdel(BA)
		return TRUE

	R.cpu_cert.remove_upgrade(U, R)

	var/obj/item/cert_card/card = new(user.drop_location())
	card.upgrade = U
	card._update_name()

	to_chat(user, span_notice("You remove [U.upgrade_name] from [R] and store it on a cert card."))
	log_game("[key_name(user)] stripped upgrade '[U.upgrade_name]' from [R] at [AREACOORD(R)]")
	return TRUE


// ====================================================
// HELPERS
// ====================================================

/obj/item/cert_card/proc/_find_conflict(datum/cpu_cert/C, datum/cert_upgrade/candidate)
	if(!candidate.exclusive_with.len)
		return null
	for(var/datum/cert_upgrade/installed in C.upgrade_slots)
		if(is_type_in_list(installed, candidate.exclusive_with))
			return installed
	return null

/obj/item/cert_card/proc/_explain_rejection(datum/cpu_cert/C, datum/cert_upgrade/U, mob/living/user)
	if(C.capability_flags & CERT_LOCKED)
		to_chat(user, span_warning("This chassis is locked. Its certification cannot be modified."))
		return
	if(C.upgrade_slots.len >= C.max_upgrade_slots)
		to_chat(user, span_warning("No upgrade slots remaining. Remove an existing upgrade first."))
		return
	if(U.required_tier > C.cert_tier)
		to_chat(user, span_warning("This upgrade requires a Tier [U.required_tier] chassis. [C.cert_name] is only Tier [C.cert_tier]."))
		return
	if(U.required_capability_flags && !(C.capability_flags & U.required_capability_flags))
		to_chat(user, span_warning("This chassis lacks a required capability for [U.upgrade_name]. Check the upgrade card's examine text for what flag is needed."))
		return
	if(U.required_cert_type && !istype(C, U.required_cert_type))
		to_chat(user, span_warning("That upgrade requires a [U.required_cert_type] chassis. This chassis is [C.type]."))
		return
	to_chat(user, span_warning("That upgrade cannot be installed in this chassis."))


// ====================================================
// CERT CARD SUBTYPES
// ====================================================

// --- Base cert cards ---
/obj/item/cert_card/base
	name = "cert card - Standard Chassis"

/obj/item/cert_card/base/Initialize(mapload)
	. = ..()
	base_cert = new /datum/cpu_cert/robot()
	_update_name()

/obj/item/cert_card/base/combat
	name = "cert card - Combat Chassis"

/obj/item/cert_card/base/combat/Initialize(mapload)
	. = ..()
	base_cert = new /datum/cpu_cert/robot/combat()
	_update_name()

/obj/item/cert_card/base/medical
	name = "cert card - Medical Chassis"

/obj/item/cert_card/base/medical/Initialize(mapload)
	. = ..()
	base_cert = new /datum/cpu_cert/robot/medical()
	_update_name()

/obj/item/cert_card/base/engineering
	name = "cert card - Engineering Chassis"

/obj/item/cert_card/base/engineering/Initialize(mapload)
	. = ..()
	base_cert = new /datum/cpu_cert/robot/engineering()
	_update_name()

/obj/item/cert_card/base/hacking_tool
	name = "cert card - Hacking Tool Certificate"

/obj/item/cert_card/base/hacking_tool/Initialize(mapload)
	. = ..()
	base_cert = new /datum/cpu_cert/device/hacking_tool()
	_update_name()

// --- Upgrade cards ---
/obj/item/cert_card/upgrade
	name = "cert card - upgrade"

/obj/item/cert_card/upgrade/vtec
	name = "cert card - VTEC Sprint System"

/obj/item/cert_card/upgrade/vtec/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/vtec()
	_update_name()

/obj/item/cert_card/upgrade/armor_plating
	name = "cert card - Reinforced Armor Plating"

/obj/item/cert_card/upgrade/armor_plating/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/armor_plating()
	_update_name()

/obj/item/cert_card/upgrade/thrusters
	name = "cert card - Ion Thruster System"

/obj/item/cert_card/upgrade/thrusters/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/thrusters()
	_update_name()

/obj/item/cert_card/upgrade/disabler_cooler
	name = "cert card - Energy Weapon Cooling System"

/obj/item/cert_card/upgrade/disabler_cooler/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/disabler_cooler()
	_update_name()

/obj/item/cert_card/upgrade/targeting_system
	name = "cert card - Advanced Targeting System"

/obj/item/cert_card/upgrade/targeting_system/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/targeting_system()
	_update_name()

/obj/item/cert_card/upgrade/emp_shielding
	name = "cert card - EMP Shielding Array"

/obj/item/cert_card/upgrade/emp_shielding/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/emp_shielding()
	_update_name()

/obj/item/cert_card/upgrade/hacking_module
	name = "cert card - Intrusion Countermeasure Suite"

/obj/item/cert_card/upgrade/hacking_module/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/hacking_module()
	_update_name()

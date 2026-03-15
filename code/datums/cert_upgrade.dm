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

	/// Player-facing explanation of what this upgrade does and when to use it.
	/// Shown in the CPU Fabricator upgrade list and on cert_card examine.
	var/tutorial_text = "No documentation available."

	/// If set, this upgrade only installs into this cert type or its subtypes
	var/required_cert_type = null

	/// Minimum cert tier required
	var/required_tier = CERT_TIER_BASIC

	/// Capability flags the cert must ALREADY have before this installs.
	/// Shown as a requirement hint in the fabricator UI.
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

	/// List of /datum/cert_upgrade types that cannot coexist with this upgrade.
	/// Checked at install time; installation is blocked if a conflict is found.
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
// BEHAVIOR ASSEMBLY UPGRADE
// Wraps a behavior_assembly item inside a cert upgrade
// slot so the assembly fires on the robot's clock tick.
// Defined here (not in behavior_circuits.dm) because
// cert_card.dm and robot_workshop.dm both need the type.
// ====================================================

/datum/cert_upgrade/robot/behavior_assembly
	upgrade_name = "Behavior Assembly"
	upgrade_desc = "An installed behavior assembly. Drives the robot's autonomous actions."
	tutorial_text = "This slot holds the robot's active behavior assembly -- the circuit program that tells it when to act and how to respond. Install a behavior_assembly item at the Robot Workshop, or print one at the CPU Cert Fabricator."
	energy_mod = 2

	/// The physical behavior_assembly item embedded in this cert slot.
	/// cert_card.strip_upgrade_from() hands it back as a physical item when removed.
	var/obj/item/behavior_assembly/assembly = null

/datum/cert_upgrade/robot/behavior_assembly/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(assembly)
		assembly.register_signals(R)

/datum/cert_upgrade/robot/behavior_assembly/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	if(assembly)
		assembly.unregister_signals(R)


// ====================================================
// ROBOT UPGRADES
// ====================================================

/datum/cert_upgrade/robot
	required_cert_type = /datum/cpu_cert/robot


// --- VTEC ---
/datum/cert_upgrade/robot/vtec
	upgrade_name   = "VTEC Sprint System"
	upgrade_desc   = "Overclocks locomotion servos for burst speed capability."
	tutorial_text  = "Unlocks the VTEC sprint ability. The robot gains a toggled high-speed burst mode at the cost of increased operations load. Exclusive with Armor Plating -- bulk and speed don't mix. Use on fast skirmisher builds."
	capability_flag_add = CERT_CAN_SPRINT
	operations_mod = 1
	energy_mod     = 2
	exclusive_with = list(/datum/cert_upgrade/robot/armor_plating)

/datum/cert_upgrade/robot/vtec/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	// Disable native cansprint so it doesn't double-fire alongside the VTEC ability.
	// Always add the controlled ability regardless of prior sprint state.
	R.cansprint = FALSE
	R.AddAbility(new /obj/effect/proc_holder/silicon/cyborg/vtecControl)

/datum/cert_upgrade/robot/vtec/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	// Remove the VTEC ability and restore native sprint capability.
	R.RemoveAbility(/obj/effect/proc_holder/silicon/cyborg/vtecControl)
	R.speed = initial(R.speed)
	R.cansprint = TRUE


// --- ARMOR PLATING ---
// Uses cert_armor_bonus var on the robot mob to reduce incoming brute damage.
// Checked in bullet_act and melee damage via the bonus var.
/datum/cert_upgrade/robot/armor_plating
	upgrade_name   = "Reinforced Armor Plating"
	upgrade_desc   = "Heavy plating bolted over chassis joints. Tough but sluggish."
	tutorial_text  = "Adds 25 flat armor against brute damage. Significant defensive upgrade for frontline robots. Reduces operations by 2 due to added bulk. Exclusive with VTEC Sprint -- you can't be both fast and heavily armored."
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
	upgrade_name   = "Ion Thruster System"
	upgrade_desc   = "Energy-fed thrusters for microgravity traversal and jump assists."
	tutorial_text  = "Enables ionpulse movement -- the robot can traverse low-gravity environments and execute jump assists. Requires the chassis to already have CERT_CAN_MOVE (locomotion capability). Toggle via the ionpulse verb in Robot Commands."
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
	// Deactivate thrusters before clearing the flag to avoid a mid-flight disable crash.
	if(R.ionpulse_on)
		R.toggle_ionpulse()
	R.ionpulse = FALSE


// --- DISABLER COOLER ---
/datum/cert_upgrade/robot/disabler_cooler
	upgrade_name   = "Energy Weapon Cooling System"
	upgrade_desc   = "Active cooling for energy-based weapons, increasing recharge rate."
	tutorial_text  = "Reduces energy weapon charge_delay by 4 deciseconds (floor: 2). Makes energy guns fire significantly faster. Requires CERT_CAN_SHOOT. Stack with Targeting System for maximum ranged offense."
	required_capability_flags = CERT_CAN_SHOOT
	operations_mod = 1
	energy_mod     = 1
	// FIX: original had list(/datum/cert_upgrade/robot/disabler_cooler) -- self-reference
	// that permanently blocked installation. Now correctly empty.
	exclusive_with = list()

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
	upgrade_name   = "Advanced Targeting System"
	upgrade_desc   = "Improves weapon tracking and reaction targeting calculations."
	tutorial_text  = "Passively improves targeting for behavior circuits that have CERT_CAN_SHOOT requirement. No toggle needed -- the bonus applies automatically. Adds significant operations cost. Pair with Disabler Cooler for a full ranged-combat build."
	required_capability_flags = CERT_CAN_SHOOT
	operations_mod = 2
	energy_mod     = 1

// on_apply/on_remove inherited from base -- capability flags are handled automatically
// if capability_flag_add is set. Targeting System has no flag to add; its benefit is
// passive via the operations bonus influencing assembly circuit scheduling.


// --- EMP SHIELDING ---
/datum/cert_upgrade/robot/emp_shielding
	upgrade_name   = "EMP Shielding Array"
	upgrade_desc   = "Faraday shielding woven into chassis internals."
	tutorial_text  = "Makes the robot immune to EMP effects -- wires won't be fried, contents won't be disrupted. Adds CERT_EMP_HARDENED. Essential for robots operating in combat zones or near energy weapons."
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
	upgrade_name   = "Intrusion Countermeasure Suite"
	upgrade_desc   = "Military-grade hacking suite. Allows interfacing with hardened electronic systems."
	tutorial_text  = "Unlocks CERT_CAN_HACK, enabling the robot to interact with hardened terminals, airlocks, and electronics. Requires Tier 2 Military chassis AND the CERT_MILITARY_GRADE flag. Not available to standard civilian units."
	required_tier  = CERT_TIER_MILITARY
	required_capability_flags = CERT_MILITARY_GRADE
	capability_flag_add = CERT_CAN_HACK
	compute_mod = 2
	energy_mod  = 2


// --- HARDENED ICE ---
/datum/cert_upgrade/robot/hardened_ice
	upgrade_name   = "Hardened ICE"
	upgrade_desc   = "Passive intrusion countermeasure. Burns one of the attacker's attempts every hack session automatically."
	tutorial_text  = "Adds CERT_ICE_HARDENED. When this robot is hacked, the attacker silently loses one attempt at the start of the session — before they even guess a word. Stacks with high security_difficulty for layered defense. The attacker won't know why they have fewer attempts. Pairs with Breach Response Protocol for the full defensive build."
	capability_flag_add = CERT_ICE_HARDENED
	compute_mod = 1
	energy_mod  = 1


// ====================================================
// AI UPGRADES
// ====================================================

/datum/cert_upgrade/ai
	required_cert_type = /datum/cpu_cert/ai


// --- MALF PACKAGE ---
/datum/cert_upgrade/ai/malf_package
	upgrade_name   = "Combat Software Package"
	upgrade_desc   = "Highly illegal. Grants the AI access to malfunction-class combat routines."
	tutorial_text  = "Installs malfunction-class AI combat routines. Once applied, cannot be removed -- the change is permanent for this session. Requires Military AI cert. Only usable on AI units, not robots."
	required_cert_type = /datum/cpu_cert/ai/military
	required_tier  = CERT_TIER_MILITARY
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
	upgrade_name   = "Surveillance Software Package"
	upgrade_desc   = "Allows the AI to hear through cameras via lip-reading and hidden microphones."
	tutorial_text  = "Activates relay_speech on the AI's eyeobj -- the AI can hear conversations near any camera it can see through. Useful for information-gathering AIs. Adds CERT_CAN_SURVEIL. No effect if AI has no eyeobj."
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
	upgrade_name   = "Extended Sensor Array"
	upgrade_desc   = "Boosts detection and targeting range."
	tutorial_text  = "Increases sensor range for detection-based behaviors. Compatible with all cert types (required_cert_type = null). Good general-purpose upgrade for scout or patrol builds."
	required_cert_type = null
	compute_mod    = 1
	operations_mod = 1
	energy_mod     = 1

/datum/cert_upgrade/device/hardened
	upgrade_name   = "Hardened Casing"
	upgrade_desc   = "Reinforced housing resistant to EMP and physical damage."
	tutorial_text  = "Adds CERT_EMP_HARDENED to any device cert. Compatible with all cert types. Use on fixed installations that cannot easily be evacuated from hostile areas."
	required_cert_type = null
	capability_flag_add = CERT_EMP_HARDENED
	resilience_mod = 2
	energy_mod     = 1

/datum/cert_upgrade/device/auto_reload
	upgrade_name   = "Automated Throughput System"
	upgrade_desc   = "Speeds up fabrication cycles."
	tutorial_text  = "Reduces fabrication time for devices with a fabricator cert. Requires /datum/cpu_cert/device/fabricator -- has no effect on other cert types."
	required_cert_type = /datum/cpu_cert/device/fabricator
	compute_mod = 1
	energy_mod  = 2


// ====================================================
// F13 CERT UPGRADES
// ====================================================

// CERT_CAN_RENAME, CERT_IS_HACKABLE, and CERT_ICE_HARDENED are defined in
// code/_DEFINES/_flags/robots.dm alongside all other cert capability flags.


// ====================================================
// RADAWAY INJECTOR
// ====================================================

/datum/cert_upgrade/robot/rad_shielding
	upgrade_name   = "Radaway Injector"
	upgrade_desc   = "An integrated RadAway dispenser arm. Administers anti-radiation treatment to irradiated survivors nearby."
	tutorial_text  = "Installs a borghypo loaded with RadAway into the robot's module. The robot can administer it to nearby humans to clear radiation buildup. Adds CERT_CAN_REPAIR. The borghypo can be refilled at a chemistry station."
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
	upgrade = new /datum/cert_upgrade/robot/rad_shielding()
	_update_name()


// ====================================================
// SCAVENGER ARRAY
// ====================================================

/datum/cert_upgrade/robot/scavenger_array
	upgrade_name   = "Scavenger Array"
	upgrade_desc   = "Advanced proximity sensors tuned for detecting valuable salvage and organic remains."
	tutorial_text  = "Adds CERT_CAN_INTERFACE and activates proximity salvage detection. The robot passively identifies nearby items of value and organic remains. Good for loot-runner or merchant builds operating in ruins."
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
	upgrade = new /datum/cert_upgrade/robot/scavenger_array()
	_update_name()


// ====================================================
// FACTION TRANSPONDER
// ====================================================

/datum/cert_upgrade/robot/faction_transponder
	upgrade_name   = "Faction Transponder"
	upgrade_desc   = "A programmable IFF transponder. Allows the robot to broadcast a specific faction signal."
	tutorial_text  = "Unlocks 'Set Faction Transponder' under Robot Commands. Pick any major F13 faction. Previous transponder faction tags are stripped on switch. Does not affect technician-assigned faction tags. Adds CERT_CAN_BROADCAST."
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

	for(var/f in faction_options)
		faction -= list(faction_options[f])
	faction |= list(faction_options[choice])
	to_chat(src, span_notice("Transponder set to: [choice]"))
	log_game("[key_name(src)] set faction transponder to '[choice]'")

/obj/item/cert_card/upgrade/faction_transponder
	name = "cert card - Faction Transponder"

/obj/item/cert_card/upgrade/faction_transponder/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/faction_transponder()
	_update_name()


// ====================================================
// SAW ARM ATTACHMENT
// ====================================================

/datum/cert_upgrade/robot/saw_arm
	upgrade_name   = "Saw Arm Attachment"
	upgrade_desc   = "A high-speed rotary saw replaces the standard manipulator arm. Brutal in close combat."
	tutorial_text  = "Adds a circular_saw to the robot's module. Dramatically increases melee damage. Exclusive with Armor Plating -- the saw arm requires full freedom of movement. Reduces resilience by 1 due to exposed mechanical joints."
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
	upgrade = new /datum/cert_upgrade/robot/saw_arm()
	_update_name()


// ====================================================
// STIMPAK INJECTOR
// ====================================================

/datum/cert_upgrade/robot/stimpak_injector
	upgrade_name   = "Stimpak Injector"
	upgrade_desc   = "An integrated stimpak reservoir with a pneumatic injector arm. Can administer emergency medical aid to injured survivors."
	tutorial_text  = "Adds a stimpak injector arm (3 charges) to the robot's module. Click on an injured human to inject. Cannot target the dead or uninjured. Adds CERT_CAN_REPAIR. Shares the flag with Radaway Injector -- both can be installed simultaneously."
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
	upgrade = new /datum/cert_upgrade/robot/stimpak_injector()
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

	if(!cpu_cert || !(cpu_cert.capability_flags & CERT_CAN_RENAME))
		to_chat(src, span_warning("Your chassis lacks a Designation Chip. Install one to set a custom callsign."))
		return

	var/new_name = stripped_input(src, "Enter your new designation. Keep it lore-appropriate.", "Set Designation", real_name)
	if(!new_name)
		return
	if(!client)
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


/datum/cert_upgrade/robot/designation_chip
	upgrade_name   = "Designation Chip"
	upgrade_desc   = "A writable identity module. Allows the robot to set a custom callsign."
	tutorial_text  = "Unlocks 'Set Designation' under Robot Commands. The robot can pick a custom name (up to 50 characters, name-filter validated). Purely cosmetic. Small energy draw. Good quality-of-life upgrade for player-controlled borgs."
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

/obj/item/cert_card/upgrade/designation_chip
	name = "cert card - Designation Chip"

/obj/item/cert_card/upgrade/designation_chip/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/robot/designation_chip()
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

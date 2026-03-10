// ====================================================
// ROBOT HACKING DEVICE — STUB
// Future PR. Do not implement here.
//
// ARCHITECTURE (settled):
//
//   /obj/item/hacking_device
//     - Carries its own /datum/cpu_cert/device/hacking_tool
//     - CERT_CAN_HACK on the device cert gates minigame access
//     - core_compute on the device cert = more time / more attempts
//     - High-tier certs (CERT_MILITARY_GRADE) = harder targets accessible
//
//   TARGET ROBOT:
//     - Must have CERT_IS_HACKABLE flag on its cpu_cert
//     - core_operations on the target cert = harder minigame (more words,
//       shorter timer, fewer attempts)
//     - NPC robots with no cpu_cert are always hackable (default easy tier)
//     - Player-controlled robots: hackable only if CERT_IS_HACKABLE set;
//       player gets a brief resist window before the hack completes
//
//   MINIGAME:
//     - Fallout wordlist minigame (see other PR for implementation)
//     - Device cert's core_compute → time limit + number of attempts
//     - Target cert's core_operations → word list difficulty + pool size
//     - Failure: device goes on cooldown, robot may react (NPC alert)
//     - Success: action menu (suppress / pacify / extract / reprogram /
//       shutdown — gated by device cert tier)
//
//   CERT FLAG NEEDED (add to robot_defines.dm or _flags/robots.dm):
//     #define CERT_IS_HACKABLE    (1 << 14)
//
//   CERT SUBTYPE NEEDED (add to cpu_fabricator.dm or cert_card.dm):
//     /datum/cpu_cert/device/hacking_tool
//       cert_name = "Hacking Tool Certificate"
//       cert_tier = CERT_TIER_BASIC  // base version; MILITARY_GRADE for advanced
//       capability_flags = CERT_CAN_HACK
//       core_compute = 2             // scales minigame time/attempts
//
//   SET CERT_IS_HACKABLE ON:
//     - /datum/cpu_cert/robot          (standard civilian chassis)
//     - /datum/cpu_cert/robot/medical
//     - /datum/cpu_cert/robot/engineering
//   DO NOT SET ON:
//     - /datum/cpu_cert/robot/combat   (hardened - resist hacking by default)
//     - Military/Enclave/BoS NPC certs
//
// File: code/modules/integrated_electronics/hacking_device.dm
// ====================================================

/obj/item/hacking_device
	name = "hacking device"
	desc = "A pre-war RobCo intrusion countermeasure tool. Interfaces with robot control systems to override or extract their programming. Requires a compatible hacking certificate."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "analyzer"
	w_class = WEIGHT_CLASS_SMALL
	force = 3
	throwforce = 5
	throw_range = 5
	throw_speed = 2

	// TODO: Future PR — implement alongside wordlist minigame
	// var/datum/cpu_cert/device/hacking_tool/device_cert = null


/obj/item/hacking_device/attack_self(mob/user)
	to_chat(user, span_notice("The hacking device is not yet functional. A compatible certificate module is required."))


/obj/item/hacking_device/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !istype(target, /mob/living/silicon/robot))
		return
	to_chat(user, span_warning("The hacking device needs a cert module installed before it can interface with [target]."))

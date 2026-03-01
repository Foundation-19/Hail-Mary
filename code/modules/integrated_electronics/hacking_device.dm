// ====================================================
// HACKING DEVICE — STUB
// Future PR. A handheld device that carries a cpu_cert
// with CERT_CAN_HACK. Used to initiate the fallout
// hacking minigame on target robots/terminals.
//
// Design notes for future implementor:
// - The DEVICE holds the cert (not the target)
// - Target robot must have hackable systems defined
//   on their cert (new flag: CERT_IS_HACKABLE)
// - CERT_CAN_HACK on device cert gates minigame access
// - High Compute stat on device cert = more time/attempts
// - High Operations stat on target cert = harder minigame
// - See code/__DEFINES/_flags/robots.dm for flag defs
//
// File: code/modules/integrated_electronics/hacking_device.dm
// ====================================================

/obj/item/hacking_device
	name = "hacking device"
	desc = "A pre-war intrusion countermeasure tool. It looks like it could interface with robot systems."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "analyzer"  // placeholder
	w_class = WEIGHT_CLASS_SMALL

	// TODO: Future PR
	// var/datum/cpu_cert/device_cert = null

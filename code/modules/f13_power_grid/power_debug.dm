// ============================================================
// F13 POWER GRID — DEBUG / TEST TOOLS
// ============================================================
//
// MASTER BREAKER
// ──────────────
// A physical in-world toggle that kills or restores the
// "magic" free power that the SS13 engine gives every area
// when no APC is present (power_equip/light/environ default
// to TRUE at initialisation).
//
// Place one on any test map.  Clicking it flips all /area/f13
// instances between:
//   ON  — areas powered normally (same as unmodified map)
//   OFF — areas dark; only areas owned by a live generator or
//         relay chain receive power from the fusion grid.
//
// This lets you test the fusion core grid in complete isolation
// without having to strip APCs or touch area definitions.
//
// MAPPER PLACEMENT:
//   /obj/machinery/f13/master_breaker
// ============================================================

GLOBAL_VAR_INIT(f13_magic_power, TRUE)

/obj/machinery/f13/master_breaker
	name          = "F13 master grid breaker"
	desc          = "Controls the map-wide 'always powered' override on all F13 areas. Toggle this to test the fusion core grid in isolation."
	icon          = 'icons/obj/power.dmi'
	icon_state    = "portgen0_1"   // icon: ON by default
	density       = FALSE
	anchored      = TRUE


/obj/machinery/f13/master_breaker/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	toggle_magic_power(user)

/// Toggle magic power for all /area/f13 instances.
/obj/machinery/f13/master_breaker/proc/toggle_magic_power(mob/user)
	GLOB.f13_magic_power = !GLOB.f13_magic_power

	// First pass — set every f13 area to the new baseline.
	for(var/area/f13/A in world)
		A.power_equip   = GLOB.f13_magic_power
		A.power_light   = GLOB.f13_magic_power
		A.power_environ = GLOB.f13_magic_power
		A.power_change()

	// Second pass (only when magic is OFF) — re-stamp zones that are
	// genuinely fed by a live generator or relay chain so they stay lit.
	if(!GLOB.f13_magic_power)
		for(var/obj/machinery/f13/faction_generator/G in world)
			if(!QDELETED(G) && G.powered)
				G.stamp_zone(TRUE)
		for(var/obj/machinery/f13/power_relay/R in world)
			if(!QDELETED(R) && R.relay_powered)
				R.stamp_zone(TRUE)

	update_icon_state()

	var/state_msg = GLOB.f13_magic_power ? "ON (areas always powered)" : "OFF (grid-only mode)"
	if(user)
		to_chat(user, span_notice("F13 magic power: [state_msg]"))
	message_admins("F13 magic power toggled [state_msg][user ? " by [key_name(user)]" : ""].")

/obj/machinery/f13/master_breaker/update_icon_state()
	icon_state = GLOB.f13_magic_power ? "portgen0_1" : "portgen0_0"


// ── Admin verb (alternate access without placing the object) ───────────────

/client/proc/f13_toggle_magic_power()
	set category  = "Debug"
	set name      = "Toggle F13 Magic Power"
	set desc      = "Flip the always-powered override on all F13 areas for grid testing."

	if(!check_rights(R_ADMIN))
		return

	// Reuse master_breaker logic — find any placed instance, or run inline.
	var/obj/machinery/f13/master_breaker/B = locate(/obj/machinery/f13/master_breaker) in world
	if(B)
		B.toggle_magic_power(usr)
	else
		// No breaker placed — run the toggle directly.
		GLOB.f13_magic_power = !GLOB.f13_magic_power
		for(var/area/f13/A in world)
			A.power_equip   = GLOB.f13_magic_power
			A.power_light   = GLOB.f13_magic_power
			A.power_environ = GLOB.f13_magic_power
			A.power_change()
		if(!GLOB.f13_magic_power)
			for(var/obj/machinery/f13/faction_generator/G in world)
				if(!QDELETED(G) && G.powered)
					G.stamp_zone(TRUE)
			for(var/obj/machinery/f13/power_relay/R in world)
				if(!QDELETED(R) && R.relay_powered)
					R.stamp_zone(TRUE)
		message_admins("F13 magic power toggled [GLOB.f13_magic_power ? "ON" : "OFF"] by [key_name(usr)].")

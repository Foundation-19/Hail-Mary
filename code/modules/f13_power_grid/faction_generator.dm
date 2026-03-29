// ============================================================
// FACTION BASE GENERATOR
// ============================================================
//
// Placed by a mapper inside or adjacent to a faction base.
// Powers the zone by setting f13_grid_power on controlled area instances,
// shutting down linked turrets on power failure, and notifying faction
// members by chat.
//
// Core fabricators must be physically wired to this generator using a
// cable coil before they can operate. Wiring is isolated — a fabricator
// is linked to exactly one generator.
//
// WIRING (cable coil):
//   1. Use a cable coil on the generator → marks it as the wire source.
//   2. Use the same coil on a fabricator or relay → link established (consumes 2 cable).
//   Wirecutters on the generator severes all downstream connections.
//   Swipe in either direction works (fabricator→generator routes via fabricator attackby).
//
// MAPPER SETUP EXAMPLE:
//   /obj/machinery/f13/faction_generator/ncr{
//       faction_tag        = FACTION_NCR
//       powered_area_types = list(/area/f13/ncr, /area/f13/ncr/barracks)
//       map_turret_tags    = "turret_ncr_gate,turret_ncr_wall"
//   }
//
// LOCK MODES:
//   GENERATOR_LOCK_NONE     — anyone may interact (default)
//   GENERATOR_LOCK_PERSONAL — only the registered owner_ckey
//   GENERATOR_LOCK_FACTION  — only members of owner_faction (social_faction match)
//   Registered by swiping an ID card after selecting the lock mode in the UI.
// ============================================================

/obj/machinery/f13/faction_generator
	name = "faction base generator"
	desc = "A heavy-duty power plant that sustains a faction's base infrastructure. Insert fusion cores to keep it running."
	icon = 'icons/obj/power.dmi'
	icon_state = "portgen0_0"
	density = TRUE
	anchored = TRUE
	max_integrity = 750
	armor = list(melee = 30, bullet = 10, laser = 5, energy = 5, bomb = 20, bio = 0, rad = 0, fire = 60, acid = 40)
	// This machine IS the power source — it must not draw from the area power system.
	use_power = NO_POWER_USE

	// ── Faction identity
	/// The FACTION_* string this generator belongs to (e.g. FACTION_NCR).
	/// Used to broadcast power-state messages to all faction members.
	var/faction_tag = null

	// ── Power state
	/// Whether the generator is currently supplying power.
	var/powered = FALSE
	/// Remaining fuel in SSobj ticks.
	var/fuel = 0
	/// Maximum fuel capacity (two cores — hard ceiling on insertion).
	var/max_fuel = FUSION_CORE_FUEL * 2

	// ── Area linkage — set by the mapper, resolved to live instances at init
	/// List of area type paths to power. E.g. list(/area/f13/ncr, /area/f13/ncr/barracks)
	var/list/powered_area_types = null
	/// Resolved live area datum instances (populated in Initialize).
	var/list/powered_area_instances = null

	// ── Turret linkage (mapper sets map_turret_tags, same pattern as terminal.dm)
	/// Comma-separated turret tag strings to auto-link on init.
	var/map_turret_tags = null
	/// Resolved live turret refs.
	var/list/linked_turrets = null

	// ── Relay wiring — populated at runtime by cable coil
	/// Live refs of all power relays directly wired to this generator.
	var/list/linked_relays = null

	// ── Generic grid clients — populated at runtime by cable coil
	/// Any /obj/machinery/f13/grid_client wired directly to this generator.
	var/list/linked_clients = null
	/// Grid clients currently suspended by load-shedding.  Draw = 0 while here.
	var/list/shed_clients = null

	// ── Lock system
	var/lock_mode     = GENERATOR_LOCK_NONE
	var/owner_ckey    = null
	/// Display name (real_name) of the personal lock owner, shown in the UI.
	var/owner_name    = null
	var/owner_faction = null
	/// When TRUE the next ID-card swipe registers a personal owner.
	var/pending_personal_reg = FALSE
	/// When TRUE the next ID-card swipe registers a faction owner.
	var/pending_faction_reg  = FALSE

	// ── Wattage budget (Factorio-style power accounting)
	/// Watts available — grows by FGEN_WATTS_PER_CORE for each inserted core slot in use.
	/// Recalculated whenever a core is inserted or the load changes.
	var/available_watts = 0
	/// Current total draw reported by relays, fabricators, and turrets.
	var/current_draw = 0
	/// TRUE when the generator has tripped due to overload.
	var/overloaded = FALSE

	// ── Load shedding — soft power management before hard-tripping the grid
	/// Direct relays currently suspended by load-shedding.  Draw = 0 while here.
	var/list/shed_relays = null

	// ── Mapper pre-wiring
	/// Comma-separated object tags for relays to auto-wire on Initialize.
	/// Mapper-placed relays with matching tags will be wired to this generator at round start.
	var/map_relay_tags = null
	/// Comma-separated object tags for grid_clients (e.g. junction boxes, fabricators) to auto-wire on Initialize.
	var/map_client_tags = null

	// ── Low-fuel fire-once flag
	var/low_fuel_warned = FALSE


// ============================================================
// LIFE CYCLE
// ============================================================

/obj/machinery/f13/faction_generator/Initialize()
	. = ..()
	fuel = FGEN_DEFAULT_FUEL
	resolve_map_links()
	// Set powered inline — avoid calling set_power_state() here because turret
	// toggle_on() -> popDown() sleeps, which is forbidden inside Initialize.
	powered = TRUE
	available_watts = FGEN_WATTS_PER_CORE * max(1, round(fuel / FUSION_CORE_FUEL))
	update_icon()
	stamp_zone(TRUE)
	// Propagate to auto-wired relays and clients asynchronously.
	// We can't call set_power_state() directly in Initialize (turret toggle_on sleeps),
	// so we defer this one tick.  The areas linked via powered_area_types are already
	// stamped above; this only affects nodes linked via map_relay_tags / map_client_tags.
	INVOKE_ASYNC(src, PROC_REF(_initial_propagate))
	START_PROCESSING(SSobj, src)

/// Deferred round-start propagation.  Fires one tick after Initialize() so that
/// all auto-wired relays and clients have also finished initialising before we
/// push power state down the chain.
/obj/machinery/f13/faction_generator/proc/_initial_propagate()
	if(QDELETED(src) || !powered)
		return
	if(linked_relays)
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(!QDELETED(R))
				R.set_relay_power(TRUE)
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.on_grid_power_change(TRUE)
	// Auto-detect any relays or clients connected via pre-placed map cables.
	_scan_cable_connections()

/// BFS-scan the cable network from this generator's turf and silently link any
/// unlinked relay or grid_client found at the end of a cable path.
/// Called once at round-start by _initial_propagate() so that maps with pre-laid
/// cables work without requiring the mapper to set map_relay_tags / map_client_tags.
/obj/machinery/f13/faction_generator/proc/_scan_cable_connections()
	var/turf/src_turf = get_turf(src)
	if(!src_turf)
		return

	// Relays first — they may spawn their own downstream scan when powered.
	for(var/obj/machinery/f13/power_relay/R in world)
		if(QDELETED(R) || R.upstream_ref)
			continue
		if(f13_cable_path_exists(src_turf, get_turf(R)))
			if(!linked_relays)
				linked_relays = list()
			if(!(R in linked_relays))
				linked_relays += R
				R.upstream_ref = WEAKREF(src)
				R.set_relay_power(powered)

	// Generic grid clients (junction boxes, fabricators, etc.).
	for(var/obj/machinery/f13/grid_client/C in world)
		if(QDELETED(C) || C.upstream_ref)
			continue
		if(f13_cable_path_exists(src_turf, get_turf(C)))
			if(!linked_clients)
				linked_clients = list()
			if(!(C in linked_clients))
				linked_clients += C
				C.upstream_ref = WEAKREF(src)
				C.on_grid_power_change(powered)

	recalc_draw()

/obj/machinery/f13/faction_generator/Destroy()
	STOP_PROCESSING(SSobj, src)
	set_power_state(FALSE)
	// Kill relay chain — relays cut themselves from the list inside Destroy().
	if(linked_relays)
		var/list/relay_copy = linked_relays.Copy()
		for(var/obj/machinery/f13/power_relay/R in relay_copy)
			if(!QDELETED(R))
				R.upstream_ref = null
				R.set_relay_power(FALSE)
	// Clear generic grid client back-refs.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.upstream_ref = null
		linked_clients = null
	return ..()


// ============================================================
// PROCESSING — fuel drain (SSobj fires every ~2 s)
// ============================================================

/obj/machinery/f13/faction_generator/process()
	if(fuel > 0)
		fuel--

		// Recompute available watts so it shrinks as cores burn down.
		var/cores_loaded = max(1, round(fuel / FUSION_CORE_FUEL))
		available_watts = FGEN_WATTS_PER_CORE * cores_loaded

		// Recompute draw, skipping any shed items.
		recalc_draw()

		// ── Under budget: try restoring previously shed loads.
		if(current_draw <= available_watts)
			_try_restore_shed()

		// ── Over budget: try soft load-shedding before hard-tripping.
		if(current_draw > available_watts)
			if(!_do_load_shed())
				// Shedding alone couldn't resolve it — hard grid trip.
				if(!overloaded)
					overloaded = TRUE
					broadcast_to_faction("<span class='warning'>OVERLOAD: [name] grid tripped ([current_draw]W vs [available_watts]W). All load-shedding options exhausted. Insert another fusion core.</span>")
					set_power_state(FALSE)
			return

		// ── Under budget and stable — clear any hard-trip state.
		if(overloaded)
			overloaded = FALSE
			set_power_state(TRUE)

		if(!low_fuel_warned && fuel <= FGEN_LOW_FUEL_WARN)
			low_fuel_warned = TRUE
			broadcast_to_faction("<span class='warning'>WARNING: [name] is running low on fuel. Approximately [fuel * 2] seconds of power remain. Insert a fusion core now.</span>")

		return

	// Fuel exhausted — only transition once.
	if(powered)
		set_power_state(FALSE)


// ============================================================
// POWER STATE
// ============================================================

/obj/machinery/f13/faction_generator/proc/set_power_state(new_powered)
	if(powered == new_powered)
		return

	powered = new_powered
	update_icon()

	// Stamp real SS13 power channels on owned areas.
	stamp_zone(powered)

	// Shut down or restore linked turrets.
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				T.toggle_on(powered)

	// Propagate to directly-wired relays.
	if(linked_relays)
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(!QDELETED(R))
				R.set_relay_power(powered)

	// Notify wired fabricators of the power change.
	// (Fabricators are now grid_client — they receive on_grid_power_change via linked_clients below.)

	// Notify generic grid clients.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.on_grid_power_change(powered)

	// Announce to faction members.
	if(powered)
		low_fuel_warned = FALSE
		broadcast_to_faction("<span class='notice'>POWER RESTORED: [faction_tag ? faction_tag : "Base"] generator is back online.</span>")
	else
		broadcast_to_faction("<span class='warning'>POWER FAILURE: [faction_tag ? faction_tag : "Base"] generator has gone offline. Insert a fusion core to restore power.</span>")

/// Stamp actual SS13 power-channel vars on every owned area and fire power_change().
/// Called directly by set_power_state() and by the master breaker when magic power is toggled.
/obj/machinery/f13/faction_generator/proc/stamp_zone(state)
	if(!powered_area_instances)
		return
	for(var/area/A in powered_area_instances)
		F13_STAMP_AREA_POWER(A, state)


// ============================================================
// WATTAGE ACCOUNTING
// ============================================================

/// Walk the entire downstream graph and sum up all watt draws.
/// Called each process() tick and after every wire/unwire event.
/// Shed items (in shed_clients / shed_relays) are excluded — they draw 0W while suspended.
/obj/machinery/f13/faction_generator/proc/recalc_draw()
	current_draw = 0
	// Direct turrets on this generator.
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				current_draw += TURRET_WATT_DRAW
	// Generic grid clients (includes fabricators) — skip any that are currently load-shed.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				if(shed_clients && (C in shed_clients))
					continue  // shed — counts as 0W
				current_draw += C.grid_watt_draw
	// Relay chains (recursive) — skip any that are currently load-shed.
	if(linked_relays)
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(!QDELETED(R))
				if(shed_relays && (R in shed_relays))
					continue  // shed — counts as 0W
				current_draw += R.get_subtree_draw()

/// Return total watts this generator is currently delivering vs. what it can supply.
/obj/machinery/f13/faction_generator/proc/get_load_summary()
	return "[current_draw]W / [available_watts]W"

// ── Load shedding — shed loads in priority order to prevent a full grid trip.
/// Called when current_draw > available_watts.
/// Returns TRUE if shedding resolved the overload, FALSE if a hard trip is still needed.
/obj/machinery/f13/faction_generator/proc/_do_load_shed()
	// PRIORITY 1: high-priority grid clients (e.g. fabricators, grid_shed_priority > 0).
	// Shed active crafting machines first (highest per-unit watt saving),
	// then idle high-priority units.
	if(current_draw > available_watts && linked_clients)
		for(var/pass in 1 to 2)
			for(var/obj/machinery/f13/grid_client/C in linked_clients)
				if(current_draw <= available_watts)
					break
				if(QDELETED(C))
					continue
				if(shed_clients && (C in shed_clients))
					continue  // already shed
				if(pass == 1 && C.grid_shed_priority == 0)
					continue  // skip low-priority on first pass
				if(pass == 2 && C.grid_shed_priority > 0)
					continue  // skip high-priority on second pass
				C.on_load_shed()
				if(!shed_clients)
					shed_clients = list()
				shed_clients += C
				current_draw -= C.grid_watt_draw

	// PRIORITY 2: relay subtrees — cut lowest-draw relays first to preserve
	// turret-heavy nodes as long as possible.
	if(current_draw > available_watts && linked_relays)
		var/list/relay_cands = list()
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(QDELETED(R) || !R.relay_powered)
				continue
			if(shed_relays && (R in shed_relays))
				continue
			relay_cands += R
		// Each pass: cut the relay with the smallest subtree draw first.
		while(relay_cands.len > 0 && current_draw > available_watts)
			var/obj/machinery/f13/power_relay/pick = null
			var/pick_draw = 999999
			for(var/obj/machinery/f13/power_relay/RC in relay_cands)
				var/d = RC.get_subtree_draw()
				if(d < pick_draw)
					pick_draw = d
					pick = RC
			if(!pick)
				break
			relay_cands -= pick
			pick.load_shed = TRUE
			pick.set_relay_power(FALSE)
			if(!shed_relays)
				shed_relays = list()
			shed_relays += pick
			current_draw -= pick_draw

	// Announce consolidated shed event.
	var/relay_n  = shed_relays  ? shed_relays.len  : 0
	var/client_n = shed_clients ? shed_clients.len : 0
	if(relay_n > 0 || client_n > 0)
		broadcast_to_faction("<span class='warning'>LOAD SHED: [name] suspended [client_n] device\s and [relay_n] relay\s to maintain grid stability. Turrets remain active.</span>")

	return (current_draw <= available_watts)

// ── Restore shed loads when the generator has headroom again.
/// Called each process() tick before the overload check (only when under budget).
/obj/machinery/f13/faction_generator/proc/_try_restore_shed()
	var/restored = 0

	// Restore relays first — area power and turrets have higher in-game impact.
	if(shed_relays && shed_relays.len)
		var/list/to_restore = list()
		for(var/obj/machinery/f13/power_relay/R in shed_relays)
			if(QDELETED(R))
				to_restore += R  // clean up dead refs
				continue
			var/would_draw = R.get_subtree_draw()
			if(current_draw + would_draw <= available_watts)
				current_draw += would_draw
				to_restore += R
		for(var/obj/machinery/f13/power_relay/R in to_restore)
			shed_relays -= R
			if(!QDELETED(R))
				R.load_shed = FALSE
				R.set_relay_power(TRUE)
				restored++

	// Restore grid clients (fabricators and junction boxes) by draw order —
	// smallest draw restored first so we fit as many devices back as possible.
	if(shed_clients && shed_clients.len)
		var/list/to_restore = list()
		for(var/obj/machinery/f13/grid_client/C in shed_clients)
			if(QDELETED(C))
				to_restore += C  // clean up dead refs
				continue
			if(current_draw + C.grid_watt_draw <= available_watts)
				current_draw += C.grid_watt_draw
				to_restore += C
		for(var/obj/machinery/f13/grid_client/C in to_restore)
			shed_clients -= C
			if(!QDELETED(C))
				C.on_load_shed_restore()
				restored++

	if(restored > 0)
		broadcast_to_faction("<span class='notice'>LOAD RESTORE: [name] returned [restored] device\s to service — grid load nominal.</span>")


// ============================================================
// MAP LINK RESOLUTION
// ============================================================

/obj/machinery/f13/faction_generator/proc/resolve_map_links()
	if(powered_area_types && powered_area_types.len)
		powered_area_instances = list()
		for(var/area_type in powered_area_types)
			var/area/A = locate(area_type) in world
			if(A && !QDELETED(A))
				powered_area_instances += A

	// Resolve turret tag strings → live turret refs (identical to terminal.dm).
	if(map_turret_tags && length(map_turret_tags))
		linked_turrets = list()
		var/list/tags = splittext(map_turret_tags, ",")
		for(var/raw_tag in tags)
			var/target_tag = trim(raw_tag)
			if(!length(target_tag))
				continue
			for(var/obj/machinery/porta_turret/T in world)
				if(T.tag == target_tag)
					if(!(T in linked_turrets))
						linked_turrets += T

	// Auto-wire relays by tag (mapper convenience — no multitool needed at round start).
	if(map_relay_tags && length(map_relay_tags))
		if(!linked_relays)
			linked_relays = list()
		for(var/raw_tag in splittext(map_relay_tags, ","))
			var/target_tag = trim(raw_tag)
			if(!length(target_tag))
				continue
			for(var/obj/machinery/f13/power_relay/R in world)
				if(R.tag == target_tag && !(R in linked_relays))
					linked_relays += R
					R.upstream_ref = WEAKREF(src)

	// Auto-wire fabricators by tag.
	// Fabricators are now grid_client — use map_client_tags to pre-wire them alongside junction boxes.
	if(map_client_tags && length(map_client_tags))
		if(!linked_clients)
			linked_clients = list()
		for(var/raw_tag in splittext(map_client_tags, ","))
			var/target_tag = trim(raw_tag)
			if(!length(target_tag))
				continue
			for(var/obj/machinery/f13/grid_client/C in world)
				if(C.tag == target_tag && !(C in linked_clients))
					linked_clients += C
					C.upstream_ref = WEAKREF(src)


// ============================================================
// LOCK ACCESS CHECK
// ============================================================

/obj/machinery/f13/faction_generator/proc/can_access(mob/living/user)
	switch(lock_mode)
		if(GENERATOR_LOCK_NONE)
			return TRUE
		if(GENERATOR_LOCK_PERSONAL)
			return (user.ckey == owner_ckey)
		if(GENERATOR_LOCK_FACTION)
			return (owner_faction in user.faction)
	return FALSE


// ============================================================
// FACTION BROADCAST HELPER
// ============================================================

/obj/machinery/f13/faction_generator/proc/broadcast_to_faction(msg)
	if(!faction_tag)
		return
	for(var/mob/M in world)
		if(M.social_faction == faction_tag)
			to_chat(M, msg)


// ============================================================
// ICON UPDATE
// ============================================================

/obj/machinery/f13/faction_generator/update_icon_state()
	icon_state = powered ? "portgen0_1" : "portgen0_0"

/obj/machinery/f13/faction_generator/examine(mob/user)
	. = ..()
	var/wired_count = (linked_clients ? linked_clients.len : 0) + (linked_relays ? linked_relays.len : 0)
	var/routing_in_progress = FALSE
	for(var/key in GLOB.f13_wire_sessions)
		var/datum/weakref/wref = GLOB.f13_wire_sessions[key]
		if(wref && wref.resolve() == src)
			routing_in_progress = TRUE
			break
	if(powered)
		if(wired_count > 0)
			. += span_notice("Cables branch from its distribution panel to [wired_count] connected device[wired_count != 1 ? "s" : ""]. The generator is running and supplying power.")
		else if(routing_in_progress)
			. += span_notice("A cable routing is underway — run the line to a fabricator or relay to complete the connection.")
		else
			. += span_notice("It's running, but no cables lead out from it — nothing is drawing from its output.")
	else
		if(wired_count > 0)
			. += span_warning("Cables run to [wired_count] device[wired_count != 1 ? "s" : ""], but the generator is offline. Nothing downstream is receiving power.")
		else if(routing_in_progress)
			. += span_warning("A cable routing is underway — finish connecting it to a fabricator or relay, then get the generator running.")
		else
			. += span_warning("No cables lead out from it, and it's offline. Insert a fusion core and wire up some devices to get power flowing.")


// ============================================================
// INTERACTION — ATTACKBY (core insertion + cable wiring + ID card)
// ============================================================

/obj/machinery/f13/faction_generator/attackby(obj/item/W, mob/user, params)
	// ── Wrench — anchor / unanchor (must be offline to remove).
	if(W.tool_behaviour == TOOL_WRENCH)
		if(powered)
			to_chat(user, span_warning("Power down the generator before unbolting it."))
			return
		anchored = !anchored
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		to_chat(user, span_notice(anchored ? "You secure [src] to the floor." : "You unbolt [src] from the floor."))
		return

	// ── Cable coil — wiring interface.
	if(istype(W, /obj/item/stack/cable_coil))
		if(!isliving(user))
			return
		var/mob/living/L = user
		var/obj/machinery/machine_src = f13_try_complete_wire(src, L)
		if(machine_src)
			// Generator is the destination — complete the link from whichever machine started the session.
			if(istype(machine_src, /obj/machinery/f13/power_relay))
				var/obj/machinery/f13/power_relay/R = machine_src
				link_relay(R, user)
			else if(istype(machine_src, /obj/machinery/f13/grid_client))
				var/obj/machinery/f13/grid_client/C = machine_src
				link_client(C, user)
			else
				to_chat(user, span_warning("[machine_src.name] cannot be wired to a generator."))
		else if(!GLOB.f13_wire_sessions["[REF(L)]"])
			// No active session for this player — this generator starts the routing.
			f13_start_wire_session(src, L)
		return

	// ── Wirecutters — sever all wired connections from this generator.
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		var/cut_count = 0
		if(linked_relays)
			for(var/obj/machinery/f13/power_relay/R in linked_relays.Copy())
				if(!QDELETED(R))
					R.upstream_ref = null
					R.update_icon()
					R.set_relay_power(FALSE)
					cut_count++
			linked_relays = null
		if(linked_clients)
			for(var/obj/machinery/f13/grid_client/C in linked_clients.Copy())
				if(!QDELETED(C))
					C.upstream_ref = null
					C.on_grid_power_change(FALSE)
					cut_count++
			linked_clients = null
		shed_relays = null
		shed_clients = null
		if(cut_count)
			recalc_draw()
			to_chat(user, span_notice("You cut all cable connections from [src]. [cut_count] device[cut_count != 1 ? "s" : ""] disconnected."))
		else
			to_chat(user, span_notice("No cable connections to cut on [src]."))
		return

	// ── ID card — register personal/faction lock owner.
	if(istype(W, /obj/item/card/id))
		handle_id_card(W, user)
		return

	// ── Fusion core insertion.
	if(istype(W, /obj/item/f13/fusion_core))
		var/obj/item/f13/fusion_core/core = W

		if(!can_access(user))
			to_chat(user, span_warning("Access denied."))
			return

		if(core.depleted)
			to_chat(user, span_warning("That core is depleted. Recycle it in a core fabricator first."))
			return

		if(fuel >= max_fuel)
			to_chat(user, span_warning("[src] already has full fuel reserves."))
			return

		user.transferItemToLoc(W, src)
		var/old_fuel = fuel
		fuel = min(fuel + FUSION_CORE_FUEL, max_fuel)
		qdel(core)

		// Eject a depleted shell — the physical casing is returned.
		new /obj/item/f13/fusion_core/depleted(loc)

		user.visible_message(
			"[user] slides a fusion core into [src].",
			span_notice("You insert a fusion core into [src]. ([fuel - old_fuel] fuel added; total: [fuel]/[max_fuel])")
		)

		// Recalculate available watts — more fuel = more capacity.
		available_watts = FGEN_WATTS_PER_CORE * max(1, round(fuel / FUSION_CORE_FUEL))
		recalc_draw()

		if(!powered)
			set_power_state(TRUE)
		else if(overloaded && current_draw <= available_watts)
			overloaded = FALSE
			broadcast_to_faction("<span class='notice'>OVERLOAD CLEARED: [name] — power restored at [current_draw]W / [available_watts]W.</span>")
			set_power_state(TRUE)

		return

	return ..()


/// Wire a generic grid client to this generator as its upstream power source.
/obj/machinery/f13/faction_generator/proc/link_client(obj/machinery/f13/grid_client/C, mob/user)
	if(!C || QDELETED(C))
		return
	if(!linked_clients)
		linked_clients = list()

	// Already linked — confirm to the player.
	if(C in linked_clients)
		to_chat(user, span_notice("[C.name] is already wired to [name]. Use wirecutters to disconnect."))
		return

	// Sever any existing upstream the client is already connected to.
	var/obj/old_up = C.upstream_ref ? C.upstream_ref.resolve() : null
	if(old_up && old_up != src)
		if(istype(old_up, /obj/machinery/f13/faction_generator))
			var/obj/machinery/f13/faction_generator/OG = old_up
			if(OG.linked_clients) OG.linked_clients -= C
		else if(istype(old_up, /obj/machinery/f13/power_relay))
			var/obj/machinery/f13/power_relay/OR = old_up
			if(OR.linked_clients) OR.linked_clients -= C

	linked_clients += C
	C.upstream_ref = WEAKREF(src)
	C.on_grid_power_change(powered)
	recalc_draw()
	to_chat(user, span_notice("Wired: [C.name] is now linked to [name]."))


/// Wire or unwire a power relay as a direct downstream child of this generator.
/obj/machinery/f13/faction_generator/proc/link_relay(obj/machinery/f13/power_relay/R, mob/user)
	if(!R || QDELETED(R))
		return
	if(!linked_relays)
		linked_relays = list()

	// Already linked — confirm to the player (use wirecutters to disconnect).
	if(R in linked_relays)
		to_chat(user, span_notice("[R.name] is already wired to [name]. Use wirecutters to disconnect."))
		return

	// Sever any existing upstream the relay is already connected to.
	R._sever_upstream()

	linked_relays += R
	R.upstream_ref = WEAKREF(src)
	R.update_icon()
	to_chat(user, span_notice("Wired: [R.name] linked to [name]. Power: [powered ? "ONLINE" : "OFFLINE"]."))
	R.set_relay_power(powered)


// ── Handle ID card swipe for personal / faction locking.
/obj/machinery/f13/faction_generator/proc/handle_id_card(obj/item/card/id/card, mob/user)
	if(!can_access(user) && !(pending_personal_reg || pending_faction_reg))
		to_chat(user, span_warning("Access denied."))
		return

	if(pending_personal_reg)
		pending_personal_reg = FALSE
		owner_ckey = user.ckey
		owner_name = user.real_name
		lock_mode = GENERATOR_LOCK_PERSONAL
		to_chat(user, span_notice("Personal lock registered to [user.real_name]."))
		show_ui(user)
		return

	if(pending_faction_reg)
		pending_faction_reg = FALSE
		var/reg_faction = get_faction_from_card(card)
		if(!reg_faction)
			to_chat(user, span_warning("This ID card has no recognised faction."))
			return
		owner_faction = reg_faction
		lock_mode = GENERATOR_LOCK_FACTION
		to_chat(user, span_notice("Faction lock set to '[reg_faction]'."))
		show_ui(user)
		return

	to_chat(user, span_notice("No pending lock registration. Open the generator panel first."))


// ── Read the faction of a job from an ID card by looking up the job datum.
/obj/machinery/f13/faction_generator/proc/get_faction_from_card(obj/item/card/id/card)
	if(!card || !card.assignment)
		return null
	var/datum/job/J = SSjob.GetJob(card.assignment)
	if(!J || !J.faction || J.faction == "None")
		return null
	return J.faction


// ============================================================
// INTERACTION — HAND CLICK → UI
// ============================================================

/obj/machinery/f13/faction_generator/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	show_ui(user)

/obj/machinery/f13/faction_generator/proc/show_ui(mob/living/user)
	var/accessible = can_access(user)
	var/fuel_pct   = max_fuel > 0 ? round((fuel / max_fuel) * 100) : 0
	var/cores_remaining = round(fuel / FUSION_CORE_FUEL, 0.1)
	var/runtime_secs = fuel * 2  // each fuel unit = 2 s
	var/runtime_min  = round(runtime_secs / 60)
	var/runtime_display = runtime_secs < 120 ? "[runtime_secs]s" : "[runtime_min] min"

	recalc_draw()
	var/load_pct   = available_watts > 0 ? round((current_draw / available_watts) * 100) : 0
	var/load_color = current_draw > available_watts ? "bad" : (current_draw > available_watts * 0.8 ? "warn" : "good")

	// Build a simple ASCII bar (20 chars wide)
	var/bar_fill  = available_watts > 0 ? round((current_draw / available_watts) * 20) : 0
	bar_fill = clamp(bar_fill, 0, 20)
	var/bar_str = "&#91;"
	var/f_bi
	for(f_bi = 1; f_bi <= 20; f_bi++)
		bar_str += f_bi <= bar_fill ? "#" : "."
	bar_str += "&#93;"

	var/dat = get_terminal_css()
	dat += get_terminal_header("Power Management Terminal")
	dat += "<pre class='dim'>  UNIT: [tag ? tag : "UNKNOWN"]  //  FACTION: [faction_tag ? faction_tag : "UNASSIGNED"]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Status block
	var/status_line = powered ? "<span class='good'>&#91;ONLINE&#93;</span>" : "<span class='bad'>&#91;OFFLINE&#93;</span>"
	if(overloaded)
		status_line += " <span class='bad'>&#91;!! CIRCUIT OVERLOAD !!&#93;</span>"
	var/shed_total = (shed_clients ? shed_clients.len : 0) + (shed_relays ? shed_relays.len : 0)
	if(shed_total > 0)
		status_line += " <span class='warn'>&#91;LOAD SHED: [shed_total] device[shed_total != 1 ? "s" : ""] suspended&#93;</span>"
	dat += "<pre>  STATUS   : [status_line]</pre>"
	dat += "<pre>  FUEL     : [fuel] / [max_fuel] <span class='dim'>([fuel_pct]%  ~[cores_remaining] cores  runtime ~[runtime_display])</span></pre>"
	dat += "<pre>  CAPACITY : [available_watts]W  <span class='dim'>([max(1,round(fuel/FUSION_CORE_FUEL))] core(s) x [FGEN_WATTS_PER_CORE]W)</span></pre>"
	dat += "<pre>  DRAW     : <span class='[load_color]'>[current_draw]W ([load_pct]%)</span></pre>"
	dat += "<pre>  LOAD BAR : <span class='[load_color]'>[bar_str]</span> [load_pct]%</pre>"
	dat += "<pre class='dim'>  COST REF.: relay=[RELAY_WATT_DRAW]W  fab=[FAB_WATT_DRAW_IDLE]W idle/[FAB_WATT_DRAW_ACTIVE]W active  turret=[TURRET_WATT_DRAW]W</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Powered areas
	if(powered_area_instances && powered_area_instances.len)
		dat += "<pre class='head'>  &#91;POWERED ZONES&#93;</pre>"
		for(var/area/A in powered_area_instances)
			if(!QDELETED(A))
				dat += "<pre>    &gt; [A.name]</pre>"
		dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Wired fabricators + other clients (unified — fabricators are grid_client)
	// Fabricators now appear in the WIRED DEVICES section below.

	// ── Relay tree
	dat += "<pre class='head'>  &#91;RELAY NETWORK&#93;</pre>"
	if(linked_relays && linked_relays.len)
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(!QDELETED(R))
				var/is_relay_shed = (shed_relays && (R in shed_relays))
				var/rstate
				if(is_relay_shed)
					rstate = "<span class='warn'>&#91;SHED&#93; </span>"
				else if(R.relay_powered)
					rstate = "<span class='good'>ONLINE </span>"
				else
					rstate = "<span class='bad'>OFFLINE</span>"
				dat += "<pre>    &gt; [R.name]  [rstate]  [R.get_subtree_draw()]W total</pre>"
				// Downstream relays indented one level
				if(R.downstream_relays && R.downstream_relays.len)
					for(var/obj/machinery/f13/power_relay/D in R.downstream_relays)
						if(!QDELETED(D))
							var/dstate = D.relay_powered ? "<span class='good'>ONLINE </span>" : "<span class='bad'>OFFLINE</span>"
							dat += "<pre class='dim'>         |-- [D.name]  [dstate]  [D.get_subtree_draw()]W</pre>"
	else
		dat += "<pre class='dim'>    &gt; none linked  (use a cable coil on generator, then on a relay)</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Generic grid clients
	dat += "<pre class='head'>  &#91;WIRED DEVICES&#93;</pre>"
	if(linked_clients && linked_clients.len)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				var/is_shed = (shed_clients && (C in shed_clients))
				var/cstate
				if(is_shed)
					cstate = "<span class='warn'>&#91;SHED&#93;   0W</span>"
				else if(C.grid_powered)
					cstate = "<span class='good'>ONLINE  [C.grid_watt_draw]W</span>"
				else
					cstate = "<span class='bad'>OFFLINE [C.grid_watt_draw]W</span>"
				dat += "<pre>    &gt; [C.name]  [cstate]</pre>"
	else
		dat += "<pre class='dim'>    &gt; none linked  (use a cable coil on generator, then on any compatible device)</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Lock settings
	var/lock_owner_display   = owner_name   ? owner_name   : "<span class='dim'>(not set)</span>"
	var/lock_faction_display = owner_faction ? owner_faction : "<span class='dim'>(not set)</span>"
	dat += "<pre class='head'>  &#91;ACCESS CONTROL&#93;</pre>"
	switch(lock_mode)
		if(GENERATOR_LOCK_NONE)
			dat += "<pre>  MODE: <span class='dim'>OPEN  (no restrictions)</span></pre>"
		if(GENERATOR_LOCK_PERSONAL)
			dat += "<pre>  MODE: PERSONAL  owner=[lock_owner_display]</pre>"
		if(GENERATOR_LOCK_FACTION)
			dat += "<pre>  MODE: FACTION   faction=[lock_faction_display]</pre>"

	if(accessible)
		dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=lock_none'>UNLOCK</a>  "
		dat += "<a href='byond://?src=[REF(src)];choice=lock_personal'>PERSONAL LOCK</a>  "
		dat += "<a href='byond://?src=[REF(src)];choice=lock_faction'>FACTION LOCK</a>  "
		dat += "<span class='dim'>(swipe ID card after selecting)</span></pre>"
	else
		dat += "<pre class='bad'>  ACCESS DENIED</pre>"

	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_generator", null, 620, 560)
	popup.set_content(dat)
	popup.open()


// ============================================================
// TOPIC — UI button handling
// ============================================================

/obj/machinery/f13/faction_generator/Topic(href, href_list)
	..()
	var/mob/living/U = usr
	if(!U || !istype(U) || !Adjacent(U))
		return

	switch(href_list["choice"])
		if("lock_none")
			lock_mode = GENERATOR_LOCK_NONE
			owner_ckey = null
			owner_name = null
			owner_faction = null
			pending_personal_reg = FALSE
			pending_faction_reg = FALSE
			to_chat(U, span_notice("Lock removed — generator is now open to all."))
		if("lock_personal")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			pending_personal_reg = TRUE
			pending_faction_reg = FALSE
			to_chat(U, span_notice("Ready to register personal owner. Swipe an ID card on the generator."))
		if("lock_faction")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			pending_faction_reg = TRUE
			pending_personal_reg = FALSE
			to_chat(U, span_notice("Ready to register faction lock. Swipe an ID card on the generator."))

	show_ui(U)

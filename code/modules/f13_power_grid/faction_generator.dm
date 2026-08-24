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
	icon = 'icons/fallout/machines/power_grid/faction_generator.dmi'
	icon_state = "generator_off"
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
	/// FALSE when this unit was field-assembled and has not had a grounding rod installed.
	/// Map-placed generators default TRUE; crafted ones start FALSE until a rod is applied.
	var/grounded = TRUE
	/// Remaining fuel in SSobj ticks.
	var/fuel = 0
	/// Maximum fuel capacity (two cores — hard ceiling on insertion).
	var/max_fuel = FUSION_CORE_FUEL * 2

	// ── Area linkage — set by the mapper, resolved to live instances at init
	/// List of area type paths to power. E.g. list(/area/f13/ncr, /area/f13/ncr/barracks)
	var/list/powered_area_types = null
	/// Resolved live area datum instances (populated in Initialize).
	var/list/powered_area_instances = null
	/// Cached list of /area/space border turfs that contain door buttons adjacent to owned areas.
	/// Built once by the first stamp_zone() call; reused on every subsequent toggle.
	var/list/button_sweep_cache = null

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
	/// When TRUE the lock/access-control system is available on this generator.
	/// Standard (faction-grade) generators have it built in.  Salvage/wasteland
	/// variants start with it FALSE; players can install a blank ID card reader
	/// to upgrade the unit in the field.
	var/has_lock_upgrade = TRUE

	// ── Wattage budget (Factorio-style power accounting)
	/// Watts available — grows by FGEN_WATTS_PER_CORE for each inserted core slot in use.
	/// Recalculated whenever a core is inserted or the load changes.
	var/available_watts = 0
	/// Current total draw reported by relays, fabricators, and turrets.
	var/current_draw = 0
	/// TRUE when the generator has tripped due to overload.
	var/overloaded = FALSE
	/// TRUE when an operator manually shut the generator down via the UI.
	/// While set the generator will not auto-restart even if fuel and capacity are available.
	/// Cleared automatically when fuel runs out so that inserting new fuel triggers a normal start.
	var/manually_shutdown = FALSE

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
	/// world.time when the generator last powered down; used for hot-refuel cooldown.
	var/shutdown_time = 0

	// ── Fuel abstraction — override these in generator subtypes.
	/// Item path this generator accepts as fuel. Checked in attackby().
	var/accepted_fuel_path  = /obj/item/f13/fusion_core
	/// Item path spawned after fuel eject/consume (null = spawn nothing).
	var/depleted_fuel_path  = /obj/item/f13/fusion_core/depleted
	/// Fuel ticks per inserted unit (replaces hard-coded FUSION_CORE_FUEL).
	var/fuel_per_unit       = FUSION_CORE_FUEL
	/// Watts produced per loaded fuel unit (replaces hard-coded FGEN_WATTS_PER_CORE).
	var/watts_per_fuel_unit = FGEN_WATTS_PER_CORE
	/// Display name for one fuel unit — used in examine messages and UI.
	var/fuel_unit_name      = "core"
	/// Set TRUE for generators fuelled by liquid reagents (e.g. diesel).
	/// When TRUE: available_watts is a flat value; fuel is tracked in reagent-volume units;
	/// initial(fuel) is used as the starting amount instead of FGEN_DEFAULT_FUEL.
	var/fuel_is_liquid      = FALSE
	/// Ticks elapsed since last maintenance service.
	/// Reset when a player uses a wrench on the generator while it is running.
	var/maintenance_ticks   = 0
	/// TRUE when the generator has exceeded FGEN_MAINTENANCE_INTERVAL and needs servicing.
	/// A wrench applied while running clears this and resets maintenance_ticks.
	var/needs_maintenance   = FALSE
	/// Ticks elapsed since needs_maintenance was set.  Drives escalating hazard probability
	/// and triggers auto-trip when it reaches FGEN_MAINTENANCE_INTERVAL.
	var/maintenance_severity = 0
	/// Accumulated heat from external hot items (welder, lighter).  Decays each process() tick.
	/// Subtypes override on_heat_exposure() to react when this crosses a threshold.
	var/heat_exposure = 0
	/// Heat total at which this subtype ignites/reacts.  0 means no heat hazard.
	/// Used by attackby() to generate escalating warning messages.
	var/heat_ignition_threshold = 0


// ============================================================
// LIFE CYCLE
// ============================================================

/obj/machinery/f13/faction_generator/Initialize()
	. = ..()
	// Liquid-fuel variants use their type-level var default; discrete-unit variants
	// start with FGEN_DEFAULT_FUEL (may exceed max_fuel intentionally for a longer first round).
	fuel = fuel_is_liquid ? initial(fuel) : FGEN_DEFAULT_FUEL
	resolve_map_links()
	// Set powered inline — avoid calling set_power_state() here because turret
	// toggle_on() -> popDown() sleeps, which is forbidden inside Initialize.
	powered = TRUE
	available_watts = fuel_is_liquid ? watts_per_fuel_unit : (watts_per_fuel_unit * max(1, round(fuel / fuel_per_unit)))
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

	// BFS from this generator's turf, stopping the frontier when a relay or client
	// tile is found.  Nodes behind another relay are left for that relay's own scan,
	// which preserves the breaker-box cascade topology regardless of BYOND's world
	// iteration order.
	var/list/visited = list(src_turf)
	var/list/frontier = list(src_turf)

	while(frontier.len)
		var/list/next_frontier = list()
		for(var/turf/T in frontier)
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				var/turf/N = get_step(T, dir)
				if(!N || (N in visited))
					continue
				visited += N
				var/blocked = FALSE
				for(var/obj/machinery/f13/power_relay/R in N)
					if(!QDELETED(R) && !R.upstream_refs)
						if(!linked_relays)
							linked_relays = list()
						if(!(R in linked_relays))
							linked_relays += R
							if(!R.upstream_refs) R.upstream_refs = list()
							R.upstream_refs += WEAKREF(src)
							R.on_upstream_changed()
					blocked = TRUE
					break
				if(blocked)
					continue
				for(var/obj/machinery/f13/grid_client/C in N)
					if(!QDELETED(C) && !C.upstream_refs)
						if(!linked_clients)
							linked_clients = list()
						if(!(C in linked_clients))
							linked_clients += C
							if(!C.upstream_refs) C.upstream_refs = list()
							C.upstream_refs += WEAKREF(src)
							C.on_upstream_changed()
					blocked = TRUE
					break
				if(blocked)
					continue
				if(locate(/obj/structure/cable) in N)
					next_frontier += N
		frontier = next_frontier

	recalc_draw()

/// Validate every existing logical connection against the current cable layout.
/// Any relay or client whose cable path is gone gets unpowered and unlinked.
/// Returns the number of connections removed.
/obj/machinery/f13/faction_generator/proc/_prune_dead_links()
	var/turf/src_turf = get_turf(src)
	if(!src_turf)
		return 0
	var/removed = 0
	if(linked_relays)
		var/list/to_remove = list()
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(QDELETED(R) || !f13_cable_path_exists(src_turf, get_turf(R)))
				to_remove += R
		for(var/obj/machinery/f13/power_relay/R in to_remove)
			f13_remove_upstream_ref(R.upstream_refs, src)
			R.on_upstream_changed()
			linked_relays -= R
			removed++
	if(linked_clients)
		var/list/to_remove = list()
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(QDELETED(C) || !f13_cable_path_exists(src_turf, get_turf(C)))
				to_remove += C
		for(var/obj/machinery/f13/grid_client/C in to_remove)
			f13_remove_upstream_ref(C.upstream_refs, src)
			C.on_upstream_changed()
			linked_clients -= C
			removed++
	if(removed)
		recalc_draw()
	return removed

/obj/machinery/f13/faction_generator/Destroy()
	STOP_PROCESSING(SSobj, src)
	set_power_state(FALSE)
	// Kill relay chain — remove self from each relay's upstream_refs, let OR logic decide.
	if(linked_relays)
		var/list/relay_copy = linked_relays.Copy()
		for(var/obj/machinery/f13/power_relay/R in relay_copy)
			if(!QDELETED(R))
				f13_remove_upstream_ref(R.upstream_refs, src)
				R.on_upstream_changed()
	// Clear generic grid client back-refs.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				f13_remove_upstream_ref(C.upstream_refs, src)
				C.on_upstream_changed()
		linked_clients = null
	return ..()


// ============================================================
// PROCESSING — fuel drain (SSobj fires every ~2 s)
// ============================================================

/obj/machinery/f13/faction_generator/process()
	// Cool down any accumulated external heat each tick.
	if(heat_exposure > 0)
		heat_exposure = max(0, heat_exposure - 1000)
	// Ungrounded frame leaks stray current — arc discharge near wet ground.
	if(powered && !grounded && prob(3))
		do_sparks(4, FALSE, src)
		for(var/mob/living/L in view(1, src))
			var/turf/LT = get_turf(L)
			if(istype(LT, /turf/open/water) || IS_WET_OPEN_TURF(LT))
				to_chat(L, span_danger("Stray current arcs through the ungrounded generator frame and into you!"))
				L.electrocute_act(20, src, flags = SHOCK_NOGLOVES)
	if(fuel > 0)
		fuel--

		// Recompute available watts.
		// Liquid-fuel generators run at a flat output; discrete units scale per slot.
		if(fuel_is_liquid)
			available_watts = watts_per_fuel_unit
		else
			var/units_loaded = max(1, round(fuel / fuel_per_unit))
			available_watts = watts_per_fuel_unit * units_loaded

		// Recompute draw, skipping any shed items.
		recalc_draw()

		// ── Maintenance tracking — advance counter each tick while running.
		maintenance_ticks++
		if(!needs_maintenance && maintenance_ticks >= FGEN_MAINTENANCE_INTERVAL)
			needs_maintenance = TRUE
			broadcast_to_faction("<span class='warning'>MAINTENANCE: [name] is overdue for service. Apply a wrench while it is running to clear the maintenance log.</span>")
		if(needs_maintenance)
			maintenance_severity++
			if(maintenance_severity == round(FGEN_MAINTENANCE_INTERVAL * 0.5))
				broadcast_to_faction("<span class='warning'>WARNING: [name] is critically overdue — faults are becoming very likely. Service it immediately.</span>")
			if(maintenance_severity >= FGEN_MAINTENANCE_INTERVAL)
				broadcast_to_faction("<span class='warning'>CRITICAL FAULT: [name] has shut itself down due to unaddressed maintenance. Wrench the unit, then restart.</span>")
				maintenance_severity = 0
				set_power_state(FALSE)
				return
			on_maintenance_hazard()

		// ── Under budget: try restoring previously shed loads.
		if(current_draw <= available_watts)
			_try_restore_shed()

		// ── Over budget: try soft load-shedding before hard-tripping.
		if(current_draw > available_watts)
			if(!_do_load_shed())
				// Shedding alone couldn't resolve it — hard grid trip.
				if(!overloaded)
					overloaded = TRUE
					var/fgen_refuel_hint = fuel_is_liquid ? "Refuel the generator." : "Insert another [fuel_unit_name]."
					broadcast_to_faction("<span class='warning'>OVERLOAD: [name] grid tripped ([current_draw]W vs [available_watts]W). All load-shedding options exhausted. [fgen_refuel_hint]</span>")
					set_power_state(FALSE)
			return

		// ── Under budget and stable — clear any hard-trip state.
		if(overloaded)
			overloaded = FALSE
			if(!manually_shutdown)
				set_power_state(TRUE)

		if(!low_fuel_warned && fuel <= FGEN_LOW_FUEL_WARN)
			low_fuel_warned = TRUE
			var/fgen_warn_hint = fuel_is_liquid ? "Refuel the generator now." : "Insert a [fuel_unit_name] now."
			broadcast_to_faction("<span class='warning'>WARNING: [name] is running low on fuel. Approximately [fuel * 2] seconds of power remain. [fgen_warn_hint]</span>")

		return

	// Fuel exhausted — only transition once.
	if(powered)
		set_power_state(FALSE)
	if(depleted_fuel_path)
		new depleted_fuel_path(drop_location())
	manually_shutdown = FALSE  // reset so inserting new fuel triggers normal auto-start


// ============================================================
// POWER STATE
// ============================================================

/obj/machinery/f13/faction_generator/proc/set_power_state(new_powered)
	if(powered == new_powered)
		return

	if(powered && !new_powered)
		_check_backfeed()
	powered = new_powered
	update_icon()

	// Stamp real SS13 power channels on owned areas.
	stamp_zone(powered)

	// Shut down or restore linked turrets.
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				T.toggle_on(powered)

	// Propagate to directly-wired relays — each recalculates via OR logic.
	if(linked_relays)
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(!QDELETED(R))
				R.on_upstream_changed()

	// Notify wired fabricators of the power change.
	// (Fabricators are now grid_client — they receive on_upstream_changed via linked_clients below.)

	// Notify generic grid clients.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.on_upstream_changed()

	// Announce to faction members.
	if(powered)
		low_fuel_warned = FALSE
		broadcast_to_faction("<span class='notice'>POWER RESTORED: [faction_tag ? faction_tag : "Base"] generator is back online.</span>")
	else
		broadcast_to_faction("<span class='warning'>POWER FAILURE: [faction_tag ? faction_tag : "Base"] generator has gone offline. Insert a fusion core to restore power.</span>")

/// Fires when this generator goes offline and any shared relay still has a live parallel generator upstream.
/obj/machinery/f13/faction_generator/proc/_check_backfeed()
	if(!linked_relays)
		return
	for(var/obj/machinery/f13/power_relay/R in linked_relays)
		if(QDELETED(R) || !R.upstream_refs)
			continue
		for(var/datum/weakref/W in R.upstream_refs)
			var/obj/up = W.resolve()
			if(!up || QDELETED(up) || up == src)
				continue
			if(istype(up, /obj/machinery/f13/faction_generator) && up:powered)
				do_sparks(8, FALSE, R)
				var/turf/T = get_turf(R)
				for(var/mob/living/L in view(1, T))
					L.electrocute_act(25, R, flags = SHOCK_NOGLOVES)
				for(var/mob/living/L in view(3, T))
					to_chat(L, span_danger("BACKFEED: [R.name] — parallel generator isolation failure. Surge at the relay."))
				break

/// Stamp actual SS13 power-channel vars on every owned area and fire power_change().
/// Called directly by set_power_state() and by the master breaker when magic power is toggled.
/// TRUE if any junction box with an open master breaker owns this area.
/obj/machinery/f13/faction_generator/proc/_area_in_tripped_jbox(area/A)
	for(var/obj/machinery/f13/junction_box/JB in world)
		if(JB.breaker_closed)
			continue
		if(JB.owned_zones && (A in JB.owned_zones))
			return TRUE
		if(JB.powered_area_instances && (A in JB.powered_area_instances))
			return TRUE
	return FALSE

/obj/machinery/f13/faction_generator/proc/stamp_zone(state)
	if(!powered_area_instances)
		return
	for(var/area/A in powered_area_instances)
		// Don't re-energise areas held dark by a tripped (non-auto-reset) breaker.
		if(state && _area_in_tripped_jbox(A))
			continue
		F13_STAMP_AREA_POWER(A, state)
	// Notify machinery (e.g. door buttons) on /area/space tiles adjacent to owned areas.
	// The border-turf list is built once on the first call and cached; subsequent toggles
	// skip the area-scan entirely and iterate only the small cached turf list.
	if(button_sweep_cache == null)
		button_sweep_cache = list()
		var/list/swept = list()
		for(var/area/A in powered_area_instances)
			if(A.outdoors)
				continue  // no enclosed walls in outdoor zones
			for(var/turf/T in A)
				for(var/turf/W in RANGE_TURFS(2, T))
					if(!swept[W] && istype(get_area(W), /area/space))
						swept[W] = TRUE
						button_sweep_cache += W
	for(var/turf/W in button_sweep_cache)
		for(var/obj/machinery/M in W)
			M.power_change()


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
					if(!R.upstream_refs) R.upstream_refs = list()
					R.upstream_refs += WEAKREF(src)

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
					if(!C.upstream_refs) C.upstream_refs = list()
					C.upstream_refs += WEAKREF(src)
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

/// Called each process tick when the generator's maintenance interval has elapsed.
/// Override in fuel-type variants to apply the appropriate hazard effect.
/// Base type: pre-War engineering quality — no passive hazard on stock units.
/obj/machinery/f13/faction_generator/proc/on_maintenance_hazard()
	return


// ============================================================
// ICON UPDATE
// ============================================================

/obj/machinery/f13/faction_generator/update_icon_state()
	icon_state = powered ? "generator_on" : "generator_off"

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
	if(needs_maintenance)
		if(maintenance_severity >= round(FGEN_MAINTENANCE_INTERVAL * 0.67))
			. += span_warning("Something is clearly wrong — heat radiating from the housing and an acrid smell. It needs servicing immediately.")
		else if(maintenance_severity >= round(FGEN_MAINTENANCE_INTERVAL * 0.33))
			. += span_warning("The unit is running rough and throwing off unusual heat. It needs servicing soon.")
		else
			. += span_notice("One of the panel covers is vibrating loose. A quick service with a wrench would clear the maintenance log.")


// ============================================================
// INTERACTION — ATTACKBY (core insertion + cable wiring + ID card)
// ============================================================

/obj/machinery/f13/faction_generator/proc/on_heat_exposure()
	return  // Base: no reaction. Subtypes override.

/obj/machinery/f13/faction_generator/attackby(obj/item/W, mob/user, params)
	// ── Grounding rod — bonds the frame to earth, clearing leakage risk.
	if(istype(W, /obj/item/f13/grounding_rod))
		if(grounded)
			to_chat(user, span_notice("[src] is already grounded."))
			return
		if(!anchored)
			to_chat(user, span_warning("Anchor the generator first — the grounding rod needs a fixed frame to bond to."))
			return
		grounded = TRUE
		qdel(W)
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		do_sparks(3, FALSE, src)
		to_chat(user, span_notice("You drive the grounding rod into the floor and bond it to [src]'s frame. The leakage risk clears."))
		return
	// ── Heat hazard — a lit welder or open flame held against the generator builds heat.
	var/item_heat = W.get_temperature()
	if(item_heat > 0 && isliving(user))
		heat_exposure += item_heat
		if(heat_ignition_threshold > 0)
			var/pct = heat_exposure / heat_ignition_threshold
			if(pct < 0.3)
				to_chat(user, span_warning("You hold [W] against [src] — the casing begins to warm."))
			else if(pct < 0.6)
				to_chat(user, span_warning("You press [W] against [src] — the casing grows hot to the touch."))
			else if(pct < 0.9)
				to_chat(user, span_danger("You press [W] against [src] — the casing radiates scorching heat. Something inside groans."))
			else
				to_chat(user, span_danger("You press [W] against [src] — the metal is scalding hot. [src] groans under the strain. Get back!"))
		else
			to_chat(user, span_warning("You hold [W] against [src] — the casing grows warm."))
		on_heat_exposure()

	// ── Water hazard — shock anyone touching a live generator while standing in water.
	if(powered && isliving(user))
		var/turf/T = get_turf(user)
		if(istype(T, /turf/open/water) || IS_WET_OPEN_TURF(T))
			to_chat(user, span_danger("You touch the generator while standing in water — electricity surges through you!"))
			var/mob/living/L = user
			L.electrocute_act(50, src, flags = SHOCK_NOGLOVES)
			return

	// ── Wrench — service running generator; repair broken offline unit; or anchor.
	if(W.tool_behaviour == TOOL_WRENCH)
		if(powered)
			if(needs_maintenance)
				needs_maintenance = FALSE
				maintenance_ticks = 0
				maintenance_severity = 0
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, span_notice("You tighten the fittings and check the seals on [src]. Maintenance log cleared."))
			else if(maintenance_ticks >= FGEN_MAINTENANCE_INTERVAL - 40)
				maintenance_ticks = 0
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, span_notice("You go over the fittings on [src] before they need it — everything feels tight. Maintenance interval reset."))
			else
				var/ticks_left = FGEN_MAINTENANCE_INTERVAL - maintenance_ticks
				var/mins = round(ticks_left / 30)
				to_chat(user, span_notice("The seals and fittings feel solid — no service needed for another [mins] minute[mins != 1 ? "s" : ""] or so. Power it down first if you want to move it."))
			return
		// Offline — repair if damaged/broken, otherwise anchor toggle.
		if((stat & BROKEN) || obj_integrity < max_integrity)
			if(!W.use_tool(src, user, 30, volume=50))
				return
			stat &= ~BROKEN
			needs_maintenance = FALSE
			maintenance_ticks = 0
			maintenance_severity = 0
			obj_integrity = max_integrity
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			to_chat(user, span_notice("You patch up [src]. The unit looks functional again — insert fuel to restart."))
			update_icon()
			return
		anchored = !anchored
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		to_chat(user, span_notice(anchored ? "You secure [src] to the floor." : "You unbolt [src] from the floor."))
		return

	// ── Screwdriver — eject remaining fuel units.
	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(!can_access(user))
			to_chat(user, span_warning("Access denied."))
			return
		if(fuel <= 0)
			to_chat(user, span_notice("The fuel reservoir is already empty — nothing to eject."))
			return
		var/ejected = fuel
		fuel = 0
		low_fuel_warned = FALSE
		if(powered)
			set_power_state(FALSE)
		on_fuel_ejected(user, ejected)
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
		if(powered && isliving(user))
			var/mob/living/L = user
			to_chat(user, span_danger("You cut into a live cable — electricity surges through you!"))
			L.electrocute_act(40, src, flags = SHOCK_NOGLOVES)
		var/cut_count = 0
		if(linked_relays)
			for(var/obj/machinery/f13/power_relay/R in linked_relays.Copy())
				if(!QDELETED(R))
					f13_remove_upstream_ref(R.upstream_refs, src)
					R.update_icon()
					R.on_upstream_changed()
					cut_count++
			linked_relays = null
		if(linked_clients)
			for(var/obj/machinery/f13/grid_client/C in linked_clients.Copy())
				if(!QDELETED(C))
					f13_remove_upstream_ref(C.upstream_refs, src)
					C.on_upstream_changed()
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

	// ── Fuel insertion — accepts whichever item type this generator variant uses.
	if(accepted_fuel_path && istype(W, accepted_fuel_path))
		if(!can_access(user))
			to_chat(user, span_warning("Access denied."))
			return

		// Arc flash — inserting into a live (powered) generator contacts live internals.
		if(powered && isliving(user))
			to_chat(user, span_danger("You crack open the fuel bay while the generator is live — the contacts arc violently across your hand!"))
			var/mob/living/L = user
			L.electrocute_act(35, src, flags = SHOCK_NOGLOVES)

		// Fusion cores have a depleted flag; other fuel types skip this check.
		if(istype(W, /obj/item/f13/fusion_core))
			var/obj/item/f13/fusion_core/core = W
			if(core.depleted)
				to_chat(user, span_warning("That core is depleted. Recycle it in a core fabricator first."))
				return

		if(fuel >= max_fuel)
			to_chat(user, span_warning("[src] already has full fuel reserves."))
			return

		user.transferItemToLoc(W, src)
		var/old_fuel = fuel
		fuel = min(fuel + fuel_per_unit, max_fuel)
		qdel(W)

		// Eject a depleted shell / empty container if applicable.
		if(depleted_fuel_path)
			new depleted_fuel_path(loc)

		user.visible_message(
			"[user] loads a [fuel_unit_name] into [src].",
			span_notice("You insert a [fuel_unit_name] into [src]. ([fuel - old_fuel] fuel added; total: [fuel]/[max_fuel])")
		)

		// Recalculate available watts — more fuel = more capacity.
		available_watts = watts_per_fuel_unit * max(1, round(fuel / fuel_per_unit))
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

	linked_clients += C
	if(!C.upstream_refs) C.upstream_refs = list()
	if(!C._has_upstream(src)) C.upstream_refs += WEAKREF(src)
	if(powered && isliving(user))
		to_chat(user, span_danger("You connect a cable to a live generator — electricity arcs across your hand!"))
		var/mob/living/UL = user
		UL.electrocute_act(25, src, flags = SHOCK_NOGLOVES)
	C.on_upstream_changed()
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

	linked_relays += R
	if(!R.upstream_refs) R.upstream_refs = list()
	if(!R._has_upstream(src)) R.upstream_refs += WEAKREF(src)
	R.update_icon()
	if(powered && isliving(user))
		to_chat(user, span_danger("You connect a cable to a live generator — electricity arcs across your hand!"))
		var/mob/living/UL = user
		UL.electrocute_act(25, src, flags = SHOCK_NOGLOVES)
	to_chat(user, span_notice("Wired: [R.name] linked to [name]. Power: [powered ? "ONLINE" : "OFFLINE"]."))
	R.on_upstream_changed()


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
	if(powered)
		var/turf/T = get_turf(user)
		if(istype(T, /turf/open/water) || IS_WET_OPEN_TURF(T))
			to_chat(user, span_danger("You reach for the controls — electricity arcs through the water and into you!"))
			user.electrocute_act(50, src, flags = SHOCK_NOGLOVES)
			return
	show_ui(user)

/obj/machinery/f13/faction_generator/proc/show_ui(mob/living/user)
	var/accessible = can_access(user)
	var/fuel_pct   = max_fuel > 0 ? round((fuel / max_fuel) * 100) : 0
	var/units_remaining = round(fuel / fuel_per_unit, 0.1)
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
	if(!grounded)
		dat += "<pre>  <span style='color:#ff8c00'>  &#9888; UNGROUNDED  &mdash;  install a grounding rod to prevent leakage current hazards</span></pre>"
	if(fuel_is_liquid)
		dat += "<pre>  FUEL     : [fuel] L / [max_fuel] L <span class='dim'>([fuel_pct]%  runtime ~[runtime_display])</span></pre>"
		if(accessible)
			dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=eject_fuel'>DRAIN TANK</a>  <span class='dim'>(vent remaining fuel; generator powers down)</span></pre>"
		dat += "<pre>  CAPACITY : [available_watts]W  <span class='dim'>(liquid fuel — flat [available_watts]W output)</span></pre>"
	else
		dat += "<pre>  FUEL     : [fuel] / [max_fuel] <span class='dim'>([fuel_pct]%  ~[units_remaining] [fuel_unit_name](s)  runtime ~[runtime_display])</span></pre>"
		if(accessible)
			dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=eject_fuel'>EJECT FUEL</a>  <span class='dim'>(purge remaining fuel; generator powers down)</span></pre>"
		dat += "<pre>  CAPACITY : [available_watts]W  <span class='dim'>([max(1,round(fuel/fuel_per_unit))] [fuel_unit_name](s) x [watts_per_fuel_unit]W)</span></pre>"
	dat += "<pre>  DRAW     : <span class='[load_color]'>[current_draw]W ([load_pct]%)</span></pre>"
	dat += "<pre>  LOAD BAR : <span class='[load_color]'>[bar_str]</span> [load_pct]%</pre>"
	dat += "<pre class='dim'>  COST REF.: relay=[RELAY_WATT_DRAW]W  fab=[FAB_WATT_DRAW_IDLE]W idle/[FAB_WATT_DRAW_ACTIVE]W active  turret=[TURRET_WATT_DRAW]W</pre>"
	var/integrity_color = obj_integrity < max_integrity * 0.33 ? "bad" : (obj_integrity < max_integrity * 0.67 ? "warn" : "good")
	dat += "<pre>  INTEGRITY: <span class='[integrity_color]'>[obj_integrity] / [max_integrity]</span>  <span class='dim'>(wrench while offline to repair)</span></pre>"
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
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;ACCESS CONTROL&#93;</pre>"
	if(has_lock_upgrade)
		var/lock_owner_display   = owner_name   ? owner_name   : "<span class='dim'>(not set)</span>"
		var/lock_faction_display = owner_faction ? owner_faction : "<span class='dim'>(not set)</span>"
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
	else
		dat += "<pre class='dim'>  No ID card reader installed. Apply a blank ID card to the generator to add one.</pre>"

	// ── Network rescan
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;POWER CONTROL&#93;</pre>"
	if(accessible)
		if(powered)
			dat += "<pre>  <a href='byond://?src=[REF(src)];choice=shutdown'>&#91; EMERGENCY SHUTDOWN &#93;</a>  <span class='dim'>(cuts output; fuel consumption continues)</span></pre>"
		else if(fuel > 0 && !overloaded)
			dat += "<pre>  <a href='byond://?src=[REF(src)];choice=startup'>&#91; START GENERATOR &#93;</a>  <span class='dim'>(bring output back online)</span></pre>"
		else if(fuel <= 0)
			dat += "<pre class='dim'>  Generator offline — no fuel.  Insert a [fuel_unit_name] to start.</pre>"
		else
			dat += "<pre class='dim'>  Generator offline — overloaded.  Reduce load then rescan.</pre>"
	else
		dat += "<pre class='bad'>  ACCESS DENIED</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;NETWORK&#93;</pre>"
	dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=rescan'>Rescan cable network</a>  <span class='dim'>(detects newly-laid cables without rebuilding)</span></pre>"

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
			if(!has_lock_upgrade) return
			lock_mode = GENERATOR_LOCK_NONE
			owner_ckey = null
			owner_name = null
			owner_faction = null
			pending_personal_reg = FALSE
			pending_faction_reg = FALSE
			to_chat(U, span_notice("Lock removed — generator is now open to all."))
		if("lock_personal")
			if(!has_lock_upgrade) return
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			pending_personal_reg = TRUE
			pending_faction_reg = FALSE
			to_chat(U, span_notice("Ready to register personal owner. Swipe an ID card on the generator."))
		if("lock_faction")
			if(!has_lock_upgrade) return
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			pending_faction_reg = TRUE
			pending_personal_reg = FALSE
			to_chat(U, span_notice("Ready to register faction lock. Swipe an ID card on the generator."))
		if("eject_fuel")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			if(fuel <= 0)
				to_chat(U, span_notice("The fuel reservoir is already empty — nothing to eject."))
			else
				var/ejected = fuel
				fuel = 0
				low_fuel_warned = FALSE
				if(powered)
					set_power_state(FALSE)
				on_fuel_ejected(U, ejected)
		if("rescan")
			var/pruned = _prune_dead_links()
			var/before_relays  = linked_relays  ? linked_relays.len  : 0
			var/before_clients = linked_clients ? linked_clients.len : 0
			_scan_cable_connections()
			var/after_relays  = linked_relays  ? linked_relays.len  : 0
			var/after_clients = linked_clients ? linked_clients.len : 0
			var/found = (after_relays - before_relays) + (after_clients - before_clients)
			if(found > 0 && pruned > 0)
				to_chat(U, span_notice("Network rescan complete — [found] new device[found != 1 ? "s" : ""] linked, [pruned] stale link[pruned != 1 ? "s" : ""] cleared."))
			else if(found > 0)
				to_chat(U, span_notice("Network rescan complete — [found] new device[found != 1 ? "s" : ""] linked."))
			else if(pruned > 0)
				to_chat(U, span_notice("Network rescan complete — [pruned] stale link[pruned != 1 ? "s" : ""] cleared."))
			else
				to_chat(U, span_notice("Network rescan complete — no changes."))

		if("shutdown")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			if(!powered)
				to_chat(U, span_notice("Generator is already offline."))
			else
				manually_shutdown = TRUE
				set_power_state(FALSE)
				to_chat(U, span_notice("Generator output cut. Fuel consumption continues. Use 'START GENERATOR' to bring it back online."))
		if("startup")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			if(powered)
				to_chat(U, span_notice("Generator is already online."))
			else if(fuel <= 0)
				to_chat(U, span_notice("No fuel — insert a [fuel_unit_name] first."))
			else if(overloaded)
				to_chat(U, span_notice("Overload condition active — reduce network load before restarting."))
			else
				manually_shutdown = FALSE
				set_power_state(TRUE)
				to_chat(U, span_notice("Generator output restored."))

	show_ui(U)


// ============================================================
// GENERATOR VARIANTS
// ============================================================
//
//  VARIANT              FUEL TYPE                        W        max_fuel  runtime full
//  ─────────────────    ──────────────────────────────   ────     ────────  ────────────
//  (base)               fusion core (discrete)           1000W/core × 2     ~30 min cap
//  /fusion              fusion core (discrete, named)    1000W/core × 2     ~30 min cap
//  /diesel              diesel reagent (liquid, jerrycan) 750W flat 1440 L  ~48 min
//  /atomic              atomic cell (discrete)           1500W × 1 cell     ~22 min
//  /wastelander         diesel reagent (liquid, jerrycan) 500W flat 1000 L  ~33 min
//                       — proximity power spread (no wired grid needed)
//
// Liquid-fuel variants: set fuel_is_liquid = TRUE, accepted_fuel_path = null,
//   depleted_fuel_path = null, fuel_per_unit = 1 (1 tick per L).  Override attackby()
//   to call try_liquid_refuel().  The type-level fuel var default is the round-start amount.
//
// Discrete-unit variants: set accepted_fuel_path, fuel_per_unit, watts_per_fuel_unit.
//   fuel starts at FGEN_DEFAULT_FUEL (may exceed max_fuel for longer initial runtime).
// ============================================================

/// Called after fuel has been zeroed out by a drain/eject action.  Override in subtypes
/// for type-specific behaviour (e.g. collecting liquid fuel in a held container).
/obj/machinery/f13/faction_generator/proc/on_fuel_ejected(mob/user, ejected_vol)
	var/units_out = max(0, round(ejected_vol / fuel_per_unit))
	if(accepted_fuel_path && units_out > 0)
		for(var/i in 1 to units_out)
			new accepted_fuel_path(drop_location())
		to_chat(user, span_notice("Fuel purged: [units_out] [fuel_unit_name][units_out != 1 ? "s" : ""] ejected."))
	else
		to_chat(user, span_notice("Fuel reservoir vented."))

/// Liquid diesel drain — checks the other hand for a container to catch fuel;
/// anything that doesn't fit (or if no container is present) spills on the floor.
/obj/machinery/f13/faction_generator/diesel/on_fuel_ejected(mob/user, ejected_vol)
	var/captured = 0
	var/obj/item/reagent_containers/can = null
	if(isliving(user))
		var/mob/living/L = user
		var/obj/item/other = L.get_inactive_held_item()
		if(istype(other, /obj/item/reagent_containers))
			can = other
	if(can && can.reagents)
		var/space = can.reagents.maximum_volume - can.reagents.total_volume
		captured = min(round(ejected_vol), space)
		if(captured > 0)
			can.reagents.add_reagent(/datum/reagent/fuel, captured)
	var/overflow = ejected_vol - captured
	if(overflow > 0)
		var/turf/T = get_turf(src)
		if(T && !locate(/obj/effect/decal/cleanable/oil) in T)
			new /obj/effect/decal/cleanable/oil/slippery(T)
		if(can)
			user.visible_message(
				span_warning("[user] drains [src] — [round(overflow)] L of diesel spills across the floor!"),
				span_warning("You drain [src]. [round(captured)] L goes into [can.name]; [round(overflow)] L hits the floor — keep ignition sources away.")
			)
		else
			user.visible_message(
				span_warning("[user] drains [src] — diesel pours across the floor!"),
				span_warning("You drain [src] without a container — [round(overflow)] L of diesel soaks the floor. Keep ignition sources away.")
			)
	else
		to_chat(user, span_notice("You drain [src]'s tank into [can.name]. ([round(captured)] L)"))

/// Attempt to refuel this generator from a liquid-fuel reagent container (e.g. jerrycan).
/// Returns TRUE if the interaction was consumed (success or informative failure).
/obj/machinery/f13/faction_generator/proc/try_liquid_refuel(obj/item/W, mob/user)
	if(!istype(W, /obj/item/reagent_containers))
		return FALSE
	var/obj/item/reagent_containers/container = W
	if(!container.reagents || !container.reagents.has_reagent(/datum/reagent/fuel))
		to_chat(user, span_warning("That won't work — [name] runs on petroleum diesel. Substituting anything else risks injector damage or a flash fire."))
		return TRUE
	// Fuel flash — pouring into a running engine vaporises fuel against hot internals.
	if(powered && isliving(user))
		var/mob/living/L = user
		to_chat(user, span_danger("You pour fuel into [src] while it's running — a vapour flash scorches your hands!"))
		L.adjustFireLoss(10)
		L.IgniteMob()
	// Hot-refuel guard: engine needs ~30 seconds to cool after shutdown before refuelling.
	if(!powered && shutdown_time > 0 && (world.time - shutdown_time) < 300)
		var/secs_left = round((300 - (world.time - shutdown_time)) / 10)
		to_chat(user, span_warning("The engine block is still too hot to refuel safely. Wait about [secs_left] more second[secs_left != 1 ? "s" : ""]."))
		return TRUE
	if(!can_access(user))
		to_chat(user, span_warning("Access denied."))
		return TRUE
	if(fuel >= max_fuel)
		to_chat(user, span_warning("The fuel tank is already full."))
		return TRUE
	var/available_vol = container.reagents.get_reagent_amount(/datum/reagent/fuel)
	var/space = max_fuel - fuel
	var/transfer = min(available_vol, space)
	if(transfer < 1)
		to_chat(user, span_warning("The fuel tank is already full."))
		return TRUE
	container.reagents.remove_reagent(/datum/reagent/fuel, transfer)
	var/old_fuel = fuel
	fuel = min(fuel + round(transfer * DIESEL_TICKS_PER_VOLUME), max_fuel)
	available_watts = watts_per_fuel_unit
	recalc_draw()
	user.visible_message(
		"[user] pours diesel fuel into [src].",
		span_notice("You pour [round(transfer)] L of diesel into [src]. Tank: [fuel]/[max_fuel] L (+[fuel - old_fuel] L).")
	)
	if(!powered && fuel > 0)
		set_power_state(TRUE)
	else if(overloaded && current_draw <= available_watts)
		overloaded = FALSE
		broadcast_to_faction("<span class='notice'>OVERLOAD CLEARED: [name] — power restored at [current_draw]W / [available_watts]W.</span>")
		set_power_state(TRUE)
	return TRUE

/// Explicit "fusion core" named variant of the base generator.
/// Mapper-placed generators that want to make clear they use fusion cores.
/obj/machinery/f13/faction_generator/fusion
	icon       = 'icons/fallout/machines/power_grid/faction_generator.dmi'
	icon_state = "generator_off"
	name = "fusion core generator"
	desc = "A pre-War Vault-Tec integrated power plant. High-yield magnetic containment feeds up to two RobCo fusion cores simultaneously. Expensive to operate, but nothing in the wasteland matches its output-to-weight ratio."

/obj/machinery/f13/faction_generator/fusion/update_icon_state()
	icon_state = powered ? "generator_cycle" : "generator_off"


/// Common post-War diesel generator.  Fuelled by pouring liquid diesel from a jerrycan.
/// Burns at a flat 750 W as long as there is fuel in the tank.
/obj/machinery/f13/faction_generator/diesel
	icon = 'icons/fallout/machines/power.dmi'
	icon_state = "diesel-off"
	name = "diesel generator"
	desc = "A battered pre-War industrial diesel unit — the kind that kept factories running before the war, and keeps settlements alive after it. Loud, thirsty, and mercifully common out here. Feed it diesel straight from a jerrycan to keep it running."
	accepted_fuel_path   = null   // liquid-fuel pathway — uses try_liquid_refuel() instead
	depleted_fuel_path   = null   // liquid fuel has no physical casing to eject
	fuel_is_liquid       = TRUE
	fuel_per_unit        = 1      // 1 tick per litre (for residual unit calculations)
	watts_per_fuel_unit  = 750    // flat output — diesel can't match fusion
	max_fuel             = 1440   // ~48 min fully loaded (~2.9 jerrycans)
	fuel                 = 500    // round-start: ~1 jerrycan worth (~17 min)
	fuel_unit_name       = "L"
	heat_ignition_threshold = 7600  // ~2-3 welder applications to ignite the fuel tank
	/// Accumulated exhaust exposure for each mob near the generator.
	/// Keyed by mob reference; value is ticks of continuous indoor exposure.
	var/list/co_exposure_map = null

/obj/machinery/f13/faction_generator/diesel/update_icon_state()
	icon_state = powered ? "diesel-on" : "diesel-off"

/obj/machinery/f13/faction_generator/diesel/attackby(obj/item/W, mob/user, params)
	if(try_liquid_refuel(W, user))
		return
	return ..()

/obj/machinery/f13/faction_generator/diesel/set_power_state(new_powered)
	if(!new_powered)
		shutdown_time = world.time
		// Clear CO tracking when the generator goes offline.
		co_exposure_map = null
	return ..()

// ============================================================
// EXHAUST / CO HAZARD
// ============================================================
// A running diesel generator in an enclosed space is a silent killer.
// Real-world CO concentrations from a generator exhaust become dangerous
// within minutes indoors — here modelled as per-tick tox+oxy damage that
// escalates with sustained exposure.
//
// "Outdoors" is any turf under /turf/open/indestructible/ground/outside.
// Wearing internals (any active breathing tank) blocks the effect entirely.
//
// CO exposure ticks per mob:
//   1-3   ticks: "The air smells faintly of exhaust."
//   4-7   ticks: Mild damage — headache warning.
//   8-14  ticks: Moderate — dizziness, nausea.
//   15+   ticks: Heavy — staggering.
//   Each tick: adjustOxyLoss(1) + adjustToxLoss(1).  At 15+ ticks both values
//   double so unconsciousness arrives within ~30 more seconds if unchecked.
//
/obj/machinery/f13/faction_generator/diesel/process()
	// Run the normal fuel/maintenance logic first.
	. = ..()
	// Only emit exhaust while actually running with fuel.
	if(!powered || fuel <= 0)
		co_exposure_map = null
		return
	// Check whether the generator is outdoors — exhaust disperses in open air.
	var/turf/own_turf = get_turf(src)
	if(!own_turf || istype(own_turf, /turf/open/indestructible/ground/outside))
		co_exposure_map = null
		return
	if(!co_exposure_map)
		co_exposure_map = list()
	// Advance or clear exposure for every living mob in range.
	var/list/seen_this_tick = list()
	for(var/mob/living/carbon/human/H in range(4, src))
		if(H.stat == DEAD)
			continue
		seen_this_tick += H
		// Internals block CO — they're breathing from a sealed tank.
		if(H.internal)
			co_exposure_map -= H
			continue
		// Gas mask filters out exhaust fumes.
		if(H.wear_mask && istype(H.wear_mask, /obj/item/clothing/mask/gas))
			co_exposure_map -= H
			continue
		// Powered armor is an airtight sealed suit — no CO penetration.
		if(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit/armor/power_armor))
			co_exposure_map -= H
			continue
		// Outdoor mob on an outside turf despite being near the generator — skip.
		var/turf/mob_turf = get_turf(H)
		if(mob_turf && istype(mob_turf, /turf/open/indestructible/ground/outside))
			co_exposure_map -= H
			continue
		var/ticks = co_exposure_map[H] || 0
		ticks++
		co_exposure_map[H] = ticks
		// Damage scales with cumulative exposure.
		var/dmg = (ticks >= 15) ? 2 : 1
		H.adjustOxyLoss(dmg, 0)
		H.adjustToxLoss(dmg, 0)
		// Staged warning messages — sent at threshold crossings only.
		switch(ticks)
			if(1)
				to_chat(H, span_warning("The air near [src] carries a faint smell of exhaust fumes."))
			if(4)
				to_chat(H, span_danger("You feel a dull throb behind your eyes. The exhaust from [src] is getting to you."))
			if(8)
				to_chat(H, span_danger("Your head swims and your stomach turns. The exhaust fumes are building up in here — you need fresh air."))
			if(15)
				to_chat(H, span_userdanger("You can barely think straight. The carbon monoxide from [src] is suffocating you slowly. Get out NOW."))
	// Remove mobs that moved out of range or died this tick.
	for(var/mob/M in co_exposure_map)
		if(!(M in seen_this_tick))
			co_exposure_map -= M

/obj/machinery/f13/faction_generator/diesel/on_maintenance_hazard()
	// Degrading fuel lines — fire risk; probability escalates the longer servicing is neglected.
	if(prob(min(25, 1 + round(maintenance_severity / 45))))
		var/turf/T = get_turf(src)
		if(T && !locate(/obj/effect/hotspot) in T)
			new /obj/effect/hotspot(T)

/obj/machinery/f13/faction_generator/diesel/on_heat_exposure()
	// ~2 sustained welder applications will ignite the fuel tank.
	if(fuel > 0 && heat_exposure >= 7600)
		heat_exposure = 0
		fire_act(3800, 1)

/obj/machinery/f13/faction_generator/diesel/fire_act(exposed_temperature, exposed_volume)
	// Diesel is flammable — direct contact with fire ruptures the tank.
	// A diesel fire is a sustained localized blaze, not a spray-blast.
	// 25% neighbour spread reflects vapour flare-off, not an explosive detonation.
	if(fuel > 0)
		playsound(src, pick('sound/effects/explosion1.ogg', 'sound/effects/explosion2.ogg'), 100, TRUE)
		do_sparks(10, FALSE, src)
		var/turf/T = get_turf(src)
		if(T)
			new /obj/effect/hotspot(T)
		for(var/turf/adjacent in orange(1, src))
			if(prob(25))  // 25% spread — diesel burns hard but doesn't spray like petrol
				new /obj/effect/hotspot(adjacent)
		// Tank is destroyed — generator is scrap.
		fuel = 0
		co_exposure_map = null
		set_power_state(FALSE)
		stat |= BROKEN
		if(T)
			new /obj/effect/decal/cleanable/ash(T)
	. = ..()

/// Rare Poseidon Energy atomic generator.  One atomic fuel cell, enormous output.
/// Cells are the scarcest fuel in the wasteland, but one will run a small base
/// for a very long time.
/obj/machinery/f13/faction_generator/atomic
	icon_state = "generator_off"
	name = "Poseidon atomic generator"
	desc = "A compact Poseidon Energy pre-War atomic generator, originally spec'd for fringe settlements too remote for a grid hook-up. A single atomic fuel cell will run most of a small base for hours — provided you can find a replacement when it burns out."
	accepted_fuel_path   = /obj/item/f13/atomic_cell
	depleted_fuel_path   = /obj/item/f13/atomic_cell/depleted
	fuel_per_unit        = 675    // ~22 min per cell
	watts_per_fuel_unit  = 1500   // high output — atomic fission beats fusion cores
	max_fuel             = 675    // single-cell chamber
	fuel_unit_name       = "fuel cell"
	heat_ignition_threshold = 15200  // ~4-5 welder applications to breach containment

/obj/machinery/f13/faction_generator/atomic/Initialize()
	. = ..()
	fuel = 675   // pre-loaded with one atomic cell at round start
	// Recalculate watts after fixing fuel — parent Initialize sets fuel to FGEN_DEFAULT_FUEL
	// which is larger than max_fuel=675 for the single-cell chamber.
	available_watts = watts_per_fuel_unit * max(1, round(fuel / fuel_per_unit))

/obj/machinery/f13/faction_generator/atomic/update_icon_state()
	icon_state = powered ? "generator_uranium" : "generator_off"

/obj/machinery/f13/faction_generator/atomic/on_maintenance_hazard()
	// Ageing containment seals — localised radiation leaks; escalates with neglect.
	if(prob(min(15, 3 + round(maintenance_severity / 90))))
		radiation_pulse(src, 35, 2)

/obj/machinery/f13/faction_generator/atomic/on_heat_exposure()
	// ~4 sustained welder applications overheat the containment vessel.
	if(fuel > 0 && heat_exposure >= 15200)
		heat_exposure = 0
		fire_act(3800, 1)

/obj/machinery/f13/faction_generator/atomic/fire_act(exposed_temperature, exposed_volume)
	// Poseidon manual: do not expose to extreme heat — containment seals will fail.
	// A containment breach dumps the cell, emits a radiation pulse, and writes off the unit.
	if(fuel > 0)
		playsound(src, pick('sound/effects/explosioncreak1.ogg', 'sound/effects/explosioncreak2.ogg'), 100, TRUE)
		do_sparks(12, FALSE, src)
		radiation_pulse(src, 80, 5)  // catastrophic breach — wide radiation plume
		var/turf/T = get_turf(src)
		if(T)
			new /obj/effect/decal/cleanable/ash(T)
		// Cell is destroyed; generator is permanently condemned.
		fuel = 0
		set_power_state(FALSE)
		stat |= BROKEN
		broadcast_to_faction("<span class='warning'>CONTAINMENT ALERT: [name] -- fire has breached containment. Emergency shutdown engaged. Severe radiation hazard. Unit is destroyed -- evacuate the area immediately.</span>")
	. = ..()

// ============================================================
// WASTELANDER GENERATOR — Wired grid with relay-extended reach
// ============================================================
//
// Works like the fusion core generator (wired relays, junction boxes, breaker panels)
// but the generator's effective range is limited to power_reach tiles.  Coverage
// extends via relay chains: any relay within power_reach of the generator (or of
// another already-reachable relay) becomes a new range anchor, and all devices
// within power_reach of that anchor receive power.
//
// Example: generator at A, relay at B (8 tiles away), relay at C (8 tiles from B
// but 16 from A).  C is unreachable from A directly but reachable through B — so
// C and its subtree get power.  Relay posts function as range extenders.
//
// stamp_zone() floods the immediate vicinity for ambient lighting.  Pair with a
// /obj/machinery/f13/power_relay/breaker_box as a manual cutoff.
//
// Fuelled by pouring liquid diesel from a jerrycan (same as the diesel variant).
// ============================================================

/// Jury-rigged wasteland generator.  Requires wiring; each relay post within reach
/// extends coverage by another power_reach hop.
/obj/machinery/f13/faction_generator/wastelander
	icon = 'icons/fallout/machines/power.dmi'
	icon_state = "diesel-off"
	name = "jury-rigged generator"
	desc = "A rattling heap of salvaged parts: an old Chryslus engine block, hydraulic hose, and what might once have been a refrigerator compressor, held together with electrical tape and misplaced optimism. Pour diesel in, run your wiring close, and stand back. Powers lights and devices within 10 tiles; each relay post extends that range by another 10 tiles."
	accepted_fuel_path   = null   // liquid-fuel pathway — uses try_liquid_refuel() instead
	depleted_fuel_path   = null
	fuel_is_liquid       = TRUE
	fuel_per_unit        = 1
	watts_per_fuel_unit  = 500    // crude output — less than a proper industrial unit
	max_fuel             = 1000   // ~33 min fully loaded (~2 jerrycans)
	fuel                 = 200    // starts nearly empty — wasteland style
	fuel_unit_name       = "L"
	has_lock_upgrade     = FALSE  // no built-in access control; install a blank ID card to unlock
	/// Base reach in tiles.  Each powered relay within reach becomes its own anchor,
	/// extending coverage by another power_reach hop in any direction.
	var/power_reach = 10
	/// Cached list of /obj/machinery/light within power_reach in the generator's own area.
	/// Built once on the first stamp_zone() call; reused on every subsequent toggle.
	var/list/range_light_cache = null
	/// Accumulated exhaust exposure per nearby mob — same hazard as the diesel variant.
	var/list/co_exposure_map = null

/obj/machinery/f13/faction_generator/wastelander/update_icon_state()
	icon_state = powered ? "diesel-on" : "diesel-off"

/// Wastelander generators do NOT use area-level stamping — they directly control
/// individual lights within power_reach in the same BYOND area.  This prevents
/// powering an entire huge wasteland/building area while still lighting nearby lamps.
/obj/machinery/f13/faction_generator/wastelander/proc/_build_area_instances()
	if(powered_area_types)
		return  // mapper-set areas — don't override
	powered_area_instances = list()  // empty: base stamp_zone does nothing; override handles lights

/// Override: directly seton() lights within power_reach in own area only.
/// Does NOT call ..() so base area-stamp logic is bypassed entirely.
/// Cache is built once on the first call (generator is anchored — position never changes).
/obj/machinery/f13/faction_generator/wastelander/stamp_zone(state)
	var/area/own_area = get_area(src)
	if(range_light_cache == null)
		range_light_cache = list()
		for(var/turf/T in RANGE_TURFS(power_reach, src))
			if(get_area(T) != own_area)
				continue  // different area — skip (no bleed)
			for(var/obj/machinery/light/L in T)
				range_light_cache += L
	for(var/obj/machinery/light/L in range_light_cache)
		if(!QDELETED(L))
			if(state)
				// Don't restore lights in a zone held dark by a tripped breaker.
				if(_area_in_tripped_jbox(get_area(L)))
					continue
				L.seton(L.status == LIGHT_OK)
			else
				// seton(FALSE) triggers update() which re-enables emergency_mode.
				// Kill the light directly so it goes dark instead of red.
				L.on = FALSE
				L.emergency_mode = FALSE
				L.set_light(0)
				L.update_icon()

// set_power_state: inherited from base — all wired relays/clients are powered unconditionally.
// power_reach only controls stamp_zone (ambient lighting), not cable-wired devices.

/obj/machinery/f13/faction_generator/wastelander/_initial_propagate()
	if(QDELETED(src))
		return
	if(!powered)
		// Lights call update(0) ~one tick after our spawn(2) fires; wait for them then kill emergency mode.
		spawn(2)
			if(!QDELETED(src) && !powered)
				range_light_cache = null
				stamp_zone(FALSE)
		return
	_build_area_instances()
	// LateInitialize resets area power before this proc runs; re-stamp to restore lights.
	range_light_cache = null
	stamp_zone(TRUE)
	..()  // powers linked_relays, linked_clients, runs cable scan

/obj/machinery/f13/faction_generator/wastelander/set_power_state(new_powered)
	if(!new_powered)
		shutdown_time = world.time
		co_exposure_map = null
	return ..()

/obj/machinery/f13/faction_generator/wastelander/on_maintenance_hazard()
	// Worst build quality — fuel vapour ignition; escalates the fastest of all variants.
	if(prob(min(30, 2 + round(maintenance_severity / 30))))
		var/turf/T = get_turf(src)
		if(T && !locate(/obj/effect/hotspot) in T)
			new /obj/effect/hotspot(T)

// Jury-rigged exhaust has no muffler — same CO risk as the diesel variant.
/obj/machinery/f13/faction_generator/wastelander/process()
	. = ..()
	if(!powered || fuel <= 0)
		co_exposure_map = null
		return
	var/turf/own_turf = get_turf(src)
	if(!own_turf || istype(own_turf, /turf/open/indestructible/ground/outside))
		co_exposure_map = null
		return
	if(!co_exposure_map)
		co_exposure_map = list()
	var/list/seen_this_tick = list()
	for(var/mob/living/carbon/human/H in range(4, src))
		if(H.stat == DEAD)
			continue
		seen_this_tick += H
		if(H.internal)
			co_exposure_map -= H
			continue
		if(H.wear_mask && istype(H.wear_mask, /obj/item/clothing/mask/gas))
			co_exposure_map -= H
			continue
		if(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit/armor/power_armor))
			co_exposure_map -= H
			continue
		var/turf/mob_turf = get_turf(H)
		if(mob_turf && istype(mob_turf, /turf/open/indestructible/ground/outside))
			co_exposure_map -= H
			continue
		var/ticks = co_exposure_map[H] || 0
		ticks++
		co_exposure_map[H] = ticks
		var/dmg = (ticks >= 15) ? 2 : 1
		H.adjustOxyLoss(dmg, 0)
		H.adjustToxLoss(dmg, 0)
		switch(ticks)
			if(1)
				to_chat(H, span_warning("The air near [src] carries a faint smell of exhaust fumes."))
			if(4)
				to_chat(H, span_danger("You feel a dull throb behind your eyes. The exhaust from [src] is getting to you."))
			if(8)
				to_chat(H, span_danger("Your head swims and your stomach turns. The exhaust fumes are building up in here — you need fresh air."))
			if(15)
				to_chat(H, span_userdanger("You can barely think straight. The carbon monoxide from [src] is suffocating you slowly. Get out NOW."))
	for(var/mob/M in co_exposure_map)
		if(!(M in seen_this_tick))
			co_exposure_map -= M

/obj/machinery/f13/faction_generator/wastelander/attackby(obj/item/W, mob/user, params)
	if(try_liquid_refuel(W, user))
		return
	// Security module + screwdriver installs the lock-reader upgrade.
	if(!has_lock_upgrade && istype(W, /obj/item/f13/security_module))
		to_chat(user, span_notice("You hold the RobCo security module against [src]'s panel. Use a screwdriver to wire it in."))
		return
	if(!has_lock_upgrade && W.tool_behaviour == TOOL_SCREWDRIVER)
		// Check the other hand for the security module.
		var/obj/item/f13/security_module/mod = null
		if(isliving(user))
			var/mob/living/L = user
			var/obj/item/other = L.get_inactive_held_item()
			if(istype(other, /obj/item/f13/security_module))
				mod = other
		if(!mod)
			to_chat(user, span_notice("The panel is sealed. Hold a RobCo security module in your other hand, then use the screwdriver."))
			return
		if(!W.use_tool(src, user, 30, volume=50))
			return
		user.temporarilyRemoveItemFromInventory(mod)
		qdel(mod)
		has_lock_upgrade = TRUE
		to_chat(user, span_notice("You wire the RobCo security module into [src]'s control panel. Access control is now available."))
		show_ui(user)
		return
	return ..()

/// After the base rescan runs, rebuild the light cache so newly in-range lamps are included.
/obj/machinery/f13/faction_generator/wastelander/Topic(href, href_list)
	. = ..()
	if(href_list["choice"] == "rescan" && powered)
		// Rebuild light cache so newly laid cables to range lamps are included.
		range_light_cache = null
		stamp_zone(TRUE)

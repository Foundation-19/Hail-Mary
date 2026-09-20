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
	icon = 'icons/machines/power_grid/faction_generator.dmi'
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
	/// Physically-inserted fuel-cell items, in slot order (discrete-unit generators only).
	/// Each item's charge_ticks tracks its own remaining fuel so it can be identified and
	/// ejected individually with the charge it actually has left. Round-start fuel is seeded
	/// here as real cores too — there is no separate invisible fuel bucket.
	var/list/inserted_cores = null

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
	/// Current total *apparent* draw (VA) — true watts divided by each client's own power
	/// factor. This is what's actually checked against get_available_va() for overload,
	/// since apparent power (current) is what stresses wiring/breakers, not true power alone.
	var/current_va_draw = 0
	/// This generator's own alternator power-factor rating (0 < PF <= 1). Determines how
	/// much apparent power (VA) the unit can deliver at its rated true-watt output — 1.0
	/// means the alternator itself never derates capacity below the engine's true output.
	var/rated_power_factor = 1.0
	/// TRUE when the generator has tripped due to overload.
	var/overloaded = FALSE
	/// TRUE when an operator manually shut the generator down via the UI.
	/// While set the generator will not auto-restart even if fuel and capacity are available.
	/// Cleared automatically when fuel runs out so that inserting new fuel triggers a normal start.
	var/manually_shutdown = FALSE
	/// TRUE once an explosion has forced an emergency shutdown. While set, no fuel is burned
	/// and no power is distributed — a damaged reactor doesn't calmly keep running. Cleared
	/// by repairing the unit with a wrench.
	var/emergency_shutdown = FALSE
	/// TRUE right after a manual screwdriver eject — suppresses the next process() "fuel exhausted"
	/// depleted-casing spawn, since on_fuel_ejected() already returned the fuel to the user.
	var/skip_next_depletion_spawn = FALSE
	/// TRUE once the current empty-tank state has already been handled by process(), so the
	/// exhaustion transition/casing spawn fires once per depletion instead of every tick at 0 fuel.
	var/depletion_handled = FALSE
	/// TRUE while a manual liquid-fuel siphon is in progress, so a second "DRAIN TANK" click
	/// can't start an overlapping drain loop.
	var/is_syphoning = FALSE

	// ── Load shedding — soft power management before hard-tripping the grid
	/// Direct relays currently suspended by load-shedding.  Draw = 0 while here.
	var/list/shed_relays = null

	// ── Mapper pre-wiring
	/// Comma-separated object tags for relays to auto-wire on Initialize.
	/// Mapper-placed relays with matching tags will be wired to this generator at round start.
	var/map_relay_tags = null
	/// Comma-separated object tags for grid_clients (e.g. junction boxes, fabricators) to auto-wire on Initialize.
	var/map_client_tags = null

	/// world.time when the generator last powered down; used for hot-refuel cooldown.
	var/shutdown_time = 0
	/// Ticks elapsed since the last automatic restart attempt while tripped from overload.
	var/overload_retry_ticks = 0

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
	/// Ticks the generator has run continuously since it was last serviced (or new).
	/// Wear doesn't start accruing until this passes FGEN_WEAR_GRACE_PERIOD — a freshly
	/// serviced unit is reliable for a while.  Reset by a wrench service while running.
	var/uptime_ticks        = 0
	/// Ticks elapsed since the last automatic dead-link prune (see FGEN_LINK_PRUNE_INTERVAL).
	var/link_prune_ticks    = 0
	/// TRUE once wear_level > 0 — the generator could use a wrench service.
	/// A wrench applied while running clears this along with wear_level/uptime_ticks.
	var/needs_maintenance   = FALSE
	/// Ticks elapsed since the last wear-check roll (see FGEN_WEAR_CHECK_INTERVAL).
	var/wear_check_ticks    = 0
	/// Accumulated wear stacks (0..FGEN_WEAR_MAX).  Each stack raises the odds of gaining
	/// another on the next check, and — past FGEN_WEAR_HAZARD_THRESHOLD — the odds of an
	/// actual type-specific hazard (see on_maintenance_hazard()).  Cleared by a wrench
	/// service while running.
	var/wear_level          = 0
	/// Percent multiplier applied to the hazard roll once past the wear threshold — lets
	/// subtypes be a safer or riskier build without duplicating the roll math. 100 = normal.
	var/wear_hazard_multiplier = 100
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
	// Liquid-fuel variants use their type-level var default; discrete-unit variants start
	// with FGEN_DEFAULT_FUEL, capped to max_fuel — a tank can't hold more than it can hold,
	// so ejecting it back out can never spawn more cores than would actually fit in a slot.
	fuel = fuel_is_liquid ? initial(fuel) : min(FGEN_DEFAULT_FUEL, max_fuel)
	if(!fuel_is_liquid)
		inserted_cores = list()
		_seed_starting_cores()  // round-start fuel comes pre-loaded as real cores, not a hidden reserve
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
					if(!QDELETED(R))
						if(!linked_relays)
							linked_relays = list()
						// Only gate on whether THIS generator already claims R — a relay already
						// fed by another generator/relay is still fair game for a second, parallel feed.
						if(!(R in linked_relays) && !R._has_upstream(src))
							linked_relays += R
							if(!R.upstream_refs) R.upstream_refs = list()
							R.upstream_refs += WEAKREF(src)
							R.on_upstream_changed()
					blocked = TRUE
					break
				if(blocked)
					continue
				for(var/obj/machinery/f13/grid_client/C in N)
					if(!QDELETED(C))
						if(!linked_clients)
							linked_clients = list()
						// Same relaxed gate as above — a client already fed by another upstream
						// can still take a second, parallel feed from this generator.
						if(!(C in linked_clients) && !C._has_upstream(src))
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
			// Strip any stale shed-list reference too — a relay that's no longer
			// actually linked must never be silently re-powered by
			// _try_restore_shed() later without its draw being re-counted.
			if(shed_relays)
				shed_relays -= R
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
			if(shed_clients)
				shed_clients -= C
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

/// A generator that survives an explosion shouldn't calmly keep burning fuel and pushing
/// power like nothing happened — force an emergency shutdown until it's repaired.
/obj/machinery/f13/faction_generator/ex_act(severity, target)
	. = ..()
	if(QDELETED(src) || emergency_shutdown)
		return
	emergency_shutdown = TRUE
	manually_shutdown = TRUE
	if(powered)
		set_power_state(FALSE)


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
	if(powered && fuel > 0 && !emergency_shutdown)
		depletion_handled = FALSE
		_drain_one_tick()

		// Periodically re-validate wired links — a cable severed by an explosion (or anything
		// else) won't otherwise be noticed until someone manually hits rescan.
		link_prune_ticks++
		if(link_prune_ticks >= FGEN_LINK_PRUNE_INTERVAL)
			link_prune_ticks = 0
			_prune_dead_links()

		// Recompute available watts.
		// Liquid-fuel generators run at a flat output; discrete units scale per slot.
		if(fuel_is_liquid)
			available_watts = watts_per_fuel_unit
		else
			var/units_loaded = max(1, round(fuel / fuel_per_unit))
			available_watts = watts_per_fuel_unit * units_loaded

		// Recompute draw, skipping any shed items.
		recalc_draw()

		// ── Wear & tear — a fresh/serviced unit is reliable for FGEN_WEAR_GRACE_PERIOD.
		// Past that, roll for wear every FGEN_WEAR_CHECK_INTERVAL ticks: each existing stack
		// raises the odds of gaining another, and — once badly worn — a much rarer roll can
		// trigger an actual type-specific hazard.  There's no auto-shutdown from neglect alone;
		// only a real hazard (fire, containment breach, ...) ever takes the unit offline.
		uptime_ticks++
		if(uptime_ticks >= FGEN_WEAR_GRACE_PERIOD)
			wear_check_ticks++
			if(wear_check_ticks >= FGEN_WEAR_CHECK_INTERVAL)
				wear_check_ticks = 0
				_roll_wear_check()

		// ── Under budget: try restoring previously shed loads.
		if(!_is_over_budget())
			_try_restore_shed()

		// ── Over budget (true watts OR apparent VA): try soft load-shedding before hard-tripping.
		if(_is_over_budget())
			if(!_do_load_shed())
				// Shedding alone couldn't resolve it — hard grid trip.
				if(!overloaded)
					overloaded = TRUE
					set_power_state(FALSE)
			return

		// ── Under budget and stable — clear any hard-trip state.
		if(overloaded)
			overloaded = FALSE
			if(!manually_shutdown)
				set_power_state(TRUE)

		return

	// Tripped from overload, not manually shut down, not out of fuel, not in emergency
	// shutdown — periodically retry in case a sibling generator/relay coming online (or
	// going offline) now leaves this one's share under budget.
	if(!powered && overloaded && !manually_shutdown && !emergency_shutdown && fuel > 0)
		overload_retry_ticks++
		if(overload_retry_ticks >= FGEN_OVERLOAD_RETRY_INTERVAL)
			overload_retry_ticks = 0
			_try_overload_retry()
		return

	// Fuel exhausted — only transition/spawn a casing once per depletion, not every tick at 0 fuel.
	if(depletion_handled)
		return
	depletion_handled = TRUE
	if(powered)
		set_power_state(FALSE)
	// If physical cores are tracked, any depleted one already sits in its slot in place —
	// only synthesize a shell for the untracked abstract reserve running out.
	var/has_tracked_cores = inserted_cores && inserted_cores.len
	if(depleted_fuel_path && !skip_next_depletion_spawn && !has_tracked_cores)
		new depleted_fuel_path(drop_location())
	skip_next_depletion_spawn = FALSE
	manually_shutdown = FALSE  // reset so inserting new fuel triggers normal auto-start

/// Fills empty slots at round start with real cores matching the starting fuel amount,
/// so players only ever see and manage physical cores — never a hidden fuel bucket.
/obj/machinery/f13/faction_generator/proc/_seed_starting_cores()
	if(!accepted_fuel_path || fuel <= 0)
		return
	var/remaining = fuel
	var/slots = max(1, round(max_fuel / fuel_per_unit))
	for(var/i in 1 to slots)
		if(remaining <= 0)
			break
		var/obj/item/seed_core = new accepted_fuel_path(src)
		var/seed_amount = min(fuel_per_unit, remaining)
		seed_core:charge_ticks = seed_amount
		inserted_cores += seed_core
		remaining -= seed_amount

/// Baseline load fraction for unmetered area equipment (lights/doors/APCs), scaled by how
/// many powered areas this generator owns. Zero if it owns no areas — nothing unmetered to run.
/obj/machinery/f13/faction_generator/proc/get_min_load_fraction()
	if(!powered_area_instances || !powered_area_instances.len)
		return 0
	return min(FGEN_MIN_LOAD_FRACTION_CAP, powered_area_instances.len * FGEN_MIN_LOAD_FRACTION_PER_AREA)

/// Consumes one fuel tick, scaled by how loaded the generator currently is relative to its
/// rated capacity — the tuned max_fuel/fuel durations assume 100% rated load, so anything
/// under that stretches the tank proportionally. Drains from the first physically-tracked
/// core that still has charge, so a depleted shell in an earlier slot doesn't block later slots.
/obj/machinery/f13/faction_generator/proc/_drain_one_tick()
	var/load_fraction = available_watts > 0 ? clamp(current_draw / available_watts, get_min_load_fraction(), 1) : 1
	fuel -= load_fraction
	if(fuel_is_liquid)
		return
	if(!inserted_cores || !inserted_cores.len)
		return
	var/obj/item/core
	for(var/obj/item/candidate in inserted_cores)
		if(!candidate:depleted && candidate:charge_ticks > 0)
			core = candidate
			break
	if(!core)
		return
	core:charge_ticks -= load_fraction
	if(core:charge_ticks <= 0 && !core:depleted)
		_deplete_core(core)

/// Swaps a spent core for its depleted shell in place, keeping the same slot position.
/obj/machinery/f13/faction_generator/proc/_deplete_core(obj/item/core)
	var/idx = inserted_cores.Find(core)
	if(!idx)
		return
	if(depleted_fuel_path)
		var/obj/item/f13/spent = new depleted_fuel_path(src)
		spent:charge_ticks = 0
		inserted_cores[idx] = spent
	else
		inserted_cores.Cut(idx, idx + 1)
	qdel(core)


// ============================================================
// POWER STATE
// ============================================================

/obj/machinery/f13/faction_generator/proc/set_power_state(new_powered)
	if(powered == new_powered)
		return

	powered = new_powered
	_propagate_power_state()

/// Shared side effects of a power-state flip: icon, area stamping, turrets, relays, clients.
/// Split out from set_power_state() so a silent retry attempt (_try_overload_retry()) can
/// reuse the same propagation.
/obj/machinery/f13/faction_generator/proc/_propagate_power_state()
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

/// Silently tests whether this generator would now fit under budget if brought back online —
/// e.g. a sibling generator/relay coming online since the trip now splits a shared load enough
/// to fit. Reverts if it still doesn't fit, so it just quietly retries next interval.
/obj/machinery/f13/faction_generator/proc/_try_overload_retry()
	powered = TRUE
	available_watts = fuel_is_liquid ? watts_per_fuel_unit : (watts_per_fuel_unit * max(1, round(fuel / fuel_per_unit)))
	recalc_draw()
	if(_is_over_budget())
		powered = FALSE  // still doesn't fit — revert quietly, try again next interval
		return
	overloaded = FALSE
	_propagate_power_state()

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
	current_va_draw = 0
	// Direct turrets on this generator.
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				current_draw += TURRET_WATT_DRAW
				current_va_draw += TURRET_WATT_DRAW  // simple electronics — PF 1.0
	// Generic grid clients (includes fabricators) — skip any that are currently load-shed.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				if(shed_clients && (C in shed_clients))
					continue  // shed — counts as 0W
				// A client fed by more than one live generator/relay splits its draw evenly between them.
				var/live_upstreams = max(1, C.get_live_upstream_count())
				current_draw += C.get_effective_watt_draw() / live_upstreams
				current_va_draw += C.get_effective_va_draw() / live_upstreams
	// Relay chains (recursive) — skip any that are currently load-shed.
	if(linked_relays)
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(!QDELETED(R))
				if(shed_relays && (R in shed_relays))
					continue  // shed — counts as 0W
				var/live_upstreams = max(1, R.get_live_upstream_count())
				current_draw += R.get_subtree_draw() / live_upstreams
				current_va_draw += R.get_subtree_va_draw() / live_upstreams

/// Apparent power (VA) capacity — the true-watt engine output divided by this unit's own
/// alternator power-factor rating. Checked against current_va_draw for overload, since
/// apparent power (current) is what actually stresses wiring and breakers.
/obj/machinery/f13/faction_generator/proc/get_available_va()
	return available_watts / max(0.05, rated_power_factor)

/// Return total watts this generator is currently delivering vs. what it can supply.
/obj/machinery/f13/faction_generator/proc/get_load_summary()
	return "[round(current_draw)]W / [available_watts]W"

// ── Load shedding — shed loads in priority order to prevent a full grid trip.
/// TRUE if either true-power (engine) or apparent-power (alternator/wiring) capacity
/// is currently exceeded — either one is a real overload, not just the true-watt figure.
/obj/machinery/f13/faction_generator/proc/_is_over_budget()
	return (current_draw > available_watts) || (current_va_draw > get_available_va())

/// Called when the generator is over budget on either true or apparent power.
/// Returns TRUE if shedding resolved the overload, FALSE if a hard trip is still needed.
/obj/machinery/f13/faction_generator/proc/_do_load_shed()
	// PRIORITY 1: high-priority grid clients (e.g. fabricators, grid_shed_priority > 0).
	// Shed active crafting machines first (highest per-unit watt saving),
	// then idle high-priority units.
	if(_is_over_budget() && linked_clients)
		for(var/pass in 1 to 2)
			for(var/obj/machinery/f13/grid_client/C in linked_clients)
				if(!_is_over_budget())
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
				current_draw -= C.get_effective_watt_draw()
				current_va_draw -= C.get_effective_va_draw()

	// PRIORITY 2: relay subtrees — cut lowest-draw relays first to preserve
	// turret-heavy nodes as long as possible.
	if(_is_over_budget() && linked_relays)
		var/list/relay_cands = list()
		for(var/obj/machinery/f13/power_relay/R in linked_relays)
			if(QDELETED(R) || !R.relay_powered)
				continue
			if(shed_relays && (R in shed_relays))
				continue
			relay_cands += R
		// Each pass: cut the relay with the smallest subtree draw first.
		while(relay_cands.len > 0 && _is_over_budget())
			var/obj/machinery/f13/power_relay/pick = null
			var/pick_draw = 999999
			for(var/obj/machinery/f13/power_relay/RC in relay_cands)
				var/d = RC.get_subtree_draw()
				if(d < pick_draw)
					pick_draw = d
					pick = RC
			if(!pick)
				break
			var/pick_va_draw = pick.get_subtree_va_draw()
			relay_cands -= pick
			pick.load_shed = TRUE
			pick.set_relay_power(FALSE)
			if(!shed_relays)
				shed_relays = list()
			shed_relays += pick
			current_draw -= pick_draw
			current_va_draw -= pick_va_draw

	return !_is_over_budget()

// ── Restore shed loads when the generator has headroom again.
/// Called each process() tick before the overload check (only when under budget).
/obj/machinery/f13/faction_generator/proc/_try_restore_shed()
	// Restore relays first — area power and turrets have higher in-game impact.
	if(shed_relays && shed_relays.len)
		var/list/to_restore = list()
		for(var/obj/machinery/f13/power_relay/R in shed_relays)
			if(QDELETED(R))
				to_restore += R  // clean up dead refs
				continue
			// Defensive: a stale reference can linger here if the relay was
			// unlinked (cable cut / pruned) while still marked shed — never
			// restore power to something that isn't actually linked anymore,
			// or its draw would go uncounted forever (ghost/free power).
			if(!linked_relays || !(R in linked_relays))
				to_restore += R  // drop the stale entry, do NOT re-power it
				continue
			var/would_draw = R.get_subtree_draw()
			var/would_va_draw = R.get_subtree_va_draw()
			if(current_draw + would_draw <= available_watts && current_va_draw + would_va_draw <= get_available_va())
				current_draw += would_draw
				current_va_draw += would_va_draw
				to_restore += R
		for(var/obj/machinery/f13/power_relay/R in to_restore)
			shed_relays -= R
			if(!QDELETED(R) && linked_relays && (R in linked_relays))
				R.load_shed = FALSE
				R.set_relay_power(TRUE)

	// Restore grid clients (fabricators and junction boxes) by draw order —
	// smallest draw restored first so we fit as many devices back as possible.
	if(shed_clients && shed_clients.len)
		var/list/to_restore = list()
		for(var/obj/machinery/f13/grid_client/C in shed_clients)
			if(QDELETED(C))
				to_restore += C  // clean up dead refs
				continue
			if(!linked_clients || !(C in linked_clients))
				to_restore += C  // stale entry — drop without re-powering
				continue
			if(current_draw + C.get_effective_watt_draw() <= available_watts && current_va_draw + C.get_effective_va_draw() <= get_available_va())
				current_draw += C.get_effective_watt_draw()
				current_va_draw += C.get_effective_va_draw()
				to_restore += C
		for(var/obj/machinery/f13/grid_client/C in to_restore)
			shed_clients -= C
			if(!QDELETED(C) && linked_clients && (C in linked_clients))
				C.on_load_shed_restore()


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


/// Rolls the periodic wear check once the grace period has elapsed.  Gaining a stack is
/// probabilistic and escalates with existing stacks; an actual hazard is a separate, much
/// rarer roll gated behind FGEN_WEAR_HAZARD_THRESHOLD stacks of wear.
/obj/machinery/f13/faction_generator/proc/_roll_wear_check()
	if(wear_level < FGEN_WEAR_MAX)
		var/gain_chance = FGEN_WEAR_BASE_CHANCE + (wear_level * FGEN_WEAR_CHANCE_PER_STACK)
		if(prob(gain_chance))
			wear_level++
			needs_maintenance = TRUE
	if(wear_level >= FGEN_WEAR_HAZARD_THRESHOLD)
		var/stacks_over = wear_level - FGEN_WEAR_HAZARD_THRESHOLD
		var/hazard_chance = (FGEN_WEAR_HAZARD_BASE_CHANCE + (stacks_over * FGEN_WEAR_HAZARD_CHANCE_PER_STACK)) * wear_hazard_multiplier / 100
		if(prob(hazard_chance))
			on_maintenance_hazard()

/// Called by _roll_wear_check() when a rare hazard roll succeeds at high wear.
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
		if(wear_level >= FGEN_WEAR_MAX)
			. += span_warning("Something is clearly wrong — heat radiating from the housing and an acrid smell. It needs servicing immediately.")
		else if(wear_level >= FGEN_WEAR_HAZARD_THRESHOLD)
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
				wear_level = 0
				uptime_ticks = 0
				wear_check_ticks = 0
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, span_notice("You tighten the fittings and check the seals on [src]. Maintenance log cleared — it feels like new."))
			else
				var/ticks_left = FGEN_WEAR_GRACE_PERIOD - uptime_ticks
				if(ticks_left > 0)
					var/mins = round(ticks_left / 30)
					to_chat(user, span_notice("The unit is fresh from its last service — no wear expected for at least [mins] more minute[mins != 1 ? "s" : ""]."))
				else
					to_chat(user, span_notice("The seals and fittings feel solid — no service needed yet. Power it down first if you want to move it."))
			return
		// Offline — repair if damaged/broken, otherwise anchor toggle.
		if((stat & BROKEN) || obj_integrity < max_integrity)
			if(!W.use_tool(src, user, 30, volume=50))
				return
			stat &= ~BROKEN
			needs_maintenance = FALSE
			wear_level = 0
			uptime_ticks = 0
			wear_check_ticks = 0
			emergency_shutdown = FALSE
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
		_eject_all_fuel(user)
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

		// Fusion cores and atomic cells both carry a depleted flag; spent cells must be recycled first.
		if((istype(W, /obj/item/f13/fusion_core) || istype(W, /obj/item/f13/atomic_cell)) && W:depleted)
			to_chat(user, span_warning("That core is depleted. Recycle it in a core fabricator first."))
			return

		if(fuel >= max_fuel)
			to_chat(user, span_warning("[src] already has full fuel reserves."))
			return

		var/slots = max(1, round(max_fuel / fuel_per_unit))
		if(inserted_cores && inserted_cores.len >= slots)
			to_chat(user, span_warning("[src] has no empty slot — eject a [fuel_unit_name] first."))
			return

		// Partially-charged cores (from an earlier eject) add only what's left in them.
		var/add_amount = fuel_per_unit
		if((istype(W, /obj/item/f13/fusion_core) || istype(W, /obj/item/f13/atomic_cell)) && W:charge_ticks >= 0)
			add_amount = W:charge_ticks

		// Never truncate a core's real charge down to whatever fits — that destroys the
		// difference permanently. Reject the insert instead so the charge stays intact.
		if(add_amount > max_fuel - fuel)
			to_chat(user, span_warning("[src] doesn't have room for that [fuel_unit_name]'s full charge — eject some fuel first."))
			return

		user.transferItemToLoc(W, src)
		var/old_fuel = fuel
		fuel = min(fuel + add_amount, max_fuel)
		W:charge_ticks = add_amount
		if(inserted_cores)
			inserted_cores += W

		user.visible_message(
			"[user] loads a [fuel_unit_name] into [src].",
			span_notice("You insert a [fuel_unit_name] into [src]. ([fuel - old_fuel] fuel added; total: [fuel]/[max_fuel])")
		)

		// Recalculate available watts — more fuel = more capacity.
		available_watts = watts_per_fuel_unit * max(1, round(fuel / fuel_per_unit))
		recalc_draw()

		if(!powered)
			set_power_state(TRUE)
		else if(overloaded && !_is_over_budget())
			overloaded = FALSE
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
	recalc_draw()


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

	recalc_draw()
	var/available_va = get_available_va()
	var/load_pct   = available_watts > 0 ? round((current_draw / available_watts) * 100) : 0
	var/va_pct     = available_va > 0 ? round((current_va_draw / available_va) * 100) : 0
	var/load_color = _is_over_budget() ? "bad" : ((current_draw > available_watts * 0.8 || current_va_draw > available_va * 0.8) ? "warn" : "good")

	// Mirror _drain_one_tick()'s actual drain rate so the displayed estimate reflects
	// current load instead of assuming a constant full-load burn.
	var/load_fraction = available_watts > 0 ? clamp(current_draw / available_watts, get_min_load_fraction(), 1) : 1
	var/runtime_display
	if(load_fraction <= 0)
		runtime_display = "indefinite"
	else
		var/runtime_secs = round((fuel / load_fraction) * 2)  // each fuel unit = 2 s at full load
		runtime_display = runtime_secs < 120 ? "[runtime_secs]s" : "[round(runtime_secs / 60)] min"

	// Build a simple ASCII bar (20 chars wide) — reflects whichever of true/apparent power is closer to tripping.
	var/bar_fill  = round(max(load_pct, va_pct) / 5)
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
	if(emergency_shutdown)
		status_line += " <span class='bad'>&#91;!! EMERGENCY SHUTDOWN — EXPLOSIVE DAMAGE !!&#93;</span>"
	if(overloaded)
		status_line += " <span class='bad'>&#91;!! CIRCUIT OVERLOAD !!&#93;</span>"
	var/shed_total = (shed_clients ? shed_clients.len : 0) + (shed_relays ? shed_relays.len : 0)
	if(shed_total > 0)
		status_line += " <span class='warn'>&#91;LOAD SHED: [shed_total] device[shed_total != 1 ? "s" : ""] suspended&#93;</span>"
	dat += "<pre>  STATUS   : [status_line]</pre>"
	if(!grounded)
		dat += "<pre>  <span style='color:#ff8c00'>  &#9888; UNGROUNDED  &mdash;  install a grounding rod to prevent leakage current hazards</span></pre>"

	// ── Diagnostics checklist — the first thing a tech should scan on approach
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;DIAGNOSTICS&#93;</pre>"
	var/list/diag = list()
	diag += list(list(grounded ? "good" : "bad", grounded ? "Grounding rod installed" : "Ungrounded — leakage current hazard"))
	diag += list(list(fuel > 0 ? "good" : "bad", fuel > 0 ? "Fuel supply nominal" : "No fuel — cannot start"))
	if(fuel > 0 && max_fuel > 0 && (fuel / max_fuel) < 0.15)
		diag += list(list("warn", "Fuel reserve low — refuel soon"))
	var/near_capacity = (available_watts > 0 && current_draw > available_watts * 0.9) || (available_va > 0 && current_va_draw > available_va * 0.9)
	diag += list(list(overloaded ? "bad" : (near_capacity ? "warn" : "good"), \
		overloaded ? "Circuit overload — output tripped" : (near_capacity ? "Load near rated capacity" : "Load within rated capacity")))
	var/blended_pf_pct = current_va_draw > 0 ? round((current_draw / current_va_draw) * 100) : 100
	diag += list(list(blended_pf_pct >= 90 ? "good" : (blended_pf_pct >= 75 ? "warn" : "bad"), \
		"Grid power factor [blended_pf_pct]%[blended_pf_pct < 90 ? " — low-PF loads are drawing more apparent current than their rated wattage suggests" : " — efficient load mix"]"))
	diag += list(list(obj_integrity >= max_integrity * 0.67 ? "good" : (obj_integrity >= max_integrity * 0.33 ? "warn" : "bad"), \
		obj_integrity >= max_integrity * 0.67 ? "Structural integrity nominal" : (obj_integrity >= max_integrity * 0.33 ? "Structural integrity degraded — repair advised" : "Structural integrity critical — repair immediately")))
	diag += list(list(wear_level >= FGEN_WEAR_MAX ? "bad" : (wear_level >= FGEN_WEAR_HAZARD_THRESHOLD ? "warn" : "good"), \
		wear_level >= FGEN_WEAR_MAX ? "Wear critical — hazard risk high, service now" : (wear_level >= FGEN_WEAR_HAZARD_THRESHOLD ? "Wear elevated — service recommended" : "Wear nominal")))
	if(emergency_shutdown)
		diag += list(list("bad", "Emergency shutdown latched — explosive damage sustained"))
	if(shed_total > 0)
		diag += list(list("warn", "[shed_total] device[shed_total != 1 ? "s" : ""] load-shed to stay under capacity"))
	for(var/entry in diag)
		var/lvl = entry[1]
		var/lbl = entry[2]
		var/tag = lvl == "good" ? "OK  " : (lvl == "warn" ? "WARN" : "FAIL")
		dat += "<pre>    <span class='[lvl]'>&#91;[tag]&#93;</span>  [lbl]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	if(fuel_is_liquid)
		dat += "<pre>  FUEL     : [fuel] L / [max_fuel] L <span class='dim'>([fuel_pct]%  runtime ~[runtime_display])</span></pre>"
		if(accessible)
			dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=eject_fuel'>DRAIN TANK</a>  <span class='dim'>(vent remaining fuel; generator powers down)</span></pre>"
		dat += "<pre>  CAPACITY : [available_watts]W  <span class='dim'>(liquid fuel — flat [available_watts]W output)</span></pre>"
	else
		dat += "<pre>  FUEL     : [fuel] / [max_fuel] <span class='dim'>([fuel_pct]%  ~[units_remaining] [fuel_unit_name](s)  runtime ~[runtime_display])</span></pre>"
		var/slots = max(1, round(max_fuel / fuel_per_unit))
		dat += "<pre class='head'>  &#91;FUEL CELLS&#93;</pre>"
		for(var/slot_i = 1; slot_i <= slots; slot_i++)
			if(inserted_cores && slot_i <= inserted_cores.len)
				var/obj/item/core = inserted_cores[slot_i]
				var/slot_line
				if(core:depleted)
					slot_line = "<span class='bad'>DEPLETED</span>"
				else
					var/core_pct = round((core:charge_ticks / fuel_per_unit) * 100)
					var/core_color = core_pct < 25 ? "warn" : "good"
					slot_line = "<span class='[core_color]'>[core_pct]% charged</span>"
				dat += "<pre>    SLOT [slot_i] : [core.name]  [slot_line]"
				if(accessible)
					dat += "  <a href='byond://?src=[REF(src)];choice=eject_core;idx=[slot_i]'>&#91;EJECT&#93;</a>"
				dat += "</pre>"
			else
				dat += "<pre class='dim'>    SLOT [slot_i] : -- empty --</pre>"
		if(accessible)
			dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=eject_fuel'>EJECT ALL</a>  <span class='dim'>(purge every slot; generator powers down)</span></pre>"
		dat += "<pre>  CAPACITY : [available_watts]W  <span class='dim'>([max(1,round(fuel/fuel_per_unit))] [fuel_unit_name](s) x [watts_per_fuel_unit]W)</span></pre>"
	dat += "<pre>  DRAW     : <span class='[load_color]'>[round(current_draw)]W ([load_pct]%)</span>  <span class='dim'>true power</span></pre>"
	dat += "<pre>  APPARENT : <span class='[load_color]'>[round(current_va_draw)]VA ([va_pct]%)</span>  <span class='dim'>(alternator rated [round(available_va)]VA @ PF [rated_power_factor])</span></pre>"
	dat += "<pre>  LOAD BAR : <span class='[load_color]'>[bar_str]</span> [max(load_pct, va_pct)]%</pre>"
	dat += "<pre class='dim'>  COST REF.: relay=[RELAY_WATT_DRAW]W  fab=[FAB_WATT_DRAW_IDLE]W idle/[FAB_WATT_DRAW_ACTIVE]W active  turret=[TURRET_WATT_DRAW]W</pre>"
	var/integrity_color = obj_integrity < max_integrity * 0.33 ? "bad" : (obj_integrity < max_integrity * 0.67 ? "warn" : "good")
	dat += "<pre>  INTEGRITY: <span class='[integrity_color]'>[obj_integrity] / [max_integrity]</span>  <span class='dim'>(wrench while offline to repair)</span></pre>"

	// ── Maintenance / wear meter
	var/wear_pct = round((wear_level / FGEN_WEAR_MAX) * 100)
	var/wear_color = wear_level >= FGEN_WEAR_MAX ? "bad" : (wear_level >= FGEN_WEAR_HAZARD_THRESHOLD ? "warn" : (wear_level > 0 ? "warn" : "good"))
	var/wear_bar_fill = clamp(wear_level, 0, FGEN_WEAR_MAX)
	var/wear_bar = "&#91;"
	var/w_bi
	for(w_bi = 1; w_bi <= FGEN_WEAR_MAX; w_bi++)
		wear_bar += w_bi <= wear_bar_fill ? "#" : "."
	wear_bar += "&#93;"
	if(uptime_ticks < FGEN_WEAR_GRACE_PERIOD)
		var/grace_mins_left = round((FGEN_WEAR_GRACE_PERIOD - uptime_ticks) / 30)
		dat += "<pre>  WEAR     : <span class='good'>[wear_bar] 0%</span>  <span class='dim'>(fresh — no wear expected for ~[grace_mins_left] min)</span></pre>"
	else
		dat += "<pre>  WEAR     : <span class='[wear_color]'>[wear_bar] [wear_pct]%</span>  <span class='dim'>(wrench while running to service)</span></pre>"
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
					cstate = "<span class='good'>ONLINE  [C.get_effective_watt_draw()]W</span>"
				else
					cstate = "<span class='bad'>OFFLINE [C.get_effective_watt_draw()]W</span>"
				if(!is_shed && C.power_factor < 1)
					cstate += " <span class='dim'>([round(C.get_effective_va_draw())]VA @ PF [C.power_factor])</span>"
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
			dat += "<pre>  <a href='byond://?src=[REF(src)];choice=shutdown'>&#91; EMERGENCY SHUTDOWN &#93;</a>  <span class='dim'>(cuts output; fuel consumption stops)</span></pre>"
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
			_eject_all_fuel(U)
		if("eject_core")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			var/idx = text2num(href_list["idx"])
			if(!inserted_cores || !idx || idx < 1 || idx > inserted_cores.len)
				return
			var/obj/item/core = inserted_cores[idx]
			inserted_cores.Cut(idx, idx + 1)
			var/removed_charge = max(0, core:charge_ticks)
			fuel = max(0, fuel - removed_charge)
			core.forceMove(drop_location())
			to_chat(U, span_notice("You eject [core] from slot [idx]."))
			available_watts = fuel_is_liquid ? watts_per_fuel_unit : (watts_per_fuel_unit * max(1, round(fuel / fuel_per_unit)))
			recalc_draw()
			if(fuel <= 0)
				skip_next_depletion_spawn = TRUE  // this eject already returned the core; don't also spawn a depleted casing
				if(powered)
					set_power_state(FALSE)
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
				to_chat(U, span_notice("Generator output cut. Fuel consumption stops while offline. Use 'START GENERATOR' to bring it back online."))
		if("startup")
			if(!can_access(U))
				to_chat(U, span_warning("Access denied."))
				return
			if(powered)
				to_chat(U, span_notice("Generator is already online."))
			else if(emergency_shutdown)
				to_chat(U, span_warning("Emergency shutdown latched after explosive damage — repair with a wrench before restarting."))
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
//   fuel starts at FGEN_DEFAULT_FUEL, capped to max_fuel, and is seeded as real slotted cores.
// ============================================================

/// Ejects everything. Liquid variants vent/capture fuel via on_fuel_ejected(); discrete-unit
/// variants eject every physically-tracked core exactly as it is (full/partial/depleted) —
/// there's no separate untracked reserve to synthesize, so nothing here can create fuel.
/obj/machinery/f13/faction_generator/proc/_eject_all_fuel(mob/user)
	if(fuel <= 0)
		to_chat(user, span_notice("The fuel reservoir is already empty — nothing to eject."))
		return
	if(fuel_is_liquid)
		_syphon_fuel(user)
		return
	skip_next_depletion_spawn = TRUE  // manual eject already returns the fuel; don't also spawn a depleted casing
	var/ejected_count = inserted_cores ? inserted_cores.len : 0
	if(ejected_count)
		for(var/obj/item/core in inserted_cores)
			core.forceMove(drop_location())
		inserted_cores.Cut()
	fuel = 0
	if(powered)
		set_power_state(FALSE)
	if(ejected_count > 0)
		to_chat(user, span_notice("Fuel purged: [ejected_count] [fuel_unit_name][ejected_count != 1 ? "s" : ""] ejected."))
	else
		to_chat(user, span_notice("Fuel reservoir vented."))

/// Gradual liquid-fuel siphon — drains a fixed amount per pump cycle instead of dumping the
/// whole tank instantly, mirroring how a real siphon/hand-pump works. Interruptible at any
/// point; whatever has already been pumped out stays out.
/obj/machinery/f13/faction_generator/proc/_syphon_fuel(mob/user)
	if(is_syphoning)
		return
	is_syphoning = TRUE
	skip_next_depletion_spawn = TRUE  // manual drain already returns the fuel; don't also spawn a depleted casing
	if(powered)
		set_power_state(FALSE)
	user.visible_message(span_notice("[user] starts siphoning [src]'s tank."), span_notice("You start siphoning [src]'s tank."))
	var/total_drained = 0
	var/total_captured = 0
	while(fuel > 0)
		if(!do_after(user, GENERATOR_SYPHON_CYCLE_TIME, target = src))
			break
		if(QDELETED(src) || fuel <= 0)
			break
		var/amount = min(GENERATOR_SYPHON_RATE, fuel)
		fuel -= amount
		total_drained += amount
		total_captured += on_fuel_ejected(user, amount)
	is_syphoning = FALSE
	if(total_drained <= 0)
		return
	var/spilled = total_drained - total_captured
	if(spilled > 0)
		to_chat(user, span_warning("You siphon [round(total_drained)] L from [src] — [round(total_captured)] L is captured, [round(spilled)] L spills across the floor. Keep ignition sources away."))
	else
		to_chat(user, span_notice("You siphon [round(total_drained)] L from [src] into your container."))

/// Called once per siphon cycle after `amount` litres have been drained from the tank.
/// Override in subtypes for type-specific behaviour (e.g. collecting liquid fuel in a held
/// container). Returns how much of `amount` was actually captured — the rest is lost/spilled.
/// Discrete-unit generators never call this — their fuel is always ejected directly as real
/// cores above.
/obj/machinery/f13/faction_generator/proc/on_fuel_ejected(mob/user, amount)
	return 0

/// Liquid diesel siphon — checks the other hand for a container to catch fuel each cycle;
/// anything that doesn't fit (or if no container is present) spills on the floor.
/obj/machinery/f13/faction_generator/diesel/on_fuel_ejected(mob/user, amount)
	var/captured = 0
	var/obj/item/reagent_containers/can = null
	if(isliving(user))
		var/mob/living/L = user
		var/obj/item/other = L.get_inactive_held_item()
		if(istype(other, /obj/item/reagent_containers))
			can = other
	if(can && can.reagents)
		var/space = can.reagents.maximum_volume - can.reagents.total_volume
		captured = min(round(amount), space)
		if(captured > 0)
			can.reagents.add_reagent(/datum/reagent/fuel, captured)
	var/overflow = amount - captured
	if(overflow > 0)
		var/turf/T = get_turf(src)
		if(T && !locate(/obj/effect/decal/cleanable/oil) in T)
			new /obj/effect/decal/cleanable/oil/slippery(T)
	return captured


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
	else if(overloaded && !_is_over_budget())
		overloaded = FALSE
		set_power_state(TRUE)
	return TRUE

/// Explicit "fusion core" named variant of the base generator.
/// Mapper-placed generators that want to make clear they use fusion cores.
/obj/machinery/f13/faction_generator/fusion
	icon       = 'icons/machines/power_grid/faction_generator.dmi'
	icon_state = "generator_off"
	name = "fusion core generator"
	desc = "A pre-War Vault-Tec integrated power plant. High-yield magnetic containment feeds up to two RobCo fusion cores simultaneously. Expensive to operate, but nothing in the wasteland matches its output-to-weight ratio."

/obj/machinery/f13/faction_generator/fusion/update_icon_state()
	icon_state = powered ? "generator_cycle" : "generator_off"


/// Common post-War diesel generator.  Fuelled by pouring liquid diesel from a jerrycan.
/// Burns at a flat 750 W as long as there is fuel in the tank.
/obj/machinery/f13/faction_generator/diesel
	icon = 'icons/machines/power.dmi'
	icon_state = "diesel-off"
	name = "diesel generator"
	desc = "A battered pre-War industrial diesel unit — the kind that kept factories running before the war, and keeps settlements alive after it. Loud, thirsty, and mercifully common out here. Feed it diesel straight from a jerrycan to keep it running."
	accepted_fuel_path   = null   // liquid-fuel pathway — uses try_liquid_refuel() instead
	depleted_fuel_path   = null   // liquid fuel has no physical casing to eject
	fuel_is_liquid       = TRUE
	fuel_per_unit        = 1      // 1 tick per litre (for residual unit calculations)
	watts_per_fuel_unit  = 750    // flat output — diesel can't match fusion
	max_fuel             = 1800   // ~60 min fully loaded (~3.6 jerrycans)
	fuel                 = 1800   // round-start: full tank — ~60 min before a refuel is needed
	fuel_unit_name       = "L"
	heat_ignition_threshold = 7600  // ~2-3 welder applications to ignite the fuel tank
	wear_hazard_multiplier = 100  // baseline risk once badly worn
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
// "Vented" means the area itself is flagged outdoors (area.outdoors) — the same
// flag every other outdoor check in the codebase uses — not one specific turf type,
// so any open terrain counts. The generator's own tile also counts as vented if an
// adjacent tile opens onto an outdoor area (parked in a garage doorway still vents).
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
/obj/machinery/f13/faction_generator/proc/_is_turf_vented(turf/T, check_adjacent = FALSE)
	if(!T)
		return FALSE
	var/area/A = get_area(T)
	if(A && A.outdoors)
		return TRUE
	// No level above (top of the z-stack) or an open multiz gap above — exposed to open sky.
	var/turf/above = get_step_multiz(T, UP)
	if(!above || istype(above, /turf/open/transparent/openspace))
		return TRUE
	if(!check_adjacent)
		return FALSE
	for(var/dir in list(NORTH, SOUTH, EAST, WEST))
		var/turf/N = get_step(T, dir)
		if(!N)
			continue
		var/area/NA = get_area(N)
		if(NA && NA.outdoors)
			return TRUE
	return FALSE

/obj/machinery/f13/faction_generator/diesel/process()
	// Run the normal fuel/maintenance logic first.
	. = ..()
	// Only emit exhaust while actually running with fuel.
	if(!powered || fuel <= 0)
		co_exposure_map = null
		return
	// Check whether the generator itself is vented — exhaust disperses in open air.
	var/turf/own_turf = get_turf(src)
	if(!own_turf || _is_turf_vented(own_turf, TRUE))
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
		// Vented mob despite being near the generator — skip.
		var/turf/mob_turf = get_turf(H)
		if(mob_turf && _is_turf_vented(mob_turf))
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
	// Degrading fuel lines — the wear-check roll already decided this fires; a rare, real fire risk.
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
	fuel_per_unit        = 1800   // ~60 min per cell
	watts_per_fuel_unit  = 1500   // high output — atomic fission beats fusion cores
	max_fuel             = 1800   // single-cell chamber
	fuel_unit_name       = "fuel cell"
	heat_ignition_threshold = 15200  // ~4-5 welder applications to breach containment
	wear_hazard_multiplier = 60  // sealed, low-maintenance design — safer than diesel/wastelander

/obj/machinery/f13/faction_generator/atomic/update_icon_state()
	icon_state = powered ? "generator_uranium" : "generator_off"

/obj/machinery/f13/faction_generator/atomic/on_maintenance_hazard()
	// Ageing containment seals — the wear-check roll already decided this fires.
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
	icon = 'icons/machines/power.dmi'
	icon_state = "diesel-off"
	name = "jury-rigged generator"
	desc = "A rattling heap of salvaged parts: an old Chryslus engine block, hydraulic hose, and what might once have been a refrigerator compressor, held together with electrical tape and misplaced optimism. Pour diesel in, run your wiring close, and stand back. Powers lights and devices within 10 tiles; each relay post extends that range by another 10 tiles."
	accepted_fuel_path   = null   // liquid-fuel pathway — uses try_liquid_refuel() instead
	depleted_fuel_path   = null
	fuel_is_liquid       = TRUE
	fuel_per_unit        = 1
	watts_per_fuel_unit  = 500    // crude output — less than a proper industrial unit
	max_fuel             = 1800   // ~60 min fully loaded (~3.6 jerrycans)
	fuel                 = 200    // starts nearly empty — wasteland style
	fuel_unit_name       = "L"
	has_lock_upgrade     = FALSE  // no built-in access control; install a blank ID card to unlock
	wear_hazard_multiplier = 120  // worst build quality of all variants — riskiest once badly worn
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
	// Worst build quality of all variants — the wear-check roll already decided this fires.
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
	if(!own_turf || _is_turf_vented(own_turf, TRUE))
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
		if(mob_turf && _is_turf_vented(mob_turf))
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

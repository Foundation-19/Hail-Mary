// ============================================================
// POWER GRID — PHYSICAL CABLE WIRING SYSTEM
// ============================================================
//
// Replaces the old two-tap multitool buffer approach with a
// physical cable-path system that feels like actual SS13 wiring.
//
// HOW IT WORKS:
//   1. Player uses a cable coil on a power grid machine
//      (generator, fabricator, or relay).
//      → A "knot" cable node is auto-spawned on the machine's
//        turf so the player can start laying cable immediately.
//      → A directional indicator appears on each walkable
//        adjacent tile showing where to route the cable.
//      → The session is stored keyed to this player.
//
//   2. Player lays cable tiles normally from the machine across
//      the floor toward the destination machine.
//      (Standard cable coil click-on-floor behavior.)
//
//   3. Player uses a cable coil on the DESTINATION machine.
//      → System BFS-traverses cable tiles from source to dest.
//      → If a path exists: link is established.
//      → If not: player is told the path is incomplete.
//
//   4. Player re-clicks the SOURCE machine to cancel the session.
//
//   WIRECUTTERS on a machine: severs all grid connections from
//   that machine and removes its auto-spawned cable stub.
//
// CABLE PATH RULES:
//   - Any tile with /obj/structure/cable on it is traversable.
//   - The source machine gets an auto-spawned knot cable (d1=0)
//     so you can start laying immediately without pre-building.
//   - The destination does NOT need a pre-existing cable node;
//     the system finds the path to its turf directly.
//   - Max path length: F13_WIRE_MAX_PATH tiles.
//   Diagonal routing is allowed, same as diagonal walking: a diagonal step is only
//   permitted if at least one of its two flanking cardinal tiles is unblocked, so cable
//   can't be routed through the solid corner of two walls.
// ============================================================

/// Maximum cable routing distance between two power grid machines.
#define F13_WIRE_MAX_PATH 100

/// Lengths of cable consumed from the player's coil when a link is completed.
#define F13_WIRE_LINK_COST 2

// ── CABLE RUNS ──────────────────────────────────────────────────────────────
// A cable tile belongs to a RUN, named by /obj/structure/cable/var/f13_run_id.
// Adjacent cable tiles connect only if they share the same run id. Cable with no run id
// (all existing map cable) forms one shared legacy run, so old maps behave exactly as before.
// Tiles holding an F13 machine join every run that touches them: the machine is the junction.
// Mappers: set f13_run_id on the cable in the map editor. Players: laid cable is tagged
// automatically (see f13_run_for()).

/// Run id for cable a player lays: the run of their active wiring session, else a personal one.
/proc/f13_run_for(mob/living/user)
	if(!user)
		return null
	return GLOB.f13_wire_session_runs["[REF(user)]"] || "free_[REF(user)]"

/// All 8 movement directions cable may route through.
GLOBAL_LIST_INIT(f13_cable_dirs, list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

/// Returns TRUE if a diagonal step from T in the given dir isn't cutting through a solid
/// wall corner (i.e. at least one of the two flanking cardinal tiles is unblocked).
/// Always TRUE for pure cardinal directions.
/proc/f13_diagonal_open(turf/T, dir)
	if(!(dir & (dir - 1)))
		return TRUE
	var/turf/side1 = get_step(T, dir & (NORTH|SOUTH))
	var/turf/side2 = get_step(T, dir & (EAST|WEST))
	if(side1 && !is_blocked_turf(side1))
		return TRUE
	if(side2 && !is_blocked_turf(side2))
		return TRUE
	return FALSE

/// Runs a tile belongs to: the run id of every cable on it ("legacy" for cable with no id), plus
/// every run a machine on it has been wired through. A machine tile with no cable at all also
/// counts as "legacy" so map cable laid next to a generator/relay still finds it.
/proc/f13_tile_runs(turf/X)
	var/list/runs = list()
	var/has_cable = FALSE
	for(var/obj/structure/cable/C in X)
		has_cable = TRUE
		var/rid = C.f13_run_id ? C.f13_run_id : "legacy"
		if(!(rid in runs))
			runs += rid
	var/has_machine = FALSE
	for(var/obj/machinery/f13/M in X)
		has_machine = TRUE
		if(M.f13_wire_runs)
			for(var/rr in M.f13_wire_runs)
				if(!(rr in runs))
					runs += rr
	if(has_machine && !has_cable && !("legacy" in runs))
		runs += "legacy"
	return runs

/// TRUE if cable at turf T and cable at its neighbour N (N = get_step(T, dir)) form one connection:
/// N must hold cable, and the two tiles must share a run. A machine is the junction between runs
/// because it carries every run that was wired to it.
/proc/f13_cable_can_step(turf/T, turf/N, dir)
	if(!(locate(/obj/structure/cable) in N))
		return FALSE
	var/list/ta = f13_tile_runs(T)
	var/list/tb = f13_tile_runs(N)
	for(var/k in ta)
		if(k in tb)
			return TRUE
	return FALSE

/// Cable sprites only have icon_states for cardinal d1/d2 combos -- collapse any
/// diagonal get_dir() result down to one cardinal component so the auto-spawned
/// knot doesn't render as a broken/placeholder diagonal line.
/proc/f13_nearest_cardinal(dir)
	if(dir & NORTH)
		return NORTH
	if(dir & SOUTH)
		return SOUTH
	if(dir & EAST)
		return EAST
	if(dir & WEST)
		return WEST
	return dir

// Key: "[REF(mob)]" string  →  Value: WEAKREF(source_machine)
GLOBAL_LIST_EMPTY(f13_wire_sessions)

/// Key -> run id for that player's active wiring session. A machine's runs are named after the
/// machine, so resuming from the same machine later continues the same run.
GLOBAL_LIST_EMPTY(f13_wire_session_runs)

/// Runs this machine has been wired through (see f13_tile_runs). Map machines start with none.
/obj/machinery/f13/var/list/f13_wire_runs = null

/// Record that a run touches this machine.
/proc/f13_machine_add_run(obj/machinery/f13/M, run_id)
	if(!istype(M) || !run_id)
		return
	if(!M.f13_wire_runs)
		M.f13_wire_runs = list()
	if(!(run_id in M.f13_wire_runs))
		M.f13_wire_runs += run_id

/// Which run a cable tile belongs to. null = the shared legacy run (all pre-existing map cable).
/obj/structure/cable/var/f13_run_id = null

/// Key -> world.time the session was started. Sessions older than this many deciseconds are dead.
GLOBAL_LIST_EMPTY(f13_wire_session_times)
#define F13_WIRE_SESSION_TIMEOUT 3000

/// Drop every wire session that has outlived F13_WIRE_SESSION_TIMEOUT (logged-off / wandered-off
/// players would otherwise leave a session, and its direction indicators, behind forever).
/proc/f13_purge_stale_wire_sessions()
	for(var/key in GLOB.f13_wire_session_times)
		if(world.time - GLOB.f13_wire_session_times[key] > F13_WIRE_SESSION_TIMEOUT)
			GLOB.f13_wire_sessions -= key
			GLOB.f13_wire_session_times -= key
			GLOB.f13_wire_session_runs -= key


// ============================================================
// SESSION MANAGEMENT
// ============================================================

/// Start a cable routing session from machine_src for this player.
/// Auto-spawns a knot cable on the machine's turf, spawns direction
/// indicators on adjacent walkable tiles, and stores the session.
/proc/f13_start_wire_session(obj/machinery/machine_src, mob/living/user)
	// Cancel any existing session first.
	f13_cancel_wire_session(user)

	// Cable laid from this machine belongs to the machine's own run, so resuming later (or a
	// second player working from the same machine) continues the same run. Registered BEFORE the
	// knot spawns so the knot is tagged too (cable Initialize reads f13_run_for()).
	GLOB.f13_wire_session_runs["[REF(user)]"] = "m_[REF(machine_src)]"
	f13_machine_add_run(machine_src, "m_[REF(machine_src)]")

	// Auto-spawn a directional cable stub on the machine's turf pointing
	// toward the player, so it flows naturally toward where they're standing.
	var/turf/T = get_turf(machine_src)
	if(T && !T.get_cable_node())
		var/spawn_dir = get_dir(T, get_turf(user))
		if(!spawn_dir)  // player is on same tile — use their facing direction
			spawn_dir = user.dir
		new /obj/structure/cable(T, null, 0, f13_nearest_cardinal(spawn_dir))

	// Register the session.
	f13_purge_stale_wire_sessions()
	GLOB.f13_wire_sessions["[REF(user)]"] = WEAKREF(machine_src)
	GLOB.f13_wire_session_times["[REF(user)]"] = world.time

	to_chat(user, span_notice("Cable routing started at [machine_src.name]. Run cable from the node here to your destination, then click the destination machine to complete. Click [machine_src.name] again to cancel."))


/// Attempt to complete a wire connection at machine_dst for this player.
/// Returns the source machine if a valid cable path was found, null otherwise.
/// On success the session is cleared. On failure the session persists.
/proc/f13_try_complete_wire(obj/machinery/machine_dst, mob/living/user)
	f13_purge_stale_wire_sessions()
	var/datum/weakref/src_ref = GLOB.f13_wire_sessions["[REF(user)]"]
	if(!src_ref)
		return null

	var/obj/machinery/machine_src = src_ref.resolve()
	if(!machine_src || QDELETED(machine_src))
		GLOB.f13_wire_sessions -= "[REF(user)]"
		GLOB.f13_wire_session_times -= "[REF(user)]"
		GLOB.f13_wire_session_runs -= "[REF(user)]"
		return null

	// Player clicked the source machine again — treat as cancel.
	if(machine_src == machine_dst)
		f13_cancel_wire_session(user)
		to_chat(user, span_notice("Cable routing cancelled."))
		return null

	// Auto-spawn a destination knot too, same as the source got on session start —
	// this only caps off the final tile, it doesn't substitute for the run in between.
	var/turf/dst_turf = get_turf(machine_dst)
	if(dst_turf && !dst_turf.get_cable_node())
		var/spawn_dir = get_dir(dst_turf, get_turf(user))
		if(!spawn_dir)
			spawn_dir = user.dir
		new /obj/structure/cable(dst_turf, null, 0, f13_nearest_cardinal(spawn_dir))

	// The destination machine joins this session's run (a machine is the junction between runs).
	f13_machine_add_run(machine_dst, GLOB.f13_wire_session_runs["[REF(user)]"])

	// BFS path check from source turf to destination turf.
	var/turf/src_turf = get_turf(machine_src)
	if(!f13_cable_path_exists(src_turf, dst_turf))
		to_chat(user, span_warning("No complete cable path found between [machine_src.name] and [machine_dst.name]. Ensure the cable route is unbroken and runs all the way to this machine's tile."))
		return null

	// Path confirmed. Completing the link costs cable from the coil in the player's active hand
	// (the headers always said "consumes 2 cable", but nothing ever took it).
	var/obj/item/stack/cable_coil/link_coil = user.get_active_held_item()
	if(!istype(link_coil) || !link_coil.use(F13_WIRE_LINK_COST))
		to_chat(user, span_warning("You need at least [F13_WIRE_LINK_COST] lengths of cable in your hand to finish this connection."))
		return null

	// Clear session, return source.
	GLOB.f13_wire_sessions -= "[REF(user)]"
	GLOB.f13_wire_session_times -= "[REF(user)]"
	GLOB.f13_wire_session_runs -= "[REF(user)]"
	return machine_src


/// Cancel the routing session for a player.
/proc/f13_cancel_wire_session(mob/living/user)
	GLOB.f13_wire_sessions -= "[REF(user)]"
	GLOB.f13_wire_session_times -= "[REF(user)]"
	GLOB.f13_wire_session_runs -= "[REF(user)]"


// ============================================================
// BFS PATH FINDER
// ============================================================

/// Returns TRUE if a live F13 generator or relay is reachable within max_steps cable tiles of start.
/proc/f13_cable_is_live(turf/start, max_steps = 8)
	if(!start)
		return FALSE
	var/list/visited = list()
	visited[start] = TRUE
	var/list/frontier = list(start)
	var/steps = 0
	while(frontier.len && steps < max_steps)
		var/list/next_frontier = list()
		for(var/turf/T in frontier)
			for(var/obj/machinery/f13/faction_generator/G in T)
				if(!QDELETED(G) && G.powered)
					return TRUE
			for(var/obj/machinery/f13/power_relay/R in T)
				if(!QDELETED(R) && R.relay_powered)
					return TRUE
			for(var/dir in GLOB.f13_cable_dirs)
				if(!f13_diagonal_open(T, dir))
					continue
				var/turf/N = get_step(T, dir)
				if(!N || visited[N])
					continue
				if(f13_cable_can_step(T, N, dir))
					visited[N] = TRUE
					next_frontier += N
		frontier = next_frontier
		steps++
	return FALSE

/// Touching a live cable while laying wire shocks the player.
/// Fires on every new cable placed outside of map-load (player-placed tiles only).
/obj/structure/cable/Initialize(mapload, param_color, _d1, _d2)
	. = ..()
	// Player-laid cable joins the player's run (map cable keeps whatever f13_run_id the mapper set).
	if(!mapload && !f13_run_id && isliving(usr))
		f13_run_id = f13_run_for(usr)
	if(!mapload && isliving(usr))
		var/turf/T = get_turf(src)
		if(T && f13_cable_is_live(T))
			to_chat(usr, span_danger("You touch a live power cable — electricity surges through you!"))
			var/mob/living/L = usr
			L.electrocute_act(15, src, flags = SHOCK_NOGLOVES)

/obj/structure/cable/attackby(obj/item/W, mob/user, params)
	// Sample liveness BEFORE the parent handler runs: cutting deletes the cable, and a deleted
	// cable has no turf left to check (the old post-..() version could never fire).
	var/was_live = FALSE
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		was_live = f13_cable_is_live(get_turf(src))
	. = ..()
	if(was_live && QDELETED(src) && isliving(user))
		var/mob/living/L = user
		L.electrocute_act(25, src, flags = SHOCK_NOGLOVES)

/// ANY removal of a cable (wirecutters, explosion, deconstruction, admin) re-validates the grid.
/// Debounced so a blast that deletes dozens of tiles triggers one prune, not dozens.
/obj/structure/cable/Destroy()
	. = ..()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(f13_notify_cable_cut)), 20, TIMER_UNIQUE | TIMER_OVERRIDE)

/// Notify all F13 generators and relays that a cable was removed at turf T so they
/// can prune any logical connections that no longer have a physical cable path.
/proc/f13_notify_cable_cut(turf/T)
	// Each generator prunes its whole downstream tree (relays recurse), so one pass per
	// generator covers every link; no need to walk the relay registry separately.
	for(var/obj/machinery/f13/faction_generator/G in GLOB.f13_generators)
		if(!QDELETED(G))
			G._prune_dead_links()

/// Remove the first WEAKREF in /list/refs whose resolved value equals /obj/target.
/// Safe to call even if refs is null or target is not in the list.
/proc/f13_remove_upstream_ref(list/refs, obj/target)
	if(!refs || !target)
		return
	for(var/datum/weakref/W in refs)
		if(W.resolve() == target)
			refs -= W
			return

/// Trigger recalc_draw() on every live faction generator.
/// Cheap because there are very few generators per map.
/proc/f13_recalc_all_generators()
	for(var/obj/machinery/f13/faction_generator/G in GLOB.f13_generators)
		if(!QDELETED(G))
			G.recalc_draw()

/// Returns TRUE if a continuous cable path exists from start to end
/// within F13_WIRE_MAX_PATH steps, checking cardinal and (corner-guarded)
/// diagonal directions. A tile is traversable if it contains any
/// /obj/structure/cable. Both endpoints must already have cable laid on
/// them -- adjacency to the destination is not enough on its own, or two
/// nearby machines could "connect" off their auto-spawned knots alone
/// without an actual wire run between them.
/proc/f13_cable_path_exists(turf/start, turf/end, max_steps = F13_WIRE_MAX_PATH)
	if(!start || !end)
		return FALSE
	if(start == end)
		return TRUE

	// Both endpoints need real laid cable -- a complete physical run, not just proximity.
	if(!(locate(/obj/structure/cable) in start))
		return FALSE
	if(!(locate(/obj/structure/cable) in end))
		return FALSE

	var/list/visited = list()
	visited[start] = TRUE
	var/list/frontier = list(start)
	var/steps = 0

	while(frontier.len && steps < max_steps)
		var/list/next_frontier = list()
		for(var/turf/T in frontier)
			for(var/check_dir in GLOB.f13_cable_dirs)
				if(!f13_diagonal_open(T, check_dir))
					continue
				var/turf/N = get_step(T, check_dir)
				if(!N || visited[N])
					continue
				// Reached destination? (the last hop must connect like any other)
				if(N == end)
					if(f13_cable_can_step(T, N, check_dir))
						return TRUE
					continue
				// Only continue through tiles whose cable actually connects to this one.
				if(f13_cable_can_step(T, N, check_dir))
					visited[N] = TRUE
					// A machine is an endpoint, not a conductor: a run may not pass through another
					// F13 machine's tile, or a breaker box / relay on a chain could be tunnelled through.
					if(locate(/obj/machinery/f13) in N)
						continue
					next_frontier += N
		frontier = next_frontier
		steps++

	return FALSE

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
//   - Only cardinal directions are checked (no diagonal routing).
// ============================================================

/// Maximum cable routing distance between two power grid machines.
#define F13_WIRE_MAX_PATH 100

// Key: "[REF(mob)]" string  →  Value: WEAKREF(source_machine)
GLOBAL_LIST_EMPTY(f13_wire_sessions)


// ============================================================
// SESSION MANAGEMENT
// ============================================================

/// Start a cable routing session from machine_src for this player.
/// Auto-spawns a knot cable on the machine's turf, spawns direction
/// indicators on adjacent walkable tiles, and stores the session.
/proc/f13_start_wire_session(obj/machinery/machine_src, mob/living/user)
	// Cancel any existing session first.
	f13_cancel_wire_session(user)

	// Auto-spawn a directional cable stub on the machine's turf pointing
	// toward the player, so it flows naturally toward where they're standing.
	var/turf/T = get_turf(machine_src)
	if(T && !T.get_cable_node())
		var/spawn_dir = get_dir(T, get_turf(user))
		if(!spawn_dir)  // player is on same tile — use their facing direction
			spawn_dir = user.dir
		new /obj/structure/cable(T, null, 0, spawn_dir)

	// Register the session.
	GLOB.f13_wire_sessions["[REF(user)]"] = WEAKREF(machine_src)

	to_chat(user, span_notice("Cable routing started at [machine_src.name]. Run cable from the node here to your destination, then click the destination machine to complete. Click [machine_src.name] again to cancel."))


/// Attempt to complete a wire connection at machine_dst for this player.
/// Returns the source machine if a valid cable path was found, null otherwise.
/// On success the session is cleared. On failure the session persists.
/proc/f13_try_complete_wire(obj/machinery/machine_dst, mob/living/user)
	var/datum/weakref/src_ref = GLOB.f13_wire_sessions["[REF(user)]"]
	if(!src_ref)
		return null

	var/obj/machinery/machine_src = src_ref.resolve()
	if(!machine_src || QDELETED(machine_src))
		GLOB.f13_wire_sessions -= "[REF(user)]"
		return null

	// Player clicked the source machine again — treat as cancel.
	if(machine_src == machine_dst)
		f13_cancel_wire_session(user)
		to_chat(user, span_notice("Cable routing cancelled."))
		return null

	// BFS path check from source turf to destination turf.
	var/turf/src_turf = get_turf(machine_src)
	var/turf/dst_turf = get_turf(machine_dst)
	if(!f13_cable_path_exists(src_turf, dst_turf))
		to_chat(user, span_warning("No complete cable path found between [machine_src.name] and [machine_dst.name]. Ensure the cable route is unbroken and runs all the way to this machine's tile."))
		return null

	// Path confirmed — clear session, return source.
	GLOB.f13_wire_sessions -= "[REF(user)]"
	return machine_src


/// Cancel the routing session for a player.
/proc/f13_cancel_wire_session(mob/living/user)
	GLOB.f13_wire_sessions -= "[REF(user)]"


// ============================================================
// BFS PATH FINDER
// ============================================================

/// Returns TRUE if a continuous cable path exists from start to end
/// within F13_WIRE_MAX_PATH steps, checking only cardinal directions.
/// A tile is traversable if it contains any /obj/structure/cable.
/// The destination tile itself does not need to have cable — we check
/// if the BFS frontier can reach any tile cardinally adjacent to end,
/// OR if end itself has cable.
/proc/f13_cable_path_exists(turf/start, turf/end, max_steps = F13_WIRE_MAX_PATH)
	if(!start || !end)
		return FALSE
	if(start == end)
		return TRUE

	// The source tile must already have a cable (we auto-spawn it).
	if(!locate(/obj/structure/cable) in start)
		return FALSE

	var/list/visited = list(start)
	var/list/frontier = list(start)
	var/steps = 0

	while(frontier.len && steps < max_steps)
		var/list/next_frontier = list()
		for(var/turf/T in frontier)
			for(var/check_dir in list(NORTH, SOUTH, EAST, WEST))
				var/turf/N = get_step(T, check_dir)
				if(!N || (N in visited))
					continue
				// Reached destination?
				if(N == end)
					return TRUE
				// Only continue through tiles that have cable.
				if(locate(/obj/structure/cable) in N)
					visited += N
					next_frontier += N
		frontier = next_frontier
		steps++

	return FALSE

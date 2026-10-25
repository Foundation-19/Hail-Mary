// ============================================================
// ELECTRICAL JUNCTION BOX
// ============================================================
//
// The Fallout 13 equivalent of an APC.  Every indoor area that
// needs to be powered by the faction generator grid has one of
// these mounted on a wall.  It ties the building's internal
// wiring to the external generator-cable network.
//
// CONCEPT:
//   Wasteland buildings have pre-existing internal wiring
//   (lights, outlets, etc.) that's been dead for centuries.
//   The junction box is the breaker panel that bridges that
//   internal circuit to your generator's cable run.  Wire the
//   box into your grid and the whole structure lights up.
//
// COVERAGE — MULTI-ZONE FLOOD FILL:
//   At LateInitialize the box performs a depth-first search from
//   its own turf, recording the original area datum of every
//   reachable tile.  Turfs that share the same origin area type
//   are grouped together and each distinct group gets its own
//   private area datum (zone).  One junction box can therefore
//   own an arbitrary number of sub-zones — one per mapped area
//   subtype discovered within its physical envelope.
//
//   Example — BoS bunker with properly-mapped subtypes:
//     /area/f13/brotherhood          → zone "Brotherhood of Steel"  (hallways)
//     /area/f13/brotherhood/armory   → zone "BoS Armory"            (weapons room)
//     /area/f13/brotherhood/dorms    → zone "BoS Dormitory"         (barracks)
//
//   The UI exposes a per-zone breaker toggle for each of those
//   sections independently.  Cut the armory's power mid-raid
//   without killing the rest of the base.
//
//   Legacy maps (everything is one broad area type) produce
//   exactly one zone — behaviour is identical to before.
//
//   The flood fill stops at:
//     • Dense turfs (walls / closed airlocks — actors can open
//       doors, so doors are intentionally NOT barriers)
//     • Outdoor areas (outdoors = TRUE)
//     • Immune areas  (f13_grid_immune = TRUE)
//     • Turfs already claimed by another junction box
//     • Area type HIERARCHY boundary: any tile whose area is not
//       a subtype (or the same type) as the box's placement area
//       is treated as foreign territory and never crossed.
//       A box in /area/f13/brotherhood walks freely through
//       /area/f13/brotherhood/armory and /brotherhood/dorms but
//       stops the moment it reaches /area/f13/ncr or any other
//       unrelated branch — even through an open door.
//     • (Bridges, not stops: openspace gaps, stairs, and ladders all carry
//       the fill across to the connected z-level.)
//
//   BOUNDARY WALL ABSORPTION:
//   After interior zones are built a second pass scans every dense
//   tile (wall, pillar, etc.) directly adjacent to a claimed interior
//   tile.  Those wall tiles are absorbed into the bordering zone so
//   objects placed on them — wall-mounted lights, conduit, mounted
//   weapons, etc. — receive area power correctly.
//
//   The wall tile's ORIGINAL area (e.g. /area/f13/city for a shared
//   perimeter wall) is remembered separately and used on Destroy() to
//   repatriate it back to the correct singleton, not the interior zone's
//   origin.  The junction box never permanently steals foreign tile
//   ownership.
//
//   On Destroy every zone's turfs are repatriated to their
//   original singleton area so the world always retains full
//   area coverage.
//
//   Use powered_area_types to bypass flood-fill entirely and
//   stamp specific named areas (legacy explicit-list path).
//
// WIRING (same as all other grid machines):
//   1. Start a wire session on the upstream node (generator
//      or relay) by clicking it with a cable coil.
//   2. Click this junction box with the same coil to complete.
//      Two cable lengths are consumed.
//   Wirecutters on the box severs the upstream connection.
//
// ROUND-START AUTO-WIRE:
//   Set map_client_tags on the faction_generator (or relay) to
//   a comma-separated list of junction box .tag values.  They
//   will be linked automatically at game start, no player
//   action required.
//
// WATT DRAW:
//   grid_watt_draw = grid_watt_draw_base (once per box) plus grid_watt_draw_per_tile
//   multiplied by the total tile count across every zone this box claims, so a
//   sprawling multi-room building costs more than a closet automatically.
//   Override grid_watt_draw_per_tile on subtypes to change the per-tile rate.
//
// MANUAL BREAKERS:
//   The UI presents a master breaker (cuts the whole building)
//   and an individual breaker per zone (cut one section).
//   Zone breakers are reset to CLOSED whenever the master
//   breaker closes, so restoring grid power always brings
//   everything back unless the player re-trips them.
// ============================================================

/obj/machinery/f13/junction_box
	parent_type   = /obj/machinery/f13/grid_client
	name          = "electrical junction box"
	desc          = "A breaker panel that connects a building's internal wiring to the external generator grid. Wire it to a generator or relay to restore power to the structure."
	icon          = 'icons/machines/power_grid/junction_box.dmi'
	icon_state    = ""
	density       = FALSE   // Wall-mounted — doesn't block movement.
	anchored      = TRUE
	max_integrity = 200
	armor         = list(melee = 5, bullet = 5, laser = 5, energy = 5, bomb = 20, bio = 0, rad = 0, fire = 10, acid = 5)

	// Watt draw = grid_watt_draw_base + (grid_watt_draw_per_tile × total claimed tiles).
	// grid_watt_draw only holds the base estimate until LateInitialize resolves zones/tiles.
	grid_watt_draw = JUNCTION_BOX_WATT_DRAW_BASE
	// A building's internal circuit is a mix of resistive (lights, heaters) and
	// inductive (motors, pumps, compressors) loads — a blended 0.92 is typical.
	power_factor = 0.92
	/// Watt cost per tile across every claimed zone.  Summed at LateInitialize; override on subtypes.
	var/grid_watt_draw_per_tile = JUNCTION_BOX_WATT_PER_TILE
	/// Fixed overhead watt cost, independent of zone count.  Override on subtypes.
	var/grid_watt_draw_base = JUNCTION_BOX_WATT_DRAW_BASE
	/// Light reach (tiles) used when the box is placed in an outdoor area (e.g. wasteland).
	/// Lights within this distance receive seton()/setoff() individually instead of a
	/// whole-map F13_STAMP_AREA_POWER call on the shared area datum.  Override on subtypes.
	var/power_reach = 10
	/// Area type this box was originally placed in, captured in Initialize() before any
	/// flood-fill zone reassignment can happen.  Every junction box in the world finishes
	/// Initialize() before ANY of them run LateInitialize()/flood-fill, so this lets a box
	/// deterministically know about every sibling box's home area regardless of which one's
	/// LateInitialize() actually runs first — fixes parent/child area boxes racing for tiles.
	var/home_area_type = null

	// ── Area ownership ──────────────────────────────────────
	/// Optional mapper override: explicit list of area type paths this box controls.
	/// When set, flood-fill is skipped entirely and these area datums are stamped
	/// directly (legacy explicit-list behaviour).  Only needed when a mapper
	/// intentionally wants one panel to serve multiple named areas simultaneously.
	var/list/powered_area_types = null
	/// Resolved area datum instances — only populated when powered_area_types is set.
	var/list/powered_area_instances = null

	/// Flood-fill zone registry.  Assoc: /area/f13 zone datum → /area original singleton.
	/// One entry per distinct area subtype discovered during the flood fill.
	/// Null when using the legacy powered_area_types path.
	var/list/owned_zones = null
	/// Scratch: areas (by datum) that another bolted box sits in; filled by build_zones().
	var/list/_other_box_areas = null
	/// Wall-tile origin registry.  Assoc: turf → /area original singleton.
	/// Wall tiles bordering interior zones are absorbed so objects on them
	/// (wall lights, etc.) receive area power.  Their real origin area may
	/// differ from the interior zone (e.g. a city-mapped perimeter wall).
	/// Used by Destroy() to repatriate each wall tile to its correct singleton.

	// ── Breaker state ───────────────────────────────────────
	/// Master breaker.  When FALSE the whole box is off even if the grid is live.
	/// Closing the master breaker also resets all zone breakers to CLOSED.
	var/breaker_closed = TRUE
	/// Per-zone breaker states.  Assoc: zone datum → TRUE (closed) / FALSE (tripped).
	/// Populated alongside owned_zones.  Ignored when using powered_area_types path.
	var/list/zone_breakers = null
	/// Assoc: zone datum -> real turf count, taken once when the zone is built. area.contents also
	/// holds every object and mob on those turfs, so contents.len made the load swing with clutter.
	var/list/zone_tile_counts = null


/// A tripped master breaker draws nothing from upstream — none of the building's
/// zones are being energised. With the master closed, only zones whose own
/// breaker is still closed count toward the load; a tripped zone stops costing
/// the grid anything, same as physically disconnecting it.
/obj/machinery/f13/junction_box/get_effective_watt_draw()
	if(!breaker_closed)
		return 0
	if(!zone_breakers || !zone_breakers.len)
		return grid_watt_draw  // legacy powered_area_types path — no per-zone breakers
	var/live_draw = grid_watt_draw_base
	for(var/area/f13/Z in zone_breakers)
		if(zone_breakers[Z])
			live_draw += _zone_watt_cost(Z)
	return live_draw

/// Watt cost of a single claimed zone: purely proportional to its tile count, so a
/// sprawling zone costs more than a closet-sized one and a tiny zone costs almost nothing.
/obj/machinery/f13/junction_box/proc/_zone_watt_cost(area/Z)
	return grid_watt_draw_per_tile * _zone_tiles(Z)

/// Real tile (turf) count for a claimed zone. Cached at build time; recounts if the cache is missing.
/obj/machinery/f13/junction_box/proc/_zone_tiles(area/Z)
	if(zone_tile_counts && !isnull(zone_tile_counts[Z]))
		return zone_tile_counts[Z]
	var/n = 0
	for(var/turf/T in Z)
		n++
	return n


/// Returns TRUE if the given area should never be stamped by a junction box.
/// Only areas with f13_grid_immune explicitly set are permanently blocked.
/// Outdoor areas CAN be powered — the wasteland generator is designed for this.
/obj/machinery/f13/junction_box/proc/_area_is_immune(area/A)
	var/area/f13/farea = A
	if(istype(farea) && farea.f13_grid_immune)
		return TRUE
	return FALSE

/// Shared validity/push check used by every z-level bridge (openspace, stairs, ladders):
/// skips already-visited turfs, turfs with no area, immune areas, areas outside the
/// flood's root type tree, and areas reserved for a different junction box.
/obj/machinery/f13/junction_box/proc/_flood_try_push(turf/candidate, list/visited, list/stack, area/start, root_type, list/reserved_types)
	if(!candidate || visited[candidate])
		return
	var/area/c_area = get_area(candidate)
	if(!c_area || _area_is_immune(c_area))
		return
	var/area/f13/fC = c_area
	var/area/check_c = (istype(fC) && fC.f13_jbox_zone) ? start : c_area
	if(!istype(check_c, root_type))
		return
	if(reserved_types && reserved_types.len && (check_c.type in reserved_types))
		return
	stack += candidate


/// Resolves the area to use as the flood-fill root.
/// If the box's own turf is dense (wall-mounted), its area is often whatever
/// broad area the wall material belongs to, not the specific room the box is
/// meant to serve.  In that case, fall back to the first adjacent walkable
/// (non-dense) turf's area instead, so a box gives identical results whether
/// it's placed on the wall or on the room's floor.
/obj/machinery/f13/junction_box/proc/_resolve_root_area()
	var/turf/T = get_turf(src)
	if(!T)
		return null
	if(!T.density)
		return get_area(T)
	for(var/dir in list(NORTH, SOUTH, EAST, WEST))
		var/turf/N = get_step(T, dir)
		if(N && !N.density)
			var/area/na = get_area(N)
			if(na)
				return na
	// No walkable neighbour found — fall back to our own (wall) area.
	return get_area(T)

/// Is A inside the territory this flood fill is allowed to walk?
/// Runtime-made (f13_custom) areas all share one typepath, so they are matched by exact
/// datum: a box inside one custom room never crosses into another custom room or into a
/// mapped area, and a box in a mapped area never leaks into a custom room.
/// Everything else is matched by area type tree (root_type and its subtypes).
/obj/machinery/f13/junction_box/proc/_area_in_scope(area/A, root_type, area/custom_root)
	var/area/f13/fA = A
	if(istype(fA) && fA.f13_custom)
		// Walk up the carve-out chain (create_area sets f13_parent_area), so a room split
		// off a box's area is still in that box's scope.
		// A carved-out room (or any room between it and us) that has its own bolted
		// junction box belongs to that box, not to the box covering the parent room.
		var/area/f13/cur = fA
		var/blocked = FALSE
		for(var/i in 1 to 8)
			if(!cur || QDELETED(cur))
				break
			if(custom_root)
				if(cur == custom_root)
					return !blocked
			else if(!cur.f13_custom && istype(cur, root_type))
				return !blocked
			if(_other_box_areas && _other_box_areas[cur])
				blocked = TRUE
			cur = cur.f13_parent_area
		return FALSE
	if(custom_root)
		return FALSE
	return istype(A, root_type)

// ============================================================
// LIFE CYCLE
// ============================================================

/obj/machinery/f13/junction_box/Initialize()
	// Zone creation is deferred to LateInitialize() so all turfs
	// and area datums are fully settled before we read or reassign them.
	// INITIALIZE_HINT_LATELOAD ensures LateInitialize() is scheduled even
	// for boxes spawned mid-round (e.g. admin-spawned or crafted in-game).
	. = ..()
	// Captured now (before any flood-fill anywhere in the world can run) so
	// ownership resolution is independent of LateInitialize() firing order.
	// Must use _resolve_root_area() here, NOT get_area(src) directly — this has
	// to match whatever LateInitialize() will actually use as its flood-fill
	// root, or a wall-mounted box's real (floor-resolved) territory wouldn't be
	// reserved correctly against other boxes.
	var/area/home = _resolve_root_area()
	home_area_type = home ? home.type : null
	GLOB.f13_jboxes += src
	return INITIALIZE_HINT_LATELOAD

// ============================================================
// WRENCH — ANCHOR / WALL MOUNT
// ============================================================
// Crafted boxes spawn unanchored (see crafting_recipes.dm) so they can be carried
// to the install site. Wrenching an unanchored box bolts it down; if it's sitting
// against a wall it mounts flush to that wall (offset sprite, same tile — same
// trick /obj/machinery/power/apc uses) instead of sitting in the middle of the
// floor. Wrenching an anchored box frees it again so it can be moved.
/obj/machinery/f13/junction_box/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(anchored)
			// Pulling a live box off its feed arcs, same as wiring a live relay does.
			// An open master breaker isolates the box, so that's the safe way to unbolt it.
			var/was_live = grid_powered && breaker_closed
			if(was_live && isliving(user))
				to_chat(user, span_danger("You unbolt [src] while it's still live — electricity arcs across your hand!"))
				var/mob/living/UL = user
				UL.electrocute_act(20, src, flags = SHOCK_NOGLOVES)
			// Release claimed territory before the box can be carried off.
			teardown_zones()
			// Unbolting pulls it off its cable run: drop the upstream link so it can't
			// keep drawing power from wherever it used to be wired.
			_sever_upstream()
			anchored = FALSE
			setDir(SOUTH)
			pixel_x = 0
			pixel_y = 0
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			to_chat(user, span_notice("You unbolt [src] — it can be moved again."))
		else
			var/turf/T = get_turf(src)
			// wall_dir = direction FROM the box TOWARD the wall (APC convention).
			// Collect every adjacent wall; only a corner/corridor is ambiguous.
			var/list/wall_dirs = list()
			for(var/d in GLOB.cardinals)
				var/turf/N = get_step(T, d)
				if(N && N.density)
					wall_dirs += d
			var/wall_dir = 0
			if(wall_dirs.len == 1)
				wall_dir = wall_dirs[1]
			else if(wall_dirs.len > 1)
				// Narrow by where the installer is: standing across the box from a wall
				// (or facing it) means that's the wall they want.
				var/list/preferred = list()
				var/user_dir = get_dir(user, src)
				if((user_dir in wall_dirs))
					preferred += user_dir
				else if((user.dir in wall_dirs) && get_dist(user, src) <= 1)
					preferred += user.dir
				if(preferred.len == 1)
					wall_dir = preferred[1]
				else
					// Still ambiguous (corner, or standing diagonally): just ask.
					var/list/choices = list()
					for(var/d in wall_dirs)
						choices["[dir2text(d)] wall"] = d
					var/pick = input(user, "Which wall should [src] be mounted on?", "Mount Junction Box") as null|anything in choices
					if(!pick || !user.Adjacent(src))
						return
					wall_dir = choices[pick]
			anchored = TRUE
			if(wall_dir)
				// Face into the room. If the sprite looks wrong, change to setDir(wall_dir)
				// (APC itself just uses setDir(SOUTH) and offsets the pixels).
				setDir(turn(wall_dir, 180))
				switch(wall_dir)
					if(NORTH)
						pixel_x = 0
						pixel_y = 28
					if(SOUTH)
						pixel_x = 0
						pixel_y = -28
					if(EAST)
						pixel_y = 0
						pixel_x = 28
					if(WEST)
						pixel_y = 0
						pixel_x = -28
				to_chat(user, span_notice("You bolt [src] flush to the wall."))
			else
				pixel_x = 0
				pixel_y = 0
				to_chat(user, span_notice("You bolt [src] to the floor."))
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			// If another box has claimed this room's tiles, make it let go first so the
			// box that is physically inside the room can take it over.
			var/area/f13/claimed_here = get_area(src)
			if(istype(claimed_here) && claimed_here.f13_jbox_zone)
				var/list/hand_over = list()
				hand_over[claimed_here] = TRUE
				f13_rescan_boxes_for_areas(hand_over)
			// Now that the box is in its final spot, claim the room it's actually in
			// (a box crafted elsewhere has no territory until it's bolted down here).
			rebuild_zones()
			update_icon()
		return
	return ..()


/obj/machinery/f13/junction_box/LateInitialize()
	. = ..()
	build_zones()

/// Claims territory (legacy list / outdoor carve-out / flood fill) and stamps it.
/// Split out of LateInitialize() so it can be re-run: a box crafted elsewhere and
/// bolted down mid-round, or a room repainted with area_edit, rebuilds its zones.
/// Does nothing while the box is unbolted — a loose box owns no territory.
/obj/machinery/f13/junction_box/proc/build_zones()
	if(!anchored)
		return
	if(powered_area_types && powered_area_types.len)
		// ── Legacy explicit-area path ───────────────────────────────────
		// Resolve type paths to live datums; skip flood fill entirely.
		powered_area_instances = list()
		for(var/atype in powered_area_types)
			var/area/A = locate(atype) in world
			if(A && !QDELETED(A) && !_area_is_immune(A))
				powered_area_instances += A
		if(!(grid_powered && breaker_closed))
			spawn(4)
				if(!QDELETED(src) && !grid_powered)
					_stamp_areas(FALSE)
		return

	// ── Outdoor area shortpath ─────────────────────────────────────────────
	// Outdoor areas (wasteland, open ground, etc.) must never be flood-filled:
	// the fill would traverse thousands of turfs and stall the server.
	// Instead, claim the generator's current area directly — same as if the
	// mapper had set powered_area_types = list(<area.type>).
	//
	// If the box itself sits on a dense (wall-mounted) turf, its own area may
	// be whatever broad area the wall material was assigned to (often a big
	// shared perimeter/hallway area), NOT the specific room it's meant to
	// serve — flood-filling from that root would claim far more than the same
	// box placed on the room's floor.  Resolve to an adjacent walkable turf's
	// area instead so root selection is consistent regardless of which exact
	// tile (wall or floor) the box was placed on.
	var/area/here = _resolve_root_area()
	if(!here)
		return
	if(_area_is_immune(here))
		return
	if(here.outdoors)
		// "here" is a shared outdoor area singleton that can span huge stretches of the
		// map — stamping or costing it directly would affect (and bill for) every tile of
		// that area type on the whole map. Instead, carve the tiles within power_reach out
		// into a private zone (same trick the indoor flood-fill path uses below), so this
		// box's power state and wattage only ever apply to its own local footprint. Every
		// machine on those tiles then gets powered through the normal power_change() flow
		// (correct icons/overlays), instead of us hand-toggling stat bits per-machine.
		var/area/f13/Z = new here.type()
		Z.f13_jbox_zone = TRUE
		Z.f13_origin = here
		GLOB.sortedAreas -= Z
		var/local_tiles = 0
		for(var/turf/T in RANGE_TURFS(power_reach, src))
			if(get_area(T) != here)
				continue
			here.contents -= T
			Z.contents += T
			local_tiles++
		powered_area_instances = list(Z)
		// NOTE: list(Z = here) would key the list by the TEXT "Z", not the zone datum, so
		// teardown could never find the zone and the carved tiles would never be handed back.
		owned_zones = list()
		owned_zones[Z] = here  // so teardown repatriates these tiles like any other zone
		grid_watt_draw = grid_watt_draw_base + (grid_watt_draw_per_tile * local_tiles)
		if(grid_powered && breaker_closed)
			_stamp_areas(TRUE)
		else
			spawn(4)
				if(!QDELETED(src) && !grid_powered)
					_stamp_areas(FALSE)
		return

	// ── Flood-fill / multi-zone path ────────────────────────────────────────
	// Walk every physically-connected turf within the same area hierarchy.
	// Pass here.type as the root so the fill respects the type boundary.
	//
	// Also collect every OTHER junction box's home area type in the world.
	// A neighbouring turf whose original area matches another box's home type
	// is off-limits — that area belongs to its own dedicated box — regardless
	// of whether that box has run its own LateInitialize()/flood-fill yet.
	// (home_area_type is set in Initialize(), and every object's Initialize()
	// finishes before any LateInitialize() runs, so this is always safe to read.)
	var/list/reserved_home_types = list()
	for(var/obj/machinery/f13/junction_box/JB in GLOB.machines)
		// Loose (unbolted) boxes own nothing, and their home_area_type is just wherever
		// they happened to be crafted/dropped - never let that block another box's fill.
		if(JB == src || QDELETED(JB) || !JB.home_area_type || !JB.anchored)
			continue
		if(JB.home_area_type == here.type)
			continue  // shares our exact home type — ambiguous, don't self-exclude
		reserved_home_types += JB.home_area_type

	// Which areas already have their own bolted box? (see _area_in_scope)
	_other_box_areas = list()
	for(var/obj/machinery/f13/junction_box/OB in GLOB.f13_jboxes)
		if(OB == src || QDELETED(OB) || !OB.anchored)
			continue
		var/area/oa = OB._resolve_root_area()
		var/area/f13/ofa = oa
		if(istype(ofa) && ofa.f13_jbox_zone && ofa.f13_origin)
			oa = ofa.f13_origin
		if(oa)
			_other_box_areas[oa] = TRUE

	// Runtime-made (area_edit) rooms all share one typepath, so scope the fill to this
	// exact area datum instead of the type tree.
	var/area/f13/fhere = here
	var/area/custom_root = (istype(fhere) && fhere.f13_custom) ? here : null
	if(custom_root && fhere.f13_jbox_zone)
		// This box sits inside a room another junction box has already claimed.
		// Leave it alone instead of stealing tiles back from that box's zone.
		return
	var/list/turf_map = _flood_fill_turfs(here.type, reserved_home_types, custom_root)
	if(!turf_map || !turf_map.len)
		return

	// ── Group turfs by their original area ───────────────────────────────
	// type_to_zone: grouping key → private zone datum  (used during grouping)
	// type_to_origin: grouping key → original singleton datum  (for repatriation)
	// The key is the area TYPE PATH for mapped areas, but the area DATUM itself for
	// custom areas (they share one typepath, so type alone would merge separate rooms).
	var/list/type_to_zone   = list()
	var/list/type_to_origin = list()

	for(var/turf/T in turf_map)
		var/area/orig = turf_map[T]          // original singleton this turf came from
		if(!istype(orig, /area))             // safety net — every visited turf should carry a real area now
			continue
		var/area/f13/forig = orig
		var/atype = (istype(forig) && forig.f13_custom) ? orig : orig.type

		if(!type_to_zone[atype])
			// First turf of this kind — spawn a private zone datum.
			var/area/f13/Z = new orig.type()
			if(istype(forig) && forig.f13_custom)
				Z.name         = orig.name  // keep the player-chosen name in the UI
			Z.f13_jbox_zone    = TRUE
			Z.f13_origin       = forig
			GLOB.sortedAreas   -= Z  // Keep zone datums out of the global area registry
			type_to_zone[atype]   = Z
			type_to_origin[atype] = orig

		// Move this turf into the private zone.
		var/area/f13/zone = type_to_zone[atype]
		var/area/old_area = get_area(T)
		if(!QDELETED(old_area) && old_area != zone)
			old_area.contents -= T
			zone.contents     += T

	// ── Build owned_zones / zone_breakers registries ─────────────────────
	owned_zones   = list()
	zone_breakers = list()
	for(var/atype in type_to_zone)
		var/area/f13/Z   = type_to_zone[atype]
		var/area/orig    = type_to_origin[atype]
		owned_zones[Z]   = orig
		zone_breakers[Z] = TRUE    // all sub-breakers start closed

	// Count each zone's real turfs once.
	zone_tile_counts = list()
	for(var/area/f13/ZC in owned_zones)
		var/tile_n = 0
		for(var/turf/CT in ZC)
			tile_n++
		zone_tile_counts[ZC] = tile_n

	// Update watt draw: fixed box overhead plus every claimed zone's tile-scaled cost.
	grid_watt_draw = grid_watt_draw_base
	for(var/area/f13/Z in owned_zones)
		grid_watt_draw += _zone_watt_cost(Z)

	// ── Re-stamp if grid was already live before LateInitialize ran ───────
	// If the box was wired before LateInitialize() fired (possible when
	// spawning mid-round), on_grid_power_change(TRUE) ran while owned_zones
	// was still null and did nothing.  Stamp now so areas light up.
	if(grid_powered && breaker_closed)
		_stamp_areas(TRUE)
	else
		spawn(4)
			if(!QDELETED(src) && !grid_powered)
				_stamp_areas(FALSE)


/// Depth-first walk from the junction box's turf.
/// root_type — the area type the box is placed in; only tiles whose area is
/// a subtype (or the exact type) of root_type will be visited.
/// reserved_types — optional list of area type paths that belong to OTHER
/// junction boxes' home areas; the fill will never cross into a turf whose
/// original area matches one of these, regardless of claim/init order.
/// Returns an assoc list: turf → original area datum it belonged to at walk time.
/// custom_root — when the box sits in a runtime-made (f13_custom) area, the exact area
/// datum to stay inside (see _area_in_scope); null for normal mapped areas.
/obj/machinery/f13/junction_box/proc/_flood_fill_turfs(root_type, list/reserved_types, area/custom_root)
	var/list/visited = list()   // turf → original area datum
	var/turf/start_turf = get_turf(src)
	var/list/stack   = list(start_turf)
	var/area/start   = get_area(src)
	if(custom_root)
		// A wall-mounted box sits on a dense turf that belongs to whatever area the wall
		// was painted into, not the room it serves.  Seed from the walkable neighbours
		// instead so the wall tile never becomes a stray one-tile zone.
		start = custom_root
		if(start_turf && start_turf.density)
			stack = list()
			for(var/seed_dir in list(NORTH, SOUTH, EAST, WEST))
				var/turf/seed = get_step(start_turf, seed_dir)
				if(seed && !seed.density)
					stack += seed
	while(stack.len)
		var/turf/T = stack[stack.len]
		stack.len--
		if(visited[T])
			continue
		var/area/T_area = get_area(T)
		if(!T_area)
			continue
		if(custom_root && T_area != custom_root)
			continue
		// Record the ORIGINAL area — before any zone datum could overwrite it.
		// If T already sits in a jbox zone from a prior Initialize run,
		// attribute it to our start area so grouping handles it correctly.
		var/area/f13/fT = T_area
		var/area/origin = (istype(fT) && fT.f13_jbox_zone) ? start : T_area
		// ── Openspace bridge (main-loop) ─────────────────────────────────
		// Openspace tiles are z-transparent "holes" between floors, but they can
		// still carry equipment (e.g. a light fixture built on a catwalk over the
		// hole) — claim the tile itself into the zone too, then bridge DOWN.
		if(istype(T, /turf/open/transparent/openspace))
			visited[T] = origin
			var/turf/os_below = get_step_multiz(T, DOWN)
			if(os_below && !visited[os_below])
				var/area/ob_area = get_area(os_below)
				if(ob_area && !_area_is_immune(ob_area))
					var/area/f13/fob = ob_area
					var/check_ob = (istype(fob) && fob.f13_jbox_zone) ? start : ob_area
					if(_area_in_scope(check_ob, root_type, custom_root))
						stack += os_below
			continue
		visited[T] = origin
		for(var/dir in list(NORTH, SOUTH, EAST, WEST))
			var/turf/N = get_step(T, dir)
			if(!N || visited[N])
				continue
			// Physical barrier — walls, etc.
			if(N.density)
				continue
			var/area/N_area = get_area(N)
			if(!N_area)
				continue
			// ── Openspace bridge (NSEW) ──────────────────────────────────
			// Openspace is a z-transparent hole — queue it so the main loop claims
			// the tile itself (equipment built on it still needs zone power), then
			// also push the tile below it.
			if(istype(N, /turf/open/transparent/openspace))
				_flood_try_push(N, visited, stack, start, root_type, reserved_types)
				var/turf/ns_below = get_step_multiz(N, DOWN)
				if(ns_below && !visited[ns_below])
					var/area/nb_area = get_area(ns_below)
					if(nb_area && !_area_is_immune(nb_area))
						var/area/f13/fnb = nb_area
						var/check_nb = (istype(fnb) && fnb.f13_jbox_zone) ? start : nb_area
						if(_area_in_scope(check_nb, root_type, custom_root))
							stack += ns_below
				continue
			// Outdoor or explicitly immune — never cross.
			if(_area_is_immune(N_area))
				continue
			// ── Hierarchy boundary ──────────────────────────────────────
			// Only cross tiles that belong to the same area type-tree as
			// this box's root.  istype() returns TRUE for the exact type
			// AND all subtypes, so brotherhood/armory passes when the
			// root is brotherhood, but ncr or any other branch does not.
			// We must resolve through any existing jbox zone datum to
			// get the real underlying type for the check.
			var/area/f13/fN = N_area
			var/area/check_area = (istype(fN) && fN.f13_jbox_zone) ? start : N_area
			if(!_area_in_scope(check_area, root_type, custom_root))
				continue
			// Already claimed by a different junction box — respect its boundary.
			if(istype(fN) && fN.f13_jbox_zone)
				continue
			// Reserved for a different box's home area (order-independent boundary).
			if(reserved_types && reserved_types.len && (check_area.type in reserved_types))
				continue
			stack += N

		// ── Staircase Z-traversal ─────────────────────────────────────────
		// If this floor tile has staircase objects on it, the floor above is
		// physically connected.  Compute the landing turf (one step forward
		// in the stair's facing direction, then up one z-level via multiz)
		// and push it so the fill continues into upper floors.
		// The same hierarchy and immune guards are applied before pushing.
		for(var/obj/structure/stairs/S in T.contents)
			var/turf/fwd = get_step(T, S.dir)
			if(!fwd)
				continue
			var/turf/landing = get_step_multiz(fwd, UP)
			if(!landing || visited[landing])
				continue
			var/area/L_area = get_area(landing)
			if(!L_area || _area_is_immune(L_area))
				continue
			var/area/f13/fL = L_area
			var/area/check_L = (istype(fL) && fL.f13_jbox_zone) ? start : L_area
			if(!_area_in_scope(check_L, root_type, custom_root))
				continue
			if(reserved_types && reserved_types.len && (check_L.type in reserved_types))
				continue
			stack += landing

		// ── Ladder Z-traversal ────────────────────────────────────────────
		// A ladder's .up/.down refs point directly at the connected ladder object
		// on the adjacent z-level, so no forward-step/landing math is needed here —
		// just push both linked turfs the same way stairs push their landing.
		for(var/obj/structure/ladder/L in T.contents)
			if(L.up)
				_flood_try_push(get_turf(L.up), visited, stack, start, root_type, reserved_types)
			if(L.down)
				_flood_try_push(get_turf(L.down), visited, stack, start, root_type, reserved_types)

	return visited


/// Releases every claimed zone: stamps them dark, repatriates their turfs to the original
/// area datums, and clears the registries.  Used by Destroy(), by unbolting, and by
/// rebuild_zones().
/obj/machinery/f13/junction_box/proc/teardown_zones()
	// Power off before we let go — stamp all zones dark.
	_stamp_areas(FALSE)

	// Repatriate flood-fill turfs back to their original singletons
	// so the world never has orphaned tiles after this box releases them.
	if(owned_zones)
		for(var/area/f13/Z in owned_zones)
			if(QDELETED(Z))
				continue
			var/area/orig = owned_zones[Z]
			if(!orig || QDELETED(orig))
				// The origin can itself have been another box's private zone that is already gone
				// (overlapping outdoor boxes removed in the "wrong" order). Fall back to the zone's
				// own origin, then to any live area of the same type, instead of abandoning the tiles.
				orig = Z.f13_origin
				if(!orig || QDELETED(orig))
					orig = null
					for(var/area/A in GLOB.sortedAreas)
						if(A != Z && A.type == Z.type && !QDELETED(A))
							orig = A
							break
			if(orig)
				for(var/turf/T in Z.contents.Copy())
					Z.contents    -= T
					orig.contents += T
			// Never delete a zone that still holds turfs; they'd end up in the default area.
			var/stranded = FALSE
			for(var/turf/ST in Z)
				stranded = TRUE
				break
			if(stranded)
				f13_log_op("jbox teardown: zone [Z.name] still holds turfs and has no live origin area; leaving it in place")
				continue
			qdel(Z)

	owned_zones            = null
	zone_breakers = null
	zone_tile_counts = null
	powered_area_instances = null
	grid_watt_draw         = grid_watt_draw_base

/// Detaches this box from every generator/relay feeding it (the logical equivalent of
/// cutting its cable) and marks it unpowered. Used when unbolting: wire links are
/// stored as references, not physical paths, so a moved box would otherwise stay
/// powered by its old connection.
/obj/machinery/f13/junction_box/proc/_sever_upstream()
	if(upstream_refs)
		for(var/datum/weakref/WC in upstream_refs)
			var/obj/upstream = WC.resolve()
			if(!upstream || QDELETED(upstream))
				continue
			if(istype(upstream, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = upstream
				if(G.linked_clients) G.linked_clients -= src
				if(G.shed_clients) G.shed_clients -= src
				G.recalc_draw()
			else if(istype(upstream, /obj/machinery/f13/power_relay))
				var/obj/machinery/f13/power_relay/R = upstream
				if(R.linked_clients) R.linked_clients -= src
		upstream_refs = null
		// Relay-fed boxes don't trigger a generator recalc themselves; do it so the
		// source stops budgeting for a load that's no longer attached.
		f13_recalc_all_generators()
	grid_powered = FALSE
	update_icon()

/// Rebuilds every bolted-down junction box that owns (or directly powers) any of the
/// given areas. Called after blueprints create_area() moves tiles between areas, so boxes
/// notice the change instead of silently losing the tiles they were powering.
/proc/f13_rescan_boxes_for_areas(list/touched)
	if(!touched || !touched.len)
		return
	for(var/obj/machinery/f13/junction_box/JB in GLOB.f13_jboxes)
		if(QDELETED(JB) || !JB.anchored)
			continue
		var/hit = FALSE
		if(JB.owned_zones)
			for(var/area/Z in JB.owned_zones)
				if(touched[Z] || touched[JB.owned_zones[Z]])
					hit = TRUE
					break
		if(!hit && JB.powered_area_instances)
			for(var/area/A in JB.powered_area_instances)
				if(touched[A])
					hit = TRUE
					break
		if(hit)
			JB.rebuild_zones()

/// Drops and re-claims territory from scratch.  Call after the box is moved/bolted down
/// or after the surrounding area was repainted with area_edit.
/obj/machinery/f13/junction_box/proc/rebuild_zones()
	// Remember which zone breakers were tripped (keyed by the original area, since the
	// zone datums themselves are recreated) so a rescan doesn't silently re-close them.
	var/list/tripped = list()
	if(owned_zones && zone_breakers)
		for(var/area/Z in owned_zones)
			if(zone_breakers[Z] == FALSE && owned_zones[Z])
				tripped[owned_zones[Z]] = TRUE
	teardown_zones()
	var/area/home = _resolve_root_area()
	home_area_type = home ? home.type : null
	build_zones()
	if(tripped.len && owned_zones && zone_breakers)
		var/restored = FALSE
		for(var/area/Z in owned_zones)
			if(tripped[owned_zones[Z]])
				zone_breakers[Z] = FALSE
				restored = TRUE
		if(restored && grid_powered && breaker_closed)
			_stamp_areas(TRUE)  // re-apply so tripped zones go back dark

/obj/machinery/f13/junction_box/Destroy()
	GLOB.f13_jboxes -= src
	teardown_zones()
	return ..()


// ============================================================
// GRID POWER HOOK
// ============================================================

/// Called by the upstream generator/relay when grid power changes.
/obj/machinery/f13/junction_box/on_grid_power_change(new_state)
	. = ..()   // sets grid_powered, calls update_icon()

	// Manual breaker override: don't restore area power if the breaker
	// was deliberately tripped, but DO cut it if the grid dies.
	if(new_state && !breaker_closed)
		return

	_stamp_areas(new_state)


// ============================================================
// AREA STAMPING
// ============================================================

/// Stamp power state onto every area this box controls.
/// Master breaker state is honoured: if state=TRUE but breaker is open, nothing turns on.
/// Per-zone breakers are respected individually when state=TRUE;
/// when state=FALSE (grid loss) ALL zones are killed regardless of zone breakers.
/obj/machinery/f13/junction_box/proc/_stamp_areas(state)
	// ── Legacy explicit-area path ────────────────────────────────────────
	if(powered_area_instances && powered_area_instances.len)
		for(var/area/A in powered_area_instances)
			if(_area_is_immune(A))
				continue
			// Defensive fallback only: a shared outdoor area singleton (not one of our own
			// carved private zones) must NOT be stamped wholesale — F13_STAMP_AREA_POWER on
			// it would light up every light of that type across the entire map. This should
			// never trigger in practice since LateInitialize() always carves outdoor claims
			// into a private zone first, but guard against it in case A ever ends up being
			// the raw singleton (e.g. legacy save data from before that carving existed).
			var/area/f13/fA = A
			if(A.outdoors && !(istype(fA) && fA.f13_jbox_zone))
				for(var/turf/T in RANGE_TURFS(power_reach, src))
					if(get_area(T) != A)
						continue
					for(var/obj/machinery/light/L in T)
						if(!QDELETED(L))
							if(state)
								L.seton(L.status == LIGHT_OK)
							else
								L.on = FALSE
								L.emergency_mode = FALSE
								L.set_light(0)
								L.update_icon()
				continue
			if(A.power_equip == state)
				continue
			F13_STAMP_AREA_POWER(A, state)
		return

	// ── Multi-zone flood-fill path ───────────────────────────────────────
	if(!owned_zones)
		return
	for(var/area/f13/Z in owned_zones)
		// On power loss: always kill zone regardless of zone breaker.
		// On power restore: only bring up zones whose individual breaker is closed.
		var/target = state && zone_breakers[Z]
		_stamp_zone(Z, target)


/// Stamp a single zone datum to the given state (APC-style diff guarded).
/obj/machinery/f13/junction_box/proc/_stamp_zone(area/f13/Z, state)
	if(QDELETED(Z))
		return
	if(Z.power_equip == state)
		return
	F13_STAMP_AREA_POWER(Z, state)

// ============================================================
// ICON
// ============================================================

/obj/machinery/f13/junction_box/update_icon_state()
	icon_state = ""
	if(grid_powered && breaker_closed)
		color = "#4aed92"   // terminal green — circuit live
	else if(upstream_refs && upstream_refs.len)
		color = "#e8a020"   // amber — wired but no power / breaker tripped
	else
		color = null        // no tint — not wired


// ============================================================
// EXAMINE
// ============================================================

/obj/machinery/f13/junction_box/examine(mob/user)
	. = ..()
	var/area/here = get_area(src)
	if(here && _area_is_immune(here))
		. += span_warning("Warning: this area ([here.name]) is marked grid-immune — the box will not power it.")
		return
	if(powered_area_instances && powered_area_instances.len)
		var/list/names = list()
		for(var/area/A in powered_area_instances)
			names += A.name
		. += span_notice("Coverage: [english_list(names)].")
	else if(owned_zones && owned_zones.len)
		. += span_notice("Controls [owned_zones.len] power zone[owned_zones.len == 1 ? "" : "s"]. Interact to manage breakers.")
	else
		. += span_warning("No power zones established — this box will not power anything.")
	if(!breaker_closed)
		. += span_warning("Master breaker is tripped. Flip it to restore power.")


// ============================================================
// UI
// ============================================================

/obj/machinery/f13/junction_box/attack_hand(mob/living/user, list/modifiers)
	if(!user || !isliving(user))
		return ..()
	// A loose box has no territory and nothing to configure yet — its panel only
	// becomes useful once it is bolted down and has claimed a room.
	if(!anchored)
		to_chat(user, span_notice("[src] isn't mounted yet. Drag it into place and bolt it down with a wrench to use its panel."))
		return
	show_ui(user)

/obj/machinery/f13/junction_box/proc/show_ui(mob/living/user)
	var/dat = get_terminal_css()
	dat += get_terminal_header("Electrical Junction Box")
	dat += "<pre class='dim'>  UNIT: [tag ? tag : name]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Status row
	var/status_str
	if(grid_powered && breaker_closed)
		status_str = "<span class='good'>&#91;ONLINE&#93;</span>  — building circuit energised"
	else if(!upstream_refs || !upstream_refs.len)
		status_str = "<span class='bad'>&#91;NOT WIRED&#93;</span>  — connect to a generator or relay"
	else if(!grid_powered)
		status_str = "<span class='bad'>&#91;NO GRID POWER&#93;</span>  — grid feed is dead"
	else
		status_str = "<span class='warn'>&#91;MASTER TRIPPED&#93;</span>  — grid live, master breaker open"
	dat += "<pre>  STATUS  : [status_str]</pre>"
	var/live_draw = get_effective_watt_draw()
	if(live_draw == grid_watt_draw)
		dat += "<pre>  LOAD    : [grid_watt_draw]W</pre>"
	else
		dat += "<pre>  LOAD    : <span class='good'>[live_draw]W</span> drawn  <span class='dim'>([grid_watt_draw]W rated — breakers are cutting [grid_watt_draw - live_draw]W)</span></pre>"
	dat += "<pre>  APPARENT: [round(get_effective_va_draw())]VA  <span class='dim'>(blended power factor [power_factor] — mixed lighting/motor circuit)</span></pre>"

	// ── Diagnostics checklist — the first thing a tech should scan
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;DIAGNOSTICS&#93;</pre>"
	var/list/diag = list()
	diag += list(list((upstream_refs && upstream_refs.len) ? "good" : "bad", (upstream_refs && upstream_refs.len) ? "Upstream wiring intact" : "Not wired — connect a cable coil to a generator or relay"))
	if(upstream_refs && upstream_refs.len)
		diag += list(list(grid_powered ? "good" : "bad", grid_powered ? "Grid feed live" : "Grid feed dead — check upstream source"))
	diag += list(list(breaker_closed ? "good" : "warn", breaker_closed ? "Master breaker closed" : "Master breaker tripped — all zones cut"))
	if(breaker_closed && zone_breakers && zone_breakers.len)
		var/tripped_zones = 0
		for(var/area/f13/Z in zone_breakers)
			if(!zone_breakers[Z])
				tripped_zones++
		if(tripped_zones)
			diag += list(list("warn", "[tripped_zones] of [zone_breakers.len] zone breaker[zone_breakers.len == 1 ? "" : "s"] tripped"))
		else
			diag += list(list("good", "All zone breakers closed"))
	for(var/entry in diag)
		var/lvl = entry[1]
		var/lbl = entry[2]
		var/tag = lvl == "good" ? "OK  " : (lvl == "warn" ? "WARN" : "FAIL")
		dat += "<pre>    <span class='[lvl]'>&#91;[tag]&#93;</span>  [lbl]</pre>"

	// ── Upstream feed
	var/list/up_names = list()
	var/obj/machinery/f13/power_relay/feed_relay = null
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(!up || QDELETED(up)) continue
			up_names += up.name
			if(!feed_relay && istype(up, /obj/machinery/f13/power_relay))
				feed_relay = up
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre>  FEED    : [up_names.len ? english_list(up_names) : "<span class='bad'>NOT WIRED — use a cable coil</span>"]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"


	// ── Master breaker control
	dat += "<pre class='head'>  &#91;MASTER BREAKER&#93;</pre>"
	if(grid_powered)
		var/mlbl = breaker_closed ? "&#91; TRIP ALL &#93;" : "&#91; CLOSE ALL &#93;"
		var/mstate = breaker_closed ? "<span class='good'>CLOSED</span>" : "<span class='warn'>TRIPPED</span>"
		dat += "<pre>    [mstate]  <a href='byond://?src=[REF(src)];toggle_breaker=1'>[mlbl]</a></pre>"
	else
		dat += "<pre class='dim'>    Master control unavailable — no grid power.</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Upstream relay cutoff (shown when at least one upstream is a relay)
	if(feed_relay)
		dat += "<pre class='head'>  &#91;UPSTREAM RELAY&#93;</pre>"
		var/rlbl = feed_relay.relay_powered ? "&#91; CUT RELAY &#93;" : "&#91; RESTORE RELAY &#93;"
		var/rstate = feed_relay.relay_powered ? "<span class='good'>ENERGISED</span>" : "<span class='warn'>CUT</span>"
		dat += "<pre>    [rstate]  [feed_relay.name]</pre>"
		dat += "<pre>    <a href='byond://?src=[REF(src)];toggle_relay=1'>[rlbl]</a>  <span class='dim'>(affects all buildings on this relay)</span></pre>"
		dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Per-zone section
	dat += "<pre class='head'>  &#91;CIRCUIT ZONES&#93;</pre>"
	if(powered_area_instances && powered_area_instances.len)
		// Legacy explicit-area path — no per-zone breakers.
		for(var/area/A in powered_area_instances)
			if(!QDELETED(A))
				var/pstate = A.power_equip ? "<span class='good'>LIVE  </span>" : "<span class='bad'>DEAD  </span>"
				dat += "<pre>    [pstate]  [A.name]</pre>"
	else if(owned_zones && owned_zones.len)
		// Multi-zone flood-fill path.
		for(var/area/f13/Z in owned_zones)
			if(QDELETED(Z))
				continue
			var/z_live   = Z.power_equip
			var/z_closed = zone_breakers[Z]
			var/pstate   = z_live ? "<span class='good'>LIVE  </span>" : "<span class='bad'>DEAD  </span>"
			var/bstate   = z_closed ? "<span class='good'>&#91;CLOSED&#93;</span>" : "<span class='warn'>&#91;TRIPPED&#93;</span>"
			var/tile_count = _zone_tiles(Z)
			var/zone_cost  = round(_zone_watt_cost(Z))
			if(grid_powered && breaker_closed)
				// Per-zone breaker toggle available when master is live.
				var/zlbl = z_closed ? "trip" : "close"
				dat += "<pre>    [pstate]  [bstate]  [Z.name]  <span class='dim'>([tile_count] tiles, [zone_cost]W)</span>  <a href='byond://?src=[REF(src)];zone_breaker=[REF(Z)]'>[zlbl]</a></pre>"
			else
				dat += "<pre>    [pstate]  [bstate]  [Z.name]  <span class='dim'>([tile_count] tiles, [zone_cost]W)</span></pre>"
	else
		var/area/here2 = get_area(src)
		if(here2 && _area_is_immune(here2))
			dat += "<pre class='bad'>    &#91;!&#93; Placed outdoors ([here2.name]) — cannot power this area.</pre>"
			dat += "<pre class='bad'>    Mount inside a building wall.</pre>"
		else
			var/area/f13/claimed_check = here2
			if(!anchored)
				dat += "<pre class='dim'>    Not bolted down — wrench it into place to claim a room.</pre>"
			else if(istype(claimed_check) && claimed_check.f13_jbox_zone)
				dat += "<pre class='dim'>    This room is already powered by another junction box.</pre>"
			else
				dat += "<pre class='dim'>    No zones established — check placement.</pre>"
	if(anchored)
		dat += "<pre>    <a href='byond://?src=[REF(src)];rebuild_zones=1'>&#91; RESCAN ZONES &#93;</a>  <span class='dim'>(re-detect rooms after area changes)</span></pre>"
	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_jbox_[REF(src)]", null, 560, 400)
	popup.set_content(dat)
	popup.open()

/obj/machinery/f13/junction_box/Topic(href, href_list)
	if(!usr || !isliving(usr))
		return
	if(!in_range(src, usr) && !isobserver(usr))
		return
	// Ignore clicks from a panel that was left open while the box got unbolted.
	if(!anchored)
		return

	if(href_list["toggle_breaker"])
		// ── Master breaker toggle ────────────────────────────────────────
		// Gate logic: the junction box only controls its own building zones.
		// The upstream relay is shared infrastructure and is never touched here.
		breaker_closed = !breaker_closed
		if(breaker_closed)
			// Closing master: reset all zone breakers then restore power if the grid is live.
			if(zone_breakers)
				for(var/area/f13/Z in zone_breakers)
					zone_breakers[Z] = TRUE
			if(grid_powered)
				_stamp_areas(TRUE)
		else
			// Tripping master: kill all zones only.
			_stamp_areas(FALSE)
		update_icon()
		var/msg = breaker_closed ? "You close the master breaker — all circuits restored." : "You trip the master breaker — all building power cut."
		to_chat(usr, span_notice(msg))
		show_ui(usr)

	if(href_list["rebuild_zones"])
		// ── Re-detect rooms (e.g. after the area was repainted with area_edit) ──
		if(!anchored)
			return
		rebuild_zones()
		update_icon()
		to_chat(usr, span_notice("Zone scan complete."))
		show_ui(usr)

	if(href_list["toggle_relay"])
		// ── Explicit upstream relay cutoff ────────────────────────────
		var/obj/machinery/f13/power_relay/R = null
		if(upstream_refs)
			for(var/datum/weakref/W in upstream_refs)
				var/obj/up = W.resolve()
				if(istype(up, /obj/machinery/f13/power_relay)) { R = up; break }
		if(!R || QDELETED(R)) return
		_set_upstream_relay_power(!R.relay_powered || R.relay_isolated)
		var/msg2 = R.relay_powered ? "Relay restored — all downstream buildings re-energised." : "Relay cut — all downstream buildings de-energised."
		to_chat(usr, span_notice(msg2))
		show_ui(usr)

	if(href_list["zone_breaker"] && owned_zones && zone_breakers)
		// ── Per-zone breaker toggle ──────────────────────────────────────
		// Only available when master breaker and grid are both live.
		if(!grid_powered || !breaker_closed)
			return
		// Locate the zone datum by its REF string.
		var/area/f13/Z = locate(href_list["zone_breaker"])
		if(!Z || QDELETED(Z) || !owned_zones[Z])
			return   // REF doesn't match a zone we own — reject silently.
		var/z_was_closed = zone_breakers[Z]
		zone_breakers[Z] = !z_was_closed
		_stamp_zone(Z, zone_breakers[Z])
		update_icon()
		var/msg = zone_breakers[Z] ? "You close the [Z.name] circuit breaker — power restored." : "You trip the [Z.name] circuit breaker — section power cut."
		to_chat(usr, span_notice(msg))
		show_ui(usr)


/// Trip or restore the upstream relay when the master breaker is toggled.
/// Makes the junction box a true master cutoff for the relay subtree feeding it.
/obj/machinery/f13/junction_box/proc/_set_upstream_relay_power(state)
	var/obj/machinery/f13/power_relay/R = null
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(istype(up, /obj/machinery/f13/power_relay)) { R = up; break }
	if(!R || QDELETED(R))
		return
	if(state)
		// Restore: clear isolation flag and let OR logic decide.
		R.relay_isolated = FALSE
		R.on_upstream_changed()
	else
		// Cut: mark isolated and force offline regardless of other upstreams.
		R.relay_isolated = TRUE
		R.set_relay_power(FALSE)

// ============================================================
// SUBTYPES — common pre-watt configurations
// ============================================================

/// Small room / shack — lower per-zone load, but the least efficient choice once a
/// building spans several zones (see grid_watt_draw_base comment in _defines.dm).
/obj/machinery/f13/junction_box/small
	name  = "electrical junction box"
	desc  = "A smaller breaker panel for a modest room or shack."
	grid_watt_draw_per_tile = 0.3
	grid_watt_draw_base     = 25
	grid_watt_draw          = 25  // pre-LateInit estimate; real value depends on claimed tiles

/// Large complex — workshop, barracks, multi-room building.  Higher fixed overhead,
/// but the cheapest per-zone rate — undercuts small/base once a building has enough
/// zones (roughly 5+), so it's the right pick for a BOS-sized multi-room compound.
/obj/machinery/f13/junction_box/large
	name  = "electrical junction box"
	desc  = "A heavy-duty breaker panel wired to a large building's internal circuits."
	grid_watt_draw_per_tile = 0.1
	grid_watt_draw_base     = 150
	grid_watt_draw          = 150  // pre-LateInit estimate; real value depends on claimed tiles

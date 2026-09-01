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
//   grid_watt_draw is multiplied by the number of zones this box
//   claims, so a box covering three sub-areas draws 3× the base
//   wattage automatically.  Override grid_watt_draw_per_zone on
//   subtypes to change the per-zone cost (default 150 W).
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

	// Watt draw — base cost per claimed zone.  Total draw = grid_watt_draw_per_zone × zone count.
	// The combined value is written to grid_watt_draw in LateInitialize once zones are known.
	grid_watt_draw = JUNCTION_BOX_WATT_DRAW
	/// Per-zone watt cost.  Summed at LateInitialize; override on subtypes.
	var/grid_watt_draw_per_zone = JUNCTION_BOX_WATT_DRAW
	/// Light reach (tiles) used when the box is placed in an outdoor area (e.g. wasteland).
	/// Lights within this distance receive seton()/setoff() individually instead of a
	/// whole-map F13_STAMP_AREA_POWER call on the shared area datum.  Override on subtypes.
	var/power_reach = 10

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


/// Returns TRUE if the given area should never be stamped by a junction box.
/// Only areas with f13_grid_immune explicitly set are permanently blocked.
/// Outdoor areas CAN be powered — the wasteland generator is designed for this.
/obj/machinery/f13/junction_box/proc/_area_is_immune(area/A)
	var/area/f13/farea = A
	if(istype(farea) && farea.f13_grid_immune)
		return TRUE
	return FALSE

// ============================================================
// LIFE CYCLE
// ============================================================

/obj/machinery/f13/junction_box/Initialize()
	// Zone creation is deferred to LateInitialize() so all turfs
	// and area datums are fully settled before we read or reassign them.
	// INITIALIZE_HINT_LATELOAD ensures LateInitialize() is scheduled even
	// for boxes spawned mid-round (e.g. admin-spawned or crafted in-game).
	. = ..()
	return INITIALIZE_HINT_LATELOAD


/obj/machinery/f13/junction_box/LateInitialize()
	. = ..()
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
	var/area/here = get_area(src)
	if(!here)
		return
	if(_area_is_immune(here))
		return
	if(here.outdoors)
		powered_area_instances = list(here)
		grid_watt_draw = grid_watt_draw_per_zone
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
	var/list/turf_map = _flood_fill_turfs(here.type)
	if(!turf_map || !turf_map.len)
		return

	// ── Group turfs by their original area type ──────────────────────────
	// type_to_zone: area TYPE PATH → private zone datum  (used during grouping)
	// type_to_origin: area TYPE PATH → original singleton datum  (for repatriation)
	var/list/type_to_zone   = list()
	var/list/type_to_origin = list()

	for(var/turf/T in turf_map)
		var/area/orig = turf_map[T]          // original singleton this turf came from
		if(!istype(orig, /area))             // openspace bridge sentinel — not an ownable tile
			continue
		var/atype     = orig.type

		if(!type_to_zone[atype])
			// First turf of this type — spawn a private zone datum.
			var/area/f13/Z = new atype()
			Z.f13_jbox_zone    = TRUE
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

	// Update watt draw: one unit per zone (matched to grid accounting).
	grid_watt_draw = grid_watt_draw_per_zone * owned_zones.len

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
/// Returns an assoc list: turf → original area datum it belonged to at walk time.
/obj/machinery/f13/junction_box/proc/_flood_fill_turfs(root_type)
	var/list/visited = list()   // turf → original area datum
	var/list/stack   = list(get_turf(src))
	var/area/start   = get_area(src)
	while(stack.len)
		var/turf/T = stack[stack.len]
		stack.len--
		if(visited[T])
			continue
		var/area/T_area = get_area(T)
		if(!T_area)
			continue
		// Record the ORIGINAL area — before any zone datum could overwrite it.
		// If T already sits in a jbox zone from a prior Initialize run,
		// attribute it to our start area so grouping handles it correctly.
		var/area/f13/fT = T_area
		var/area/origin = (istype(fT) && fT.f13_jbox_zone) ? start : T_area
		// ── Openspace bridge (main-loop) ─────────────────────────────────
		// Openspace tiles are z-transparent "holes" between floors — they
		// are not ownable interior area.  Store T as a sentinel (truthy,
		// non-area value) so revisit checks pass, then bridge DOWN.
		if(istype(T, /turf/open/transparent/openspace))
			visited[T] = T   // sentinel: visited/bridged, not owned
			var/turf/os_below = get_step_multiz(T, DOWN)
			if(os_below && !visited[os_below])
				var/area/ob_area = get_area(os_below)
				if(ob_area && !_area_is_immune(ob_area))
					var/area/f13/fob = ob_area
					var/check_ob = (istype(fob) && fob.f13_jbox_zone) ? start : ob_area
					if(istype(check_ob, root_type))
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
			// Openspace is a z-transparent hole — push the tile below it
			// instead of trying to own it.  Bypass the immune check since
			// the openspace tile's own area is irrelevant.
			if(istype(N, /turf/open/transparent/openspace))
				var/turf/ns_below = get_step_multiz(N, DOWN)
				if(ns_below && !visited[ns_below])
					var/area/nb_area = get_area(ns_below)
					if(nb_area && !_area_is_immune(nb_area))
						var/area/f13/fnb = nb_area
						var/check_nb = (istype(fnb) && fnb.f13_jbox_zone) ? start : nb_area
						if(istype(check_nb, root_type))
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
			var/check_area = (istype(fN) && fN.f13_jbox_zone) ? start : N_area
			if(!istype(check_area, root_type))
				continue
			// Already claimed by a different junction box — respect its boundary.
			if(istype(fN) && fN.f13_jbox_zone)
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
			var/check_L = (istype(fL) && fL.f13_jbox_zone) ? start : L_area
			if(!istype(check_L, root_type))
				continue
			stack += landing

	return visited


/obj/machinery/f13/junction_box/Destroy()
	// Power off before we vanish — stamp all zones dark.
	_stamp_areas(FALSE)

	// Repatriate flood-fill turfs back to their original singletons
	// so the world never has orphaned tiles after this box is removed.
	if(owned_zones)
		for(var/area/f13/Z in owned_zones)
			var/area/orig = owned_zones[Z]
			if(QDELETED(Z) || !orig || QDELETED(orig))
				continue
			for(var/turf/T in Z.contents.Copy())
				Z.contents    -= T
				orig.contents += T
			qdel(Z)

	owned_zones            = null
	zone_breakers          = null
	powered_area_instances = null
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
			// Outdoor areas (e.g. wasteland) must NOT be stamped wholesale —
			// F13_STAMP_AREA_POWER on a shared outdoor area datum lights up every
			// light of that type across the entire map.  Toggle only lights
			// within power_reach of this box instead.
			if(A.outdoors)
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
	dat += "<pre>  LOAD    : [grid_watt_draw]W</pre>"

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
			var/tile_count = Z.contents.len
			if(grid_powered && breaker_closed)
				// Per-zone breaker toggle available when master is live.
				var/zlbl = z_closed ? "trip" : "close"
				dat += "<pre>    [pstate]  [bstate]  [Z.name]  <span class='dim'>([tile_count] tiles)</span>  <a href='byond://?src=[REF(src)];zone_breaker=[REF(Z)]'>[zlbl]</a></pre>"
			else
				dat += "<pre>    [pstate]  [bstate]  [Z.name]  <span class='dim'>([tile_count] tiles)</span></pre>"
	else
		var/area/here2 = get_area(src)
		if(here2 && _area_is_immune(here2))
			dat += "<pre class='bad'>    &#91;!&#93; Placed outdoors ([here2.name]) — cannot power this area.</pre>"
			dat += "<pre class='bad'>    Mount inside a building wall.</pre>"
		else
			dat += "<pre class='dim'>    No zones established — check placement.</pre>"
	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_jbox_[REF(src)]", null, 560, 400)
	popup.set_content(dat)
	popup.open()

/obj/machinery/f13/junction_box/Topic(href, href_list)
	if(!usr || !isliving(usr))
		return
	if(!in_range(src, usr) && !isobserver(usr))
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

/// Small room / shack — lower per-zone load.
/obj/machinery/f13/junction_box/small
	name  = "electrical junction box"
	desc  = "A smaller breaker panel for a modest room or shack."
	grid_watt_draw_per_zone = 75
	grid_watt_draw          = 75   // pre-set for pre-LateInit cost estimates

/// Large complex — workshop, barracks, multi-room building.
/obj/machinery/f13/junction_box/large
	name  = "electrical junction box"
	desc  = "A heavy-duty breaker panel wired to a large building's internal circuits."
	grid_watt_draw_per_zone = 250
	grid_watt_draw          = 250

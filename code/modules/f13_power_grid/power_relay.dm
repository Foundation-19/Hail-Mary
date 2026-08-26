// ============================================================
// POWER RELAY
// ============================================================
//
// A distribution node that sits between a faction_generator and
// the areas / devices it should power.  Think Fallout 4 power
// pylons or Factorio medium power poles — a chain of relays
// lets you route the grid across a base without having the
// generator own every area directly.
//
// TOPOLOGY:
//   Generator ─── Relay A (gatehouse)
//              └── Relay B (barracks) ─── Relay C (armoury)
//
// Cutting the feed between Generator and Relay A kills A, B,
// and C (cascade).  Cutting B–C only kills C.  Destroying any
// relay mid-chain also cascades downstream.
//
// WIRING (cable coil):
//   Option A — upstream first:
//     1. Use a cable coil on the generator or upstream relay → marks it as the wire source.
//     2. Use the same coil on this relay → link formed (consumes 2 cable).
//   Option B — downstream first:
//     1. Use a cable coil on this relay → marks it as the source.
//     2. Use the same coil on the upstream generator or relay → link formed (consumes 2 cable).
//   Wirecutters on a relay severs its upstream connection.
//
// MAPPER SETUP EXAMPLE:
//   /obj/machinery/f13/power_relay/bos_gate{
//       powered_area_types = list(/area/f13/underground/bos)
//       map_turret_tags    = "turret_bos_main_gate"
//   }
// ============================================================

/obj/machinery/f13/power_relay
	name          = "power relay"
	desc          = "A power distribution node. Wire it to a base generator or another relay with a multitool to extend the grid."
	icon          = 'icons/machines/power_grid/power_relay.dmi'
	icon_state    = ""
	density       = TRUE
	anchored      = TRUE
	max_integrity = 350
	armor         = list(melee = 10, bullet = 10, laser = 5, energy = 5, bomb = 20, bio = 0, rad = 0, fire = 25, acid = 15)
	// Relay routes power — it doesn't consume from the area power system.
	use_power     = NO_POWER_USE

	// ── Wiring ─────────────────────────────────────────────
	/// List of WEAKREFs to all upstream generators/relays feeding this node.
	/// Multiple entries allow parallel / redundant feeds (OR logic).
	var/list/upstream_refs = null
	/// Relays this node feeds downstream.
	var/list/downstream_relays = null
	/// Any /obj/machinery/f13/grid_client directly wired to this relay.
	var/list/linked_clients = null

	// ── Zone ownership ──────────────────────────────────────
	/// Area type paths this relay is responsible for powering.
	var/list/powered_area_types  = null
	/// Resolved live area datum instances (populated in Initialize).
	var/list/powered_area_instances = null
	/// Turret tag string (comma-separated) — same pattern as generator.
	var/map_turret_tags = null
	/// Comma-separated tags of downstream relays to auto-wire on Initialize.
	var/map_downstream_tags = null
	/// Comma-separated object tags for grid_clients (e.g. junction boxes) to auto-wire on Initialize.
	var/map_client_tags = null
	/// Resolved live turret refs.
	var/list/linked_turrets = null

	// ── State ───────────────────────────────────────────────
	var/relay_powered = FALSE
	/// TRUE when this relay was taken offline deliberately by the generator's load-shedding.
	/// Distinguishes a managed suspension from a wiring fault or generator failure.
	var/load_shed = FALSE
	/// Set TRUE when this relay has been manually isolated (e.g. via junction box CUT RELAY).
	/// While isolated, on_upstream_changed() keeps the relay offline even if upstreams are live.
	var/relay_isolated = FALSE
	/// Set TRUE after the first power-on cable scan so we don't re-scan on every toggle.
	var/cable_scan_done = FALSE
	/// Cached list of /area/space border turfs that contain door buttons adjacent to owned areas.
	/// Built once by the first stamp_zone() call; reused on every subsequent toggle.
	var/list/button_sweep_cache = null


// ============================================================
// LIFECYCLE
// ============================================================

/obj/machinery/f13/power_relay/Initialize()
	. = ..()
	resolve_map_links()
	// Relay starts unpowered; the upstream must wire in and send power.

/obj/machinery/f13/power_relay/Destroy()
	// Sever all upstream links cleanly.
	_sever_upstream()

	// Notify downstream relays they lost one upstream — each recalculates via OR logic.
	if(downstream_relays)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				f13_remove_upstream_ref(R.upstream_refs, src)
				R.on_upstream_changed()

	// Disconnect generic grid clients.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				f13_remove_upstream_ref(C.upstream_refs, src)
				C.on_upstream_changed()
		linked_clients = null

	return ..()


// ============================================================
// MAP LINK RESOLUTION (mirrors faction_generator)
// ============================================================

/obj/machinery/f13/power_relay/proc/resolve_map_links()
	if(powered_area_types && powered_area_types.len)
		powered_area_instances = list()
		for(var/area_type in powered_area_types)
			var/area/A = locate(area_type) in world
			if(A && !QDELETED(A))
				powered_area_instances += A

	if(map_turret_tags && length(map_turret_tags))
		linked_turrets = list()
		for(var/raw_tag in splittext(map_turret_tags, ","))
			var/target_tag = trim(raw_tag)
			if(!length(target_tag))
				continue
			for(var/obj/machinery/porta_turret/T in world)
				if(T.tag == target_tag && !(T in linked_turrets))
					linked_turrets += T

	// Auto-wire downstream relays by tag.
	if(map_downstream_tags && length(map_downstream_tags))
		if(!downstream_relays)
			downstream_relays = list()
		for(var/raw_tag in splittext(map_downstream_tags, ","))
			var/target_tag = trim(raw_tag)
			if(!length(target_tag))
				continue
			for(var/obj/machinery/f13/power_relay/R in world)
				if(R.tag == target_tag && !(R in downstream_relays) && !src._has_upstream(R))
					downstream_relays += R
					if(!R.upstream_refs) R.upstream_refs = list()
					R.upstream_refs += WEAKREF(src)

	// Auto-wire generic grid clients (including junction boxes) by tag.
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


/// Walk this relay's subtree and return total watt draw (self + downstream).
/// Self draw = RELAY_WATT_DRAW + owned turrets + any wired fabricators if this relay has them.
// visited guards against cycles in downstream_relays (e.g. two relays each wired to the other).
/obj/machinery/f13/power_relay/proc/get_subtree_draw(list/visited)
	if(!relay_powered)
		return 0
	var/draw = RELAY_WATT_DRAW
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				draw += TURRET_WATT_DRAW
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				draw += C.grid_watt_draw
	if(downstream_relays)
		if(!visited)
			visited = list(src)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R) && !(R in visited))
				visited += R
				draw += R.get_subtree_draw(visited)
	return draw

/// Recalculate this relay's power state from all registered upstream nodes.
/// Uses OR logic: relay is powered if ANY upstream is live AND relay_isolated is FALSE.
/// Cascades downstream so every node in the subtree also recalculates.
/obj/machinery/f13/power_relay/proc/on_upstream_changed()
	if(relay_isolated)
		set_relay_power(FALSE)
		return
	var/any_live = FALSE
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(!up || QDELETED(up))
				continue
			if(istype(up, /obj/machinery/f13/faction_generator) && up:powered)
				any_live = TRUE
				break
			if(istype(up, /obj/machinery/f13/power_relay) && up:relay_powered)
				any_live = TRUE
				break
	set_relay_power(any_live)

/// Returns TRUE if /obj/target is already registered in upstream_refs.
/obj/machinery/f13/power_relay/proc/_has_upstream(obj/target)
	if(!upstream_refs || !target)
		return FALSE
	for(var/datum/weakref/W in upstream_refs)
		if(W.resolve() == target)
			return TRUE
	return FALSE


// ============================================================
// POWER PROPAGATION
// ============================================================

/// Stamp all owned areas then cascade to downstream relays.
/obj/machinery/f13/power_relay/proc/set_relay_power(new_state)
	if(relay_powered == new_state)
		return

	// Round-start: before the first power-on cascade, scan for any relays or
	// clients that were connected via pre-placed map cables but never linked
	// via map tags.  Adds them to the lists so the cascade below covers them.
	if(new_state && !cable_scan_done)
		cable_scan_done = TRUE
		_scan_cable_connections()

	relay_powered = new_state
	update_icon()

	// Update owned areas.
	if(powered_area_instances)
		for(var/area/A in powered_area_instances)
			F13_STAMP_AREA_POWER(A, relay_powered)

	// Toggle owned turrets.
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				T.toggle_on(relay_powered)

	// Cascade to downstream relays — each recalculates from its own upstreams (OR logic).
	if(downstream_relays)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				R.on_upstream_changed()

	// Propagate to generic grid clients — same OR recalculation.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.on_upstream_changed()


// ============================================================
// WIRING — CABLE INTERACTION
// ============================================================

/// BFS-scan from this relay's turf and silently link any unlinked downstream
/// relay or grid_client reachable via cable.  Called once on first power-on
/// to handle maps with pre-laid cables that weren't set up via map_*_tags.
/obj/machinery/f13/power_relay/proc/_scan_cable_connections()
	var/turf/src_turf = get_turf(src)
	if(!src_turf)
		return

	// BFS from this relay's turf, stopping the frontier at relay/client tiles.
	// set_relay_power / on_grid_power_change fire via the cascade after this returns.
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
					if(!QDELETED(R) && R != src)
						// Skip if R is already our upstream — wiring it downstream too would form a cycle.
						if(!(R in downstream_relays) && !src._has_upstream(R))
							if(!downstream_relays) downstream_relays = list()
							downstream_relays += R
							if(!R.upstream_refs) R.upstream_refs = list()
							if(!R._has_upstream(src)) R.upstream_refs += WEAKREF(src)
						blocked = TRUE
						break
				if(blocked)
					continue
				for(var/obj/machinery/f13/grid_client/C in N)
					if(!QDELETED(C))
						if(!(C in linked_clients))
							if(!linked_clients) linked_clients = list()
							linked_clients += C
							if(!C.upstream_refs) C.upstream_refs = list()
							if(!C._has_upstream(src)) C.upstream_refs += WEAKREF(src)
						blocked = TRUE
						break
				if(blocked)
					continue
				if(locate(/obj/structure/cable) in N)
					next_frontier += N
		frontier = next_frontier

/// Validate every existing logical connection from this relay against the current cable layout.
/// Any downstream relay or client whose cable path is gone gets unpowered and unlinked.
/// Returns the number of connections removed.
/obj/machinery/f13/power_relay/proc/_prune_dead_links()
	var/turf/src_turf = get_turf(src)
	if(!src_turf)
		return 0
	var/removed = 0
	if(downstream_relays)
		var/list/to_remove = list()
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(QDELETED(R) || !f13_cable_path_exists(src_turf, get_turf(R)))
				to_remove += R
		for(var/obj/machinery/f13/power_relay/R in to_remove)
			f13_remove_upstream_ref(R.upstream_refs, src)
			R.on_upstream_changed()
			downstream_relays -= R
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
	return removed

/obj/machinery/f13/power_relay/attackby(obj/item/W, mob/user, params)
	// Wrench: when ONLINE → anchor/unanchor; when OFFLINE → repair.
	if(W.tool_behaviour == TOOL_WRENCH)
		if(relay_powered)
			anchored = !anchored
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			to_chat(user, span_notice(anchored ? "You bolt [src] to the floor." : "You unbolt [src] from the floor."))
		else
			// Repair damaged relay while offline.
			if(obj_integrity < max_integrity)
				obj_integrity = min(obj_integrity + RELAY_REPAIR_AMOUNT, max_integrity)
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, span_notice("You repair [src]. ([obj_integrity]/[max_integrity] HP)"))
			else
				anchored = !anchored
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, span_notice(anchored ? "You bolt [src] to the floor." : "You unbolt [src] from the floor."))
		return

	// ── Cable coil — wiring interface.
	if(istype(W, /obj/item/stack/cable_coil))
		if(!isliving(user))
			return
		var/mob/living/L = user
		var/obj/machinery/machine_src = f13_try_complete_wire(src, L)
		if(machine_src)
			// Relay is the destination — link from generator or upstream relay.
			if(istype(machine_src, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = machine_src
				G.link_relay(src, user)
			else if(istype(machine_src, /obj/machinery/f13/power_relay) && machine_src != src)
				var/obj/machinery/f13/power_relay/P = machine_src
				set_upstream_relay(P, user)
			else if(istype(machine_src, /obj/machinery/f13/grid_client))
				// Player started from a client and ended here — wire the client to this relay.
				var/obj/machinery/f13/grid_client/C = machine_src
				link_client(C, user)
		else if(!GLOB.f13_wire_sessions["[REF(L)]"])
			// No active session — start one from this relay.
			f13_start_wire_session(src, L)
		return

	// ── Wirecutters — sever ALL upstream connections.
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		if(relay_powered && isliving(user))
			var/mob/living/L = user
			to_chat(user, span_danger("You cut into a live cable — electricity surges through you!"))
			L.electrocute_act(30, src, flags = SHOCK_NOGLOVES)
		if(!upstream_refs || !upstream_refs.len)
			to_chat(user, span_notice("[src] has no upstream cable to cut."))
			return
		// Collect names and clear shed tracking before severing.
		var/list/cut_names = list()
		for(var/datum/weakref/W2 in upstream_refs)
			var/obj/upstream_obj = W2.resolve()
			if(!upstream_obj || QDELETED(upstream_obj)) continue
			cut_names += upstream_obj.name
			if(istype(upstream_obj, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = upstream_obj
				if(G.shed_relays) G.shed_relays -= src
		load_shed = FALSE
		_sever_upstream()
		relay_isolated = FALSE
		set_relay_power(FALSE)
		update_icon()
		to_chat(user, span_notice("You cut the cable[cut_names.len > 1 ? "s" : ""] from [src] to [english_list(cut_names)]. [src] and all downstream nodes are now offline."))
		return

	return ..()


/// Wire a generic grid client to this relay as its upstream power source.
/obj/machinery/f13/power_relay/proc/link_client(obj/machinery/f13/grid_client/C, mob/user)
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
	if(relay_powered && isliving(user))
		to_chat(user, span_danger("You connect a cable to a live relay — electricity arcs across your hand!"))
		var/mob/living/UL = user
		UL.electrocute_act(20, src, flags = SHOCK_NOGLOVES)
	C.on_upstream_changed()
	to_chat(user, span_notice("Wired: [C.name] linked to [name]."))
	f13_recalc_all_generators()


/// Link this relay as a downstream child of another relay.
/// Supports multiple upstreams — does NOT sever existing upstream connections.
/obj/machinery/f13/power_relay/proc/set_upstream_relay(obj/machinery/f13/power_relay/parent, mob/user)
	if(!parent || QDELETED(parent))
		return

	// Already wired to this parent — confirm to the player (use wirecutters to disconnect).
	if(_has_upstream(parent))
		to_chat(user, span_notice("[name] is already wired to [parent.name]. Use wirecutters to disconnect."))
		return

	if(!parent.downstream_relays)
		parent.downstream_relays = list()
	if(!(src in parent.downstream_relays))
		parent.downstream_relays += src
	if(!upstream_refs) upstream_refs = list()
	upstream_refs += WEAKREF(parent)
	update_icon()
	if(parent.relay_powered && isliving(user))
		to_chat(user, span_danger("You connect a cable to a live relay — electricity arcs across your hand!"))
		var/mob/living/UL = user
		UL.electrocute_act(20, src, flags = SHOCK_NOGLOVES)
	to_chat(user, span_notice("Wired: [name] → [parent.name]. Power: [parent.relay_powered ? "ONLINE" : "OFFLINE"]."))
	on_upstream_changed()

/// Remove self from ALL upstream owners.
/obj/machinery/f13/power_relay/proc/_sever_upstream()
	if(!upstream_refs)
		return
	for(var/datum/weakref/W in upstream_refs)
		var/upstream = W.resolve()
		if(!upstream) continue
		if(istype(upstream, /obj/machinery/f13/faction_generator))
			var/obj/machinery/f13/faction_generator/G = upstream
			if(G.linked_relays) G.linked_relays -= src
		else if(istype(upstream, /obj/machinery/f13/power_relay))
			var/obj/machinery/f13/power_relay/P = upstream
			if(P.downstream_relays) P.downstream_relays -= src
	upstream_refs = null


// ============================================================
// INTERACT — HAND CLICK
// ============================================================

/obj/machinery/f13/power_relay/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	show_ui(user)

/obj/machinery/f13/power_relay/proc/show_ui(mob/living/user)
	// Build upstream summary from all registered upstream nodes.
	var/list/up_names = list()
	var/list/up_states = list()
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(!up || QDELETED(up)) continue
			up_names += up.name
			var/live = FALSE
			if(istype(up, /obj/machinery/f13/faction_generator)) live = up:powered
			else if(istype(up, /obj/machinery/f13/power_relay)) live = up:relay_powered
			up_states += live ? "<span class='good'>ONLINE</span>" : "<span class='bad'>OFFLINE</span>"
	var/upstream_str
	if(!up_names.len)
		upstream_str = "<span class='dim'>NOT WIRED</span>"
	else
		var/list/parts = list()
		for(var/i = 1; i <= up_names.len; i++)
			parts += "[up_names[i]] [up_states[i]]"
		upstream_str = parts.Join("  |  ")

	// Break down this node's own draw for the UI
	var/self_draw   = RELAY_WATT_DRAW
	var/turret_draw = 0
	var/turret_count = 0
	if(linked_turrets)
		for(var/obj/machinery/porta_turret/T in linked_turrets)
			if(!QDELETED(T))
				turret_count++
				turret_draw += TURRET_WATT_DRAW
	var/downstream_draw = 0
	if(downstream_relays)
		var/list/ui_visited = list(src)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R) && !(R in ui_visited))
				ui_visited += R
				downstream_draw += R.get_subtree_draw(ui_visited)
	var/my_draw = self_draw + turret_draw + downstream_draw

	var/dat = get_terminal_css()
	dat += get_terminal_header("Power Relay Node")
	dat += "<pre class='dim'>  UNIT: [tag ? tag : name]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Status
	var/relay_status_str
	if(relay_powered)
		relay_status_str = "<span class='good'>&#91;ONLINE&#93;</span>"
	else if(load_shed)
		relay_status_str = "<span class='warn'>&#91;LOAD SHED&#93;</span>  <span class='dim'>(generator managing overload — auto-restores when capacity clears)</span>"
	else
		relay_status_str = "<span class='bad'>&#91;OFFLINE&#93;</span>"
	dat += "<pre>  STATUS   : [relay_status_str]</pre>"
	dat += "<pre>  UPSTREAM : [upstream_str]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Power draw breakdown
	dat += "<pre class='head'>  &#91;POWER DRAW BREAKDOWN&#93;</pre>"
	dat += "<pre>  NODE SELF     : [self_draw]W</pre>"
	if(turret_count > 0)
		dat += "<pre>  TURRETS ([turret_count]x)  : [turret_draw]W  <span class='dim'>([turret_count] x [TURRET_WATT_DRAW]W)</span></pre>"
	else
		dat += "<pre class='dim'>  TURRETS       : none</pre>"
	dat += "<pre>  DOWNSTREAM    : [downstream_draw]W</pre>"
	dat += "<pre>  SUBTREE TOTAL : <b>[my_draw]W</b></pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Powered areas
	dat += "<pre class='head'>  &#91;POWERED ZONES&#93;</pre>"
	if(powered_area_instances && powered_area_instances.len)
		for(var/area/A in powered_area_instances)
			if(!QDELETED(A))
				dat += "<pre>    &gt; [A.name]</pre>"
	else
		dat += "<pre class='dim'>    &gt; none configured</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Downstream relays
	dat += "<pre class='head'>  &#91;DOWNSTREAM RELAYS&#93;</pre>"
	if(downstream_relays && downstream_relays.len)
		var/list/ds_visited = list(src)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				var/rstate
				if(R.relay_powered)
					rstate = "<span class='good'>ONLINE </span>"
				else if(R.load_shed)
					rstate = "<span class='warn'>&#91;SHED&#93; </span>"
				else
					rstate = "<span class='bad'>OFFLINE</span>"
				ds_visited += R
				dat += "<pre>    &gt; [R.name]  [rstate]  [R.get_subtree_draw(ds_visited)]W</pre>"
	else
		dat += "<pre class='dim'>    &gt; none  (use a cable coil on this relay, then on a downstream relay)</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Generic grid clients
	dat += "<pre class='head'>  &#91;WIRED DEVICES&#93;</pre>"
	if(linked_clients && linked_clients.len)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				var/cstate = C.grid_powered ? "<span class='good'>ONLINE  [C.grid_watt_draw]W</span>" : "<span class='bad'>OFFLINE [C.grid_watt_draw]W</span>"
				dat += "<pre>    &gt; [C.name]  [cstate]</pre>"
	else
		dat += "<pre class='dim'>    &gt; none  (use a cable coil on this relay, then on any compatible device)</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Tip
	dat += "<pre class='dim'>  MAINTENANCE: wrench = repair (offline) / anchor (online)</pre>"
	dat += "<pre class='dim'>  INTEGRITY  : [obj_integrity] / [max_integrity]</pre>"
	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_relay_[REF(src)]", null, 520, 480)
	popup.set_content(dat)
	popup.open()


// ============================================================
// ICON
// ============================================================

/obj/machinery/f13/power_relay/update_icon_state()
	icon_state = ""
	color = relay_powered ? "#5ddb8a" : null

/obj/machinery/f13/power_relay/examine(mob/user)
	. = ..()
	var/list/up_names = list()
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(up && !QDELETED(up)) up_names += up.name
	if(relay_powered)
		. += span_notice("A bundle of thick cables connects it to the power grid. Indicator lights glow steadily — it's live.")
	else if(up_names.len)
		. += span_notice("Cables run from its base toward [english_list(up_names)], but the connection isn't carrying any power right now.")
	else
		. += span_warning("No power cables are attached. Wire it to a generator or upstream relay to bring it online.")


// ============================================================
// STAMP ZONE (called by master_breaker re-stamp pass)
// ============================================================

/// Stamp all owned areas with the given power state without cascading to downstream relays.
/// Used by master_breaker so it can iterate all relays itself and re-stamp each one individually.
/obj/machinery/f13/power_relay/proc/stamp_zone(state)
	if(!powered_area_instances)
		return
	for(var/area/A in powered_area_instances)
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
// WASTELAND RELAY — Salvage-built distribution node
// ============================================================

/// Jury-rigged relay post built from scavenged automotive and building parts.
/// When powered, automatically stamps the area it physically sits in so that
/// lights and doors in that space work without needing powered_area_types entries
/// on every post.  Outdoor/wasteland areas are skipped — they are always-powered
/// and stamping them would iterate every machine in the area.
/// If the mapper explicitly sets powered_area_types, that configuration is used
/// instead of the auto-stamp (allows sub-zone overrides on specific posts).
/obj/machinery/f13/power_relay/wasteland
	name          = "cobbled relay post"
	desc          = "Power distribution on a shoestring: an automotive fuse block, lamp cord, and a junction box that has seen better decades, all clamped to a rebar post with pipe fittings. Carries power down the line just as well as the original. Mostly."
	/// Radius in tiles — must match the wastelander generator's power_reach.
	var/power_reach = 10
	/// Cached list of /obj/machinery/light within power_reach in the relay's own area.
	/// Built once on the first stamp_zone() call; reused on every subsequent toggle.
	var/list/range_light_cache = null

/// Before delegating to the base set_relay_power(), fix powered_area_instances to empty
/// so no area-level stamp fires.  Lights are handled by stamp_zone() override instead.
/obj/machinery/f13/power_relay/wasteland/set_relay_power(new_state)
	// Early-exit before any work — mirrors the guard in the base proc.
	if(relay_powered == new_state)
		return
	// Ensure powered_area_instances is resolved (empty — no area stamp).
	if(powered_area_instances == null && !powered_area_types)
		powered_area_instances = list()
	..()  // sets relay_powered, cascades downstream
	// Power lights within range in own area only.
	stamp_zone(relay_powered)

/// Kill emergency mode on nearby lights at round-start when this relay starts offline.
/obj/machinery/f13/power_relay/wasteland/LateInitialize()
	. = ..()
	if(relay_powered)
		return  // generator already stamped these lights live
	spawn(4)  // after lights' deferred update(0) fires (~0.3s from init)
		if(!QDELETED(src) && !relay_powered)
			stamp_zone(FALSE)

/// Override: directly seton() lights within power_reach in own area only.
/// Does NOT call ..() so base area-stamp logic is bypassed entirely.
/obj/machinery/f13/power_relay/wasteland/stamp_zone(state)
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
				L.seton(L.status == LIGHT_OK)
			else
				// seton(FALSE) triggers update() which re-enables emergency_mode.
				// Kill the light directly so it goes dark instead of red.
				L.on = FALSE
				L.emergency_mode = FALSE
				L.set_light(0)
				L.update_icon()


// ============================================================
// BREAKER BOX — Inline manual cutoff switch
// ============================================================
//
// Wire it between the generator (or upstream relay) and downstream devices.
// Acts as a parallel cut switch for its subtree — opening this panel kills
// everything downstream without affecting the generator or sibling branches.
// When closed, power flows normally and each downstream junction box honours
// its own master breaker and per-zone breakers.
//
// Behaves as a standard relay in all other respects: wiring, area stamps,
// turret links, load-shedding exclusion.
// ============================================================

/// Inline power cutoff panel.  Wire upstream to the generator; wire downstream
/// to relays or junction boxes.  Click to open the panel UI; toggle the lever
/// there to cut or restore the downstream subtree.
/obj/machinery/f13/power_relay/breaker_box
	name          = "main breaker panel"
	desc          = "A heavy-duty disconnect panel — wired between the generator and the rest of the installation so you can cut power to everything downstream without touching the generator. The lever positions are labelled ON and OFF. Someone scratched them out and wrote LIVE and DEAD."

	/// TRUE when the player has manually opened (tripped) this breaker.
	/// While set, upstream power-restore cascades are ignored — only a direct
	/// hand interaction via the panel UI can bring it back online.
	var/manually_tripped = FALSE

/// Override: honour manually_tripped so upstream cascades don't silently restore
/// a breaker the player deliberately opened.  When the grid tries to turn us ON
/// but the breaker is open, the downstream is kept dead; when the grid dies we
/// always propagate the outage regardless of the manual flag.
/obj/machinery/f13/power_relay/breaker_box/set_relay_power(new_state)
	if(new_state && manually_tripped)
		// Grid trying to restore but player left the breaker open — keep downstream dead.
		if(relay_powered)
			relay_powered = FALSE
			update_icon()
			if(downstream_relays)
				for(var/obj/machinery/f13/power_relay/R in downstream_relays)
					if(!QDELETED(R))
						R.set_relay_power(FALSE)
			if(linked_clients)
				for(var/obj/machinery/f13/grid_client/C in linked_clients)
					if(!QDELETED(C))
						C.on_grid_power_change(FALSE)
		return
	return ..()

/// Override: amber tint when manually tripped so the panel is visually distinct
/// from a relay that is simply offline due to a dead upstream.
/obj/machinery/f13/power_relay/breaker_box/update_icon_state()
	icon_state = ""
	if(relay_powered)
		color = "#5ddb8a"    // green — circuit live
	else if(manually_tripped)
		color = "#e8a020"    // amber — operator has opened this panel
	else
		color = null         // no tint — upstream is dead

/// Open the breaker panel UI instead of toggling directly.
/obj/machinery/f13/power_relay/breaker_box/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	show_ui(user)

/// Terminal-style panel UI that shows circuit state and downstream junction-box
/// zone detail, then offers a single close/open lever control.
/obj/machinery/f13/power_relay/breaker_box/show_ui(mob/living/user)
	// Use first registered upstream for display (same as old single-upstream behaviour).
	var/obj/upstream = null
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			upstream = W.resolve()
			if(upstream && !QDELETED(upstream)) break
			upstream = null
	var/upstream_name = upstream ? upstream.name : "NONE"
	var/upstream_live = FALSE
	if(upstream)
		if(istype(upstream, /obj/machinery/f13/faction_generator))
			upstream_live = upstream:powered
		else if(istype(upstream, /obj/machinery/f13/power_relay))
			upstream_live = upstream:relay_powered

	var/dat = get_terminal_css()
	dat += get_terminal_header("Main Breaker Panel")
	dat += "<pre class='dim'>  UNIT: [tag ? tag : name]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Circuit status
	var/circuit_str
	if(manually_tripped)
		circuit_str = "<span class='warn'>&#91;CIRCUIT OPEN — MANUALLY TRIPPED&#93;</span>"
	else if(relay_powered)
		circuit_str = "<span class='good'>&#91;CIRCUIT CLOSED — LIVE&#93;</span>"
	else
		circuit_str = "<span class='bad'>&#91;CIRCUIT OPEN — UPSTREAM DEAD&#93;</span>"
	dat += "<pre>  CIRCUIT  : [circuit_str]</pre>"
	dat += "<pre>  UPSTREAM : [upstream_name]  [upstream ? "<span class='[(upstream_live ? "good" : "bad")]'>[upstream_live ? "ONLINE" : "OFFLINE"]</span>" : "<span class='dim'>NOT WIRED</span>"]</pre>"
	dat += "<pre class='dim'>             Upstream stays live when this breaker opens — it feeds the rest of the grid.</pre>"
	dat += "<pre class='dim'>             Only devices wired <b>to this panel</b> lose power when the breaker is opened.</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Lever control
	dat += "<pre class='head'>  &#91;BREAKER CONTROL&#93;</pre>"
	if(!upstream_refs || !upstream_refs.len)
		dat += "<pre class='dim'>    Panel not wired to an upstream source — cannot operate.</pre>"
	else if(relay_powered)
		dat += "<pre>    <a href='byond://?src=[REF(src)];breaker_toggle=1'>&#91; OPEN BREAKER — CUT DOWNSTREAM &#93;</a></pre>"
		dat += "<pre class='dim'>    Kills all downstream circuits; junction-box zone-breaker states are preserved.</pre>"
	else
		dat += "<pre>    <a href='byond://?src=[REF(src)];breaker_toggle=1'>&#91; CLOSE BREAKER — RESTORE DOWNSTREAM &#93;</a></pre>"
		dat += "<pre class='dim'>    Downstream junction boxes will restore only their closed-breaker zones.</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Downstream circuit inventory
	dat += "<pre class='head'>  &#91;DOWNSTREAM CIRCUITS&#93;</pre>"
	var/found_any = FALSE
	// Direct downstream relays (non-junction-box relay nodes)
	if(downstream_relays && downstream_relays.len)
		var/list/inv_visited = list(src)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(QDELETED(R))
				continue
			var/rstate = R.relay_powered ? "<span class='good'>LIVE</span>" : "<span class='bad'>DEAD</span>"
			inv_visited += R
			dat += "<pre>  RELAY: [R.name]  [rstate]  [R.get_subtree_draw(inv_visited)]W</pre>"
			found_any = TRUE
	// Direct grid clients — show junction boxes with zone detail, others briefly
	if(linked_clients && linked_clients.len)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(QDELETED(C))
				continue
			found_any = TRUE
			if(istype(C, /obj/machinery/f13/junction_box))
				var/obj/machinery/f13/junction_box/JB = C
				var/jstate = (JB.grid_powered && JB.breaker_closed) ? "<span class='good'>LIVE</span>" : "<span class='bad'>DEAD</span>"
				var/mstate = JB.breaker_closed ? "<span class='good'>CLOSED</span>" : "<span class='warn'>TRIPPED</span>"
				dat += "<pre>  JBOX : [JB.name]  [jstate]  master: [mstate]  [JB.grid_watt_draw]W</pre>"
				if(JB.owned_zones && JB.zone_breakers)
					for(var/area/f13/Z in JB.owned_zones)
						if(!QDELETED(Z))
							var/zb     = JB.zone_breakers[Z]
							var/zlive  = Z.power_equip
							var/zstate = zlive ? "<span class='good'>LIVE  </span>" : "<span class='bad'>DEAD  </span>"
							var/zbstr  = zb    ? "<span class='good'>&#91;CLOSED&#93; </span>" : "<span class='warn'>&#91;TRIPPED&#93;</span>"
							dat += "<pre class='dim'>           |-- [zstate] [zbstr]  [Z.name]</pre>"
			else
				var/cstate = C.grid_powered ? "<span class='good'>LIVE</span>" : "<span class='bad'>DEAD</span>"
				dat += "<pre>  DEV  : [C.name]  [cstate]  [C.grid_watt_draw]W</pre>"
	if(!found_any)
		dat += "<pre class='dim'>    No downstream devices wired.</pre>"
	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_breaker_[REF(src)]", null, 560, 460)
	popup.set_content(dat)
	popup.open()

/// Handle lever-toggle clicks from the panel UI.
/obj/machinery/f13/power_relay/breaker_box/Topic(href, href_list)
	var/mob/living/U = usr
	if(!U || !istype(U))
		return
	if(!in_range(src, U) && !isobserver(U))
		return

	if(href_list["breaker_toggle"])
		var/new_state = !relay_powered
		manually_tripped = !new_state   // opening = tripped; closing = cleared
		set_relay_power(new_state)
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		U.visible_message(
			"[U] [new_state ? "closes" : "opens"] the main breaker on [src].",
			span_notice("You [new_state ? "close the main breaker — power restored to downstream circuits." : "open the main breaker — everything downstream is now dead."]")
		)
		// Notify the upstream generator immediately so watt accounting stays current.
		f13_recalc_all_generators()
		show_ui(U)

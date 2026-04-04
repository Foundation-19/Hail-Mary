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
	icon          = 'icons/obj/power.dmi'
	icon_state    = "portgen0_0"
	density       = TRUE
	anchored      = TRUE
	max_integrity = 350
	armor         = list(melee = 10, bullet = 10, laser = 5, energy = 5, bomb = 20, bio = 0, rad = 0, fire = 25, acid = 15)
	// Relay routes power — it doesn't consume from the area power system.
	use_power     = NO_POWER_USE

	// ── Wiring ─────────────────────────────────────────────
	/// Weakref to the upstream generator or relay feeding this node.
	var/datum/weakref/upstream_ref = null
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
	/// Set TRUE after the first power-on cable scan so we don't re-scan on every toggle.
	var/cable_scan_done = FALSE


// ============================================================
// LIFECYCLE
// ============================================================

/obj/machinery/f13/power_relay/Initialize()
	. = ..()
	resolve_map_links()
	// Relay starts unpowered; the upstream must wire in and send power.

/obj/machinery/f13/power_relay/Destroy()
	// Cut upstream link.
	var/upstream = upstream_ref ? upstream_ref.resolve() : null
	if(upstream)
		if(istype(upstream, /obj/machinery/f13/faction_generator))
			var/obj/machinery/f13/faction_generator/G = upstream
			if(G.linked_relays)
				G.linked_relays -= src
		else if(istype(upstream, /obj/machinery/f13/power_relay))
			var/obj/machinery/f13/power_relay/P = upstream
			if(P.downstream_relays)
				P.downstream_relays -= src
	upstream_ref = null

	// Kill downstream chain before we vanish.
	if(downstream_relays)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				R.upstream_ref = null
				R.set_relay_power(FALSE)

	// Disconnect generic grid clients.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.upstream_ref = null
				C.on_grid_power_change(FALSE)
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
				if(R.tag == target_tag && !(R in downstream_relays))
					downstream_relays += R
					R.upstream_ref = WEAKREF(src)

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
					C.upstream_ref = WEAKREF(src)


/// Walk this relay's subtree and return total watt draw (self + downstream).
/// Self draw = RELAY_WATT_DRAW + owned turrets + any wired fabricators if this relay has them.
/obj/machinery/f13/power_relay/proc/get_subtree_draw()
	if(!relay_powered)
		return 0  // offline relay draws nothing
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
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				draw += R.get_subtree_draw()
	return draw


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

	// Cascade to downstream relays.
	if(downstream_relays)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				R.set_relay_power(relay_powered)

	// Propagate to generic grid clients.
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				C.on_grid_power_change(relay_powered)


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

	// Downstream relays — their set_relay_power will trigger their own scans.
	for(var/obj/machinery/f13/power_relay/R in world)
		if(QDELETED(R) || R.upstream_ref || R == src)
			continue
		if(f13_cable_path_exists(src_turf, get_turf(R)))
			if(!downstream_relays)
				downstream_relays = list()
			if(!(R in downstream_relays))
				downstream_relays += R
				R.upstream_ref = WEAKREF(src)
				// set_relay_power is called in the cascade below

	// Generic grid clients (junction boxes, etc.).
	for(var/obj/machinery/f13/grid_client/C in world)
		if(QDELETED(C) || C.upstream_ref)
			continue
		if(f13_cable_path_exists(src_turf, get_turf(C)))
			if(!linked_clients)
				linked_clients = list()
			if(!(C in linked_clients))
				linked_clients += C
				C.upstream_ref = WEAKREF(src)
				// on_grid_power_change is called in the cascade below

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

	// ── Wirecutters — sever the upstream connection.
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		if(relay_powered && isliving(user))
			var/mob/living/L = user
			to_chat(user, span_danger("You cut into a live cable — electricity surges through you!"))
			L.electrocute_act(30, src, flags = SHOCK_NOGLOVES)
		if(!upstream_ref)
			to_chat(user, span_notice("[src] has no upstream cable to cut."))
			return
		var/obj/upstream_obj = upstream_ref.resolve()
		var/upstream_name = upstream_obj ? upstream_obj.name : "upstream"
		// Remove from generator's shed tracking before severing.
		if(istype(upstream_obj, /obj/machinery/f13/faction_generator))
			var/obj/machinery/f13/faction_generator/G = upstream_obj
			if(G.shed_relays) G.shed_relays -= src
		load_shed = FALSE
		_sever_upstream()
		set_relay_power(FALSE)
		update_icon()  // ensure wired-but-offline tint clears if generator was already offline
		to_chat(user, span_notice("You cut the cable from [src] to [upstream_name]. [src] and all downstream nodes are now offline."))
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
	C.on_grid_power_change(relay_powered)
	to_chat(user, span_notice("Wired: [C.name] linked to [name]."))
	// Tell the generator upstream to recalc its watt budget.
	var/obj/up = upstream_ref ? upstream_ref.resolve() : null
	while(up)
		if(istype(up, /obj/machinery/f13/faction_generator))
			var/obj/machinery/f13/faction_generator/G = up
			G.recalc_draw()
			break
		else if(istype(up, /obj/machinery/f13/power_relay))
			var/obj/machinery/f13/power_relay/R = up
			up = R.upstream_ref ? R.upstream_ref.resolve() : null
		else
			break


/// Link this relay as a downstream child of another relay.
/obj/machinery/f13/power_relay/proc/set_upstream_relay(obj/machinery/f13/power_relay/parent, mob/user)
	if(!parent || QDELETED(parent))
		return

	// Already wired to this parent — confirm to the player (use wirecutters to disconnect).
	if(upstream_ref && upstream_ref.resolve() == parent)
		to_chat(user, span_notice("[name] is already wired to [parent.name]. Use wirecutters to disconnect."))
		return

	// Cut any existing upstream.
	_sever_upstream()

	if(!parent.downstream_relays)
		parent.downstream_relays = list()
	parent.downstream_relays += src
	upstream_ref = WEAKREF(parent)
	update_icon()
	to_chat(user, span_notice("Wired: [name] → [parent.name]. Power: [parent.relay_powered ? "ONLINE" : "OFFLINE"]."))
	set_relay_power(parent.relay_powered)

/// Remove self from whatever upstream currently owns us.
/obj/machinery/f13/power_relay/proc/_sever_upstream()
	if(!upstream_ref)
		return
	var/upstream = upstream_ref.resolve()
	if(!upstream)
		upstream_ref = null
		return
	if(istype(upstream, /obj/machinery/f13/faction_generator))
		var/obj/machinery/f13/faction_generator/G = upstream
		if(G.linked_relays)
			G.linked_relays -= src
	else if(istype(upstream, /obj/machinery/f13/power_relay))
		var/obj/machinery/f13/power_relay/P = upstream
		if(P.downstream_relays)
			P.downstream_relays -= src
	upstream_ref = null


// ============================================================
// INTERACT — HAND CLICK
// ============================================================

/obj/machinery/f13/power_relay/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	show_ui(user)

/obj/machinery/f13/power_relay/proc/show_ui(mob/living/user)
	var/upstream = upstream_ref ? upstream_ref.resolve() : null
	var/obj/upstream_obj = upstream
	var/upstream_name  = upstream_obj ? upstream_obj.name : "NONE"
	var/upstream_state = "OFFLINE"
	if(upstream)
		if(istype(upstream, /obj/machinery/f13/faction_generator))
			upstream_state = (upstream:powered) ? "ONLINE" : "OFFLINE"
		else if(istype(upstream, /obj/machinery/f13/power_relay))
			upstream_state = (upstream:relay_powered) ? "ONLINE" : "OFFLINE"

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
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				downstream_draw += R.get_subtree_draw()
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
	dat += "<pre>  UPSTREAM : [upstream_name]  [upstream ? "<span class='[(upstream_state == "ONLINE") ? "good" : "bad"]'>[upstream_state]</span>" : "<span class='dim'>NOT WIRED</span>"]</pre>"
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
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				var/rstate
				if(R.relay_powered)
					rstate = "<span class='good'>ONLINE </span>"
				else if(R.load_shed)
					rstate = "<span class='warn'>&#91;SHED&#93; </span>"
				else
					rstate = "<span class='bad'>OFFLINE</span>"
				dat += "<pre>    &gt; [R.name]  [rstate]  [R.get_subtree_draw()]W</pre>"
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
	icon_state = relay_powered ? "portgen0_1" : "portgen0_0"

/obj/machinery/f13/power_relay/examine(mob/user)
	. = ..()
	var/obj/upstream = upstream_ref ? upstream_ref.resolve() : null
	if(relay_powered)
		. += span_notice("A bundle of thick cables connects it to the power grid. Indicator lights glow steadily — it's live.")
	else if(upstream)
		. += span_notice("Cables run from its base toward [upstream.name], but the connection isn't carrying any power right now.")
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


// ============================================================
// WASTELAND RELAY — Salvage-built distribution node
// ============================================================

/// Jury-rigged relay post built from scavenged automotive and building parts.
/// Functionally identical to the standard power relay.  Wire it the same way.
/obj/machinery/f13/power_relay/wasteland
	name          = "cobbled relay post"
	desc          = "Power distribution on a shoestring: an automotive fuse block, lamp cord, and a junction box that has seen better decades, all clamped to a rebar post with pipe fittings. Carries power down the line just as well as the original. Mostly."


// ============================================================
// BREAKER BOX — Inline manual cutoff switch
// ============================================================
//
// Wire it between the generator (or upstream relay) and downstream devices.
// Activate by hand to toggle power to everything downstream without shutting
// the generator off.  Useful as the main on/off switch for a jury-rigged setup.
//
// Behaves as a standard relay in all other respects: wiring, area stamps,
// turret links, load-shedding exclusion.
// ============================================================

/// Inline power cutoff panel.  Wire upstream to the generator; wire downstream
/// to relays or junction boxes.  Toggle by hand to cut or restore downstream power.
/obj/machinery/f13/power_relay/breaker_box
	name          = "main breaker panel"
	desc          = "A heavy-duty disconnect panel — wired between the generator and the rest of the installation so you can cut power to everything downstream without touching the generator. The lever positions are labelled ON and OFF. Someone scratched them out and wrote LIVE and DEAD."

/obj/machinery/f13/power_relay/breaker_box/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	var/new_state = !relay_powered
	set_relay_power(new_state)
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	user.visible_message(
		"[user] [new_state ? "closes" : "opens"] the main breaker on [src].",
		span_notice("You [new_state ? "close the main breaker — power restored downstream." : "open the main breaker — everything downstream is now dead."]")
	)

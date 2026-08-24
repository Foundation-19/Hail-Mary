// ============================================================
// POWER GRID — GRID CLIENT MIXIN
// ============================================================
//
// Any /obj/machinery can become a grid-powered device by
// inheriting from /obj/machinery/f13/grid_client.
//
// USAGE:
//   /obj/machinery/my_machine
//       parent_type   = /obj/machinery/f13/grid_client
//       grid_watt_draw = 150  // optional — default is GRID_CLIENT_WATT_DEFAULT
//
//   /obj/machinery/my_machine/on_grid_power_change(new_state)
//       . = ..()    // sets grid_powered, calls update_icon()
//       // add your own reaction to power going on / off
//
// WIRING:
//   Same as all other grid machines — use a cable coil on the
//   source machine (generator or relay), lay cable to this one,
//   then click this machine with the same coil to complete.
//   Wirecutters on this machine severes the upstream connection.
//
// LOAD SHEDDING:
//   Grid clients are the lowest-priority load.  The generator
//   will suspend them last and restore them first.
//   on_grid_power_change(FALSE) is called when shed;
//   on_grid_power_change(TRUE) when restored.
// ============================================================

/obj/machinery/f13/grid_client
	/// List of WEAKREFs to every generator or relay feeding this machine.
	/// Multiple entries allow parallel / redundant feeds (OR logic).
	var/list/upstream_refs = null
	/// Current power state as set by the upstream grid node.
	var/grid_powered = FALSE
	/// Watts this machine draws continuously from the grid.
	var/grid_watt_draw = GRID_CLIENT_WATT_DEFAULT
	/// Load-shedding priority.  Higher value = shed first when the grid is over capacity.
	/// Default 0 (shed last).  Set higher on high-draw machines (e.g. fabricators = 10).
	var/grid_shed_priority = 0
	// Grid clients track their own power via grid_powered / on_grid_power_change().
	// They must not participate in the SS13 area power system.
	use_power = NO_POWER_USE


// ============================================================
// OVERRIDE HOOK
// ============================================================

/// Called by the grid whenever power is turned on or off.
/// Base implementation sets grid_powered and refreshes the icon.
/// Override to react to power changes; always call ..() first.
/obj/machinery/f13/grid_client/proc/on_grid_power_change(new_state)
	grid_powered = new_state
	update_icon()

/// Called by the generator when it load-sheds this client to ease grid pressure.
/// Base implementation delegates to on_grid_power_change(FALSE).
/// Override to provide a distinct visible message or stop running processes.
/obj/machinery/f13/grid_client/proc/on_load_shed()
	on_grid_power_change(FALSE)

/// Called by the generator when load-shedding is cleared and this client is restored.
/// Base implementation delegates to on_grid_power_change(TRUE).
/// Override to provide a distinct restore message.
/obj/machinery/f13/grid_client/proc/on_load_shed_restore()
	on_grid_power_change(TRUE)

/// Recalculate this client's power state from all registered upstream nodes.
/// Uses OR logic: powered if ANY upstream is live.  Called when upstream topology changes.
/obj/machinery/f13/grid_client/proc/on_upstream_changed()
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
	on_grid_power_change(any_live)

/// Returns TRUE if /obj/target is already registered in upstream_refs.
/obj/machinery/f13/grid_client/proc/_has_upstream(obj/target)
	if(!upstream_refs || !target)
		return FALSE
	for(var/datum/weakref/W in upstream_refs)
		if(W.resolve() == target)
			return TRUE
	return FALSE


// ============================================================
// LIFE CYCLE
// ============================================================

/obj/machinery/f13/grid_client/Destroy()
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/upstream = W.resolve()
			if(!upstream || QDELETED(upstream))
				continue
			if(istype(upstream, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = upstream
				if(G.linked_clients) G.linked_clients -= src
				G.recalc_draw()
			else if(istype(upstream, /obj/machinery/f13/power_relay))
				var/obj/machinery/f13/power_relay/R = upstream
				if(R.linked_clients) R.linked_clients -= src
		upstream_refs = null
	return ..()


// ============================================================
// EXAMINE
// ============================================================

/obj/machinery/f13/grid_client/examine(mob/user)
	. = ..()
	var/list/up_names = list()
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(up && !QDELETED(up)) up_names += up.name
	if(grid_powered)
		. += span_notice("Power cables connect it to [up_names.len ? english_list(up_names) : "the grid"]. Indicator lights confirm it's live.")
	else if(up_names.len)
		. += span_notice("Cables run to [english_list(up_names)], but no power is currently flowing through the line.")
	else
		. += span_warning("No power cables are attached. Wire it to a generator or relay to bring it online.")


// ============================================================
// INTERACTION — CABLE COIL + WIRECUTTERS
// ============================================================

/obj/machinery/f13/grid_client/attackby(obj/item/W, mob/user, params)
	// ── Cable coil — wiring interface.
	if(istype(W, /obj/item/stack/cable_coil))
		if(!isliving(user))
			return
		var/mob/living/L = user
		var/obj/machinery/machine_src = f13_try_complete_wire(src, L)
		if(machine_src)
			// This machine is the destination — source must be an upstream node.
			if(istype(machine_src, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = machine_src
				G.link_client(src, user)
			else if(istype(machine_src, /obj/machinery/f13/power_relay))
				var/obj/machinery/f13/power_relay/R = machine_src
				R.link_client(src, user)
			else
				to_chat(user, span_warning("Can't wire [machine_src.name] to [name] — only generators and relays can feed power to this device."))
		else if(!GLOB.f13_wire_sessions["[REF(L)]"])
			// No active session — start one from this machine.
			f13_start_wire_session(src, L)
		return

	// ── Wirecutters — sever all upstream connections.
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		if(!upstream_refs || !upstream_refs.len)
			to_chat(user, span_notice("No cable connection to cut."))
			return
		var/list/cut_names = list()
		for(var/datum/weakref/WC in upstream_refs)
			var/obj/upstream = WC.resolve()
			if(!upstream || QDELETED(upstream))
				continue
			cut_names += upstream.name
			if(istype(upstream, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = upstream
				if(G.linked_clients) G.linked_clients -= src
				if(G.shed_clients) G.shed_clients -= src
				G.recalc_draw()
			else if(istype(upstream, /obj/machinery/f13/power_relay))
				var/obj/machinery/f13/power_relay/R = upstream
				if(R.linked_clients) R.linked_clients -= src
		upstream_refs = null
		on_grid_power_change(FALSE)
		to_chat(user, span_notice("You cut the cable connection[cut_names.len > 1 ? "s" : ""] to [cut_names.len ? english_list(cut_names) : "upstream"]."))
		return

	return ..()

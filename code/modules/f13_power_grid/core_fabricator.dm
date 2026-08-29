// ============================================================
// CORE FABRICATOR
// ============================================================
//
// Crafts new fusion cores (or recycles depleted ones) for a
// faction base generator.  The fabricator MUST be wired to a
// faction_generator via cable coil before it can operate.
// It checks its linked generator's `powered` var directly —
// area power is not used here.
//
// WIRING (cable coil):
//   Option A — generator first:
//     1. Use a cable coil on the faction_generator → marks it as the wire source.
//     2. Use the same coil on this fabricator → link established (consumes 2 cable).
//   Option B — fabricator first:
//     1. Use a cable coil on this fabricator → marks it as the wire source.
//     2. Use the same coil on the faction_generator → link established (consumes 2 cable).
//   Wirecutters on either machine severs the connection.
//
// CRAFT REQUIREMENTS (fresh core):
//   FAB_REQ_URANIUM      uranium ore/sheets
//   FAB_REQ_METALPARTS   metal parts
//   FAB_REQ_ELECTRONICPARTS    electronic parts
//
// RECYCLE REQUIREMENTS (depleted core + smaller material top-up):
//   FAB_REQ_URANIUM_RECYCLE
//   FAB_REQ_METALPARTS_RECYCLE
//   FAB_REQ_ELECTRONICPARTS_RECYCLE
//   (one depleted fusion core must also be in the fabricator)
// ============================================================

/obj/machinery/f13/core_fabricator
	parent_type = /obj/machinery/f13/grid_client
	name = "core fabricator"
	desc = "A heavy industrial fabricator that assembles or recycles fusion cores. Requires a wired power connection to a faction base generator."
	icon = 'icons/fallout/machines/64x32.dmi'
	icon_state = "generator_off"
	density = TRUE
	anchored = TRUE
	max_integrity = 500
	armor = list(melee = 10, bullet = 5, laser = 5, energy = 5, bomb = 15, bio = 0, rad = 0, fire = 20, acid = 10)
	// Power state is managed via on_grid_power_change() / on_load_shed() from grid_client.
	use_power = NO_POWER_USE
	// Fabricators draw more when actively crafting; updated whenever fab_state changes.
	grid_watt_draw = FAB_WATT_DRAW_IDLE
	// Shed fabricators before generic low-draw clients (e.g. junction boxes).
	grid_shed_priority = 10

	// ── Internal material storage.
	var/stocked_uranium     = 0
	var/stocked_metalparts  = 0
	var/stocked_electronicparts   = 0
	var/has_depleted_core   = FALSE   // One depleted core for recycle jobs.

	// ── Crafting state.
	var/fab_state  = FAB_STATE_IDLE
	var/progress   = 0               // Ticks elapsed of current craft job.

	// ── Lock system (mirrors generator, same defines).
	var/lock_mode     = GENERATOR_LOCK_NONE
	var/owner_ckey    = null
	/// Display name (real_name) of the personal lock owner, shown in the UI.
	var/owner_name    = null
	var/owner_faction = null
	/// When TRUE the next ID-card swipe registers a personal owner.
	var/pending_personal_reg = FALSE
	/// When TRUE the next ID-card swipe registers a faction owner.
	var/pending_faction_reg  = FALSE
	/// Mobs currently viewing the UI — refreshed each process() tick while crafting.
	var/list/ui_watchers = list()


// ============================================================
// WIRING HELPERS
// ============================================================

/// Resolve the upstream generator.  Returns null if unwired or the upstream is not a generator.
/obj/machinery/f13/core_fabricator/proc/get_linked_generator()
	if(!upstream_refs || !upstream_refs.len)
		return null
	for(var/datum/weakref/W in upstream_refs)
		var/obj/machinery/f13/faction_generator/G = W.resolve()
		if(G && !QDELETED(G) && istype(G, /obj/machinery/f13/faction_generator))
			return G
	return null

/// Override: react to upstream going on or off (hard power failure or reconnect).
/obj/machinery/f13/core_fabricator/on_grid_power_change(new_state)
	. = ..()  // sets grid_powered, calls update_icon()
	if(!new_state)
		// Hard power loss — stop any active fabrication job.
		if(fab_state == FAB_STATE_CRAFTING)
			STOP_PROCESSING(SSobj, src)
			fab_state        = FAB_STATE_IDLE
			grid_watt_draw   = FAB_WATT_DRAW_IDLE
			progress         = 0
			update_icon()
			ui_watchers      = list()
			visible_message(span_warning("[src] hums down — generator offline."))

/// Override: load-shedding suspends this fabricator to ease grid pressure.
/obj/machinery/f13/core_fabricator/on_load_shed()
	if(fab_state == FAB_STATE_CRAFTING)
		STOP_PROCESSING(SSobj, src)
		fab_state      = FAB_STATE_IDLE
		grid_watt_draw = FAB_WATT_DRAW_IDLE
		progress       = 0
		update_icon()
		// Push a final UI refresh so the terminal shows [LOAD SHED] immediately.
		for(var/mob/living/M in ui_watchers)
			if(M && !QDELETED(M) && Adjacent(M))
				show_ui(M)
		ui_watchers = list()
		visible_message(span_warning("[src] halts — generator load shedding active. Power will auto-restore."))
	else
		update_icon()
		visible_message(span_warning("[src] powers down — grid overload load-shedding in progress."))

/// Called by the generator when a shed is cleared and this fabricator is restored.
/// The fabricator returns to idle standby; the player must manually restart crafting.
/obj/machinery/f13/core_fabricator/on_load_shed_restore()
	update_icon()
	visible_message(span_notice("[src] returns to standby — load shed cleared, power restored."))

/// Tell the upstream node to re-tally its watt budget.
/// Called whenever fab_state changes so overload is detected immediately.
/obj/machinery/f13/core_fabricator/proc/_notify_generator_draw_changed()
	var/obj/upstream = null
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(up && !QDELETED(up)) { upstream = up; break }
	if(!upstream || QDELETED(upstream))
		return
	if(istype(upstream, /obj/machinery/f13/faction_generator))
		var/obj/machinery/f13/faction_generator/G = upstream
		G.recalc_draw()


// ============================================================
// LIFE CYCLE
// ============================================================

/obj/machinery/f13/core_fabricator/Destroy()
	if(fab_state == FAB_STATE_CRAFTING)
		STOP_PROCESSING(SSobj, src)
	ui_watchers = list()
	return ..()  // grid_client.Destroy() handles upstream_refs / linked_clients cleanup


// ============================================================
// PROCESSING — craft tick (SSobj fires every ~2 s, only while crafting)
// ============================================================

/obj/machinery/f13/core_fabricator/process()
	// Abort gracefully if power has gone away between ticks.
	if(!grid_powered)
		fab_state      = FAB_STATE_IDLE
		grid_watt_draw = FAB_WATT_DRAW_IDLE
		progress       = 0
		update_icon()
		visible_message(span_warning("[src] hums down — generator offline."))
		ui_watchers = list()
		return PROCESS_KILL

	progress++

	// Refresh the UI for anyone who has the panel open.
	for(var/mob/living/M in ui_watchers)
		if(M && !QDELETED(M) && Adjacent(M))
			show_ui(M)
		else
			ui_watchers -= M

	if(progress >= FAB_CRAFT_TICKS)
		// Deliver the finished core.
		new /obj/item/f13/fusion_core(loc)
		progress       = 0
		fab_state      = FAB_STATE_IDLE
		grid_watt_draw = FAB_WATT_DRAW_IDLE
		update_icon()
		visible_message(span_notice("[src] chimes — fusion core fabrication complete."))
		ui_watchers = list()
		_notify_generator_draw_changed()
		return PROCESS_KILL


// ============================================================
// ICON UPDATE
// ============================================================

/obj/machinery/f13/core_fabricator/update_icon_state()
	if(fab_state == FAB_STATE_CRAFTING)
		icon_state = "generator_cycle"
	else if(grid_powered)
		icon_state = "generator_on"
	else
		icon_state = "generator_off"

/obj/machinery/f13/core_fabricator/examine(mob/user)
	. = ..()
	var/obj/machinery/f13/faction_generator/G = get_linked_generator()
	if(G)
		if(G.powered)
			. += span_notice("Heavy-gauge power cables run from its base and disappear into the floor, humming faintly with current.")
		else
			. += span_notice("Power cables connect it to [G.name], though the line is currently dead silent.")
	else
		. += span_warning("No power cables are attached. It won't do anything without a wired generator connection.")


// ============================================================
// LOCK ACCESS CHECK
// ============================================================

/obj/machinery/f13/core_fabricator/proc/can_access(mob/living/user)
	switch(lock_mode)
		if(GENERATOR_LOCK_NONE)
			return TRUE
		if(GENERATOR_LOCK_PERSONAL)
			return (user.ckey == owner_ckey)
		if(GENERATOR_LOCK_FACTION)
			return (owner_faction in user.faction)
	return FALSE


// ============================================================
// INTERACTION — ATTACKBY (material loading + cable wiring + ID card)
// ============================================================

/obj/machinery/f13/core_fabricator/attackby(obj/item/W, mob/user, params)
	// ── Wrench — anchor / unanchor (must be idle to remove).
	if(W.tool_behaviour == TOOL_WRENCH)
		if(fab_state == FAB_STATE_CRAFTING)
			to_chat(user, span_warning("Wait for fabrication to complete before moving [src]."))
			return
		anchored = !anchored
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		to_chat(user, span_notice(anchored ? "You secure [src] to the floor." : "You unbolt [src] from the floor."))
		return

	// ── Cable coil — generator-only wiring interface.
	if(istype(W, /obj/item/stack/cable_coil))
		if(!isliving(user))
			return
		var/mob/living/L = user
		var/obj/machinery/machine_src = f13_try_complete_wire(src, L)
		if(machine_src)
			// Fabricator is the destination — source must be a faction generator.
			if(istype(machine_src, /obj/machinery/f13/faction_generator))
				var/obj/machinery/f13/faction_generator/G = machine_src
				G.link_client(src, user)
			else
				to_chat(user, span_warning("The core fabricator can only be wired directly to a faction generator, not [machine_src.name]."))
		else if(!GLOB.f13_wire_sessions["[REF(L)]"])
			// No active session — start one from this fabricator.
			f13_start_wire_session(src, L)
		return

	// Wirecutters and other tool handling fall through to grid_client.attackby() via ..().

	// ── ID card — update personal / faction lock owner.
	if(istype(W, /obj/item/card/id))
		handle_id_card(W, user)
		return

	if(!can_access(user))
		to_chat(user, span_warning("Access denied."))
		return

	// ── Depleted core for recycling.
	if(istype(W, /obj/item/f13/fusion_core/depleted))
		if(has_depleted_core)
			to_chat(user, span_warning("[src] already has a depleted core loaded for recycling."))
			return
		user.transferItemToLoc(W, src)
		has_depleted_core = TRUE
		qdel(W)
		to_chat(user, span_notice("Depleted core loaded into recycling slot."))
		return

	// ── Material: uranium ore / sheets.
	if(istype(W, /obj/item/stack/sheet/mineral/uranium) || istype(W, /obj/item/stack/ore/uranium))
		if(!load_stack(W, user, "uranium"))
			to_chat(user, span_warning("[src] cannot accept more uranium right now."))
		return

	// ── Material: metal parts.
	if(istype(W, /obj/item/stack/crafting/metalparts))
		if(!load_stack(W, user, "metal"))
			to_chat(user, span_warning("[src] cannot accept more metal parts right now."))
		return

	// ── Material: electronic parts.
	if(istype(W, /obj/item/stack/crafting/electronicparts))
		if(!load_stack(W, user, "electronic"))
			to_chat(user, span_warning("[src] cannot accept more electronic parts right now."))
		return

	return ..()


/// Simple stack-item material loader. Takes as many from S as needed (up to cap). Returns TRUE if any amount was accepted.
/obj/machinery/f13/core_fabricator/proc/load_stack(obj/item/stack/S, mob/user, type)
	if(!S || S.amount < 1)
		return FALSE
	switch(type)
		if("uranium")
			var/cap = has_depleted_core ? FAB_REQ_URANIUM_RECYCLE : FAB_REQ_URANIUM
			var/space = cap - stocked_uranium
			if(space <= 0)
				return FALSE
			var/take = min(S.amount, space)
			S.use(take)
			stocked_uranium += take
			to_chat(user, span_notice("Loaded [take] uranium. ([stocked_uranium]/[cap])"))
			return TRUE
		if("metal")
			var/cap = has_depleted_core ? FAB_REQ_METALPARTS_RECYCLE : FAB_REQ_METALPARTS
			var/space = cap - stocked_metalparts
			if(space <= 0)
				return FALSE
			var/take = min(S.amount, space)
			S.use(take)
			stocked_metalparts += take
			to_chat(user, span_notice("Loaded [take] metal parts. ([stocked_metalparts]/[cap])"))
			return TRUE
		if("electronic")
			var/cap = has_depleted_core ? FAB_REQ_ELECTRONICPARTS_RECYCLE : FAB_REQ_ELECTRONICPARTS
			var/space = cap - stocked_electronicparts
			if(space <= 0)
				return FALSE
			var/take = min(S.amount, space)
			S.use(take)
			stocked_electronicparts += take
			to_chat(user, span_notice("Loaded [take] electronic parts. ([stocked_electronicparts]/[cap])"))
			return TRUE
	return FALSE


/// Read the faction of a job from an ID card by looking up the job datum.
/obj/machinery/f13/core_fabricator/proc/get_faction_from_card(obj/item/card/id/card)
	if(!card || !card.assignment)
		return null
	var/datum/job/J = SSjob.GetJob(card.assignment)
	if(!J || !J.faction || J.faction == "None")
		return null
	return J.faction


/// Handle an ID card swipe for lock management.
/obj/machinery/f13/core_fabricator/proc/handle_id_card(obj/item/card/id/card, mob/user)
	if(!can_access(user) && !(pending_personal_reg || pending_faction_reg))
		to_chat(user, span_warning("Access denied."))
		return

	if(pending_personal_reg)
		pending_personal_reg = FALSE
		owner_ckey = user.ckey
		owner_name = user.real_name
		lock_mode  = GENERATOR_LOCK_PERSONAL
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
		lock_mode     = GENERATOR_LOCK_FACTION
		to_chat(user, span_notice("Faction lock registered to '[reg_faction]'."))
		show_ui(user)
		return

	to_chat(user, span_notice("No pending lock registration. Open the fabricator panel first."))


// ============================================================
// INTERACTION — HAND CLICK → UI
// ============================================================

/obj/machinery/f13/core_fabricator/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	show_ui(user)

/obj/machinery/f13/core_fabricator/proc/show_ui(mob/living/user)
	// Track this user so process() can push live updates during crafting.
	if(fab_state == FAB_STATE_CRAFTING && !(user in ui_watchers))
		ui_watchers += user
	var/accessible = can_access(user)
	var/obj/machinery/f13/faction_generator/G = get_linked_generator()
	var/is_shed = (G && G.shed_clients && (src in G.shed_clients))

	// Progress bar for crafting (20 chars)
	var/prog_bar = ""
	var/prog_pct = 0
	if(fab_state == FAB_STATE_CRAFTING)
		prog_pct = round((progress / FAB_CRAFT_TICKS) * 100)
		var/fill = clamp(round((progress / FAB_CRAFT_TICKS) * 20), 0, 20)
		prog_bar = "&#91;"
		var/p_bi
		for(p_bi = 1; p_bi <= 20; p_bi++)
			prog_bar += p_bi <= fill ? "#" : "."
		prog_bar += "&#93;"

	var/dat = get_terminal_css()
	dat += get_terminal_header("Molecular Synthesizer")
	dat += "<pre class='dim'>  UNIT: [tag ? tag : name]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Generator link + status
	if(G)
		var/gstate = G.powered ? "<span class='good'>&#91;ONLINE&#93;</span>" : "<span class='bad'>&#91;OFFLINE&#93;</span>"
		var/load_note = G.available_watts > 0 ? "<span class='dim'>([G.current_draw]W / [G.available_watts]W)</span>" : ""
		dat += "<pre>  GENERATOR: [G.name]  [gstate]  [load_note]</pre>"
	else
		dat += "<pre>  GENERATOR: <span class='bad'>NOT WIRED</span>  <span class='dim'>(multitool a generator to link)</span></pre>"

	switch(fab_state)
		if(FAB_STATE_CRAFTING)
			dat += "<pre>  STATUS   : <span class='warn'>SYNTHESIZING ... [prog_pct]%  [FAB_WATT_DRAW_ACTIVE]W</span></pre>"
			dat += "<pre>  PROGRESS : [prog_bar] [prog_pct]%</pre>"
		else
			if(is_shed)
				dat += "<pre>  STATUS   : <span class='warn'>&#91;LOAD SHED&#93; — STANDBY  0W</span>  <span class='dim'>(grid overload managed; restores automatically)</span></pre>"
			else
				dat += "<pre>  STATUS   : <span class='dim'>STANDBY  [FAB_WATT_DRAW_IDLE]W</span></pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Material stock
	var/req_u = has_depleted_core ? FAB_REQ_URANIUM_RECYCLE            : FAB_REQ_URANIUM
	var/req_m = has_depleted_core ? FAB_REQ_METALPARTS_RECYCLE         : FAB_REQ_METALPARTS
	var/req_g = has_depleted_core ? FAB_REQ_ELECTRONICPARTS_RECYCLE    : FAB_REQ_ELECTRONICPARTS
	dat += "<pre class='head'>  &#91;MATERIAL INVENTORY&#93;</pre>"
	dat += "<pre>  URANIUM        : [stocked_uranium    >= req_u ? "<span class='good'>[stocked_uranium]</span>"           : "<span class='bad'>[stocked_uranium]</span>"]  / [req_u]</pre>"
	dat += "<pre>  METAL PARTS    : [stocked_metalparts >= req_m ? "<span class='good'>[stocked_metalparts]</span>"        : "<span class='bad'>[stocked_metalparts]</span>"]  / [req_m]</pre>"
	dat += "<pre>  ELEC. PARTS    : [stocked_electronicparts >= req_g ? "<span class='good'>[stocked_electronicparts]</span>" : "<span class='bad'>[stocked_electronicparts]</span>"]  / [req_g]</pre>"
	dat += "<pre>  DEPLETED CORE  : [has_depleted_core ? "<span class='warn'>LOADED</span>" : "<span class='dim'>EMPTY</span>"]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	if(accessible && fab_state == FAB_STATE_IDLE)
		var/can_craft   = (stocked_uranium >= FAB_REQ_URANIUM && stocked_metalparts >= FAB_REQ_METALPARTS && stocked_electronicparts >= FAB_REQ_ELECTRONICPARTS)
		var/can_recycle = (has_depleted_core && stocked_uranium >= FAB_REQ_URANIUM_RECYCLE && stocked_metalparts >= FAB_REQ_METALPARTS_RECYCLE && stocked_electronicparts >= FAB_REQ_ELECTRONICPARTS_RECYCLE)

		// Pre-compute headroom and timing context for synthesis buttons.
		var/craft_secs = FAB_CRAFT_TICKS * 2
		var/craft_disp = craft_secs >= 120 ? "[round(craft_secs/60)] min" : "[craft_secs]s"
		var/watt_preview = ""
		var/overload_warn = ""
		var/runtime_note = ""
		if(G)
			var/post_draw = G.current_draw - FAB_WATT_DRAW_IDLE + FAB_WATT_DRAW_ACTIVE
			var/rt_secs = G.fuel * 2
			var/rt_disp = rt_secs < 120 ? "[rt_secs]s" : "[round(rt_secs/60)] min"
			watt_preview = "  <span class='dim'>(+[FAB_WATT_DRAW_ACTIVE - FAB_WATT_DRAW_IDLE]W -> [post_draw]W / [G.available_watts]W)</span>"
			runtime_note = "  runtime: ~[rt_disp] remaining"
			if(post_draw > G.available_watts)
				overload_warn = "<pre class='warn'>     !! CAPACITY EXCEEDED: load-shedding will pause this job !!</pre>"

		dat += "<pre class='head'>  &#91;SYNTHESIS PROGRAMS&#93;</pre>"
		if(is_shed)
			dat += "<pre class='warn'>  &#91;LOAD SHED ACTIVE&#93; — synthesis suspended.</pre>"
			dat += "<pre class='dim'>  Generator is managing grid overload. Operations will unlock</pre>"
			dat += "<pre class='dim'>  automatically when capacity is restored (e.g. insert a core).</pre>"
		else
			// FABRICATE
			if(can_craft)
				dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=craft'>FABRICATE NEW CORE</a>[watt_preview]</pre>"
			else
				dat += "<pre class='dim'>  &gt; FABRICATE NEW CORE  (insufficient materials)</pre>"
			dat += "<pre class='dim'>     requires: U=[FAB_REQ_URANIUM]  M=[FAB_REQ_METALPARTS]  G=[FAB_REQ_ELECTRONICPARTS]  // duration: ~[craft_disp][runtime_note]</pre>"
			if(overload_warn)
				dat += overload_warn

			// RECYCLE
			if(can_recycle)
				dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=recycle'>RECYCLE DEPLETED CORE</a>[watt_preview]</pre>"
			else
				dat += "<pre class='dim'>  &gt; RECYCLE DEPLETED CORE  (insufficient materials or no core)</pre>"
			dat += "<pre class='dim'>     requires: U=[FAB_REQ_URANIUM_RECYCLE]  M=[FAB_REQ_METALPARTS_RECYCLE]  G=[FAB_REQ_ELECTRONICPARTS_RECYCLE]  + core  // duration: ~[craft_disp][runtime_note]</pre>"
			if(overload_warn)
				dat += overload_warn

			// EJECT
			if(stocked_uranium > 0 || stocked_metalparts > 0 || stocked_electronicparts > 0 || has_depleted_core)
				dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=eject'><span class='warn'>EJECT ALL MATERIALS</span></a></pre>"
		dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

		// Lock settings
		var/lock_owner_display   = owner_name   ? owner_name   : "<span class='dim'>(not set)</span>"
		var/lock_faction_display = owner_faction ? owner_faction : "<span class='dim'>(not set)</span>"
		dat += "<pre class='head'>  &#91;ACCESS CONTROL&#93;</pre>"
		if(lock_mode == GENERATOR_LOCK_NONE)
			dat += "<pre>  MODE: <span class='dim'>OPEN  (no restrictions)</span></pre>"
		else if(lock_mode == GENERATOR_LOCK_PERSONAL)
			dat += "<pre>  MODE: PERSONAL  owner=[lock_owner_display]</pre>"
		else if(lock_mode == GENERATOR_LOCK_FACTION)
			dat += "<pre>  MODE: FACTION   faction=[lock_faction_display]</pre>"
		if(pending_personal_reg || pending_faction_reg)
			dat += "<pre class='warn'>  !! AWAITING ID CARD SWIPE TO COMPLETE REGISTRATION !!</pre>"
		dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=lock_none'>UNLOCK</a>  "
		dat += "<a href='byond://?src=[REF(src)];choice=lock_personal'>PERSONAL LOCK</a>  "
		dat += "<a href='byond://?src=[REF(src)];choice=lock_faction'>FACTION LOCK</a>  "
		dat += "<span class='dim'>(swipe ID card after selecting)</span></pre>"

	else if(fab_state == FAB_STATE_CRAFTING)
		dat += "<pre class='head'>  &#91;SYNTHESIS PROGRAMS&#93;</pre>"
		dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=cancel'><span class='warn'>ABORT SYNTHESIS</span></a>  <span class='dim'>(materials already consumed)</span></pre>"

	else if(!accessible)
		dat += "<pre class='bad'>  ACCESS DENIED  -- INSUFFICIENT CLEARANCE</pre>"

	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_fabricator", null, 620, 580)
	popup.set_content(dat)
	popup.open()


// ============================================================
// TOPIC — UI button handling
// ============================================================

/obj/machinery/f13/core_fabricator/Topic(href, href_list)
	..()
	var/mob/living/U = usr
	if(!U || !istype(U) || !Adjacent(U))
		return
	if(!can_access(U) && !(href_list["choice"] in list("lock_none","lock_personal","lock_faction")))
		to_chat(U, span_warning("Access denied."))
		return

	switch(href_list["choice"])
		if("craft")
			if(fab_state != FAB_STATE_IDLE)
				to_chat(U, span_warning("Already working."))
				return
			if(!grid_powered)
				to_chat(U, span_warning("[src] has no power — wire it to a running generator first."))
				return
			if(stocked_uranium < FAB_REQ_URANIUM || stocked_metalparts < FAB_REQ_METALPARTS || stocked_electronicparts < FAB_REQ_ELECTRONICPARTS)
				to_chat(U, span_warning("Insufficient materials for a new core."))
				return
			stocked_uranium         -= FAB_REQ_URANIUM
			stocked_metalparts      -= FAB_REQ_METALPARTS
			stocked_electronicparts -= FAB_REQ_ELECTRONICPARTS
			fab_state      = FAB_STATE_CRAFTING
			grid_watt_draw = FAB_WATT_DRAW_ACTIVE
			progress       = 0
			update_icon()
			START_PROCESSING(SSobj, src)
			visible_message(span_notice("[src] hums to life — fabricating a fusion core."))
			_notify_generator_draw_changed()

		if("recycle")
			if(fab_state != FAB_STATE_IDLE)
				to_chat(U, span_warning("Already working."))
				return
			if(!grid_powered)
				to_chat(U, span_warning("[src] has no power — wire it to a running generator first."))
				return
			if(!has_depleted_core || stocked_uranium < FAB_REQ_URANIUM_RECYCLE || stocked_metalparts < FAB_REQ_METALPARTS_RECYCLE || stocked_electronicparts < FAB_REQ_ELECTRONICPARTS_RECYCLE)
				to_chat(U, span_warning("Insufficient materials or no depleted core loaded."))
				return
			stocked_uranium         -= FAB_REQ_URANIUM_RECYCLE
			stocked_metalparts      -= FAB_REQ_METALPARTS_RECYCLE
			stocked_electronicparts -= FAB_REQ_ELECTRONICPARTS_RECYCLE
			has_depleted_core  = FALSE
			fab_state      = FAB_STATE_CRAFTING
			grid_watt_draw = FAB_WATT_DRAW_ACTIVE
			progress       = 0
			update_icon()
			START_PROCESSING(SSobj, src)
			visible_message(span_notice("[src] hums to life — recycling depleted core."))
			_notify_generator_draw_changed()

		if("eject")
			if(fab_state != FAB_STATE_IDLE)
				to_chat(U, span_warning("Cannot eject while fabricating."))
				return
			if(stocked_uranium > 0)
				for(var/i in 1 to stocked_uranium)
					new /obj/item/stack/ore/uranium(loc)
				stocked_uranium = 0
			if(stocked_metalparts > 0)
				for(var/i in 1 to stocked_metalparts)
					new /obj/item/stack/crafting/metalparts(loc)
				stocked_metalparts = 0
			if(stocked_electronicparts > 0)
				for(var/i in 1 to stocked_electronicparts)
					new /obj/item/stack/crafting/electronicparts(loc)
				stocked_electronicparts = 0
			if(has_depleted_core)
				new /obj/item/f13/fusion_core/depleted(loc)
				has_depleted_core = FALSE
			to_chat(U, span_notice("Materials ejected onto the floor."))

		if("cancel")
			if(fab_state != FAB_STATE_CRAFTING)
				return
			STOP_PROCESSING(SSobj, src)
			fab_state      = FAB_STATE_IDLE
			grid_watt_draw = FAB_WATT_DRAW_IDLE
			progress       = 0
			update_icon()
			ui_watchers = list()
			_notify_generator_draw_changed()
			to_chat(U, span_notice("Fabrication cancelled. Materials already consumed."))

		if("lock_none")
			lock_mode = GENERATOR_LOCK_NONE
			owner_ckey = null
			owner_name = null
			owner_faction = null
			pending_personal_reg = FALSE
			pending_faction_reg  = FALSE
			to_chat(U, span_notice("Lock removed — fabricator is now open to all."))
		if("lock_personal")
			if(!can_access(U)) return
			pending_personal_reg = TRUE
			pending_faction_reg  = FALSE
			to_chat(U, span_notice("Ready to register personal owner. Swipe an ID card on the fabricator."))
		if("lock_faction")
			if(!can_access(U)) return
			pending_faction_reg  = TRUE
			pending_personal_reg = FALSE
			to_chat(U, span_notice("Ready to register faction lock. Swipe an ID card on the fabricator."))

	show_ui(U)

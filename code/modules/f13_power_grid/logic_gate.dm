// ============================================================
// POWER LOGIC GATE
// ============================================================
//
// A power_relay subtype that computes a boolean function over
// its upstream inputs before driving downstream nodes.
//
// SUPPORTED GATES  (binary unless noted)
//   OR    — output 1 if any input is 1             (default; same as plain relay)
//   AND   — output 1 only if all inputs are 1
//   NOT   — output = !A                            (single input)
//   NAND  — output = !(A & B)
//   NOR   — output = !(A | B)
//   XOR   — output 1 if inputs differ
//   XNOR  — output 1 if inputs are the same
//
// WIRING
//   Input  A/B: cable coil from a generator or relay → click this gate.
//   Output    : cable coil from this gate → click a downstream relay/device.
//   Wirecutters on the gate severs ALL upstream inputs (output side stays).
//   Wirecutters on the downstream relay/device severs that specific output link.
//
// GATE SELECTION
//   Click the gate to open the panel; all seven types appear as direct links.
//   Switching to a type with fewer max inputs automatically severs the surplus.
// ============================================================

/obj/machinery/f13/logic_gate
	parent_type  = /obj/machinery/f13/power_relay
	name         = "power logic gate"
	desc         = "A programmable relay node that evaluates a boolean function over its wired inputs. Change the gate type via the panel."
	icon         = 'icons/machines/power_grid/power_relay.dmi'
	icon_state   = ""

	var/gate_type = GATE_OR


// ============================================================
// GATE HELPERS
// ============================================================

/obj/machinery/f13/logic_gate/proc/gate_name()
	switch(gate_type)
		if(GATE_OR)   return "OR"
		if(GATE_AND)  return "AND"
		if(GATE_NOT)  return "NOT"
		if(GATE_NAND) return "NAND"
		if(GATE_NOR)  return "NOR"
		if(GATE_XOR)  return "XOR"
		if(GATE_XNOR) return "XNOR"
	return "OR"

// Max upstream inputs the current gate type uses meaningfully.
/obj/machinery/f13/logic_gate/proc/gate_max_inputs()
	return gate_type == GATE_NOT ? 1 : 2

/obj/machinery/f13/logic_gate/proc/_compute(list/states)
	if(!states || !states.len)
		return FALSE
	switch(gate_type)
		if(GATE_OR)
			for(var/s in states)
				if(s) return TRUE
			return FALSE
		if(GATE_AND)
			for(var/s in states)
				if(!s) return FALSE
			return TRUE
		if(GATE_NOT)
			return !states[1]
		if(GATE_NAND)
			for(var/s in states)
				if(!s) return TRUE   // at least one 0 → NAND = 1
			return FALSE             // all 1s → NAND = 0
		if(GATE_NOR)
			for(var/s in states)
				if(s) return FALSE   // any 1 → NOR = 0
			return TRUE              // all 0s → NOR = 1
		if(GATE_XOR)
			if(states.len < 2) return FALSE
			return (states[1] ? 1 : 0) != (states[2] ? 1 : 0)
		if(GATE_XNOR)
			if(states.len < 2) return FALSE
			return (states[1] ? 1 : 0) == (states[2] ? 1 : 0)
	return FALSE


// ============================================================
// POWER COMPUTATION — overrides relay OR logic
// ============================================================

/obj/machinery/f13/logic_gate/on_upstream_changed()
	if(relay_isolated)
		set_relay_power(FALSE)
		return
	var/list/states = list()
	if(upstream_refs)
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(!up || QDELETED(up)) continue
			if(istype(up, /obj/machinery/f13/faction_generator))
				states += up:powered ? TRUE : FALSE
			else if(istype(up, /obj/machinery/f13/power_relay))
				states += up:relay_powered ? TRUE : FALSE
	set_relay_power(_compute(states))


// ============================================================
// INPUT CAPPING — enforce max_inputs when wiring relay→gate
// ============================================================

/obj/machinery/f13/logic_gate/set_upstream_relay(obj/machinery/f13/power_relay/parent, mob/user)
	var/cur = upstream_refs ? upstream_refs.len : 0
	if(cur >= gate_max_inputs())
		to_chat(user, span_warning("[gate_name()] gate already has [cur] input[cur != 1 ? "s" : ""] (max [gate_max_inputs()]). Use wirecutters to free a slot."))
		return
	return ..()


// ============================================================
// ICON
// ============================================================

/obj/machinery/f13/logic_gate/update_icon_state()
	icon_state = ""
	color = relay_powered ? "#5db8db" : (upstream_refs && upstream_refs.len ? "#e86a20" : null)


// ============================================================
// UI
// ============================================================

/obj/machinery/f13/logic_gate/attack_hand(mob/living/user)
	if(!Adjacent(user)) return
	show_ui(user)

/obj/machinery/f13/logic_gate/show_ui(mob/living/user)
	// Collect per-input state rows.
	var/list/input_rows = list()
	if(upstream_refs)
		var/idx = 1
		for(var/datum/weakref/W in upstream_refs)
			var/obj/up = W.resolve()
			if(!up || QDELETED(up)) continue
			var/s = FALSE
			if(istype(up, /obj/machinery/f13/faction_generator))      s = up:powered
			else if(istype(up, /obj/machinery/f13/power_relay))        s = up:relay_powered
			var/lbl = idx == 1 ? "A" : (idx == 2 ? "B" : "[idx]")
			var/sstr = s ? "<span class='good'>1  LIVE</span>" : "<span class='bad'>0  DEAD</span>"
			input_rows += "<pre>  INPUT [lbl] : [up.name]  [sstr]</pre>"
			idx++

	var/wired_count    = upstream_refs ? upstream_refs.len : 0
	var/needs_two      = (gate_type == GATE_XOR || gate_type == GATE_XNOR) && wired_count < 2
	var/out_str        = relay_powered ? "<span class='good'>1  LIVE</span>" : (needs_two ? "<span class='warn'>0  NEEDS 2 INPUTS</span>" : "<span class='bad'>0  DEAD</span>")
	var/iso_note = relay_isolated ? "  <span class='warn'>&#91;ISOLATED&#93;</span>" : ""

	var/dat = get_terminal_css()
	dat += get_terminal_header("Power Logic Gate")
	dat += "<pre class='dim'>  UNIT: [tag ? tag : name]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Gate function — direct selector
	dat += "<pre class='head'>  &#91;GATE FUNCTION&#93;</pre>"
	var/list/all_gate_names = list("OR","AND","NOT","NAND","NOR","XOR","XNOR")
	var/list/sel_parts = list()
	for(var/gi = 1 to all_gate_names.len)
		if(gi == gate_type)
			sel_parts += "<b>[all_gate_names[gi]]</b>"
		else
			sel_parts += "<a href='byond://?src=[REF(src)];set_gate=[gi]'>[all_gate_names[gi]]</a>"
	dat += "<pre>  TYPE   : [sel_parts.Join("  ")]</pre>"
	dat += "<pre>  INPUTS : up to [gate_max_inputs()] (currently [wired_count] wired)</pre>"
	if(needs_two)
		dat += "<pre>  <span class='warn'>  &#9888; [gate_name()] requires two inputs to evaluate — wire a second source to activate.</span></pre>"
	dat += "<pre>  OUTPUT : [out_str][iso_note]</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Input states
	dat += "<pre class='head'>  &#91;INPUTS&#93;</pre>"
	if(input_rows.len)
		for(var/row in input_rows)
			dat += row
	else
		dat += "<pre class='dim'>    None wired — use a cable coil on a source, then click this gate.</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// ── Output side
	var/ds_count = (downstream_relays ? downstream_relays.len : 0) + (linked_clients ? linked_clients.len : 0)
	dat += "<pre class='head'>  &#91;OUTPUT SIDE&#93;  [ds_count] downstream node[ds_count != 1 ? "s" : ""]</pre>"
	if(downstream_relays)
		for(var/obj/machinery/f13/power_relay/R in downstream_relays)
			if(!QDELETED(R))
				dat += "<pre class='dim'>    &gt; RELAY  [R.name]  [R.relay_powered ? "<span class='good'>LIVE</span>" : "<span class='bad'>DEAD</span>"]</pre>"
	if(linked_clients)
		for(var/obj/machinery/f13/grid_client/C in linked_clients)
			if(!QDELETED(C))
				dat += "<pre class='dim'>    &gt; CLIENT [C.name]  [C.grid_powered ? "<span class='good'>LIVE</span>" : "<span class='bad'>DEAD</span>"]</pre>"
	if(!ds_count)
		dat += "<pre class='dim'>    None wired — use a cable coil from this gate to a relay or device.</pre>"
	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_gate_[REF(src)]", null, 520, 400)
	popup.set_content(dat)
	popup.open()


// ============================================================
// TOPIC
// ============================================================

/obj/machinery/f13/logic_gate/Topic(href, href_list)
	var/mob/living/U = usr
	if(!U || !istype(U)) return
	if(!in_range(src, U) && !isobserver(U)) return

	if(href_list["set_gate"])
		var/new_type = text2num(href_list["set_gate"])
		if(!new_type || new_type < GATE_OR || new_type > GATE_XNOR || new_type == gate_type)
			show_ui(U)
			return
		gate_type = new_type
		var/new_max = gate_max_inputs()
		// Sever surplus inputs when the new gate type accepts fewer.
		if(upstream_refs && upstream_refs.len > new_max)
			var/list/to_sever = list()
			for(var/i = new_max + 1 to upstream_refs.len)
				to_sever += upstream_refs[i]
			for(var/datum/weakref/W in to_sever)
				var/obj/up = W.resolve()
				if(!up || QDELETED(up)) continue
				if(istype(up, /obj/machinery/f13/faction_generator))
					var/obj/machinery/f13/faction_generator/G = up
					if(G.linked_relays) G.linked_relays -= src
				else if(istype(up, /obj/machinery/f13/power_relay))
					var/obj/machinery/f13/power_relay/P = up
					if(P.downstream_relays) P.downstream_relays -= src
				upstream_refs -= W
			to_chat(U, span_warning("Severed [to_sever.len] input[to_sever.len != 1 ? "s" : ""] — [gate_name()] accepts at most [new_max]."))
		on_upstream_changed()
		update_icon()
		to_chat(U, span_notice("Gate type → [gate_name()]."))
		show_ui(U)


// ============================================================
// EXAMINE
// ============================================================

/obj/machinery/f13/logic_gate/examine(mob/user)
	. = ..()
	var/wired = upstream_refs ? upstream_refs.len : 0
	. += span_notice("Gate type: <b>[gate_name()]</b>  ([gate_max_inputs()]-input). Output: [relay_powered ? "1 (live)" : "0 (dead)"].")
	if((gate_type == GATE_XOR || gate_type == GATE_XNOR) && wired < 2)
		. += span_warning("[gate_name()] needs 2 inputs — currently [wired] wired.")


// Subtypes give mappers a pre-configured object to stamp in DMMs.
// In-game all gates are the same entity — type is changed via the panel.

/obj/machinery/f13/logic_gate/and
	name      = "AND power gate"
	gate_type = GATE_AND

/obj/machinery/f13/logic_gate/not
	name      = "NOT power gate"
	gate_type = GATE_NOT

/obj/machinery/f13/logic_gate/nand
	name      = "NAND power gate"
	gate_type = GATE_NAND

/obj/machinery/f13/logic_gate/nor
	name      = "NOR power gate"
	gate_type = GATE_NOR

/obj/machinery/f13/logic_gate/xor
	name      = "XOR power gate"
	gate_type = GATE_XOR

/obj/machinery/f13/logic_gate/xnor
	name      = "XNOR power gate"
	gate_type = GATE_XNOR

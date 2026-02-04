#define DUNGEON_LOGIC_ALL "all"
#define DUNGEON_LOGIC_ANY "any"
#define DUNGEON_LOGIC_N_OF_M "n_of_m"
#define DUNGEON_LOGIC_EXACT "exact"
#define DUNGEON_LOGIC_XOR "xor"
#define DUNGEON_LOGIC_SEQUENCE "sequence"
#define DUNGEON_LOGIC_SIMULTANEOUS "simultaneous"
#define DUNGEON_LOGIC_TIME_WINDOW "time_window"

#define DUNGEON_TRIGGER_SOLVE "solve"
#define DUNGEON_TRIGGER_UNSOLVE "unsolve"
#define DUNGEON_TRIGGER_RESET "reset"

#define DUNGEON_ACTION_OPEN_DOORS "open_doors"
#define DUNGEON_ACTION_CLOSE_DOORS "close_doors"
#define DUNGEON_ACTION_CYCLE_DOORS "cycle_doors"
#define DUNGEON_ACTION_MESSAGE "message"
#define DUNGEON_ACTION_MESSAGE_GLOBAL "message_global"
#define DUNGEON_ACTION_SOUND "sound"
#define DUNGEON_ACTION_SPAWN_ITEM "spawn_item"
#define DUNGEON_ACTION_SPAWN_MOB "spawn_mob"
#define DUNGEON_ACTION_SET_NODE_ON "set_node_on"
#define DUNGEON_ACTION_SET_NODE_OFF "set_node_off"
#define DUNGEON_ACTION_TOGGLE_NODE "toggle_node"
#define DUNGEON_ACTION_RESET_PUZZLE "reset_puzzle"

/obj/machinery/door
	/// Optional mapper-facing channel used by f13 dungeon puzzle consoles.
	/// If set, a dungeon console can open/close this door regardless of door subtype.
	var/dungeon_channel = null

GLOBAL_VAR(dungeon_puzzles)

/proc/get_dungeon_puzzle(var/puzzle_id)
	if(isnull(puzzle_id) || !length("[puzzle_id]"))
		return null
	if(!GLOB.dungeon_puzzles)
		GLOB.dungeon_puzzles = list()
	var/key = lowertext("[puzzle_id]")
	var/datum/f13_dungeon_puzzle/P = GLOB.dungeon_puzzles[key]
	if(!P)
		P = new
		P.id = key
		GLOB.dungeon_puzzles[key] = P
	return P

/proc/dungeon_parse_id_list(var/raw)
	var/list/out = list()
	if(isnull(raw))
		return out
	var/text = "[raw]"
	text = replacetext(text, ";", ",")
	var/list/parts = splittext(text, ",")
	for(var/part in parts)
		var/token = lowertext("[part]")
		while(length(token) && copytext(token, 1, 2) == " ")
			token = copytext(token, 2)
		while(length(token) && copytext(token, length(token), length(token) + 1) == " ")
			token = copytext(token, 1, length(token))
		if(length(token))
			out += token
	return out

/proc/_dungeon_channel_matches(var/raw_value, var/raw_channel)
	if(isnull(raw_value) || isnull(raw_channel))
		return FALSE
	return lowertext("[raw_value]") == lowertext("[raw_channel]")

/proc/find_dungeon_channel_doors(var/channel_id, var/z_filter = 0)
	var/list/targets = list()
	if(isnull(channel_id) || !length("[channel_id]"))
		return targets
	for(var/obj/machinery/door/D in GLOB.machines)
		if(z_filter && D.z != z_filter)
			continue
		if(D.dungeon_channel && _dungeon_channel_matches(D.dungeon_channel, channel_id))
			targets += D
			continue
		if(istype(D, /obj/machinery/door/poddoor))
			var/obj/machinery/door/poddoor/P = D
			if(_dungeon_channel_matches(P.id, channel_id))
				targets += D
				continue
		if(istype(D, /obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/A = D
			if(_dungeon_channel_matches(A.id_tag, channel_id))
				targets += D
	return targets

/proc/set_dungeon_channel_doors(var/channel_id, var/should_open = TRUE, var/z_filter = 0)
	var/list/targets = find_dungeon_channel_doors(channel_id, z_filter)
	for(var/obj/machinery/door/D as anything in targets)
		if(!D || QDELETED(D))
			continue
		if(should_open)
			INVOKE_ASYNC(D, TYPE_PROC_REF(/obj/machinery/door, open))
		else
			INVOKE_ASYNC(D, TYPE_PROC_REF(/obj/machinery/door, close))
	return targets.len

/proc/_dungeon_emit_message(atom/source, var/text)
	if(isnull(text) || !length("[text]"))
		return
	if(source)
		for(var/mob/M in viewers(7, source))
			to_chat(M, span_notice("[text]"))
		return
	to_chat(world, span_notice("[text]"))

/datum/f13_dungeon_puzzle
	var/id = null
	var/list/node_state = list()
	var/list/node_refs = list()
	var/list/listeners = list()
	/// node_id => world.time when last activated to TRUE
	var/list/node_activation_time = list()
	/// Activation order stream, newest at end.
	var/list/activation_order = list()

/datum/f13_dungeon_puzzle/proc/register_node(obj/machinery/f13/dungeon/puzzle_node/N)
	if(!N)
		return
	var/node_key = lowertext("[N.node_id]")
	node_refs[node_key] = N
	if(isnull(node_state[node_key]))
		node_state[node_key] = !!N.active
	else
		N.active = !!node_state[node_key]
	N.update_node_visuals()

/datum/f13_dungeon_puzzle/proc/unregister_node(obj/machinery/f13/dungeon/puzzle_node/N)
	if(!N)
		return
	var/node_key = lowertext("[N.node_id]")
	node_refs -= node_key

/datum/f13_dungeon_puzzle/proc/register_listener(obj/machinery/f13/dungeon/door_console/C)
	if(!C)
		return
	if(!(C in listeners))
		listeners += C

/datum/f13_dungeon_puzzle/proc/unregister_listener(obj/machinery/f13/dungeon/door_console/C)
	listeners -= C

/datum/f13_dungeon_puzzle/proc/note_activation(var/node_id)
	if(isnull(node_id) || !length("[node_id]"))
		return
	var/node_key = lowertext("[node_id]")
	node_activation_time[node_key] = world.time
	activation_order += node_key
	while(activation_order.len > 64)
		activation_order.Cut(1, 2)

/datum/f13_dungeon_puzzle/proc/set_node_state(var/node_id, var/new_state)
	if(isnull(node_id) || !length("[node_id]"))
		return
	var/node_key = lowertext("[node_id]")
	var/was_active = !!node_state[node_key]
	node_state[node_key] = !!new_state
	if(new_state && !was_active)
		note_activation(node_key)
	notify_listeners()

/datum/f13_dungeon_puzzle/proc/get_active_count(var/list/filter_ids = null)
	var/count = 0
	if(filter_ids && filter_ids.len)
		for(var/id in filter_ids)
			if(node_state[id])
				count++
		return count
	for(var/node_key in node_state)
		if(node_state[node_key])
			count++
	return count

/datum/f13_dungeon_puzzle/proc/get_total_count(var/list/filter_ids = null)
	if(filter_ids && filter_ids.len)
		return filter_ids.len
	return node_state.len

/datum/f13_dungeon_puzzle/proc/get_active_weight(var/list/filter_ids = null)
	var/weight = 0
	if(filter_ids && filter_ids.len)
		for(var/id in filter_ids)
			if(!node_state[id])
				continue
			var/obj/machinery/f13/dungeon/puzzle_node/N = node_refs[id]
			weight += max(1, N?.node_weight || 1)
		return weight
	for(var/node_key in node_state)
		if(!node_state[node_key])
			continue
		var/obj/machinery/f13/dungeon/puzzle_node/N = node_refs[node_key]
		weight += max(1, N?.node_weight || 1)
	return weight

/datum/f13_dungeon_puzzle/proc/get_total_weight(var/list/filter_ids = null)
	var/weight = 0
	if(filter_ids && filter_ids.len)
		for(var/id in filter_ids)
			var/obj/machinery/f13/dungeon/puzzle_node/N = node_refs[id]
			weight += max(1, N?.node_weight || 1)
		return weight
	for(var/node_key in node_state)
		var/obj/machinery/f13/dungeon/puzzle_node/N = node_refs[node_key]
		weight += max(1, N?.node_weight || 1)
	return weight

/datum/f13_dungeon_puzzle/proc/get_last_activation(var/node_id)
	if(isnull(node_id) || !length("[node_id]"))
		return 0
	var/node_key = lowertext("[node_id]")
	return node_activation_time[node_key] || 0

/datum/f13_dungeon_puzzle/proc/evaluate_logic(var/logic_mode, var/required_nodes = 0, var/list/required_ids = null, var/window_ds = 0, var/use_weighted = FALSE, var/required_weight = 0, var/list/forbidden_ids = null)
	logic_mode = lowertext("[logic_mode]")
	var/list/filter = required_ids?.len ? required_ids.Copy() : null
	var/active_count = get_active_count(filter)
	var/total_count = get_total_count(filter)
	if(!total_count)
		return FALSE
	var/active_weight = use_weighted ? get_active_weight(filter) : active_count
	var/total_weight = use_weighted ? get_total_weight(filter) : total_count
	if(required_nodes <= 0)
		required_nodes = total_count
	if(required_weight <= 0)
		required_weight = required_nodes
	if(forbidden_ids?.len)
		for(var/id in forbidden_ids)
			if(node_state[id])
				return FALSE

	switch(logic_mode)
		if(DUNGEON_LOGIC_ANY)
			return active_weight >= 1
		if(DUNGEON_LOGIC_N_OF_M)
			if(use_weighted)
				return active_weight >= required_weight
			return active_count >= required_nodes
		if(DUNGEON_LOGIC_EXACT)
			if(use_weighted)
				return active_weight == required_weight
			return active_count == required_nodes
		if(DUNGEON_LOGIC_XOR)
			return active_count == 1
		if(DUNGEON_LOGIC_SEQUENCE)
			if(!filter || !filter.len)
				return FALSE
			if(activation_order.len < filter.len)
				return FALSE
			var/start_index = activation_order.len - filter.len + 1
			for(var/i = 1 to filter.len)
				if(activation_order[start_index + i - 1] != filter[i])
					return FALSE
			return TRUE
		if(DUNGEON_LOGIC_SIMULTANEOUS, DUNGEON_LOGIC_TIME_WINDOW)
			var/list/target_ids = list()
			if(filter?.len)
				target_ids = filter.Copy()
			else
				for(var/node_key in node_state)
					if(node_state[node_key])
						target_ids += node_key
			if(!target_ids.len)
				return FALSE
			if(use_weighted)
				if(active_weight < required_weight)
					return FALSE
			else if(active_count < required_nodes)
				return FALSE
			if(window_ds <= 0)
				window_ds = (logic_mode == DUNGEON_LOGIC_SIMULTANEOUS) ? 50 : 300
			var/min_time = 1.0e31
			var/max_time = 0
			var/considered = 0
			for(var/node_key in target_ids)
				if(!node_state[node_key])
					continue
				var/t = get_last_activation(node_key)
				if(!t)
					continue
				considered++
				if(t < min_time)
					min_time = t
				if(t > max_time)
					max_time = t
			if(use_weighted)
				if(considered <= 0)
					return FALSE
			else if(considered < required_nodes)
				return FALSE
			return (max_time - min_time) <= window_ds
		else
			// ALL default
			if(filter?.len)
				if(use_weighted)
					return active_weight >= total_weight
				return active_count >= filter.len
			if(use_weighted)
				return active_weight >= required_weight
			return active_count >= required_nodes

/datum/f13_dungeon_puzzle/proc/notify_listeners()
	for(var/obj/machinery/f13/dungeon/door_console/C as anything in listeners)
		if(!C || QDELETED(C))
			continue
		C.on_puzzle_update()

/datum/f13_dungeon_puzzle/proc/reset_all_nodes()
	for(var/node_key in node_refs)
		var/obj/machinery/f13/dungeon/puzzle_node/N = node_refs[node_key]
		if(!N || QDELETED(N))
			continue
		N.reset_node_state()
	activation_order = list()
	notify_listeners()

/obj/machinery/f13/dungeon
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	use_power = NO_POWER_USE
	density = TRUE
	anchored = TRUE
	resistance_flags = FIRE_PROOF

/obj/machinery/f13/dungeon/door_console
	name = "dungeon access console"
	desc = "A modular access console that can drive blast doors and linked doors when puzzle nodes are solved."
	/// Shared ID used to collect node progress.
	var/puzzle_id = null
	/// Door channel to control (matches door.dungeon_channel, poddoor.id, or airlock.id_tag).
	var/door_channel = null
	/// Logic mode: all, any, n_of_m, sequence, simultaneous, time_window
	var/logic_mode = DUNGEON_LOGIC_ALL
	/// Nodes required for n_of_m / window modes. If 0, defaults to total node count.
	var/required_nodes = 0
	/// Optional list of required node IDs, comma-separated. Example: "alpha,beta,gamma"
	var/required_node_ids_text = ""
	/// Optional list of node IDs that must be inactive.
	var/forbidden_node_ids_text = ""
	/// Window length in deciseconds for simultaneous/time_window logic.
	var/window_ds = 0
	/// If TRUE, logic checks weighted node totals instead of raw node count.
	var/use_weighted_logic = FALSE
	/// Weighted threshold for n_of_m/exact/all(simulated). If 0, defaults from required_nodes.
	var/required_weight = 0
	/// Open linked doors immediately when requirements are met.
	var/auto_open_on_solve = TRUE
	/// Allow users to manually open/close/cycle once solved.
	var/allow_manual_toggle = TRUE
	/// If TRUE, only controls doors on the same z-level.
	var/same_z_only = TRUE
	/// Optional auto-relock after opening, in seconds (0 = disabled).
	var/relock_after_seconds = 0
	/// If TRUE, anyone may reset puzzle progress from this console.
	var/allow_public_reset = FALSE
	/// If TRUE, puzzle can return to unsolved when conditions drop.
	var/can_unsolve = TRUE
	/// Optional local message shown on solve.
	var/solve_message = "ACCESS UNLOCKED."
	/// Optional local message shown on unsolve.
	var/unsolve_message = "PUZZLE STATE LOST."
	var/solved = FALSE

/obj/machinery/f13/dungeon/door_console/Initialize(mapload)
	. = ..()
	if(puzzle_id)
		var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
		P?.register_listener(src)
	addtimer(CALLBACK(src, PROC_REF(on_puzzle_update)), 1)

/obj/machinery/f13/dungeon/door_console/Destroy()
	if(puzzle_id)
		var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
		P?.unregister_listener(src)
	return ..()

/obj/machinery/f13/dungeon/door_console/examine(mob/user)
	. = ..()
	. += span_notice("Puzzle: [puzzle_id || "<unset>"] | Door channel: [door_channel || "<unset>"]")
	. += span_notice("Logic: [logic_mode] | Required: [required_nodes || "auto"] | Window: [window_ds || "default"] ds")
	if(use_weighted_logic)
		. += span_notice("Weighted logic enabled (threshold: [required_weight || "auto"]).")
	. += span_notice("Progress: [get_active_nodes()]/[get_total_nodes()] active")
	if(length(required_node_ids_text))
		. += span_notice("Required node IDs: [required_node_ids_text]")
	if(length(forbidden_node_ids_text))
		. += span_notice("Forbidden active node IDs: [forbidden_node_ids_text]")
	. += span_notice("Mapper setup: set puzzle_id + door_channel. Place puzzle nodes with same puzzle_id. Target doors via dungeon_channel (or legacy poddoor id / airlock id_tag).")

/obj/machinery/f13/dungeon/door_console/proc/get_puzzle()
	return get_dungeon_puzzle(puzzle_id)

/obj/machinery/f13/dungeon/door_console/proc/get_required_ids()
	return dungeon_parse_id_list(required_node_ids_text)

/obj/machinery/f13/dungeon/door_console/proc/get_forbidden_ids()
	return dungeon_parse_id_list(forbidden_node_ids_text)

/obj/machinery/f13/dungeon/door_console/proc/get_active_nodes()
	var/datum/f13_dungeon_puzzle/P = get_puzzle()
	if(!P)
		return 0
	var/list/required_ids = get_required_ids()
	return P.get_active_count(required_ids)

/obj/machinery/f13/dungeon/door_console/proc/get_total_nodes()
	var/datum/f13_dungeon_puzzle/P = get_puzzle()
	if(!P)
		return 0
	var/list/required_ids = get_required_ids()
	return P.get_total_count(required_ids)

/obj/machinery/f13/dungeon/door_console/proc/evaluate_solved()
	var/datum/f13_dungeon_puzzle/P = get_puzzle()
	if(!P)
		return FALSE
	return P.evaluate_logic(logic_mode, required_nodes, get_required_ids(), window_ds, use_weighted_logic, required_weight, get_forbidden_ids())

/obj/machinery/f13/dungeon/door_console/proc/show_diagnostics(mob/user)
	var/datum/f13_dungeon_puzzle/P = get_puzzle()
	if(!P)
		to_chat(user, span_warning("No puzzle state found for [puzzle_id]."))
		return
	to_chat(user, span_notice("Diagnostics: puzzle [puzzle_id], logic [logic_mode], solved=[evaluate_solved()]."))
	for(var/node_key in P.node_state)
		var/state = P.node_state[node_key] ? "ACTIVE" : "inactive"
		var/obj/machinery/f13/dungeon/puzzle_node/N = P.node_refs[node_key]
		var/w = N?.node_weight || 1
		var/t = P.get_last_activation(node_key)
		to_chat(user, span_notice("- [node_key]: [state], w=[w], t=[t]"))
	if(P.activation_order.len)
		to_chat(user, span_notice("Recent order: [jointext(P.activation_order, " -> ")]"))

/obj/machinery/f13/dungeon/door_console/proc/trigger_anchors(var/trigger)
	for(var/obj/effect/f13/dungeon_trigger_anchor/A in world)
		if(!A || QDELETED(A))
			continue
		if(!A.matches(puzzle_id, trigger, same_z_only ? z : 0))
			continue
		A.activate(trigger, src)

/obj/machinery/f13/dungeon/door_console/proc/on_puzzle_update()
	if(!puzzle_id)
		return
	var/is_solved_now = evaluate_solved()
	if(is_solved_now)
		if(solved)
			return
		solved = TRUE
		if(length(solve_message))
			visible_message(span_notice("[src] [solve_message]"))
		playsound(src, 'sound/machines/ping.ogg', 40, TRUE)
		if(auto_open_on_solve)
			open_controlled_doors()
		trigger_anchors(DUNGEON_TRIGGER_SOLVE)
		return
	if(!solved)
		return
	if(!can_unsolve)
		return
	solved = FALSE
	if(length(unsolve_message))
		visible_message(span_warning("[src] [unsolve_message]"))
	trigger_anchors(DUNGEON_TRIGGER_UNSOLVE)

/obj/machinery/f13/dungeon/door_console/proc/open_controlled_doors()
	if(!door_channel)
		return 0
	var/z_filter = same_z_only ? z : 0
	var/opened = set_dungeon_channel_doors(door_channel, TRUE, z_filter)
	if(relock_after_seconds > 0)
		addtimer(CALLBACK(src, PROC_REF(close_controlled_doors)), relock_after_seconds * 10)
	return opened

/obj/machinery/f13/dungeon/door_console/proc/close_controlled_doors()
	if(!door_channel)
		return 0
	var/z_filter = same_z_only ? z : 0
	return set_dungeon_channel_doors(door_channel, FALSE, z_filter)

/obj/machinery/f13/dungeon/door_console/proc/reset_puzzle(mob/user)
	var/datum/f13_dungeon_puzzle/P = get_puzzle()
	if(!P)
		to_chat(user, span_warning("No puzzle state found for [puzzle_id]."))
		return
	P.reset_all_nodes()
	solved = FALSE
	trigger_anchors(DUNGEON_TRIGGER_RESET)
	to_chat(user, span_notice("Puzzle [puzzle_id] has been reset."))

/obj/machinery/f13/dungeon/door_console/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(!puzzle_id || !door_channel)
		to_chat(user, span_warning("Console misconfigured. Mapper must set puzzle_id and door_channel."))
		return
	if(!solved)
		to_chat(user, span_notice("Access lock engaged: [get_active_nodes()]/[get_total_nodes()] active ([logic_mode])."))
		if(length(required_node_ids_text))
			to_chat(user, span_notice("Required nodes: [required_node_ids_text]"))
		if(length(forbidden_node_ids_text))
			to_chat(user, span_notice("Forbidden nodes (must stay OFF): [forbidden_node_ids_text]"))
		return
	var/list/options = list("Status", "Open Doors", "Close Doors", "Diagnostics")
	if(allow_manual_toggle)
		options += "Cycle Doors"
	if(allow_public_reset)
		options += "Reset Puzzle"
	var/choice = input(user, "Control linked channel [door_channel].", src.name) as null|anything in options
	if(!choice)
		return
	switch(choice)
		if("Status")
			to_chat(user, span_notice("Console online. Puzzle [puzzle_id] solved ([get_active_nodes()]/[get_total_nodes()])."))
		if("Open Doors")
			var/opened = open_controlled_doors()
			to_chat(user, span_notice("Sent OPEN to [opened] linked door(s)."))
		if("Close Doors")
			var/closed = close_controlled_doors()
			to_chat(user, span_notice("Sent CLOSE to [closed] linked door(s)."))
		if("Diagnostics")
			show_diagnostics(user)
		if("Cycle Doors")
			var/closed = close_controlled_doors()
			addtimer(CALLBACK(src, PROC_REF(open_controlled_doors)), 20)
			to_chat(user, span_notice("Cycled [closed] linked door(s)."))
		if("Reset Puzzle")
			reset_puzzle(user)

/obj/machinery/f13/dungeon/puzzle_node
	name = "puzzle node"
	desc = "Part of a linked facility puzzle network."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrl"
	anchored = TRUE
	density = TRUE
	use_power = NO_POWER_USE
	/// Shared puzzle id this node contributes to.
	var/puzzle_id = null
	/// Unique key within the puzzle (set manually for readability in map editor).
	var/node_id = null
	/// Optional weighted value for weighted console logic.
	var/node_weight = 1
	var/active = FALSE
	var/one_time = TRUE
	/// Action time in deciseconds.
	var/interaction_time = 15
	var/fail_chance = 0
	/// Optional required item path (for attackby activation).
	var/requires_item_type = null
	/// Total amount needed (works with stack items too).
	var/required_amount = 1
	/// Progress toward required_amount.
	var/current_amount = 0
	/// Optional number of successful interactions needed before node activates.
	var/required_interactions = 1
	var/current_interactions = 0
	/// Optional co-op gate: requires this many unique ckeys to interact successfully.
	var/required_unique_users = 0
	var/list/unique_users = list()
	var/consume_required_item = TRUE
	var/allow_hand_use = TRUE
	var/activate_text = "You reconfigure the node."
	var/fail_text = "The node emits a harsh buzz and rejects your attempt."
	var/activation_cooldown_ds = 0
	var/next_activation = 0
	/// If >0, active state automatically clears after this delay.
	var/auto_deactivate_ds = 0

/obj/machinery/f13/dungeon/puzzle_node/Initialize(mapload)
	. = ..()
	if(!node_id)
		node_id = "node_[x]_[y]_[z]"
	var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
	P?.register_node(src)
	update_node_visuals()

/obj/machinery/f13/dungeon/puzzle_node/Destroy()
	var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
	P?.unregister_node(src)
	return ..()

/obj/machinery/f13/dungeon/puzzle_node/examine(mob/user)
	. = ..()
	. += span_notice("Puzzle: [puzzle_id || "<unset>"] | Node: [node_id]")
	. += span_notice("State: [active ? "ACTIVE" : "INACTIVE"]")
	. += span_notice("Weight: [node_weight]")
	if(required_interactions > 1)
		. += span_notice("Interaction progress: [current_interactions]/[required_interactions].")
	if(required_unique_users > 1)
		. += span_notice("Unique users required: [unique_users.len]/[required_unique_users].")
	if(requires_item_type)
		if(required_amount > 1)
			. += span_notice("Requires [required_amount]x [requires_item_type] ([current_amount]/[required_amount]).")
		else
			. += span_notice("Requires item: [requires_item_type].")

/obj/machinery/f13/dungeon/puzzle_node/proc/update_node_visuals()
	set_light(active ? 2 : 0, 0.8, active ? "#6bcf7a" : null)
	alpha = active ? 255 : 210

/obj/machinery/f13/dungeon/puzzle_node/proc/reset_node_state()
	current_amount = 0
	current_interactions = 0
	unique_users = list()
	set_active(FALSE, null, TRUE)

/obj/machinery/f13/dungeon/puzzle_node/proc/can_attempt(mob/living/user, obj/item/used_item)
	if(world.time < next_activation)
		to_chat(user, span_warning("[src] is still cycling."))
		return FALSE
	if(!puzzle_id)
		to_chat(user, span_warning("This node is not linked to a puzzle_id."))
		return FALSE
	if(one_time && active)
		to_chat(user, span_notice("[src] is already active."))
		return FALSE
	if((req_access?.len || req_one_access?.len) && !allowed(user))
		to_chat(user, span_warning("Access denied."))
		return FALSE
	if(requires_item_type && !istype(used_item, requires_item_type))
		to_chat(user, span_warning("[src] requires [requires_item_type]."))
		return FALSE
	return TRUE

/obj/machinery/f13/dungeon/puzzle_node/proc/set_active(var/new_state, mob/living/user, var/silent = FALSE, var/notify_puzzle = TRUE)
	active = !!new_state
	update_node_visuals()
	if(notify_puzzle)
		var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
		P?.set_node_state(node_id, active)
	if(!silent && user)
		to_chat(user, span_notice("[src] is now [active ? "active" : "inactive"]."))
	if(active && auto_deactivate_ds > 0)
		addtimer(CALLBACK(src, PROC_REF(_auto_clear_active)), auto_deactivate_ds)

/obj/machinery/f13/dungeon/puzzle_node/proc/_auto_clear_active()
	if(one_time)
		return
	set_active(FALSE, null, TRUE)

/obj/machinery/f13/dungeon/puzzle_node/proc/handle_required_item(obj/item/used_item, mob/living/user)
	if(!requires_item_type)
		return TRUE
	if(!used_item)
		return FALSE

	var/need = max(0, required_amount - current_amount)
	if(need <= 0)
		return TRUE

	var/added = 0
	if(istype(used_item, /obj/item/stack))
		var/obj/item/stack/S = used_item
		added = min(need, S.amount)
		if(added <= 0)
			return FALSE
		current_amount += added
		if(consume_required_item)
			S.use(added)
	else
		added = 1
		current_amount += 1
		if(consume_required_item)
			qdel(used_item)

	if(current_amount < required_amount)
		to_chat(user, span_notice("[src] progress: [current_amount]/[required_amount]."))
		return FALSE
	return TRUE

/obj/machinery/f13/dungeon/puzzle_node/proc/try_activate(mob/living/user, obj/item/used_item)
	if(!can_attempt(user, used_item))
		return FALSE
	if(interaction_time > 0)
		to_chat(user, span_notice(activate_text))
		if(!do_after(user, interaction_time, target = src))
			return FALSE
	if(fail_chance > 0 && prob(fail_chance))
		to_chat(user, span_warning(fail_text))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 35, TRUE)
		next_activation = world.time + activation_cooldown_ds
		return FALSE
	if(!handle_required_item(used_item, user))
		next_activation = world.time + activation_cooldown_ds
		return FALSE
	if(user?.ckey)
		if(!(user.ckey in unique_users))
			unique_users += user.ckey
	if(required_unique_users > 0 && unique_users.len < required_unique_users)
		to_chat(user, span_notice("[src] team sync: [unique_users.len]/[required_unique_users] unique users."))
		next_activation = world.time + activation_cooldown_ds
		return FALSE
	current_interactions++
	if(required_interactions > 1 && current_interactions < required_interactions)
		to_chat(user, span_notice("[src] interaction progress: [current_interactions]/[required_interactions]."))
		next_activation = world.time + activation_cooldown_ds
		return FALSE
	set_active(TRUE, user)
	playsound(src, 'sound/machines/ping.ogg', 35, TRUE)
	next_activation = world.time + activation_cooldown_ds
	return TRUE

/obj/machinery/f13/dungeon/puzzle_node/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!allow_hand_use)
		to_chat(user, span_notice("[src] requires a specific component."))
		return
	add_fingerprint(user)
	try_activate(user, null)

/obj/machinery/f13/dungeon/puzzle_node/attackby(obj/item/W, mob/living/user, params)
	if(requires_item_type)
		if(try_activate(user, W))
			return
	return ..()

/obj/machinery/f13/dungeon/puzzle_node/lever
	name = "puzzle lever"
	desc = "A locking lever tied to a puzzle network."
	icon_state = "launcher"
	one_time = FALSE
	interaction_time = 0
	allow_hand_use = TRUE

/obj/machinery/f13/dungeon/puzzle_node/lever/attack_hand(mob/living/user)
	if(!puzzle_id)
		to_chat(user, span_warning("This lever is not linked to a puzzle_id."))
		return
	if((req_access?.len || req_one_access?.len) && !allowed(user))
		to_chat(user, span_warning("Access denied."))
		return
	add_fingerprint(user)
	set_active(!active, user)
	playsound(src, 'sound/machines/click.ogg', 35, TRUE)

/obj/machinery/f13/dungeon/puzzle_node/keypad
	name = "puzzle keypad"
	desc = "A hardened keypad that can arm one stage of a door puzzle."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	allow_hand_use = FALSE
	interaction_time = 5
	var/passcode = "0420"
	var/max_attempts = 5
	var/lockout_time = 300 // deciseconds
	var/failed_attempts = 0
	var/locked_until = 0

/obj/machinery/f13/dungeon/puzzle_node/keypad/attack_hand(mob/living/user)
	if(world.time < locked_until)
		to_chat(user, span_warning("Keypad locked out."))
		return
	if(one_time && active)
		to_chat(user, span_notice("Keypad already accepted the code."))
		return
	add_fingerprint(user)
	var/guess = stripped_input(user, "Enter access code:", "Access Keypad", "")
	if(isnull(guess))
		return
	if(guess != passcode)
		failed_attempts++
		playsound(src, 'sound/machines/buzz-sigh.ogg', 35, TRUE)
		to_chat(user, span_warning("Incorrect code."))
		if(failed_attempts >= max_attempts)
			failed_attempts = 0
			locked_until = world.time + lockout_time
			to_chat(user, span_warning("Too many failed attempts. Keypad lockout engaged."))
		return
	failed_attempts = 0
	try_activate(user, null)

/obj/machinery/f13/dungeon/puzzle_node/item_socket
	name = "puzzle component socket"
	desc = "An empty socket waiting for a compatible component."
	allow_hand_use = FALSE
	requires_item_type = /obj/item/stack/sheet/mineral/uranium
	required_amount = 5
	consume_required_item = TRUE
	interaction_time = 10
	activate_text = "You seat the component into the socket..."

/obj/machinery/f13/dungeon/puzzle_node/multitool_patch
	name = "maintenance bypass panel"
	desc = "A panel that requires a multitool patch to bring online."
	allow_hand_use = FALSE
	requires_item_type = /obj/item/multitool
	required_amount = 1
	consume_required_item = FALSE
	interaction_time = 20
	activate_text = "You begin rerouting this panel with your multitool..."

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate
	name = "pressure plate"
	desc = "A weighted plate linked into a puzzle network."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pressure_pad"
	density = FALSE
	one_time = FALSE
	allow_hand_use = FALSE
	interaction_time = 0
	var/list/occupants = list()
	/// Safety rescan while occupied, in deciseconds.
	var/rescan_interval_ds = 10
	var/rescan_queued = FALSE

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/Initialize(mapload)
	. = ..()
	_schedule_plate_rescan(2)

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/Destroy()
	occupants = null
	return ..()

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/proc/_is_plate_occupant(atom/movable/AM)
	if(!AM || QDELETED(AM))
		return FALSE
	return isliving(AM)

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/proc/_schedule_plate_rescan(var/delay_ds = 1)
	if(rescan_queued)
		return
	rescan_queued = TRUE
	addtimer(CALLBACK(src, PROC_REF(_run_plate_rescan)), max(1, delay_ds))

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/proc/_run_plate_rescan()
	rescan_queued = FALSE
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/list/new_occupants = list()
	for(var/atom/movable/AM in T)
		if(!_is_plate_occupant(AM))
			continue
		new_occupants += AM
	occupants = new_occupants
	var/should_be_active = occupants.len > 0
	if(should_be_active != active)
		set_active(should_be_active, null, TRUE)
	if(should_be_active && rescan_interval_ds > 0)
		_schedule_plate_rescan(rescan_interval_ds)

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/Crossed(atom/movable/AM)
	. = ..()
	if(!_is_plate_occupant(AM))
		return
	if(!(AM in occupants))
		occupants += AM
	_schedule_plate_rescan(1)

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/Uncrossed(atom/movable/AM)
	. = ..()
	occupants -= AM
	_schedule_plate_rescan(1)

/obj/machinery/f13/dungeon/puzzle_node/pressure_plate/reset_node_state()
	occupants = list()
	set_active(FALSE, null, TRUE)
	_schedule_plate_rescan(2)

/obj/machinery/f13/dungeon/puzzle_node/timer
	name = "timed relay"
	desc = "A timed relay that can auto-activate a puzzle state."
	allow_hand_use = FALSE
	one_time = FALSE
	interaction_time = 0
	var/auto_start = TRUE
	var/start_delay_ds = 100
	var/pulse_length_ds = 0

/obj/machinery/f13/dungeon/puzzle_node/timer/Initialize(mapload)
	. = ..()
	if(auto_start)
		addtimer(CALLBACK(src, PROC_REF(trigger_timer)), start_delay_ds)

/obj/machinery/f13/dungeon/puzzle_node/timer/proc/trigger_timer()
	set_active(TRUE, null, TRUE)
	if(pulse_length_ds > 0)
		addtimer(CALLBACK(src, PROC_REF(clear_timer)), pulse_length_ds)

/obj/machinery/f13/dungeon/puzzle_node/timer/proc/clear_timer()
	set_active(FALSE, null, TRUE)

/obj/machinery/f13/dungeon/puzzle_node/fuse_box
	name = "fuse service box"
	desc = "A service box that needs cable and fuses to restore a locked circuit."
	allow_hand_use = FALSE
	requires_item_type = /obj/item/stack/cable_coil
	required_amount = 8
	consume_required_item = TRUE
	interaction_time = 15
	activate_text = "You begin rewiring the fuse box..."
	node_weight = 2

/obj/machinery/f13/dungeon/puzzle_node/biometric_reader
	name = "biometric gate reader"
	desc = "A scanner that expects authorized personnel and synchronized confirmations."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	allow_hand_use = TRUE
	requires_item_type = null
	interaction_time = 8
	required_unique_users = 2
	required_interactions = 2
	one_time = TRUE
	activate_text = "You place your hand on the scanner..."

/obj/machinery/f13/dungeon/puzzle_reset_console
	name = "dungeon puzzle reset console"
	desc = "Administrative reset for a linked puzzle network."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	use_power = NO_POWER_USE
	density = TRUE
	anchored = TRUE
	var/puzzle_id = null

/obj/machinery/f13/dungeon/puzzle_reset_console/examine(mob/user)
	. = ..()
	. += span_notice("Puzzle target: [puzzle_id || "<unset>"]")

/obj/machinery/f13/dungeon/puzzle_reset_console/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!puzzle_id)
		to_chat(user, span_warning("No puzzle_id configured."))
		return
	var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
	if(!P)
		to_chat(user, span_warning("Puzzle [puzzle_id] not found."))
		return
	P.reset_all_nodes()
	to_chat(user, span_notice("Puzzle [puzzle_id] has been reset."))

/obj/machinery/f13/dungeon/puzzle_debug_console
	name = "dungeon puzzle diagnostics"
	desc = "A diagnostics terminal for mappers and operators."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	use_power = NO_POWER_USE
	density = TRUE
	anchored = TRUE
	var/puzzle_id = null

/obj/machinery/f13/dungeon/puzzle_debug_console/examine(mob/user)
	. = ..()
	. += span_notice("Puzzle target: [puzzle_id || "<unset>"]")

/obj/machinery/f13/dungeon/puzzle_debug_console/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!puzzle_id)
		to_chat(user, span_warning("No puzzle_id configured."))
		return
	var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(puzzle_id)
	if(!P)
		to_chat(user, span_warning("Puzzle [puzzle_id] not found."))
		return
	to_chat(user, span_notice("Diagnostics: [puzzle_id] nodes=[P.node_state.len], active=[P.get_active_count()]."))
	for(var/node_key in P.node_state)
		var/obj/machinery/f13/dungeon/puzzle_node/N = P.node_refs[node_key]
		var/w = N?.node_weight || 1
		var/state = P.node_state[node_key] ? "ACTIVE" : "inactive"
		var/t = P.get_last_activation(node_key)
		to_chat(user, span_notice("- [node_key] | [state] | w=[w] | t=[t]"))

/obj/effect/f13/dungeon_trigger_anchor
	name = "dungeon trigger anchor"
	desc = "Mapper utility: runs an action when a puzzle trigger fires."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	anchored = TRUE
	density = FALSE
	invisibility = INVISIBILITY_OBSERVER
	var/puzzle_id = null
	var/trigger = DUNGEON_TRIGGER_SOLVE
	var/action = DUNGEON_ACTION_MESSAGE
	var/door_channel = null
	var/message_text = "Puzzle event triggered."
	var/sound_file = 'sound/machines/ping.ogg'
	var/sound_volume = 40
	var/spawn_path = null
	var/spawn_count = 1
	/// Optional target puzzle/node for node actions.
	var/target_puzzle_id = null
	var/target_node_id = null
	/// Runtime controls.
	var/delay_ds = 0
	var/cooldown_ds = 0
	var/next_fire_time = 0
	var/chance_percent = 100
	var/one_shot = FALSE
	var/fired = FALSE
	var/same_z_only = TRUE

/obj/effect/f13/dungeon_trigger_anchor/proc/matches(var/raw_puzzle_id, var/raw_trigger, var/z_filter)
	if(one_shot && fired)
		return FALSE
	if(!_dungeon_channel_matches(puzzle_id, raw_puzzle_id))
		return FALSE
	if(lowertext("[trigger]") != lowertext("[raw_trigger]"))
		return FALSE
	if(same_z_only && z_filter && z != z_filter)
		return FALSE
	return TRUE

/obj/effect/f13/dungeon_trigger_anchor/proc/activate(var/raw_trigger, obj/machinery/f13/dungeon/door_console/source_console)
	if(world.time < next_fire_time)
		return
	if(chance_percent < 100 && !prob(clamp(chance_percent, 0, 100)))
		return
	if(one_shot && fired)
		return
	fired = TRUE
	next_fire_time = world.time + max(0, cooldown_ds)
	if(delay_ds > 0)
		addtimer(CALLBACK(src, PROC_REF(_run_action), raw_trigger, source_console), delay_ds)
		return
	_run_action(raw_trigger, source_console)

/obj/effect/f13/dungeon_trigger_anchor/proc/_run_action(var/raw_trigger, obj/machinery/f13/dungeon/door_console/source_console)
	switch(lowertext("[action]"))
		if(DUNGEON_ACTION_OPEN_DOORS)
			set_dungeon_channel_doors(door_channel, TRUE, (same_z_only && source_console) ? source_console.z : 0)
		if(DUNGEON_ACTION_CLOSE_DOORS)
			set_dungeon_channel_doors(door_channel, FALSE, (same_z_only && source_console) ? source_console.z : 0)
		if(DUNGEON_ACTION_CYCLE_DOORS)
			set_dungeon_channel_doors(door_channel, FALSE, (same_z_only && source_console) ? source_console.z : 0)
			addtimer(CALLBACK(src, PROC_REF(_cycle_reopen), source_console ? source_console.z : 0), 20)
		if(DUNGEON_ACTION_SOUND)
			if(sound_file)
				playsound(src, sound_file, sound_volume, TRUE)
		if(DUNGEON_ACTION_SPAWN_ITEM, DUNGEON_ACTION_SPAWN_MOB)
			if(spawn_path)
				for(var/i = 1 to max(1, spawn_count))
					new spawn_path(get_turf(src))
		if(DUNGEON_ACTION_SET_NODE_ON, DUNGEON_ACTION_SET_NODE_OFF, DUNGEON_ACTION_TOGGLE_NODE)
			var/destination_puzzle = target_puzzle_id || puzzle_id
			if(!destination_puzzle || !target_node_id)
				return
			var/datum/f13_dungeon_puzzle/P = get_dungeon_puzzle(destination_puzzle)
			if(!P)
				return
			var/node_key = lowertext("[target_node_id]")
			if(lowertext("[action]") == DUNGEON_ACTION_SET_NODE_ON)
				P.set_node_state(node_key, TRUE)
			else if(lowertext("[action]") == DUNGEON_ACTION_SET_NODE_OFF)
				P.set_node_state(node_key, FALSE)
			else
				P.set_node_state(node_key, !P.node_state[node_key])
		if(DUNGEON_ACTION_RESET_PUZZLE)
			var/destination = target_puzzle_id || puzzle_id
			if(destination)
				var/datum/f13_dungeon_puzzle/P2 = get_dungeon_puzzle(destination)
				P2?.reset_all_nodes()
		if(DUNGEON_ACTION_MESSAGE_GLOBAL)
			_dungeon_emit_message(null, message_text)
		else
			_dungeon_emit_message(source_console || src, message_text)

/obj/effect/f13/dungeon_trigger_anchor/proc/_cycle_reopen(var/z_filter = 0)
	set_dungeon_channel_doors(door_channel, TRUE, same_z_only ? z_filter : 0)

// Mapper-ready console presets
/obj/machinery/f13/dungeon/door_console/preset

/obj/machinery/f13/dungeon/door_console/preset/all_nodes
	name = "dungeon access console (ALL nodes)"
	logic_mode = DUNGEON_LOGIC_ALL
	required_nodes = 0

/obj/machinery/f13/dungeon/door_console/preset/any_node
	name = "dungeon access console (ANY node)"
	logic_mode = DUNGEON_LOGIC_ANY
	required_nodes = 1

/obj/machinery/f13/dungeon/door_console/preset/three_of_five
	name = "dungeon access console (3 of 5)"
	logic_mode = DUNGEON_LOGIC_N_OF_M
	required_nodes = 3

/obj/machinery/f13/dungeon/door_console/preset/exact_two
	name = "dungeon access console (EXACT 2)"
	logic_mode = DUNGEON_LOGIC_EXACT
	required_nodes = 2

/obj/machinery/f13/dungeon/door_console/preset/xor_single
	name = "dungeon access console (XOR single)"
	logic_mode = DUNGEON_LOGIC_XOR
	required_nodes = 1

/obj/machinery/f13/dungeon/door_console/preset/sequence
	name = "dungeon access console (SEQUENCE)"
	logic_mode = DUNGEON_LOGIC_SEQUENCE
	required_node_ids_text = "alpha,beta,gamma"

/obj/machinery/f13/dungeon/door_console/preset/simultaneous
	name = "dungeon access console (SIMULTANEOUS)"
	logic_mode = DUNGEON_LOGIC_SIMULTANEOUS
	required_nodes = 3
	window_ds = 50

/obj/machinery/f13/dungeon/door_console/preset/weighted
	name = "dungeon access console (WEIGHTED)"
	logic_mode = DUNGEON_LOGIC_N_OF_M
	use_weighted_logic = TRUE
	required_weight = 5
	required_nodes = 0

#undef DUNGEON_LOGIC_ALL
#undef DUNGEON_LOGIC_ANY
#undef DUNGEON_LOGIC_N_OF_M
#undef DUNGEON_LOGIC_EXACT
#undef DUNGEON_LOGIC_XOR
#undef DUNGEON_LOGIC_SEQUENCE
#undef DUNGEON_LOGIC_SIMULTANEOUS
#undef DUNGEON_LOGIC_TIME_WINDOW
#undef DUNGEON_TRIGGER_SOLVE
#undef DUNGEON_TRIGGER_UNSOLVE
#undef DUNGEON_TRIGGER_RESET
#undef DUNGEON_ACTION_OPEN_DOORS
#undef DUNGEON_ACTION_CLOSE_DOORS
#undef DUNGEON_ACTION_CYCLE_DOORS
#undef DUNGEON_ACTION_MESSAGE
#undef DUNGEON_ACTION_MESSAGE_GLOBAL
#undef DUNGEON_ACTION_SOUND
#undef DUNGEON_ACTION_SPAWN_ITEM
#undef DUNGEON_ACTION_SPAWN_MOB
#undef DUNGEON_ACTION_SET_NODE_ON
#undef DUNGEON_ACTION_SET_NODE_OFF
#undef DUNGEON_ACTION_TOGGLE_NODE
#undef DUNGEON_ACTION_RESET_PUZZLE

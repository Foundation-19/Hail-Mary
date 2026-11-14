/// How many tiles away from the builder something can be placed
#define BUILD_PLACEMENT_RANGE 2
#define BUILD_GHOST_VALID "#7dff7d"
#define BUILD_GHOST_INVALID "#ff6e6e"
/// The most tiles a single drag can queue
#define BUILD_QUEUE_MAX 25

/**
 * Placement mode for stack recipes flagged `placeable`.
 *
 * Attached to the builder. Shows a green/red ghost of the result on the hovered tile, builds on
 * click, and revalidates server-side before and after the build time, so the client is only
 * ever a view of the real checks in /datum/buildable/check_placement().
 *
 * Controls: left click builds, hold and drag to build a line, scroll or ctrl-click rotates, middle click
 * cancels. Taking things apart is not part of placement mode: it goes through each structure's own
 * tool deconstruction, guarded by /obj/structure/proc/deconstruct_blocked() (see build_ownership.dm).
 * Design notes: docs/base_building/README.md
 */
/datum/component/build_placement
	var/datum/buildable/buildable
	/// A /datum/stack_recipe (paid from source) or a /datum/crafting_recipe (paid from the builder's surroundings)
	var/recipe
	/// The stack paying for a stack recipe. Null for a crafting recipe.
	var/obj/item/stack/source
	var/build_dir = SOUTH
	var/range = BUILD_PLACEMENT_RANGE
	var/image/ghost
	var/client/viewer
	var/turf/hovered
	var/placing = FALSE
	/// Why can_place() last said no
	var/block_reason
	/// Hover hints are rate limited and only repeat when the tile or reason changes
	var/turf/hinted_turf
	var/hinted_reason
	var/next_hint = 0
	/// Tiles dragged over while a button is held, built one after another
	var/list/queue = list()
	var/processing_queue = FALSE
	var/turf/last_queued
	/// Reason => number of queued tiles skipped for it, reported once the queue empties
	var/list/skipped = list()

/datum/component/build_placement/Initialize(recipe, obj/item/stack/source)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/user = parent
	if(istype(recipe, /datum/stack_recipe))
		var/datum/stack_recipe/stack_recipe = recipe
		if(!stack_recipe.placeable || !istype(source))
			return COMPONENT_INCOMPATIBLE
		buildable = stack_recipe.get_buildable()
	else if(istype(recipe, /datum/crafting_recipe))
		var/datum/crafting_recipe/craft_recipe = recipe
		if(!craft_recipe.is_placeable() || !user.GetComponent(/datum/component/personal_crafting))
			return COMPONENT_INCOMPATIBLE
		buildable = craft_recipe.get_place_buildable()
		source = null
	else
		return COMPONENT_INCOMPATIBLE
	src.recipe = recipe
	src.source = source
	build_dir = user.dir
	var/obj/D = buildable.result_type
	ghost = image(initial(D.icon), icon_state = initial(D.icon_state), layer = ABOVE_ALL_MOB_LAYER)
	ghost.plane = GAME_PLANE
	ghost.alpha = 150
	ghost.dir = buildable.is_directional() ? build_dir : initial(D.dir)
	attach_ghost(user.client)
	to_chat(user, span_notice("Placing [buildable.name]: left click a tile to build, or hold and drag for a line[buildable.is_directional() ? ", scroll or ctrl-click to rotate" : ""]. Middle click to stop."))

/datum/component/build_placement/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_CLICKON, PROC_REF(on_click))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_MOUSEMOVE, PROC_REF(on_mouse_move))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_MOUSEDRAG, PROC_REF(on_mouse_drag))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_MOUSEUP, PROC_REF(on_mouse_up))
	RegisterSignal(parent, COMSIG_MOB_MOUSEWHEEL, PROC_REF(on_wheel))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_login))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_logout))
	// Crafts are built from the surroundings, so there is nothing held to put down or swap away
	if(source)
		RegisterSignal(parent, COMSIG_MOB_SWAP_HANDS, PROC_REF(on_cancel))
		RegisterSignal(source, list(COMSIG_ITEM_DROPPED, COMSIG_PARENT_QDELETING), PROC_REF(on_cancel))
	RegisterSignal(parent, COMSIG_MOB_DEATH, PROC_REF(on_cancel))

/datum/component/build_placement/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_CLICKON, COMSIG_MOB_CLIENT_MOUSEMOVE, COMSIG_MOB_CLIENT_MOUSEDRAG, COMSIG_MOB_CLIENT_MOUSEUP, COMSIG_MOB_MOUSEWHEEL, COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_DEATH, COMSIG_MOB_SWAP_HANDS))
	if(source)
		UnregisterSignal(source, list(COMSIG_ITEM_DROPPED, COMSIG_PARENT_QDELETING))

/datum/component/build_placement/Destroy()
	detach_ghost()
	ghost = null
	source = null
	recipe = null
	buildable = null
	hovered = null
	hinted_turf = null
	last_queued = null
	queue = null
	skipped = null
	return ..()

/datum/component/build_placement/proc/attach_ghost(client/C)
	detach_ghost()
	viewer = C
	if(viewer && ghost)
		viewer.images += ghost

/datum/component/build_placement/proc/detach_ghost()
	if(viewer && ghost)
		viewer.images -= ghost
	viewer = null

/datum/component/build_placement/proc/on_login(datum/source, client/C)
	SIGNAL_HANDLER
	attach_ghost(C)

/datum/component/build_placement/proc/on_logout(datum/source, client/C)
	SIGNAL_HANDLER
	detach_ghost()

/// The range and view checks depend on where the builder stands, so the ghost colour must follow them.
/datum/component/build_placement/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	update_ghost()

/datum/component/build_placement/proc/on_cancel(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/build_placement/proc/on_mouse_move(datum/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	var/turf/T = get_turf(object)
	if(T == hovered)
		return
	hovered = T
	update_ghost()

/datum/component/build_placement/proc/on_wheel(datum/source, atom/A, delta_x, delta_y, params)
	SIGNAL_HANDLER
	rotate(delta_y > 0 ? 90 : -90)

/datum/component/build_placement/proc/on_click(datum/source, atom/A, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(modifiers["shift"] || modifiers["alt"] || modifiers["right"])
		return
	if(modifiers["middle"])
		// With tiles still queued, the first middle click only drops the queue and keeps placement mode
		if(length(queue))
			to_chat(parent, span_notice("You drop the [length(queue)] queued tile\s. Middle click again to stop placing [buildable.name]."))
			queue.Cut()
			return COMSIG_MOB_CANCEL_CLICKON
		to_chat(parent, span_notice("You stop placing [buildable.name]."))
		qdel(src)
		return COMSIG_MOB_CANCEL_CLICKON
	if(modifiers["ctrl"])
		rotate(-90)
		return COMSIG_MOB_CANCEL_CLICKON
	if(!isturf(A) && !isturf(A.loc))
		return
	hovered = get_turf(A)
	INVOKE_ASYNC(src, PROC_REF(try_place), hovered)
	return COMSIG_MOB_CANCEL_CLICKON

/// Holding the left button and dragging builds along the path, so a line of fences is one drag.
/datum/component/build_placement/proc/on_mouse_drag(datum/source, atom/src_object, atom/over_object, over_location, params)
	SIGNAL_HANDLER
	if(!over_object)
		return
	var/list/modifiers = params2list(params)
	if(!modifiers["left"] || modifiers["shift"] || modifiers["alt"] || modifiers["ctrl"] || modifiers["middle"])
		return
	var/turf/T = get_turf(over_object)
	if(!T)
		return
	hovered = T
	update_ghost()
	if(!last_queued)
		var/turf/origin = get_turf(src_object)
		if(!origin)
			return
		queue_tile(origin)
	queue_tile(T)

/datum/component/build_placement/proc/on_mouse_up(datum/source, atom/object, location, params)
	SIGNAL_HANDLER
	last_queued = null

/// Adds T, and any tiles skipped by a fast drag since the last one, to the build queue.
/datum/component/build_placement/proc/queue_tile(turf/T)
	if(T == last_queued)
		return
	var/list/path = list(T)
	if(last_queued)
		path = getline(last_queued, T)
		path.Cut(1, 2)
	last_queued = T
	for(var/turf/tile in path)
		if(length(queue) >= BUILD_QUEUE_MAX)
			break
		if(!(tile in queue))
			queue += tile
	if(!processing_queue)
		INVOKE_ASYNC(src, PROC_REF(process_queue))

/datum/component/build_placement/proc/process_queue()
	if(processing_queue)
		return
	processing_queue = TRUE
	while(!QDELETED(src) && length(queue))
		var/turf/next = queue[1]
		queue.Cut(1, 2)
		// A build already in progress, such as a click, finishes before the queue carries on
		while(placing && !QDELETED(src))
			stoplag()
		if(QDELETED(src))
			break
		try_place(next, TRUE)
	if(QDELETED(src))
		return
	processing_queue = FALSE
	report_skipped()

/// Tells the builder how many tiles of a drag were not built, and why.
/datum/component/build_placement/proc/report_skipped()
	if(!length(skipped))
		return
	var/list/parts = list()
	var/total = 0
	for(var/reason in skipped)
		total += skipped[reason]
		parts += "[skipped[reason]] x [lowertext(reason)]"
	skipped.Cut()
	to_chat(parent, span_notice("Skipped [total] tile\s: [english_list(parts)]"))

/datum/component/build_placement/proc/rotate(degrees)
	// Rotating mid build would change what gets built after the user committed to it
	if(placing || !buildable.is_directional())
		return
	build_dir = turn(build_dir, degrees)
	update_ghost()

/datum/component/build_placement/proc/update_ghost()
	if(!ghost)
		return
	if(!hovered)
		ghost.loc = null
		return
	if(buildable.is_directional())
		ghost.dir = build_dir
	ghost.loc = hovered
	var/valid = can_place(hovered)
	ghost.color = valid ? BUILD_GHOST_VALID : BUILD_GHOST_INVALID
	if(!valid)
		hint_blocked()

/// Tells the builder why the hovered tile is red, once per tile and reason and not more than about once a second.
/datum/component/build_placement/proc/hint_blocked()
	if(!block_reason || world.time < next_hint)
		return
	if(hovered == hinted_turf && block_reason == hinted_reason)
		return
	hinted_turf = hovered
	hinted_reason = block_reason
	next_hint = world.time + 1 SECONDS
	to_chat(parent, span_notice("[block_reason]"))

/// Records why placement is refused, and tells complain if there is someone to tell.
/datum/component/build_placement/proc/refuse(mob/complain, reason)
	block_reason = reason
	if(complain)
		to_chat(complain, span_warning(reason))
	return FALSE

/// Whether the user has what the crafting recipe needs right now. Tells complain what is missing.
/datum/component/build_placement/proc/can_afford(mob/complain)
	var/datum/component/personal_crafting/crafting = parent.GetComponent(/datum/component/personal_crafting)
	if(!crafting)
		return FALSE
	var/blocker = crafting.get_blocker(parent, recipe)
	if(!blocker)
		return TRUE
	if(complain)
		to_chat(complain, span_warning("You can't build \the [buildable.name]: [blocker]."))
	return FALSE

/// Whether the user could build on T right now. Pass a complainer to tell them why not; block_reason is set either way.
/datum/component/build_placement/proc/can_place(turf/T, mob/complain)
	var/mob/living/user = parent
	block_reason = null
	if(!istype(T))
		return refuse(null, "That isn't somewhere you can build.")
	// Crafts are paid for from the surroundings, which is too much to search every time the mouse moves, so they are only checked when building
	if(source && source.get_amount() < buildable.req_amount)
		return refuse(complain, "You haven't got enough [source] to build \the [buildable.name]!")
	if(T.z != user.z || get_dist(user, T) > range)
		return refuse(complain, "That is too far away.")
	if(!(T in view(range, user)))
		return refuse(complain, "You can't see that spot.")
	if(T.density)
		return refuse(complain, "That spot is solid. You can't build there.")
	buildable.last_failure = null
	if(!buildable.check_placement(complain, T, build_dir))
		block_reason = buildable.last_failure
		return FALSE
	return TRUE

/// Whether the builder is still in a state to keep building. Ends placement mode if not.
/datum/component/build_placement/proc/user_can_build()
	var/mob/living/user = parent
	if(user.incapacitated() || (source && (QDELETED(source) || !user.is_holding(source))))
		qdel(src)
		return FALSE
	return TRUE

/datum/component/build_placement/proc/try_place(turf/T, quiet = FALSE)
	if(placing || QDELETED(src) || !user_can_build())
		return
	var/mob/living/user = parent
	// Tiles from a drag fail quietly, since most of a long line is allowed to be blocked
	if(!can_place(T, quiet ? null : user))
		if(quiet)
			skipped[block_reason || "can't build there"]++
		return
	if(!source && !can_afford(user))
		if(quiet)
			skipped["missing materials"]++
		return
	placing = TRUE
	user.face_atom(T)
	var/adjusted_time = source ? buildable.get_build_time(user) : craft_time(user)
	if(adjusted_time)
		user.visible_message(span_notice("[user] starts building [buildable.name]."), span_notice("You start building [buildable.name]..."))
		var/completed = do_after(user, adjusted_time, target = T)
		if(QDELETED(src))
			return
		if(!completed || !user_can_build())
			placing = FALSE
			// An interrupted drag build shouldn't carry on down the line
			if(!QDELETED(src) && quiet && length(queue))
				to_chat(user, span_notice("You stop building, dropping the [length(queue)] queued tile\s."))
				queue.Cut()
			return
		if(!can_place(T, quiet ? null : user) || (!source && !can_afford(quiet ? null : user)))
			placing = FALSE
			if(quiet)
				skipped[block_reason || "can't build there"]++
			return
	if(!source)
		place_craft(user, T)
		return
	// Spending the last of the stack deletes it and so ends placement mode, so only the buildable does the building
	var/needed = buildable.req_amount
	if(!buildable.build_from_stack(user, source, T, build_dir))
		to_chat(user, span_warning("You couldn't build \the [buildable.name]."))
		placing = FALSE
		return
	if(QDELETED(src))
		to_chat(user, span_notice("You've run out of materials."))
		return
	placing = FALSE
	if(QDELETED(source) || source.get_amount() < needed)
		to_chat(user, span_notice("You've run out of materials."))
		qdel(src)
		return
	update_ghost()

/datum/component/build_placement/proc/craft_time(mob/living/user)
	var/datum/crafting_recipe/craft_recipe = recipe
	return craft_recipe.get_craft_time(user)

/// Builds the crafting recipe on T, spending its ingredients from around the builder.
/datum/component/build_placement/proc/place_craft(mob/living/user, turf/T)
	var/datum/component/personal_crafting/crafting = user.GetComponent(/datum/component/personal_crafting)
	var/atom/movable/made = crafting?.place_crafted(user, recipe, T, build_dir)
	placing = FALSE
	if(!made)
		to_chat(user, span_warning("You couldn't build \the [buildable.name]."))
		return
	update_ghost()

/// Starts placement mode for a recipe flagged placeable. Replaces any placement already in progress.
/obj/item/stack/proc/start_placement(mob/living/user, datum/stack_recipe/R)
	if(!R?.placeable || !istype(user))
		return FALSE
	if(get_amount() < R.req_amount)
		to_chat(user, span_warning("You haven't got enough [src] to build \the [R.title]!"))
		return FALSE
	return !!user.AddComponent(/datum/component/build_placement, R, src)

/// Starts placement mode for a crafting recipe the builder lists, if the user has what it takes right now.
/datum/crafting_recipe/proc/start_placement(mob/living/user)
	if(!is_placeable() || !istype(user))
		return FALSE
	var/datum/component/personal_crafting/crafting = user.GetComponent(/datum/component/personal_crafting)
	var/blocker = crafting?.get_blocker(user, src)
	if(blocker)
		to_chat(user, span_warning("You can't build \the [name]: [blocker]."))
		return FALSE
	return !!user.AddComponent(/datum/component/build_placement, src)


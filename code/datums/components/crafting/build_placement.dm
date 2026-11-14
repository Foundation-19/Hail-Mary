/// How many tiles away from the builder something can be placed
#define BUILD_PLACEMENT_RANGE 2
#define BUILD_GHOST_VALID "#7dff7d"
#define BUILD_GHOST_INVALID "#ff6e6e"

/**
 * Placement mode for stack recipes flagged `placeable`.
 *
 * Attached to the builder. Shows a green/red ghost of the result on the hovered tile, builds on
 * click, and revalidates server-side before and after the build time, so the client is only
 * ever a view of the real checks in /datum/buildable/check_placement().
 *
 * Controls: left click builds, scroll or ctrl-click rotates, middle click cancels.
 * Design notes: docs/base_building/README.md
 */
/datum/component/build_placement
	var/datum/buildable/buildable
	var/datum/stack_recipe/recipe
	var/obj/item/stack/source
	var/build_dir = SOUTH
	var/range = BUILD_PLACEMENT_RANGE
	var/image/ghost
	var/client/viewer
	var/turf/hovered
	var/placing = FALSE

/datum/component/build_placement/Initialize(datum/stack_recipe/recipe, obj/item/stack/source)
	if(!isliving(parent) || !istype(recipe) || !recipe.placeable || !istype(source))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/user = parent
	src.recipe = recipe
	src.source = source
	buildable = recipe.get_buildable()
	build_dir = user.dir
	var/obj/D = buildable.result_type
	ghost = image(initial(D.icon), icon_state = initial(D.icon_state), layer = ABOVE_ALL_MOB_LAYER)
	ghost.plane = GAME_PLANE
	ghost.alpha = 150
	ghost.dir = buildable.is_directional() ? build_dir : initial(D.dir)
	attach_ghost(user.client)
	to_chat(user, span_notice("Placing [recipe.title]: left click a tile to build[buildable.is_directional() ? ", scroll or ctrl-click to rotate" : ""], middle click to stop."))

/datum/component/build_placement/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_CLICKON, PROC_REF(on_click))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_MOUSEMOVE, PROC_REF(on_mouse_move))
	RegisterSignal(parent, COMSIG_MOB_MOUSEWHEEL, PROC_REF(on_wheel))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_login))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_logout))
	RegisterSignal(parent, list(COMSIG_MOB_DEATH, COMSIG_MOB_SWAP_HANDS), PROC_REF(on_cancel))
	RegisterSignal(source, list(COMSIG_ITEM_DROPPED, COMSIG_PARENT_QDELETING), PROC_REF(on_cancel))

/datum/component/build_placement/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_CLICKON, COMSIG_MOB_CLIENT_MOUSEMOVE, 	COMSIG_MOB_MOUSEWHEEL, COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_DEATH, COMSIG_MOB_SWAP_HANDS))
	if(source)
		UnregisterSignal(source, list(COMSIG_ITEM_DROPPED, COMSIG_PARENT_QDELETING))

/datum/component/build_placement/Destroy()
	detach_ghost()
	ghost = null
	source = null
	recipe = null
	buildable = null
	hovered = null
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
		to_chat(parent, span_notice("You stop placing [recipe.title]."))
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
	ghost.color = can_place(hovered) ? BUILD_GHOST_VALID : BUILD_GHOST_INVALID

/// Whether the user could build on T right now. Pass a complainer to tell them why not.
/datum/component/build_placement/proc/can_place(turf/T, mob/complain)
	var/mob/living/user = parent
	if(!istype(T))
		return FALSE
	if(source.get_amount() < buildable.req_amount)
		if(complain)
			to_chat(complain, span_warning("You haven't got enough [source] to build \the [buildable.name]!"))
		return FALSE
	if(T.z != user.z || get_dist(user, T) > range)
		if(complain)
			to_chat(complain, span_warning("That is too far away."))
		return FALSE
	if(!(T in view(range, user)))
		if(complain)
			to_chat(complain, span_warning("You can't see that spot."))
		return FALSE
	return buildable.check_placement(complain, T, build_dir)

/// Whether the builder is still in a state to keep building. Ends placement mode if not.
/datum/component/build_placement/proc/user_can_build()
	var/mob/living/user = parent
	if(QDELETED(source) || !user.is_holding(source) || user.incapacitated())
		qdel(src)
		return FALSE
	return TRUE

/datum/component/build_placement/proc/try_place(turf/T)
	if(placing || QDELETED(src) || !user_can_build())
		return
	var/mob/living/user = parent
	if(!can_place(T, user))
		return
	placing = TRUE
	user.face_atom(T)
	if(buildable.build_time)
		var/adjusted_time = buildable.get_build_time(user)
		user.visible_message(span_notice("[user] starts building [buildable.name]."), span_notice("You start building [buildable.name]..."))
		var/completed = do_after(user, adjusted_time, target = T)
		if(QDELETED(src))
			return
		if(!completed || !user_can_build() || !can_place(T, user))
			placing = FALSE
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

/// Starts placement mode for a recipe flagged placeable. Replaces any placement already in progress.
/obj/item/stack/proc/start_placement(mob/living/user, datum/stack_recipe/R)
	if(!R?.placeable || !istype(user))
		return FALSE
	if(get_amount() < R.req_amount)
		to_chat(user, span_warning("You haven't got enough [src] to build \the [R.title]!"))
		return FALSE
	return !!user.AddComponent(/datum/component/build_placement, R, src)

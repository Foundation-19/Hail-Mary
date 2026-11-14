/**
 * Shared placement rules for anything a player builds.
 *
 * Stack recipes and crafting recipes are adapted onto this (see get_buildable()) so that
 * every build path validates and spawns through the same code.
 * Design notes: docs/base_building/README.md
 */
/datum/buildable
	var/name = "ERROR"
	var/result_type
	/// Refuse if another of result_type is already on the turf
	var/one_per_turf = FALSE
	/// Must be built on a floor or ground turf, and not on top of dense objects
	var/on_floor = FALSE
	/// Run valid_window_location() for the build direction
	var/window_checks = FALSE
	/// STACK_CHECK_CARDINALS or STACK_CHECK_ADJACENT
	var/placement_checks = FALSE

/datum/buildable/New(name, result_type, one_per_turf = FALSE, on_floor = FALSE, window_checks = FALSE, placement_checks = FALSE)
	src.name = name
	src.result_type = result_type
	src.one_per_turf = one_per_turf
	src.on_floor = on_floor
	src.window_checks = window_checks
	src.placement_checks = placement_checks

/// Whether any placement rule is set. Callers can skip validation entirely when this is false.
/datum/buildable/proc/has_placement_rules()
	return one_per_turf || on_floor || window_checks || placement_checks

/// Checks whether this can be built on target by user facing build_dir. Tells the user why not.
/datum/buildable/proc/check_placement(mob/user, turf/target, build_dir)
	if(!isturf(target))
		return FALSE
	var/obj/D = result_type
	if(window_checks && !valid_window_location(target, initial(D.dir) == FULLTILE_WINDOW_DIR ? FULLTILE_WINDOW_DIR : build_dir))
		placement_failed(user, "The [name] won't fit here!")
		return FALSE
	if(one_per_turf && (locate(result_type) in target))
		placement_failed(user, "There is another [name] here!")
		return FALSE
	if(on_floor)
		if(!isfloorturf(target) && !isgroundturf(target))
			placement_failed(user, "\The [name] must be constructed on the floor!")
			return FALSE
		for(var/obj/AM in target)
			if(istype(AM, /obj/structure/grille))
				continue
			if(istype(AM, /obj/structure/table))
				continue
			if(istype(AM, /obj/structure/window))
				var/obj/structure/window/W = AM
				if(!W.fulltile)
					continue
			if(AM.density)
				placement_failed(user, "Theres a [AM.name] here. You cant make a [name] here!")
				return FALSE
	if(placement_checks)
		switch(placement_checks)
			if(STACK_CHECK_CARDINALS)
				for(var/direction in GLOB.cardinals)
					if(locate(result_type) in get_step(target, direction))
						placement_failed(user, "\The [name] must not be built directly adjacent to another!")
						return FALSE
			if(STACK_CHECK_ADJACENT)
				if(locate(result_type) in range(1, target))
					placement_failed(user, "\The [name] must be constructed at least one tile away from others of its type!")
					return FALSE
	return TRUE

/datum/buildable/proc/placement_failed(mob/user, message)
	if(user)
		to_chat(user, span_warning(message))

/// Spawns result_type on target facing build_dir. Types that remember their initial direction
/// override set_build_dir() so nothing has to patch it up after the fact.
/datum/buildable/proc/create(turf/target, build_dir)
	var/atom/movable/A = new result_type(target)
	if(A && !QDELETED(A))
		A.set_build_dir(build_dir)
	return A

/// Called when a player builds this with a chosen direction. Override to also record an initial direction.
/atom/movable/proc/set_build_dir(new_dir)
	setDir(new_dir)

/datum/stack_recipe/proc/get_buildable()
	if(!buildable)
		buildable = new /datum/buildable(title, result_type, one_per_turf, on_floor, window_checks, placement_checks)
	return buildable

/datum/crafting_recipe/proc/get_buildable()
	if(!buildable)
		buildable = new /datum/buildable(name, result, one_per_turf, on_floor, window_checks, placement_checks)
	return buildable

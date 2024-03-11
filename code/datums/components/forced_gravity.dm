/datum/component/forced_gravity
	var/gravity
	var/ignore_space = FALSE	//If forced gravity should also work on space turfs

/datum/component/forced_gravity/Initialize(forced_value = 1)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(COMSIG_ATOM_HAS_GRAVITY, PROC_REF(gravity_check))
	if(isturf(parent))
		RegisterSignal(COMSIG_TURF_HAS_GRAVITY, PROC_REF(turf_gravity_check))

	gravity = forced_value

TYPE_PROC_REF(/datum/component/forced_gravity, gravity_check)(turf/location, list/gravs)
	if(!ignore_space && isspaceturf(location))
		return
	gravs += gravity

TYPE_PROC_REF(/datum/component/forced_gravity, turf_gravity_check)(atom/checker, list/gravs)
	return gravity_check(parent, gravs)

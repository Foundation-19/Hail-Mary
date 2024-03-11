/datum/component/magnetic_catch/Initialize()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(examine))
	if(ismovable(parent))
		RegisterSignal(parent, COMSIG_MOVABLE_CROSSED, PROC_REF(crossed_react))
		RegisterSignal(parent, COMSIG_MOVABLE_UNCROSSED, PROC_REF(uncrossed_react))
		for(var/i in get_turf(parent))
			if(i == parent)
				continue
			RegisterSignal(i, COMSIG_MOVABLE_PRE_THROW, PROC_REF(throw_react))
	else
		RegisterSignal(parent, COMSIG_ATOM_ENTERED, PROC_REF(entered_react))
		RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(exited_react))
		for(var/i in parent)
			RegisterSignal(i, COMSIG_MOVABLE_PRE_THROW, PROC_REF(throw_react))

TYPE_PROC_REF(/datum/component/magnetic_catch, examine)(datum/source, mob/user, list/examine_list)
	examine_list += "It has been installed with inertia dampening to prevent coffee spills."

TYPE_PROC_REF(/datum/component/magnetic_catch, crossed_react)(datum/source, atom/movable/thing)
	RegisterSignal(thing, COMSIG_MOVABLE_PRE_THROW, PROC_REF(throw_react), TRUE)

TYPE_PROC_REF(/datum/component/magnetic_catch, uncrossed_react)(datum/source, atom/movable/thing)
	UnregisterSignal(thing, COMSIG_MOVABLE_PRE_THROW)

TYPE_PROC_REF(/datum/component/magnetic_catch, entered_react)(datum/source, atom/movable/thing, atom/oldloc)
	RegisterSignal(thing, COMSIG_MOVABLE_PRE_THROW, PROC_REF(throw_react), TRUE)

TYPE_PROC_REF(/datum/component/magnetic_catch, exited_react)(datum/source, atom/movable/thing, atom/newloc)
	UnregisterSignal(thing, COMSIG_MOVABLE_PRE_THROW)

TYPE_PROC_REF(/datum/component/magnetic_catch, throw_react)(datum/source, list/arguments)
	return COMPONENT_CANCEL_THROW

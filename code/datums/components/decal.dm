/datum/component/decal
	dupe_mode = COMPONENT_DUPE_ALLOWED

	var/cleanable
	var/description
	var/mutable_appearance/pic

	var/first_dir // This only stores the dir arg from init

/datum/component/decal/Initialize(_icon, _icon_state, _dir, _cleanable=CLEAN_GOD, _color, _layer=TURF_LAYER, _description)
	if(!isatom(parent) || !generate_appearance(_icon, _icon_state, _dir, _layer, _color))
		return COMPONENT_INCOMPATIBLE
	first_dir = _dir
	description = _description
	cleanable = _cleanable

	apply()

/datum/component/decal/RegisterWithParent()
	if(first_dir)
		RegisterSignal(parent, COMSIG_ATOM_DIR_CHANGE, PROC_REF(rotate_react))
	if(cleanable)
		RegisterSignal(parent, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(clean_react))
	if(description)
		RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(examine))

/datum/component/decal/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_COMPONENT_CLEAN_ACT, COMSIG_PARENT_EXAMINE))

/datum/component/decal/Destroy()
	remove()
	return ..()

/datum/component/decal/PreTransfer()
	remove()

/datum/component/decal/PostTransfer()
	remove()
	apply()

TYPE_PROC_REF(/datum/component/decal, generate_appearance)(_icon, _icon_state, _dir, _layer, _color)
	if(!_icon || !_icon_state)
		return FALSE
	// It has to be made from an image or dir breaks because of a byond bug
	var/temp_image = image(_icon, null, _icon_state, _layer, _dir)
	pic = new(temp_image)
	pic.color = _color
	return TRUE

TYPE_PROC_REF(/datum/component/decal, apply)(atom/thing)
	var/atom/master = thing || parent
	master.add_overlay(pic, TRUE)
	if(isitem(master))
		addtimer(CALLBACK(master, TYPE_PROC_REF(/obj/item, update_slot_icon)), 0, TIMER_UNIQUE)

TYPE_PROC_REF(/datum/component/decal, remove)(atom/thing)
	var/atom/master = thing || parent
	master.cut_overlay(pic, TRUE)
	if(isitem(master))
		addtimer(CALLBACK(master, TYPE_PROC_REF(/obj/item, update_slot_icon)), 0, TIMER_UNIQUE)

TYPE_PROC_REF(/datum/component/decal, rotate_react)(old_dir, new_dir)
	if(old_dir == new_dir)
		return
	remove()
	pic.dir = turn(pic.dir, dir2angle(old_dir) - dir2angle(new_dir))
	apply()

TYPE_PROC_REF(/datum/component/decal, clean_react)(strength)
	if(strength >= cleanable)
		qdel(src)

TYPE_PROC_REF(/datum/component/decal, examine)(mob/user)
	to_chat(user, description)

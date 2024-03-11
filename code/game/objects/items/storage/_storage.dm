
/obj/item/storage
	name = "storage"
	icon = 'icons/obj/storage.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	var/component_type = /datum/component/storage/concrete
	var/in_use = FALSE

/obj/item/storage/get_dumping_location(obj/item/storage/source,mob/user)
	return src

/obj/item/storage/Initialize()
	. = ..()
	PopulateContents()

/obj/item/storage/ComponentInitialize()
	AddComponent(component_type)
	//RegisterSignal(src, COMSIG_VORE_ATOM_DIGESTED, PROC_REF(dump_everything)) // TODO: Make this work

/obj/item/storage/AllowDrop()
	return TRUE

/obj/item/storage/contents_explosion(severity, target)
	var/in_storage = istype(loc, /obj/item/storage)? (max(0, severity - 1)) : (severity)
	for(var/atom/A in contents)
		A.ex_act(in_storage, target)
		CHECK_TICK

//Cyberboss says: "USE THIS TO FILL IT, NOT INITIALIZE OR NEW"
/obj/item/storage/proc/PopulateContents()

/obj/item/storage/proc/dump_everything(datum/source)
	SIGNAL_HANDLER
	SEND_SIGNAL(src, COMSIG_TRY_STORAGE_HIDE_ALL)
	if(contents)
		SEND_SIGNAL(src, COMSIG_TRY_STORAGE_QUICK_EMPTY)
		return TRUE
	//qdel(src)

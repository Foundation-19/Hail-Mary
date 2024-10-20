/datum/component/storage/concrete/trunk
	var/dumping_sound = 'sound/mecha/neostep1.ogg'


/datum/component/storage/concrete/trunk/mousedrop_onto()
	var/obj/item/mecha_parts/mecha_equipment/trunk/P = parent
	if(!P.chassis)
		P.visible_message("<span class='warning'>The [P] is not installed!.</span>", "<span class='warning'>someone tried to open you!.</span>")
		return
	. = ..()

/datum/component/storage/concrete/trunk/dump_content_at(atom/dest_object, mob/M)
	var/obj/item/mecha_parts/mecha_equipment/trunk/P = parent
	var/obj/mecha/A = P.chassis
	if(!A)
		P.visible_message("<span class='warning'>The [P] is not installed!.</span>", "<span class='warning'>someone tried to open you!.</span>")
		return
	var/atom/dump_destination = dest_object.get_dumping_location()
	if(A.Adjacent(M) && dump_destination && M.Adjacent(dump_destination))
		if(check_locked(null, M, TRUE))
			return FALSE
		if(dump_destination.storage_contents_dump_act(src, M))
			playsound(A, "rustle", 50, 1, -5)
			A.do_squish(0.8, 1.2)
			return TRUE
	return FALSE

/datum/component/storage/concrete/trunk/signal_take_type(datum/source, type, atom/destination, amount = INFINITY, check_adjacent = FALSE, force = FALSE, mob/user, list/inserted)
	if(!force)
		if(check_adjacent)
			if(!user || !user.can_reach(destination) || !user.can_reach(parent))
				return FALSE
	var/list/taking = typecache_filter_list(contents(), typecacheof(type))
	if(taking.len > amount)
		taking.len = amount
	if(inserted)			//duplicated code for performance, don't bother checking retval/checking for list every item.
		for(var/i in taking)
			if(remove_from_storage(i, destination))
				inserted |= i
	else
		for(var/i in taking)
			remove_from_storage(i, destination)
	return TRUE

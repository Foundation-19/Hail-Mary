/mob/living/proc/handle_recoil(obj/item/gun/G, recoil_buildup)
	add_recoil(recoil_buildup)

/mob/living/proc/external_recoil(recoil_buildup) // Used in human_attackhand.dm
	add_recoil(recoil_buildup)

mob/proc/handle_movement_recoil() // Used in movement/mob.dm
	return // Ghosts and roaches have no movement recoil

/**
 * Settles recoil down based on how much real time has actually passed since we last touched it, instead of
 * relying on a scheduled callback that rapid-fire shots/footsteps kept cancelling and pushing back before it
 * could ever run. This is what lets aim recover mid-burst instead of only once you stop entirely.
 */
/mob/living/proc/decay_recoil()
	if(!recoil)
		recoil_last_update = world.time
		return
	var/steps = round((world.time - recoil_last_update) / RECOIL_DECAY_TICK)
	if(steps <= 0)
		return
	var/scale = HAS_TRAIT(src, SPREAD_CONTROL) ? 0.5 : RECOIL_DECAY_MULT
	for(var/i in 1 to min(steps, RECOIL_DECAY_MAX_CATCHUP))
		if(recoil <= RECOIL_DECAY_FLAT)
			recoil = 0
			break
		recoil -= RECOIL_DECAY_FLAT
		recoil *= scale
	recoil_last_update = world.time

/mob/living/proc/add_recoil(recoil_buildup)
	decay_recoil()
	if(recoil_buildup)
		if(HAS_TRAIT(src, SPREAD_CONTROL))
			recoil_buildup *= 0.5
		recoil += recoil_buildup
		update_recoil()

/// Periodic cosmetic nudge so recoil visibly settles back to 0 (and the cursor updates) even if nothing else touches it
/mob/living/proc/calc_recoil()
	recoil_reduction_timer = null
	decay_recoil()
	update_recoil()

/mob/living/proc/calculate_offset(offset = 0)
	decay_recoil()
	if(recoil)
		offset += recoil
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(H.head)
			offset += H.head.obscuration

	offset = round(RECOIL_SPREAD_CALC(offset))
	offset = CLAMP(offset, 0, MAX_ACCURACY_OFFSET)
	return offset

//Called after setting recoil
/mob/living/proc/update_recoil()
	var/obj/item/gun/G = get_active_held_item()
	if(istype(G) && G)
		G.check_safety_cursor(src)

	if(recoil > 0)
		if(!recoil_reduction_timer)
			recoil_reduction_timer = addtimer(CALLBACK(src, PROC_REF(calc_recoil)), RECOIL_DECAY_TICK, TIMER_STOPPABLE)
	else
		if(!istype(G))
			remove_cursor()
		deltimer(recoil_reduction_timer)
		recoil_reduction_timer = null

/mob/living/proc/update_cursor(obj/item/gun/G)
	if(!(istype(get_active_held_item(), /obj/item/gun) || recoil > 0))
		remove_cursor()
		return
	if(client)
		if(!CHECK_BITFIELD(client.prefs.cb_toggles, AIM_CURSOR_ON))
			remove_cursor()
			return
		client.mouse_pointer_icon = initial(client.mouse_pointer_icon)
		var/offset = round(calculate_offset(G.added_spread) * 0.8)
		var/icon/base = find_cursor_icon('icons/obj/eris_standard.dmi', offset)
		ASSERT(isicon(base))
		client.mouse_pointer_icon = base

/mob/living/proc/remove_cursor()
	if(client)
		client.mouse_pointer_icon = initial(client.mouse_pointer_icon)

/proc/find_cursor_icon(icon_file, offset)
	var/list/L = GLOB.cursor_icons[icon_file]
	if(L)
		return L["[offset]"]

/proc/add_cursor_icon(icon/icon, icon_file, offset)
	var/list/L = GLOB.cursor_icons[icon_file]
	if(!L)
		GLOB.cursor_icons[icon_file] = list()
		L = GLOB.cursor_icons[icon_file]
	L["[offset]"] = icon

/proc/make_cursor_icon(icon_file, offset)
	var/icon/base = icon('icons/effects/96x96_eris.dmi')
	var/icon/scaled = icon('icons/obj/eris_standard.dmi') //Default cursor, cut into pieces according to their direction
	base.Blend(scaled, ICON_OVERLAY, x = 32, y = 32)

	for(var/dir in list(NORTHEAST,NORTHWEST,SOUTHEAST,SOUTHWEST))
		var/icon/overlay = icon('icons/obj/eris_standard.dmi', "[dir]")
		var/pixel_y
		var/pixel_x
		if(dir & NORTH)
			pixel_y = CLAMP(offset, -MAX_ACCURACY_OFFSET, MAX_ACCURACY_OFFSET)
		if(dir & SOUTH)
			pixel_y = CLAMP(-offset, -MAX_ACCURACY_OFFSET, MAX_ACCURACY_OFFSET)
		if(dir & EAST)
			pixel_x = CLAMP(offset, -MAX_ACCURACY_OFFSET, MAX_ACCURACY_OFFSET)
		if(dir & WEST)
			pixel_x = CLAMP(-offset, -MAX_ACCURACY_OFFSET, MAX_ACCURACY_OFFSET)
		base.Blend(overlay, ICON_OVERLAY, x=32+pixel_x, y=32+pixel_y)
	add_cursor_icon(base, 'icons/obj/eris_standard.dmi', offset)
	return base

/proc/send_all_cursor_icons(client/C)
	var/list/cursor_icons = GLOB.cursor_icons
	for(var/icon_file in cursor_icons)
		var/list/icons = cursor_icons[icon_file]
		for(var/offset in icons)
			var/icon/I = icons[offset]
			C << I

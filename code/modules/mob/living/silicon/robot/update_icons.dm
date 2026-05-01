/// this is bad code
/mob/living/silicon/robot/update_icons()
	cut_overlays()
	icon_state = module.cyborg_base_icon

	// Icon file is declared per-module as cyborg_icon_file (defaults to robots.dmi).
	icon = module.cyborg_icon_file
	if(stat != DEAD && !(IsUnconscious() ||IsStun() || IsKnockdown() || IsParalyzed() || low_power_mode)) //Not dead, not stunned.
		if(!eye_lights)
			eye_lights = new()
		// cyborg_eye_state is set per-module. F13 dmi files use "eyes-[name]"; vanilla uses "[name]_e".
		var/eye_key = module.special_light_key ? module.special_light_key : module.cyborg_eye_state
		if(module.cyborg_eye_state)
			eye_lights.icon_state = eye_key
			eye_lights.icon = module.cyborg_icon_file
			add_overlay(eye_lights)

	if(opened && module.has_cover_overlay)
		if(wiresexposed)
			add_overlay("ov-opencover +w")
		else if(cell)
			add_overlay("ov-opencover +c")
		else
			add_overlay("ov-opencover -c")
	if(hat)
		var/mutable_appearance/head_overlay = hat.build_worn_icon(default_layer = 20, default_icon_file = 'icons/mob/clothing/head.dmi', override_state = hat.icon_state)
		head_overlay.pixel_y += hat_offset
		add_overlay(head_overlay)
	update_fire()

	SEND_SIGNAL(src, COMSIG_ROBOT_UPDATE_ICONS)

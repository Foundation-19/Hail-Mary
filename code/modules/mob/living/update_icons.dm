//IMPORTANT: Multiple animate() calls do not stack well, so try to do them all at once if you can.
/mob/living/update_transform()
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	var/final_pixel_y = pixel_y
	var/changed = 0

	appearance_flags |= PIXEL_SCALE

	if(lying != lying_prev && rotate_on_lying)
		changed++
		ntransform.TurnTo(lying_prev,lying)
		if(lying == 0) //Lying to standing
			final_pixel_y = get_standard_pixel_y_offset()
		else //if(lying != 0)
			if(lying_prev == 0) //Standing to lying
				pixel_y = get_standard_pixel_y_offset()
				final_pixel_y = get_standard_pixel_y_offset(lying)
				if(dir & (EAST|WEST)) //Facing east or west
					setDir(pick(NORTH, SOUTH)) //So you fall on your side rather than your face or ass

	if(resize != RESIZE_DEFAULT_SIZE)
		changed++
		ntransform.Scale(resize)
		resize = RESIZE_DEFAULT_SIZE

	if(changed)
		animate(src, transform = ntransform, time = 2, pixel_y = final_pixel_y, easing = EASE_IN|EASE_OUT)
		floating_need_update = TRUE

/mob/living/carbon/human
	var/list/overlays_standing[TOTAL_LAYERS]
	var/list/underlays_standing[TOTAL_UNDERLAYS]
	var/previous_damage_appearance // store what the body last looked like, so we only have to update it if something changed

/mob/living/carbon/human/apply_overlay(cache_index)
	var/list/to_add = list()
	SEND_SIGNAL(src, COMSIG_HUMAN_APPLY_OVERLAY, cache_index, to_add)
	var/image/I = overlays_standing[cache_index]
	if(I)
		//TODO THIS SHOULD USE THE API!
		to_add += I
	overlays += to_add

/mob/living/carbon/human/remove_overlay(cache_index)
	var/list/to_remove = list()
	SEND_SIGNAL(src, COMSIG_HUMAN_REMOVE_OVERLAY, cache_index, to_remove)
	if(overlays_standing[cache_index])
		to_remove += overlays_standing[cache_index]
		overlays_standing[cache_index] = null
	overlays -= to_remove

/mob/living/carbon/human/apply_underlay(cache_index)
	var/image/I = underlays_standing[cache_index]
	if(I)
		underlays += I

/mob/living/carbon/human/remove_underlay(cache_index)
	if(underlays_standing[cache_index])
		underlays -= underlays_standing[cache_index]
		underlays_standing[cache_index] = null

/mob/living/carbon/human/update_inv_wear_suit()
	remove_overlay(SUIT_LAYER)
	species?.update_inv_wear_suit(src)
	if(!wear_suit)
		return

	if(client && hud_used?.hud_shown && hud_used.inventory_shown)
		wear_suit.screen_loc = ui_oclothing
		client.screen += wear_suit

	overlays_standing[SUIT_LAYER] = wear_suit.make_worn_icon(species_type = species.name, slot_name = slot_wear_suit_str, default_icon = 'icons/mob/clothing/suits/suit_0.dmi', default_layer = SUIT_LAYER)

	apply_overlay(SUIT_LAYER)

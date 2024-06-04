/// Sprint buffer ///
/mob/living/carbon/doSprintLossTiles(tiles)
	doSprintBufferRegen(FALSE)		//first regen.
	if(sprint_buffer)
		var/use = min(tiles, sprint_buffer)
		var/special_discount = calc_sprint_stamina_mod_from_special(tiles) // S.P.E.C.I.A.L.
		if(HAS_TRAIT(src, TRAIT_SPEED))
			sprint_buffer -= (use * 0.5) * special_discount
		else
			sprint_buffer -= (use * special_discount)
			tiles -= use
	update_hud_sprint_bar()
	if(!tiles)		//we had enough, we're done!
		return
	var/datum/keybinding/living/toggle_sprint/sprint_bind = GLOB.keybindings_by_name["toggle_sprint"]
	var/datum/keybinding/living/hold_sprint/sprint_hold_bind = GLOB.keybindings_by_name["hold_sprint"]
	if(!client || !((client in sprint_bind.is_down) || (client in sprint_hold_bind.is_down))) // there are two keybinds, apparently
		disable_intentional_sprint_mode()
		return // if you're not holding it, you stop sprinting when you run out
	if(HAS_TRAIT(src, TRAIT_SPEED))
		adjustStaminaLoss(tiles * sprint_stamina_cost * 0.5)
	if(HAS_TRAIT(src, TRAIT_SUPER_SPEED))
		return
	else
		adjustStaminaLoss(tiles * sprint_stamina_cost)		//use stamina to cover deficit.

/mob/living/carbon/proc/doSprintBufferRegen(updating = TRUE)
	var/diff = world.time - sprint_buffer_regen_last
	sprint_buffer_regen_last = world.time
	sprint_buffer = min(sprint_buffer_max, sprint_buffer + sprint_buffer_regen_ds * diff)
	if(updating)
		update_hud_sprint_bar()

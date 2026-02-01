/mob/living/carbon
	var/saved_sprint_buffer = 0
	var/saved_sprint_buffer_max = 0

/mob/living/carbon/doSprintLossTiles(tiles)
	// Check if we're mounted
	var/atom/movable/buckled_to_obj = buckled
	if(buckled_to_obj && istype(buckled_to_obj, /mob/living/simple_animal/cow))
		var/mob/living/simple_animal/cow/mount = buckled_to_obj
		return mount.doMountSprintLoss(tiles, src)
	
	// NORMAL PLAYER SPRINT
	doSprintBufferRegen(FALSE)
	sprint_idle_time = 0
	if(sprint_buffer)
		var/use = min(tiles, sprint_buffer)
		var/special_discount = calc_sprint_stamina_mod_from_special()
		if(HAS_TRAIT(src, TRAIT_SPEED))
			sprint_buffer -= (use * 0.5) * special_discount
		else
			sprint_buffer -= (use * special_discount)
			tiles -= use
	update_hud_sprint_bar()
	if(!tiles)
		return
	var/datum/keybinding/living/toggle_sprint/sprint_bind = GLOB.keybindings_by_name["toggle_sprint"]
	var/datum/keybinding/living/hold_sprint/sprint_hold_bind = GLOB.keybindings_by_name["hold_sprint"]
	if(!client || !((client in sprint_bind.is_down) || (client in sprint_hold_bind.is_down)))
		disable_intentional_sprint_mode()
		return
	var/stamina_modifier = calc_sprint_stamina_mod_from_special()
	if(HAS_TRAIT(src, TRAIT_SPEED))
		adjustStaminaLoss(tiles * sprint_stamina_cost * 0.5 * stamina_modifier)
	else if(HAS_TRAIT(src, TRAIT_SUPER_SPEED))
		return
	else
		adjustStaminaLoss(tiles * sprint_stamina_cost * stamina_modifier)

/mob/living/carbon/proc/save_sprint_on_mount(mob/living/simple_animal/cow/mount)
	saved_sprint_buffer = sprint_buffer
	saved_sprint_buffer_max = sprint_buffer_max
	
	var/mount_sprint_percent = 1 - ((mount.hunger - 1) / 3.0)
	sprint_buffer_max = 100
	sprint_buffer = sprint_buffer_max * mount_sprint_percent
	update_hud_sprint_bar()

/mob/living/carbon/proc/restore_sprint_on_dismount()
	sprint_buffer = saved_sprint_buffer
	sprint_buffer_max = saved_sprint_buffer_max
	saved_sprint_buffer = 0
	saved_sprint_buffer_max = 0
	update_hud_sprint_bar()

/mob/living/carbon/proc/doSprintBufferRegen(updating = TRUE)
	// Don't regenerate sprint buffer if mounted - mount controls the display
	if(buckled && istype(buckled, /mob/living/simple_animal/cow))
		return
	
	var/diff = world.time - sprint_buffer_regen_last
	sprint_buffer_regen_last = world.time
	
	// Track time since last sprint
	sprint_idle_time += diff
	
	// Apply regen boost if idle for 3+ seconds (30 deciseconds)
	var/regen_rate = sprint_buffer_regen_ds
	if(sprint_idle_time >= 30)
		regen_rate *= 1.25 // 25% boost to regen when not sprinting for 3+ seconds
	
	sprint_buffer = min(sprint_buffer_max, sprint_buffer + regen_rate * diff)
	if(updating)
		update_hud_sprint_bar()

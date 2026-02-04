/mob/proc/overlay_fullscreen(category, type, severity)
	var/obj/screen/fullscreen/screen = screens[category]
	if (!screen || screen.type != type)
		// needs to be recreated
		clear_fullscreen(category, FALSE)
		screens[category] = screen = new type()
	else if ((!severity || severity == screen.severity) && (!client || screen.screen_loc != "CENTER-7,CENTER-7" || screen.view == client.view))
		// doesn't need to be updated
		return screen

	screen.icon_state = "[initial(screen.icon_state)][severity]"
	screen.severity = severity
	if (client && screen.should_show_to(src))
		screen.update_for_view(client.view)
		client.screen += screen

	return screen

/mob/proc/clear_fullscreen(category, animated = 10)
	var/obj/screen/fullscreen/screen = screens[category]
	if(!screen)
		return

	screens -= category

	if(animated)
		animate(screen, alpha = 0, time = animated)
		addtimer(CALLBACK(src, PROC_REF(clear_fullscreen_after_animate), screen), animated, TIMER_CLIENT_TIME)
	else
		if(client)
			client.screen -= screen
		qdel(screen)

/mob/proc/clear_fullscreen_after_animate(obj/screen/fullscreen/screen)
	if(client)
		client.screen -= screen
	qdel(screen)

/mob/proc/clear_fullscreens()
	for(var/category in screens)
		clear_fullscreen(category)

/mob/proc/hide_fullscreens()
	if(client)
		for(var/category in screens)
			client.screen -= screens[category]

/mob/proc/reload_fullscreen()
	if(client)
		var/obj/screen/fullscreen/screen
		for(var/category in screens)
			screen = screens[category]
			if(screen.should_show_to(src))
				screen.update_for_view(client.view)
				client.screen |= screen
			else
				client.screen -= screen

/obj/screen/fullscreen
	icon = 'icons/mob/screen_full.dmi'
	icon_state = "default"
	screen_loc = "CENTER-7,CENTER-7"
	layer = FULLSCREEN_LAYER
	plane = FULLSCREEN_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/view = 7
	var/severity = 0
	var/show_when_dead = FALSE

/obj/screen/fullscreen/proc/update_for_view(client_view)
	if(!client_view)
		return  // Skip update if no view parameter
	if (screen_loc == "CENTER-7,CENTER-7" && view != client_view)
		var/list/actualview = getviewsize(client_view)
		if(!actualview || actualview.len < 2)
			return  // Skip if view size calculation fails
		view = client_view
		transform = matrix(actualview[1]/FULLSCREEN_OVERLAY_RESOLUTION_X, 0, 0, 0, actualview[2]/FULLSCREEN_OVERLAY_RESOLUTION_Y, 0)

/obj/screen/fullscreen/proc/should_show_to(mob/mymob)
	if(!show_when_dead && mymob.stat == DEAD)
		return FALSE
	return TRUE

/obj/screen/fullscreen/Destroy()
	severity = 0
	. = ..()

/obj/screen/fullscreen/brute
	icon_state = "brutedamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/obj/screen/fullscreen/oxy
	icon_state = "oxydamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/obj/screen/fullscreen/crit
	icon_state = "passage"
	layer = CRIT_LAYER
	plane = FULLSCREEN_PLANE

/obj/screen/fullscreen/crit/vision
	icon_state = "oxydamageoverlay"
	layer = BLIND_LAYER

/obj/screen/fullscreen/blind
	icon_state = "blackimageoverlay"
	layer = BLIND_LAYER
	plane = FULLSCREEN_PLANE

/obj/screen/fullscreen/curse
	icon_state = "curse"
	layer = CURSE_LAYER
	plane = FULLSCREEN_PLANE

/obj/screen/fullscreen/impaired
	icon_state = "impairedoverlay"

/obj/screen/fullscreen/blurry
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "blurry"

/obj/screen/fullscreen/flash
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"

/obj/screen/fullscreen/flash/static
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "noise"

/obj/screen/fullscreen/high
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "druggy"

/obj/screen/fullscreen/color_vision
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	alpha = 80

/obj/screen/fullscreen/color_vision/green
	color = "#00ff00"

/obj/screen/fullscreen/color_vision/red
	color = "#ff0000"

/obj/screen/fullscreen/color_vision/blue
	color = "#0000ff"

/obj/screen/fullscreen/lighting_backdrop
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	transform = matrix(200, 0, 0, 0, 200, 0)
	plane = LIGHTING_PLANE
	blend_mode = BLEND_OVERLAY
	show_when_dead = TRUE

//Provides darkness to the back of the lighting plane
/obj/screen/fullscreen/lighting_backdrop/lit
	invisibility = INVISIBILITY_LIGHTING
	layer = BACKGROUND_LAYER+21
	color = "#06090C"
	show_when_dead = TRUE

//Provides whiteness in case you don't see lights so everything is still visible
/obj/screen/fullscreen/lighting_backdrop/unlit
	layer = BACKGROUND_LAYER+20
	color = "#B7C7D6"
	alpha = 190
	show_when_dead = TRUE

/obj/screen/fullscreen/lighting_grain
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "noise"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+22
	blend_mode = BLEND_OVERLAY
	alpha = 10
	color = "#B8AD94"
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_transition
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = FULLSCREEN_PLANE
	layer = CURSE_LAYER
	color = "#06080C"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_exposure
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+23
	blend_mode = BLEND_MULTIPLY
	color = "#0B1015"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_mood
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+24
	blend_mode = BLEND_OVERLAY
	color = "#D27A34"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_rads
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "noise"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+25
	blend_mode = BLEND_OVERLAY
	color = "#96FF8E"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_heat_haze
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "noise"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+26
	blend_mode = BLEND_ADD
	color = "#FFC67A"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_emergency
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+27
	blend_mode = BLEND_OVERLAY
	color = "#FF4C3E"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_dust
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "noise"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+28
	blend_mode = BLEND_OVERLAY
	color = "#D9B983"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/cinematic_lens_glow
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER+29
	blend_mode = BLEND_ADD
	color = "#A6D8FF"
	alpha = 0
	show_when_dead = TRUE

/obj/screen/fullscreen/see_through_darkness
	icon_state = "nightvision"
	plane = LIGHTING_PLANE
	blend_mode = BLEND_ADD
	show_when_dead = TRUE

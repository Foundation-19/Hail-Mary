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

/// The shadow a cloud casts on the ground, a flat black sheet faded to however dark it should be
/obj/screen/fullscreen/cloud_shadow
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	color = "#000000"
	layer = FULLSCREEN_LAYER - 0.1
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// The shadows of clouds that belong to no weather, drifting over the ground with the wind. A tileable texture scrolled one whole tile at a time so it wraps without a seam. The sheet is also slid against the viewer's footsteps, so the shadows stay put on the ground instead of on the screen
/obj/screen/fullscreen/ambient_clouds
	icon = null
	icon_state = null
	screen_loc = "WEST,SOUTH"
	layer = FULLSCREEN_LAYER - 0.2
	alpha = 0
	show_when_dead = TRUE
	/// The drift this layer is animating, so it is only restarted when the wind turns to another quarter
	var/drift_key
	/// Where, in pixels, the sheet is slid to match the ground under the viewer, always within one tile of the texture
	var/offset_x = 0
	var/offset_y = 0
	/// The mob whose footsteps move the sheet
	var/datum/weakref/viewer

/obj/screen/fullscreen/ambient_clouds/Initialize(mapload)
	. = ..()
	var/list/tiles = list()
	for(var/x in -1 to WEATHER_CLOUD_TILES - 2)
		for(var/y in -1 to WEATHER_CLOUD_TILES - 2)
			var/mutable_appearance/tile = mutable_appearance('icons/effects/cloud_shadow.dmi', "cloud_shadow")
			tile.pixel_x = x * WEATHER_CLOUD_TILE_SIZE
			tile.pixel_y = y * WEATHER_CLOUD_TILE_SIZE
			tiles += tile
	add_overlay(tiles)

/obj/screen/fullscreen/ambient_clouds/Destroy()
	var/mob/M = viewer?.resolve()
	if(M)
		UnregisterSignal(M, COMSIG_MOVABLE_MOVED)
	viewer = null
	return ..()

/// Starts following a mob's steps and puts the sheet where the ground under them says it should be
/obj/screen/fullscreen/ambient_clouds/proc/follow(mob/M)
	if(viewer?.resolve() != M)
		var/mob/old = viewer?.resolve()
		if(old)
			UnregisterSignal(old, COMSIG_MOVABLE_MOVED)
		viewer = WEAKREF(M)
		RegisterSignal(M, COMSIG_MOVABLE_MOVED, PROC_REF(on_viewer_moved))
	sync_position(M, TRUE)

/obj/screen/fullscreen/ambient_clouds/proc/on_viewer_moved(datum/source)
	sync_position(source)

/// Slides the sheet by the whole of the viewer's position, wrapped to one tile of the texture. A wrap looks the same as no move, so it is jumped to rather than slid
/obj/screen/fullscreen/ambient_clouds/proc/sync_position(mob/M, force = FALSE)
	var/turf/T = get_turf(M.client?.eye || M)
	if(!T)
		return
	var/new_x = -((T.x * world.icon_size) % WEATHER_CLOUD_TILE_SIZE)
	var/new_y = -((T.y * world.icon_size) % WEATHER_CLOUD_TILE_SIZE)
	if(!force && new_x == offset_x && new_y == offset_y)
		return
	var/jump = force || abs(new_x - offset_x) > WEATHER_CLOUD_TILE_SIZE / 2 || abs(new_y - offset_y) > WEATHER_CLOUD_TILE_SIZE / 2
	offset_x = new_x
	offset_y = new_y
	animate(src, transform = matrix(1, 0, new_x, 0, 1, new_y), time = jump ? 0 : max(1, round(world.icon_size / max(M.glide_size, 1))), flags = ANIMATION_PARALLEL)

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
	color = "#000"
	show_when_dead = TRUE

//Provides whiteness in case you don't see lights so everything is still visible
/obj/screen/fullscreen/lighting_backdrop/unlit
	layer = BACKGROUND_LAYER+20
	show_when_dead = TRUE

/obj/screen/fullscreen/see_through_darkness
	icon_state = "nightvision"
	plane = LIGHTING_PLANE
	blend_mode = BLEND_ADD
	show_when_dead = TRUE

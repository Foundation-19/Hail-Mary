/**
 * Causes weather to occur in a patch of sky over certain area types
 *
 * Weather is a localized cell (see weather_cell.dm) that forms somewhere, grows, drifts with the wind and fades, instead of blanketing
 * every outdoor area at once. Only outdoor areas under the cell are affected, and only people in or near it see, hear or feel it.
 * Weather that really is everywhere (like the floor is lava) sets localized to FALSE and keeps working per area.
 * Can have custom durations, targets, and can automatically protect indoor areas.
 *
 */

/datum/weather
	/// name of weather
	var/name = "space wind"
	/// description of weather
	var/desc = "Heavy gusts of wind blanket the area, periodically knocking down anyone caught in the open."

	/// The message displayed in chat to foreshadow the weather's beginning
	var/telegraph_message = span_warning("The wind begins to pick up.")

	/// In deciseconds, how long from the beginning of the telegraph until the weather begins
	var/telegraph_duration = 300
	/// The sound file played to everyone on an affected z-level
	var/telegraph_sound
	/// The overlay applied to all tiles on the z-level
	var/telegraph_overlay
	/// Displayed in chat once the weather begins in earnest
	var/weather_message = span_userdanger("The wind begins to blow ferociously!")
	///In deciseconds, how long the weather lasts once it begins
	var/weather_duration = 1200
	///See above - this is the lowest possible duration
	var/weather_duration_lower = 1200
	///See above - this is the highest possible duration
	var/weather_duration_upper = 1500
	/// Looping sound while weather is occuring
	var/weather_sound
	/// Area overlay while the weather is occuring
	var/weather_overlay
	/// Color to apply to the area while weather is occuring
	var/weather_color = null

	/// Displayed once the weather is over
	var/end_message = span_danger("The wind relents its assault.")
	/// In deciseconds, how long the "wind-down" graphic will appear before vanishing entirely
	var/end_duration = 300
	/// Sound that plays while weather is ending
	var/end_sound
	/// Area overlay while weather is ending
	var/end_overlay

	/// Types of area(s) to affect
	var/area_types = list(/area/space)
	/// Pulls a list of areas that are set as valid to have this weather, and uses that! see [code\__DEFINES\weather.dm] for details~
	var/tag_weather
	/// TRUE value protects areas with outdoors marked as false, regardless of area type
	var/protect_indoors = TRUE
	/// Areas to be affected by the weather, calculated when the weather begins
	var/list/impacted_areas = list()
	/// Is the weather particularly dangerous?
	var/is_dangerous = TRUE // most are tbh
	/// Does this make the area impossible to see through? Like walking through smoke
	var/obscures_sight = FALSE

	/// Areas that are protected and excluded from the affected areas.
	var/list/protected_areas = list()
	/// The list of z-levels that can reasonably see the weather coming and get messages about it
	var/list/impacted_z_levels = ABOVE_GROUND_Z_LEVELS

	/// Since it's above everything else, this is the layer used by default. TURF_LAYER is below mobs and walls if you need to use that.
	/// Only used for the non-localized /area overlay in update_areas(); the localized screen haze keeps its own FULLSCREEN plane and layer
	var/overlay_layer = AREA_LAYER
	/// If the weather has no purpose but aesthetics. 
	var/aesthetic = FALSE
	/// Used by mobs to prevent them from being affected by the weather 
	var/immunity_type = "storm"

	/// The stage of the weather, from 1-4
	var/stage = END_STAGE

	/// Weight amongst other eligible weather. if zero, will never happen randomly.
	var/probability = 0
	/// The z-level trait to affect when run randomly or when not overridden.
	var/target_trait = ZTRAIT_STATION

	/// Weathers of the same family can't be out together, like a heat wave and a cold wave. Empty means just this type
	var/weather_family = ""
	/// Whether a barometer can predict when the weather will happen
	var/barometer_predictable = FALSE
	/// For barometers to know when the next storm will hit
	var/next_hit_time = 0
	
	var/affects_turfs = FALSE //Does this weather affect turfs at all?
	var/turfs_impacted = FALSE // Did this weather already impact turfs?
	var/carbons_only = FALSE //Does this weather affect only carbon mobs?
	/// Kelvin added to the outdoor ambient temperature while this weather is in its main stage, see code/modules/mob/living/carbon/human/climate.dm
	var/climate_temp_shift = 0
	/// Multiplies how far hostile mobs can spot anyone standing in the affected areas. Below 1 gives rushers cover to close in
	var/visibility_mult = 1
	/// Wetness per second gained by carbons caught outside, see climate.dm
	var/wetness_rate = 0
	/// Puts out campfires and bonfires standing in the affected areas
	var/extinguishes_fires = FALSE
	/// Multiplies this weather's chance of being rolled by the phase of the day it would arrive in: space separated numbers, one per NIGHTCYCLE_PHASE_* in order (sunrise, morning, late morning, daytime, afternoon, late afternoon, sunset, full sunset, night). Empty means no preference. Text because initial() cannot read a list off a type path
	var/phase_weights = ""

	/// Weather forms as a patch of sky instead of covering every area that can have it
	var/localized = TRUE
	/// Radius of the patch at full size, as a fraction of the smaller side of the map
	var/cell_radius_lower = 0.15
	var/cell_radius_upper = 0.25
	/// How lopsided the patch is, 0 is a circle
	var/cell_stretch = 0.35
	/// Tiles per second the patch drifts downwind
	var/drift_speed = 0.1
	/// Tiles beyond the edge where people can still see or hear it gathering
	var/forecast_range = 30
	/// Where the patch of sky is, by z level. Stacked levels share one
	var/list/cells = list()
	var/list/datum/weather_cell/unique_cells = list()
	/// Where an admin or a staff wanted the weather to form
	var/turf/epicenter
	var/last_cell_update = 0
	var/next_turf_sweep = 0
	/// Turfs a drifting patch has already acted on, so nothing is done twice
	var/list/turfs_done = list()
	/// The overlay of every client of the players who were out in the open under the patch on the last update. Each client gets its own so it can fade with how deep in the patch they stand
	var/list/client_screens = list()
	/// Players who were somewhere under the patch, indoors or out, on the last update
	var/list/covered_mobs = list()
	/// Players with the weather's blur applied
	var/list/blurred_mobs = list()
	/// Players with the ground darkened by the weather's cloud shadow
	var/list/shaded_mobs = list()
	/// Players who have already been told about the gust ahead of the patch on this approach
	var/list/gusted_mobs = list()
	/// When the main stage began, for working out how far through its life the weather is
	var/main_started = 0
	var/next_shelter_check = 0

	/// Told to people out in the open as the gust ahead of the patch reaches them. Empty means this weather has no notable gust
	var/gust_message = ""
	/// Chance per second, at full vigor, of lightning striking somewhere under each patch
	var/lightning_rate = 0
	/// How dark the ground gets under the patch, 1 is the usual, 0 casts no shadow
	var/cloud_shadow = 0.4
	/// Deciseconds the ground stays wet after it has been rained on, 0 leaves it dry
	var/wet_ground_time = 0
	/// Moisture per minute the ground takes up at the heart of the weather, see geoclimate. 0 leaves the land as dry as it was
	var/soak_rate = 0
	/// Vegetation per minute the weather kills off at its heart, for blight and acid
	var/vegetation_harm = 0
	/// Rads per minute the ground soaks up at the heart of the weather, see geoclimate. 0 leaves the land clean
	var/ground_contamination_rate = 0
	/// Tame animals out in this weather go looking for cover
	var/animals_seek_shelter = FALSE

/// Every weather in full force over this atom right now
/proc/get_active_weathers(atom/A)
	. = list()
	var/area/place = get_area(A)
	if(!place)
		return
	for(var/datum/weather/W as anything in SSweather.processing)
		if(W.stage == MAIN_STAGE && (place in W.impacted_areas) && W.in_cell(A))
			. += W

/// The weather hitting this atom hardest right now, if any
/proc/get_active_weather(atom/A)
	var/best_intensity = 0
	for(var/datum/weather/W as anything in get_active_weathers(A))
		var/intensity = W.get_intensity(A)
		if(!. || intensity > best_intensity)
			. = W
			best_intensity = intensity

/proc/is_rained_on(atom/A)
	for(var/datum/weather/W as anything in get_active_weathers(A))
		if(W.extinguishes_fires)
			return TRUE
	return FALSE

/// A purely visual layer for people standing under a localized weather
/obj/screen/weather_overlay
	icon = 'icons/effects/weather_effects.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = FULLSCREEN_PLANE
	layer = FULLSCREEN_LAYER - 0.05
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/weather/New(list/z_levels, duration, turf/epicenter)
	..()
	impacted_z_levels = z_levels ? z_levels.Copy() : list()
	src.epicenter = epicenter
	telegraph()

/datum/weather/Destroy(force, ...)
	clear_presence()
	cells = null
	unique_cells = null
	epicenter = null
	. = ..()

/// Whether this atom is under the patch of sky the weather is in, margin pushes the edge out by that many tiles. Everyone is, for weather that is not localized
/datum/weather/proc/in_cell(atom/A, margin = 0)
	if(!localized)
		return TRUE
	var/turf/T = get_turf(A)
	if(!T)
		return FALSE
	var/datum/weather_cell/C = cells["[T.z]"]
	return C ? C.covers(T, margin) : FALSE

/// 0 at the edge of the weather up to 1 deeper in, how hard it is hitting this atom
/datum/weather/proc/get_intensity(atom/A)
	if(!localized)
		return 1
	var/turf/T = get_turf(A)
	if(!T)
		return 0
	var/datum/weather_cell/C = cells["[T.z]"]
	return C ? C.intensity(T) : 0

/// How thick the weather looks from where this atom is, as an alpha, 0 when it is too far off to see
/datum/weather/proc/get_screen_alpha(atom/A)
	var/turf/T = get_turf(A)
	if(!T)
		return 0
	var/datum/weather_cell/C = cells["[T.z]"]
	return C ? C.screen_alpha(T) : 0

/// Where the weather is relative to a turf, for barometers
/datum/weather/proc/describe_position(turf/T)
	var/datum/weather_cell/C = cells["[T.z]"]
	if(!C)
		return null
	var/dx = C.x - T.x
	var/dy = C.y - T.y
	var/distance = max(0, round(sqrt(dx * dx + dy * dy) - (C.radius_x + C.radius_y) * 0.5 * C.scale))
	var/turf/centre = locate(clamp(round(C.x), 1, world.maxx), clamp(round(C.y), 1, world.maxy), T.z)
	var/heading = dir2text(get_dir(T, centre))
	. = "[distance] tiles to the [heading]"
	if(-dx * C.vx - dy * C.vy > 0)
		. += ", drifting your way"

/// Forms a patch of sky for each z level the weather can reach
/datum/weather/proc/form_cells()
	cells = list()
	unique_cells = list()
	if(epicenter && !(epicenter.z in impacted_z_levels))
		impacted_z_levels |= epicenter.z
	var/map_size = min(world.maxx, world.maxy)
	var/heading = SSweather.wind_angle + rand(-30, 30)
	var/list/stacked = list()
	for(var/z in impacted_z_levels)
		if(z > world.maxz)
			continue
		if(z != epicenter?.z && SSmapping.level_trait(z, ZTRAIT_ABOVE))
			stacked += z
			continue
		form_cell(z, map_size, heading)
	// Levels above another look up at the same sky, so they share its patch
	for(var/z in stacked)
		var/datum/space_level/level = SSmapping.get_level(z)
		var/datum/space_level/below = level?.neigbours[TEXT_DOWN]
		var/datum/weather_cell/shared = below ? cells["[below.z_value]"] : null
		if(shared)
			shared.z_levels += z
			cells["[z]"] = shared
		else
			form_cell(z, map_size, heading)

/datum/weather/proc/form_cell(z, map_size, heading)
	var/turf/centre = (epicenter?.z == z) ? epicenter : pick_cell_centre(z)
	if(!centre)
		return
	var/radius = map_size * (cell_radius_lower + rand() * (cell_radius_upper - cell_radius_lower))
	var/stretch = 1 + rand() * cell_stretch
	var/radius_x = prob(50) ? radius * stretch : radius / stretch
	var/radius_y = radius * radius / radius_x
	var/datum/weather_cell/C = new(list(z), centre.x, centre.y, radius_x, radius_y, sin(heading) * drift_speed, cos(heading) * drift_speed)
	cells["[z]"] = C
	unique_cells += C

/// A random spot on this z level that is under open sky and can have this weather
/datum/weather/proc/pick_cell_centre(z)
	for(var/i in 1 to 40)
		var/turf/T = locate(rand(1, world.maxx), rand(1, world.maxy), z)
		if(T && (T.loc in impacted_areas))
			return T

/// Grows, drifts and shrinks the patch of sky. It is steered by the wind, which swings over time, and strengthens towards the middle of the weather's life
/datum/weather/proc/update_cells()
	var/elapsed = (world.time - last_cell_update) * 0.1
	last_cell_update = world.time
	var/target_scale = 1
	var/target_vigor = 1
	switch(stage)
		if(STARTUP_STAGE)
			target_scale = WEATHER_CELL_FORMING_SCALE
			target_vigor = 0.5
		if(MAIN_STAGE)
			var/progress = clamp((world.time - main_started) / max(1, weather_duration), 0, 1)
			target_vigor = 0.75 + 0.25 * sin(180 * progress)
		if(WIND_DOWN_STAGE)
			target_scale = WEATHER_CELL_FADING_SCALE
			target_vigor = 0.3
	var/steer = min(1, WEATHER_CELL_STEER * elapsed)
	var/wind_vx = sin(SSweather.wind_angle) * drift_speed
	var/wind_vy = cos(SSweather.wind_angle) * drift_speed
	for(var/datum/weather_cell/C as anything in unique_cells)
		C.drift(elapsed)
		C.scale += (target_scale - C.scale) * min(1, WEATHER_CELL_GROW_RATE * elapsed)
		C.vigor += (target_vigor - C.vigor) * min(1, WEATHER_CELL_GROW_RATE * elapsed)
		C.vx += (wind_vx - C.vx) * steer
		C.vy += (wind_vy - C.vy) * steer
		C.aim()

/**
 * Telegraphs the beginning of the weather on the impacted z levels
 *
 * Sends sounds and details to mobs in the area
 * Calculates duration and hit areas, and makes a callback for the actual weather to start
 *
 */
/datum/weather/proc/telegraph()
	if(stage == STARTUP_STAGE || !tag_weather)
		abort()
		return
	if(tag_weather == WEATHER_ALL_AREAS) // pretty much just for the floor is lava, which works in theory
		var/list/affectareas = list()
		for(var/V in get_areas(/area))
			var/area/A = V
			affectareas |= A
			if(A.sub_areas)
				affectareas |= A.sub_areas
		for(var/V in protected_areas)
			affectareas -= get_areas(V)
		for(var/V in affectareas)
			var/area/A = V
			if(protect_indoors && !A.outdoors)
				continue
			if(A.z in impacted_z_levels)
				impacted_areas |= A
	else if(LAZYLEN(GLOB.area_weather_list[tag_weather]))
		impacted_areas |= GLOB.area_weather_list[tag_weather]
	if(!LAZYLEN(impacted_areas))
		abort()
		return
	if(localized)
		form_cells()
		if(!length(unique_cells))
			abort()
			return
		last_cell_update = world.time
	stage = STARTUP_STAGE
	weather_duration = rand(weather_duration_lower, weather_duration_upper)
	next_hit_time = world.time + telegraph_duration
	START_PROCESSING(SSweather, src) //The reason this doesn't start and stop at main stage is because processing list is also used to see active running weathers (for example, you wouldn't want two ash storms starting at once.)
	update_areas()
	update_presence()
	alert_players(telegraph_message, telegraph_sound, forecast_range)
	addtimer(CALLBACK(src, PROC_REF(start)), telegraph_duration)

/// The weather has nowhere to happen. It never ran, so whoever made it has to throw it away
/datum/weather/proc/abort()
	stage = END_STAGE

/**
 * Starts the actual weather and effects from it
 *
 * Updates area overlays and sends sounds and messages to mobs to notify them
 * Begins dealing effects from weather to mobs in the area
 *
 */
/datum/weather/proc/start()
	if(stage >= MAIN_STAGE)
		return
	stage = MAIN_STAGE
	main_started = world.time
	update_areas()
	alert_players(weather_message, weather_sound)
	addtimer(CALLBACK(src, PROC_REF(wind_down)), weather_duration)

/**
 * Weather enters the winding down phase, stops effects
 *
 * Updates areas to be in the winding down phase
 * Sends sounds and messages to mobs to notify them
 *
 */
/datum/weather/proc/wind_down()
	if(stage >= WIND_DOWN_STAGE)
		return
	stage = WIND_DOWN_STAGE
	update_areas()
	alert_players(end_message, end_sound)
	addtimer(CALLBACK(src, PROC_REF(end)), end_duration)

/// Tells the players under the weather, or within margin tiles of it, with a message and a sound
/datum/weather/proc/alert_players(message, sound_play, margin = 0)
	if(!message && !sound_play)
		return FALSE
	for(var/M in GLOB.player_list)
		var/turf/mob_turf = get_turf(M)
		if(mob_turf && (mob_turf.z in impacted_z_levels) && in_cell(mob_turf, margin))
			if(message)
				to_chat(M, message)
			if(sound_play)
				SEND_SOUND(M, sound(sound_play))

/**
 * Fully ends the weather
 *
 * Effects no longer occur and area overlays are removed
 * Removes weather from processing completely
 *
 */
/datum/weather/proc/end(forced)
	if(stage == END_STAGE)
		return 1
	stage = END_STAGE
	STOP_PROCESSING(SSweather, src)
	update_areas()
	clear_presence()
	if(forced)
		alert_players(end_message, end_sound)
	qdel(src)

/datum/weather/process()
	if(stage == END_STAGE)
		return
	if(localized)
		update_cells()
	update_presence()
	if(stage == MAIN_STAGE && localized)
		if(lightning_rate)
			lightning_tick()
		if(animals_seek_shelter && world.time >= next_shelter_check)
			next_shelter_check = world.time + WEATHER_SHELTER_INTERVAL
			animals_find_shelter()
	if(aesthetic || (stage != MAIN_STAGE))
		return
	if(affects_turfs)
		sweep_turfs()
	for(var/i in (carbons_only ? GLOB.carbon_list : GLOB.mob_living_list))
		var/mob/living/L = i
		if(can_weather_act(L))
			weather_act(L)

/// Acts on every turf the weather has reached, once each. A drifting patch keeps reaching new ground, so this runs every few seconds
/datum/weather/proc/sweep_turfs()
	if(!localized)
		if(turfs_impacted)
			return
		turfs_impacted = TRUE
		for(var/i in impacted_areas)
			var/area/A = i
			for(var/turf/T in get_area_turfs(A))
				weather_act_turf(T)
		return
	if(world.time < next_turf_sweep)
		return
	next_turf_sweep = world.time + WEATHER_TURF_SWEEP_INTERVAL
	for(var/datum/weather_cell/C as anything in unique_cells)
		var/reach_x = round(C.radius_x * C.scale * (1 + WEATHER_CELL_LUMP)) + 1
		var/reach_y = round(C.radius_y * C.scale * (1 + WEATHER_CELL_LUMP)) + 1
		var/min_x = clamp(round(C.x) - reach_x, 1, world.maxx)
		var/max_x = clamp(round(C.x) + reach_x, 1, world.maxx)
		var/min_y = clamp(round(C.y) - reach_y, 1, world.maxy)
		var/max_y = clamp(round(C.y) + reach_y, 1, world.maxy)
		for(var/z in C.z_levels)
			for(var/turf/T as anything in block(locate(min_x, min_y, z), locate(max_x, max_y, z)))
				if(turfs_done[T] || !(T.loc in impacted_areas) || !C.covers(T))
					continue
				turfs_done[T] = TRUE
				weather_act_turf(T)
				CHECK_TICK

/**
 * Works out who is out in the weather and keeps what they see, hear and are told in step with it
 *
 * Players out in the open under the patch get the weather's overlay and sound, the ones indoors under it hear it muffled
 */
/datum/weather/proc/update_presence()
	var/list/outside = list()
	var/list/inside = list()
	var/list/covered = list()
	var/list/watching = list()
	if(stage != END_STAGE)
		for(var/mob/M as anything in GLOB.player_list)
			var/turf/T = get_turf(M)
			if(!T)
				continue
			if(!in_cell(T))
				// Someone out in the open near the patch can see it from where they stand
				if(localized && (T.loc in impacted_areas) && in_cell(T, WEATHER_CELL_HALO))
					watching += M
				continue
			covered += M
			if(T.loc in impacted_areas)
				outside += M
			else
				inside += M
	if(localized)
		update_screens(outside, covered, watching)
		update_gusts(watching)
	update_listeners(outside, inside)

/// Tells people out in the open when the gust ahead of the patch reaches them, once for each time it comes at them
/datum/weather/proc/update_gusts(list/watching)
	var/list/gusting = list()
	if(length(gust_message) && (stage == STARTUP_STAGE || stage == MAIN_STAGE))
		for(var/mob/M as anything in watching)
			if(get_gust(M) <= 0)
				continue
			gusting += M
			if(!(M in gusted_mobs))
				to_chat(M, gust_message)
	gusted_mobs = gusting

/// 0 to 1, how hard the gust ahead of the patch is blowing at this atom
/datum/weather/proc/get_gust(atom/A)
	if(!localized)
		return 0
	var/turf/T = get_turf(A)
	if(!T)
		return 0
	var/datum/weather_cell/C = cells["[T.z]"]
	return C ? C.gust(T) : 0

/// Kelvin the gust ahead of the patch adds to the air at this atom: the patch's own shift carried ahead of it, weaker, to someone out in the open
/datum/weather/proc/get_gust_shift(atom/A)
	if(!climate_temp_shift || !localized || (stage != STARTUP_STAGE && stage != MAIN_STAGE))
		return 0
	if(!(get_area(A) in impacted_areas))
		return 0
	return climate_temp_shift * WEATHER_GUST_STRENGTH * get_gust(A)

/// How much sun there is for a cloud to block, 0 at night and 1 in full day
/datum/weather/proc/get_daylight()
	switch(SSnightcycle.current_time)
		if(NIGHTCYCLE_PHASE_SUNRISE, NIGHTCYCLE_PHASE_SUNSET)
			return 0.5
		if(NIGHTCYCLE_PHASE_MORNING, NIGHTCYCLE_PHASE_LATEAFTERNOON)
			return 0.85
		if(NIGHTCYCLE_PHASE_FULLSUNSET)
			return 0.25
		if(NIGHTCYCLE_PHASE_NIGHTTIME)
			return 0
	return 1

/// Shows the weather's overlay to everyone out in it and, fainter, to those out in the open near it. Blurs the sight of those caught in weather that obscures it, and tells people as the patch passes them
/datum/weather/proc/update_screens(list/outside, list/covered, list/watching = list())
	var/new_state
	switch(stage)
		if(STARTUP_STAGE)
			new_state = telegraph_overlay
		if(MAIN_STAGE)
			new_state = weather_overlay
		if(WIND_DOWN_STAGE)
			new_state = end_overlay
	// Screens belong to the client, which can move to another body, so they are tracked by client
	var/list/new_screens = list()
	var/list/blurred = list()
	var/list/shaded = list()
	var/shade_scale = cloud_shadow * get_daylight()
	for(var/mob/M as anything in outside + watching)
		var/client/C = M.client
		if(!C)
			continue
		// The weather is a gradient: a haze out beyond the patch, thickening towards its heart
		var/fade = get_screen_alpha(M)
		if(fade <= 0)
			continue
		var/obj/screen/weather_overlay/S = client_screens[C]
		if(S)
			client_screens -= C
		else
			S = new
			S.color = weather_color
			S.alpha = 0
			C.screen += S
		new_screens[C] = S
		S.icon_state = new_state
		animate(S, alpha = fade, time = 1 SECONDS)
		// The patch also shades the ground, and it is darker the thicker it is overhead
		var/shade_alpha = round(WEATHER_SHADE_MAX_ALPHA * shade_scale * fade / WEATHER_SCREEN_MAX_ALPHA)
		if(shade_alpha > 0)
			var/obj/screen/fullscreen/shade = M.overlay_fullscreen("cloud_shadow_[type]", /obj/screen/fullscreen/cloud_shadow)
			if(shade)
				if(!(M in shaded_mobs))
					shade.alpha = 0
				animate(shade, alpha = shade_alpha, time = 1 SECONDS)
				shaded += M
		if(obscures_sight && stage == MAIN_STAGE && (M in outside))
			var/obj/screen/fullscreen/blur = M.overlay_fullscreen("weather_[type]", /obj/screen/fullscreen/blurry)
			if(blur)
				if(!(M in blurred_mobs))
					blur.alpha = 0
				animate(blur, alpha = fade, time = 1 SECONDS)
			blurred += M
	for(var/client/C as anything in client_screens)
		var/obj/screen/weather_overlay/S = client_screens[C]
		if(C)
			C.screen -= S
		qdel(S)
	for(var/mob/M as anything in blurred_mobs - blurred)
		M?.clear_fullscreen("weather_[type]")
	for(var/mob/M as anything in shaded_mobs - shaded)
		M?.clear_fullscreen("cloud_shadow_[type]")
	if(stage == MAIN_STAGE || stage == WIND_DOWN_STAGE)
		for(var/mob/M as anything in covered - covered_mobs)
			to_chat(M, span_notice("The [name] sweeps over you."))
		for(var/mob/M as anything in covered_mobs - covered)
			to_chat(M, span_notice("The [name] has moved past you."))
	client_screens = new_screens
	covered_mobs = covered
	blurred_mobs = blurred
	shaded_mobs = shaded

/// Lightning strikes somewhere under a patch now and then. Storms are livelier at their peak
/datum/weather/proc/lightning_tick()
	for(var/datum/weather_cell/C as anything in unique_cells)
		if(!prob(lightning_rate * C.vigor * 100))
			continue
		var/turf/strike = C.random_point()
		if(strike)
			lightning_strike(strike)

/// A flash for everyone out in the open who can see it and, after the time sound takes to travel, thunder for everyone in earshot, muffled indoors
/datum/weather/proc/lightning_strike(turf/strike)
	for(var/mob/M as anything in GLOB.player_list)
		var/turf/T = get_turf(M)
		if(!T || T.z != strike.z)
			continue
		var/dist = sqrt((T.x - strike.x) ** 2 + (T.y - strike.y) ** 2)
		if(dist > WEATHER_LIGHTNING_RANGE)
			continue
		var/area/place = T.loc
		var/outdoors = place.outdoors
		if(outdoors && dist <= WEATHER_LIGHTNING_FLASH_RANGE)
			var/obj/screen/fullscreen/flash = M.overlay_fullscreen("lightning", /obj/screen/fullscreen/flash)
			if(flash)
				flash.alpha = round(clamp(170 - dist * 3, 30, 170))
				M.clear_fullscreen("lightning", 6)
		var/volume = clamp(100 - dist * 1.1, 20, 100) * (outdoors ? 1 : 0.5)
		addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, playsound_local), strike, 'sound/weather/thunder.ogg', volume, TRUE), round(dist * WEATHER_THUNDER_DELAY))

/// Tame animals caught out in this weather head for the nearest ground it does not reach
/datum/weather/proc/animals_find_shelter()
	for(var/mob/living/simple_animal/A as anything in GLOB.simple_animals[AI_ON])
		if(ishostile(A) || A.client || A.mind || A.stat != CONSCIOUS || A.buckled || A.resting || length(A.buckled_mobs))
			continue
		if(!can_weather_act(A))
			continue
		var/turf/shelter
		var/best = WEATHER_SHELTER_RANGE + 1
		for(var/turf/open/T in view(WEATHER_SHELTER_RANGE, A))
			if(T.loc in impacted_areas)
				continue
			var/dist = get_dist(A, T)
			if(dist < best && !is_blocked_turf(T, TRUE))
				best = dist
				shelter = T
		if(shelter)
			walk_to(A, shelter, 0, max(2, round(A.movement_delay())))
		CHECK_TICK

/datum/weather/proc/update_listeners(list/outside, list/inside)
	return

/// Takes the weather's overlay and blur off everyone who has them
/datum/weather/proc/clear_presence()
	for(var/client/C as anything in client_screens)
		var/obj/screen/weather_overlay/S = client_screens[C]
		if(C)
			C.screen -= S
		qdel(S)
	for(var/mob/M as anything in blurred_mobs)
		M?.clear_fullscreen("weather_[type]")
	for(var/mob/M as anything in shaded_mobs)
		M?.clear_fullscreen("cloud_shadow_[type]")
	client_screens = list()
	covered_mobs = list()
	blurred_mobs = list()
	shaded_mobs = list()
	gusted_mobs = list()

/**
 * Returns TRUE if the living mob can be affected by the weather
 *
 */
/datum/weather/proc/can_weather_act(mob/living/L)
/* 	var/turf/mob_turf = get_turf(L)
	if(mob_turf && !(mob_turf.z in impacted_z_levels))
		return */
	if(immunity_type in L.weather_immunities)
		return
	if(!(get_area(L) in impacted_areas))
		return
	if(!in_cell(L))
		return
	return TRUE

/**
 * Affects the mob with whatever the weather does
 *
 */
/datum/weather/proc/weather_act(mob/living/L)
	return

/**
 * Affects a turf, ONCE, with whatever the weather does
 *
 */
/datum/weather/proc/weather_act_turf(turf/T)
	return


/**
 * Updates the overlays on impacted areas
 *
 */
/datum/weather/proc/update_areas()
	if(localized) // a patch of sky is drawn on the players' screens, painting the whole area would put it everywhere
		return
	for(var/V in impacted_areas)
		var/area/N = V
		N.layer = overlay_layer
		N.icon = 'icons/effects/weather_effects.dmi'
		N.color = weather_color
		switch(stage)
			if(STARTUP_STAGE)
				N.icon_state = telegraph_overlay
			if(MAIN_STAGE)
				N.icon_state = weather_overlay
				if(obscures_sight)
					N.set_opacity(TRUE)
			if(WIND_DOWN_STAGE)
				N.icon_state = end_overlay
				if(obscures_sight)
					N.set_opacity(FALSE)
			if(END_STAGE)
				N.color = null
				N.icon_state = ""
				N.icon = 'icons/turf/areas.dmi'
				N.layer = AREA_LAYER //Just default back to normal area stuff since I assume setting a var is faster than initial
				if(obscures_sight) // just in case
					N.set_opacity(FALSE)


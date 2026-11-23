//Used for all kinds of weather, ex. lavaland ash storms.
PROCESSING_SUBSYSTEM_DEF(weather)
	name = "Weather"
	flags = SS_BACKGROUND
	wait = 10
	runlevels = RUNLEVEL_GAME
	var/list/eligible_zlevels = ABOVE_GROUND_Z_LEVELS // 4 through 8, its 4 through 8, fuck you its 4 through 8
	var/list/weather_rolls = list()
	/// Clouds on their way, soonest first: the system the barometers read
	var/list/datum/weather_forecast/forecast = list()
	/// direction the wind is blowing in
	var/wind_direction = NORTH
	/// Bearing the wind is blowing towards in degrees, 0 north and clockwise. It swings a little at a time so clouds are steered round rather than flipped
	var/wind_angle = 0
	/// wind direction stuff cooldown
	COOLDOWN_DECLARE(wind_change_cooldown)
	/// Ground that rain has soaked, turf = when it dries out. See wet_turf()
	var/list/wet_turfs = list()
	COOLDOWN_DECLARE(wet_check_cooldown)
	/// Family to the families it cannot be out alongside, worked out from every weather's conflicting_families the first time it is needed
	var/list/family_conflicts
	/// How much of the sky is covered in cloud, 0 clear to 1 overcast, across the whole map. It drifts slowly, fills in before rain and clears after
	var/cloud_cover = 0.25
	/// How far the cloud cover has been pulled from the level the ground's moisture sets, a slow random walk
	var/cloud_wander = 0
	/// How much cloud cover changed last time it was nudged, positive while the sky is filling in. This is what a barometer calls pressure falling
	var/cloud_trend = 0
	COOLDOWN_DECLARE(cloud_cooldown)
	/// Milliseconds of server time the parts of weather cost per second, for stat_entry
	var/cost_visuals = 0
	var/cost_sweep = 0
	var/cost_presence = 0
	var/cost_shelter = 0
	var/cost_clouds = 0
/// A cloud that has been forecast and is yet to form
/datum/weather_forecast
	var/datum/weather/weather_type
	/// When the weather forms
	var/launch_time = 0
	/// When people start to feel it, the telegraph is over
	var/hit_time = 0
	var/timerid

/datum/weather_forecast/Destroy()
	if(timerid)
		deltimer(timerid)
		timerid = null
	return ..()

/// Weathers of the same family can't be out together, like a heat wave and a cold wave. Defaults to the weather's own type
/proc/get_weather_family(datum/weather/weather_type)
	return initial(weather_type.weather_family) || "[weather_type]"

/datum/controller/subsystem/processing/weather/fire()
	. = ..() //Active weather is handled by . = ..() processing subsystem base fire().
	if(COOLDOWN_FINISHED(src, cloud_cooldown))
		update_cloud_cover()
		COOLDOWN_START(src, cloud_cooldown, WEATHER_CLOUD_INTERVAL)
	if(length(GLOB.player_list))
		var/started = TICK_USAGE
		update_cloud_layers()
		cost_clouds = MC_AVERAGE(cost_clouds, TICK_DELTA_TO_MS(TICK_USAGE - started))
	if(COOLDOWN_FINISHED(src, wind_change_cooldown))
		set_wind_direction()
		COOLDOWN_START(src, wind_change_cooldown, rand(WEATHER_WIND_SHIFT_MIN, WEATHER_WIND_SHIFT_MAX))
	if(length(wet_turfs) && COOLDOWN_FINISHED(src, wet_check_cooldown))
		dry_turfs()
		COOLDOWN_START(src, wet_check_cooldown, WEATHER_WET_CHECK_INTERVAL)
	if(length(forecast) || !LAZYLEN(weather_rolls))
		return FALSE
	roll_forecast()

/// Forecasts the next system: one cloud or several, arriving around the same time
/datum/controller/subsystem/processing/weather/proc/roll_forecast()
	var/clouds = text2num(pickweight(WEATHER_FRONT_SIZES))
	var/base_wait = rand(WEATHER_WAIT_MIN, WEATHER_WAIT_MAX)
	var/list/taken = get_busy_families()
	for(var/i in 1 to clouds)
		var/wait = base_wait + (i > 1 ? rand(0, WEATHER_FRONT_SPREAD) : 0)
		var/list/weights = get_weather_weights(wait, taken)
		if(!length(weights))
			break
		var/datum/weather/W = pickweight(weights)
		taken += get_weather_family(W)
		var/datum/weather_forecast/F = new
		F.weather_type = W
		F.launch_time = world.time + wait + initial(W.weather_duration_upper)
		F.hit_time = F.launch_time + initial(W.telegraph_duration)
		F.timerid = addtimer(CALLBACK(src, PROC_REF(launch_forecast), F), F.launch_time - world.time, TIMER_STOPPABLE)
		forecast += F
	sortTim(forecast, GLOBAL_PROC_REF(cmp_forecast_launch))

/proc/cmp_forecast_launch(datum/weather_forecast/a, datum/weather_forecast/b)
	return a.launch_time - b.launch_time

/// A forecast cloud forms, unless the sky is already as crowded as it can be
/datum/controller/subsystem/processing/weather/proc/launch_forecast(datum/weather_forecast/F)
	forecast -= F
	F.timerid = null
	var/datum/weather/weather_type = F.weather_type
	qdel(F)
	if(length(get_concurrent_weathers()) >= WEATHER_MAX_CONCURRENT || (get_weather_family(weather_type) in expand_families(get_busy_families(TRUE))))
		return
	run_weather(weather_type, null, null, FALSE)

/// Weathers out that count towards the cap on how many can be out at once
/datum/controller/subsystem/processing/weather/proc/get_concurrent_weathers()
	. = list()
	for(var/datum/weather/W as anything in get_active_weathers())
		if(W.counts_toward_concurrency)
			. += W

/// Families that cannot be out alongside this one, as declared by either side
/datum/controller/subsystem/processing/weather/proc/get_conflicts(family)
	if(!family_conflicts)
		family_conflicts = list()
		for(var/datum/weather/W as anything in subtypesof(/datum/weather))
			var/own = get_weather_family(W)
			for(var/other in splittext(initial(W.conflicting_families), " "))
				if(!length(other))
					continue
				if(!family_conflicts[own])
					family_conflicts[own] = list()
				if(!family_conflicts[other])
					family_conflicts[other] = list()
				family_conflicts[own] |= other
				family_conflicts[other] |= own
	return family_conflicts[family] || list()

/// These families and every family that conflicts with one of them
/datum/controller/subsystem/processing/weather/proc/expand_families(list/families)
	. = families.Copy()
	for(var/family in families)
		. |= get_conflicts(family)

/// The families of every cloud out or on its way
/datum/controller/subsystem/processing/weather/proc/get_busy_families(active_only = FALSE)
	. = list()
	for(var/datum/weather/W as anything in get_active_weathers())
		. |= get_weather_family(W.type)
	if(active_only)
		return
	for(var/datum/weather_forecast/F as anything in forecast)
		. |= get_weather_family(F.weather_type)

/// Every weather that has formed and not yet ended
/datum/controller/subsystem/processing/weather/proc/get_active_weathers()
	. = list()
	for(var/datum/weather/W as anything in processing)
		if(W.stage != END_STAGE)
			. += W

/// weather_rolls with each chance scaled by how well the weather suits the time of day it would hit at (the roll is made wait before the weather is queued to start), leaving out any family in blocked
/datum/controller/subsystem/processing/weather/proc/get_weather_weights(wait, list/blocked)
	var/list/weights = list()
	var/list/open = list()
	if(blocked)
		blocked = expand_families(blocked)
	var/dryness
	for(var/datum/weather/W as anything in weather_rolls)
		if(blocked && (get_weather_family(W) in blocked))
			continue
		open[W] = weather_rolls[W]
		var/weight_text = initial(W.phase_weights)
		var/mult = 1
		if(length(weight_text))
			var/list/phase_weights = splittext(weight_text, " ")
			var/phase = SSnightcycle.predict_phase(wait + initial(W.weather_duration_upper))
			mult = text2num(phase_weights[phase + 1])
		var/dry_pull = initial(W.dryness_weight)
		var/wet_pull = initial(W.wetness_weight)
		if(dry_pull || wet_pull)
			if(isnull(dryness))
				dryness = SSgeoclimate.get_dryness()
			mult *= (1 - dry_pull) + dry_pull * dryness
			mult *= (1 - wet_pull) + wet_pull * (1 - dryness)
		var/cloud_pull = initial(W.cloud_weight)
		if(cloud_pull)
			mult *= (1 - cloud_pull) + cloud_pull * (0.5 + cloud_cover)
		if(mult > 0)
			weights[W] = weather_rolls[W] * mult
	return LAZYLEN(weights) ? weights : open

/datum/controller/subsystem/processing/weather/Initialize(start_timeofday)
	set_wind_direction(rand(0, 359))
	cloud_cover = rand(10, 40) / 100
	SSnightcycle.apply_cloud_cover()
	for(var/V in subtypesof(/datum/weather))
		var/datum/weather/W = V
		var/probability = initial(W.probability)
		// any weather with a probability set may occur at random
		if (probability)
			weather_rolls[W] = probability
	return ..()

/// How much sun there is for a cloud to block, 0 at night and 1 in full day
/datum/controller/subsystem/processing/weather/proc/get_daylight()
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

/// Nudges the sky's cloud cover towards what the ground's moisture, the weather out and the weather on its way ask of it
/datum/controller/subsystem/processing/weather/proc/update_cloud_cover()
	cloud_wander = clamp(cloud_wander + (rand(-100, 100) / 100) * WEATHER_CLOUD_WANDER_STEP, WEATHER_CLOUD_WANDER_MIN, WEATHER_CLOUD_WANDER_MAX)
	var/goal = clamp(0.15 + 0.4 * (1 - SSgeoclimate.get_dryness()) + cloud_wander, 0, 1)
	for(var/datum/weather/W as anything in get_active_weathers())
		if(isnull(W.cloud_cover_goal))
			continue
		goal += (W.cloud_cover_goal - goal) * (W.stage == WIND_DOWN_STAGE ? 0.5 : 1)
	// A forecast cloud fills the sky in over the build-up to it, rather than popping into being
	for(var/datum/weather_forecast/F as anything in forecast)
		var/datum/weather/weather_type = F.weather_type
		var/forecast_goal = initial(weather_type.cloud_cover_goal)
		if(isnull(forecast_goal))
			continue
		goal += (forecast_goal - goal) * clamp(1 - (F.hit_time - world.time) / WEATHER_CLOUD_BUILDUP, 0, 1)
	var/old_cover = cloud_cover
	cloud_cover = clamp(cloud_cover + (goal - cloud_cover) * WEATHER_CLOUD_RATE, 0, 1)
	cloud_trend = (cloud_trend + (cloud_cover - old_cover)) * 0.5
	SSnightcycle.apply_cloud_cover()

/// Which way the cloud shadows scroll as how many whole tiles of the texture across and up, one of the eight directions nearest the wind. Whole tiles are what let the texture wrap without a seam
/datum/controller/subsystem/processing/weather/proc/get_cloud_drift()
	var/east = sin(wind_angle)
	var/north = cos(wind_angle)
	return list(abs(east) >= 0.38 ? (east > 0 ? 1 : -1) : 0, abs(north) >= 0.38 ? (north > 0 ? 1 : -1) : 0)

/// How much of the sky someone can see to cast cloud shadows on the ground they stand on, 0 indoors, under a storm or in a bank of fog
/datum/controller/subsystem/processing/weather/proc/get_sky_openness(mob/M)
	var/turf/T = get_turf(M)
	if(!T || !(T.z in eligible_zlevels))
		return 0
	var/area/A = T.loc
	if(!A.outdoors)
		return 0
	. = 1
	for(var/datum/weather/W as anything in processing)
		if(W.cloud_shadow <= 0 || (W.stage != MAIN_STAGE && W.stage != WIND_DOWN_STAGE))
			continue
		// Weather's own shadow and its murk replace the ambient clouds' as it closes in
		. *= 1 - clamp(W.get_screen_alpha(T) * W.get_density_mult() / WEATHER_SCREEN_MAX_ALPHA, 0, 1)

/// Keeps every player's drifting cloud shadow layer in step with the cloud cover, the wind and the time of day
/datum/controller/subsystem/processing/weather/proc/update_cloud_layers()
	var/max_alpha = cloud_cover * get_daylight() * WEATHER_CLOUD_LAYER_MAX_ALPHA
	var/list/drift = get_cloud_drift()
	var/drift_key = "[drift[1]],[drift[2]]"
	for(var/mob/M as anything in GLOB.player_list)
		var/client/C = M.client
		if(!C)
			continue
		var/target = 0
		if(max_alpha >= WEATHER_CLOUD_LAYER_MIN_ALPHA && !(C.prefs?.toggles & DISABLE_CLOUD_SHADOWS))
			target = round(max_alpha * get_sky_openness(M))
		if(target < WEATHER_CLOUD_LAYER_MIN_ALPHA)
			if(M.screens["ambient_clouds"])
				M.clear_fullscreen("ambient_clouds", 2 SECONDS)
			continue
		var/obj/screen/fullscreen/ambient_clouds/layer = M.overlay_fullscreen("ambient_clouds", /obj/screen/fullscreen/ambient_clouds)
		if(!layer)
			continue
		if(layer.drift_key != drift_key)
			layer.drift_key = drift_key
			layer.pixel_x = 0
			layer.pixel_y = 0
			layer.alpha = target
			// Moving a whole tile of the texture looks the same as not having moved, so the loop can jump back with no one the wiser
			animate(layer, pixel_x = drift[1] * WEATHER_CLOUD_TILE_SIZE, pixel_y = drift[2] * WEATHER_CLOUD_TILE_SIZE, time = WEATHER_CLOUD_DRIFT_SECONDS * 10 * sqrt(drift[1] ** 2 + drift[2] ** 2), loop = -1)
		else if(abs(layer.alpha - target) >= 2)
			animate(layer, alpha = target, time = 2 SECONDS, flags = ANIMATION_PARALLEL)
		layer.follow(M)

/datum/controller/subsystem/processing/weather/stat_entry(msg)
	. = ..()
	return "[.]|W:[length(get_active_weathers())]|C:[round(cloud_cover * 100)]%|V:[round(cost_visuals, 0.1)]|S:[round(cost_sweep, 0.1)]|U:[round(cost_presence, 0.1)]|A:[round(cost_shelter, 0.1)]|L:[round(cost_clouds, 0.1)]"

/// Forms a weather. Unless it is a forecast cloud forming (replace is FALSE), it takes the place of any weather of the same family that is already out
/datum/controller/subsystem/processing/weather/proc/run_weather(datum/weather/weather_datum_type, duration, turf/epicenter, replace = TRUE)
	if (istext(weather_datum_type))
		for (var/V in subtypesof(/datum/weather))
			var/datum/weather/W = V
			if (initial(W.name) == weather_datum_type)
				weather_datum_type = V
				break
	if (!ispath(weather_datum_type, /datum/weather))
		CRASH("run_weather called with invalid weather_datum_type: [weather_datum_type || "null"]")
	if(replace)
		end_family(get_weather_family(weather_datum_type))
	var/datum/weather/new_weather = new weather_datum_type(eligible_zlevels, duration, epicenter)
	if(new_weather.stage == END_STAGE) // nowhere for it to happen, it never started
		qdel(new_weather)

/// Ends every weather out that belongs to this family
/datum/controller/subsystem/processing/weather/proc/end_family(family)
	for(var/datum/weather/W as anything in get_active_weathers())
		if(get_weather_family(W.type) == family)
			W.end(TRUE)

/// Weathers over this atom's spot of sky, at any stage. Ladders use it to warn about what is on the other side
/datum/controller/subsystem/processing/weather/proc/get_weather(atom/place)
	var/area/active_area = get_area(place)
	if(!isarea(active_area) || isarea(place)) // an area has no spot to check against the patch of sky, so it never has weather
		return
	if(!LAZYLEN(active_area.weather_tags)) // area cant have weather (or it wasnt set up right), so it doesnt have weather
		return
	for(var/datum/weather/W as anything in get_active_weathers())
		if((W.tag_weather in active_area.weather_tags) && W.in_cell(place))
			. = W
			if(W.is_dangerous) // the worst of them is what matters
				return

/// The wind swings a little each time rather than jumping to another quarter. The first shift picks any way to blow
/datum/controller/subsystem/processing/weather/proc/set_wind_direction(swing = rand(-WEATHER_WIND_SWING, WEATHER_WIND_SWING))
	wind_angle = SIMPLIFY_DEGREES(wind_angle + swing)
	wind_direction = angle2dir_cardinal(wind_angle)

/// Soaks a turf for a while, tinting it so the ground looks wet until it dries out
/datum/controller/subsystem/processing/weather/proc/wet_turf(turf/T, duration)
	if(!isturf(T) || duration <= 0)
		return
	if(!wet_turfs[T] && !T.color)
		T.add_atom_colour(WEATHER_WET_COLOUR, TEMPORARY_COLOUR_PRIORITY)
	wet_turfs[T] = world.time + duration * (0.8 + rand() * 0.4)

/// Whether the ground here is still wet from rain
/datum/controller/subsystem/processing/weather/proc/is_wet_ground(atom/A)
	var/turf/T = get_turf(A)
	return T && wet_turfs[T] > world.time

/// Dries out every turf whose time is up
/datum/controller/subsystem/processing/weather/proc/dry_turfs()
	for(var/turf/T as anything in wet_turfs.Copy())
		if(wet_turfs[T] > world.time && !QDELETED(T))
			continue
		wet_turfs -= T
		if(!QDELETED(T))
			T.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, WEATHER_WET_COLOUR)
		CHECK_TICK



#define STARTUP_STAGE 1
#define MAIN_STAGE 2
#define WIND_DOWN_STAGE 3
#define END_STAGE 4
#define FALLOUT_WEATHER_WAIT_MIN 10 MINUTES
#define FALLOUT_WEATHER_WAIT_MAX 18 MINUTES
#define FALLOUT_DANGEROUS_WEATHER_GAP 20 MINUTES

//Used for all kinds of weather, ex. lavaland ash storms.
PROCESSING_SUBSYSTEM_DEF(weather)
	name = "Weather"
	flags = SS_BACKGROUND
	wait = 10
	runlevels = RUNLEVEL_GAME
	var/list/eligible_zlevels = ABOVE_GROUND_Z_LEVELS // 4 through 8, its 4 through 8, fuck you its 4 through 8
	var/list/weather_rolls = list()
	var/next_hit_by_zlevel //Used by barometers to know when the next storm is coming
	/// Was a random weather queued?
	var/weather_queued = FALSE
	var/timerid
	/// What weather is currently running?
	var/datum/weather/current_weather
	/// direction the wind is blowing in
	var/wind_direction = NORTH
	/// wind direction stuff cooldown
	COOLDOWN_DECLARE(wind_change_cooldown)
	/// Enables curated Fallout weather cycling with safety pacing.
	var/use_fallout_weather_director = TRUE
	/// Curated weather weights used by the Fallout weather director.
	var/list/fallout_weather_rolls = list()
	/// Prevent immediate same-weather repeats.
	var/last_weather_path = null
	/// Last time a non-aesthetic dangerous weather ended.
	var/last_dangerous_weather_end = 0

/datum/controller/subsystem/processing/weather/fire()
	. = ..() //Active weather is handled by . = ..() processing subsystem base fire().
	if(COOLDOWN_FINISHED(src, wind_change_cooldown))
		set_wind_direction()
		COOLDOWN_START(src, wind_change_cooldown, rand(5 MINUTES, 15 MINUTES))
	if(use_fallout_weather_director)
		return schedule_fallout_weather()
	// start random weather on relevant levels - the SAME weather on all those Zs!
	if(weather_queued || !LAZYLEN(weather_rolls))
		return FALSE
	var/datum/weather/W = pickweight(weather_rolls)
	var/randTime = rand(WEATHER_WAIT_MIN, WEATHER_WAIT_MAX)
	timerid = addtimer(CALLBACK(src, PROC_REF(run_weather), W), randTime + initial(W.weather_duration_upper), TIMER_UNIQUE | TIMER_STOPPABLE) //Around 25-30 minutes between weathers
	next_hit_by_zlevel = world.time + randTime + initial(W.telegraph_duration)
	weather_queued = TRUE // weather'll set this to FALSE when it ends

/datum/controller/subsystem/processing/weather/Initialize(start_timeofday)
	for(var/V in subtypesof(/datum/weather))
		var/datum/weather/W = V
		var/probability = initial(W.probability)
		// any weather with a probability set may occur at random
		if (probability)
			weather_rolls[W] = probability
	if(use_fallout_weather_director)
		configure_fallout_weather_rolls()
	return ..()

/datum/controller/subsystem/processing/weather/proc/configure_fallout_weather_rolls()
	fallout_weather_rolls = list(
		/datum/weather/ash_storm/sandstorm = 24,
		/datum/weather/rain/fog = 20,
		/datum/weather/rain = 16,
		/datum/weather/heat_wave = 14,
		/datum/weather/cold_wave = 12,
		/datum/weather/rad_storm = 8,
		/datum/weather/acid_rain = 6
	)
	// Also reflect the curated pool in weather_rolls for debug/admin visibility.
	weather_rolls = fallout_weather_rolls.Copy()

/datum/controller/subsystem/processing/weather/proc/is_weather_path_dangerous(weather_path)
	if(!ispath(weather_path, /datum/weather))
		return FALSE
	var/datum/weather/W = weather_path
	if(initial(W.aesthetic))
		return FALSE
	return !!initial(W.is_dangerous)

/datum/controller/subsystem/processing/weather/proc/pick_fallout_weather()
	if(!LAZYLEN(fallout_weather_rolls))
		return null

	var/list/candidates = list()
	for(var/weather_path in fallout_weather_rolls)
		var/weight = fallout_weather_rolls[weather_path]
		if(weight <= 0)
			continue
		if(weather_path == last_weather_path && LAZYLEN(fallout_weather_rolls) > 1)
			continue
		if(is_weather_path_dangerous(weather_path) && world.time < (last_dangerous_weather_end + FALLOUT_DANGEROUS_WEATHER_GAP))
			continue
		candidates[weather_path] = weight

	// Fallback: if all options are filtered out, relax the dangerous-gap filter.
	if(!LAZYLEN(candidates))
		for(var/weather_path in fallout_weather_rolls)
			var/weight = fallout_weather_rolls[weather_path]
			if(weight <= 0)
				continue
			if(weather_path == last_weather_path && LAZYLEN(fallout_weather_rolls) > 1)
				continue
			candidates[weather_path] = weight

	if(!LAZYLEN(candidates))
		return null
	return pickweight(candidates)

/datum/controller/subsystem/processing/weather/proc/schedule_fallout_weather()
	if(weather_queued || !LAZYLEN(fallout_weather_rolls))
		return FALSE
	var/datum/weather/W = pick_fallout_weather()
	if(!W)
		return FALSE

	var/randTime = rand(FALLOUT_WEATHER_WAIT_MIN, FALLOUT_WEATHER_WAIT_MAX)
	timerid = addtimer(CALLBACK(src, PROC_REF(run_weather), W), randTime + initial(W.weather_duration_upper), TIMER_UNIQUE | TIMER_STOPPABLE)
	next_hit_by_zlevel = world.time + randTime + initial(W.telegraph_duration)
	weather_queued = TRUE
	return TRUE

/datum/controller/subsystem/processing/weather/proc/run_weather(datum/weather/weather_datum_type, duration)
	if (istext(weather_datum_type))
		for (var/V in subtypesof(/datum/weather))
			var/datum/weather/W = V
			if (initial(W.name) == weather_datum_type)
				weather_datum_type = V
				break
	if (!ispath(weather_datum_type, /datum/weather))
		CRASH("run_weather called with invalid weather_datum_type: [weather_datum_type || "null"]")
/* 	if (isnull(z_levels))
		z_levels = SSmapping.levels_by_trait(initial(weather_datum_type.target_trait))
	else if (isnum(z_levels))
		z_levels = list(z_levels)
	else if (!islist(z_levels))
		CRASH("run_weather called with invalid z_levels: [z_levels || "null"]")
	if(duration && !isnum(duration))
		CRASH("run_weather called with invalid duration: [duration || "null"]") */
	end_weather(FALSE, FALSE, TRUE)
	current_weather = new weather_datum_type(eligible_zlevels, duration)

/datum/controller/subsystem/processing/weather/proc/end_weather(clear_fluff = TRUE, reset_queue = TRUE, delete_weather = TRUE)
	if(current_weather)
		last_weather_path = current_weather.type
		if(is_weather_path_dangerous(last_weather_path))
			last_dangerous_weather_end = world.time
	if(clear_fluff)
		next_hit_by_zlevel = null
	if(reset_queue)
		weather_queued = FALSE
	if(delete_weather)
		if(current_weather)
			current_weather.end(TRUE)
			QDEL_NULL(current_weather)
		if(timerid)
			deltimer(timerid)

/datum/controller/subsystem/processing/weather/proc/get_weather(area/active_area)
	if(!current_weather) // No weather, no problems
		return
	if(!isarea(active_area))
		active_area = get_area(active_area)
		if(!isarea(active_area)) // still??
			return
	if(!LAZYLEN(active_area.weather_tags) || !active_area.weather_tags || isnull(active_area.weather_tags))
		return // area cant have weather (or it wasnt set up right), so it doesnt have weather
	if(current_weather.tag_weather in active_area.weather_tags) // weather affects all affectable areas at once, so if we have a weather, and that area can support it, it'll have that weather
		return current_weather

/datum/controller/subsystem/processing/weather/proc/set_wind_direction()
	var/list/possible_directions = list(NORTH, SOUTH, EAST, WEST)
	wind_direction = pick(possible_directions)



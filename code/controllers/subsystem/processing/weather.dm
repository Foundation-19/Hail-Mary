#define STARTUP_STAGE 1
#define MAIN_STAGE 2
#define WIND_DOWN_STAGE 3
#define END_STAGE 4

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
	if(length(get_active_weathers()) >= WEATHER_MAX_CONCURRENT || (get_weather_family(weather_type) in get_busy_families(TRUE)))
		return
	run_weather(weather_type, null, null, FALSE)

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
		if(mult > 0)
			weights[W] = weather_rolls[W] * mult
	return LAZYLEN(weights) ? weights : open

/datum/controller/subsystem/processing/weather/Initialize(start_timeofday)
	set_wind_direction(rand(0, 359))
	for(var/V in subtypesof(/datum/weather))
		var/datum/weather/W = V
		var/probability = initial(W.probability)
		// any weather with a probability set may occur at random
		if (probability)
			weather_rolls[W] = probability
	return ..()

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



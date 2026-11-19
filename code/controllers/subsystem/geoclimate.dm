/**
 * Geoclimate: the ground's slow memory of the weather. See code/__DEFINES/geoclimate.dm for the numbers.
 *
 * The outdoors is cut into parcels. Rain soaks them, heat and the sun dry them, and every parcel drifts back toward its own water table,
 * which is higher the more open water is around it, so a floodplain keeps sliding back to marsh however many droughts pass over it.
 * Wet ground grows plants and goes to mud. A parcel nobody has set foot in for an hour is taken back by vines, so a ruin left alone
 * is a ruin overgrown. People holding a place keep it from going wild. A radiation storm leaves its fallout soaked into the ground
 * too, which fades on its own slow clock long after the clouds have cleared, so land that got hit hard stays dangerous for a while.
 */
SUBSYSTEM_DEF(geoclimate)
	name = "Geoclimate"
	flags = SS_BACKGROUND
	wait = GEO_TICK_INTERVAL
	priority = FIRE_PRIORITY_WET_FLOORS
	runlevels = RUNLEVEL_GAME
	/// Parcels by z level, row by row
	var/list/grid = list()
	var/list/datum/geo_parcel/parcels = list()
	var/list/datum/geo_parcel/currentrun = list()
	/// Parcels whose mud has to be laid or lifted
	var/list/datum/geo_parcel/mud_queue = list()
	var/columns = 1
	var/rows = 1
	/// Where the mud patches lie. Global so a patch carries on across the edge of a parcel
	var/mud_seed_a = 0
	var/mud_seed_b = 0
	// Worked out once per tick
	var/list/datum/weather/wet_weathers = list()
	/// Weathers laying fallout into the ground this tick, see geoclimate
	var/list/datum/weather/rad_weathers = list()
	var/list/turf/player_turfs = list()
	var/evaporation = 1

/datum/controller/subsystem/geoclimate/Initialize(start_timeofday)
	mud_seed_a = rand(0, 359)
	mud_seed_b = rand(0, 359)
	columns = -round(-world.maxx / GEO_PARCEL_SIZE)
	rows = -round(-world.maxy / GEO_PARCEL_SIZE)
	grid.len = world.maxz
	for(var/z in SSweather.eligible_zlevels)
		if(z <= world.maxz)
			survey_level(z)
	load_persistence()
	return ..()

/datum/controller/subsystem/geoclimate/stat_entry(msg)
	msg = "P:[length(parcels)]|M:[length(mud_queue)]"
	return ..()

/datum/controller/subsystem/geoclimate/Recover()
	if(islist(SSgeoclimate.grid))
		grid = SSgeoclimate.grid
		parcels = SSgeoclimate.parcels
		mud_seed_a = SSgeoclimate.mud_seed_a
		mud_seed_b = SSgeoclimate.mud_seed_b
		columns = SSgeoclimate.columns
		rows = SSgeoclimate.rows

/// Maps one level and works out how wet its country is
/datum/controller/subsystem/geoclimate/proc/survey_level(z)
	var/list/level = list()
	level.len = columns * rows
	for(var/row in 0 to rows - 1)
		for(var/column in 0 to columns - 1)
			var/datum/geo_parcel/P = new(z, column * GEO_PARCEL_SIZE + 1, row * GEO_PARCEL_SIZE + 1, min(world.maxx, (column + 1) * GEO_PARCEL_SIZE), min(world.maxy, (row + 1) * GEO_PARCEL_SIZE))
			P.survey()
			level[row * columns + column + 1] = P
			CHECK_TICK
	grid[z] = level
	for(var/datum/geo_parcel/P as anything in level)
		var/neighbour_water = 0
		var/neighbours = 0
		for(var/datum/geo_parcel/N as anything in get_neighbours(P))
			neighbour_water += N.water_share()
			neighbours++
		P.settle(neighbours ? neighbour_water / neighbours : 0)
		if(P.active)
			parcels += P

/// The parcel a spot is in, if that level is mapped
/datum/controller/subsystem/geoclimate/proc/get_parcel(atom/A)
	var/turf/T = get_turf(A)
	if(!T || T.z > length(grid))
		return null
	var/list/level = grid[T.z]
	if(!level)
		return null
	return level[round((T.y - 1) / GEO_PARCEL_SIZE) * columns + round((T.x - 1) / GEO_PARCEL_SIZE) + 1]

/// The parcels around this one, without itself
/datum/controller/subsystem/geoclimate/proc/get_neighbours(datum/geo_parcel/P)
	. = list()
	var/list/level = grid[P.z]
	var/column = round((P.x1 - 1) / GEO_PARCEL_SIZE)
	var/row = round((P.y1 - 1) / GEO_PARCEL_SIZE)
	for(var/dr in -1 to 1)
		for(var/dc in -1 to 1)
			if(!dr && !dc)
				continue
			var/r = row + dr
			var/c = column + dc
			if(r < 0 || r >= rows || c < 0 || c >= columns)
				continue
			var/datum/geo_parcel/N = level[r * columns + c + 1]
			if(N)
				. += N

/datum/controller/subsystem/geoclimate/fire(resumed = FALSE)
	process_mud()
	if(!resumed)
		currentrun = parcels.Copy()
		prepare_tick()
	var/list/run = currentrun
	while(length(run))
		var/datum/geo_parcel/P = run[length(run)]
		run.len--
		update_parcel(P)
		if(MC_TICK_CHECK)
			return

/// Who is about, what is falling and how hard the sun is drying things, for every parcel this tick
/datum/controller/subsystem/geoclimate/proc/prepare_tick()
	player_turfs = list()
	for(var/mob/living/L in GLOB.player_list)
		if(L.stat == DEAD)
			continue
		var/turf/T = get_turf(L)
		var/datum/geo_parcel/home = get_parcel(T)
		if(!home)
			continue
		player_turfs += T
		home.last_visit = world.time
		for(var/datum/geo_parcel/N as anything in get_neighbours(home))
			N.last_visit = world.time
	wet_weathers = list()
	rad_weathers = list()
	var/heat = 0
	for(var/datum/weather/W as anything in SSweather.get_active_weathers())
		if(W.stage == MAIN_STAGE)
			heat += W.climate_temp_shift
		if((W.soak_rate || W.vegetation_harm) && (W.stage == MAIN_STAGE || W.stage == WIND_DOWN_STAGE))
			wet_weathers += W
		if(W.ground_contamination_rate && (W.stage == MAIN_STAGE || W.stage == WIND_DOWN_STAGE))
			rad_weathers += W
	var/sun = SSnightcycle.current_sun_power / 200
	evaporation = clamp((0.3 + 0.7 * sun) * (1 + heat / 30), GEO_EVAP_MIN, GEO_EVAP_MAX)

/datum/controller/subsystem/geoclimate/proc/update_parcel(datum/geo_parcel/P)
	var/minutes = (world.time - P.last_step) / (1 MINUTES)
	if(minutes <= 0)
		return
	P.last_step = world.time
	var/soak = 0
	var/harm = 0
	for(var/datum/weather/W as anything in wet_weathers)
		var/strength = (W.stage == MAIN_STAGE ? 1 : 0.5) * W.get_intensity(P.centre)
		soak += W.soak_rate * strength
		harm += W.vegetation_harm * strength
	var/contamination = 0
	for(var/datum/weather/W as anything in rad_weathers)
		var/strength = (W.stage == MAIN_STAGE ? 1 : 0.5) * W.get_intensity(P.centre)
		contamination += W.ground_contamination_rate * strength
	P.advance(minutes, soak, evaporation, harm, P.growth_multiplier(), contamination)
	if(P.soil_n && P.target_mud_step() != P.mud_step)
		mud_queue |= P
	cultivate(P)

/// Lays or lifts the mud of a few parcels whose ground has got wetter or drier
/datum/controller/subsystem/geoclimate/proc/process_mud()
	for(var/i in 1 to GEO_MUD_PARCELS_PER_TICK)
		if(!length(mud_queue))
			return
		var/datum/geo_parcel/P = mud_queue[1]
		mud_queue.Cut(1, 2)
		P.mud_step = P.target_mud_step()
		apply_mud(P)

/// Sets every soil turf in a parcel to match its current mud step
/datum/controller/subsystem/geoclimate/proc/apply_mud(datum/geo_parcel/P)
	var/cover = GEO_MUD_MAX_COVER * P.mud_step / GEO_MUD_STEPS
	for(var/turf/T as anything in P.get_turfs())
		if(T.geo_class() != GEO_TURF_SOIL)
			continue
		var/turf/open/soil = T
		soil.set_geo_mud(cover > 0 && mud_noise(T) < cover)
		CHECK_TICK

/// 0 to 1, a lumpy field that mud spreads through as it deepens
/datum/controller/subsystem/geoclimate/proc/mud_noise(turf/T)
	return 0.5 + 0.25 * (sin(T.x * 23 + T.y * 9 + mud_seed_a) + sin(T.y * 19 - T.x * 13 + mud_seed_b))

/// Plants spring up where the ground is wet enough and wither where it has dried, out of sight of anyone, and vines take abandoned ruins
/datum/controller/subsystem/geoclimate/proc/cultivate(datum/geo_parcel/P)
	P.clean_grown()
	var/wild = P.plant_cap()
	if(length(P.grown_soil) < wild)
		for(var/i in 1 to GEO_PLANTS_PER_PARCEL_TICK)
			grow(P)
	else if(length(P.grown_soil) > wild + 1)
		wither(P, P.grown_soil)
	var/reclaimed = P.reclaim_cap()
	if(length(P.grown_built) < reclaimed)
		reclaim(P)
	else if(length(P.grown_built) > reclaimed + 1)
		wither(P, P.grown_built)

/// Whether a player could be watching this turf
/datum/controller/subsystem/geoclimate/proc/is_watched(turf/T)
	for(var/turf/watcher as anything in player_turfs)
		if(watcher.z == T.z && get_dist(watcher, T) <= GEO_UNSEEN_RANGE)
			return TRUE
	return FALSE

/datum/controller/subsystem/geoclimate/proc/grow(datum/geo_parcel/P)
	for(var/attempt in 1 to 4)
		var/turf/open/T = P.random_turf()
		if(!istype(T))
			continue
		var/class = T.geo_class()
		if((class != GEO_TURF_SOIL && class != GEO_TURF_SAND) || !T.geo_free_to_grow() || is_watched(T))
			continue
		var/plant_type = P.pick_plant()
		var/obj/structure/flora/plant = new plant_type(T)
		T.turfPlant = plant
		P.grown_soil += plant
		return

/datum/controller/subsystem/geoclimate/proc/reclaim(datum/geo_parcel/P)
	for(var/attempt in 1 to 4)
		var/turf/open/T = P.random_turf()
		if(!istype(T) || T.geo_class() != GEO_TURF_BUILT || !T.geo_free_to_grow() || !T.geo_outdoors() || is_watched(T))
			continue
		var/obj/structure/flora/grass/whitelegvine/overgrown/vines = new(T)
		P.grown_built += vines
		return

/// Takes one of a parcel's plants away, never in front of anyone
/datum/controller/subsystem/geoclimate/proc/wither(datum/geo_parcel/P, list/plants)
	var/obj/structure/flora/plant = pick(plants)
	var/turf/T = get_turf(plant)
	if(!T || is_watched(T))
		return
	plants -= plant
	if(istype(T, /turf/open))
		var/turf/open/O = T
		if(O.turfPlant == plant)
			O.turfPlant = null
	qdel(plant)

/// What the ground at a spot is like and where it is heading, for the barometer
/datum/controller/subsystem/geoclimate/proc/describe_ground(atom/A)
	var/datum/geo_parcel/P = get_parcel(A)
	if(!P)
		return null
	. = "The ground here is [P.describe_moisture()]."
	if(P.wetland_pull >= GEO_MARSH_PULL)
		. += " This is low, wet country. Left alone it will slide back toward marsh."
	else if(P.abandoned() && P.vegetation >= 40)
		. += " Nobody has kept this ground in a long while and the growth is taking it back."
	else if(P.vegetation < 15 && P.moisture < 20)
		. += " Nothing much will grow here without rain."
	if(P.radiation >= GEO_RADIATION_MAX * 0.1)
		. += " A geiger counter would not stop clicking here. Something irradiated this ground badly, and it has not faded yet."

/// Soaks every parcel within a radius, in tiles, by that much moisture. Negative dries it. For admins and tests
/datum/controller/subsystem/geoclimate/proc/drench(turf/centre, radius, amount)
	for(var/datum/geo_parcel/P as anything in parcels)
		if(P.z == centre.z && get_dist(P.centre, centre) <= radius)
			P.moisture = clamp(P.moisture + amount, 0, 100)
			if(P.soil_n)
				mud_queue |= P

/// Kelvin that damp ground adds to or takes from the air at this spot: nights are milder and days are cooler over wet ground
/datum/controller/subsystem/geoclimate/proc/get_thermal_moderation(atom/A, temperature)
	var/datum/geo_parcel/P = get_parcel(A)
	if(!P)
		return 0
	return (CLIMATE_INDOOR_TEMP - temperature) * GEO_THERMAL_MODERATION * clamp(P.moisture / 100, 0, 1)

/// 0 to 100, how wet the ground under this spot is right now. For anything outdoors that wants to drink the rain instead of a watering can
/datum/controller/subsystem/geoclimate/proc/get_ground_moisture(atom/A)
	var/datum/geo_parcel/P = get_parcel(A)
	return P ? P.moisture : 0

/// 0 to GEO_RADIATION_MAX, how hot a storm's fallout has left this ground. Keeps giving off rads long after the sky has cleared
/datum/controller/subsystem/geoclimate/proc/get_radiation_level(atom/A)
	var/datum/geo_parcel/P = get_parcel(A)
	return P ? P.radiation : 0

/// Where this map's ground is remembered between rounds, one file per map so a map swap does not mix up two different pieces of country
/datum/controller/subsystem/geoclimate/proc/save_path()
	return "data/Geoclimate[SSmapping.config.map_name].json"

/// Writes every active parcel's moisture, vegetation, mud and growth to disk, so the land remembers what it had earned here when the round ends
/datum/controller/subsystem/geoclimate/proc/save_persistence()
	var/list/parcel_data = list()
	for(var/datum/geo_parcel/P as anything in parcels)
		P.clean_grown()
		parcel_data += list(P.to_save_data())
	var/list/file_data = list("parcels" = parcel_data)
	var/json_file = file(save_path())
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/// Reads back whatever this map's ground remembers from the last round that used it, and plants it in straight away instead of waiting on it to regrow
/datum/controller/subsystem/geoclimate/proc/load_persistence()
	var/json_file = file(save_path())
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!islist(json) || !islist(json["parcels"]))
		return
	for(var/list/entry in json["parcels"])
		if(!islist(entry))
			continue
		var/datum/geo_parcel/P = get_parcel(locate(entry["x"], entry["y"], entry["z"]))
		// Skip anything that no longer lines up: a different map, or the same map recompiled with a different parcel grid
		if(!P || !P.active || P.x1 != entry["x"] || P.y1 != entry["y"] || P.z != entry["z"])
			continue
		P.apply_save_data(entry)
		if(P.soil_n)
			apply_mud(P)
		for(var/i in 1 to clamp(round(isnum(entry["wild"]) ? entry["wild"] : 0), 0, GEO_PLANTS_PER_PARCEL_TICK * 50))
			grow(P)
		for(var/i in 1 to clamp(round(isnum(entry["reclaimed"]) ? entry["reclaimed"] : 0), 0, 50))
			reclaim(P)
		CHECK_TICK

/// A patch of the outdoors, see the subsystem
/datum/geo_parcel
	var/z = 1
	var/x1 = 1
	var/y1 = 1
	var/x2 = 1
	var/y2 = 1
	var/turf/centre
	var/size = 1
	var/water_n = 0
	var/soil_n = 0
	var/sand_n = 0
	var/rock_n = 0
	/// Open outdoor ground people built over
	var/built_open_n = 0
	/// Whether there is anything here to grow, wet or take back
	var/active = FALSE
	/// 0 to 1, how much this parcel wants to be wetland, from the water around it
	var/wetland_pull = 0
	var/equilibrium = 0
	var/moisture = 0
	var/vegetation = 0
	/// 0 to GEO_RADIATION_MAX, fallout a radiation storm has left soaked into this parcel. Fades on its own slow clock, see advance()
	var/radiation = 0
	var/last_step = 0
	var/last_visit = 0
	/// How much of the mud this parcel is meant to have is laid, in steps up to GEO_MUD_STEPS
	var/mud_step = 0
	var/list/obj/structure/flora/grown_soil = list()
	var/list/obj/structure/flora/grown_built = list()

/datum/geo_parcel/New(z, x1, y1, x2, y2)
	..()
	src.z = z
	src.x1 = x1
	src.y1 = y1
	src.x2 = x2
	src.y2 = y2
	size = (x2 - x1 + 1) * (y2 - y1 + 1)
	centre = locate(round((x1 + x2) / 2), round((y1 + y2) / 2), z)
	last_step = world.time
	last_visit = world.time

/datum/geo_parcel/Destroy()
	centre = null
	grown_soil = null
	grown_built = null
	return ..()

/datum/geo_parcel/proc/get_turfs()
	return block(locate(x1, y1, z), locate(x2, y2, z))

/// Counts what the ground is made of
/datum/geo_parcel/proc/survey()
	for(var/turf/T as anything in get_turfs())
		switch(T.geo_class())
			if(GEO_TURF_WATER)
				water_n++
			if(GEO_TURF_SOIL)
				soil_n++
			if(GEO_TURF_SAND)
				sand_n++
			if(GEO_TURF_ROCK)
				rock_n++
			if(GEO_TURF_BUILT)
				if(isopenturf(T) && T.geo_outdoors())
					built_open_n++
	active = (soil_n + sand_n + built_open_n) > 0

/datum/geo_parcel/proc/water_share()
	return water_n / size

/// Sets how wet the country is from the water in and around the parcel, and starts it at the level it would settle at
/datum/geo_parcel/proc/settle(neighbour_water_share)
	wetland_pull = clamp(water_share() * GEO_WETLAND_OWN + neighbour_water_share * GEO_WETLAND_NEIGHBOUR, 0, 1)
	equilibrium = wetland_pull * GEO_WETLAND_MAX
	moisture = equilibrium
	vegetation = vegetation_target() * 0.5

/// 0 to 1, how well the ground grows things
/datum/geo_parcel/proc/fertility()
	return (soil_n + sand_n * GEO_SAND_FERTILITY) / max(1, soil_n + sand_n + rock_n)

/// The vegetation the current moisture will in the end bring
/datum/geo_parcel/proc/vegetation_target()
	return clamp((moisture - GEO_VEG_MOISTURE_FLOOR) * GEO_VEG_PER_MOISTURE, 0, 100) * clamp(0.25 + 0.75 * fertility(), 0, 1)

/// Brings the parcel on by this many minutes. Soak is moisture per minute from rain, evaporation scales how fast the surplus drains,
/// harm is vegetation per minute lost to blight and growth scales how fast plants come on. Contamination is rads per minute a storm
/// is laying into the ground right now, which then fades on its own long after the storm has gone
/datum/geo_parcel/proc/advance(minutes, soak, evaporation, harm, growth, contamination = 0)
	moisture = clamp(moisture + soak * minutes, 0, 100)
	if(moisture > equilibrium)
		var/keep = 1 - clamp(GEO_DRAIN_RATE * evaporation * (1 - GEO_WETLAND_RETENTION * wetland_pull), 0, 0.9)
		moisture = equilibrium + (moisture - equilibrium) * (keep ** minutes)
	else
		moisture = equilibrium - (equilibrium - moisture) * ((1 - GEO_SEEP_RATE) ** minutes)
	var/target = vegetation_target()
	if(target > vegetation)
		vegetation = min(target, vegetation + GEO_GROWTH_RATE * growth * minutes)
	else
		vegetation = max(target, vegetation - GEO_WITHER_RATE * minutes)
	vegetation = max(0, vegetation - harm * minutes)
	if(contamination > 0)
		radiation = min(GEO_RADIATION_MAX, radiation + contamination * minutes)
	radiation *= (1 - GEO_RADIATION_DECAY) ** minutes

/datum/geo_parcel/proc/abandoned()
	return world.time - last_visit >= GEO_ABANDON_TIME

/// People trim and trample what grows around them. Nobody about at all lets it run wild
/datum/geo_parcel/proc/growth_multiplier()
	var/idle = world.time - last_visit
	if(idle < GEO_TENDED_TIME)
		return GEO_TENDED_GROWTH
	if(idle >= GEO_ABANDON_TIME)
		return GEO_ABANDONED_GROWTH
	return 1

/datum/geo_parcel/proc/target_mud_step()
	if(!soil_n)
		return 0
	return round(clamp((moisture - GEO_MUD_START) / (GEO_MUD_FULL - GEO_MUD_START), 0, 1) * GEO_MUD_STEPS)

/// How many plants the ground can carry at the moment
/datum/geo_parcel/proc/plant_cap()
	return round((soil_n + sand_n * GEO_SAND_FERTILITY) * GEO_MAX_COVER * vegetation / 100)

/// How many places in the ruins vines hold. None while anyone is about
/datum/geo_parcel/proc/reclaim_cap()
	if(!abandoned())
		return 0
	return round(built_open_n * GEO_RECLAIM_COVER * vegetation / 100)

/datum/geo_parcel/proc/clean_grown()
	for(var/obj/structure/flora/F as anything in grown_soil)
		if(QDELETED(F))
			grown_soil -= F
	for(var/obj/structure/flora/F as anything in grown_built)
		if(QDELETED(F))
			grown_built -= F

/// This parcel's moisture, vegetation, mud and growth, ready to write to disk between rounds
/datum/geo_parcel/proc/to_save_data()
	var/list/entry = list()
	entry["z"] = z
	entry["x"] = x1
	entry["y"] = y1
	entry["moisture"] = round(moisture, 0.1)
	entry["vegetation"] = round(vegetation, 0.1)
	entry["radiation"] = round(radiation, 0.1)
	entry["mud_step"] = mud_step
	entry["idle"] = round(world.time - last_visit)
	entry["wild"] = length(grown_soil)
	entry["reclaimed"] = length(grown_built)
	return entry

/// Restores moisture, vegetation, mud step and idle time from a saved entry. Falls back to a safe default for anything missing or not a number,
/// so a corrupt or outdated save file cannot leave the parcel in a broken state. The subsystem restores the actual growth, since that needs real turfs
/datum/geo_parcel/proc/apply_save_data(list/entry)
	moisture = clamp(isnum(entry["moisture"]) ? entry["moisture"] : 0, 0, 100)
	vegetation = clamp(isnum(entry["vegetation"]) ? entry["vegetation"] : 0, 0, 100)
	radiation = clamp(isnum(entry["radiation"]) ? entry["radiation"] : 0, 0, GEO_RADIATION_MAX)
	mud_step = clamp(round(isnum(entry["mud_step"]) ? entry["mud_step"] : 0), 0, GEO_MUD_STEPS)
	last_visit = world.time - max(0, round(isnum(entry["idle"]) ? entry["idle"] : 0))

/datum/geo_parcel/proc/random_turf()
	return locate(rand(x1, x2), rand(y1, y2), z)

/datum/geo_parcel/proc/pick_plant()
	if(moisture >= GEO_MARSH_MOISTURE && wetland_pull >= GEO_MARSH_PULL)
		return pickweight(GLOB.geo_marsh_plant_list)
	if(moisture >= GEO_LUSH_MOISTURE && vegetation >= GEO_LUSH_VEGETATION)
		return pickweight(GLOB.lush_plant_spawn_list)
	return pickweight(GLOB.desolate_plant_spawn_list)

/datum/geo_parcel/proc/describe_moisture()
	switch(moisture)
		if(0 to 10)
			return "parched and cracked"
		if(10 to 30)
			return "dry"
		if(30 to 55)
			return "damp"
		if(55 to 75)
			return "sodden"
		if(75 to 90)
			return "boggy"
	return "waterlogged"

GLOBAL_LIST_INIT(geo_marsh_plant_list, list(
	/obj/structure/flora/grass/saltlake = 3,
	/obj/structure/flora/grass/saltlakesparse/two = 3,
	/obj/structure/flora/grass/saltlakesparse/three = 3,
	/obj/structure/flora/grass/saltlakesparse/four = 2,
	/obj/structure/flora/grass/wasteland = 4
	))

/// Vines coming up through the cracks of a place nobody tends any more
/obj/structure/flora/grass/whitelegvine/overgrown
	name = "overgrowth"
	desc = "Vines and weeds forcing their way up through the cracks. Nature is taking this place back."

/// What the ground is made of, for the geoclimate subsystem to count
/turf/proc/geo_class()
	return GEO_TURF_BUILT

/turf/proc/geo_outdoors()
	var/area/A = loc
	return istype(A) && A.outdoors

/turf/open/water/geo_class()
	return GEO_TURF_WATER

/turf/open/indestructible/ground/outside/geo_class()
	return GEO_TURF_ROCK

/turf/open/indestructible/ground/outside/river/geo_class()
	return GEO_TURF_WATER

/turf/open/indestructible/ground/outside/water/geo_class()
	return GEO_TURF_WATER

/turf/open/indestructible/ground/outside/dirt/geo_class()
	return GEO_TURF_SOIL

/turf/open/indestructible/ground/outside/dirt_s/geo_class()
	return GEO_TURF_SOIL

/turf/open/indestructible/ground/outside/grass_s/geo_class()
	return GEO_TURF_SOIL

/turf/open/indestructible/ground/outside/savannah/geo_class()
	return GEO_TURF_SOIL

/turf/open/indestructible/ground/outside/desert/geo_class()
	return GEO_TURF_SAND

/turf/open/floor/plating/f13/outside/desert/geo_class()
	return GEO_TURF_SAND

/turf/open
	/// Churned to mud by wet weather, see geoclimate
	var/geo_mud = FALSE

/// Nothing standing on it that would be in the way of something growing there
/turf/open/proc/geo_free_to_grow()
	if(turfPlant && !QDELETED(turfPlant))
		return FALSE
	if(is_blocked_turf(src, TRUE))
		return FALSE
	return !(locate(/obj/structure) in src) && !(locate(/obj/machinery) in src) && !(locate(/obj/item) in src) && geo_outdoors()

/turf/open/proc/set_geo_mud(muddy)
	if(muddy == geo_mud)
		return
	geo_mud = muddy
	if(muddy)
		slowdown += GEO_MUD_SLOWDOWN
		add_atom_colour(GEO_MUD_COLOUR, FIXED_COLOUR_PRIORITY)
	else
		slowdown -= GEO_MUD_SLOWDOWN
		remove_atom_colour(FIXED_COLOUR_PRIORITY, GEO_MUD_COLOUR)

/turf/open/examine(mob/user)
	. = ..()
	if(geo_mud)
		. += span_notice("The ground here has turned to sucking mud.")

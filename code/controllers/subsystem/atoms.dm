#define BAD_INIT_QDEL_BEFORE 1
#define BAD_INIT_DIDNT_INIT 2
#define BAD_INIT_SLEPT 4
#define BAD_INIT_NO_HINT 8

SUBSYSTEM_DEF(atoms)
	name = "Atoms"
	init_order = INIT_ORDER_ATOMS
	flags = SS_NO_FIRE

	var/old_initialized

	var/list/late_loaders

	var/list/BadInitializeCalls = list()

#ifdef ATOM_INIT_PROFILE
	/// Cumulative real-time (deciseconds) in Initialize() per type; only populated with ATOM_INIT_PROFILE defined
	var/list/init_type_times = list()
	var/list/init_type_counts = list()
#endif

/datum/controller/subsystem/atoms/Initialize(timeofday)
	GLOB.fire_overlay.appearance_flags = RESET_COLOR
	setupGenetics()
	
	// OPTIMIZATION: Pre-allocate GLOB.machines to avoid repeated list resizing during init
	// Typical maps have 1000-2500 machines, so pre-allocate to avoid performance hits
	GLOB.machines = new /list(2500)
	
	initialized = INITIALIZATION_INNEW_MAPLOAD
	InitializeAtoms()
#ifdef ATOM_INIT_PROFILE
	var/profilelog = InitProfileLog()
	if(profilelog)
		text2file(profilelog, "[GLOB.log_directory]/initialize_profile.log")
#endif
	return ..()

/datum/controller/subsystem/atoms/proc/InitializeAtoms(list/atoms)
	if(initialized == INITIALIZATION_INSSATOMS)
		return

	initialized = INITIALIZATION_INNEW_MAPLOAD

	LAZYINITLIST(late_loaders)

	var/count
	var/batch_count = 0
	var/list/mapload_arg = list(TRUE)
	if(atoms)
		count = atoms.len
		for(var/I in atoms)
			var/atom/A = I
			if(!(A.flags_1 & INITIALIZED_1))
				InitAtom(I, mapload_arg)
				if(++batch_count >= 100)
					batch_count = 0
					CHECK_TICK
	else
		count = 0
		for(var/atom/A in world)
			if(!(A.flags_1 & INITIALIZED_1))
				InitAtom(A, mapload_arg)
				++count
				if(++batch_count >= 100)
					batch_count = 0
					CHECK_TICK

	testing("Initialized [count] atoms")
	pass(count)

	initialized = INITIALIZATION_INNEW_REGULAR

	var/phase_t = REALTIMEOFDAY
	if(late_loaders.len)
		batch_count = 0
		for(var/I in late_loaders)
			var/atom/A = I
			A.LateInitialize()
			if(++batch_count >= 100)
				batch_count = 0
				CHECK_TICK
		testing("Late initialized [late_loaders.len] atoms")
		late_loaders.Cut()
	var/late_ms = (REALTIMEOFDAY - phase_t) * 100
	// Batch post-init passes only during mapload (atoms == null when called for mapload)
	if(!atoms)
		// Sunlight source setup — iterate only tracked source turfs, collect borders as we go.
		phase_t = REALTIMEOFDAY
		testing("Updating sunlight and water adjacency for all turfs...")
		var/list/border_turf_queue = list()
		batch_count = 0
		for(var/turf/T in GLOB.init_sunlight_source_turfs)
			T.vis_contents += SSnightcycle.sunlight_source_object
			T.luminosity = 1
			for(var/dir in GLOB.alldirs)
				var/turf/neighbor = get_step(T, dir)
				if(!neighbor || !neighbor.type || (neighbor.sunlight_state && neighbor.sunlight_state != NO_SUNLIGHT))
					continue
				neighbor.sunlight_state = SUNLIGHT_BORDER
				border_turf_queue += neighbor  // only added once (next check above will skip it)
			if(++batch_count >= 100)
				batch_count = 0
				CHECK_TICK
		GLOB.init_sunlight_source_turfs = null

		// Water adjacency overlays — iterate only tracked water turfs.
		batch_count = 0
		for(var/turf/T in GLOB.init_water_turfs)
			for(var/dir in GLOB.cardinals)
				var/turf/N = get_step(T, dir)
				if(!N)
					continue
				if(istype(N, /turf/open/indestructible/ground/outside/desert))
					var/obj/effect/overlay/desert_side/DS = new /obj/effect/overlay/desert_side(N)
					switch(turn(dir, 180))
						if(NORTH)
							DS.pixel_y = 32
						if(SOUTH)
							DS.pixel_y = -32
						if(EAST)
							DS.pixel_x = 32
						if(WEST)
							DS.pixel_x = -32
					DS.dir = N.dir = dir
				else if(istype(N, /turf/open/indestructible/ground/inside/mountain))
					var/obj/effect/overlay/rockfloor_side/DS = new /obj/effect/overlay/rockfloor_side(N)
					switch(turn(dir, 180))
						if(NORTH)
							DS.pixel_y = 32
						if(SOUTH)
							DS.pixel_y = -32
						if(EAST)
							DS.pixel_x = 32
						if(WEST)
							DS.pixel_x = -32
					DS.dir = dir
			if(++batch_count >= 100)
				batch_count = 0
				CHECK_TICK
		GLOB.init_water_turfs = null

		// Subway adjacency overlays — iterate only tracked subway turfs.
		batch_count = 0
		for(var/turf/T in GLOB.init_subway_turfs)
			for(var/dir in GLOB.cardinals)
				var/turf/N = get_step(T, dir)
				if(!N || !istype(N, /turf/open))
					continue
				var/obj/effect/overlay/railsnone_side/DS = new /obj/effect/overlay/railsnone_side(T)
				switch(dir)
					if(NORTH)
						DS.pixel_y = 32
					if(SOUTH)
						DS.pixel_y = -32
					if(EAST)
						DS.pixel_x = 32
					if(WEST)
						DS.pixel_x = -32
				DS.dir = turn(dir, 180)
			if(++batch_count >= 100)
				batch_count = 0
				CHECK_TICK
		GLOB.init_subway_turfs = null

		var/cam_sun_ms = (REALTIMEOFDAY - phase_t) * 100
		testing("Sunlight and water adjacency updated")

		// Border smooth pass — use collected border list, no second world scan needed.
		testing("Smoothing sunlight borders...")
		phase_t = REALTIMEOFDAY
		batch_count = 0
		for(var/turf/T in border_turf_queue)
			if(isnull(T.border_neighbors))
				T.smooth_sunlight_border()
			if(++batch_count >= 100)
				batch_count = 0
				CHECK_TICK
		border_turf_queue = null
		var/border_ms = (REALTIMEOFDAY - phase_t) * 100
		testing("Sunlight borders smoothed")
		log_world("Atoms phase breakdown: LateInit=[late_ms]ms | Sunlight=[cam_sun_ms]ms | BorderSmooth=[border_ms]ms")
		// Camera visibility deferred to post-init — no clients are connected during init.
		addtimer(CALLBACK(src, PROC_REF(update_camera_visibility)), 0)
/datum/controller/subsystem/atoms/proc/update_camera_visibility()
	var/batch_count = 0
	for(var/turf/T in world)
		T.visibilityChanged()
		if(++batch_count >= 100)
			batch_count = 0
			CHECK_TICK

/datum/controller/subsystem/atoms/proc/InitAtom(atom/A, list/arguments)
	var/the_type = A.type
	if(QDELING(A))
		BadInitializeCalls[the_type] |= BAD_INIT_QDEL_BEFORE
		return TRUE

	var/start_tick = world.time
#ifdef ATOM_INIT_PROFILE
	var/pre_time = REALTIMEOFDAY
#endif

	var/result = A.Initialize(arglist(arguments))

	// Track turfs for fast mapload batch passes (avoids full world scans in sunlight/border phases)
	// Guards are null-checks: after the sunlight pass the globals are null to free memory,
	// and SSshuttle later calls InitializeAtoms() again — skip tracking then.
	if(arguments[1] && isturf(A))
		var/turf/T = A
		if(GLOB.init_sunlight_source_turfs && T.sunlight_state == SUNLIGHT_SOURCE)
			GLOB.init_sunlight_source_turfs += T
		if(GLOB.init_water_turfs && (istype(T, /turf/open/water) || istype(T, /turf/open/indestructible/ground/outside/water)))
			GLOB.init_water_turfs += T
		if(GLOB.init_subway_turfs && istype(T, /turf/open/indestructible/ground/inside/subway))
			GLOB.init_subway_turfs += T

#ifdef ATOM_INIT_PROFILE
	var/elapsed = REALTIMEOFDAY - pre_time
	init_type_times[the_type] = (init_type_times[the_type] || 0) + elapsed
	init_type_counts[the_type] = (init_type_counts[the_type] || 0) + 1
#endif

	if(start_tick != world.time)
		BadInitializeCalls[the_type] |= BAD_INIT_SLEPT

	var/qdeleted = FALSE

	if(result != INITIALIZE_HINT_NORMAL)
		switch(result)
			if(INITIALIZE_HINT_LATELOAD)
				if(arguments[1])	//mapload
					late_loaders += A
				else
					A.LateInitialize()
			if(INITIALIZE_HINT_QDEL)
				qdel(A)
				qdeleted = TRUE
			else
				BadInitializeCalls[the_type] |= BAD_INIT_NO_HINT

	if(!A)	//possible harddel
		qdeleted = TRUE
	else if(!(A.flags_1 & INITIALIZED_1))
		BadInitializeCalls[the_type] |= BAD_INIT_DIDNT_INIT
	else
		SEND_SIGNAL(A,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE)

	return qdeleted || QDELING(A)

/datum/controller/subsystem/atoms/proc/map_loader_begin()
	old_initialized = initialized
	initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms/proc/map_loader_stop()
	initialized = old_initialized

/datum/controller/subsystem/atoms/Recover()
	initialized = SSatoms.initialized
	if(initialized == INITIALIZATION_INNEW_MAPLOAD)
		InitializeAtoms()
	old_initialized = SSatoms.old_initialized
	BadInitializeCalls = SSatoms.BadInitializeCalls

/datum/controller/subsystem/atoms/proc/setupGenetics()
	var/list/mutations = subtypesof(/datum/mutation/human)
	shuffle_inplace(mutations)
	for(var/A in subtypesof(/datum/generecipe))
		var/datum/generecipe/GR = A
		GLOB.mutation_recipes[initial(GR.required)] = initial(GR.result)
	for(var/i in 1 to LAZYLEN(mutations))
		var/path = mutations[i] //byond gets pissy when we do it in one line
		var/datum/mutation/human/B = new path ()
		B.alias = "Mutation [i]"
		GLOB.all_mutations[B.type] = B
		GLOB.full_sequences[B.type] = generate_gene_sequence(B.blocks)
		GLOB.alias_mutations[B.alias] = B.type
		if(B.locked)
			continue
		if(B.quality == POSITIVE)
			GLOB.good_mutations |= B
		else if(B.quality == NEGATIVE)
			GLOB.bad_mutations |= B
		else if(B.quality == MINOR_NEGATIVE)
			GLOB.not_good_mutations |= B
		CHECK_TICK

/datum/controller/subsystem/atoms/proc/InitLog()
	. = ""
	for(var/path in BadInitializeCalls)
		. += "Path : [path] \n"
		var/fails = BadInitializeCalls[path]
		if(fails & BAD_INIT_DIDNT_INIT)
			. += "- Didn't call atom/Initialize()\n"
		if(fails & BAD_INIT_NO_HINT)
			. += "- Didn't return an Initialize hint\n"
		if(fails & BAD_INIT_QDEL_BEFORE)
			. += "- Qdel'd in New()\n"
		if(fails & BAD_INIT_SLEPT)
			. += "- Slept during Initialize()\n"

/datum/controller/subsystem/atoms/Shutdown()
	var/initlog = InitLog()
	if(initlog)
		text2file(initlog, "[GLOB.log_directory]/initialize.log")
#ifdef ATOM_INIT_PROFILE
	var/profilelog = InitProfileLog()
	if(profilelog)
		text2file(profilelog, "[GLOB.log_directory]/initialize_profile.log")
#endif

#ifdef ATOM_INIT_PROFILE
/// Logs top 50 slowest Initialize() types by cumulative time to initialize_profile.log
/datum/controller/subsystem/atoms/proc/InitProfileLog()
	if(!length(init_type_times))
		return null
	. = "--- SSatoms Initialize() Profile (top 100 by cumulative time) ---\n"
	. += "Format: total_ms | count | avg_ms : type\n\n"
	var/list/profiled = init_type_times.Copy()
	var/remaining = min(100, length(profiled))
	while(remaining--)
		var/slowest = null
		var/max_t = -1
		for(var/k in profiled)
			if(profiled[k] > max_t)
				max_t = profiled[k]
				slowest = k
		if(isnull(slowest))
			break
		var/cnt = init_type_counts[slowest]
		. += "  [max_t * 100]ms | [cnt]x | avg [round(max_t * 100 / cnt, 0.01)]ms : [slowest]\n"
		profiled.Remove(slowest)
#endif // ATOM_INIT_PROFILE

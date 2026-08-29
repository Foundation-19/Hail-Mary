SUBSYSTEM_DEF(icon_smooth)
	name = "Icon Smoothing"
	init_order = INIT_ORDER_ICON_SMOOTHING
	wait = 1
	priority = FIRE_PRIOTITY_SMOOTHING
	flags = SS_TICKER

	var/list/smooth_queue = list()
	var/list/deferred = list()

/datum/controller/subsystem/icon_smooth/fire()
	var/list/cached = smooth_queue
	while(cached.len)
		var/atom/A = cached[cached.len]
		cached.len--
		if (A.flags_1 & INITIALIZED_1)
			smooth_icon(A)
		else
			deferred += A
		if (MC_TICK_CHECK)
			return

	if (!cached.len)
		if (deferred.len)
			smooth_queue = deferred
			deferred = cached
		else
			can_fire = 0

/datum/controller/subsystem/icon_smooth/Initialize()
	// OPTIMIZATION: All smoothable atoms call queue_smooth(src) in their own Initialize().
	// smooth_queue is already populated. Skip the synchronous smooth_zlevel() passes and
	// queue processing here — fire() (wait=1) will drain the queue within seconds post-init.
	return ..()

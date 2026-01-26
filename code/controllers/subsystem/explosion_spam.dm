SUBSYSTEM_DEF(explosion_spam)
	name = "Explosion Spam Controller"
	wait = 1
	priority = FIRE_PRIORITY_DEFAULT - 5
	flags = SS_NO_INIT
	
	var/list/queued_explosions = list()
	var/max_per_tick = 2 // Process max 2 explosions per tick to prevent lag
	var/spam_mode = FALSE
	var/spam_threshold = 10 // Enter spam mode if queue exceeds this
	
/datum/controller/subsystem/explosion_spam/stat_entry(msg)
	msg = "Q:[queued_explosions.len]"
	if(spam_mode)
		msg += " SPAM"
	return ..()

/datum/controller/subsystem/explosion_spam/fire(resumed = FALSE)
	// Check if we're in spam mode
	spam_mode = (queued_explosions.len > spam_threshold)
	
	var/processed = 0
	while(queued_explosions.len && processed < max_per_tick)
		var/datum/queued_explosion/E = queued_explosions[1]
		queued_explosions.Cut(1, 2)
		
		if(E.source && QDELETED(E.source))
			E.source = null

		// Execute the explosion
		if(spam_mode)
			// Reduced effects during spam
			explosion(E.epicenter, E.devastation * 0.7, E.heavy * 0.7, E.light * 0.7, E.flash * 0.5, flame_range = E.flame_range * 0.5, adminlog = FALSE)
		else
			// Full explosion
			explosion(E.epicenter, E.devastation, E.heavy, E.light, E.flash, flame_range = E.flame_range, adminlog = E.adminlog)
		
		qdel(E)
		processed++

/datum/controller/subsystem/explosion_spam/proc/queue_explosion(turf/epicenter, devastation, heavy, light, flash = 0, flame_range = 0, obj/source, adminlog = TRUE)
	if(!epicenter)
		return FALSE
	
	var/datum/queued_explosion/E = new()
	E.epicenter = epicenter
	E.devastation = devastation
	E.heavy = heavy
	E.light = light
	E.flash = flash
	E.flame_range = flame_range
	E.source = source
	E.adminlog = adminlog
	E.queued_time = world.time
	
	queued_explosions += E
	return TRUE

/datum/queued_explosion
	var/turf/epicenter
	var/devastation = 0
	var/heavy = 0
	var/light = 0
	var/flash = 0
	var/flame_range = 0
	var/obj/source
	var/adminlog = TRUE
	var/queued_time = 0

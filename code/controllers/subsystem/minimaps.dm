SUBSYSTEM_DEF(minimaps)
	name = "Minimaps"
	flags = SS_NO_FIRE
	var/list/station_minimaps = list()
	var/datum/minimap_group/station_minimap = null
	// Mobs that asked to see the map before it finished baking -- notified/auto-opened once ready.
	var/list/mob/waiting_for_map = list()

/datum/controller/subsystem/minimaps/Initialize()
	if(!CONFIG_GET(flag/minimaps_enabled))
		to_chat(world, span_boldwarning("Minimaps disabled! Skipping init."))
		return ..()
	addtimer(CALLBACK(src, PROC_REF(build_minimaps)), 0)
	return ..()

/datum/controller/subsystem/minimaps/proc/build_minimaps()
	// Single source of truth so the fallback level name and the group label can't drift apart.
	var/generic_label = "World Map"
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/datum/space_level/SL = SSmapping.get_level(z)
		var/name = (SL.name == initial(SL.name))? "[z] - [generic_label]" : "[z] - [SL.name]"
		station_minimaps += new /datum/minimap(z, name = name)

	station_minimap = new(station_minimaps, generic_label)

	for(var/mob/M in waiting_for_map)
		if(M.client)
			to_chat(M, span_boldnotice("World Map generation complete! Opening..."))
			station_minimap.ui_interact(M)
	waiting_for_map = list()

///Finds the baked minimap for a given z-level, or null if that z has none (or minimaps aren't built yet).
/datum/controller/subsystem/minimaps/proc/get_minimap_for_z(z)
	for(var/datum/minimap/M in station_minimaps)
		if(M.z_level == z)
			return M
	return null

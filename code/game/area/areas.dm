// Areas.dm

/// so we dont have to initialize a sound loop datum for every fucking area in the game
/// might have the sound effect that everyone hears the same sound at once, hopefully
GLOBAL_LIST_EMPTY(area_sound_loops)

/// List of weather tags and their respective areas
GLOBAL_LIST_INIT(area_weather_list, list(WEATHER_ALL))

/area
	level = null
	name = "Space"
	icon = 'icons/turf/areas.dmi'
	icon_state = "unknown"
	layer = AREA_LAYER
	plane = BLACKNESS_PLANE //Keeping this on the default plane, GAME_PLANE, will make area overlays fail to render on FLOOR_PLANE.
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_LIGHTING

	/// Set in New(); preserves the name set by the map maker, even if renamed by the Blueprints.
	var/map_name

	/// If it's valid territory for gangs/cults to summon
	var/valid_territory = TRUE
	/// malf ais can hack this
	var/valid_malf_hack = TRUE
	/// if blobs can spawn there and if it counts towards their score.
	var/blob_allowed = TRUE
	/// whether servants can warp into this area from Reebe
	var/clockwork_warp_allowed = TRUE
	/// Message to display when the clockwork warp fails
	var/clockwork_warp_fail = "The structure there is too dense for warping to pierce. (This is normal in high-security areas.)"

	/// If mining tunnel generation is allowed in this area
	var/tunnel_allowed = FALSE
	/// If flora are allowed to spawn in this area randomly through tunnel generation
	var/flora_allowed = FALSE
	/// if mobs can be spawned by natural random generation
	var/mob_spawn_allowed = FALSE
	/// If megafauna can be spawned by natural random generation
	var/megafauna_spawn_allowed = FALSE

	/// Considered space for hull shielding
	var/considered_hull_exterior = FALSE

	var/fire = null
	var/atmos = TRUE
	var/atmosalm = FALSE
	var/poweralm = TRUE
	var/lightswitch = TRUE

	var/totalbeauty = 0 //All beauty in this area combined, only includes indoor area.
	var/beauty = 0 // Beauty average per open turf in the area
	var/beauty_threshold = 150 //If a room is too big it doesn't have beauty.

	var/requires_power = TRUE
	/// This gets overridden to 1 for space in area/Initialize().
	var/always_unpowered = FALSE

	/// For space, the asteroid, lavaland, etc. Used with blueprints to determine if we are adding a new area (vs editing a station room)
	var/outdoors = FALSE

	/// What weathers affect this area? If null, no weathers happen here, shrimple as
	var/list/weather_tags = list()

	/// Size of the area in open turfs, only calculated for indoors areas.
	var/areasize = 0

	var/power_equip = TRUE
	var/power_light = TRUE
	var/power_environ = TRUE
	var/music = null
	var/used_equip = 0
	var/used_light = 0
	var/used_environ = 0
	var/static_equip
	var/static_light = 0
	var/static_environ

	var/has_gravity = 0
	/// Are you forbidden from teleporting to the area? (centcom, mobs, wizard, hand teleporter)
	var/noteleport = FALSE
	/// Hides area from player Teleport function.
	var/hidden = FALSE
	/// Is the area teleport-safe: no space / radiation / aggresive mobs / other dangers
	var/safe = FALSE
	/// If false, loading multiple maps with this area type will create multiple instances.
	var/unique = TRUE

	var/no_air = null

	var/parallax_movedir = 0

	var/open_space = 0

	/// List of music to play. FORMAT: AREA_MUSIC('sound/file.ogg, sound length)
	// var/list/ambientmusic = list(
	//	AREA_MUSIC('sound/misc/sadtrombone.ogg', 3.9 SECONDS)
	//	)
	var/list/ambientmusic

	/// List of sounds to play. FORMAT: list(AREA_SOUND('sound/misc/sadtrombone.ogg', 3.9 SECONDS), AREA_MUSIC('sound/misc/sadtrombone.ogg', 3.9 SECONDS)) has a cooldown of 3 seconds between each play, but you can have sounds play for longer if you want
	//var/list/ambientsounds = list(
	//	AREA_SOUND('sound/misc/server-ready.ogg', 1 SECONDS),
	//	AREA_SOUND('sound/misc/splort.ogg', 0.5 SECONDS)	
	//	)
	var/list/ambientsounds

	/// Sound loop datums full of ambient sounds to play, refer to code\datums\looping_sounds\ambient_sounds.dm!
	//var/list/ambience_area = list(
	//	/datum/looping_sound/ambient/debug,
	//	/datum/looping_sound/ambient/debug2
	//)
	var/list/ambience_area
	var/environment = -1
	var/grow_chance = 100
	flags_1 = CAN_BE_DIRTY_1

	var/list/firedoors
	var/list/cameras
	var/list/firealarms
	var/firedoors_last_closed_on = 0
	var/xenobiology_compatible = FALSE //Can the Xenobio management console transverse this area by default?
	var/list/canSmoothWithAreas //typecache to limit the areas that atoms in this area can smooth with


	/// Color on minimaps, if it's null (which is default) it makes one at random.
	var/minimap_color

/**
 * These two vars allow for multiple unique areas to be linked to a master area
 * and share some functionalities such as APC powernet nodes, fire alarms etc, without sacrificing
 * their own flags, statuses, variables and more snowflakes.
 * Friendly reminder: no map edited areas.
 */
	var/list/area/sub_areas //list of typepaths of the areas you wish to link here, will be replaced with a list of references on mapload.
	var/area/base_area //The area we wish to use in place of src for certain actions such as APC area linking.

	var/nightshift_public_area = NIGHTSHIFT_AREA_NONE		//considered a public area for nightshift

	///Used to decide what kind of reverb the area makes sound have
	var/sound_environment = SOUND_ENVIRONMENT_NONE

	///How much radiation to give to every player in this area, per tick
	var/rads_per_second

/*Adding a wizard area teleport list because motherfucking lag -- Urist*/
/*I am far too lazy to make it a proper list of areas so I'll just make it run the usual telepot routine at the start of the game*/
GLOBAL_LIST_EMPTY(teleportlocs)

/proc/process_teleport_locs()
	for(var/V in GLOB.sortedAreas)
		var/area/AR = V
		if(istype(AR, /area/shuttle) || AR.noteleport)
			continue
		if(GLOB.teleportlocs[AR.name])
			continue
		if (!AR.contents.len)
			continue
		var/turf/picked = AR.contents[1]
		if (picked && is_station_level(picked.z))
			GLOB.teleportlocs[AR.name] = AR

	sortTim(GLOB.teleportlocs, GLOBAL_PROC_REF(cmp_text_dsc))

// ===

/area/New()
	if(!minimap_color) // goes in New() because otherwise it doesn't fucking work
		// generate one using the icon_state
		if(icon_state && icon_state != "unknown")
			var/icon/I = new(icon, icon_state, dir)
			I.Scale(1,1)
			minimap_color = I.GetPixel(1,1)
		else // no icon state? use random.
			minimap_color = rgb(rand(50,70),rand(50,70),rand(50,70))	// This interacts with the map loader, so it needs to be set immediately
	// rather than waiting for atoms to initialize.
	if (unique)
		GLOB.areas_by_type[type] = src
	return ..()

/area/Initialize()
	icon_state = ""
	layer = AREA_LAYER
	map_name = name // Save the initial (the name set in the map) name of the area.
	canSmoothWithAreas = typecacheof(canSmoothWithAreas)

	if(requires_power)
		luminosity = 0
	else
		power_light = TRUE
		power_equip = TRUE
		power_environ = TRUE

		if(dynamic_lighting == DYNAMIC_LIGHTING_FORCED)
			dynamic_lighting = DYNAMIC_LIGHTING_ENABLED
			luminosity = 0
		else if(dynamic_lighting != DYNAMIC_LIGHTING_IFSTARLIGHT)
			dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	if(dynamic_lighting == DYNAMIC_LIGHTING_IFSTARLIGHT)
		dynamic_lighting = CONFIG_GET(flag/starlight) ? DYNAMIC_LIGHTING_ENABLED : DYNAMIC_LIGHTING_DISABLED

	. = ..()

	blend_mode = BLEND_MULTIPLY // Putting this in the constructor so that it stops the icons being screwed up in the map editor.

	if(!IS_DYNAMIC_LIGHTING(src))
		add_overlay(/obj/effect/fullbright)

	reg_in_areas_in_z()

	initialize_soundloop()

	initialize_weather_list()

	//so far I'm only implementing it on mapped unique areas, it's easier this way.
	if(unique && sub_areas)
		if(type in sub_areas)
			WARNING("\"[src]\" typepath found inside its own sub-areas list, please make sure it doesn't share its parent type initial sub-areas value.")
			sub_areas = null
		else
			var/paths = sub_areas.Copy()
			sub_areas = null
			for(var/type in paths)
				var/area/A = GLOB.areas_by_type[type]
				if(!A) //By chance an area not loaded in the current world, no warning report.
					continue
				if(A == src)
					WARNING("\"[src]\" area a attempted to link with itself.")
					continue
				if(A.base_area)
					WARNING("[src] attempted to link with [A] while the latter is already linked to another area ([A.base_area]).")
					continue
				LAZYADD(sub_areas, A)
				A.base_area = src
	else if(LAZYLEN(sub_areas))
		WARNING("sub-areas are currently not supported for non-unique areas such as [src].")
		sub_areas = null

	return INITIALIZE_HINT_LATELOAD

/area/LateInitialize()
	if(!base_area) //we don't want to run it twice.
		power_change()		// all machines set to current power level, also updates icon
	update_beauty()

/area/ComponentInitialize()
	. = ..()
	if(rads_per_second)
		AddComponent(/datum/component/radiation_area, rads_per_second)

/area/proc/reg_in_areas_in_z()
	if(contents.len)
		var/list/areas_in_z = SSmapping.areas_in_z
		var/z
		update_areasize()
		for(var/i in 1 to contents.len)
			var/atom/thing = contents[i]
			if(!thing)
				continue
			z = thing.z
			break
		if(!z)
			WARNING("No z found for [src]")
			return
		if(!areas_in_z["[z]"])
			areas_in_z["[z]"] = list()
		areas_in_z["[z]"] += src

/area/Destroy()
	if(GLOB.areas_by_type[type] == src)
		GLOB.areas_by_type[type] = null
	if(base_area)
		LAZYREMOVE(base_area, src)
		base_area = null
	if(sub_areas)
		for(var/i in sub_areas)
			var/area/A = i
			A.base_area = null
			sub_areas -= A
			if(A.requires_power)
				A.power_light = FALSE
				A.power_equip = FALSE
				A.power_environ = FALSE
			INVOKE_ASYNC(A, PROC_REF(power_change))
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(ambience_area)
	remove_from_weather_list()
	return ..()

/area/proc/initialize_soundloop()
	if(!islist(ambience_area))
		ambience_area = null
		return FALSE
	for(var/loopy in ambience_area)
		if(!ispath(loopy, /datum/looping_sound))
			ambience_area -= loopy
			continue
		/// First one to use a sound loop initializes it
		if(!(loopy in GLOB.area_sound_loops))
			GLOB.area_sound_loops[loopy] = new loopy(list(), FALSE)

/// Adds the area to a list for weather to read when picking areas for weather
/area/proc/initialize_weather_list()
	if(!weather_tags || !LAZYLEN(weather_tags) || isnull(weather_tags))
		return FALSE
	for(var/wethertag in weather_tags)
		if(!islist(GLOB.area_weather_list[wethertag]))
			GLOB.area_weather_list[wethertag] = list()
		GLOB.area_weather_list[wethertag] |= src

/// unAdds the area to a list for weather to read when picking areas for weather
/area/proc/remove_from_weather_list()
	if(!weather_tags || !LAZYLEN(weather_tags) || isnull(weather_tags))
		return FALSE
	for(var/unweather in weather_tags)
		GLOB.area_weather_list[unweather] -= src

/area/proc/poweralert(state, obj/source)
	if (state != poweralm)
		poweralm = state
		if(istype(source))	//Only report power alarms on the z-level where the source is located.
			for (var/item in GLOB.silicon_mobs)
				var/mob/living/silicon/aiPlayer = item
				if (state == 1)
					aiPlayer.cancelAlarm("Power", src, source)
				else
					aiPlayer.triggerAlarm("Power", src, cameras, source)

			for (var/item in GLOB.alert_consoles)
				var/obj/machinery/computer/station_alert/a = item
				if(state == 1)
					a.cancelAlarm("Power", src, source)
				else
					a.triggerAlarm("Power", src, cameras, source)

			for (var/item in GLOB.drones_list)
				var/mob/living/simple_animal/drone/D = item
				if(state == 1)
					D.cancelAlarm("Power", src, source)
				else
					D.triggerAlarm("Power", src, cameras, source)
			for(var/item in GLOB.alarmdisplay)
				var/datum/computer_file/program/alarm_monitor/p = item
				if(state == 1)
					p.cancelAlarm("Power", src, source)
				else
					p.triggerAlarm("Power", src, cameras, source)

/area/proc/atmosalert(danger_level, obj/source)
	if(danger_level != atmosalm)
		if (danger_level==2)

			for (var/item in GLOB.silicon_mobs)
				var/mob/living/silicon/aiPlayer = item
				aiPlayer.triggerAlarm("Atmosphere", src, cameras, source)
			for (var/item in GLOB.alert_consoles)
				var/obj/machinery/computer/station_alert/a = item
				a.triggerAlarm("Atmosphere", src, cameras, source)
			for (var/item in GLOB.drones_list)
				var/mob/living/simple_animal/drone/D = item
				D.triggerAlarm("Atmosphere", src, cameras, source)
			for(var/item in GLOB.alarmdisplay)
				var/datum/computer_file/program/alarm_monitor/p = item
				p.triggerAlarm("Atmosphere", src, cameras, source)

		else if (src.atmosalm == 2)
			for (var/item in GLOB.silicon_mobs)
				var/mob/living/silicon/aiPlayer = item
				aiPlayer.cancelAlarm("Atmosphere", src, source)
			for (var/item in GLOB.alert_consoles)
				var/obj/machinery/computer/station_alert/a = item
				a.cancelAlarm("Atmosphere", src, source)
			for (var/item in GLOB.drones_list)
				var/mob/living/simple_animal/drone/D = item
				D.cancelAlarm("Atmosphere", src, source)
			for(var/item in GLOB.alarmdisplay)
				var/datum/computer_file/program/alarm_monitor/p = item
				p.cancelAlarm("Atmosphere", src, source)

		atmosalm = danger_level
		for(var/i in sub_areas)
			var/area/A = i
			A.atmosalm = danger_level
		return TRUE
	return FALSE

/area/proc/ModifyFiredoors(opening)
	if(firedoors)
		firedoors_last_closed_on = world.time
		for(var/FD in firedoors)
			var/obj/machinery/door/firedoor/D = FD
			var/cont = !D.welded
			if(cont && opening)	//don't open if adjacent area is on fire
				for(var/I in D.affecting_areas)
					var/area/A = I
					if(A.fire)
						cont = FALSE
						break
			if(cont && D.is_operational())
				if(D.operating)
					D.nextstate = opening ? FIREDOOR_OPEN : FIREDOOR_CLOSED
				else if(!(D.density ^ opening))
					INVOKE_ASYNC(D, (opening ? TYPE_PROC_REF(/obj/machinery/door/firedoor, open) : TYPE_PROC_REF(/obj/machinery/door/firedoor, close)))

/area/proc/firealert(obj/source)
	if(always_unpowered == 1) //no fire alarms in space/asteroid
		return

	if (!fire)
		set_fire_alarm_effects(TRUE)
		ModifyFiredoors(FALSE)

	for (var/item in GLOB.alert_consoles)
		var/obj/machinery/computer/station_alert/a = item
		a.triggerAlarm("Fire", src, cameras, source)
	for (var/item in GLOB.silicon_mobs)
		var/mob/living/silicon/aiPlayer = item
		aiPlayer.triggerAlarm("Fire", src, cameras, source)
	for (var/item in GLOB.drones_list)
		var/mob/living/simple_animal/drone/D = item
		D.triggerAlarm("Fire", src, cameras, source)
	for(var/item in GLOB.alarmdisplay)
		var/datum/computer_file/program/alarm_monitor/p = item
		p.triggerAlarm("Fire", src, cameras, source)

	START_PROCESSING(SSobj, src)

/area/proc/firereset(obj/source)
	if (fire)
		set_fire_alarm_effects(FALSE)
		ModifyFiredoors(TRUE)

	for (var/item in GLOB.silicon_mobs)
		var/mob/living/silicon/aiPlayer = item
		aiPlayer.cancelAlarm("Fire", src, source)
	for (var/item in GLOB.alert_consoles)
		var/obj/machinery/computer/station_alert/a = item
		a.cancelAlarm("Fire", src, source)
	for (var/item in GLOB.drones_list)
		var/mob/living/simple_animal/drone/D = item
		D.cancelAlarm("Fire", src, source)
	for(var/item in GLOB.alarmdisplay)
		var/datum/computer_file/program/alarm_monitor/p = item
		p.cancelAlarm("Fire", src, source)

	STOP_PROCESSING(SSobj, src)

/area/process()
	if(firedoors_last_closed_on + 100 < world.time)	//every 10 seconds
		ModifyFiredoors(FALSE)

/area/proc/close_and_lock_door(obj/machinery/door/DOOR)
	set waitfor = FALSE
	DOOR.close()
	if(DOOR.density)
		DOOR.lock()

/area/proc/burglaralert(obj/trigger)
	if(always_unpowered) //no burglar alarms in space/asteroid
		return

	//Trigger alarm effect
	set_fire_alarm_effects(TRUE)
	//Lockdown airlocks
	for(var/obj/machinery/door/DOOR in get_sub_areas_contents(src))
		close_and_lock_door(DOOR)

	for (var/i in GLOB.silicon_mobs)
		var/mob/living/silicon/SILICON = i
		if(SILICON.triggerAlarm("Burglar", src, cameras, trigger))
			//Cancel silicon alert after 1 minute
			addtimer(CALLBACK(SILICON, TYPE_PROC_REF(/mob/living/silicon,cancelAlarm),"Burglar",src,trigger), 600)

/area/proc/set_fire_alarm_effects(boolean)
	fire = boolean
	for(var/i in sub_areas)
		var/area/A = i
		A.fire = boolean
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	for(var/alarm in firealarms)
		var/obj/machinery/firealarm/F = alarm
		F.update_fire_light(fire)
		F.update_icon()
	for(var/obj/machinery/light/L in get_sub_areas_contents(src))
		L.update()

/area/proc/updateicon()
/**
 * Update the icon state of the area
 *
 * Im not sure what the heck this does, somethign to do with weather being able to set icon
 * states on areas?? where the heck would that even display?
 */
/area/update_icon_state()
	var/weather_icon
	for(var/V in SSweather.processing)
		var/datum/weather/W = V
		if(W.stage != END_STAGE && (src in W.impacted_areas))
			W.update_areas()
			weather_icon = TRUE
	if(!weather_icon)
		icon_state = null

/**
 * Update the icon of the area (overridden to always be null for space
 */
/area/space/update_icon_state()
	icon_state = null

/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(chan)		// return true if the area has power to given channel

	if(!requires_power)
		return 1
	if(always_unpowered)
		return 0
	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ

	return 0

/area/space/powered(chan) //Nope.avi
	return 0

// called when power status changes

/area/proc/power_change()
	for(var/obj/machinery/M in src)	// for each machine in the area
		M.power_change()				// reverify power status (to update icons etc.)
	if(sub_areas)
		for(var/i in sub_areas)
			var/area/A = i
			A.power_light = power_light
			A.power_equip = power_equip
			A.power_environ = power_environ
			INVOKE_ASYNC(A, PROC_REF(power_change))
	update_icon()

/area/proc/usage(chan)
	switch(chan)
		if(LIGHT)
			. += used_light
		if(EQUIP)
			. += used_equip
		if(ENVIRON)
			. += used_environ
		if(TOTAL)
			. += used_light + used_equip + used_environ
		if(STATIC_EQUIP)
			. += static_equip
		if(CHANNEL_STATIC_LIGHT)
			. += static_light
		if(STATIC_ENVIRON)
			. += static_environ
	if(sub_areas)
		for(var/i in sub_areas)
			var/area/A = i
			. += A.usage(chan)

/area/proc/addStaticPower(value, powerchannel)
	switch(powerchannel)
		if(STATIC_EQUIP)
			static_equip += value
		if(CHANNEL_STATIC_LIGHT)
			static_light += value
		if(STATIC_ENVIRON)
			static_environ += value

/area/proc/clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0
	if(sub_areas)
		for(var/i in sub_areas)
			var/area/A = i
			A.clear_usage()

/area/proc/use_power(amount, chan)

	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount


/area/Entered(atom/movable/M, atom/OldLoc)
	set waitfor = FALSE
	SEND_SIGNAL(src, COMSIG_AREA_ENTERED, M)
	SEND_SIGNAL(M, COMSIG_ENTER_AREA, src) //The atom that enters the area
	if(!isliving(M))
		return

	var/mob/living/L = M
	var/turf/oldTurf = get_turf(OldLoc)
	var/area/A = oldTurf?.loc
	if(A && (A.has_gravity != has_gravity))
		L.update_gravity(L.mob_has_gravity())

	if(!L.ckey)
		return

	// Ambience goes down here -- make sure to list each area separately for ease of adding things in later, thanks! Note: areas adjacent to each other should have the same sounds to prevent cutoff when possible.- LastyScratch
	if(L.client && L.client.prefs.toggles & SOUND_SHIP_AMBIENCE)
		if(islist(ambience_area))
			addremove_to_soundloop(L, TRUE)

		if(LAZYLEN(ambientsounds) && !COOLDOWN_TIMELEFT(L.client, area_sound_effect_cooldown) && prob(35))
			var/sounds_to_play = pick(ambientsounds)
			var/sound_delay = rand(1 SECONDS, 15 SECONDS)
			var/sound/S = sound(sounds_to_play[SL_FILE_PATH], repeat = 0, wait = 0, volume = 25, channel = SSsounds.random_available_channel())
			addtimer(CALLBACK(src, PROC_REF(play_ambient_sound_delayed), S, L), sound_delay, TIMER_STOPPABLE)
			COOLDOWN_START(L.client, area_sound_effect_cooldown, sounds_to_play[SL_FILE_LENGTH] + sound_delay)

		if(LAZYLEN(ambientmusic) && !COOLDOWN_TIMELEFT(L.client, area_music_cooldown) && prob(35)) //fortuna add. re-implements ambient music
			var/music_to_play = pick(ambientmusic)
			var/sound_delay = rand(1 SECONDS, 15 SECONDS)
			var/sound/S = sound(music_to_play[SL_FILE_PATH], repeat = 0, wait = 0, volume = 25, channel = SSsounds.random_available_channel())
			addtimer(CALLBACK(src, PROC_REF(play_ambient_sound_delayed), S, L), sound_delay, TIMER_STOPPABLE)
			COOLDOWN_START(L.client, area_music_cooldown, music_to_play[SL_FILE_LENGTH] + sound_delay)

/area/proc/play_ambient_sound_delayed(sound/to_play, mob/living/play_to)
	SEND_SOUND(play_to, to_play)

/area/proc/addremove_to_soundloop(mob/living/player, add = TRUE)
	if(!ambience_area)
		return
	if(!islist(ambience_area))
		ambience_area = null
		return
	if(!isliving(player))
		return
	for(var/loopy in ambience_area)
		var/datum/looping_sound/our_loop = GLOB.area_sound_loops[loopy]
		if(!istype(our_loop))
			initialize_soundloop()
			our_loop = GLOB.area_sound_loops[loopy]
			if(!istype(our_loop)) // STILL??
				ambience_area -= loopy // prevent this from happening ever again!!
				continue
		if(add)
			our_loop.start(player)
		else
			our_loop.stop(player, kill = FALSE)

///Divides total beauty in the room by roomsize to allow us to get an average beauty per tile.
/area/proc/update_beauty()
	if(!areasize)
		beauty = 0
		return FALSE
	if(areasize >= beauty_threshold)
		beauty = 0
		return FALSE //Too big
	beauty = totalbeauty / areasize

/area/Exited(atom/movable/M)
	SEND_SIGNAL(src, COMSIG_AREA_EXITED, M)
	SEND_SIGNAL(M, COMSIG_EXIT_AREA, src) //The atom that exits the area
	addremove_to_soundloop(M, FALSE)

/area/proc/setup(a_name)
	name = a_name
	power_equip = FALSE
	power_light = FALSE
	power_environ = FALSE
	always_unpowered = FALSE
	valid_territory = FALSE
	valid_malf_hack = FALSE
	blob_allowed = FALSE
	addSorted()

/area/proc/update_areasize()
	if(outdoors)
		return FALSE
	areasize = 0
	for(var/turf/open/T in contents)
		areasize++

/area/AllowDrop()
	CRASH("Bad op: area/AllowDrop() called")

/area/drop_location()
	CRASH("Bad op: area/drop_location() called")

// A hook so areas can modify the incoming args
/area/proc/PlaceOnTopReact(list/new_baseturfs, turf/fake_turf_type, flags)
	return flags


// ==================== Merged from fallout (code\modules\fallout\code\modules\mapping\areas.dm) ====================
/area/f13/village/tunnel_motel
	name = "Rockspring - Tunnel Motel"

/area/f13/village/tunnel_diner
	name = "Rockspring - Tunnel Diner"

/area/f13/village/overpass_village
	name = "Overpass Village - Upper"

/area/f13/village/overpass_lower
	name = "Overpass Village - Lower"

/area/f13/village/tunnel_reststop
	name = "Rockspring - Tunnel Rest Stop"

/area/f13/village/overpass_trailer
	name = "Overpass Village - Trailer"

/area/f13/building/firetower
	name = "Building - Firetower Upper"

/area/f13/building/lower_firetower
	name = "Building - Firetower Lower"

/area/f13/building/tunnel
	name = "Rocksprings - Tunnel"

/area/f13/wasteland/west/lower_firetower
	name = "Rocksprings - Firetower Lower"


// ==================== Merged from fallout (areas/area.dm) ====================
//Fallout 13 specific areas directory

/area

/area/f13
	name = "error"
	icon_state = "error"
	has_gravity = 1
	// Indoor F13 areas start unpowered.  A faction_generator must cover this area
	// (via powered_area_types) and be running for machines here to function.
	// Outdoor/wasteland areas define requires_power = FALSE, which causes
	// area/Initialize() to set power_equip/light/environ back to TRUE for them.
	power_equip  = FALSE
	power_light  = FALSE
	power_environ = FALSE
	/// Mirrors power_equip — tracks whether a generator is actively supplying this area.
	/// Updated automatically by the power_change() override below.
	var/f13_grid_power = FALSE
	/// When TRUE, junction boxes will never stamp this area's power state.
	/// The outdoors flag also triggers this guard automatically.
	/// Set explicitly on any area that manages its own power or should always be on.
	var/f13_grid_immune = FALSE
	/// Runtime flag set by the junction box system on dynamically-allocated
	/// flood-fill zone datums.  Never set by mappers.  Checked during flood fill
	/// to prevent two boxes from merging each other's physical zones.
	var/f13_jbox_zone = FALSE

/// Keep f13_grid_power in sync with the actual SS13 equip-channel state.
/// Also explicitly notify any door/access buttons inside or adjacent to this area.
/// F13 areas have no APC, so buttons are never iterated by the normal
/// machinery-notification path — we must push the update ourselves.

// f13 power state is set by junction boxes post-init; skip power_change on all f13 areas.
/area/f13/LateInitialize()
	if(!GLOB.f13_magic_power)
		power_equip   = FALSE
		power_light   = FALSE
		power_environ = FALSE
	update_beauty()

/area/f13/power_change()
	set background = 1
	f13_grid_power = power_equip
	// Notify buttons on any turf (open or closed) WITHIN this area.
	for(var/obj/machinery/button/B in src)
		B.power_change()
	// Sweep closed (wall) tiles adjacent to this area and notify buttons there.
	// Wall tiles are frequently in /area/space or a parent f13 area type rather
	// than the stamped subzone, so they are not reachable by the loop above.
	// Skipped for outdoor areas — they have no enclosed walls and iterating
	// thousands of wasteland tiles here would stall the server.
	if(!outdoors)
		var/list/swept = list()
		for(var/turf/T in src)
			for(var/dir in GLOB.alldirs)
				var/turf/W = get_step(T, dir)
				if(!W || swept[W] || !isclosedturf(W))
					continue
				swept[W] = TRUE
				var/area/WA = get_area(W)
				if(istype(WA, /area/space) || (istype(WA, /area/f13) && WA != src))
					for(var/obj/machinery/button/B in W)
						B.power_change()
	return ..()

//Wasteland generic areas

//Ambigen sound tips for ambientsounds: 
//1 - 2 : outside the ruined buildings, 
//3 - 9 : inside the wasteland buildings,
// 10 - 14 : vaults and bunkers specific, 
//15-19 : caves
//These were defined a long time ago, but we may still consider using them with our new ambient sound system ~TK

///////////////
//C O Y O T E//
//B A Y O U  //
//  AMBIENT  //
//   AREAS   //
///////////////
/area/f13/wasteland
	name = "Wasteland"
	icon_state = "wasteland"
	ambience_area = list(
		/datum/looping_sound/ambient/critters,
		/datum/looping_sound/ambient/critters/birds,
		/datum/looping_sound/ambient/critters/birds/crow,
		/datum/looping_sound/ambient/critters/frogs,
		/datum/looping_sound/ambient/forest,
	)
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 19
	grow_chance = 45
	weather_tags = list(WEATHER_ALL)

/area/f13/wasteland/powered
	requires_power = FALSE

/area/f13/wasteland/cold
	icon_state = "wastelandcold"

/// Consistently-named powered variant — use this for new maps.
/area/f13/wasteland/cold/powered
	requires_power = FALSE

/// Legacy alias kept for Tipton map compatibility.  Do not use for new maps.
/area/f13/wasteland/cold/power
	requires_power = FALSE

/area/f13/Ocean
	name = "Ocean"
	icon_state = "blue"
	ambience_area = list(
		/datum/looping_sound/ambient/ocean_b,
		)
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 0
	grow_chance = 0
	weather_tags = list(WEATHER_ALL)

/area/f13/wasteland/city
	name = "Ruined City Coast"
	icon_state = "city"
	ambience_area = list(
		/datum/looping_sound/ambient/ocean_a,
		)
	ambientmusic = list('sound/f13music/thecoastpart1fo4.ogg')
	grow_chance = 45
	environment = 10

/area/f13/wasteland/city/citycenter
	name = "Ruined Center City"
	icon_state = "citycaves"
	ambience_area = list(
		/datum/looping_sound/ambient/critters,
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/critters/birds,
		/datum/looping_sound/ambient/critters/birds/crow,
		)
	ambientmusic = list('sound/f13music/nomoresailsfo4.ogg')
	grow_chance = 45
	environment = 10

/area/f13/wasteland/town
	name = "Town"
	icon_state = "green"
	ambience_area = list(
		/datum/looping_sound/ambient/harbor_b,
		)
	ambientmusic = list('sound/f13music/endlessoceanfo4.ogg')
	grow_chance = 5


/area/f13/building
	name = "Building"
	icon_state = "building"
	ambience_area = list(
		/datum/looping_sound/ambient/harbor_interior,
		)
	weather_tags = null
	outdoors = FALSE

/area/f13/building/center
	name = "Ruined city center Building"
	icon_state = "yellow"
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/woodcreak,
		/datum/looping_sound/ambient/lightbulb,
		)
	weather_tags = null
	outdoors = FALSE

/area/f13/building/boat
	name = "Boat"
	icon_state = "red"
	ambience_area = list(
		/datum/looping_sound/ambient/ship_interior,
		)
	weather_tags = null
	outdoors = FALSE

/area/f13/building/abandoned
	name = "Abandoned Building"
	icon_state = "black"
	requires_power = TRUE
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/woodcreak,
		/datum/looping_sound/ambient/lightbulb,
		)

/area/f13/building/hospital
	name = "Hospital Building"
	icon_state = "hospital"
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/woodcreak,
		)
	weather_tags = null

/area/f13/building/church
	name = "Church Building"
	icon_state = "green"
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/woodcreak,
		)

/area/f13/building/tribal
	name = "Tribal Building"
	icon_state = "orange"
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/woodcreak,
		/datum/looping_sound/ambient/torch,
		)

/area/f13/building/tribal/cave
	name = "Tribal Cave"
	icon_state = "purple"
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/woodcreak,
		/datum/looping_sound/ambient/torch,
		/datum/looping_sound/ambient/cave,
		/datum/looping_sound/ambient/swamp/quiet,
		/datum/looping_sound/ambient/critters/birds,
		/datum/looping_sound/ambient/critters/birds/crow,
		)

/area/f13/building/sewers
	name = "Sewers"
	requires_power = TRUE
	icon_state = "blue"
	ambience_area = list(
		/datum/looping_sound/ambient/sewers,
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/steam,
		)
	ambientmusic = null
	grow_chance = 5
	weather_tags = null

/area/f13/building/sewers/powered

/area/f13/sewer/powered

/area/f13/building/powered

/area/f13/caves
	name = "Caves"
	icon_state = "caves"
	requires_power = TRUE
	// Natural cave systems are permanently dark — no junction box should
	// accidentally power them via subtype scanning.  Use /area/f13/caves/powered
	// for any cave space that a mapper intentionally wants on the grid
	// (e.g. a raider generator room), which lets players cut the power
	// strategically by tripping that room's junction box breaker.
	f13_grid_immune = TRUE
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/cave,
		/datum/looping_sound/ambient/tunnel,
	)
	weather_tags = null

/// Cave area intentionally wired to the power grid.
/// Use this for underground bases, raider dens, etc. where cutting
/// the lights is a meaningful tactical option.  Place a junction box
/// inside and wire it to the local generator as normal.
/area/f13/caves/powered
	f13_grid_immune = FALSE

/area/f13/tunnel
	name = "Tunnel"
	icon_state = "tunnel"
	environment = 21
	grow_chance = 25
	ambience_area = list(
		/datum/looping_sound/ambient/general,
		/datum/looping_sound/ambient/cave,
		/datum/looping_sound/ambient/tunnel,
	)
	weather_tags = null

/area/f13/bar
	name = "Bar"
	icon_state = "bar"
	ambience_area = list(
		///datum/looping_sound/ambient/radiomusic,
		///datum/looping_sound/ambient/radiostatic,
		///datum/looping_sound/ambient/djswampass,
		/datum/looping_sound/ambient/woodcreak,
	)
	weather_tags = null

///////////////
//C O Y O T E//
//B A Y O U  //
//  AMBIENT  //
//   AREAS   //
//   END     //
///////////////


/area/f13/wasteland/event
	name = "Wasteland (Event)"

/area/f13/wasteland/east
	name = "Eastern Yuma"
	icon_state = "yumaeast"

/area/f13/wasteland/west
	name = "Western Yuma"
	icon_state = "yumawest"

/area/f13/wasteland/quarry
	name = "Quarry"
	icon_state = "quarry"

/area/f13/wasteland/massfusion
	name = "Mass Fusion Exterior"
	icon_state = "massfusionout"

/area/f13/wasteland/mall
	name = "Yuma Mall Exterior"
	icon_state = "mallex"

/area/f13/wasteland/hospital
	name = "Yuma General Exterior"
	icon_state = "hospitalex"

/area/f13/wasteland/museum
	name = "Museum of Technology Exterior"
	icon_state = "museumex"

/area/f13/wasteland/firestation
	name = "Fire Station Exterior"
	icon_state = "fireex"

/area/f13/wasteland/heaven
	name = "Heaven's Night Exterior"
	icon_state = "heavenex"

/area/f13/wasteland/train
	name = "Train Station Exterior"
	icon_state = "trainex"

/area/f13/wasteland/nanotrasen
	name = "NanoTrasen HQ Exterior"
	icon_state = "nanoex"

/area/f13/wasteland/bighorn
	name = "Bighorn Exterior"
	icon_state = "bighornex"

/area/f13/wasteland/khanfort
	name = "Khan Fortress Exterior"
	icon_state = "khanfortex"

/area/f13/wasteland/followers
	name = "Followers Exterior"
	icon_state = "followersex" //lol

/area/f13/wasteland/bighornbunker
	name = "Bighorn Bunker Exterior"
	icon_state = "bighornbunkerex"

/area/f13/wasteland/ncr
	name = "NCR Outpost Exterior"
	icon_state = "ncrex"

/area/f13/wasteland/legion
	name = "Legion Fortress Exterior"
	icon_state = "legionex"

/area/f13/forest
	name = "Forest"
	icon_state = "forest"
//	ambientmusic = list('sound/f13music/fo2_wasteland.ogg','sound/f13music/fo2_chapel.ogg','sound/f13music/fo2_world.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/bird_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_8.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_3.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 15
	grow_chance = 75
	weather_tags = list(WEATHER_ALL)

/area/f13/ruins
	name = "Ruins"
	icon_state = "ruins"
//	ambientmusic = list('sound/f13music/fo2_ruins.ogg','sound/f13music/fo2_necropolis.ogg','sound/f13music/fo2_raider.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_3.ogg', 10 SECONDS))
	outdoors = 0
	open_space = 1
	blob_allowed = 0
	environment = 5
	grow_chance = 5


/area/f13/shack
	name = "Shack"
	icon_state = "shack"
//	ambientmusic = list('sound/f13music/fo2_ruins.ogg','sound/f13music/fo2_city.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_15.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_16.ogg', 10 SECONDS))
	environment = 2
	grow_chance = 5


//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS))
	environment = 2
	grow_chance = 5

/area/f13/building/massfusion
	name = "Mass Fusion Plant"
	icon_state = "massfusionin"

///area/f13/building/hospital
//	name = "Christus Saint Michaels Hospital"
//	icon_state = "hospital"

/area/f13/building/mall
	name = "Yuma Mall"
	icon_state = "mall"

/area/f13/building/museum
	name = "Museum of Technology"
	icon_state = "museum"

/area/f13/building/firestation
	name = "Fire Station"
	icon_state = "fire"

/area/f13/building/trainstation
	name = "Train Station"
	icon_state = "train"

/area/f13/building/nanotrasen
	name = "NanoTrasen HQ"
	icon_state = "nano"

/area/f13/building/khanfort
	name = "Khan Fortress"
	icon_state = "khanfort"

/area/f13/building/bighornbunker
	name = "Bighorn Bunker"
	icon_state = "bighornbunker"

/area/f13/building/powered

/area/f13/factory
	name = "robco factory"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/cola
	name = "rx cola"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/planetarium
	name = "planetarium"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/potashfarm
	name = "hydroponics"
	icon_state = "farm"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/potashwarehouse
	name = "intrepid warehouse"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/shamanhut
	name = "80s shaman"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/theater
	name = "theater"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/movietheater
	name = "movie theater"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/drivein
	name = "movie theater drive-in"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/casinobasement
	name = "stateline basement"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/casinofloor
	name = "stateline casino"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/darkroom
	name = "dark room"
	icon_state = "building"
//	ambience_area =  list('sound/f13ambience/building.ogg')
//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list('sound/f13ambience/ambigen_3.ogg','sound/f13ambience/ambigen_4.ogg','sound/f13ambience/ambigen_5.ogg', \
	'sound/f13ambience/ambigen_6.ogg','sound/f13ambience/ambigen_7.ogg','sound/f13ambience/ambigen_8.ogg','sound/f13ambience/ambigen_9.ogg')
	environment = 2
	grow_chance = 5

/area/f13/farm
	name = "Farm"
	icon_state = "farm"

//	ambientmusic = list('sound/f13music/fo2_village.ogg','sound/f13music/fo2_wasteland.ogg','sound/f13music/fo2_chapel.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_8.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 15
	grow_chance = 50
	weather_tags = list(WEATHER_ALL)

/area/f13/tribe
	name = "Tribe"
	icon_state = "tribe"

//	ambientmusic = list('sound/f13music/fo2_village.ogg','sound/f13music/fo2_wasteland.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_8.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 15
	grow_chance = 5
	weather_tags = list(WEATHER_ALL)

/area/f13/village
	name = "Village"
	icon_state = "village"

//	ambientmusic = list('sound/f13music/fo2_village.ogg','sound/f13music/fo2_wasteland.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_4.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 15
	grow_chance = 5
	weather_tags = list(WEATHER_ALL)

/area/f13/outpost
	name = "Outpost"
	icon_state = "outpost"

//	ambientmusic = list('sound/f13music/fo2_outpost.ogg','sound/f13music/fo2_brotherhood.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/battle_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/battle_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/battle_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/bird_4.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 16
	grow_chance = 5

/area/f13/hub
	name = "Hub"
	icon_state = "hub"

//	ambientmusic = list('sound/f13music/fo2_hub.ogg','sound/f13music/fo2_village.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_3.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 16
	grow_chance = 5

/area/f13/city
	name = "City"
	icon_state = "city"

//	ambientmusic = list('sound/f13music/fo2_city.ogg','sound/f13music/fo2_hub.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 16
	grow_chance = 5

/area/f13/city/museum
	name = "Museum"
	outdoors = FALSE

/area/f13/city/bighorn
	name = "Bighorn"
	icon_state = "bighorn"

/area/f13/citycaves
	name = "City Caves"
	icon_state = "citycaves"

//	ambientmusic = list('sound/f13music/fo2_city.ogg','sound/f13music/fo2_hub.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_15.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_16.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS))
	environment = 8
	grow_chance = 25

/area/f13/chapel
	name = "Chapel"
	icon_state = "chapel"

//	ambientmusic = list('sound/f13music/fo2_chapel.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/ambience/ambicha1.ogg', 10 SECONDS),
		AREA_SOUND('sound/ambience/ambicha2.ogg', 10 SECONDS),
		AREA_SOUND('sound/ambience/ambicha3.ogg', 10 SECONDS),
		AREA_SOUND('sound/ambience/ambicha4.ogg', 10 SECONDS))
	environment = 5
	grow_chance = 5



//	ambientmusic = list('sound/f13music/fo2_bar.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS))

	environment = 2
	grow_chance = 5

/area/f13/bar/heaven
	name = "Heaven's Night"
	icon_state = "heaven"

/area/f13/casino
	name = "Casino"
	icon_state = "casino"

//	ambientmusic = list('sound/f13music/fo2_bar.ogg','sound/f13music/fo2_raiders.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS))
	environment = 6
	grow_chance = 5

/area/f13/casino/powered

/area/f13/clinic
	name = "Clinic"
	icon_state = "clinic"

//	ambientmusic = list('sound/f13music/fo2_necropolis.ogg','sound/f13music/fo2_ruins.ogg','sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_caves.ogg','sound/f13music/fo2_desert.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_17.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_18.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_19.ogg', 10 SECONDS))
	environment = 6
	grow_chance = 5

/area/f13/office
	name = "Office"
	icon_state = "office"

//	ambientmusic = list('sound/f13music/fo2_city.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS))
	environment = 2
	grow_chance = 5

/area/f13/store
	name = "Store"
	icon_state = "store"

//	ambientmusic = list('sound/f13music/fo2_bar.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS))
	environment = 4
	grow_chance = 5

/area/f13/bunker
	name = "Bunker"
	icon_state = "bunker"

//	ambientmusic = list('sound/f13music/fo2_vats.ogg','sound/f13music/fo2_outpost.ogg','sound/f13music/fo2_ruins.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS))
	environment = 11
	grow_chance = 5

/area/f13/bunker/bunkertwo
	name = "Bunker Two"

/area/f13/bunker/museum
	name = "Bunker Museum"

/area/f13/bunker/bighornbunker
	name = "Bighorn Bunker"
	icon_state = "bighornbunker2"

/area/f13/bunker/bunkerthree
	name = "Bunker Three"

/area/f13/bunker/bunkerfour
	name = "Bunker Four"

/area/f13/bunker/bunkerfive
	name = "Bunker Five"

/area/f13/bunker/bunkersix
	name = "Bunker Six"

/area/f13/bunker/bunkerseven
	name = "Bunker Seven"

/area/f13/bunker/bunkereight
	name = "Bunker Eight"

/area/f13/bunker/bunkernine
	name = "Bunker Nine"

/area/f13/tunnel/northeast
	name = "North-Eastern Tunnel"
	icon_state = "tunnelne"

/area/f13/tunnel/northwest
	name = "North-Western Tunnel"
	icon_state = "tunnelnw"

/area/f13/tunnel/southeast
	name = "South-Eastern Tunnel"
	icon_state = "tunnelse"

/area/f13/tunnel/southwest
	name = "South-Western Tunnel"
	icon_state = "tunnelsw"

/area/f13/tunnel/southeasteastwood
	name = "Eastwood Eastern Sewers"
	icon_state = "tunnelse"

/area/f13/tunnel/southwesteastwood
	name = "Eastwood Western Sewers"
	icon_state = "tunnelsw"

/area/f13/tunnel/sub
	name = "Subway Tunnel"
	icon_state = "tunnelsub"

/area/f13/tunnel/khanfort
	name = "Khan Fortress Tunnel"
	icon_state = "tunnelkhan"

/area/f13/trainstation
	name = "Tunnel"
	icon_state = "tunnel"

//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_caves.ogg','sound/f13music/fo2_vats.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_15.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_16.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13effects/steam_short.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13effects/steam_long.ogg', 10 SECONDS))
	environment = 21
	grow_chance = 25

/area/f13/sewer
	name = "Sewer"
	icon_state = "sewer"
	requires_power = TRUE

//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_caves.ogg','sound/f13music/fo2_desert.ogg','sound/f13music/fo2_vats.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13effects/steam_short.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13effects/steam_long.ogg', 10 SECONDS))
	environment = 21
	grow_chance = 50

/area/f13/caves
	name = "Caves"
	icon_state = "caves"


//	ambientmusic = list('sound/f13music/fo2_caves.ogg','sound/f13music/fo2_desert.ogg','sound/f13music/fo2_necropolis.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_15.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_16.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_17.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_18.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_19.ogg', 10 SECONDS))
	environment = 8
	grow_chance = 75

/area/f13/subway
	name = "Subway"
	icon_state = "subway"

//	ambientmusic = list('sound/f13music/fo2_tunnels.ogg','sound/f13music/fo2_caves.ogg','sound/f13music/fo2_vats.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS))
	environment = 21
	grow_chance = 25

/area/f13/secret
	name = "Secret"
	icon_state = "secret"

//	ambientmusic = list('sound/f13music/fo2_chapel.ogg','sound/f13music/fo2_city.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/ambience/signal.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS))
	environment = 11
	grow_chance = 0

/area/f13/radiation
	name = "Radiation"
	icon_state = "radiation"

//	ambientmusic = list('sound/f13music/fo2_wasteland.ogg','sound/f13music/fo2_desert.ogg','sound/f13music/fo2_world.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/rattlesnake_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/rattlesnake_3.ogg', 10 SECONDS))
	environment = 19
	grow_chance = 5

//Faction related areas

/area/f13/raiders
	name = "Raiders"
	icon_state = "raiders"

//	ambientmusic = list('sound/f13music/fo2_raider.ogg','sound/f13music/fo2_raiders.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/battle_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/battle_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/battle_3.ogg', 10 SECONDS))
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 6
	grow_chance = 5
	weather_tags = list(WEATHER_ALL)

/area/f13/vault
	name = "Vault"
	icon_state = "vaulttec"

//	ambientmusic = list('sound/f13music/fo2_vats.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_14.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13effects/steam_short.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13effects/steam_long.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 6
	grow_chance = 5

/area/f13/vault/reactor
	name = "Reactor"
	icon_state = "engine"

/area/f13/vault/storage
	name = "Storage"
	icon_state = "storage"

/area/f13/vault/storageoffice
	name = "Storage Office"
	icon_state = "storage_wing"

/area/f13/vault/overseer
	name = "Overseer"
	icon_state = "overseer_office"

/area/f13/vault/chiefoffice
	name = "Chief Office"
	icon_state = "sec_hos"

/area/f13/vault/idcontrol
	name = "ID Control Office"
	icon_state = "hop_office"

/area/f13/vault/vents
	name = "Vents"
	icon_state = "red"

/area/f13/vault/botcontrol
	name = "Bot Control"
	icon_state = "mechbay"

/area/f13/vault/atrium
	name = "Vault Atrium"
	icon_state = "vault_atrium_upper"

/area/f13/vault/security
	name = "Brig"
	icon_state = "brig"

/area/f13/vault/security/checkpoint
	name = "Security Checkpoint"
	icon_state = "checkpoint1"

/area/f13/vault/security/armory
	name = "Armory"
	icon_state = "armory"

/area/f13/vault/medical
	name = "Medical Center"
	icon_state = "medbay"

/area/f13/vault/medical/surgery
	name = "Surgery"
	icon_state = "surgery"

/area/f13/vault/medical/breakroom
	name = "Break Room"
	icon_state = "medbay2"

/area/f13/vault/medical/morgue
	name = "Morgue"
	icon_state = "morgue"

/area/f13/vault/medical/chemistry
	name = "Chemistry"
	icon_state = "chem"

/area/f13/vault/science
	name = "Science"
	icon_state = "purple"

/area/f13/vault/science/biology
	name = "Biology"
	icon_state = "purple"

/area/f13/vault/garden
	name = "Garden"
	icon_state = "garden"

/area/f13/vault/diner
	name = "Dining Hall"
	icon_state = "cafeteria"

/area/f13/vault/custodial
	name = "Custodial Closet"
	icon_state = "auxstorage"

/area/f13/vault/dormitory
	name = "Dormitory"
	icon_state = "crew_quarters"

/area/f13/vault/lavatory
	name = "Lavatory"
	icon_state = "restrooms"

/area/f13/brotherhood
	name = "Brotherhood of Steel Bunker"//Brother Hood
	icon_state = "brotherhood"
	requires_power = TRUE

//	ambientmusic = list('sound/f13music/fo2_brotherhood.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 6
	grow_chance = 5

/area/f13/brotherhood/rnd
	name = "Brotherhood of Steel RnD Department"//Brother Hood
	icon_state = "brotherhoodrnddepartment"

/area/f13/brotherhood/offices1st
	name = "Brotherhood of Steel 1st Floor Offices"//Brother Hood
	icon_state = "brotherhoodoffices1st"

/area/f13/brotherhood/offices2nd
	name = "Brotherhood of Steel 1st Floor Offices"//Brother Hood
	icon_state = "brotherhoodoffices2nd"

/area/f13/brotherhood/surface
	name = "Brotherhood of Steel Surface Outpost"//Brother Hood
	icon_state = "brotherhood"

/area/f13/brotherhood/medical
	name = "Brotherhood of Steel Medbay"//Brother Hood
	icon_state = "brotherhoodmedbay"

/area/f13/brotherhood/operating
	name = "Brotherhood of Steel Operating Room"//Brother Hood
	icon_state = "brotherhoodoperating"

/area/f13/brotherhood/chemistry
	name = "Brotherhood of Steel Chemistry Lab"//Brother Hood
	icon_state = "brotherhoodchemistry"

/area/f13/brotherhood/dorms
	name = "Brotherhood of Steel Dormitories"//Brother Hood
	icon_state = "brotherhooddorms"

/area/f13/brotherhood/armory
	name = "Brotherhood of Steel Armory"//Brother Hood
	icon_state = "brotherhoodarmory"

/area/f13/brotherhood/archives
	name = "Brotherhood of Steel Archives"//Brother Hood
	icon_state = "brotherhoodarchives"

/area/f13/brotherhood/operations
	name = "Brotherhood of Steel Operations Department"//Brother Hood
	icon_state = "brotherhoodoperationsdepartment"

/area/f13/brotherhood/leisure
	name = "Brotherhood of Steel Leisure Areas"//Brother Hood
	icon_state = "brotherhoodleisure"

/area/f13/brotherhood/reactor
	name = "Brotherhood of Steel Reactor"//Brother Hood
	icon_state = "brotherhoodreactor"

/area/f13/brotherhood/mining
	name = "Brotherhood of Steel Mining"//Brother Hood
	icon_state = "brotherhoodmining"

/area/f13/brotherhood/powered
	requires_power = TRUE // same as parent — powered by generator only, not always-on

/area/f13/enclave
	name = "Enclave Bunker"
	icon_state = "enclave"

//	ambientmusic = list('sound/f13music/fo2_vats.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_14.ogg', 10 SECONDS),
		AREA_SOUND('sound/ambience/signal.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/enclave_vault.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 6
	grow_chance = 5

/area/f13/enclave/rnd
	name = "Enclave Research and Development"
	icon_state = "enclave"

/area/f13/enclave/labs
	name = "Enclave Research Labs"
	icon_state = "enclave"

/area/f13/enclave/armory
	name = "Enclave Armory"
	icon_state = "enclave"

/area/f13/enclave/barracks
	name = "Enclave Barracks"
	icon_state = "enclave"

/area/f13/enclave/medical
	name = "Enclave Medbay"
	icon_state = "enclave"

/area/f13/enclave/command
	name = "Enclave Command Center"
	icon_state = "enclave"

/area/f13/enclave/reactor
	name = "Enclave Reactor"
	icon_state = "enclave"

/area/f13/enclave/comms
	name = "Enclave Communications"
	icon_state = "enclave"

/area/f13/enclave/powered

/area/f13/ahs
	name = "Adepts of Hubology Studies"
	icon_state = "ahs"

//	ambientmusic = list('sound/f13music/fo2_vats.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS),
		AREA_SOUND('sound/ambience/signal.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 5
	grow_chance = 5

/area/f13/ahs/temple
	name = "AHS Temple"
	icon_state = "ahs"

/area/f13/ahs/study
	name = "AHS Study Hall"
	icon_state = "ahs"

/area/f13/ahs/dormitory
	name = "AHS Dormitory"
	icon_state = "ahs"

/area/f13/ahs/xenotech
	name = "AHS Xenoscience Department"
	icon_state = "ahs"

/area/f13/ahs/command
	name = "AHS Command"
	icon_state = "ahs"

/area/f13/ncr
	name = "NCR Outpost"
	icon_state = "ncr"

//	ambientmusic = list('sound/f13music/fo2_city.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_5.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_6.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_7.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_8.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_9.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 4
	grow_chance = 5

/area/f13/ncr/powered
	name = "NCR Outpost"
	icon_state = "ncr"

/area/f13/ncr/barracks
	name = "NCR Barracks"
	icon_state = "ncr"

/area/f13/ncr/armory
	name = "NCR Armory"
	icon_state = "ncr"

/area/f13/ncr/command
	name = "NCR Command Post"
	icon_state = "ncr"

/area/f13/ncr/medical
	name = "NCR Medical"
	icon_state = "ncr"

/area/f13/ncr/storage
	name = "NCR Storage"
	icon_state = "ncr"

/area/f13/ncr/mess
	name = "NCR Mess Hall"
	icon_state = "ncr"

/area/f13/ncr/entrance
	name = "NCR Outpost Entrance"
	icon_state = "ncr"

/area/f13/ncr/jail
	name = "NCR Holding Cells"
	icon_state = "ncr"

/area/f13/legion
	name = "Legion Fortress"
	icon_state = "legion"

//	ambientmusic = list('sound/f13music/fo2_hub.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_3.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_4.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_15.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_16.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_1.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_2.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/dog_distant_3.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 4
	grow_chance = 5
//	weather_tags = list(WEATHER_ALL) tf

/area/f13/legion/powered
	name = "Legion Fortress"
	icon_state = "legion"

/area/f13/legion/barracks
	name = "Legion Barracks"
	icon_state = "legion"

/area/f13/legion/armory
	name = "Legion Armory"
	icon_state = "legion"

/area/f13/legion/medical
	name = "Legion Medical"
	icon_state = "legion"

/area/f13/legion/command
	name = "Legion Command Tent"
	icon_state = "legion"

/area/f13/legion/prison
	name = "Legion Prison"
	icon_state = "legion"

/area/f13/legion/arena
	name = "Legion Arena"
	icon_state = "legion"

/area/f13/legion/forge
	name = "Legion Forge"
	icon_state = "legion"

/area/f13/followers
	name = "Followers of the Apocalypse Clinic"
	icon_state = "followers"

//	ambientmusic = list('sound/f13music/fo2_vats.ogg','sound/f13music/fo2_outpost.ogg','sound/misc/null.ogg')
	ambientsounds = list(
		AREA_SOUND('sound/f13ambience/ambigen_10.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_11.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_12.ogg', 10 SECONDS),
		AREA_SOUND('sound/f13ambience/ambigen_13.ogg', 10 SECONDS),
		AREA_SOUND('sound/ambience/signal.ogg', 10 SECONDS))
	blob_allowed = 0
	environment = 5
	grow_chance = 5

/area/f13/followers/clinic
	name = "Followers Clinic"
	icon_state = "followers"

/area/f13/followers/library
	name = "Followers Library"
	icon_state = "followers"

/area/f13/followers/surgery
	name = "Followers Surgery"
	icon_state = "followers"

/area/f13/followers/storage
	name = "Followers Storage"
	icon_state = "followers"

/area/f13/followers/quarters
	name = "Followers Living Quarters"
	icon_state = "followers"

/area/f13/followers/lab
	name = "Followers Laboratory"
	icon_state = "followers"

/area/f13/wasteland/khans
	name = "Great Khan Encampment"
	icon_state = "tribe"
	weather_tags = list(WEATHER_ALL)


// Holiday Tipton Town

/area/f13/holiday
	name = "Holiday"
	icon_state = "holiday"

/area/f13/holiday/mine
	name = "Holiday mine"
	icon_state = "holiday_mine"

/area/f13/holiday/powered
	name = "Holiday"
	icon_state = "holiday"

/area/f13/holiday/powered/deepmine // deepmines for holiday means no infinite power
	name = "Holiday deep mine"
	icon_state = "holiday_mine"

// Zion Valley

/area/f13/wasteland/badlands
	name = "Badlands"
	icon_state = "badland"
//	ambience_area =  list('sound/f13ambience/wasteland.ogg')
	ambientmusic = list('sound/ambience/wilderness.ogg')
	ambientsounds = list('sound/f13ambience/bird_1.ogg','sound/f13ambience/bird_2.ogg','sound/f13ambience/bird_3.ogg', \
	'sound/f13ambience/bird_4.ogg','sound/f13ambience/bird_5.ogg','sound/f13ambience/bird_6.ogg', \
	'sound/f13ambience/bird_7.ogg','sound/f13ambience/bird_8.ogg', 'sound/f13ambience/rattlesnake_1.ogg', \
	'sound/f13ambience/rattlesnake_2.ogg','sound/f13ambience/rattlesnake_3.ogg')
	outdoors = 1
	open_space = 1
	blob_allowed = 0
	environment = 15
	grow_chance = 75

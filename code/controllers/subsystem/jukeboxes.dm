SUBSYSTEM_DEF(jukeboxes)
	name = "Jukeboxes"
	wait = 5
	var/list/datum/track/songs = list()
	var/list/activejukeboxes = list()
	var/list/freejukeboxchannels = list()

/datum/track
	var/song_name = "generic"
	var/song_path = null
	var/song_length = 0
	var/song_beat = 0
	var/song_associated_id = null

/datum/track/New(name, path, length, beat, assocID)
	song_name = name
	song_path = path
	song_length = length
	song_beat = beat
	song_associated_id = assocID

/datum/controller/subsystem/jukeboxes/proc/addjukebox(obj/jukebox, datum/track/T, jukefalloff = 1)
	if(!istype(T))
		CRASH("[src] tried to play a song with a nonexistant track")
	var/channeltoreserve = pick(freejukeboxchannels)
	if(!channeltoreserve)
		return FALSE
	freejukeboxchannels -= channeltoreserve
	var/list/youvegotafreejukebox = list(T, channeltoreserve, jukebox, jukefalloff)
	activejukeboxes.len++
	activejukeboxes[activejukeboxes.len] = youvegotafreejukebox

	//Due to changes in later versions of 512, SOUND_UPDATE no longer properly plays audio when a file is defined in the sound datum. As such, we are now required to init the audio before we can actually do anything with it.
	//Downsides to this? This means that you can *only* hear the jukebox audio if you were present on the server when it started playing, and it means that it's now impossible to add loops to the jukebox track list.
	var/sound/song_to_init = sound(T.song_path)
	song_to_init.status = SOUND_MUTE
	for(var/mob/M in GLOB.player_list)
		if(!M.client)
			continue
		if(!(M.client.prefs.toggles & SOUND_INSTRUMENTS))
			continue

		M.playsound_local(M, null, 100, channel = youvegotafreejukebox[2], S = song_to_init)
	return activejukeboxes.len

/datum/controller/subsystem/jukeboxes/proc/removejukebox(IDtoremove)
	if(islist(activejukeboxes[IDtoremove]))
		var/jukechannel = activejukeboxes[IDtoremove][2]
		for(var/mob/M in GLOB.player_list)
			if(!M.client)
				continue
			M.stop_sound_channel(jukechannel)
		freejukeboxchannels |= jukechannel
		activejukeboxes.Cut(IDtoremove, IDtoremove+1)
		return TRUE
	else
		CRASH("Tried to remove jukebox with invalid ID")

/datum/controller/subsystem/jukeboxes/proc/findjukeboxindex(obj/jukebox)
	if(activejukeboxes.len)
		for(var/list/jukeinfo in activejukeboxes)
			if(jukebox in jukeinfo)
				return activejukeboxes.Find(jukeinfo)
	return FALSE

/datum/controller/subsystem/jukeboxes/Initialize()
	var/list/tracks = flist("config/jukebox_music/sounds/")
	for(var/S in tracks)
		var/datum/track/T = new()
		T.song_path = file("config/jukebox_music/sounds/[S]")
		var/list/L = splittext(S,"+")
		T.song_name = L[1]
		T.song_length = text2num(L[2])
		T.song_beat = text2num(L[3])
		T.song_associated_id = L[4]
		songs |= T
	for(var/i in CHANNEL_JUKEBOX_START to CHANNEL_JUKEBOX)
		freejukeboxchannels |= i
	return ..()

/datum/controller/subsystem/jukeboxes/fire()
	if(!activejukeboxes.len)
		return
	for(var/list/jukeinfo in activejukeboxes)
		if(!jukeinfo.len)
			stack_trace("Active jukebox without any associated metadata.")
			continue
		var/datum/track/juketrack = jukeinfo[1]
		if(!istype(juketrack))
			stack_trace("Invalid jukebox track datum.")
			continue
		var/obj/jukebox = jukeinfo[3]
		if(!istype(jukebox))
			stack_trace("Nonexistant or invalid object associated with jukebox.")
			continue
		var/sound/song_played = sound(juketrack.song_path)
//		var/area/currentarea = get_area(jukebox)
		var/turf/currentturf = get_turf(jukebox)
//		var/list/hearerscache = hearers(7, jukebox)

		song_played.falloff = jukeinfo[4]

		for(var/mob/M in GLOB.player_list)
			if(!M.client)
				continue
			if(!(M.client.prefs.toggles & SOUND_INSTRUMENTS) || !M.can_hear())
				M.stop_sound_channel(jukeinfo[2])
				continue
			var/turf/juketurf = get_turf(jukebox)
			var/turf/mturf = get_turf(M)
			if(!juketurf || !mturf)
				continue
			if(juketurf.z == mturf.z)	//todo - expand this to work with mining planet z-levels when robust jukebox audio gets merged to master
				song_played.status = SOUND_UPDATE
			else if(juketurf.z == mturf.z -1)
				var/turf/juketurf_above = SSmapping.get_turf_above(juketurf)
				if(istype(juketurf_above, /turf/open/transparent))
					song_played.status = SOUND_UPDATE
			else if(juketurf.z == mturf.z +1)
				var/turf/mturf_above = SSmapping.get_turf_above(mturf)
				if(istype(mturf_above, /turf/open/transparent) || istype(juketurf,/turf/open/transparent))
					song_played.status = SOUND_UPDATE
			else
				song_played.status = SOUND_MUTE | SOUND_UPDATE	//Setting volume = 0 doesn't let the sound properties update at all, which is lame.

			M.playsound_local(currentturf, null, 100, channel = jukeinfo[2], S = song_played)
			CHECK_TICK
	return
//BIG IRON EDIT start
/datum/controller/subsystem/jukeboxes/proc/add_song(datum/track/NS) //proc usted to add a song, when a disk is added to a jukebox
	if(SSjukeboxes.songs.len)
		for(var/datum/track/CT in SSjukeboxes.songs)
			if(NS.song_associated_id == CT.song_associated_id)
				return FALSE
	SSjukeboxes.songs += NS

/datum/controller/subsystem/jukeboxes/proc/remove_song(datum/track/NS)  //proc usted to remove a song, when a disk is removed from a jukebox
	for(var/datum/track/RT in SSjukeboxes.songs)
		if(NS.song_associated_id == RT.song_associated_id)
			SSjukeboxes.songs -= NS
			return TRUE


/datum/track/cursed
	song_name = "Cursed Track"
	song_path = 'modular_BD2/general/sound/cursed.ogg'
	song_length = 1370
	song_beat = 010
	song_associated_id = "cursedsong01"
//BIG IRON EDIT -end

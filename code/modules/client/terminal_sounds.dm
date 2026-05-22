// Terminal sound system for RobCo character setup
// Sound files should be placed in sound/terminal/
// The system will gracefully handle missing files

// Play terminal sound to a client
/proc/play_terminal_sound_to(client/C, sound_type, volume = 30)
	if(!C)
		return FALSE
	
	var/sound/s
	var/sound_path
	
	switch(sound_type)
		if("boot")
			sound_path = "sound/terminal/boot.ogg"
		if("keypress")
			sound_path = "sound/terminal/keypress.ogg"
		if("select")
			sound_path = "sound/terminal/select.ogg"
		if("error")
			sound_path = "sound/terminal/error.ogg"
		if("enter")
			sound_path = "sound/terminal/enter.ogg"
	
	if(sound_path && fexists(sound_path))
		s = sound(file(sound_path), volume = volume)
		C << s
		return TRUE
	return FALSE

// Terminal sound manager datum for more complex sound sequences
/datum/terminal_sound_manager
	var/client/owner
	var/sound_enabled = TRUE
	var/volume = 30

/datum/terminal_sound_manager/New(client/C)
	owner = C

/datum/terminal_sound_manager/proc/play(sound_type)
	if(!sound_enabled || !owner)
		return FALSE
	return play_terminal_sound_to(owner, sound_type, volume)

/datum/terminal_sound_manager/proc/play_boot_sequence()
	if(!sound_enabled)
		return
	
	// Play boot sound with slight variations
	play("boot")
	
	// Play keypresses during boot
	addtimer(CALLBACK(src, .proc/play, "keypress"), 1 SECONDS)
	addtimer(CALLBACK(src, .proc/play, "keypress"), 2 SECONDS)
	addtimer(CALLBACK(src, .proc/play, "keypress"), 3 SECONDS)

/datum/terminal_sound_manager/proc/set_volume(new_volume)
	volume = clamp(new_volume, 0, 100)

/datum/terminal_sound_manager/proc/toggle_sounds()
	sound_enabled = !sound_enabled
	return sound_enabled

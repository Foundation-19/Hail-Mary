//******************************************
//WHEN ADDING NEW MUSIC, ADD THE MUSIC'S NAME TO _globalvars/lists/objects.dm global_music_list and then scroll down to the switch(music_name) part
//Make sure you put it in alphabetical order and also update the switch(music_file) part at the disk burner's attack_hand proc with whatever music you added
//******************************************

/obj/machinery/radio_station
	name = "radio station"
	desc = "A specially equipped radio station to broadcast music to every radio in a the waste. Comes pre-coded with over 30 songs!"
	icon = 'icons/fallout/machines/radio.dmi'
	icon_state = "gannets_machine21"
	max_integrity = 150
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	armor = list("melee" = 20, "bullet" = 20, "laser" = 20, "energy" = 20, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 20)
	circuit = /obj/item/circuitboard/machine/radio_station
	light_color = LIGHT_COLOR_GREEN
	var/datum/track/selectedtrack = "None" //File path to the music's audio file
	var/selectedtrackname = "none"
//	var/datum/track = null //This is the name of the song, not the file name. This is what shows up at the top of the music selection.
	var/list/music_list //List of music that can be played. Only the most based songs may be added.
	var/cooldowntime
	var/obj/item/record_disk/R //The record disk that's currently playing music
	var/can_eject_disk = 1
	var/ready_to_delete = 0 //For Destroy()
	var/brightness_on = 1
	var/volume = 35 //the volume that music plays at

/obj/machinery/radio_station/Initialize()
	. = ..()
	music_list = SSjukeboxes.songs
	update_icon()

/obj/machinery/radio_station/attack_hand(mob/living/user)
	..()
	var/machinesound = 'sound/machines/doorclick.ogg'
	playsound(src, machinesound, 100, 1)
	if(R)
		if(can_eject_disk)
			update_icon()
			playsound(src, 'sound/effects/plastic_click.ogg', 100, 0)
			R.forceMove(get_turf(src))
			R = null
			stopRadioMusic()
			return
		else
			to_chat(user, "<span class ='warning'>You must wait to eject the record disk!</span>")
			return

	if(stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		update_icon()
		return
	if(cooldowntime > world.time)
		to_chat(user, "<span class ='warning'>The broadcasting antenna needs time to recharge! It will be ready in [DisplayTimeText(cooldowntime - world.time)].</span>")
		return
	var/list/songnames = list()
	if(music_list.len)
		for(var/i = 1, i <= music_list.len, i++)
			var/datum/track/CT = music_list[i]
			var/ctsn = "[CT.song_name]"
			songnames += ctsn
	var/datum/track/cooming = input(user, "Last played music: [selectedtrackname]", "Available Music") as null|anything in songnames
	if(!user.Adjacent(src))
		to_chat(user, "<span class='warning'>You are too far away!")
		return
	if(!cooming)
		return
	if(cooldowntime > world.time)
		to_chat(user, "<span class ='warning'>The broadcasting antenna needs time to recharge! It will be ready in [DisplayTimeText(cooldowntime - world.time)].</span>")
		return
	for(var/datum/track/S in music_list)
		if(S.song_name == cooming)//agghggagaghaghah
			selectedtrack = S.song_path
			selectedtrackname = S.song_name
			continue
	playsound(src, machinesound, 100, 1)
	playMusicToRadios(user)

/obj/machinery/radio_station/attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/record_disk))
		if(cooldowntime > world.time)
			to_chat(user, "<span class ='warning'>The broadcasting antenna needs time to recharge! It will be ready in [DisplayTimeText(cooldowntime - world.time)].</span>")
			return
		if(!R)
			R = I
			I.forceMove(src)
			add_overlay("radio_station_disk")
			playsound(src, 'sound/effects/plastic_click.ogg', 100, 0)
			selectedtrack = R.R.song_path
			if(R.R.song_name != "CUSTOM")
				selectedtrack = R.R.song_path
				selectedtrackname = R.R.song_name
			else
				selectedtrack = R.R.song_path
				selectedtrackname = "A custom song!f"
			playMusicToRadios(user)
			return
		else
			to_chat(user, "<span class='warning'>There is already a record disk in the [src]!</span>")
			return
	..()

/obj/machinery/radio_station/proc/playMusicToRadios(mob/living/user)
	if(stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		update_icon()
		return
	if(cooldowntime > world.time)
		to_chat(user, "<span class ='warning'>The broadcasting antenna needs time to recharge! It will be ready in [DisplayTimeText(cooldowntime - world.time)].</span>")
		return

	var/store_resistance_flags = resistance_flags
	resistance_flags = INDESTRUCTIBLE	//Need to do this so that it can't be destroyed before the music starts playing.

	can_eject_disk = 0
	cooldowntime = world.time + 0001
	for(var/obj/item/radio/R in GLOB.radio_list) //Calls the playmusic() proc for every radio in radio_list (everyone)
		R.playmusic(selectedtrack, selectedtrackname, volume)

	src.audible_message("<span class='robot'><b>[src]</b> beeps, 'Now broadcasting: <i>[selectedtrackname]</i>' </span>")

	resistance_flags = store_resistance_flags

	can_eject_disk = 1
	if(stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF) //Need to check again in case the radio station is destroyed while this proc is in progress
		update_icon()
		stopRadioMusic()
		return


/obj/machinery/radio_station/proc/stopRadioMusic()
	var/i
	for(i = 1; i <= GLOB.radio_list.len; i++) //This time it will stop the music for every radio listening to this radio station.
		if(!istype(GLOB.radio_list[i], /obj/item/pda))
			GLOB.radio_list[i].stopmusic(GLOB.radio_list[i].radio_holder, 3)

/obj/machinery/radio_station/Destroy()
	stopRadioMusic()
	..()

/obj/machinery/radio_station/update_icon()
	..()
	cut_overlays()
	if(!(stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF))
		add_overlay("radio_station_on")
		luminosity = 1
		set_light(brightness_on)
		return
	luminosity = 0
	set_light(0)

/obj/machinery/radio_station/power_change()
	. = ..()
	if(stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		set_light(0)
	else
		set_light(brightness_on)

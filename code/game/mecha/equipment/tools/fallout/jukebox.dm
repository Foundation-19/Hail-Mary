/obj/item/mecha_parts/mecha_equipment/stereo
	name = "exosuit Stereo System"
	desc = "a stereo system hooked up a jukebox, modified for easy transport."
	icon_state = "mecha_stereo"
	range = MELEE
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/volume = 70
	var/datum/track/selection = null
	var/open_tray = TRUE
	var/list/obj/item/record_disk/record_disks = list()
	var/obj/item/record_disk/selected_disk = null

/obj/item/mecha_parts/mecha_equipment/stereo/attach(obj/mecha/M)
	. = ..()
	bypass_interactions = TRUE

/obj/item/mecha_parts/mecha_equipment/stereo/detach(obj/mecha/M)
	. = ..()
	bypass_interactions = FALSE

/obj/item/mecha_parts/mecha_equipment/stereo/attackby(obj/item/O, mob/user, params)
	. = ..()
	if(!active)
		if(istype(O, /obj/item/record_disk)) //this one checks for a record disk and if the jukebox is open, it adds it to the machine
			if(open_tray == FALSE)
				to_chat(usr, "The Disk Tray is not open!")
				return
			var/obj/item/record_disk/I = O
			if(!I.R.song_associated_id)
				to_chat(user, span_warning("This record is empty!"))
				return
			for(var/datum/track/RT in SSjukeboxes.songs)
				if(I.R.song_associated_id == RT.song_associated_id)
					to_chat(user, span_warning("this track is already added to the jukebox!"))
					return
			record_disks += I
			O.forceMove(src)
			playsound(src, 'sound/effects/plastic_click.ogg', 100, 0)
			if(I.R.song_path)
				SSjukeboxes.add_song(I.R)
			return

/obj/item/mecha_parts/mecha_equipment/stereo/proc/eject_record(obj/item/record_disk/M) //BIG IRON EDIT -start- ejects a record as defined and removes it's song from the list
	if(!M)
		visible_message("no disk to eject")
		return
	playsound(src, 'sound/effects/disk_tray.ogg', 100, 0)
	src.visible_message("<span class ='notice'> ejected the [selected_disk] from the [src]!</span>")
	M.forceMove(get_turf(src))
	SSjukeboxes.remove_song(M.R)
	record_disks -= M
	selected_disk = null

/obj/item/mecha_parts/mecha_equipment/stereo/ui_status(mob/user)
	if(!SSjukeboxes.songs.len && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue.</span>")
		playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/obj/item/mecha_parts/mecha_equipment/stereo/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Jukebox", name)
		ui.open()

/obj/item/mecha_parts/mecha_equipment/stereo/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	data["songs"] = list()
	for(var/datum/track/S in SSjukeboxes.songs)
		var/list/track_data = list(
			name = S.song_name
		)
		data["songs"] += list(track_data)
	data["track_selected"] = null
	data["track_length"] = null
	data["track_beat"] = null
	data["disks"] = list()
	for(var/obj/item/record_disk/RD in record_disks)
		var/list/tracks_data = list(
			name = RD.name
		)
		data["disks"] += list(tracks_data)
	data["disk_selected"] = null //BIG IRON EDIT- start more tracks data
	data["disk_selected_lenght"] = null
	data["disk_beat"] = null //BIG IRON EDIT -end
	if(selection)
		data["track_selected"] = selection.song_name
		data["track_length"] = DisplayTimeText(selection.song_length)
		data["track_beat"] = selection.song_beat
	if(selected_disk)
		data["disk_selected"] = selected_disk
		data["disk_selected_length"] = DisplayTimeText(selected_disk.R.song_length)
		data["disk_selected_beat"] = selected_disk.R.song_beat
	data["volume"] = volume
	return data

/obj/item/mecha_parts/mecha_equipment/stereo/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			if(QDELETED(src))
				return
			if(!active)
				if(stop > world.time)
					to_chat(usr, "<span class='warning'>Error: The device is still resetting from the last activation, it will be ready again in [DisplayTimeText(stop-world.time)].</span>")
					playsound(src, 'sound/misc/compiler-failure.ogg', 50, TRUE)
					return
				activate_music()
				START_PROCESSING(SSobj, src)
				return TRUE
			else
				stop = 0
				return TRUE
		if("select_track")
			if(active)
				to_chat(usr, "<span class='warning'>Error: You cannot change the song until the current one is over.</span>")
				return
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selection = available[selected]
			return TRUE
		if("select_record")
			if(!record_disks.len)
				to_chat(usr, "<span class='warning'>Error: no tracks on the bin!.</span>")
				return
			var/list/obj/item/record_disk/availabledisks = list()
			for(var/obj/item/record_disk/RR in record_disks)
				availabledisks[RR.name] = RR
			var/selecteddisk = params["record"]
			if(QDELETED(src) || !selecteddisk)
				return
			selected_disk = availabledisks[selecteddisk]
			updateUsrDialog()
		if("eject_disk") // sanity check for the disk ejection
			if(!record_disks.len)
				to_chat(usr, "<span class='warning'>Error: no disks in trays.</span>")
				return
			if(!selected_disk)
				to_chat(usr,"<span class='warning'>Error: no disk chosen.</span>" )
				return
			if(selection == selected_disk.R)
				selection = null
			eject_record(selected_disk)
			return TRUE
		if("set_volume")
			var/new_volume = params["volume"]
			if(new_volume  == "reset")
				volume = initial(volume)
				return TRUE
			else if(new_volume == "min")
				volume = 0
				return TRUE
			else if(new_volume == "max")
				volume = 100
				return TRUE
			else if(text2num(new_volume) != null)
				volume = text2num(new_volume)
				return TRUE

/obj/item/mecha_parts/mecha_equipment/stereo/proc/activate_music()
	if(!selection)
		visible_message("Track is no longer avaible")
		return
	var/jukeboxslottotake = SSjukeboxes.addjukebox(src, selection, 2)
	if(jukeboxslottotake)
		active = TRUE
		update_icon()
		START_PROCESSING(SSobj, src)
		stop = world.time + selection.song_length
		return TRUE
	else
		return FALSE

/obj/item/mecha_parts/mecha_equipment/stereo/get_equip_info()
	var/output = ..()
	if(output)
		var/temp = ""
		temp = "<a href='?src=[REF(src)];dashboard=1'>Dashboard</a>"
		return "[output] [temp]"
	return

/obj/item/mecha_parts/mecha_equipment/stereo/Topic(href,href_list)
	..()
	if(href_list["dashboard"])
		var/mob/user = chassis.occupant
		ui_interact(user)
		return

/obj/item/mecha_parts/mecha_equipment/stereo/process()
	if(active && world.time >= stop)
		active = FALSE
		dance_over()
		playsound(src,'sound/machines/terminal_off.ogg',50,1)
		update_icon()
		stop = world.time + 100

/obj/item/mecha_parts/mecha_equipment/stereo/proc/dance_over()
	var/position = SSjukeboxes.findjukeboxindex(src)
	if(!position)
		return
	SSjukeboxes.removejukebox(position)
	STOP_PROCESSING(SSobj, src)
	rangers = list()

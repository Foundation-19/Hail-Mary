/obj/machinery/jukebox
	name = "jukebox"
	desc = "A classic music player."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "jukebox"
	verb_say = "states"
	density = TRUE
	req_one_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_HYDROPONICS, ACCESS_ENGINE, ACCESS_CARGO, ACCESS_THEATRE)
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/volume = 70
	var/datum/track/selection = null
	var/obj/item/lock_part/lock = null //BIG IRON EDIT START 
	var/open_tray = FALSE //usted to determine if the jukebox is open or not, needs a key
	var/list/record_disks = list() //list of inserted disk inthe jukebox
	var/obj/item/record_disk/selected_disk = null //the disk chosen to view or ejection

/obj/machinery/jukebox/constructed //BIG IRON EDIT start- a sub jukebox with access for everyone
	req_one_access = null
	desc = "an improvised jukebox, made with scraps and hopes"
//BIG IRON EDIT -end-
/obj/machinery/jukebox/disco
	name = "radiant dance machine mark IV"
	desc = "The first three prototypes were discontinued after mass casualty incidents."
	icon_state = "disco"
	req_access = list(ACCESS_ENGINE)
	anchored = FALSE
	var/list/spotlights = list()
	var/list/sparkles = list()

//BIG IRON EDIT -start
/obj/machinery/jukebox/Initialize() //BIG IRON EDIT -start
	. = ..()
	lock = new /obj/item/lock_part()
	lock.forceMove(src)
	var/obj/item/key/vending/K = new /obj/item/key/vending()
	K.name = "[src.name] key"
	K.forceMove(src.loc)
	if(lock)
		lock.is_secured = 0
		lock.store_key(K)
		lock.is_secured = 1
//BIG IRON EDIT -end

/obj/machinery/jukebox/disco/indestructible
	name = "radiant dance machine mark V"
	desc = "Now redesigned with data gathered from the extensive disco and plasma research."
	req_access = null
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	flags_1 = NODECONSTRUCT_1

/obj/machinery/jukebox/Destroy()
	dance_over()
	return ..()

/obj/machinery/jukebox/attackby(obj/item/O, mob/user, params)
	if(!active && !(flags_1 & NODECONSTRUCT_1))
		if(istype(O, /obj/item/wrench))
			if(!anchored && !isinspace())
				to_chat(user,span_notice("You secure [src] to the floor."))
				setAnchored(TRUE)
			else if(anchored)
				to_chat(user,span_notice("You unsecure and disconnect [src]."))
				setAnchored(FALSE)
			playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
			return
		if(istype(O, /obj/item/key)) //BIG IRON EDIT -start this one checks for a key used in the jukebox
			if(lock.check_key(O)) //check if the key used is assinged to this lock
				if(open_tray == FALSE)
					open_tray = TRUE
					to_chat(user,span_warning("you open the [src]'s tray."))
				else
					open_tray = FALSE
					to_chat(user,span_warning("you close the [src]'s tray."))
				playsound(src, 'sound/items/Ratchet.ogg', 60, 1)
				return
			else
				playsound(src, 'sound/machines/DeniedBeep.ogg', 60, 1)
				to_chat(usr, "Unknown key.")
				return
		else if(istype(O, /obj/item/record_disk)) //this one checks for a record disk and if the jukebox is open, it adds it to the machine
			if(open_tray == FALSE)
				to_chat(usr, "The Disk Tray is not open!")
				return
			var/obj/item/record_disk/I = O
			for(var/datum/track/RT in SSjukeboxes.songs)
				if(I.R.song_associated_id == SSjukeboxes.songs[RT].song_associated_id)
					to_chat(user, span_warning("this track is already added to the jukebox!"))
					return
			record_disks += I
			O.forceMove(src)
			playsound(src, 'sound/effects/plastic_click.ogg', 100, 0)
			if(I.R.song_path)
				SSjukeboxes.add_song(I.R)
			return//BIG IRON EDIT -end
	return ..()
/obj/machinery/jukebox/proc/eject_record(obj/item/record_disk/M) //BIG IRON EDIT -start- ejects a record as defined and removes it's song from the list
	if(!M)
		visible_message("no disk to eject")
		return
	playsound(src, 'sound/effects/disk_tray.ogg', 100, 0)
	src.visible_message("<span class ='notice'> ejected the [selected_disk] from the [src]!</span>")
	M.forceMove(get_turf(src))
	SSjukeboxes.remove_song(M.R)
	selected_disk = null

/obj/machinery/jukebox/update_icon_state()
	if(active)
		icon_state = "[initial(icon_state)]-active"
	else
		icon_state = "[initial(icon_state)]"

/obj/machinery/jukebox/ui_status(mob/user)
	if(!anchored)
		to_chat(user,span_warning("This device must be anchored by a wrench!"))
		return UI_CLOSE
	if(!allowed(user) && !isobserver(user))
		to_chat(user,span_warning("Error: Access Denied."))
		user.playsound_local(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	if(!SSjukeboxes.songs.len && !isobserver(user))
		to_chat(user,span_warning("Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue."))
		playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	var/list/dat = list()
	dat +="<div class='statusDisplay' style='text-align:center'>"
	dat += "<b><A href='?src=[REF(src)];action=toggle'>[!active ? "BREAK IT DOWN" : "SHUT IT DOWN"]<b></A><br>"
	dat += "</div><br>"
	dat += "<A href='?src=[REF(src)];action=select'> Select Track</A><br>"
	dat += "<A href='?src=[REF(src)];action=loaded_tracks'> manage loaded tracks</A><br>" // ATOM EDIT- used for track management
	dat += "<A href='?src=[REF(src)];action=eject_disk'> eject the currently selected disk</A><br>" //ATOM EDIT- ejects the chosen disk
	if(istype(selection))
		dat += "Track Selected: [selection.song_name]<br>"
		dat += "Track Length: [DisplayTimeText(selection.song_length)]<br><br>"
	else
		dat += "Track Selected: None!<br><br>"
	if(record_disks.len) //ATOM EDIT -start shows information of a the current music library
		dat += "number of loaded tracks: [record_disks.len]<br>"
	if(istype(selected_disk))
		dat += "disk Selected: [selected_disk]<br>"
		dat += "with song: [selected_disk.R.song_name]<br>"
		dat += "Track duration: [DisplayTimeText(selected_disk.R.song_length)])<br>" //custom tracks should come out as number but just in case
	else
		dat += "Disk Selected: None!<br><br>" //ATOM EDIT -end
	var/datum/browser/popup = new(user, "vending", "[name]", 400, 350)
	popup.set_content(dat.Join())
	popup.open()
	
/obj/machinery/jukebox/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Jukebox", name)
		ui.open()

/obj/machinery/jukebox/ui_data(mob/user)
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
	data["volume"] = volume
	data["loaded tracks"] = list() //ATOM EDIT -start- most of these are shown if at least a disk is in the jukebox
	var/TN = 1
	for(var/obj/item/record_disk in record_disks[TN])
		var/list/track_data = list(
			name = record_disks[TN]
		)
		data["loaded tracks"] += list(track_data)
		TN ++
	if(selected_disk)
		data["disk_selected"] = selected_disk.R.song_name
		data["disk_selected_lengt"] = selected_disk.R.song_length
		data["disk_beat"] = selected_disk.R.song_beat //ATOM EDIT- end
	return data

/obj/machinery/jukebox/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			if(QDELETED(src))
				return
			if(!active)
				if(stop > world.time)
					to_chat(usr, span_warning("Error: The device is still resetting from the last activation, it will be ready again in [DisplayTimeText(stop-world.time)]."))
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
				to_chat(usr, span_warning("Error: You cannot change the song until the current one is over."))
				return
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selection = available[selected]
			return TRUE
		if("select_record") //BIG IRON EDIT -start- how an user chooses a disk
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
			selected_disk = availabletracks[selecteddisk]
			return TRUE
		if("eject_disk") // this one ejects a currently selected disk
			if(!selected_disk)
				to_chat(usr, span_warning("Error: no disk selected."))
			return TRUE
//BIG IRON EDIT -end
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
		
/obj/machinery/jukebox/Topic(href, href_list)
	if(..())
		return
	add_fingerprint(usr)
	switch(href_list["action"])
		if("toggle")
			if (QDELETED(src))
				return
			if(!active)
				if(stop > world.time)
					to_chat(usr, "<span class='warning'>Error: The device is still resetting from the last activation, it will be ready again in [DisplayTimeText(stop-world.time)].</span>")
					playsound(src, 'sound/misc/compiler-failure.ogg', 50, 1)
					return
				if(!istype(selection))
					to_chat(usr, "<span class='warning'>Error: Severe user incompetence detected.</span>")
					playsound(src, 'sound/misc/compiler-failure.ogg', 50, 1)
					return
				if(!activate_music())
					to_chat(usr, "<span class='warning'>Error: Generic hardware failure.</span>")
					playsound(src, 'sound/misc/compiler-failure.ogg', 50, 1)
					return
				updateUsrDialog()
			else if(active)
				stop = 0
				updateUsrDialog()
		if("select")
			if(active)
				to_chat(usr, "<span class='warning'>Error: You cannot change the song until the current one is over.</span>")
				return

			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = input(usr, "Choose your song", "Track:") as null|anything in available
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selection = available[selected]
			updateUsrDialog()
		if("loaded_tracks") //ATOM EDIT -start- how an user chooses a disk
			if(!record_disks.len)
				to_chat(usr, "<span class='warning'>Error: no tracks on the bin!.</span>")
				return
			var/list/availabledisks = list()
			for(var/obj/item/record_disk/RR in record_disks)
				availabledisks[RR.name] = RR
			var/selecteddisk = input(usr, "Choose a disk to eject", "disk:") as null|anything in availabledisks
			if(QDELETED(src) || !selecteddisk || !istype(availabledisks[selecteddisk], /obj/item/record_disk))
				return
			selected_disk = availabledisks[selecteddisk]
			updateUsrDialog()
		if("eject_disk") // sanity check for the disk ejection
			if(!record_disks.len)
				to_chat(usr, "<span class='warning'>Error: no disks in trays.</span>")
				return
			if(!selected_disk)
				to_chat(usr,"<span class='warning'>Error: no disk chosen.</span>" )
			eject_record(selected_disk)
			selected_disk = null
			updateUsrDialog()
//ATOM EDIT -end

/obj/machinery/jukebox/proc/activate_music()
	var/jukeboxslottotake = SSjukeboxes.addjukebox(src, selection, 2)
	if(jukeboxslottotake)
		active = TRUE
		update_icon()
		START_PROCESSING(SSobj, src)
		stop = world.time + selection.song_length
		return TRUE
	else
		return FALSE

/obj/machinery/jukebox/disco/activate_music()
	..()
	dance_setup()
	lights_spin()

/obj/machinery/jukebox/disco/proc/dance_setup()
	var/turf/cen = get_turf(src)
	FOR_DVIEW(var/turf/t, 3, get_turf(src),INVISIBILITY_LIGHTING)
		if(t.x == cen.x && t.y > cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_RED)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1+get_dist(src, L)
			spotlights+=L
			continue
		if(t.x == cen.x && t.y < cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_PURPLE)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1+get_dist(src, L)
			spotlights+=L
			continue
		if(t.x > cen.x && t.y == cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_YELLOW)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1+get_dist(src, L)
			spotlights+=L
			continue
		if(t.x < cen.x && t.y == cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_GREEN)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x+1 == cen.x && t.y+1 == cen.y) || (t.x+2==cen.x && t.y+2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_ORANGE)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x-1 == cen.x && t.y-1 == cen.y) || (t.x-2==cen.x && t.y-2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_CYAN)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x-1 == cen.x && t.y+1 == cen.y) || (t.x-2==cen.x && t.y+2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_BLUEGREEN)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x+1 == cen.x && t.y-1 == cen.y) || (t.x+2==cen.x && t.y-2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.set_light_color(LIGHT_COLOR_BLUE)
			L.set_light_power(30-(get_dist(src,L)*8))
			L.range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		continue
	FOR_DVIEW_END

/obj/machinery/jukebox/disco/proc/hierofunk()
	for(var/i in 1 to 10)
		spawn_atom_to_turf(/obj/effect/temp_visual/hierophant/telegraph/edge, src, 1, FALSE)
		sleep(5)
		if(QDELETED(src))
			return

#define DISCO_INFENO_RANGE (rand(85, 115)*0.01)

/obj/machinery/jukebox/disco/proc/lights_spin()
	for(var/i in 1 to 25)
		if(QDELETED(src) || !active)
			return
		var/obj/effect/overlay/sparkles/S = new /obj/effect/overlay/sparkles(src)
		S.alpha = 0
		sparkles += S
		switch(i)
			if(1 to 8)
				S.orbit(src, 30, TRUE, 60, 36, TRUE)
			if(9 to 16)
				S.orbit(src, 62, TRUE, 60, 36, TRUE)
			if(17 to 24)
				S.orbit(src, 95, TRUE, 60, 36, TRUE)
			if(25)
				S.pixel_y = 7
				S.forceMove(get_turf(src))
		sleep(7)
	if(selection.song_name == "Engineering's Ultimate High-Energy Hustle")
		sleep(280)
	for(var/obj/reveal in sparkles)
		reveal.alpha = 255
	while(active)
		for(var/obj/item/flashlight/spotlight/glow in spotlights) // The multiples reflects custom adjustments to each colors after dozens of tests
			if(QDELETED(src) || !active || QDELETED(glow))
				return
			if(glow.light_color == LIGHT_COLOR_RED)
				glow.set_light_color(LIGHT_COLOR_BLUE)
				glow.set_light_power(glow.light_power * 1.48)
				glow.set_light_range(0)
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_BLUE)
				glow.set_light_color(LIGHT_COLOR_GREEN)
				glow.set_light_range(glow.range * DISCO_INFENO_RANGE)
				glow.set_light_power(glow.light_power * 2 )// Any changes to power must come in pairs to neutralize it for other colors
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_GREEN)
				glow.set_light_color(LIGHT_COLOR_ORANGE)
				glow.set_light_power(glow.light_power * 0.5)
				glow.set_light_range(0)
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_ORANGE)
				glow.set_light_color(LIGHT_COLOR_PURPLE)
				glow.set_light_power(glow.light_power * 2.27)
				glow.set_light_range(glow.range * DISCO_INFENO_RANGE)
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_PURPLE)
				glow.set_light_color(LIGHT_COLOR_BLUEGREEN)
				glow.set_light_power(glow.light_power * 0.44)
				glow.set_light_range(0)
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_BLUEGREEN)
				glow.set_light_color(LIGHT_COLOR_YELLOW)
				glow.set_light_range(glow.range * DISCO_INFENO_RANGE)
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_YELLOW)
				glow.set_light_color(LIGHT_COLOR_CYAN)
				glow.set_light_range(0)
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_CYAN)
				glow.set_light_color(LIGHT_COLOR_RED)
				glow.set_light_power(glow.light_power * 0.68)
				glow.set_light_range(glow.range * DISCO_INFENO_RANGE)
				glow.update_light()
				continue
		if(prob(2))  // Unique effects for the dance floor that show up randomly to mix things up
			INVOKE_ASYNC(src, PROC_REF(hierofunk))
		sleep(selection.song_beat)

#undef DISCO_INFENO_RANGE

/obj/machinery/jukebox/disco/proc/dance(mob/living/M) //Show your moves
	set waitfor = FALSE
	switch(rand(0,9))
		if(0 to 1)
			dance2(M)
		if(2 to 3)
			dance3(M)
		if(4 to 6)
			dance4(M)
		if(7 to 9)
			dance5(M)

/obj/machinery/jukebox/disco/proc/dance2(mob/living/M)
	for(var/i = 1, i < 10, i++)
		for(var/d in list(NORTH,SOUTH,EAST,WEST,EAST,SOUTH,NORTH,SOUTH,EAST,WEST,EAST,SOUTH))
			M.setDir(d)
			if(i == WEST && !M.incapacitated())
				M.SpinAnimation(7, 1)
			sleep(1)
		sleep(20)

/obj/machinery/jukebox/disco/proc/dance3(mob/living/M)
	var/matrix/initial_matrix = matrix(M.transform)
	for (var/i in 1 to 75)
		if (!M)
			return
		switch(i)
			if (1 to 15)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (16 to 30)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(1,-1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (31 to 45)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-1,-1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (46 to 60)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-1,1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (61 to 75)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(1,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		M.setDir(turn(M.dir, 90))
		switch (M.dir)
			if (NORTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (SOUTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,-3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (EAST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (WEST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		sleep(1)
	M.lying_fix()


/obj/machinery/jukebox/disco/proc/dance4(mob/living/M)
	var/speed = rand(1,3)
	set waitfor = 0
	var/time = 30
	while(time)
		sleep(speed)
		for(var/i in 1 to speed)
			M.setDir(pick(GLOB.cardinals))
			// update resting manually to avoid chat spam CITADEL EDIT - NO MORE RESTSPAM
			//for(mob/living/carbon/NS in rangers)
			//	NS.resting = !NS.resting
			//	NS.update_canmove()
		time--

/obj/machinery/jukebox/disco/proc/dance5(mob/living/M)
	animate(M, transform = matrix(180, MATRIX_ROTATE), time = 1, loop = 0)
	var/matrix/initial_matrix = matrix(M.transform)
	for (var/i in 1 to 60)
		if (!M)
			return
		if (i<31)
			initial_matrix = matrix(M.transform)
			initial_matrix.Translate(0,1)
			animate(M, transform = initial_matrix, time = 1, loop = 0)
		if (i>30)
			initial_matrix = matrix(M.transform)
			initial_matrix.Translate(0,-1)
			animate(M, transform = initial_matrix, time = 1, loop = 0)
		M.setDir(turn(M.dir, 90))
		switch (M.dir)
			if (NORTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (SOUTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,-3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (EAST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (WEST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		sleep(1)
	M.lying_fix()

/mob/living/proc/lying_fix()
	animate(src, transform = null, time = 1, loop = 0)
	lying_prev = 0

/obj/machinery/jukebox/proc/dance_over()
	var/position = SSjukeboxes.findjukeboxindex(src)
	if(!position)
		return
	SSjukeboxes.removejukebox(position)
	STOP_PROCESSING(SSobj, src)
	rangers = list()

/obj/machinery/jukebox/disco/dance_over()
	..()
	QDEL_LIST(spotlights)
	QDEL_LIST(sparkles)

/obj/machinery/jukebox/process()
	if(active && world.time >= stop)
		active = FALSE
		dance_over()
		playsound(src,'sound/machines/terminal_off.ogg',50,1)
		update_icon()
		stop = world.time + 100


/obj/machinery/jukebox/disco/process()
	. = ..()
	if(active)
		for(var/mob/living/M in rangers)
			if(prob(5+(allowed(M)*4)) && CHECK_MOBILITY(M, MOBILITY_MOVE))
				dance(M)

/obj/item/record_disk //BIG IRON EDIT START- the objets used in the creation o music
	name = "record disk" //used to store tracks to add to the jukeboxes
	desc = "A disk for storing music. Dear god."
	icon = 'icons/obj/machines/disk_recorder.dmi'
	icon_state = "record_disk"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	force = 5
	throwforce = 16
	throw_speed = 2
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("sliced", "DISKED", "Played music to")
	siemens_coefficient = 0 //Means it's insulated
	sharpness = SHARP_EDGED
	resistance_flags = NONE
	max_integrity = 45
	var/datum/track/R = new ()

/obj/item/record_disk/Initialize() //moves them a bit so they are not all accumulated on the same pixel
	..()
	name = "Generic record disk" // the name changes with music
	pixel_x = rand(-3, 3)
	pixel_y = rand(-3, 3)

/obj/item/record_disk/throw_impact() //since they are not made with petrolium they are a bit more fragile
	..()
	src.visible_message("<span class ='warning'>The spinning [src] shatters on impact!</span>")
	Destroy()

/obj/item/record_disk/Destroy()
	playsound(src, 'sound/effects/record_shatter.ogg', 100, 0)
	new /obj/item/record_shard(get_turf(src))
	new /obj/item/record_shard(get_turf(src))
	new /obj/item/record_shard(get_turf(src))
	new /obj/item/record_shard(get_turf(src))
	new /obj/item/record_shard(get_turf(src))
	..()
/obj/item/record_shard //if the disk breaks you get pieces of disk that can cut into your feet if you are not carefull
	name = "record disk shard"
	desc = "A broken shard of a record disk. Who knew record disks were so fragile."
	icon = 'icons/obj/machines/disk_recorder.dmi'
	icon_state = "record_shard"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	force = 5
	throwforce = 8
	attack_verb = list("stabs", "DISKED", "sliced")
	hitsound = 'sound/weapons/bladeslice.ogg'
	resistance_flags = ACID_PROOF
	armor = list("melee" = 100, "bullet" = 0, "laser" = 0, "energy" = 100, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 100)
	max_integrity = 40
	sharpness = SHARP_POINTY

/obj/item/record_shard/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is slitting [user.p_their()] [pick("wrists", "throat")] with the record disk shard! It looks like [user.p_theyre()] trying to commit suicide.</span>")
	return (BRUTELOSS)

/obj/item/record_shard/Initialize()
	. = ..()
	AddComponent(/datum/component/caltrop, force)
	AddComponent(/datum/component/butchering, 150, 65)
	pixel_x = rand(-8, 8)
	pixel_y = rand(-8, 8)

/obj/item/record_shard/afterattack(atom/A as mob|obj, mob/user, proximity)
	. = ..()
	if(!proximity || !(src in user))
		return
	if(isturf(A))
		return
	if(istype(A, /obj/item/storage))
		return
	var/hit_hand = ((user.active_hand_index % 2 == 0) ? "r_" : "l_") + "arm"
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!H.gloves && !HAS_TRAIT(H, TRAIT_PIERCEIMMUNE)) // golems, etc
			to_chat(H, span_warning("[src] cuts into your hand!"))
			H.apply_damage(force*0.5, BRUTE, hit_hand)
	else if(ismonkey(user))
		var/mob/living/carbon/monkey/M = user
		if(!HAS_TRAIT(M, TRAIT_PIERCEIMMUNE))
			to_chat(M, span_warning("[src] cuts into your hand!"))
			M.apply_damage(force*0.5, BRUTE, hit_hand)

/obj/machinery/gramophone_recorder //used to record new tracks to add to the jukeboxes, due to the nature of such Admin Discretion is advised when when given to the playerbase 
	name = "Gramophone Recorder"
	desc = "old gramaphone used to record sounds and audio."
	icon = 'icons/obj/machines/disk_recorder.dmi'
	icon_state = "gramophone_recorder"
	verb_say = "transmit"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/gramophone_recorder
	var/list/music_to_burn
	var/obj/item/record_disk/R //Our stored record disk
	var/inuse = FALSE
	var/list/menu_options = list("EJECT", "Burn existing music", "Burn custom music", "Rename disk", "Update Songs Library")
	var/datum/track/music_file = null
	var/custom_name
	var/loaded_song_path
	var/loaded_song_name
	var/loaded_song_length
	var/loaded_song_beat
	var/loaded_song_associated_id

/obj/machinery/gramophone_recorder/Initialize()
	. = ..()
	Update_library()
	update_icon()

/obj/machinery/gramophone_recorder/proc/Update_library() //this is used to check for the currently loaded songs
	var/list/available[SSjukeboxes.songs.len]
	if(available == null)
		src.visible_message("<span class='warning'>no song in library</span>")
	for(var/datum/track/S in SSjukeboxes.songs)
		available[S.song_name] = S
	music_to_burn = available
	src.visible_message("<span class='warning'> music library has been updated.")

/obj/machinery/gramophone_recorder/proc/diskProcess() //its an old piece of tech and it takes it's time
	addtimer(CALLBACK(src, .proc/burnDisk), 40)
	inuse = TRUE
	src.visible_message("<span class='warning'>your disk is being burned, please stand by.")

/obj/machinery/gramophone_recorder/proc/burnDisk() //basically just burns the gathered info into the loaded disk
	if(!R)
		visible_message("<span class ='warning'>There's no disk to burn!</span>")
		inuse = FALSE
		return
	R.R.song_path = loaded_song_path
	R.R.song_name = loaded_song_name
	R.R.song_length = loaded_song_length
	R.R.song_beat = loaded_song_beat
	R.R.song_associated_id = loaded_song_associated_id
	R.name = "[R.R.song_name] record disk"
	playsound(src, 'sound/machines/ping.ogg', 50, 1)
	src.visible_message("<span class='warning'> [R] is ready!.")
	inuse = FALSE

/obj/machinery/gramophone_recorder/attack_hand(mob/living/user)
	if(stat & NOPOWER || stat & BROKEN)
		update_icon()
		return
	if(!R)
		to_chat(user, "<span class='warning'>There is no record disk inserted!</span>")
		return
	if(inuse)
		to_chat(user, "<span class ='warning'>A disk is currently being burned!</span>")
		return
	var/choice = input(user, "Disk: [R] \nChoose an option", "[src] menu") as null|anything in menu_options
	if(!user.Adjacent(src))
		to_chat(user, "<span class='warning'>You are too far away!")
		return
	if(inuse)
		to_chat(user, "<span class ='warning'>A disk is currently being burned!</span>")
		return
	switch(choice)
		if(null)
			return
		if("EJECT")
			if(inuse == TRUE)
				to_chat(user, "<span class ='warning'>There's no disk to burn!</span>")
				return
			playsound(src, 'sound/effects/disk_tray.ogg', 100, 0)
			src.visible_message("<span class ='notice'>[user] ejects the [R] from the [src]!</span>")
			R.forceMove(get_turf(src))
			R = null
			icon_state = "gramophone_recorder"
			return
		if("Burn existing music")
			if(!SSjukeboxes.songs.len)
				src.visible_message("<span class ='notice'> No songs loaded!")
				return
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			music_file = input(user, "Choose a song from the library", "[src] menu") as null|anything in music_to_burn
			if(QDELETED(src) || !music_file || !istype(available[music_file], /datum/track))
				return
			music_file = available[music_file]
			loaded_song_path = music_file
			loaded_song_name = music_file.song_name
			loaded_song_length = music_file.song_length
			loaded_song_beat = music_file.song_beat
			loaded_song_associated_id = "CS[music_file.song_associated_id]"
			diskProcess()
		if("Burn custom music")
			loaded_song_path = input(user, "Choose a custom song!") as null|sound //uses the server AllowedUpload, by the time of writting,it was about 1024kb
			if(loaded_song_path == null)
				return
			loaded_song_name = input(user, "Enter the song's name") as null|text
			if(loaded_song_name == null)
				loaded_song_name = "CUSTOM"
			loaded_song_length = input(user, "enter the song's duration (in seconds)") as null|text
			loaded_song_length = text2num(loaded_song_length)
			loaded_song_length *= 10 //why is server time in 0.1
			if(loaded_song_length == null || !isnum(loaded_song_length))
				loaded_song_length = 1800 //3 minutes is good for most songs, no?
			loaded_song_beat = 10
			loaded_song_associated_id = "CS00[loaded_song_path]" //while originally not used for much, associated ID can be used to identify different files when checking for songs to add
			if(inuse)
				to_chat(user, "<span class ='warning'>A disk is currently being burned!</span>")
				return
			diskProcess()
		if("Rename disk")
			custom_name = input(user, "Enter new disk name") as null|text
			if(custom_name)
				R.name = custom_name
				src.audible_message("<span class='robot'><b>[src]</b> beeps, 'Record disk renamed to: [R]' </span>")
				custom_name = null
			else
				to_chat(user, "<span class='warning'>Name selection invalid.</span>")
		if("Update Songs Library")
			Update_library()
			src.audible_message("<span class='robot'><b>[src]</b> beeps, 'updated music library</span>")

/obj/machinery/gramophone_recorder/attackby(obj/item/I, mob/user)
	if(stat & NOPOWER || stat & BROKEN)
		update_icon()
		return
	if(istype(I, /obj/item/record_disk))
		if(!R) //only one disk on the tray
			R = I
			I.forceMove(src)
			playsound(src, 'sound/effects/disk_tray.ogg', 100, 0)
			usr.visible_message("<span class='notice'>[user] loads the [R] into the [src].</span>")
			icon_state = "loaded_recorder"
			return
		else
			to_chat(user, "<span class ='warning'>There is already a record disk loaded into the [src]!</span>")
			return
	..()

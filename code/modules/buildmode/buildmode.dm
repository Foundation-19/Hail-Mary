#define BM_SWITCHSTATE_NONE	0
#define BM_SWITCHSTATE_MODE	1
#define BM_SWITCHSTATE_DIR	2

/datum/buildmode
	var/build_dir = SOUTH
	var/datum/buildmode_mode/mode
	var/client/holder

	// login callback
	var/li_cb

	// SECTION UI
	var/list/buttons

	// Switching management
	var/switch_state = BM_SWITCHSTATE_NONE
	var/switch_width = 5
	// modeswitch UI
	var/obj/screen/buildmode/mode/modebutton
	var/list/modeswitch_buttons = list()
	// dirswitch UI
	var/obj/screen/buildmode/bdir/dirbutton
	var/list/dirswitch_buttons = list()

/datum/buildmode/New(client/c)
	mode = new /datum/buildmode_mode/basic(src)
	holder = c
	buttons = list()
	li_cb = CALLBACK(src, PROC_REF(post_login))
	holder.player_details.post_login_callbacks += li_cb
	holder.show_popup_menus = FALSE
	create_buttons()
	holder.screen += buttons
	holder.click_intercept = src
	mode.enter_mode(src)
	
TYPE_PROC_REF(/datum/buildmode, quit)()
	mode.exit_mode(src)
	holder.screen -= buttons
	holder.click_intercept = null
	holder.show_popup_menus = TRUE
	qdel(src)

/datum/buildmode/Destroy()
	close_switchstates()
	holder.player_details.post_login_callbacks -= li_cb
	holder = null
	QDEL_NULL(mode)
	QDEL_LIST(modeswitch_buttons)
	QDEL_LIST(dirswitch_buttons)
	return ..()

TYPE_PROC_REF(/datum/buildmode, post_login)()
	// since these will get wiped upon login
	holder.screen += buttons
	// re-open the according switch mode
	switch(switch_state)
		if(BM_SWITCHSTATE_MODE)
			open_modeswitch()
		if(BM_SWITCHSTATE_DIR)
			open_dirswitch()

TYPE_PROC_REF(/datum/buildmode, create_buttons)()
	// keep a reference so we can update it upon mode switch
	modebutton = new /obj/screen/buildmode/mode(src)
	buttons += modebutton
	buttons += new /obj/screen/buildmode/help(src)
	// keep a reference so we can update it upon dir switch
	dirbutton = new /obj/screen/buildmode/bdir(src)
	buttons += dirbutton
	buttons += new /obj/screen/buildmode/quit(src)
	// build the lists of switching buttons
	build_options_grid(subtypesof(/datum/buildmode_mode), modeswitch_buttons, /obj/screen/buildmode/modeswitch)
	build_options_grid(list(SOUTH,EAST,WEST,NORTH,NORTHWEST), dirswitch_buttons, /obj/screen/buildmode/dirswitch)

// this creates a nice offset grid for choosing between buildmode options,
// because going "click click click ah hell" sucks.
TYPE_PROC_REF(/datum/buildmode, build_options_grid)(list/elements, list/buttonslist, buttontype)
	var/pos_idx = 0
	for(var/thing in elements)
		var/x = pos_idx % switch_width
		var/y = FLOOR(pos_idx / switch_width, 1)
		var/obj/screen/buildmode/B = new buttontype(src, thing)
		// extra .5 for a nice offset look
		B.screen_loc = "NORTH-[(1 + 0.5 + y*1.5)],WEST+[0.5 + x*1.5]"
		buttonslist += B
		pos_idx++

TYPE_PROC_REF(/datum/buildmode, close_switchstates)()
	switch(switch_state)
		if(BM_SWITCHSTATE_MODE)
			close_modeswitch()
		if(BM_SWITCHSTATE_DIR)
			close_dirswitch()

TYPE_PROC_REF(/datum/buildmode, toggle_modeswitch)()
	if(switch_state == BM_SWITCHSTATE_MODE)
		close_modeswitch()
	else
		close_switchstates()
		open_modeswitch()
	
TYPE_PROC_REF(/datum/buildmode, open_modeswitch)()
	switch_state = BM_SWITCHSTATE_MODE
	holder.screen += modeswitch_buttons

TYPE_PROC_REF(/datum/buildmode, close_modeswitch)()
	switch_state = BM_SWITCHSTATE_NONE
	holder.screen -= modeswitch_buttons

TYPE_PROC_REF(/datum/buildmode, toggle_dirswitch)()
	if(switch_state == BM_SWITCHSTATE_DIR)
		close_dirswitch()
	else
		close_switchstates()
		open_dirswitch()
	
TYPE_PROC_REF(/datum/buildmode, open_dirswitch)()
	switch_state = BM_SWITCHSTATE_DIR
	holder.screen += dirswitch_buttons

TYPE_PROC_REF(/datum/buildmode, close_dirswitch)()
	switch_state = BM_SWITCHSTATE_NONE
	holder.screen -= dirswitch_buttons

TYPE_PROC_REF(/datum/buildmode, change_mode)(newmode)
	mode.exit_mode(src)
	QDEL_NULL(mode)
	close_switchstates()
	mode = new newmode(src)
	mode.enter_mode(src)
	modebutton.update_icon()

TYPE_PROC_REF(/datum/buildmode, change_dir)(newdir)
	build_dir = newdir
	close_dirswitch()
	dirbutton.update_icon()
	return 1

TYPE_PROC_REF(/datum/buildmode, InterceptClickOn)(mob/user, params, atom/object)
	mode.handle_click(user.client, params, object)
	return TRUE // no doing underlying actions

/proc/togglebuildmode(mob/M as mob in GLOB.player_list)
	set name = "Toggle Build Mode"
	set category = "Event"

	if(M.client)
		if(istype(M.client.click_intercept,/datum/buildmode))
			var/datum/buildmode/B = M.client.click_intercept
			B.quit()
			log_admin("[key_name(usr)] has left build mode.")
		else
			new /datum/buildmode(M.client)
			message_admins("[key_name_admin(usr)] has entered build mode.")
			log_admin("[key_name(usr)] has entered build mode.")
	
#undef BM_SWITCHSTATE_NONE
#undef BM_SWITCHSTATE_MODE
#undef BM_SWITCHSTATE_DIR

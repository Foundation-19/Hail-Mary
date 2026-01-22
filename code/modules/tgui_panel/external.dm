/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/client/var/datum/tgui_panel/tgui_panel

/client/proc/load_statbrowser()
	// Clear the subsystem's cached images for this client
	if(mob?.listed_turf)
		mob.listed_turf = null
	
	// Clear the global image cache in the statpanels subsystem
	SSstatpanels.cached_images.Cut()
	
	// Close the old window completely to clear all cached data
	src << browse(null, "window=statbrowser")
	
	// Small delay to ensure window closes
	sleep(3)
	
	// Reload the statbrowser fresh
	src << browse(file('html/statbrowser.html'), "window=statbrowser")
	
	// Wait for HTML to load, then reinitialize everything
	spawn(15)
		init_verbs() // Restore all verb tabs
		
		// Restore admin tabs if they're an admin
		if(holder)
			src << output("[url_encode(holder.href_token)]", "statbrowser:add_admin_tabs")
		
		// Set theme to dark mode
		src << output("dark", "statbrowser:set_theme")

/**
 * tgui panel / chat troubleshooting verb
 */
/client/verb/fix_tgui_panel()
	set name = "Fix chat"
	set category = "OOC"
	var/action
	log_tgui(src, "Started fixing.", context = "verb/fix_tgui_panel")

	nuke_chat()
	
	// Also fix statpanel at the same time
	load_statbrowser()

	// Failed to fix, using tgalert as fallback
	action = tgalert(src, "Did that work?", "", "Yes", "No, switch to old ui")
	if (action == "No, switch to old ui")
		winset(src, "output", "on-show=&is-disabled=0&is-visible=1")
		winset(src, "browseroutput", "is-disabled=1;is-visible=0")
		log_tgui(src, "Failed to fix.", context = "verb/fix_tgui_panel")

/client/verb/fix_statpanel()
	set name = "Fix Statpanel"
	set category = "OOC"
	
	load_statbrowser()
	to_chat(src, span_notice("Statpanel reloaded. Icons should load correctly now when you alt+click."))

/client/proc/nuke_chat()
	// Catch all solution (kick the whole thing in the pants)
	winset(src, "output", "on-show=&is-disabled=0&is-visible=1")
	winset(src, "browseroutput", "is-disabled=1;is-visible=0")
	if(!tgui_panel || !istype(tgui_panel))
		log_tgui(src, "tgui_panel datum is missing",
			context = "verb/fix_tgui_panel")
		tgui_panel = new(src)
	tgui_panel.initialize(force = TRUE)
	// Force show the panel to see if there are any errors
	winset(src, "output", "is-disabled=1&is-visible=0")
	winset(src, "browseroutput", "is-disabled=0;is-visible=1")

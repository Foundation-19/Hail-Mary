/datum/verbs/menu/Admin/Generate_list(client/C)
	if (C.holder)
		. = ..()

/datum/verbs/menu/Admin/verb/playerpanel()
	set name = "Player Panel"
	set desc = "Player Panel"
	set category = "Admin.Game"
	if(usr.client.holder)
		usr.client.holder.player_panel_tgui()
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Player Panel New") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/verbs/menu/Admin/verb/gamepanel()
	set name = "Game Panel"
	set desc = "Game Panel"
	set category = "Admin.Game"
	if(usr.client.holder)
		usr.client.holder.game_panel_tgui()
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Game Panel TGUI")

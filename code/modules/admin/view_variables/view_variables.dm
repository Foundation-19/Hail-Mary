/client/proc/debug_variables(datum/D in world)
	set category = "Debug"
	set name = "View Variables"
	
	if(!usr.client || !usr.client.holder)
		to_chat(usr, span_danger("You need to be an administrator to access this."), confidential = TRUE)
		return
	
	if(!D)
		return
	
	debug_variables_tgui(D)

/client/proc/vv_update_display(datum/D, span, content)
	src << output("[span]:[content]", "variables[REF(D)].browser:replace_span")

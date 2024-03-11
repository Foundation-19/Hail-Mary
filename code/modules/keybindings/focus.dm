TYPE_PROC_REF(/mob, set_focus)(datum/new_focus)
	if(focus == new_focus)
		return
	focus = new_focus
	reset_perspective(focus) //Maybe this should be done manually? You figure it out, reader

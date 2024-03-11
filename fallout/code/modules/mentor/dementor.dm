TYPE_PROC_REF(/client, cmd_mentor_dementor)()
	set category = "Mentor"
	set name = "dementor"
	if(!is_mentor())
		return
	remove_mentor_verbs()
	if (TYPE_PROC_REF(/client, mentor_unfollow) in verbs)
		mentor_unfollow()
	GLOB.mentors -= src
	add_verb(src, TYPE_PROC_REF(/client, cmd_mentor_rementor))
	
TYPE_PROC_REF(/client, cmd_mentor_rementor)()
	set category = "Mentor"
	set name = "rementor"
	if(!is_mentor())
		return
	add_mentor_verbs()
	GLOB.mentors += src
	remove_verb(src, TYPE_PROC_REF(/client, cmd_mentor_rementor))

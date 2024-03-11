GLOBAL_LIST_INIT(mentor_verbs, list(
	TYPE_PROC_REF(/client, cmd_mentor_say),
	TYPE_PROC_REF(/client, show_mentor_memo),
	TYPE_PROC_REF(/client, cmd_mentor_dementor)
	))
GLOBAL_PROTECT(mentor_verbs)

TYPE_PROC_REF(/client, add_mentor_verbs)()
	if(mentor_datum)
		add_verb(src, GLOB.mentor_verbs)

TYPE_PROC_REF(/client, remove_mentor_verbs)()
	remove_verb(src, GLOB.mentor_verbs)

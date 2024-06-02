SUBSYSTEM_DEF(grace)
	name = "Grace Period End"
	var/allowed_firings = 1

/datum/controller/subsystem/grace/fire()
	if(allowed_firings)
		addtimer(CALLBACK(src, .proc/announce_over), 30 MINUTES)
		allowed_firings = FALSE // unfuck this later.

/datum/controller/subsystem/grace/proc/announce_over()
	for(var/M in GLOB.player_list)
		to_chat(M, "[span_minorannounce("<font color = red>["Grace Over"]</font color><BR>["You feel the wind grow tense with violence. The Wasteland has grown a shade more violent."]")]<BR>")

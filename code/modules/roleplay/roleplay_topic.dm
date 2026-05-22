// Called from client_procs.dm - do NOT define /client/Topic here

// Main entry point - call this from client_procs.dm
/proc/handle_roleplay_topic(client/C, href_list)
	if(!C || !href_list)
		return FALSE
	
	// Try each handler in turn
	if(handle_relationships_topic(C, href_list))
		return TRUE
	if(handle_backgrounds_topic(C, href_list))
		return TRUE
	if(handle_perks_topic(C, href_list))
		return TRUE
	if(handle_player_stats_topic(C, href_list))
		return TRUE
	
	return FALSE

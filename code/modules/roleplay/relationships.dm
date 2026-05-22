// Tracks player-to-player relationships

GLOBAL_LIST_INIT(relationship_types, list("friend", "enemy", "family", "rival", "mentor", "student"))
GLOBAL_LIST_EMPTY(relationship_proposals)

/datum/relationship_proposal
	var/mob/proposer
	var/mob/target
	var/rel_type
	var/description

// Get all relationships for a player
/proc/get_relationships(ckey)
	if(!SSdbcore.Connect())
		return list()
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT char_1, char_2, relationship_type, description, is_secret FROM [format_table_name("character_relationships")] WHERE char_1 = :ckey OR char_2 = :ckey",
		list("ckey" = ckey)
	)
	
	var/list/relationships = list()
	if(query.Execute())
		while(query.NextRow())
			var/other_char = query.item[1] == ckey ? query.item[2] : query.item[1]
			var/rel_type = query.item[3]
			var/description = query.item[4]
			var/is_secret = text2num(query.item[5])
			
			relationships[other_char] = list(
				"type" = rel_type,
				"description" = description,
				"secret" = is_secret
			)
	
	qdel(query)
	return relationships

// Get specific relationship between two players
/proc/get_relationship(ckey1, ckey2)
	if(!SSdbcore.Connect())
		return null
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT relationship_type, description, is_secret FROM [format_table_name("character_relationships")] WHERE (char_1 = :ckey1 AND char_2 = :ckey2) OR (char_1 = :ckey2 AND char_2 = :ckey1)",
		list("ckey1" = ckey1, "ckey2" = ckey2)
	)
	
	var/list/relationship = null
	if(query.Execute() && query.NextRow())
		relationship = list(
			"type" = query.item[1],
			"description" = query.item[2],
			"secret" = text2num(query.item[3])
		)
	
	qdel(query)
	return relationship

// Set or update a relationship
/proc/set_relationship(ckey1, ckey2, rel_type, description = "", secret = FALSE)
	if(!SSdbcore.Connect())
		return FALSE
	
	if(!(rel_type in GLOB.relationship_types))
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("character_relationships")] (char_1, char_2, relationship_type, description, is_secret) VALUES (:ckey1, :ckey2, :type, :desc, :secret) ON DUPLICATE KEY UPDATE relationship_type = :type, description = :desc, is_secret = :secret",
		list("ckey1" = ckey1, "ckey2" = ckey2, "type" = rel_type, "desc" = description, "secret" = secret ? 1 : 0)
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

// Remove a relationship
/proc/remove_relationship(ckey1, ckey2)
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"DELETE FROM [format_table_name("character_relationships")] WHERE (char_1 = :ckey1 AND char_2 = :ckey2) OR (char_1 = :ckey2 AND char_2 = :ckey1)",
		list("ckey1" = ckey1, "ckey2" = ckey2)
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

// Get relationship description
/proc/get_relationship_desc(ckey1, ckey2)
	var/list/rel = get_relationship(ckey1, ckey2)
	if(!rel)
		return null
	
	var/type = rel["type"]
	var/desc = rel["description"]
	
	switch(type)
		if("friend")
			return desc ? desc : "A trusted friend"
		if("enemy")
			return desc ? desc : "A bitter enemy"
		if("family")
			return desc ? desc : "Family member"
		if("rival")
			return desc ? desc : "A bitter rival"
		if("mentor")
			return desc ? desc : "Your teacher"
		if("student")
			return desc ? desc : "Your pupil"
	
	return null

// Mob helpers
/mob/proc/get_relationships()
	return get_relationships(ckey)

/mob/proc/get_relationship_with(mob/other)
	return get_relationship(ckey, other.ckey)

// Relationship effects
/proc/get_relationship_damage_mod(ckey1, ckey2)
	var/list/rel = get_relationship(ckey1, ckey2)
	if(!rel)
		return 1.0
	
	switch(rel["type"])
		if("friend")
			return 0.8
		if("family")
			return 0.5
		if("enemy")
			return 1.2
		if("rival")
			return 1.1
	
	return 1.0

// Player verb to propose relationship
/client/verb/propose_relationship()
	set name = "Propose Relationship"
	set category = "Admin"
	set desc = "Propose a relationship with another player nearby"
	
	var/list/possible_targets = list()
	for(var/mob/living/player in view(7, usr))
		if(player != usr && player.ckey && player.client)
			possible_targets[player.name] = player
	
	if(!possible_targets.len)
		to_chat(usr, span_warning("No other players nearby."))
		return
	
	var/mob/target = input(usr, "Choose a player:", "Propose Relationship") as null|anything in possible_targets
	if(!target)
		return
	
	if(get_dist(usr, target) > 7)
		to_chat(usr, span_warning("[target.name] is too far away."))
		return
	
	var/rel_type = input(usr, "What type of relationship?", "Relationship Type") as null|anything in GLOB.relationship_types
	if(!rel_type)
		return
	
	var/description = input(usr, "Add a description (optional):", "Description") as text|null
	
	var/datum/relationship_proposal/proposal = new
	proposal.proposer = usr
	proposal.target = target
	proposal.rel_type = rel_type
	proposal.description = description || ""
	
	GLOB.relationship_proposals[target.ckey] = proposal
	
	to_chat(usr, span_notice("You proposed a [rel_type] relationship with [target.name]. Waiting for response..."))
	to_chat(target, span_notice("<b>[usr.name] wants to establish a [rel_type] relationship with you.</b><br>Description: [description]<br><a href='?src=[REF(src)];respond_relationship=accept'>Accept</a> | <a href='?src=[REF(src)];respond_relationship=decline'>Decline</a>"))

// Player verb to view relationships
/client/verb/view_relationships()
	set name = "View Relationships"
	set category = "Character"
	set desc = "View your relationships with other players"
	
	var/list/rels = get_relationships(ckey)
	
	if(!rels.len)
		to_chat(usr, span_notice("You have no relationships."))
		return
	
	var/dat = "<center><h2>Your Relationships</h2></center><br>"
	
	for(var/other_ckey in rels)
		var/list/rel = rels[other_ckey]
		var/type = rel["type"]
		var/description = rel["description"]
		var/secret = rel["secret"]
		
		dat += "<h3>[other_ckey] - [type]</h3>"
		if(description)
			dat += "<p>[description]</p>"
		if(secret)
			dat += "<p><i>(Secret)</i></p>"
		
		dat += "<p><a href='?src=[REF(src)];remove_relationship=[other_ckey]'>Remove Relationship</a></p><br>"
	
	usr << browse(dat, "window=relationships;size=500x600")

// Handle relationship Topic calls - called from client_procs.dm
/proc/handle_relationships_topic(client/C, href_list)
	if(href_list["respond_relationship"])
		var/response = href_list["respond_relationship"]
		var/datum/relationship_proposal/proposal = GLOB.relationship_proposals[C.ckey]
		
		if(!proposal || !proposal.proposer || !proposal.target)
			to_chat(C.mob, span_warning("This proposal is no longer valid."))
			return TRUE
	
		var/mob/proposer = proposal.proposer
		var/mob/target = proposal.target
		
		if(response == "accept")
			set_relationship(proposer.ckey, target.ckey, proposal.rel_type, proposal.description)
			to_chat(proposer, span_notice("[target.name] accepted your proposal!"))
			to_chat(target, span_notice("You now have a [proposal.rel_type] relationship with [proposer.name]."))
		else
			to_chat(proposer, span_warning("[target.name] declined your proposal."))
			to_chat(target, span_notice("You declined the proposal."))
		
		GLOB.relationship_proposals -= C.ckey
		qdel(proposal)
		return TRUE
	
	if(href_list["remove_relationship"])
		var/other_ckey = href_list["remove_relationship"]
		remove_relationship(C.ckey, other_ckey)
		to_chat(C.mob, span_notice("Relationship removed."))
		C.mob << browse(null, "window=relationships")
		C.view_relationships()
		return TRUE
	
	return FALSE

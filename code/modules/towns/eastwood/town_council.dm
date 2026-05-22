// Eastwood Town Council
// Elected governance with voting on laws and policies

// ============ CITIZEN DATUM ============

/datum/eastwood_citizen
	var/ckey
	var/name
	var/citizenship_date
	var/criminal_record = FALSE
	var/voted_this_election = FALSE

/datum/eastwood_citizen/proc/can_vote()
	return citizenship_date && !criminal_record

/datum/eastwood_citizen/proc/can_run_for_council()
	return can_vote() && (world.time - citizenship_date) >= (RESIDENCY_REQUIREMENT_DAYS * 24 * 60 * 10)

// ============ TOWN COUNCIL ============

/datum/eastwood_council
	var/list/council_members = list()
	var/list/candidates = list()
	var/list/proposed_laws = list()
	var/list/enacted_laws = list()
	var/election_start_time = 0
	var/election_active = FALSE
	var/term_end_time = 0
	var/mayor_ckey = null
	var/list/votes = list()

/datum/eastwood_council/proc/is_citizen(ckey)
	for(var/datum/eastwood_citizen/C in GLOB.eastwood_citizens)
		if(C.ckey == ckey)
			return TRUE
	return FALSE

/datum/eastwood_council/proc/get_citizen(ckey)
	for(var/datum/eastwood_citizen/C in GLOB.eastwood_citizens)
		if(C.ckey == ckey)
			return C
	return null

/datum/eastwood_council/proc/grant_citizenship(mob/user)
	if(is_citizen(user.ckey))
		return FALSE

	var/datum/eastwood_citizen/new_citizen = new()
	new_citizen.ckey = user.ckey
	new_citizen.name = user.name
	new_citizen.citizenship_date = world.time

	GLOB.eastwood_citizens += new_citizen
	return TRUE

/datum/eastwood_council/proc/revoke_citizenship(ckey)
	for(var/datum/eastwood_citizen/C in GLOB.eastwood_citizens)
		if(C.ckey == ckey)
			GLOB.eastwood_citizens -= C
			qdel(C)
			return TRUE
	return FALSE

/datum/eastwood_council/proc/register_candidate(mob/user)
	if(!is_citizen(user.ckey))
		return FALSE

	var/datum/eastwood_citizen/citizen = get_citizen(user.ckey)
	if(!citizen.can_run_for_council())
		return FALSE

	for(var/datum/council_candidate/C in candidates)
		if(C.ckey == user.ckey)
			return FALSE

	var/datum/council_candidate/candidate = new()
	candidate.ckey = user.ckey
	candidate.name = user.name
	candidate.registration_time = world.time

	candidates += candidate
	return TRUE

/datum/eastwood_council/proc/remove_candidate(ckey)
	for(var/datum/council_candidate/C in candidates)
		if(C.ckey == ckey)
			candidates -= C
			qdel(C)
			return TRUE
	return FALSE

/datum/eastwood_council/proc/start_election()
	if(election_active)
		return FALSE

	election_active = TRUE
	election_start_time = world.time
	votes = list()

	for(var/datum/eastwood_citizen/C in GLOB.eastwood_citizens)
		C.voted_this_election = FALSE

	return TRUE

/datum/eastwood_council/proc/cast_vote(mob/user, candidate_ckey)
	if(!election_active)
		return FALSE

	var/datum/eastwood_citizen/citizen = get_citizen(user.ckey)
	if(!citizen || !citizen.can_vote())
		return FALSE

	if(citizen.voted_this_election)
		return FALSE

	var/valid_candidate = FALSE
	for(var/datum/council_candidate/C in candidates)
		if(C.ckey == candidate_ckey)
			valid_candidate = TRUE
			break

	if(!valid_candidate)
		return FALSE

	votes[candidate_ckey] = (votes[candidate_ckey] || 0) + 1
	citizen.voted_this_election = TRUE
	return TRUE

/datum/eastwood_council/proc/end_election()
	if(!election_active)
		return FALSE

	election_active = FALSE

	var/list/vote_counts = list()
	for(var/ckey in votes)
		vote_counts[ckey] = votes[ckey]

	vote_counts = sortList(vote_counts, /proc/cmp_numeric_desc, associative = TRUE)

	council_members = list()
	var/count = 0
	for(var/ckey in vote_counts)
		if(count >= COUNCIL_SIZE)
			break
		var/datum/council_member/member = new()
		member.ckey = ckey
		for(var/datum/council_candidate/C in candidates)
			if(C.ckey == ckey)
				member.name = C.name
				break
		member.votes_received = vote_counts[ckey]
		council_members += member
		count++

	if(council_members.len > 0)
		var/datum/council_member/first = council_members[1]
		mayor_ckey = first.ckey

	term_end_time = world.time + (COUNCIL_TERM_DAYS * 24 * 60 * 10)
	candidates = list()
	votes = list()

	return TRUE

/datum/eastwood_council/proc/is_council_member(ckey)
	for(var/datum/council_member/M in council_members)
		if(M.ckey == ckey)
			return TRUE
	return FALSE

/datum/eastwood_council/proc/is_mayor(ckey)
	return mayor_ckey == ckey

/datum/eastwood_council/proc/propose_law(law_name, law_description, proposer_ckey)
	if(!is_council_member(proposer_ckey))
		return FALSE

	var/datum/town_law/law = new()
	law.id = "law_[world.time]"
	law.name = law_name
	law.description = law_description
	law.proposer = proposer_ckey
	law.proposed_time = world.time

	proposed_laws += law
	return TRUE

/datum/eastwood_council/proc/vote_on_law(law_id, vote, voter_ckey)
	if(!is_council_member(voter_ckey))
		return FALSE

	for(var/datum/town_law/L in proposed_laws)
		if(L.id == law_id)
			if(vote)
				L.votes_for += 1
			else
				L.votes_against += 1

			if(L.votes_for > (COUNCIL_SIZE / 2))
				enacted_laws += L
				proposed_laws -= L
				return TRUE

			if(L.votes_against > (COUNCIL_SIZE / 2))
				proposed_laws -= L
				qdel(L)

			return TRUE

	return FALSE

// ============ COUNCIL CANDIDATE ============

/datum/council_candidate
	var/ckey
	var/name
	var/registration_time

// ============ COUNCIL MEMBER ============

/datum/council_member
	var/ckey
	var/name
	var/votes_received = 0

// ============ TOWN LAW ============

/datum/town_law
	var/id
	var/name
	var/description
	var/proposer
	var/proposed_time
	var/votes_for = 0
	var/votes_against = 0

// ============ TOWN HALL CONSOLE ============

/obj/machinery/computer/town_hall
	name = "Eastwood Town Hall Terminal"
	desc = "A terminal for town council management and citizenship."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/town_hall/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/town_hall/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TownHall")
		ui.open()

/obj/machinery/computer/town_hall/ui_data(mob/user)
	var/list/data = list()

	data["is_citizen"] = GLOB.eastwood_council.is_citizen(user.ckey)
	data["is_council_member"] = GLOB.eastwood_council.is_council_member(user.ckey)
	data["is_mayor"] = GLOB.eastwood_council.is_mayor(user.ckey)
	data["election_active"] = GLOB.eastwood_council.election_active
	data["term_end_time"] = GLOB.eastwood_council.term_end_time

	var/list/citizens_data = list()
	for(var/datum/eastwood_citizen/C in GLOB.eastwood_citizens)
		citizens_data += list(list("ckey" = C.ckey, "name" = C.name))
	data["citizens"] = citizens_data

	var/list/council_data = list()
	for(var/datum/council_member/M in GLOB.eastwood_council.council_members)
		council_data += list(list("ckey" = M.ckey, "name" = M.name, "votes" = M.votes_received, "is_mayor" = (M.ckey == GLOB.eastwood_council.mayor_ckey)))
	data["council"] = council_data

	var/list/candidates_data = list()
	for(var/datum/council_candidate/C in GLOB.eastwood_council.candidates)
		candidates_data += list(list("ckey" = C.ckey, "name" = C.name))
	data["candidates"] = candidates_data

	var/list/laws_data = list()
	for(var/datum/town_law/L in GLOB.eastwood_council.proposed_laws)
		laws_data += list(list("id" = L.id, "name" = L.name, "description" = L.description, "votes_for" = L.votes_for, "votes_against" = L.votes_against))
	data["proposed_laws"] = laws_data

	var/list/enacted_data = list()
	for(var/datum/town_law/L in GLOB.eastwood_council.enacted_laws)
		enacted_data += list(list("id" = L.id, "name" = L.name, "description" = L.description))
	data["enacted_laws"] = enacted_data

	return data

/obj/machinery/computer/town_hall/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("apply_citizenship")
			if(GLOB.eastwood_council.grant_citizenship(usr))
				to_chat(usr, span_notice("You are now a citizen of Eastwood!"))
			else
				to_chat(usr, span_warning("You are already a citizen."))
			return TRUE

		if("register_candidate")
			if(GLOB.eastwood_council.register_candidate(usr))
				to_chat(usr, span_notice("You have registered as a council candidate."))
			else
				to_chat(usr, span_warning("Cannot register. Check requirements."))
			return TRUE

		if("withdraw_candidacy")
			GLOB.eastwood_council.remove_candidate(usr.ckey)
			to_chat(usr, span_notice("You have withdrawn your candidacy."))
			return TRUE

		if("start_election")
			if(!GLOB.eastwood_council.is_council_member(usr.ckey))
				return FALSE
			if(GLOB.eastwood_council.start_election())
				to_chat(usr, span_notice("Election has started!"))
			return TRUE

		if("cast_vote")
			var/candidate_ckey = params["candidate"]
			if(GLOB.eastwood_council.cast_vote(usr, candidate_ckey))
				to_chat(usr, span_notice("Vote cast successfully."))
			return TRUE

		if("end_election")
			if(!GLOB.eastwood_council.is_mayor(usr.ckey) && !GLOB.eastwood_council.is_council_member(usr.ckey))
				return FALSE
			if(GLOB.eastwood_council.end_election())
				to_chat(usr, span_notice("Election has ended. Results are final."))
			return TRUE

		if("propose_law")
			var/law_name = params["name"]
			var/law_desc = params["description"]
			if(GLOB.eastwood_council.propose_law(law_name, law_desc, usr.ckey))
				to_chat(usr, span_notice("Law proposed."))
			return TRUE

		if("vote_law")
			var/law_id = params["law_id"]
			var/vote = text2num(params["vote"])
			if(GLOB.eastwood_council.vote_on_law(law_id, vote, usr.ckey))
				to_chat(usr, span_notice("Vote recorded."))
			return TRUE

	return FALSE

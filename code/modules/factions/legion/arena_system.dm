// Legion Arena System
// Gladiatorial combat with betting

// ============ ARENA CONTROLLER ============

/obj/structure/arena_controller
	name = "Arena Control Pillar"
	desc = "Controls the Legion arena's barriers, gates, and scoring."
	icon = 'icons/obj/structures.dmi'
	icon_state = "arena_pillar"
	density = TRUE
	anchored = TRUE

	var/list/red_team = list()
	var/list/blue_team = list()
	var/match_active = FALSE
	var/match_type = ARENA_DEATHMATCH
	var/total_bets_red = 0
	var/total_bets_blue = 0
	var/list/bettors = list()
	var/datum/arena_match/current_match
	var/list/match_history = list()
	var/match_id_counter = 1
	var/winner_team = null

/obj/structure/arena_controller/attack_hand(mob/user)
	ui_interact(user)

/obj/structure/arena_controller/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArenaControl")
		ui.open()

/obj/structure/arena_controller/ui_data(mob/user)
	var/list/data = list()
	data["match_active"] = match_active
	data["match_type"] = match_type
	data["match_type_name"] = get_match_type_name()
	data["total_bets_red"] = total_bets_red
	data["total_bets_blue"] = total_bets_blue
	data["odds_red"] = calculate_odds("red")
	data["odds_blue"] = calculate_odds("blue")
	data["winner_team"] = winner_team

	var/list/red_team_data = list()
	for(var/datum/arena_fighter/F in red_team)
		red_team_data += list(F.get_ui_data())
	data["red_team"] = red_team_data

	var/list/blue_team_data = list()
	for(var/datum/arena_fighter/F in blue_team)
		blue_team_data += list(F.get_ui_data())
	data["blue_team"] = blue_team_data

	var/list/history_data = list()
	for(var/i = max(1, match_history.len - 4) to match_history.len)
		if(match_history[i])
			history_data += list(match_history[i])
	data["match_history"] = history_data

	data["is_arena_master"] = check_arena_master(user)

	return data

/obj/structure/arena_controller/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_match_type")
			match_type = text2num(params["match_type"])
			return TRUE

		if("register_fighter")
			var/team = params["team"]
			var/mob/living/carbon/human/H = usr
			if(!istype(H))
				return FALSE
			if(!register_fighter(H, team))
				to_chat(usr, span_warning("Cannot register fighter."))
			return TRUE

		if("remove_fighter")
			var/team = params["team"]
			var/fighter_id = params["fighter_id"]
			remove_fighter(fighter_id, team)
			return TRUE

		if("start_match")
			if(!check_arena_master(usr))
				to_chat(usr, span_warning("Only Arena Masters can start matches."))
				return FALSE
			if(!start_match())
				to_chat(usr, span_warning("Cannot start match. Need at least 1 fighter per team."))
			return TRUE

		if("end_match")
			if(!check_arena_master(usr))
				to_chat(usr, span_warning("Only Arena Masters can end matches."))
				return FALSE
			var/winner = params["winner"]
			end_match(winner)
			return TRUE

		if("place_bet")
			var/team = params["team"]
			var/amount = text2num(params["amount"])
			if(amount < ARENA_MIN_BET || amount > ARENA_MAX_BET)
				to_chat(usr, span_warning("Bet must be between [ARENA_MIN_BET] and [ARENA_MAX_BET] caps."))
				return FALSE
			if(place_bet(usr, team, amount))
				to_chat(usr, span_notice("Bet placed: [amount] caps on [team] team."))
			else
				to_chat(usr, span_warning("Cannot place bet. Check your caps."))
			return TRUE

		if("reset_arena")
			reset_arena()
			return TRUE

	return FALSE

/obj/structure/arena_controller/proc/get_match_type_name()
	switch(match_type)
		if(ARENA_DEATHMATCH)
			return "Deathmatch"
		if(ARENA_SUBMISSION)
			return "Submission"
		if(ARENA_TEAM_BATTLE)
			return "Team Battle"
		if(ARENA_BEAST_FIGHT)
			return "Beast Fight"
		return "Unknown"

/obj/structure/arena_controller/proc/calculate_odds(team)
	if(team == "red")
		if(total_bets_red == 0)
			return 1.0
		var/total = total_bets_red + total_bets_blue
		if(total == 0)
			return 1.0
		return round(total / total_bets_red, 0.1)
	else
		if(total_bets_blue == 0)
			return 1.0
		var/total = total_bets_red + total_bets_blue
		if(total == 0)
			return 1.0
		return round(total / total_bets_blue, 0.1)

/obj/structure/arena_controller/proc/check_arena_master(mob/user)
	if(!user.mind)
		return FALSE
	if(user.mind.assigned_role in list("Legion Arena Master", "Legion Centurion", "Legion Legate"))
		return TRUE
	return FALSE

/obj/structure/arena_controller/proc/register_fighter(mob/living/carbon/human/H, team)
	if(match_active)
		return FALSE
	if(!istype(H))
		return FALSE

	for(var/datum/arena_fighter/F in red_team + blue_team)
		if(F.fighter_ckey == H.ckey)
			return FALSE

	var/datum/arena_fighter/fighter = new()
	fighter.fighter_ckey = H.ckey
	fighter.fighter_name = H.name
	fighter.wins = 0
	fighter.losses = 0

	var/is_slave = FALSE
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == H.ckey && entry.status == "enslaved")
			is_slave = TRUE
			fighter.is_slave = TRUE
			break

	if(team == "red")
		if(red_team.len >= ARENA_MAX_TEAM_SIZE)
			return FALSE
		red_team += fighter
	else
		if(blue_team.len >= ARENA_MAX_TEAM_SIZE)
			return FALSE
		blue_team += fighter

	return TRUE

/obj/structure/arena_controller/proc/remove_fighter(fighter_id, team)
	if(match_active)
		return

	if(team == "red")
		for(var/datum/arena_fighter/F in red_team)
			if(F.fighter_ckey == fighter_id)
				red_team -= F
				qdel(F)
				return
	else
		for(var/datum/arena_fighter/F in blue_team)
			if(F.fighter_ckey == fighter_id)
				blue_team -= F
				qdel(F)
				return

/obj/structure/arena_controller/proc/start_match()
	if(match_active)
		return FALSE
	if(red_team.len < 1 || blue_team.len < 1)
		return FALSE

	match_active = TRUE
	winner_team = null
	current_match = new /datum/arena_match()
	current_match.match_id = "match_[match_id_counter++]"
	current_match.match_type = match_type
	current_match.start_time = world.time

	for(var/datum/arena_fighter/F in red_team)
		current_match.red_fighters += F
	for(var/datum/arena_fighter/F in blue_team)
		current_match.blue_fighters += F

	for(var/datum/arena_fighter/F in red_team + blue_team)
		var/mob/living/carbon/human/H = get_mob_by_ckey(F.fighter_ckey)
		if(H)
			to_chat(H, span_alert("THE MATCH HAS BEGUN! Fight for glory!"))

	visible_message(span_alert("[src] announces: THE MATCH HAS BEGUN!"))
	return TRUE

/obj/structure/arena_controller/proc/end_match(winner)
	if(!match_active)
		return

	match_active = FALSE
	winner_team = winner

	if(current_match)
		current_match.winner_team = winner
		current_match.end_time = world.time
		current_match.total_bets_red = total_bets_red
		current_match.total_bets_blue = total_bets_blue
		match_history += list(current_match.get_summary())

		process_payouts(winner)

	visible_message(span_alert("[src] announces: THE MATCH IS OVER! [uppertext(winner)] TEAM VICTORIOUS!"))

/obj/structure/arena_controller/proc/place_bet(mob/bettor, team, amount)
	if(match_active)
		return FALSE

	var/mob/living/carbon/human/H = bettor
	if(!istype(H))
		return FALSE

	if(!H.client)
		return FALSE

	for(var/datum/arena_bet/B in bettors)
		if(B.bettor_ckey == H.ckey)
			return FALSE

	var/datum/arena_bet/bet = new()
	bet.bettor_ckey = H.ckey
	bet.bettor_name = H.name
	bet.team = team
	bet.amount = amount

	bettors += bet

	if(team == "red")
		total_bets_red += amount
	else
		total_bets_blue += amount

	return TRUE

/obj/structure/arena_controller/proc/process_payouts(winner)
	for(var/datum/arena_bet/B in bettors)
		if(B.team == winner)
			var/odds = calculate_odds(B.team)
			var/payout = round(B.amount * odds)

			var/mob/living/carbon/human/H = get_mob_by_ckey(B.bettor_ckey)
			if(H)
				to_chat(H, span_notice("You won your bet! Payout: [payout] caps."))
		else
			var/mob/living/carbon/human/H = get_mob_by_ckey(B.bettor_ckey)
			if(H)
				to_chat(H, span_warning("You lost your bet."))

	bettors.Cut()

/obj/structure/arena_controller/proc/reset_arena()
	if(match_active)
		end_match("none")

	red_team.Cut()
	blue_team.Cut()
	total_bets_red = 0
	total_bets_blue = 0
	bettors.Cut()
	winner_team = null

/obj/structure/arena_controller/proc/get_mob_by_ckey(ckey)
	for(var/mob/M in GLOB.player_list)
		if(M.ckey == ckey)
			return M
	return null

// ============ ARENA FIGHTER DATUM ============

/datum/arena_fighter
	var/fighter_ckey
	var/fighter_name
	var/wins = 0
	var/losses = 0
	var/is_slave = FALSE

/datum/arena_fighter/proc/get_ui_data()
	return list(
		"fighter_ckey" = fighter_ckey,
		"fighter_name" = fighter_name,
		"wins" = wins,
		"losses" = losses,
		"is_slave" = is_slave,
	)

/datum/arena_fighter/proc/add_win()
	wins++

/datum/arena_fighter/proc/add_loss()
	losses++

// ============ ARENA MATCH DATUM ============

/datum/arena_match
	var/match_id
	var/match_type
	var/list/red_fighters = list()
	var/list/blue_fighters = list()
	var/winner_team
	var/start_time
	var/end_time
	var/total_bets_red = 0
	var/total_bets_blue = 0

/datum/arena_match/proc/get_summary()
	return list(
		"match_id" = match_id,
		"match_type" = match_type,
		"winner_team" = winner_team,
		"red_fighters" = get_fighter_names(red_fighters),
		"blue_fighters" = get_fighter_names(blue_fighters),
		"total_bets" = total_bets_red + total_bets_blue,
	)

/datum/arena_match/proc/get_fighter_names(list/fighters)
	var/list/names = list()
	for(var/datum/arena_fighter/F in fighters)
		names += F.fighter_name
	return english_list(names)

// ============ ARENA BET DATUM ============

/datum/arena_bet
	var/bettor_ckey
	var/bettor_name
	var/team
	var/amount

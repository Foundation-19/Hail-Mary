#define LINKIFY_READY(string, value) "<a href='byond://?src=[REF(src)];ready=[value]'>[string]</a>"
/mob/dead/new_player
	flags_1 = NONE
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	stat = DEAD

	//is there a result we want to read from the age gate
	var/age_gate_result

	var/ready = FALSE
	/// Referenced when you want to delete the new_player later on in the code.
	var/spawning = FALSE
	/// For instant transfer once the round is set up
	var/mob/living/new_character
	///Used to make sure someone doesn't get spammed with messages if they're ineligible for roles.
	var/ineligible_for_roles = FALSE



/mob/dead/new_player/Initialize(mapload)
	if(client && SSticker.state == GAME_STATE_STARTUP)
		var/obj/screen/splash/S = new(null, client, TRUE, TRUE)
		S.Fade(TRUE)

	if(length(GLOB.newplayer_start))
		forceMove(pick(GLOB.newplayer_start))
	else
		forceMove(locate(1,1,1))

	ComponentInitialize()

	. = ..()

/mob/dead/new_player/Destroy()
	// Clean up mind reference to break garbage collection cycles
	if(mind)
		mind.current = null
		mind = null

	// Clean up client screen objects to prevent orphaned UI elements
	if(client)
		QDEL_LIST(client.screen)
		client.screen = null

	return ..()

/mob/dead/new_player/prepare_huds()
	return

/mob/dead/new_player/proc/new_player_panel()
	if(client?.interviewee)
		return

	if(!client?.prefs?.rules_accepted)
		show_rules_panel(TRUE)
		return

	// Reset all HUD button toggle states — they persist through mob transfers
	winset(client, "infowindow.setoocstatus", "is-checked=false")
	winset(client, "infowindow.tgwiki", "is-checked=false")
	winset(client, "infowindow.changelog", "is-checked=false")
	winset(client, "infowindow.github", "is-checked=false")
	winset(client, "infowindow.discord", "is-checked=false")

	var/datum/asset/asset_datum = get_asset_datum(/datum/asset/simple/lobby)
	asset_datum.send(client)
	var/rs = REF(src)
	var/list/o = list()

	o += "<!DOCTYPE html><html><head><meta charset='UTF-8'><style>"
	o += "* { box-sizing: border-box; margin: 0; padding: 0; }"
	o += "body { background: #062113; color: #4aed92; font-family: 'Courier New', Courier, monospace; font-size: 15px; line-height: 1.7; padding: 0; margin: 0; }"
	o += ".hdr { padding: 14px 18px 10px; border-bottom: 1px solid #1a5e38; text-align: center; }"
	o += ".hdr .title { font-size: 11px; color: #2a7a52; letter-spacing: 2px; text-transform: uppercase; margin-bottom: 6px; }"
	o += ".hdr .name { font-size: 18px; font-weight: bold; color: #4aed92; }"
	o += ".menu { padding: 16px 18px; }"
	o += ".menu-item { display: block; padding: 8px 0; border-bottom: 1px solid #0d3322; }"
	o += ".menu-item:last-child { border-bottom: none; }"
	o += "a, a:link, a:visited, a:active { color: #4aed92; text-decoration: none; display: block; padding: 6px 10px; }"
	o += "a:hover { background: #4aed92; color: #062113; }"
	o += "a:hover b, a:hover strong, a:hover * { color: #041a0e; }"
	o += ".muted { color: #2a7a52; font-size: 13px; padding: 6px 4px; }"
	o += ".sep { border-top: 1px solid #1a5e38; margin: 10px 0; }"
	o += ".waiting { color: #e8a020; font-size: 13px; padding: 4px; }"
	o += "</style></head><body>"

	o += "<div class='hdr'>"
	o += "<div class='title'>ROBCO INDUSTRIES &mdash; WASTELAND TERMINAL</div>"
	if(client?.prefs)
		var/pname = client.prefs.be_random_name ? "WANDERER" : uppertext(client.prefs.real_name)
		o += "<div class='name'>[pname]</div>"
	o += "</div>"

	o += "<div class='menu'>"
	o += "<div class='menu-item'><a href='byond://?src=[rs];show_preferences=1'>&gt; CHARACTER CREATOR</a></div>"

	if(SSticker.current_state <= GAME_STATE_PREGAME)
		o += "<div class='waiting'>&gt; AWAITING ROUND START...</div>"
		o += "<div class='menu-item'><a href='byond://?src=[rs];refresh=1'>&gt; REFRESH</a></div>"
		o += "<div class='menu-item'><a href='byond://?src=[rs];refresh_chat=1'>&gt; FIX CHAT WINDOW</a></div>"
	else
		o += "<div class='menu-item'><a href='byond://?src=[rs];late_join=1'>&gt; JOIN GAME</a></div>"
		o += "<div class='menu-item'><a href='byond://?src=[rs];ready=[PLAYER_READY_TO_OBSERVE]'>&gt; OBSERVE</a></div>"
		o += "<div class='menu-item'><a href='byond://?src=[rs];refresh_chat=1'>&gt; FIX CHAT WINDOW</a></div>"

	o += "<div class='sep'></div>"
	o += "<div class='menu-item'><a href='byond://?src=[rs];view_wiki=1'>&gt; WIKI</a></div>"
	o += "<div class='menu-item'><a href='byond://?src=[rs];show_rules_only=1'>&gt; SERVER RULES</a></div>"

	if(!IsGuestKey(src.key))
		o += playerpolls()

	o += "</div>"
	o += "<div style='padding:8px 18px;font-size:11px;color:#1a5e38;border-top:1px solid #0d3322;text-align:center;'>ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL</div>"
	o += "</body></html>"

	var/datum/browser/popup = new(src, "playersetup", null, 320, 600)
	popup.set_window_options("can_close=0")
	popup.set_content(o.Join())
	popup.open(FALSE)

/mob/dead/new_player/proc/show_rules_panel(accepting = TRUE)
	var/rs = REF(src)
	var/list/c = list()
	c += "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
	c += "<style>"
	c += "* { box-sizing: border-box; margin: 0; padding: 0; }"
	c += "body { background: #062113; color: #4aed92; font-family: 'Courier New', Courier, monospace; font-size: 15px; line-height: 1.6; }"
	c += ".hdr { padding: 12px 16px 10px; border-bottom: 1px solid #1a5e38; }"
	c += ".hdr .sys { font-size: 11px; color: #2a7a52; letter-spacing: 2px; margin-bottom: 4px; }"
	c += ".hdr h2 { font-size: 17px; font-weight: bold; color: #4aed92; text-transform: uppercase; letter-spacing: 1px; }"
	c += ".hint { font-size: 12px; color: #2a7a52; padding: 6px 16px 2px; }"
	c += ".scroll { max-height: 360px; overflow-y: auto; padding: 8px 16px 12px; }"
	c += ".scroll::-webkit-scrollbar { width: 6px; } .scroll::-webkit-scrollbar-track { background: #041a0d; } .scroll::-webkit-scrollbar-thumb { background: #1a5e38; }"
	c += ".rule { display: flex; align-items: flex-start; gap: 10px; padding: 8px 0; border-bottom: 1px solid #0d3322; }"
	c += ".rule:last-child { border-bottom: none; }"
	c += ".rule input { margin-top: 4px; flex-shrink: 0; width: 16px; height: 16px; cursor: pointer; accent-color: #4aed92; }"
	c += ".rule label { cursor: pointer; color: #4aed92; line-height: 1.6; }"
	c += ".rule p { color: #4aed92; line-height: 1.6; }"
	c += ".rule label.done { color: #2a7a52; }"
	c += ".n { color: #4aed92; font-weight: bold; }"
	c += ".sub { color: #2a9f5c; padding-left: 18px; display: block; font-size: 13px; }"
	c += ".addendum { margin: 10px 16px 0; padding: 10px 12px; background: #041a0d; border-left: 3px solid #2a7a52; font-size: 13px; color: #2a9f5c; line-height: 1.6; }"
	c += ".addendum b { color: #e8a020; display: block; margin-bottom: 4px; font-size: 14px; }"
	c += ".footer { padding: 12px 16px; border-top: 1px solid #1a5e38; text-align: center; background: #041a0d; }"
	c += ".footer .q { margin-bottom: 10px; font-size: 15px; color: #4aed92; }"
	c += "button { background: #062113; color: #4aed92; border: 1px solid #4aed92; padding: 8px 28px; cursor: pointer; font-family: 'Courier New', Courier, monospace; font-size: 15px; text-transform: uppercase; letter-spacing: 1px; }"
	c += "button:disabled { color: #1a5e38; border-color: #1a5e38; cursor: not-allowed; }"
	c += "button:hover:not(:disabled) { background: #4aed92; color: #062113; }"
	c += "</style></head>"
	c += "<body>"
	c += "<div class='hdr'>"
	c += "<div class='sys'>ROBCO INDUSTRIES TERMLINK PROTOCOL</div>"
	c += "<h2>&gt; Server Rules</h2>"
	c += "</div>"
	c += "<div class='scroll'>"
	if(accepting)
		c += "<p class='hint'>&gt; Acknowledge each rule to proceed.</p>"

	// Rules 1-6: straightforward
	var/list/simple_rules = list(
		"Play in good faith. Don't be too much of a dick, don't meta-game, power-game, or abuse exploits.",
		"Don't harass each other OOC. Banter is fine but don't take it too far.",
		"Roleplay believably as a member of your faction. Don't be a blatant shitpost. (Some exception for Raiders.)",
		"Names cannot be obvious references to pop culture. More subtle ones are fine.",
		"Use escalation when engaging in PvP combat.",
		"Don't attack other players until the 30-minute grace period is over. You'll see a big notice when it's time to mog."
	)
	for(var/i = 1; i <= length(simple_rules); i++)
		c += "<div class='rule'>"
		if(accepting)
			c += "<input type='checkbox' class='rc' id='r[i]' onchange='upd()'>"
			c += "<label for='r[i]'><span class='n'>[i].</span> [simple_rules[i]]</label>"
		else
			c += "<p><span class='n'>[i].</span> [simple_rules[i]]</p>"
		c += "</div>"

	// Rule 7: raids (complex with sub-points)
	c += "<div class='rule'>"
	if(accepting)
		c += "<input type='checkbox' class='rc' id='r7' onchange='upd()'>"
		c += "<label for='r7'><span class='n'>7.</span> Make an ahelp before you raid &mdash; all we require is a good IC reason. &#91;WAIT FOR ADMIN APPROVAL&#93;"
		c += "<span class='sub'>&bull; Make it known to your target that you are raiding them before going in. (e.g. &ldquo;Hello NCR, we are here to raid you.&rdquo;)</span>"
		c += "<span class='sub'>&bull; Do not linger too long after the raid is complete, or risk getting admin-killed.</span>"
		c += "<span class='sub'>&bull; If no admins are online, raids may be permitted 2 hours into the round.</span>"
		c += "</label>"
	else
		c += "<p><span class='n'>7.</span> Make an ahelp before you raid &mdash; all we require is a good IC reason. &#91;WAIT FOR ADMIN APPROVAL&#93;"
		c += "<span class='sub'>&bull; Make it known to your target that you are raiding them before going in. (e.g. &ldquo;Hello NCR, we are here to raid you.&rdquo;)</span>"
		c += "<span class='sub'>&bull; Do not linger too long after the raid is complete, or risk getting admin-killed.</span>"
		c += "<span class='sub'>&bull; If no admins are online, raids may be permitted 2 hours into the round.</span>"
		c += "</p>"
	c += "</div>"

	// Rules 8-11
	var/list/tail_rules = list(
		"Stay in your faction armor, or use the colormate to paint found armor to your faction colors. (Legion = red, NCR = brown, etc.)",
		"Do not mess with AFK players at all unless you are sending-to-matrix (despawning) those who aren't coming back.",
		"ERP is not allowed. Do not emote anything sexually explicit.",
		"Have fun."
	)
	for(var/i = 1; i <= length(tail_rules); i++)
		var/rule_num = i + 7
		c += "<div class='rule'>"
		if(accepting)
			c += "<input type='checkbox' class='rc' id='r[rule_num]' onchange='upd()'>"
			c += "<label for='r[rule_num]'><span class='n'>[rule_num].</span> [tail_rules[i]]</label>"
		else
			c += "<p><span class='n'>[rule_num].</span> [tail_rules[i]]</p>"
		c += "</div>"

	c += "</div>"

	// Addendum
	c += "<div class='addendum'>"
	c += "<b>&gt; Additional Rulings (Temporary)</b>"
	c += "Sieges are now considered raids &mdash; ahelp for permission. "
	c += "Blocking a bunker with walls is fine; others may break in equally. "
	c += "Basing in a bunker (e.g. casino) does not require raid permissions, but this only applies before the 1:30 mark."
	c += "</div>"

	if(accepting)
		c += "<div class='footer'>"
		c += "<p class='q'>&gt; Do you accept the rules above?</p>"
		c += "<button id='ab' disabled onclick=\"window.location='byond://?src=[rs];accept_rules=1'\">&#91; I ACCEPT &#93;</button>"
		c += "</div>"
		c += "<script>function upd(){var b=document.querySelectorAll('.rc');var ok=Array.from(b).every(function(x){return x.checked;});document.getElementById('ab').disabled=!ok;document.querySelectorAll('.rule label').forEach(function(l){if(document.getElementById(l.getAttribute('for')).checked)l.classList.add('done');else l.classList.remove('done');});}</script>"
	else
		c += "<div class='footer'>"
		c += "<button onclick=\"window.location='byond://?src=[rs];close_rules=1'\">&#91; CLOSE &#93;</button>"
		c += "</div>"
	c += "</body></html>"

	var/datum/browser/popup = new(src, "rules_panel", "<div align='center'>Server Rules</div>", 520, 620)
	if(accepting)
		popup.set_window_options("can_close=0")
	popup.set_content(c.Join())
	popup.open(FALSE)

/mob/dead/new_player/proc/playerpolls()
	var/list/output = list()
	if (SSdbcore.Connect())
		var/isadmin = FALSE
		if(client?.holder)
			isadmin = TRUE
		var/datum/db_query/query_get_new_polls = SSdbcore.NewQuery({"
			SELECT id FROM [format_table_name("poll_question")]
			WHERE (adminonly = 0 OR :isadmin = 1)
			AND Now() BETWEEN starttime AND endtime
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_vote")]
				WHERE ckey = :ckey
			)
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_textreply")]
				WHERE ckey = :ckey
			)
		"}, list("isadmin" = isadmin, "ckey" = ckey))
		var/rs = REF(src)
		if(!query_get_new_polls.Execute())
			qdel(query_get_new_polls)
			return
		if(query_get_new_polls.NextRow())
			output += "<p><b><a href='byond://?src=[rs];showpoll=1'>Show Player Polls</A> (NEW!)</b></p>"
		else
			output += "<p><a href='byond://?src=[rs];showpoll=1'>Show Player Polls</A></p>"
		qdel(query_get_new_polls)
		if(QDELETED(src))
			return
		return output

/mob/dead/new_player/Topic(href, href_list[])
	if(src != usr)
		return

	if(!client)
		return

	if(client.interviewee)
		return FALSE

	//don't let people get to this unless they are specifically not verified
	if(href_list["Month"] && (CONFIG_GET(flag/age_verification) && !check_rights_for(client, R_ADMIN) && !(client.ckey in GLOB.bunker_passthrough)))
		var/player_month = text2num(href_list["Month"])
		var/player_year = text2num(href_list["Year"])

		var/current_time = world.realtime
		var/current_month = text2num(time2text(current_time, "MM"))
		var/current_year = text2num(time2text(current_time, "YYYY"))

		var/player_total_months = (player_year * 12) + player_month

		var/current_total_months = (current_year * 12) + current_month

		var/months_in_eighteen_years = 18 * 12

		var/month_difference = current_total_months - player_total_months
		if(month_difference > months_in_eighteen_years)
			age_gate_result = TRUE // they're fine
		else
			if(month_difference < months_in_eighteen_years)
				age_gate_result = FALSE
			else
				//they could be 17 or 18 depending on the /day/ they were born in
				var/current_day = text2num(time2text(current_time, "DD"))
				var/days_in_months = list(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
				if((player_year % 4) == 0) // leap year so february actually has 29 days
					days_in_months[2] = 29
				var/total_days_in_player_month = days_in_months[player_month]
				var/list/days = list()
				for(var/number in 1 to total_days_in_player_month)
					days += number
				var/player_day = input(src, "What day of the month were you born in.") as anything in days
				if(player_day <= current_day)
					//their birthday has passed
					age_gate_result = TRUE
				else
					//it has NOT been their 18th birthday yet
					age_gate_result = FALSE

	//Determines Relevent Population Cap
	var/relevant_cap
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc && epc)
		relevant_cap = min(hpc, epc)
	else
		relevant_cap = max(hpc, epc)

	if(href_list["show_preferences"])
		client.prefs.ShowChoices(src)
		return 1

	if(href_list["ready"])
		var/tready = text2num(href_list["ready"])
		//Avoid updating ready if we're after PREGAME (they should use latejoin instead)
		//This is likely not an actual issue but I don't have time to prove that this
		//no longer is required
		if(SSticker.current_state <= GAME_STATE_PREGAME)
			if((length_char(client.prefs.features["flavor_text"])) < MIN_FLAVOR_LEN)
				to_chat(client.mob, span_danger("Your flavortext does not meet the minimum of [MIN_FLAVOR_LEN] characters."))
				return
			ready = tready
		//if it's post initialisation and they're trying to observe we do the needful
		if(SSticker.current_state >= GAME_STATE_PREGAME && tready == PLAYER_READY_TO_OBSERVE)
			ready = tready
			make_me_an_observer()
			return

	if(href_list["refresh"])
		src << browse(null, "window=playersetup") //closes the player setup window
		new_player_panel()

	if(href_list["refresh_chat"]) //fortuna addition. asset delivery pain
		client.nuke_chat()

	if(href_list["late_join"])
		if(!SSticker || !SSticker.IsRoundInProgress())
			to_chat(usr, span_danger("The round is either not ready, or has already finished..."))
			return
		
		if((length_char(client.prefs.features["flavor_text"])) < MIN_FLAVOR_LEN)
			to_chat(client.mob, span_danger("Your flavortext does not meet the minimum of [MIN_FLAVOR_LEN] characters."))
			return

		if(href_list["late_join"] == "override")
			LateChoices()
			return

		if(SSticker.queued_players.len || (relevant_cap && living_player_count() >= relevant_cap && !(ckey(key) in GLOB.admin_datums)))
			to_chat(usr, span_danger("[CONFIG_GET(string/hard_popcap_message)]"))

			var/queue_position = SSticker.queued_players.Find(usr)
			if(queue_position == 1)
				to_chat(usr, span_notice("You are next in line to join the game. You will be notified when a slot opens up."))
			else if(queue_position)
				to_chat(usr, span_notice("There are [queue_position-1] players in front of you in the queue to join the game."))
			else
				SSticker.queued_players += usr
				to_chat(usr, span_notice("You have been added to the queue to join the game. Your position in queue is [SSticker.queued_players.len]."))
			return

		if(GLOB.data_core.get_record_by_name(client.prefs.real_name))
			alert(src, "This character name is already in use. Choose another.")
			return

		LateChoices()

	if(href_list["manifest"])
		ViewManifest()

	if(href_list["accept_rules"])
		if(client.prefs)
			client.prefs.rules_accepted = TRUE
			client.prefs.save_preferences()
		log_game("[key_name(src)] has accepted the server rules.")
		src << browse(null, "window=rules_panel")
		new_player_panel()
		return

	if(href_list["show_rules_only"])
		show_rules_panel(FALSE)
		return

	if(href_list["close_rules"])
		src << browse(null, "window=rules_panel")
		return

	if(href_list["view_wiki"])
		client << link("https://sites.google.com/view/f13mechanisediron/menu?authuser=0")
		return

	if(href_list["SelectedJob"])
		if(!SSticker || !SSticker.IsRoundInProgress())
			var/msg = "[key_name(usr)] attempted to join the round using a href that shouldn't be available at this moment!"
			log_admin(msg)
			message_admins(msg)
			to_chat(usr, span_danger("The round is either not ready, or has already finished..."))
			return

		if(!GLOB.enter_allowed)
			to_chat(usr, span_notice("There is an administrative lock on entering the game!"))
			return

		if(SSticker.queued_players.len && !(ckey(key) in GLOB.admin_datums))
			if((living_player_count() >= relevant_cap) || (src != SSticker.queued_players[1]))
				to_chat(usr, span_warning("Server is full."))
				return

		AttemptLateSpawn(href_list["SelectedJob"])
		return

	if(href_list["JoinAsGhostRole"])
		if(!GLOB.enter_allowed)
			to_chat(usr, span_notice(" There is an administrative lock on entering the game!"))

		if(SSticker.queued_players.len && !(ckey(key) in GLOB.admin_datums))
			if((living_player_count() >= relevant_cap) || (src != SSticker.queued_players[1]))
				to_chat(usr, span_warning("Server is full."))
				return

		var/obj/effect/mob_spawn/MS = pick(GLOB.mob_spawners[href_list["JoinAsGhostRole"]])
		if(MS.attack_ghost(src, latejoinercalling = TRUE))
			SSticker.queued_players -= src
			SSticker.queue_delay = 4
			qdel(src)

	else if(!href_list["late_join"])
		new_player_panel()

	if(href_list["showpoll"])
		handle_player_polling()
		return

	if(href_list["pollid"])
		var/pollid = href_list["pollid"]
		if(istext(pollid))
			pollid = text2num(pollid)
		if(isnum(pollid) && ISINTEGER(pollid))
			src.poll_player(pollid)
		return

	if(href_list["votepollid"] && href_list["votetype"])
		var/pollid = text2num(href_list["votepollid"])
		var/votetype = href_list["votetype"]
		//lets take data from the user to decide what kind of poll this is, without validating it
		//what could go wrong
		switch(votetype)
			if(POLLTYPE_OPTION)
				var/optionid = text2num(href_list["voteoptionid"])
				if(vote_on_poll(pollid, optionid))
					to_chat(usr, span_notice("Vote successful."))
				else
					to_chat(usr, span_danger("Vote failed, please try again or contact an administrator."))
			if(POLLTYPE_TEXT)
				var/replytext = href_list["replytext"]
				if(log_text_poll_reply(pollid, replytext))
					to_chat(usr, span_notice("Feedback logging successful."))
				else
					to_chat(usr, span_danger("Feedback logging failed, please try again or contact an administrator."))
			if(POLLTYPE_RATING)
				var/id_min = text2num(href_list["minid"])
				var/id_max = text2num(href_list["maxid"])

				if( (id_max - id_min) > 100 )	//Basic exploit prevention
												//(protip, this stops no exploits)
					to_chat(usr, "The option ID difference is too big. Please contact administration or the database admin.")
					return

				for(var/optionid = id_min; optionid <= id_max; optionid++)
					if(!isnull(href_list["o[optionid]"]))	//Test if this optionid was replied to
						var/rating
						if(href_list["o[optionid]"] == "abstain")
							rating = null
						else
							rating = text2num(href_list["o[optionid]"])
							if(!isnum(rating) || !ISINTEGER(rating))
								return

						if(!vote_on_numval_poll(pollid, optionid, rating))
							to_chat(usr, span_danger("Vote failed, please try again or contact an administrator."))
							return
				to_chat(usr, span_notice("Vote successful."))
			if(POLLTYPE_MULTI)
				var/id_min = text2num(href_list["minoptionid"])
				var/id_max = text2num(href_list["maxoptionid"])

				if( (id_max - id_min) > 100 )	//Basic exploit prevention
					to_chat(usr, "The option ID difference is too big. Please contact administration or the database admin.")
					return

				for(var/optionid = id_min; optionid <= id_max; optionid++)
					if(!isnull(href_list["option_[optionid]"]))	//Test if this optionid was selected
						var/i = vote_on_multi_poll(pollid, optionid)
						switch(i)
							if(0)
								continue
							if(1)
								to_chat(usr, span_danger("Vote failed, please try again or contact an administrator."))
								return
							if(2)
								to_chat(usr, span_danger("Maximum replies reached."))
								break
				to_chat(usr, span_notice("Vote successful."))
			if(POLLTYPE_IRV)
				if (!href_list["IRVdata"])
					to_chat(src, span_danger("No ordering data found. Please try again or contact an administrator."))
					return
				var/list/votelist = splittext(href_list["IRVdata"], ",")
				if (!vote_on_irv_poll(pollid, votelist))
					to_chat(src, span_danger("Vote failed, please try again or contact an administrator."))
					return
				to_chat(src, span_notice("Vote successful."))

//When you cop out of the round (NB: this HAS A SLEEP FOR PLAYER INPUT IN IT)
/mob/dead/new_player/proc/make_me_an_observer()
	if(QDELETED(src) || !src.client)
		ready = PLAYER_NOT_READY
		return FALSE

	var/this_is_like_playing_right = alert(src,"Are you sure you wish to observe? No current restrictions on observing, you can spawn in as normal.","Player Setup","Yes","No")

	if(QDELETED(src) || !src.client || this_is_like_playing_right != "Yes")
		ready = PLAYER_NOT_READY
		src << browse(null, "window=playersetup") //closes the player setup window
		new_player_panel()
		return FALSE

	var/mob/dead/observer/observer = new()
	spawning = TRUE

	observer.started_as_observer = TRUE
	close_spawn_windows()
	var/obj/effect/landmark/observer_start/O = locate(/obj/effect/landmark/observer_start) in GLOB.landmarks_list
	to_chat(src, span_notice("Now teleporting."))
	if (O)
		observer.forceMove(O.loc)
	else
		to_chat(src, span_notice("Teleporting failed. Ahelp an admin please"))
		stack_trace("There's no freaking observer landmark available on this map or you're making observers before the map is initialised")
	if(mind)
		mind.transfer_to(observer, TRUE)
	else
		transfer_ckey(observer, FALSE)
		observer.client = client
	observer.set_ghost_appearance()
	if(observer.client && observer.client.prefs)
		observer.real_name = observer.client.prefs.real_name
		observer.name = observer.real_name
		observer.client.init_verbs()
	observer.update_icon()
	observer.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	QDEL_NULL(mind)
	qdel(src)
	return TRUE

/proc/get_job_unavailable_error_message(retval, jobtitle)
	switch(retval)
		if(JOB_AVAILABLE)
			return "[jobtitle] is available."
		if(JOB_UNAVAILABLE_GENERIC)
			return "[jobtitle] is unavailable."
		if(JOB_UNAVAILABLE_BANNED)
			return "You are currently banned from [jobtitle]."
		if(JOB_UNAVAILABLE_PLAYTIME)
			return "You do not have enough relevant playtime for [jobtitle]."
		if(JOB_UNAVAILABLE_ACCOUNTAGE)
			return "Your account is not old enough for [jobtitle]."
		if(JOB_UNAVAILABLE_SLOTFULL)
			return "[jobtitle] is already filled to capacity."
		if(JOB_UNAVAILABLE_SPECIESLOCK)
			return "Your species cannot play as a [jobtitle]."
		if(JOB_UNAVAILABLE_WHITELIST)
			return "[jobtitle] requires a whitelist."
		if(JOB_UNAVAILABLE_SPECIAL)
			return "[jobtitle] requires certain SPECIAL stats high enough."
	return "Error: Unknown job availability."

/mob/dead/new_player/proc/IsJobUnavailable(rank, latejoin = FALSE)
	var/datum/job/job = SSjob.GetJob(rank)
	if(!job)
		return JOB_UNAVAILABLE_GENERIC
	if((job.current_positions >= job.total_positions) && job.total_positions != -1)
		if(job.title == "Assistant")
			if(isnum(client.player_age) && client.player_age <= 14) //Newbies can always be assistants
				return JOB_AVAILABLE
			for(var/datum/job/J in SSjob.occupations)
				if(J && J.current_positions < J.total_positions && J.title != job.title)
					return JOB_UNAVAILABLE_SLOTFULL
		else
			return JOB_UNAVAILABLE_SLOTFULL
	if(jobban_isbanned(src,rank))
		return JOB_UNAVAILABLE_BANNED
	if(job.special_stat_check(client?.prefs))
		return JOB_UNAVAILABLE_SPECIAL
	if(QDELETED(src))
		return JOB_UNAVAILABLE_GENERIC
	if(!job.player_old_enough(client))
		return JOB_UNAVAILABLE_ACCOUNTAGE
	if(job.required_playtime_remaining(client))
		return JOB_UNAVAILABLE_PLAYTIME
	if(job.whitelist_locked(client,job.title))  //x check if this user should have access to this job via whitelist
		return JOB_UNAVAILABLE_WHITELIST
	if(latejoin && !job.special_check_latejoin(client))
		return JOB_UNAVAILABLE_GENERIC
	if(!client.prefs.pref_species.qualifies_for_rank(rank, client.prefs.features))
		return JOB_UNAVAILABLE_SPECIESLOCK
	if(LAZYLEN(SSmapping?.config?.removed_jobs))
		for(var/J in SSmapping.config.removed_jobs) //Search through our individual jobs to be removed
			if(job.title == J) //Found one, abort.
				return JOB_UNAVAILABLE_GENERIC
			if(J == "#all#" && LAZYLEN(SSmapping.config.added_jobs)) //Uhoh, remove everything but added jobs
				if(!(job.title in SSmapping.config.added_jobs))
					return JOB_UNAVAILABLE_GENERIC //Not found, get us out of here

	return JOB_AVAILABLE

/mob/dead/new_player/proc/AttemptLateSpawn(rank)
	var/error = IsJobUnavailable(rank)
	if(error != JOB_AVAILABLE)
		alert(src, get_job_unavailable_error_message(error, rank))
		return FALSE

	var/datum/job/job = SSjob.GetJob(rank)
	if(job.faction && (job.faction in SSjob.disabled_factions))
		alert(src, "An administrator has disabled spawning as the [job.faction] faction!")
		return FALSE

	if(SSticker.late_join_disabled)
		alert(src, "An administrator has disabled late join spawning.")
		return FALSE

	if((length_char(client.prefs.features["flavor_text"])) < MIN_FLAVOR_LEN)
		to_chat(client.mob, span_danger("Your flavortext does not meet the minimum of [MIN_FLAVOR_LEN] characters."))
		return FALSE

	var/arrivals_docked = TRUE
	if(SSshuttle.arrivals)
		close_spawn_windows()	//In case we get held up
		if(SSshuttle.arrivals.damaged && CONFIG_GET(flag/arrivals_shuttle_require_safe_latejoin))
			src << alert("The arrivals shuttle is currently malfunctioning! You cannot join.")
			return FALSE

		if(CONFIG_GET(flag/arrivals_shuttle_require_undocked))
			SSshuttle.arrivals.RequireUndocked(src)
		arrivals_docked = SSshuttle.arrivals.mode != SHUTTLE_CALL

	//Remove the player from the join queue if he was in one and reset the timer
	SSticker.queued_players -= src
	SSticker.queue_delay = 4

	SSjob.AssignRole(src, rank, 1)

	var/mob/living/character = create_character(TRUE)	//creates the human and transfers vars and mind
	if(!character)
		return FALSE
	var/equip = SSjob.EquipRank(character, rank, TRUE)
	if(isliving(equip))	//Borgs get borged in the equip, so we need to make sure we handle the new mob.
		character = equip

	if(job && !job.override_latejoin_spawn(character))
		SSjob.SendToLateJoin(character)
		if(!arrivals_docked)
			var/obj/screen/splash/Spl = new(character.client, TRUE)
			Spl.Fade(TRUE)
			character.playsound_local(get_turf(character), 'sound/voice/ApproachingTG.ogg', 25)

		character.update_parallax_teleport()

	job.standard_assign_skills(character.mind)

	SSticker.minds += character.mind
	// Removed duplicate init_verbs() call - verbs already finalized in Login()
	var/mob/living/carbon/human/humanc
	if(ishuman(character))
		humanc = character	//Let's retypecast the var to be human,

	if(humanc)	//These procs all expect humans
		if(humanc.client)
			GLOB.data_core.manifest_inject(humanc, humanc.client, humanc.client.prefs)
		if(SSshuttle.arrivals)
			SSshuttle.arrivals.QueueAnnounce(humanc, rank)
		else
			AnnounceArrival(humanc, rank)
		AddEmploymentContract(humanc)
		if(GLOB.highlander)
			to_chat(humanc, "<span class='userdanger'><i>THERE CAN BE ONLY ONE!!!</i></span>")
			humanc.make_scottish()

		if(GLOB.summon_guns_triggered)
			give_guns(humanc)
		if(GLOB.summon_magic_triggered)
			give_magic(humanc)
		if(GLOB.curse_of_madness_triggered)
			give_madness(humanc, GLOB.curse_of_madness_triggered)
		if(humanc.client)
			humanc.client.prefs.post_copy_to(humanc)

	GLOB.joined_player_list += character.ckey
	GLOB.latejoiners += character

	if(CONFIG_GET(flag/allow_latejoin_antagonists) && humanc)	//Borgs aren't allowed to be antags. Will need to be tweaked if we get true latejoin ais.
		if(SSshuttle.emergency)
			switch(SSshuttle.emergency.mode)
				if(SHUTTLE_RECALL, SHUTTLE_IDLE)
					SSticker.mode.make_antag_chance(humanc)
				if(SHUTTLE_CALL)
					if(SSshuttle.emergency.timeLeft(1) > initial(SSshuttle.emergencyCallTime)*0.5)
						SSticker.mode.make_antag_chance(humanc)

	if(humanc && CONFIG_GET(flag/roundstart_traits))
		if(humanc.client)
			SSquirks.AssignQuirks(humanc, humanc.client, TRUE, FALSE, job, FALSE)
	if(humanc && humanc.client && humanc.ckey == "tk420634")
		humanc.client.deadmin()

	log_manifest(character.mind.key,character.mind,character,latejoin = TRUE)

	if(job == src.previous_job)
		log_and_message_admins("[ADMIN_TPMONTY(character)] has spawned as a job they've previously matrixed as ([character.job])!")

/mob/dead/new_player/proc/AddEmploymentContract(mob/living/carbon/human/employee)
	//TODO:  figure out a way to exclude wizards/nukeops/demons from this.
	for(var/C in GLOB.employmentCabinets)
		var/obj/structure/filingcabinet/employment/employmentCabinet = C
		if(!employmentCabinet.virgin)
			employmentCabinet.addFile(employee)


/mob/dead/new_player/proc/LateChoices()
	if(!client?.prefs)
		return
	var/list/dat = list()

	dat += "<style>"
	dat += ".lj-hdr{text-align:center;margin:0 0 10px;}"
	dat += ".lj-hdr p{color:#2a7a52;font-size:12px;margin:2px 0;}"
	dat += ".occ-grid{display:flex;flex-wrap:wrap;gap:10px;padding:4px 6px 10px 6px;}"
	dat += ".faction-block{flex:1 1 200px;min-width:185px;max-width:270px;border:1px solid #1a5e38;background:#041a0e;}"
	dat += ".faction-hdr{background:#0a3e20;font-weight:bold;letter-spacing:1px;font-size:11px;padding:4px 8px;border-bottom:1px solid #1a5e38;text-align:center;}"
	dat += ".job-row{display:flex;justify-content:space-between;align-items:center;padding:2px 6px;border-bottom:1px solid #081e10;font-size:12px;}"
	dat += ".job-row:last-child{border-bottom:none;}"
	dat += ".job-row a{color:#4aed92;text-decoration:none;flex:1;display:block;padding:1px 0;}"
	dat += ".job-row a:hover{color:#062113;background:#4aed92;}"
	dat += ".job-row a b{color:#6af5aa;}"
	dat += ".job-row a:hover b,.job-row a:hover *{color:#041a0e;}"
	dat += ".jlocked{color:#2a4a38;flex:1;padding-right:4px;}"
	dat += ".jbadge{display:inline-block;font-size:10px;font-weight:bold;padding:1px 5px;min-width:50px;text-align:center;letter-spacing:1px;background:#160606;color:#5a1a10;border:1px solid #2a0808;}"
	dat += ".has-tip{position:relative;cursor:default;}"
	dat += ".tip{display:none;position:absolute;right:0;bottom:calc(100% + 4px);background:#041a0e;border:1px solid #1a5e38;padding:8px 10px;min-width:190px;z-index:9999;}"
	dat += ".has-tip:hover .tip{display:block;}"
	dat += ".tip-title{font-size:10px;color:#6af5aa;letter-spacing:1px;margin-bottom:6px;text-align:center;border-bottom:1px solid #1a5e38;padding-bottom:4px;}"
	dat += ".bar-row{margin-bottom:5px;}"
	dat += ".bar-label{font-size:10px;color:#4aed92;margin-bottom:2px;}"
	dat += ".bar-track{background:#081e10;border:1px solid #1a5e38;height:8px;width:170px;}"
	dat += ".bar-fill{background:#4aed92;height:100%;}"
	dat += ".bar-pct{font-size:10px;color:#2a7a52;margin-top:1px;text-align:right;}"
	dat += "</style>"

	dat += "<div class='lj-hdr'>"
	dat += "<p>Round Duration: [DisplayTimeText(world.time - SSticker.round_start_time)]</p>"
	if(SSshuttle.emergency)
		switch(SSshuttle.emergency.mode)
			if(SHUTTLE_ESCAPE)
				dat += "<p style='color:#c8160a;'>The area has been evacuated.</p>"
			if(SHUTTLE_CALL)
				if(!SSshuttle.canRecall())
					dat += "<p style='color:#c8160a;'>The area is currently undergoing evacuation procedures.</p>"
	dat += "</div>"

	dat += "<div class='occ-grid'>"
	for(var/category in GLOB.position_categories)
		var/list/jobs_in_cat = GLOB.position_categories[category]["jobs"]
		var/list/dept_dat = list()

		for(var/job in jobs_in_cat)
			var/datum/job/job_datum = SSjob.name_occupations[job]
			if(!job_datum)
				continue
			var/availability = IsJobUnavailable(job_datum.title, TRUE)
			if(availability == JOB_AVAILABLE)
				dept_dat += "<div class='job-row'>"
				if(job in GLOB.command_positions)
					dept_dat += "<a href='byond://?src=[REF(src)];SelectedJob=[job_datum.title]'><b>[job_datum.title]</b> ([job_datum.current_positions])</a>"
				else
					dept_dat += "<a href='byond://?src=[REF(src)];SelectedJob=[job_datum.title]'>[job_datum.title] ([job_datum.current_positions])</a>"
				dept_dat += "</div>"
			else if(availability == JOB_UNAVAILABLE_PLAYTIME)
				// Build progress bar HTML for each exp requirement
				var/list/bars = list()
				if(job_datum.exp_requirements && job_datum.exp_type)
					var/req_type = job_datum.get_exp_req_type()
					var/req_amount = job_datum.get_exp_req_amount()
					var/my_exp = max(0, client.calc_exp_type(req_type))
					var/pct = min(100, round(my_exp / req_amount * 100))
					bars += "<div class='bar-row'>"
					bars += "<div class='bar-label'>[req_type]</div>"
					bars += "<div class='bar-track'><div class='bar-fill' style='width:[pct]%'></div></div>"
					bars += "<div class='bar-pct'>[pct]% &bull; [get_exp_format(my_exp)] / [get_exp_format(req_amount)]</div>"
					bars += "</div>"
				if(job_datum.multi_exp_requirements)
					for(var/req_type in job_datum.multi_exp_requirements)
						var/req_amount = job_datum.multi_exp_requirements[req_type]
						var/my_exp = max(0, client.calc_exp_type(req_type))
						var/pct = min(100, round(my_exp / req_amount * 100))
						bars += "<div class='bar-row'>"
						bars += "<div class='bar-label'>[req_type]</div>"
						bars += "<div class='bar-track'><div class='bar-fill' style='width:[pct]%'></div></div>"
						bars += "<div class='bar-pct'>[pct]% &bull; [get_exp_format(my_exp)] / [get_exp_format(req_amount)]</div>"
						bars += "</div>"
				// Tier prereq bars
				var/tier_key_ui = get_tier_key_for_job(job_datum.title)
				if(tier_key_ui && !(tier_key_ui in client.prefs.exp_type_exempt))
					var/sep_ui = findtext(tier_key_ui, EXP_TIER_SEP)
					var/faction_ui = copytext(tier_key_ui, 1, sep_ui)
					var/tier_name_ui = copytext(tier_key_ui, sep_ui + 1)
					if(!(faction_ui in client.prefs.exp_type_exempt))
						var/list/reqs_ui = GLOB.exp_tier_requirements[tier_name_ui]
						if(reqs_ui)
							var/faction_req_ui = text2num(reqs_ui["faction"])
							if(faction_req_ui)
								var/have = _get_tier_faction_minutes(client, faction_ui)
								var/pct = min(100, round(have / faction_req_ui * 100))
								bars += "<div class='bar-row'>"
								bars += "<div class='bar-label'>[faction_ui] hours</div>"
								bars += "<div class='bar-track'><div class='bar-fill' style='width:[pct]%'></div></div>"
								bars += "<div class='bar-pct'>[pct]% &bull; [get_exp_format(have)] / [get_exp_format(faction_req_ui)]</div>"
								bars += "</div>"
							var/wasteland_req_ui = text2num(reqs_ui["wasteland"])
							if(wasteland_req_ui && faction_ui != "Wasteland" && !("Wasteland" in client.prefs.exp_type_exempt))
								var/have = _get_tier_faction_minutes(client, "Wasteland")
								var/pct = min(100, round(have / wasteland_req_ui * 100))
								bars += "<div class='bar-row'>"
								bars += "<div class='bar-label'>Wasteland hours</div>"
								bars += "<div class='bar-track'><div class='bar-fill' style='width:[pct]%'></div></div>"
								bars += "<div class='bar-pct'>[pct]% &bull; [get_exp_format(have)] / [get_exp_format(wasteland_req_ui)]</div>"
								bars += "</div>"
							var/other_req_ui = text2num(reqs_ui["other_faction"])
							if(other_req_ui)
								var/have = _get_best_other_faction_minutes(client, faction_ui)
								var/pct = min(100, round(have / other_req_ui * 100))
								bars += "<div class='bar-row'>"
								bars += "<div class='bar-label'>Other faction hours (best)</div>"
								bars += "<div class='bar-track'><div class='bar-fill' style='width:[pct]%'></div></div>"
								bars += "<div class='bar-pct'>[pct]% &bull; [get_exp_format(have)] / [get_exp_format(other_req_ui)]</div>"
								bars += "</div>"
				dept_dat += "<div class='job-row'>"
				dept_dat += "<span class='jlocked'>[job_datum.title]</span>"
				dept_dat += "<span class='jbadge has-tip'>LOCKED"
				dept_dat += "<span class='tip'>"
				dept_dat += "<div class='tip-title'>XP REQUIRED</div>"
				dept_dat += jointext(bars, "")
				dept_dat += "</span>"
				dept_dat += "</span>"
				dept_dat += "</div>"
			// All other unavailability reasons (banned, full, whitelist, etc.) are omitted

		if(dept_dat.len)
			dat += "<div class='faction-block'>"
			dat += "<div class='faction-hdr'>&#9658; [category] &#9664;</div>"
			dat += jointext(dept_dat, "")
			dat += "</div>"

	dat += "</div>" // end occ-grid

	src << browse(client.prefs.get_terminal_page(dat.Join(), "&#9654; JOIN GAME &#9664;"), "window=latechoices;size=960x720;can_close=1;can_minimize=1;can_maximize=0;can_resize=1;titlebar=1;")


/mob/dead/new_player/proc/create_character(transfer_after)
	spawning = 1
	close_spawn_windows()

	var/mob/living/carbon/human/H = new(loc)

	var/frn = CONFIG_GET(flag/force_random_names)
	if(!frn)
		frn = jobban_isbanned(src, "appearance")
		if(QDELETED(src))
			return
	if(frn)
		if(!client)
			return
		client.prefs.random_character()
		client.prefs.real_name = client.prefs.pref_species.random_name(gender,1)
	if(!client)
		qdel(H)
		return
	var/cur_scar_index = client.prefs.scars_index
	if(client.prefs.persistent_scars && client.prefs.scars_list["[cur_scar_index]"])
		var/scar_string = client.prefs.scars_list["[cur_scar_index]"]
		var/valid_scars = ""
		for(var/scar_line in splittext(scar_string, ";"))
			if(H.load_scar(scar_line))
				valid_scars += "[scar_line];"

		client.prefs.scars_list["[cur_scar_index]"] = valid_scars
		client.prefs.save_character()
	client.prefs.copy_to(H, initial_spawn = TRUE)
	H.dna.update_dna_identity()
	if(mind)
		if(transfer_after)
			mind.late_joiner = TRUE
		mind.active = 0					//we wish to transfer the key manually
		mind.transfer_to(H)					//won't transfer key since the mind is not active
		mind.original_character = H

	// Removed early init_verbs() call - verbs will be initialized after Login() in BYOND 516
	. = H
	new_character = .
	if(transfer_after)
		transfer_character()

/mob/dead/new_player/proc/transfer_character()
	. = new_character
	if(.)
		new_character.key = key		//Manually transfer the key to log them in
		new_character.stop_sound_channel(CHANNEL_LOBBYMUSIC)
		new_character = null
		qdel(src)

/mob/dead/new_player/proc/ViewManifest()
	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	var/dat = "<h4>Crew Manifest</h4>"
	dat += GLOB.data_core.get_manifest_dr(OOC = 1)

	src << browse(HTML_SKELETON(dat), "window=manifest;size=387x420;can_close=1")

/mob/dead/new_player/Move()
	return 0


/mob/dead/new_player/proc/close_spawn_windows()

	src << browse(null, "window=latechoices") //closes late choices window
	src << browse(null, "window=playersetup") //closes the player setup window
	src << browse(null, "window=preferences") //closes job selection
	src << browse(null, "window=mob_occupation")
	src << browse(null, "window=latechoices") //closes late job selection

/*	Used to make sure that a player has a valid job preference setup, used to knock players out of eligibility for anything if their prefs don't make sense.
	A "valid job preference setup" in this situation means at least having one job set to low, or not having "return to lobby" enabled
	Prevents "antag rolling" by setting antag prefs on, all jobs to never, and "return to lobby if preferences not availible"
	Doing so would previously allow you to roll for antag, then send you back to lobby if you didn't get an antag role
	This also does some admin notification and logging as well, as well as some extra logic to make sure things don't go wrong
*/

/mob/dead/new_player/proc/check_preferences()
	if(!client)
		return FALSE //Not sure how this would get run without the mob having a client, but let's just be safe.
	if(client.prefs.joblessrole != RETURNTOLOBBY)
		return TRUE
	// If they have antags enabled, they're potentially doing this on purpose instead of by accident. Notify admins if so.
	var/has_antags = FALSE
	if(client.prefs.be_special.len > 0)
		has_antags = TRUE
	if(client.prefs.job_preferences.len == 0)
		if(!ineligible_for_roles)
			to_chat(src, span_danger("You have no jobs enabled, along with return to lobby if job is unavailable. This makes you ineligible for any round start role, please update your job preferences."))
		ineligible_for_roles = TRUE
		ready = PLAYER_NOT_READY
		if(has_antags)
			log_admin("[src.ckey] just got booted back to lobby with no jobs, but antags enabled.")
			message_admins("[src.ckey] just got booted back to lobby with no jobs enabled, but antag rolling enabled. Likely antag rolling abuse.")

		return FALSE //This is the only case someone should actually be completely blocked from antag rolling as well
	return TRUE

/**
 * Prepares a client for the interview system, and provides them with a new interview
 *
 * This proc will both prepare the user by removing all verbs from them, as well as
 * giving them the interview form and forcing it to appear.
 */
/mob/dead/new_player/proc/register_for_interview()
	// First we detain them by removing all the verbs they have on client
	for (var/v in client.verbs)
		var/procpath/verb_path = v
		if (!(verb_path in GLOB.stat_panel_verbs))
			remove_verb(client, verb_path)

	// Then remove those on their mob as well
	for (var/v in verbs)
		var/procpath/verb_path = v
		if (!(verb_path in GLOB.stat_panel_verbs))
			remove_verb(src, verb_path)
	// Then we create the interview form and show it to the client
	var/datum/interview/I = GLOB.interviews.interview_for_client(client)
	if (I)
		I.ui_interact(src)

	// Add verb for re-opening the interview panel, and re-init the verbs for the stat panel
	add_verb(src, /mob/dead/new_player/proc/open_interview)

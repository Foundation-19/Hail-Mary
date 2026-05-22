// PLAYER JOB BOARD - Post and accept jobs from other players
// Creates a marketplace for player-to-player services

/datum/player_job
	var/title = ""
	var/description = ""
	var/reward = 0
	var/poster_name = ""
	var/poster_ref = ""
	var/post_time = 0
	var/claimed = FALSE
	var/claimed_by = ""
	var/completed = FALSE
	var/job_type = ""

#define JOB_TYPE_BODYGUARD "Bodyguard"
#define JOB_TYPE_SCAVENGE "Scavenging"
#define JOB_TYPE_DELIVERY "Delivery"
#define JOB_TYPE_ASSASSINATION "Assassination"
#define JOB_TYPE_ESCORT "Escort"
#define JOB_TYPE_CRAFTING "Crafting"
#define JOB_TYPE_MEDICAL "Medical Aid"
#define JOB_TYPE_OTHER "Other"

/obj/structure/player_job_board
	name = "job board"
	desc = "A board where wastelanders post jobs for hire. Get paid to do dangerous work."
	icon = 'icons/obj/structures.dmi'
	icon_state = "noticeboard"
	density = FALSE
	anchored = TRUE
	var/list/datum/player_job/jobs = list()
	var/max_jobs = 30

/obj/structure/player_job_board/attack_hand(mob/user)
	if(!ishuman(user))
		return
	show_board(user)

/obj/structure/player_job_board/proc/show_board(mob/user)
	var/html = "<center><h2>Wasteland Job Board</h2><hr>"
	html += "<a href='byond://?src=[REF(src)];post=1'>Post a Job</a><hr>"
	html += "<table width='100%'>"
	html += "<tr><th>Type</th><th>Title</th><th>Reward</th><th>Poster</th><th>Action</th></tr>"
	for(var/i = 1 to jobs.len)
		var/datum/player_job/J = jobs[i]
		if(J.completed)
			continue
		html += "<tr>"
		html += "<td>[J.job_type]</td>"
		html += "<td>[J.title]</td>"
		html += "<td>[J.reward] caps</td>"
		html += "<td>[J.poster_name]</td>"
		if(J.claimed)
			html += "<td><i>Claimed by [J.claimed_by]</i></td>"
		else
			html += "<td><a href='byond://?src=[REF(src)];claim=[i]'>Claim</a></td>"
		html += "</tr>"
	html += "</table></center>"
	var/datum/browser/popup = new(user, "job_board_[REF(src)]", "Wasteland Job Board", 500, 500)
	popup.set_content(html)
	popup.open()

/obj/structure/player_job_board/Topic(href, href_list)
	if(href_list["post"])
		post_job(usr)
	else if(href_list["claim"])
		var/index = text2num(href_list["claim"])
		if(index && index <= jobs.len)
			claim_job(usr, index)
	show_board(usr)

/obj/structure/player_job_board/proc/post_job(mob/living/carbon/human/H)
	if(jobs.len >= max_jobs)
		to_chat(H, span_warning("The board is full!"))
		return

	var/job_type = input(H, "Job type:", "Post Job") as null|anything in list(JOB_TYPE_BODYGUARD, JOB_TYPE_SCAVENGE, JOB_TYPE_DELIVERY, JOB_TYPE_ASSASSINATION, JOB_TYPE_ESCORT, JOB_TYPE_CRAFTING, JOB_TYPE_MEDICAL, JOB_TYPE_OTHER)
	if(!job_type)
		return

	var/title = stripped_input(H, "Job title:", "Post Job", "[job_type] needed")
	if(!title)
		return

	var/description = stripped_input(H, "Description:", "Post Job", "Meet me in town.", 500)
	if(!description)
		return

	var/reward = input(H, "Reward (caps):", "Post Job", 50) as num|null
	if(isnull(reward) || reward < 1)
		return

	var/choice = alert(H, "Post '[title]' for [reward] caps? You must deposit the reward upfront.", "Confirm", "Post", "Cancel")
	if(choice != "Post")
		return

	var/caps_available = find_caps_on_mob(H)
	if(caps_available < reward)
		to_chat(H, span_warning("You don't have enough caps to post this job!"))
		return

	remove_caps_from_mob(H, reward)

	var/datum/player_job/J = new()
	J.title = title
	J.description = description
	J.reward = reward
	J.poster_name = H.real_name
	J.poster_ref = REF(H)
	J.post_time = world.time
	J.job_type = job_type
	jobs += J

	visible_message(span_notice("[H] posts a job on the board: '[title]' - [reward] caps!"))
	to_chat(H, span_notice("You deposited [reward] caps. The reward will be paid when the job is completed."))
	log_game("JOB BOARD: [H.ckey] posted job '[title]' for [reward] caps")
	if(H.ckey)
		adjust_karma(H.ckey, 2)

/obj/structure/player_job_board/proc/claim_job(mob/living/carbon/human/H, index)
	var/datum/player_job/J = jobs[index]
	if(!J || J.claimed)
		to_chat(H, span_warning("This job is already claimed."))
		return
	if(J.poster_ref == REF(H))
		to_chat(H, span_warning("You can't claim your own job!"))
		return

	J.claimed = TRUE
	J.claimed_by = H.real_name
	visible_message(span_notice("[H] claims the job: '[J.title]'!"))
	to_chat(H, span_notice("You claimed '[J.title]'. Contact [J.poster_name] for details."))
	if(H.ckey)
		adjust_karma(H.ckey, 1)

/obj/structure/player_job_board/verb/complete_job()
	set src in view(2)
	set name = "Complete Job"
	set category = "IC"

	if(!ishuman(usr))
		return

	var/mob/living/carbon/human/H = usr
	var/list/my_jobs = list()
	for(var/datum/player_job/J in jobs)
		if(J.poster_ref == REF(H) && J.claimed && !J.completed)
			my_jobs += J

	if(!my_jobs.len)
		to_chat(H, span_warning("You have no claimed jobs to complete."))
		return

	var/datum/player_job/J = input(H, "Mark which job as complete?", "Complete Job") as null|anything in my_jobs
	if(!J)
		return

	J.completed = TRUE

	var/found_claimer = FALSE
	for(var/mob/living/carbon/human/claimer in GLOB.alive_mob_list)
		if(claimer.real_name == J.claimed_by)
			var/obj/item/stack/f13Cash/caps/C = new(get_turf(claimer), J.reward)
			claimer.put_in_hands(C)
			to_chat(claimer, span_greentext("[J.title] is complete! You earned [J.reward] caps!"))
			found_claimer = TRUE
			break

	if(!found_claimer)
		var/obj/item/stack/f13Cash/caps/C = new(get_turf(H), J.reward)
		H.put_in_hands(C)
		to_chat(H, span_notice("[J.claimed_by] is not around. The [J.reward] caps reward is returned to you."))

	visible_message(span_notice("[H] marks '[J.title]' as complete!"))
	if(H.ckey)
		adjust_karma(H.ckey, 3)

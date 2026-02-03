/* Code by Tienn (cleaned) */

#define STATE_IDLE 0
#define STATE_VEND 1

/obj/machinery/bounty_machine
	name = "Wasteland Bounty Machine"
	desc = "Wasteland Contracts Database terminal."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "Bounty_Console"
	anchored = TRUE
	density = TRUE
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	obj_integrity = 300
	max_integrity = 300
	integrity_failure = 100
	armor = list(melee = 20, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 50, acid = 70)

	// Subtypes will be selected for all quest list
	var/quest_type = /datum/bounty_quest/faction/wasteland

	// All quest types (paths)
	var/list/all_quests = list()

	// Currently active quests (instances)
	var/list/active_quests = list()

	var/quest_limit = 4

	// Connected bounty pod
	var/obj/machinery/bounty_pod/connected_pod
	var/pod_distance = 2

/obj/machinery/bounty_machine/New()
	..()
	InitQuestList()
	FindPod(pod_distance)
	UpdateActiveQuests()

/obj/machinery/bounty_machine/proc/InitQuestList()
	all_quests = typesof(quest_type)
	// Remove the base type itself so we only pick actual quest subtypes
	all_quests -= quest_type

/obj/machinery/bounty_machine/proc/GetRandomQuest()
	if(!all_quests || all_quests.len == 0)
		return null
	var/random_index = rand(1, all_quests.len)
	var/qt = all_quests[random_index]
	return new qt()

/obj/machinery/bounty_machine/proc/UpdateActiveQuests()
	while(active_quests.len < quest_limit)
		var/datum/bounty_quest/Q = GetRandomQuest()
		if(Q)
			active_quests += Q
		else
			break

/obj/machinery/bounty_machine/proc/ClearActiveQuests(create_new = FALSE)
	for(var/datum/bounty_quest/Q in active_quests)
		qdel(Q)
	active_quests.Cut()
	if(create_new)
		UpdateActiveQuests()

/obj/machinery/bounty_machine/proc/ProcessQuestComplete(quest_index, mob/user)
	quest_index = text2num(quest_index)
	if(quest_index < 1 || quest_index > active_quests.len)
		return "Invalid contract."

	if(!connected_pod)
		return "No pod connected."

	var/turf/location = get_turf(connected_pod)
	var/datum/bounty_quest/current_quest = active_quests[quest_index]
	var/next_stage_type = current_quest.next_stage_type

	// Find all target objects on the pod turf
	var/list/quest_objects = list()
	for(var/atom/A in location.contents)
		if(current_quest.ItsATarget(A))
			quest_objects += A

	if(quest_objects.len == 0)
		return "Nothing on the pod matches this contract."

	// Check counts
	if(!current_quest.CheckTargets(current_quest.target_items, quest_objects))
		return "Contract not fulfilled yet."

	var/bonus_complete = FALSE
	if(current_quest.HasBonus())
		bonus_complete = current_quest.CheckTargets(current_quest.bonus_items, quest_objects)

	// Fulfilled: remove only the required/bonus counts from the pod turf
	flick("tele0", connected_pod)
	var/list/removal_targets = list()
	var/list/pending_required = current_quest.target_items.Copy()
	var/list/pending_bonus = list()
	if(bonus_complete)
		pending_bonus = current_quest.bonus_items.Copy()
	for(var/atom/A in quest_objects)
		var/removed = FALSE
		for(var/target_type in pending_required)
			if(pending_required[target_type] > 0 && istype(A, target_type))
				pending_required[target_type] = max(0, pending_required[target_type] - 1)
				removal_targets += A
				removed = TRUE
				break
		if(removed || !bonus_complete)
			continue
		for(var/target_type in pending_bonus)
			if(pending_bonus[target_type] > 0 && istype(A, target_type))
				pending_bonus[target_type] = max(0, pending_bonus[target_type] - 1)
				removal_targets += A
				break
	for(var/atom/A in removal_targets)
		qdel(A)

	// Spawn reward
	var/obj/item/stack/f13Cash/caps/C = new /obj/item/stack/f13Cash/caps(connected_pod.loc)
	var/reward = max(1, current_quest.caps_reward)
	if(bonus_complete)
		reward += max(0, current_quest.bonus_reward)
	C.add(reward - 1)

	if(bonus_complete && current_quest.bonus_end_message)
		to_chat(user, current_quest.bonus_end_message)
	else
		to_chat(user, current_quest.end_message)

	// Remove quest + refill
	active_quests -= current_quest
	qdel(current_quest)
	if(next_stage_type)
		var/datum/bounty_quest/next_stage = new next_stage_type()
		active_quests.Insert(quest_index, next_stage)
	UpdateActiveQuests()

	return "Contract delivered."

/obj/machinery/bounty_machine/proc/FindPod(distance = 1)
	connected_pod = null
	for(var/obj/O in view(distance, src))
		if(istype(O, /obj/machinery/bounty_pod))
			connected_pod = O
			break

/obj/machinery/bounty_machine/proc/ShowUI(mob/user)
	if(!user) return

	var/dat = ""
	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/bounty_employers)
	assets.send(user)

	dat += "<h1>Wasteland Contracts Database</h1>"

	if(connected_pod)
		dat += "<font color='green'>Pod found</font><br>"
	else
		dat += "<font color='red'>Pod not found</font><br>"
	dat += "<a href='?src=\ref[src];findpod=1'>Rescan</a><br>"

	dat += "<style>.leftimg {float:left;margin: 7px 7px 7px 0;}</style>"
	dat += "<h2>Contracts:</h2>"

	var/i = 1
	for(var/datum/bounty_quest/Q in active_quests)
		dat += "<div class='statusDisplay'>"
		dat += "<img src='[Q.employer_icon]' class='leftimg' width=59 height=70></img>"
		dat += "<font color='green'><b>Name:</b> [Q.name]</font><br>"
		dat += "<font color='green'><b>Employer:</b> [Q.employer]</font><br>"
		dat += "<font color='green'><b>Message:</b> [Q.desc]</font><br>"
		dat += "<font color='green'><b>Need:</b> <i>[Q.need_message]</i></font><br>"
		if(Q.HasBonus())
			var/bonus_reward = max(0, Q.bonus_reward)
			dat += "<font color='green'><b>Bonus:</b> <i>[Q.bonus_need_message]</i> (+[bonus_reward] caps)</font><br>"
		dat += "<font color='green'><b>Reward:</b> [Q.caps_reward] caps</font> "
		dat += "<a href='?src=\ref[src];completequest=[i]'>Send</a>"
		dat += "</div>"
		i++

	var/datum/browser/popup = new(user, "bounty", "Wasteland Contracts Database", 640, 400)
	popup.set_content(dat)
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/bounty_machine/Topic(href, href_list)
	..()

	if(href_list["completequest"])
		var/msg = ProcessQuestComplete(href_list["completequest"], usr)
		to_chat(usr, msg)
		ShowUI(usr)
		return

	if(href_list["findpod"])
		FindPod(pod_distance)
		ShowUI(usr)
		return

/obj/machinery/bounty_machine/attack_hand(mob/user)
	..()
	ShowUI(user)

#undef STATE_IDLE
#undef STATE_VEND

// CAPS PAYCHECK SYSTEM - Recurring caps income for employed players
// Uses a timer loop that fires every PAYCHECK_INTERVAL
// Defines are in __DEFINES/roleplay_constants.dm

GLOBAL_LIST_EMPTY(pay_safes)

/proc/start_caps_paychecks()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(caps_paycheck_loop)), PAYCHECK_INTERVAL, TIMER_LOOP)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(quest_progress_loop)), 100, TIMER_LOOP)

/proc/caps_paycheck_loop()
	credit_all_paychecks()

/proc/quest_progress_loop()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat != DEAD && H.ckey)
			check_quest_progress_all(H)
			check_mercenary_contract_progress(H)
			if(H.client && !H.client.is_afk(300))
				check_perk_playtime(H.ckey, H.client.player_age, TRUE)

/proc/credit_all_paychecks()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat == DEAD || !H.mind || !H.mind.assigned_role)
			continue
		if(H.client && H.client.is_afk(600))
			continue
		var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
		if(!J || J.caps_paycheck <= 0)
			continue
		var/pay_amount = J.caps_paycheck
		var/obj/machinery/pay_safe/safe = find_nearest_pay_safe(H)
		if(safe)
			safe.stored_caps += pay_amount
			safe.owed_players[H.ckey] = (safe.owed_players[H.ckey] || 0) + pay_amount
			safe.update_icon()
			to_chat(H, span_notice("<b>PAYDAY!</b> [pay_amount] caps deposited in the pay safe near [get_area(safe)]. Go collect your wages!"))
		else
			var/obj/item/stack/f13Cash/caps/C = new(get_turf(H), pay_amount)
			if(H.put_in_hands(C))
				to_chat(H, span_notice("<b>PAYDAY!</b> You receive [pay_amount] caps for your work as [J.title]."))
			else
				to_chat(H, span_notice("<b>PAYDAY!</b> [pay_amount] caps dropped at your feet for your work as [J.title]."))
		if(H.ckey)
			adjust_karma(H.ckey, 1)
		log_game("PAYCHECK: [H.ckey] received [pay_amount] caps as [J.title]")

/proc/find_nearest_pay_safe(mob/living/carbon/human/H)
	if(!H || !H.z)
		return null
	var/best_dist = INFINITY
	var/obj/machinery/pay_safe/best_safe = null
	for(var/obj/machinery/pay_safe/safe in GLOB.pay_safes)
		if(safe.z != H.z || QDELETED(safe) || safe.stat & BROKEN)
			continue
		var/dist = get_dist(H, safe)
		if(dist < best_dist)
			best_dist = dist
			best_safe = safe
	return best_safe

/proc/check_mercenary_contract_progress(mob/living/carbon/human/H)
	if(!H || !H.ckey)
		return
	for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
		if(contract.assigned_to == H.ckey && contract.status == "active")
			contract.check_progress(H)
			contract.check_timeout()

// ============ PAY SAFE ============

/obj/machinery/pay_safe
	name = "Pay Safe"
	desc = "A reinforced safe where wages are deposited. Collect your hard-earned caps here."
	icon = 'icons/obj/vending.dmi'
	icon_state = "fridge_dark"
	density = TRUE
	anchored = TRUE
	var/stored_caps = 0
	var/list/owed_players = list()

/obj/machinery/pay_safe/Initialize()
	. = ..()
	GLOB.pay_safes += src

/obj/machinery/pay_safe/Destroy()
	GLOB.pay_safes -= src
	return ..()

/obj/machinery/pay_safe/update_icon()
	. = ..()
	if(stored_caps > 0)
		icon_state = "fridge_dark"
	else
		icon_state = "fridge_dark"

/obj/machinery/pay_safe/attack_hand(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/owed = owed_players[H.ckey] || 0
	var/html = "<center><h2>Pay Safe</h2>"
	html += "<p>Stored caps: <b>[stored_caps]</b></p>"
	if(owed > 0)
		html += "<p style='color:#44ff44;'>You have <b>[owed]</b> caps in wages to collect!</p>"
		html += "<a href='byond://?src=[REF(src)];collect=1'>Collect [owed] Caps</a>"
	else
		html += "<p style='color:#888888;'>You have no wages to collect.</p>"
	html += "</center>"
	var/datum/browser/popup = new(H, "paysafe_[REF(src)]", "Pay Safe", 350, 250)
	popup.set_content(html)
	popup.open()

/obj/machinery/pay_safe/Topic(href, href_list)
	if(href_list["collect"])
		if(!ishuman(usr))
			return
		var/mob/living/carbon/human/H = usr
		var/owed = owed_players[H.ckey] || 0
		if(owed <= 0 || stored_caps < owed)
			to_chat(H, span_warning("Nothing to collect."))
			return
		var/obj/item/stack/f13Cash/caps = new /obj/item/stack/f13Cash/caps(get_turf(H), owed)
		H.put_in_hands(caps)
		stored_caps -= owed
		owed_players -= H.ckey
		to_chat(H, span_notice("You collect [owed] caps from the pay safe!"))
		log_game("PAYSAFE: [H.ckey] collected [owed] caps from pay safe at [get_area(src)]")
		attack_hand(H)

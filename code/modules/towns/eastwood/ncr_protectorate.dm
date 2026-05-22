// NCR-Eastwood Protectorate Relations
// Defines the relationship between NCR and Eastwood

// ============ PROTECTORATE DATUM ============

/datum/ncr_protectorate
	var/active = TRUE
	var/treaty_date = 0
	var/weekly_tribute = NCR_WEEKLY_TRIBUTE
	var/tribute_paid_date = 0
	var/list/garrison_troops = list()
	var/protection_level = NCR_PROTECTION_LEVEL
	var/trade_agreement = TRUE
	var/list/treaty_terms = list()

/datum/ncr_protectorate/proc/get_garrison_count()
	return garrison_troops.len

/datum/ncr_protectorate/proc/can_add_garrison()
	return garrison_troops.len < NCR_GARRISON_MAX

/datum/ncr_protectorate/proc/add_garrison_troop(mob/user)
	if(!can_add_garrison())
		return FALSE

	var/datum/garrison_troop/troop = new()
	troop.ckey = user.ckey
	troop.name = user.name
	troop.assigned_date = world.time

	garrison_troops += troop
	return TRUE

/datum/ncr_protectorate/proc/remove_garrison_troop(target_ckey)
	for(var/datum/garrison_troop/T in garrison_troops)
		if(T.ckey == target_ckey)
			garrison_troops -= T
			qdel(T)
			return TRUE
	return FALSE

/datum/ncr_protectorate/proc/pay_tribute()
	if(tribute_paid_date && (world.time - tribute_paid_date) < (7 * 24 * 60 * 10))
		return FALSE

	tribute_paid_date = world.time
	return TRUE

/datum/ncr_protectorate/proc/is_tribute_due()
	if(!tribute_paid_date)
		return TRUE
	return (world.time - tribute_paid_date) >= (7 * 24 * 60 * 10)

/datum/ncr_protectorate/proc/set_protection_level(level)
	protection_level = clamp(level, 1, 5)
	return TRUE

/datum/ncr_protectorate/proc/get_protection_benefits()
	var/list/benefits = list()

	switch(protection_level)
		if(1)
			benefits["patrols"] = "Weekly"
			benefits["trade_bonus"] = 0.05
			benefits["garrison_limit"] = 5
		if(2)
			benefits["patrols"] = "Bi-weekly"
			benefits["trade_bonus"] = 0.10
			benefits["garrison_limit"] = 10
		if(3)
			benefits["patrols"] = "Weekly"
			benefits["trade_bonus"] = 0.15
			benefits["garrison_limit"] = 15
		if(4)
			benefits["patrols"] = "Daily"
			benefits["trade_bonus"] = 0.20
			benefits["garrison_limit"] = 20
		if(5)
			benefits["patrols"] = "Constant"
			benefits["trade_bonus"] = 0.25
			benefits["garrison_limit"] = 30

	return benefits

/datum/ncr_protectorate/proc/negotiate_terms(term_id, value)
	for(var/datum/protectorate_term/T in treaty_terms)
		if(T.term_id == term_id)
			T.value = value
			return TRUE
	return FALSE

// ============ GARRISON TROOP ============

/datum/garrison_troop
	var/ckey
	var/name
	var/assigned_date
	var/rank = "Private"

// ============ PROTECTORATE TERM ============

/datum/protectorate_term
	var/term_id
	var/name
	var/value
	var/negotiable = TRUE

// ============ NCR LIAISON OFFICE ============

/obj/machinery/computer/ncr_liaison
	name = "NCR Liaison Terminal"
	desc = "A terminal for NCR-Eastwood protectorate management."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/ncr_liaison/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/ncr_liaison/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NCRLiaison")
		ui.open()

/obj/machinery/computer/ncr_liaison/ui_data(mob/user)
	var/list/data = list()

	data["protectorate_active"] = GLOB.ncr_protectorate.active
	data["weekly_tribute"] = GLOB.ncr_protectorate.weekly_tribute
	data["tribute_due"] = GLOB.ncr_protectorate.is_tribute_due()
	data["protection_level"] = GLOB.ncr_protectorate.protection_level
	data["trade_agreement"] = GLOB.ncr_protectorate.trade_agreement
	data["garrison_count"] = GLOB.ncr_protectorate.get_garrison_count()
	data["garrison_max"] = NCR_GARRISON_MAX

	var/list/garrison_data = list()
	for(var/datum/garrison_troop/T in GLOB.ncr_protectorate.garrison_troops)
		garrison_data += list(list("ckey" = T.ckey, "name" = T.name, "rank" = T.rank))
	data["garrison"] = garrison_data

	var/list/benefits = GLOB.ncr_protectorate.get_protection_benefits()
	data["benefits"] = benefits

	return data

/obj/machinery/computer/ncr_liaison/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("pay_tribute")
			if(GLOB.ncr_protectorate.pay_tribute())
				to_chat(usr, span_notice("Weekly tribute paid to NCR."))
			else
				to_chat(usr, span_warning("Tribute already paid this week."))
			return TRUE

		if("add_garrison")
			if(GLOB.ncr_protectorate.add_garrison_troop(usr))
				to_chat(usr, span_notice("Added to NCR garrison."))
			else
				to_chat(usr, span_warning("Cannot add to garrison."))
			return TRUE

		if("remove_garrison")
			var/target_ckey = params["target_ckey"]
			if(GLOB.ncr_protectorate.remove_garrison_troop(target_ckey))
				to_chat(usr, span_notice("Removed from garrison."))
			return TRUE

		if("set_protection")
			var/level = text2num(params["level"])
			if(GLOB.ncr_protectorate.set_protection_level(level))
				to_chat(usr, span_notice("Protection level set to [level]."))
			return TRUE

		if("toggle_trade")
			GLOB.ncr_protectorate.trade_agreement = !GLOB.ncr_protectorate.trade_agreement
			to_chat(usr, span_notice("Trade agreement [GLOB.ncr_protectorate.trade_agreement ? "activated" : "suspended"]."))
			return TRUE

	return FALSE

// ============ NCR OUTPOST ============

/obj/structure/ncr_outpost
	name = "NCR Outpost"
	desc = "A small NCR military outpost."
	icon = 'icons/obj/structures.dmi'
	icon_state = "ncr_outpost"
	density = FALSE
	anchored = TRUE

/obj/structure/ncr_outpost/attack_hand(mob/user)
	to_chat(user, span_notice("NCR Garrison: [GLOB.ncr_protectorate.get_garrison_count()]/[NCR_GARRISON_MAX] troops."))

// ============ PROTECTORATE TREATY DOCUMENT ============

/obj/item/paper/protectorate_treaty
	name = "NCR-Eastwood Protectorate Treaty"
	desc = "The official treaty document between NCR and Eastwood."

/obj/item/paper/protectorate_treaty/Initialize(mapload)
	. = ..()
	info = {"<h2>NCR-Eastwood Protectorate Treaty</h2><br>
	<b>Article I: Protection</b><br>
	The New California Republic agrees to provide military protection to the settlement of Eastwood.<br><br>
	<b>Article II: Tribute</b><br>
	Eastwood agrees to pay a weekly tribute of [NCR_WEEKLY_TRIBUTE] caps to the NCR.<br><br>
	<b>Article III: Garrison</b><br>
	NCR may station up to [NCR_GARRISON_MAX] troops within Eastwood territory.<br><br>
	<b>Article IV: Trade</b><br>
	NCR and Eastwood agree to preferential trade terms with reduced tariffs.<br><br>
	<b>Article V: Jurisdiction</b><br>
	Eastwood retains local governance rights while NCR provides external security.<br><br>
	<i>Signed: [world.time]</i>"}
	update_icon()

// ============ GLOBAL INIT ============

GLOBAL_DATUM_INIT(eastwood_inn, /datum/eastwood_inn, new())
GLOBAL_DATUM_INIT(eastwood_clinic, /datum/eastwood_clinic, new())
GLOBAL_DATUM_INIT(eastwood_repair, /datum/eastwood_repair_shop, new())
GLOBAL_DATUM_INIT(ncr_protectorate, /datum/ncr_protectorate, new())

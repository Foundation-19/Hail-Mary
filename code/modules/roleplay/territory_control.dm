// Territory Control System
// Capturable resource nodes that factions can contest
// Provides periodic resources/bonuses to controlling faction

GLOBAL_LIST_EMPTY(territory_nodes)
GLOBAL_LIST_EMPTY(territory_captures)

#define TERRITORY_NEUTRAL "neutral"
#define TERRITORY_CAPTURING "capturing"
#define TERRITORY_CONTESTED "contested"
#define TERRITORY_CAPTURE_TIME 300
#define TERRITORY_RESOURCE_INTERVAL 5 MINUTES
#define TERRITORY_DEFEND_BONUS_REP 3
#define TERRITORY_CAPTURE_REP 10
#define TERRITORY_RESOURCE_CAPS 25
#define TERRITORY_RESOURCE_REP 5

/datum/territory_node
	var/node_id
	var/name = "Territory"
	var/description = "A strategic location in the wasteland."
	var/controlling_faction = "neutral"
	var/list/capture_progress = list()
	var/capture_threshold = TERRITORY_CAPTURE_TIME
	var/resource_type = "caps"
	var/resource_amount = TERRITORY_RESOURCE_CAPS
	var/list/connected_area_names = list()
	var/obj/machinery/territory_beacon/beacon
	var/last_capture_time = 0
	var/last_resource_time = 0
	var/bonus_xp = XP_DISCOVER_LOCATION

	var/static/next_id = 1

/datum/territory_node/New()
	node_id = "territory_[next_id++]"
	last_resource_time = world.time

/datum/territory_node/proc/get_ui_data()
	var/list/faction_progress = list()
	for(var/faction in capture_progress)
		faction_progress += list(list(
			"faction" = faction,
			"faction_name" = get_faction_name(faction),
			"progress" = capture_progress[faction],
			"progress_pct" = round(capture_progress[faction] / capture_threshold * 100),
		))
	return list(
		"node_id" = node_id,
		"name" = name,
		"description" = description,
		"controlling_faction" = controlling_faction,
		"controlling_faction_name" = controlling_faction == "neutral" ? "Unclaimed" : get_faction_name(controlling_faction),
		"resource_type" = resource_type,
		"resource_amount" = resource_amount,
		"capture_progress" = faction_progress,
		"last_capture_time" = last_capture_time,
	)

/datum/territory_node/proc/process_tick()
	if(!beacon || QDELETED(beacon))
		return

	var/list/faction_presence = count_faction_presence()

	if(!faction_presence.len)
		decay_progress()
		return

	var/dominant_faction = get_dominant_faction(faction_presence)

	if(dominant_faction == controlling_faction)
		capture_progress[dominant_faction] = min(capture_threshold, (capture_progress[dominant_faction] || 0) + 10)
		for(var/faction in capture_progress)
			if(faction != dominant_faction)
				capture_progress[faction] = max(0, capture_progress[faction] - 5)
		return

	if(controlling_faction != "neutral" && faction_presence.len > 1)
		for(var/faction in faction_presence)
			if(faction != controlling_faction)
				capture_progress[faction] = (capture_progress[faction] || 0) + 5
		capture_progress[controlling_faction] = max(0, (capture_progress[controlling_faction] || 0) - 10)
		return

	capture_progress[dominant_faction] = (capture_progress[dominant_faction] || 0) + 10

	for(var/faction in capture_progress)
		if(faction != dominant_faction)
			capture_progress[faction] = max(0, capture_progress[faction] - 3)

	if(capture_progress[dominant_faction] >= capture_threshold)
		complete_capture(dominant_faction)

/datum/territory_node/proc/count_faction_presence()
	var/list/presence = list()
	if(!beacon)
		return presence
	for(var/mob/living/carbon/human/H in view(7, beacon))
		if(H.stat == DEAD || !H.ckey)
			continue
		var/faction = get_mob_faction(H)
		if(faction && faction != "neutral")
			presence[faction] = (presence[faction] || 0) + 1
	return presence

/datum/territory_node/proc/get_dominant_faction(list/faction_presence)
	var/best_faction = null
	var/best_count = 0
	for(var/faction in faction_presence)
		if(faction_presence[faction] > best_count)
			best_count = faction_presence[faction]
			best_faction = faction
	return best_faction

/datum/territory_node/proc/decay_progress()
	for(var/faction in capture_progress)
		capture_progress[faction] = max(0, capture_progress[faction] - 2)

/datum/territory_node/proc/complete_capture(capturing_faction)
	var/old_faction = controlling_faction
	controlling_faction = capturing_faction
	last_capture_time = world.time
	capture_progress.Cut()

	var/area/A = get_area(beacon)
	var/area_name = A ? A.name : "unknown location"
	log_game("TERRITORY: [capturing_faction] captured '[name]' at [area_name] (was [old_faction])")

	for(var/mob/living/carbon/human/H in view(7, beacon))
		if(H.ckey)
			var/faction = get_mob_faction(H)
			if(faction == capturing_faction)
				to_chat(H, span_greentext("<b>TERRITORY CAPTURED!</b> [get_faction_name(capturing_faction)] now controls [name]!"))
				adjust_faction_reputation(H.ckey, capturing_faction, TERRITORY_CAPTURE_REP)
				add_xp(H.ckey, XP_DISCOVER_LOCATION, "territory_capture:[name]")
			else if(faction == old_faction && old_faction != "neutral")
				to_chat(H, span_boldwarning("<b>TERRITORY LOST!</b> [get_faction_name(old_faction)] has lost control of [name]!"))

	if(beacon)
		beacon.update_icon()

/datum/territory_node/proc/deliver_resources()
	if(controlling_faction == "neutral")
		return
	if(world.time < last_resource_time + TERRITORY_RESOURCE_INTERVAL)
		return

	last_resource_time = world.time

	var/list/recipients = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat == DEAD || !H.ckey)
			continue
		var/faction = get_mob_faction(H)
		if(faction == controlling_faction)
			recipients += H

	if(!recipients.len)
		return

	var/caps_each = max(5, round(resource_amount / recipients.len))
	for(var/mob/living/carbon/human/H in recipients)
		var/obj/item/stack/f13Cash/caps = new /obj/item/stack/f13Cash/caps(get_turf(H), caps_each)
		H.put_in_hands(caps)
		adjust_faction_reputation(H.ckey, controlling_faction, TERRITORY_RESOURCE_REP)
		to_chat(H, span_notice("<b>TERRITORY INCOME:</b> [caps_each] caps from [name] ([get_faction_name(controlling_faction)] territory)"))

/datum/territory_node/proc/get_mob_faction(mob/living/carbon/human/H)
	if(!H || !H.mind || !H.mind.assigned_role)
		return "neutral"
	var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
	if(!J)
		return "neutral"
	if(findtext(J.title, "NCR") || findtext(J.title, "ncr"))
		return "ncr"
	if(findtext(J.title, "Legion") || findtext(J.title, "legion"))
		return "legion"
	if(findtext(J.title, "Brotherhood") || findtext(J.title, "BOS") || findtext(J.title, "bos"))
		return "bos"
	if(findtext(J.title, "Enclave") || findtext(J.title, "enclave"))
		return "enclave"
	if(findtext(J.title, "Khan") || findtext(J.title, "khan"))
		return "greatkhans"
	if(findtext(J.title, "Follower") || findtext(J.title, "follower"))
		return "followers"
	return "neutral"

// ============ TERRITORY BEACON ============

/obj/machinery/territory_beacon
	name = "Territory Beacon"
	desc = "A broadcast beacon marking this location as a strategic territory. Control it to gain resources."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE
	var/datum/territory_node/territory

/obj/machinery/territory_beacon/Initialize()
	. = ..()
	if(!territory)
		territory = new /datum/territory_node()
		territory.beacon = src
		GLOB.territory_nodes += territory
	update_icon()

/obj/machinery/territory_beacon/Destroy()
	if(territory)
		GLOB.territory_nodes -= territory
		territory.beacon = null
		qdel(territory)
	return ..()

/obj/machinery/territory_beacon/update_icon()
	. = ..()
	if(territory)
		switch(territory.controlling_faction)
			if("ncr")
				icon_state = "computer" // Could use faction-colored states
			if("legion")
				icon_state = "computer"
			if("bos")
				icon_state = "computer"
			if("enclave")
				icon_state = "computer"
			else
				icon_state = "computer"

/obj/machinery/territory_beacon/attack_hand(mob/user)
	if(!ishuman(user))
		return
	ui_interact(user)

/obj/machinery/territory_beacon/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TerritoryBeacon")
		ui.open()

/obj/machinery/territory_beacon/ui_data(mob/user)
	var/list/node_data = territory ? territory.get_ui_data() : list()
	var/mob/living/carbon/human/H = user
	var/player_faction = territory ? territory.get_mob_faction(H) : "neutral"
	node_data["player_faction"] = player_faction
	node_data["player_faction_name"] = player_faction == "neutral" ? "Wastelander" : get_faction_name(player_faction)
	return node_data

/obj/machinery/territory_beacon/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	return FALSE

// ============ MAP-PLACED TERRITORY NODES ============

/obj/machinery/territory_beacon/water_station
	name = "Water Station Beacon"
	desc = "A water purification station. Control this to supply your faction with clean water and caps."

/obj/machinery/territory_beacon/water_station/Initialize()
	. = ..()
	if(territory)
		territory.name = "Water Station"
		territory.description = "A water purification station vital for wasteland survival."
		territory.resource_type = "water"
		territory.resource_amount = 30

/obj/machinery/territory_beacon/trading_post
	name = "Trading Post Beacon"
	desc = "A strategic trading post. Control this to generate caps for your faction."

/obj/machinery/territory_beacon/trading_post/Initialize()
	. = ..()
	if(territory)
		territory.name = "Trading Post"
		territory.description = "A valuable trading post on a major route."
		territory.resource_type = "caps"
		territory.resource_amount = 40

/obj/machinery/territory_beacon/tech_cache
	name = "Technology Cache Beacon"
	desc = "A pre-war technology cache. Control this for Brotherhood-level tech resources."

/obj/machinery/territory_beacon/tech_cache/Initialize()
	. = ..()
	if(territory)
		territory.name = "Technology Cache"
		territory.description = "A cache of pre-war technology of immense strategic value."
		territory.resource_type = "tech"
		territory.resource_amount = 35
		territory.capture_threshold = TERRITORY_CAPTURE_TIME * 1.5

/obj/machinery/territory_beacon/mine
	name = "Mine Beacon"
	desc = "A resource-rich mine. Control this for steady income."

/obj/machinery/territory_beacon/mine/Initialize()
	. = ..()
	if(territory)
		territory.name = "Mine"
		territory.description = "A mine rich with salvageable resources."
		territory.resource_type = "materials"
		territory.resource_amount = 50

/obj/machinery/territory_beacon/fortress
	name = "Fortress Beacon"
	desc = "A fortified position. Hard to capture, provides significant strategic advantage."

/obj/machinery/territory_beacon/fortress/Initialize()
	. = ..()
	if(territory)
		territory.name = "Fortress"
		territory.description = "A heavily fortified position with commanding views of the surrounding area."
		territory.resource_type = "military"
		territory.resource_amount = 45
		territory.capture_threshold = TERRITORY_CAPTURE_TIME * 2

// ============ TERRITORY PROCESSING ============

/proc/process_territory_control()
	for(var/datum/territory_node/node as anything in GLOB.territory_nodes)
		node.process_tick()
		node.deliver_resources()

/proc/start_territory_processing()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(process_territory_control)), 10, TIMER_LOOP)

// ============ TERRITORY STATUS COMMAND ============

/mob/living/carbon/human/verb/check_territory_status()
	set name = "Check Territory Status"
	set category = "IC"

	var/html = "<center><h2>Wasteland Territory Control</h2><hr>"

	if(!GLOB.territory_nodes.len)
		html += "<i>No territories have been established yet.</i>"
	else
		html += "<table width='100%'>"
		html += "<tr><th>Territory</th><th>Controller</th><th>Type</th><th>Income</th></tr>"
		for(var/datum/territory_node/node as anything in GLOB.territory_nodes)
			var/controller = node.controlling_faction == "neutral" ? "<span style='color:#888888'>Unclaimed</span>" : "<span style='color:#44aaff'>[get_faction_name(node.controlling_faction)]</span>"
			html += "<tr>"
			html += "<td>[node.name]</td>"
			html += "<td>[controller]</td>"
			html += "<td>[node.resource_type]</td>"
			html += "<td>[node.resource_amount]</td>"
			html += "</tr>"
		html += "</table>"

	html += "</center>"
	var/datum/browser/popup = new(src, "territory_status", "Territory Control", 500, 400)
	popup.set_content(html)
	popup.open()

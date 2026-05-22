// Hireable follower NPCs that follow and assist players

GLOBAL_LIST_EMPTY(active_companions)

#define COMPANION_STATE_FOLLOW 1
#define COMPANION_STATE_STAY 2
#define COMPANION_STATE_HUNT 3

/datum/component/companion
	var/mob/living/carbon/human/master
	var/state = COMPANION_STATE_FOLLOW
	var/datum/ai_laws/laws
	var/loyalty = 100
	var/attack_threshold = 30
	var/list/allowed_targets = list()

/datum/component/companion/Initialize(mob/living/carbon/human/new_master)
	if(!new_master)
		return COMPONENT_INCOMPATIBLE
	master = new_master
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, /datum/component/companion/proc/on_move)
	START_PROCESSING(SSfastprocess, src)
	GLOB.active_companions += src

/datum/component/companion/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	GLOB.active_companions -= src
	master = null
	return ..()

/datum/component/companion/process()
	if(QDELETED(master))
		qdel(parent)
		return

	switch(state)
		if(COMPANION_STATE_FOLLOW)
			follow_master()
		if(COMPANION_STATE_HUNT)
			hunt_targets()

/datum/component/companion/proc/follow_master()
	if(QDELETED(master))
		return

	var/mob/companion = parent
	var/dist = get_dist(companion, master)

	if(dist > 1)
		var/turf/target_turf = get_turf(master)
		var/turf/companion_turf = get_turf(companion)
		var/dir = get_dir(companion_turf, target_turf)

		var/turf/next_turf = get_step(companion_turf, dir)
		if(next_turf && !next_turf.density)
			companion.Move(next_turf, dir)

	if(dist > 5)
		companion.visible_message(span_notice("[companion] runs to catch up to [master]."))

/datum/component/companion/proc/hunt_targets()
	var/mob/companion = parent
	for(var/mob/living/L in view(7, companion))
		if(L == master)
			continue
		if(L in allowed_targets)
			attack_target(L)
			return

	var/list/possible_targets = list()
	for(var/mob/living/L in view(7, companion))
		if(L != master && L.stat == CONSCIOUS)
			var/faction_check = L.faction != master.faction
			if(faction_check)
				possible_targets += L

	if(possible_targets.len > 0)
		var/mob/target = pick(possible_targets)
		allowed_targets += target
		attack_target(target)

/datum/component/companion/proc/attack_target(mob/living/target)
	if(QDELETED(target))
		return

	var/mob/companion = parent
	if(get_dist(companion, target) > 1)
		var/turf/target_turf = get_turf(target)
		var/turf/companion_turf = get_turf(companion)
		var/dir = get_dir(companion_turf, target_turf)
		companion.Move(get_step(companion_turf, dir), dir)
	else
		if(ismob(target))
			companion.UnarmedAttack(target)

/datum/component/companion/proc/on_move()
	// Could add response to master moving

/datum/component/companion/proc/on_attacked(mob/living/carbon/human/attacker)
	if(attacker && attacker != master)
		allowed_targets += attacker
		if(state == COMPANION_STATE_STAY)
			state = COMPANION_STATE_HUNT
			to_chat(parent, span_warning("You were attacked! Switching to hunt mode!"))

/datum/component/companion/proc/set_state(new_state)
	state = new_state
	var/mob/companion = parent
	switch(state)
		if(COMPANION_STATE_FOLLOW)
			to_chat(companion, span_notice("I'll follow you."))
		if(COMPANION_STATE_STAY)
			to_chat(companion, span_notice("I'll stay here."))
		if(COMPANION_STATE_HUNT)
			to_chat(companion, span_notice("I'll hunt down any threats!"))

/datum/component/companion/proc/get_status()
	var/status_text = "Following"
	switch(state)
		if(COMPANION_STATE_STAY)
			status_text = "Staying"
		if(COMPANION_STATE_HUNT)
			status_text = "Hunting"
	return status_text

/mob/living/carbon/human/verb/companion_ui()
	set category = "Interaction"
	set name = "Companion Menu"

	var/datum/component/companion/C = GetComponent(/datum/component/companion)
	if(!C)
		to_chat(src, span_warning("You don't have a companion."))
		return

	C.show_ui()

/datum/component/companion/proc/show_ui()
	var/mob/companion = parent
	var/datum/browser/popup = new(companion, "companion_menu", "Companion", 400, 300)
	popup.set_content(generate_html())
	popup.open()

/datum/component/companion/proc/generate_html()
	var/mob/companion = parent
	var/status = get_status()

	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; }
			.status { padding: 10px; background: #221100; margin: 10px 0; }
			.btn { padding: 10px 20px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; margin: 5px; }
			.btn:hover { background: #443322; }
		</style>
	</head>
	<body>
		<h1>[companion.name]</h1>
		<div class="status">Status: [status]</div>
		<div class="controls">
			<button class="btn" onclick="setState('follow')">Follow</button>
			<button class="btn" onclick="setState('stay')">Stay</button>
			<button class="btn" onclick="setState('hunt')">Hunt</button>
		</div>
		<script>
			function setState(state) {
				window.location = 'byond://?src=[REF(master.client)];companion_action=' + state;
			}
		</script>
	</body>
	</html>
	"}
	return html

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["companion_action"])
		var/action = href_list["companion_action"]
		var/datum/component/companion/C = GetComponent(/datum/component/companion)
		if(C)
			switch(action)
				if("follow")
					C.set_state(COMPANION_STATE_FOLLOW)
				if("stay")
					C.set_state(COMPANION_STATE_STAY)
				if("hunt")
					C.set_state(COMPANION_STATE_HUNT)

	. = ..()

/obj/structure/sign/companion_recruiter
	name = "Companion Wanted Poster"
	desc = "A weathered poster advertising a hiring opportunity in the wasteland."
	icon = 'icons/obj/decals.dmi'
	icon_state = "poster1_legit"

/obj/structure/sign/companion_recruiter/Initialize()
	. = ..()
	update_icon()

/obj/structure/sign/companion_recruiter/attack_hand(mob/user)
	show_recruit_ui(user)

/obj/structure/sign/companion_recruiter/proc/show_recruit_ui(mob/user)
	var/datum/browser/popup = new(user, "recruit", "Hire Companion", 400, 400)
	popup.set_content({"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; }
			.companion { padding: 15px; background: #221100; margin: 10px 0; border: 1px solid #664422; }
			.name { color: #ffcc66; font-weight: bold; }
			.price { color: #99ff99; }
			.desc { color: #996633; margin: 10px 0; }
			.btn { padding: 10px 20px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; }
			.btn:hover { background: #443322; }
		</style>
	</head>
	<body>
		<h1>Wasteland Companions</h1>
		<div class="companion">
			<div class="name">Dogmeat (Wasteland Dog)</div>
			<div class="price">Cost: 200 caps</div>
			<div class="desc">A loyal mutt from the wastes. Good in a fight, better as a friend.</div>
			<button class="btn" onclick="hire('dogmeat')">Hire (200 caps)</button>
		</div>
		<div class="companion">
			<div class="name">Raider Buddy</div>
			<div class="price">Cost: 300 caps</div>
			<div class="desc">A rough but reliable mercenary. Knows the wastes well.</div>
			<button class="btn" onclick="hire('raider')">Hire (300 caps)</button>
		</div>
		<div class="companion">
			<div class="name">Wasteland Scholar</div>
			<div class="price">Cost: 500 caps</div>
			<div class="desc">An intelligent wanderer who can help with repairs and crafting.</div>
			<button class="btn" onclick="hire('scholar')">Hire (500 caps)</button>
		</div>
		<div class="companion">
			<div class="name">Vault Survivor</div>
			<div class="price">Cost: 100 caps</div>
			<div class="desc">Fresh from the vault, eager to explore the wasteland.</div>
			<button class="btn" onclick="hire('vault')">Hire (100 caps)</button>
		</div>
		<script>
			function hire(type) {
				window.location = 'byond://?src=[REF(user.client)];hire_companion=' + type;
			}
		</script>
	</body>
	</html>
	"})
	popup.open()

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["hire_companion"])
		var/companion_type = href_list["hire_companion"]
		hire_companion(companion_type)
		return

	. = ..()

/mob/living/carbon/human/proc/hire_companion(type)
	var/price = 0
	var/mob/living/companion_mob
	var/is_human = TRUE

	switch(type)
		if("dogmeat")
			price = 200
			is_human = FALSE
		if("raider")
			price = 300
		if("scholar")
			price = 500
		if("vault")
			price = 100
		else
			to_chat(src, span_warning("Unknown companion type."))
			return

	var/caps = 0
	for(var/obj/item/stack/f13Cash/C in get_contents())
		caps += C.amount

	if(caps < price)
		to_chat(src, span_warning("You need [price] caps to hire this companion."))
		return

	var/removed = 0
	for(var/obj/item/stack/f13Cash/C in get_contents())
		if(removed >= price)
			break
		var/take = min(C.amount, price - removed)
		if(take == C.amount)
			qdel(C)
		else
			C.amount -= take
		removed += take

	if(removed < price)
		to_chat(src, span_warning("You don't have enough caps."))
		return

	var/turf/spawn_turf = get_turf(src)
	spawn_turf = get_step(spawn_turf, pick(GLOB.cardinals))

	if(!spawn_turf)
		spawn_turf = get_turf(src)

	if(is_human)
		companion_mob = new /mob/living/carbon/human(spawn_turf)
		var/mob/living/carbon/human/H = companion_mob
		H.set_species(/datum/species/human)
	else
		companion_mob = new /mob/living/simple_animal/pet/dog/corgi(spawn_turf)

	switch(type)
		if("dogmeat")
			companion_mob.name = "Dogmeat"
			companion_mob.real_name = "Dogmeat"
		if("raider")
			companion_mob.name = "Raider Buddy"
			companion_mob.real_name = "Raider Buddy"
			var/mob/living/carbon/human/H = companion_mob
			H.equip_to_slot_or_del(new /obj/item/clothing/under/f13/mercc(H), SLOT_W_UNIFORM)
			H.equip_to_slot_or_del(new /obj/item/clothing/shoes/jackboots(H), SLOT_SHOES)
		if("scholar")
			companion_mob.name = "Wasteland Scholar"
			companion_mob.real_name = "Scholar"
			var/mob/living/carbon/human/H = companion_mob
			H.equip_to_slot_or_del(new /obj/item/clothing/under/f13/machinist(H), SLOT_W_UNIFORM)
			H.equip_to_slot_or_del(new /obj/item/clothing/head/hopcap(H), SLOT_HEAD)
		if("vault")
			companion_mob.name = "Vault Survivor"
			companion_mob.real_name = "Vault Survivor"
			var/mob/living/carbon/human/H = companion_mob
			H.equip_to_slot_or_del(new /obj/item/clothing/under/f13/vault(H), SLOT_W_UNIFORM)

	companion_mob.faction = faction
	companion_mob.AddComponent(/datum/component/companion, src)

	to_chat(src, span_notice("You hired [companion_mob.name] as your companion! Use Companion Menu to give them commands."))
	visible_message(span_notice("[src] hires [companion_mob.name] as a companion."))

	adjust_karma(ckey, 5)

// Random encounters and effects based on player karma

GLOBAL_VAR_INIT(karma_event_enabled, TRUE)
GLOBAL_VAR_INIT(last_karma_event_time, 0)

#define KARMA_EVENT_COOLDOWN 1800 // 3 minutes between events

/proc/handle_karma_events(mob/living/carbon/human/H)
	if(!GLOB.karma_event_enabled)
		return
	if(!H.client)
		return
	
	var/ckey = H.ckey
	if(!ckey)
		return
	
	// Cooldown check
	if(world.time - GLOB.last_karma_event_time < KARMA_EVENT_COOLDOWN)
		return
	
	GLOB.last_karma_event_time = world.time
	
	var/karma = get_karma(ckey)
	
	// Hero events (positive karma)
	if(karma >= KARMA_HERO)
		if(prob(5)) // 5% chance per check when eligible
			trigger_hero_event(H)
	
	// Villain events (negative karma)
	if(karma <= KARMA_VILLAIN)
		if(prob(8)) // 8% chance when eligible
			trigger_villain_event(H)
	
	// Legendary events
	if(karma >= KARMA_LEGEND)
		if(prob(3))
			trigger_legendary_event(H)
	
	// Infamous events
	if(karma <= KARMA_INFAMOUS)
		if(prob(5))
			trigger_infamous_event(H)

/proc/trigger_hero_event(mob/living/carbon/human/H)
	var/list/hero_events = list(
		"grateful_nomad",
		"merchant_gift",
		"free_healing",
		"story_told"
	)
	
	var/event_type = pick(hero_events)
	var/ckey = H.ckey
	
	switch(event_type)
		if("grateful_nomad")
			to_chat(H, span_notice("A nomad waves at you from the road. \"Thanks for all you do out here, hero!\""))
			H.visible_message(span_notice("[H] receives a wave from a passing nomad."))
			modify_karma_by_action(ckey, "help_stranger", null, "Grateful nomad acknowledged")
			adjust_faction_reputation(ckey, "ncr", 2)
			adjust_faction_reputation(ckey, "followers", 2)
		
		if("merchant_gift")
			to_chat(H, span_notice("A nearby merchant notices you and slides a stimpak your way. \"On the house, hero.\""))
			new /obj/item/reagent_containers/hypospray/medipen/stimpak(get_turf(H))
			modify_karma_by_action(ckey, "donate_charity", null, "Received gift from merchant")
		
		if("free_healing")
			to_chat(H, span_notice("A Follower of the Apocrypha approaches. \"Let me tend to your wounds, hero. No charge.\""))
			H.heal_overall_damage(30, 30)
			H.adjustToxLoss(-20)
			modify_karma_by_action(ckey, "heal_player", null, "Free healing from Followers")
		
		if("story_told")
			to_chat(H, span_notice("Travelers spot you and gather around to hear stories of your exploits."))
			modify_karma_by_action(ckey, "help_stranger", null, "Shared stories with travelers")

/proc/trigger_villain_event(mob/living/carbon/human/H)
	var/list/villain_events = list(
		"hostile_ambush",
		"bounty_placed",
		"merchant_refuse",
		"witness_flee"
	)
	
	var/event_type = pick(villain_events)
	var/ckey = H.ckey
	
	switch(event_type)
		if("hostile_ambush")
			to_chat(H, span_danger("You notice hostile figures watching you from the shadows..."))
			H.visible_message(span_danger("Raiders emerge, targeting [H]!"))
			modify_karma_by_action(ckey, "attack_peaceful", null, "Ambushed by hostiles")
			adjust_faction_reputation(ckey, "raiders", 5)
			adjust_faction_reputation(ckey, "ncr", -3)
		
		if("bounty_placed")
			to_chat(H, span_warning("You notice a bounty poster with your face on it!"))
			to_chat(H, span_notice("Bounty: 500 caps"))
			modify_karma_by_action(ckey, "kill_player", null, "Bounty placed on player")
		
		if("merchant_refuse")
			to_chat(H, span_warning("A merchant sees you and quickly packs up their wares. \"N-not today!\""))
			modify_karma_by_action(ckey, "intimidate", null, "Merchant frightened")
			adjust_faction_reputation(ckey, "ncr", -2)
		
		if("witness_flee")
			to_chat(H, span_warning("Locals spot you and quickly hide or flee."))
			H.visible_message(span_warning("People scatter as [H] approaches."))
			modify_karma_by_action(ckey, "intimidate", null, "Witnesses flee in fear")

/proc/trigger_legendary_event(mob/living/carbon/human/H)
	var/ckey = H.ckey
	
	var/list/legendary_rewards = list(
		"legendary_gear",
		"caps_gift",
		"reputation_boost",
		"rare_item"
	)
	
	var/reward_type = pick(legendary_rewards)
	
	switch(reward_type)
		if("legendary_gear")
			to_chat(H, span_greentext("A mysterious figure approaches and offers you equipment. \"A hero like you deserves this.\""))
			modify_karma_by_action(ckey, "complete_good_quest", null, "Legendary gear reward")
		
		if("caps_gift")
			to_chat(H, span_greentext("An envelope contains 200 caps and a note: \"For the legend.\""))
			modify_karma_by_action(ckey, "donate_charity", null, "Legendary caps gift")
		
		if("reputation_boost")
			to_chat(H, span_greentext("Word of your deeds spreads. All factions take notice."))
			adjust_faction_reputation(ckey, "ncr", 15)
			adjust_faction_reputation(ckey, "legion", 5)
			adjust_faction_reputation(ckey, "bos", 10)
			adjust_faction_reputation(ckey, "followers", 15)
		
		if("rare_item")
			to_chat(H, span_greentext("You find a cache of rare items left specifically for you."))
			modify_karma_by_action(ckey, "complete_good_quest", null, "Legendary item reward")

/proc/trigger_infamous_event(mob/living/carbon/human/H)
	var/ckey = H.ckey
	
	var/infamous_events = list("bounty_hunters", "faction_hostile", "scorched_earth", "dark_deal")
	
	var/event_type = pick(infamous_events)
	
	switch(event_type)
		if("bounty_hunters")
			to_chat(H, span_danger("Bounty hunters have found you!"))
			H.visible_message(span_danger("Armored figures engage [H]!"))
			modify_karma_by_action(ckey, "kill_player", null, "Bounty hunter attack")
			adjust_faction_reputation(ckey, "ncr", -10)
			adjust_faction_reputation(ckey, "legion", -5)
		
		if("faction_hostile")
			to_chat(H, span_warning("A faction has declared you an enemy!"))
			modify_karma_by_action(ckey, "kill_npc_friendly", null, "Faction hostile declaration")
		
		if("scorched_earth")
			to_chat(H, span_notice("Settlements go dark as you approach. They've learned to fear you."))
			modify_karma_by_action(ckey, "intimidate", null, "Settlements fear player")
			adjust_faction_reputation(ckey, "ncr", -15)
		
		if("dark_deal")
			to_chat(H, span_notice("A shadowy figure offers you dark work... for the right price."))
			modify_karma_by_action(ckey, "complete_evil_quest", null, "Dark deal offered")

/proc/apply_karma_vendor_bonus(mob/living/carbon/human/H, obj/item/stack/f13Cash/caps/price)
	var/ckey = H.ckey
	if(!ckey || !price)
		return
		
	var/karma_discount = get_karma_vendor_discount(ckey)
	if(karma_discount != 0)
		var/discount_amount = round(price.amount * karma_discount)
		if(discount_amount > 0)
			var/sign = karma_discount > 0 ? "+" : "-"
			to_chat(H, span_notice("[sign][abs(discount_amount)] caps [karma_discount > 0 ? "discount" : " markup"] (Karma: [get_karma_title(get_karma(ckey))])"))

/mob/living/carbon/human/Life()
	. = ..()
	if(.)
		if(ckey && !initialized_perks)
			initialize_perk_system()
			initialized_perks = TRUE
		if(client && prob(1))
			handle_karma_events(src)

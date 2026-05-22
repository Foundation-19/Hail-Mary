// Allows NPCs to offer services (healing, repair, storage, training) via dialogue

GLOBAL_LIST_EMPTY(npc_services_cache)

/datum/npc_service
	var/service_id
	var/name
	var/description
	var/cost_type = "caps" // caps, rep, item, free
	var/cost = 0
	var/required_skill = 0
	var/cooldown = 0
	var/last_used = 0

/proc/load_services_for_dialogue(dialogue_type)
	if(!GLOB.json_dialogue_cache.len)
		load_dialogue_files()
	
	var/dialogue_data = GLOB.json_dialogue_cache[dialogue_type]
	if(!dialogue_data || !dialogue_data["services"])
		return list()
	
	var/list/services = list()
	for(var/service_id in dialogue_data["services"])
		var/list/service_data = dialogue_data["services"][service_id]
		var/datum/npc_service/service = new()
		service.service_id = service_id
		service.name = service_data["name"] || service_id
		service.description = service_data["description"] || ""
		service.cost_type = service_data["cost_type"] || "caps"
		service.cost = service_data["cost"] || 0
		service.required_skill = service_data["required_skill"] || 0
		service.cooldown = service_data["cooldown"] || 0
		services[service_id] = service
	
	return services

/proc/get_service_data(dialogue_type, service_id)
	var/list/services = load_services_for_dialogue(dialogue_type)
	return services[service_id]

/proc/can_afford_service(mob/living/carbon/human/user, datum/npc_service/service)
	if(!user || !service)
		return FALSE
	
	switch(service.cost_type)
		if("caps")
			var/player_caps = get_caps_amount(user)
			return player_caps >= service.cost
		if("free")
			return TRUE
	
	return FALSE

/proc/pay_for_service(mob/living/carbon/human/user, datum/npc_service/service)
	if(!user || !service)
		return FALSE
	
	if(!can_afford_service(user, service))
		return FALSE
	
	switch(service.cost_type)
		if("caps")
			remove_caps(user, service.cost)
	
	return TRUE

/proc/execute_service(mob/living/carbon/human/user, datum/npc_service/service, mob/living/simple_animal/hostile/npc)
	if(!user || !service)
		return "error"
	
	// Check cooldown
	if(service.cooldown > 0 && service.last_used > 0)
		if(world.time < service.last_used + service.cooldown)
			return "cooldown"
	
	// Check if can afford
	if(!can_afford_service(user, service))
		return "insufficient_funds"
	
	// Apply attitude modifier to cost
	var/actual_cost = service.cost
	if(npc)
		actual_cost = npc.apply_attitude_to_price(service.cost, user)
		service.cost = actual_cost
	
	// Pay
	if(!pay_for_service(user, service))
		return "payment_failed"
	
	// Execute the service effect
	var/result = "success"
	
	// Check for service type in the service data
	var/service_data = GLOB.json_dialogue_cache[npc?.dialogue_type]?["services"]?[service.service_id]
	var/effect = service_data?["effect"]
	
	if(effect)
		switch(effect)
			if("heal_all")
				heal_player_fully(user)
				to_chat(user, span_notice("You feel completely healed!"))
			if("heal_50")
				heal_player_amount(user, 50)
				to_chat(user, span_notice("You feel much better!"))
			if("cure_radiation")
				cure_radiation(user)
				to_chat(user, span_notice("The radiation sickness fades."))
			if("repair_all")
				repair_equipment(user)
				to_chat(user, span_notice("Your equipment has been repaired."))
			if("identify")
				to_chat(user, span_notice("The item has been identified."))
			if("train_skill")
				var/skill = service_data["skill"]
				var/amount = service_data["amount"] || 1
				train_player_skill(user, skill, amount)
				to_chat(user, span_notice("You feel more skilled!"))
			else
				// Generic effect - just notify
				to_chat(user, span_notice("Service completed: [service.name]"))
	
	// Apply attitude service modifier for healing services
	if(npc && effect && findtext(effect, "heal"))
		var/modifier = get_attitude_service_modifier(npc, user)
		if(modifier > 1.0)
			var/bonus = round((modifier - 1.0) * 100)
			to_chat(user, span_notice("You received a [bonus]% bonus from the friendly service!"))
	
	// Record interaction
	if(npc)
		npc.record_player_interaction(user, "talked")
	
	// Set cooldown
	service.last_used = world.time
	
	return result

/proc/heal_player_fully(mob/living/carbon/human/user)
	if(!user)
		return
	
	user.adjustBruteLoss(-user.getBruteLoss())
	user.adjustFireLoss(-user.getFireLoss())
	user.adjustToxLoss(-user.getToxLoss())
	user.adjustOxyLoss(-user.getOxyLoss())
	user.adjustCloneLoss(-user.getCloneLoss())
	
	// Heal limbs
	for(var/obj/item/bodypart/BP in user.bodyparts)
		BP.heal_damage(100, 100, TRUE, FALSE)

/proc/heal_player_amount(mob/living/carbon/human/user, amount)
	if(!user)
		return
	
	user.adjustBruteLoss(-amount)
	user.adjustFireLoss(-amount)
	user.adjustToxLoss(-amount * 0.5)
	user.adjustOxyLoss(-amount)

/proc/cure_radiation(mob/living/carbon/human/user)
	if(!user)
		return
	
	user.radiation = 0

/proc/repair_equipment(mob/living/carbon/human/user)
	if(!user)
		return
	
	for(var/obj/item/I in user.get_contents())
		if(I.obj_integrity < I.max_integrity)
			I.obj_integrity = I.max_integrity

/proc/train_player_skill(mob/living/carbon/human/user, skill, amount)
	if(!user || !user.mind)
		return
	
	to_chat(user, span_notice("You receive training in [skill]."))

/proc/remove_caps(mob/living/carbon/human/user, amount)
	if(!user)
		return FALSE
	
	for(var/obj/item/stack/f13Cash/caps/C in user.get_contents())
		if(C.amount >= amount)
			C.use(amount)
			return TRUE
		else
			amount -= C.amount
			C.use(C.amount)
			if(amount <= 0)
				return TRUE
	
	return FALSE

// Service dialogue response handler
/proc/handle_service_response(mob/living/carbon/human/user, mob/living/simple_animal/hostile/npc, service_id)
	if(!user || !npc || !service_id)
		return "error"
	
	var/datum/npc_service/service = get_service_data(npc.dialogue_type, service_id)
	if(!service)
		return "not_found"
	
	return execute_service(user, service, npc)

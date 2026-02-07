// In this document: Goat, Chicken, Brahmin, Radstag, Bighorner (also cow but extinct so basically brahmin)

//////////
// GOAT //
//////////

/mob/living/simple_animal/hostile/retaliate/goat
	name = "goat"
	desc = "Not known for their pleasant disposition."
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "goat"
	icon_living = "goat"
	icon_dead = "goat_dead"
	speak = list("EHEHEHEHEH","eh?")
	speak_emote = list("brays")
	emote_hear = list("brays.")
	emote_see = list("shakes its head.", "stamps a foot.", "glares around.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4)
	response_help_continuous  = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	faction = list("neutral")
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	attack_same = 1
	attack_verb_continuous = "kicks"
	attack_verb_simple = "kick"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 40
	maxHealth = 40
	melee_damage_lower = 1
	melee_damage_upper = 2
	environment_smash = ENVIRONMENT_SMASH_NONE
	stop_automated_movement_when_pulled = 1
	blood_volume = 480
	var/obj/item/udder/udder = null
	var/datum/reagent/milk_reagent = /datum/reagent/consumable/milk

	footstep_type = FOOTSTEP_MOB_SHOE

/mob/living/simple_animal/hostile/retaliate/goat/Initialize(/datum/reagent/milk_reagent)
	if(milk_reagent)
		src.milk_reagent = milk_reagent
	udder = new (null, src.milk_reagent)
	. = ..()

/mob/living/simple_animal/hostile/retaliate/goat/Destroy()
	qdel(udder)
	udder = null
	return ..()

/mob/living/simple_animal/hostile/retaliate/goat/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	if(stat == CONSCIOUS)
		//chance to go crazy and start wacking stuff
		if(!enemies.len && prob(1))
			Retaliate()

		if(enemies.len && prob(10))
			enemies.Cut()
			LoseTarget()
			src.visible_message(span_notice("[src] calms down."))
		udder.generateMilk(milk_reagent)
		eat_plants()
		if(!pulledby)
			for(var/direction in shuffle(list(1,2,4,8,5,6,9,10)))
				var/step = get_step(src, direction)
				if(step)
					if(locate(/obj/structure/spacevine) in step || locate(/obj/structure/glowshroom) in step)
						Move(step, get_dir(src, step))

/mob/living/simple_animal/hostile/retaliate/goat/Retaliate()
	..()
	src.visible_message(span_danger("[src] gets an evil-looking gleam in [p_their()] eye."))

/mob/living/simple_animal/hostile/retaliate/goat/Move()
	. = ..()
	if(!stat)
		eat_plants()

/mob/living/simple_animal/hostile/retaliate/goat/proc/eat_plants()
	var/eaten = FALSE
	var/obj/structure/spacevine/SV = locate(/obj/structure/spacevine) in loc
	if(SV)
		SV.eat(src)
		eaten = TRUE

	var/obj/structure/glowshroom/GS = locate(/obj/structure/glowshroom) in loc
	if(GS)
		qdel(GS)
		eaten = TRUE

	if(eaten && prob(10))
		say("Nom")

/mob/living/simple_animal/hostile/retaliate/goat/attackby(obj/item/O, mob/user, params)
	if(stat == CONSCIOUS && istype(O, /obj/item/reagent_containers/glass))
		udder.milkAnimal(O, user)
		return 1
	else
		return ..()


/mob/living/simple_animal/hostile/retaliate/goat/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		if(istype(H.dna.species, /datum/species/pod))
			var/obj/item/bodypart/NB = pick(H.bodyparts)
			H.visible_message(span_warning("[src] takes a big chomp out of [H]!"), \
									span_userdanger("[src] takes a big chomp out of your [NB]!"))
			NB.dismember()

//cow
/mob/living/simple_animal/cow
	name = "cow"
	desc = "Known for their milk, just don't tip them over."
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "brahmin"
	icon_living = "brahmin"
	icon_dead = "brahmin_dead"
	icon_gib = "brahmin_gib"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("moo?","moo","MOOOOOO")
	speak_emote = list("moos","moos hauntingly")
	emote_hear = list("brays.")
	emote_see = list("shakes its head.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 6)
	response_help_continuous  = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	attack_verb_continuous = "kicks"
	attack_verb_simple = "kick"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 200
	maxHealth = 200
	var/list/ride_offsets = list(
		"1" = list(0, 8),
		"2" = list(0, 8),
		"4" = list(-2, 8),
		"8" = list(2, 8)
		)
	var/obj/item/udder/udder = null
	var/datum/reagent/milk_reagent = /datum/reagent/consumable/milk
	var/list/food_types = list(/obj/item/reagent_containers/food/snacks/grown/wheat, /obj/item/stack/sheet/hay)
	gold_core_spawnable = FRIENDLY_SPAWN
	var/is_calf = 0
	var/has_calf = 0
	var/young_type = null
	blood_volume = 480
	var/ride_move_delay = 3.5
	var/hunger = 1
	COOLDOWN_DECLARE(hunger_cooldown)

	var/last_fear_check = 0
	var/fear_check_cooldown = 30 // 3 seconds in deciseconds
	var/being_untipped = FALSE
	var/auto_untip_attempted = FALSE

	footstep_type = FOOTSTEP_MOB_SHOE
	
///////////////////////
//Dave's Brahmin Bags//
///////////////////////

	var/mob/living/owner = null
	var/follow = FALSE

	var/bridle = FALSE
	var/bags = FALSE
	var/collar = FALSE
	var/saddle = FALSE
	var/brand = ""
	var/mob/living/carbon/human/current_rider

	// MOUNT SPRINT VARS
	var/is_sprinting = FALSE
	var/base_move_delay = 0
	var/sprint_move_delay = 0
	var/last_sprint_time = 0
	var/sprint_hunger_cost = 0.05 // FIXED: Reduced from 0.1 to allow ~4 full sprints
	var/hunger_float = 1.0 // Precise hunger tracking
	COOLDOWN_DECLARE(sprint_cooldown) // NEW: Cooldown tracker

	// LOYALTY SYSTEM
	var/loyalty = 0 // Current loyalty value
	var/loyalty_max = 100
	
	// Static loyalty bonuses (permanent)
	var/loyalty_from_name = 0 // +20 for being named
	var/loyalty_from_brand = 0 // +15 for being branded
	
	// Temporary loyalty tracking
	var/loyalty_from_petting = 0 // Caps at 10
	var/loyalty_from_feeding = 0 // Caps at 20
	COOLDOWN_DECLARE(healing_loyalty_cooldown)
	
	// Decay rate
	var/loyalty_decay_rate = 0.5 // How much loyalty decays per life tick
	
	COOLDOWN_DECLARE(loyalty_decay_cooldown)
	COOLDOWN_DECLARE(petting_cooldown) // Prevent spam petting

/mob/living/simple_animal/cow/Initialize()
	udder = new(null, milk_reagent)
	base_move_delay = ride_move_delay
	sprint_move_delay = ride_move_delay * 0.5
	hunger_float = hunger
	. = ..()

/mob/living/simple_animal/cow/Destroy()
	qdel(udder)
	udder = null
	return ..()

/mob/living/simple_animal/cow/death(gibbed)
	. = ..()
	if(can_buckle)
		can_buckle = FALSE
	if(buckled_mobs)
		for(var/mob/living/M in buckled_mobs)
			unbuckle_mob(M)
	for(var/atom/movable/stuff_innit in contents)
		stuff_innit.forceMove(get_turf(src))
	if(collar)
		new /obj/item/brahmincollar(get_turf(src))
	if(bridle)
		new /obj/item/brahminbridle(get_turf(src))
	if(saddle)
		new /obj/item/brahminsaddle(get_turf(src))

// Calculate total loyalty including all sources
/mob/living/simple_animal/cow/proc/get_total_loyalty()
	return loyalty_from_name + loyalty_from_brand + loyalty_from_petting + loyalty_from_feeding + loyalty

// Add loyalty with feedback
/mob/living/simple_animal/cow/proc/add_loyalty(amount, source)
	loyalty = clamp(loyalty + amount, 0, loyalty_max)
	if(source && current_rider)
		to_chat(current_rider, span_notice("[src]'s loyalty increases from [source]!"))

// Loyalty from healing (only when damaged)
/mob/living/simple_animal/cow/proc/grant_healing_loyalty(amount_healed, mob/healer)
	if(!healer || amount_healed <= 0)
		return
	
	// Prevent spam healing for loyalty
	if(!COOLDOWN_FINISHED(src, healing_loyalty_cooldown))
		return
	
	// Grant loyalty based on % of health healed
	// 10% max health healed = +2 loyalty
	var/health_percent_healed = (amount_healed / maxHealth) * 100
	var/loyalty_gain = round(health_percent_healed / 5) // Every 5% = +1 loyalty
	
	if(loyalty_gain > 0)
		loyalty += loyalty_gain
		loyalty = clamp(loyalty, 0, loyalty_max)
		to_chat(healer, span_notice("[src] seems grateful for your care! (+[loyalty_gain] loyalty)"))
		
		COOLDOWN_START(src, healing_loyalty_cooldown, 30 SECONDS)

// NAME CALLING - listen for owner calling mount's name
/mob/living/simple_animal/cow/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode, atom/sound_loc)
	. = ..()

	// Only respond to owner with collar
	if(!owner || !collar || stat || speaker != owner)
		return

	// Check if they're calling the mount by name
	if(findtext(lowertext(message), lowertext(name)))
		if(findtext(lowertext(message), "come") || findtext(lowertext(message), "here"))
			attempt_come_to_owner(speaker)
		else if(findtext(lowertext(message), "stay") || findtext(lowertext(message), "stop"))
			attempt_stay(speaker)

/mob/living/simple_animal/cow/proc/attempt_come_to_owner(mob/living/caller)
	if(!caller || stat)
		return
	
	var/total_loyalty = get_total_loyalty()
	
	// Loyalty determines success chance
	var/success_chance = min(30 + (total_loyalty * 0.6), 100)
	
	if(!prob(success_chance))
		// Failed to respond
		var/list/fail_messages = list(
			"[src] looks at [caller] but doesn't move.",
			"[src] flicks an ear but ignores the call.",
			"[src] seems distracted by something else.",
			"[src] glances at [caller] uncertainly."
		)
		visible_message(span_notice(pick(fail_messages)))
		return
	
	// Success! Mount comes to owner
	var/list/success_messages = list(
		"[src] perks up and trots toward [caller]!",
		"[src] eagerly responds to [caller]'s call!",
		"[src] obediently approaches [caller]."
	)
	visible_message(span_notice(pick(success_messages)))
	
	// Start following owner
	follow = TRUE
	
	// Kick off the fast following loop
	start_following_loop()
	
	// Small loyalty boost for successful recall
	if(loyalty < loyalty_max)
		loyalty = min(loyalty + 2, loyalty_max)

// New proc: Fast following loop (like flee but toward owner)
/mob/living/simple_animal/cow/proc/start_following_loop()
	spawn(0)
		while(!stat && follow && owner)
			if(Adjacent(owner))
				sleep(5) // Wait a bit when next to owner
				continue
			
			if(!CHECK_MOBILITY(src, MOBILITY_MOVE) || !isturf(loc))
				break
			
			step_to(src, owner, 0)
			sleep(4) // Slower movement - matches walking pace (2 for jogging, 4 for walking, 6 for crawling)

/mob/living/simple_animal/cow/proc/attempt_stay(mob/living/caller)
	if(!caller || stat)
		return
	
	var/total_loyalty = get_total_loyalty()
	var/success_chance = min(30 + (total_loyalty * 0.6), 100)
	
	if(!prob(success_chance))
		var/list/fail_messages = list(
			"[src] continues following [caller].",
			"[src] doesn't seem to understand.",
			"[src] ignores the command."
		)
		visible_message(span_notice(pick(fail_messages)))
		return
	
	// Success! Mount stops
	var/list/success_messages = list(
		"[src] stops and stands still.",
		"[src] obediently halts.",
		"[src] comes to a stop."
	)
	visible_message(span_notice(pick(success_messages)))
	
	follow = FALSE

// Fear chance is always 25% below 75% HP - loyalty doesn't reduce it
/mob/living/simple_animal/cow/proc/get_fear_chance()
	if(!saddle && !bridle)
		return 0
	
	var/health_percent = (health / maxHealth) * 100
	
	// No fear above 75% HP
	if(health_percent >= 75)
		return 0
	
	// Base 25% fear chance below 75% HP (loyalty doesn't affect this)
	return 25

// New proc: Calculate loyalty resistance chance
/mob/living/simple_animal/cow/proc/get_loyalty_resistance()
	var/total_loyalty = get_total_loyalty()
	
	// Every 10 loyalty = 5% chance to resist fear
	// Max loyalty (155) = 77.5% resistance chance
	var/resistance_chance = (total_loyalty / 10) * 5
	
	return resistance_chance

/mob/living/simple_animal/cow/proc/get_bucking_chance()
	if(!saddle && !bridle)
		return 0
	
	var/health_percent = (health / maxHealth) * 100
	
	// No bucking above 75% HP
	if(health_percent >= 75)
		return 0
	
	// Calculate 25% health chunks lost
	// 75% HP = 0 chunks, 50% HP = 1 chunk, 25% HP = 2 chunks, 0% HP = 3 chunks
	var/health_chunks_lost = round((75 - health_percent) / 25)
	health_chunks_lost = clamp(health_chunks_lost, 0, 3)
	
	// 5% chance per chunk
	var/bucking_chance = health_chunks_lost * 5
	
	return bucking_chance

/mob/living/simple_animal/cow/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, include_roboparts = FALSE)
	. = ..()
	if(amount > 0 && !stat)
		// Stop following when damaged
		if(follow)
			follow = FALSE
			if(owner)
				visible_message(span_warning("[src] stops following [owner] due to the pain!"))
		
		// FEAR PROC when unmounted and damaged
		if(!current_rider && amount >= 5) // Only if unmounted and significant damage
			var/fear_chance = 60 // 60% chance to panic
			if(prob(fear_chance))
				visible_message(span_warning("[src] panics from the pain and flees in terror!"))
				
				// Flee like the bucking code
				spawn(0)
					for(var/i in 1 to rand(6,10))
						if(stat)
							break
						var/flee_dir = pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
						step(src, flee_dir)
						sleep(3)
		
		// Existing pain emote code
		if(prob(30))
			var/list/pain_emotes = list(
				"[src] lets out a pained cry!",
				"[src] whimpers in pain!",
				"[src] cries out!",
				"[src] bellows in distress!"
			)
			visible_message(span_warning(pick(pain_emotes)))

/mob/living/simple_animal/cow/Move(NewLoc, direct)
	// Check sprint status BEFORE every move
	if(current_rider && saddle)
		var/datum/keybinding/living/toggle_sprint/sprint_bind = GLOB.keybindings_by_name["toggle_sprint"]
		var/datum/keybinding/living/hold_sprint/sprint_hold_bind = GLOB.keybindings_by_name["hold_sprint"]
		var/trying_to_sprint = (current_rider.client in sprint_bind.is_down) || (current_rider.client in sprint_hold_bind.is_down)
		
		// Stop sprint immediately if key released
		if(!trying_to_sprint && is_sprinting)
			stop_mount_sprint(current_rider)
	
	if(current_rider && (saddle || bridle) && world.time >= last_fear_check + fear_check_cooldown)
		last_fear_check = world.time
		var/fear_chance = get_fear_chance()
		
		if(fear_chance > 0 && prob(fear_chance))
			// Fear triggered! Now check if loyalty resists it
			var/resistance_chance = get_loyalty_resistance()
			
			if(resistance_chance > 0 && prob(resistance_chance))
				// LOYALTY OVERCOMES FEAR!
				var/list/resolve_messages = list(
					"[src] trembles with fear, but their loyalty to [current_rider] holds strong!",
					"[src] fights through their terror with unwavering devotion!",
					"[src] steadies themself, trusting in their bond with [current_rider]!",
					"[src] resists their fear through sheer loyalty!",
					"[src] pushes past their panic, determined not to fail [current_rider]!"
				)
				visible_message(span_notice(pick(resolve_messages)))
				to_chat(current_rider, span_green("[src]'s loyalty overcomes their fear!"))
				return ..() // Continue moving normally
			
			// Fear wins - loyalty wasn't enough
			var/bucking_chance = get_bucking_chance()
			var/total_loyalty = get_total_loyalty()
			
			// Show loyalty resistance message based on loyalty level
			if(total_loyalty > 50)
				visible_message(span_notice("[src] struggles valiantly against their fear, but it's too much!"))
			else if(total_loyalty > 20)
				visible_message(span_notice("[src] tries to resist their fear, but fails..."))
			
			if(prob(bucking_chance))
				// FULL BUCKING - throw rider off AND flee
				visible_message(span_warning("[src] bucks wildly and rears back!"))
				to_chat(current_rider, span_userdanger("[src] throws you off!"))
				
				Stun(20)
				
				if(current_rider)
					var/mob/living/rider = current_rider
					
					// Screen shake effect
					if(rider.client)
						shake_camera(rider, 3, 3)
					
					var/throw_dir = turn(dir, pick(-45, 45))
					var/turf/throw_target = get_step(src, throw_dir)
					
					unbuckle_mob(rider)
					rider.Paralyze(20)
					
					if(throw_target)
						rider.throw_at(throw_target, 2, 1)
				
				// FLEE
				visible_message(span_warning("[src] flees in terror!"))
				spawn(0)
					for(var/i in 1 to rand(5,8))
						if(stat)
							break
						var/flee_dir = pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
						step(src, flee_dir)
						sleep(3)
			else
				// MINOR STUTTER - just resist movement
				visible_message(span_warning("[src] balks and resists!"))
				to_chat(current_rider, span_warning("[src] is frightened!"))
				Stun(20)
			
			return FALSE
	
	return ..()

/mob/living/simple_animal/cow/examine(mob/user)
	. = ..()
	if(collar)
		. += "<br>A collar with a tag etched '[name]' is hanging from its neck."
	if(brand)
		. += "<br>It has a brand reading '[brand]' on its backside."
	if(bridle)
		. += "<br>It has a bridle and reins attached to its head."
	if(bags)
		. += "<br>It has some bags attached."
	if(saddle)
		. += "<br>It has a saddle across its back."
	if(health <= 0 || stat != CONSCIOUS)
		return
	if(saddle || bridle)
		. += "<br>Feeding this beast will let it move quickly for longer! You'll need to remove their bridle and saddle to get them pregnant."
	else
		. += "<br>Feeding this beast will get it pregnant! You'll need to give them a bridle and/or a saddle to feed their hunger."
	switch(hunger)
		if(1)
			. += "<br>They look well fed."
		if(2)
			. += "<br>They look hungry."
		if(3)
			. += "<br>They look <i>really</i> hungry."
		else
			. += "<br>They look fuckin <i>famished</i>."

/mob/living/simple_animal/cow/attackby(obj/item/O, mob/user, params)
	// Allow weapons to damage mounted animals with HARM intent
	if(user.a_intent == INTENT_HARM)
		// Call parent but prevent unbuckling
		var/original_buckle = can_buckle
		can_buckle = FALSE
		. = ..()
		can_buckle = original_buckle
		return
	
	// Existing attackby code for milking, feeding, etc. (non-HARM intent)
	if(stat == CONSCIOUS && istype(O, /obj/item/reagent_containers/glass))
		udder.milkAnimal(O, user)
		return TRUE
	if(stat == CONSCIOUS && is_type_in_list(O, food_types))
		feed_em(O, user)
		return

	if(istype(O,/obj/item/brahmincollar))
		if(user != owner)
			to_chat(user, span_warning("You need to claim the mount with a bridle before you can rename it!"))
			return

		name = input("Choose a new name for your mount!","Name", name)

		if(!name)
			return

		collar = TRUE
		loyalty_from_name = 20
		to_chat(user, span_notice("You add [O] to [src]. They seem to recognize their new name!"))
		message_admins(span_notice("[ADMIN_LOOKUPFLW(user)] renamed a mount to [name]."))
		qdel(O)
		return

	if(istype(O,/obj/item/brahminbridle))
		if(bridle)
			to_chat(user, span_warning("This mount already has a bridle!"))
			return

		owner = user
		bridle = TRUE
		tame = TRUE
		to_chat(user, span_notice("You add [O] to [src], claiming it as yours."))
		qdel(O)
		return

	if(istype(O,/obj/item/brahminsaddle))
		install_saddle(O, user)
		return

	if(istype(O,/obj/item/brahminbrand))
		if(brand)
			to_chat(user, span_warning("This mount already has a brand!"))
			return
		
		if(user != owner)
			to_chat(user, span_warning("You need to claim the mount with a bridle before you can brand it!"))
			return
		
		var/total_loyalty = get_total_loyalty()
		
		var/kick_chance = 0
		if(total_loyalty < 40)
			kick_chance = 80
		else if(total_loyalty < 60)
			kick_chance = 60
		else if(total_loyalty < 80)
			kick_chance = 40
		
		if(kick_chance > 0 && prob(kick_chance))
			visible_message(span_danger("[src] violently kicks [user] away!"))
			to_chat(user, span_userdanger("[src] kicks you hard in the chest!"))
			
			if(isliving(user))
				var/mob/living/L = user
				
				if(L.client)
					shake_camera(L, 4, 4)
				
				L.apply_damage(25, BRUTE, BODY_ZONE_CHEST)
				L.Paralyze(20)
				L.Knockdown(30)
				
				var/throw_dir = get_dir(src, L)
				var/turf/throw_target = get_step(L, throw_dir)
				if(throw_target)
					L.throw_at(throw_target, 2, 1)
			
			playsound(src, 'sound/weapons/punch1.ogg', 50, TRUE)
			
			to_chat(user, span_warning("You need to build more loyalty before [src] will accept a brand! (Current loyalty: [total_loyalty]/80 required)"))
			return
		
		brand = input("What would you like to brand on your mount?","Brand", brand)
		
		if(!brand)
			return
		
		loyalty_from_brand = 15
		visible_message(span_notice("[user] successfully brands [src]!"))
		to_chat(user, span_notice("You brand [src]. They seem to accept you as their master!"))
		qdel(O)
		return
	
	// If nothing else matched, call parent
	return ..()

// CONSOLIDATED SADDLE INSTALLATION
/mob/living/simple_animal/cow/proc/install_saddle(obj/item/brahminsaddle/saddle_item, mob/user, list/custom_offsets)
	if(saddle)
		to_chat(user, span_warning("This mount already has a saddle!"))
		return FALSE
	
	saddle = TRUE
	can_buckle = TRUE
	buckle_lying = FALSE
	
	var/datum/component/riding/D = LoadComponent(/datum/component/riding)
	
	// Use custom offsets if provided, otherwise use default ride_offsets
	var/list/mount_offsets = custom_offsets || ride_offsets
	
	D.set_riding_offsets(RIDING_OFFSET_ALL, mount_offsets)
	D.set_vehicle_dir_layer(SOUTH, FLOAT_LAYER)
	D.set_vehicle_dir_layer(NORTH, FLOAT_LAYER)
	D.set_vehicle_dir_layer(EAST, ABOVE_MOB_LAYER)
	D.set_vehicle_dir_layer(WEST, ABOVE_MOB_LAYER)
	D.vehicle_move_delay = ride_move_delay
	D.drive_verb = "ride"
	
	to_chat(user, span_notice("You add [saddle_item] to [src]."))
	qdel(saddle_item)
	return TRUE

/mob/living/simple_animal/cow/heal_bodypart_damage(brute, burn, updating_health)
	var/healed_amount = ..()
	if(healed_amount > 0 && isliving(usr))
		grant_healing_loyalty(healed_amount, usr)
	return healed_amount

/mob/living/simple_animal/cow/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	if(stat == CONSCIOUS)
		handle_following()
		
		// FIXED: Check if rider equipped PA/Salvage while mounted
		if(current_rider && has_buckled_mobs())
			check_rider_equipment()
		
		// Decay temporary loyalty over time (feeding and petting decay)
		if(COOLDOWN_FINISHED(src, loyalty_decay_cooldown))
			// Decay feeding loyalty first
			if(loyalty_from_feeding > 0)
				loyalty_from_feeding = max(loyalty_from_feeding - loyalty_decay_rate, 0)
			// Then petting loyalty
			else if(loyalty_from_petting > 0)
				loyalty_from_petting = max(loyalty_from_petting - loyalty_decay_rate, 0)
			// Finally healing loyalty
			else if(loyalty > 0)
				loyalty = max(loyalty - loyalty_decay_rate, 0)
			
			COOLDOWN_START(src, loyalty_decay_cooldown, 30 SECONDS) // Decay every 30 seconds
		
		// Check sprint key state for mounted riders - NO AUTOMATIC REGEN
		if(current_rider && saddle)
			check_rider_sprint_input()
		
		if((prob(3) && has_calf))
			has_calf++
		if(has_calf > 10)
			has_calf = 0
			visible_message(span_alertalien("[src] gives birth to a calf."))
			new young_type(get_turf(src))

		if(is_calf)
			if((prob(3)))
				is_calf = 0
				udder = new()
				if (name == "brahmin calf")
					name = "brahmin"
				else
					name = "cow"
				visible_message(span_alertalien("[src] has fully grown."))
		else
			udder.generateMilk(milk_reagent)
			// ONLY let hunger naturally increase if mount does NOT have saddle/bridle
			if(!(saddle || bridle))
				if(COOLDOWN_FINISHED(src, hunger_cooldown))
					if(prob(5))
						become_hungry()
					COOLDOWN_START(src, hunger_cooldown, 5 MINUTES)

// FIXED: New proc to check if rider is wearing forbidden armor
/mob/living/simple_animal/cow/proc/check_rider_equipment()
	if(!current_rider || !ishuman(current_rider))
		return
	
	var/mob/living/carbon/human/H = current_rider
	
	// Check if they're wearing PA or Salvage armor
	if(istype(H.wear_suit))
		var/obj/item/clothing/suit/armor = H.wear_suit
		if(armor.slowdown == ARMOR_SLOWDOWN_PA || armor.slowdown == ARMOR_SLOWDOWN_SALVAGE)
			// They equipped forbidden armor while mounted!
			// FEAR EMOTES - mount realizes it's about to die
			var/list/fear_emotes = list(
				"[src] suddenly buckles under the weight!",
				"[src] lets out a terrified cry as its legs begin to give out!",
				"[src] trembles violently, struggling to stay upright!",
				"[src] whinnies in panic as the crushing weight settles in!",
				"[src]'s legs shake uncontrollably under the massive load!"
			)
			visible_message(span_danger(pick(fear_emotes)))
			
			// Screen shake for the rider
			if(H.client)
				shake_camera(H, 5, 5)
			
			// Brief delay as mount struggles
			sleep(1 SECONDS)
			
			// DEATH EMOTES
			var/list/death_emotes = list(
				"[src]'s legs finally give out with a sickening crack!",
				"[src] collapses with a final anguished cry!",
				"[src]'s body crumples under the unbearable weight!",
				"[src] falls to the ground, unable to bear the load any longer!"
			)
			visible_message(span_danger(pick(death_emotes)))
			H.visible_message(span_danger("[H]'s heavy [armor] crushes [src]!"),
				span_userdanger("Your [armor] is too heavy! You're crushing [src]!"))
			
			// Kill the mount
			src.death()
			
			// Throw and hurt the rider
			H.Paralyze(4 SECONDS)
			H.Knockdown(6 SECONDS)
			H.apply_damage(20, BRUTE, BODY_ZONE_L_LEG)
			H.apply_damage(20, BRUTE, BODY_ZONE_R_LEG)
			to_chat(H, span_userdanger("[src] collapses under the weight of your armor, throwing you to the ground!"))
			playsound(src, 'sound/effects/splat.ogg', 50, TRUE)
			
			return

/mob/living/simple_animal/cow/proc/add_hunger(amount)
	var/old_hunger = hunger
	
	hunger_float += amount
	hunger_float = clamp(hunger_float, 1.0, 4.0)
	
	hunger = round(hunger_float)
	
	if(hunger != old_hunger)
		if(!is_sprinting)
			update_speed()
		if(current_rider)
			update_rider_sprint_display(current_rider)
	
	hunger = round(hunger_float)
	
	if(hunger != old_hunger)
		// Only update speed if NOT currently sprinting
		if(!is_sprinting)
			update_speed()
		if(current_rider)
			update_rider_sprint_display(current_rider)

/mob/living/simple_animal/cow/proc/become_hungry()
	// Don't become hungry if we have saddle/bridle (mount mode)
	if(saddle || bridle)
		return
	
	hunger++
	hunger_float = hunger
	update_speed()
	// Update rider's display if mounted
	if(current_rider)
		update_rider_sprint_display(current_rider)

/mob/living/simple_animal/cow/proc/refuel_horse()
	hunger = 1
	hunger_float = 1.0
	update_speed()
	// Update rider's sprint display if mounted
	if(current_rider)
		update_rider_sprint_display(current_rider)

/mob/living/simple_animal/cow/proc/update_speed()
	// Only apply speed penalty when hunger is 3.5 or higher (almost out of stamina)
	if(hunger_float >= 3.5)
		// Apply penalty based on how close to 4.0 we are
		var/penalty_amount = (hunger_float - 3.5) / 0.5 // 0 to 1 scale
		ride_move_delay = initial(ride_move_delay) + (penalty_amount * 2) // Up to +2 delay at max
	else
		// No penalty, use base speed
		ride_move_delay = initial(ride_move_delay)
	
	if(saddle && !is_sprinting)
		var/datum/component/riding/D = LoadComponent(/datum/component/riding)
		if(D)
			D.vehicle_move_delay = ride_move_delay

/mob/living/simple_animal/cow/on_attack_hand(mob/living/carbon/M, act_intent = M.a_intent, unarmed_attack_flags)
	if(!stat && M.a_intent == INTENT_HELP)
		// Check if mount is tipped over - help them up
		if(icon_state == icon_dead)
			if(M.special_s < 8)
				to_chat(M, span_warning("You're not strong enough to help [src] up!"))
				return
			
			M.visible_message(span_notice("[M] starts helping [src] back up..."),
				span_notice("You start helping [src] back up..."))
			
			if(!do_after(M, 2 SECONDS, target = src))
				to_chat(M, span_warning("You stop helping [src]."))
				return
			
			M.visible_message(span_notice("[M] helps [src] back onto its feet!"),
				span_notice("You help [src] back up!"))
			to_chat(src, span_notice("[M] helps you back up!"))
			
			being_untipped = TRUE
			icon_state = icon_living
			return
		
		// Normal petting when not tipped
		M.visible_message(span_notice("[M] pets [src]."), span_notice("You pet [src]."))
		
		if(loyalty_from_petting < 10 && COOLDOWN_FINISHED(src, petting_cooldown))
			loyalty_from_petting += 2
			to_chat(M, span_notice("[src] seems to appreciate the attention! (Petting loyalty: [loyalty_from_petting]/10)"))
			COOLDOWN_START(src, petting_cooldown, 30 SECONDS)
		else if(loyalty_from_petting >= 10)
			to_chat(M, span_notice("[src] is already very affectionate with you."))
		
		return

	// HARM INTENT - Damage mount but DON'T unbuckle rider
	if(!stat && M.a_intent == INTENT_HARM)
		if(has_buckled_mobs())
			// Mount is being ridden - attack the mount, not the rider
			M.visible_message(span_warning("[M] strikes [src]!"),
				span_warning("You strike [src]!"))
			
			playsound(src, 'sound/weapons/punch1.ogg', 50, TRUE)
			apply_damage(rand(5, 10), BRUTE) // Apply some damage
			
			if(M.client)
				shake_camera(M, 1, 1)
			
			return // Don't call parent - prevents unbuckle
		else
			// Not being ridden - normal attack behavior
			return ..()

	// Tipping with SPECIAL strength check and channeling
	if(!stat && M.a_intent == INTENT_DISARM && icon_state != icon_dead)
		if(saddle || bridle)
			M.visible_message(span_warning("[M] tries to tip over [src], but it's too well-equipped!"),
				span_warning("You can't tip over [src] while it has a saddle or bridle!"))
			return
		
		if(M.special_s < 8)
			to_chat(M, span_warning("You're not strong enough to tip over [src]!"))
			return
		
		M.visible_message(span_warning("[M] starts trying to tip over [src]..."),
			span_notice("You start tipping over [src]..."))
		
		if(!do_after(M, 2 SECONDS, target = src))
			to_chat(M, span_warning("You stop trying to tip over [src]."))
			return
		
		M.visible_message(span_warning("[M] tips over [src]!"),
			span_notice("You tip over [src]!"))
		to_chat(src, span_userdanger("You are tipped over by [M]!"))
		icon_state = icon_dead
		being_untipped = FALSE
		auto_untip_attempted = FALSE
		spawn(rand(20,50))
			if(!stat && !being_untipped && !auto_untip_attempted)
				auto_untip_attempted = TRUE
		
				if(!prob(50))
					visible_message(span_notice("[src] struggles but can't get back up..."))
					return
		
				icon_state = icon_living
				visible_message(span_notice("[src] struggles and manages to get back on its feet!"))
		
				var/external
				var/internal
				switch(pick(1,2,3,4))
					if(1,2,3)
						var/text = pick("imploringly.", "pleadingly.", "with a resigned expression.")
						external = "[src] looks at [M] [text]"
						internal = "You look at [M] [text]"
					if(4)
						external = "[src] seems resigned to its fate."
						internal = "You resign yourself to your fate."
				visible_message(span_notice("[external]"), span_revennotice("[internal]"))
		return
	
	return ..()

/mob/living/simple_animal/cow/proc/feed_em(obj/item/I, mob/user)
	if(!I || !user)
		return
	var/obj/item/stack/stax
	if(istype(I, /obj/item/stack))
		stax = I
		if(!stax.tool_use_check(user, 2))
			return

	if(saddle || bridle)
		to_chat(user, span_notice("You begin feeding [I] to [src]..."))
		if(!do_after(user, 2 SECONDS, target = src))
			to_chat(user, span_warning("You stop feeding [src]."))
			return
		visible_message(span_alertalien("[src] consumes the [I]."))
		
		// Calculate stamina gain based on potency
		var/stamina_gain = 3.0 // Default full refuel
		
		// Check if it's hay (low-quality food)
		if(istype(I, /obj/item/stack/sheet/hay))
			stamina_gain = 3.0 / 8 // Same as low-potency crops (0.375 = 12.5% stamina)
			to_chat(user, span_notice("[src] munches on the hay. It's not very nutritious. (Stamina restored: [stamina_gain])"))
		// Check if it's a grown item with potency
		else if(istype(I, /obj/item/reagent_containers/food/snacks/grown))
			var/obj/item/reagent_containers/food/snacks/grown/G = I
			if(G.seed && G.seed.potency)
				var/potency = G.seed.potency
				if(potency < 50)
					stamina_gain = 3.0 / 8 // 1/8 of full refuel = 0.375
				else
					stamina_gain = 3.0 / 4 // 1/4 of full refuel = 0.75
				
				to_chat(user, span_notice("[src] consumed food with [potency] potency. (Stamina restored: [stamina_gain])"))
		
		// Apply stamina gain (reduce hunger)
		hunger_float = max(hunger_float - stamina_gain, 1.0)
		hunger = round(hunger_float)
		update_speed()
		
		// Update rider's sprint display immediately if mounted
		if(current_rider)
			update_rider_sprint_display(current_rider)
			to_chat(current_rider, span_notice("[src]'s stamina: [100 - ((hunger_float - 1.0) / 3.0 * 100)]%"))
		
		// Show stamina change to the feeder
		var/stamina_percent = 100 - ((hunger_float - 1.0) / 3.0 * 100)
		to_chat(user, span_notice("[src]'s stamina is now at [round(stamina_percent)]%."))
		
		// Grant loyalty if under cap
		if(loyalty_from_feeding < 20)
			loyalty_from_feeding += 5
			to_chat(user, span_notice("[src]'s loyalty increases from feeding! (Feeding loyalty: [loyalty_from_feeding]/20)"))
		else
			to_chat(user, span_notice("[src] enjoys the meal, but they already trust you greatly."))
			
	else if(is_calf)
		visible_message(span_alertalien("[src] adorably chews the [I]."))
	else if(!has_calf)
		has_calf = 1
		visible_message(span_alertalien("[src] fertilely consumes the [I]."))
	else
		visible_message(span_alertalien("[src] absently munches the [I]."))

	if(stax)
		stax.use(2)
	else
		qdel(I)

/mob/living/simple_animal/cow/proc/handle_following()
	// This proc now just maintains the follow state
	// The actual movement is handled by start_following_loop()
	if(stat == DEAD || health <= 0)
		follow = FALSE
		return

/mob/living/simple_animal/cow/CtrlShiftClick(mob/user)
	if(get_dist(user, src) > 1)
		return

	// Check if removing bridle (DISARM intent)
	if(bridle && user.a_intent == INTENT_DISARM)
		bridle = FALSE
		tame = FALSE
		owner = null
		follow = FALSE // Stop following when bridle removed
		to_chat(user, span_notice("You remove the bridle gear from [src], dropping it on the ground."))
		new /obj/item/brahminbridle(get_turf(user))
		return

	// Check if removing collar (GRAB intent)
	if(collar && user.a_intent == INTENT_GRAB)
		collar = FALSE
		name = initial(name)
		loyalty_from_name = 0
		to_chat(user, span_notice("You remove the collar from [src], dropping it on the ground."))
		new /obj/item/brahmincollar(get_turf(user))
		return

	// Owner commands with HELP intent
	if(user == owner && bridle && user.a_intent == INTENT_HELP)
		if(stat == DEAD || health <= 0)
			to_chat(user, span_alert("[src] can't obey your commands anymore. It is dead."))
			return
		if(follow)
			to_chat(user, span_notice("You tug on the reins of [src], telling it to stay."))
			follow = FALSE
			return
		else if(!follow)
			to_chat(user, span_notice("You tug on the reins of [src], telling it to follow."))
			follow = TRUE
			return

///////////////////////////
// MOUNT SPRINT SYSTEM  //
///////////////////////////

/mob/living/simple_animal/cow/proc/doMountSprintLoss(tiles, mob/living/carbon/rider)
	if(!rider || !rider.client)
		stop_mount_sprint(rider)
		return
	
	var/datum/keybinding/living/toggle_sprint/sprint_bind = GLOB.keybindings_by_name["toggle_sprint"]
	var/datum/keybinding/living/hold_sprint/sprint_hold_bind = GLOB.keybindings_by_name["hold_sprint"]
	var/trying_to_sprint = (rider.client in sprint_bind.is_down) || (rider.client in sprint_hold_bind.is_down)
	
	if(!trying_to_sprint)
		stop_mount_sprint(rider)
		return
	
	if(!COOLDOWN_FINISHED(src, sprint_cooldown))
		if(!is_sprinting)
			to_chat(rider, span_warning("[src] needs to catch their breath before sprinting again!"))
		return
	
	// Can't sprint if too exhausted
	if(hunger >= 4)
		stop_mount_sprint(rider)
		if(prob(10))
			to_chat(rider, span_warning("[src] is too exhausted to sprint!"))
		return
	
	if(!is_sprinting)
		start_mount_sprint(rider)
	
	// DRAIN STAMINA BASED ON TIME SPRINTING, NOT JUST TILES
	if(is_sprinting)
		// Drain stamina every tick while sprinting (not just when moving)
		add_hunger(sprint_hunger_cost * 0.5) // Drain over time regardless of movement
		
		// Additional drain for actual movement
		if(tiles > 0)
			add_hunger(tiles * sprint_hunger_cost * 0.5)
	
	update_rider_sprint_display(rider)

/mob/living/simple_animal/cow/proc/check_rider_sprint_input()
	if(!current_rider || !current_rider.client)
		stop_mount_sprint(current_rider)
		return
	
	var/datum/keybinding/living/toggle_sprint/sprint_bind = GLOB.keybindings_by_name["toggle_sprint"]
	var/datum/keybinding/living/hold_sprint/sprint_hold_bind = GLOB.keybindings_by_name["hold_sprint"]
	var/trying_to_sprint = (current_rider.client in sprint_bind.is_down) || (current_rider.client in sprint_hold_bind.is_down)
	
	// Always stop if not trying to sprint
	if(!trying_to_sprint && is_sprinting)
		stop_mount_sprint(current_rider)

/mob/living/simple_animal/cow/proc/start_mount_sprint(mob/living/carbon/rider)
	is_sprinting = TRUE
	
	// Make mount faster
	if(saddle)
		var/datum/component/riding/D = LoadComponent(/datum/component/riding)
		D.vehicle_move_delay = sprint_move_delay
	
	last_sprint_time = world.time

/mob/living/simple_animal/cow/proc/stop_mount_sprint(mob/living/carbon/rider)
	if(!is_sprinting)
		return
	
	is_sprinting = FALSE
	
	// Calculate cooldown based on how much stamina was used
	var/stamina_used = world.time - last_sprint_time // Time spent sprinting
	var/proportional_cooldown = stamina_used * 0.5 // 50% of sprint time as cooldown
	
	COOLDOWN_START(src, sprint_cooldown, proportional_cooldown)
	
	update_speed()

/mob/living/simple_animal/cow/proc/update_rider_sprint_display(mob/living/carbon/rider)
	if(!rider)
		return
	
	// Convert mount hunger to sprint bar percentage
	// hunger 1.0 = 100% sprint, hunger 4.0 = 0% sprint
	var/mount_sprint_percent = 1 - ((hunger_float - 1.0) / 3.0)
	mount_sprint_percent = clamp(mount_sprint_percent, 0, 1)
	rider.sprint_buffer = rider.sprint_buffer_max * mount_sprint_percent
	rider.update_hud_sprint_bar()

///////////////////////////
// CONSOLIDATED BUCKLE  //
///////////////////////////

// Base class handles power armor check + rider setup
/mob/living/simple_animal/cow/user_buckle_mob(mob/living/carbon/human/M, mob/user, check_loc = TRUE)
	// Power armor check - applies to ALL mounts
	if(ishuman(M) && istype(M.wear_suit))
		var/obj/item/clothing/suit/armor = M.wear_suit
		if(armor.slowdown == ARMOR_SLOWDOWN_PA || armor.slowdown == ARMOR_SLOWDOWN_SALVAGE)
			to_chat(M, span_warning("Your [armor] is too heavy! You're crushing [src]!"))
			M.visible_message(span_danger("[M] attempts to mount [src] but their heavy armor crushes the poor creature!"))
			
			if(!do_after(M, 3 SECONDS, target = src))
				return FALSE
			
			src.death()
			M.Paralyze(4 SECONDS)
			M.Knockdown(6 SECONDS)
			M.apply_damage(15, BRUTE, BODY_ZONE_L_LEG)
			M.apply_damage(15, BRUTE, BODY_ZONE_R_LEG)
			to_chat(M, span_userdanger("[src] collapses under the weight of your armor, throwing you to the ground!"))
			playsound(src, 'sound/effects/splat.ogg', 50, TRUE)
			return FALSE
	
	. = ..()
	
	// Handle rider sprint system
	if(. && M && ishuman(M))
		current_rider = M
		M.save_sprint_on_mount(src)
		update_rider_sprint_display(M)

// Base class handles unbuckle
/mob/living/simple_animal/cow/user_unbuckle_mob(mob/living/buckled_mob, mob/user, silent)
	if(buckled_mob)
		buckled_mob.pixel_x = 0
		buckled_mob.pixel_y = 0
		
		if(ishuman(buckled_mob))
			var/mob/living/carbon/human/rider = buckled_mob
			rider.restore_sprint_on_dismount()
			stop_mount_sprint(rider)
	
	current_rider = null
	return ..()

///////////////////////////
//End Dave's Brahmin Bags//
///////////////////////////

//a cow that produces a random reagent in its udder
/mob/living/simple_animal/cow/random
	name = "strange cow"
	desc = "Something seems off about the milk this cow is producing."

/mob/living/simple_animal/cow/random/Initialize()
	milk_reagent = get_random_reagent_id()
	..()

//Wisdom cow, speaks and bestows great wisdoms
/mob/living/simple_animal/cow/wisdom
	name = "wisdom cow"
	desc = "Known for its wisdom, shares it with all"
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/wisdomcow = 1)
	gold_core_spawnable = FALSE
	speak_chance = 10
	milk_reagent = /datum/reagent/medicine/liquid_wisdom

/mob/living/simple_animal/cow/wisdom/Initialize()
	. = ..()
	speak = GLOB.wisdoms


/////////////
// CHICKEN //
/////////////

/mob/living/simple_animal/chick
	name = "\improper chick"
	desc = "Adorable! They make such a racket though."
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "chick"
	icon_living = "chick"
	icon_dead = "chick_dead"
	icon_gib = "chick_gib"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("Cherp.","Cherp?","Chirrup.","Cheep!")
	speak_emote = list("cheeps")
	emote_hear = list("cheeps.")
	emote_see = list("pecks at the ground.","flaps its tiny wings.")
	density = FALSE
	speak_chance = 2
	turns_per_move = 2
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/chicken = 1)
	response_help_continuous  = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	attack_verb_continuous = "kicks"
	attack_verb_simple = "kick"
	health = 3
	maxHealth = 3
	ventcrawler = VENTCRAWLER_ALWAYS
	var/amount_grown = 0
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	gold_core_spawnable = FRIENDLY_SPAWN

	footstep_type = FOOTSTEP_MOB_CLAW

/mob/living/simple_animal/chick/Initialize()
	. = ..()
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)

/mob/living/simple_animal/chick/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	if(!stat && !ckey)
		amount_grown += rand(1,2)
		if(amount_grown >= 100)
			new /mob/living/simple_animal/chicken(src.loc)
			qdel(src)

/mob/living/simple_animal/chick/holo/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	amount_grown = 0

/mob/living/simple_animal/chicken
	name = "\improper chicken"
	desc = "Hopefully the eggs are good this season."
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "chicken_brown"
	icon_living = "chicken_brown"
	icon_dead = "chicken_brown_dead"
	speak = list("Cluck!","BWAAAAARK BWAK BWAK BWAK!","Bwaak bwak.")
	speak_emote = list("clucks","croons")
	emote_hear = list("clucks.")
	emote_see = list("pecks at the ground.","flaps its wings viciously.")
	density = FALSE
	speak_chance = 2
	turns_per_move = 3
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/chicken = 2)
	var/egg_type = /obj/item/reagent_containers/food/snacks/egg
	var/food_type = /obj/item/reagent_containers/food/snacks/grown/wheat
	response_help_continuous  = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	attack_verb_continuous = "kicks"
	attack_verb_simple = "kick"
	health = 15
	maxHealth = 15
	ventcrawler = VENTCRAWLER_ALWAYS
	var/eggsleft = 0
	var/eggsFertile = TRUE
	var/body_color
	var/icon_prefix = "chicken"
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	var/list/feedMessages = list("It clucks happily.","It clucks happily.")
	var/list/layMessage = EGG_LAYING_MESSAGES
	var/list/validColors = list("brown","black","white")
	gold_core_spawnable = FRIENDLY_SPAWN
	var/static/chicken_count = 0

	footstep_type = FOOTSTEP_MOB_CLAW

/mob/living/simple_animal/chicken/Initialize()
	. = ..()
	if(!body_color)
		body_color = pick(validColors)
	icon_state = "[icon_prefix]_[body_color]"
	icon_living = "[icon_prefix]_[body_color]"
	icon_dead = "[icon_prefix]_[body_color]_dead"
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)
	++chicken_count

/mob/living/simple_animal/chicken/Destroy()
	--chicken_count
	return ..()

/mob/living/simple_animal/chicken/attackby(obj/item/O, mob/user, params)
	if(istype(O, food_type))
		if(!stat && eggsleft < 8)
			var/feedmsg = "[user] feeds [O] to [name]! [pick(feedMessages)]"
			user.visible_message(feedmsg)
			qdel(O)
			eggsleft += rand(1, 4)
		else
			to_chat(user, span_warning("[name] doesn't seem hungry!"))
	else
		..()

/mob/living/simple_animal/chicken/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	if((!stat && prob(3) && eggsleft > 0) && egg_type)
		visible_message(span_alertalien("[src] [pick(layMessage)]"))
		eggsleft--
		var/obj/item/E = new egg_type(get_turf(src))
		E.pixel_x = rand(-6,6)
		E.pixel_y = rand(-6,6)
		if(eggsFertile)
			if(chicken_count < MAX_CHICKENS && prob(25))
				START_PROCESSING(SSobj, E)

/obj/item/reagent_containers/food/snacks/egg/var/amount_grown = 0
/obj/item/reagent_containers/food/snacks/egg/process()
	if(isturf(loc))
		amount_grown += rand(1,2)
		if(amount_grown >= 100)
			visible_message("[src] hatches with a quiet cracking sound.")
			new /mob/living/simple_animal/chick(get_turf(src))
			STOP_PROCESSING(SSobj, src)
			qdel(src)
	else
		STOP_PROCESSING(SSobj, src)

///////////
// UDDER //
///////////

/obj/item/udder
	name = "udder"

/obj/item/udder/Initialize(loc, milk_reagent)
	if(!milk_reagent)
		milk_reagent = /datum/reagent/consumable/milk
	create_reagents(50, NONE, NO_REAGENTS_VALUE)
	reagents.add_reagent(milk_reagent, 20)
	. = ..()

/obj/item/udder/proc/generateMilk(datum/reagent/milk_reagent)
	if(prob(5))
		reagents.add_reagent(milk_reagent, rand(5, 10))

/obj/item/udder/proc/milkAnimal(obj/O, mob/user)
	var/obj/item/reagent_containers/glass/G = O
	if(G.reagents.total_volume >= G.volume)
		to_chat(user, span_danger("[O] is full."))
		return
	var/transfered = reagents.trans_to(O, rand(5,10))
	if(transfered)
		user.visible_message("[user] milks [src] using \the [O].", span_notice("You milk [src] using \the [O]."))
	else
		to_chat(user, span_danger("The udder is dry. Wait a bit longer..."))



/////////////
// BRAHMIN //
/////////////

/mob/living/simple_animal/cow/brahmin
	name = "brahmin"
	desc = "Brahmin or brahma are mutated cattle with two heads and looking udderly ridiculous.<br>Known for their milk, just don't tip them over."
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "brahmin"
	icon_living = "brahmin"
	icon_dead = "brahmin_dead"
	icon_gib = "brahmin_gib"
	speak = list("moo?","moo","MOOOOOO")
	speak_emote = list("moos","moos hauntingly")
	waddle_amount = 3
	waddle_up_time = 1
	waddle_side_time = 2
	can_ghost_into = TRUE
	young_type = /mob/living/simple_animal/cow/brahmin/calf
	var/obj/item/inventory_back
	footstep_type = FOOTSTEP_MOB_HOOF
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab = 4,
		/obj/item/reagent_containers/food/snacks/rawbrahminliver = 1,
		/obj/item/reagent_containers/food/snacks/rawbrahmintongue = 2,
		/obj/item/stack/sheet/animalhide/brahmin = 3,
		/obj/item/stack/sheet/bone = 2
		)
	butcher_difficulty = 1

// Only override if you need custom pixel positioning
/mob/living/simple_animal/cow/brahmin/user_buckle_mob(mob/living/carbon/human/M, mob/user, check_loc = TRUE)
	. = ..()
	
	if(. && M)
		spawn(1)
			if(M && M.buckled == src)
				M.pixel_x = 0
				M.pixel_y = 6

/mob/living/simple_animal/cow/brahmin/molerat
	name = "tamed molerat"
	desc = "That's a big ol' molerat, seems to be able to take a saddle!"
	icon = 'fallout/icons/mob/mounts.dmi'
	icon_state = "molerat"
	icon_living = "molerat"
	icon_dead = "molerat_dead"
	icon_gib = "brahmin_gib"
	speak = list("*gnarl","*scrungy")
	speak_emote = list("grrrllgs","makes horrible molerat noises")
	emote_hear = list("chatters.")
	emote_see = list("shakes its head.")
	waddle_amount = 4
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab = 4,
		/obj/item/stack/sheet/bone = 2
		)

/mob/living/simple_animal/cow/brahmin/molerat/user_buckle_mob(mob/living/carbon/human/M, mob/user, check_loc = TRUE)
	. = ..()
	
	if(. && M)
		spawn(1)
			if(M && M.buckled == src)
				M.pixel_x = 0
				M.pixel_y = 8

/mob/living/simple_animal/cow/brahmin/molerat/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/brahminsaddle))
		var/list/molerat_offsets = list(
			"1" = list(0, 8),
			"2" = list(0, 8),
			"4" = list(0, 8),
			"8" = list(0, 8)
		)
		install_saddle(O, user, molerat_offsets)
		return
	return ..()

//Horse

/mob/living/simple_animal/cow/brahmin/horse
	name = "horse"
	desc = "Horses are commonly used for logistics and transportation over long distances. Surprisingly this horse isn't fully mutated like the rest of the animals."
	icon = 'fallout/icons/mob/horse.dmi'
	icon_state = "horse"
	icon_living = "horse"
	icon_dead = "horse_dead"
	pixel_x = 0
	pixel_y = -6
	speak = list("*shiver", "*alert")
	speak_emote = list("nays","nays hauntingly")
	health = 100
	maxHealth = 100
	ride_move_delay = 2.1
	young_type = /mob/living/simple_animal/cow/brahmin/horse
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab = 4,
		/obj/item/crafting/wonderglue = 1,
		/obj/item/stack/sheet/bone = 2
		)

/mob/living/simple_animal/cow/brahmin/horse/user_buckle_mob(mob/living/carbon/human/M, mob/user, check_loc = TRUE)
	. = ..()
	
	if(. && M)
		spawn(1)
			if(M && M.buckled == src)
				M.pixel_x = 16
				M.pixel_y = 18

/mob/living/simple_animal/cow/brahmin/horse/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/brahminsaddle))
		var/list/horse_offsets = list(
			"1" = list(16, 18),
			"2" = list(16, 18),
			"4" = list(16, 18),
			"8" = list(16, 18)
		)
		install_saddle(O, user, horse_offsets)
		return
	return ..()

//Ridable Nightstalker

/mob/living/simple_animal/cow/brahmin/nightstalker
	name = "tamed nightstalker"
	desc = "A crazed genetic hybrid of rattlesnake and coyote DNA. This one seems a bit less crazed, at least."
	icon = 'icons/fallout/mobs/animals/nightstalker.dmi'
	icon_state = "nightstalker-legion"
	icon_living = "nightstalker-legion"
	icon_dead = "nightstalker-legion-dead"
	speak = list("*shiss","*gnarl","*bark")
	speak_emote = list("barks","hisses")
	emote_hear = list("perks its head up.")
	emote_see = list("stares.")
	health = 150
	maxHealth = 150
	ride_move_delay = 2.5
	young_type = /mob/living/simple_animal/cow/brahmin/nightstalker
	food_types = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/gecko,
		/obj/item/reagent_containers/food/snacks/f13/canned/dog
		)
	milk_reagent = /datum/reagent/toxin
	guaranteed_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/slab/nightstalker_meat = 2,
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/stack/sheet/bone = 2
		)

/mob/living/simple_animal/cow/brahmin/nightstalker/user_buckle_mob(mob/living/carbon/human/M, mob/user, check_loc = TRUE)
	. = ..()
	
	if(. && M)
		spawn(1)
			if(M && M.buckled == src)
				M.pixel_x = 15
				M.pixel_y = 8

/mob/living/simple_animal/cow/brahmin/nightstalker/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/brahminsaddle))
		var/list/nightstalker_offsets = list(
			"1" = list(15, 10),
			"2" = list(15, 10),
			"4" = list(15, 10),
			"8" = list(15, 10)
		)
		install_saddle(O, user, nightstalker_offsets)
		return
	return ..()

/mob/living/simple_animal/cow/brahmin/nightstalker/hunterspider
	name = "tamed spider"
	desc = "SOMEONE TAMED A FUCKING GIANT SPIDER?"
	icon = 'fallout/icons/mob/mounts.dmi'
	icon_state = "hunter"
	icon_living = "hunter"
	icon_dead = "hunter_dead"
	speak = list("*chitter","*hiss")
	speak_emote = list("chitters","hisses")
	emote_hear = list("rubs it mandibles together.")
	emote_see = list("stares, with all 8 eyes.")

/mob/living/simple_animal/cow/brahmin/nightstalker/hunterspider/user_buckle_mob(mob/living/carbon/human/M, mob/user, check_loc = TRUE)
	. = ..()
	
	if(. && M)
		spawn(1)
			if(M && M.buckled == src)
				M.pixel_x = 0
				M.pixel_y = 9

/mob/living/simple_animal/cow/brahmin/nightstalker/hunterspider/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/brahminsaddle))
		var/list/spider_offsets = list(
			"1" = list(0, 14),
			"2" = list(0, 14),
			"4" = list(-2, 14),
			"8" = list(-2, 14)
		)
		install_saddle(O, user, spider_offsets)
		return
	return ..()

/obj/item/brahmincollar
	name = "mount collar"
	desc = "A collar with a piece of etched metal serving as a tag. Use this on a mount you own to rename them."
	icon = 'icons/mob/pets.dmi'
	icon_state = "petcollar"

/obj/item/brahminbridle
	name = "mount bridle gear"
	desc = "A set of headgear used to control and claim a mount. Consists of a bit, reins, and leather straps stored in a satchel."
	icon = 'icons/fallout/objects/tools.dmi'
	icon_state = "brahminbridle"

/obj/item/brahminsaddle
	name = "mount saddle"
	desc = "A saddle fit for a mutant beast of burden."
	icon = 'icons/fallout/objects/tools.dmi'
	icon_state = "brahminsaddle"

/obj/item/brahminbrand
	name = "mount branding tool"
	desc = "Use this on a mount to claim it as yours!"
	icon = 'icons/fallout/objects/tools.dmi'
	icon_state = "brahminbrand"

/obj/item/storage/backpack/duffelbag/debug_brahmin_kit
	name = "Lets test brahmin!"

/obj/item/storage/backpack/duffelbag/debug_brahmin_kit/PopulateContents()
	. = ..()
	new /obj/item/brahmincollar(src)
	new /obj/item/brahminbridle(src)
	new /obj/item/brahminsaddle(src)
	new /obj/item/brahminbrand(src)
	new /obj/item/choice_beacon/pet/mountable(src)
	new /obj/item/gun/ballistic/rifle/mag/antimateriel(src)

/datum/crafting_recipe/brahmincollar
	name = "Mount collar"
	result = /obj/item/brahmincollar
	time = 60
	reqs = list(/obj/item/stack/sheet/metal = 1,
				/obj/item/stack/sheet/cloth = 1)
	tools = list(TOOL_WORKBENCH)
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/brahminbridle
	name = "Mount bridle gear"
	result = /obj/item/brahminbridle
	time = 60
	reqs = list(/obj/item/stack/sheet/metal = 3,
				/obj/item/stack/sheet/leather = 2,
				/obj/item/stack/sheet/cloth = 1)
	tools = list(TOOL_WORKBENCH)
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/brahminsaddle
	name = "Mount saddle"
	result = /obj/item/brahminsaddle
	time = 60
	reqs = list(/obj/item/stack/sheet/metal = 1,
				/obj/item/stack/sheet/leather = 4,
				/obj/item/stack/sheet/cloth = 1)
	tools = list(TOOL_WORKBENCH)
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC

/datum/crafting_recipe/brahminbrand
	name = "Mount branding tool"
	result = /obj/item/brahminbrand
	time = 60
	reqs = list(/obj/item/stack/sheet/metal = 1,
				/obj/item/stack/rods = 1)
	tools = list(TOOL_WORKBENCH)
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC


/mob/living/simple_animal/cow/brahmin/calf
	name = "brahmin calf"
	is_calf = 1

/mob/living/simple_animal/cow/brahmin/calf/Initialize()
	. = ..()
	resize = 0.7
	update_transform()

/mob/living/simple_animal/cow/brahmin/sgtsillyhorn
	name = "Sergeant Sillyhorn"
	desc = "A distinguished war veteran alongside his junior enlisted sidekick, Corporal McCattle. The two of them wear a set of golden rings, smelted from captured Centurions."
	emote_see = list("shakes its head.","swishes its tail eagerly.")
	speak_chance = 2

/mob/living/simple_animal/cow/brahmin/proc/update_brahmin_fluff()
	name = real_name
	desc = initial(desc)
	speak = list("Moo?","Moo!","Mooo!","Moooo!","Moooo.")
	emote_hear = list("brays.")
	desc = initial(desc)


/////////////
// RADSTAG //
/////////////

/mob/living/simple_animal/radstag
	name = "radstag"
	desc = "a two headed deer that will run at the first sight of danger."
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "radstag"
	icon_living = "radstag"
	icon_dead = "radstag_dead"
	icon_gib = "radstag_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	turns_per_move = 5
	see_in_dark = 6
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4, /obj/item/stack/sheet/sinew = 2, /obj/item/stack/sheet/animalhide/radstag = 2, /obj/item/stack/sheet/bone = 2)
	butcher_difficulty = 1
	response_help_simple  = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple   = "kicks"
	attack_verb_simple = "kicks"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 50
	maxHealth = 50
	gold_core_spawnable = FRIENDLY_SPAWN
	blood_volume = BLOOD_VOLUME_NORMAL
	faction = list("neutral")

/mob/living/simple_animal/radstag/rudostag
	name = "Rudo the Rednosed Stag"
	desc = "An almost normal looking radstag. Apart from both of it's noses was a bright, glowing red."
	icon_state = "rudostag"
	icon_living = "rudostag"
	icon_dead = "rudostag_dead"

///////////////
// BIGHORNER //
///////////////

/mob/living/simple_animal/hostile/retaliate/goat/bighorn
	name = "bighorner"
	desc = "Mutated bighorn sheep that are often found in mountains, and are known for being foul-tempered even at the best of times."
	icon = 'icons/fallout/mobs/animals/farmanimals.dmi'
	icon_state = "bighorner"
	icon_living = "bighorner"
	icon_dead = "bighorner_dead"
	icon_gib = "bighorner_gib"
	speak = list("EHEHEHEHEH","eh?")
	speak_emote = list("brays")
	emote_hear = list("brays.")
	emote_see = list("shakes its head.", "stamps a foot.", "glares around.", "grunts.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	guaranteed_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4, /obj/item/stack/sheet/sinew = 2, /obj/item/stack/sheet/bone = 3)
	butcher_difficulty = 1
	response_help_simple  = "pets"
	response_disarm_simple = "gently pushes aside"
	response_harm_simple   = "kicks"
	faction = list("bighorner")
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	attack_verb_simple = "rams"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 120
	maxHealth = 120
	melee_damage_lower = 25
	melee_damage_upper = 20
	environment_smash = ENVIRONMENT_SMASH_NONE
	stop_automated_movement_when_pulled = 1
	var/is_calf = 0
	var/food_type = /obj/item/reagent_containers/food/snacks/grown/wheat
	var/has_calf = 0
	var/young_type = /mob/living/simple_animal/hostile/retaliate/goat/bighorn/calf

/mob/living/simple_animal/hostile/retaliate/goat/bighorn/attackby(obj/item/O, mob/user, params)
	if(stat == CONSCIOUS && istype(O, /obj/item/reagent_containers/glass))
		udder.milkAnimal(O, user)
		return 1
	if(stat == CONSCIOUS && istype(O, food_type))
		if(is_calf)
			visible_message(span_alertalien("[src] adorably chews the [O]."))
			qdel(O)
		if(!has_calf && !is_calf)
			has_calf = 1
			visible_message(span_alertalien("[src] hungrily consumes the [O]."))
			qdel(O)
		else
			visible_message(span_alertalien("[src] absently munches the [O]."))
			qdel(O)
	else
		return ..()

/mob/living/simple_animal/hostile/retaliate/goat/bighorn/Life()
	. = ..()
	if(stat == CONSCIOUS)
		if((prob(3) && has_calf))
			has_calf++
		if(has_calf > 10)
			has_calf = 0
			visible_message(span_alertalien("[src] gives birth to a calf."))
			new young_type(get_turf(src))

		if(is_calf)
			if((prob(3)))
				is_calf = 0
				udder = new()
				if(name == "bighorn lamb")
					name = "bighorn"
				else
					name = "bighorn"
				visible_message(span_alertalien("[src] has fully grown."))
		else
			udder?.generateMilk(milk_reagent)

/mob/living/simple_animal/hostile/retaliate/goat/bighorn/calf
	name = "bighoner calf"
	resize = 0.7

/mob/living/simple_animal/hostile/retaliate/goat/bighorn/calf/Initialize()
	. = ..()
	resize = 0.7
	update_transform()

/* Seems obsolete with Daves Brahmin packs, marked for death?
	if(inventory_back && inventory_back.brahmin_fashion)
		var/datum/brahmin_fashion/BF = new inventory_back.brahmin_fashion(src)
		BF.apply(src)
/mob/living/simple_animal/cow/brahmin/regenerate_icons()
	..()
	if(inventory_back)
		var/image/back_icon
		var/datum/brahmin_fashion/BF = new inventory_back.brahmin_fashion(src)
		if(!BF.obj_icon_state)
			BF.obj_icon_state = inventory_back.icon_state
		if(!BF.obj_alpha)
			BF.obj_alpha = inventory_back.alpha
		if(!BF.obj_color)
			BF.obj_color = inventory_back.color
		if(health <= 0)
			back_icon = BF.get_overlay(dir = EAST)
			back_icon.pixel_y = -11
			back_icon.transform = turn(back_icon.transform, 180)
		else
			back_icon = BF.get_overlay()
		add_overlay(back_icon)
	return
/mob/living/simple_animal/cow/brahmin/show_inv(mob/user)
	user.set_machine(src)
	if(user.stat)
		return
	var/dat = 	"<div align='center'><b>Inventory of [name]</b></div><p>"
	if(inventory_back)
		dat +=	"<br><b>Back:</b> [inventory_back] (<a href='?src=[REF(src)];remove_inv=back'>Remove</a>)"
	else
		dat +=	"<br><b>Back:</b> <a href='?src=[REF(src)];add_inv=back'>Nothing</a>"
	user << browse(dat, text("window=mob[];size=325x500", real_name))
	onclose(user, "mob[real_name]")
	return
mob/living/simple_animal/cow/brahmin/Topic(href, href_list)
	if(usr.stat)
		return
	//Removing from inventory
	if(href_list["remove_inv"])
		if(!Adjacent(usr) || !(ishuman(usr) || ismonkey(usr) || iscyborg(usr) ||  isalienadult(usr)))
			return
		var/remove_from = href_list["remove_inv"]
		switch(remove_from)
			if("back")
				if(inventory_back)
					inventory_back.forceMove(drop_location())
					inventory_back = null
					update_brahmin_fluff()
					regenerate_icons()
				else
					to_chat(usr, span_danger("There is nothing to remove from its [remove_from]."))
					return
		show_inv(usr)
	//Adding things to inventory
	else if(href_list["add_inv"])
		if(!Adjacent(usr) || !(ishuman(usr) || ismonkey(usr) || iscyborg(usr) ||  isalienadult(usr)))
			return
		var/add_to = href_list["add_inv"]
		switch(add_to)
			if("back")
				if(inventory_back)
					to_chat(usr, span_warning("It's already wearing something!"))
					return
				else
					var/obj/item/item_to_add = usr.get_active_held_item()
					if(!item_to_add)
						usr.visible_message("[usr] pets [src].",span_notice("You rest your hand on [src]'s back for a moment."))
						return
					if(!usr.temporarilyRemoveItemFromInventory(item_to_add))
						to_chat(usr, span_warning("\The [item_to_add] is stuck to your hand, you cannot put it on [src]'s back!"))
						return
					//The objects that brahmin can wear on their backs.
					var/allowed = FALSE
					if(ispath(item_to_add.brahmin_fashion, /datum/brahmin_fashion/back))
						allowed = TRUE
					if(!allowed)
						to_chat(usr, span_warning("You set [item_to_add] on [src]'s back, but it falls off!"))
						item_to_add.forceMove(drop_location())
						if(prob(25))
							step_rand(item_to_add)
						for(var/i in list(1,2,4,8,4,8,4,dir))
							setDir(i)
							sleep(1)
						return
					item_to_add.forceMove(src)
					src.inventory_back = item_to_add
					update_brahmin_fluff()
					regenerate_icons()
		show_inv(usr)
	else
		..()
*/

#define WORKPIECE_PRESENT 1
#define WORKPIECE_INPROGRESS 2
#define WORKPIECE_FINISHED 3
#define WORKPIECE_SLAG 5

#define SMITH_STRESS_WARNING 60
#define SMITH_STRESS_CRITICAL 80
#define SMITH_STRESS_CRACK 100
#define SMITH_STRESS_SLAG 130

#define RECIPE_HAMMER "bpp" //bend punch punch
#define RECIPE_SHOVEL "buu" //bend upset upset
#define RECIPE_PICKAXE "bff" //bend fold fold
#define RECIPE_PROSPECTPICK "bfs" //bend fold shrink
#define RECIPE_KITCHENKNIFE "bsd" //bend shrink draw
#define RECIPE_CROWBAR "bbb" //bend bend bend
#define RECIPE_UNITOOL "bbu"  //bend bend upset
#define RECIPE_SCRAPSAW "ffsu" //fold fold shrink upset

#define RECIPE_RING "sss" //shrink shrink shrink
#define RECIPE_BALLANDCHAIN "pbu" //punch bend upset
#define RECIPE_ARMOR_PIECE "pup" //punch upset punch

#define RECIPE_BOWIE "dfs" //draw fold shrink
#define RECIPE_DAGGER "dds" //draw draw shrink

#define RECIPE_MACHETE "fdf" //fold draw fold
#define RECIPE_MACHREFORG "fuf" //fold upset fold lawnmower classic

#define RECIPE_SWORD "ffdf" // fold fold draw fold
#define RECIPE_SABRE "ffdd" //fold fold draw draw

#define RECIPE_LONGSWORD "fffdd" //fold fold fold draw draw
#define RECIPE_KATANA "fffff" //fold fold fold fold fold
#define RECIPE_WAKI "fffs" //fold fold fold shrink

#define RECIPE_ZWEIHANDER "fffdu" //fold fold fold draw upset

#define RECIPE_MACE "upu"  //upset punch upset
#define RECIPE_SCRAP "udpp" //upset draw shrink punch
#define RECIPE_AXE "udsp" //upset draw shrink punch
#define RECIPE_CRUSHER "uupp" //upset upset punch punch

#define RECIPE_SPEAR "dddf" //draw draw draw fold
#define RECIPE_TRIDENT "ddbf" //draw draw bend fold
#define RECIPE_PIKE "dduf" //draw draw upset fold

#define RECIPE_JAVELIN "sdu" //shrink draw upset
#define RECIPE_THROWING "sdd" //shrink draw draw
#define RECIPE_BOLA "suu" //shrink upset upset

// LEGION SPECIFIC
#define RECIPE_GLADIUS "fbf" //fold bend fold
#define RECIPE_LANCE "dbdf" //draw bend draw fold LEGION
#define RECIPE_SPATHA "ffbf" // fold fold bend fold LEGION
#define RECIPE_WARAXE "udup" //upset draw upset punch LEGION

GLOBAL_LIST_INIT(anvil_recipes, list(
	RECIPE_HAMMER = /obj/item/smithing/hammerhead,
	RECIPE_SHOVEL = /obj/item/smithing/shovelhead,
	RECIPE_PICKAXE = /obj/item/smithing/pickaxehead,
	RECIPE_PROSPECTPICK = /obj/item/smithing/prospectingpickhead,
	RECIPE_KITCHENKNIFE = /obj/item/smithing/weapon/knifeblade,
	RECIPE_CROWBAR = /obj/item/smithing/crowbar,
	RECIPE_UNITOOL = /obj/item/smithing/unitool,
	RECIPE_RING = /obj/item/smithing/special/jewelry/ring,
	RECIPE_BALLANDCHAIN = /obj/item/smithing/weapon/ballandchain,
	RECIPE_ARMOR_PIECE = /obj/item/smithing/armor_piece,
	RECIPE_DAGGER = /obj/item/smithing/weapon/daggerblade,
	RECIPE_BOWIE = /obj/item/smithing/weapon/daggerblade/bowieblade,
	RECIPE_MACHETE = /obj/item/smithing/weapon/macheteblade,
	RECIPE_MACHREFORG = /obj/item/smithing/weapon/macheteblade/macheterblade,
	RECIPE_SWORD = /obj/item/smithing/weapon/swordblade,
	RECIPE_SABRE = /obj/item/smithing/weapon/swordblade/sabreblade,
	RECIPE_LONGSWORD = /obj/item/smithing/longswordblade,
	RECIPE_KATANA = /obj/item/smithing/katanablade,
	RECIPE_WAKI = /obj/item/smithing/weapon/macheteblade/wakiblade,
	RECIPE_SCRAPSAW  = /obj/item/smithing/weapon/scrapsaw,
	RECIPE_MACE = /obj/item/smithing/weapon/macehead,
	RECIPE_SCRAP = /obj/item/smithing/scrapblade,
	RECIPE_ZWEIHANDER = /obj/item/smithing/zweiblade,
	RECIPE_AXE = /obj/item/smithing/axehead,
	RECIPE_CRUSHER = /obj/item/smithing/crusherhead,
	RECIPE_SPEAR = /obj/item/smithing/spearhead,
	RECIPE_TRIDENT = /obj/item/smithing/spearhead/tridenthead,
	RECIPE_PIKE = /obj/item/smithing/spearhead/pikehead,
	RECIPE_JAVELIN = /obj/item/smithing/javelinhead,
	RECIPE_THROWING = /obj/item/smithing/throwingknife,
	RECIPE_BOLA = /obj/item/smithing/bola,
	RECIPE_GLADIUS =  /obj/item/smithing/weapon/macheteblade/gladiusblade,
	RECIPE_SPATHA = /obj/item/smithing/weapon/swordblade/spathablade,
	RECIPE_WARAXE = /obj/item/smithing/waraxehead,
	RECIPE_LANCE = /obj/item/smithing/spearhead/lancehead,
	))


// Logic of smithing recipes: Tools start with bend and have 3 steps. 1h weapons have 3-4 steps. 2h weapons have 4-5 steps. Bigger bladed stuff start with a fold. Pointy stuff generally start with a draw. Unusual stuff migth start with upset.
// Point of having a structure is obviously to help remember, not just keeping every recipe as pure rote memory with no internal logic. If you add more stuff and fuck this up and don't read comments I hope you get a prolapse. - Pebbles

/obj/structure/blacksmith/anvil
	name = "anvil template"
	desc = "This should not be visible - please file a bug report."
	icon = 'icons/obj/blacksmith_bd2.dmi'
	density = TRUE
	anchored = TRUE
	max_integrity = 1000
	light_system = MOVABLE_LIGHT
	light_range = 2
	light_power = GLOW_MODERATE
	light_color = LIGHT_COLOR_FIRE
	light_on = FALSE
	var/busy = FALSE //If someone is already interacting with this anvil
	var/workpiece_state = FALSE
	var/list/workpiece_material
	var/workpiece_type = /obj/item/blacksmith/ingot/iron //Ingot type the workpiece came from, returned when lifted off
	var/anvilquality = 0
	var/work_score = 0 //Potential final quality of the workpiece
	var/stress = 0 //Risk of failure. Cracks the piece at SMITH_STRESS_CRACK, slags it at SMITH_STRESS_SLAG
	var/steps_taken = 0 //Total actions performed on this workpiece
	var/bright_hits = 0 //Actions completed at bright heat or above
	var/flux_used = FALSE //Whether flux benefited any shaping action
	var/heavy_blows = 0 //Heavy blows struck, used for slag feedback
	var/peak_stress = 0 //Highest stress reached, rewards recovering from near-failure
	var/cracked = FALSE //Recoverable damage state, caps quality
	var/stepsdone = "" //Recipe string of shaping steps
	var/heat_peak = SMITH_HEAT_COLD //Heat stage of the workpiece at heat_time, it cools from there
	var/heat_time = 0
	var/forge_cleanliness = 0 //Small quality modifier from the fuel used to heat the workpiece
	var/flux_hits = 0 //Remaining hits that benefit from flux
	var/pattern_welded = FALSE
	var/fallible = TRUE
	var/guaranteed_artifact = FALSE //vv this if you want an artifact
	var/itemqualitymax = 25

/obj/structure/blacksmith/anvil/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_CLICK_ALT, PROC_REF(ResetAnvil)) // emergency way to reset the anvil incase something goes wrong.

/obj/structure/blacksmith/anvil/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/blacksmith/ingot)) // That's it we're refactoring this code because I can't im literally crying rn ; _;
		return HandleIngot(I, user)

	if(istype(I, /obj/item/blacksmith/flux))
		return apply_flux(I, user)

	var/hammer_speed = 0
	var/hammer_work_bonus = 0
	var/hammer_stress_modifier = 1
	var/heavy_work_bonus = 0
	var/heavy_stress_modifier = 1
	if(!istype(I, /obj/item/twohanded/sledgehammer/simple)) // Hammer interactions:
		if(istype(I, /obj/item/melee/smith/hammer))
			var/obj/item/melee/smith/hammer/hammertime = I
			hammer_speed = hammertime.smithing_speed
			hammer_work_bonus = hammertime.smithing_quality_bonus
			hammer_stress_modifier = hammertime.smithing_stress_modifier
		else
			return ..()
	else
		// The sledgehammer is slow and forceful: best for heavy blows, poor for careful work.
		hammer_speed = -1
		heavy_work_bonus = 2
		heavy_stress_modifier = 1.35
	// if there is nothing present or something in progress.
	if(!(workpiece_state == WORKPIECE_PRESENT || workpiece_state == WORKPIECE_INPROGRESS))
		to_chat(user, "You can't work an empty anvil!")
		return FALSE

		// Checks if F.busy or busy.
	if(CheckBusy(user))
		to_chat(user, "This anvil is already being worked or you're already working on another one!")
		return FALSE

	return do_shaping(user, hammer_speed, hammer_work_bonus, hammer_stress_modifier, heavy_work_bonus, heavy_stress_modifier) // The actual progression part.

/obj/structure/blacksmith/anvil/proc/CheckBusy(mob/user)
	var/mob/living/carbon/human/F = user

	return F.busy || busy

/obj/structure/blacksmith/anvil/proc/set_busy(value, mob/living/carbon/human/H)
	if(H)
		H.busy = value
	busy = value

/obj/structure/blacksmith/anvil/proc/ResetAnvil()
	set_light_on(FALSE)
	work_score = 0
	stress = 0
	steps_taken = 0
	bright_hits = 0
	flux_used = FALSE
	heavy_blows = 0
	peak_stress = 0
	cracked = FALSE
	stepsdone = ""
	heat_peak = SMITH_HEAT_COLD
	heat_time = 0
	forge_cleanliness = 0
	flux_hits = 0
	pattern_welded = FALSE
	workpiece_state = FALSE
	cut_overlay(image(icon= 'icons/obj/blacksmith_bd2.dmi',icon_state="workpiece"))
	set_busy(FALSE, null)

/obj/structure/blacksmith/anvil/proc/get_heat_stage()
	if(!workpiece_state)
		return SMITH_HEAT_COLD
	var/stage = calc_smith_heat(heat_peak, heat_time)
	if(stage < SMITH_HEAT_WORKING)
		flux_hits = 0 // flux burns off once the metal is too cool
	return stage

/obj/structure/blacksmith/anvil/proc/describe_heat(stage)
	switch(stage)
		if(SMITH_HEAT_COLD)
			return "cold and dark, it needs reheating"
		if(SMITH_HEAT_WARM)
			return "a dull red, barely workable"
		if(SMITH_HEAT_WORKING)
			return "a good working orange"
		if(SMITH_HEAT_BRIGHT)
			return "a bright yellow-orange"
	return "glaring white-hot and sparking"

/obj/structure/blacksmith/anvil/examine(mob/user)
	. = ..()
	if(workpiece_state)
		. += span_notice("The workpiece is [describe_heat(get_heat_stage())].")
		if(cracked)
			. += span_warning("It is visibly cracked.")
		if(flux_hits)
			. += span_notice("A layer of flux is melted over its surface.")

/obj/structure/blacksmith/anvil/proc/apply_flux(obj/item/blacksmith/flux/flux, mob/user)
	if(!workpiece_state)
		to_chat(user, "There is nothing on the anvil to flux.")
		return FALSE
	if(get_heat_stage() < SMITH_HEAT_WORKING)
		to_chat(user, "The metal is too cool for the flux to melt.")
		return FALSE
	flux_hits = 4
	to_chat(user, "You sprinkle flux over the hot metal. It melts into a glossy layer.")
	flux.uses--
	if(flux.uses <= 0)
		to_chat(user, "You use up the last of the [flux].")
		qdel(flux)
	return TRUE

/obj/structure/blacksmith/anvil/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!workpiece_state)
		return ..()
	if(CheckBusy(user))
		return
	var/obj/item/blacksmith/ingot/workpiece = new workpiece_type(get_turf(src))
	workpiece.set_custom_materials(workpiece_material)
	workpiece.progress = list(work_score, stress, steps_taken, heavy_blows, peak_stress, cracked, stepsdone, forge_cleanliness, bright_hits, flux_used, pattern_welded)
	workpiece.forge_cleanliness = forge_cleanliness
	if(get_heat_stage() > SMITH_HEAT_COLD)
		workpiece.workability = "shapeable"
		workpiece.heat_peak = heat_peak
		workpiece.heat_time = heat_time
		workpiece.icon_state = "hot_ingot"
		workpiece.set_light_on(TRUE)
	to_chat(user, "You lift the workpiece off the [src] with your tongs.")
	ResetAnvil()

/obj/structure/blacksmith/anvil/proc/HandleIngot(obj/item/blacksmith/ingot/workpiece, mob/user)
	if(workpiece_state)
		return forge_weld(workpiece, user)
	if(workpiece.get_heat_stage() > SMITH_HEAT_COLD)
		workpiece_state = WORKPIECE_PRESENT
		workpiece_material = workpiece.custom_materials
		workpiece_type = workpiece.type
		heat_peak = workpiece.heat_peak
		heat_time = workpiece.heat_time
		forge_cleanliness = workpiece.forge_cleanliness
		if(workpiece.progress)
			var/list/saved = workpiece.progress
			work_score = saved[1]
			stress = saved[2]
			steps_taken = saved[3]
			heavy_blows = saved[4]
			peak_stress = saved[5]
			cracked = saved[6]
			stepsdone = saved[7]
			if(length(saved) >= 8)
				forge_cleanliness = saved[8]
			if(length(saved) >= 9)
				bright_hits = saved[9]
			if(length(saved) >= 10)
				flux_used = saved[10]
			if(length(saved) >= 11)
				pattern_welded = saved[11]
		to_chat(user, "You place the [workpiece] on the [src].")

		add_overlay(image(icon= 'icons/obj/blacksmith_bd2.dmi',icon_state="workpiece"))
		set_light_on(TRUE)

		qdel(workpiece)
	else
		to_chat(user, "The ingot isn't workable yet!")
		return FALSE

/obj/structure/blacksmith/anvil/proc/forge_weld(obj/item/blacksmith/ingot/second_ingot, mob/user)
	if(!ishuman(user) || CheckBusy(user))
		to_chat(user, span_warning("You cannot forge-weld another ingot right now."))
		return FALSE
	if(pattern_welded || cracked)
		to_chat(user, span_warning("This workpiece cannot take another forge weld."))
		return FALSE
	if(get_heat_stage() < SMITH_HEAT_BRIGHT || second_ingot.get_heat_stage() < SMITH_HEAT_BRIGHT)
		to_chat(user, span_warning("Both pieces must be at bright heat to forge-weld them."))
		return FALSE
	if(!flux_hits)
		to_chat(user, span_warning("The joint needs a fresh layer of flux before it can be forge-welded."))
		return FALSE
	if(!islist(workpiece_material) || !islist(second_ingot.custom_materials))
		to_chat(user, span_warning("The materials cannot be joined safely."))
		return FALSE

	var/list/combined_materials = workpiece_material.Copy()
	var/has_dissimilar_material = FALSE
	for(var/material_path in second_ingot.custom_materials)
		var/material_amount = combined_materials[material_path]
		if(isnull(material_amount))
			has_dissimilar_material = TRUE
			material_amount = 0
		combined_materials[material_path] = material_amount + second_ingot.custom_materials[material_path]
	if(!has_dissimilar_material)
		to_chat(user, span_warning("Pattern welding needs two different metals."))
		return FALSE

	set_busy(TRUE, user)
	to_chat(user, "You bring the hot ingots together and begin forge-welding their layers.")
	if(!do_after(user, 50, target = src))
		return set_busy(FALSE, user)
	if(get_heat_stage() < SMITH_HEAT_BRIGHT || second_ingot.get_heat_stage() < SMITH_HEAT_BRIGHT || !flux_hits)
		to_chat(user, span_warning("The joint cools before the weld can take."))
		return set_busy(FALSE, user)

	workpiece_material = combined_materials
	pattern_welded = TRUE
	work_score += 3
	stress += 10
	peak_stress = max(peak_stress, stress)
	steps_taken++
	bright_hits++
	flux_hits--
	flux_used = TRUE
	qdel(second_ingot)
	to_chat(user, span_notice("The metals weld together in a layered pattern."))
	check_stress(user)
	set_busy(FALSE, user)
	return TRUE

/obj/structure/blacksmith/anvil/proc/do_shaping(mob/user, hammer_speed, hammer_work_bonus, hammer_stress_modifier, heavy_work_bonus, heavy_stress_modifier)
	if(!iscarbon(user))
		return

	set_busy(TRUE, user)
	workpiece_state = WORKPIECE_INPROGRESS // set it so we're working on it.

	if(get_heat_stage() == SMITH_HEAT_COLD)
		to_chat(user, span_warning("The metal has gone cold. Lift it off the anvil and reheat it in the furnace."))
		return set_busy(FALSE, user)

	// Present choice selection.
	var/list/working_steps = list("light tap", "medium strike", "heavy blow")
	var/shaping_steps = list("fold", "draw", "shrink", "bend", "punch", "upset") //hits affect work/stress. All the other steps shape.
	var/finishing_steps = list("finish (strong)", "finish (sharp)", "finish (jagged)")
	var/all_steps = working_steps + shaping_steps
	for(var/i in GLOB.anvil_recipes) // for each recipes.
		if(i == stepsdone)
			all_steps += finishing_steps
			break
	if(cracked)
		all_steps += "salvage"
	if(cracked || stress >= SMITH_STRESS_WARNING)
		all_steps += "anneal"
	var/stepdone = input(user, "How would you like to work the metal?") in all_steps

	// if user is not in range, remove business.
	if(!locate(src) in range(1, user))
		return set_busy(FALSE, user)

	if(stepdone == "salvage")
		set_busy(FALSE, user)
		return salvage(user)

	if(stepdone == "anneal")
		if(get_heat_stage() < SMITH_HEAT_WORKING)
			to_chat(user, span_warning("The metal must be at working heat or hotter before it can be annealed."))
			return set_busy(FALSE, user)
		to_chat(user, "You bank the hot metal and begin a slow anneal.")
		if(!do_after(user, 20 SECONDS, target = src))
			return set_busy(FALSE, user)
		stress = round(stress * 0.25)
		work_score = round(work_score * 0.8)
		cracked = FALSE
		heat_peak = SMITH_HEAT_WARM
		heat_time = world.time
		to_chat(user, span_notice("The metal cools slowly. It has lost some shape, but much of its strain is relieved."))
		return set_busy(FALSE, user)

	do_shaping_feedback(user, stepdone)

	// Time it takes for us to uh...forge..?
	var/steptime = 45 // sounds edited to fit 4.5 seconds
	if(user.mind.skill_holder) // Skill modifier to make it faster at blacksmithing. Limited to avoid going too far out of step with sounds.
		var/skillmod = user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)/15 + 1
		steptime /= skillmod
	var/hammer_speed_mod = (hammer_speed * 0.05) + 1
	steptime /= hammer_speed_mod

	if(!do_after(user, steptime, target = src))
		return set_busy(FALSE, user)

	if(stepdone in finishing_steps)
		try_finish(user, stepdone)
	else
		var/extra_work = hammer_work_bonus
		var/extra_stress_mult = hammer_stress_modifier
		if(stepdone == "heavy blow")
			extra_work += heavy_work_bonus
			extra_stress_mult *= heavy_stress_modifier
		apply_work(user, stepdone, extra_work, extra_stress_mult)
		do_smithing_sparks(1, TRUE, src) // sparkles~
		steps_taken++
		check_stress(user)
		if(workpiece_state && get_heat_stage() < SMITH_HEAT_WORKING)
			to_chat(user, span_notice("The metal is [describe_heat(get_heat_stage())]."))

	set_busy(FALSE, user) // Set it to false, cause we're done now.

/// Returns work score / stress for an action as list(work, stress)
/obj/structure/blacksmith/anvil/proc/get_action_values(stepdone)
	switch(stepdone)
		if("light tap")
			return list(1, 2)
		if("medium strike")
			return list(3, 6)
		if("heavy blow")
			return list(6, 14)
		if("fold")
			return list(3, 9)
		if("draw")
			return list(2, 7)
		if("shrink")
			return list(2, 5)
		if("bend")
			return list(2, 6)
		if("punch")
			return list(3, 10)
		if("upset")
			return list(3, 12)
	return list(0, 0)

/obj/structure/blacksmith/anvil/proc/get_skill(mob/user)
	if(user.mind?.skill_holder)
		return user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)
	return 0

/obj/structure/blacksmith/anvil/proc/apply_work(mob/user, stepdone, extra_work = 0, extra_stress_mult = 1)
	var/list/values = get_action_values(stepdone)
	var/skill = get_skill(user)
	// Skill and a good anvil make the metal more forgiving, a poor anvil less so.
	var/stress_mult = (0.92 ** skill) * 1.2 * clamp(1 - 0.04 * anvilquality, 0.6, 1.4) * extra_stress_mult
	var/work_mult = 1
	var/stage = get_heat_stage()
	switch(stage)
		if(SMITH_HEAT_WARM)
			work_mult = 0.75
			stress_mult *= 2
		if(SMITH_HEAT_BRIGHT)
			work_mult = 1.2
			stress_mult *= 1.2
		if(SMITH_HEAT_OVERHEATED)
			work_mult = 1.5
			stress_mult *= 1.8
	// Aggressive actions gain more from, and risk more at, high heat
	if(stage >= SMITH_HEAT_BRIGHT && (stepdone in list("heavy blow", "fold", "upset")))
		work_mult *= 1.15
		stress_mult *= 1.15
	if(stage >= SMITH_HEAT_BRIGHT)
		bright_hits++
	if(flux_hits > 0)
		flux_used = TRUE
		work_mult *= 1.1
		stress_mult *= 0.75
		flux_hits--
		if(!flux_hits)
			to_chat(user, span_notice("The last of the flux burns away."))
	if(!(stepdone in list("light tap", "medium strike", "heavy blow")))
		stepsdone += stepdone[1]
	if(stepdone == "heavy blow")
		heavy_blows++
	work_score += (values[1] + extra_work) * work_mult
	stress += values[2] * stress_mult
	peak_stress = max(peak_stress, stress)

/obj/structure/blacksmith/anvil/proc/check_stress(mob/user)
	if(!fallible)
		return
	if(stress >= SMITH_STRESS_SLAG || (cracked && stress >= SMITH_STRESS_CRACK))
		return slag_workpiece(user)
	if(stress >= SMITH_STRESS_CRACK)
		cracked = TRUE
		work_score = round(work_score * 0.6)
		stress = SMITH_STRESS_CRITICAL - 15
		to_chat(user, span_warning("The metal cracks! It can still be worked, but it will never be the same. You could also salvage it."))
		return
	if(stress >= SMITH_STRESS_CRITICAL)
		to_chat(user, span_warning("Fractures spread through the metal. One more careless blow and it will give way!"))
	else if(stress >= SMITH_STRESS_WARNING)
		to_chat(user, span_warning("The metal groans under the hammer. It is under a lot of strain."))

/obj/structure/blacksmith/anvil/proc/slag_workpiece(mob/user)
	to_chat(user, span_warning("You overwork the metal, causing it to turn into useless slag!"))
	if(heavy_blows >= 3)
		to_chat(user, span_notice("Lesson: too many heavy blows built up more strain than the metal could take."))
	else if(cracked)
		to_chat(user, span_notice("Lesson: you kept hammering after the metal had already cracked."))
	else
		to_chat(user, span_notice("Lesson: you pushed the metal too hard for too long without easing off."))
	new /obj/item/stack/ore/slag(get_turf(src)) // Spawn some slag
	give_failure_xp(user)
	ResetAnvil() // Resets it to be default.

/obj/structure/blacksmith/anvil/proc/give_failure_xp(mob/user)
	if(user.mind?.skill_holder) // learning XP scaled by how far the player got
		var/xp = clamp(25 + 12 * steps_taken, 30, 200)
		user.mind.auto_gain_experience(/datum/skill/level/dwarfy/blacksmithing, xp, 500000, silent = FALSE)

/obj/structure/blacksmith/anvil/proc/salvage(mob/user)
	to_chat(user, "You give up on the cracked piece and scrape what is left into slag.")
	new /obj/item/stack/ore/slag(get_turf(src))
	give_failure_xp(user)
	ResetAnvil()

/obj/structure/blacksmith/anvil/proc/get_final_quality(mob/user)
	var/skill_bonus = get_skill(user) / 2.5
	var/stress_penalty = max(0, stress - 30) / 3
	var/quality = work_score + skill_bonus + anvilquality + forge_cleanliness - stress_penalty
	if(cracked)
		quality = min(quality - 3, 9)
	return clamp(quality, -10, 25)

/obj/structure/blacksmith/anvil/proc/try_finish(mob/user, finishing_touch)
	var/final_quality = get_final_quality(user)
	var/artifactchance = 0
	if(final_quality >= 10)
		artifactchance = final_quality / 2000 //Artifacts are silly, fun on occasion but not meant be a balance crutch.
	var/artifact = (prob(artifactchance) || guaranteed_artifact)
	var/recipe_string = stepsdone

	var/obj/item/smithing/finisheditem = GLOB.anvil_recipes[recipe_string]
	finisheditem = new finisheditem(get_turf(src)) // Lets just spawn the item in immediately!

	to_chat(user, "You finish your [finisheditem]! Quench it while it's still hot.")

	finisheditem.quality = min(final_quality, itemqualitymax)
	if(artifact)
		to_chat(user, "It is an artifact, a creation whose legacy shall live on forevermore.") //todo: SSblackbox
		finisheditem.artifact = TRUE

	finisheditem.set_custom_materials(workpiece_material)
	finisheditem.finishing_touch = finishing_touch
	finisheditem.recipe_string = recipe_string
	finisheditem.forging_steps = steps_taken
	finisheditem.bright_forging_steps = bright_hits
	finisheditem.final_forging_stress = stress
	finisheditem.peak_forging_stress = peak_stress
	finisheditem.cracked_during_forging = cracked
	finisheditem.forging_used_flux = flux_used
	finisheditem.pattern_welded = pattern_welded

	ResetAnvil()

/obj/structure/blacksmith/anvil/proc/do_shaping_feedback(mob/user, stepdone)
	switch(stepdone)
		if("light tap")
			playsound(src, 'code/modules/smithing/sound/anvil_weak.ogg',100)
			user.visible_message("<span class='notice'>[user] carefully hammers out imperfections in the metal.</span>", \
						"<span class='notice'>You carefully hammer out imperfections in the metal.</span>")
		if("medium strike")
			playsound(src, 'code/modules/smithing/sound/anvil_strong.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] hammers out imperfections in the metal.</span>", \
						"<span class='notice'>You hammer out imperfections in the metal.</span>")
		if("heavy blow")
			playsound(src, 'code/modules/smithing/sound/anvil_heavy.ogg',100)
			do_smithing_sparks(2, TRUE, src)
			user.visible_message("<span class='notice'>[user] forcefully hammers out imperfections in the metal.</span>", \
						"<span class='notice'>You forcefuly hammer out imperfections in the metal.</span>")
		if("fold")
			playsound(src, 'code/modules/smithing/sound/anvil_double1.ogg',95)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] folds the metal.</span>", \
						"<span class='notice'>You fold the metal.</span>")
		if("draw")
			playsound(src, 'code/modules/smithing/sound/anvil_double2.ogg',80)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] hammers both sides of the metal, drawing it out.</span>", \
						"<span class='notice'>You hammer both sides of the metal, drawing it out.</span>")
		if("shrink")
			playsound(src, 'code/modules/smithing/sound/anvil_rapid.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] flattens the metal, shrinking it.</span>", \
						"<span class='notice'>You flatten the metal, shrinking it.</span>")
		if("bend")
			playsound(src, 'code/modules/smithing/sound/anvil_single1.ogg',75)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] bends the metal, using the rounded end of the anvil.</span>", \
						"<span class='notice'>You bend the metal, using the rounded end of the anvil.</span>")
		if("punch")
			playsound(src, 'code/modules/smithing/sound/anvil_single2.ogg',95)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] uses the puncher to make holes in the metal.</span>", \
						"<span class='notice'>You use the puncher to make holes in the metal.</span>")
		if("upset")
			playsound(src, 'code/modules/smithing/sound/anvil_double3.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] upsets the metal by hammering the thick end.</span>", \
						"<span class='notice'>You upset the metal by hammering the thick end.</span>")
		if("finish (strong)")
			playsound(src, 'code/modules/smithing/sound/anvil_double3.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] prepares to finish up their work.</span>", \
						"<span class='notice'>You prepare to finish up your work.</span>")
		if("finish (sharp)")
			playsound(src, 'code/modules/smithing/sound/anvil_double3.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] sharpens the edge of their piece.</span>", \
						"<span class='notice'>You prepare to finish up your work, sharpening the edge of your piece.</span>")
		if("finish (jagged)")
			playsound(src, 'code/modules/smithing/sound/anvil_double3.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] cuts serrated teeth into their piece.</span>", \
						"<span class='notice'>You prepare to finish up your work, cutting jagged edges into your piece.</span>")

//////////////////////
//					//
//		ANVILS		//
//					//
//////////////////////

// A proper steel anvil
/obj/structure/blacksmith/anvil/obtainable
	name = "anvil"
	desc = "Made from solid steel, you wont be moving this around any time soon."
	icon_state = "anvil"
	anvilquality = -1 //This was causing balance problems to where you could get high levels of blacksmithing in 1-2 items

// Best anvil
/obj/structure/blacksmith/anvil/obtainable/legion
	name = "anvil"
	desc = "A solid steel anvil with a stamped bull on it."
	icon_state = "legvil"
	anvilquality = 0 //DO NOT GIVE A +1 BONUS TO ANVILS WHEN THEY HAVE A MAXQAL OF 8, THIS ONLY ASKS FOR MAX TIER FORGED ITEMS

// Decent makeshift anvil, mobile.
/obj/structure/blacksmith/anvil/obtainable/table
	name = "table anvil"
	desc = "A reinforced table. Usable as an anvil, favored by mad wastelanders and the dregs of the wasteland. Can be loosened from its bolts and moved."
	icon_state = "tablevil"
	anvilquality = -2

/obj/structure/blacksmith/anvil/obtainable/table/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I, 5)
	return TRUE

// Sandstone anvil
/obj/structure/blacksmith/anvil/obtainable/sandstone
	name = "sandstone brick anvil"
	desc = "A big block of sandstone. Useable as an anvil."
	custom_materials = list(/datum/material/sandstone=8000)
	icon_state = "sandvil"
	anvilquality = -2

// Debug anvil for some reason
/obj/structure/blacksmith/anvil/debugsuper
	name = "super ultra epic anvil of debugging."
	desc = "WOW. A DEBUG <del>ITEM</DEL> STRUCTURE. EPIC."
	icon_state = "anvil"
	anvilquality = 10
	itemqualitymax = 9001
	fallible = FALSE

#undef WORKPIECE_PRESENT
#undef WORKPIECE_INPROGRESS
#undef WORKPIECE_FINISHED
#undef WORKPIECE_SLAG
#undef SMITH_STRESS_WARNING
#undef SMITH_STRESS_CRITICAL
#undef SMITH_STRESS_CRACK
#undef SMITH_STRESS_SLAG

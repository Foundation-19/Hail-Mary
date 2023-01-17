#define WORKPIECE_PRESENT 1
#define WORKPIECE_INPROGRESS 2
#define WORKPIECE_FINISHED 3
#define WORKPIECE_SLAG 5

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

#define RECIPE_MACE "upu"  //upset punch upset
#define RECIPE_SCRAP "udpp" //upset draw shrink punch
#define RECIPE_AXE "udsp" //upset draw shrink punch
#define RECIPE_CRUSHER "uupp" //upset upset punch punch

#define RECIPE_SPEAR "dddf" //draw draw draw fold
#define RECIPE_TRIDENT "ddbf" //draw draw bend fold

#define RECIPE_JAVELIN "sdu" //shrink draw upset
#define RECIPE_THROWING "sdd" //shrink draw draw
#define RECIPE_BOLA "suu" //shrink upset upset


// LEGION SPECIFIC
#define RECIPE_GLADIUS "fbf" //fold bend fold
#define RECIPE_LANCE "dbdf" //draw bend fold fold LEGION
#define RECIPE_SPATHA "ffbf" // fold fold bend fold LEGION
#define RECIPE_WARAXE "udup" //upset draw upset punch LEGION

GLOBAL_LIST_INIT(anvil_recipes, list(
	RECIPE_HAMMER = /obj/item/smithing/hammerhead,
	RECIPE_SHOVEL = /obj/item/smithing/shovelhead,
	RECIPE_PICKAXE = /obj/item/smithing/pickaxehead,
	RECIPE_PROSPECTPICK = /obj/item/smithing/prospectingpickhead,
	RECIPE_KITCHENKNIFE = /obj/item/smithing/knifeblade,
	RECIPE_CROWBAR = /obj/item/smithing/crowbar,
	RECIPE_UNITOOL = /obj/item/smithing/unitool,
	RECIPE_RING = /obj/item/smithing/special/jewelry/ring,
	RECIPE_BALLANDCHAIN = /obj/item/smithing/ballandchain,
	RECIPE_ARMOR_PIECE = /obj/item/smithing/armor_piece,
	RECIPE_DAGGER = /obj/item/smithing/daggerblade,
   	RECIPE_BOWIE = /obj/item/smithing/bowieblade,
	RECIPE_MACHETE = /obj/item/smithing/macheteblade,
	RECIPE_MACHREFORG = /obj/item/smithing/macheterblade,
	RECIPE_SWORD = /obj/item/smithing/swordblade,
	RECIPE_SABRE = /obj/item/smithing/sabreblade,
	RECIPE_LONGSWORD = /obj/item/smithing/longswordblade,
	RECIPE_KATANA = /obj/item/smithing/katanablade,
	RECIPE_WAKI = /obj/item/smithing/wakiblade,
	RECIPE_SCRAPSAW  = /obj/item/smithing/scrapsaw,
	RECIPE_MACE = /obj/item/smithing/macehead,
	RECIPE_SCRAP = /obj/item/smithing/scrapblade,
	RECIPE_AXE = /obj/item/smithing/axehead,
	RECIPE_CRUSHER = /obj/item/smithing/crusherhead,
	RECIPE_SPEAR = /obj/item/smithing/spearhead,
	RECIPE_TRIDENT = /obj/item/smithing/tridenthead,
	RECIPE_JAVELIN = /obj/item/smithing/javelinhead,
	RECIPE_THROWING = /obj/item/smithing/throwingknife,
	RECIPE_BOLA = /obj/item/smithing/bola,
	RECIPE_GLADIUS =  /obj/item/smithing/gladiusblade,
	RECIPE_SPATHA = /obj/item/smithing/spathablade,
	RECIPE_WARAXE = /obj/item/smithing/waraxehead,
	RECIPE_LANCE = /obj/item/smithing/lancehead,
    ))


// Logic of smithing recipes: Tools start with bend and have 3 steps. 1h weapons have 3-4 steps. 2h weapons have 4-5 steps. Bigger bladed stuff start with a fold. Pointy stuff generally start with a draw. Unusual stuff migth start with upset.
// Point of having a structure is obviously to help remember, not just keeping every recipe as pure rote memory with no internal logic. If you add more stuff and fuck this up and don't read comments I hope you get a prolapse. - Pebbles

/obj/structure/blacksmith/anvil
	name = "anvil template"
	desc = "This should not be visible - please file a bug report."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
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
	var/datum/material/workpiece_material
	var/anvilquality = 0
	var/currentquality = 0 //lolman? what the fuck do these vars do?
	var/currentsteps = 0 //even i don't know
	var/outrightfailchance = 5 //todo: document this shit
	var/stepsdone = ""
	var/rng = TRUE
	var/debug = FALSE //vv this if you want an artifact
	var/artifactrolled = FALSE
	var/itemqualitymax = 10

/obj/structure/blacksmith/anvil/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_CLICK_ALT, .proc/ResetAnvil) // emergency way to reset the anvil incase something goes wrong.
	currentquality = anvilquality

/obj/structure/blacksmith/anvil/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/blacksmith/ingot)) // That's it we're refactoring this code because I can't im literally crying rn ; _;
		return HandleIngot(I, user)

	if(istype(I, /obj/item/melee/smith/hammer) || istype(I, /obj/item/twohanded/sledgehammer/simple)) // Hammer interactions:
		var/obj/item/melee/smith/hammer/hammertime = I // Even though they are two seperate object paths, I believe because we're only accessing qualitymod, it casts accordingly.

		// if there is nothing present or something in progress.
		if(!(workpiece_state == WORKPIECE_PRESENT || workpiece_state == WORKPIECE_INPROGRESS))
			to_chat(user, "You can't work an empty anvil!")
			return FALSE

		// Checks if F.busy or busy.
		if(CheckBusy(user))
			to_chat(user, "This anvil is already being worked or you're already working on another one!")
			return FALSE

		return do_shaping(user, hammertime.qualitymod) // The actual progression part.

	return ..()

/obj/structure/blacksmith/anvil/proc/CheckBusy(mob/user)
	var/mob/living/carbon/human/F = user

	return F.busy || busy

/obj/structure/blacksmith/anvil/proc/SetBusy(value, mob/living/carbon/human/H)
	if(H)
		H.busy = value
	busy = value

/obj/structure/blacksmith/anvil/proc/ResetAnvil()
	set_light_on(FALSE)
	currentquality = initial(currentquality)
	stepsdone = ""
	currentsteps = 0
	outrightfailchance = initial(outrightfailchance)
	artifactrolled = FALSE
	workpiece_state = FALSE
	cut_overlay(image(icon= 'modular_BD2/blacksmith/icons/blacksmith.dmi',icon_state="workpiece"))
	SetBusy(FALSE, null)

/obj/structure/blacksmith/anvil/proc/HandleIngot(obj/item/blacksmith/ingot/workpiece, mob/user)
	if(workpiece_state)
		to_chat(user, "There's already a workpiece! Finish it or take it off.")
		return FALSE
	if(workpiece.workability == "shapeable")
		workpiece_state = WORKPIECE_PRESENT
		workpiece_material = workpiece.custom_materials
		to_chat(user, "You place the [workpiece] on the [src].")

		currentquality = initial(currentquality)

		if(workpiece_state == WORKPIECE_PRESENT)
			add_overlay(image(icon= 'modular_BD2/blacksmith/icons/blacksmith.dmi',icon_state="workpiece"))
			set_light_on(TRUE)

		var/skillmod = 0
		if(user.mind.skill_holder)
			skillmod = user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)/2
		currentquality += skillmod

		qdel(workpiece)
	else
		to_chat(user, "The ingot isn't workable yet!")
		return FALSE

/obj/structure/blacksmith/anvil/proc/do_shaping(mob/user, qualitychange)
	if(!iscarbon(user))
		return

	SetBusy(TRUE, user)

	currentquality += qualitychange
	workpiece_state = WORKPIECE_INPROGRESS // set it so we're working on it.

	// Present choice selection.
	var/list/shapingsteps = list("weak hit", "strong hit", "heavy hit", "fold", "draw", "shrink", "bend", "punch", "upset") //weak/strong/heavy hit affect strength. All the other steps shape.
	var/stepdone = input(user, "How would you like to work the metal?") in shapingsteps


	// if user is not in range, remove business.
	if(!locate(src) in range(1, user))
		return SetBusy(FALSE, user)


	// Time it takes for us to uh...forge..?
	var/steptime = 45 // sounds edited to fit 4.5 seconds
	switch(stepdone) // Have some more then
		if("weak hit")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_weak.ogg',100)
			user.visible_message("<span class='notice'>[user] carefully hammers out imperfections in the metal.</span>", \
						"<span class='notice'>You carefully hammer out imperfections in the metal.</span>")
		if("strong hit")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_strong.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] hammers out imperfections in the metal.</span>", \
						"<span class='notice'>You hammer out imperfections in the metal.</span>")
		if("heavy hit")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_heavy.ogg',100)
			do_smithing_sparks(2, TRUE, src)
			user.visible_message("<span class='notice'>[user] forcefully hammers out imperfections in the metal.</span>", \
						"<span class='notice'>You forcefuly hammer out imperfections in the metal.</span>")
		if("fold")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_double1.ogg',95)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] folds the metal.</span>", \
						"<span class='notice'>You fold the metal.</span>")
		if("draw")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_double2.ogg',80)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] hammers both sides of the metal, drawing it out.</span>", \
						"<span class='notice'>You hammer both sides of the metal, drawing it out.</span>")
		if("shrink")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_rapid.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] flattens the metal, shrinking it.</span>", \
						"<span class='notice'>You flatten the metal, shrinking it.</span>")
		if("bend")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_single1.ogg',75)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] bends the metal, using the rounded end of the anvil.</span>", \
						"<span class='notice'>You bend the metal, using the rounded end of the anvil.</span>")
		if("punch")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_single2.ogg',95)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] uses the puncher to make holes in the metal.</span>", \
						"<span class='notice'>You use the puncher to make holes in the metal.</span>")
		if("upset")
			playsound(src, 'modular_BD2/blacksmith/sound/anvil_double3.ogg',100)
			do_smithing_sparks(1, TRUE, src)
			user.visible_message("<span class='notice'>[user] upsets the metal by hammering the thick end.</span>", \
						"<span class='notice'>You upset the metal by hammering the thick end.</span>")

	if(user.mind.skill_holder) // Skill modifier to make it faster at blacksmithing. Limited to avoid going too far out of step with sounds.
		var/skillmod = user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)/15 + 1
		steptime = 50 / skillmod


	if(!do_after(user, steptime, target = src))
		return SetBusy(FALSE, user)

	// I hate this.
	// I'd rather die.
	switch(stepdone)
		if("weak hit")
			currentsteps += 1
			outrightfailchance += 4
			currentquality += 1
		if("strong hit")
			currentsteps += 2
			outrightfailchance += 8.5
			currentquality += 2
		if("heavy hit")
			currentsteps += 3
			outrightfailchance += 13
			currentquality += 3
		if("fold")
			stepsdone += "f"
			currentsteps += 1
			currentquality -= 1
		if("draw")
			stepsdone += "d"
			currentsteps += 1
			currentquality -= 1
		if("shrink")
			stepsdone += "s"
			currentsteps += 1
			currentquality -= 1
		if("bend")
			stepsdone += "b"
			currentsteps += 1
			currentquality -= 1
		if("punch")
			stepsdone += "p"
			currentsteps += 1
			currentquality -= 1
		if("upset")
			stepsdone += "u"
			currentsteps += 1
			currentquality -= 1

	// sparkles~
	do_smithing_sparks(1, TRUE, src)

	// the stepsdone is a string of characters which are actions made.
	// Once it is more or equal to 3, call try finish.
	if(length(stepsdone) >= 3)
		tryfinish(user)

	SetBusy(FALSE, user) // Set it to false, cause we're done now some how.

/obj/structure/blacksmith/anvil/proc/tryfinish(mob/user) // Oh god before I prettify this code I just feel like I'm having a stroke at all this word garble.

	var/artifactchance = 0
	var/combinedqualitymax = user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)/4 + itemqualitymax //This is no longer as good. /2 divisor to /4 to make the max ~12
	if(!artifactrolled) // if there has not been a roll chance, do it now..?
		artifactchance = (1+(user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)/4))/2000 //Reduced. Artifacts are silly, fun on occasion but not meant be a balance crutch. Adjust base values until sweet spot instead ffs.
		//artifactrolled = TRUE --Disabled because this is a shitty mechanic.

	var/artifact = max(prob(artifactchance), debug) // If there is an artifact..?

	var/finalfailchance = outrightfailchance // Compiled fail chance result

	if(user.mind.skill_holder) // Divide the failing chance based on the skillmodifier
		var/skillmod = user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing) / 10 + 1
		finalfailchance = max(0, finalfailchance / skillmod) //lv 2 gives 20% less to fail, 3 30%, etc


	///////
	// The two main conditionals
	///////

	// I hate this. If you hit more than 10 times, or the final piece failed and you have no artifact. Why it gotta look so awkward.
	if((currentsteps > 10 || (rng && prob(finalfailchance))) && !artifact)

		to_chat(user, span_warning("You overwork the metal, causing it to turn into useless slag!"))

		new /obj/item/stack/ore/slag(get_turf(src)) // Spawn some slag

		ResetAnvil() // Resets it to be default.

		if(user.mind.skill_holder) // give them some experience
			user.mind.auto_gain_experience(/datum/skill/level/dwarfy/blacksmithing, 50, 500000, silent = FALSE) //This shouldn't give you a full level until 3+

		return SetBusy(FALSE, user)

	// IF YOU DIDN'T FUCK UP THE RECIPE
	for(var/i in GLOB.anvil_recipes) // for each recipes.
		if(i == stepsdone)

			var/obj/item/smithing/finisheditem = GLOB.anvil_recipes[stepsdone]
			finisheditem = new finisheditem(get_turf(src)) // Lets just spawn the item in immediately!

			to_chat(user, "You finish your [finisheditem]!")

			// math to make quality better if its an artifact.
			if(artifact)
				to_chat(user, "It is an artifact, a creation whose legacy shall live on forevermore.") //todo: SSblackbox
				currentquality = max(currentquality, 2)
				finisheditem.artifact = TRUE
			else
				if(combinedqualitymax >= 0)
					finisheditem.quality = min(currentquality, combinedqualitymax) //Changed so better smiths can make better gear regardless of their anvil. WILL HAVE TO BE TWEAKED, POSSIBLY.
				else
					finisheditem.quality = min(currentquality, itemqualitymax)

			finisheditem.set_custom_materials(workpiece_material)
			var/stepexperience = currentsteps + finisheditem.quality
			var/finalexperience = (150 *(stepexperience + finisheditem.quality))/8 //Makes powerlevelling late-game harder as it gives more bonuses here
			if(user.mind.skill_holder) // give them some experience!
				if(currentquality <= 1)
					user.mind.auto_gain_experience(/datum/skill/level/dwarfy/blacksmithing, 400, 500000, silent = FALSE) //Incentivises not spamming Slag
				else
					user.mind.auto_gain_experience(/datum/skill/level/dwarfy/blacksmithing, finalexperience, 500000, silent = FALSE) //Made more forgiving for lower levels and terrible anvils.

			workpiece_state = FALSE
			finisheditem.set_custom_materials(workpiece_material)
			currentquality = anvilquality
			stepsdone = ""
			currentsteps = 0
			outrightfailchance = 1
			artifactrolled = FALSE
			ResetAnvil() // Worse Case something might break if we dont do this. soo.... yeah!
			break



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
	outrightfailchance = 0
	rng = FALSE

#undef WORKPIECE_PRESENT
#undef WORKPIECE_INPROGRESS
#undef WORKPIECE_FINISHED
#undef WORKPIECE_SLAG

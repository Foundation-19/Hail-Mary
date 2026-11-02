
#define GLOW_BRIGHT 2.5
#define GLOW_MODERATE 0.75
#define GLOW_WEAK 0.4

#define WOODEN_ROD /obj/item/blacksmith/woodenrod
#define SWORD_HANDLE /obj/item/blacksmith/swordhandle
#define LEATHER_STRIP /obj/item/stack/sheet/leatherstrips
#define CHAIN /obj/item/blacksmith/chain

#define QUALITY_MODIFIER quality

#define SMITH_HEAT_COLD 1
#define SMITH_HEAT_WARM 2
#define SMITH_HEAT_WORKING 3
#define SMITH_HEAT_BRIGHT 4
#define SMITH_HEAT_OVERHEATED 5

/// Time a workpiece spends at each heat stage (indexed by stage) before dropping to the next one down
GLOBAL_LIST_INIT(smith_heat_durations, list(0, 30 SECONDS, 90 SECONDS, 50 SECONDS, 25 SECONDS))

/// Stage of a piece that was at heat_peak at heat_time, cooling one stage each time its duration runs out
/proc/calc_smith_heat(heat_peak, heat_time)
	var/stage = heat_peak
	var/elapsed = world.time - heat_time
	while(stage > SMITH_HEAT_COLD)
		var/duration = GLOB.smith_heat_durations[stage]
		if(elapsed < duration)
			break
		elapsed -= duration
		stage--
	return stage

#define FORCE_SMITH_REACH 20
#define FORCE_SMITH_LOW 24
#define FORCE_SMITH_HIGH 29


//////////////////////////////////////
//									//
//		QUENCHING TROUGH			//
//									//
//////////////////////////////////////

/obj/structure/blacksmith/quenching
	name = "quenching trough"
	desc = "A water-filled trough for heat treating freshly forged metal."
	icon = 'icons/obj/blacksmith_bd2.dmi'
	icon_state = "quench"
	max_integrity = 500
	density = TRUE
	anchored = TRUE
	var/toohot
	var/quench_medium = "water"

/obj/structure/blacksmith/quenching/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/smithing))
		var/obj/item/smithing/untempered = I
		if(untempered.quality_locked)
			playsound(src, 'sound/effects/water_wade4.ogg',50, 1)
			to_chat(user, span_notice("The [untempered] has already been heat treated."))
			return
		if(world.time >= untempered.quench_started_at + 2 MINUTES)
			to_chat(user, span_warning("The [untempered] has cooled too far to quench. It can still cool in the air."))
			return
		to_chat(user, "You temper the [untempered] by quenching it in [quench_medium]. There is a loud hiss and a puff of steam.")
		playsound(src, 'code/modules/smithing/sound/steam_whoosh.ogg', 40, TRUE)
		flick("quench_boil",src)
		var/datum/effect_system/steam_spread/puff = new /datum/effect_system/steam_spread/()
		puff.effect_type = /obj/effect/particle_effect/steam
		puff.set_up(2, 0, src)
		puff.start()
		if(!do_after(user, 15, TRUE, src))
			return
		if(!untempered.apply_quench(quench_medium))
			return
		if(quench_medium == untempered.get_preferred_quench())
			to_chat(user, span_notice("The [untempered] takes the quench cleanly."))
		else
			to_chat(user, span_warning("The [untempered] shudders in the wrong quenching medium. Its quality suffers."))
		untempered.on_attack_hand(user)
	else if(istype(I, /obj/item/blacksmith/ingot))
		var/obj/item/blacksmith/ingot/workpiece = I
		if(workpiece.get_heat_stage() == SMITH_HEAT_COLD)
			playsound(src, 'code/modules/smithing/sound/water_splash2.ogg',50, 1)
			return
		to_chat(user, "You cool the [workpiece] in [quench_medium].")
		playsound(src, 'code/modules/smithing/sound/steam_short.ogg',70, 1)
		flick("quench_boil",src)
		var/datum/effect_system/steam_spread/puff = new /datum/effect_system/steam_spread/()
		puff.effect_type = /obj/effect/particle_effect/steam
		puff.set_up(1, 0, src)
		puff.start()
		workpiece.cool_down()
		I.on_attack_hand(user)
	else
		. = ..()

/obj/structure/blacksmith/quenching/oil
	name = "oil quenching trough"
	desc = "A trough filled with quenching oil for heat treating metal that needs a slower, gentler quench."
	icon_state = "quench"
	quench_medium = "oil"

/* THESE THINGS ALREADY COPIED TO BASE CODE
// Bronze less retarded
/datum/material/bronze
	strength_modifier = 1

/datum/material/adamantine
	strength_modifier = 1.2


// ------------ SLAG ------------------ Makes slag more suitable visually for the interactions with the anvil
/obj/item/stack/ore/slag
	icon = 'icons/obj/blacksmith_bd2.dmi'
*/

// ------------ BLACKSMITH MITTENS ------------------	Mittens, since finger gloves and heat insulation is a lame combo

/obj/item/clothing/gloves/blacksmith_mittens
	name = "forge mittens"
	desc = "A pair of heavy duty leather mittens designed to protect the wearer when metalforging. Unsuited for tasks requiring manual dexterity."
	icon = 'icons/obj/blacksmith_bd2.dmi'
	icon_state = "blacksmith_mittens"
	mob_overlay_icon = 'icons/onmob/slot.dmi'
	item_state = "blacksmith_mittens"
	transfer_prints = FALSE
	strip_delay = 10
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT

/obj/item/clothing/gloves/blacksmith_mittens/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user) && user.mind && slot == SLOT_HANDS)
		ADD_TRAIT(user, TRAIT_CLUMSY, CLOTHING_TRAIT)

/obj/item/clothing/gloves/blacksmith_mittens/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_CLUMSY, CLOTHING_TRAIT)

/* COPIED TO BASE CODE
// ------------ SLEDGEHAMMER (SIMPLE) ------------------ Just a art redirect, since the sledgehammer/simple is integral to blacksmithing I want the art to match

/obj/item/twohanded/sledgehammer/simple
	name = "sledgehammer"
	icon = 'icons/obj/blacksmith_bd2.dmi'
	mob_overlay_icon = 'icons/onmob/slot.dmi'
	lefthand_file = 'icons/onmob/lefthand.dmi'
	righthand_file = 'icons/onmob/righthand.dmi'
	icon_state = "sledgehammer"
	icon_prefix = "sledgehammer"
	wielded_icon = "sledgehammer2"
	qualitymod = 0
*/

///////////////////////////////////
// ADVICE FOR BLACKSMITH ROOKIES //
///////////////////////////////////

// Explains most things ingame so you dont have to code dive to learn.
/obj/item/book/manual/advice_blacksmith
	name = "The Forgemasters Primer"
	desc = "A thin book with some basic advice on how to use a hammer and anvil, copied by hand."
	icon = 'icons/obj/blacksmith_bd2.dmi'
	lefthand_file = 'icons/onmob/lefthand.dmi'
	righthand_file = 'icons/onmob/righthand.dmi'
	icon_state = "advice_smithing"
	author = "Forgemaster Gallius"
	title = "Advice on Blacksmithing - For hotheaded whelps"
	dat = {"<html>
				<head>
				<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>
				<style>
				h1 {font-size: 18px; margin: 15px 0px 5px;}
				h2 {font-size: 15px; margin: 15px 0px 5px;}
				li {margin: 2px 0px 2px 15px;}
				ul {list-style: none; margin: 5px; padding: 0px;}
				ol {margin: 5px; padding: 0px 15px;}
				</style>
				</head>
				<body>

				<h3>How to work a hammer and anvil and produce basic tools.</h3>

				The needed tools are: forging mittens, metal ingots, a furnace, wood planks, an anvil, quenching trough and a suitable hammer.
				<p>
				<ol>
				<li>Forging mittens: Only very thick mittens are really reliable enough for touching red-hot metal. Make some from leather if you need to.</li>
				<li>Metal ingots: Take the metal stack you want to work in your hand and fashion ingots from it. (inhand crafting) </li>
				<li>Furnace: Needs fuel. Wood burns quickly with a smoky working heat; coke lasts longer and gives clean, bright heat. Welding fuel also works as a general fuel.</li>
				<li>Wooden bits: Cut down planks to rods with something sharp. Then cut leather to strips and wrap it around the rod for making a sword handle, or directly on the workpiece for some tools. </li>
				<li>Metal bits: On occasion you might need some chain to complete your work, if so, take a metal sheet in your hand and make a length of chain from it. (inhand crafting) </li>
				<li>Anvil: A solid anvil makes things easier. (crafting menu forging & blacksmithing)</li>
				<li>Quenching trough: Use water for most metals, but pieces containing titanium or pre-war steel take oil better. The wrong medium harms the quality. You can also let a piece cool in air for two minutes, though that costs quality. </li>
				<li>Hammer: A sledgehammer gives heavy blows more force but adds risk. A well-made smithing hammer works faster and more carefully. Craft one to get going. (crafting menu forging & blacksmithing) </li>
				</ol>
				<p>

				<h3>The process</h3>

				<p>
				<ol>
				<li>Heat the ingot, move it to the anvil. Metal cools as you work: bright metal is quicker to shape but riskier, and cold metal can't be worked. Click the anvil with an empty hand to lift a piece off and reheat it, its progress is kept. Overheating (heating metal that is still bright) gives the biggest gains and the biggest risk. </li>
				<li>Forge flux (crafting menu), sprinkled on hot metal on the anvil, reduces strain for the next few hits. </li>
				<li>Prepare the metal with light taps, medium strikes and heavy blows. Every blow builds up strain in the metal: if it starts groaning, ease off. Push too far and it cracks (still workable, but worse, or you can salvage it) and then turns to slag. Slag still teaches you something. </li>
				<li>When strain is high or the piece has cracked, anneal it at working heat or hotter. The slow cooling eases most strain and can mend a crack, but costs some of the work already done. </li>
				<li>For pattern welding, flux a workpiece at bright heat or hotter, then use a different, equally hot ingot on the anvil. The weld improves the workpiece but adds strain, and can only be done once per piece. </li>
				<li>Follow the secret smithing recipe for the item you want to make, then choose a finishing step. The result depends on your experience and the quality of your tools and preparations. </li>
				<li>For differential hardening, use refractory clay coating on a suitable hot blade before quenching. The correct quench gives the edge a small improvement. </li>
				<li>Quench the hot piece before adding fittings such as a wooden rod, sword handle, chain or leather strips. This locks its quality; a wrong quench or air cooling lowers it. </li>
				<li>Excellent work can become Masterwork, High Masterwork, Peak Masterwork or, rarely, Legendary. Careful bright-heat work, flux, the correct quench and controlled strain build smithing mastery when the piece is finished. </li>
				<li>After finishing and cooling a piece, a skilled blacksmith can hold it and use it on a maker's branding iron to add a permanent mark. A mark can only be applied once. </li>
				<li>The first item you make should be a good hammer, you might need to repeat the process and replace the previous hammer with a new one in steps. Try to have at least a masterworked iron hammer before moving on to other items to save you headache. </li>
				</ol>
				<p>


				<h3>Some secret smithing recipes.</h3>

				These are some of the items that can be made with hot iron and a steady hand. Results are not always the same depending on the anvil used.
				<p>
				<ol>
				<li>Hammer: (BPP) Bend the metal, then punch it twice to form the hammerhead. Add a rod.</li>
				<li>Shovel: (BUU) Bend the metal, then upset it twice. Add a rod.</li>
				<li>Crowbar: (BBB) Bend the metal until you got the crowbar done, then wrap it in leather strips. Better than the usual crowbars folks use nowadays.</li>
				<li>Pickaxe: (BFF) Bend the metal, then fold it into shape twice, then add a wooden rod.</li>
				<li>Prospecting pick: (BFS) Bend the metal, then fold it into shape and shrink it, then add a wooden rod. Useful for finding mineral deposits.</li>
				<li>Kitchen knife: (BSD) Bend the metal, shrink and draw it, then add a knife handle. A perfect gift for women.</li>
				<li>Universal tool: (BBU) Want a crowbar with a blade forgewelded on? Bend it twice, upset, then wrap it in leather strips when tempered.</li>
				<li>Scrapsaw: (FFSU) Fold twice, shrink and upset, wrap it with a leather strip once tempered. If you want a ugly ass saw, here you go. You could probably try to catch a blade with it I guess. </li>

				<li>Rings: (SSS) Tiny things, my fingers hurt when I try to work it, but if you youngsters want to make one just shrink the metal to shape. Might cheer you up.</li>
				<li>Ball and chain: (PBU) Punch the metal, bend and upset it. Add a chain and then snap it on the slaves leg, and laugh while they hobble about. Silly slave.</li>
				<li>Armor piece: (PUP) Punch the metal, upset and punch some more holes. Use the metal together with leather to make armoured gauntlets and such.</li>

				<li>Bowie knife: (DFS) Draw fold and shrink it, add a sword handle and THIS is a knife. </li>
				<li>Dagger: (DDS) Draw draw and shrink it, add a sword handle and you got a tiny little weapon. </li>

				<li>Machete: (FDF) Fold the metal, draw it, fold it more. Add handle.</li>
				<li>Lawnmower machete: (FUF) Fold the metal, upset it and ugh..yeah, fold it more. Add handle.</li>

				<li>Sword: (FFDF) Fold the metal twice, draw it and fold it again. Add a handle and you got a fine blade! </li>
				<li>Sabre: (FFDD) Fold the metal twice, then draw it twice into a proper thin shape. Add a handle and you got a curved blade. </li>

				<li>Longsword: (FFFDD) Fold, fold, fold then draw twice.. Done right, you get a proper sharp sword, after adding a sword handle.</li>
				<li>Katana: (FFFFF) Fold, fold, then FOLD SOME MORE. These curved swords look weird but are reasonably sharp I guess.</li>
				<li>Wakizashi: (FFFS) Fold thrice and shrink it, add a handle and you got a small dinky blade. </li>

				<li>Mace: (UPU) Upset the metal, punch it and upset it again. Add a wooden rod. </li>
				<li>Scrap blade: (UDPP) Upset, draw and punch the metal twice. Wrap it in leather strips. </li>

				<li>Heavy axe: (UDSP) Upset the hot metal, draw it, shrink it, punch holes in it. Add a wooden rod, then go chop down some wood or enemies. Easy. </li>
				<li>Crusher: (UUPP) Upset the hot metal twice, then punch it twice for the fittings. Add a wooden rod and crush those disgusting ghouls like twigs. </li>

				<li>Spear: (DDDF) Draw the metal thrice then fold it. Add a rod, and enjoy a simple but effective weapon.</li>
				<li>Trident: (DDBF) Draw the metal twice, bend it and fold it. Add a rod, and enjoy a simple but effective weapon.</li>

				<li>Javelin: (SDU) Shrink, draw, upset, add a wooden rod and throw it in someones face.</li>
				<li>Throwing knife: (SDD) Shrink and draw the metal twice, then add leather strips and there you go.</li>
				<li>Bola: (SUU) Shrink then upset twice, add a chain and you got a nice slavecatcher.</li>

				<li>For forgemasters trained in the east, you of course also know the ways to make our own weapons, that outsiders are unfit to touch, unless its tasting its edge. </li>
				<li>Legion Spatha: (FFBF) Fold the metal twice, bend it and fold it again. Add a handle and marvel at the beauty of the Legions finest blade! </li>
				<li>Legion Lance: (DBDF) Draw the metal, bend it, draw it again and fold it. Add a rod, and enjoy a simple but effective weapon.</li>
				<li>Legion Waraxe: (UDUP) Upset the hot metal, draw, upset, and punch it. Add a wooden rod, and behold the perfection of a Legion war axe. </li>
				<li>Legion Gladius: (FBF) Fold the metal, bend it and ugh..yeah, fold it more. Add handle.</li>

				</ol>
				<p>
				If you need more metal for your work, stop being lazy and smelt the ores in a furnace then keep going!
				Now go and make things of metal!

				</body>
				</html>
				"}

/obj/item/book/manual/smithing_journal
	name = "Smithing Field Journal"
	desc = "A smith's notebook that records hard-won techniques and material guidance."
	icon = 'icons/obj/blacksmith_bd2.dmi'
	icon_state = "advice_smithing"
	author = "The Forgemasters"
	title = "Smithing Field Journal"

/obj/item/book/manual/smithing_journal/attack_self(mob/user)
	var/html = "<html><head><meta charset='UTF-8'><style>body{font-family:Verdana;} h2{margin-bottom:4px;} li{margin:4px 0;}</style></head><body><h1>Smithing Field Journal</h1>"
	if(!user.mind)
		html += "<p>The notes only make sense to a living smith.</p>"
	else
		var/skill = 0
		if(user.mind.skill_holder)
			skill = user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing)
		var/list/techniques = list(
			"Bright forging" = "bright forging",
			"Flux and correct quenching" = "flux and quench",
			"Masterwork control" = "masterwork control",
			"Differential hardening" = "differential hardening",
			"Pattern welding" = "pattern welding",
		)
		html += "<h2>Practice</h2><ul>"
		for(var/technique_name in techniques)
			var/mastery_count = user.mind.smithing_mastery[techniques[technique_name]]
			if(mastery_count)
				html += "<li>[technique_name]: [mastery_count] successful finishes recorded.</li>"
			else
				html += "<li>[technique_name]: not yet recorded.</li>"
		html += "</ul><p>Distinct designs completed: [length(user.mind.smithed_recipes)].</p><h2>Material notes</h2>"
		if(skill >= 3)
			html += "<p>Most common metals take water quenching. Air cooling preserves neither time nor quality as well as a proper quench.</p>"
		else
			html += "<p>Your notes on metal-specific heat treatment are still incomplete.</p>"
		if(skill >= 6)
			html += "<p>Titanium- and pre-war steel-bearing pieces respond better to oil. In a layered piece, use the medium preferred by any metal that requires oil.</p>"
	html += "</body></html>"
	user << browse(html, "window=smithing_journal;size=500x560")

/* COPIED TO BASE CODE
// ------------ METALWORKING BENCH ------------------ Part of the module, for metalworking that doesnt need a whole forge setup

/obj/machinery/workbench/forge // should be repathed to worbench/metal
	name = "metalworking bench"
	desc = "A workbench with a drill press, a makeshift blowtorch setup, and various tools for making crude weapons and tools."
	icon = 'icons/workbench64x32.dmi'
	icon_state = "bench_metal"
*/


/*
// Stacking craftin items visual updater
/obj/item/stack/crafting/update_icon_state()
	var/amount = get_amount()
	if(amount <= 5)
		icon_state = initial(icon_state)
	else if(amount <= 25)
		icon_state = "[initial(icon_state)]_2"
	else
		icon_state = "[initial(icon_state)]_3"

// Adapted for the specific bullet remnant stacking
/obj/item/stack/crafting/powder/update_icon_state()
	var/amount = get_amount()
	if(amount <= 80)
		icon_state = initial(icon_state)
	else if(amount <= 160)
		icon_state = "[initial(icon_state)]_2"
	else
		icon_state = "[initial(icon_state)]_3"
*/

// ------------ COAL & COKE ------------------ New base material and the sheet that can be used as fuel or ground for charcoal

/datum/material/coal
	name = "coal"
	desc = "coal"
	color = "#0a0a0a"
	alpha = 150
	categories = list(MAT_CATEGORY_RIGID = TRUE, MAT_CATEGORY_BASE_RECIPES = FALSE)
	sheet_type = /obj/item/stack/ore/coal
	value_per_unit = 0.0050

/obj/item/stack/ore/coal // turns to coke when heated in a Furnace or ORM
	name = "coal"
	desc = "Pure coal needs heat-processing to become good fuel."
	icon_state = "ore_coal"
	singular_name = "lump of coal"
	points = 2
	custom_materials = null
	refined_type = /obj/item/stack/sheet/coke
	merge_type = /obj/item/stack/ore/coal
	resistance_flags = FLAMMABLE

/obj/item/stack/sheet/coke // Can be used to fuel Furnaces, Campfires, Barrel Fires, Potbelly stoves, Fireplaces, or grind for charcoal
	name = "coke"
	desc = "Coke is what you get when you heat-treat coal. It's a good fuel for burning."
	singular_name = "bag of coke"
	icon_state = "sheet_coke"
	custom_materials = null
	throwforce = 2
	grind_results = list(/datum/reagent/medicine/charcoal = 5)
	material_type = /datum/material/coal
	merge_type = /obj/item/stack/sheet/coke
	resistance_flags = FLAMMABLE

/obj/item/stack/sheet/coke/twenty
	amount = 20

// ------------ FLUX ------------------ Sprinkled on hot metal on the anvil to reduce stress for a few hits

/obj/item/blacksmith/flux
	name = "pouch of forge flux"
	desc = "Sand and ash ground together. Sprinkled on hot metal, it keeps the surface clean and helps it take hammering without cracking."
	icon = 'icons/obj/mining.dmi'
	icon_state = "Glass ore"
	w_class = WEIGHT_CLASS_TINY
	max_integrity = 20
	var/uses = 5

/obj/item/blacksmith/flux/examine(mob/user)
	. = ..()
	. += span_notice("It looks like there is enough for about [uses] applications.")

/obj/item/blacksmith/clay_coating
	name = "refractory clay coating"
	desc = "A heat-resistant wash for coating the spine of a blade before a differential quench."
	icon = 'icons/obj/mining.dmi'
	icon_state = "Glass ore"
	w_class = WEIGHT_CLASS_TINY

/turf/closed/mineral/coal
	mineralType = /obj/item/stack/ore/coal
	spreadChance = 5
	spread = 1
	scan_state = "rock_Coal"

// woodenrod production made, in sheet_types.dm /obj/item/stack/sheet/mineral/wood/attackby(obj/item/W, mob/user, params)

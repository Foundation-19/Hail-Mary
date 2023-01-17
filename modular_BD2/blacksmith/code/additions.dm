
#define GLOW_BRIGHT 2.5
#define GLOW_MODERATE 0.75
#define GLOW_WEAK 0.4

#define WOODEN_ROD /obj/item/blacksmith/woodenrod
#define SWORD_HANDLE /obj/item/blacksmith/swordhandle
#define LEATHER_STRIP /obj/item/stack/sheet/leatherstrips
#define CHAIN /obj/item/blacksmith/chain

#define QUALITY_MODIFIER quality

#define FORCE_SMITH_REACH 14
#define FORCE_SMITH_LOW 18
#define FORCE_SMITH_HIGH 23


//////////////////////////////////////
//									//
//		QUENCHING TROUGH			//
//									//
//////////////////////////////////////

/obj/structure/blacksmith/quenching
	name = "quenching trough"
	desc = "Water in a open box, for tempering hot metal in."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "quench"
	max_integrity = 500
	density = TRUE
	anchored = TRUE
	var/toohot

/obj/structure/blacksmith/quenching/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/smithing))
		var/obj/item/smithing/untempered = I
		if(untempered.toohot == FALSE)
			playsound(src, 'sound/effects/water_wade4.ogg',50, 1)
			return
		to_chat(user, "You temper the [untempered] by quenching it in the water. There is a loud hiss and a puff of steam.")
		playsound(src, 'modular_BD2/blacksmith/sound/steam_whoosh.ogg', 40, TRUE)
		flick("quench_boil",src)
		var/datum/effect_system/steam_spread/puff = new /datum/effect_system/steam_spread/()
		puff.effect_type = /obj/effect/particle_effect/steam
		puff.set_up(2, 0, src)
		puff.start()
		if(!do_after(user, 15, TRUE, src))
			return
		untempered.toohot = FALSE
		untempered.istempered()
		I.on_attack_hand(user)
	else
		. = ..()

/obj/structure/blacksmith/quenching/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/blacksmith/ingot))
		var/obj/item/blacksmith/ingot/workpiece = I
		if(workpiece.workability == FALSE)
			playsound(src, 'modular_BD2/blacksmith/sound/water_splash2.ogg',50, 1)
			return
		to_chat(user, "You cool the [workpiece] in the water.")
		playsound(src, 'modular_BD2/blacksmith/sound/steam_short.ogg',70, 1)
		flick("quench_boil",src)
		var/datum/effect_system/steam_spread/puff = new /datum/effect_system/steam_spread/()
		puff.effect_type = /obj/effect/particle_effect/steam
		puff.set_up(1, 0, src)
		puff.start()
		workpiece.workability = FALSE
		workpiece.icon_state = "ingot"
		workpiece.set_light_on(FALSE)
		I.on_attack_hand(user)
	else
		. = ..()

/* THESE THINGS ALREADY COPIED TO BASE CODE
// Bronze less retarded
/datum/material/bronze
	strength_modifier = 1

/datum/material/adamantine
	strength_modifier = 1.2


// ------------ SLAG ------------------ Makes slag more suitable visually for the interactions with the anvil
/obj/item/stack/ore/slag
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
*/

// ------------ BLACKSMITH MITTENS ------------------	Mittens, since finger gloves and heat insulation is a lame combo

/obj/item/clothing/gloves/blacksmith_mittens
	name = "forge mittens"
	desc = "A pair of heavy duty leather mittens designed to protect the wearer when metalforging. Unsuited for tasks requiring manual dexterity."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "blacksmith_mittens"
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
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
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
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
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
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
				<li>Furnace: Needs fuel, welding fuel most commonly. Five measures of fuel burns fast but is enough to heat a couple ingots if you are fast.</li>
				<li>Wooden bits: Cut down planks to rods with something sharp. Then cut leather to strips and wrap it around the rod for making a sword handle, or directly on the workpiece for some tools. </li>
				<li>Metal bits: On occasion you might need some chain to complete your work, if so, take a metal sheet in your hand and make a length of chain from it. (inhand crafting) </li>
				<li>Anvil: A solid anvil makes things easier. (crafting menu forging & blacksmithing)</li>
				<li>Quenching trough: Basically a big tub of water, or oil. (crafting menu forging & blacksmithing) </li>
				<li>Hammer: Most commonly a sledgehammer is used for the first work, which is making a better hammer. Craft one to get going. (crafting menu forging & blacksmithing) </li>
				</ol>
				<p>

				<h3>The process</h3>

				<p>
				<ol>
				<li>Heat the ingot, move it to the anvil.</li>
				<li>Prepare the metal, weak, strong and heavy hits enhance the quality but overworking the metal will produce slag and you have to start over. Try a couple hits then move on to making the item if you have no other ideas. </li>
				<li>Follow the secret smithing recipe for the item you want to make, the end result will depend on how much experience you have smithing, and the quality of your tools and preparations. </li>
				<li>Quenching: when the hot metal piece is finished, you need to temper it in cold fluids in a trough to finish it, before adding fittings such as a wooden rod, sword handle, chain or leather strips. </li>
				<li>The first item you make should be a good hammer, you might need to repeat the process and replace the previous hammer with a new one in steps. Try to have at least a masterworked iron hammer before moving on to other items to save you headache. </li>
				</ol>
				<p>


				<h3>Some secret smithing recipes.</h3>

				These are some of the items that can be made with hot iron and a steady hand. Results are not always the same depending on the anvil used.
				<p>
				<ol>
				<li>Hammer: (BPP) Bend the metal, then punch it like you would a profligates face until the hammerhead is done. Add a rod.</li>
				<li>Shovel: (BUU) Bend the metal, then upset. Add a rod.</li>
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

				<li>Sword: (FFDF) You must fold the metal some, then draw it and fold it again. Add a handle and you got a fine blade! </li>
				<li>Sabre: (FFDD) You must fold the metal some, then draw it into a proper thin shape. Add a handle and you got a curved blade. </li>

				<li>Longsword: (FFFDD) Fold, fold, fold then draw twice.. Done right, you get a proper sharp sword, after adding a sword handle.</li>
				<li>Katana: (FFFFF) Fold, fold, then FOLD SOME MORE. These curved swords look weird but are reasonably sharp I guess.</li>
				<li>Wakizashi: (FFFS) Fold thrice and shrink it, add a handle and you got a small dinky blade. </li>

				<li>Mace: (UPU) Fold, draw, and fold twice, add a handle and you got a small dinky blade. </li>
				<li>Scrap blade: (UDPP) Fold, draw, and fold twice, add a handle and you got a small dinky blade. </li>

				<li>Heavy axe: (UDSP) Upset the hot metal, draw it, shrink it, punch holes in it. Add a wooden rod, then go chop down some wood or enemies. Easy. </li>
				<li>Crusher: (UUPP) Upset the hot metal, then use the puncher to make holes for the fittings. Add a wooden rod and crush those disgusting ghouls like twigs. </li>

				<li>Spear: (DDDF) Draw the metal thrice then fold it. Add a rod, and enjoy a simple but effective weapon.</li>
				<li>Trident: (DDBF) Draw the metal thrice then fold it. Add a rod, and enjoy a simple but effective weapon.</li>

				<li>Javelin: (SDU) Shrink, draw, upset, add a wooden rod and throw it in someones face.</li>
				<li>Throwing knife: (SDD) Shrink and draw the metal twice, then add leather strips and there you go.</li>
				<li>Bola: (SUU) Shrink then upset twice, add a chain and you got a nice slavecatcher.</li>

				<li>For forgemasters trained in the east, you of course also know the ways to make our own weapons, that outsiders are unfit to touch, unless its tasting its edge. </li>
				<li>Legion Spatha: (FFBF) You must fold the metal some, then bend it and fold some more. Add a handle and marvel at the beauty of the Legions finest blade! </li>
				<li>Legion Lance: (DBDF) Draw the metal thrice then fold it. Add a rod, and enjoy a simple but effective weapon.</li>
				<li>Legion Waraxe: (UDUP) Upset the hot metal, draw, upset, and punch it. Add a wooden rod, and behold the perfection of a Legion war axe. </li>
				<li>Legion Gladius: (FBF) Fold the metal, bend it and ugh..yeah, fold it more. Add handle.</li>

				</ol>
				<p>
				If you need more metal for your work, stop being lazy and smelt the ores in a furnace then keep going!
				Now go and make things of metal!

				</body>
				</html>
				"}

// woodenrod production made, in sheet_types.dm /obj/item/stack/sheet/mineral/wood/attackby(obj/item/W, mob/user, params)

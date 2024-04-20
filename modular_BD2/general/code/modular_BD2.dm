/* 	IN THIS FILE
	*	MATERIALS
	*	AUTOLATHES
	*	FALLOUT TOOLS
	*	WORKBENCHES
	*	STRUCTURES
	*	ITEMS
*/

//////////////////////////////////////////////////
//												//
//												//
//					MATERIALS					//
//												//
//												//
//////////////////////////////////////////////////

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
	icon = 'modular_BD2/general/icons/stackable_items.dmi'
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
	icon = 'modular_BD2/general/icons/stackable_items.dmi'
	icon_state = "sheet_coke"
	custom_materials = null
	throwforce = 2
	grind_results = list(/datum/reagent/medicine/charcoal = 5)
	material_type = /datum/material/coal
	merge_type = /obj/item/stack/sheet/coke
	resistance_flags = FLAMMABLE

/obj/item/stack/sheet/coke/twenty
	amount = 20

/turf/closed/mineral/coal
	mineralType = /obj/item/stack/ore/coal
	spreadChance = 5
	spread = 1
	scan_state = "rock_Coal"
/*
UPDATED CODE TO ALLOW FOR COKE AS FUEL
/obj/machinery/grill/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/sheet/mineral/coal) || I, /obj/item/stack/sheet/mineral/coke) || istype(I, /obj/item/stack/sheet/mineral/wood))
		var/obj/item/stack/S = I
		var/stackamount = S.get_amount()
		to_chat(user, span_notice("You put [stackamount] [I]s in [src]."))
		if(istype(I, /obj/item/stack/sheet/mineral/coal) || I, /obj/item/stack/sheet/mineral/coke))
			grill_fuel += (500 * stackamount)
		else
			grill_fuel += (50 * stackamount)
		S.use(stackamount)
		update_icon()
		return
	if(I.resistance_flags & INDESTRUCTIBLE)
		to_chat(user, span_warning("You don't feel it would be wise to grill [I]..."))
		return ..()
	if(istype(I, /obj/item/reagent_containers))
		if(istype(I, /obj/item/reagent_containers/food) && !istype(I, /obj/item/reagent_containers/food/drinks))
			if(HAS_TRAIT(I, TRAIT_NODROP) || (I.item_flags & (ABSTRACT | DROPDEL)))
				return ..()
			else if(!grill_fuel)
				to_chat(user, span_notice("There is not enough fuel."))
				return
			else if(!grilled_item && user.transferItemToLoc(I, src))
				grilled_item = I
				to_chat(user, span_notice("You put the [grilled_item] on [src]."))
				update_icon()
				grill_loop.start()
				return
		else
			if(I.reagents.has_reagent(/datum/reagent/consumable/monkey_energy))
				grill_fuel += (20 * (I.reagents.get_reagent_amount(/datum/reagent/consumable/monkey_energy)))
				to_chat(user, span_notice("You pour the Monkey Energy in [src]."))
				I.reagents.remove_reagent("monkey_energy", I.reagents.get_reagent_amount(/datum/reagent/consumable/monkey_energy))
				update_icon()
				return
	..()
*/
/* Added
	icon = 'modular_BD2/general/icons/stackable_items.dmi'
to the below
/obj/item/stack/sheet/gold
/obj/item/stack/sheet/silver
/obj/item/stack/sheet/lead
/obj/item/stack/sheet/metal
/obj/item/stack/sheet/plasteel
/obj/item/stack/sheet/mineral/wood
/obj/item/stack/medical/gauze/improvised
/obj/item/stack/sheet/cloth
/obj/item/stack/sheet/plastic
/obj/item/stack/sheet/glass
/obj/item/stack/sheet/leatherstrips
/obj/item/stack/sheet/mineral/limestone
/obj/item/stack/sheet/mineral/concrete
/obj/item/stack/ore/blackpowder
/obj/item/stack/crafting/armor_plate
/obj/item/stack/crafting/metalparts
/obj/item/stack/crafting/goodparts
/obj/item/stack/crafting/electronicparts
/obj/item/stack/crafting/powder
*/

//////////////////////////////////////////////////
//												//
//												//
//					AUTOLATHES					//
//												//
//												//
//////////////////////////////////////////////////
/*
// ------------------------------- MANUAL AUTOLATHE ------------------------------

/obj/machinery/autolathe/manual
	name = "manual lathe"
	desc = "Produce simple items with manually cranked tools."
	icon = 'modular_BD2/general/icons/autolathe_primitive.dmi'
	icon_state = "autolathe"
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/autolathe/manual
	tooadvanced = FALSE
	categories = list(
					"Tools",
					"Construction",
					"Equipment",
					"Medical",
					"Misc",
					"Dinnerware",
					)
	base_print_speed = 30
	allowed_materials = list(
		/datum/material/iron,
		/datum/material/glass,
		/datum/material/titanium,
		/datum/material/bone,
		/datum/material/lead
		)
	stored_research = /datum/techweb/specialized/autounlocking/autolathe/manual


/obj/item/circuitboard/machine/autolathe/manual // not reinventing machine building entirely even if its dorky
	name = "manual lathe kit"

/datum/techweb/specialized/autounlocking/autolathe/manual
	design_autounlock_buildtypes = AUTOLATHE_PRIMITIVE
	allowed_buildtypes = AUTOLATHE_PRIMITIVE


// ------------------------------- MANUAL AUTOLATHE DESIGNS ------------------------------

/datum/design/hemostat_primitive
	name = "Hemostat (primitive)"
	id = "hemostat_primitive"
	materials = list(/datum/material/iron = ONE_SHEET*2, /datum/material/bone = HALF_SHEET)
	build_path = /obj/item/hemostat/tribal
	category = list("initial", "Medical")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/cautery_primitive
	name = "Cautery (primitive)"
	id = "cautery_primitive"
	materials = list(/datum/material/iron = ONE_SHEET*2, /datum/material/glass = HALF_SHEET)
	build_path = /obj/item/cautery/primitive
	category = list("initial", "Medical")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/razor
	name = "Straight razor"
	id = "straigth_razor"
	materials = list(/datum/material/iron = ONE_SHEET*2, /datum/material/bone = HALF_SHEET)
	build_path = /obj/item/melee/onehanded/straight_razor
	category = list("initial", "Medical")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/retractor_primitive
	name = "Retractor (primitive)"
	id = "retractor_primitive"
	materials = list(/datum/material/iron = ONE_SHEET*2, /datum/material/bone = HALF_SHEET)
	build_path = /obj/item/retractor/tribal
	category = list("initial", "Medical")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/bonesetter_primitive
	name = "Bonesetter (primitive)"
	id = "bonesetter_primitive"
	materials = list(/datum/material/iron = ONE_SHEET*2, /datum/material/bone = HALF_SHEET)
	build_path = /obj/item/bonesetter
	category = list("initial", "Medical")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/handsaw
	name = "Hand saw"
	id = "handsaw"
	materials = list(/datum/material/iron =  ONE_SHEET*3)
	build_path = /obj/item/circular_saw/primitive
	category = list("initial", "Medical")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/lantern
	name = "Lantern"
	id = "lantern"
	materials = list(/datum/material/lead = QUARTER_SHEET, /datum/material/glass = ONE_SHEET)
	build_path = /obj/item/flashlight/lantern
	category = list("initial","Equipment")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/binoculars
	name = "Binoculars"
	id = "binoculars"
	materials = list(/datum/material/lead = ONE_SHEET*2, /datum/material/glass =  ONE_SHEET*10) // leaded glass
	build_path = /obj/item/binoculars
	category = list("initial","Equipment")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/weldingtool_basic
	name = "Welding tool"
	id = "weldingtool_basic"
	materials = list(/datum/material/iron = ONE_SHEET, /datum/material/glass = QUARTER_SHEET)
	build_path = /obj/item/weldingtool/basic
	category = list("initial","Tools")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/screwdriver_basic
	name = "Screwdriver"
	id = "screwdriver_basic"
	materials = list(/datum/material/iron = QUARTER_SHEET)
	build_path = /obj/item/screwdriver/basic
	category = list("initial","Tools")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/wirecutters_basic
	name = "Wirecutters"
	id = "wirecutters_basic"
	materials = list(/datum/material/iron = QUARTER_SHEET)
	build_path = /obj/item/wirecutters/basic
	category = list("initial","Tools")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/wrench_basic
	name = "Wrench"
	id = "wrench_basic"
	materials = list(/datum/material/iron = HALF_SHEET)
	build_path = /obj/item/wrench/basic
	category = list("initial","Tools")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/crowbar_basic
	name = "Crowbar"
	id = "crowbar_basic"
	materials = list(/datum/material/iron = HALF_SHEET)
	build_path = /obj/item/crowbar/basic
	category = list("initial","Tools")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/metal_parts
	name = "Metal parts"
	id = "metalparts"
	materials = list(/datum/material/iron = ONE_SHEET*5)
	build_path = /obj/item/stack/crafting/metalparts
	category = list("initial","Construction")
	build_type = AUTOLATHE_PRIMITIVE
	maxstack = 50

/datum/design/hq_parts
	name = "High quality parts"
	id = "hqparts"
	materials = list(/datum/material/titanium = ONE_SHEET*5)
	build_path = /obj/item/stack/crafting/goodparts
	category = list("initial","Construction")
	build_type = AUTOLATHE_PRIMITIVE
	maxstack = 50

/datum/design/titanium
	name = "Titanium sheet"
	id = "titanium_sheet"
	build_type = AUTOLATHE_PRIMITIVE
	materials = list(/datum/material/titanium = ONE_SHEET)
	build_path = /obj/item/stack/sheet/metal
	category = list("initial","Construction")
	maxstack = 50

/datum/design/lead
	name = "Lead sheet"
	id = "lead"
	build_type = AUTOLATHE | AUTOLATHE_PRIMITIVE
	materials = list(/datum/material/lead = ONE_SHEET)
	build_path = /obj/item/stack/sheet/lead
	category = list("initial","Construction")
	maxstack = 50

/datum/design/chain
	name = "Length of chain"
	id = "chain"
	materials = list(/datum/material/iron = ONE_SHEET)
	build_path = /obj/item/blacksmith/chain
	category = list("initial","Construction")
	build_type = AUTOLATHE_PRIMITIVE

/datum/design/lunchbox
	name = "Lunchbox"
	id = "lunchbox"
	build_type = AUTOLATHE_PRIMITIVE
	materials = list(/datum/material/iron = ONE_SHEET)
	build_path = /obj/item/crafting/lunchbox
	category = list("initial", "Misc")

/datum/design/beartrap
	name = "Beartrap"
	id = "beartrap"
	build_type = AUTOLATHE_PRIMITIVE
	materials = list(/datum/material/titanium = ONE_SHEET)
	build_path = /obj/item/restraints/legcuffs/beartrap
	category = list("initial", "Misc")

/datum/design/coffeepot
	name = "Coffeepot"
	id = "coffeepot"
	build_type = AUTOLATHE_PRIMITIVE
	materials = list(/datum/material/iron = ONE_SHEET)
	build_path = /obj/item/crafting/coffee_pot
	category = list("initial", "Misc")

// Also the following recipes has [] | AUTOLATHE_PRIMITIVE } added to build_type: /datum/design/lead, /datum/design/titanium, /datum/design/rods, /datum/design/metal, /datum/design/glass, /datum/design/rglass
// /datum/design/handlabeler, /datum/design/kitchen_knife, /datum/design/fork, /datum/design/beaker, /datum/design/large_beaker, /datum/design/bonesetter
// /datum/design/handcuffs, /datum/design/syringe, /datum/design/igniter, /datum/design/spraycan, /datum/design/extinguisher, /datum/design/welding_helmet, /datum/design/cable_coil
// /datum/design/toolbox, /datum/design/spraybottle, /datum/design/bucket, /datum/design/timer, /datum/design/tray, /datum/design/bowl, /datum/design/drinking_glass, /datum/design/shot_glass
// /datum/design/shaker, /datum/design/earmuffs
// #define AUTOLATHE_PRIMITIVE	(1<<13)	// ADD to defines machines.dm


// ------------------------------- MILITARY AUTOLATHE ------------------------------

/obj/machinery/autolathe/military
	name = "military autolathe"
	desc = "Ancient technology, still works."
	icon = 'modular_BD2/general/icons/autolathe_military.dmi'
	circuit = /obj/item/circuitboard/machine/autolathe/military

/obj/item/circuitboard/machine/autolathe/military
	name = "army lathe circuit board"


// ------------------------------- AMMOLATHE ------------------------------

/obj/machinery/autolathe/ammo
	name = "reloading bench"
	icon = 'modular_BD2/general/icons/ammo_lathe.dmi'

/obj/machinery/autolathe/ammo/attackby(obj/item/O, mob/user, params)
	if(!busy && !stat)
		if(istype(O, /obj/item/storage/bag/casings))
			insert_things_from_bag(user, O)
			return
		if(istype(O, /obj/item/ammo_box))
			if(pre_insert_check(user, O))
				if(!insert_bullets_from_box(user, O))
					return
		if(istype(O, /obj/item/gun/ballistic))
			if(pre_insert_check(user, O))
				if(!insert_magazine_from_gun(user, O))
					return
	if(panel_open && accepts_books)
		if(!simple && istype(O, /obj/item/book/granter/crafting_recipe/gunsmith_one))
			to_chat(user, "<span class='notice'>You upgrade [src] with simple ammunition schematics.</span>")
			simple = TRUE
			add_overlay("book1")
			qdel(O)
			return
		if(!basic && istype(O, /obj/item/book/granter/crafting_recipe/gunsmith_two))
			to_chat(user, "<span class='notice'>You upgrade [src] with basic ammunition schematics.</span>")
			basic = TRUE
			add_overlay("book2")
			qdel(O)
			return
		else if(!intermediate && istype(O, /obj/item/book/granter/crafting_recipe/gunsmith_three))
			to_chat(user, "<span class='notice'>You upgrade [src] with intermediate ammunition schematics.</span>")
			intermediate = TRUE
			add_overlay("book3")
			qdel(O)
			return
		else if(!advanced && istype(O, /obj/item/book/granter/crafting_recipe/gunsmith_four))
			to_chat(user, "<span class='notice'>You upgrade [src] with advanced ammunition schematics.</span>")
			advanced = TRUE
			add_overlay("book4")
			qdel(O)
			return
	return ..()

/obj/machinery/autolathe/ammo/on_deconstruction()
	..()
	if(simple)
		new /obj/item/book/granter/crafting_recipe/gunsmith_one(src)
	if(basic)
		new /obj/item/book/granter/crafting_recipe/gunsmith_two(src)
	if(intermediate)
		new /obj/item/book/granter/crafting_recipe/gunsmith_three(src)
	if(advanced)
		new /obj/item/book/granter/crafting_recipe/gunsmith_four(src)
	cut_overlays()
	return

/obj/machinery/autolathe/ammo/unlocked_basic/Initialize()
	. = ..()
	add_overlay("book2")

/obj/machinery/autolathe/ammo/unlocked
	simple = TRUE
	basic = TRUE
	intermediate = TRUE
	advanced = TRUE

/obj/machinery/autolathe/ammo/unlocked/Initialize()
	. = ..()
	add_overlay("book4")


//////////////////////////////////////////////////
//												//
//												//
//					FALLOUT TOOLS				//
//												//
//												//
//////////////////////////////////////////////////

// ------------------------------- BASIC TOOLS ------------------------------

/obj/item/screwdriver/basic
	name = "basic screwdriver"
	desc = "Shoddy workmanship, but the tool is fully functional."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "screwdriver_basic"
	item_state = "screwdriver_basic"
	toolspeed = 1.1
	random_color = FALSE

/obj/item/wrench/basic
	name = "wrench (basic)"
	desc = "No movable parts, just a simple wrench."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "wrench_basic"
	item_state = "wrench_basic"
	toolspeed = 1.2

/obj/item/crowbar/basic
	name = "crowbar"
	desc = "Made of poor quality steel and has a rough finish, but it does get the job done."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "crowbar_basic"
	item_state = "crowbar_basic"
	toolspeed = 1.5

/obj/item/wirecutters/basic
	name = "basic wirecutters"
	desc = "Almost sharp cutters, maded of various bits of scrap metal."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "wirecutters_basic"
	item_state = "wirecutters_basic"
	toolspeed = 1.3
	random_color = FALSE

/obj/item/weldingtool/basic
	name = "basic welding tool"
	desc = "Has some small fuel leaks and looks like its just some rusty piece of junk, but somehow it works."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "welder_basic"
	item_state = "welder_basic"
	toolspeed = 1.1


// ------------------------------- PRE-WAR TOOLS ------------------------------  Idea is not buildable, obviously, and about 50% better than standard tools.

/obj/item/wirecutters/prewar
	name = "wirecutters (prewar)"
	desc = "High quality steel and precise mechanism."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "wirecutters_prewar"
	item_state = "wirecutters_prewar"
	toolspeed = 0.4
	random_color = FALSE

/obj/item/wrench/prewar // obsolete due to power drill
	name = "wrench (prewar)"
	desc = "An torque locking tool thats very good for wrenching."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "wrench_prewar"
	item_state = "wrench_prewar"
	toolspeed = 0.5

/obj/item/screwdriver/prewar
	name = "screwdriver (prewar)"
	desc = "Polymer handle, blackened steel finish, its a high-quality tool for sure.""
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "screwdriver_prewar"
	item_state = "screwdriver_prewar"
	toolspeed = 0.5
	random_color = FALSE

/obj/item/crowbar/prewar
	name = "crowbar (prewar)"
	desc = "Heat-resistant powder coating, smooth steel surfaces, its a high-quality tool for sure.""
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "crowbar_prewar"
	item_state = "crowbar_prewar"
	toolspeed = 0.8

/obj/item/screwdriver/power // obsolete due to power drill
	icon = 'modular_BD2/general/icons/tools.dmi'
	icon_state = "drill_screw"
	item_state = "drill"
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'

/obj/item/wrench/power
	icon = 'modular_BD2/general/icons/tools.dmi'
	icon_state = "drill_bolt"
	item_state = "drill"
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'

/obj/item/weldingtool/prewar
	name = "welding tool (pre-war)"
	desc = "Comfortable grip, large tank and precise cutting."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "welder_prewar"
	item_state = "welder_prewar"
	toolspeed = 0.7
	max_fuel = 40

/obj/item/metaldetector
	name = "metal detector"
	desc = "Detects buried metals in a 50 metre radius when activated."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "metaldetect"



//////////////////////////////////////////////////
//												//
//												//
//					WORKBENCHES					//
//												//
//												//
//////////////////////////////////////////////////

// ------------ METALWORKING BENCH ------------------ 

/obj/machinery/workbench/forge // should be repathed to worbench/metal
	name = "metalworking bench"
	desc = "A workbench with a drill press, a makeshift blowtorch setup, and various tools for making crude weapons and tools."
	icon = 'modular_BD2/blacksmith/icons/workbench64x32.dmi'
	icon_state = "bench_metal"


// ------------ WORKBENCH ------------------ 

/obj/machinery/workbench
	desc = "A basic workbench with a full set of tools for simple to intermediate projects."
	icon = 'modular_BD2/general/icons/workbench.dmi'
	machine_tool_behaviour = list(TOOL_WORKBENCH, TOOL_CROWBAR, TOOL_SCREWDRIVER, TOOL_WIRECUTTER, TOOL_WRENCH)
	drag_delay = 0.4 SECONDS // Heavy, slow to drag


// ------------ ADVANCED WORKBENCH ------------------ 

/obj/machinery/workbench/advanced
	desc = "A large and advanced pre-war workbench to tackle any project! Comes with a full set of basic tools and a digital multitool."
	icon = 'modular_BD2/general/icons/workbench.dmi'
	machine_tool_behaviour = list(TOOL_AWORKBENCH, TOOL_WORKBENCH, TOOL_CROWBAR, TOOL_SCREWDRIVER, TOOL_WIRECUTTER, TOOL_WRENCH, TOOL_MULTITOOL)

*/


//////////////////////////////////////////////////
//												//
//												//
//					STRUCTURES					//
//												//
//												//
//////////////////////////////////////////////////

/* Copied to base code

/obj/structure/closet/crate/basic
	icon = 'modular_BD2/general/icons/crates.dmi'

// ------------ CRATES ------------------ 

/obj/structure/closet/crate/wicker
	icon = 'icons/fallout/farming/farming_tools.dmi'
	open_sound = 'sound/effects/rustle3.ogg'
	close_sound = 'sound/effects/rustle3.ogg'
	material_drop = /obj/item/stack/sheet/hay

/obj/structure/closet/crate/footchest
	icon = 'modular_BD2/general/icons/crates.dmi'
	open_sound = 'modular_BD2/sound/creak.ogg'
	close_sound = 'modular_BD2/sound/creak.ogg'
	dense_when_open = FALSE
*/


/*	

//////////////////////////////////////////////////
//												//
//												//
//					ITEMS						//
//												//
//												//
//////////////////////////////////////////////////

// -------------------- TOOLBOX (PREWAR) ------------------  Meant to be loot possible to find in well preserved high tech places

/obj/item/storage/toolbox/prewar
	name = "toolbox (pre-war)"
	desc = "Plastic toolbox, made long ago."
	icon = 'modular_BD2/general/icons/tools.dmi'
	righthand_file = 'modular_BD2/general/icons/righthand.dmi'
	lefthand_file = 'modular_BD2/general/icons/lefthand.dmi'
	icon_state = "toolbox_prewar"
	item_state = "toolbox_prewar"
	custom_materials = list(/datum/material/plastic = 500)

/obj/item/storage/toolbox/prewar/PopulateContents()
	new /obj/item/crowbar/prewar(src)
	new /obj/item/wirecutters/prewar(src)
	new /obj/item/wrench/prewar(src)
	new /obj/item/weldingtool/prewar(src)
	new /obj/item/screwdriver/prewar(src)
	new	/obj/item/multitool(src)


// ------------------------------- ABRAXO SPRAYBOTTLE ------------------------------
// Abraxo spray is now made by adding Abraxo to a spray bottle, not taking a pinch of glass and snap your fingers.
// Abraxo my beloved. Slap it on spray bottle, clean away.

/obj/item/reagent_containers/spray/empty/attackby(obj/item/C, mob/user, params)
	if(istype(C, /obj/item/crafting/abraxo))
		user.visible_message("[user] begins filling the[src] with Abraxo solution.", \
				span_notice("You begin filling he [src] with Abraxo. Smells nice."), \
				span_italic("You hear faint bubbling sounds."))
		playsound(get_turf(src), 'modular_BD2/sound/abraxo.ogg', 100, TRUE)
		if(!do_after(user, 40, TRUE, src))
			return
		new /obj/item/reagent_containers/spray/cleaner(drop_location())
		qdel(src)
		qdel(C)
		return
	return ..()

/obj/item/reagent_containers/spray/empty
	desc = "A spray bottle, with an unscrewable top. Meant to be filled with Abraxo for superior cleanliness."
	icon = 'modular_BD2/general/icons/cleaning.dmi'


// ------------------------------- MATCHBOX FIX ------------------------------

/obj/item/storage/box/matches/attackby(obj/item/match/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/match))
		if(prob(50))
			playsound(src, 'sound/f13items/matchstick_hit.ogg', 80, TRUE)
			return
		else
			W.matchignite()
			playsound(src, 'sound/f13items/matchstick_lit.ogg', 80, TRUE)



// ------------ CRAFING STACKABLE ICON UPDATERS ------------------
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


// -------------------- CRAFTING RECIPES ------------------

/datum/crafting_recipe/broom
	name = "Broom"
	result = /obj/item/broom
	time = 50
	reqs = list(/obj/item/stack/sheet/hay = 2,
				/obj/item/stack/sheet/mineral/wood = 4)
	category = CAT_CRAFTING
	subcategory = CAT_TOOL

/datum/crafting_recipe/mop
	name = "Mop"
	result = /obj/item/mop
	time = 50
	reqs = list(/obj/item/stack/sheet/cloth = 2,
				/obj/item/stack/sheet/mineral/wood = 4)
	category = CAT_CRAFTING
	subcategory = CAT_TOOL


// -------------------- ARMOR KIT CUSTOMIZATION ------------------ Because I like slapcrafting and Id like for my shoulder kit to be craftable

/obj/item/clothing/suit/armor/light/kit/attackby(obj/item/C, mob/user, params)
	if(istype(C, /obj/item/crafting/duct_tape))
		user.visible_message("[user] begins taping on some punky bits to the the [src].", \
				span_notice("You begin taping some punkish item on the [src]."), \
				span_italic("You hear someone tape stuff together."))
		playsound(src, 'sound/f13items/craft_2.ogg', 100, TRUE)
		if(!do_after(user, 40, TRUE, src))
			return
		new /obj/item/clothing/suit/armor/light/kit/punk(drop_location())
		qdel(src)
		qdel(C)
		return
	if(istype(C, /obj/item/stack/sheet/metal))
		user.visible_message("[user] begins adding metal sheet to the the [src].", \
				span_notice("You begin attaching some metal sheet on the [src]."), \
				span_italic("You hear grunts as someone tries to bend metal with their hands."))
		playsound(src, 'sound/f13items/craft_2.ogg', 100, TRUE)
		if(!do_after(user, 40, TRUE, src))
			return
		new /obj/item/clothing/suit/armor/light/kit/plates(drop_location())
		qdel(src)
		C.use(1)
		return
	if(C.tool_behaviour == TOOL_WIRECUTTER)
		user.visible_message("[user] begins cutting new straps to wear [src] differently.", \
				span_notice("You begin cutting straps and readjusting the [src]."), \
				span_italic("You hear the snips of a wirecutter on fabric."))
		playsound(src, 'sound/weapons/slice.ogg', 50, TRUE)
		if(!do_after(user, 40, TRUE, src))
			return
		new /obj/item/clothing/suit/armor/light/kit/shoulder(drop_location())
		qdel(src)
		return
	return ..()


// -------------------- HAIR & BEARDS ------------------
Files edited to make the new hair icon set work:
species.dm adjusted for new hair an beard suffixes + changed names.
hair_head.dm
hair_face.dm
*/

/obj/structure/rack/shelf_wood
	name = "BUGGED VERSION, MURDER"
	desc = "NO!!!."

// TEMP FOR PORTING AND FUNCTIOANLITY

// ------------------------ STRAIGHT RAZOR ------------------------------- // Pebbles straight razor. It borrows the razor code, edits some timers, adds sounds and slaps it on a melee weapon.
/obj/item/melee/onehanded/straight_razor
	name = "straight razor"
	desc = "For those smooth close shaves. Better aim for the mouth or the head, or else things might get messy. Could be used as a scalpel in a pinch."
	icon = 'modular_BD2/fashion/icons/cosmetics.dmi'
	righthand_file = 'modular_BD2/fashion/icons/onmobright.dmi'
	lefthand_file = 'modular_BD2/fashion/icons/onmobleft.dmi'
	icon_state = "straight_razor"
	force = WEAPON_FORCE_BIG_TOOL
	throwforce = THROWING_PATHETIC
	wound_bonus = WOUNDING_MALUS_SHALLOW // crap against armor
	bare_wound_bonus = WOUNDING_BONUS_BIG // bleeds a lot, despite its low damage
	sharpness = SHARP_EDGED
	total_mass = TOTAL_MASS_TINY_ITEM
	w_class = WEIGHT_CLASS_TINY
	tool_behaviour = TOOL_SCALPEL //ghetto surgery yay
	toolspeed = 1.2

/obj/item/melee/onehanded/straight_razor/proc/manual_shave(mob/living/carbon/human/H, location = BODY_ZONE_PRECISE_MOUTH)
	if(location == BODY_ZONE_PRECISE_MOUTH)
		H.facial_hair_style = "Clean shave (Hairless)"
	else
		H.hair_style = "Skinhead"

	H.update_hair()

/obj/item/melee/onehanded/straight_razor/attack(mob/M, mob/user)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/location = user.zone_selected
		if((location in list(BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_HEAD)) && !H.get_bodypart(BODY_ZONE_HEAD))
			to_chat(user, span_warning("[H] doesn't have a head!"))
			return
		if(location == BODY_ZONE_PRECISE_MOUTH)
			if(!(FACEHAIR in H.dna.species.species_traits))
				to_chat(user, span_warning("There is no facial hair to shave!"))
				return
			if(!get_location_accessible(H, location))
				to_chat(user, span_warning("The mask is in the way!"))
				return
			if(H.facial_hair_style == "Clean shave (Hairless)")
				to_chat(user, span_warning("Already clean-shaven!"))
				return

			if(H == user) //shaving yourself
				playsound(loc, 'modular_BD2/fashion/sound/shaving.ogg', 100, 1) // added
				user.visible_message("[user] starts to shave [user.p_their()] facial hair with [src].", \
									span_notice("You take a moment to shave your facial hair with [src]..."))
				if(do_after(user, 150, target = H))
					user.visible_message("[user] shaves [user.p_their()] facial hair clean with [src].", \
										span_notice("You finish shaving with [src]. Fast and clean!"))
					manual_shave(H, location)
			else
				var/turf/H_loc = H.loc
				playsound(loc, 'modular_BD2/fashion/sound/shaving.ogg', 100, 1) // added
				user.visible_message(span_warning("[user] tries to shave [H]'s facial hair with [src]."), \
									span_notice("You start shaving [H]'s facial hair..."))
				if(do_after(user, 100, target = H))
					if(H_loc == H.loc)
						user.visible_message(span_warning("[user] shaves off [H]'s facial hair with [src]."), \
											span_notice("You shave [H]'s facial hair clean off."))
						manual_shave(H, location)

		else if(location == BODY_ZONE_HEAD)
			if(!(HAIR in H.dna.species.species_traits))
				to_chat(user, span_warning("There is no hair to shave!"))
				return
			if(!get_location_accessible(H, location))
				to_chat(user, span_warning("The headgear is in the way!"))
				return
			if(H.hair_style == "Bald" || H.hair_style == "Mature (Balding)" || H.hair_style == "Clean shave (Hairless)")
				to_chat(user, span_warning("There is not enough hair left to shave!"))
				return

			if(H == user) //shaving yourself
				playsound(loc, 'modular_BD2/fashion/sound/shaving.ogg', 100, 1) // added
				user.visible_message("[user] starts to shave [user.p_their()] head with [src].", \
									span_notice("You start to shave your head with [src]..."))
				if(do_after(user, 150, target = H)) //edited time
					user.visible_message("[user] shaves [user.p_their()] head with [src].", \
										span_notice("You finish shaving with [src]."))
					manual_shave(H, location)
			else
				var/turf/H_loc = H.loc
				playsound(loc, 'modular_BD2/fashion/sound/shaving.ogg', 100, 1) // added
				user.visible_message(span_warning("[user] tries to shave [H]'s head with [src]!"), \
									span_notice("You start shaving [H]'s head..."))
				if(do_after(user, 150, target = H)) //edited time
					if(H_loc == H.loc)
						user.visible_message(span_warning("[user] shaves [H]'s head bald with [src]!"), \
											span_notice("You shave [H]'s head bald."))
						manual_shave(H, location)
		else
			..()
	else
		..()


//////////////////////////////////////////
// 										//
//										//
//			PRIMITIVE MEDICAL			//
//										//
//										//
//////////////////////////////////////////

// ------------------- BUTCHERS TABLE -----------------------------

/obj/structure/table/optable/primitive
	name = "butchers table"
	desc = "Used for painful, primitive medical procedures."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'


// ------------------- PRIMITIVE SURGERY STUFF -----------------------------  Could use more janky ghetto stuff feeling, messing about in the wound datums maybe or whatnot. Currently basically reskins with a bit slower speed.

/obj/item/cautery/primitive
	name = "primitive cautery"
	desc = "A welding device tuned down to cauterize wounds. Not very precise."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	righthand_file = 'modular_BD2/legio_invicta/icons/onmob_legion_righthand.dmi'
	lefthand_file = 'modular_BD2/legio_invicta/icons/onmob_legion_lefthand.dmi'
	icon_state = "cautery_primitive"
	toolspeed = 1.5

/obj/item/circular_saw/primitive
	name = "handsaw"
	desc = "For sawing through wood or possibly bones."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	icon_state = "saw"
	item_state = "saw"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	hitsound = 'sound/effects/shovel_dig.ogg'
	usesound = 'sound/effects/shovel_dig.ogg'
	custom_materials = list(/datum/material/iron=2000)
	toolspeed = 1.2
	wound_bonus = 0
	bare_wound_bonus = 10
	attack_verb = list("sawed", "scratched")

/obj/item/stack/medical/bone_gel/superglue
	name = "superglue (bonegel)"
	singular_name = "superglue"
	desc = "Good for gluing together broken bones!"
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	icon_state = "superglue"
	lefthand_file = NONE
	righthand_file = NONE
	grind_results = NONE

/obj/item/reagent_containers/medspray/sterilizine/honey
	name = "medical honey (sterilizer)"
	desc = "Pure honey has antiseptic properties, and probably works just as a sterilizing agent."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	icon_state = "sterilizer_honey"
	apply_method = "smear"
//	sound_squirt = 'modular_BD2/general/sound/honey.ogg' FIX LATER MARKED FOR DEATH

/* Added to base code
sound_squirt
Added to proc/attempt_spray
		playsound(src, sound_squirt, 50, 1, -6)
*/

// ------------------- PRIMITIVE MEDICAL BAG -----------------------------

/obj/item/storage/backpack/duffelbag/med/surgery/primitive
	name = "surgical duffel bag"
	desc = "A large duffel bag for holding extra medical supplies - this one seems to be designed for holding surgical tools."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	righthand_file = 'modular_BD2/legio_invicta/icons/onmob_legion_righthand.dmi'
	lefthand_file = 'modular_BD2/legio_invicta/icons/onmob_legion_lefthand.dmi'
	icon_state = "toolbag_primitive"

/obj/item/storage/backpack/duffelbag/med/surgery/primitive/PopulateContents()
	new /obj/item/melee/onehanded/straight_razor(src)
	new /obj/item/hemostat/tribal(src)
	new /obj/item/retractor/tribal(src)
	new /obj/item/circular_saw/primitive(src)
	new /obj/item/cautery/primitive(src)
	new /obj/item/bonesetter(src)
	new /obj/item/bedsheet/blanket(src)
	new /obj/item/reagent_containers/medspray/sterilizine/honey(src)
	new /obj/item/stack/sticky_tape/surgical(src)
	new /obj/item/stack/medical/bone_gel/superglue(src)

/obj/item/storage/backpack/duffelbag/med/surgery/primitive/anchored
	name = "surgical toolset"
	desc = "Large piece of felt with various surgical tools laid out."
	icon_state = "surgicalset_primitive"
	anchored = TRUE


// ------------------- PRIMITIVE IV DRIP -----------------------------

/obj/machinery/iv_drip/primitive
	name = "wooden IV drip"
	desc = "Simple frame for infusing liquids using gravity. Can't suck out fluids."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	anchored = TRUE
	plane = GAME_PLANE

/* 
/obj/machinery/iv_drip/verb/toggle_mode() updated
added this to make the overlay actually work
			var/mutable_appearance/filling_overlay = mutable_appearance('modular_BD2/icons/primitive_medical.dmi', "reagent")
*/


// ------------------- PRIMITIVE DEFIB MOUNT -----------------------------

/obj/machinery/defibrillator_mount/primitive
	desc = "Holds a primitive defibrillator."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	icon_state = "defibrillator_mount"
	density = FALSE
	use_power = FALSE
	clamps_locked = TRUE
	plane = GAME_PLANE

/obj/machinery/defibrillator_mount/primitive/Initialize() //loaded subtype for mapping use
	. = ..()
	defib = new/obj/item/defibrillator/primitive(src)
	update_overlays()


// ------------------- PRIMITIVE MEDICAL TOOLBELT -----------------------------

obj/item/storage/belt/medical/primitive
	name = "primitive medical toolbelt"
	desc = "This might look a bit like a toolbelt for a carpenter, but the items inside are meant to be used in surgery. No really."
	icon = 'modular_BD2/legio_invicta/icons/icons_legion.dmi'
	righthand_file = 'modular_BD2/legio_invicta/icons/onmob_legion_righthand.dmi'
	lefthand_file = 'modular_BD2/legio_invicta/icons/onmob_legion_lefthand.dmi'
	mob_overlay_icon = 'modular_BD2/legio_invicta/icons/onmob_legion.dmi'
	icon_state = "belt_blacksmith"
	item_state = "belt_blacksmith"

/obj/item/storage/belt/medical/primitive/PopulateContents()
	new /obj/item/surgical_drapes(src)
	new /obj/item/melee/onehanded/straight_razor(src)
	new /obj/item/circular_saw/primitive(src)
	new /obj/item/retractor/tribal(src)
	new /obj/item/hemostat/tribal(src)
	new /obj/item/cautery/primitive(src)
	new /obj/item/bonesetter(src)

/obj/item/hemostat/tribal
	name = "primitive hemostat (flesh-poker)"
	desc = "A pinching device made from bone to clamp bleedings with"
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	icon_state = "hemostat_primitive"

/obj/item/retractor/tribal
	name = "primitive retractor (skin-puller)"
	desc = "Pries the flesh and bones open."
	icon = 'modular_BD2/general/icons/primitive_medical.dmi'
	icon_state = "retractor_primitive"


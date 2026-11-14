/**
 * The universal builder.
 *
 * One tgui menu for everything a player can put together out of materials:
 *  - every stack recipe in the game, listed under its material, whether or not the player has any of it
 *  - every structure crafting recipe that needs no workbench or other station (see /datum/crafting_recipe/is_builder_recipe)
 * Materials the player carries or stands next to are pooled, so two half stacks build one thing.
 * Stack recipes are built through make_recipe() (build here) or start_placement() (placement mode),
 * and crafting recipes through craft_recipe(), so every rule in buildable.dm and build_ownership.dm still applies.
 * Design notes: docs/base_building/README.md
 */

/// Category order in the builder's tabs
GLOBAL_LIST_INIT(build_menu_categories, list(
	"Floors & Walls",
	"Windows & Grilles",
	"Doors",
	"Defenses",
	"Furniture",
	"Plumbing",
	"Workshop",
	"Power & Machines",
	"Structures",
	"Materials",
	"Clothing",
	"Storage",
	"Weapons",
	"Tools",
	"Items",
))

/// One menu per player, keyed by REF(mob)
GLOBAL_LIST_EMPTY(build_menus)
/// Built on first use. A list of /datum/build_material, one per kind of stack that has recipes.
GLOBAL_LIST_EMPTY(build_catalog)
GLOBAL_VAR_INIT(build_catalog_built, FALSE)
/// The part of the menu's static data that is the same for everyone, built with the catalog
GLOBAL_LIST_EMPTY(build_static_data)

/// Which builder tab something that makes result_type is listed under.
/proc/get_build_category(result_type)
	if(!ispath(result_type))
		return "Items"
	if(ispath(result_type, /turf) || ispath(result_type, /obj/structure/girder) || ispath(result_type, /obj/item/stack/tile))
		return "Floors & Walls"
	if(ispath(result_type, /obj/structure/window) || ispath(result_type, /obj/structure/windoor_assembly) || ispath(result_type, /obj/structure/grille))
		return "Windows & Grilles"
	if(ispath(result_type, /obj/structure/simple_door) || ispath(result_type, /obj/structure/mineral_door) || ispath(result_type, /obj/structure/door_assembly) || ispath(result_type, /obj/machinery/door))
		return "Doors"
	if(ispath(result_type, /obj/structure/barricade) || ispath(result_type, /obj/structure/fence) || ispath(result_type, /obj/structure/railing) || ispath(result_type, /obj/structure/obstacle) \
		|| ispath(result_type, /obj/structure/punji_sticks) || ispath(result_type, /obj/structure/headpike) || ispath(result_type, /obj/structure/plasticflaps))
		return "Defenses"
	if(ispath(result_type, /obj/structure/sink) || ispath(result_type, /obj/structure/toilet) || ispath(result_type, /obj/structure/urinal) || ispath(result_type, /obj/machinery/shower) || ispath(result_type, /obj/structure/disposalpipe))
		return "Plumbing"
	if(ispath(result_type, /obj/structure/blacksmith) || ispath(result_type, /obj/structure/campfire) || ispath(result_type, /obj/structure/bonfire) || ispath(result_type, /obj/structure/fireplace) \
		|| ispath(result_type, /obj/structure/loom) || ispath(result_type, /obj/structure/fermenting_barrel) || ispath(result_type, /obj/structure/reagent_dispensers) || ispath(result_type, /obj/structure/kitchenspike) \
		|| ispath(result_type, /obj/structure/kitchenspike_frame) || ispath(result_type, /obj/structure/butter_churn) || ispath(result_type, /obj/structure/ore_box) || ispath(result_type, /obj/structure/legion_extractor) \
		|| ispath(result_type, /obj/item/chopping_block) || ispath(result_type, /obj/machinery/grill) || ispath(result_type, /obj/machinery/microwave) || ispath(result_type, /obj/machinery/smartfridge) || ispath(result_type, /obj/machinery/workbench))
		return "Workshop"
	if(ispath(result_type, /obj/structure/table) || ispath(result_type, /obj/structure/table_frame) || ispath(result_type, /obj/structure/chair) || ispath(result_type, /obj/structure/bed) || ispath(result_type, /obj/structure/closet) \
		|| ispath(result_type, /obj/structure/rack) || ispath(result_type, /obj/item/chair) || ispath(result_type, /obj/structure/curtain) || ispath(result_type, /obj/structure/mirror) || ispath(result_type, /obj/structure/bookcase) \
		|| ispath(result_type, /obj/structure/dresser) || ispath(result_type, /obj/structure/displaycase_chassis) || ispath(result_type, /obj/item/bedsheet))
		return "Furniture"
	if(ispath(result_type, /obj/machinery) || ispath(result_type, /obj/structure/frame) || ispath(result_type, /obj/structure/light_construct) || ispath(result_type, /obj/item/wallframe))
		return "Power & Machines"
	if(ispath(result_type, /obj/structure))
		return "Structures"
	if(ispath(result_type, /obj/item/stack))
		return "Materials"
	if(ispath(result_type, /obj/item/clothing))
		return "Clothing"
	if(ispath(result_type, /obj/item/storage))
		return "Storage"
	if(ispath(result_type, /obj/item/gun) || ispath(result_type, /obj/item/ammo_box) || ispath(result_type, /obj/item/ammo_casing))
		return "Weapons"
	if(ispath(result_type, /obj/item))
		var/obj/item/made = result_type
		if(initial(made.tool_behaviour))
			return "Tools"
		if(initial(made.force) >= 10)
			return "Weapons"
	return "Items"

/// Opens (or refreshes) the universal builder for user, optionally starting on the recipes of one stack.
/proc/open_build_menu(mob/user, obj/item/stack/focus)
	if(!istype(user) || !user.client)
		return
	var/datum/build_menu/menu = get_build_menu(user, focus)
	menu.ui_interact(user)

/// The user's menu, made if they have none. A player never has more than one.
/proc/get_build_menu(mob/user, obj/item/stack/focus)
	for(var/ref in GLOB.build_menus)
		var/datum/build_menu/stale = GLOB.build_menus[ref]
		if(QDELETED(stale) || QDELETED(stale.user))
			qdel(stale)
			GLOB.build_menus -= ref
	var/datum/build_menu/menu = GLOB.build_menus[REF(user)]
	if(!menu)
		menu = new(user)
	menu.focus_key = focus?.build_menu_key()
	return menu

/datum/stack_recipe
	/// Builder tab this recipe is listed under. Left null, it is worked out from what the recipe makes.
	var/category

/datum/stack_recipe/proc/get_category()
	return category || get_build_category(result_type)

/// Every recipe this stack offers in the order the menu lists them, flattened out of any sublists.
/// An assoc list of recipe to the title of the sublist it came from ("" for none), so it is indexed 1..n by recipe.
/obj/item/stack/proc/get_flat_recipes()
	var/list/flat = list()
	flatten_recipe_list(recipes, flat, null)
	return flat

/obj/item/stack/proc/flatten_recipe_list(list/entries, list/flat, group)
	for(var/entry in entries)
		if(istype(entry, /datum/stack_recipe_list))
			var/datum/stack_recipe_list/sublist = entry
			flatten_recipe_list(sublist.recipes, flat, sublist.title)
		else if(istype(entry, /datum/stack_recipe))
			flat[entry] = group || ""

/// The key a stack is listed under in the builder. Stacks that merge with each other share one.
/obj/item/stack/proc/build_menu_key()
	return "[merge_type || type]"

/// One kind of material in the builder's catalog
/datum/build_material
	var/key
	var/name
	var/unit
	/// recipe to sublist title, as get_flat_recipes() gives
	var/list/flat

/// Every kind of stack that has recipes. Built once, the first time a builder is opened.
/proc/get_build_catalog()
	if(GLOB.build_catalog_built)
		return GLOB.build_catalog
	GLOB.build_catalog_built = TRUE
	var/list/seen = list()
	for(var/stack_type in subtypesof(/obj/item/stack))
		var/obj/item/stack/prototype = stack_type
		if(initial(prototype.builder_hidden) || initial(prototype.is_cyborg))
			continue
		if(seen["[initial(prototype.merge_type) || stack_type]"])
			continue
		// The recipes only exist once a stack has been made
		var/obj/item/stack/sample = new stack_type(null, 1, FALSE)
		var/key = sample.build_menu_key()
		var/list/flat = sample.get_flat_recipes()
		if(length(flat) && !seen[key])
			seen[key] = TRUE
			var/datum/build_material/material = new
			material.key = key
			material.name = capitalize(sample.name)
			material.unit = sample.singular_name || "unit"
			material.flat = flat
			GLOB.build_catalog += material
		qdel(sample)
	return GLOB.build_catalog

/// Everything the builder can make, for the spritesheet: the result type of every catalog recipe and every builder crafting recipe.
/proc/get_build_result_types()
	var/list/types = list()
	for(var/datum/build_material/material as anything in get_build_catalog())
		for(var/datum/stack_recipe/R as anything in material.flat)
			if(ispath(R.result_type))
				types[R.result_type] = TRUE
	for(var/datum/crafting_recipe/CR as anything in GLOB.crafting_recipes)
		if(CR.is_builder_recipe())
			types[CR.result] = TRUE
	return types

/// Icons for the builder's recipes. Built the first time a builder opens, since it needs the catalog, which needs the game running.
/datum/asset/spritesheet/build_menu
	_abstract = /datum/asset/spritesheet/build_menu
	name = "build_menu"
	/// result type, as text, to its sprite name
	var/list/type_keys = list()

/datum/asset/spritesheet/build_menu/register()
	var/list/by_icon = list()
	var/list/states_of = list()
	for(var/atom/result as anything in get_build_result_types())
		var/icon_file = initial(result.icon)
		var/icon_state = initial(result.icon_state)
		if(!icon_file || isnull(icon_state))
			continue
		var/file_key = "[icon_file]"
		var/list/states = states_of[file_key]
		if(!states)
			states = icon_states(icon_file)
			states_of[file_key] = states
		if(!(icon_state in states))
			continue
		var/icon_key = "[file_key]|[icon_state]"
		var/sprite = by_icon[icon_key]
		if(!sprite)
			sprite = "r[length(by_icon) + 1]"
			by_icon[icon_key] = sprite
			Insert(sprite, icon_file, icon_state)
		type_keys["[result]"] = sprite
	return ..()

// The menu draws every icon in one square
/datum/asset/spritesheet/build_menu/ModifyInserted(icon/pre_asset)
	if(pre_asset.Width() != 32 || pre_asset.Height() != 32)
		pre_asset.Scale(32, 32)
	return pre_asset

/// The CSS classes that draw the icon for something that makes result_type, or "" if it has none.
/datum/asset/spritesheet/build_menu/proc/icon_class_for(result_type)
	var/sprite = type_keys["[result_type]"]
	return sprite ? icon_class_name(sprite) : ""

/// Builds the catalog and icons ahead of the first player opening the builder, so that first open is not a pause.
/proc/prewarm_build_menu()
	get_build_static_data()

/// The part of the menu's data that is the same for every player: the catalog's materials and stack recipes.
/proc/get_build_static_data()
	if(length(GLOB.build_static_data))
		return GLOB.build_static_data
	var/list/catalog = get_build_catalog()
	var/datum/asset/spritesheet/build_menu/sheet = get_asset_datum(/datum/asset/spritesheet/build_menu)
	var/list/sources = list()
	var/list/recipe_data = list()
	for(var/datum/build_material/material as anything in sortTim(catalog.Copy(), GLOBAL_PROC_REF(cmp_build_material)))
		sources += list(list("key" = material.key, "name" = material.name, "unit" = material.unit))
		var/list/flat = material.flat
		for(var/i in 1 to length(flat))
			var/datum/stack_recipe/R = flat[i]
			var/atom/result = R.result_type
			recipe_data += list(list(
				"kind" = "stack",
				"source" = material.key,
				"idx" = i,
				"result" = "[R.result_type]",
				"name" = R.title,
				"desc" = ispath(R.result_type) ? initial(result.desc) : "",
				"icon" = sheet.icon_class_for(R.result_type),
				"category" = R.get_category(),
				"group" = flat[R],
				"req" = R.req_amount,
				"res" = R.res_amount,
				"max_res" = R.max_res_amount,
				"time" = R.time,
				"placeable" = !!R.placeable,
			))
	GLOB.build_static_data["sources"] = sources
	GLOB.build_static_data["recipes"] = recipe_data
	return GLOB.build_static_data

/proc/cmp_build_material(datum/build_material/a, datum/build_material/b)
	return sorttext(b.name, a.name)

/datum/build_menu
	var/mob/user
	/// build_menu_key() of the stack the menu was opened on
	var/focus_key
	/// The crafting recipes this user can see, made when the menu opens
	var/list/craft_recipes
	var/busy = FALSE

/datum/build_menu/New(mob/user)
	src.user = user
	GLOB.build_menus[REF(user)] = src

/datum/build_menu/Destroy()
	if(user && GLOB.build_menus[REF(user)] == src)
		GLOB.build_menus -= REF(user)
	user = null
	craft_recipes = null
	return ..()

/datum/build_menu/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/datum/build_menu/ui_close(mob/user)
	qdel(src)

/datum/build_menu/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/build_menu))

/datum/build_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BuildMenu")
		ui.open()

/**
 * The stacks the user can build from: those they carry or stand next to.
 * Returns an assoc list of build_menu_key() to a list of stacks. The first of each list is the one built from:
 * a held stack if there is one, else the biggest. The others are merged into it when more is needed.
 */
/datum/build_menu/proc/gather_stacks()
	var/list/found = list()
	if(QDELETED(user))
		return found
	var/list/candidates = list()
	for(var/obj/item/stack/carried in user.GetAllContents(/obj/item/stack))
		candidates += carried
	for(var/obj/item/stack/nearby in range(1, user))
		if(isturf(nearby.loc))
			candidates += nearby
	for(var/obj/item/stack/S as anything in candidates)
		if(QDELETED(S) || !length(S.recipes) || (S.is_cyborg && !S.source) || S.get_amount() <= 0)
			continue
		LAZYADD(found[S.build_menu_key()], S)
	for(var/key in found)
		var/list/stacks = found[key]
		var/obj/item/stack/primary
		for(var/obj/item/stack/option as anything in stacks)
			if(!primary)
				primary = option
				continue
			var/held = user.is_holding(option)
			var/primary_held = user.is_holding(primary)
			if((held && !primary_held) || (held == primary_held && option.get_amount() > primary.get_amount()))
				primary = option
		stacks -= primary
		stacks.Insert(1, primary)
	return found

/datum/build_menu/proc/total_amount(list/stacks)
	. = 0
	for(var/obj/item/stack/S as anything in stacks)
		. += S.get_amount()

/// Merges the user's other stacks of a kind into the first until it holds needed. Returns whether it does.
/datum/build_menu/proc/pool_stacks(list/stacks, needed)
	var/obj/item/stack/primary = stacks[1]
	if(primary.get_amount() >= needed)
		return TRUE
	if(primary.is_cyborg)
		return FALSE
	for(var/obj/item/stack/other as anything in stacks)
		if(primary.get_amount() >= needed)
			break
		if(other == primary || QDELETED(other) || !other.can_merge(primary, TRUE))
			continue
		other.merge(primary, needed)
	return primary.get_amount() >= needed

/// The crafting recipes the builder lists for this user
/datum/build_menu/proc/get_craft_recipes()
	. = list()
	if(!user?.GetComponent(/datum/component/personal_crafting))
		return
	for(var/datum/crafting_recipe/R as anything in GLOB.crafting_recipes)
		if(!R.is_builder_recipe())
			continue
		if(!R.always_available && !(R.type in user.mind?.learned_recipes))
			continue
		. += R

/datum/build_menu/ui_static_data(mob/user)
	var/list/static_data = get_build_static_data()
	var/list/recipes = list()
	recipes += static_data["recipes"]
	craft_recipes = get_craft_recipes()
	var/datum/component/personal_crafting/crafting = user.GetComponent(/datum/component/personal_crafting)
	var/datum/asset/spritesheet/build_menu/sheet = get_asset_datum(/datum/asset/spritesheet/build_menu)
	for(var/datum/crafting_recipe/R as anything in craft_recipes)
		var/list/info = crafting.build_recipe_data(R)
		var/atom/result = R.result
		var/group = "Crafting - [R.category || "Misc"]"
		if(R.subcategory)
			group += " - [R.subcategory]"
		recipes += list(list(
			"kind" = "craft",
			"ref" = info["ref"],
			"name" = R.name,
			"desc" = initial(result.desc),
			"icon" = sheet.icon_class_for(R.result),
			"category" = get_build_category(R.result),
			"group" = group,
			"req_text" = info["req_text"],
			"tool_text" = info["tool_text"],
			"time" = R.get_craft_time(user),
			"placeable" = !!R.is_placeable(),
		))
	return list(
		"categories" = GLOB.build_menu_categories,
		"sources" = static_data["sources"],
		"recipes" = recipes,
	)

/datum/build_menu/ui_data(mob/user)
	var/list/amounts = list()
	var/list/found = gather_stacks()
	for(var/key in found)
		amounts[key] = total_amount(found[key])
	var/list/crafts = list()
	var/datum/component/personal_crafting/crafting = user.GetComponent(/datum/component/personal_crafting)
	if(crafting && length(craft_recipes))
		var/list/surroundings = crafting.get_surroundings(user)
		for(var/datum/crafting_recipe/R as anything in craft_recipes)
			var/has_contents = crafting.check_contents(user, R, surroundings)
			var/has_tools = crafting.check_tools(user, R, surroundings)
			var/missing = ""
			if(!has_contents || !has_tools)
				var/list/reasons = list()
				if(!has_contents)
					reasons += crafting.get_missing_text(R, surroundings)
				if(!has_tools)
					reasons += crafting.get_missing_tool_text(user, R, surroundings)
				reasons -= ""
				missing = length(reasons) ? reasons.Join(", ") : "requirements not met"
			crafts["[REF(R)]"] = list("ok" = has_contents && has_tools, "missing" = missing)
	return list(
		"amounts" = amounts,
		"crafts" = crafts,
		"focus" = focus_key,
		"busy" = busy,
	)

/// Looks up the stacks and the recipe a stack action points at. Returns list(stacks, recipe), or null if either is gone.
/datum/build_menu/proc/resolve_stack_recipe(list/params)
	var/list/stacks = gather_stacks()[params["source"]]
	if(!length(stacks))
		return null
	var/obj/item/stack/primary = stacks[1]
	var/list/flat = primary.get_flat_recipes()
	var/idx = text2num(params["idx"])
	if(!isnum(idx) || idx < 1 || idx > length(flat))
		return null
	var/datum/stack_recipe/R = flat[idx]
	if("[R.result_type]" != params["result"])
		return null
	return list(stacks, R)

/datum/build_menu/ui_act(action, list/params)
	. = ..()
	if(. || busy)
		return
	var/mob/living/L = usr
	if(!istype(L) || L != user)
		return
	busy = TRUE
	try
		switch(action)
			if("build")
				build_action(L, params)
			if("place")
				place_action(L, params)
			if("craft")
				craft_action(L, params)
			if("place_craft")
				place_craft_action(L, params)
	catch(var/exception/e)
		stack_trace("build menu [action] error: [e]")
		to_chat(L, span_warning("Construction failed, something went wrong."))
	busy = FALSE
	return TRUE

/// Builds a stack recipe a number of times from the user's stacks of that material.
/datum/build_menu/proc/build_action(mob/living/L, list/params)
	var/list/resolved = resolve_stack_recipe(params)
	if(!resolved)
		to_chat(L, span_warning("You don't have the materials for that any more."))
		return
	var/list/stacks = resolved[1]
	var/datum/stack_recipe/R = resolved[2]
	var/multiplier = round(text2num(params["multiplier"]) || 1)
	if(multiplier < 1 || !pool_stacks(stacks, R.req_amount * multiplier))
		to_chat(L, span_warning("You haven't got enough to build that!"))
		return
	var/obj/item/stack/primary = stacks[1]
	primary.make_recipe(L, R, multiplier)

/// Starts placement mode for a stack recipe, so the user chooses where it goes.
/datum/build_menu/proc/place_action(mob/living/L, list/params)
	var/list/resolved = resolve_stack_recipe(params)
	if(!resolved)
		to_chat(L, span_warning("You don't have the materials for that any more."))
		return
	var/list/stacks = resolved[1]
	var/datum/stack_recipe/R = resolved[2]
	if(!R.placeable)
		return
	var/obj/item/stack/primary = stacks[1]
	if(!pool_stacks(stacks, R.req_amount))
		to_chat(L, span_warning("You haven't got enough [primary] to build \the [R.title]!"))
		return
	if(!L.is_holding(primary) && !L.put_in_hands(primary, merge_stacks = FALSE))
		to_chat(L, span_warning("You need a free hand to hold \the [primary] while you build."))
		return
	if(primary.start_placement(L, R))
		to_chat(L, span_notice("Placing [R.title]. The builder stays open, and the ghost follows your mouse."))

/// Starts placement mode for a crafting recipe, so the user chooses where it goes.
/datum/build_menu/proc/place_craft_action(mob/living/L, list/params)
	var/datum/crafting_recipe/R = locate(params["ref"]) in GLOB.crafting_recipes
	if(!R || !(R in get_craft_recipes()) || !R.is_placeable())
		to_chat(L, span_warning("That recipe is no longer valid."))
		return
	if(R.start_placement(L))
		to_chat(L, span_notice("Placing [R.name]. The builder stays open, and the ghost follows your mouse."))

/// Crafts one of the structure crafting recipes the builder lists.
/datum/build_menu/proc/craft_action(mob/living/L, list/params)
	var/datum/component/personal_crafting/crafting = L.GetComponent(/datum/component/personal_crafting)
	var/datum/crafting_recipe/R = locate(params["ref"]) in GLOB.crafting_recipes
	if(!crafting || !R || !(R in get_craft_recipes()))
		to_chat(L, span_warning("That recipe is no longer valid."))
		return
	if(crafting.busy)
		return
	crafting.craft_recipe(L, R, FALSE)

/datum/crafting_recipe
	var/name = "" //in-game display name
	var/list/reqs = list() //type paths of items consumed associated with how many are needed
	var/list/blacklist = list() //type paths of items explicitly not allowed as an ingredient
	var/result //type path of item resulting from this craft
	var/list/tools = list() //type paths of items needed but not consumed
	var/time = 30 //time in deciseconds
	var/list/parts = list() //type paths of items that will be placed in the result
	var/list/chem_catalysts = list() //like tools but for reagents
	var/category = CAT_NONE //where it shows up in the crafting UI
	var/subcategory = CAT_NONE
	var/always_available = TRUE //Set to FALSE if it needs to be learned first.
	var/required_int = 0 //Min S.P.E.C.I.A.L. Intelligence required to craft this thing
	/// Opt-in placement rules for structure results, enforced through /datum/buildable
	var/one_per_turf = FALSE
	var/on_floor = FALSE
	var/window_checks = FALSE
	var/placement_checks = FALSE
	/// Lazily built by get_buildable()
	var/datum/buildable/buildable

/datum/crafting_recipe/New()
	if(!(result in reqs))
		blacklist += result

/// Tool behaviours that mean "stand at a bench". Recipes needing one stay in the crafting menu.
GLOBAL_LIST_INIT(crafting_station_tools, list(
	TOOL_WORKBENCH, TOOL_MWORKBENCH, TOOL_ASSWORKBENCH, TOOL_FWORKBENCH, TOOL_AWORKBENCH,
	TOOL_BOTTLER, TOOL_FORGE, TOOL_LOOM, TOOL_CHEMMASTER, TOOL_ALCHEMY_TABLE,
	TOOL_RELOADER, TOOL_MSRELOADER, TOOL_NCR, TOOL_LEGION, TOOL_LUNCHBOX,
	TOOL_GUNTIER1, TOOL_GUNTIER2, TOOL_GUNTIER3, TOOL_GUNTIER4,
))

/**
 * Whether this recipe is listed in the universal builder instead of the crafting menu.
 * Recipes that put down a structure or machine, and need no workbench or other station, move over.
 * This is the one switch for the migration: return FALSE here and everything is back in the crafting menu.
 */
/datum/crafting_recipe/proc/is_builder_recipe()
	if(name == "" || !ispath(result))
		return FALSE
	if(!ispath(result, /obj/structure) && !ispath(result, /obj/machinery))
		return FALSE
	for(var/tool in tools)
		if(tool in GLOB.crafting_station_tools)
			return FALSE
		if(ispath(tool, /obj/machinery))
			return FALSE
	return TRUE

/**
 * Run custom pre-craft checks for this recipe
 *
 * user: The /mob that initiated the crafting
 * collected_requirements: A list of lists of /obj/item instances that satisfy reqs. Top level list is keyed by requirement path.
 */
/datum/crafting_recipe/proc/check_requirements(mob/user, list/collected_requirements)
	if(required_int) //S.P.E.C.I.A.L.
		return special_crafting_requirements_check(user)
	return TRUE

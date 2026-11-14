/* Stack type objects!
 * Contains:
 * 		Stacks
 * 		Recipe datum
 * 		Recipe list datum
 */

/*
 * Stacks
 */
/obj/item/stack
	icon = 'icons/obj/stack_objects.dmi'
	gender = PLURAL
	material_modifier = 0.01
	var/list/datum/stack_recipe/recipes
	var/singular_name
	var/amount = 1
	var/max_amount = 50 //also see stack recipes initialisation, param "max_res_amount" must be equal to this max_amount
	var/is_cyborg = 0 // It's 1 if module is used by a cyborg, and uses its storage
	/// Keeps this material out of the universal builder, for materials only a faith may work
	var/builder_hidden = FALSE
	var/datum/robot_energy_storage/source
	var/cost = 1 // How much energy from storage it costs
	var/merge_type = null // This path and its children should merge with this stack, defaults to src.type
	var/full_w_class = WEIGHT_CLASS_NORMAL //The weight class the stack should have at amount > 2/3rds max_amount
	var/novariants = TRUE //Determines whether the item should update it's sprites based on amount.
	var/list/mats_per_unit //list that tells you how much is in a single unit.
	///Datum material type that this stack is made of
	var/material_type
	max_integrity = 100
	var/latin = 0 // Use weird latin pluralization.
	//NOTE: When adding grind_results, the amounts should be for an INDIVIDUAL ITEM - these amounts will be multiplied by the stack size in on_grind()
	var/obj/structure/table/tableVariant // we tables now (stores table variant to be built from this stack)

		// The following are all for medical treatment, they're here instead of /stack/medical because sticky tape can be used as a makeshift bandage or splint
	/// If set and this used as a splint for a broken bone wound, this is used as a multiplier for applicable slowdowns (lower = better) (also for speeding up burn recoveries)
	var/splint_factor
	/// How much blood flow this stack can absorb if used as a bandage on a cut wound, note that absorption is how much we lower the flow rate, not the raw amount of blood we suck up
	var/absorption_capacity
	/// How quickly we lower the blood flow on a cut wound we're bandaging. Expected lifetime of this bandage in ticks is thus absorption_capacity/absorption_rate, or until the cut heals, whichever comes first
	var/absorption_rate

/obj/item/stack/on_grind()
	for(var/i in 1 to grind_results.len) //This should only call if it's ground, so no need to check if grind_results exists
		grind_results[grind_results[i]] *= get_amount() //Gets the key at position i, then the reagent amount of that key, then multiplies it by stack size

/obj/item/stack/grind_requirements(obj/machinery/reagentgrinder/R, silent)
	if(is_cyborg)
		if(!silent)
			to_chat(usr, span_danger("[src] is electronically synthesized in your chassis and can't be ground up!"))
		return GRIND_IS_CYBORG
	return FALSE

/obj/item/stack/Initialize(mapload, new_amount, merge = TRUE)
	if(new_amount != null)
		amount = new_amount
	while(amount > max_amount)
		amount -= max_amount
		new type(loc, max_amount, FALSE)
	if(!merge_type)
		merge_type = type
	if(custom_materials && custom_materials.len)
		mats_per_unit = list()
		var/in_process_mat_list = custom_materials.Copy()
		for(var/i in custom_materials)
			mats_per_unit[SSmaterials.GetMaterialRef(i)] = in_process_mat_list[i]
			custom_materials[i] *= amount
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_movable_entered_occupied_turf),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

	if(merge)
		for(var/obj/item/stack/item_stack in loc)
			if(item_stack == src)
				continue
			if(can_merge(item_stack))
				INVOKE_ASYNC(src, PROC_REF(merge_without_del), item_stack)
				if(zero_amount())
					return INITIALIZE_HINT_QDEL
	var/list/temp_recipes = get_main_recipes()
	recipes = temp_recipes.Copy()
	if(material_type)
		var/datum/material/M = SSmaterials.GetMaterialRef(material_type) //First/main material
		for(var/i in M.categories)
			switch(i)
				if(MAT_CATEGORY_BASE_RECIPES)
					var/list/temp = SSmaterials.rigid_stack_recipes.Copy()
					recipes += temp
	update_weight()
	update_icon()

/obj/item/stack/proc/get_main_recipes()
	return list()//empty list

/obj/item/stack/proc/update_weight()
	if(amount <= (max_amount * (1/3)))
		w_class = clamp(full_w_class-2, WEIGHT_CLASS_TINY, full_w_class)
	else if (amount <= (max_amount * (2/3)))
		w_class = clamp(full_w_class-1, WEIGHT_CLASS_TINY, full_w_class)
	else
		w_class = full_w_class

/obj/item/stack/update_icon_state()
	if(novariants)
		return
	if(amount <= (max_amount * (1/3)))
		icon_state = initial(icon_state)
	else if (amount <= (max_amount * (2/3)))
		icon_state = "[initial(icon_state)]_2"
	else
		icon_state = "[initial(icon_state)]_3"


/obj/item/stack/Destroy()
	if (usr && usr.machine==src)
		usr << browse(null, "window=stack")
	. = ..()

/obj/item/stack/examine(mob/user)
	. = ..()
	if (is_cyborg)
		if(singular_name)
			. += "There is enough energy for [get_amount()] [singular_name]\s."
		else
			. += "There is enough energy for [get_amount()]."
		return
	if(singular_name)
		if (latin)
			if(get_amount()>1)
				to_chat(user, "There are [get_amount()] [singular_name]i in the stack.")
			else
				to_chat(user, "There is [get_amount()] [singular_name]us in the stack.")
		else
			if(get_amount()>1)
				to_chat(user, "There are [get_amount()] [singular_name]\s in the stack.")
			else
				to_chat(user, "There is [get_amount()] [singular_name] in the stack.")
		if(get_amount()>1)
			. += "There are [get_amount()] [singular_name]\s in the stack."
		else
			. += "There is [get_amount()] [singular_name] in the stack."
	else if(get_amount()>1)
		. += "There are [get_amount()] in the stack."
	else
		. += "There is [get_amount()] in the stack."
	. += span_notice("Alt-click to take a custom amount.")

/obj/item/stack/proc/get_amount()
	if(is_cyborg)
		. = source ? round(source.energy / cost) : 0
	else
		. = (amount)

/obj/item/stack/attack_self(mob/user)
	interact(user)

/// Opens the universal builder, focused on this stack's recipes.
/obj/item/stack/interact(mob/user)
	if(!length(recipes))
		return
	open_build_menu(user, src)

/obj/item/stack/Topic(href, href_list)
	..()
	if (usr.restrained() || usr.stat || usr.get_active_held_item() != src)
		return
	if (href_list["place"])
		var/list/place_list = recipes
		if (href_list["sublist"])
			var/datum/stack_recipe_list/place_srl = place_list[text2num(href_list["sublist"])]
			place_list = place_srl.recipes
		var/datum/stack_recipe/placed_recipe = place_list[text2num(href_list["place"])]
		if(istype(placed_recipe) && start_placement(usr, placed_recipe))
			usr << browse(null, "window=stack")
		return
	if (href_list["make"])
		if (get_amount() < 1 && !is_cyborg)
			qdel(src)

		var/list/recipes_list = recipes
		if (href_list["sublist"])
			var/datum/stack_recipe_list/srl = recipes_list[text2num(href_list["sublist"])]
			recipes_list = srl.recipes
		var/datum/stack_recipe/R = recipes_list[text2num(href_list["make"])]
		make_recipe(usr, R, round(text2num(href_list["multiplier"])))

/// Builds recipe R multiplier times from this stack, for user. The legacy make link and the build menu both come through here.
/obj/item/stack/proc/make_recipe(mob/user, datum/stack_recipe/R, multiplier)
	if(!istype(R) || !istype(user))
		return
		
	// Validate multiplier is in acceptable range
	var/max_multiplier = round(get_amount() / R.req_amount)
	if(R.max_res_amount > 1)
		max_multiplier = min(max_multiplier, round(R.max_res_amount / R.res_amount))
		
	if(!multiplier || multiplier < 1 || multiplier > max_multiplier || !IS_FINITE(multiplier))
		log_admin("[key_name(user)] attempted stack exploit with invalid multiplier: [multiplier] (max: [max_multiplier])")
		return
	if(!building_checks(R, multiplier, user))
		return
	if (R.time)
		var/adjusted_time = 0
		user.visible_message(span_notice("[user] starts building [R.title]."), span_notice("You start building [R.title]..."))
		if(R.trait_booster && HAS_TRAIT(user, R.trait_booster))
			adjusted_time = (R.time * R.trait_modifier)
		else
			adjusted_time = R.time
		// Building several at once takes as long as building each in turn
		adjusted_time *= multiplier
		if (!do_after(user, adjusted_time, target = user))
			return
		if(!building_checks(R, multiplier, user))
			return

	// Placeable recipes build through the same code as placement mode so the two can't drift apart
	if(R.placeable && multiplier == 1)
		R.get_buildable().build_from_stack(user, src, get_turf(user), user.dir)
		return

	var/obj/O
	if(R.max_res_amount > 1) //Is it a stack?
		if(R.is_stack)
			O = new R.result_type(user.drop_location(), R.res_amount * multiplier)
		else
			for(var/i in 1 to multiplier)
				O = new R.result_type(get_turf(user))
	else if(ispath(R.result_type, /turf))
		var/turf/T = user.drop_location()
		if(!isturf(T))
			return
		T.PlaceOnTop(R.result_type, flags = CHANGETURF_INHERIT_AIR)
	else
		O = new R.result_type(get_turf(user))
	if(O)
		O.set_build_dir(user.dir)
		log_craft("[O] crafted by [user] at [loc_name(O.loc)]")

	use(R.req_amount * multiplier)

	if(O && R.applies_mats && custom_materials && custom_materials.len)
		var/list/used_materials = list()
		for(var/i in custom_materials)
			used_materials[SSmaterials.GetMaterialRef(i)] = R.req_amount / R.res_amount * (MINERAL_MATERIAL_AMOUNT / custom_materials.len)
		O.set_custom_materials(used_materials)

	if(istype(O, /obj/item/restraints/handcuffs/cable))
		var/obj/item/cuffs = O
		cuffs.color = color

	if (QDELETED(O))
		return //It's a stack and has already been merged

	if (isitem(O))
		user.put_in_hands(O)
	O.add_fingerprint(user)

	//BubbleWrap - so newly formed boxes are empty
	if ( istype(O, /obj/item/storage) )
		for (var/obj/item/I in O)
			qdel(I)
	//BubbleWrap END

/obj/item/stack/proc/building_checks(datum/stack_recipe/R, multiplier, mob/user = usr)
	if (get_amount() < R.req_amount*multiplier)
		if (R.req_amount*multiplier>1)
			to_chat(user, span_warning("You haven't got enough [src] to build \the [R.req_amount*multiplier] [R.title]\s!"))
		else
			to_chat(user, span_warning("You haven't got enough [src] to build \the [R.title]!"))
		return FALSE
	return R.get_buildable().check_placement(user, get_turf(user), user.dir)

/obj/item/stack/use(used, transfer = FALSE, check = TRUE) // return 0 = borked; return 1 = had enough
	if(check && zero_amount())
		return FALSE
	if (is_cyborg)
		return source.use_charge(used * cost)
	if (amount < used)
		return FALSE
	amount -= used
	if(check && zero_amount())
		return TRUE
	if(length(mats_per_unit))
		var/temp_materials = custom_materials.Copy()
		for(var/i in mats_per_unit)
			temp_materials[i] = mats_per_unit[i] * src.amount
		set_custom_materials(temp_materials)
	update_icon()
	update_weight()
	return TRUE

/obj/item/stack/tool_use_check(mob/living/user, amount)
	if(get_amount() < amount)
		if(singular_name)
			if(amount > 1)
				to_chat(user, span_warning("You need at least [amount] [singular_name]\s to do this!"))
			else
				to_chat(user, span_warning("You need at least [amount] [singular_name] to do this!"))
		else
			to_chat(user, span_warning("You need at least [amount] to do this!"))

		return FALSE

	return TRUE

/obj/item/stack/proc/zero_amount()
	if(is_cyborg)
		return source.energy < cost
	if(amount < 1)
		qdel(src)
		return 1
	return 0

/obj/item/stack/proc/add(amount)
	if (is_cyborg)
		source.add_charge(amount * cost)
	else
		src.amount += amount
	if(length(mats_per_unit))
		var/temp_materials = custom_materials.Copy()
		for(var/i in mats_per_unit)
			temp_materials[i] = mats_per_unit[i] * src.amount
		set_custom_materials(temp_materials)
	update_icon()
	update_weight()

/** Checks whether this stack can merge itself into another stack.
 *
 * Arguments:
 * - [check][/obj/item/stack]: The stack to check for mergeability.
 * - [inhand][boolean]: Whether or not the stack to check should act like it's in a mob's hand.
 */
/obj/item/stack/proc/can_merge(obj/item/stack/check, inhand = FALSE)
	if(!istype(check))
		return FALSE
	if(check.merge_type != merge_type)
		return FALSE
	if(mats_per_unit ~! check.mats_per_unit) // ~! in case of lists this operator checks only keys, but not values
		return FALSE
	if(is_cyborg) // No merging cyborg stacks into other stacks
		return FALSE
	if(ismob(loc) && !inhand) // no merging with items that are on the mob
		return FALSE
	return TRUE

/**
 * Merges as much of src into target_stack as possible. If present, the limit arg overrides target_stack.max_amount for transfer.
 *
 * This calls use() without check = FALSE, preventing the item from qdeling itself if it reaches 0 stack size.
 *
 * As a result, this proc can leave behind a 0 amount stack.
 */
/obj/item/stack/proc/merge_without_del(obj/item/stack/target_stack, limit)
	// Cover edge cases where multiple stacks are being merged together and haven't been deleted properly.
	// Also cover edge case where a stack is being merged into itself, which is supposedly possible.
	if(!target_stack)
		// Target stack is null - cannot merge into it, return early
		return 0
	if(QDELETED(target_stack))
		// Target stack is queued for deletion - cannot merge into it, return early
		return 0
	if(QDELETED(src))
		// Source stack is queued for deletion - cannot merge from it, return early
		return 0
	if(target_stack == src)
		// Cannot merge a stack into itself
		return 0

	var/transfer = get_amount()
	if(target_stack.is_cyborg)
		transfer = min(transfer, round((target_stack.source.max_energy - target_stack.source.energy) / target_stack.cost))
	else
		transfer = min(transfer, (limit ? limit : target_stack.max_amount) - target_stack.amount)
	if(pulledby)
		INVOKE_ASYNC(pulledby, TYPE_PROC_REF(/atom/movable, start_pulling), target_stack)
	target_stack.copy_evidences(src)
	use(transfer, transfer = TRUE, check = FALSE)
	target_stack.add(transfer)
	if(target_stack.mats_per_unit != mats_per_unit && target_stack.amount > 0) // We get the average value of mats_per_unit between two stacks getting merged
		var/list/temp_mats_list = list() // mats_per_unit is passed by ref into this coil, and that same ref is used in other places. If we didn't make a new list here we'd end up contaminating those other places, which leads to batshit behavior
		for(var/mat_type in target_stack.mats_per_unit)
			temp_mats_list[mat_type] = (target_stack.mats_per_unit[mat_type] * (target_stack.amount - transfer) + mats_per_unit[mat_type] * transfer) / target_stack.amount
		target_stack.mats_per_unit = temp_mats_list
	return transfer

/obj/item/stack/proc/merge(obj/item/stack/target_stack, limit)
	. = merge_without_del(target_stack, limit)
	zero_amount()

/// Signal handler for connect_loc element. Called when a movable enters the turf we're currently occupying. Merges if possible.
/obj/item/stack/proc/on_movable_entered_occupied_turf(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER

	// Edge case. This signal will also be sent when src has entered the turf. Don't want to merge with ourselves.
	if(arrived == src)
		return

	if(!arrived.throwing && can_merge(arrived))
		INVOKE_ASYNC(src, PROC_REF(merge), arrived)

/obj/item/stack/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(can_merge(AM, TRUE))
		merge(AM)
	. = ..()

/obj/item/stack/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(user.get_inactive_held_item() == src)
		if(zero_amount())
			return
		return change_stack(user,1)
	else
		. = ..()

/obj/item/stack/AltClick(mob/living/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	if(is_cyborg)
		return
	else
		if(zero_amount())
			return
		//get amount from user
		var/max = get_amount()
		var/stackmaterial = round(input(user,"How many sheets do you wish to take out of this stack? (Maximum  [max])") as null|num)
		max = get_amount()
		stackmaterial = min(max, stackmaterial)
		if(stackmaterial == null || stackmaterial <= 0 || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
			return TRUE
		else
			change_stack(user, stackmaterial)
			to_chat(user, span_notice("You take [stackmaterial] sheets out of the stack"))
		return TRUE

/obj/item/stack/proc/change_stack(mob/user, amount)
	if(!use(amount, TRUE, FALSE))
		return FALSE
	var/obj/item/stack/F = new type(user? user : drop_location(), amount, FALSE)
	. = F
	F.copy_evidences(src)
	if(user)
		if(!user.put_in_hands(F, merge_stacks = FALSE))
			F.forceMove(user.drop_location())
		add_fingerprint(user)
		F.add_fingerprint(user)
	zero_amount()

/obj/item/stack/attackby(obj/item/W, mob/user, params)
	if(can_merge(W, TRUE))
		var/obj/item/stack/S = W
		if(merge(S))
			to_chat(user, span_notice("Your [S.name] stack now contains [S.get_amount()] [S.singular_name]\s."))
	else
		. = ..()

/obj/item/stack/proc/copy_evidences(obj/item/stack/from)
	if(from.blood_DNA)
		blood_DNA = from.blood_DNA.Copy()
	if(from.fingerprints)
		fingerprints = from.fingerprints.Copy()
	if(from.fingerprintshidden)
		fingerprintshidden = from.fingerprintshidden.Copy()
	if(from.fingerprintslast)
		fingerprintslast = from.fingerprintslast

/obj/item/stack/microwave_act(obj/machinery/microwave/M)
	if(istype(M) && M.dirty < 100)
		M.dirty += amount

/*
 * Recipe datum
 */
/datum/stack_recipe
	var/title = "ERROR"
	var/result_type
	var/req_amount = 1
	var/res_amount = 1
	var/max_res_amount = 1
	var/time = 0
	var/one_per_turf = FALSE
	var/on_floor = FALSE
	var/window_checks = FALSE
	var/placement_checks = FALSE
	var/applies_mats = FALSE
	var/trait_booster = null
	var/trait_modifier = 1
	/// Is the resulting thing made from this a stack? if so, multi-crafting will make a stack with multiple 'uses' of it. if not, multi-crafting makes several separate items of it
	var/is_stack = TRUE
	/// Lazily built by get_buildable(); holds the shared placement rules
	var/datum/buildable/buildable
	/// Offers placement mode (ghost preview, build on a nearby tile). Only for single structures built with no custom materials.
	/// Left null, it is on for any such structure that must be built on a floor and is limited to one per tile (or checked as a window); pass FALSE to opt out.
	var/placeable = null
	/// Placement mode lets the builder rotate the result. Left null, it follows placeable (fulltile windows never rotate); pass FALSE for things whose facing is meaningless.
	var/rotatable = FALSE

/datum/stack_recipe/New(title, result_type, req_amount = 1, res_amount = 1, max_res_amount = 1,time = 0, one_per_turf = FALSE, on_floor = FALSE, window_checks = FALSE, placement_checks = FALSE, applies_mats = FALSE, trait_booster = null, trait_modifier = 1, is_stack = TRUE, placeable = null, rotatable = null)


	src.title = title
	src.result_type = result_type
	src.req_amount = req_amount
	src.res_amount = res_amount
	src.max_res_amount = max_res_amount
	src.one_per_turf = one_per_turf
	src.on_floor = on_floor
	src.window_checks = window_checks
	src.placement_checks = placement_checks
	src.applies_mats = applies_mats
	src.trait_booster = trait_booster
	src.trait_modifier = trait_modifier
	src.is_stack = is_stack
	// Putting something up is never instant, so nobody can spam it, and builders are always quicker at it
	if(ispath(result_type, /obj/structure) || ispath(result_type, /obj/machinery) || ispath(result_type, /turf))
		time = max(time, clamp(10 + 5 * req_amount, BUILD_MIN_TIME, BUILD_MAX_MIN_TIME))
		if(!src.trait_booster && trait_modifier == 1)
			src.trait_booster = TRAIT_QUICK_BUILD
			src.trait_modifier = BUILD_QUICK_MODIFIER
	src.time = time
	if(isnull(placeable))
		placeable = (ispath(result_type, /obj/structure) || ispath(result_type, /obj/machinery)) && res_amount == 1 && max_res_amount == 1 && (on_floor || window_checks)
	src.placeable = placeable
	if(isnull(rotatable))
		rotatable = placeable && !ispath(result_type, /obj/machinery)
	src.rotatable = rotatable
/*
 * Recipe list datum
 */
/datum/stack_recipe_list
	var/title = "ERROR"
	var/list/recipes

/datum/stack_recipe_list/New(title, recipes)
	src.title = title
	src.recipes = recipes

/**
 * A list of recipes for a kind of tile and every kind of tile under it, so each look can be chosen.
 * All cost the same. Tiles that share the base tile's name are told apart by where they sit in the type tree.
 * extra: more tile types to list that aren't under base.
 */
/proc/tile_variant_recipes(obj/item/stack/tile/base, req_amount = 1, res_amount = 4, max_res_amount = 20, list/extra)
	var/list/recipes = list()
	var/base_name = initial(base.name)
	var/base_text = "[base]"
	for(var/obj/item/stack/tile/variant as anything in typesof(base) + extra)
		if(!initial(variant.turf_type))
			continue
		var/variant_text = "[variant]"
		var/variant_name = initial(variant.name)
		if(variant_name == base_name && variant != base)
			var/suffix = ispath(variant, base) ? copytext(variant_text, length(base_text) + 2) : copytext(variant_text, findlasttext(variant_text, "/") + 1)
			variant_name = "[base_name] ([replacetext(replacetext(suffix, "/", " "), "_", " ")])"
		recipes += new /datum/stack_recipe(variant_name, variant, req_amount, res_amount, max_res_amount)
	return recipes

// TAVERN SYSTEM - Bartending RP mechanics
// Adds: drink menu, tipping, tabs, and drink serving

// ============================================
// DRINK MENU BOARD
// ============================================

/obj/structure/drink_menu
	name = "drink menu"
	desc = "A chalkboard listing the house specialties."
	icon = 'icons/obj/structures.dmi'
	icon_state = "noticeboard0"
	density = FALSE
	anchored = TRUE
	var/list/menu_items = list(
		"Nuka-Cola" = 5,
		"Sunset Sarsaparilla" = 5,
		"Beer" = 3,
		"Ale" = 4,
		"Whiskey" = 8,
		"Vodka" = 8,
		"Rum" = 7,
		"Moonshine" = 12,
		"Rotgut" = 15,
		"Nuka-Cola Dark" = 10,
		"Dirty Wastelander" = 12,
		"Battle Brew" = 15,
		"Atom Bomb" = 20,
		"Wasteland Tequila" = 10,
		"Iced Nuka" = 6,
	)
	var/owner_name = ""

/obj/structure/drink_menu/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	show_menu(user)

/obj/structure/drink_menu/proc/show_menu(mob/user)
	var/html = "<center><h2>[name]</h2>"
	if(owner_name)
		html += "<i>Proprietor: [owner_name]</i><br>"
	html += "<hr>"
	html += "<table width='100%'>"
	html += "<tr><th>Drink</th><th>Price (caps)</th></tr>"
	for(var/drink in menu_items)
		html += "<tr><td>[drink]</td><td>[menu_items[drink]]</td></tr>"
	html += "</table>"
	html += "<hr><i>Tip your barkeep!</i></center>"
	var/datum/browser/popup = new(user, "drink_menu_[REF(src)]", "Drink Menu", 300, 400)
	popup.set_content(html)
	popup.open()

/obj/structure/drink_menu/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/pen))
		var/choice = input(user, "Menu options:", "Drink Menu") as null|anything in list("Add drink", "Remove drink", "Set owner")
		if(!choice)
			return
		if(choice == "Add drink")
			var/drink_name = stripped_input(user, "Drink name:", "Add Drink")
			if(!drink_name)
				return
			var/price = input(user, "Price in caps:", "Add Drink", 5) as num|null
			if(isnull(price) || price < 0)
				return
			menu_items[drink_name] = price
			to_chat(user, span_notice("Added [drink_name] for [price] caps."))
		else if(choice == "Remove drink")
			var/to_remove = input(user, "Remove which drink?", "Remove Drink") as null|anything in menu_items
			if(!to_remove)
				return
			menu_items -= to_remove
			to_chat(user, span_notice("Removed [to_remove] from the menu."))
		else if(choice == "Set owner")
			owner_name = stripped_input(user, "Owner name:", "Set Owner", owner_name)
		return
	return ..()

// ============================================
// TIP JAR
// ============================================

/obj/item/storage/drink_tip_jar
	name = "tip jar"
	desc = "A jar for generous patrons to show their appreciation."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "glass_brown"
	w_class = WEIGHT_CLASS_SMALL
	var/total_tips = 0

/obj/item/storage/drink_tip_jar/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/f13Cash/caps))
		var/obj/item/stack/f13Cash/caps/C = I
		var/amount = min(C.amount, 50)
		if(amount <= 0)
			return
		C.use(amount)
		total_tips += amount
		visible_message(span_notice("[user] drops [amount] cap[amount > 1 ? "s" : ""] into the tip jar!"))
		return
	return ..()

/obj/item/storage/drink_tip_jar/attack_hand(mob/user)
	if(user.a_intent == INTENT_HELP && !user.get_active_held_item())
		to_chat(user, span_notice("The tip jar has collected [total_tips] caps."))
		return
	return ..()

/obj/item/storage/drink_tip_jar/AltClick(mob/user)
	if(total_tips <= 0)
		to_chat(user, span_notice("The tip jar is empty."))
		return
	var/obj/item/stack/f13Cash/caps/C = new(get_turf(user), total_tips)
	if(user.put_in_hands(C))
		to_chat(user, span_notice("You collect [total_tips] caps from the tip jar."))
	else
		to_chat(user, span_notice("[total_tips] caps fall from the tip jar."))
	total_tips = 0

// ============================================
// BAR TAB SYSTEM
// ============================================

/datum/bar_tab
	var/customer_name
	var/customer_ref
	var/amount_owed = 0
	var/tab_items = list()
	var/tab_start_time = 0
	var/bar_name = "The Bar"
	var/tab_timeout = 30 MINUTES

/datum/bar_tab/New(customer, bar)
	customer_name = customer
	bar_name = bar
	tab_start_time = world.time

/datum/bar_tab/proc/add_charge(item_name, amount)
	amount_owed += amount
	tab_items += "[item_name]: [amount] caps"

/datum/bar_tab/proc/get_total()
	return amount_owed

/datum/bar_tab/proc/settle(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	var/total = get_total()
	if(total <= 0)
		return TRUE
	var/caps_available = find_caps_on_mob(H)
	if(caps_available < total)
		to_chat(H, span_warning("You can't afford the [total] cap tab!"))
		return FALSE
	remove_caps_from_mob(H, total)
	to_chat(H, span_notice("You settle your [total] cap tab at [bar_name]."))
	return TRUE

// ============================================
// BAR TAB TRACKER (global per-bar)
// ============================================

/obj/structure/bar_tab_tracker
	name = "bar register"
	desc = "The bar's register for tracking tabs and payments."
	icon = 'icons/obj/vending.dmi'
	icon_state = "fridge_dark"
	density = TRUE
	anchored = TRUE
	var/list/datum/bar_tab/tabs = list()
	var/bar_name = "The Tavern"

/obj/structure/bar_tab_tracker/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	show_tabs(user)

/obj/structure/bar_tab_tracker/proc/show_tabs(mob/user)
	cleanup_expired_tabs()
	var/html = "<center><h2>[bar_name] - Register</h2><hr>"
	html += "<table width='100%'>"
	html += "<tr><th>Customer</th><th>Tab</th><th>Actions</th></tr>"
	for(var/datum/bar_tab/T in tabs)
		html += "<tr><td>[T.customer_name]</td><td>[T.amount_owed] caps</td>"
		html += "<td><a href='byond://?src=[REF(src)];settle=[REF(T)]'>Settle</a> | <a href='byond://?src=[REF(src)];clear=[REF(T)]'>Clear</a></td></tr>"
	html += "</table></center>"
	var/datum/browser/popup = new(user, "bar_register_[REF(src)]", "[bar_name] Register", 400, 400)
	popup.set_content(html)
	popup.open()

/obj/structure/bar_tab_tracker/Topic(href, href_list)
	if(href_list["settle"])
		var/datum/bar_tab/T = locate(href_list["settle"])
		if(T && (T in tabs))
			T.settle(usr)
			if(T.amount_owed <= 0)
				tabs -= T
	if(href_list["clear"])
		var/datum/bar_tab/T = locate(href_list["clear"])
		if(T && (T in tabs))
			tabs -= T
	. = ..()

/obj/structure/bar_tab_tracker/proc/get_or_create_tab(mob/living/carbon/human/H)
	for(var/datum/bar_tab/T in tabs)
		if(T.customer_ref == REF(H))
			return T
	var/datum/bar_tab/new_tab = new(H.real_name, bar_name)
	new_tab.customer_ref = REF(H)
	tabs += new_tab
	return new_tab

/obj/structure/bar_tab_tracker/proc/charge_customer(mob/living/carbon/human/H, item_name, amount)
	var/datum/bar_tab/T = get_or_create_tab(H)
	T.add_charge(item_name, amount)
	to_chat(H, span_notice("[item_name] added to your tab. You owe [T.amount_owed] caps at [bar_name]."))

/obj/structure/bar_tab_tracker/proc/cleanup_expired_tabs()
	for(var/datum/bar_tab/T in tabs)
		if((world.time - T.tab_start_time) > T.tab_timeout)
			tabs -= T

/proc/find_caps_on_mob(mob/living/carbon/human/H)
	var/total = 0
	for(var/obj/item/stack/f13Cash/caps/C in H.contents)
		total += C.amount
	for(var/obj/item/storage/S in H.contents)
		for(var/obj/item/stack/f13Cash/caps/C in S.contents)
			total += C.amount
	return total

/proc/remove_caps_from_mob(mob/living/carbon/human/H, amount)
	if(!H || amount <= 0)
		return FALSE
	var/remaining = amount
	for(var/obj/item/stack/f13Cash/caps/C in H.contents)
		if(remaining <= 0)
			break
		var/take = min(C.amount, remaining)
		C.use(take)
		remaining -= take
	for(var/obj/item/storage/S in H.contents)
		if(remaining <= 0)
			break
		for(var/obj/item/stack/f13Cash/caps/C in S.contents)
			if(remaining <= 0)
				break
			var/take = min(C.amount, remaining)
			C.use(take)
			remaining -= take
	return remaining <= 0

/proc/find_first_caps_stack(mob/living/carbon/human/H)
	for(var/obj/item/stack/f13Cash/caps/C in H.contents)
		return C
	for(var/obj/item/storage/S in H.contents)
		for(var/obj/item/stack/f13Cash/caps/C in S.contents)
			return C
	return null
// ============================================

/mob/living/carbon/human/verb/serve_drink()
	set name = "Serve Drink"
	set desc = "Serve a drink to someone and charge them"
	set category = "IC"

	if(stat != CONSCIOUS)
		return

	var/obj/item/reagent_containers/food/drinks/drink = get_active_held_item()
	if(!istype(drink))
		to_chat(src, span_warning("You need to hold a drink to serve!"))
		return

	var/list/nearby_people = list()
	for(var/mob/living/carbon/human/H in view(1, src))
		if(H == src || H.stat == DEAD)
			continue
		nearby_people += H

	if(!nearby_people.len)
		to_chat(src, span_warning("No one nearby to serve!"))
		return

	var/mob/living/carbon/human/customer = input(src, "Serve to whom?", "Serve Drink") as null|anything in nearby_people
	if(!customer || !Adjacent(customer))
		return

	var/price = input(src, "How many caps?", "Serve Drink", 5) as num|null
	if(isnull(price) || price < 0)
		return

	var/choice = alert(customer, "[src] offers you [drink.name] for [price] caps. Accept?", "Drink Offer", "Yes", "No")
	if(choice != "Yes")
		to_chat(src, span_warning("[customer] declined the drink."))
		return

	// Try to charge
	if(price > 0)
		var/caps_available = find_caps_on_mob(customer)
		if(caps_available < price)
			// Offer to put on tab
			var/tab_choice = alert(customer, "You don't have enough caps. Put [price] caps on your tab?", "Tab", "Yes", "No")
			if(tab_choice == "Yes")
				var/obj/structure/bar_tab_tracker/tracker = locate() in range(5, src)
				if(tracker)
					tracker.charge_customer(customer, drink.name, price)
				else
					to_chat(customer, span_warning("No bar register nearby to track your tab."))
					return
			else
				return
		else
			remove_caps_from_mob(customer, price)
			var/obj/item/stack/f13Cash/caps/payment = new(get_turf(src), price)
			put_in_hands(payment)
			to_chat(src, span_notice("[customer] pays [price] caps for [drink.name]."))

	// Transfer the drink
	if(!drink || !customer.put_in_hands(drink))
		to_chat(src, span_warning("Failed to serve the drink."))
		return

	visible_message(span_notice("[src] serves [customer] [drink.name]."))

	// Karma for serving
	if(ckey)
		adjust_karma(ckey, 2)
	if(customer.ckey)
		adjust_karma(customer.ckey, 1)

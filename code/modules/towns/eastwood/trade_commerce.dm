// Eastwood Trade & Commerce
// Market system, vendors, and trade relations

// ============ MARKET DATUM ============

/datum/eastwood_market
	var/list/registered_vendors = list()
	var/list/market_stalls = list()
	var/tax_collected = 0
	var/list/trade_agreements = list()
	var/market_open = TRUE

/datum/eastwood_market/proc/register_vendor(mob/user, vendor_type)
	if(!GLOB.eastwood_council.is_citizen(user.ckey))
		return FALSE

	for(var/datum/market_vendor/V in registered_vendors)
		if(V.owner_ckey == user.ckey)
			return FALSE

	var/datum/market_vendor/vendor = new()
	vendor.owner_ckey = user.ckey
	vendor.owner_name = user.name
	vendor.vendor_type = vendor_type
	vendor.registration_date = world.time

	switch(vendor_type)
		if("general")
			vendor.permit_fee = VENDOR_PERMIT_FEE
		if("weapons")
			vendor.permit_fee = WEAPONS_PERMIT_FEE
		if("medical")
			vendor.permit_fee = MEDICAL_LICENSE_FEE
		else
			vendor.permit_fee = VENDOR_PERMIT_FEE

	registered_vendors += vendor
	return TRUE

/datum/eastwood_market/proc/remove_vendor(target_ckey)
	for(var/datum/market_vendor/V in registered_vendors)
		if(V.owner_ckey == target_ckey)
			registered_vendors -= V
			qdel(V)
			return TRUE
	return FALSE

/datum/eastwood_market/proc/rent_stall(mob/user, stall_id)
	if(!GLOB.eastwood_council.is_citizen(user.ckey))
		return FALSE

	var/datum/market_vendor/vendor = get_vendor(user.ckey)
	if(!vendor)
		return FALSE

	for(var/datum/market_stall/S in market_stalls)
		if(S.stall_id == stall_id)
			if(S.rented_by)
				return FALSE
			S.rented_by = user.ckey
			S.rent_expiry = world.time + (24 * 60 * 10)
			return TRUE

	return FALSE

/datum/eastwood_market/proc/get_vendor(ckey)
	for(var/datum/market_vendor/V in registered_vendors)
		if(V.owner_ckey == ckey)
			return V
	return null

/datum/eastwood_market/proc/collect_tax(amount)
	var/tax = round(amount * MARKET_TAX_RATE)
	tax_collected += tax
	return tax

/datum/eastwood_market/proc/create_trade_agreement(faction, terms)
	var/datum/trade_agreement/agreement = new()
	agreement.faction = faction
	agreement.terms = terms
	agreement.created_date = world.time

	trade_agreements += agreement
	return TRUE

/datum/eastwood_market/proc/get_faction_trade_bonus(faction)
	for(var/datum/trade_agreement/A in trade_agreements)
		if(A.faction == faction)
			return A.trade_bonus
	return 0

// ============ MARKET VENDOR ============

/datum/market_vendor
	var/owner_ckey
	var/owner_name
	var/vendor_type
	var/registration_date
	var/permit_fee = 0
	var/permit_paid = FALSE
	var/total_sales = 0
	var/total_taxes_paid = 0

// ============ MARKET STALL ============

/datum/market_stall
	var/stall_id
	var/rented_by
	var/rent_expiry
	var/daily_rate = STALL_RENT_DAILY

// ============ TRADE AGREEMENT ============

/datum/trade_agreement
	var/faction
	var/terms
	var/created_date
	var/trade_bonus = 0.1
	var/active = TRUE

// ============ MARKET TERMINAL ============

/obj/machinery/computer/eastwood_market
	name = "Eastwood Market Terminal"
	desc = "A terminal for market registration and vendor management."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/eastwood_market/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/eastwood_market/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EastwoodMarket")
		ui.open()

/obj/machinery/computer/eastwood_market/ui_data(mob/user)
	var/list/data = list()

	data["is_citizen"] = GLOB.eastwood_council.is_citizen(user.ckey)
	data["market_open"] = GLOB.eastwood_market.market_open
	data["tax_rate"] = MARKET_TAX_RATE
	data["tax_collected"] = GLOB.eastwood_market.tax_collected

	var/datum/market_vendor/vendor = GLOB.eastwood_market.get_vendor(user.ckey)
	if(vendor)
		data["is_vendor"] = TRUE
		data["vendor_type"] = vendor.vendor_type
		data["permit_paid"] = vendor.permit_paid
		data["permit_fee"] = vendor.permit_fee
		data["total_sales"] = vendor.total_sales
	else
		data["is_vendor"] = FALSE

	var/list/vendors_data = list()
	for(var/datum/market_vendor/V in GLOB.eastwood_market.registered_vendors)
		vendors_data += list(list("owner" = V.owner_name, "type" = V.vendor_type, "paid" = V.permit_paid))
	data["vendors"] = vendors_data

	var/list/stalls_data = list()
	for(var/datum/market_stall/S in GLOB.eastwood_market.market_stalls)
		stalls_data += list(list("id" = S.stall_id, "rented" = (S.rented_by ? TRUE : FALSE), "daily_rate" = S.daily_rate))
	data["stalls"] = stalls_data

	var/list/agreements_data = list()
	for(var/datum/trade_agreement/A in GLOB.eastwood_market.trade_agreements)
		agreements_data += list(list("faction" = A.faction, "active" = A.active, "bonus" = A.trade_bonus))
	data["trade_agreements"] = agreements_data

	return data

/obj/machinery/computer/eastwood_market/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("register_vendor")
			var/vendor_type = params["vendor_type"]
			if(GLOB.eastwood_market.register_vendor(usr, vendor_type))
				to_chat(usr, span_notice("You have registered as a [vendor_type] vendor."))
			else
				to_chat(usr, span_warning("Cannot register. Check requirements."))
			return TRUE

		if("pay_permit")
			var/datum/market_vendor/vendor = GLOB.eastwood_market.get_vendor(usr.ckey)
			if(vendor && !vendor.permit_paid)
				vendor.permit_paid = TRUE
				to_chat(usr, span_notice("Permit fee paid. You may now operate."))
			return TRUE

		if("rent_stall")
			var/stall_id = params["stall_id"]
			if(GLOB.eastwood_market.rent_stall(usr, stall_id))
				to_chat(usr, span_notice("Stall rented for 1 day."))
			else
				to_chat(usr, span_warning("Cannot rent stall."))
			return TRUE

		if("toggle_market")
			if(GLOB.eastwood_council.is_council_member(usr.ckey))
				GLOB.eastwood_market.market_open = !GLOB.eastwood_market.market_open
				to_chat(usr, span_notice("Market is now [GLOB.eastwood_market.market_open ? "open" : "closed"]."))
			return TRUE

	return FALSE

// ============ VENDOR STALL ============

/obj/structure/vendor_stall
	name = "Market Stall"
	desc = "A stall for selling goods."
	icon = 'icons/obj/structures.dmi'
	icon_state = "market_stall"
	density = TRUE
	anchored = TRUE

	var/stall_id = "stall_1"
	var/owner_ckey = null

/obj/structure/vendor_stall/Initialize(mapload)
	. = ..()
	var/datum/market_stall/stall = new()
	stall.stall_id = stall_id
	GLOB.eastwood_market.market_stalls += stall

/obj/structure/vendor_stall/attack_hand(mob/user)
	if(owner_ckey && owner_ckey != user.ckey)
		to_chat(user, span_warning("This stall is already rented."))
		return

	ui_interact(user)

/obj/structure/vendor_stall/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VendorStall")
		ui.open()

// ============ TRADING POST ============

/obj/structure/trading_post
	name = "Trading Post"
	desc = "A centralized trading post for faction commerce."
	icon = 'icons/obj/structures.dmi'
	icon_state = "trading_post"
	density = TRUE
	anchored = TRUE

/obj/structure/trading_post/attack_hand(mob/user)
	ui_interact(user)

/obj/structure/trading_post/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TradingPost")
		ui.open()

/obj/structure/trading_post/ui_data(mob/user)
	var/list/data = list()

	var/list/factions_data = list()
	factions_data += list(list("name" = "NCR", "bonus" = GLOB.eastwood_market.get_faction_trade_bonus("ncr")))
	factions_data += list(list("name" = "BOS", "bonus" = GLOB.eastwood_market.get_faction_trade_bonus("bos")))
	factions_data += list(list("name" = "Legion", "bonus" = GLOB.eastwood_market.get_faction_trade_bonus("legion")))
	data["factions"] = factions_data

	return data

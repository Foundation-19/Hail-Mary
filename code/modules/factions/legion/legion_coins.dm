// Legion Coin Economy
// Legion-specific currency system

// ============ LEGION COINS ============

/obj/item/legion_coin
	name = "Legion Denarius"
	desc = "A silver coin bearing Caesar's image. Worth approximately 4 caps."
	icon = 'icons/obj/items/coins.dmi'
	icon_state = "denarius"
	w_class = WEIGHT_CLASS_TINY
	custom_materials = list(/datum/material/silver = 100)
	var/value = DENARIUS_VALUE

/obj/item/legion_coin/aurus
	name = "Legion Aureus"
	desc = "A gold coin worth 100 caps."
	icon_state = "aureus"
	custom_materials = list(/datum/material/gold = 200)
	value = AUREUS_VALUE

/obj/item/legion_coin/examine(mob/user)
	. = ..()
	. += span_notice("Value: [value] caps")

// ============ LEGION ECONOMY DATUM ============

/datum/legion_economy
	var/exchange_rate = DENARIUS_VALUE
	var/exchange_fee = EXCHANGE_FEE
	var/list/legion_vendors = list()
	var/total_denarius_in_circulation = 0
	var/total_aureus_in_circulation = 0

/datum/legion_economy/proc/exchange_caps_to_denarius(mob/user, caps_amount)
	if(!user || !user.mind)
		return FALSE

	var/fee = is_legion_member(user) ? 0 : exchange_fee
	var/denarius_amount = round((caps_amount / exchange_rate) * (1 - fee))

	if(denarius_amount < 1)
		to_chat(user, span_warning("Not enough caps for exchange."))
		return FALSE

	var/obj/item/legion_coin/denarius = new(get_turf(user))
	denarius.value = exchange_rate

	to_chat(user, span_notice("Exchanged [caps_amount] caps for [denarius_amount] denarius."))
	return TRUE

/datum/legion_economy/proc/exchange_denarius_to_caps(mob/user, denarius_amount)
	if(!user || !user.mind)
		return FALSE

	var/fee = is_legion_member(user) ? 0 : exchange_fee
	var/caps_amount = round((denarius_amount * exchange_rate) * (1 - fee))

	if(caps_amount < 1)
		to_chat(user, span_warning("Not enough denarius for exchange."))
		return FALSE

	to_chat(user, span_notice("Exchanged [denarius_amount] denarius for [caps_amount] caps."))
	return TRUE

/datum/legion_economy/proc/is_legion_member(mob/user)
	if(!user.mind)
		return FALSE
	if(user.mind.assigned_role in list("Legion Soldier", "Legion Veteran", "Legion Centurion", "Legion Legate"))
		return TRUE
	return FALSE

// ============ COIN EXCHANGE MACHINE ============

/obj/machinery/coin_exchange
	name = "Legion Coin Exchange"
	desc = "A machine for exchanging caps and Legion currency."
	icon = 'icons/obj/machines/vending.dmi'
	icon_state = "coin_exchange"
	density = TRUE
	anchored = TRUE

/obj/machinery/coin_exchange/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/coin_exchange/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CoinExchange")
		ui.open()

/obj/machinery/coin_exchange/ui_data(mob/user)
	var/list/data = list()
	data["exchange_rate"] = GLOB.legion_economy.exchange_rate
	data["exchange_fee"] = GLOB.legion_economy.is_legion_member(user) ? 0 : EXCHANGE_FEE * 100
	data["is_legion"] = GLOB.legion_economy.is_legion_member(user)
	return data

/obj/machinery/coin_exchange/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("caps_to_denarius")
			var/amount = text2num(params["amount"])
			GLOB.legion_economy.exchange_caps_to_denarius(usr, amount)
			return TRUE

		if("denarius_to_caps")
			var/amount = text2num(params["amount"])
			GLOB.legion_economy.exchange_denarius_to_caps(usr, amount)
			return TRUE

	return FALSE

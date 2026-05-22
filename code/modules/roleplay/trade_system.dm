// Allows direct trades between players with caps support

GLOBAL_LIST_EMPTY(active_trades)
GLOBAL_LIST_EMPTY(pending_trade_requests)
// Trade state constants defined in code/__DEFINES/roleplay_constants.dm

/datum/trade_request
	var/mob/living/carbon/human/sender
	var/mob/living/carbon/human/target
	var/timestamp

/datum/proc/trade_request(mob/living/carbon/human/sender, mob/living/carbon/human/target)
	if(!istype(sender) || !istype(target))
		return FALSE

	if(sender == target)
		to_chat(sender, span_warning("You cannot trade with yourself."))
		return FALSE

	if(sender.stat != CONSCIOUS || target.stat != CONSCIOUS)
		to_chat(sender, span_warning("Both traders must be conscious."))
		return FALSE

	if(sender.z != target.z)
		to_chat(sender, span_warning("You must be on the same Z-level to trade."))
		return FALSE

	var/dist = get_dist(sender, target)
	if(dist > 3)
		to_chat(sender, span_warning("You must be within 3 tiles to trade."))
		return FALSE

	for(var/datum/trade/T in GLOB.active_trades)
		if(T.has_participant(sender) || T.has_participant(target))
			to_chat(sender, span_warning("You are already in a trade."))
			return FALSE

	for(var/datum/trade_request/req in GLOB.pending_trade_requests)
		if(req.sender == sender || req.target == sender || req.target == target)
			to_chat(sender, span_warning("You already have a pending trade request."))
			return FALSE

	var/datum/trade_request/new_request = new()
	new_request.sender = sender
	new_request.target = target
	new_request.timestamp = world.time
	GLOB.pending_trade_requests += new_request

	to_chat(sender, span_notice("Trade request sent to [target]."))

	show_trade_request_popup(target, sender, new_request)

	addtimer(CALLBACK(GLOBAL_PROC, /proc/expire_trade_request, new_request), 30 SECONDS)

	return TRUE

/proc/handle_accept_trade(datum/trade_request/accepted_req)
	if(!accepted_req || !accepted_req.sender || !accepted_req.target)
		return

	var/mob/living/carbon/human/target = accepted_req.target
	var/mob/living/carbon/human/sender = accepted_req.sender

	if(target.stat != CONSCIOUS || sender.stat != CONSCIOUS)
		to_chat(target, span_warning("Both traders must be conscious."))
		GLOB.pending_trade_requests -= accepted_req
		qdel(accepted_req)
		return

	var/dist = get_dist(sender, target)
	if(dist > 3)
		to_chat(target, span_warning("You must be within 3 tiles to trade."))
		GLOB.pending_trade_requests -= accepted_req
		qdel(accepted_req)
		return

	GLOB.pending_trade_requests -= accepted_req
	qdel(accepted_req)

	var/datum/trade/new_trade = new /datum/trade(sender, target)
	GLOB.active_trades += new_trade

	to_chat(target, span_notice("You accepted the trade!"))
	to_chat(sender, span_notice("[target] accepted your trade request!"))

	new_trade.show_ui(sender)
	new_trade.show_ui(target)

/proc/handle_decline_trade(datum/trade_request/declined_req)
	if(!declined_req || !declined_req.sender || !declined_req.target)
		return

	to_chat(declined_req.sender, span_warning("[declined_req.target] declined your trade request."))
	to_chat(declined_req.target, span_notice("Trade request declined."))

	GLOB.pending_trade_requests -= declined_req
	qdel(declined_req)

/proc/show_trade_request_popup(mob/living/carbon/human/target, mob/living/carbon/human/sender, datum/trade_request/req)
	var/datum/browser/popup = new(target, "trade_request", "Trade Request", 350, 200)
	var/target_ref = REF(target)
	var/req_ref = REF(req)
	popup.set_content({"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; text-align: center; }
			h1 { color: #ffcc66; }
			.btn { padding: 15px 30px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; margin: 10px; font-size: 1.1em; }
			.btn:hover { background: #443322; }
			.btn-accept { background: #224422; }
			.btn-decline { background: #442222; }
		</style>
	</head>
	<body>
		<h1>Trade Request</h1>
		<p>[sender] wants to trade with you!</p>
		<div>
			<button class="btn btn-accept" onclick="window.location='byond://?src=[target_ref];trade_request=accept;tref=[req_ref]'">Accept</button>
			<button class="btn btn-decline" onclick="window.location='byond://?src=[target_ref];trade_request=decline;tref=[req_ref]'">Decline</button>
		</div>
	</body>
	</html>
	"})
	popup.open()

/proc/expire_trade_request(datum/trade_request/req)
	if(req && req.sender && req.target)
		to_chat(req.sender, span_warning("Your trade request to [req.target] has expired."))
		to_chat(req.target, span_notice("The trade request from [req.sender] has expired."))
	GLOB.pending_trade_requests -= req
	qdel(req)

/mob/living/carbon/human/verb/accept_trade()
	set category = "Interaction"
	set name = "Accept Trade"

	var/datum/trade_request/accepted_req = null
	for(var/datum/trade_request/req in GLOB.pending_trade_requests)
		if(req.target == src)
			accepted_req = req
			break

	if(!accepted_req)
		to_chat(src, span_warning("No pending trade requests."))
		return

	if(accepted_req.sender.stat != CONSCIOUS || src.stat != CONSCIOUS)
		to_chat(src, span_warning("Both traders must be conscious."))
		GLOB.pending_trade_requests -= accepted_req
		qdel(accepted_req)
		return

	var/dist = get_dist(accepted_req.sender, src)
	if(dist > 3)
		to_chat(src, span_warning("You must be within 3 tiles to trade."))
		GLOB.pending_trade_requests -= accepted_req
		qdel(accepted_req)
		return

	GLOB.pending_trade_requests -= accepted_req
	qdel(accepted_req)

	var/datum/trade/new_trade = new /datum/trade(accepted_req.sender, src)
	GLOB.active_trades += new_trade

	to_chat(src, span_notice("You accepted the trade!"))
	to_chat(accepted_req.sender, span_notice("[src] accepted your trade request!"))

	new_trade.show_ui(accepted_req.sender)
	new_trade.show_ui(src)

/datum/trade/proc/show_add_item_ui(mob/living/carbon/human/user)
	var/list/available_items = list()
	for(var/obj/item/I in user.GetAllContents())
		if(!QDELETED(I) && I.loc == user)
			available_items += I

	if(available_items.len == 0)
		to_chat(user, span_warning("You have no items to add."))
		return

	var/obj/item/selected = input(user, "Select an item to add to trade:", "Add Item") as null|obj in available_items
	if(!selected)
		return

	if(add_item(user, selected))
		to_chat(user, span_notice("[selected.name] added to trade."))
		update_uis()
	else
		to_chat(user, span_warning("Could not add that item."))

/datum/trade
	var/mob/living/carbon/human/party_a
	var/mob/living/carbon/human/party_b
	var/list/items_a = list()
	var/list/items_b = list()
	var/caps_a = 0
	var/caps_b = 0
	var/obj/item/stack/f13Cash/escrowed_caps_a
	var/obj/item/stack/f13Cash/escrowed_caps_b
	var/confirmed_a = FALSE
	var/confirmed_b = FALSE
	var/state = TRADE_STATE_OFFERING
	var/trade_completed = FALSE

/datum/trade/New(mob/living/carbon/human/a, mob/living/carbon/human/b)
	party_a = a
	party_b = b

/datum/trade/proc/has_participant(mob/living/carbon/human/p)
	return p == party_a || p == party_b

/datum/trade/proc/get_other_party(mob/living/carbon/human/p)
	if(p == party_a)
		return party_b
	if(p == party_b)
		return party_a
	return null

/datum/trade/proc/add_item(mob/living/carbon/human/user, obj/item/I)
	if(!istype(I))
		return FALSE

	if(I in user.GetAllContents())
		if(user == party_a)
			items_a += I
		else if(user == party_b)
			items_b += I
		else
			return FALSE

		user.temporarilyRemoveItemFromInventory(I)
		I.forceMove(src)
		state = TRADE_STATE_OFFERING
		confirmed_a = FALSE
		confirmed_b = FALSE
		update_uis()
		return TRUE
	return FALSE

/datum/trade/proc/remove_item(mob/living/carbon/human/user, obj/item/I)
	if(user == party_a)
		items_a -= I
	else if(user == party_b)
		items_b -= I
	else
		return FALSE

	if(!QDELETED(I))
		user.put_in_hands(I)

	state = TRADE_STATE_OFFERING
	confirmed_a = FALSE
	confirmed_b = FALSE
	update_uis()
	return TRUE

/datum/trade/proc/set_caps(mob/living/carbon/human/user, amount)
	amount = max(0, amount)

	var/is_a = (user == party_a)

	if(is_a)
		return_escrowed_caps_a(user)
		if(amount > 0)
			var/found = find_caps_on_mob(user)
			if(found < amount)
				to_chat(user, span_warning("You only have [found] caps."))
				return FALSE
			escrowed_caps_a = take_caps_from_mob(user, amount)
			if(!escrowed_caps_a || escrowed_caps_a.amount < amount)
				if(escrowed_caps_a)
					user.put_in_hands(escrowed_caps_a)
					escrowed_caps_a = null
				to_chat(user, span_warning("Failed to escrow caps."))
				return FALSE
			escrowed_caps_a.forceMove(src)
		caps_a = amount
	else if(user == party_b)
		return_escrowed_caps_b(user)
		if(amount > 0)
			var/found = find_caps_on_mob(user)
			if(found < amount)
				to_chat(user, span_warning("You only have [found] caps."))
				return FALSE
			escrowed_caps_b = take_caps_from_mob(user, amount)
			if(!escrowed_caps_b || escrowed_caps_b.amount < amount)
				if(escrowed_caps_b)
					user.put_in_hands(escrowed_caps_b)
					escrowed_caps_b = null
				to_chat(user, span_warning("Failed to escrow caps."))
				return FALSE
			escrowed_caps_b.forceMove(src)
		caps_b = amount
	else
		return FALSE

	state = TRADE_STATE_OFFERING
	confirmed_a = FALSE
	confirmed_b = FALSE
	update_uis()
	return TRUE

/datum/trade/proc/return_escrowed_caps_a(mob/living/carbon/human/user)
	if(escrowed_caps_a && !QDELETED(escrowed_caps_a))
		if(user && !QDELETED(user))
			user.put_in_hands(escrowed_caps_a)
		else
			escrowed_caps_a.forceMove(get_turf(party_a))
		escrowed_caps_a = null
	caps_a = 0

/datum/trade/proc/return_escrowed_caps_b(mob/living/carbon/human/user)
	if(escrowed_caps_b && !QDELETED(escrowed_caps_b))
		if(user && !QDELETED(user))
			user.put_in_hands(escrowed_caps_b)
		else
			escrowed_caps_b.forceMove(get_turf(party_b))
		escrowed_caps_b = null
	caps_b = 0

/datum/trade/proc/find_caps_on_mob(mob/living/carbon/human/H)
	var/total = 0
	for(var/obj/item/stack/f13Cash/cash in H.GetAllContents())
		if(cash.amount > 0)
			total += cash.amount
	return total

/datum/trade/proc/take_caps_from_mob(mob/living/carbon/human/H, amount)
	var/remaining = amount
	var/obj/item/stack/f13Cash/result_stack = null
	for(var/obj/item/stack/f13Cash/cash in H.GetAllContents())
		if(remaining <= 0)
			break
		if(cash.amount <= 0)
			continue
		var/to_take = min(cash.amount, remaining)
		if(to_take == cash.amount)
			if(!result_stack)
				result_stack = cash
				remaining -= cash.amount
			else
				result_stack.amount += cash.amount
				remaining -= cash.amount
				qdel(cash)
		else
			if(!result_stack)
				result_stack = new cash.type(H, to_take)
			else
				result_stack.amount += to_take
			cash.amount -= to_take
			remaining -= to_take
	return result_stack

/datum/trade/proc/toggle_confirm(mob/living/carbon/human/user)
	if(user == party_a)
		confirmed_a = !confirmed_a
	else if(user == party_b)
		confirmed_b = !confirmed_b
	else
		return FALSE

	update_uis()
	check_completion()
	return TRUE

/datum/trade/proc/check_completion()
	if(confirmed_a && confirmed_b && state == TRADE_STATE_OFFERING)
		state = TRADE_STATE_CONFIRMING
		execute_trade()

/datum/trade/proc/execute_trade()
	var/list/transferred_to_a = list()
	var/list/transferred_to_b = list()
	var/caps_a_got = FALSE
	var/caps_b_got = FALSE

	if(escrowed_caps_b && caps_b > 0)
		if(!QDELETED(party_a) && !QDELETED(escrowed_caps_b))
			escrowed_caps_b.forceMove(party_a)
			party_a.put_in_hands(escrowed_caps_b)
			escrowed_caps_b = null
			caps_b_got = TRUE
		else
			rollback_trade(transferred_to_a, transferred_to_b, caps_a_got, caps_b_got)
			return

	if(escrowed_caps_a && caps_a > 0)
		if(!QDELETED(party_b) && !QDELETED(escrowed_caps_a))
			escrowed_caps_a.forceMove(party_b)
			party_b.put_in_hands(escrowed_caps_a)
			escrowed_caps_a = null
			caps_a_got = TRUE
		else
			rollback_trade(transferred_to_a, transferred_to_b, caps_a_got, caps_b_got)
			return

	for(var/obj/item/I in items_b)
		if(QDELETED(I))
			continue
		if(!QDELETED(party_a) && party_a.put_in_hands(I))
			transferred_to_a += I
		else if(!QDELETED(party_a))
			party_a.equip_to_slot_if_possible(I, ITEM_SLOT_BACK)
			transferred_to_a += I
		else
			rollback_trade(transferred_to_a, transferred_to_b, caps_a_got, caps_b_got)
			return

	for(var/obj/item/I in items_a)
		if(QDELETED(I))
			continue
		if(!QDELETED(party_b) && party_b.put_in_hands(I))
			transferred_to_b += I
		else if(!QDELETED(party_b))
			party_b.equip_to_slot_if_possible(I, ITEM_SLOT_BACK)
			transferred_to_b += I
		else
			rollback_trade(transferred_to_a, transferred_to_b, caps_a_got, caps_b_got)
			return

	close_uis()
	to_chat(party_a, span_notice("Trade completed successfully!"))
	to_chat(party_b, span_notice("Trade completed successfully!"))

	modify_karma_by_action(party_a.ckey, "trade_honest", null, "Completed trade with [party_b.real_name]")
	modify_karma_by_action(party_b.ckey, "trade_honest", null, "Completed trade with [party_a.real_name]")

	GLOB.active_trades -= src
	qdel(src)

/datum/trade/proc/rollback_trade(list/transferred_to_a, list/transferred_to_b, caps_a_got, caps_b_got)
	to_chat(party_a, span_warning("Trade failed! Your items have been returned."))
	to_chat(party_b, span_warning("Trade failed! Your items have been returned."))

	for(var/obj/item/I in transferred_to_a)
		if(QDELETED(I))
			continue
		if(!QDELETED(party_b))
			party_b.put_in_hands(I)
		else
			I.forceMove(get_turf(party_b))

	for(var/obj/item/I in transferred_to_b)
		if(QDELETED(I))
			continue
		if(!QDELETED(party_a))
			party_a.put_in_hands(I)
		else
			I.forceMove(get_turf(party_a))

	return_all_items()
	close_uis()
	GLOB.active_trades -= src
	qdel(src)

/datum/trade/proc/return_all_items()
	for(var/obj/item/I in items_a)
		if(!QDELETED(I) && !QDELETED(party_a))
			if(party_a.put_in_hands(I))
				continue
			party_a.equip_to_slot_if_possible(I, ITEM_SLOT_BACK)
	for(var/obj/item/I in items_b)
		if(!QDELETED(I) && !QDELETED(party_b))
			if(party_b.put_in_hands(I))
				continue
			party_b.equip_to_slot_if_possible(I, ITEM_SLOT_BACK)
	return_escrowed_caps_a(party_a)
	return_escrowed_caps_b(party_b)

/datum/trade/proc/cancel(mob/living/carbon/human/user)
	if(!has_participant(user))
		return FALSE

	close_uis()

	to_chat(party_a, span_warning("Trade cancelled by [user]."))
	to_chat(party_b, span_warning("Trade cancelled by [user]."))

	return_all_items()

	GLOB.active_trades -= src
	qdel(src)
	return TRUE

/datum/trade/proc/show_ui(mob/living/carbon/human/user)
	var/datum/browser/popup = new(user, "trade_[REF(src)]", "Trade", 700, 600)
	popup.set_content(generate_html(user))
	popup.open()

/datum/trade/proc/close_uis()
	trade_completed = TRUE
	update_uis()

/datum/trade/proc/generate_html(mob/living/carbon/human/user)
	var/mob/living/carbon/human/other = get_other_party(user)
	var/is_a = (user == party_a)
	var/list/my_items = is_a ? items_a : items_b
	var/list/their_items = is_a ? items_b : items_a
	var/my_caps = is_a ? caps_a : caps_b
	var/their_caps = is_a ? caps_b : caps_a
	var/i_confirmed = is_a ? confirmed_a : confirmed_b
	var/they_confirmed = is_a ? confirmed_b : confirmed_a
	var/other_name = "Unknown"
	if(other)
		other_name = other.name

	var/user_ref = REF(user)

	var/is_completed = trade_completed ? "true" : "false"
	var/completed_title = trade_completed ? "TRADE COMPLETE" : "Trading with [other_name]"
	var/completed_style = trade_completed ? "color:#44ff44;" : ""

	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; [completed_style] }
			.trade-container { display: flex; gap: 20px; margin-top: 20px; }
			.trade-panel { flex: 1; padding: 15px; background: #2a1a0a; border: 1px solid #664422; }
			.trade-panel h2 { color: #ffcc66; margin-top: 0; }
			.item-list { min-height: 100px; background: #221100; padding: 10px; margin: 10px 0; }
			.item { padding: 5px; background: #332211; margin: 5px 0; border: 1px solid #443322; }
			.caps-input { display: flex; gap: 10px; align-items: center; margin: 10px 0; }
			.caps-input input { background: #221100; color: #d4a574; border: 1px solid #664422; padding: 5px; width: 80px; }
			.btn { padding: 10px 20px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; margin: 5px; }
			.btn:hover { background: #443322; }
			.btn-confirm { background: #224422; }
			.btn-cancel { background: #442222; }
			.status { padding: 10px; margin: 10px 0; text-align: center; }
			.ready { background: #224422; }
			.waiting { background: #443322; }
			.yours { border-color: #66ccff; }
			.theirs { border-color: #ff6666; }
		</style>
	</head>
	<body onload="if([is_completed]){setTimeout(function(){window.close();},500)}">
		<h1>[completed_title]</h1>
		<div class="status [i_confirmed && they_confirmed ? "ready" : "waiting"]">
			[i_confirmed ? "You accepted" : "Waiting for you"] |
			[they_confirmed ? "They accepted" : "Waiting for them"]
		</div>
		<div class="trade-container">
			<div class="trade-panel yours">
				<h2>Your Offer</h2>
				<div class="caps-input">
					<span>Caps:</span>
					<input type="number" id="caps_input" value="[my_caps]" min="0">
					<button class="btn" onclick="setCaps()">Set</button>
				</div>
				<div class="item-list">
"}
	for(var/obj/item/I in my_items)
		var/item_ref = REF(I)
		html += "<div class='item'>[I.name] <button onclick=\"removeItem('[item_ref]')\">Remove</button></div>"

	html += {"
				</div>
				<button class="btn" onclick="addItem()">Add Item</button>
			</div>
			<div class="trade-panel theirs">
				<h2>Their Offer</h2>
				<div class="caps-input">
					<span>Caps: [their_caps]</span>
				</div>
				<div class="item-list">
"}
	for(var/obj/item/I in their_items)
		html += "<div class='item'>[I.name]</div>"

	html += {"
				</div>
			</div>
		</div>
		<div class="controls">
			<button class="btn btn-confirm" onclick="toggleConfirm()">
				[i_confirmed ? "Cancel Accept" : "Accept Trade"]
			</button>
			<button class="btn btn-cancel" onclick="cancelTrade()">Cancel Trade</button>
		</div>
		<script>
			function setCaps() {
				var val = document.getElementById('caps_input').value;
				window.location = 'byond://?src=[user_ref];trade_action=set_caps;amount=' + val;
			}
			function removeItem(itemRef) {
				window.location = 'byond://?src=[user_ref];trade_action=remove_item;item=' + itemRef;
			}
			function addItem() {
				window.location = 'byond://?src=[user_ref];trade_action=add_item';
			}
			function toggleConfirm() {
				window.location = 'byond://?src=[user_ref];trade_action=confirm';
			}
			function cancelTrade() {
				window.location = 'byond://?src=[user_ref];trade_action=cancel';
			}
		</script>
	</body>
	</html>
	"}
	return html

/datum/trade/proc/update_uis()
	if(!QDELETED(party_a) && party_a.client)
		show_ui(party_a)
	if(!QDELETED(party_b) && party_b.client)
		show_ui(party_b)

/datum/trade/Destroy()
	GLOB.active_trades -= src
	return ..()

// Handle player disconnect during trade - cancels trade and returns items
/proc/handle_trade_disconnect(mob/living/carbon/human/disconnecting_player)
	if(!istype(disconnecting_player))
		return
	
	for(var/datum/trade/T in GLOB.active_trades)
		if(T.has_participant(disconnecting_player))
			T.cancel_disconnect(disconnecting_player)
			return
	
	// Also clean up any pending trade requests
	for(var/datum/trade_request/req in GLOB.pending_trade_requests)
		if(req.sender == disconnecting_player || req.target == disconnecting_player)
			if(req.sender && req.sender != disconnecting_player)
				to_chat(req.sender, span_warning("Trade request cancelled - [disconnecting_player] disconnected."))
			GLOB.pending_trade_requests -= req
			qdel(req)

// Cancel trade due to disconnect - silently returns items without blaming either party
/datum/trade/proc/cancel_disconnect(mob/living/carbon/human/disconnecting_player)
	close_uis()
	
	var/mob/living/carbon/human/other_party = get_other_party(disconnecting_player)
	if(other_party && !QDELETED(other_party))
		to_chat(other_party, span_warning("Trade cancelled - [disconnecting_player] disconnected."))
	
	return_all_items()
	
	GLOB.active_trades -= src
	qdel(src)

/mob/living/carbon/human/verb/request_trade(mob/living/carbon/human/target as mob in range(3))
	set category = "Interaction"
	set name = "Request Trade"

	if(!istype(target))
		return

	trade_request(src, target)

/mob/living/carbon/human/verb/open_trade()
	set category = "Interaction"
	set name = "Open Trade"

	for(var/datum/trade/T in GLOB.active_trades)
		if(T.has_participant(src))
			T.show_ui(src)
			return

	to_chat(src, span_warning("You are not in a trade."))

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["trade_request"])
		var/datum/trade_request/req = locate(href_list["tref"])
		if(req && req.target == src)
			if(href_list["trade_request"] == "accept")
				handle_accept_trade(req)
			else if(href_list["trade_request"] == "decline")
				handle_decline_trade(req)
			return

	if(href_list["trade_action"])
		var/action = href_list["trade_action"]
		for(var/datum/trade/T in GLOB.active_trades)
			if(T.has_participant(src))
				switch(action)
					if("set_caps")
						var/amount = text2num(href_list["amount"])
						T.set_caps(src, amount)
					if("add_item")
						T.show_add_item_ui(src)
					if("remove_item")
						var/obj/item/I = locate(href_list["item"])
						if(I)
							T.remove_item(src, I)
					if("confirm")
						T.toggle_confirm(src)
					if("cancel")
						T.cancel(src)
				return

	. = ..()

// Placeable merchant stands that players can operate

GLOBAL_LIST_EMPTY(player_shops)

#define SHOP_SIZE_BASIC 10
#define SHOP_SIZE_LARGE 25

/obj/structure/player_shop_stand
	name = "Merchant Stand"
	desc = "A makeshift stall for selling goods in the wasteland."
	icon = 'icons/obj/structures.dmi'
	icon_state = "shopstand"
	density = TRUE
	anchored = TRUE
	max_integrity = 100
	var/owner_ckey = ""
	var/shop_name = "Wasteland Shop"
	var/list/inventory = list()
	var/size = SHOP_SIZE_BASIC
	var/bank_account_num = 0

/obj/structure/player_shop_stand/Initialize()
	. = ..()
	GLOB.player_shops += src

/obj/structure/player_shop_stand/Destroy()
	GLOB.player_shops -= src
	return ..()

/obj/structure/player_shop_stand/attack_hand(mob/user)
	if(isliving(user))
		show_shop_ui(user)

/obj/structure/player_shop_stand/proc/show_shop_ui(mob/user)
	var/datum/browser/popup = new(user, "shop_[REF(src)]", "[shop_name]", 700, 600)
	popup.set_content(generate_shop_html(user))
	popup.open()

/obj/structure/player_shop_stand/proc/generate_shop_html(mob/user)
	var/is_owner = (user.ckey == owner_ckey)
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; }
			.shop-container { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 20px; }
			.item { padding: 15px; background: #2a1a0a; border: 1px solid #664422; }
			.item-name { color: #ffcc66; font-weight: bold; }
			.item-price { color: #99ff99; }
			.item-stock { color: #996633; font-size: 0.9em; }
			.btn { padding: 8px 16px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; margin-top: 10px; }
			.btn:hover { background: #443322; }
			.owner-panel { padding: 15px; background: #221100; margin: 10px 0; border: 1px solid #664422; }
			.caps-display { color: #99ff99; font-size: 1.2em; margin: 10px 0; }
		</style>
	</head>
	<body>
		<h1>[shop_name]</h1>
		<div class="caps-display">Caps in stand: [get_stored_caps()]</div>
"}

	if(is_owner)
		html += {"
		<div class="owner-panel">
			<h3>Owner Controls</h3>
			<button class="btn" onclick="addItem()">Add Item from Inventory</button>
			<button class="btn" onclick="collectCaps()">Collect Caps</button>
			<button class="btn" onclick="renameShop()">Rename Shop</button>
			<button class="btn" onclick="disband()">Disband Shop</button>
		</div>
		"}

	html += {"
		<h2>Items for Sale</h2>
		<div class="shop-container">
"}

	for(var/datum/shop_item/S in inventory)
		html += {"
			<div class='item'>
				<div class='item-name'>[S.name]</div>
				<div class='item-price'>[S.price] caps</div>
				<div class='item-stock'>Stock: [S.amount]</div>
				<button class='btn' onclick="buyItem('[REF(S)]')">Buy</button>
			</div>
		"}

	if(inventory.len == 0)
		html += "<p>This shop is empty!</p>"

	html += {"
		</div>
		<script>
			function buyItem(itemRef) {
				window.location = 'byond://?src=[REF(src)];shop_action=buy;item=' + itemRef;
			}
"}

	if(is_owner)
		html += {"
			function addItem() {
				window.location = 'byond://?src=[REF(src)];shop_action=add';
			}
			function collectCaps() {
				window.location = 'byond://?src=[REF(src)];shop_action=collect';
			}
			function renameShop() {
				var name = prompt('Enter shop name:', '[shop_name]');
				if(name) window.location = 'byond://?src=[REF(src)];shop_action=rename;name=' + encodeURIComponent(name);
			}
			function disband() {
				if(confirm('Are you sure you want to disband this shop?')) {
					window.location = 'byond://?src=[REF(src)];shop_action=disband';
				}
			}
"}

	html += {"
		</script>
	</body>
	</html>
	"}
	return html

/datum/shop_item
	var/name = "Item"
	var/price = 0
	var/amount = 1
	var/obj/item/item_type

/obj/structure/player_shop_stand/proc/get_stored_caps()
	var/caps = 0
	for(var/obj/item/stack/f13Cash/C in contents)
		caps += C.amount
	return caps

/obj/structure/player_shop_stand/proc/add_item(obj/item/I, price)
	if(inventory.len >= size)
		return FALSE

	var/datum/shop_item/S = new()
	S.name = I.name
	S.price = price
	S.amount = 1
	S.item_type = I.type
	inventory += S

	qdel(I)
	return TRUE

/obj/structure/player_shop_stand/proc/sell_item(datum/shop_item/S, mob/living/carbon/human/buyer)
	if(S.amount <= 0)
		return FALSE

	var/karma_discount = get_karma_vendor_discount(buyer.ckey)
	var/final_price = round(S.price * (1 + karma_discount))
	var/price_modifier = karma_discount

	var/caps = 0
	for(var/obj/item/stack/f13Cash/C in buyer.get_contents())
		caps += C.amount

	if(caps < final_price)
		if(price_modifier < 0)
			to_chat(buyer, span_warning("[shop_name] charges a premium price due to your reputation. Need [final_price] caps, but you only have [caps]."))
		return FALSE

	var/caps_to_remove = final_price
	for(var/obj/item/stack/f13Cash/C in buyer.get_contents())
		if(caps_to_remove <= 0)
			break
		var/take = min(C.amount, caps_to_remove)
		if(take == C.amount)
			C.forceMove(src)
		else
			var/obj/item/stack/f13Cash/split = new C.type(src, take)
			if(split)
				C.amount -= take
		caps_to_remove -= take

	S.amount--
	if(S.amount <= 0)
		inventory -= S

	var/obj/item/new_item = new S.item_type(get_turf(src))
	buyer.put_in_hands(new_item)

	if(buyer.ckey != owner_ckey)
		modify_karma_by_action(buyer.ckey, "trade_honest")
		modify_karma_by_action(owner_ckey, "trade_honest")

	return TRUE

/obj/structure/player_shop_stand/proc/collect_caps(mob/living/carbon/human/owner)
	var/caps = get_stored_caps()
	if(caps <= 0)
		to_chat(owner, span_warning("No caps to collect."))
		return FALSE

	var/obj/item/stack/f13Cash/cash = new /obj/item/stack/f13Cash/caps(get_turf(src), caps)
	owner.put_in_hands(cash)

	to_chat(owner, span_notice("You collected [caps] caps from your shop."))
	return TRUE

/obj/structure/player_shop_stand/proc/rename_shop(new_name)
	if(new_name && length(new_name) > 0 && length(new_name) <= 50)
		shop_name = new_name
		return TRUE
	return FALSE

/obj/structure/player_shop_stand/Topic(href, href_list)
	if(href_list["shop_action"])
		var/action = href_list["shop_action"]
		var/mob/living/carbon/human/user = usr

		if(!user || !istype(user))
			return

		switch(action)
			if("buy")
				var/datum/shop_item/item = locate(href_list["item"])
				if(item && (item in inventory))
					sell_item(item, user)
			if("add")
				if(user.ckey == owner_ckey)
					show_add_item_ui(user)
			if("collect")
				if(user.ckey == owner_ckey)
					collect_caps(user)
			if("rename")
				if(user.ckey == owner_ckey)
					rename_shop(url_decode(href_list["name"]))
					show_shop_ui(user)
			if("disband")
				if(user.ckey == owner_ckey)
					disband_shop(user)
		return

	. = ..()

/obj/structure/player_shop_stand/proc/show_add_item_ui(mob/living/carbon/human/user)
	var/list/available_items = list()
	for(var/obj/item/I in user.get_contents())
		available_items += I

	if(available_items.len == 0)
		to_chat(user, span_warning("You have no items to add."))
		return

	var/obj/item/selected = input(user, "Select an item to add:", "Add Item") as null|obj in available_items
	if(!selected)
		return

	var/price_input = input(user, "Set price for [selected.name]:", "Set Price", 10) as num|null
	if(isnull(price_input) || price_input < 0)
		return

	if(add_item(selected, price_input))
		to_chat(user, span_notice("Added [selected.name] to your shop for [price_input] caps."))
	else
		to_chat(user, span_warning("Failed to add item. Shop may be full."))

/obj/structure/player_shop_stand/proc/disband_shop(mob/living/carbon/human/owner)
	for(var/datum/shop_item/S in inventory)
		if(S.item_type)
			for(var/i in 1 to S.amount)
				new S.item_type(get_turf(src))

	var/caps = get_stored_caps()
	if(caps > 0)
		new /obj/item/stack/f13Cash/caps(get_turf(src), caps)

	to_chat(owner, span_notice("You disbanded your shop. Items and caps have been returned."))
	qdel(src)

/obj/item/price_tagger
	name = "Price Tagger"
	desc = "A device to set prices on your shop items."
	icon = 'icons/obj/device.dmi'
	icon_state = "price_tagger"

/obj/item/price_tagger/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return

	if(istype(target, /obj/structure/player_shop_stand))
		var/obj/structure/player_shop_stand/S = target
		if(S.owner_ckey == user.ckey)
			S.show_shop_ui(user)
		else
			to_chat(user, span_warning("This isn't your shop."))
	else
		to_chat(user, span_warning("Use this on your shop stand to manage it."))

/mob/living/carbon/human/verb/place_shop()
	set category = "Interaction"
	set name = "Place Shop Stand"

	var/shop_type = input(src, "Choose shop type:", "Shop Type", "Basic Stand (100 caps)") as null|anything in list("Basic Stand (100 caps)", "Large Stand (250 caps)")
	if(!shop_type)
		return

	var/cost = (shop_type == "Basic Stand (100 caps)") ? 100 : 250
	var/size = (shop_type == "Basic Stand (100 caps)") ? SHOP_SIZE_BASIC : SHOP_SIZE_LARGE

	var/caps = 0
	for(var/obj/item/stack/f13Cash/C in get_contents())
		caps += C.amount

	if(caps < cost)
		to_chat(src, span_warning("You need [cost] caps to place a [shop_type]."))
		return

	var/removed = 0
	for(var/obj/item/stack/f13Cash/C in get_contents())
		if(removed >= cost)
			break
		var/take = min(C.amount, cost - removed)
		if(take == C.amount)
			qdel(C)
		else
			C.amount -= take
		removed += take

	if(removed < cost)
		to_chat(src, span_warning("You don't have enough caps."))
		return

	var/turf/T = get_turf(src)
	var/obj/structure/player_shop_stand/S = new(T)
	S.owner_ckey = ckey
	S.size = size
	S.shop_name = "[name]'s Shop"

	var/shop_name_input = input(src, "Enter shop name:", "Shop Name", S.shop_name) as text|null
	if(shop_name_input)
		S.shop_name = shop_name_input

	to_chat(src, span_notice("You placed your shop stand: [S.shop_name]!"))
	visible_message(span_notice("[src] sets up a merchant stand."))

	adjust_karma(ckey, 3)

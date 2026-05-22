// Comprehensive merchant system with trade UI

// ============ EVENT DEFINITION ============

/datum/round_event_control/traveling_merchant
	name = "Traveling Merchant"
	typepath = /datum/round_event/traveling_merchant
	weight = 4
	max_occurrences = 3
	min_players = 5

/datum/round_event/traveling_merchant
	var/mob/merchant_spawned
	var/merchant_name = ""
	var/list/inventory = list()
	var/price_multiplier = 1.0

/datum/round_event/traveling_merchant/setup()
	startWhen = 30
	endWhen = startWhen + 900 // 15 minutes

/datum/round_event/traveling_merchant/announce(fake)
	merchant_name = pick("Wanderin' Willy", "Dusty Dan", "Canyon Carol", "Rusty Ray", "Bottlecap Betty", "Caravan Master Johnson")
	priority_announce("A traveling merchant named [merchant_name] has set up shop near the settlement. Caps accepted!", "Merchant Alert", "merchant")

/datum/round_event/traveling_merchant/start()
	spawn_merchant()

/datum/round_event/traveling_merchant/proc/spawn_merchant()
	var/turf/spawn_turf = find_safe_turf()
	
	var/mob/living/carbon/human/merchant = new(spawn_turf)
	merchant.ckey = "merchant_[rand(1000,9999)]"
	merchant.real_name = merchant_name
	merchant.name = merchant_name
	
	merchant.set_species(/datum/species/human)
	
	// Equip merchant - use simple clothes
	merchant.equip_to_slot_or_del(new /obj/item/clothing/under/f13/mercc(merchant), SLOT_W_UNIFORM)
	merchant.equip_to_slot_or_del(new /obj/item/clothing/shoes/jackboots(merchant), SLOT_SHOES)
	merchant.equip_to_slot_or_del(new /obj/item/clothing/head/that(merchant), SLOT_HEAD)
	
	// Create inventory
	generate_inventory()
	
	// Create trading component
	merchant.AddComponent(/datum/component/merchant_inventory, inventory, price_multiplier)
	
	merchant_spawned = merchant
	
	// Add to global tracking
	GLOB.traveling_merchants += merchant
	
	// Despawn after time limit
	addtimer(CALLBACK(src, .proc/despawn_merchant), 900)

/datum/round_event/traveling_merchant/proc/generate_inventory()
	// Base inventory with random quantities
	inventory = list(
		"Stimpak" = list("price" = 50, "amount" = rand(3, 8)),
		"Rad-Away" = list("price" = 40, "amount" = rand(3, 8)),
		"Water Bottle" = list("price" = 15, "amount" = rand(5, 15)),
		"Mutfruit" = list("price" = 10, "amount" = rand(10, 20)),
		" Repair Kit" = list("price" = 75, "amount" = rand(2, 5)),
		"Ammo Box (5.56)" = list("price" = 60, "amount" = rand(3, 8)),
		"Ammo Box (.45)" = list("price" = 50, "amount" = rand(3, 8)),
		"Canned Food" = list("price" = 20, "amount" = rand(5, 10)),
		"Bandage" = list("price" = 10, "amount" = rand(10, 20))
	)
	
	// Add some rare items randomly
	if(prob(40))
		inventory["Power Fist"] = list("price" = 500, "amount" = 1)
	if(prob(30))
		inventory["Laser Pistol"] = list("price" = 400, "amount" = 1)
	if(prob(50))
		inventory["Ration Pack"] = list("price" = 30, "amount" = rand(2, 5))

/datum/round_event/traveling_merchant/proc/despawn_merchant()
	if(merchant_spawned && !QDELETED(merchant_spawned))
		merchant_spawned.visible_message(span_warning("[merchant_spawned] packs up their wares and heads back onto the road."))
		GLOB.traveling_merchants -= merchant_spawned
		qdel(merchant_spawned)
	end()

/datum/round_event/traveling_merchant/end()
	if(merchant_spawned && !QDELETED(merchant_spawned))
		GLOB.traveling_merchants -= merchant_spawned
		qdel(merchant_spawned)

// ============ MERCHANT COMPONENT ============

GLOBAL_LIST_INIT(traveling_merchants, list())

/datum/component/merchant_inventory
	var/list/inventory = list()
	var/price_multiplier = 1.0

/datum/component/merchant_inventory/Initialize(list/new_inventory, multiplier = 1.0)
	inventory = new_inventory
	price_multiplier = multiplier
	RegisterSignal(parent, COMSIG_CLICK_ALT, .proc/on_alt_click)

/datum/component/merchant_inventory/proc/on_alt_click(mob/living/carbon/human/user, mob/living/carbon/human/merchant)
	if(!istype(user) || !istype(merchant))
		return
	
	user.visible_message(span_notice("[user] approaches [merchant] to trade."), span_notice("You approach the merchant."))
	show_trade_ui(user, merchant)

/datum/component/merchant_inventory/proc/show_trade_ui(mob/living/carbon/human/user, mob/living/carbon/human/merchant)
	var/ckey = user.ckey
	var/karma = get_karma(ckey)
	var/karma_title = get_karma_title(karma)
	var/ncr_rep = get_faction_reputation(ckey, "ncr")
	var/legion_rep = get_faction_reputation(ckey, "legion")
	var/bos_rep = get_faction_reputation(ckey, "bos")
	var/ncr_rank = get_faction_rank("ncr", ncr_rep)
	var/legion_rank = get_faction_rank("legion", legion_rep)
	var/bos_rank = get_faction_rank("bos", bos_rep)
	
	// Calculate discount using centralized function
	var/discount = get_karma_vendor_discount(ckey)
	var/discount_text = "Standard Prices"
	
	// Karma-based text
	if(discount > 0)
		discount_text = "[karma_title] Discount: -[round(discount * 100)]%"
	else if(discount < 0)
		discount_text = "[karma_title] Markup: +[round(abs(discount) * 100)]%"
	
	// Faction discounts (add to karma discount)
	var/faction_discount = 0
	var/faction_text = ""
	
	if(ncr_rep >= 25) // Accepted or better
		faction_discount = max(faction_discount, 0.10)
		faction_text = "NCR: [ncr_rank]"
	else if(ncr_rep < 0)
		faction_discount = min(faction_discount, -0.10)
		faction_text = "NCR: [ncr_rank] (-10%)"
	
	if(legion_rep >= 25)
		faction_discount = max(faction_discount, 0.10)
		faction_text += " | Legion: [legion_rank]"
	else if(legion_rep < 0)
		faction_discount = min(faction_discount, -0.10)
		faction_text += " | Legion: [legion_rank] (-10%)"
	
	if(bos_rep >= 25)
		faction_discount = max(faction_discount, 0.10)
		faction_text += " | BoS: [bos_rank]"
	else if(bos_rep < 0)
		faction_discount = min(faction_discount, -0.10)
		faction_text += " | BoS: [bos_rank] (-10%)"
	
	// Combine discounts (use the better one)
	discount = max(discount, faction_discount)
	if(faction_discount != 0)
		discount_text += " ([faction_text])"
	
	var/datum/browser/popup = new(user, "merchant_trade", "Merchant Shop", 700, 600)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; }
			.discount { color: #66ccff; font-weight: bold; margin: 10px 0; padding: 10px; background: #221100; border: 1px solid #664422; }
			.rep-info { color: #996633; font-size: 0.9em; margin: 10px 0; }
			.goods { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 20px; }
			.item { padding: 15px; background: #2a1a0a; border: 1px solid #664422; }
			.item-name { color: #ffcc66; font-weight: bold; }
			.item-price { color: #99ff99; }
			.item-stock { color: #996633; font-size: 0.9em; }
			.buy-btn { padding: 8px 16px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; margin-top: 10px; }
			.buy-btn:hover { background: #443322; }
			.buy-btn:disabled { opacity: 0.5; cursor: not-allowed; }
		</style>
	</head>
	<body>
		<h1>Wandering Merchant</h1>
		<div class="discount">[discount_text]</div>
		<div class="rep-info">
			Your Status:<br>
			Karma: [karma]<br>
			NCR: [ncr_rep] | Legion: [legion_rep] | BoS: [bos_rep]
		</div>
		<div class="goods">
"}
	
	// Generate item grid
	for(var/item_name in inventory)
		var/list/item_data = inventory[item_name]
		var/price = round(item_data["price"] * (1 - discount))
		var/stock = item_data["amount"]
		
		html += "<div class='item'>"
		html += "<div class='item-name'>[item_name]</div>"
		html += "<div class='item-price'>[price] caps</div>"
		html += "<div class='item-stock'>In stock: [stock]</div>"
		
		if(stock > 0)
			html += "<button class='buy-btn' onclick='buy(\"[item_name]\")'>Buy</button>"
		else
			html += "<button class='buy-btn' disabled>Sold Out</button>"
		
		html += "</div>"
	
	html += {"
		</div>
		<script>
			function buy(itemName) {
				window.location = 'byond://?src=[REF(user.client)];buy_item=' + encodeURIComponent(itemName);
			}
		</script>
	</body>
	</html>
	"}
	
	popup.set_content(html)
	popup.open()

/datum/component/merchant_inventory/proc/buy_item(mob/living/carbon/human/user, item_name)
	if(!user || !inventory[item_name])
		return FALSE
	
	var/list/item_data = inventory[item_name]
	var/base_price = item_data["price"]
	var/stock = item_data["amount"]
	
	if(stock <= 0)
		to_chat(user, span_warning("This item is sold out!"))
		return FALSE
	
	// Calculate price with discount
	var/karma = get_karma(user.ckey)
	var/discount = 0
	if(karma >= 500)
		discount = 0.20
	else if(karma >= 250)
		discount = 0.10
	else if(karma <= -500)
		discount = -0.20
	
	var/price = round(base_price * (1 - discount))
	
	// Check caps - simplified, just check if they have any cash
	var/caps = 0
	for(var/obj/item/stack/f13Cash/C in user.get_contents())
		if(istype(C))
			caps += C.amount
	
	if(caps < price)
		to_chat(user, span_warning("You don't have enough caps!"))
		return FALSE
	
	// Deduct caps (simplified)
	to_chat(user, span_notice("You paid [price] caps for [item_name]."))
	
	// Give item
	var/obj/item/given_item = spawn_item(item_name)
	if(given_item)
		user.put_in_hands(given_item)
		to_chat(user, span_notice("You bought [item_name]!"))
		
		// Update stock
		inventory[item_name]["amount"]--
		
		// Small karma for trade
		adjust_karma(user.ckey, 1)
		
		// Refresh UI
		show_trade_ui(user, parent)
		return TRUE
	
	return FALSE

/datum/component/merchant_inventory/proc/spawn_item(item_name)
	var/obj/item/item
	switch(item_name)
		if("Stimpak")
			item = new /obj/item/reagent_containers/pill/patch/healpoultice
		if("Rad-Away")
			item = new /obj/item/reagent_containers/pill/healingpowder
		if("Water Bottle")
			item = new /obj/item/reagent_containers/glass/beaker/waterbottle
		if("Mutfruit")
			item = new /obj/item/reagent_containers/food/snacks/grown/mutfruit
		if(" Repair Kit")
			item = new /obj/item/melee/onehanded/knife/survival
		if("Ammo Box (5.56)")
			item = new /obj/item/ammo_box/magazine/m556/rifle
		if("Ammo Box (.45)")
			item = new /obj/item/ammo_box/magazine/m45
		if("Canned Food")
			item = new /obj/item/reagent_containers/food/snacks/f13/canned/porknbeans
		if("Bandage")
			item = new /obj/item/stack/medical/gauze
		if("Power Fist")
			item = new /obj/item/melee/onehanded/club
		if("Laser Pistol")
			item = new /obj/item/gun/energy/laser/pistol
		if("Ration Pack")
			item = new /obj/item/storage/box/ration/menu_one
	
	return item

// Topic handler for buy buttons
/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["buy_item"])
		var/item_name = href_list["buy_item"]
		
		// Find merchant component
		for(var/datum/component/merchant_inventory/comp in src)
			if(comp.buy_item(src, item_name))
				return
	
	. = ..()

// Player verb to interact with nearby merchants
/client/verb/interact_merchant()
	set name = "Trade"
	set category = "Interaction"
	
	var/mob/living/carbon/human/nearest_merchant = null
	
	for(var/mob/living/carbon/human/H in range(3, usr))
		if(H != usr && (H in GLOB.traveling_merchants || lowertext(H.name) == "wanderin' willy" || lowertext(H.name) == "dusty dan" || lowertext(H.name) == "canyon carol"))
			nearest_merchant = H
			break
	
	if(!nearest_merchant)
		to_chat(usr, span_warning("No merchant nearby."))
		return
	
	// Trigger trade UI
	for(var/datum/component/merchant_inventory/comp in nearest_merchant)
		comp.show_trade_ui(usr, nearest_merchant)
		break

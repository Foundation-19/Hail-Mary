/*
	Bounty quest definitions (Hail-Mary sync)
	Only uses item paths confirmed in the current codebase (see crafting/food/trash/explosives modules).
*/

/datum/bounty_quest
	var/name = "Contract"
	var/desc = "A posted contract from the wastes."
	var/employer = "Unknown"

	/* Items needed to complete this contract */
	var/list/target_items = list()

	/* Optional bonus items for higher payout */
	var/list/bonus_items = list()

	/* Caps dispensed on completion */
	var/caps_reward = 100

	/* Extra caps if bonus items are delivered */
	var/bonus_reward = 0

	/* Message shown to the player on completion */
	var/end_message = "*Beep* Contract fulfilled. Payment dispensing..."

	/* Message shown to the player on completion with bonus */
	var/bonus_end_message = ""

	var/need_message = "Bring items to the pod."

	var/bonus_need_message = ""

	var/employer_icon = "employer_00.png"
	var/employer_icon_folder = "icons/bounty_employers/"

/datum/bounty_quest/proc/ItsATarget(var/target)
	for(var/target_type in target_items)
		if(istype(target, target_type))
			return TRUE
	for(var/target_type in bonus_items)
		if(istype(target, target_type))
			return TRUE
	return FALSE

/datum/bounty_quest/proc/HasBonus()
	return bonus_items && bonus_items.len && bonus_reward > 0

/datum/bounty_quest/proc/CheckTargets(var/list/items, var/list/quest_objects)
	if(!items || !items.len)
		return FALSE
	var/list/pending = items.Copy()
	for(var/atom/A in quest_objects)
		for(var/target_type in pending)
			if(istype(A, target_type))
				pending[target_type] = max(0, pending[target_type] - 1)
	for(var/k in pending)
		if(pending[k] > 0)
			return FALSE
	return TRUE

/datum/bounty_quest/proc/GetIconWithPath()
	return text2path("[employer_icon_folder][employer_icon]")

// Wasteland contract pool (used by bounty machines)
/datum/bounty_quest/faction/wasteland
	name = "Wasteland Contract"
	desc = "A contract posted to an automated RobCo board."
	employer = "Wasteland Board"
	employer_icon = "employer_00.png"
	need_message = "Bring the required items to the pod."
	end_message = "Good work. Payment authorized."
	caps_reward = 100


/datum/bounty_quest/faction/wasteland/qst_000
	name = "Contract: Patch Kit"
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Caravan canvas is shredded. Bring 6 rolls of duct tape to the pod."
	end_message = "Good. The caravans keep moving."
	target_items = list(/obj/item/crafting/duct_tape = 6)
	caps_reward = 450
	bonus_need_message = "Bonus: add 2 Wonderglue for a reinforced patch."
	bonus_end_message = "Excellent. That's a proper field fix."
	bonus_items = list(/obj/item/crafting/wonderglue = 2)
	bonus_reward = 200


/datum/bounty_quest/faction/wasteland/qst_001
	name = "Contract: Clean Sweep"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Our camp is drowning in pre-war junk. Bring 10 empty tins."
	end_message = "Nice. Less trash, fewer rats."
	target_items = list(/obj/item/trash/f13/tin = 10)
	caps_reward = 250


/datum/bounty_quest/faction/wasteland/qst_002
	name = "Contract: Abrasive Supplies"
	employer = "Field Medic"
	employer_icon = "employer_05.png"
	need_message = "Need cleaning chems for wound prep. Bring 4 boxes of Abraxo."
	end_message = "Perfect. This'll keep infections down."
	target_items = list(/obj/item/crafting/abraxo = 4)
	caps_reward = 380


/datum/bounty_quest/faction/wasteland/qst_003
	name = "Contract: Glue Run"
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Repairs need proper adhesive. Bring 3 Wonderglue."
	end_message = "That'll do. Here's your pay."
	target_items = list(/obj/item/crafting/wonderglue = 3)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_004
	name = "Contract: Basic Electronics"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "We're rebuilding old kit. Bring 3 capacitors, 3 diodes, and 3 transistors."
	end_message = "Acceptable. Components received."
	target_items = list(/obj/item/crafting/capacitor = 3, /obj/item/crafting/diode = 3, /obj/item/crafting/transistor = 3)
	caps_reward = 950
	bonus_need_message = "Bonus: include 4 resistors for control boards."
	bonus_end_message = "Full set received. You'll be credited."
	bonus_items = list(/obj/item/crafting/resistor = 4)
	bonus_reward = 300


/datum/bounty_quest/faction/wasteland/qst_005
	name = "Contract: Resistor Bundle"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Need resistors for control boards. Bring 8 resistors."
	end_message = "Received. Payment authorized."
	target_items = list(/obj/item/crafting/resistor = 8)
	caps_reward = 600


/datum/bounty_quest/faction/wasteland/qst_006
	name = "Contract: Fuse Stock"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Outpost generators keep popping. Bring 6 fuses."
	end_message = "Good work. Keep the lights on."
	target_items = list(/obj/item/crafting/fuse = 6)
	caps_reward = 550


/datum/bounty_quest/faction/wasteland/qst_007
	name = "Contract: Gearbox Parts"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Bring 4 small gears and 2 large gears."
	end_message = "Solid haul. That's useful metal."
	target_items = list(/obj/item/crafting/small_gear = 4, /obj/item/crafting/large_gear = 2)
	caps_reward = 700


/datum/bounty_quest/faction/wasteland/qst_008
	name = "Contract: Scrap Lunch"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Troops want something that isn't dirt. Bring 6 MREs."
	end_message = "Rations received. Here's your caps."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/mre = 6)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_009
	name = "Contract: BlamCo Stack"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 6 boxes of BlamCo Mac & Cheese."
	end_message = "Food is food. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/blamco = 6)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_010
	name = "Contract: Sugar Bombs"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Somebody's paying stupid money for Sugar Bombs. Bring 5 boxes."
	end_message = "Heh. People will buy anything."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/sugarbombs = 5)
	caps_reward = 650


/datum/bounty_quest/faction/wasteland/qst_011
	name = "Contract: Cram Delivery"
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Bring 6 cans of Cram."
	end_message = "Gross. But it sells."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/cram = 6)
	caps_reward = 500


/datum/bounty_quest/faction/wasteland/qst_012
	name = "Contract: Dandy Apples"
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Bring 6 boxes of Dandy Boy Apples."
	end_message = "Sweet. Literally."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/dandyapples = 6)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_013
	name = "Contract: Crisps"
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Bring 8 packs of Crisps."
	end_message = "Delivered. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/crisps = 8)
	caps_reward = 480


/datum/bounty_quest/faction/wasteland/qst_014
	name = "Contract: Pork n' Beans"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 6 cans of Pork n' Beans."
	end_message = "Decent. Better than starving."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/canned/porknbeans = 6)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_015
	name = "Contract: Campfire Kits"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Bring 2 campfire kits for a new camp."
	end_message = "Good. We'll survive another night."
	target_items = list(/obj/item/crafting/campfirekit = 2)
	caps_reward = 420
	bonus_need_message = "Bonus: include 3 bottles of turpentine to seal the frames."
	bonus_end_message = "Supply complete. Fires will keep burning."
	bonus_items = list(/obj/item/crafting/turpentine = 3)
	bonus_reward = 180


/datum/bounty_quest/faction/wasteland/qst_016
	name = "Contract: Turpentine"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Bring 3 bottles of turpentine. Need it for stripping and sealing."
	end_message = "Careful stuff. Good delivery."
	target_items = list(/obj/item/crafting/turpentine = 3)
	caps_reward = 480


/datum/bounty_quest/faction/wasteland/qst_017
	name = "Contract: Switches"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 4 switches for control panels."
	end_message = "Adequate. Logged and stored."
	target_items = list(/obj/item/crafting/switch_crafting = 4)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_018
	name = "Contract: Boards"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 4 circuit boards."
	end_message = "Boards received."
	target_items = list(/obj/item/crafting/board = 4)
	caps_reward = 650


/datum/bounty_quest/faction/wasteland/qst_019
	name = "Contract: Bulbs"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 6 light bulbs."
	end_message = "Outpost lighting restored. Paid."
	target_items = list(/obj/item/crafting/bulb = 6)
	caps_reward = 420


/datum/bounty_quest/faction/wasteland/qst_020
	name = "Contract: Buzzers"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 4 buzzers for alarm systems."
	end_message = "Good. Security improves."
	target_items = list(/obj/item/crafting/buzzer = 4)
	caps_reward = 520


/datum/bounty_quest/faction/wasteland/qst_021
	name = "Contract: Lunchbox Cache"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Bring 4 lunchboxes. Don't ask."
	end_message = "Heh. Fine. Paid."
	target_items = list(/obj/item/crafting/lunchbox = 4)
	caps_reward = 450


/datum/bounty_quest/faction/wasteland/qst_022
	name = "Contract: Bottlecap Mines"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "We need area denial. Bring 2 bottlecap mines. Keep your fingers."
	end_message = "Good. Try not to blow yourself up next time."
	target_items = list(/obj/item/bottlecap_mine = 2)
	caps_reward = 1400


/datum/bounty_quest/faction/wasteland/qst_023
	name = "Contract: Shrapnel Mine"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 1 shrapnel mine."
	end_message = "Received. Payment approved."
	target_items = list(/obj/item/mine/shrapnel = 1)
	caps_reward = 1200


/datum/bounty_quest/faction/wasteland/qst_024
	name = "Contract: EMP Mine"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 1 EMP mine. We're testing it on a captured bot."
	end_message = "Excellent. Data will be collected."
	target_items = list(/obj/item/mine/emp = 1)
	caps_reward = 1600


/datum/bounty_quest/faction/wasteland/qst_025
	name = "Contract: Plasma Gas Mine"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 1 plasma gas mine. Do not drop it."
	end_message = "You delivered it intact. Impressive."
	target_items = list(/obj/item/mine/gas/plasma = 1)
	caps_reward = 1800





/datum/bounty_quest/faction/wasteland/qst_027
	name = "Contract: Stocks"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Bring 2 weapon stocks."
	end_message = "Good lumber and metal. Paid."
	target_items = list(/obj/item/weaponcrafting/stock = 2)
	caps_reward = 850

/datum/bounty_quest/faction/wasteland/qst_028
	name = "Contract: Lunchbox Stack"
	employer = "Camp Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 8 lunchboxes. Storage is a mess."
	end_message = "Good. That's actually useful."
	target_items = list(/obj/item/crafting/lunchbox = 8)
	caps_reward = 700

/datum/bounty_quest/faction/wasteland/qst_029
	name = "Contract: Frames for Fabrication"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 4 frames. We need mounts for repairs."
	end_message = "Frames received. Logged."
	target_items = list(/obj/item/crafting/frame = 4)
	caps_reward = 850

/datum/bounty_quest/faction/wasteland/qst_030
	name = "Contract: Coffee Pot"
	employer = "Caravan Cook"
	employer_icon = "employermerc.png"
	need_message = "Bring 2 coffee pots. Morale is collapsing."
	end_message = "Bless you. Paid."
	target_items = list(/obj/item/crafting/coffee_pot = 2)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_031
	name = "Contract: Repair Bundle"
	employer = "Wasteland Scavengers Union"
	employer_icon = "employer_03.png"
	need_message = "Bring 3 duct tape and 2 wonderglue."
	end_message = "That’ll keep junk together. Paid."
	target_items = list(/obj/item/crafting/duct_tape = 3, /obj/item/crafting/wonderglue = 2)
	caps_reward = 520

/datum/bounty_quest/faction/wasteland/qst_032
	name = "Contract: Cleanup Crew"
	employer = "Town Council"
	employer_icon = "employer_05.png"
	need_message = "Bring 6 tins. Yeah. Seriously."
	end_message = "Disgusting. Thank you."
	target_items = list(/obj/item/trash/f13/tin = 6)
	caps_reward = 420

/datum/bounty_quest/faction/wasteland/qst_033
	name = "Contract: Big Tin Haul"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 6 large tins."
	end_message = "Nice. Heavy metal. Paid."
	target_items = list(/obj/item/trash/f13/tin_large = 6)
	caps_reward = 520

/datum/bounty_quest/faction/wasteland/qst_034
	name = "Contract: BlamCo Bulk"
	employer = "Camp Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 4 BlamCo and 2 large BlamCo."
	end_message = "Carbs acquired. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/blamco = 4, /obj/item/reagent_containers/food/snacks/f13/blamco/large = 2)
	caps_reward = 680

/datum/bounty_quest/faction/wasteland/qst_035
	name = "Contract: Cram Cases"
	employer = "Camp Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 4 Cram and 2 large Cram."
	end_message = "War rations secured. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/cram = 4, /obj/item/reagent_containers/food/snacks/f13/cram/large = 2)
	caps_reward = 650

/datum/bounty_quest/faction/wasteland/qst_036
	name = "Contract: Fancy Lads"
	employer = "Caravan Merchant"
	employer_icon = "employermerc.png"
	need_message = "Bring 6 boxes of Fancy Lads Snack Cakes."
	end_message = "Sweet. Customers love these."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/fancylads = 6)
	caps_reward = 700

/datum/bounty_quest/faction/wasteland/qst_037
	name = "Contract: InstaMash"
	employer = "Camp Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 6 boxes of InstaMash."
	end_message = "Mash is mash. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/instamash = 6)
	caps_reward = 620

/datum/bounty_quest/faction/wasteland/qst_038
	name = "Contract: YumYum"
	employer = "Caravan Merchant"
	employer_icon = "employermerc.png"
	need_message = "Bring 8 YumYum Deviled Eggs."
	end_message = "Disgusting. Profitable. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/yumyum = 8)
	caps_reward = 700

/datum/bounty_quest/faction/wasteland/qst_039
	name = "Contract: Bubblegum"
	employer = "Trader"
	employer_icon = "employermerc.png"
	need_message = "Bring 10 packs of bubblegum."
	end_message = "Kids still exist somehow. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/bubblegum = 10)
	caps_reward = 650

/datum/bounty_quest/faction/wasteland/qst_040
	name = "Contract: Big Bubblegum"
	employer = "Trader"
	employer_icon = "employermerc.png"
	need_message = "Bring 6 large bubblegum packs."
	end_message = "Nice. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/bubblegum/large = 6)
	caps_reward = 700

/datum/bounty_quest/faction/wasteland/qst_041
	name = "Contract: Caravan Lunches"
	employer = "Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Bring 6 caravan lunches."
	end_message = "Good. Road food."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/caravanlunch = 6)
	caps_reward = 620




/datum/bounty_quest/faction/wasteland/qst_045
	name = "Contract: Switchboard Parts"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 3 switches and 3 buzzers."
	end_message = "This will do."
	target_items = list(/obj/item/crafting/switch_crafting = 3, /obj/item/crafting/buzzer = 3)
	caps_reward = 650

/datum/bounty_quest/faction/wasteland/qst_046
	name = "Contract: Lighting Refit"
	employer = "Town Electrician"
	employer_icon = "employer_05.png"
	need_message = "Bring 8 bulbs and 4 fuses."
	end_message = "Finally. Light."
	target_items = list(/obj/item/crafting/bulb = 8, /obj/item/crafting/fuse = 4)
	caps_reward = 700

/datum/bounty_quest/faction/wasteland/qst_047
	name = "Contract: Circuit Pack"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 2 boards, 4 resistors, 2 capacitors."
	end_message = "Components confirmed."
	target_items = list(/obj/item/crafting/board = 2, /obj/item/crafting/resistor = 4, /obj/item/crafting/capacitor = 2)
	caps_reward = 900

/datum/bounty_quest/faction/wasteland/qst_048
	name = "Contract: Control Board Kit"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 2 boards, 2 diodes, 2 transistors."
	end_message = "Good. Paid."
	target_items = list(/obj/item/crafting/board = 2, /obj/item/crafting/diode = 2, /obj/item/crafting/transistor = 2)
	caps_reward = 950

/datum/bounty_quest/faction/wasteland/qst_049
	name = "Contract: Gear Train"
	employer = "Mechanic"
	employer_icon = "employer_03.png"
	need_message = "Bring 6 small gears and 3 large gears."
	end_message = "Nice. Paid."
	target_items = list(/obj/item/crafting/small_gear = 6, /obj/item/crafting/large_gear = 3)
	caps_reward = 1000

/datum/bounty_quest/faction/wasteland/qst_050
	name = "Contract: Solvent & Cleaner"
	employer = "Workshop Foreman"
	employer_icon = "employer_03.png"
	need_message = "Bring 2 turpentine and 2 Abraxo."
	end_message = "Good. This is real work."
	target_items = list(/obj/item/crafting/turpentine = 2, /obj/item/crafting/abraxo = 2)
	caps_reward = 620

/datum/bounty_quest/faction/wasteland/qst_051
	name = "Contract: Bottlecap Mine Pair"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 2 bottlecap mines. Don’t set them off."
	end_message = "Area denial delivered. Paid."
	target_items = list(/obj/item/bottlecap_mine = 2)
	caps_reward = 1500

/datum/bounty_quest/faction/wasteland/qst_052
	name = "Contract: Shrapnel Mine"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 1 shrapnel mine."
	end_message = "Received."
	target_items = list(/obj/item/mine/shrapnel = 1)
	caps_reward = 1200

/datum/bounty_quest/faction/wasteland/qst_053
	name = "Contract: Shrapnel Mine Pair"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 2 shrapnel mines."
	end_message = "Received."
	target_items = list(/obj/item/mine/shrapnel = 2)
	caps_reward = 2200

/datum/bounty_quest/faction/wasteland/qst_054
	name = "Contract: EMP Mine"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 1 EMP mine."
	end_message = "Excellent."
	target_items = list(/obj/item/mine/emp = 1)
	caps_reward = 1600

/datum/bounty_quest/faction/wasteland/qst_055
	name = "Contract: Plasma Gas Mine"
	employer = "Brotherhood Scribe"
	employer_icon = "employer_02.png"
	need_message = "Bring 1 plasma gas mine. Carefully."
	end_message = "Intact. Good."
	target_items = list(/obj/item/mine/gas/plasma = 1)
	caps_reward = 1800

/datum/bounty_quest/faction/wasteland/qst_056
	name = "Contract: NCR C-Rations"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 10 NCR C-ration trash packs (1, 2, or 3)."
	end_message = "Even trash tells us what was issued. Paid."
	target_items = list(/obj/item/trash/f13/c_ration_1 = 4, /obj/item/trash/f13/c_ration_2 = 3, /obj/item/trash/f13/c_ration_3 = 3)
	caps_reward = 650

/datum/bounty_quest/faction/wasteland/qst_057
	name = "Contract: K-Ration Trash"
	employer = "Archivist"
	employer_icon = "employer_05.png"
	need_message = "Bring 8 K-ration trash packs."
	end_message = "Catalogued. Paid."
	target_items = list(/obj/item/trash/f13/k_ration = 8)
	caps_reward = 520

/datum/bounty_quest/faction/wasteland/qst_058
	name = "Contract: Sugar Bombs Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 Sugar Bombs trash boxes."
	end_message = "Lightweight, but it sells."
	target_items = list(/obj/item/trash/f13/sugarbombs = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_059
	name = "Contract: YumYum Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 YumYum trash boxes."
	end_message = "Gross. Paid."
	target_items = list(/obj/item/trash/f13/yumyum = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_060
	name = "Contract: Fancy Lads Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 Fancy Lads trash boxes."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/fancylads = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_061
	name = "Contract: InstaMash Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 InstaMash trash boxes."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/instamash = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_062
	name = "Contract: BlamCo Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 BlamCo trash boxes."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/blamco = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_063
	name = "Contract: Cram Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 Cram trash tins."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/cram = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_064
	name = "Contract: Crisps Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 Crisps trash packs."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/crisps = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_065
	name = "Contract: Dandy Apples Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 Dandy Apples trash boxes."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/dandyapples = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_066
	name = "Contract: Pork n' Beans Trash"
	employer = "Scrap Dealer"
	employer_icon = "employer_03.png"
	need_message = "Bring 10 Pork n' Beans trash cans."
	end_message = "Paid."
	target_items = list(/obj/item/trash/f13/porknbeans = 10)
	caps_reward = 450

/datum/bounty_quest/faction/wasteland/qst_067
	name = "Contract: MRE Trash"
	employer = "NCR Quartermaster"
	employer_icon = "employer_00.png"
	need_message = "Bring 10 MRE trash packs."
	end_message = "Paper trail matters. Paid."
	target_items = list(/obj/item/trash/f13/mre = 10)
	caps_reward = 520



/datum/bounty_quest/faction/wasteland/qst_069
	name = "Contract: Borscht Cans"
	employer = "Collector"
	employer_icon = "employer_05.png"
	need_message = "Bring 6 borscht cans."
	end_message = "Niche. Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/canned/borscht = 6)
	caps_reward = 900

/datum/bounty_quest/faction/wasteland/qst_070
	name = "Contract: Dog Food"
	employer = "Collector"
	employer_icon = "employer_05.png"
	need_message = "Bring 6 cans of dog food."
	end_message = "Paid."
	target_items = list(/obj/item/reagent_containers/food/snacks/f13/canned/dog = 6)
	caps_reward = 850

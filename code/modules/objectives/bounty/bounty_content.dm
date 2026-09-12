/*
	Placeholder bounty board content, 3-5 contracts per pool per the v1 build plan. Fleshing
	these out further (more variety, better balancing) is expected follow-up content work, not
	systems work - see /datum/bounty_contract in _bounty_contract.dm for the fields to fill in.
*/

// ============================== UNIVERSAL ==============================

/datum/bounty_contract/universal/deathclaw_hide
	name = "Deathclaw Cull"
	employer = "Wasteland Bounty Board"
	flavor = "Deathclaws are thinning the trade routes. Hides prove the kill."
	required_type = /obj/item/stack/sheet/animalhide/deathclaw
	required_count = 12
	reward_crate_type = /obj/structure/closet/crate/bounty/melee_high
	reward_points = 15

/datum/bounty_contract/universal/scrap_metal
	name = "Scrap Drive"
	employer = "Wasteland Bounty Board"
	flavor = "Every settlement needs raw metal more than it needs whatever you found it holding up."
	required_type = /obj/item/stack/sheet/metal
	required_count = 50
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/universal/caps_tax
	name = "Debt Collection"
	employer = "Wasteland Bounty Board"
	flavor = "Somebody owes somebody. Bring the caps, don't ask questions."
	required_type = /obj/item/stack/f13Cash/caps
	required_count = 200
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/universal/purified_water
	name = "Water Rationing"
	employer = "Wasteland Bounty Board"
	flavor = "Clean water is worth more than caps out here. Bring bottled water to the board - full bottles, not empties."
	required_type = /obj/item/reagent_containers/glass/beaker/waterbottle
	required_count = 15
	required_reagent_type = /datum/reagent/water
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/universal/uranium_cleanup
	name = "Radioactive Cleanup"
	employer = "Wasteland Bounty Board"
	flavor = "Nobody wants that ore sitting around glowing. Bring it in for proper disposal."
	required_type = /obj/item/stack/ore/uranium
	required_count = 10
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

GLOBAL_LIST_INIT(bounty_contract_pool_universal, list(
	/datum/bounty_contract/universal/deathclaw_hide,
	/datum/bounty_contract/universal/scrap_metal,
	/datum/bounty_contract/universal/caps_tax,
	/datum/bounty_contract/universal/purified_water,
	/datum/bounty_contract/universal/uranium_cleanup,
))

// ============================== BROTHERHOOD OF STEEL (tech/energy) ==============================

/datum/bounty_contract/bos/microfusion
	name = "Fusion Cell Requisition"
	employer = "Brotherhood Quartermaster"
	flavor = "The Brotherhood always needs charged cells for the field teams."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/stock_parts/cell/high
	required_count = 5
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 15

/datum/bounty_contract/bos/scrap_tech
	name = "Pre-War Tech Salvage"
	employer = "Brotherhood Scribe"
	flavor = "Bring back reclaimable tech scrap for study, Brother."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/stack/sheet/metal
	required_count = 30
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 12

/datum/bounty_contract/bos/tools
	name = "Field Tool Kit"
	employer = "Brotherhood Quartermaster"
	flavor = "Every squire needs a working weldingtool."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/weldingtool
	required_count = 3
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 8

/datum/bounty_contract/bos/fusion_cores
	name = "Core Requisition"
	employer = "Brotherhood Quartermaster"
	flavor = "The generators don't run on faith, Brother. Bring fresh fusion cores."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/f13/fusion_core
	required_count = 5
	reward_crate_type = /obj/structure/closet/crate/bounty/energy_arms
	reward_points = 20
	min_reputation = 3
	reputation_gain = 2

GLOBAL_LIST_INIT(bounty_contract_pool_bos, list(
	/datum/bounty_contract/bos/microfusion,
	/datum/bounty_contract/bos/scrap_tech,
	/datum/bounty_contract/bos/tools,
	/datum/bounty_contract/bos/recon_gear,
	/datum/bounty_contract/bos/fusion_cores,
	/datum/bounty_contract/bos/medical_requisition,
	/datum/bounty_contract/bos/black_market_parts,
	/datum/bounty_contract/bos/archive_recovery,
	/datum/bounty_contract/crossfaction/tribal_outreach,
))

/datum/bounty_contract/bos/recon_gear
	name = "Recon Gear Recovery"
	employer = "Brotherhood Scribe"
	flavor = "Squires don't get handed the good tech until scribes can vouch for them. Start by returning our field gear."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/geiger_counter
	required_count = 4
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/bos/medical_requisition
	name = "Field Medical Stock"
	employer = "Brotherhood Paladin-Medic"
	flavor = "Squires bleed same as anyone. Bring stimpaks for the infirmary."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/reagent_containers/hypospray/medipen/stimpak
	required_count = 6
	reward_crate_type = /obj/structure/closet/crate/bounty/chems
	reward_points = 12

/datum/bounty_contract/bos/black_market_parts
	name = "Off-the-Books Parts Trade"
	employer = "Brotherhood Scribe"
	flavor = "A scribe wants spare cells quietly, no paperwork, no questions from anyone watching the Brotherhood."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/stock_parts/cell/high
	required_count = 3
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10
	quiet_dealing = TRUE

/datum/bounty_contract/bos/archive_recovery
	name = "Archive Recovery"
	employer = "Brotherhood Elder"
	flavor = "Only proven Brothers get sent after the deep archives. Bring back the hardened cells inside."
	faction = FACTION_BROTHERHOOD
	required_type = /obj/item/stock_parts/cell/high/plus
	required_count = 3
	reward_crate_type = /obj/structure/closet/crate/bounty/energy_arms
	reward_points = 25
	min_reputation = 4
	reputation_gain = 2

// ============================== LEGION (kill-focused) ==============================

/datum/bounty_contract/legion/deathclaw_hunt
	name = "Prove Your Strength"
	employer = "Legion Centurion"
	flavor = "Caesar rewards those who bring death to the wasteland's beasts."
	faction = FACTION_LEGION
	required_type = /obj/item/stack/sheet/animalhide/deathclaw
	required_count = 8
	reward_crate_type = /obj/structure/closet/crate/bounty/melee_high
	reward_points = 15
	min_reputation = 1

/datum/bounty_contract/legion/raider_trophies
	name = "Raider Purge"
	employer = "Legion Centurion"
	flavor = "Bring proof you've cleared the raider filth from Legion territory."
	faction = FACTION_LEGION
	required_type = /obj/item/stack/sheet/animalhide/human
	required_count = 6
	reward_crate_type = /obj/structure/closet/crate/bounty/armor
	reward_points = 12
	min_reputation = 2
	reputation_gain = 2

/datum/bounty_contract/legion/scrap_machines
	name = "Machine Purge"
	employer = "Legion Centurion"
	flavor = "Caesar has no love for NCR or raider machines. Bring back the wreckage."
	faction = FACTION_LEGION
	required_type = /obj/item/stack/sheet/metal
	required_count = 20
	reward_crate_type = /obj/structure/closet/crate/bounty/melee_low
	reward_points = 10

/datum/bounty_contract/legion/chem_confiscation
	name = "Chem Confiscation"
	employer = "Legion Centurion"
	flavor = "Caesar's soldiers don't touch the stuff, but Caesar's coffers don't mind selling it back to the weak."
	faction = FACTION_LEGION
	required_type = /obj/item/reagent_containers/pill/buffout
	required_count = 10
	reward_crate_type = /obj/structure/closet/crate/bounty/caps
	reward_points = 10

/datum/bounty_contract/legion/quiet_trade
	name = "Quiet Trade"
	employer = "Legion Centurion"
	flavor = "Small enough that nobody watching the Legion's movements will notice a thing."
	faction = FACTION_LEGION
	required_type = /obj/item/stack/sheet/metal
	required_count = 15
	reward_crate_type = /obj/structure/closet/crate/bounty/caps
	reward_points = 10
	quiet_dealing = TRUE

/datum/bounty_contract/legion/proving_grounds
	name = "Proving Grounds"
	employer = "Legion Legate"
	flavor = "The Legate himself only notices the strongest. Bring proof worthy of his attention."
	faction = FACTION_LEGION
	required_type = /obj/item/stack/sheet/animalhide/deathclaw
	required_count = 15
	reward_crate_type = /obj/structure/closet/crate/bounty/melee_high
	reward_points = 25
	min_reputation = 4
	reputation_gain = 2

GLOBAL_LIST_INIT(bounty_contract_pool_legion, list(
	/datum/bounty_contract/legion/deathclaw_hunt,
	/datum/bounty_contract/legion/raider_trophies,
	/datum/bounty_contract/legion/scrap_machines,
	/datum/bounty_contract/legion/chem_confiscation,
	/datum/bounty_contract/legion/quiet_trade,
	/datum/bounty_contract/legion/proving_grounds,
))

// ============================== NCR (generic military) ==============================

/datum/bounty_contract/ncr/ammo
	name = "Ammunition Resupply"
	employer = "NCR Quartermaster"
	flavor = "Rangers need their boxes stocked. Bring 5.56 to the depot."
	faction = FACTION_NCR
	required_type = /obj/item/ammo_box/a556
	required_count = 3
	reward_crate_type = /obj/structure/closet/crate/bounty/armor
	reward_points = 12
	min_reputation = 1

/datum/bounty_contract/ncr/road_clearing
	name = "Route Clearance"
	employer = "NCR Quartermaster"
	flavor = "Rangers don't hand rifles to unknowns. Prove the road's clear of raiders first."
	faction = FACTION_NCR
	required_type = /obj/item/stack/sheet/animalhide/human
	required_count = 10
	reward_crate_type = /obj/structure/closet/crate/bounty/arms
	reward_points = 18
	min_reputation = 2
	reputation_gain = 2

/datum/bounty_contract/ncr/caps
	name = "War Bonds"
	employer = "NCR Quartermaster"
	flavor = "The Republic runs on caps as much as bullets."
	faction = FACTION_NCR
	required_type = /obj/item/stack/f13Cash/caps
	required_count = 150
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/ncr/tools
	name = "Engineer Corps Supply"
	employer = "NCR Quartermaster"
	flavor = "Combat engineers always need more scrap metal for fieldworks."
	faction = FACTION_NCR
	required_type = /obj/item/stack/sheet/metal
	required_count = 40
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/ncr/medical_corps
	name = "Medical Corps Resupply"
	employer = "NCR Field Medic"
	flavor = "Rangers get hurt out there. Bring stimpaks and radaway for the aid station."
	faction = FACTION_NCR
	required_type = /obj/item/reagent_containers/blood/radaway
	required_count = 6
	reward_crate_type = /obj/structure/closet/crate/bounty/chems
	reward_points = 12

/datum/bounty_contract/ncr/backchannel_trade
	name = "Backchannel Trade"
	employer = "NCR Quartermaster"
	flavor = "Small enough that it won't reach anyone keeping tabs on the Republic's dealings."
	faction = FACTION_NCR
	required_type = /obj/item/stack/sheet/metal
	required_count = 15
	reward_crate_type = /obj/structure/closet/crate/bounty/caps
	reward_points = 10
	quiet_dealing = TRUE

/datum/bounty_contract/ncr/officer_commission
	name = "Officer's Commission"
	employer = "NCR Ranger Command"
	flavor = "Ranger Command doesn't commission just anyone. Prove yourself against the raiders first."
	faction = FACTION_NCR
	required_type = /obj/item/stack/sheet/animalhide/human
	required_count = 20
	reward_crate_type = /obj/structure/closet/crate/bounty/arms
	reward_points = 25
	min_reputation = 4
	reputation_gain = 2

GLOBAL_LIST_INIT(bounty_contract_pool_ncr, list(
	/datum/bounty_contract/ncr/ammo,
	/datum/bounty_contract/ncr/caps,
	/datum/bounty_contract/ncr/tools,
	/datum/bounty_contract/ncr/road_clearing,
	/datum/bounty_contract/ncr/medical_corps,
	/datum/bounty_contract/ncr/backchannel_trade,
	/datum/bounty_contract/ncr/officer_commission,
	/datum/bounty_contract/crossfaction/tribal_outreach,
))

// ============================== CROSS-FACTION (rolled onto more than one board) ==============================
// Not tied to a single pool - the same contract typepath is listed in multiple faction
// GLOBAL_LIST_INIT pools above so it can be rolled on either board.

/datum/bounty_contract/crossfaction/tribal_outreach
	name = "Tribal Out-reach Program"
	employer = "Frontier Liaison Office"
	flavor = "NCR and Brotherhood both want the tribes talking instead of raiding. Trade goods buy goodwill - bring bitters."
	required_type = /obj/item/reagent_containers/pill/bitterdrink
	required_count = 20
	reward_crate_type = /obj/structure/closet/crate/bounty/arms
	reward_points = 15
	min_reputation = 2
	reputation_gain = 2

// ============================== TOWN (food/trade focused) ==============================

/datum/bounty_contract/town/corn
	name = "Harvest Contract"
	employer = "Town Trading Post"
	flavor = "The market's short on corn this week."
	faction = FACTION_EASTWOOD
	required_type = /obj/item/reagent_containers/food/snacks/grown/corn
	required_count = 20
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 8

/datum/bounty_contract/town/caps
	name = "Trade Investment"
	employer = "Town Trading Post"
	flavor = "Caps keep the caravans running."
	faction = FACTION_EASTWOOD
	required_type = /obj/item/stack/f13Cash/caps
	required_count = 100
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 8

/datum/bounty_contract/town/hides
	name = "Tannery Order"
	employer = "Town Trading Post"
	flavor = "The tannery pays well for fresh hides, no questions asked."
	faction = FACTION_EASTWOOD
	required_type = /obj/item/stack/sheet/animalhide
	required_count = 15
	reward_crate_type = /obj/structure/closet/crate/bounty/supplies
	reward_points = 10

/datum/bounty_contract/town/caravan_guard
	name = "Caravan Guard Contract"
	employer = "Town Trading Post"
	flavor = "The caravan masters want capable hands watching the road - but not before they know your face."
	faction = FACTION_EASTWOOD
	required_type = /obj/item/stack/sheet/animalhide/deathclaw
	required_count = 5
	reward_crate_type = /obj/structure/closet/crate/bounty/arms
	reward_points = 16
	min_reputation = 1
	reputation_gain = 2

/datum/bounty_contract/town/ore_trade
	name = "Prospector's Delivery"
	employer = "Town Trading Post"
	flavor = "The smiths always have a buyer for raw ore, no matter whose pick dug it up."
	faction = FACTION_EASTWOOD
	required_type = /obj/item/stack/ore/blackpowder
	required_count = 15
	reward_crate_type = /obj/structure/closet/crate/bounty/caps
	reward_points = 10

GLOBAL_LIST_INIT(bounty_contract_pool_town, list(
	/datum/bounty_contract/town/corn,
	/datum/bounty_contract/town/caps,
	/datum/bounty_contract/town/hides,
	/datum/bounty_contract/town/caravan_guard,
	/datum/bounty_contract/town/ore_trade,
))

// ============================== EVENT (never auto-rolled, posted by an admin via the bountyevent verb) ==============================

/datum/bounty_contract/event/beast_hunt
	name = "The Beast"
	employer = "Wasteland Bounty Board"
	flavor = "Something's been raiding the caravans and it isn't raiders. Bring back proof it's dead."
	required_type = /obj/item/stack/sheet/animalhide/deathclaw
	required_count = 3
	reward_crate_type = /obj/structure/closet/crate/bounty/melee_high
	reward_points = 30

/datum/bounty_contract/event/relief_effort
	name = "Emergency Relief"
	employer = "Wasteland Bounty Board"
	flavor = "A settlement just got hit hard. They need water and caps, fast, more than they need heroes."
	required_type = /obj/item/reagent_containers/glass/beaker/waterbottle
	required_count = 10
	required_reagent_type = /datum/reagent/water
	required_type_2 = /obj/item/stack/f13Cash/caps
	required_count_2 = 100
	reward_crate_type = /obj/structure/closet/crate/bounty/arms
	reward_points = 25

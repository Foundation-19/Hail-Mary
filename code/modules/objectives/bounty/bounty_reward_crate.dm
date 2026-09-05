/*
	Reward crates for the faction bounty board, see code/modules/objectives/bounty/_bounty_contract.dm
*/

/obj/structure/closet/crate/bounty
	name = "bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Payment for a job well done."
	icon_state = "crate"
	/// Existing curated lootdrop spawner reused for contents instead of inventing a new loot list.
	var/loot_spawner_type

/obj/structure/closet/crate/bounty/PopulateContents()
	. = ..()
	if(loot_spawner_type)
		new loot_spawner_type(src)

// Thin subtypes of the existing lootdrop spawners with spawn_on_turf disabled, so the rolled
// item lands inside the crate's contents instead of on the turf underneath it. Loot lists are
// inherited as-is from the parent tier - no duplication of the curated pools.
// NOTE: armor/gun tiers roll nested /obj/effect/spawner/bundle spawners, which always use
// get_turf() regardless of spawn_on_turf - those items land on the same tile as the crate
// (not inside its storage) but are otherwise unaffected, so it's still fine to use them here.
/obj/effect/spawner/lootdrop/f13/weapon/melee/tier1/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/weapon/melee/tier2/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/weapon/melee/tier4/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/weapon/melee/tier5/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/armor/tier3/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/weapon/gun/ballistic/highmid/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/weapon/gun/energy/mid/incrate
	spawn_on_turf = FALSE

/obj/effect/spawner/lootdrop/f13/medical/vault/meds/incrate
	spawn_on_turf = FALSE

/// "Low tier melee loot-crate" reward - reuses the existing tier 2 melee lootdrop pool.
/obj/structure/closet/crate/bounty/melee_low
	name = "melee weapon bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Sounds like it's got something sharp inside."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/weapon/melee/tier2/incrate

/// High effort melee reward - power tools and unique melee weapons (ripper, chainsaw, supersledge, etc).
/obj/structure/closet/crate/bounty/melee_high
	name = "heavy weapon bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Whatever's in here, it's heavy and it hums."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/weapon/melee/tier5/incrate

/// Generic materials/supplies reward for non-combat contracts (BoS tech turn-ins, Town trade goods, etc).
/obj/structure/closet/crate/bounty/supplies
	name = "supply bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Feels heavy with tools and scrap."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/weapon/melee/tier1/incrate

/// Combat armor set reward for the harder military-flavored contracts.
/obj/structure/closet/crate/bounty/armor
	name = "armor bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Padded and reinforced."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/armor/tier3/incrate

/// Firearm reward for the biggest ballistic-hungry contracts.
/obj/structure/closet/crate/bounty/arms
	name = "arms bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Rattles like a rifle and spare mags."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/weapon/gun/ballistic/highmid/incrate

/// Energy weapon reward, mirrors /arms for BoS/tech-flavored contracts.
/obj/structure/closet/crate/bounty/energy_arms
	name = "energy arms bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Faint capacitor whine from inside."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/weapon/gun/energy/mid/incrate

/// Medical/chem reward for non-combat contracts that don't fit the tool/scrap supplies crate.
/obj/structure/closet/crate/bounty/chems
	name = "medical bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Rattles like pill bottles."
	loot_spawner_type = /obj/effect/spawner/lootdrop/f13/medical/vault/meds/incrate

/// Straight caps payout for contracts that reward hard currency instead of gear.
/obj/structure/closet/crate/bounty/caps
	name = "caps bounty crate"
	desc = "A supply crate stamped with a bounty board seal. Sounds like it's full of caps."
	var/cap_amount = 100

/obj/structure/closet/crate/bounty/caps/PopulateContents()
	. = ..()
	var/obj/item/stack/f13Cash/caps/payout = new(src)
	payout.amount = cap_amount
	payout.use(0) // refreshes the stack sprite/name for the new amount

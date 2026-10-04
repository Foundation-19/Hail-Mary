//Fallout-style ranked "Wasteland Perks" - point-buy quirks that mirror real multi-rank Fallout
//Perks (Gun Nut, Science!, Chemist, Demolition Expert - each 3 ranks). Each family's Rank N+1
//quirk sets `requires_quirk` to Rank N's name; adopting a higher rank via the preferences UI
//automatically refunds/replaces the lower rank (see the "update" Topic() handler in
//code/modules/client/preferences.dm). All ranks within a family still grant the SAME base
//mob_trait as the old flat quirks they replace, since 30+ job files and a VR training room
//grant these flags directly outside the quirk system - only the recipe lists granted differ
//per rank. The matching retired flat quirks are commented out in good.dm. Runtime "skill
//books" that bump a rank by one per read live in code/game/objects/items/granters.dm
//(/obj/item/book/granter/trait/rank).

GLOBAL_LIST_INIT(gunsmith_recipes_basic, list(
	/datum/crafting_recipe/ninemil,
	/datum/crafting_recipe/huntingrifle,
	/datum/crafting_recipe/n99,
	/datum/crafting_recipe/huntingshotgun,
	/datum/crafting_recipe/m1911,
	/datum/crafting_recipe/varmintrifle,
	/datum/crafting_recipe/salvaged_eastern_rifle,
	/datum/crafting_recipe/autoaxe,
	/datum/crafting_recipe/steelsaw,
	/datum/crafting_recipe/tools/forged/entrenching_tool,
	/datum/crafting_recipe/chainsaw,
	/datum/crafting_recipe/steeltower))

GLOBAL_LIST_INIT(gunsmith_recipes_mods, list(
	/datum/crafting_recipe/durathread_vest,
	/datum/crafting_recipe/scope,
	/datum/crafting_recipe/suppressor,
	/datum/crafting_recipe/ergonomic_grip,
	/datum/crafting_recipe/metal_guard,
	/datum/crafting_recipe/forged_barrel,
	/datum/crafting_recipe/booster,
	/datum/crafting_recipe/heatsink,
	/datum/crafting_recipe/laserguide,
	/datum/crafting_recipe/gigalens,
	/datum/crafting_recipe/gun/flintlock))

GLOBAL_LIST_INIT(gunsmith_recipes_master, list(
	/datum/crafting_recipe/ecpbad,
	/datum/crafting_recipe/mfcbad,
	/datum/crafting_recipe/ecbad,
	/datum/crafting_recipe/gun/flintlock_laser))

/* ---------------------------------- Gun Nut ---------------------------------- */

/datum/quirk/gunsmith_rank1
	name = "Gun Nut I"
	desc = "You've got a knack for cobbling together firearms and melee tools from scrap. Unlocks basic weapon crafting recipes."
	value = 2
	mob_trait = TRAIT_WEAPONSMITH
	gain_text = span_notice("You are adept at crafting makeshift weapons.")
	lose_text = span_danger("You feel less adept at crafting makeshift weapons.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 3

/datum/quirk/gunsmith_rank1/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.gunsmith_recipes_basic

/datum/quirk/gunsmith_rank1/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.gunsmith_recipes_basic

/datum/quirk/gunsmith_rank2
	name = "Gun Nut II"
	desc = "Years more practice have taught you gun mods, armored vests, and a few oddities besides. Requires Gun Nut I. Unlocks mod/attachment crafting recipes."
	value = 4
	requires_quirk = "Gun Nut I"
	mob_trait = TRAIT_WEAPONSMITH
	gain_text = span_notice("You've mastered the finer points of weaponsmithing.")
	lose_text = span_danger("You feel less adept at crafting makeshift weapons.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5

/datum/quirk/gunsmith_rank2/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.gunsmith_recipes_basic
	H.mind.learned_recipes |= GLOB.gunsmith_recipes_mods

/datum/quirk/gunsmith_rank2/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.gunsmith_recipes_basic
		H.mind.learned_recipes -= GLOB.gunsmith_recipes_mods

/datum/quirk/gunsmith_rank3
	name = "Gun Nut III"
	desc = "You've gone from gunsmith to weapons master, fabricating the finest energy-weapon-grade components in the Wasteland. Requires Gun Nut II."
	value = 6
	requires_quirk = "Gun Nut II"
	mob_trait = TRAIT_WEAPONSMITH
	gain_text = span_notice("You've achieved true mastery over weaponsmithing.")
	lose_text = span_danger("You feel less adept at crafting makeshift weapons.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7

/datum/quirk/gunsmith_rank3/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.gunsmith_recipes_basic
	H.mind.learned_recipes |= GLOB.gunsmith_recipes_mods
	H.mind.learned_recipes |= GLOB.gunsmith_recipes_master

/datum/quirk/gunsmith_rank3/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.gunsmith_recipes_basic
		H.mind.learned_recipes -= GLOB.gunsmith_recipes_mods
		H.mind.learned_recipes -= GLOB.gunsmith_recipes_master

/* ---------------------------------- Science! ---------------------------------- */

/datum/quirk/technophreak_rank1
	name = "Science! I"
	desc = "You're skilled at breaking down old-war rubble more precisely, gaining more salvage from cars and piles. Unlocks energy weapon cell crafting and power armor repair."
	value = 2
	mob_trait = TRAIT_TECHNOPHREAK
	gain_text = span_notice("Old-War rubble seems considerably more generous to you.")
	lose_text = span_danger("Old-War rubble suddenly seems less generous to you.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 4

/datum/quirk/technophreak_rank1/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.energyweapon_cell_crafting
	H.mind.learned_recipes |= GLOB.pa_repair

/datum/quirk/technophreak_rank1/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.energyweapon_cell_crafting
		H.mind.learned_recipes -= GLOB.pa_repair

/datum/quirk/technophreak_rank2
	name = "Science! II"
	desc = "Your mastery of complex pre-war technology lets you craft top-tier machine parts. Requires Science! I."
	value = 4
	requires_quirk = "Science! I"
	mob_trait = TRAIT_TECHNOPHREAK
	gain_text = span_notice("You've unlocked the deepest secrets of Old-War technology.")
	lose_text = span_danger("Old-War rubble suddenly seems less generous to you.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 6

/datum/quirk/technophreak_rank2/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.energyweapon_cell_crafting
	H.mind.learned_recipes |= GLOB.pa_repair
	H.mind.learned_recipes |= GLOB.tier_three_parts

/datum/quirk/technophreak_rank2/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.energyweapon_cell_crafting
		H.mind.learned_recipes -= GLOB.pa_repair
		H.mind.learned_recipes -= GLOB.tier_three_parts

/datum/quirk/technophreak_rank3
	name = "Science! III"
	desc = "You can overclock and fabricate energy weapons from scratch, a skill almost nobody left alive still has. Requires Science! II."
	value = 6
	requires_quirk = "Science! II"
	mob_trait = TRAIT_TECHNOPHREAK
	gain_text = span_notice("You've achieved true mastery over Old-War technology.")
	lose_text = span_danger("Old-War rubble suddenly seems less generous to you.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 8

/datum/quirk/technophreak_rank3/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.energyweapon_cell_crafting
	H.mind.learned_recipes |= GLOB.pa_repair
	H.mind.learned_recipes |= GLOB.tier_three_parts
	H.mind.learned_recipes |= GLOB.energyweapon_crafting

/datum/quirk/technophreak_rank3/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.energyweapon_cell_crafting
		H.mind.learned_recipes -= GLOB.pa_repair
		H.mind.learned_recipes -= GLOB.tier_three_parts
		H.mind.learned_recipes -= GLOB.energyweapon_crafting

/* ---------------------------------- Chemist ---------------------------------- */

/datum/quirk/chemwhiz_rank1
	name = "Chemist I"
	desc = "You've been playing around with chemicals all your life. You know how to use chemistry machinery and make basic stabilization supplies."
	value = 1
	mob_trait = TRAIT_CHEMWHIZ
	gain_text = span_notice("The mysteries of chemistry are revealed to you.")
	lose_text = span_danger("You forget how the periodic table works.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 3

/datum/quirk/chemwhiz_rank1/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.chemwhiz_recipes_basic

/datum/quirk/chemwhiz_rank1/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.chemwhiz_recipes_basic

/datum/quirk/chemwhiz_rank2
	name = "Chemist II"
	desc = "You've branched out into combat and performance chems. Requires Chemist I."
	value = 2
	requires_quirk = "Chemist I"
	mob_trait = TRAIT_CHEMWHIZ
	gain_text = span_notice("Combat chemistry no longer holds any secrets from you.")
	lose_text = span_danger("You forget how the periodic table works.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5

/datum/quirk/chemwhiz_rank2/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.chemwhiz_recipes_basic
	H.mind.learned_recipes |= GLOB.chemwhiz_recipes_mid

/datum/quirk/chemwhiz_rank2/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.chemwhiz_recipes_basic
		H.mind.learned_recipes -= GLOB.chemwhiz_recipes_mid

/datum/quirk/chemwhiz_rank3
	name = "Chemist III"
	desc = "Decades of practice have taught you advanced chemical formulas. Requires Chemist II."
	value = 4
	requires_quirk = "Chemist II"
	mob_trait = TRAIT_CHEMWHIZ
	gain_text = span_notice("Advanced chemistry no longer holds any secrets from you.")
	lose_text = span_danger("You forget how the periodic table works.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 6

/datum/quirk/chemwhiz_rank3/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.chemwhiz_recipes_basic
	H.mind.learned_recipes |= GLOB.chemwhiz_recipes_mid
	H.mind.learned_recipes |= GLOB.chemwhiz_recipes_advanced

/datum/quirk/chemwhiz_rank3/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.chemwhiz_recipes_basic
		H.mind.learned_recipes -= GLOB.chemwhiz_recipes_mid
		H.mind.learned_recipes -= GLOB.chemwhiz_recipes_advanced

/* ------------------------------ Demolition Expert ------------------------------ */
// Recipe unlocks only (no mob_trait-based on_spawn/remove needed for the damage bonus).
// The actual +30%/+60%/+90% explosive radius bonus is read directly off these quirk typepaths
// by /mob/living/proc/get_demolition_expert_radius_mult() (status_procs.dm) and applied at the
// explosion() call sites in grenade.dm, f13grenade.dm, emgrenade.dm, and projectiles/rocket.dm.

/datum/quirk/explosive_crafting_rank1
	name = "Demolition Expert I"
	desc = "You have strong feelings about the future of industrial society. Unlocks basic explosive crafting recipes, and all explosives you throw or fire hit 30% harder/wider."
	value = 1
	mob_trait = TRAIT_EXPLOSIVE_CRAFTING
	gain_text = span_notice("You feel like you can make a bomb out of anything.")
	lose_text = span_danger("You feel okay with the advancement of technology.")
	locked = TRUE
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 3

/datum/quirk/explosive_crafting_rank1/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.basic_explosive_recipes

/datum/quirk/explosive_crafting_rank1/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.basic_explosive_recipes

/datum/quirk/explosive_crafting_rank2
	name = "Demolition Expert II"
	desc = "Your expertise now extends to incendiary ordnance, and your explosives now hit 60% harder/wider. Requires Demolition Expert I."
	value = 2
	requires_quirk = "Demolition Expert I"
	mob_trait = TRAIT_EXPLOSIVE_CRAFTING
	gain_text = span_notice("You've moved firmly onto several more no-fly lists.")
	lose_text = span_danger("You feel okay with the advancement of technology.")
	locked = TRUE
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 5

/datum/quirk/explosive_crafting_rank2/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.basic_explosive_recipes
	H.mind.learned_recipes |= GLOB.adv_explosive_recipes

/datum/quirk/explosive_crafting_rank2/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.basic_explosive_recipes
		H.mind.learned_recipes -= GLOB.adv_explosive_recipes

/datum/quirk/explosive_crafting_rank3
	name = "Demolition Expert III"
	desc = "You've graduated to the exotic stuff - radiological, EMP, and the biggest rockets money can't buy. Your explosives now hit 90% harder/wider. Requires Demolition Expert II."
	value = 4
	requires_quirk = "Demolition Expert II"
	mob_trait = TRAIT_EXPLOSIVE_CRAFTING
	gain_text = span_notice("You've achieved true mastery over the controlled (and uncontrolled) release of energy.")
	lose_text = span_danger("You feel okay with the advancement of technology.")
	locked = TRUE
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 7

/datum/quirk/explosive_crafting_rank3/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.mind.learned_recipes)
		H.mind.learned_recipes = list()
	H.mind.learned_recipes |= GLOB.basic_explosive_recipes
	H.mind.learned_recipes |= GLOB.adv_explosive_recipes
	H.mind.learned_recipes |= GLOB.exotic_explosive_recipes

/datum/quirk/explosive_crafting_rank3/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H && H.mind)
		H.mind.learned_recipes -= GLOB.basic_explosive_recipes
		H.mind.learned_recipes -= GLOB.adv_explosive_recipes
		H.mind.learned_recipes -= GLOB.exotic_explosive_recipes

/* ----------------------------------- Surgeon ----------------------------------- */
//Unlike the families above, Surgery already had a fully-wired 3-tier trait ladder
//(TRAIT_SURGERY_LOW/MID/HIGH, live-used in code/modules/surgery/*.dm to gate which operations
//can be performed) but only the bottom tier was ever purchasable as a quirk ("Minor Surgery" in
//good.dm, left untouched here for save-compat). These two ranks fill in the missing Mid/High
//tiers using the same requires_quirk chain mechanism, rooted on the existing "Minor Surgery".

/datum/quirk/surgery_rank2
	name = "Intermediate Surgery"
	desc = "Pre-war medical texts and hard-won field experience have taken your surgical skill well past basic first aid. Requires Minor Surgery."
	value = 5
	requires_quirk = "Minor Surgery"
	mob_trait = TRAIT_SURGERY_MID
	gain_text = span_notice("You feel confident handling more complex surgical procedures.")
	lose_text = span_danger("You forget the finer points of surgery.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5

/datum/quirk/surgery_rank3
	name = "Advanced Surgery"
	desc = "You've mastered trauma care and complex procedures few wastelanders ever attempt, cybernetics included. Requires Intermediate Surgery."
	value = 7
	requires_quirk = "Intermediate Surgery"
	mob_trait = TRAIT_SURGERY_HIGH
	gain_text = span_notice("Few procedures remain beyond your surgical expertise.")
	lose_text = span_danger("You forget the finer points of surgery.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7

/* --------------------------------- Big Leagues --------------------------------- */
//Real Fallout 4 "Big Leagues" melee perk (5 in-game ranks, +20% melee damage/rank), compressed
//to 3 ranks here (+20%/+40%/+60%) to fit this codebase's quirk-point economy. Percentage-based
//force bonus is applied directly in code/_onclick/item_attack.dm's force_modifier elif chain -
//only the TOP held rank applies (no stacking), mirroring FO4's single always-replaced perk rank.

/datum/quirk/bigleagues_rank1
	name = "Little Leagues"
	desc = "Swing for the outfield! You deal 20% additional damage with melee weapons."
	value = 1
	mob_trait = TRAIT_LITTLE_LEAGUES
	gain_text = span_notice("You feel like swinging for the outfield!")
	lose_text = span_danger("You feel like skipping practice.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 3

/datum/quirk/bigleagues_rank2
	name = "Big Leagues"
	desc = "Swing away! You deal 40% additional damage with melee weapons. Requires Little Leagues."
	value = 3
	requires_quirk = "Little Leagues"
	mob_trait = TRAIT_BIG_LEAGUES_MID
	gain_text = span_notice("You feel like really swinging away!")
	lose_text = span_danger("You feel like bunting.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 5

/datum/quirk/bigleagues_rank3
	name = "Big Leagues II"
	desc = "Swing for the fences! You deal 60% additional damage with melee weapons. Requires Big Leagues."
	value = 5
	requires_quirk = "Big Leagues"
	mob_trait = TRAIT_BIG_LEAGUES
	gain_text = span_notice("You feel like swinging for the fences!")
	lose_text = span_danger("You feel like bunting.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 7

/* ---------------------------------- Iron Fist ---------------------------------- */
//Real Fallout "Iron Fist" unarmed perk, expanded to 3 ranks on this codebase's existing punch
//damage ladder (IRON/STEEL/TITANIUM_FIST_PUNCH_DAMAGE_LOW/MAX). TRAIT_IRONFIST is also still
//granted for free by the paired Wasteland Trait "Heavy Handed" - safe to hold both at once
//since ADD_TRAIT is refcounted and both apply the identical punch values. All ranks overwrite
//punchdamagelow/high outright (not additive), so no remove() is needed to undo it - whichever
//rank's on_spawn() last fired always leaves the correct final value. Higher ranks naturally
//roll bigger knockdowns too: species.dm's unarmed-attack knockdown check scales off stamina
//damage, which scales directly off punch damage - no separate stagger hook needed.

/datum/quirk/ironfist_rank1
	name = "Iron Fist"
	desc = "You have fists of kung-fury! Increases unarmed damage."
	value = 1
	mob_trait = TRAIT_IRONFIST
	gain_text = span_notice("Your fists feel furious!")
	lose_text = span_danger("Your fists feel calm again.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 3

/datum/quirk/ironfist_rank1/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.dna.species.punchdamagelow = IRON_FIST_PUNCH_DAMAGE_LOW
	H.dna.species.punchdamagehigh = IRON_FIST_PUNCH_DAMAGE_MAX

/datum/quirk/ironfist_rank2
	name = "Steel Fist"
	desc = "You have MASSIVE fists of kung-fury! Increases unarmed damage even MORE. Requires Iron Fist."
	value = 2
	requires_quirk = "Iron Fist"
	mob_trait = TRAIT_STEELFIST
	gain_text = span_notice("Your fists feel MASSIVELY furious!")
	lose_text = span_danger("Your fists feel calm again, what a relief.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 5

/datum/quirk/ironfist_rank2/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.dna.species.punchdamagelow = STEEL_FIST_PUNCH_DAMAGE_LOW
	H.dna.species.punchdamagehigh = STEEL_FIST_PUNCH_DAMAGE_MAX

/datum/quirk/ironfist_rank3
	name = "Titanium Fist"
	desc = "Your fists could punch through a Deathclaw's hide! Increases unarmed damage to its absolute MAXIMUM. Requires Steel Fist."
	value = 4
	requires_quirk = "Steel Fist"
	mob_trait = TRAIT_TITANIUMFIST
	gain_text = span_notice("Your fists feel like solid titanium!")
	lose_text = span_danger("Your fists feel soft and fleshy again.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 7

/datum/quirk/ironfist_rank3/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.dna.species.punchdamagelow = TITANIUM_FIST_PUNCH_DAMAGE_LOW
	H.dna.species.punchdamagehigh = TITANIUM_FIST_PUNCH_DAMAGE_MAX

/* --------------------------------- Life Giver --------------------------------- */
//Real Fallout 4 "Life Giver" HP perk (3 ranks: +HP at ranks 1-2, HP regen unlocked at rank 3).
//All ranks add HP additively via on_spawn(), so remove() IS needed on each - otherwise a
//runtime book rank-up (remove Rank N, add Rank N+1) would leave both bonuses stacked instead
//of upgrading cleanly. Rank 3's passive regen uses on_process() (ticks once per SSquirks wait,
//currently 1 second), matching the existing on_process() pattern used by jolly/optimist.
//Also grants special_stamina_mod_bonus (special_stats.dm) - raw maxHealth ONLY raises the
//health/bleed-out crit buffer, not the separate stamina softcrit/hardcrit thresholds that
//decide most melee knockouts, so a HP-only Life Giver felt weak in actual fights. Each rank
//also raises stamina-crit resilience directly so it helps in both kinds of crit, not just one.

/datum/quirk/lifegiver_rank1
	name = "Life Giver"
	desc = "You embody wellness! Instantly gain +10 maximum Health, and shrug off fatigue a little better."
	value = 1
	mob_trait = TRAIT_LIFEGIVER
	gain_text = span_notice("You feel more healthy than usual.")
	lose_text = span_danger("You feel less healthy than usual.")
	medical_record_text = "Patient has higher capacity for injury."
	locked = TRUE

/datum/quirk/lifegiver_rank1/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.maxHealth += 10
	H.health += 10
	H.special_stamina_mod_bonus += 0.1

/datum/quirk/lifegiver_rank1/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.maxHealth -= 10
		H.health = min(H.health, H.maxHealth)
		H.special_stamina_mod_bonus -= 0.1

/datum/quirk/lifegiver_rank2
	name = "Life Giver II"
	desc = "You embody wellness to the MAX! Instantly gain +20 maximum Health (+30 total), and shrug off fatigue even better. Requires Life Giver."
	value = 3
	requires_quirk = "Life Giver"
	mob_trait = TRAIT_LIFEGIVERPLUS
	gain_text = span_notice("You feel much more healthy than usual.")
	lose_text = span_danger("You feel much less healthy than usual.")
	medical_record_text = "Patient has much higher capacity for injury."
	locked = TRUE

/datum/quirk/lifegiver_rank2/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.maxHealth += 20
	H.health += 20
	H.special_stamina_mod_bonus += 0.2

/datum/quirk/lifegiver_rank2/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.maxHealth -= 20
		H.health = min(H.health, H.maxHealth)
		H.special_stamina_mod_bonus -= 0.2

/datum/quirk/lifegiver_rank3
	name = "Life Giver III"
	desc = "You embody wellness perfected! Instantly gain +40 maximum Health (+70 total), slowly regenerate health over time, and are much harder to exhaust into a stagger. Requires Life Giver II."
	value = 5
	requires_quirk = "Life Giver II"
	mob_trait = TRAIT_LIFEGIVERMAX
	gain_text = span_notice("You feel like you could heal from almost anything.")
	lose_text = span_danger("You feel like your body has lost its resilience.")
	medical_record_text = "Patient shows a remarkable, near-supernatural rate of recovery."
	locked = TRUE

/datum/quirk/lifegiver_rank3/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.maxHealth += 40
	H.health += 40
	H.special_stamina_mod_bonus += 0.35

/datum/quirk/lifegiver_rank3/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.maxHealth -= 40
		H.health = min(H.health, H.maxHealth)
		H.special_stamina_mod_bonus -= 0.35

/datum/quirk/lifegiver_rank3/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD)
		return
	if(H.health < H.maxHealth)
		H.heal_overall_damage(0.4, 0.4, updating_health = TRUE)

/* ------------------------------- Wasteland Trekker ------------------------------- */
//Codebase-original movement perk (no direct real-Fallout equivalent), consumed directly in
//code/modules/mob/living/living_movement.dm (TRAIT_HARD_YARDS checked before TRAIT_SOFT_YARDS,
//so only the higher rank held ever actually applies).

/datum/quirk/trekker_rank1
	name = "Wasteland Wanderer"
	desc = "You've spent some time in the wastes, and can move around them a bit more easily for it."
	value = 2
	mob_trait = TRAIT_SOFT_YARDS
	gain_text = span_notice("Rain or shine only slow you down a little.")
	lose_text = span_danger("You walk with a less sure gait, the ground seeming less firm somehow.")
	locked = TRUE
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 3

/datum/quirk/trekker_rank2
	name = "Wasteland Trekker"
	desc = "You've spent a lot of time wandering the wastes, and for your hard work you out pace most folks when travelling across them. Requires Wasteland Wanderer."
	value = 3
	requires_quirk = "Wasteland Wanderer"
	mob_trait = TRAIT_HARD_YARDS
	gain_text = span_notice("Rain or shine, nothing slows you down.")
	lose_text = span_danger("You walk with a less sure gait, the ground seeming less firm somehow.")
	locked = TRUE
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5

/* -------------------------------- Rad Resistant -------------------------------- */
//Revived from fully-dead-but-fully-wired code in good.dm (radimmunesorta/radimmuneish/radimmune) -
//TRAIT_50_RAD_RESIST/TRAIT_75_RAD_RESIST (living.dm, halves/quarters incoming radiation) and
//TRAIT_RADIMMUNE (life.dm/living.dm, blocks radiation gain entirely) were already fully consumed
//by the engine and by Rad-X's chem effect; they were just never purchasable, same "infrastructure
//built, chargen never extended to expose it" gap as Surgery. Each rank uses a DIFFERENT mob_trait
//(like Surgery, unlike the shared-flag crafting families), so requires_quirk's auto-upgrade
//swap handles it with zero extra mechanism.

/datum/quirk/radresist_rank1
	name = "Rad Resistant I"
	desc = "The wasteland's radiation doesn't bother you as much as most people. Grants 50% innate radiation resistance."
	value = 3
	mob_trait = TRAIT_50_RAD_RESIST
	gain_text = span_notice("You've decided radiation only kind of matters.")
	lose_text = span_danger("You no longer think you should hang out next to rad puddles.")
	locked = TRUE

/datum/quirk/radresist_rank2
	name = "Rad Resistant II"
	desc = "Geiger counters are for suckers, mostly. Grants 75% innate radiation resistance. Requires Rad Resistant I."
	value = 4
	requires_quirk = "Rad Resistant I"
	mob_trait = TRAIT_75_RAD_RESIST
	gain_text = span_notice("You've decided radiation just doesn't matter much.")
	lose_text = span_danger("You no longer feel like you could roll around in a rad puddle for a while.")
	locked = TRUE

/datum/quirk/radresist_rank3
	name = "Rad Resistant III"
	desc = "Geiger counters are for suckers. You are entirely immune to radiation. Requires Rad Resistant II."
	value = 6
	requires_quirk = "Rad Resistant II"
	mob_trait = TRAIT_RADIMMUNE
	gain_text = span_notice("You've decided radiation just doesn't matter.")
	lose_text = span_danger("You no longer feel like you could probably live in a microwave while it's on.")
	locked = TRUE

/* ----------------------------------- Sneak ----------------------------------- */
//Perk-gated exception to the "sneaking no longer reduces sound" design decision in
//get_movement_sound_level() (human.dm) - only mobs holding one of these ranks get quieter
//while in sneak mode (hostile mob rear-detection range, see hostile.dm GetMovementSound()).
//Does not touch the light/vision-cone side of detection, only the sound side.

/datum/quirk/sneak_rank1
	name = "Sneak I"
	desc = "You know how to place your feet. While in sneak mode, you move about half as loud as normal."
	value = 2
	mob_trait = TRAIT_SNEAK_RANK1
	gain_text = span_notice("You feel like you could slip past most people unnoticed.")
	lose_text = span_danger("You've lost your knack for moving quietly.")
	locked = TRUE
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 3

/datum/quirk/sneak_rank2
	name = "Sneak II"
	desc = "You move like a ghost. While in sneak mode, you move about a quarter as loud as normal. Requires Sneak I."
	value = 4
	requires_quirk = "Sneak I"
	mob_trait = TRAIT_SNEAK_RANK2
	gain_text = span_notice("You feel like you could walk right past someone without them noticing.")
	lose_text = span_danger("You've lost your knack for moving like a ghost.")
	locked = TRUE
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5

/* --------------------------------- Strong Back --------------------------------- */
//Stacks an extra flat bonus on top of the existing Strength-based carry capacity scaling
//(get_strength_carry_capacity_multiplier(), code/modules/mob/special_stats.dm) so carry
//capacity has a real, dedicated build identity instead of being a side-effect of a Strength
//stat dump. Consumed directly by the same getter - no other call sites to touch.

/datum/quirk/strongback_rank1
	name = "Strong Back I"
	desc = "Years of hauling scrap and salvage have taught you how to pack a bag properly. +20% carry capacity on top of whatever your Strength provides."
	value = 2
	mob_trait = TRAIT_STRONGBACK_RANK1
	gain_text = span_notice("You feel like you could stuff a lot more into your bags.")
	lose_text = span_danger("Your bags feel like they hold less than they used to.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 4

/datum/quirk/strongback_rank2
	name = "Strong Back II"
	desc = "You've got the frame and the know-how to turn yourself into a pack mule. +45% carry capacity on top of whatever your Strength provides. Requires Strong Back I."
	value = 4
	requires_quirk = "Strong Back I"
	mob_trait = TRAIT_STRONGBACK_RANK2
	gain_text = span_notice("You feel like a proper pack mule now.")
	lose_text = span_danger("You no longer feel like you can carry the wasteland on your back.")
	locked = TRUE
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 6

/* ------------------------------- Nuclear Physicist ------------------------------ */
//Reduces how fast a worn Power Armor suit's installed cell drains (usage_cost in
///obj/item/clothing/suit/armor/power_armor/process(), code/modules/clothing/suits/bigiron_suits.dm -
//f13armor.dm's copy of this proc is entirely dead/commented-out reference code, not the live one)
//so fusion cores genuinely "last longer" while worn, mirroring the real Fallout 4 perk.

/datum/quirk/nuclear_physicist_rank1
	name = "Nuclear Physicist I"
	desc = "You understand fission reactors well enough to squeeze more out of them. Power Armor cells drain 33% slower while worn."
	value = 2
	mob_trait = TRAIT_NUCLEAR_PHYSICIST_RANK1
	gain_text = span_notice("You start eyeing every fusion core with a calculating look.")
	lose_text = span_danger("Your grasp of fusion core efficiency slips away.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5

/datum/quirk/nuclear_physicist_rank2
	name = "Nuclear Physicist II"
	desc = "You've all but mastered fission power theory. Power Armor cells drain 55% slower while worn. Requires Nuclear Physicist I."
	value = 4
	requires_quirk = "Nuclear Physicist I"
	mob_trait = TRAIT_NUCLEAR_PHYSICIST_RANK2
	gain_text = span_notice("Fusion core efficiency is second nature to you now.")
	lose_text = span_danger("Your deep understanding of fusion cores fades.")
	locked = TRUE
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7


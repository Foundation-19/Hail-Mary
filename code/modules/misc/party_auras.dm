/**
 * Selectable leadership auras radiated by a party's `/datum/party/aura`. A leader unlocks more
 * options as their Charisma buff tier (get_special_charisma_party_buff_tier()) rises, and can
 * switch between unlocked auras with /mob/living/proc/set_party_aura(). Stateless by design -
 * `apply_tick()`/`remove()` take the member/leader/tier as arguments instead of caching anything
 * on the aura instance itself, so one aura instance can safely serve every member of a party.
 */
/datum/party_aura
	var/name = "Aura"
	var/desc = "Does nothing."
	/// Minimum get_special_charisma_party_buff_tier() the leader needs before this aura can be selected.
	var/required_tier = 0
	/// Shown to a member the moment this aura's buff first kicks in (joining range).
	var/gain_message = "You feel your leader's presence steady you."
	/// Shown to a member the moment this aura's buff lapses (leaving range).
	var/loss_message = "Your leader's steadying presence fades."

/// Applies (or refreshes) this aura's effect on an in-range member for the current tick. Called every tick while the member is in range and buffed.
/datum/party_aura/proc/apply_tick(mob/living/member, mob/living/leader, tier)
	return

/// Cleans up whatever apply_tick() applied. Must be safe to call even if the member never received the buff, and after the member has already left the party.
/datum/party_aura/proc/remove(mob/living/member)
	return

/// VANGUARD - the original/default aura: steadier stamina and a quicker step.
/datum/party_aura/vanguard
	name = "Vanguard"
	desc = "Steady stamina and a quicker step for everyone sticking close to you."
	required_tier = 0
	gain_message = "A surge of energy steadies your legs and lungs - Vanguard's rally kicks in!"
	loss_message = "The spring leaves your step as Vanguard's rally fades."

/datum/party_aura/vanguard/apply_tick(mob/living/member, mob/living/leader, tier)
	SEND_SIGNAL(member, COMSIG_ADD_MOOD_EVENT, "party_rally", /datum/mood_event/party_rally)
	member.adjustStaminaLoss(-tier, FALSE)
	member.add_movespeed_modifier(/datum/movespeed_modifier/party_rally)

/datum/party_aura/vanguard/remove(mob/living/member)
	member.remove_movespeed_modifier(/datum/movespeed_modifier/party_rally)

/// GUARDIAN - trades some of the leader's composure for tougher allies. Unlocks at tier 2 (special_c 7+).
/datum/party_aura/guardian
	name = "Guardian"
	desc = "Toughens your allies' hide, trimming the brute and burn damage they take while they're near you."
	required_tier = 2
	gain_message = "Your skin feels tougher under Guardian's watch!"
	loss_message = "Guardian's protection fades from your skin."

/datum/party_aura/guardian/apply_tick(mob/living/member, mob/living/leader, tier)
	if(!ishuman(member))
		return
	var/mob/living/carbon/human/H = member
	SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "party_rally", /datum/mood_event/party_rally_guardian)
	var/target_mod = max(0.6, 1 - (tier * 0.08))
	if(H.party_aura_applied_mod == target_mod)
		return
	remove(member) // undo whatever mod (this aura's or a different one's) was applied last tick before reapplying at the new tier
	H.physiology.brute_mod *= target_mod
	H.physiology.burn_mod *= target_mod
	H.party_aura_applied_mod = target_mod

/datum/party_aura/guardian/remove(mob/living/member)
	if(!ishuman(member))
		return
	var/mob/living/carbon/human/H = member
	if(!H.party_aura_applied_mod)
		return
	H.physiology.brute_mod /= H.party_aura_applied_mod
	H.physiology.burn_mod /= H.party_aura_applied_mod
	H.party_aura_applied_mod = null

/// OPERATIVE - keeps everyone's hands quick for fieldwork. Unlocks at tier 3 (special_c 9+).
/datum/party_aura/operative
	name = "Operative"
	desc = "Keeps everyone's hands quick and steady for fieldwork while they're near you, speeding up do-after actions."
	required_tier = 3
	gain_message = "Your hands feel quick and sure under Operative's guidance!"
	loss_message = "Operative's steadying influence fades from your hands."

/datum/party_aura/operative/apply_tick(mob/living/member, mob/living/leader, tier)
	if(!ishuman(member))
		return
	var/mob/living/carbon/human/H = member
	SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "party_rally", /datum/mood_event/party_rally_operative)
	var/target_mod = max(0.7, 1 - (tier * 0.06))
	if(H.party_aura_applied_mod == target_mod)
		return
	remove(member)
	H.physiology.do_after_speed *= target_mod
	H.party_aura_applied_mod = target_mod

/datum/party_aura/operative/remove(mob/living/member)
	if(!ishuman(member))
		return
	var/mob/living/carbon/human/H = member
	if(!H.party_aura_applied_mod)
		return
	H.physiology.do_after_speed /= H.party_aura_applied_mod
	H.party_aura_applied_mod = null

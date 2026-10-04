/**
 * tgui state: party_state
 * Only lets current party members (or admins) interact with their own /datum/party.
 */

GLOBAL_DATUM_INIT(party_state, /datum/ui_state/party, new)

/datum/ui_state/party/can_use_topic(src_object, mob/user)
	if(check_rights_for(user.client, R_ADMIN))
		return UI_INTERACTIVE
	var/datum/party/P = src_object
	if(istype(P) && (user in P.members))
		return UI_INTERACTIVE
	return UI_CLOSE

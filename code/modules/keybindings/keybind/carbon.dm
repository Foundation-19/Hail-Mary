/datum/keybinding/carbon
	category = CATEGORY_CARBON
	weight = WEIGHT_MOB

/datum/keybinding/carbon/can_use(client/user)
	return iscarbon(user.mob)

/datum/keybinding/carbon/toggle_throw_mode
	hotkey_keys = list("R", "Southwest") // END
	name = "toggle_throw_mode"
	full_name = "Toggle throw mode"
	description = "Toggle throwing the current item or not."
	category = CATEGORY_CARBON

/datum/keybinding/carbon/toggle_throw_mode/down(client/user)
	var/mob/living/carbon/C = user.mob
	C.toggle_throw_mode()
	return TRUE

/datum/keybinding/carbon/select_help_intent
	hotkey_keys = list("1")
	name = "select_help_intent"
	full_name = "Select help intent"
	description = ""
	category = CATEGORY_CARBON

/datum/keybinding/carbon/select_help_intent/down(client/user)
	user.mob?.a_intent_change(INTENT_HELP)
	return TRUE

/datum/keybinding/carbon/select_disarm_intent
	hotkey_keys = list("2")
	name = "select_disarm_intent"
	full_name = "Select disarm intent"
	description = ""
	category = CATEGORY_CARBON

/datum/keybinding/carbon/select_disarm_intent/down(client/user)
	user.mob?.a_intent_change(INTENT_DISARM)
	return TRUE

/datum/keybinding/carbon/select_grab_intent
	hotkey_keys = list("3")
	name = "select_grab_intent"
	full_name = "Select grab intent"
	description = ""
	category = CATEGORY_CARBON

/datum/keybinding/carbon/select_grab_intent/down(client/user)
	user.mob?.a_intent_change(INTENT_GRAB)
	return TRUE

/datum/keybinding/carbon/select_harm_intent
	hotkey_keys = list("4")
	name = "select_harm_intent"
	full_name = "Select harm intent"
	description = ""
	category = CATEGORY_CARBON

/datum/keybinding/carbon/select_harm_intent/down(client/user)
	user.mob?.a_intent_change(INTENT_HARM)
	return TRUE

/datum/keybinding/carbon/wield 
	hotkey_keys = list("ShiftX")
	name = "wield_item"
	full_name = "Wield held item"
	description = ""
	category = CATEGORY_CARBON

/datum/keybinding/carbon/wield/down(client/user)
	var/mob/living/carbon/C = user.mob
	C.do_wield()
	return TRUE

/datum/keybinding/carbon/lookup
	hotkey_keys = list(",")
	name = "Look_up"
	full_name = "Look up"
	description = "looks up"
	category = CATEGORY_CARBON

/datum/keybinding/carbon/lookup/down(client/user)
	var/mob/living/carbon/C = user.mob
	C.lookup()
	return TRUE

/datum/keybinding/carbon/lookdown
	hotkey_keys = list(".")
	name = "Look_down"
	full_name = "looks down"
	description = "looks down your feet"
	category = CATEGORY_CARBON

/datum/keybinding/carbon/lookdown/down(client/user)
	var/mob/living/carbon/C = user.mob
	C.lookdown()
	return TRUE

/datum/keybinding/carbon/lookstop
	hotkey_keys = list("-")
	name = "Look_stop"
	full_name = "stop looking"
	description = "stop looking around and see foward"
	category = CATEGORY_CARBON

/datum/keybinding/carbon/lookstop/down(client/user)
	var/mob/living/carbon/C = user.mob
	C.stop_looking()
	return TRUE

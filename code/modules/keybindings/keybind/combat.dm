/datum/keybinding/living/toggle_combat_mode
	hotkey_keys = list("C")
	name = "toggle_combat_mode"
	full_name = "Toggle combat mode"
	category = CATEGORY_COMBAT
	description = "Toggles whether or not you're in combat mode."

/datum/keybinding/living/toggle_combat_mode/down(client/user)
	SEND_SIGNAL(user.mob, COMSIG_TOGGLE_COMBAT_MODE)
	return TRUE

/datum/keybinding/living/glove_power_attack
	hotkey_keys = list("Unbound")
	name = "glove_power_attack"
	full_name = "Power Attack (Worn Glove Weapon)"
	category = CATEGORY_COMBAT
	description = "Hold to charge a Power Attack with a weapon worn in your glove slot (e.g. a power fist) - unlike a held weapon, there's no hand item to right-click, so this releases facing whatever direction you're looking instead of at your cursor."

/datum/keybinding/living/glove_power_attack/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_start_glove_power_attack()
	return TRUE

/datum/keybinding/living/glove_power_attack/up(client/user)
	var/mob/living/L = user.mob
	L.keybind_stop_glove_power_attack()

/datum/keybinding/living/active_block
	hotkey_keys = list("Northwest", "F") // HOME
	name = "active_block"
	full_name = "Block (Hold)"
	category = CATEGORY_COMBAT
	description = "Hold down to actively block with your currently in-hand object."

/datum/keybinding/living/active_block/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_start_active_blocking()
	return TRUE

/datum/keybinding/living/active_block/up(client/user)
	var/mob/living/L = user.mob
	L.keybind_stop_active_blocking()

/datum/keybinding/living/active_block_toggle
	hotkey_keys = list("Unbound")
	name = "active_block_toggle"
	full_name = "Block (Toggle)"
	category = CATEGORY_COMBAT
	description = "Toggles active blocking system using currenet in hand object, or any found object if applicable."

/datum/keybinding/living/active_block_toggle/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_toggle_active_blocking()
	return TRUE

/datum/keybinding/living/active_parry
	hotkey_keys = list("Insert", "G")
	name = "active_parry"
	full_name = "Parry"
	category = CATEGORY_COMBAT
	description = "Press to initiate a parry sequence with your currently in-hand object."

/datum/keybinding/living/active_parry/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_parry()
	return TRUE



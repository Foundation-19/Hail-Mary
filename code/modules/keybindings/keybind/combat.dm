/datum/keybinding/living/toggle_combat_mode
	hotkey_keys = list("C")
	name = "toggle_combat_mode"
	full_name = "Toggle combat mode"
	category = CATEGORY_COMBAT
	description = "Toggles whether or not you're in combat mode."

/datum/keybinding/living/toggle_combat_mode/down(client/user)
	SEND_SIGNAL(user.mob, COMSIG_TOGGLE_COMBAT_MODE)
	return TRUE

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

/datum/keybinding/living/power_attack_pick_heavy_strike
	hotkey_keys = list("Unbound")
	name = "power_attack_pick_heavy_strike"
	full_name = "Power Attack: Heavy Strike"
	category = CATEGORY_COMBAT
	description = "Arms Heavy Strike on your currently wielded weapon, if it can perform it - same as picking it from the Alt+Click/Alt+RMB radial menu, but instant."

/datum/keybinding/living/power_attack_pick_heavy_strike/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_power_attack_pick(/datum/power_attack/heavy_strike)
	return TRUE

/datum/keybinding/living/power_attack_pick_cleave
	hotkey_keys = list("Unbound")
	name = "power_attack_pick_cleave"
	full_name = "Power Attack: Cleave"
	category = CATEGORY_COMBAT
	description = "Arms Cleave on your currently wielded weapon, if it can perform it - same as picking it from the Alt+Click/Alt+RMB radial menu, but instant."

/datum/keybinding/living/power_attack_pick_cleave/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_power_attack_pick(/datum/power_attack/cleave)
	return TRUE

/datum/keybinding/living/power_attack_pick_guard_break
	hotkey_keys = list("Unbound")
	name = "power_attack_pick_guard_break"
	full_name = "Power Attack: Guard Break"
	category = CATEGORY_COMBAT
	description = "Arms Guard Break on your currently wielded weapon, if it can perform it - same as picking it from the Alt+Click/Alt+RMB radial menu, but instant."

/datum/keybinding/living/power_attack_pick_guard_break/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_power_attack_pick(/datum/power_attack/guard_break)
	return TRUE

/datum/keybinding/living/power_attack_pick_execute
	hotkey_keys = list("Unbound")
	name = "power_attack_pick_execute"
	full_name = "Power Attack: Execute"
	category = CATEGORY_COMBAT
	description = "Arms Execute on your currently wielded weapon, if it can perform it - same as picking it from the Alt+Click/Alt+RMB radial menu, but instant."

/datum/keybinding/living/power_attack_pick_execute/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_power_attack_pick(/datum/power_attack/execute)
	return TRUE

/datum/keybinding/living/power_attack_pick_lunge
	hotkey_keys = list("Unbound")
	name = "power_attack_pick_lunge"
	full_name = "Power Attack: Lunge"
	category = CATEGORY_COMBAT
	description = "Arms Lunge on your currently wielded weapon, if it can perform it - same as picking it from the Alt+Click/Alt+RMB radial menu, but instant."

/datum/keybinding/living/power_attack_pick_lunge/down(client/user)
	var/mob/living/L = user.mob
	L.keybind_power_attack_pick(/datum/power_attack/lunge)
	return TRUE



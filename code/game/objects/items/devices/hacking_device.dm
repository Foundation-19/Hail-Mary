// ============================================================
// HACKING DEVICE
// A pre-war electronic bypass tool. Used to crack locked-out
// terminals. Effectiveness scales with the user's Intelligence.
// ============================================================

/obj/item/hacking_device
	name = "hacking device"
	desc = "A pre-war RobCo terminal bypass tool. Useful for getting into systems that have locked you out — if you know what you're doing."
	icon = 'icons/obj/hacking_device.dmi'
	icon_state = "hacking_device"
	w_class = WEIGHT_CLASS_SMALL
	force = 3
	throwforce = 5
	throw_range = 5
	throw_speed = 2
	/// Whether the working animation is currently playing
	var/working = FALSE

// ── Play the working (animated) icon state during a bypass attempt
/obj/item/hacking_device/proc/start_working_anim()
	if(working)
		return
	working = TRUE
	icon_state = "hacking_device_anim"

// ── Return to idle icon state
/obj/item/hacking_device/proc/stop_working_anim()
	working = FALSE
	icon_state = "hacking_device"

// ── Flash the denied icon state briefly on failure
/obj/item/hacking_device/proc/play_denied_anim()
	stop_working_anim()
	icon_state = "hacking_device_denied"
	addtimer(CALLBACK(src, PROC_REF(stop_working_anim)), 1.5 SECONDS)

// ── Examine hint
/obj/item/hacking_device/examine(mob/user)
	. = ..()
	. += span_notice("Use it on a locked-out terminal to attempt a bypass. Higher Intelligence helps.")
	if(istype(user, /mob/living))
		var/mob/living/L = user
		var/int_val = L.special_i
		if(int_val <= 4)
			. += span_warning("Your Intelligence is too low to make use of this.")
		else if(int_val <= 6)
			. += span_warning("Your Intelligence is adequate. Success is possible but not guaranteed.")
		else if(int_val <= 8)
			. += span_notice("Your Intelligence gives you a solid chance of success.")
		else
			. += span_nicegreen("Your Intelligence is excellent. This should be routine.")

// ── Using on yourself does nothing useful
/obj/item/hacking_device/attack_self(mob/user)
	to_chat(user, span_warning("You wave the hacking device around. It blinks expectantly."))

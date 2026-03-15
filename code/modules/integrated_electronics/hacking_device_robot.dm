// ====================================================
// HACKING DEVICE — INTEGRATED ELECTRONICS EXTENSION
// Extension procs on /obj/item/hacking_device.
// The base item is defined in:
//   code/game/objects/items/devices/hacking_device.dm
// That file owns: item definition, working var,
// animation procs, terminal examine, attack_self msg.
//
// This file adds:
//   - device_cert slot (hacking tool certificate)
//   - Robot hack state vars
//   - attackby cert installation
//   - attack_self override (eject cert or fall through)
//   - examine extension (cert status + cooldown)
//   - Full robot intrusion system: afterattack targeting,
//     minigame browser (Option B via temp terminal datum),
//     action menu (suppress/pacify/extract/reprogram/shutdown)
//
// File: code/modules/integrated_electronics/hacking_device.dm
// ====================================================

// ====================================================
// HACK PROXY TERMINAL
// Subtype of terminal used ONLY as minigame state
// carrier. Defined FIRST so the type path is known
// when /obj/item/hacking_device declares hack_session.
// ====================================================

/obj/machinery/computer/terminal/hack_proxy
	/// Weakref to the owning hacking device.
	var/datum/weakref/device_ref = null
	/// Display name of the robot being hacked — shown in window title.
	var/hack_target_name = ""

/obj/machinery/computer/terminal/hack_proxy/ui_interact(mob/user)
	// Do NOT call ..() — skip normal terminal rendering entirely.
	var/obj/item/hacking_device/D = device_ref?.resolve()
	if(D)
		D._render_minigame(user)

/obj/machinery/computer/terminal/hack_proxy/Topic(href, list/href_list)
	var/mob/U = usr
	if(!U?.client) return
	var/obj/item/hacking_device/D = device_ref?.resolve()
	if(!D) return
	var/choice = href_list["choice"]
	var/handled = FALSE
	switch(choice)
		if("hack_word")
			process_hack_attempt(U, href_list["word"])
			handled = TRUE
		if("hack_dud")
			remove_dud(U)
			handled = TRUE
		if("hack_refill")
			refill_attempts(U)
			handled = TRUE
		if("hack_junk")
			process_hack_junk_click(U)
			handled = TRUE
	if(!handled)
		return
	// Explicitly re-render after every action rather than relying on
	// updateUsrDialog() / ui_interact() which behave inconsistently
	// when the browser isn't opened through the normal ui_interact path.
	// _render_minigame handles solve/lockout transitions automatically.
	// Guard: if the session ended during the proc (success/fail), don't re-render.
	if(D.hack_session)
		D._render_minigame(U)


/obj/item/hacking_device
	/// The installed hacking cert. Needed for robot intrusion.
	/// null = terminal bypass still works; robot hacking blocked.
	var/datum/cpu_cert/device/hacking_tool/device_cert = null

	/// World.time when the robot-hack cooldown expires.
	var/hack_cooldown_until = 0

	/// Temporary terminal proxy used as minigame state carrier.
	/// Non-null while a robot hack session is active.
	var/obj/machinery/computer/terminal/hack_proxy/hack_session = null

	/// Weakrefs for the active hack session.
	var/datum/weakref/hack_target_ref = null
	var/datum/weakref/hack_user_ref   = null

	/// Guard: TRUE while success/fail is being resolved to prevent double-fire
	/// from both ui_interact and proxy.Topic calling _render_minigame.
	var/hack_resolving = FALSE


// ====================================================
// CERT SLOT
// Use a hacking tool cert card on the device to install.
// Activate (click in hand) to eject when cert is slotted.
// ====================================================

/obj/item/hacking_device/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/cert_card/base/hacking_tool))
		var/obj/item/cert_card/base/hacking_tool/C = W
		if(!C.base_cert)
			return ..()
		if(device_cert)
			to_chat(user, span_warning("[src] already has a cert installed. Activate it to eject first."))
			return
		device_cert = C.base_cert
		C.base_cert = null
		to_chat(user, span_nicegreen("You slot [device_cert.cert_name] into [src]."))
		to_chat(user, span_notice("Robot intrusion enabled. Click any standard robot with the device to begin hacking."))
		qdel(W)
		return
	return ..()

/// Override attack_self: eject cert if one is installed,
/// otherwise fall through to the devices file's message.
/obj/item/hacking_device/attack_self(mob/user)
	if(device_cert)
		var/obj/item/cert_card/base/hacking_tool/card = new(user.loc)
		card.base_cert = device_cert
		card._update_name()
		device_cert = null
		to_chat(user, span_notice("You eject [card.name] from [src]."))
		return
	return ..()

/// Extend examine to show cert status and next-step guidance.
/obj/item/hacking_device/examine(mob/user)
	. = ..()
	if(device_cert)
		. += span_notice("Cert installed: <b>[device_cert.cert_name]</b>  (Compute [device_cert.get_compute()] — [device_cert.get_compute() + 2] attempts)")
		if(device_cert.capability_flags & CERT_MILITARY_GRADE)
			. += span_good("Military-grade: identity masking active on successful hacks.")
		. += span_notice("Ready to hack. <b>Click a robot</b> with this device to start.")
		. += span_notice("Combat-certified robots (Assaultron, Sentry Bot) cannot be hacked.")
	else
		. += span_warning("No certificate installed — cannot hack robots.")
		. += span_notice("Print a <b>Hacking Tool Certificate</b> at the CPU Cert Fabricator, then use it on this device.")
	if(world.time < hack_cooldown_until)
		var/remaining = round((hack_cooldown_until - world.time) / 10)
		. += span_warning("Cooldown active — [remaining]s before next attempt.")


// ====================================================
// MINIGAME RENDER
// Called by hack_proxy.ui_interact on every refresh.
// Checks solve/lockout state and transitions to
// success or fail callbacks accordingly.
// ====================================================

/obj/item/hacking_device/proc/_render_minigame(mob/living/user)
	if(!hack_session || hack_resolving)
		return

	// Solved — transition to success
	if(hack_session.hack_solved)
		hack_resolving = TRUE
		_on_hack_success(hack_session, user)
		return

	// Locked out — transition to fail
	if(hack_session.hack_locked_out)
		hack_resolving = TRUE
		_on_hack_fail(user)
		return

	// Still in progress — re-render the lock screen through our browser window
	// The lock screen renders with src=hack_session so all links point at the proxy,
	// which routes clicks back here via proxy.Topic -> proxy.ui_interact -> _render_minigame.
	hack_session.render_lock_screen(user)
	// Set the window title to show target context — render_lock_screen opens "terminal"
	// with a null title, so we patch it immediately after.
	if(user?.client && hack_session.hack_target_name)
		winset(user, "terminal", "title=Hacking: [hack_session.hack_target_name]")


// ====================================================
// AFTERATTACK — targeting a robot
// ====================================================

/obj/item/hacking_device/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !istype(target, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = target

	if(!device_cert || !(device_cert.capability_flags & CERT_CAN_HACK))
		to_chat(user, span_warning("No hacking certificate installed. Print a Hacking Tool Certificate at the CPU Cert Fabricator and use it on this device first."))
		play_denied_anim()
		return

	if(world.time < hack_cooldown_until)
		var/remaining = round((hack_cooldown_until - world.time) / 10)
		to_chat(user, span_warning("Device cooling down. [remaining]s until ready."))
		play_denied_anim()
		return

	if(hack_session)
		to_chat(user, span_warning("Hack already in progress. Finish or wait for the current session to end."))
		return

	// Determine hackability and difficulty from target cert
	var/hackable = TRUE
	var/hack_diff = 0  // no cert = always easy
	if(R.cpu_cert)
		if(R.cpu_cert.capability_flags & CERT_IS_HACKABLE)
			hack_diff = clamp(round((R.cpu_cert.base_operations - 1) / 2), 0, 4)
		else
			hackable = FALSE

	if(!hackable)
		to_chat(user, span_warning("[R] has a hardened combat certification — intrusion is not possible with this device."))
		to_chat(user, span_notice("Standard, Medical, and Engineering chassis can be hacked. Combat-certified robots cannot."))
		R.visible_message(span_warning("[R]'s indicator light flashes red. \"Intrusion attempt rejected.\""))
		log_game("HACK BLOCKED: [key_name(user)] attempted to hack [R] ([R.name]) — hardened cert at [AREACOORD(R)]")
		play_denied_anim()
		hack_cooldown_until = world.time + 100
		return

	_begin_hack_session(R, user, hack_diff)


// ====================================================
// HACK SESSION
// ====================================================

/obj/item/hacking_device/proc/_begin_hack_session(mob/living/silicon/robot/R, mob/living/user, difficulty)
	hack_target_ref = WEAKREF(R)
	hack_user_ref   = WEAKREF(user)

	hack_session = new /obj/machinery/computer/terminal/hack_proxy(null)
	hack_session.device_ref       = WEAKREF(src)
	hack_session.hack_target_name = R.name
	hack_session.locked          = TRUE
	hack_session.hack_difficulty = difficulty
	hack_session.init_hack(user)
	// Apply compute scaling AFTER init_hack so it isn't overwritten
	hack_session.hack_max        = clamp(device_cert.get_compute() + 2, 2, 8)
	hack_session.hack_attempts   = hack_session.hack_max

	user.visible_message(
		span_notice("[user] connects [src] to [R]'s access port and begins an intrusion sequence."),
		span_notice("Hacking [R]. Guess the correct password in the terminal window. Higher Intelligence = more attempts.")
	)
	log_game("HACK ATTEMPT: [key_name(user)] targeting [R] ([R.name]) at [AREACOORD(R)] — difficulty [difficulty]")
	start_working_anim()
	_render_minigame(user)


// ====================================================
// CALLBACKS
// ====================================================

/obj/item/hacking_device/proc/_on_hack_success(obj/machinery/computer/terminal/T, mob/living/user)
	var/mob/living/silicon/robot/R = hack_target_ref?.resolve()
	stop_working_anim()
	// Close the minigame window before opening the action menu
	if(user?.client)
		winset(user, "terminal", "is-visible=false")
	if(!R || QDELETED(R))
		to_chat(user, span_warning("Hack succeeded but the target is gone."))
		INVOKE_ASYNC(src, PROC_REF(_end_hack_session))
		return

	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	if(masked)
		log_game("HACK SUCCESS (MASKED): [key_name(user)] on [R] ([R.name]) at [AREACOORD(R)]")
		R.log_service("INTRUSION SUCCESS -- operator identity masked.")
	else
		log_game("HACK SUCCESS: [key_name(user)] on [R] ([R.name]) at [AREACOORD(R)]")
		R.log_service("INTRUSION SUCCESS -- operator: [user.name] at [AREACOORD(R)]")

	INVOKE_ASYNC(src, PROC_REF(_end_hack_session))
	_open_action_menu(R, user, masked)

/obj/item/hacking_device/proc/_on_hack_fail(mob/living/user)
	var/mob/living/silicon/robot/R = hack_target_ref?.resolve()
	play_denied_anim()  // play_denied_anim calls stop_working_anim internally
	hack_cooldown_until = world.time + 300
	// Close the minigame window
	if(user?.client)
		winset(user, "terminal", "is-visible=false")
	to_chat(user, span_warning("Intrusion failed. The device needs 30 seconds to reset before another attempt."))
	to_chat(user, span_notice("Tip: higher Intelligence gives more attempts. Try a robot with a lower-tier cert for an easier minigame."))

	if(R && !QDELETED(R))
		R.log_service("INTRUSION FAILED -- access denied.")
		var/is_npc = (!R.mind || R.mind.key == null)
		if(is_npc && R.stat != DEAD)
			R.visible_message(span_warning("[R]'s indicator light flashes red. \"Intrusion attempt detected.\""))
			if(R.cpu_cert)
				for(var/datum/cert_upgrade/robot/behavior_assembly/BA in R.cpu_cert.upgrade_slots)
					if(BA?.assembly)
						for(var/datum/behavior_circuit/response/enter_combat_mode/EC in BA.assembly.circuits)
							EC.execute(R, BA.assembly)
						break
		log_game("HACK FAIL: [key_name(user)] failed on [R] ([R.name]) at [AREACOORD(R)]")

	INVOKE_ASYNC(src, PROC_REF(_end_hack_session))

/obj/item/hacking_device/proc/_end_hack_session()
	if(hack_session)
		qdel(hack_session)
		hack_session = null
	hack_target_ref = null
	hack_user_ref   = null
	hack_resolving  = FALSE


// ====================================================
// ACTION MENU
// ====================================================

/obj/item/hacking_device/proc/_open_action_menu(mob/living/silicon/robot/R, mob/living/user, masked)
	var/is_military = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	var/dat = _get_hack_css()
	dat += "<b>INTRUSION SUCCESS</b><br>"
	dat += "<span class='dim'>Target: [html_encode(R.name)]  |  Location: ([R.x],[R.y],[R.z])</span><br>"
	if(masked)
		dat += "<span class='good'>&gt; Identity masking active.</span><br>"
	dat += "<br><b>SELECT ACTION</b><br><br>"

	dat += "<a href='byond://?src=[REF(src)];hack_action=suppress;rref=[REF(R)]'>&gt; SUPPRESS</a>"
	dat += "  <span class='dim'>// Robot freezes for 30 seconds — behavior circuits go dark.</span><br>"

	dat += "<a href='byond://?src=[REF(src)];hack_action=pacify;rref=[REF(R)]'>&gt; PACIFY</a>"
	dat += "  <span class='dim'>// Clears combat mode and wipes enemy memory — robot stands down.</span><br>"

	dat += "<a href='byond://?src=[REF(src)];hack_action=extract;rref=[REF(R)]'>&gt; EXTRACT</a>"
	dat += "  <span class='dim'>// Reads what this robot knows: assembly program, allied factions, operator lock.</span><br>"

	if(device_cert.get_compute() >= 3 || is_military)
		dat += "<a href='byond://?src=[REF(src)];hack_action=reprogram;rref=[REF(R)]'>&gt; REPROGRAM</a>"
		dat += "  <span class='dim'>// Rewrite loyalty: redirect it to follow you, inject your faction, or remove its operator lock.</span><br>"
	else
		dat += "<span class='dim'>&gt; REPROGRAM  // Needs higher-compute cert (Compute 3+). Print an upgraded cert at the CPU Fabricator.</span><br>"

	if(is_military)
		dat += "<a href='byond://?src=[REF(src)];hack_action=shutdown;rref=[REF(R)]'><span class='bad'>&gt; SHUTDOWN</span></a>"
		dat += "  <span class='dim'>// Hard kill. Robot goes offline permanently until rebooted.</span><br>"
	else
		dat += "<span class='dim'>&gt; SHUTDOWN  // Military-grade cert only. Find one in the world.</span><br>"

	dat += "<br><a href='byond://?src=[REF(src)];hack_action=close'>&gt; \[Close\]</a>"
	dat += "</font></body></html>"

	var/datum/browser/popup = new(user, "hacking_device_[REF(src)]", "RobCo ICE — Action Menu", 560, 360)
	popup.set_content(dat)
	popup.open()


// ====================================================
// TOPIC
// ====================================================

/obj/item/hacking_device/Topic(href, list/href_list)
	var/mob/user = usr
	if(!user?.client) return
	if(!href_list["hack_action"]) return
	// Ownership check — only the person who started the hack can act
	var/mob/session_user = hack_user_ref?.resolve()
	if(session_user && user != session_user)
		to_chat(user, span_warning("This is not your hack session."))
		return

	var/action = href_list["hack_action"]

	if(action == "close")
		if(user?.client)
			winset(user, "hacking_device_[REF(src)]", "is-visible=false")
		return

	var/mob/living/silicon/robot/R = null
	if(href_list["rref"])
		R = locate(href_list["rref"])

	if(!R || QDELETED(R))
		to_chat(user, span_warning("Target is no longer available."))
		return

	switch(action)
		if("suppress")                _hack_suppress(R, user)
		if("pacify")                  _hack_pacify(R, user)
		if("extract")                 _hack_extract(R, user)
		if("reprogram")               _hack_reprogram_menu(R, user)
		if("action_menu")             _open_action_menu(R, user, device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE))
		if("reprogram_follow")        _hack_reprogram_follow(R, user)
		if("reprogram_faction_add")   _hack_reprogram_faction_add(R, user)
		if("reprogram_faction_clear") _hack_reprogram_faction_clear(R, user)
		if("reprogram_clear_lock")    _hack_reprogram_clear_lock(R, user)
		if("shutdown")                _hack_shutdown(R, user)


// ====================================================
// ACTIONS
// ====================================================

/obj/item/hacking_device/proc/_hack_suppress(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	if(R.cpu_cert)
		for(var/datum/cert_upgrade/robot/behavior_assembly/BA in R.cpu_cert.upgrade_slots)
			if(BA?.assembly)
				BA.assembly.assembly_override = FALSE
				INVOKE_ASYNC(src, PROC_REF(_suppress_timeout), BA.assembly)
				break
	R.visible_message(span_warning("[R] emits a low tone and goes still."))
	to_chat(user, span_nicegreen("Suppressed. [R.name]'s behavior circuits are offline for 30 seconds."))
	R.log_service("HACK: SUPPRESS — operator: [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_suppress_timeout(obj/item/behavior_assembly/A)
	sleep(300)
	if(!QDELETED(A))
		A.assembly_override = TRUE

/obj/item/hacking_device/proc/_hack_pacify(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	if(R.installed_hardware)
		for(var/datum/robot_hardware/memory_core/MEM in R.installed_hardware)
			MEM.clear("last_enemy")
			MEM.clear("alert")
			break
	R.visible_message(span_notice("[R]'s indicator light returns to green."))
	to_chat(user, span_nicegreen("Pacified. [R.name] has stood down — combat mode cleared, enemy memory wiped."))
	R.log_service("HACK: PACIFY — operator: [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_hack_extract(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	var/dat = _get_hack_css()
	dat += "<b>EXTRACT — [html_encode(R.name)]</b><br><br>"

	if(R.cpu_cert)
		dat += "<b>CERT:</b> [html_encode(R.cpu_cert.cert_name)]<br>"
		dat += "<span class='dim'>C.O.R.E.: C[R.cpu_cert.get_compute()] O[R.cpu_cert.get_operations()] R[R.cpu_cert.get_resilience()] E[R.cpu_cert.get_energy()]</span><br>"
	else
		dat += "<b>CERT:</b> <span class='warn'>None (default NPC)</span><br>"

	var/cmode = R.control_mode ? R.control_mode : "npc"
	dat += "<b>CONTROL:</b> [cmode]"
	if(R.locked_ckey) dat += "  <span class='dim'>locked to: [html_encode(R.locked_ckey)]</span>"
	dat += "<br>"

	dat += "<b>FACTIONS:</b> "
	if(R.faction && R.faction.len)
		var/list/clean_factions = list()
		for(var/f in R.faction)
			if(!findtext(f, "\[") && length(f))
				clean_factions += f
		dat += clean_factions.len ? jointext(clean_factions, ", ") : "<span class='dim'>none (all tags malformed)</span>"
	else
		dat += "<span class='dim'>none</span>"
	dat += "<br>"

	dat += "<b>ASSEMBLY:</b><br>"
	if(R.cpu_cert)
		for(var/datum/cert_upgrade/robot/behavior_assembly/BA in R.cpu_cert.upgrade_slots)
			if(BA?.assembly)
				dat += "&gt; [html_encode(BA.assembly.assembly_label)]  ([BA.assembly.circuits.len] circuits)<br>"
				for(var/datum/behavior_circuit/C in BA.assembly.circuits)
					dat += "<span class='dim'>  - [html_encode(C.circuit_name)]</span><br>"
				break

	dat += "<br><a href='byond://?src=[REF(src)];hack_action=action_menu;rref=[REF(R)]'>&gt; \[Back\]</a>"
	dat += "</font></body></html>"

	var/datum/browser/popup = new(user, "hacking_device_[REF(src)]", "RobCo ICE — Extract", 560, 460)
	popup.set_content(dat)
	popup.open()
	R.log_service("HACK: EXTRACT — operator: [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_hack_reprogram_menu(mob/living/silicon/robot/R, mob/living/user)
	var/dat = _get_hack_css()
	dat += "<b>REPROGRAM — [html_encode(R.name)]</b><br>"
	dat += "<span class='dim'>These changes are permanent until someone overwrites them.</span><br><br>"

	dat += "<a href='byond://?src=[REF(src)];hack_action=reprogram_follow;rref=[REF(R)]'>&gt; Make it follow you</a>"
	dat += "  <span class='dim'>// Overwrites its Follow Linked Target — it will escort you until reprogrammed again.</span><br>"

	dat += "<a href='byond://?src=[REF(src)];hack_action=reprogram_faction_add;rref=[REF(R)]'>&gt; Add your faction as ally</a>"
	dat += "  <span class='dim'>// Robot reads your ID card's faction and adds it — won't attack your people anymore.</span><br>"

	dat += "<a href='byond://?src=[REF(src)];hack_action=reprogram_faction_clear;rref=[REF(R)]'><span class='warn'>&gt; Wipe all faction loyalty</span></a>"
	dat += "  <span class='dim'>// Robot becomes hostile to everyone. Useful chaos, dangerous to you too.</span><br>"

	if(R.locked_ckey)
		dat += "<a href='byond://?src=[REF(src)];hack_action=reprogram_clear_lock;rref=[REF(R)]'><span class='warn'>&gt; Remove operator lock</span></a>"
		dat += "  <span class='dim'>// [html_encode(R.locked_ckey)] currently owns this robot. Clearing the lock frees it for anyone.</span><br>"
	else
		dat += "<span class='dim'>&gt; Remove operator lock  // No lock installed.</span><br>"

	dat += "<br><a href='byond://?src=[REF(src)];hack_action=action_menu;rref=[REF(R)]'>&gt; \[Back\]</a>"
	dat += "</font></body></html>"

	var/datum/browser/popup = new(user, "hacking_device_[REF(src)]", "RobCo ICE — Reprogram", 560, 300)
	popup.set_content(dat)
	popup.open()

/obj/item/hacking_device/proc/_hack_reprogram_follow(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	var/linked = 0
	if(R.cpu_cert)
		for(var/datum/cert_upgrade/robot/behavior_assembly/BA in R.cpu_cert.upgrade_slots)
			if(BA?.assembly)
				for(var/datum/behavior_circuit/response/follow_target/FT in BA.assembly.circuits)
					// Intentional: hacking device bypasses the multitool tamper gate.
					// This is the designed hacker path — no panel-open required.
					FT.set_linked_target(user, user)
					linked++
				break
	if(!linked)
		to_chat(user, span_warning("No Follow Linked Target circuit found in this assembly."))
		return
	to_chat(user, span_nicegreen("Done. [R.name] will now follow you — its Follow Linked Target circuit points to you."))
	R.log_service("HACK: REPROGRAM follow_target -> [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_hack_reprogram_faction_add(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	var/obj/item/card/id/ID = null
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		ID = H.get_idcard(TRUE)
	var/faction_tag = ID ? resolve_faction_from_card(ID) : null
	if(!faction_tag)
		to_chat(user, span_warning("Could not determine your faction. Carry a valid ID card."))
		return
	if(!R.faction) R.faction = list()
	if(faction_tag in R.faction)
		to_chat(user, span_warning("[faction_tag] is already in [R.name]'s faction list."))
		return
	R.faction += faction_tag
	to_chat(user, span_nicegreen("Done. [R.name] now treats '[faction_tag]' as allied — it won't attack your people."))
	R.log_service("HACK: REPROGRAM faction injected: [faction_tag] — operator: [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_hack_reprogram_faction_clear(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	R.faction = list()
	R.visible_message(span_warning("[R]'s indicator pulses amber. Faction registry wiped."))
	to_chat(user, span_nicegreen("Done. [R.name] has no allies now — it will engage everyone, including you."))
	R.log_service("HACK: REPROGRAM faction cleared — operator: [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_hack_reprogram_clear_lock(mob/living/silicon/robot/R, mob/living/user)
	var/masked = device_cert && (device_cert.capability_flags & CERT_MILITARY_GRADE)
	var/old_op = R.locked_ckey ? R.locked_ckey : "unknown"
	R.control_mode = null
	R.locked_ckey  = null
	to_chat(user, span_nicegreen("Operator lock cleared. [R.name] is no longer reserved for [old_op]."))
	R.log_service("HACK: REPROGRAM lock cleared (was: [old_op]) — operator: [masked ? "(masked)" : user.name]")

/obj/item/hacking_device/proc/_hack_shutdown(mob/living/silicon/robot/R, mob/living/user)
	if(!device_cert || !(device_cert.capability_flags & CERT_MILITARY_GRADE))
		to_chat(user, span_warning("Military-grade certificate required for shutdown command."))
		return
	R.visible_message(span_danger("[R] emits a descending tone and goes dark."))
	to_chat(user, span_nicegreen("Shutdown command executed. [R.name] is offline."))
	R.log_service("HACK: SHUTDOWN — operator: (masked)")
	R.death(null)


// ====================================================
// CSS HELPER
// ====================================================

/obj/item/hacking_device/proc/_get_hack_css()
	var/dat = "<html><head><style>"
	dat += "body{padding:0;margin:14px;background-color:#062113;color:#4aed92;"
	dat += "line-height:170%;font-family:'Courier New',Courier,monospace;}"
	dat += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;"
	dat += "background:#062113;border:none;padding:1px 4px;margin:0 2px;}"
	dat += "a:hover{color:#062113;background:#4aed92;cursor:pointer;}"
	dat += ".dim{color:#2a7a52;}.good{color:#4aed92;font-weight:bold;}"
	dat += ".bad{color:#c0392b;font-weight:bold;}.warn{color:#e67e22;font-weight:bold;}"
	dat += "b{color:#4aed92;}"
	dat += "</style></head><body><font face='Courier New'>"
	return dat

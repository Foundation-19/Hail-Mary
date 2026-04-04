// ============================================================
// F13 POWER GRID -- DEBUG / TEST TOOLS
// ============================================================
//
// MASTER BREAKER
// A physical in-world toggle that kills or restores the
// "magic" free power that the SS13 engine gives every area
// when no APC is present (power_equip/light/environ default
// to TRUE at initialisation).
//
// PAPER GUIDE
// /obj/item/paper/f13/power_grid_guide -- spawnable lore paper
// describing how to set up the F13 fusion power grid.
// Spawn via admin panel or place directly on a map.
//
// Place one on any test map.  Clicking it flips all /area/f13
// instances between:
//   ON  -- areas powered normally (same as unmodified map)
//   OFF -- areas dark; only areas owned by a live generator or
//         relay chain receive power from the fusion grid.
//
// This lets you test the fusion core grid in complete isolation
// without having to strip APCs or touch area definitions.
//
// MAPPER PLACEMENT:
//   /obj/machinery/f13/master_breaker
// ============================================================

GLOBAL_VAR_INIT(f13_magic_power, TRUE)

/obj/machinery/f13/master_breaker
	name          = "F13 master grid breaker"
	desc          = "Controls the map-wide 'always powered' override on all F13 areas. Toggle this to test the fusion core grid in isolation."
	icon          = 'icons/obj/power.dmi'
	icon_state    = "portgen0_1"   // icon: ON by default
	density       = FALSE
	anchored      = TRUE


/obj/machinery/f13/master_breaker/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	toggle_magic_power(user)

/// Toggle magic power for all /area/f13 instances.
/obj/machinery/f13/master_breaker/proc/toggle_magic_power(mob/user)
	GLOB.f13_magic_power = !GLOB.f13_magic_power

	// First pass -- set every f13 area to the new baseline.
	for(var/area/f13/A in world)
		A.power_equip   = GLOB.f13_magic_power
		A.power_light   = GLOB.f13_magic_power
		A.power_environ = GLOB.f13_magic_power
		A.power_change()

	// Second pass (only when magic is OFF) -- re-stamp zones that are
	// genuinely fed by a live generator or relay chain so they stay lit.
	if(!GLOB.f13_magic_power)
		for(var/obj/machinery/f13/faction_generator/G in world)
			if(!QDELETED(G) && G.powered)
				G.stamp_zone(TRUE)
		for(var/obj/machinery/f13/power_relay/R in world)
			if(!QDELETED(R) && R.relay_powered)
				R.stamp_zone(TRUE)

	update_icon_state()

	var/state_msg = GLOB.f13_magic_power ? "ON (areas always powered)" : "OFF (grid-only mode)"
	if(user)
		to_chat(user, span_notice("F13 magic power: [state_msg]"))
	message_admins("F13 magic power toggled [state_msg][user ? " by [key_name(user)]" : ""].")

/obj/machinery/f13/master_breaker/update_icon_state()
	icon_state = GLOB.f13_magic_power ? "portgen0_1" : "portgen0_0"


// --- Admin verb (alternate access without placing the object)

/client/proc/f13_toggle_magic_power()
	set category  = "Debug"
	set name      = "Toggle F13 Magic Power"
	set desc      = "Flip the always-powered override on all F13 areas for grid testing."

	if(!check_rights(R_ADMIN))
		return

	// Reuse master_breaker logic -- find any placed instance, or run inline.
	var/obj/machinery/f13/master_breaker/B = locate(/obj/machinery/f13/master_breaker) in world
	if(B)
		B.toggle_magic_power(usr)
	else
		// No breaker placed -- run the toggle directly.
		GLOB.f13_magic_power = !GLOB.f13_magic_power
		for(var/area/f13/A in world)
			A.power_equip   = GLOB.f13_magic_power
			A.power_light   = GLOB.f13_magic_power
			A.power_environ = GLOB.f13_magic_power
			A.power_change()
		if(!GLOB.f13_magic_power)
			for(var/obj/machinery/f13/faction_generator/G in world)
				if(!QDELETED(G) && G.powered)
					G.stamp_zone(TRUE)
			for(var/obj/machinery/f13/power_relay/R in world)
				if(!QDELETED(R) && R.relay_powered)
					R.stamp_zone(TRUE)
		message_admins("F13 magic power toggled [GLOB.f13_magic_power ? "ON" : "OFF"] by [key_name(usr)].")


// --- Admin verb -- per-area control panel

/client/proc/f13_area_power_panel()
	set category  = "Debug"
	set name      = "F13 Area Power Panel"
	set desc      = "Open a UI to toggle power per F13 faction area individually."

	if(!check_rights(R_ADMIN))
		return

	var/obj/machinery/f13/master_breaker/B = locate(/obj/machinery/f13/master_breaker) in world
	if(B)
		B.show_panel(usr)
	else
		// No placed breaker -- create a temporary one, show UI, then clean up.
		var/obj/machinery/f13/master_breaker/T = new /obj/machinery/f13/master_breaker(null)
		T.show_panel(usr)
		qdel(T)


// ============================================================
// MASTER BREAKER -- UPGRADED UI
// ============================================================

/obj/machinery/f13/master_breaker/attack_hand(mob/living/user)
	if(!Adjacent(user))
		return
	show_panel(user)

/// Open the per-area power control panel.
/obj/machinery/f13/master_breaker/proc/show_panel(mob/user)
	var/dat = get_terminal_css()
	dat += get_terminal_header("F13 Grid Control Panel")

	// --- Global toggle
	var/global_state = GLOB.f13_magic_power ? "<span class='good'>ON (magic power active)</span>" : "<span class='bad'>OFF (grid-only mode)</span>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;GLOBAL OVERRIDE&#93;</pre>"
	dat += "<pre>  Magic power  : [global_state]</pre>"
	dat += "<pre>  &gt; <a href='byond://?src=[REF(src)];choice=global_toggle'>Toggle global magic power</a></pre>"
	dat += "<pre class='dim'>  When ON every F13 area is always lit regardless of generators.</pre>"
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"

	// --- Per-generator area listing
	dat += "<pre class='head'>  &#91;CONNECTED GENERATORS&#93;</pre>"
	var/gen_count = 0
	for(var/obj/machinery/f13/faction_generator/G in world)
		if(QDELETED(G) || !G.powered_area_instances || !G.powered_area_instances.len)
			continue
		gen_count++
		var/state = G.powered ? "<span class='good'>ONLINE</span>" : "<span class='bad'>OFFLINE</span>"
		dat += "<pre>  Generator: [G.name ? G.name : "unnamed"]  [state]</pre>"
		for(var/area/A in G.powered_area_instances)
			if(QDELETED(A))
				continue
			var/pstate = A.power_equip ? "<span class='good'>powered</span>" : "<span class='bad'>unpowered</span>"
			dat += "<pre>    &gt; [A.name]  [pstate]  <a href='byond://?src=[REF(src)];choice=toggle_area;target=[REF(A)]'>Toggle</a></pre>"
		dat += "<pre class='dim'>  ---</pre>"
	if(!gen_count)
		dat += "<pre class='dim'>  No generators with configured area lists found.</pre>"

	// --- Flat area listing (all /area/f13 not belonging to any generator)
	dat += "<pre class='sep'>  ----------------------------------------------------------------</pre>"
	dat += "<pre class='head'>  &#91;ALL F13 AREAS&#93;</pre>"
	for(var/area/f13/A in world)
		if(QDELETED(A) || A.f13_grid_immune || A.outdoors)
			continue
		var/pstate = A.power_equip ? "<span class='good'>on </span>" : "<span class='bad'>off</span>"
		dat += "<pre>    [pstate]  [A.name]  <a href='byond://?src=[REF(src)];choice=toggle_area;target=[REF(A)]'>Toggle</a></pre>"

	dat += "<pre class='sep'>  ================================================================</pre>"

	var/datum/browser/popup = new(user, "f13_breaker", null, 640, 580)
	popup.set_content(dat)
	popup.open()

/obj/machinery/f13/master_breaker/Topic(href, href_list)
	..()
	if(!check_rights_for(usr.client, R_ADMIN))
		return

	switch(href_list["choice"])
		if("global_toggle")
			toggle_magic_power(usr)
		if("toggle_area")
			var/area/f13/A = locate(href_list["target"])
			if(!A || QDELETED(A))
				to_chat(usr, span_warning("Area not found."))
				return
			var/new_state = !A.power_equip
			F13_STAMP_AREA_POWER(A, new_state)
			message_admins("F13 area power toggled [new_state ? "ON" : "OFF"] for [A.name] by [key_name(usr)].")

	show_panel(usr)


// ============================================================
// F13 POWER GRID -- PAPER GUIDE
// ============================================================

/obj/item/paper/f13/power_grid_guide
	name = "FPG-7700 Power Grid Controller -- Maintenance Manual"
	info = {"<center><b>VAULT-TEC CORPORATION</b></center>
<center><b>INTEGRATED POWER SYSTEMS DIVISION</b></center>
<center>MAINTENANCE &amp; OPERATIONS MANUAL</center>
<center>SERIES FPG-7700 POWER GRID CONTROLLER</center>
<br>
<center>DOCUMENT NO. VT-PWR-7700-MNT &nbsp;&nbsp;|&nbsp;&nbsp; REVISION C</center>
<center>FOR USE WITH: FUSION CORE GENERATOR VARIANT</center>
<center>CLASSIFICATION: FACILITY MAINTENANCE PERSONNEL</center>
<br>
<hr>
<br>
<b>1.0 &nbsp; GENERAL DESCRIPTION</b>
<br>
<br>The Series FPG-7700 Power Grid Controller (hereafter referred to as <i>the Generator</i>
or <i>the Unit</i>) is a self-contained electrical power generation and distribution
management system designed for installation in permanent or semi-permanent habitation
structures.  The Unit provides regulated alternating current to all wired downstream
devices on the installation's local power grid.
<br>
<br>This manual covers the <b>fusion core variant</b>.  For diesel and atomic generator
variants, refer to the applicable supplementary documentation.  For the jury-rigged
wastelander model, a separate field guide is available.
<br>
<br>Power generation is achieved via insertion of standard RobCo-specification fusion cores
(see Section 3.3).  The Unit's integral load-management subsystem continuously monitors
downstream draw and will automatically suspend non-essential loads before engaging a
hard grid trip, ensuring critical systems remain live for as long as possible under
overload conditions.
<br>
<br>Vault-Tec Corporation warrants this product to be in perfect working order.  Any
observed malfunction is therefore the fault of improper installation or operator error.
<br>
<br>
<hr>
<b>2.0 &nbsp; SAFETY PRECAUTIONS</b>
<br>
<br><b>2.1 &nbsp; GENERAL HAZARDS</b>
<br>
<br>READ ALL INSTRUCTIONS BEFORE OPERATING THIS EQUIPMENT.  Failure to comply with the
following precautions may result in property damage, injury, or involuntary exposure to
potentially interesting radiation levels.
<br>
<br>&nbsp;&nbsp; (a)&nbsp; DO NOT operate this Unit while standing in water.
<br>&nbsp;&nbsp; (b)&nbsp; DO NOT drop, strike, or expose fusion cores to temperatures above 900&deg;F.
<br>&nbsp;&nbsp; (c)&nbsp; DO NOT remove the fuel module cover while the Unit is online (POWERED indicator
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; green).  Power down fully before servicing fuel assemblies.
<br>&nbsp;&nbsp; (d)&nbsp; DO NOT obstruct the exhaust port.  Depleted core casings are ejected on insertion.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Keep a 0.5 m clearance.
<br>&nbsp;&nbsp; (e)&nbsp; DO NOT attempt to re-activate an overloaded Unit without first identifying and
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; resolving the overload condition.  Repeated cycling under overload will
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; damage connected equipment.
<br>
<br><b>2.2 &nbsp; FUEL PRECAUTIONS (FUSION CORE)</b>
<br>
<br>&nbsp;&nbsp;&nbsp; Treat as a CLASS IV sealed energy source.  Do not strike, crush, or expose to
<br>&nbsp;&nbsp;&nbsp; temperatures in excess of 900&deg;F.  Depleted casings are safe for handling and may
<br>&nbsp;&nbsp;&nbsp; be returned to a core fabricator for reconstitution.
<br>
<br>
<hr>
<b>3.0 &nbsp; COMPONENTS AND SPECIFICATIONS</b>
<br>
<br><b>3.1 &nbsp; POWER GRID CONTROLLER (Generator)</b>
<br>
<br>&nbsp;&nbsp; Function:&nbsp; Primary power generation and distribution management.
<br>&nbsp;&nbsp; Install location:&nbsp; Interior or immediately adjacent to primary structure.
<br>&nbsp;&nbsp; Mounting:&nbsp; Must be anchored to floor (wrench) before insertion of fuel.
<br>&nbsp;&nbsp; Fuel slots:&nbsp; Up to two fusion cores simultaneously.
<br>&nbsp;&nbsp; Interface:&nbsp; Integrated terminal accessible by hand contact.
<br>&nbsp;&nbsp; Lock modes:&nbsp; OPEN | PERSONAL | FACTION (register via ID card swipe).
<br>
<br><b>3.2 &nbsp; WATT BUDGET REFERENCE</b>
<br>
<br>&nbsp;&nbsp; Per-relay overhead:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 50 W
<br>&nbsp;&nbsp; Core fabricator (idle):&nbsp;&nbsp;&nbsp; 50 W
<br>&nbsp;&nbsp; Core fabricator (active):&nbsp; 300 W
<br>&nbsp;&nbsp; Turret (each):&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 100 W
<br>&nbsp;&nbsp; Junction box (standard):&nbsp;&nbsp; 150 W
<br>&nbsp;&nbsp; Generic client (default):&nbsp; 100 W
<br>
<br><b>3.3 &nbsp; FUEL ASSEMBLY -" FUSION CORE</b>
<br>
<br>&nbsp;&nbsp; Fuel: RobCo-specification fusion core
<br>&nbsp;&nbsp; Output: 1,000 W per loaded core &nbsp;|&nbsp; Two-core capacity
<br>&nbsp;&nbsp; Max output: 2,000 W (two cores inserted)
<br>&nbsp;&nbsp; Runtime per core: approx. 15 minutes
<br>&nbsp;&nbsp; Runtime at full capacity: approx. 30 minutes
<br>&nbsp;&nbsp; Exhaust: depleted fusion core casing (recoverable for fabricator recycling)
<br>&nbsp;&nbsp; NOTE: Depleted cores may be recycled in a core fabricator at reduced material cost.
<br>
<br><b>3.4 &nbsp; POWER RELAY</b>
<br>
<br>&nbsp;&nbsp; Function:&nbsp; Extends the grid to additional zones and downstream devices.
<br>&nbsp;&nbsp; Draw:&nbsp; 50 W continuous (transmission overhead).
<br>&nbsp;&nbsp; Cascade:&nbsp; Each relay may wire to further relays, junction boxes, or clients.
<br>
<br><b>3.5 &nbsp; JUNCTION BOX</b>
<br>
<br>&nbsp;&nbsp; Function:&nbsp; Connects a building's internal lighting and outlet circuit to the grid.
<br>&nbsp;&nbsp; Draw:&nbsp; 150 W (standard).  Small variant: 75 W.  Large: 250 W.
<br>&nbsp;&nbsp; Coverage:&nbsp; On activation, flood-fills all rooms accessible from its installed turf
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; to discover the internal circuit.
<br>
<br><b>3.6 &nbsp; CORE FABRICATOR</b>
<br>
<br>&nbsp;&nbsp; Function:&nbsp; Synthesises new fusion cores from raw materials.
<br>&nbsp;&nbsp; Wiring required:&nbsp; Must be wired directly to a generator.
<br>&nbsp;&nbsp; Draw:&nbsp; 50 W idle / 300 W during fabrication.
<br>
<br>
<hr>
<b>4.0 &nbsp; INSTALLATION PROCEDURE</b>
<br>
<br>&nbsp;&nbsp; STEP 1.&nbsp; Select an installation site.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; The Generator must be placed inside or immediately adjacent to the
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; primary structure.  Ensure at least 1 tile clearance on all sides.
<br>
<br>&nbsp;&nbsp; STEP 2.&nbsp; Anchor the Unit.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Use a wrench on the Generator to secure it to the floor.  The Unit
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; must be powered down before it can be unanchored for relocation.
<br>
<br>&nbsp;&nbsp; STEP 3.&nbsp; Load a fusion core.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Load a fusion core into the upper fuel port; the loader mechanism is
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; spring-assisted.  The POWER indicator transitions from RED to GREEN.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; A depleted casing is ejected from the exhaust port automatically.
<br>
<br>&nbsp;&nbsp; STEP 4.&nbsp; Verify power state.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Open the integrated access panel.  Confirm
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; STATUS reads ONLINE and FUEL percentage is non-zero.
<br>
<br>
<hr>
<b>5.0 &nbsp; CABLE ROUTING AND NETWORK WIRING</b>
<br>
<br><b>5.1 &nbsp; WIRING A DEVICE TO THE GENERATOR</b>
<br>
<br>&nbsp;&nbsp; 1.&nbsp; Obtain a length of heavy-gauge insulated cable.
<br>&nbsp;&nbsp; 2.&nbsp; Route the cable from the generator's output terminal to the target device.
<br>&nbsp;&nbsp; 3.&nbsp; Terminate at the target device (junction box, relay, or fabricator)
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; to complete the run.  Two cable lengths are consumed per connection.
<br>&nbsp;&nbsp; 4.&nbsp; Repeat for each additional device in the network.
<br>
<br>&nbsp;&nbsp; NOTE: Cable runs may be laid in either direction (device to generator is equally valid).
<br>
<br><b>5.2 &nbsp; SEVERING CONNECTIONS</b>
<br>
<br>&nbsp;&nbsp; Remove all cable connections at the generator's output terminal to sever
<br>&nbsp;&nbsp; all downstream links at once.  Individual connections may be cut at the
<br>&nbsp;&nbsp; relay or device end.
<br>
<br><b>5.3 &nbsp; PRE-INSTALLATION WIRING</b>
<br>
<br>&nbsp;&nbsp; Vault-Tec facility pre-commissioning specifications permit designation of downstream
<br>&nbsp;&nbsp; relays, junction boxes, and turret arrays for automated network initialisation at
<br>&nbsp;&nbsp; system commissioning.  Contact the facility electrical contractor for per-unit
<br>&nbsp;&nbsp; configuration details.
<br>
<br>&nbsp;&nbsp; Cable runs installed prior to commissioning are detected automatically at system
<br>&nbsp;&nbsp; start.  Cable runs added after commissioning can be incorporated by running a
<br>&nbsp;&nbsp; network scan from the integrated access panel.
<br>
<br>
<hr>
<b>6.0 &nbsp; OPERATIONAL CHECKS -" INITIAL STARTUP SEQUENCE</b>
<br>
<br>&nbsp;&nbsp; 6.1.&nbsp; Confirm anchor status (wrench applied, Unit immobile).
<br>&nbsp;&nbsp; 6.2.&nbsp; Confirm fuel load (FUEL indicator &gt; 0%).
<br>&nbsp;&nbsp; 6.3.&nbsp; Open the integrated access panel.  Verify STATUS = ONLINE.
<br>&nbsp;&nbsp; 6.4.&nbsp; Confirm all expected devices appear in WIRED DEVICES or RELAY NETWORK.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Run RESCAN NETWORK if newly-wired devices do not appear.
<br>&nbsp;&nbsp; 6.5.&nbsp; Verify DRAW &lt; CAPACITY.  Load bar should be green or amber, not red.
<br>&nbsp;&nbsp; 6.6.&nbsp; Verify powered areas are illuminated.
<br>
<br>
<hr>
<b>7.0 &nbsp; POWER BUDGETING AND LOAD MANAGEMENT</b>
<br>
<br>The Generator tracks total downstream draw against available generation capacity.
Capacity scales with loaded cores: 1,000 W per core, maximum 2 cores (2,000 W).
When draw exceeds capacity, the Unit attempts the following in sequence:
<br>
<br>&nbsp;&nbsp; 1. LOAD SHED -" suspend lowest-priority clients and relays until within budget.
<br>&nbsp;&nbsp; 2. HARD TRIP -" if shedding alone cannot resolve the overload, the grid shuts down.
<br>
<br>Non-essential loads should be wired via relays so they can be shed as a subtree.
Critical devices should be wired directly to the generator or a high-priority relay.
<br>
<br>
<hr>
<b>8.0 &nbsp; FAULT ISOLATION AND TROUBLESHOOTING</b>
<br>
<br>&nbsp;&nbsp; FAULT&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; PROBABLE CAUSE&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; CORRECTIVE ACTION
<br>&nbsp;&nbsp; \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500&nbsp;&nbsp; \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500&nbsp;&nbsp; \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
<br>&nbsp;&nbsp; Generator will not start&nbsp;&nbsp; No cores loaded&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Insert a fusion core
<br>&nbsp;&nbsp; Zone remains dark&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Junction box not wired/powered&nbsp;&nbsp;&nbsp; Wire box; check relay chain
<br>&nbsp;&nbsp; Device not in terminal UI&nbsp; Cable not detected&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Press RESCAN NETWORK
<br>&nbsp;&nbsp; STATUS = OVERLOAD&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Draw exceeds generation capacity&nbsp; Insert another core or reduce load
<br>&nbsp;&nbsp; Core ejected on insert&nbsp;&nbsp;&nbsp;&nbsp; Core was already depleted&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Recycle in core fabricator
<br>&nbsp;&nbsp; Cannot anchor / unanchor&nbsp;&nbsp; Generator is online&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Power down before servicing
<br>
<br>
<hr>
<b>9.0 &nbsp; SCHEDULED MAINTENANCE</b>
<br>
<br>&nbsp;&nbsp; INTERVAL&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; TASK
<br>&nbsp;&nbsp; \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500&nbsp;&nbsp; \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
<br>&nbsp;&nbsp; Every 15 min&nbsp; Service the generator with a wrench while running to seat
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; fuel line seals.  No shutdown required.  Overdue units risk
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; progressive seal degradation and possible fuel spill.
<br>&nbsp;&nbsp; Per fuel load&nbsp; Clear exhaust port.  Retrieve depleted casing promptly.
<br>&nbsp;&nbsp; Weekly&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Run RESCAN NETWORK.  Verify all expected devices listed.
<br>&nbsp;&nbsp; Monthly&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Inspect cable runs for scorching, kinking, or battle damage.
<br>&nbsp;&nbsp; As required&nbsp;&nbsp; Re-apply lock configuration after personnel changes.
<br>
<br>
<hr>
<center><i>Vault-Tec Corporation.  Building a better tomorrow, today.</i></center>
<center><i>This document is the property of Vault-Tec Corporation.</i></center>
<center><i>Unauthorised duplication is a violation of V-T Regulation 7.4.1(b).</i></center>"}


/obj/item/paper/f13/power_grid_guide/diesel
	name = "CP-8800 Diesel Generator -- Operator's Field Manual"
	info = {"<center><b>CONTINENTAL PETROLEUM SERVICES</b></center>
<center>Field Equipment Division</center>
<center>MODEL CP-8800 DIESEL GENERATOR</center>
<center><b>OPERATOR'S FIELD MANUAL</b></center>
<br>
<center>DOCUMENT: CPS-FE-8800-OPR &nbsp;|&nbsp; REVISION 2</center>
<hr>
<br>
<b>1. INTRODUCTION</b>
<br>
<br>The CP-8800 is a heavy-duty diesel generator rated for continuous industrial service.
Unlike fusion or atomic systems, it runs on ordinary petroleum distillate -" diesel fuel
-" available from virtually any pre-War storage facility, filling station, or a good
enough scavenging run.  No rare components.  No exotic physics.  Just fuel and fire.
<br>
<br>The unit produces a continuous 750 W and will power most light industrial loads
indefinitely as long as the fuel supply is maintained.
<br>
<br>
<b>2. SAFETY</b>
<br>
<br>&nbsp;&nbsp; (a) Diesel fuel is FLAMMABLE.  No open flames.  No sparks near the tank.
<br>&nbsp;&nbsp; (b) Keep the exhaust clear.  Carbon monoxide accumulation indoors is lethal.
<br>&nbsp;&nbsp;    Operator is responsible for ventilation.
<br>&nbsp;&nbsp; (c) Do not refuel while the unit is hot.  Allow cooling before adding fuel.
<br>&nbsp;&nbsp; (d) Fuel spills must be cleaned up promptly.
<br>&nbsp;&nbsp; (e) DO NOT substitute vegetable oil, water, or improvised liquids.
<br>&nbsp;&nbsp;    Injector damage from bad fuel is not covered under service.
<br>&nbsp;&nbsp;    (Note: warranty service is unlikely to be available in your area.)
<br>
<br>
<b>3. FUEL REQUIREMENTS</b>
<br>
<br>Fuel type: petroleum diesel distillate.  Standard wasteland-grade is acceptable.
<br>Delivery: any fuel-rated reagent container.  Standard jerrycan recommended.
<br>Tank capacity: 1,440 L total.  One full jerrycan (500 L) provides ~17 minutes.
<br>
To refuel: connect a fuel hose or pour directly from any fuel container into the fill
port on the side panel.  Fuel transfers until the tank is full or the container empties.
The generator starts automatically on first fill if it was previously stopped.
<br>
<br>To drain the tank: turn the drain cock on the underside of the tank, or open the
DRAIN TANK valve from the access panel.
Warning -" drained fuel is vented.  It cannot be recovered.  Shut down first.
<br>
<br>
<b>4. INSTALLATION</b>
<br>
<br>&nbsp;&nbsp; 1.&nbsp; Position the unit.  Leave at least 1 tile exhaust clearance.
<br>&nbsp;&nbsp; 2.&nbsp; Anchor to floor with a wrench.
<br>&nbsp;&nbsp; 3.&nbsp; Run cable from the generator's output terminal to junction boxes, relays, and clients.
<br>&nbsp;&nbsp; 4.&nbsp; Load diesel fuel.  Generator starts automatically on first load.
<br>&nbsp;&nbsp; 5.&nbsp; Open the integrated access panel.  Verify STATUS = ONLINE.
<br>
<br>
<b>5. OPERATION AND GRID INTEGRATION</b>
<br>
<br>Run cable from the output terminal to downstream relays and junction boxes for
extended coverage.  Full load-management and load-shedding is supported.  Total draw
must stay below 750 W; loads are shed automatically before a hard grid trip.
<br>
<br>Fuel burns at approximately 1 L per 2 seconds.  Monitor the FUEL indicator in the
access panel.  A low-fuel alert is broadcast to faction members when approximately
3 minutes of runtime remain.
<br>
<br>Service the unit with a wrench approximately every 15 minutes while running.
This seats fuel line connections and clears the maintenance log.  Neglected units
risk fuel vapour accumulation and ignition near the tank.
<br>
<br>
<b>6. TROUBLESHOOTING</b>
<br>
<br>&nbsp;&nbsp; Unit won't start ......... no diesel in tank
<br>&nbsp;&nbsp; Won't accept fuel ........ container has no diesel reagent
<br>&nbsp;&nbsp; OVERLOAD warning ......... draw exceeds 750W -" reduce connected load
<br>&nbsp;&nbsp; Zone stays dark .......... junction box not wired, or relay offline
<br>&nbsp;&nbsp; Device missing from UI ... use Rescan Network button in access panel
<br>&nbsp;&nbsp; Maintenance due .......... apply a wrench while running -- no shutdown needed
<br>
<br>
<b>7. SPECIFICATIONS</b>
<br>
<br>&nbsp;&nbsp; Output: 750 W continuous (flat -" does not scale with fuel level)
<br>&nbsp;&nbsp; Fuel type: petroleum diesel distillate (direct-fill; no canisters required)
<br>&nbsp;&nbsp; Tank: 1,440 L (~2.9 full jerrycans)
<br>&nbsp;&nbsp; Runtime: ~48 min full | ~17 min per jerrycan
<br>
<br>
<hr>
<center><i>Continental Petroleum Services -" Built to last.</i></center>
<center><i>For equipment service, contact your local CPS distributor.</i></center>
<center><i>(No distributors are currently operational in your area.)</i></center>"}


/obj/item/paper/f13/power_grid_guide/atomic
	name = "Poseidon PEAG-5 Atomic Generator -- Owner's Guide"
	info = {"<center><b>POSEIDON ENERGY CORPORATION</b></center>
<center><i>Clean Power for a Better Tomorrow</i></center>
<br>
<center><b>PEAG-5 SERIES ATOMIC GENERATOR</b></center>
<center>Owner's Guide &amp; Installation Manual</center>
<br>
<center>Document: PE-PEAG5-OWN &nbsp;|&nbsp; Revision 1.2</center>
<hr>
<br>
<b>WELCOME FROM POSEIDON ENERGY</b>
<br>
<br>Congratulations on your purchase of the Poseidon Energy PEAG-5 Atomic Generator.
You have selected the finest compact atomic power source available to non-licensed
civilian facilities.  The PEAG-5 will provide clean, reliable, <i>atomic</i> power for
your installation for years to come.
<br>
<br>At Poseidon Energy, we believe the atom belongs to everyone.  The PEAG-5 is our
commitment to putting that belief into practice -" one settlement at a time.
<br>
<br>
<b>1. THE SCIENCE OF ATOMIC POWER</b>
<br>
<br>The PEAG-5 operates on a single POS-7R atomic fuel cell: a shielded dense-alloy
rod containing refined fissile material, processed at Poseidon Energy facilities.
The POS-7R sustains a controlled atomic fission reaction, which the PEAG-5 converts
directly into 1,500 watts of usable electrical output.
<br>
<br>This output exceeds comparable fusion generators by 50% and diesel generators by
100%, while requiring significantly less frequent refuelling.  One cell powers a
typical faction installation for approximately 22 minutes.
<br>
<br><i>Poseidon Energy: More Power.  Less Everything Else.</i>
<br>
<br>
<b>2. SAFETY INFORMATION</b>
<br>
<br>The POS-7R atomic fuel cell is a Class I fissile assembly rated safe for civilian
handling under normal operating conditions.  Radiation shielding is permanently
integrated into the cell casing.
<br>
<br>&nbsp;&nbsp; (a) Do not open, puncture, or attempt to machine the cell casing.
<br>&nbsp;&nbsp; (b) Do not expose the cell to sustained temperatures above 1,200&deg;F.
<br>&nbsp;&nbsp; (c) Keep away from children.  Keep children away from the generator entirely.
<br>&nbsp;&nbsp; (d) Depleted cells retain residual radiation.  Deep burial recommended.
<br>&nbsp;&nbsp; (e) In the event of visible cell casing damage, evacuate immediately and
<br>&nbsp;&nbsp;    contact Poseidon Energy Emergency Services.
<br>&nbsp;&nbsp;    (Poseidon Energy Emergency Services may not currently be available.)
<br>
<br>
<b>3. INSTALLATION</b>
<br>
<br>&nbsp;&nbsp; Step 1.&nbsp; Position on a stable, level surface.
<br>&nbsp;&nbsp; Step 2.&nbsp; Anchor to floor with a wrench.
<br>&nbsp;&nbsp; Step 3.&nbsp; Wire downstream devices with a cable coil (optional but recommended).
<br>&nbsp;&nbsp; Step 4.&nbsp; Load the POS-7R atomic fuel cell through the top-facing insertion port.
<br>&nbsp;&nbsp; Step 5.&nbsp; Generator starts immediately.  Depleted casing is ejected from the port.
<br>&nbsp;&nbsp; Step 6.&nbsp; Verify STATUS = ONLINE and output = 1,500W in the terminal.
<br>
<br>
<b>4. LOADING A FUEL CELL</b>
<br>
<br>The PEAG-5 accepts ONE POS-7R atomic fuel cell.  The single-cell chamber ensures
maximum efficiency and minimises criticality risk from improper multi-cell loading.
<br>
To insert: load the cell through the top-facing insertion port.  The previous
cycle's spent casing is ejected automatically.
Retain depleted casings -- submission for Poseidon Energy recycling credit is available.
(Recycling submission facilities may not currently be operational.)
<br>
<br>To eject remaining fuel: actuate the manual ejection lever on the side panel,
or select EJECT FUEL from the access panel.
The cell is ejected as a depleted casing.  Remaining fuel capacity is forfeited.
<br>
<br>
<b>5. OPERATION</b>
<br>
<br>The PEAG-5 produces 1,500 W continuously for the full life of the inserted cell.
Output does not degrade as the cell depletes -" full 1,500W right until exhaustion.
A low-fuel warning is issued approximately 3 minutes before shutdown.
<br>
<br>Integrates in full with the faction power grid.  Run cable from the output terminal
to downstream relays and junction boxes for extended coverage.  Load-shedding is
supported.
<br>
<br>Service the unit with a wrench approximately every 15 minutes while running.
This maintains containment seal integrity.  Neglected units may exhibit localised
radiation leakage from aged seals.
<br>
<br>
<b>6. TROUBLESHOOTING</b>
<br>
<br>&nbsp;&nbsp; Unit offline ............. no cell loaded -" insert a POS-7R cell
<br>&nbsp;&nbsp; Cell rejected ............ cell is depleted (dark indicator light)
<br>&nbsp;&nbsp; OVERLOAD ................. 1,500W total draw exceeded -" reduce load
<br>&nbsp;&nbsp; No powered areas ......... wire junction boxes or configure area list
<br>&nbsp;&nbsp; Unusual radiation ........ containment seals may need service.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Apply a wrench while running to clear the maintenance log.
<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; If leakage persists, contact Poseidon Energy technical support.
<br>
<br>
<b>7. SPECIFICATIONS</b>
<br>
<br>&nbsp;&nbsp; Output: 1,500 W continuous (flat per cell)
<br>&nbsp;&nbsp; Fuel: Poseidon Energy POS-7R atomic fuel cell (one-cell chamber)
<br>&nbsp;&nbsp; Runtime per cell: ~22 min
<br>&nbsp;&nbsp; Cell ejection: automatic on depletion; manual via screwdriver or terminal
<br>
<br>
<hr>
<center><i>Poseidon Energy Corporation.  Clean Power for a Better Tomorrow.</i></center>
<center><b><i>"The atom is your friend."</i></b></center>"}


/obj/item/paper/f13/power_grid_guide/wastelander
	name = "genrater -- how to use it"
	info = {"<b>GENRATER HOW TO USE IT</b>
<br>writ by WADE TUCKER (mechanic, Riverside Station)
<br>
<br>---
<br>
<br>this is the WASTELAND MODEL. not the vault-tec grid thing.
<br>UPDATED this note because the old one was wrong.
<br>read this one, not whatever youve heard.
<br>
<br>---
<br>
<br><b>WHAT IT DOES</b>
<br>
<br>powers stuff near it. about 10 tiles out.
<br>stuff further away than that wont get it even if its wired.
<br>
<br>UNLIKE WHAT I WROTE BEFORE: you DO have to wire it.
<br>i was wrong the first time. sorry.
<br>it still does the spread-out thing naturally for things right next to it.
<br>but if you want to run power down a corridor to a room
<br>you need relay posts and a breaker panel. same idea as the vault-tec
<br>units just smaller and more beat-up looking.
<br>
<br>so it DOES do the grid thing. just only within 10 tiles.
<br>relays outside that range wont carry the power even if wired.
<br>keep your grid tight.
<br>
<br>---
<br>
<br><b>FUEL</b>
<br>
<br>runs on DIESEL FUEL. pour it from a jerrycan or any fuel container.
<br>theres a fill port on top, funnel is already welded on there.
<br>just tip the container into the funnel and it flows in.
<br>tank holds about 1000 units.
<br>one full jerrycan (500 units) = about 17 minutes.
<br>
<br>check the gauge on the side panel to see how much fuel is left.
<br>when its low it will send a message out. dont ignore it.
<br>
<br>---
<br>
<br><b>WIRING IT UP</b>
<br>
<br>1. place the main breaker panel near the generator
<br>2. run cable from the generator output to the breaker panel
<br>3. run cable from the breaker out to relay posts for longer runs
<br>4. connect your devices off the relay posts or direct cable
<br>5. everything within 10 tiles of the generator gets power
<br>   - stuff beyond 10 tiles wont get it even if the wire reaches
<br>
<br>the breaker panel is useful. flip the lever on it to cut power to
<br>everything downstream without touching the generator.
<br>good for when something catches fire and you need to isolate fast.
<br>
<br>---
<br>
<br><b>STARTING IT</b>
<br>
<br>1. bolt it down first (wrench it so it dont shift)
<br>2. pour fuel in the top funnel
<br>3. it starts itself once fuel is in
<br>
<br>if it wont start: check the gauge for how much fuel is showing.
<br>if fuel is showing and still nothing: flip the main switch on the
<br>panel face off and back on.
<br>
<br>---
<br>
<br><b>MOVING IT</b>
<br>
<br>shut it down first. flip the main switch on the panel face to OFF
<br>and wait for the hum to stop.
<br>open the drain valve on the underside (the fuel vents - you lose it, sorry).
<br>unbolt with wrench. now you can move it.
<br>refuel and restart at the new spot.
<br>
<br>if it refuses to restart after moving: unbolt it, shift it one tile,
<br>bolt it back and try again. sometimes the ground contact needs resetting.
<br>
<br>---
<br>
<br><b>MAINTENANCE</b>
<br>
<br>HIT IT WITH A WRENCH EVERY 15 MINUTES WHILE RUNNING.
<br>i know it sounds stupid but the fuel line fittings vibrate loose.
<br>if you dont tighten them the vapour builds up near the tank.
<br>i have personally seen one of these catch fire because nobody
<br>bothered to check it. it is not a small fire.
<br>
<br>you do NOT need to shut it down to service it.
<br>just wrench it while its running. takes two seconds.
<br>
<br>---
<br>
<br><b>IF IT STOPS WORKING</b>
<br>
<br>no fuel = add fuel.
<br>gauge says OVERLOAD = too many devices on the grid. remove something.
<br>lights out but gauge says running = check the breaker panel lever.
<br>device not getting power but wired = check if its within 10 tiles.
<br>wont restart after move = unbolt, shift one tile, rebolt, try again.
<br>
<br>---
<br>
<br><b>NOTES</b>
<br>
<br>diesel smells. if theres a window, open it.
<br>keep it away from gunpowder. you would think this is obvious.
<br>if anything breaks and its my setup thats to blame ill fix it for free.
<br>if its not my fault its 5 caps minimum.
<br>
<br>---
<br>
<br>- W. Tucker
<br>(if this breaks ask for me at Riverside, ill take a look)
"}

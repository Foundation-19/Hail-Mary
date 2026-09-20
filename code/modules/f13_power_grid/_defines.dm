// ============================================================
// FUSION CORE POWER GRID — DEFINES
// ============================================================

// ── Generator / Fabricator lock modes

/// No lock — anyone can interact with this machine.
#define GENERATOR_LOCK_NONE     0
/// Personal lock — only the registered owner_ckey can interact.
#define GENERATOR_LOCK_PERSONAL 1
/// Faction lock — only members of the registered owner_faction can interact.
#define GENERATOR_LOCK_FACTION  2

// ── Fuel constants

/// Fuel ticks added per fusion core (SSobj wait=20 = ~2s/tick; 900 ticks ≈ 30 min per core —
/// two slots = ~1 hour full tank).
#define FUSION_CORE_FUEL        900
/// Fuel ticks added per 1 reagent-volume unit of diesel poured into a liquid-fuel generator.
/// At 1:1 a full standard jerrycan (500 vol) = 500 ticks ≈ 16.7 min.
#define DIESEL_TICKS_PER_VOLUME  1
/// Litres drained per pump cycle when manually siphoning a liquid-fuel generator's tank —
/// a gradual hand-pump action rather than instantly dumping the whole reservoir.
#define GENERATOR_SYPHON_RATE        100
/// Deciseconds between siphon pump cycles (1 second per pump stroke).
#define GENERATOR_SYPHON_CYCLE_TIME  10
/// SSobj ticks a generator can run after being serviced before wear starts accruing at all.
/// 2700 ticks × 2 s = 5400 s ≈ 90 min.  A freshly-serviced unit is reliable until this passes.
#define FGEN_WEAR_GRACE_PERIOD          2700
/// SSobj ticks between wear rolls once past the grace period. 900 ticks × 2 s = 1800 s ≈ 30 min.
#define FGEN_WEAR_CHECK_INTERVAL        900
/// Max wear stacks (100% worn). Reached only after many unlucky/neglected rolls.
#define FGEN_WEAR_MAX                   10
/// Base percent chance per check to gain a wear stack, before any existing stacks are counted.
#define FGEN_WEAR_BASE_CHANCE           8
/// Extra percent chance per existing wear stack when rolling for another one.
#define FGEN_WEAR_CHANCE_PER_STACK      4
/// Wear stacks required before a hazard roll is even possible — hazards are a rare, late-stage
/// consequence of prolonged neglect, not an early risk.
#define FGEN_WEAR_HAZARD_THRESHOLD      6
/// Base percent chance per check for an actual hazard once past FGEN_WEAR_HAZARD_THRESHOLD.
#define FGEN_WEAR_HAZARD_BASE_CHANCE    3
/// Extra percent chance per wear stack above the hazard threshold.
#define FGEN_WEAR_HAZARD_CHANCE_PER_STACK 2
/// Default starting fuel for a generator (1800 ticks ≈ 60 min — capped to each type's own
/// max_fuel, so this only matters for types whose tank is at least that big).
#define FGEN_DEFAULT_FUEL       1800
/// Fuel level at which a low-power warning is broadcast to the faction (~3 min remaining).
#define FGEN_LOW_FUEL_WARN      90
/// SSobj ticks between automatic re-validation of wired links (cable path re-checked against
/// the live map). 5 ticks × 2 s = 10 s, so a cable severed by an explosion (or anything else)
/// stops being powered shortly after, without needing a manual rescan.
#define FGEN_LINK_PRUNE_INTERVAL 5
/// SSobj ticks between automatic retry attempts for a generator tripped from overload (not
/// out of fuel, not manually shut down). Retries are fully silent on failure — only a success
/// is announced — so this can stay short: 10 ticks × 2 s = 20 s.
#define FGEN_OVERLOAD_RETRY_INTERVAL 10
/// Minimum fraction of rated fuel burn a running generator always pays per powered area it
/// owns, even at 0 tracked watts of draw — accounts for the vanilla area equipment (lights/
/// doors/APCs) that stamp_zone() powers directly and isn't metered through current_draw.
/// A generator that owns no powered areas AND has no custom wiring pays 0 — there's nothing
/// unmetered left for it to be secretly running.
#define FGEN_MIN_LOAD_FRACTION_PER_AREA  0.03
/// Hard ceiling on the per-area baseline above, so a generator with a huge base attached
/// never gets floored above half its rated capacity just from unmetered area equipment.
#define FGEN_MIN_LOAD_FRACTION_CAP       0.6

// ── Fabricator crafting constants

/// SSobj ticks required to craft one fusion core (60 ticks × 2s = ~2 minutes per core).
#define FAB_CRAFT_TICKS         60

/// Materials required per core (full cost, no depleted shell in the buffer).
#define FAB_REQ_URANIUM         2
#define FAB_REQ_METALPARTS      5
#define FAB_REQ_ELECTRONICPARTS       3

/// Material cost when a depleted fusion core shell is in the buffer (50% reduction).
#define FAB_REQ_URANIUM_RECYCLE   1
#define FAB_REQ_METALPARTS_RECYCLE 3
#define FAB_REQ_ELECTRONICPARTS_RECYCLE  2

// ── Fabricator states
#define FAB_STATE_IDLE      0   // Not crafting; waiting for materials / start command.
#define FAB_STATE_CRAFTING  1   // Actively crafting; SSobj processing is running.

// ── Wattage budget — Factorio-style power accounting
//    Everything that draws from a generator reduces its available_watts pool.
//    If total_draw > available_watts the generator trips the circuit breaker
//    and calls set_power_state(FALSE) until the overload is cleared.

/// Watts produced per fusion core slot.
/// Bumped from 1000 -> 1500 so a single loaded core comfortably covers a
/// larger multi-zone junction box (7+ zones) without tripping load-shedding.
#define FGEN_WATTS_PER_CORE     1500

/// Continuous watt draw of each directly-wired relay (transmission overhead).
#define RELAY_WATT_DRAW         50

/// Watt draw of a core fabricator while actively crafting.
#define FAB_WATT_DRAW_ACTIVE    300
/// Watt draw of a core fabricator while idle but wired and powered.
#define FAB_WATT_DRAW_IDLE      50

/// Watt draw of each turret managed by a relay or generator.
#define TURRET_WATT_DRAW        100

/// Default watt draw for a generic /obj/machinery/f13/grid_client.
/// Override grid_watt_draw on the subtype for anything non-standard.
#define GRID_CLIENT_WATT_DEFAULT 100

/// Fixed overhead watt draw for a junction box, independent of size (panel/transformer
/// standby losses) — charged once per box, not per zone. Total draw = JUNCTION_BOX_WATT_DRAW_BASE
/// + (JUNCTION_BOX_WATT_PER_TILE * total tiles across all claimed zones). Larger panels
/// carry more overhead but a lower per-tile rate, so one large box undercuts a chain of
/// small boxes once a building is big enough (e.g. a BOS-sized multi-room compound) --
/// without this, small boxes are strictly cheaper than large ones at every scale.
#define JUNCTION_BOX_WATT_DRAW_BASE 60

/// Watt draw PER TILE across every zone a standard /obj/machinery/f13/junction_box claims —
/// the entire cost of powering a building scales with its actual floor area, not a flat
/// per-room charge. Kept small: a 2500-tile bunker should cost a few hundred watts, not
/// eat an entire generator's rated output by itself. Use /junction_box/small (0.3 W/tile,
/// 25 W base) for shacks, /junction_box/large (0.1 W/tile, 150 W base) for compounds.
#define JUNCTION_BOX_WATT_PER_TILE 0.18

// ── Logic gate types
#define GATE_OR   1
#define GATE_AND  2
#define GATE_NOT  3
#define GATE_NAND 4
#define GATE_NOR  5
#define GATE_XOR  6
#define GATE_XNOR 7

// ── Relay repair constants
/// HP restored per wrench hit on a damaged relay.
#define RELAY_REPAIR_AMOUNT     50
/// Tool required to repair a relay — TOOL_WRENCH matches the existing wrench-to-anchor verb.
/// Relay must be offline (relay_powered == FALSE) to be repaired from destroyed state.

// ── Power-channel shorthand (mirrors SS13 EQUIP/LIGHT/ENVIRON)
// Calls the proc below rather than inlining to avoid the async sub_area timing bug.
#define F13_STAMP_AREA_POWER(area_ref, state) f13_stamp_area_power((area_ref), (state))

// ============================================================
// POWER-GRID TRACE LOG
// Rolling log of the last 50 power-grid events.  After an MC
// stall/restart, use the "F13 Power Trace Dump" admin verb to
// read out what was running when the server locked up.
// ============================================================

GLOBAL_LIST_EMPTY(f13_trace_log)

/// Append a timestamped message to the rolling trace log AND to
/// game/log so it also shows up in the log files on disk.
/proc/f13_log_op(msg)
	var/entry = "[world.time]ds: [msg]"
	GLOB.f13_trace_log += entry
	// Keep the list capped at 50 entries (trim from the front).
	if(GLOB.f13_trace_log.len > 50)
		GLOB.f13_trace_log.Cut(1, GLOB.f13_trace_log.len - 49)
	log_game("F13_PWR: [msg]")

// ── area/f13/power_change() override
// The base area/power_change() iterates machines with no yield points.
// For large zones (hundreds–thousands of machines) that loop blocks the
// MC for 80+ ticks, triggering SSobj watchdog restarts.
// This override inserts CHECK_TICK every 25 machines so BYOND can let
// the MC fire between batches, and logs begin/end for post-mortem diagnosis.
/area/f13/power_change()
	f13_log_op("power_change BEGIN [name] equip=[power_equip]")
	var/mcount = 0
	var/last_type = "none"
	for(var/obj/machinery/M in src)
		last_type = M.type
		M.power_change()
		if(++mcount % 25 == 0)
			CHECK_TICK
	if(sub_areas)
		for(var/i in sub_areas)
			var/area/A = i
			A.power_light   = power_light
			A.power_equip   = power_equip
			A.power_environ = power_environ
			INVOKE_ASYNC(A, PROC_REF(power_change))
	update_icon()
	f13_log_op("power_change END [name] machines=[mcount] last=[last_type]")

// Power-off iteration for f13 areas.  Called via INVOKE_ASYNC so CHECK_TICK is safe here.
// Lights are handled directly to suppress SS13's emergency-red path.
/area/f13/proc/f13_power_off_async()
	f13_log_op("stamp_area OFF [name] (start)")
	var/count = 0
	for(var/obj/machinery/M in src)
		if(!istype(M, /obj/machinery/light))
			M.power_change()
		if(++count % 25 == 0)
			CHECK_TICK
	for(var/obj/machinery/light/L in src)
		if(!QDELETED(L))
			L.on = FALSE
			L.emergency_mode = FALSE
			L.set_light(0)
			L.update_icon()
	if(sub_areas)
		for(var/area/sub in sub_areas)
			f13_stamp_area_power(sub, FALSE)
	update_icon()
	f13_log_op("stamp_area OFF [name] (done, [count] machines)")

/// Stamp power onto an area and kick off async machine iteration.
/// Both on and off paths use INVOKE_ASYNC so this proc never directly sleeps.
/proc/f13_stamp_area_power(area/A, state)
	if(QDELETED(A))
		return
	A.power_equip   = state
	A.power_light   = state
	A.power_environ = state
	if(state)
		f13_log_op("stamp_area ON [A.name] (async queued)")
		INVOKE_ASYNC(A, TYPE_PROC_REF(/area, power_change))
	else
		f13_log_op("stamp_area OFF [A.name] (async queued)")
		INVOKE_ASYNC(A, TYPE_PROC_REF(/area/f13, f13_power_off_async))

// F13 area lights have no backup cells — delete the emergency cell after parent creates it.
/obj/machinery/light/Initialize(mapload)
	. = ..()
	if(istype(get_area(src), /area/f13) && cell)
		qdel(cell)
		cell = null

// ============================================================
// SHARED TERMINAL-STYLE UI HELPERS
// Mirrors terminal.dm's get_terminal_css / get_terminal_header so that all
// f13 power-grid machine UIs use a consistent Fallout terminal aesthetic.
// ============================================================

/obj/machinery/f13/proc/get_terminal_css()
	var/css = "<head><style>"
	css += "body{padding:0;margin:15px;background-color:#062113;color:#4aed92;line-height:170%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;cursor:default;}"
	css += "a:hover{color:#062113;background:#4aed92;}"
	css += "table{border-spacing:6px 3px;}"
	css += ".good{color:#4aed92;font-weight:bold;}"
	css += ".bad{color:#c0392b;font-weight:bold;animation:blink 1s step-start infinite;}"
	css += ".dim{color:#2a7a52;}"
	css += ".warn{color:#e8a020;font-weight:bold;}"
	css += ".head{color:#4aed92;letter-spacing:2px;font-weight:bold;}"
	css += ".sep{color:#2a7a52;}"
	css += "@keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}"
	css += "</style></head>"
	return css

/obj/machinery/f13/proc/get_terminal_header(title_line)
	var/h = "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	h += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	h += "= [title_line] =</center><br>"
	return h

// F13 machines manage their own power — never let APC power_change() set NOPOWER on them.
/obj/machinery/f13/power_change()
	return


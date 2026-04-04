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

/// Fuel ticks added per fusion core (SSobj wait=20 = ~2s/tick; 450 ticks ≈ 15 min per core).
#define FUSION_CORE_FUEL        450
/// Fuel ticks added per 1 reagent-volume unit of diesel poured into a liquid-fuel generator.
/// At 1:1 a full standard jerrycan (500 vol) = 500 ticks ≈ 16.7 min.
#define DIESEL_TICKS_PER_VOLUME  1
/// SSobj ticks between mandatory wrench-service events on a running generator.
/// 450 ticks × 2 s = 900 s ≈ 15 min.  Overdue generators trigger type-specific hazard effects.
/// Service by applying a wrench while the unit is running — no shutdown required.
#define FGEN_MAINTENANCE_INTERVAL 450
/// Default starting fuel for a generator (1350 ticks ≈ 45 min, i.e. half a ~90 min round).
#define FGEN_DEFAULT_FUEL       1350
/// Fuel level at which a low-power warning is broadcast to the faction (~3 min remaining).
#define FGEN_LOW_FUEL_WARN      90

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

/// Watts produced per fusion core slot (one core = 1000 W).
#define FGEN_WATTS_PER_CORE     1000

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

/// Baseline watt draw for a standard /obj/machinery/f13/junction_box.
/// Represents the building's lighting + outlet load (150 W).
/// Use /junction_box/small (75 W) for shacks, /junction_box/large (250 W) for compounds.
#define JUNCTION_BOX_WATT_DRAW  150

// ── Relay repair constants
/// HP restored per wrench hit on a damaged relay.
#define RELAY_REPAIR_AMOUNT     50
/// Tool required to repair a relay — TOOL_WRENCH matches the existing wrench-to-anchor verb.
/// Relay must be offline (relay_powered == FALSE) to be repaired from destroyed state.

// ── Power-channel shorthand (mirrors SS13 EQUIP/LIGHT/ENVIRON)
/// Set all three SS13 power channels on an area to the given state and fire power_change().
#define F13_STAMP_AREA_POWER(area_ref, state) \
	if(!QDELETED(area_ref)) { \
		(area_ref).power_equip   = state; \
		(area_ref).power_light   = state; \
		(area_ref).power_environ = state; \
		(area_ref).power_change(); \
	}


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


///////////////////////////////////////////////////////////////
// WASTELAND GRID (Fallout 13 / Hail-Mary)
// v2 PLANT OPS EXPANSION (single-file)
//
// Keeps your existing:
// - online/state/faults/escalation
// - repair points + multipart consumption
// - restart ritual + rolling blackouts + background rads
// - work order board
//
// Adds (ALL IN THIS FILE):
// - plant process model (reactivity/flow/pressures/steam/turbine/output)
// - operator setpoints (rods/valves/bypass/relief/target output + SCRAM)
// - wear + chemistry + instrumentation drift
// - causal fault triggers (overpressure/overheat/wear/ops error)
// - maintenance tasks queue (datum/grid_task) + completion hooks
// - pipe networks (datum/grid_network) + component registry
// - physical plant objects: valves, pumps, relief, filter, heat exchanger,
//   turbine controller, sensor panel, breaker cabinet, purge valve
// - procedures: coolant purge (timed, requires valve + pump actions)
//
// NOTE: you MUST place the new plant objects on the map for gameplay.
//       (see "CONCRETE PLANT OBJECTS" section)
///////////////////////////////////////////////////////////////

/*
CORE RULES:
- Console sets targets. Physical components + sim loop do the work.
- Failures are mostly causal, not RNG. RNG only spices.
*/

///////////////////////////////////////////////////////////////
// GLOBALS (existing)
///////////////////////////////////////////////////////////////

// Radiation source anchor for SSradiation waves
GLOBAL_VAR(grid_rad_source)
GLOBAL_VAR(wasteland_grid_wave_tick_counter)

GLOBAL_VAR(wasteland_grid_online)
GLOBAL_VAR(wasteland_grid_state) // "GREEN","YELLOW","RED","OFF"
GLOBAL_VAR(wasteland_grid_district_off_until)
GLOBAL_VAR(wasteland_grid_district_forced_off)
GLOBAL_VAR(wasteland_grid_district_applied_on)
GLOBAL_VAR(wasteland_grid_relays_by_district)
GLOBAL_VAR(wasteland_grid_apc_saved_operating)
GLOBAL_VAR(wasteland_grid_area_saved_power)

GLOBAL_VAR(wasteland_grid_fuel)
GLOBAL_VAR(wasteland_grid_coolant)

GLOBAL_VAR(wasteland_grid_faults) // list(/datum/wasteland_grid_fault)
GLOBAL_VAR(wasteland_grid_last_trip)

// Reactor health + map-wide radiation driver (existing high-level)
GLOBAL_VAR(wasteland_grid_core_heat)       // 0..100
GLOBAL_VAR(wasteland_grid_containment)     // 0..100
GLOBAL_VAR(wasteland_grid_integrity)       // 0..100
GLOBAL_VAR(wasteland_grid_background_rads) // scalar 0..~30+

GLOBAL_VAR(wasteland_grid_rads_tick_counter)

// Restart ritual (existing)
GLOBAL_VAR(wasteland_grid_restart_stage)      // 0..3
GLOBAL_VAR(wasteland_grid_restart_operator)   // ckey string
GLOBAL_VAR(wasteland_grid_restart_lock)       // bool
GLOBAL_VAR(wasteland_grid_restart_cooldown_until) // world.time

GLOBAL_VAR(wasteland_grid_bootstrapping)

///////////////////////////////////////////////////////////////
// GLOBALS (v2 plant ops)
///////////////////////////////////////////////////////////////

// Operator controls / setpoints
GLOBAL_VAR(grid_sp_target_output)     // 0..100
GLOBAL_VAR(grid_sp_rod_insertion)     // 0..100 (higher = less power)
GLOBAL_VAR(grid_sp_coolant_valve)     // 0..100
GLOBAL_VAR(grid_sp_feedwater_valve)   // 0..100
GLOBAL_VAR(grid_sp_relief_valve)      // 0..100
GLOBAL_VAR(grid_sp_bypass)            // 0..100
GLOBAL_VAR(grid_sp_turbine_governor)  // 0..100 (maps to rpm demand)
GLOBAL_VAR(grid_sp_boron_ppm)         // 0..2000 (soluble boron setpoint)
GLOBAL_VAR(grid_scram)                // bool

// Process variables
GLOBAL_VAR(grid_core_reactivity)      // 0..100
GLOBAL_VAR(grid_primary_flow)         // 0..100
GLOBAL_VAR(grid_primary_pressure)     // 0..200
GLOBAL_VAR(grid_secondary_pressure)   // 0..200
GLOBAL_VAR(grid_steam_quality)        // 0..100
GLOBAL_VAR(grid_turbine_rpm)          // 0..200
GLOBAL_VAR(grid_output)               // 0..100
GLOBAL_VAR(grid_turbine_stress)       // 0..100
GLOBAL_VAR(grid_turbine_moisture)     // 0..100 (wetness)

// Core physics extensions (xenon/boron/decay/burnup)
GLOBAL_VAR(grid_xenon_poison)         // 0..40
GLOBAL_VAR(grid_iodine_inventory)     // 0..40
GLOBAL_VAR(grid_samarium_poison)      // 0..20
GLOBAL_VAR(grid_fuel_burnup)          // 0..100
GLOBAL_VAR(grid_reactivity_reserve)   // -30..30
GLOBAL_VAR(grid_decay_heat)           // 0..50
GLOBAL_VAR(grid_boron_ppm)            // 0..2000
GLOBAL_VAR(grid_doppler_coeff)        // 0..1 (negative feedback strength)
GLOBAL_VAR(grid_moderator_coeff)      // -0.3..1 (can go slightly positive)
GLOBAL_VAR(grid_subcool_margin)       // 0..100
GLOBAL_VAR(grid_npsh_margin)          // 0..100 (pump suction margin)

// Consumables + chemistry
GLOBAL_VAR(grid_coolant_contamination) // 0..100
GLOBAL_VAR(grid_filter_clog)           // 0..100
GLOBAL_VAR(grid_lube_level)            // 0..100

// Pressurizer / condenser abstractions
GLOBAL_VAR(grid_pressurizer_level)     // 0..100
GLOBAL_VAR(grid_pressurizer_heaters)   // 0..100
GLOBAL_VAR(grid_pressurizer_spray)     // 0..100
GLOBAL_VAR(grid_condenser_vacuum)      // 0..100
GLOBAL_VAR(grid_hotwell_level)         // 0..100

// Wear
GLOBAL_VAR(grid_wear_pump_primary)   // 0..100
GLOBAL_VAR(grid_wear_valves)         // 0..100
GLOBAL_VAR(grid_wear_turbine)        // 0..100
GLOBAL_VAR(grid_wear_breakers)       // 0..100
GLOBAL_VAR(grid_wear_sensors)        // 0..100
GLOBAL_VAR(grid_pipe_integrity)      // 0..100 (global baseline; networks have their own too)

// Sensors / instrumentation drift
GLOBAL_VAR(grid_sensor_drift_heat)   // float-ish
GLOBAL_VAR(grid_sensor_drift_press)  // float-ish
GLOBAL_VAR(grid_sensor_drift_flow)   // float-ish
GLOBAL_VAR(grid_sensor_health)       // 0..100

// Maintenance scheduler
GLOBAL_VAR(grid_maint_queue)        // list(/datum/grid_task)
GLOBAL_VAR(grid_last_maint_roll)    // world.time
GLOBAL_VAR(grid_maint_interval)     // ticks

// Networks + components registries
GLOBAL_VAR(grid_networks_by_id)     // assoc id => /datum/grid_network
GLOBAL_VAR(grid_components_by_tag)  // assoc tag => obj
GLOBAL_LIST_EMPTY(grid_icon_state_cache) // "[icon]|[state]" => bool
GLOBAL_LIST_EMPTY(wasteland_grid_turbine_assemblies)
GLOBAL_LIST_EMPTY(wasteland_grid_breaker_cabinets)
GLOBAL_LIST_EMPTY(wasteland_grid_breaker_panels)
GLOBAL_LIST_EMPTY(wasteland_grid_backup_generators)
GLOBAL_LIST_EMPTY(wasteland_grid_filter_units)
GLOBAL_LIST_EMPTY(wasteland_grid_heat_exchangers)
GLOBAL_LIST_EMPTY(wasteland_grid_relief_valves)

// Procedure state: coolant purge
GLOBAL_VAR(grid_proc_purge_stage)     // 0..4
GLOBAL_VAR(grid_proc_purge_operator)  // ckey
GLOBAL_VAR(grid_proc_purge_lock)      // bool
GLOBAL_VAR(grid_proc_purge_started_at)// world.time

// Deliberate catastrophe controls
GLOBAL_VAR(grid_safety_interlocks_enabled) // bool
GLOBAL_VAR(grid_catastrophe_risk)          // 0..100
GLOBAL_VAR(grid_catastrophe_triggered)     // bool
GLOBAL_VAR(grid_interlock_last_trip_at)    // world.time
GLOBAL_VAR(grid_auto_enabled)              // bool
GLOBAL_VAR(grid_auto_player_threshold)     // active player cutoff
GLOBAL_VAR(grid_auto_active)               // bool: currently driving controls
GLOBAL_VAR(grid_auto_last_player_count)    // cached active players
GLOBAL_VAR(grid_lowpop_faults_threshold)   // below this, suppress random/causal faults + maintenance generation
GLOBAL_VAR(grid_debug_controls_enabled)    // admin-only toggle that exposes reactor debug actions in TGUI

// Phase 1: Plant upgrade tree + chemistry program + turbine overhaul
GLOBAL_VAR(grid_plant_upgrade_points)      // spendable upgrade points
GLOBAL_VAR(grid_plant_upgrades)            // assoc key => level
GLOBAL_VAR(grid_add_anticorrosion)         // active additive level 0..100
GLOBAL_VAR(grid_add_antifoam)              // active additive level 0..100
GLOBAL_VAR(grid_add_flowboost)             // active additive level 0..100
GLOBAL_VAR(grid_stock_anticorrosion)       // additive stock 0..250
GLOBAL_VAR(grid_stock_antifoam)            // additive stock 0..250
GLOBAL_VAR(grid_stock_flowboost)           // additive stock 0..250
GLOBAL_VAR(grid_turbine_bearing_cond)      // 0..100
GLOBAL_VAR(grid_turbine_blade_cond)        // 0..100
GLOBAL_VAR(grid_turbine_alignment_cond)    // 0..100
GLOBAL_VAR(grid_overhaul_session)          // list("active","expires","steps","index")
GLOBAL_VAR(grid_overhaul_bonus_until)      // world.time

// Phase 2: Auctions + emergency dispatch
GLOBAL_VAR(grid_auction_open_until)        // world.time
GLOBAL_VAR(grid_auction_round_id)          // integer
GLOBAL_VAR(grid_auction_bids)              // district => bid row
GLOBAL_VAR(grid_district_mw_alloc)         // district => MW allocation
GLOBAL_VAR(grid_committed_mw)              // total allocated MW
GLOBAL_VAR(grid_auction_revenue_pool)      // total escrow pool
GLOBAL_VAR(grid_dispatch_calls)            // list of dispatch rows
GLOBAL_VAR(grid_dispatch_next_id)          // integer
GLOBAL_VAR(grid_dispatch_next_roll)        // world.time

// Phase 3: Spent fuel + theft/forensics
GLOBAL_VAR(grid_spent_fuel_units)          // abstract spent fuel units
GLOBAL_VAR(grid_casks_staged)              // packaged casks
GLOBAL_VAR(grid_casks_stored)              // casks in shielded storage
GLOBAL_VAR(grid_casks_processed)           // cumulative processed casks
GLOBAL_VAR(grid_waste_hazard)              // 0..100
GLOBAL_VAR(grid_theft_by_district)         // district => intensity 0..100
GLOBAL_VAR(grid_theft_load_mw)             // MW lost to theft
GLOBAL_VAR(grid_forensics_report)          // recent scan report rows
GLOBAL_VAR(grid_forensics_last_scan)       // world.time

///////////////////////////////////////////////////////////////
// AREA TAGS (existing mapping knobs)
///////////////////////////////////////////////////////////////

/area
	var/grid_district = null
	var/grid_rads_mult = 1.0

///////////////////////////////////////////////////////////////
// BOOTSTRAP
///////////////////////////////////////////////////////////////

#define GRID_DEFAULT_MAINT_INTERVAL (4 MINUTES)
#define GRID_AUCTION_DURATION (2 MINUTES)
#define GRID_AUCTION_BASE_SUPPLY_MW 120
#define GRID_AUCTION_RESEARCH_PER_MW 10
#define GRID_AUCTION_MAX_SUPPLY_MW 260
#define GRID_DISPATCH_INTERVAL (90 SECONDS)
#define GRID_DISPATCH_TTL (6 MINUTES)
#define GRID_FORENSICS_SCAN_COOLDOWN (30 SECONDS)
#define GRID_CATASTROPHE_CORE_RADIUS 20
#define GRID_CATASTROPHE_CORE_DOSE 140
#define GRID_BACKUP_FUEL_PER_URANIUM_SHEET 3
#define GRID_BACKUP_FUEL_DRAIN_INTERVAL (20 SECONDS)
#define GRID_BACKUP_FUEL_CAP 120
#define GRID_BACKUP_MIN_ACTIVE_FUEL 1

proc/_wasteland_grid_bootstrap()
	if(GLOB.wasteland_grid_bootstrapping)
		return
	GLOB.wasteland_grid_bootstrapping = TRUE

	// --- existing ---
	if(isnull(GLOB.wasteland_grid_online)) GLOB.wasteland_grid_online = TRUE
	if(isnull(GLOB.wasteland_grid_state))  GLOB.wasteland_grid_state = "GREEN"
	if(isnull(GLOB.wasteland_grid_fuel))   GLOB.wasteland_grid_fuel = 100
	if(isnull(GLOB.wasteland_grid_coolant))GLOB.wasteland_grid_coolant = 100
	if(isnull(GLOB.wasteland_grid_faults)) GLOB.wasteland_grid_faults = list()
	if(isnull(GLOB.wasteland_grid_last_trip)) GLOB.wasteland_grid_last_trip = 0

	if(isnull(GLOB.wasteland_grid_core_heat))   GLOB.wasteland_grid_core_heat = 10
	if(isnull(GLOB.wasteland_grid_containment)) GLOB.wasteland_grid_containment = 100
	if(isnull(GLOB.wasteland_grid_integrity))   GLOB.wasteland_grid_integrity = 100
	if(isnull(GLOB.wasteland_grid_background_rads)) GLOB.wasteland_grid_background_rads = 0
	if(isnull(GLOB.wasteland_grid_rads_tick_counter)) GLOB.wasteland_grid_rads_tick_counter = 0
	if(isnull(GLOB.wasteland_grid_district_off_until)) GLOB.wasteland_grid_district_off_until = list()
	if(isnull(GLOB.wasteland_grid_district_forced_off)) GLOB.wasteland_grid_district_forced_off = list()
	if(isnull(GLOB.wasteland_grid_district_applied_on)) GLOB.wasteland_grid_district_applied_on = list()
	if(isnull(GLOB.wasteland_grid_relays_by_district)) GLOB.wasteland_grid_relays_by_district = list()
	if(isnull(GLOB.wasteland_grid_apc_saved_operating)) GLOB.wasteland_grid_apc_saved_operating = list()
	if(isnull(GLOB.wasteland_grid_area_saved_power)) GLOB.wasteland_grid_area_saved_power = list()

	if(isnull(GLOB.wasteland_grid_restart_stage)) GLOB.wasteland_grid_restart_stage = 0
	if(isnull(GLOB.wasteland_grid_restart_operator)) GLOB.wasteland_grid_restart_operator = null
	if(isnull(GLOB.wasteland_grid_restart_lock)) GLOB.wasteland_grid_restart_lock = FALSE
	if(isnull(GLOB.wasteland_grid_restart_cooldown_until)) GLOB.wasteland_grid_restart_cooldown_until = 0

	// --- v2 setpoints ---
	if(isnull(GLOB.grid_sp_target_output))   GLOB.grid_sp_target_output = 50
	if(isnull(GLOB.grid_sp_rod_insertion))   GLOB.grid_sp_rod_insertion = 50
	if(isnull(GLOB.grid_sp_coolant_valve))   GLOB.grid_sp_coolant_valve = 70
	if(isnull(GLOB.grid_sp_feedwater_valve)) GLOB.grid_sp_feedwater_valve = 60
	if(isnull(GLOB.grid_sp_relief_valve))    GLOB.grid_sp_relief_valve = 0
	if(isnull(GLOB.grid_sp_bypass))          GLOB.grid_sp_bypass = 10
	if(isnull(GLOB.grid_sp_turbine_governor))GLOB.grid_sp_turbine_governor = 55
	if(isnull(GLOB.grid_sp_boron_ppm))       GLOB.grid_sp_boron_ppm = 900
	if(isnull(GLOB.grid_scram))              GLOB.grid_scram = FALSE

	// --- v2 process vars ---
	if(isnull(GLOB.grid_core_reactivity))    GLOB.grid_core_reactivity = 0
	if(isnull(GLOB.grid_primary_flow))       GLOB.grid_primary_flow = 60
	if(isnull(GLOB.grid_primary_pressure))   GLOB.grid_primary_pressure = 60
	if(isnull(GLOB.grid_secondary_pressure)) GLOB.grid_secondary_pressure = 50
	if(isnull(GLOB.grid_steam_quality))      GLOB.grid_steam_quality = 70
	if(isnull(GLOB.grid_turbine_rpm))        GLOB.grid_turbine_rpm = 40
	if(isnull(GLOB.grid_output))             GLOB.grid_output = 30
	if(isnull(GLOB.grid_turbine_stress))     GLOB.grid_turbine_stress = 5
	if(isnull(GLOB.grid_turbine_moisture))   GLOB.grid_turbine_moisture = 15

	// --- v3 kinetics + chemistry ---
	if(isnull(GLOB.grid_xenon_poison))       GLOB.grid_xenon_poison = 4
	if(isnull(GLOB.grid_iodine_inventory))   GLOB.grid_iodine_inventory = 3
	if(isnull(GLOB.grid_samarium_poison))    GLOB.grid_samarium_poison = 1
	if(isnull(GLOB.grid_fuel_burnup))        GLOB.grid_fuel_burnup = 0
	if(isnull(GLOB.grid_reactivity_reserve)) GLOB.grid_reactivity_reserve = 15
	if(isnull(GLOB.grid_decay_heat))         GLOB.grid_decay_heat = 0
	if(isnull(GLOB.grid_boron_ppm))          GLOB.grid_boron_ppm = GLOB.grid_sp_boron_ppm
	if(isnull(GLOB.grid_doppler_coeff))      GLOB.grid_doppler_coeff = 0.20
	if(isnull(GLOB.grid_moderator_coeff))    GLOB.grid_moderator_coeff = 0.30
	if(isnull(GLOB.grid_subcool_margin))     GLOB.grid_subcool_margin = 60
	if(isnull(GLOB.grid_npsh_margin))        GLOB.grid_npsh_margin = 55

	// --- chemistry ---
	if(isnull(GLOB.grid_coolant_contamination)) GLOB.grid_coolant_contamination = 10
	if(isnull(GLOB.grid_filter_clog))           GLOB.grid_filter_clog = 10
	if(isnull(GLOB.grid_lube_level))            GLOB.grid_lube_level = 80
	if(isnull(GLOB.grid_pressurizer_level))     GLOB.grid_pressurizer_level = 55
	if(isnull(GLOB.grid_pressurizer_heaters))   GLOB.grid_pressurizer_heaters = 25
	if(isnull(GLOB.grid_pressurizer_spray))     GLOB.grid_pressurizer_spray = 20
	if(isnull(GLOB.grid_condenser_vacuum))      GLOB.grid_condenser_vacuum = 70
	if(isnull(GLOB.grid_hotwell_level))         GLOB.grid_hotwell_level = 55

	// --- wear ---
	if(isnull(GLOB.grid_wear_pump_primary)) GLOB.grid_wear_pump_primary = 10
	if(isnull(GLOB.grid_wear_valves))       GLOB.grid_wear_valves = 10
	if(isnull(GLOB.grid_wear_turbine))      GLOB.grid_wear_turbine = 10
	if(isnull(GLOB.grid_wear_breakers))     GLOB.grid_wear_breakers = 10
	if(isnull(GLOB.grid_wear_sensors))      GLOB.grid_wear_sensors = 10
	if(isnull(GLOB.grid_pipe_integrity))    GLOB.grid_pipe_integrity = 100

	// --- sensors ---
	if(isnull(GLOB.grid_sensor_drift_heat))  GLOB.grid_sensor_drift_heat = 0
	if(isnull(GLOB.grid_sensor_drift_press)) GLOB.grid_sensor_drift_press = 0
	if(isnull(GLOB.grid_sensor_drift_flow))  GLOB.grid_sensor_drift_flow = 0
	if(isnull(GLOB.grid_sensor_health))      GLOB.grid_sensor_health = 100

	// --- maintenance ---
	if(isnull(GLOB.grid_maint_queue))        GLOB.grid_maint_queue = list()
	if(isnull(GLOB.grid_last_maint_roll))    GLOB.grid_last_maint_roll = 0
	if(isnull(GLOB.grid_maint_interval))     GLOB.grid_maint_interval = GRID_DEFAULT_MAINT_INTERVAL

	// --- registries ---
	if(isnull(GLOB.grid_networks_by_id))     GLOB.grid_networks_by_id = list()
	if(isnull(GLOB.grid_components_by_tag))  GLOB.grid_components_by_tag = list()

	// --- procedure ---
	if(isnull(GLOB.grid_proc_purge_stage))      GLOB.grid_proc_purge_stage = 0
	if(isnull(GLOB.grid_proc_purge_operator))   GLOB.grid_proc_purge_operator = null
	if(isnull(GLOB.grid_proc_purge_lock))       GLOB.grid_proc_purge_lock = FALSE
	if(isnull(GLOB.grid_proc_purge_started_at)) GLOB.grid_proc_purge_started_at = 0

	// --- catastrophe controls ---
	if(isnull(GLOB.grid_safety_interlocks_enabled)) GLOB.grid_safety_interlocks_enabled = TRUE
	if(isnull(GLOB.grid_catastrophe_risk))          GLOB.grid_catastrophe_risk = 0
	if(isnull(GLOB.grid_catastrophe_triggered))     GLOB.grid_catastrophe_triggered = FALSE
	if(isnull(GLOB.grid_interlock_last_trip_at))    GLOB.grid_interlock_last_trip_at = 0
	if(isnull(GLOB.grid_auto_enabled))              GLOB.grid_auto_enabled = FALSE
	if(isnull(GLOB.grid_auto_player_threshold))     GLOB.grid_auto_player_threshold = 20
	if(isnull(GLOB.grid_auto_active))               GLOB.grid_auto_active = FALSE
	if(isnull(GLOB.grid_auto_last_player_count))    GLOB.grid_auto_last_player_count = 0
	if(isnull(GLOB.grid_lowpop_faults_threshold))   GLOB.grid_lowpop_faults_threshold = 20
	if(isnull(GLOB.grid_debug_controls_enabled))    GLOB.grid_debug_controls_enabled = FALSE

	// --- phase 1 ---
	if(isnull(GLOB.grid_plant_upgrade_points))      GLOB.grid_plant_upgrade_points = 0
	if(!islist(GLOB.grid_plant_upgrades))
		GLOB.grid_plant_upgrades = list(
			"stability" = 0,
			"peak_output" = 0,
			"automation" = 0,
			"safety" = 0
		)
	if(isnull(GLOB.grid_add_anticorrosion))         GLOB.grid_add_anticorrosion = 0
	if(isnull(GLOB.grid_add_antifoam))              GLOB.grid_add_antifoam = 0
	if(isnull(GLOB.grid_add_flowboost))             GLOB.grid_add_flowboost = 0
	if(isnull(GLOB.grid_stock_anticorrosion))       GLOB.grid_stock_anticorrosion = 70
	if(isnull(GLOB.grid_stock_antifoam))            GLOB.grid_stock_antifoam = 60
	if(isnull(GLOB.grid_stock_flowboost))           GLOB.grid_stock_flowboost = 55
	if(isnull(GLOB.grid_turbine_bearing_cond))      GLOB.grid_turbine_bearing_cond = 92
	if(isnull(GLOB.grid_turbine_blade_cond))        GLOB.grid_turbine_blade_cond = 92
	if(isnull(GLOB.grid_turbine_alignment_cond))    GLOB.grid_turbine_alignment_cond = 92
	if(!islist(GLOB.grid_overhaul_session))
		GLOB.grid_overhaul_session = list(
			"active" = FALSE,
			"expires" = 0,
			"steps" = list("bearing", "blade", "alignment"),
			"index" = 1
		)
	if(isnull(GLOB.grid_overhaul_bonus_until))      GLOB.grid_overhaul_bonus_until = 0

	// --- phase 2 ---
	if(isnull(GLOB.grid_auction_open_until))        GLOB.grid_auction_open_until = 0
	if(isnull(GLOB.grid_auction_round_id))          GLOB.grid_auction_round_id = 1
	if(!islist(GLOB.grid_auction_bids))             GLOB.grid_auction_bids = list()
	if(!islist(GLOB.grid_district_mw_alloc))        GLOB.grid_district_mw_alloc = list()
	if(isnull(GLOB.grid_committed_mw))              GLOB.grid_committed_mw = 0
	if(isnull(GLOB.grid_auction_revenue_pool))      GLOB.grid_auction_revenue_pool = 0
	if(!islist(GLOB.grid_dispatch_calls))           GLOB.grid_dispatch_calls = list()
	if(isnull(GLOB.grid_dispatch_next_id))          GLOB.grid_dispatch_next_id = 1
	if(isnull(GLOB.grid_dispatch_next_roll))        GLOB.grid_dispatch_next_roll = world.time + GRID_DISPATCH_INTERVAL

	// --- phase 3 ---
	if(isnull(GLOB.grid_spent_fuel_units))          GLOB.grid_spent_fuel_units = 0
	if(isnull(GLOB.grid_casks_staged))              GLOB.grid_casks_staged = 0
	if(isnull(GLOB.grid_casks_stored))              GLOB.grid_casks_stored = 0
	if(isnull(GLOB.grid_casks_processed))           GLOB.grid_casks_processed = 0
	if(isnull(GLOB.grid_waste_hazard))              GLOB.grid_waste_hazard = 0
	if(!islist(GLOB.grid_theft_by_district))        GLOB.grid_theft_by_district = list()
	if(isnull(GLOB.grid_theft_load_mw))             GLOB.grid_theft_load_mw = 0
	if(!islist(GLOB.grid_forensics_report))         GLOB.grid_forensics_report = list()
	if(isnull(GLOB.grid_forensics_last_scan))       GLOB.grid_forensics_last_scan = 0

	// IMPORTANT: do NOT call _recalc_background_rads() from bootstrap
	_recalc_wasteland_grid_state()
	_grid_ensure_default_networks()

	GLOB.wasteland_grid_bootstrapping = FALSE

///////////////////////////////////////////////////////////////
// DISTRICT BLACKOUTS (existing)
///////////////////////////////////////////////////////////////

#define GRID_RED_OUTAGE_MIN   60 SECONDS
#define GRID_RED_OUTAGE_MAX   120 SECONDS

proc/_wasteland_grid_bootstrap_districts()
	if(isnull(GLOB.wasteland_grid_district_off_until))
		GLOB.wasteland_grid_district_off_until = list()
	if(isnull(GLOB.wasteland_grid_district_forced_off))
		GLOB.wasteland_grid_district_forced_off = list()
	if(isnull(GLOB.wasteland_grid_district_applied_on))
		GLOB.wasteland_grid_district_applied_on = list()
	if(isnull(GLOB.wasteland_grid_relays_by_district))
		GLOB.wasteland_grid_relays_by_district = list()
	if(isnull(GLOB.wasteland_grid_apc_saved_operating))
		GLOB.wasteland_grid_apc_saved_operating = list()
	if(isnull(GLOB.wasteland_grid_area_saved_power))
		GLOB.wasteland_grid_area_saved_power = list()

/proc/_grid_set_district_off(district, duration)
	_wasteland_grid_bootstrap_districts()
	if(!district) return
	GLOB.wasteland_grid_district_off_until[district] = world.time + duration
	_grid_reconcile_district_power()

/proc/_grid_set_district_forced(district, forced_off = TRUE)
	_wasteland_grid_bootstrap_districts()
	if(!district) return
	if(forced_off)
		GLOB.wasteland_grid_district_forced_off[district] = TRUE
	else
		if(!isnull(GLOB.wasteland_grid_district_forced_off[district]))
			GLOB.wasteland_grid_district_forced_off[district] = null
	// Clearing forced mode should also clear stale timed blackouts by default.
	if(!forced_off && !isnull(GLOB.wasteland_grid_district_off_until[district]))
		GLOB.wasteland_grid_district_off_until[district] = world.time
	_grid_reconcile_district_power()

/proc/_grid_get_relay_for_district(district)
	_wasteland_grid_bootstrap_districts()
	if(!district)
		return null
	var/obj/structure/grid/power_relay/R = GLOB.wasteland_grid_relays_by_district[district]
	if(!R || QDELETED(R))
		GLOB.wasteland_grid_relays_by_district[district] = null
		return null
	return R

/proc/_grid_is_relay_online(district)
	var/obj/structure/grid/power_relay/R = _grid_get_relay_for_district(district)
	if(!R)
		return TRUE
	return R.is_online()

/proc/_grid_is_district_on(district)
	_wasteland_grid_bootstrap_districts()
	if(!district) return TRUE
	if(!_grid_is_relay_online(district))
		return FALSE
	if(GLOB.wasteland_grid_district_forced_off[district])
		return FALSE
	var/t = GLOB.wasteland_grid_district_off_until[district]
	if(isnull(t)) return TRUE
	return world.time >= t

/proc/_grid_has_backup_power(district)
	_wasteland_grid_bootstrap_districts()
	if(!district) return FALSE
	for(var/obj/structure/grid/backup_generator/G in GLOB.wasteland_grid_backup_generators)
		if(!G || QDELETED(G))
			continue
		if(G.get_district_id() != district)
			continue
		if(!G.is_active())
			continue
		return TRUE
	return FALSE

/proc/_grid_is_district_powered(district)
	if(!district)
		return !!GLOB.wasteland_grid_online
	if(_grid_has_backup_power(district))
		return TRUE
	return (GLOB.wasteland_grid_online && _grid_is_district_on(district))

/proc/_grid_get_area_district(area/A)
	if(!A)
		return null
	if(istext(A.grid_district) && A.grid_district)
		return A.grid_district

	var/type_path = lowertext("[A.type]")
	if(findtext(type_path, "/area/f13/brotherhood") || findtext(type_path, "/area/f13/underground/bos") || findtext(type_path, "/area/f13/bos"))
		return "BOS"
	if(findtext(type_path, "/area/f13/ncr"))
		return "NCR"
	if(findtext(type_path, "/area/f13/legion"))
		return "Legion"
	if(findtext(type_path, "/area/f13/village") || findtext(type_path, "/area/f13/hub") || findtext(type_path, "/area/f13/city") || findtext(type_path, "/area/f13/wasteland/town"))
		return "Town"
	if(findtext(type_path, "/area/f13/wasteland/massfusion") || findtext(type_path, "/area/f13/building/massfusion"))
		return "Mass Fusion"

	var/area_name = lowertext("[A.name]")
	if(findtext(area_name, "brotherhood") || findtext(area_name, "bos"))
		return "BOS"
	if(findtext(area_name, "ncr"))
		return "NCR"
	if(findtext(area_name, "legion"))
		return "Legion"
	if(findtext(area_name, "town") || findtext(area_name, "village") || findtext(area_name, "city") || findtext(area_name, "hub"))
		return "Town"
	if(findtext(area_name, "mass fusion") || findtext(area_name, "massfusion") || findtext(area_name, "fusion plant"))
		return "Mass Fusion"

	return null

/proc/_grid_apply_area_power_state(area/A, should_be_on)
	if(!A) return

	var/obj/machinery/power/apc/APC = A.get_apc()
	if(APC)
		var/apc_key = REF(APC)
		if(!should_be_on)
			if(isnull(GLOB.wasteland_grid_apc_saved_operating[apc_key]))
				GLOB.wasteland_grid_apc_saved_operating[apc_key] = APC.operating ? 1 : 0
			APC.operating = FALSE
			APC.failure_timer = max(APC.failure_timer, 20)
			APC.update()
			APC.update_icon()
		else
			if(!isnull(GLOB.wasteland_grid_apc_saved_operating[apc_key]))
				APC.operating = !!GLOB.wasteland_grid_apc_saved_operating[apc_key]
				GLOB.wasteland_grid_apc_saved_operating[apc_key] = null
			APC.failure_timer = 0
			APC.update()
			APC.update_icon()
		return

	// Fallback for areas without APCs: force area channels directly.
	var/area_key = REF(A)
	if(!should_be_on)
		if(!islist(GLOB.wasteland_grid_area_saved_power[area_key]))
			GLOB.wasteland_grid_area_saved_power[area_key] = list(
				"light" = A.power_light,
				"equip" = A.power_equip,
				"environ" = A.power_environ
			)
		var/changed = (A.power_light || A.power_equip || A.power_environ)
		A.power_light = FALSE
		A.power_equip = FALSE
		A.power_environ = FALSE
		if(changed)
			A.power_change()
	else
		var/list/saved = GLOB.wasteland_grid_area_saved_power[area_key]
		if(!islist(saved))
			return
		var/new_light = !!saved["light"]
		var/new_equip = !!saved["equip"]
		var/new_environ = !!saved["environ"]
		var/changed_back = (A.power_light != new_light || A.power_equip != new_equip || A.power_environ != new_environ)
		A.power_light = new_light
		A.power_equip = new_equip
		A.power_environ = new_environ
		GLOB.wasteland_grid_area_saved_power[area_key] = null
		if(changed_back)
			A.power_change()

/proc/_grid_apply_district_power_state(district, should_be_on)
	if(!district) return
	for(var/area/A in world)
		if(!A || _grid_get_area_district(A) != district)
			continue
		_grid_apply_area_power_state(A, should_be_on)

/proc/_grid_reconcile_district_power()
	_wasteland_grid_bootstrap_districts()

	// Clean out expired timed outages to keep list compact.
	var/list/expired = list()
	for(var/d in GLOB.wasteland_grid_district_off_until)
		var/t = GLOB.wasteland_grid_district_off_until[d]
		if(isnull(t) || world.time >= t)
			expired += d
	for(var/dx in expired)
		GLOB.wasteland_grid_district_off_until[dx] = null

	var/list/discovered = list()
	for(var/area/A in world)
		if(!A) continue
		var/d = _grid_get_area_district(A)
		if(istext(d) && d)
			discovered[d] = TRUE

	for(var/district in discovered)
		var/should_be_on = _grid_is_district_powered(district)
		var/prev = GLOB.wasteland_grid_district_applied_on[district]
		if(isnull(prev) || (!!prev != !!should_be_on))
			GLOB.wasteland_grid_district_applied_on[district] = !!should_be_on
			_grid_apply_district_power_state(district, should_be_on)

/proc/_grid_pick_random_district()
	var/list/districts = list()
	for(var/area/A in world)
		if(!A) continue
		var/d = _grid_get_area_district(A)
		if(istext(d) && d && !(d in districts))
			districts += d
	if(!districts.len) return null
	return pick(districts)

///////////////////////////////////////////////////////////////
// POWER AVAILABILITY CHECK (existing)
///////////////////////////////////////////////////////////////

/proc/grid_power_available_for(atom/A)
	_wasteland_grid_bootstrap_districts()

	if(isnull(GLOB.wasteland_grid_online))
		return TRUE
	if(!GLOB.wasteland_grid_online)
		return FALSE

	var/area/Ar = get_area(A)
	var/d = _grid_get_area_district(Ar)
	if(d)
		if(!_grid_is_district_powered(d))
			return FALSE

	return TRUE

/proc/_grid_tick_backup_generators()
	var/dirty = FALSE
	for(var/obj/structure/grid/backup_generator/G in GLOB.wasteland_grid_backup_generators)
		if(!G || QDELETED(G))
			continue
		if(G.tick_fuel())
			dirty = TRUE
	if(dirty)
		_grid_reconcile_district_power()

///////////////////////////////////////////////////////////////
// NETWORKS + COMPONENT REGISTRY
///////////////////////////////////////////////////////////////

/datum/grid_network
	var/id
	var/fluid = "coolant" // "coolant"|"steam"|"feedwater"
	var/pressure = 0      // 0..200
	var/flow = 0          // 0..100
	var/leak_rate = 0     // 0..5
	var/restriction = 0   // 0..100 (higher = worse)
	var/integrity = 100   // 0..100

	var/list/nodes = list() // objs attached (optional)

/datum/grid_network/proc/effective_restriction()
	return clamp(restriction + (100 - integrity), 0, 100)

/proc/grid_register_network(datum/grid_network/N)
	_wasteland_grid_bootstrap()
	if(!N || !N.id) return
	GLOB.grid_networks_by_id[N.id] = N

/proc/grid_get_network(id)
	_wasteland_grid_bootstrap()
	if(!id) return null
	return GLOB.grid_networks_by_id[id]

/proc/grid_register_component(obj/O)
	_wasteland_grid_bootstrap()
	if(!O) return
	if(!istext(O:component_tag) || !O:component_tag) return
	GLOB.grid_components_by_tag[O:component_tag] = O

/proc/grid_get_component(tag)
	_wasteland_grid_bootstrap()
	if(!tag) return null
	return GLOB.grid_components_by_tag[tag]

/proc/_grid_ensure_default_networks()
	// Creates 3 baseline networks if missing
	if(!grid_get_network("primary"))
		var/datum/grid_network/P = new
		P.id = "primary"
		P.fluid = "coolant"
		P.pressure = GLOB.grid_primary_pressure
		P.flow = GLOB.grid_primary_flow
		P.integrity = GLOB.grid_pipe_integrity
		grid_register_network(P)

	if(!grid_get_network("secondary"))
		var/datum/grid_network/S = new
		S.id = "secondary"
		S.fluid = "steam"
		S.pressure = GLOB.grid_secondary_pressure
		S.flow = 50
		S.integrity = 100
		grid_register_network(S)

	if(!grid_get_network("feedwater"))
		var/datum/grid_network/FW = new
		FW.id = "feedwater"
		FW.fluid = "feedwater"
		FW.pressure = 40
		FW.flow = 50
		FW.integrity = 100
		grid_register_network(FW)

///////////////////////////////////////////////////////////////
// MAINTENANCE TASKS
///////////////////////////////////////////////////////////////
#define GRID_REPAIR_RANGE 1
/proc/_grid_get_nearby_items(atom/center)
	var/list/items = list()

	// Include turf items
	for(var/turf/T in range(GRID_REPAIR_RANGE, center))
		for(var/obj/item/I in T)
			items += I

	return items
/proc/_grid_collect_available_parts(mob/user, atom/center)
	var/list/have = list()

	// 1) Mob inventory
	for(var/obj/item/I in user.contents)
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			have[I.type] += S.amount
		else
			have[I.type] += 1

	// 2) Nearby items
	for(var/obj/item/I in _grid_get_nearby_items(center))
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			have[I.type] += S.amount
		else
			have[I.type] += 1

	return have

/datum/grid_task
	var/id
	var/name
	var/desc
	var/severity = 1        // 1..3
	var/expires_at = 0      // world.time
	var/target_tag = null   // component_tag OR null
	var/target_type = null  // typepath OR null
	var/required_tool = null
	var/list/required_reqs = null // list(typepath=amount)
	var/list/steps = null          // list("step text")
	var/completed = FALSE
	var/created_at = 0

/datum/grid_task/proc/describe()
	var/t = "[name] (S[severity])"
	if(completed) t += " [span_notice("(done)")]"
	if(desc) t += " — [desc]"
	return t

/proc/grid_task_add(id, name, desc, severity, expires_in, target_tag, target_type, required_tool, list/reqs, list/steps)
	_wasteland_grid_bootstrap()
	if(!GLOB.grid_maint_queue) GLOB.grid_maint_queue = list()

	// de-dupe by id if active
	for(var/datum/grid_task/T in GLOB.grid_maint_queue)
		if(T && !T.completed && T.id == id)
			return T

	var/datum/grid_task/N = new
	N.id = id
	N.name = name
	N.desc = desc
	N.severity = clamp(severity, 1, 3)
	N.created_at = world.time
	N.expires_at = world.time + max(30 SECONDS, expires_in)
	N.target_tag = target_tag
	N.target_type = target_type
	N.required_tool = required_tool
	N.required_reqs = reqs
	N.steps = steps
	GLOB.grid_maint_queue += N
	return N

/proc/grid_task_complete_by(mob/user, datum/grid_task/T)
	if(!T || T.completed) return FALSE
	T.completed = TRUE
	to_chat(user, span_notice("Maintenance completed: [T.name]."))
	return TRUE

/proc/grid_task_find_for_obj(obj/O)
	_wasteland_grid_bootstrap()
	if(!O) return null

	var/tag = null
	if(istext(O:component_tag)) tag = O:component_tag

	for(var/datum/grid_task/T in GLOB.grid_maint_queue)
		if(!T || T.completed) continue
		if(T.target_tag && tag && T.target_tag == tag)
			return T
		if(T.target_type && istype(O, T.target_type))
			return T
	return null

///////////////////////////////////////////////////////////////
// FAULT DATUM (existing, expanded with cause + targeting)
///////////////////////////////////////////////////////////////

/datum/wasteland_grid_fault
	var/id
	var/name
	var/severity = 1 // 1-3
	var/location_hint = "Mass Fusion"

	// v2 metadata
	var/cause = "random"             // "overpressure"|"overheat"|"wear"|"operator_error"|"sabotage"|"random"
	var/affects_network_id = null    // "primary"/"secondary"/"feedwater"
	var/affects_component_tag = null // e.g. "primary_pump_1"

	var/required_tool = null

	var/required_part = null
	var/required_part_amount = 1

	var/list/required_reqs = null

	var/repair_key = "breaker" // "breaker" | "coolant" | "control" | "turbine"

	var/fixed = FALSE
	var/created_at = 0
	var/last_escalation = 0
	var/escalate_every = 5 MINUTES

/datum/wasteland_grid_fault/proc/get_required_tool_text()
	if(!required_tool) return "hands"
	var/t = "[required_tool]"
	var/atom/A = required_tool
	if(A) t = initial(A.name)
	return t

/datum/wasteland_grid_fault/proc/get_effective_reqs()
	if(required_reqs && islist(required_reqs) && required_reqs.len)
		return required_reqs
	if(required_part)
		return list(required_part = required_part_amount)
	return null

/datum/wasteland_grid_fault/proc/get_effective_reqs_text()
	var/list/reqs = get_effective_reqs()
	if(!reqs || !islist(reqs) || !reqs.len) return "no parts"

	var/t = ""
	for(var/path in reqs)
		var/amt = reqs[path]
		if(!amt) continue
		var/nm = "[path]"
		var/atom/A = path
		if(A) nm = initial(A.name)
		t += "[amt]x [nm], "
	if(length(t) >= 2)
		t = copytext(t, 1, length(t) - 1)
	return t

/datum/wasteland_grid_fault/proc/describe()
	var/t = "[name] (S[severity]) @ [location_hint]"
	if(fixed) t += " [span_notice("(fixed)")]"
	if(cause) t += " Cause: [cause]"
	var/need = ""
	if(required_tool) need += " Tool: [get_required_tool_text()]"
	var/list/reqs = get_effective_reqs()
	if(reqs && reqs.len) need += " Parts: [get_effective_reqs_text()]"
	if(need) t += ".[need]"
	return t

///////////////////////////////////////////////////////////////
// BACKGROUND RADIATION (existing)
///////////////////////////////////////////////////////////////

#define GRID_RADS_TICK_DIV   3
#define GRID_RADS_BASE_UNIT  0.2

proc/_recalc_background_rads()
	if(isnull(GLOB.wasteland_grid_faults))
		return

	var/r = 0
	switch(GLOB.wasteland_grid_state)
		if("GREEN") r += 0
		if("YELLOW") r += 1
		if("RED") r += 3
		if("OFF") r += 0

	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed)
			r += F.severity

	if(GLOB.wasteland_grid_containment < 80) r += 2
	if(GLOB.wasteland_grid_containment < 60) r += 4
	if(GLOB.wasteland_grid_containment < 40) r += 8
	if(GLOB.wasteland_grid_containment < 20) r += 15
	if(GLOB.grid_catastrophe_triggered) r += 60

	// v2: output instability adds background load stress (minor)
	if(GLOB.grid_output < 10 && GLOB.wasteland_grid_online) r += 1
	if(GLOB.grid_output > 85 && GLOB.grid_primary_pressure > 140) r += 1

	GLOB.wasteland_grid_background_rads = max(0, r)

/proc/_apply_background_radiation()
	_wasteland_grid_bootstrap()

	if(!SSticker || !SSticker.HasRoundStarted())
		return

	GLOB.wasteland_grid_rads_tick_counter++
	if(GLOB.wasteland_grid_rads_tick_counter < GRID_RADS_TICK_DIV)
		return
	GLOB.wasteland_grid_rads_tick_counter = 0

	var/bg = GLOB.wasteland_grid_background_rads
	if(bg <= 0) return

	for(var/mob/living/carbon/human/H in world)
		if(!H || H.stat == DEAD) continue

		var/area/A = get_area(H)
		var/mult = 1.0
		if(A) mult = A.grid_rads_mult

		var/dose = GRID_RADS_BASE_UNIT * bg * mult
		var/irr = max(1, round(dose))
		H.apply_effect(irr, EFFECT_IRRADIATE, 0)

/proc/_apply_catastrophe_core_radiation()
	_wasteland_grid_bootstrap()
	if(!GLOB.grid_catastrophe_triggered)
		return
	if(!SSticker || !SSticker.HasRoundStarted())
		return

	var/atom/anchor = _grid_get_radiation_anchor()
	if(!anchor || !anchor.loc)
		return

	for(var/mob/living/carbon/human/H in range(GRID_CATASTROPHE_CORE_RADIUS, anchor))
		if(!H || H.stat == DEAD)
			continue
		var/d = get_dist(anchor, H)
		var/falloff = max(0.25, 1 - (d / max(1, GRID_CATASTROPHE_CORE_RADIUS)))
		var/irr = max(10, round(GRID_CATASTROPHE_CORE_DOSE * falloff))
		H.apply_effect(irr, EFFECT_IRRADIATE, 0)

#define GRID_WAVE_TICK_DIV  3  // every 3 subsystem fires (your subsystem waits 10s -> every 30s). change if needed.
#define GRID_WAVE_INTENSITY_CAP 120
#define GRID_WAVE_DIAG_PROB 25

/proc/_grid_get_radiation_anchor()
	_wasteland_grid_bootstrap()

	var/atom/existing = GLOB.grid_rad_source
	if(existing && existing.loc)
		return existing

	for(var/obj/structure/f13/grid_radiation_source/R in world)
		if(R && R.loc)
			GLOB.grid_rad_source = R
			return R

	for(var/obj/machinery/f13/wasteland_grid_console/C in world)
		if(C && C.loc)
			return C

	return null

/proc/_emit_background_radiation_waves()
	_wasteland_grid_bootstrap()

	if(!SSticker || !SSticker.HasRoundStarted())
		return

	// throttle
	if(isnull(GLOB.wasteland_grid_wave_tick_counter)) GLOB.wasteland_grid_wave_tick_counter = 0
	GLOB.wasteland_grid_wave_tick_counter++
	if(GLOB.wasteland_grid_wave_tick_counter < GRID_WAVE_TICK_DIV)
		return
	GLOB.wasteland_grid_wave_tick_counter = 0

	var/bg = GLOB.wasteland_grid_background_rads
	if(bg <= 0) return

	// no anchor = nothing to emit from
	var/atom/RS = _grid_get_radiation_anchor()
	if(!RS || !RS.loc)
		return


	// Must stay above RAD_BACKGROUND_RADIATION or waves self-delete instantly.
	var/intensity = clamp(round((bg * 4) + 8), RAD_BACKGROUND_RADIATION + 1, GRID_WAVE_INTENSITY_CAP)
	if(GLOB.grid_catastrophe_triggered)
		intensity = max(intensity, 65)

	// Emit cardinal waves always
	new /datum/radiation_wave(RS, NORTH, intensity, RAD_DISTANCE_COEFFICIENT, TRUE)
	new /datum/radiation_wave(RS, SOUTH, intensity, RAD_DISTANCE_COEFFICIENT, TRUE)
	new /datum/radiation_wave(RS, EAST,  intensity, RAD_DISTANCE_COEFFICIENT, TRUE)
	new /datum/radiation_wave(RS, WEST,  intensity, RAD_DISTANCE_COEFFICIENT, TRUE)

	// Diagonals sometimes (CPU + vibe)
	if(prob(GRID_WAVE_DIAG_PROB))
		var/diag = max(1, round(intensity * 0.75))
		new /datum/radiation_wave(RS, NORTHEAST, diag, RAD_DISTANCE_COEFFICIENT, TRUE)
		new /datum/radiation_wave(RS, NORTHWEST, diag, RAD_DISTANCE_COEFFICIENT, TRUE)
		new /datum/radiation_wave(RS, SOUTHEAST, diag, RAD_DISTANCE_COEFFICIENT, TRUE)
		new /datum/radiation_wave(RS, SOUTHWEST, diag, RAD_DISTANCE_COEFFICIENT, TRUE)

///////////////////////////////////////////////////////////////
// ONE TRUE SETTER (existing)
///////////////////////////////////////////////////////////////

/proc/set_wasteland_grid_online(state)
	_wasteland_grid_bootstrap()

	var/new_state = !!state
	var/changed = (new_state != !!GLOB.wasteland_grid_online)
	GLOB.wasteland_grid_online = new_state
	_recalc_wasteland_grid_state()
	_recalc_background_rads()
	_sync_wasteland_grid_reactor()
	_grid_reconcile_district_power()
	if(!changed)
		return

	// Lights: instant reaction
	for(var/obj/machinery/light/L in GLOB.machines)
		L.on_wasteland_grid_change()

	// Grid-gated machines
	for(var/obj/machinery/f13_grid_gated/M in GLOB.machines)
		M.power_change()

/proc/_sync_wasteland_grid_reactor()
	var/obj/structure/f13/grid_radiation_source/R = GLOB.grid_rad_source
	if(istype(R) && R.loc)
		R.sync_visual_and_audio()
	_sync_wasteland_grid_component_visuals()

/proc/_grid_icon_state_exists(icon/icon_file, state_name)
	if(!icon_file || !istext(state_name) || !length(state_name))
		return FALSE
	var/key = "[icon_file]|[state_name]"
	var/cached = GLOB.grid_icon_state_cache[key]
	if(!isnull(cached))
		return !!cached
	var/list/states = icon_states(icon_file)
	var/found = (islist(states) && (state_name in states))
	GLOB.grid_icon_state_cache[key] = found
	return found

/proc/_grid_try_set_icon_state(atom/A, list/candidates)
	if(!A || !islist(candidates) || !length(candidates))
		return FALSE
	for(var/state_name in candidates)
		if(!istext(state_name) || !length(state_name))
			continue
		if(_grid_icon_state_exists(A.icon, state_name))
			A.icon_state = state_name
			return TRUE
	return FALSE

/proc/_sync_wasteland_grid_component_visuals()
	for(var/obj/machinery/grid/turbine_controller/T in GLOB.machines)
		T.sync_visual_state()

	for(var/obj/machinery/grid/pump/P in GLOB.machines)
		P.sync_visual_state()

	for(var/obj/structure/grid/turbine_assembly/TA in GLOB.wasteland_grid_turbine_assemblies)
		if(!TA || QDELETED(TA) || !TA.loc)
			GLOB.wasteland_grid_turbine_assemblies -= TA
			continue
		TA.sync_visual_state()

	for(var/obj/structure/grid/filter_unit/FU in GLOB.wasteland_grid_filter_units)
		if(!FU || QDELETED(FU) || !FU.loc)
			GLOB.wasteland_grid_filter_units -= FU
			continue
		FU.sync_visual_state()

	for(var/obj/structure/grid/heat_exchanger/HX in GLOB.wasteland_grid_heat_exchangers)
		if(!HX || QDELETED(HX) || !HX.loc)
			GLOB.wasteland_grid_heat_exchangers -= HX
			continue
		HX.sync_visual_state()

	for(var/obj/structure/grid/relief_valve/RV in GLOB.wasteland_grid_relief_valves)
		if(!RV || QDELETED(RV) || !RV.loc)
			GLOB.wasteland_grid_relief_valves -= RV
			continue
		RV.sync_visual_state()

	for(var/obj/structure/grid/breaker_cabinet/B in GLOB.wasteland_grid_breaker_cabinets)
		if(!B || QDELETED(B) || !B.loc)
			GLOB.wasteland_grid_breaker_cabinets -= B
			continue
		B._sync_icon_state()

	for(var/obj/structure/wasteland_grid/breaker_panel/BP in GLOB.wasteland_grid_breaker_panels)
		if(!BP || QDELETED(BP) || !BP.loc)
			GLOB.wasteland_grid_breaker_panels -= BP
			continue
		BP._sync_icon_state()

///////////////////////////////////////////////////////////////
// GRID STATE + FAULT HELPERS (existing)
///////////////////////////////////////////////////////////////

/proc/_unfixed_fault_count()
	var/n = 0
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed) n++
	return n

/proc/_max_fault_severity()
	var/m = 0
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed)
			m = max(m, F.severity)
	return m

/proc/_has_unfixed_faults()
	return _unfixed_fault_count() > 0

/proc/_recalc_wasteland_grid_state()
	if(!GLOB.wasteland_grid_online)
		GLOB.wasteland_grid_state = "OFF"
		return

	var/state = "GREEN"
	if(GLOB.wasteland_grid_fuel <= 20 || GLOB.wasteland_grid_coolant <= 20)
		state = "YELLOW"
	if(GLOB.wasteland_grid_fuel <= 10 || GLOB.wasteland_grid_coolant <= 10)
		state = "RED"

	var/maxsev = _max_fault_severity()
	if(maxsev >= 2 && state == "GREEN") state = "YELLOW"
	if(maxsev >= 3) state = "RED"

	// v2: severe process conditions force RED even if resources ok
	if(GLOB.grid_primary_pressure >= 170 || GLOB.wasteland_grid_core_heat >= 90)
		state = "RED"
	if(GLOB.grid_subcool_margin <= 8 || (GLOB.grid_decay_heat > 15 && GLOB.grid_primary_flow < 25))
		state = "RED"
	if(GLOB.grid_pressurizer_level >= 98)
		state = "RED"
	if(GLOB.grid_xenon_poison >= 24 && state == "GREEN")
		state = "YELLOW"

	GLOB.wasteland_grid_state = state

/proc/_announce_grid(msg)
	world << "<span class='boldannounce'>[msg]</span>"

///////////////////////////////////////////////////////////////
// FAULT FACTORY (expanded with new fault ids + causal tagging)
///////////////////////////////////////////////////////////////

/proc/_make_fault(id)
	var/datum/wasteland_grid_fault/F = new
	F.id = id
	F.created_at = world.time
	F.last_escalation = world.time

	F.required_tool = null
	F.required_part = null
	F.required_part_amount = 1
	F.required_reqs = null
	F.cause = "random"
	F.affects_network_id = null
	F.affects_component_tag = null

	switch(id)
		// --- existing ---
		if("coolant_leak")
			F.name = "Coolant Leak"
			F.severity = 2
			F.repair_key = "coolant"
			F.location_hint = "Pump Station"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/stack/sheet/metal = 50, /obj/item/crafting/duct_tape = 3, /obj/item/crafting/wonderglue = 2)
			F.cause = "overpressure"
			F.affects_network_id = "primary"

		if("breaker_trip")
			F.name = "Breaker Trip"
			F.severity = 1
			F.repair_key = "breaker"
			F.location_hint = "Breaker Room"
			F.required_tool = /obj/item/screwdriver
			F.required_reqs = list(/obj/item/crafting/fuse = 2, /obj/item/crafting/switch_crafting = 1)
			F.cause = "wear"

		if("control_bus_short")
			F.name = "Control Bus Short"
			F.severity = 2
			F.repair_key = "control"
			F.location_hint = "Control Bus Rack"
			F.required_tool = /obj/item/wirecutters
			F.required_reqs = list(/obj/item/stack/cable_coil = 30, /obj/item/crafting/board = 2, /obj/item/crafting/transistor = 4, /obj/item/crafting/diode = 4)
			F.cause = "overheat"

		if("fuel_feed_jam")
			F.name = "Fuel Feed Jam"
			F.severity = 1
			F.repair_key = "breaker"
			F.location_hint = "Feed Mechanism"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/stack/sheet/metal = 25, /obj/item/crafting/small_gear = 2, /obj/item/crafting/duct_tape = 1)
			F.cause = "wear"

		// --- v2 new: causal plant faults ---
		if("pipe_rupture_primary")
			F.name = "Primary Loop Pipe Rupture"
			F.severity = 3
			F.repair_key = "coolant"
			F.location_hint = "Primary Pipe Gallery"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/stack/sheet/metal = 80, /obj/item/stack/cable_coil = 20, /obj/item/crafting/duct_tape = 5)
			F.cause = "overpressure"
			F.affects_network_id = "primary"

		if("relief_valve_stuck")
			F.name = "Relief Valve Stuck"
			F.severity = 2
			F.repair_key = "control"
			F.location_hint = "Relief Valve Manifold"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/crafting/small_gear = 1, /obj/item/crafting/wonderglue = 1)
			F.cause = "wear"
			F.affects_component_tag = "relief_1"

		if("pump_cavitation")
			F.name = "Primary Pump Cavitation"
			F.severity = 2
			F.repair_key = "coolant"
			F.location_hint = "Primary Pump House"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/crafting/duct_tape = 2, /obj/item/crafting/small_gear = 2)
			F.cause = "operator_error"
			F.affects_component_tag = "primary_pump_1"

		if("pump_bearing_seizure")
			F.name = "Primary Pump Bearing Seizure"
			F.severity = 3
			F.repair_key = "coolant"
			F.location_hint = "Primary Pump House"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/stack/sheet/metal = 30, /obj/item/crafting/small_gear = 4, /obj/item/crafting/wonderglue = 2)
			F.cause = "wear"
			F.affects_component_tag = "primary_pump_1"

		if("filter_blockage")
			F.name = "Coolant Filter Blockage"
			F.severity = 1
			F.repair_key = "coolant"
			F.location_hint = "Filter Skid"
			F.required_tool = /obj/item/screwdriver
			F.required_reqs = list(/obj/item/crafting/board = 1, /obj/item/crafting/duct_tape = 1)
			F.cause = "wear"
			F.affects_component_tag = "filter_1"

		if("turbine_overspeed_trip")
			F.name = "Turbine Overspeed Trip"
			F.severity = 2
			F.repair_key = "turbine"
			F.location_hint = "Turbine Controller"
			F.required_tool = /obj/item/screwdriver
			F.required_reqs = list(/obj/item/crafting/fuse = 2, /obj/item/crafting/transistor = 2)
			F.cause = "operator_error"
			F.affects_component_tag = "turbine_ctrl_1"

		if("turbine_vibration")
			F.name = "Turbine Vibration"
			F.severity = 2
			F.repair_key = "turbine"
			F.location_hint = "Turbine Hall"
			F.required_tool = /obj/item/wrench
			F.required_reqs = list(/obj/item/crafting/small_gear = 2, /obj/item/crafting/wonderglue = 1)
			F.cause = "wear"
			F.affects_component_tag = "turbine_1"

		if("sensor_drift")
			F.name = "Instrumentation Drift"
			F.severity = 1
			F.repair_key = "control"
			F.location_hint = "Instrumentation Bay"
			F.required_tool = /obj/item/screwdriver
			F.required_reqs = list(/obj/item/crafting/board = 1, /obj/item/crafting/diode = 2, /obj/item/crafting/transistor = 2)
			F.cause = "wear"
			F.affects_component_tag = "sensor_panel_1"

		else
			F.name = "Unknown Fault"
			F.severity = 1
			F.repair_key = "breaker"
			F.location_hint = "Mass Fusion"
			F.required_tool = /obj/item/wrench
			F.required_reqs = null
			F.cause = "random"

	return F

/proc/add_grid_fault(id, severity_override = 0)
	_wasteland_grid_bootstrap()

	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && F.id == id && !F.fixed)
			if(severity_override > 0) F.severity = max(F.severity, severity_override)
			else F.severity = min(3, F.severity + 1)
			_announce_grid("WASTELAND GRID: Fault worsened: [F.name] (S[F.severity]).")
			_recalc_wasteland_grid_state()
			_recalc_background_rads()
			return F

	var/datum/wasteland_grid_fault/N = _make_fault(id)
	if(severity_override > 0)
		N.severity = clamp(severity_override, 1, 3)

	GLOB.wasteland_grid_faults += N
	_announce_grid("WASTELAND GRID: Fault detected: [N.describe()]")
	_recalc_wasteland_grid_state()
	_recalc_background_rads()
	return N

/proc/fix_grid_fault(datum/wasteland_grid_fault/F)
	if(!F || F.fixed) return FALSE
	F.fixed = TRUE
	_announce_grid("WASTELAND GRID: Fault resolved: [F.name].")
	_recalc_wasteland_grid_state()
	_recalc_background_rads()

	// v2: resolving certain faults restores conditions a bit
	if(F.id == "pipe_rupture_primary")
		GLOB.grid_primary_pressure = max(0, GLOB.grid_primary_pressure - 20)
		GLOB.grid_primary_flow = max(0, GLOB.grid_primary_flow - 10)

	return TRUE

/proc/_escalate_faults_if_neglected()
	if(_grid_lowpop_suppression_active())
		return
	var/changed = FALSE
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(!F || F.fixed) continue

		if(world.time - F.last_escalation >= F.escalate_every)
			F.last_escalation = world.time
			F.severity = min(3, F.severity + 1)
			changed = TRUE
			_announce_grid("WASTELAND GRID: Neglect escalated fault: [F.name] (S[F.severity]).")

		if(F.severity >= 3 && GLOB.wasteland_grid_online)
			_trip_grid("Critical fault: [F.name]")
			return

	if(changed)
		_recalc_wasteland_grid_state()
		_recalc_background_rads()

///////////////////////////////////////////////////////////////
// V2 SIMULATION PHASES (ordered)
///////////////////////////////////////////////////////////////

#define GRID_K_REACTIVITY  0.010
#define GRID_K_COOLING     0.050
#define GRID_K_PRESS_HEAT  0.35
#define GRID_K_PRESS_FLOW  0.20
#define GRID_K_RPM         0.25
#define GRID_K_OUT         0.010
#define GRID_K_BORON_TRACK 0.06

/proc/_grid_coolant_efficiency()
	var/eff = 1.0
	eff -= (GLOB.grid_coolant_contamination / 200)
	eff -= (GLOB.grid_filter_clog / 200)
	return clamp(eff, 0.2, 1.0)

/proc/_grid_fault_penalty_multiplier()
	// more unfixed faults => worse efficiency and higher stress
	var/unfixed = _unfixed_fault_count()
	var/maxsev = _max_fault_severity()
	return 1.0 + (0.05 * unfixed) + (0.10 * maxsev)

/proc/_apply_operator_controls()
	// SCRAM overrides everything
	if(GLOB.grid_scram)
		GLOB.grid_sp_rod_insertion = 100
		GLOB.grid_sp_bypass = max(GLOB.grid_sp_bypass, 70)
		GLOB.grid_sp_relief_valve = max(GLOB.grid_sp_relief_valve, 50)

	// Clamp setpoints
	GLOB.grid_sp_target_output = clamp(GLOB.grid_sp_target_output, 0, 100)
	GLOB.grid_sp_rod_insertion = clamp(GLOB.grid_sp_rod_insertion, 0, 100)
	GLOB.grid_sp_coolant_valve = clamp(GLOB.grid_sp_coolant_valve, 0, 100)
	GLOB.grid_sp_feedwater_valve = clamp(GLOB.grid_sp_feedwater_valve, 0, 100)
	GLOB.grid_sp_relief_valve = clamp(GLOB.grid_sp_relief_valve, 0, 100)
	GLOB.grid_sp_bypass = clamp(GLOB.grid_sp_bypass, 0, 100)
	GLOB.grid_sp_turbine_governor = clamp(GLOB.grid_sp_turbine_governor, 0, 100)
	GLOB.grid_sp_boron_ppm = clamp(GLOB.grid_sp_boron_ppm, 0, 2000)

	// Chemistry system slowly tracks to operator boron target.
	var/boron_err = GLOB.grid_sp_boron_ppm - GLOB.grid_boron_ppm
	GLOB.grid_boron_ppm += (boron_err * GRID_K_BORON_TRACK)
	GLOB.grid_boron_ppm = clamp(round(GLOB.grid_boron_ppm), 0, 2000)

/proc/_simulate_reactor_kinetics()
	// Core poison + burnup + decay heat model (abstracted but causal).
	var/online_reaction = (GLOB.wasteland_grid_online && !GLOB.grid_scram)

	// Fuel burnup accumulates when operating at power.
	if(online_reaction)
		GLOB.grid_fuel_burnup += 0.02 + (GLOB.grid_output / 500) + (GLOB.grid_core_reactivity / 900)
	GLOB.grid_fuel_burnup = clamp(GLOB.grid_fuel_burnup, 0, 100)

	// Samarium is effectively permanent poison that rises with burnup.
	if(online_reaction)
		GLOB.grid_samarium_poison += 0.003 + (GLOB.grid_fuel_burnup / 12000)
	GLOB.grid_samarium_poison = clamp(GLOB.grid_samarium_poison, 0, 20)

	// Iodine inventory follows operation, then decays into xenon.
	if(online_reaction)
		GLOB.grid_iodine_inventory += 0.10 + (GLOB.grid_output / 1200)
	else
		GLOB.grid_iodine_inventory = max(0, GLOB.grid_iodine_inventory - 0.03)
	GLOB.grid_iodine_inventory = clamp(GLOB.grid_iodine_inventory, 0, 40)

	// Xenon peaks after shutdown and burns out when power is restored.
	GLOB.grid_xenon_poison += (GLOB.grid_iodine_inventory * 0.018)
	if(online_reaction)
		GLOB.grid_xenon_poison -= 0.08 + (GLOB.grid_core_reactivity / 700)
	else
		GLOB.grid_xenon_poison -= 0.012
	GLOB.grid_xenon_poison = clamp(GLOB.grid_xenon_poison, 0, 40)

	// Reactivity reserve drops with burnup (depleted core struggles to stay critical).
	GLOB.grid_reactivity_reserve = clamp(25 - (GLOB.grid_fuel_burnup * 0.50), -30, 30)

	// Decay heat persists after shutdown/scram and must be removed.
	if(online_reaction)
		GLOB.grid_decay_heat += 0.25 + (GLOB.grid_output / 350)
	else
		GLOB.grid_decay_heat -= 0.06 + (GLOB.grid_primary_flow / 2500)
	GLOB.grid_decay_heat = clamp(GLOB.grid_decay_heat, 0, 50)

	// Doppler + moderator coefficients drift with temperature/chemistry conditions.
	GLOB.grid_doppler_coeff = clamp(0.12 + (GLOB.wasteland_grid_core_heat / 400), 0.10, 0.45)
	GLOB.grid_moderator_coeff = 0.22 + (GLOB.grid_boron_ppm / 3500) + (GLOB.grid_xenon_poison / 260)
	// Slightly positive MTC edge case at low boron + high xenon.
	if(GLOB.grid_boron_ppm < 250 && GLOB.grid_xenon_poison > 20)
		GLOB.grid_moderator_coeff -= 0.35
	GLOB.grid_moderator_coeff = clamp(GLOB.grid_moderator_coeff, -0.30, 1.00)

/proc/_simulate_thermal()
	// Reactivity model includes poisons, burnup reserve, boron, and temperature coefficients.
	var/fuel_factor = (GLOB.wasteland_grid_fuel > 0) ? 1.0 : 0.0
	var/online_reaction = (GLOB.wasteland_grid_online && !GLOB.grid_scram)
	var/base_reactivity = (100 - GLOB.grid_sp_rod_insertion) * fuel_factor
	base_reactivity += GLOB.grid_reactivity_reserve
	base_reactivity -= (GLOB.grid_xenon_poison * 1.7)
	base_reactivity -= (GLOB.grid_samarium_poison * 1.2)
	base_reactivity -= (GLOB.grid_boron_ppm / 40)

	// Doppler is strong negative feedback; moderator coeff can go slightly positive in edge cases.
	var/temp_delta = GLOB.wasteland_grid_core_heat - 45
	var/doppler_feedback = temp_delta * GLOB.grid_doppler_coeff
	var/mod_feedback = (temp_delta / 2) * GLOB.grid_moderator_coeff
	var/react = base_reactivity - doppler_feedback - mod_feedback
	if(!online_reaction)
		react *= 0.10
	react = clamp(react, 0, 100)
	GLOB.grid_core_reactivity = react

	// Heat changes
	var/heat = GLOB.wasteland_grid_core_heat
	var/eff = _grid_coolant_efficiency()
	var/pen = _grid_fault_penalty_multiplier()

	heat += (GRID_K_REACTIVITY * react * 100) * pen
	heat += (GLOB.grid_decay_heat * 0.35)
	heat -= (GRID_K_COOLING * GLOB.grid_primary_flow * eff * 100)

	// low coolant resource makes heat worse
	if(GLOB.wasteland_grid_coolant <= 0) heat += 2.0
	if(GLOB.wasteland_grid_fuel <= 0) heat -= 1.0

	// clamp
	GLOB.wasteland_grid_core_heat = clamp(round(heat), 0, 100)

/proc/_simulate_hydraulics()
	var/datum/grid_network/prim = grid_get_network("primary")
	var/datum/grid_network/sec  = grid_get_network("secondary")
	var/datum/grid_network/fw   = grid_get_network("feedwater")

	// Base pump power degraded by wear and lube
	var/pump_health = 1.0 - (GLOB.grid_wear_pump_primary / 150)
	var/lube_eff = clamp(GLOB.grid_lube_level / 100, 0.2, 1.0)
	var/pump_power = 80 * pump_health * lube_eff
	pump_power += (GLOB.grid_add_flowboost * 0.10)
	pump_power += (_grid_upgrade_level("stability") * 2)

	// Simple pressurizer auto-control loop.
	if(GLOB.grid_primary_pressure < 95)
		GLOB.grid_pressurizer_heaters += 3
		GLOB.grid_pressurizer_spray -= 2
	else if(GLOB.grid_primary_pressure > 135)
		GLOB.grid_pressurizer_spray += 3
		GLOB.grid_pressurizer_heaters -= 2
	else
		GLOB.grid_pressurizer_heaters -= 1
		GLOB.grid_pressurizer_spray -= 1
	GLOB.grid_pressurizer_heaters = clamp(round(GLOB.grid_pressurizer_heaters), 0, 100)
	GLOB.grid_pressurizer_spray = clamp(round(GLOB.grid_pressurizer_spray), 0, 100)

	// NPSH abstraction: hot fluid + low hotwell => cavitation risk.
	var/npsh = GLOB.grid_hotwell_level - (GLOB.wasteland_grid_core_heat * 0.45) + (GLOB.grid_primary_pressure * 0.20)
	GLOB.grid_npsh_margin = clamp(round(npsh), 0, 100)
	if(GLOB.grid_npsh_margin < 25)
		pump_power *= clamp(GLOB.grid_npsh_margin / 25, 0.35, 1.0)

	// Valve restrictions (operators + wear)
	var/valve_eff = clamp(GLOB.grid_sp_coolant_valve / 100, 0.0, 1.0)
	var/line_factor = 1.0 - (GLOB.grid_filter_clog / 200) - (GLOB.grid_coolant_contamination / 300)
	line_factor += (GLOB.grid_add_anticorrosion / 500)
	line_factor = clamp(line_factor, 0.2, 1.0)

	// Primary flow
	var/flow = pump_power * valve_eff * line_factor
	flow *= (1.0 - (GLOB.grid_wear_valves / 300))
	flow = clamp(flow, 0, 100)
	GLOB.grid_primary_flow = round(flow)

	// Primary pressure: heat pushes up, low flow pushes up, restriction pushes up, relief/leaks pull down
	var/restr = 0
	if(prim) restr = prim.effective_restriction()
	restr = max(0, restr - round(GLOB.grid_add_anticorrosion / 8) - (_grid_upgrade_level("stability") * 4))

	var/p = GLOB.grid_primary_pressure
	p += (GLOB.wasteland_grid_core_heat - 40) * (GRID_K_PRESS_HEAT)
	p += (60 - GLOB.grid_primary_flow) * (GRID_K_PRESS_FLOW)
	p += (restr / 50)
	p += (GLOB.grid_pressurizer_heaters / 20)

	// relief valve vents pressure
	p -= (GLOB.grid_sp_relief_valve / 15)
	p -= (GLOB.grid_pressurizer_spray / 18)

	// leaks reduce pressure & coolant resource
	var/leak = 0
	if(prim) leak = prim.leak_rate
	p -= leak * 2

	GLOB.grid_primary_pressure = clamp(round(p), 0, 200)

	// Secondary pressure follows heat exchanger and feedwater
	var/sec_p = GLOB.grid_secondary_pressure
	var/fw_eff = clamp(GLOB.grid_sp_feedwater_valve / 100, 0.0, 1.0)
	var/vac_eff = clamp(GLOB.grid_condenser_vacuum / 100, 0.2, 1.0)
	sec_p += (GLOB.wasteland_grid_core_heat - 50) * 0.25
	sec_p -= (fw_eff * 10) // more feedwater = better condensing = lower pressure
	sec_p -= (GLOB.grid_sp_bypass / 20) // bypass dumps steam
	sec_p -= (vac_eff * 7) // stronger condenser vacuum pulls secondary pressure down
	GLOB.grid_secondary_pressure = clamp(round(sec_p), 0, 200)

	// Steam quality better with good feedwater and good exchanger health (modeled via wear + clog)
	var/sq = GLOB.grid_steam_quality
	sq += (fw_eff * 4)
	sq += (GLOB.grid_add_antifoam * 0.05)
	sq -= (GLOB.grid_filter_clog / 40)
	sq -= (GLOB.grid_wear_turbine / 60)

	// Loss of subcooling degrades quality quickly (boiling/voiding starts).
	var/subcool = 85 - (GLOB.wasteland_grid_core_heat * 0.6) + (GLOB.grid_primary_pressure * 0.15)
	subcool += (GLOB.grid_sp_coolant_valve * 0.20) + (GLOB.grid_sp_feedwater_valve * 0.08)
	subcool -= (GLOB.grid_coolant_contamination * 0.20)
	GLOB.grid_subcool_margin = clamp(round(subcool), 0, 100)
	if(GLOB.grid_subcool_margin < 18)
		sq -= (18 - GLOB.grid_subcool_margin) * 0.8

	// Very cold/high-boron condition can precipitate boron and hurt loop quality.
	if(GLOB.wasteland_grid_core_heat < 20 && GLOB.grid_boron_ppm > 1700)
		GLOB.grid_filter_clog = clamp(GLOB.grid_filter_clog + 0.6, 0, 100)
		GLOB.grid_coolant_contamination = clamp(GLOB.grid_coolant_contamination + 0.4, 0, 100)

	sq = clamp(round(sq), 0, 100)
	GLOB.grid_steam_quality = sq

	// Pressurizer inventory behavior and "solid plant" tendency.
	var/pzr = GLOB.grid_pressurizer_level
	pzr += ((GLOB.wasteland_grid_core_heat - 50) / 250)
	pzr += (GLOB.grid_sp_feedwater_valve - 50) / 900
	pzr -= (GLOB.grid_sp_relief_valve / 550)
	GLOB.grid_pressurizer_level = clamp(round(pzr), 0, 100)

	// Condenser/hotwell abstractions.
	GLOB.grid_hotwell_level = clamp(round(GLOB.grid_hotwell_level + (fw_eff * 0.5) - (GLOB.grid_primary_flow / 220)), 0, 100)
	GLOB.grid_condenser_vacuum = clamp(round(GLOB.grid_condenser_vacuum + 0.15 - (GLOB.grid_filter_clog / 650) - (GLOB.grid_secondary_pressure / 900)), 0, 100)

	// writeback to networks if present
	if(prim)
		prim.flow = GLOB.grid_primary_flow
		prim.pressure = GLOB.grid_primary_pressure
	if(sec)
		sec.pressure = GLOB.grid_secondary_pressure
	if(fw)
		fw.flow = round(50 * fw_eff)

/proc/_simulate_turbine_and_output()
	// Turbine is now governor-driven instead of pure passive pressure-following.
	var/bypass_dump = (GLOB.grid_sp_bypass / 100) * 60
	var/rpm = GLOB.grid_turbine_rpm
	var/steam_head = clamp(GLOB.grid_secondary_pressure - bypass_dump, 0, 200)
	var/steam_drive = clamp((steam_head * 1.4) + (GLOB.grid_steam_quality * 0.7), 0, 200)

	// Command RPM from governor + target output request.
	var/governor_cap = clamp(GLOB.grid_sp_turbine_governor * 2, 0, 200)
	var/target_from_output = clamp(GLOB.grid_sp_target_output * 2, 0, 200)
	var/commanded_rpm = min(governor_cap, max(target_from_output, 20))
	var/target_rpm = min(commanded_rpm, steam_drive)

	// Ramp rate limited to avoid rotor stress transients.
	var/ramp_limit = 8 + round((100 - GLOB.grid_turbine_stress) / 25)
	var/delta = clamp(target_rpm - rpm, -ramp_limit, ramp_limit)
	rpm += delta

	// Moisture estimate (wet steam) and turbine stress accumulation.
	var/moisture_target = clamp(100 - GLOB.grid_steam_quality, 0, 100)
	GLOB.grid_turbine_moisture += (moisture_target - GLOB.grid_turbine_moisture) * 0.15
	GLOB.grid_turbine_moisture = clamp(GLOB.grid_turbine_moisture, 0, 100)

	GLOB.grid_turbine_stress += (abs(delta) / 2) + (GLOB.grid_turbine_moisture / 180)
	if(rpm > 170)
		GLOB.grid_turbine_stress += 1.2
	GLOB.grid_turbine_stress -= 1.1
	GLOB.grid_turbine_stress = clamp(GLOB.grid_turbine_stress, 0, 100)

	// Stress and wear damp achievable RPM.
	if(GLOB.grid_turbine_stress > 85)
		rpm -= 6
	var/cond_min = min(GLOB.grid_turbine_bearing_cond, GLOB.grid_turbine_blade_cond, GLOB.grid_turbine_alignment_cond)
	rpm *= clamp(cond_min / 100, 0.35, 1.0)
	rpm *= (1.0 - (GLOB.grid_wear_turbine / 250))
	rpm = clamp(round(rpm), 0, 200)
	GLOB.grid_turbine_rpm = rpm

	// Output reflects steam quality, turbine condition, and condenser vacuum.
	var/wf = (1.0 - (GLOB.grid_wear_turbine / 150))
	var/stress_pen = (1.0 - (GLOB.grid_turbine_stress / 220))
	var/moisture_pen = (1.0 - (GLOB.grid_turbine_moisture / 260))
	var/vac_eff = clamp(GLOB.grid_condenser_vacuum / 100, 0.35, 1.0)
	var/out = GRID_K_OUT * rpm * GLOB.grid_steam_quality * wf * stress_pen * moisture_pen * vac_eff
	out *= (1.0 + _grid_upgrade_bonus("peak_output"))
	if(world.time < GLOB.grid_overhaul_bonus_until)
		out *= 1.10
	out -= (GLOB.grid_theft_load_mw / 2)
	out = clamp(round(out), 0, 100)
	GLOB.grid_output = out

/proc/_update_wear_and_chemistry()
	// Chemistry drifts with temperature, pressure, and time
	var/heat = GLOB.wasteland_grid_core_heat
	var/press = GLOB.grid_primary_pressure
	var/stability_bonus = _grid_upgrade_bonus("stability")
	var/safety_bonus = _grid_upgrade_bonus("safety")

	// Active additive levels decay over time and consume stock when engaged.
	if(GLOB.grid_add_anticorrosion > 0)
		GLOB.grid_add_anticorrosion = max(0, GLOB.grid_add_anticorrosion - 0.6)
	if(GLOB.grid_add_antifoam > 0)
		GLOB.grid_add_antifoam = max(0, GLOB.grid_add_antifoam - 0.7)
	if(GLOB.grid_add_flowboost > 0)
		GLOB.grid_add_flowboost = max(0, GLOB.grid_add_flowboost - 0.8)

	// filter clogs steadily; faster when dirty/overheated
	GLOB.grid_filter_clog = clamp(GLOB.grid_filter_clog + 0.4 + (heat / 300) - (GLOB.grid_add_anticorrosion / 220), 0, 100)

	// contamination rises with heat and low flow (stagnation)
	if(GLOB.grid_primary_flow < 30) GLOB.grid_coolant_contamination += 0.6
	GLOB.grid_coolant_contamination += (heat / 250)
	GLOB.grid_coolant_contamination -= (GLOB.grid_add_antifoam / 180)
	GLOB.grid_coolant_contamination = clamp(GLOB.grid_coolant_contamination, 0, 100)

	// lube slowly drains; faster with high rpm
	GLOB.grid_lube_level -= 0.2 + (GLOB.grid_turbine_rpm / 800)
	GLOB.grid_lube_level = clamp(GLOB.grid_lube_level, 0, 100)

	// Wear rises with stress
	GLOB.grid_wear_pump_primary += (0.10 + (press / 1500) + (heat / 1200) + (GLOB.grid_decay_heat / 500)) * (1.0 - stability_bonus)
	GLOB.grid_wear_valves       += (0.05 + (GLOB.grid_sp_coolant_valve / 3000)) * (1.0 - stability_bonus)
	GLOB.grid_wear_turbine      += (0.10 + (GLOB.grid_turbine_rpm / 1000) + (GLOB.grid_sp_bypass / 2000) + (GLOB.grid_turbine_stress / 700) + (GLOB.grid_turbine_moisture / 1200)) * (1.0 - stability_bonus)
	GLOB.grid_wear_breakers     += (0.08 + (GLOB.grid_output / 1200)) * (1.0 - safety_bonus)
	GLOB.grid_wear_sensors      += 0.05 + (heat / 2000)

	GLOB.grid_wear_pump_primary = clamp(GLOB.grid_wear_pump_primary, 0, 100)
	GLOB.grid_wear_valves       = clamp(GLOB.grid_wear_valves, 0, 100)
	GLOB.grid_wear_turbine      = clamp(GLOB.grid_wear_turbine, 0, 100)
	GLOB.grid_wear_breakers     = clamp(GLOB.grid_wear_breakers, 0, 100)
	GLOB.grid_wear_sensors      = clamp(GLOB.grid_wear_sensors, 0, 100)

	// sensor drift grows with wear
	GLOB.grid_sensor_drift_heat  += (GLOB.grid_wear_sensors / 5000)
	GLOB.grid_sensor_drift_press += (GLOB.grid_wear_sensors / 7000)
	GLOB.grid_sensor_drift_flow  += (GLOB.grid_wear_sensors / 9000)

	GLOB.grid_sensor_health = clamp(100 - round(GLOB.grid_wear_sensors), 0, 100)

/proc/_update_alarms_and_fault_triggers()
	// Suppress automatic fault generation/maintenance pressure at low population.
	if(_grid_lowpop_suppression_active())
		return

	// --- Causal fault triggers (mostly deterministic-ish) ---
	// Overpressure + relief mostly closed => rupture
	if(GLOB.grid_primary_pressure > 160 && GLOB.grid_sp_relief_valve < 20)
		if(prob(30))
			add_grid_fault("pipe_rupture_primary", 3)

	// Low flow + heat rising => cavitation
	if(GLOB.grid_primary_flow < 20 && GLOB.wasteland_grid_core_heat > 65)
		if(prob(25))
			add_grid_fault("pump_cavitation", 2)

	// Pump wear => bearing seizure
	if(GLOB.grid_wear_pump_primary > 90)
		if(prob(12))
			add_grid_fault("pump_bearing_seizure", 3)

	// Filter clog extreme => filter blockage fault + contamination spike
	if(GLOB.grid_filter_clog > 90)
		if(prob(18))
			add_grid_fault("filter_blockage", 1)
			GLOB.grid_coolant_contamination = clamp(GLOB.grid_coolant_contamination + 5, 0, 100)

	// Turbine overspeed => trip
	if(GLOB.grid_turbine_rpm > 150)
		if(prob(20))
			add_grid_fault("turbine_overspeed_trip", 2)

	// Turbine wear high => vibration
	if(GLOB.grid_wear_turbine > 80 && GLOB.grid_turbine_rpm > 90)
		if(prob(15))
			add_grid_fault("turbine_vibration", 2)

	// Subcooling collapse + decay heat is dangerous even post-SCRAM.
	if(GLOB.grid_subcool_margin < 10 && GLOB.grid_decay_heat > 6)
		if(prob(25))
			add_grid_fault("coolant_leak", 2)

	// Pump cavitation from low suction margin.
	if(GLOB.grid_npsh_margin < 15)
		if(prob(28))
			add_grid_fault("pump_cavitation", 2)

	// Solid pressurizer condition can force pressure excursions.
	if(GLOB.grid_pressurizer_level >= 98 && GLOB.grid_primary_pressure > 140)
		if(prob(18))
			add_grid_fault("control_bus_short", 2)

	// Rotor stress / wet steam faults.
	if(GLOB.grid_turbine_stress > 85 || GLOB.grid_turbine_moisture > 60)
		if(prob(20))
			add_grid_fault("turbine_vibration", 2)

	// Sensor drift high => instrumentation fault
	if((GLOB.grid_sensor_drift_heat > 4 || GLOB.grid_sensor_drift_press > 4) && prob(10))
		add_grid_fault("sensor_drift", 1)

	// Small spice RNG (kept minimal)
	if(prob(1))
		add_grid_fault(pick(list("breaker_trip","control_bus_short","fuel_feed_jam")), 0)

/proc/_spawn_maintenance_tasks()
	if(_grid_lowpop_suppression_active())
		// Keep rolling timestamp fresh so the system does not "backlog burst"
		// the instant population crosses the threshold again.
		GLOB.grid_last_maint_roll = world.time
		return

	// roll on interval
	if(world.time < (GLOB.grid_last_maint_roll + GLOB.grid_maint_interval))
		return
	GLOB.grid_last_maint_roll = world.time

	// Filter service
	if(GLOB.grid_filter_clog > 60)
		grid_task_add(
			"maint_filter_replace",
			"Replace Coolant Filters",
			"Swap filter media and reseat the housing.",
			(GLOB.grid_filter_clog > 85) ? 3 : 2,
			5 MINUTES,
			"filter_1",
			/obj/structure/grid/filter_unit,
			/obj/item/screwdriver,
			list(/obj/item/crafting/board = 1, /obj/item/crafting/duct_tape = 2),
			list("Open access panel", "Replace filter media", "Reseat housing", "Close panel")
		)

	// Pump lubrication
	if(GLOB.grid_wear_pump_primary > 70 || GLOB.grid_lube_level < 40)
		grid_task_add(
			"maint_pump_lube",
			"Lubricate Primary Pump",
			"Top up lube and inspect bearings.",
			(GLOB.grid_wear_pump_primary > 85) ? 3 : 2,
			6 MINUTES,
			"primary_pump_1",
			/obj/machinery/grid/pump,
			/obj/item/wrench,
			list(/obj/item/crafting/wonderglue = 1, /obj/item/crafting/duct_tape = 1),
			list("Open pump service hatch", "Apply lubricant", "Inspect bearings", "Close hatch")
		)

	// Turbine service
	if(GLOB.grid_wear_turbine > 70 || GLOB.grid_turbine_stress > 70 || GLOB.grid_turbine_moisture > 45)
		grid_task_add(
			"maint_turbine_service",
			"Service Turbine Train",
			"Inspect governor controls, rotor mounts, and blade clearances.",
			(GLOB.grid_wear_turbine > 85 || GLOB.grid_turbine_stress > 85) ? 3 : 2,
			6 MINUTES,
			"turbine_1",
			/obj/structure/grid/turbine_assembly,
			/obj/item/wrench,
			list(/obj/item/crafting/small_gear = 2, /obj/item/crafting/wonderglue = 1, /obj/item/crafting/duct_tape = 1),
			list("Lock out controller", "Inspect rotor mounts", "Retorque housing", "Run vibration check")
		)

	// Sensor calibration
	if(GLOB.grid_sensor_health < 70 || GLOB.grid_wear_sensors > 60)
		grid_task_add(
			"maint_sensor_cal",
			"Calibrate Instrumentation",
			"Reset drift and verify readings against baseline.",
			(GLOB.grid_sensor_health < 50) ? 3 : 2,
			6 MINUTES,
			"sensor_panel_1",
			/obj/structure/grid/sensor_panel,
			/obj/item/screwdriver,
			list(/obj/item/crafting/board = 1, /obj/item/crafting/transistor = 2, /obj/item/crafting/diode = 2),
			list("Run calibration routine", "Replace noisy module", "Confirm drift reset")
		)

	// Valve exercise
	if(GLOB.grid_wear_valves > 75)
		grid_task_add(
			"maint_valve_exercise",
			"Exercise Coolant Valves",
			"Cycle valves to prevent sticking.",
			2,
			6 MINUTES,
			"coolant_valve_1",
			/obj/structure/grid/valve,
			/obj/item/wrench,
			list(/obj/item/crafting/wonderglue = 1),
			list("Cycle valve 0->100->0", "Check for binding", "Re-lube stem")
		)

	// Coolant flush
	if(GLOB.grid_coolant_contamination > 50)
		grid_task_add(
			"maint_flush",
			"Flush Coolant Loop",
			"Purge contaminated coolant and stabilize pressure.",
			(GLOB.grid_coolant_contamination > 80) ? 3 : 2,
			7 MINUTES,
			"purge_valve_1",
			/obj/structure/grid/purge_valve,
			/obj/item/wrench,
			list(/obj/item/f13/grid_coolant = 2),
			list("Open purge valve", "Run pump at low RPM", "Close purge valve", "Verify pressure stable")
		)

///////////////////////////////////////////////////////////////
// EXISTING REACTOR HEALTH LOOP (kept, but now uses v2 vars)
///////////////////////////////////////////////////////////////

/proc/_update_reactor_health()
	_wasteland_grid_bootstrap()

	var/heat = GLOB.wasteland_grid_core_heat
	var/contain = GLOB.wasteland_grid_containment
	var/integ = GLOB.wasteland_grid_integrity

	// Use v2 output as "load"; higher load stresses containment slowly
	if(GLOB.grid_output > 70) contain -= 0.2
	if(GLOB.grid_output > 90) contain -= 0.5

	var/unfixed = 0
	var/maxsev = 0
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed)
			unfixed++
			maxsev = max(maxsev, F.severity)

	// Faults reduce integrity; high heat reduces containment
	integ -= (0.08 * unfixed) + (0.20 * maxsev)
	if(heat > 60) contain -= 0.5
	if(heat > 75) contain -= 1.0
	if(heat > 90) contain -= 2.0
	if(GLOB.grid_decay_heat > 10 && GLOB.grid_primary_flow < 35)
		contain -= 0.7

	GLOB.wasteland_grid_containment = clamp(round(contain), 0, 100)
	GLOB.wasteland_grid_integrity   = clamp(round(integ), 0, 100)

	// containment collapse adds faults and can trip
	if(!_grid_lowpop_suppression_active() && GLOB.wasteland_grid_containment <= 50 && prob(5))
		add_grid_fault(pick(list("control_bus_short","coolant_leak","breaker_trip")), 2)

	if(GLOB.wasteland_grid_containment <= 25 && GLOB.wasteland_grid_online)
		_trip_grid("Containment collapse risk")

	_recalc_background_rads()

#define GRID_CATASTROPHE_RISK_LIMIT 100

/proc/_run_safety_interlocks()
	_wasteland_grid_bootstrap()

	if(GLOB.grid_catastrophe_triggered)
		return
	if(!GLOB.grid_safety_interlocks_enabled)
		return
	if(!GLOB.wasteland_grid_online)
		return

	var/extreme_pressure = (GLOB.grid_primary_pressure >= 190)
	var/extreme_heat = (GLOB.wasteland_grid_core_heat >= 98)
	var/loss_of_cooling = (GLOB.grid_primary_flow <= 12 && GLOB.grid_subcool_margin <= 5 && GLOB.grid_decay_heat >= 8)
	if(!(extreme_pressure || extreme_heat || loss_of_cooling))
		return

	GLOB.grid_scram = TRUE
	GLOB.grid_sp_rod_insertion = max(GLOB.grid_sp_rod_insertion, 95)
	GLOB.grid_sp_relief_valve = max(GLOB.grid_sp_relief_valve, 90)
	GLOB.grid_sp_bypass = max(GLOB.grid_sp_bypass, 80)

	if(world.time >= GLOB.grid_interlock_last_trip_at + (45 SECONDS))
		GLOB.grid_interlock_last_trip_at = world.time
		_announce_grid("WASTELAND GRID: Safety interlocks engaged (auto SCRAM + pressure relief).")

	if(extreme_pressure || loss_of_cooling)
		_trip_grid("Automatic safety interlock trip")

/proc/_trigger_grid_catastrophe(reason = "Prompt critical excursion")
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		return

	GLOB.grid_catastrophe_triggered = TRUE
	GLOB.grid_catastrophe_risk = GRID_CATASTROPHE_RISK_LIMIT
	GLOB.grid_safety_interlocks_enabled = FALSE

	GLOB.wasteland_grid_online = FALSE
	GLOB.wasteland_grid_restart_stage = 0
	GLOB.wasteland_grid_restart_operator = null
	GLOB.wasteland_grid_restart_lock = TRUE
	GLOB.wasteland_grid_restart_cooldown_until = world.time + (30 MINUTES)

	GLOB.grid_scram = FALSE
	GLOB.grid_output = 0
	GLOB.grid_turbine_rpm = 0
	GLOB.grid_primary_flow = 0
	GLOB.wasteland_grid_core_heat = 100
	GLOB.grid_decay_heat = 50
	GLOB.grid_primary_pressure = 200
	GLOB.grid_secondary_pressure = 200
	GLOB.wasteland_grid_containment = 0
	GLOB.wasteland_grid_integrity = 0

	_recalc_wasteland_grid_state()
	_recalc_background_rads()
	_sync_wasteland_grid_reactor()

	_announce_grid("WASTELAND GRID CATASTROPHIC FAILURE: [reason]. Massive radiation release in progress.")
	add_grid_fault("pipe_rupture_primary", 3)
	add_grid_fault("coolant_leak", 3)
	add_grid_fault("control_bus_short", 3)
	add_grid_fault("breaker_trip", 3)
	add_grid_fault("turbine_overspeed_trip", 3)

	var/atom/epicenter = _grid_get_radiation_anchor()
	if(epicenter)
		explosion(epicenter, 5, 9, 14, 20)
		for(var/d in list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
			new /datum/radiation_wave(epicenter, d, 120, RAD_DISTANCE_COEFFICIENT, TRUE)

/proc/_update_catastrophe_risk()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		return

	var/risk = GLOB.grid_catastrophe_risk
	var/risk_delta = -4
	var/extreme_combo = FALSE

	if(GLOB.wasteland_grid_online && !GLOB.grid_safety_interlocks_enabled && !GLOB.grid_scram)
		var/high_heat = (GLOB.wasteland_grid_core_heat >= 94)
		var/high_pressure = (GLOB.grid_primary_pressure >= 170)
		var/low_flow = (GLOB.grid_primary_flow <= 18)
		var/low_subcool = (GLOB.grid_subcool_margin <= 8)
		var/rods_withdrawn = (GLOB.grid_sp_rod_insertion <= 10)
		var/low_boron = (GLOB.grid_boron_ppm <= 180)
		var/high_xenon = (GLOB.grid_xenon_poison >= 22)

		extreme_combo = (high_heat && high_pressure && low_flow && low_subcool && rods_withdrawn && low_boron && high_xenon)
		if(extreme_combo)
			risk_delta = 7
		else if(high_heat && low_flow && rods_withdrawn)
			risk_delta = 2
		else
			risk_delta = -2

	risk = clamp(risk + risk_delta, 0, GRID_CATASTROPHE_RISK_LIMIT)
	GLOB.grid_catastrophe_risk = risk

	if(extreme_combo && risk >= GRID_CATASTROPHE_RISK_LIMIT)
		_trigger_grid_catastrophe("Deliberate interlock bypass under unstable xenon/low-flow conditions")

/proc/_grid_get_active_players()
	var/players = get_active_player_count(alive_check = 1, afk_check = 1, human_check = 1)
	GLOB.grid_auto_last_player_count = players
	return players

/proc/_grid_lowpop_suppression_active()
	_wasteland_grid_bootstrap()
	var/threshold = clamp(round(GLOB.grid_lowpop_faults_threshold), 1, 120)
	GLOB.grid_lowpop_faults_threshold = threshold
	var/players = GLOB.grid_auto_last_player_count
	if(isnull(players) || players < 0)
		players = _grid_get_active_players()
	return (players < threshold)

/proc/_grid_upgrade_level(key)
	if(!istext(key) || !islist(GLOB.grid_plant_upgrades))
		return 0
	var/v = GLOB.grid_plant_upgrades[key]
	if(isnull(v))
		return 0
	return clamp(round(v), 0, 3)

/proc/_grid_upgrade_bonus(key)
	return _grid_upgrade_level(key) * 0.08

/proc/_grid_get_export_mw_max()
	_wasteland_grid_bootstrap()
	var/base = GRID_AUCTION_BASE_SUPPLY_MW
	base += round(_grid_upgrade_level("peak_output") * 25)
	return clamp(base, 60, GRID_AUCTION_MAX_SUPPLY_MW)

/proc/_grid_get_export_mw_capacity()
	_wasteland_grid_bootstrap()
	var/max_mw = _grid_get_export_mw_max()
	var/output_factor = clamp(GLOB.grid_output / 100, 0, 1.25)
	var/cond_min = min(GLOB.grid_turbine_bearing_cond, GLOB.grid_turbine_blade_cond, GLOB.grid_turbine_alignment_cond)
	var/cond_factor = clamp(cond_min / 100, 0.4, 1.0)
	var/chem_factor = 1.0
	chem_factor += (GLOB.grid_add_flowboost / 700)
	chem_factor += (GLOB.grid_add_antifoam / 1200)
	chem_factor += (_grid_upgrade_bonus("stability") * 0.5)
	if(world.time < GLOB.grid_overhaul_bonus_until)
		chem_factor += 0.08

	var/cap = round(max_mw * output_factor * cond_factor * chem_factor)
	if(!GLOB.wasteland_grid_online)
		cap = round(max_mw * 0.15)
	cap -= round(GLOB.grid_theft_load_mw)
	return clamp(cap, 0, GRID_AUCTION_MAX_SUPPLY_MW)

/proc/_grid_get_user_faction(mob/user)
	if(!user || !SSfaction_control)
		return null
	if(!hascall(SSfaction_control, "get_mob_faction"))
		return null
	return call(SSfaction_control, "get_mob_faction")(user)

/proc/_grid_get_dispatch_districts()
	var/list/out = list()
	for(var/d in GLOB.wasteland_grid_district_applied_on)
		if(istext(d) && d)
			out += "[d]"
	if(!length(out))
		out = list("BOS", "NCR", "Legion", "Town", "Mass Fusion")
	return out

/proc/_grid_get_district_owner(district)
	if(!district || !SSfaction_control || !hascall(SSfaction_control, "get_owner"))
		return null
	return call(SSfaction_control, "get_owner")(district)

/proc/_grid_start_auction()
	_wasteland_grid_bootstrap()
	GLOB.grid_auction_round_id++
	GLOB.grid_auction_open_until = world.time + GRID_AUCTION_DURATION
	GLOB.grid_auction_bids = list()
	GLOB.grid_auction_revenue_pool = 0
	_announce_grid("WASTELAND GRID: Power auction round #[GLOB.grid_auction_round_id] opened for [round(GRID_AUCTION_DURATION/10)]s.")

/proc/_grid_submit_auction_bid(mob/user, district, requested_mw, bid_caps)
	_wasteland_grid_bootstrap()
	if(!user || !istext(district) || !district)
		return "Invalid bid."
	if(world.time >= GLOB.grid_auction_open_until)
		return "Auction is closed."
	var/faction = _grid_get_user_faction(user)
	if(!faction)
		return "Could not resolve your faction."
	if(!SSfaction_control || !hascall(SSfaction_control, "spend_faction_funds"))
		return "Faction economy subsystem unavailable."

	var/mw = clamp(round(text2num("[requested_mw]")), 5, 120)
	var/caps = clamp(round(text2num("[bid_caps]")), 50, 5000)

	var/list/current = GLOB.grid_auction_bids[district]
	if(islist(current))
		var/current_caps = round(current["bid_caps"])
		if(caps <= current_caps)
			return "Bid rejected: must exceed current high bid ([current_caps] caps)."

	if(!call(SSfaction_control, "spend_faction_funds")(faction, caps))
		return "Your faction treasury cannot afford this bid."

	if(islist(current))
		var/old_faction = current["faction"]
		var/old_escrow = round(current["escrow"])
		if(old_faction && old_escrow > 0 && hascall(SSfaction_control, "add_faction_funds"))
			call(SSfaction_control, "add_faction_funds")(old_faction, old_escrow)
		GLOB.grid_auction_revenue_pool = max(0, GLOB.grid_auction_revenue_pool - old_escrow)

	GLOB.grid_auction_bids[district] = list(
		"faction" = faction,
		"district" = district,
		"request_mw" = mw,
		"bid_caps" = caps,
		"escrow" = caps,
		"submitted_at" = world.time
	)
	GLOB.grid_auction_revenue_pool += caps
	return "Bid accepted: [faction] bids [caps] caps for [mw]MW in [district]."

/proc/_grid_close_auction()
	_wasteland_grid_bootstrap()
	if(world.time < GLOB.grid_auction_open_until)
		return
	if(!islist(GLOB.grid_district_mw_alloc))
		GLOB.grid_district_mw_alloc = list()
	GLOB.grid_district_mw_alloc = list()

	var/base_supply = _grid_get_export_mw_capacity()
	base_supply = clamp(base_supply, 0, GRID_AUCTION_MAX_SUPPLY_MW)
	var/available = base_supply
	var/list/research_awards = list()

	var/list/keys = list()
	for(var/d in GLOB.grid_auction_bids)
		keys += d
	keys = sortList(keys)

	for(var/d in keys)
		var/list/bid = GLOB.grid_auction_bids[d]
		if(!islist(bid))
			continue
		var/request = clamp(round(bid["request_mw"]), 5, 120)
		var/grant = min(request, available)
		GLOB.grid_district_mw_alloc[d] = grant
		if(grant > 0)
			var/f = bid["faction"]
			if(istext(f) && f)
				research_awards[f] = round(research_awards[f]) + (grant * GRID_AUCTION_RESEARCH_PER_MW)
		available -= grant
		if(available <= 0)
			break

	GLOB.grid_committed_mw = base_supply - max(0, available)
	var/revenue = GLOB.grid_auction_revenue_pool
	GLOB.grid_auction_revenue_pool = 0
	GLOB.grid_auction_open_until = 0

	if(revenue > 0 && SSfaction_control && hascall(SSfaction_control, "add_faction_funds"))
		call(SSfaction_control, "add_faction_funds")("Mass Fusion", revenue)
	if(SSfaction_control && hascall(SSfaction_control, "add_research_points"))
		for(var/faction in research_awards)
			var/rp = round(research_awards[faction])
			if(rp > 0)
				call(SSfaction_control, "add_research_points")(faction, rp)
	_announce_grid("WASTELAND GRID: Power auction closed. Committed [GLOB.grid_committed_mw]MW, plant revenue +[revenue] caps.")

/proc/_grid_dispatch_make_call(call_type, district, severity, desc)
	if(!istext(district) || !district)
		return
	var/list/C = list(
		"id" = "D[round(GLOB.grid_dispatch_next_id++)]",
		"type" = call_type,
		"district" = district,
		"severity" = clamp(round(severity), 1, 3),
		"desc" = "[desc]",
		"created_at" = world.time,
		"expires_at" = world.time + GRID_DISPATCH_TTL,
		"resolved" = FALSE,
		"resolved_by" = null
	)
	GLOB.grid_dispatch_calls += list(C)

/proc/_grid_dispatch_tick()
	_wasteland_grid_bootstrap()
	if(world.time < GLOB.grid_dispatch_next_roll)
		return
	GLOB.grid_dispatch_next_roll = world.time + GRID_DISPATCH_INTERVAL

	var/list/remove = list()
	for(var/list/C in GLOB.grid_dispatch_calls)
		if(!islist(C))
			remove += C
			continue
		if(C["resolved"])
			remove += C
			continue
		if(world.time >= round(C["expires_at"]))
			remove += C
	if(length(remove))
		GLOB.grid_dispatch_calls -= remove

	if(length(GLOB.grid_dispatch_calls) >= 6)
		return

	var/list/districts = _grid_get_dispatch_districts()
	if(!length(districts))
		return
	var/d = pick(districts)
	var/sev = 1
	var/type = "outage"
	var/desc = "Localized power irregularities detected."
	if(GLOB.grid_primary_pressure > 150 || GLOB.wasteland_grid_core_heat > 85)
		type = "coolant_leak"
		desc = "Hot-loop instability and leak indications."
		sev = 3
	else if(!_grid_is_district_on(d))
		type = "outage"
		desc = "District blackout requires field verification."
		sev = 2
	else if(prob(40))
		type = "breaker_fault"
		desc = "Breaker panel fault reported by district controllers."
		sev = 2
	_grid_dispatch_make_call(type, d, sev, desc)

/proc/_grid_resolve_dispatch_call(mob/user, call_id)
	_wasteland_grid_bootstrap()
	if(!user || !call_id)
		return "Invalid dispatch completion."
	for(var/list/C in GLOB.grid_dispatch_calls)
		if(!islist(C) || C["id"] != call_id)
			continue
		if(C["resolved"])
			return "Call already resolved."
		var/sev = clamp(round(C["severity"]), 1, 3)
		var/owner = _grid_get_district_owner(C["district"])
		var/time_left_ds = max(0, round(C["expires_at"]) - world.time)
		var/speed_bonus = round((time_left_ds / 10) * 3)
		var/pay = 120 + (sev * 80) + speed_bonus
		if(owner && SSfaction_control && hascall(SSfaction_control, "add_faction_funds"))
			call(SSfaction_control, "add_faction_funds")(owner, pay)
		GLOB.grid_plant_upgrade_points += sev
		C["resolved"] = TRUE
		C["resolved_by"] = "[user]"
		C["resolved_at"] = world.time
		return "Dispatch resolved: [C["district"]] ([C["type"]]). Paid [pay] caps to [owner ? owner : "local authority"] and +[sev] plant upgrade point(s)."
	return "Dispatch call not found."

/proc/_grid_tick_spent_fuel_and_waste()
	_wasteland_grid_bootstrap()
	if(GLOB.wasteland_grid_online)
		GLOB.grid_spent_fuel_units += max(0, round((GLOB.grid_output / 25) + (GLOB.grid_fuel_burnup / 200), 0.1))
	if(GLOB.grid_casks_staged > 0 || GLOB.grid_casks_stored > 0)
		GLOB.grid_waste_hazard = clamp(GLOB.grid_waste_hazard + (GLOB.grid_casks_staged * 0.3) + (GLOB.grid_casks_stored * 0.1), 0, 100)
	GLOB.grid_waste_hazard = clamp(GLOB.grid_waste_hazard - (0.20 + _grid_upgrade_bonus("safety")), 0, 100)

/proc/_grid_stage_spent_fuel_cask(mob/user)
	_wasteland_grid_bootstrap()
	if(!user)
		return "No operator."
	if(GLOB.grid_spent_fuel_units < 5)
		return "Not enough spent fuel to package a cask."
	GLOB.grid_spent_fuel_units -= 5
	GLOB.grid_casks_staged++
	GLOB.grid_waste_hazard = clamp(GLOB.grid_waste_hazard + 4, 0, 100)
	return "Spent fuel packaged into cask. Staged casks: [GLOB.grid_casks_staged]."

/proc/_grid_store_staged_cask(mob/user)
	_wasteland_grid_bootstrap()
	if(!user)
		return "No operator."
	if(GLOB.grid_casks_staged <= 0)
		return "No staged casks."
	GLOB.grid_casks_staged--
	GLOB.grid_casks_stored++
	GLOB.grid_waste_hazard = clamp(GLOB.grid_waste_hazard - 2, 0, 100)
	return "Moved one cask to shielded storage."

/proc/_grid_process_stored_cask(mob/user)
	_wasteland_grid_bootstrap()
	if(!user)
		return "No operator."
	if(GLOB.grid_casks_stored <= 0)
		return "No stored casks to process."
	GLOB.grid_casks_stored--
	GLOB.grid_casks_processed++
	GLOB.grid_waste_hazard = clamp(GLOB.grid_waste_hazard - 4, 0, 100)
	GLOB.grid_plant_upgrade_points += 1
	if(SSfaction_control && hascall(SSfaction_control, "add_faction_funds"))
		call(SSfaction_control, "add_faction_funds")("Mass Fusion", 90)
	return "Processed one cask. +1 plant upgrade point."

/proc/_grid_theft_tick()
	_wasteland_grid_bootstrap()
	var/list/districts = _grid_get_dispatch_districts()
	var/theft_load = 0
	for(var/d in districts)
		if(!isnum(GLOB.grid_theft_by_district[d]))
			GLOB.grid_theft_by_district[d] = 0
		var/v = round(GLOB.grid_theft_by_district[d])
		if(_grid_is_district_on(d) && prob(20))
			v += rand(1, 4)
		v -= 1 + _grid_upgrade_level("automation")
		v = clamp(v, 0, 100)
		GLOB.grid_theft_by_district[d] = v
		theft_load += round(v / 25)
	GLOB.grid_theft_load_mw = clamp(theft_load, 0, 80)

/proc/_grid_run_forensics_scan()
	_wasteland_grid_bootstrap()
	if(world.time < GLOB.grid_forensics_last_scan + GRID_FORENSICS_SCAN_COOLDOWN)
		return FALSE
	GLOB.grid_forensics_last_scan = world.time
	var/list/report = list()
	for(var/d in _grid_get_dispatch_districts())
		var/v = round(GLOB.grid_theft_by_district[d])
		if(v <= 0)
			continue
		report += list(list("district" = d, "intensity" = v))
	GLOB.grid_forensics_report = report
	return TRUE

/proc/_grid_shutdown_tap(district)
	_wasteland_grid_bootstrap()
	if(!istext(district) || !district)
		return FALSE
	var/v = round(GLOB.grid_theft_by_district[district])
	if(v <= 0)
		return FALSE
	GLOB.grid_theft_by_district[district] = max(0, v - 25)
	return TRUE

/proc/_grid_start_overhaul(mob/user)
	_wasteland_grid_bootstrap()
	if(!user)
		return "No operator."
	if(GLOB.grid_overhaul_session["active"])
		return "Overhaul already in progress."
	GLOB.grid_overhaul_session["active"] = TRUE
	GLOB.grid_overhaul_session["expires"] = world.time + (4 MINUTES)
	GLOB.grid_overhaul_session["steps"] = list("bearing", "blade", "alignment")
	GLOB.grid_overhaul_session["index"] = 1
	return "Turbine overhaul started. Step 1: bearing."

/proc/_grid_get_overhaul_step()
	if(!GLOB.grid_overhaul_session["active"])
		return "idle"
	var/list/steps = GLOB.grid_overhaul_session["steps"]
	var/idx = clamp(round(GLOB.grid_overhaul_session["index"]), 1, length(steps))
	return steps[idx]

/proc/_grid_progress_overhaul(mob/user, step)
	_wasteland_grid_bootstrap()
	if(!user)
		return "No operator."
	if(!GLOB.grid_overhaul_session["active"])
		return "No active overhaul session."
	if(world.time > round(GLOB.grid_overhaul_session["expires"]))
		GLOB.grid_overhaul_session["active"] = FALSE
		return "Overhaul session expired."
	var/current = _grid_get_overhaul_step()
	if(step != current)
		return "Wrong step. Current step: [current]."

	if(step == "bearing")
		GLOB.grid_turbine_bearing_cond = clamp(GLOB.grid_turbine_bearing_cond + 15, 0, 100)
	else if(step == "blade")
		GLOB.grid_turbine_blade_cond = clamp(GLOB.grid_turbine_blade_cond + 15, 0, 100)
	else if(step == "alignment")
		GLOB.grid_turbine_alignment_cond = clamp(GLOB.grid_turbine_alignment_cond + 15, 0, 100)

	var/list/steps = GLOB.grid_overhaul_session["steps"]
	var/idx = round(GLOB.grid_overhaul_session["index"]) + 1
	if(idx > length(steps))
		GLOB.grid_overhaul_session["active"] = FALSE
		GLOB.grid_overhaul_bonus_until = world.time + (8 MINUTES)
		return "Overhaul complete. Turbine receives an efficiency bonus for 8 minutes."
	GLOB.grid_overhaul_session["index"] = idx
	return "Step complete. Next step: [steps[idx]]."

/proc/_grid_tick_turbine_condition()
	_wasteland_grid_bootstrap()
	var/stress_factor = max(0, (GLOB.grid_turbine_stress - 40) / 100)
	var/moist_factor = max(0, (GLOB.grid_turbine_moisture - 25) / 120)
	var/wear_rate = 0.12 + stress_factor + moist_factor
	GLOB.grid_turbine_bearing_cond = clamp(GLOB.grid_turbine_bearing_cond - wear_rate, 0, 100)
	GLOB.grid_turbine_blade_cond = clamp(GLOB.grid_turbine_blade_cond - (wear_rate * 0.9), 0, 100)
	GLOB.grid_turbine_alignment_cond = clamp(GLOB.grid_turbine_alignment_cond - (wear_rate * 0.8), 0, 100)

/proc/_grid_apply_additive(mob/user, key, amount)
	_wasteland_grid_bootstrap()
	if(!user || !istext(key) || !key)
		return "Invalid additive request."
	var/qty = clamp(round(text2num("[amount]")), 1, 25)
	if(key == "anticorrosion")
		if(GLOB.grid_stock_anticorrosion < qty)
			return "Not enough anti-corrosion stock."
		GLOB.grid_stock_anticorrosion -= qty
		GLOB.grid_add_anticorrosion = clamp(GLOB.grid_add_anticorrosion + (qty * 2), 0, 100)
		return "Injected anti-corrosion additive (+[qty])."
	if(key == "antifoam")
		if(GLOB.grid_stock_antifoam < qty)
			return "Not enough anti-foam stock."
		GLOB.grid_stock_antifoam -= qty
		GLOB.grid_add_antifoam = clamp(GLOB.grid_add_antifoam + (qty * 2), 0, 100)
		return "Injected anti-foam additive (+[qty])."
	if(key == "flowboost")
		if(GLOB.grid_stock_flowboost < qty)
			return "Not enough flow boost stock."
		GLOB.grid_stock_flowboost -= qty
		GLOB.grid_add_flowboost = clamp(GLOB.grid_add_flowboost + (qty * 2), 0, 100)
		return "Injected flow boost additive (+[qty])."
	return "Unknown additive."

/proc/_grid_buy_plant_upgrade(mob/user, key)
	_wasteland_grid_bootstrap()
	if(!user || !istext(key) || !key)
		return "Invalid upgrade request."
	if(!(key in list("stability", "peak_output", "automation", "safety")))
		return "Unknown upgrade path."
	var/lvl = _grid_upgrade_level(key)
	if(lvl >= 3)
		return "[key] is already maxed."
	var/cost = lvl + 1
	if(GLOB.grid_plant_upgrade_points < cost)
		return "Need [cost] plant points (have [GLOB.grid_plant_upgrade_points])."
	GLOB.grid_plant_upgrade_points -= cost
	GLOB.grid_plant_upgrades[key] = lvl + 1
	return "Upgraded [key] to tier [lvl + 1]."

/proc/_grid_run_automation()
	_wasteland_grid_bootstrap()

	var/players = _grid_get_active_players()
	var/threshold = clamp(round(GLOB.grid_auto_player_threshold), 1, 120)
	GLOB.grid_auto_player_threshold = threshold

	var/auto_now = (!!GLOB.grid_auto_enabled && !GLOB.grid_catastrophe_triggered && players < threshold)
	if(auto_now != !!GLOB.grid_auto_active)
		GLOB.grid_auto_active = auto_now
		if(auto_now)
			_announce_grid("WASTELAND GRID: Auto-operations engaged ([players] active players, threshold [threshold]).")
		else
			_announce_grid("WASTELAND GRID: Auto-operations disengaged ([players] active players, threshold [threshold]).")

	if(!auto_now)
		return

	// Automation always prefers safe operation.
	if(!GLOB.grid_safety_interlocks_enabled)
		GLOB.grid_safety_interlocks_enabled = TRUE
		GLOB.grid_catastrophe_risk = max(0, GLOB.grid_catastrophe_risk - 5)

	if(GLOB.grid_sp_target_output < 35 || GLOB.grid_sp_target_output > 60)
		GLOB.grid_sp_target_output = 45

	GLOB.grid_sp_coolant_valve = max(GLOB.grid_sp_coolant_valve, 65)
	GLOB.grid_sp_feedwater_valve = max(GLOB.grid_sp_feedwater_valve, 55)
	GLOB.grid_sp_turbine_governor = max(GLOB.grid_sp_turbine_governor, 40)
	GLOB.grid_sp_bypass = clamp(GLOB.grid_sp_bypass, 5, 25)

	var/high_risk = (GLOB.wasteland_grid_core_heat >= 90 || GLOB.grid_primary_pressure >= 150 || GLOB.grid_subcool_margin <= 15 || GLOB.grid_npsh_margin <= 12)

	if(high_risk)
		GLOB.grid_sp_rod_insertion = min(100, max(GLOB.grid_sp_rod_insertion, 85))
		GLOB.grid_sp_coolant_valve = min(100, GLOB.grid_sp_coolant_valve + 10)
		GLOB.grid_sp_relief_valve = max(GLOB.grid_sp_relief_valve, 35)
		GLOB.grid_sp_turbine_governor = max(25, GLOB.grid_sp_turbine_governor - 8)
		if(GLOB.wasteland_grid_core_heat >= 96 || GLOB.grid_primary_pressure >= 180)
			GLOB.grid_scram = TRUE
	else
		if(GLOB.grid_scram && GLOB.wasteland_grid_core_heat <= 70 && GLOB.grid_primary_pressure <= 115 && GLOB.grid_subcool_margin >= 25)
			GLOB.grid_scram = FALSE

		if(GLOB.grid_output < (GLOB.grid_sp_target_output - 8))
			GLOB.grid_sp_rod_insertion = max(18, GLOB.grid_sp_rod_insertion - 4)
			GLOB.grid_sp_turbine_governor = min(78, GLOB.grid_sp_turbine_governor + 3)
		else if(GLOB.grid_output > (GLOB.grid_sp_target_output + 8))
			GLOB.grid_sp_rod_insertion = min(92, GLOB.grid_sp_rod_insertion + 4)
			GLOB.grid_sp_turbine_governor = max(30, GLOB.grid_sp_turbine_governor - 2)
		else
			GLOB.grid_sp_rod_insertion = clamp(GLOB.grid_sp_rod_insertion, 35, 75)

		var/target_boron = 700 + (GLOB.grid_xenon_poison * 12) + (GLOB.grid_fuel_burnup * 2)
		GLOB.grid_sp_boron_ppm = clamp(round(target_boron), 500, 1500)
		GLOB.grid_sp_relief_valve = clamp(GLOB.grid_sp_relief_valve, 0, 20)

	if(!GLOB.wasteland_grid_online && !GLOB.wasteland_grid_restart_lock && world.time >= GLOB.wasteland_grid_restart_cooldown_until)
		if(GLOB.wasteland_grid_fuel > 0 && GLOB.wasteland_grid_coolant > 0 && GLOB.grid_xenon_poison < 34)
			GLOB.wasteland_grid_restart_stage = 0
			GLOB.wasteland_grid_restart_operator = null
			GLOB.wasteland_grid_restart_lock = FALSE
			set_wasteland_grid_online(TRUE)
			_announce_grid("WASTELAND GRID: Auto-operations brought the reactor online.")

///////////////////////////////////////////////////////////////
// SUBSYSTEM (modified to v2 phase order)
///////////////////////////////////////////////////////////////

SUBSYSTEM_DEF(wasteland_grid)
	name = "Wasteland Grid"
	wait = 10 SECONDS
	priority = FIRE_PRIORITY_DEFAULT

	// tuning knobs (existing resource drains)
	var/fuel_drain_per_tick = 1
	var/coolant_drain_per_tick = 1
	var/min_fuel_to_run = 1
	var/min_coolant_to_run = 1

/datum/controller/subsystem/wasteland_grid/Initialize(timeofday)
	. = ..()
	_wasteland_grid_bootstrap()

/datum/controller/subsystem/wasteland_grid/fire(resumed)
	_wasteland_grid_bootstrap()
	_grid_get_active_players()
	// procedures must advance even if nobody is using the console
	grid_tick_procedures()

	// Drain basic resources only if online (existing)
	if(GLOB.wasteland_grid_online)
		GLOB.wasteland_grid_fuel = max(0, GLOB.wasteland_grid_fuel - fuel_drain_per_tick)
		GLOB.wasteland_grid_coolant = max(0, GLOB.wasteland_grid_coolant - coolant_drain_per_tick)

		if(GLOB.wasteland_grid_fuel < min_fuel_to_run || GLOB.wasteland_grid_coolant < min_coolant_to_run)
			_trip_grid("Resource failure (fuel/coolant)")

	// Neglect escalation always
	_escalate_faults_if_neglected()
	_grid_run_automation()

	// v2 PHASE ORDER
	_apply_operator_controls()
	_simulate_reactor_kinetics()
	_simulate_thermal()
	_simulate_hydraulics()
	_simulate_turbine_and_output()
	_update_wear_and_chemistry()
	_grid_tick_turbine_condition()
	_grid_tick_spent_fuel_and_waste()
	_grid_theft_tick()
	_update_alarms_and_fault_triggers()
	_run_safety_interlocks()
	_update_catastrophe_risk()
	_spawn_maintenance_tasks()
	_grid_dispatch_tick()

	if(GLOB.grid_auction_open_until <= 0)
		_grid_start_auction()
	else if(world.time >= GLOB.grid_auction_open_until)
		_grid_close_auction()
		_grid_start_auction()

	// State recalc (existing + v2 conditions)
	_recalc_wasteland_grid_state()

	// Reactor health + rads (existing)
	_update_reactor_health()
	_sync_wasteland_grid_reactor()

	if(!SSticker || !SSticker.HasRoundStarted())
		return

	// Rolling blackouts (existing, RED only)
	if(GLOB.wasteland_grid_online && GLOB.wasteland_grid_state == "RED")
		var/d = _grid_pick_random_district()
		if(d && _grid_is_district_on(d))
			_grid_set_district_off(d, rand(GRID_RED_OUTAGE_MIN, GRID_RED_OUTAGE_MAX))
			_announce_grid("WASTELAND GRID: Rolling blackout in district: [d].")

	_grid_tick_backup_generators()

	// Keep district power channels in sync with reactor routing and outage timers.
	_grid_reconcile_district_power()

	_apply_background_radiation()
	_apply_catastrophe_core_radiation()
	_emit_background_radiation_waves()

	for(var/obj/machinery/f13_grid_gated/M in GLOB.machines)
		M.power_change()

///////////////////////////////////////////////////////////////
// GRID OPS (existing)
///////////////////////////////////////////////////////////////

/proc/_trip_grid(reason)
	if(!GLOB.wasteland_grid_online)
		return

	set_wasteland_grid_online(FALSE)
	GLOB.wasteland_grid_last_trip = world.time
	GLOB.wasteland_grid_restart_stage = 0
	GLOB.wasteland_grid_restart_operator = null
	GLOB.wasteland_grid_restart_lock = FALSE
	GLOB.wasteland_grid_restart_cooldown_until = max(GLOB.wasteland_grid_restart_cooldown_until, world.time + 45 SECONDS)

	add_grid_fault("breaker_trip", 2)
	_announce_grid("WASTELAND GRID OFFLINE: [reason]. Power is out across the wasteland.")

///////////////////////////////////////////////////////////////
// ITEMS: FUEL + COOLANT (existing)
///////////////////////////////////////////////////////////////

/obj/item/f13/grid_fuel
	name = "fuel rod"
	desc = "A heavy sealed fuel rod. Feeds the Mass Fusion plant."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "jar"
	w_class = WEIGHT_CLASS_BULKY
	var/fuel_value = 25

/obj/item/f13/grid_coolant
	name = "coolant canister"
	desc = "A pressurized coolant canister."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "box"
	w_class = WEIGHT_CLASS_BULKY
	var/coolant_value = 25

///////////////////////////////////////////////////////////////
// REPAIR POINTS (existing multipart system)
///////////////////////////////////////////////////////////////

/proc/_grid_count_reqs_nearby(mob/user, atom/center, list/reqs)
	if(!reqs || !reqs.len)
		return TRUE

	var/list/have = _grid_collect_available_parts(user, center)

	for(var/req_path in reqs)
		var/need = reqs[req_path]
		if(need <= 0)
			continue

		var/got = 0
		for(var/have_path in have)
			if(ispath(have_path, req_path))
				got += have[have_path]
				if(got >= need)
					break

		if(got < need)
			return FALSE

	return TRUE

/proc/_grid_count_reqs_in_mob(mob/user, list/reqs)
	if(!user) return FALSE
	if(!reqs || !reqs.len) return TRUE

	var/list/have = list()

	// inventory counts
	for(var/obj/item/I in user.contents)
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			have[I.type] += S.amount
		else
			have[I.type] += 1

	for(var/req_path in reqs)
		var/need = reqs[req_path]
		if(need <= 0) continue

		var/got = 0
		for(var/have_path in have)
			if(ispath(have_path, req_path))
				got += have[have_path]
				if(got >= need) break

		if(got < need)
			return FALSE

	return TRUE

/proc/_grid_consume_reqs_from_mob(mob/user, list/reqs)
	if(!user) return FALSE
	if(!reqs || !reqs.len) return TRUE

	for(var/req_path in reqs)
		var/need = reqs[req_path]
		if(need <= 0) continue

		// 1) stacks
		for(var/obj/item/stack/S in user.contents)
			if(ispath(S.type, req_path) && need > 0)
				var/take = min(need, S.amount)
				S.use(take)
				need -= take

		// 2) loose items
		for(var/obj/item/I in user.contents)
			if(need <= 0) break
			if(!istype(I, /obj/item/stack) && ispath(I.type, req_path))
				qdel(I)
				need--

		if(need > 0)
			return FALSE

	return TRUE

/proc/_grid_consume_reqs_nearby(mob/user, atom/center, list/reqs)
	if(!reqs || !reqs.len)
		return TRUE

	for(var/req_path in reqs)
		var/need = reqs[req_path]
		if(need <= 0)
			continue

		// 1) Inventory stacks
		for(var/obj/item/stack/S in user.contents)
			if(ispath(S.type, req_path) && need > 0)
				var/take = min(need, S.amount)
				S.use(take)
				need -= take

		// 2) Nearby stacks
		for(var/obj/item/stack/S in _grid_get_nearby_items(center))
			if(ispath(S.type, req_path) && need > 0)
				var/take = min(need, S.amount)
				S.use(take)
				need -= take

		// 3) Inventory loose items
		for(var/obj/item/I in user.contents)
			if(need <= 0) break
			if(!istype(I, /obj/item/stack) && ispath(I.type, req_path))
				qdel(I)
				need--

		// 4) Nearby loose items
		for(var/obj/item/I in _grid_get_nearby_items(center))
			if(need <= 0) break
			if(!istype(I, /obj/item/stack) && ispath(I.type, req_path))
				qdel(I)
				need--

		if(need > 0)
			return FALSE

	return TRUE

/obj/structure/wasteland_grid/repair_point
	name = "grid repair point"
	icon = 'fallout/eris/icons/Reactor_32x32.dmi'
	icon_state = "Breaker_cabinet_closed"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/repair_key = "breaker"
	var/can_advance_restart = TRUE

/obj/structure/wasteland_grid/repair_point/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	if(!user) return ..()

	var/datum/wasteland_grid_fault/F = _find_matching_fault()
	if(F)
		to_chat(user, span_warning("Active issue: [F.describe()]"))
		to_chat(user, span_notice("Required tool: [F.get_required_tool_text()]"))
		to_chat(user, span_notice("Required parts: [F.get_effective_reqs_text()]"))
		to_chat(user, span_notice("Use the required tool on the panel to attempt the repair (parts are consumed from your inventory)."))
		return TRUE

	if(can_advance_restart)
		if(_try_do_restart_action(user)) return TRUE

	to_chat(user, span_notice("Nothing to fix here right now."))
	return TRUE

/obj/structure/wasteland_grid/repair_point/proc/_try_do_restart_action(mob/user)
	if(GLOB.wasteland_grid_restart_stage <= 0) return FALSE
	if(!GLOB.wasteland_grid_restart_operator || user.ckey != GLOB.wasteland_grid_restart_operator) return FALSE

	if(GLOB.wasteland_grid_restart_stage == 1 && repair_key == "breaker")
		user.visible_message(span_notice("[user] starts resetting the breakers..."), span_notice("You start resetting the breakers..."))
		if(do_after(user, 30, target = src))
			GLOB.wasteland_grid_restart_stage = 2
			_announce_grid("WASTELAND GRID: Breakers reset. Next: purge coolant at pump station.")
			_sync_wasteland_grid_reactor()
		return TRUE

	if(GLOB.wasteland_grid_restart_stage == 2 && repair_key == "coolant")
		user.visible_message(span_notice("[user] starts purging the coolant system..."), span_notice("You start purging the coolant system..."))
		if(do_after(user, 30, target = src))
			GLOB.wasteland_grid_restart_stage = 3
			_announce_grid("WASTELAND GRID: Coolant purged. Return to console to engage grid.")
			_sync_wasteland_grid_reactor()
		return TRUE

	return FALSE

/obj/structure/wasteland_grid/repair_point/proc/_find_matching_fault()
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed && F.repair_key == repair_key)
			return F
	return null

/obj/structure/wasteland_grid/repair_point/examine(mob/user)
	. = ..()
	_wasteland_grid_bootstrap()
	var/datum/wasteland_grid_fault/F = _find_matching_fault()
	if(F)
		. += span_warning("Active issue: [F.describe()]")
		. += span_notice("Required tool: [F.get_required_tool_text()]")
		. += span_notice("Required parts: [F.get_effective_reqs_text()]")
	else
		. += span_notice("No active faults detected here.")

/obj/structure/wasteland_grid/repair_point/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!user || !I) return ..()

	var/datum/wasteland_grid_fault/F = _find_matching_fault()
	if(!F)
		to_chat(user, span_notice("Nothing to fix here right now."))
		return TRUE

	if(F.required_tool && !istype(I, F.required_tool))
		to_chat(user, span_warning("Wrong tool. You need [F.get_required_tool_text()]."))
		return TRUE

	var/list/reqs = F.get_effective_reqs()
	if(reqs && reqs.len)
		if(!_grid_count_reqs_nearby(user, src, reqs))
			to_chat(user, span_warning("Missing parts. Need: [F.get_effective_reqs_text()]."))
			return TRUE

	user.visible_message(span_notice("[user] starts repairing [src]..."), span_notice("You start repairing [src]..."))
	if(do_after(user, 40, target = src))
		if(reqs && reqs.len)
			// re-check parts after delay
			if(!_grid_count_reqs_in_mob(user, reqs) && !_grid_count_reqs_nearby(user, src, reqs))
				to_chat(user, span_warning("Repair failed: parts missing after you started."))
				return TRUE

			// consume from nearby (inventory + floor)
			if(!_grid_consume_reqs_nearby(user, src, reqs))
				to_chat(user, span_warning("Repair failed: couldn't consume required parts."))
				return TRUE

		fix_grid_fault(F)
		to_chat(user, span_notice("Repair complete."))

		if(can_advance_restart)
			_try_advance_restart_from_repair_point(user)

	return TRUE

/obj/structure/wasteland_grid/repair_point/proc/_try_advance_restart_from_repair_point(mob/user)
	if(GLOB.wasteland_grid_restart_stage <= 0) return
	if(!GLOB.wasteland_grid_restart_operator || user.ckey != GLOB.wasteland_grid_restart_operator) return

	if(GLOB.wasteland_grid_restart_stage == 1 && repair_key == "breaker")
		GLOB.wasteland_grid_restart_stage = 2
		_announce_grid("WASTELAND GRID: Breakers reset. Next: purge coolant at pump station.")
		_sync_wasteland_grid_reactor()
		return

	if(GLOB.wasteland_grid_restart_stage == 2 && repair_key == "coolant")
		GLOB.wasteland_grid_restart_stage = 3
		_announce_grid("WASTELAND GRID: Coolant purged. Return to console to engage grid.")
		_sync_wasteland_grid_reactor()
		return

/obj/structure/wasteland_grid/breaker_panel
	parent_type = /obj/structure/wasteland_grid/repair_point
	name = "breaker panel"
	desc = "A crusty breaker cabinet. Smells like ozone."
	icon_state = "Breaker_cabinet_closed"
	repair_key = "breaker"

/obj/structure/wasteland_grid/breaker_panel/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_breaker_panels))
		GLOB.wasteland_grid_breaker_panels += src
	_sync_icon_state()

/obj/structure/wasteland_grid/breaker_panel/Destroy()
	GLOB.wasteland_grid_breaker_panels -= src
	return ..()

/obj/structure/wasteland_grid/breaker_panel/proc/_sync_icon_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		if(_grid_try_set_icon_state(src, list("Breaker_cabinet_destroyed", "Breaker_cabinet_open")))
			return
	var/needs_attention = FALSE
	if(_find_matching_fault())
		needs_attention = TRUE
	if(GLOB.wasteland_grid_restart_stage == 1)
		needs_attention = TRUE
	if(needs_attention)
		icon_state = "Breaker_cabinet_open"
	else
		icon_state = "Breaker_cabinet_closed"

/obj/structure/wasteland_grid/coolant_pump
	parent_type = /obj/structure/wasteland_grid/repair_point
	name = "coolant pump station"
	desc = "A pump manifold with valves and pressure gauges."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Primary_pump"
	pixel_x = -32
	pixel_y = -32
	repair_key = "coolant"
	var/__purge_doing = FALSE
	var/__purge_ticks_left = 0

/obj/structure/wasteland_grid/control_bus
	parent_type = /obj/structure/wasteland_grid/repair_point
	name = "control bus rack"
	desc = "A tangled rack of control cables and relays."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "comm_server_o"
	repair_key = "control"

///////////////////////////////////////////////////////////////
// V2 PHYSICAL PLANT OBJECTS
///////////////////////////////////////////////////////////////
/obj/structure/f13/grid_radiation_source
	name = "mass fusion reactor core"
	desc = "The reactor core housing. It hums when the grid is online."
	icon = 'fallout/eris/icons/128x128_reactor.dmi'
	icon_state = "Reactor_off"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	pixel_x = -48
	pixel_y = -48
	var/last_visual_state = null
	var/next_hum_at = 0

/obj/structure/f13/grid_radiation_source/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()
	GLOB.grid_rad_source = src
	sync_visual_and_audio(TRUE, FALSE)

/obj/structure/f13/grid_radiation_source/Destroy()
	if(GLOB.grid_rad_source == src)
		GLOB.grid_rad_source = null
	return ..()

/obj/structure/f13/grid_radiation_source/proc/_desired_visual_state()
	if(GLOB.grid_catastrophe_triggered)
		return "destroyed"
	if(GLOB.wasteland_grid_containment <= 15 || GLOB.wasteland_grid_integrity <= 15)
		return "destroyed"
	if(GLOB.wasteland_grid_online)
		return "on"
	return "off"

/obj/structure/f13/grid_radiation_source/proc/sync_visual_and_audio(force = FALSE, allow_sfx = TRUE)
	var/desired = _desired_visual_state()

	if(force || desired != last_visual_state)
		switch(desired)
			if("on")
				icon_state = "Reactor_on"
				set_light(6, 1.45, "#67FF72")
				if(allow_sfx && last_visual_state && last_visual_state != "on")
					playsound(src, 'sound/f13machines/generator_on.ogg', 60, FALSE)
				next_hum_at = world.time + 4 SECONDS
			if("destroyed")
				icon_state = "Reactor_destroyed"
				set_light(6, 1.5, "#FF9B3A")
				if(allow_sfx && last_visual_state == "on")
					playsound(src, 'sound/f13machines/generator_off.ogg', 55, FALSE)
			else
				icon_state = "Reactor_off"
				set_light(0)
				if(allow_sfx && last_visual_state == "on")
					playsound(src, 'sound/f13machines/generator_off.ogg', 55, FALSE)
		last_visual_state = desired

	if(desired != "on")
		return

	if(!SSticker || !SSticker.HasRoundStarted())
		return

	if(world.time < next_hum_at)
		return

	if(prob(34))
		playsound(src, 'sound/f13machines/engine_running1.ogg', 45, 1)
	else if(prob(50))
		playsound(src, 'sound/f13machines/engine_running2.ogg', 45, 1)
	else
		playsound(src, 'sound/f13machines/engine_running3.ogg', 45, 1)
	next_hum_at = world.time + rand(14 SECONDS, 20 SECONDS)

/obj/structure/grid/base
	name = "grid component"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/component_tag = null
	var/network_id = null

/obj/structure/grid/base/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()
	grid_register_component(src)
	if(network_id)
		var/datum/grid_network/N = grid_get_network(network_id)
		if(N && !N.nodes) N.nodes = list()
		if(N && !(src in N.nodes)) N.nodes += src

/obj/structure/grid/valve
	parent_type = /obj/structure/grid/base
	name = "valve"
	desc = "A manual valve with a crusty handwheel."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "coolant valve"
	pixel_x = -32
	pixel_y = -32
	var/valve_type = "coolant"  // "coolant"|"feedwater"|"relief"|"bypass"
	var/position = 50           // 0..100
	var/locked = FALSE
	var/stuck_chance = 0        // % (increases with wear)
	var/wear = 0                // 0..100

/obj/structure/grid/valve/examine(mob/user)
	. = ..()
	. += span_notice("Position: [position]%. Type: [valve_type].")
	if(locked) . += span_warning("It is locked.")

/obj/structure/grid/valve/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	if(locked)
		to_chat(user, span_warning("It's locked."))
		return TRUE

	var/newpos = input(user, "Set valve position (0-100)", "Valve") as null|num
	if(isnull(newpos)) return TRUE
	newpos = clamp(round(newpos), 0, 100)

	var/ch = clamp(stuck_chance + (wear / 5) + (GLOB.grid_wear_valves / 10), 0, 60)
	if(prob(ch))
		to_chat(user, span_warning("The valve binds and won't move properly."))
		wear = clamp(wear + 2, 0, 100)
		return TRUE

	position = newpos
	to_chat(user, span_notice("Valve set to [position]%."))
	wear = clamp(wear + 0.2, 0, 100)

	// apply to setpoints if configured
	if(valve_type == "coolant") GLOB.grid_sp_coolant_valve = position
	if(valve_type == "feedwater") GLOB.grid_sp_feedwater_valve = position
	if(valve_type == "relief") GLOB.grid_sp_relief_valve = position
	if(valve_type == "bypass") GLOB.grid_sp_bypass = position

	return TRUE

/obj/machinery/grid/pump
	name = "grid pump"
	desc = "A heavy pump. Sounds like it wants lubrication."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Main_Primary_Pump"
	pixel_x = -32
	pixel_y = -32
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/component_tag = null
	var/network_id = "primary"
	var/rpm = 60           // 0..100 (operator set locally)
	var/power = 1.0
	var/wear = 0           // 0..100
	var/cavitation = 0     // 0..100
	var/__purge_doing = FALSE

/obj/machinery/grid/pump/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()
	grid_register_component(src)
	var/datum/grid_network/N = grid_get_network(network_id)
	if(N && !(src in N.nodes)) N.nodes += src
	sync_visual_state()

/obj/machinery/grid/pump/proc/sync_visual_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		if(_grid_try_set_icon_state(src, list("Primary_pump_destroyed", "Main_Primary_Pump_destroyed", "Main_Primary_Pump_damaged", "Main_Primary_Pump_off")))
			set_light(3, 1.0, "#FF9B3A")
			return
	icon_state = "Main_Primary_Pump"
	if(GLOB.wasteland_grid_online)
		var/light_color = (GLOB.wasteland_grid_state == "RED") ? "#FF5656" : "#79E5FF"
		set_light(2, 0.65, light_color)
	else
		set_light(0)

/obj/machinery/grid/pump/examine(mob/user)
	. = ..()
	. += span_notice("RPM: [rpm]. Wear: [round(wear)]%. Cavitation: [round(cavitation)]%.")

/obj/machinery/grid/pump/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	var/newrpm = input(user, "Set pump RPM (0-100)\n(High RPM = more stress)", "Pump") as null|num
	if(isnull(newrpm)) return TRUE
	rpm = clamp(round(newrpm), 0, 100)
	to_chat(user, span_notice("Pump RPM set to [rpm]."))
	return TRUE

/obj/machinery/grid/pump/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	var/datum/grid_task/T = grid_task_find_for_obj(src)

	// basic pump service actions
	if(istype(I, /obj/item/wrench))
		user.visible_message(span_notice("[user] services the pump..."), span_notice("You service the pump..."))
		if(do_after(user, 35, target = src))
			// if task exists, require its parts then complete
			if(T && !T.completed)
				if(T.required_reqs && !_grid_count_reqs_nearby(user, src, T.required_reqs))
					to_chat(user, span_warning("Missing parts for maintenance (inventory or on the floor nearby)."))
					return TRUE
				if(T.required_reqs && !_grid_consume_reqs_nearby(user, src, T.required_reqs))
					to_chat(user, span_warning("Couldn't consume maintenance parts."))
					return TRUE
				grid_task_complete_by(user, T)


			// effects
			wear = max(0, wear - 10)
			GLOB.grid_wear_pump_primary = max(0, GLOB.grid_wear_pump_primary - 8)
			GLOB.grid_lube_level = clamp(GLOB.grid_lube_level + 20, 0, 100)
			cavitation = max(0, cavitation - 10)
			to_chat(user, span_notice("Pump serviced."))
		return TRUE

	return ..()

/obj/machinery/grid/pump/proc/_purge_finish_tick()
	// finish stage 2 if still valid
	if(!GLOB.grid_proc_purge_lock)
		__purge_doing = FALSE
		return

	if(GLOB.grid_proc_purge_stage != 2)
		__purge_doing = FALSE
		return

	if(rpm > 35)
		__purge_doing = FALSE
		return

	GLOB.grid_proc_purge_stage = 3
	__purge_doing = FALSE
	_announce_grid("GRID PROCEDURE: Low-RPM purge run complete. Next: CLOSE purge valve.")

/obj/structure/grid/relief_valve
	parent_type = /obj/structure/grid/base
	name = "relief valve"
	desc = "A safety relief valve. Lift test it or it will betray you."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Relief_valve"
	pixel_x = -32
	pixel_y = -32
	var/position = 0   // 0..100 (mapped to grid_sp_relief_valve)
	var/stuck_closed = FALSE
	var/stuck_open = FALSE

/obj/structure/grid/relief_valve/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_relief_valves))
		GLOB.wasteland_grid_relief_valves += src

/obj/structure/grid/relief_valve/Destroy()
	GLOB.wasteland_grid_relief_valves -= src
	return ..()

/obj/structure/grid/relief_valve/attack_hand(mob/user)
	_wasteland_grid_bootstrap()

	if(stuck_closed)
		to_chat(user, span_warning("It refuses to open."))
		return TRUE
	if(stuck_open)
		to_chat(user, span_warning("It's jammed open."))
		return TRUE

	var/newpos = input(user, "Set relief valve opening (0-100)", "Relief Valve") as null|num
	if(isnull(newpos)) return TRUE
	position = clamp(round(newpos), 0, 100)
	GLOB.grid_sp_relief_valve = position
	to_chat(user, span_notice("Relief valve set to [position]%."))
	return TRUE

/obj/structure/grid/relief_valve/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	// lift test / service
	if(istype(I, /obj/item/wrench))
		user.visible_message(span_notice("[user] performs a lift test..."), span_notice("You perform a lift test..."))
		if(do_after(user, 30, target = src))
			// chance to clear stuck state; chance to reveal fault
			if(stuck_closed && prob(60)) stuck_closed = FALSE
			if(stuck_open && prob(60)) stuck_open = FALSE

			// wear reduction
			GLOB.grid_wear_valves = max(0, GLOB.grid_wear_valves - 4)
			to_chat(user, span_notice("Lift test complete."))
		return TRUE

	return ..()

/obj/structure/grid/relief_valve/proc/sync_visual_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		_grid_try_set_icon_state(src, list("Relief_valve_destroyed", "Relief_valve_off", "Relief_valve"))
		set_light(2, 0.9, "#FF9B3A")
		return
	icon_state = "Relief_valve"
	if(GLOB.grid_primary_pressure >= 150 || GLOB.grid_sp_relief_valve >= 70)
		set_light(2, 0.75, "#FF5A5A")
	else
		set_light(0)

/obj/structure/grid/filter_unit
	parent_type = /obj/structure/grid/base
	name = "filter unit"
	desc = "A coolant filter skid. Ignore it and your coolant turns to soup."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Filter_unit"
	pixel_x = -32
	pixel_y = -32
	var/clog_local = 0 // optional per-unit view

/obj/structure/grid/filter_unit/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_filter_units))
		GLOB.wasteland_grid_filter_units += src

/obj/structure/grid/filter_unit/Destroy()
	GLOB.wasteland_grid_filter_units -= src
	return ..()

/obj/structure/grid/filter_unit/examine(mob/user)
	. = ..()
	. += span_notice("Global clog: [round(GLOB.grid_filter_clog)]%. Contamination: [round(GLOB.grid_coolant_contamination)]%.")

/obj/structure/grid/filter_unit/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	var/datum/grid_task/T = grid_task_find_for_obj(src)

	if(istype(I, /obj/item/screwdriver))
		user.visible_message(span_notice("[user] opens the filter housing..."), span_notice("You open the filter housing..."))
		if(do_after(user, 35, target = src))
			if(T && !T.completed)
				if(T.required_reqs && !_grid_count_reqs_nearby(user, src, T.required_reqs))
					to_chat(user, span_warning("Missing parts for filter replacement (inventory or nearby floor)."))
					return TRUE
				if(T.required_reqs && !_grid_consume_reqs_nearby(user, src, T.required_reqs))
					to_chat(user, span_warning("Couldn't consume maintenance parts."))
					return TRUE
				grid_task_complete_by(user, T)

			// effects
			GLOB.grid_filter_clog = max(0, GLOB.grid_filter_clog - 35)
			GLOB.grid_coolant_contamination = max(0, GLOB.grid_coolant_contamination - 15)
			to_chat(user, span_notice("Filters replaced."))
		return TRUE

	return ..()

/obj/structure/grid/filter_unit/proc/sync_visual_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		if(_grid_try_set_icon_state(src, list("Filter_unit_destroyed", "Filter_unit_off", "Filter_unit_damaged")))
			set_light(2, 0.95, "#FF9B3A")
			return
	icon_state = "Filter_unit"
	if(GLOB.wasteland_grid_online)
		var/filter_power = clamp(0.45 + ((100 - GLOB.grid_filter_clog) / 250), 0.35, 0.9)
		set_light(2, filter_power, "#76FF9B")
	else
		set_light(0)

/obj/structure/grid/heat_exchanger
	parent_type = /obj/structure/grid/base
	name = "heat exchanger"
	desc = "A battered exchanger. Descale it or steam quality drops."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Heat_exchanger"
	pixel_x = -32
	pixel_y = -32
	var/fouling = 10 // 0..100

/obj/structure/grid/heat_exchanger/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_heat_exchangers))
		GLOB.wasteland_grid_heat_exchangers += src

/obj/structure/grid/heat_exchanger/Destroy()
	GLOB.wasteland_grid_heat_exchangers -= src
	return ..()

/obj/structure/grid/heat_exchanger/examine(mob/user)
	. = ..()
	. += span_notice("Fouling: [round(fouling)]%. Steam quality: [GLOB.grid_steam_quality]%.")

/obj/structure/grid/heat_exchanger/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	if(istype(I, /obj/item/wrench))
		user.visible_message(span_notice("[user] flushes the exchanger..."), span_notice("You flush the exchanger..."))
		if(do_after(user, 40, target = src))
			fouling = max(0, fouling - 20)
			GLOB.grid_steam_quality = clamp(GLOB.grid_steam_quality + 5, 0, 100)
			to_chat(user, span_notice("Exchanger flushed."))
		return TRUE

	return ..()

/obj/structure/grid/heat_exchanger/proc/sync_visual_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		if(_grid_try_set_icon_state(src, list("Heat_exchanger_destroyed", "Heat_exchanger_off", "Heat_exchanger_damaged")))
			set_light(2, 0.95, "#FF9B3A")
			return
	icon_state = "Heat_exchanger"
	if(GLOB.wasteland_grid_online)
		var/exchanger_power = clamp(0.35 + (GLOB.grid_steam_quality / 220), 0.35, 0.85)
		set_light(2, exchanger_power, "#FFC470")
	else
		set_light(0)

/obj/structure/grid/turbine_assembly
	parent_type = /obj/structure/grid/base
	name = "turbine assembly"
	desc = "The main steam turbine train. It needs regular mechanical service."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Turbine_main"
	pixel_x = -32
	pixel_y = -32
	component_tag = "turbine_1"

/obj/structure/grid/turbine_assembly/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_turbine_assemblies))
		GLOB.wasteland_grid_turbine_assemblies += src
	sync_visual_state()

/obj/structure/grid/turbine_assembly/Destroy()
	GLOB.wasteland_grid_turbine_assemblies -= src
	return ..()

/obj/structure/grid/turbine_assembly/proc/sync_visual_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		if(_grid_try_set_icon_state(src, list("Turbine_destroyed", "Turbine_main_destroyed", "Turbine_main_damaged", "Turbine_main_off")))
			set_light(3, 1.0, "#FF9B3A")
			return
	icon_state = "Turbine_main"
	if(GLOB.wasteland_grid_online && GLOB.grid_turbine_rpm > 5)
		var/turbine_power = clamp(0.35 + (GLOB.grid_turbine_rpm / 150), 0.35, 1.0)
		var/turbine_color = (GLOB.grid_turbine_stress >= 70) ? "#FF6E6E" : "#A7D8FF"
		set_light(3, turbine_power, turbine_color)
	else
		set_light(0)

/obj/structure/grid/turbine_assembly/proc/_find_turbine_fault()
	_wasteland_grid_bootstrap()
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(!F || F.fixed) continue
		if(F.affects_component_tag && component_tag && F.affects_component_tag == component_tag)
			return F
	return null

/obj/structure/grid/turbine_assembly/examine(mob/user)
	. = ..()
	. += span_notice("RPM: [GLOB.grid_turbine_rpm]. Wear: [round(GLOB.grid_wear_turbine)]%. Stress: [round(GLOB.grid_turbine_stress)]%. Moisture: [round(GLOB.grid_turbine_moisture)]%.")
	. += span_notice("Control adjustments are made at the turbine controller console.")

	var/datum/wasteland_grid_fault/F = _find_turbine_fault()
	if(F)
		. += span_warning("Active issue: [F.describe()]")

	var/datum/grid_task/T = grid_task_find_for_obj(src)
	if(T && !T.completed)
		. += span_notice("Maintenance due: [T.describe()]")

/obj/structure/grid/turbine_assembly/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	if(!user) return TRUE

	var/datum/wasteland_grid_fault/F = _find_turbine_fault()
	if(F)
		to_chat(user, span_warning("Active issue: [F.describe()]"))
		to_chat(user, span_notice("Required tool: [F.get_required_tool_text()]"))
		to_chat(user, span_notice("Required parts: [F.get_effective_reqs_text()]"))
		return TRUE

	var/datum/grid_task/T = grid_task_find_for_obj(src)
	if(T && !T.completed)
		to_chat(user, span_notice("Maintenance due: [T.describe()]"))
		return TRUE

	to_chat(user, span_notice("The turbine assembly looks stable. Use a wrench to perform service when needed."))
	return TRUE

/obj/structure/grid/turbine_assembly/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	var/datum/wasteland_grid_fault/F = _find_turbine_fault()
	if(F)
		if(F.required_tool && !istype(I, F.required_tool))
			to_chat(user, span_warning("Wrong tool. You need [F.get_required_tool_text()]."))
			return TRUE

		var/list/fault_reqs = F.get_effective_reqs()
		if(fault_reqs && fault_reqs.len)
			if(!_grid_count_reqs_nearby(user, src, fault_reqs))
				to_chat(user, span_warning("Missing parts. Need: [F.get_effective_reqs_text()]."))
				return TRUE

		user.visible_message(span_notice("[user] starts repairing the turbine assembly..."), span_notice("You start repairing the turbine assembly..."))
		if(do_after(user, 45, target = src))
			if(fault_reqs && fault_reqs.len)
				if(!_grid_count_reqs_in_mob(user, fault_reqs) && !_grid_count_reqs_nearby(user, src, fault_reqs))
					to_chat(user, span_warning("Repair failed: parts missing after you started."))
					return TRUE
				if(!_grid_consume_reqs_nearby(user, src, fault_reqs))
					to_chat(user, span_warning("Repair failed: couldn't consume required parts."))
					return TRUE

			fix_grid_fault(F)
			GLOB.grid_wear_turbine = max(0, GLOB.grid_wear_turbine - 12)
			GLOB.grid_turbine_stress = max(0, GLOB.grid_turbine_stress - 16)
			GLOB.grid_turbine_moisture = max(0, GLOB.grid_turbine_moisture - 8)
			to_chat(user, span_notice("Turbine assembly repair complete."))
		return TRUE

	var/datum/grid_task/T = grid_task_find_for_obj(src)
	if(T && !T.completed)
		if(T.required_tool && !istype(I, T.required_tool))
			var/tool_txt = "[T.required_tool]"
			var/atom/A = T.required_tool
			if(A) tool_txt = initial(A.name)
			to_chat(user, span_warning("Wrong tool for maintenance. Need: [tool_txt]."))
			return TRUE

		if(T.required_reqs && !_grid_count_reqs_nearby(user, src, T.required_reqs))
			to_chat(user, span_warning("Missing maintenance parts (inventory or nearby floor)."))
			return TRUE

		user.visible_message(span_notice("[user] starts turbine maintenance..."), span_notice("You start turbine maintenance..."))
		if(do_after(user, 40, target = src))
			if(T.required_reqs && !_grid_count_reqs_in_mob(user, T.required_reqs) && !_grid_count_reqs_nearby(user, src, T.required_reqs))
				to_chat(user, span_warning("Maintenance failed: parts missing after you started."))
				return TRUE
			if(T.required_reqs && !_grid_consume_reqs_nearby(user, src, T.required_reqs))
				to_chat(user, span_warning("Maintenance failed: couldn't consume required parts."))
				return TRUE

			grid_task_complete_by(user, T)
			GLOB.grid_wear_turbine = max(0, GLOB.grid_wear_turbine - 10)
			GLOB.grid_turbine_stress = max(0, GLOB.grid_turbine_stress - 12)
			GLOB.grid_turbine_moisture = max(0, GLOB.grid_turbine_moisture - 6)
			to_chat(user, span_notice("Turbine maintenance complete."))
		return TRUE

	return ..()

/obj/machinery/grid/turbine_controller
	name = "turbine controller"
	desc = "Sets load and bypass. Overspeed this and it'll trip."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/component_tag = "turbine_ctrl_1"

/obj/machinery/grid/turbine_controller/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()
	grid_register_component(src)
	sync_visual_state()

/obj/machinery/grid/turbine_controller/proc/sync_visual_state()
	_wasteland_grid_bootstrap()
	if(GLOB.grid_catastrophe_triggered)
		if(_grid_try_set_icon_state(src, list("control_destroyed", "control_off")))
			set_light(2, 0.9, "#FF9B3A")
			return
	icon_state = "control_on"
	if(GLOB.wasteland_grid_online)
		var/ctrl_color = (GLOB.wasteland_grid_state == "RED") ? "#FF5E5E" : "#79C8FF"
		set_light(2, 0.5, ctrl_color)
	else
		set_light(0)

/obj/machinery/grid/turbine_controller/proc/_find_turbine_fault()
	_wasteland_grid_bootstrap()

	// Prefer faults that explicitly target this controller.
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(!F || F.fixed) continue
		if(F.affects_component_tag && component_tag && F.affects_component_tag == component_tag)
			return F

	// Compatibility fallback: if no dedicated turbine assembly exists on map,
	// let the controller handle turbine-tagged faults too.
	var/obj/structure/grid/turbine_assembly/TA = grid_get_component("turbine_1")
	if(!istype(TA))
		for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
			if(!F || F.fixed) continue
			if(F.repair_key == "turbine")
				return F

	return null

/obj/machinery/grid/turbine_controller/examine(mob/user)
	. = ..()
	. += span_notice("RPM: [GLOB.grid_turbine_rpm]. Wear: [round(GLOB.grid_wear_turbine)]%. Stress: [round(GLOB.grid_turbine_stress)]%.")

	var/datum/wasteland_grid_fault/F = _find_turbine_fault()
	if(F)
		. += span_warning("Active issue: [F.describe()]")

	var/datum/grid_task/T = grid_task_find_for_obj(src)
	if(T && !T.completed)
		. += span_notice("Maintenance due: [T.describe()]")

/obj/machinery/grid/turbine_controller/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	if(!user) return

	var/list/options = list()
	options += "Set target output"
	options += "Set turbine governor"
	options += "Set bypass valve"
	options += "Set feedwater valve"
	options += "Set boron ppm"
	options += "SCRAM"
	options += "Close"

	var/msg = "Turbine/Load Control\nOutput: [GLOB.grid_output]% (Target: [GLOB.grid_sp_target_output]%)\nRPM: [GLOB.grid_turbine_rpm] (Governor [GLOB.grid_sp_turbine_governor]%)\nBypass: [GLOB.grid_sp_bypass]%\nFeedwater: [GLOB.grid_sp_feedwater_valve]%\nBoron: [GLOB.grid_boron_ppm] ppm"
	var/c = input(user, msg, "Turbine Controller") as null|anything in options
	if(!c || c == "Close") return

	if(c == "Set target output")
		var/v = input(user, "Target output (0-100)", "Target") as null|num
		if(!isnull(v)) GLOB.grid_sp_target_output = clamp(round(v), 0, 100)

	if(c == "Set turbine governor")
		var/vg = input(user, "Turbine governor demand (0-100)\nHigher allows higher RPM.", "Governor") as null|num
		if(!isnull(vg)) GLOB.grid_sp_turbine_governor = clamp(round(vg), 0, 100)

	if(c == "Set bypass valve")
		var/v2 = input(user, "Bypass (0-100)\nHigher dumps steam (safer, less output).", "Bypass") as null|num
		if(!isnull(v2)) GLOB.grid_sp_bypass = clamp(round(v2), 0, 100)

	if(c == "Set feedwater valve")
		var/v3 = input(user, "Feedwater (0-100)", "Feedwater") as null|num
		if(!isnull(v3)) GLOB.grid_sp_feedwater_valve = clamp(round(v3), 0, 100)

	if(c == "Set boron ppm")
		var/vb = input(user, "Boron setpoint ppm (0-2000)\nHigher boron suppresses reactivity.", "Boron") as null|num
		if(!isnull(vb)) GLOB.grid_sp_boron_ppm = clamp(round(vb), 0, 2000)

	if(c == "SCRAM")
		GLOB.grid_scram = TRUE
		_announce_grid("WASTELAND GRID: SCRAM triggered by [user]!")

/obj/machinery/grid/turbine_controller/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	var/datum/wasteland_grid_fault/F = _find_turbine_fault()
	if(F)
		if(F.required_tool && !istype(I, F.required_tool))
			to_chat(user, span_warning("Wrong tool. You need [F.get_required_tool_text()]."))
			return TRUE

		var/list/fault_reqs = F.get_effective_reqs()
		if(fault_reqs && fault_reqs.len)
			if(!_grid_count_reqs_nearby(user, src, fault_reqs))
				to_chat(user, span_warning("Missing parts. Need: [F.get_effective_reqs_text()]."))
				return TRUE

		user.visible_message(span_notice("[user] starts servicing the turbine controller..."), span_notice("You start servicing the turbine controller..."))
		if(do_after(user, 40, target = src))
			if(fault_reqs && fault_reqs.len)
				if(!_grid_count_reqs_in_mob(user, fault_reqs) && !_grid_count_reqs_nearby(user, src, fault_reqs))
					to_chat(user, span_warning("Repair failed: parts missing after you started."))
					return TRUE
				if(!_grid_consume_reqs_nearby(user, src, fault_reqs))
					to_chat(user, span_warning("Repair failed: couldn't consume required parts."))
					return TRUE

			fix_grid_fault(F)
			GLOB.grid_wear_turbine = max(0, GLOB.grid_wear_turbine - 8)
			GLOB.grid_turbine_stress = max(0, GLOB.grid_turbine_stress - 15)
			GLOB.grid_turbine_moisture = max(0, GLOB.grid_turbine_moisture - 8)
			to_chat(user, span_notice("Turbine repair complete."))
		return TRUE

	var/datum/grid_task/T = grid_task_find_for_obj(src)
	if(T && !T.completed)
		if(T.required_tool && !istype(I, T.required_tool))
			var/tool_txt = "[T.required_tool]"
			var/atom/A = T.required_tool
			if(A) tool_txt = initial(A.name)
			to_chat(user, span_warning("Wrong tool for maintenance. Need: [tool_txt]."))
			return TRUE

		if(T.required_reqs && !_grid_count_reqs_nearby(user, src, T.required_reqs))
			to_chat(user, span_warning("Missing maintenance parts (inventory or nearby floor)."))
			return TRUE

		user.visible_message(span_notice("[user] starts turbine maintenance..."), span_notice("You start turbine maintenance..."))
		if(do_after(user, 35, target = src))
			if(T.required_reqs && !_grid_count_reqs_in_mob(user, T.required_reqs) && !_grid_count_reqs_nearby(user, src, T.required_reqs))
				to_chat(user, span_warning("Maintenance failed: parts missing after you started."))
				return TRUE
			if(T.required_reqs && !_grid_consume_reqs_nearby(user, src, T.required_reqs))
				to_chat(user, span_warning("Maintenance failed: couldn't consume required parts."))
				return TRUE

			grid_task_complete_by(user, T)
			GLOB.grid_wear_turbine = max(0, GLOB.grid_wear_turbine - 10)
			GLOB.grid_turbine_stress = max(0, GLOB.grid_turbine_stress - 12)
			GLOB.grid_turbine_moisture = max(0, GLOB.grid_turbine_moisture - 6)
			to_chat(user, span_notice("Turbine maintenance complete."))
		return TRUE

	return ..()

/obj/structure/grid/sensor_panel
	parent_type = /obj/structure/grid/base
	name = "instrumentation panel"
	desc = "Calibration bay. Drift lives here."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "comm_server_o"

/obj/structure/grid/sensor_panel/examine(mob/user)
	. = ..()
	. += span_notice("Sensor health: [GLOB.grid_sensor_health]%. Drift(H/P/F): [round(GLOB.grid_sensor_drift_heat)] / [round(GLOB.grid_sensor_drift_press)] / [round(GLOB.grid_sensor_drift_flow)].")

/obj/structure/grid/sensor_panel/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	if(!user) return TRUE

	var/msg = "Instrumentation\nHealth: [GLOB.grid_sensor_health]%\nDrift heat: [GLOB.grid_sensor_drift_heat]\nDrift press: [GLOB.grid_sensor_drift_press]\nDrift flow: [GLOB.grid_sensor_drift_flow]"
	to_chat(user, span_notice("[msg]"))
	to_chat(user, span_notice("Use a screwdriver to run calibration (consumes parts if maintenance task exists)."))
	return TRUE

/obj/structure/grid/sensor_panel/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user) return ..()

	var/datum/grid_task/T = grid_task_find_for_obj(src)

	if(istype(I, /obj/item/screwdriver))
		user.visible_message(span_notice("[user] runs the calibration routine..."), span_notice("You run the calibration routine..."))
		if(do_after(user, 35, target = src))
			if(T && !T.completed)
				if(T.required_reqs && !_grid_count_reqs_nearby(user, src, T.required_reqs))
					to_chat(user, span_warning("Missing calibration parts (inventory or nearby floor)."))
					return TRUE
				if(T.required_reqs && !_grid_consume_reqs_nearby(user, src, T.required_reqs))
					to_chat(user, span_warning("Couldn't consume calibration parts."))
					return TRUE
				grid_task_complete_by(user, T)


			GLOB.grid_sensor_drift_heat = 0
			GLOB.grid_sensor_drift_press = 0
			GLOB.grid_sensor_drift_flow = 0
			GLOB.grid_wear_sensors = max(0, GLOB.grid_wear_sensors - 10)
			to_chat(user, span_notice("Calibration complete. Drift reset."))
		return TRUE

	return ..()

/obj/structure/grid/power_relay
	parent_type = /obj/structure/grid/base
	name = "district power relay"
	desc = "A high-voltage relay node feeding one faction district. Sabotage this to hard-cut that district."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	var/district = null
	max_integrity = 100
	var/integrity = 100
	var/sabotaged = FALSE

/obj/structure/grid/power_relay/Initialize()
	. = ..()
	var/d = get_district_id()
	if(d)
		GLOB.wasteland_grid_relays_by_district[d] = src
	_sync_icon_state()
	_grid_reconcile_district_power()

/obj/structure/grid/power_relay/Destroy()
	var/d = get_district_id()
	if(d && GLOB.wasteland_grid_relays_by_district[d] == src)
		GLOB.wasteland_grid_relays_by_district[d] = null
	_grid_reconcile_district_power()
	return ..()

/obj/structure/grid/power_relay/proc/get_district_id()
	if(istext(district) && district)
		return district
	var/area/A = get_area(src)
	return _grid_get_area_district(A)

/obj/structure/grid/power_relay/proc/is_online()
	return (!sabotaged && integrity > 0)

/obj/structure/grid/power_relay/proc/_sync_icon_state()
	icon_state = is_online() ? "control_on" : "control_off"

/obj/structure/grid/power_relay/proc/set_sabotaged(state = TRUE, reason = null)
	sabotaged = !!state
	if(sabotaged)
		integrity = min(integrity, 35)
	_sync_icon_state()
	_grid_reconcile_district_power()
	var/d = get_district_id()
	if(reason && d)
		_announce_grid("WASTELAND GRID: Relay [d] [reason].")

/obj/structure/grid/power_relay/examine(mob/user)
	. = ..()
	var/d = get_district_id()
	. += span_notice("District: [d ? d : "unassigned"] | State: [is_online() ? "ONLINE" : "OFFLINE"] | Integrity: [round(integrity)]%")
	if(sabotaged)
		. += span_warning("Sabotaged: requires engineering repair.")

/obj/structure/grid/power_relay/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	var/d = get_district_id()
	to_chat(user, span_notice("Relay [d ? d : "UNASSIGNED"] status: [is_online() ? "ONLINE" : "OFFLINE"] | Integrity [round(integrity)]%."))
	if(sabotaged)
		to_chat(user, span_warning("Sabotaged. Use a welder to patch internals and restore service."))
	return TRUE

/obj/structure/grid/power_relay/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user)
		return ..()

	if(istype(I, /obj/item/wirecutters) || istype(I, /obj/item/screwdriver))
		if(sabotaged)
			to_chat(user, span_warning("Relay is already sabotaged."))
			return TRUE
		user.visible_message(span_warning("[user] starts tampering with the relay internals!"), span_warning("You start sabotaging the relay..."))
		if(do_after(user, 35, target = src))
			set_sabotaged(TRUE, "was sabotaged")
			to_chat(user, span_warning("You sabotage the district relay."))
		return TRUE

	if(istype(I, /obj/item/weldingtool))
		var/obj/item/weldingtool/W = I
		if(!W.tool_start_check(user, amount=1))
			return TRUE
		user.visible_message(span_notice("[user] starts repairing the relay."), span_notice("You start repairing the relay..."))
		if(do_after(user, 45, target = src) && W.use_tool(src, user, 0, amount=1))
			integrity = clamp(integrity + 45, 0, max_integrity)
			if(integrity >= 60)
				set_sabotaged(FALSE, "was restored")
			else
				_sync_icon_state()
				_grid_reconcile_district_power()
			to_chat(user, span_notice("Relay repaired to [round(integrity)]% integrity."))
		return TRUE

	if(istype(I, /obj/item/wrench))
		if(sabotaged)
			to_chat(user, span_warning("Mechanical reset failed: relay is sabotaged. Repair first."))
			return TRUE
		user.visible_message(span_notice("[user] reseats relay contacts."), span_notice("You reseat relay contacts."))
		integrity = clamp(integrity + 8, 0, max_integrity)
		_sync_icon_state()
		_grid_reconcile_district_power()
		return TRUE

	return ..()

/obj/structure/grid/relay_tower
	parent_type = /obj/structure/grid/base
	name = "relay tower"
	desc = "A tall transmission tower from the old world. Decorative, but imposing."
	icon = 'icons/Relay_Tower.dmi'
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/grid/backup_generator
	parent_type = /obj/structure/grid/base
	name = "district backup generator"
	desc = "A uranium-hungry emergency generator that can keep one district powered if the main grid drops."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "Backup_Generator"
	pixel_x = -32
	pixel_y = -32
	var/district = null
	var/active = FALSE
	var/fuel = 0
	var/max_fuel = GRID_BACKUP_FUEL_CAP
	var/next_fuel_drain_at = 0

/obj/structure/grid/backup_generator/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_backup_generators))
		GLOB.wasteland_grid_backup_generators += src
	sync_visual_state()

/obj/structure/grid/backup_generator/Destroy()
	var/was_active = is_active()
	GLOB.wasteland_grid_backup_generators -= src
	if(was_active)
		_grid_reconcile_district_power()
	return ..()

/obj/structure/grid/backup_generator/proc/get_district_id()
	if(istext(district) && district)
		return district
	return _grid_get_area_district(get_area(src))

/obj/structure/grid/backup_generator/proc/is_active()
	return (active && fuel >= GRID_BACKUP_MIN_ACTIVE_FUEL)

/obj/structure/grid/backup_generator/proc/sync_visual_state()
	if(is_active())
		if(_grid_try_set_icon_state(src, list("Backup_Generator_on", "Backup_Generator_active", "Backup_Generator")))
			set_light(3, 0.95, "#FFB85C")
			return
	else
		if(_grid_try_set_icon_state(src, list("Backup_Generator_off", "Backup_Generator")))
			set_light(0)
			return
	icon_state = "Backup_Generator"
	if(is_active())
		set_light(3, 0.95, "#FFB85C")
	else
		set_light(0)

/obj/structure/grid/backup_generator/proc/start_generator()
	if(fuel < GRID_BACKUP_MIN_ACTIVE_FUEL)
		return FALSE
	active = TRUE
	next_fuel_drain_at = world.time + GRID_BACKUP_FUEL_DRAIN_INTERVAL
	sync_visual_state()
	return TRUE

/obj/structure/grid/backup_generator/proc/stop_generator()
	var/was_active = is_active()
	active = FALSE
	sync_visual_state()
	return was_active

/obj/structure/grid/backup_generator/proc/tick_fuel()
	if(!active)
		return FALSE

	var/was_active = is_active()
	if(fuel < GRID_BACKUP_MIN_ACTIVE_FUEL)
		active = FALSE
		sync_visual_state()
		return was_active

	if(world.time < next_fuel_drain_at)
		return FALSE

	fuel = max(0, fuel - 1)
	next_fuel_drain_at = world.time + GRID_BACKUP_FUEL_DRAIN_INTERVAL

	var/is_now_active = (active && fuel >= GRID_BACKUP_MIN_ACTIVE_FUEL)
	if(!is_now_active)
		active = FALSE

	if(was_active != is_now_active)
		sync_visual_state()
		return TRUE
	return FALSE

/obj/structure/grid/backup_generator/examine(mob/user)
	. = ..()
	var/d = get_district_id()
	. += span_notice("District: [d ? d : "unassigned"] | State: [is_active() ? "ONLINE" : "OFFLINE"] | Fuel: [fuel]/[max_fuel]")
	. += span_notice("Fuel type: uranium sheets. 1 sheet -> [GRID_BACKUP_FUEL_PER_URANIUM_SHEET] fuel.")

/obj/structure/grid/backup_generator/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	var/d = get_district_id()
	var/status = is_active() ? "ONLINE" : "OFFLINE"
	var/fuel_txt = "[fuel]/[max_fuel]"
	var/msg = "District: [d ? d : "UNASSIGNED"]\nState: [status]\nFuel: [fuel_txt]\n\nStart/stop this backup generator?"
	var/choice = alert(user, msg, "Backup Generator", is_active() ? "Shut Down" : "Start", "Cancel")
	if(choice == "Cancel")
		return TRUE
	if(choice == "Start")
		if(!start_generator())
			to_chat(user, span_warning("No usable fuel. Insert uranium sheets first."))
			return TRUE
		to_chat(user, span_notice("Backup generator started."))
		_grid_reconcile_district_power()
		return TRUE
	if(choice == "Shut Down")
		if(stop_generator())
			_grid_reconcile_district_power()
		to_chat(user, span_notice("Backup generator shut down."))
		return TRUE
	return TRUE

/obj/structure/grid/backup_generator/attackby(obj/item/I, mob/user, params)
	_wasteland_grid_bootstrap()
	if(!I || !user)
		return ..()

	if(istype(I, /obj/item/stack/sheet/mineral/uranium))
		var/obj/item/stack/sheet/mineral/uranium/U = I
		if(fuel >= max_fuel)
			to_chat(user, span_warning("Fuel tank is already full."))
			return TRUE
		var/fuel_need = max_fuel - fuel
		var/need_sheets = round((fuel_need + GRID_BACKUP_FUEL_PER_URANIUM_SHEET - 1) / GRID_BACKUP_FUEL_PER_URANIUM_SHEET)
		var/take = min(U.amount, need_sheets)
		if(take <= 0)
			to_chat(user, span_warning("No uranium fuel to insert."))
			return TRUE
		U.use(take)
		fuel = clamp(fuel + (take * GRID_BACKUP_FUEL_PER_URANIUM_SHEET), 0, max_fuel)
		to_chat(user, span_notice("Loaded [take] uranium sheet(s). Fuel: [fuel]/[max_fuel]."))
		sync_visual_state()
		return TRUE

	return ..()

/obj/structure/grid/relay_breaker_box
	parent_type = /obj/structure/grid/base
	name = "relay breaker box"
	desc = "Local isolation breaker for a district relay."
	icon = 'fallout/eris/icons/Reactor_32x32.dmi'
	icon_state = "Breaker_cabinet_closed"
	var/district = null

/obj/structure/grid/relay_breaker_box/proc/get_district_id()
	if(istext(district) && district)
		return district
	return _grid_get_area_district(get_area(src))

/obj/structure/grid/relay_breaker_box/proc/_sync_icon_state()
	var/d = get_district_id()
	var/is_out = (d && !_grid_is_district_on(d))
	icon_state = is_out ? "Breaker_cabinet_open" : "Breaker_cabinet_closed"

/obj/structure/grid/relay_breaker_box/examine(mob/user)
	. = ..()
	var/d = get_district_id()
	. += span_notice("District: [d ? d : "unassigned"] | Breaker: [d && _grid_is_district_on(d) ? "CLOSED" : "OPEN"]")

/obj/structure/grid/relay_breaker_box/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	var/d = get_district_id()
	if(!d)
		to_chat(user, span_warning("No district assigned."))
		return TRUE
	var/choice = alert(user, "Breaker control for [d].", "Relay Breaker", "Close / Route ON", "Open / Force OFF", "Cancel")
	if(choice == "Close / Route ON")
		_grid_set_district_forced(d, FALSE)
		_announce_grid("WASTELAND GRID: [d] relay breaker closed by [user].")
	if(choice == "Open / Force OFF")
		_grid_set_district_forced(d, TRUE)
		_announce_grid("WASTELAND GRID: [d] relay breaker opened by [user].")
	_sync_icon_state()
	return TRUE

/obj/structure/grid/breaker_cabinet
	parent_type = /obj/structure/grid/base
	name = "breaker cabinet"
	desc = "High-current breakers. District load lives here."
	icon = 'fallout/eris/icons/Reactor_32x32.dmi'
	icon_state = "Breaker_cabinet_closed"
	var/district = null

/obj/structure/grid/breaker_cabinet/Initialize()
	. = ..()
	if(!(src in GLOB.wasteland_grid_breaker_cabinets))
		GLOB.wasteland_grid_breaker_cabinets += src
	_sync_icon_state()

/obj/structure/grid/breaker_cabinet/Destroy()
	GLOB.wasteland_grid_breaker_cabinets -= src
	return ..()

/obj/structure/grid/breaker_cabinet/proc/_sync_icon_state()
	var/is_out = FALSE
	if(district)
		is_out = !_grid_is_district_on(district)
	if(is_out)
		icon_state = "Breaker_cabinet_open"
	else
		icon_state = "Breaker_cabinet_closed"

/obj/structure/grid/breaker_cabinet/examine(mob/user)
	. = ..()
	. += span_notice("District: [(district ? district : "unassigned")]. Breaker wear: [round(GLOB.grid_wear_breakers)]%.")

/obj/structure/grid/breaker_cabinet/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	_sync_icon_state()
	if(!district)
		to_chat(user, span_notice("This cabinet isn't assigned a district. Set district var on the map if you want local control."))
		return TRUE

	var/on = _grid_is_district_on(district)
	to_chat(user, span_notice("District [district] power is currently: [(on ? "ON" : "OFF (rolling outage)")]"))
	return TRUE

/obj/structure/grid/district_controller
	parent_type = /obj/structure/grid/base
	name = "district load controller"
	desc = "Routes reactor power to a specific district without touching the full grid."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	var/district = null
	var/default_outage_seconds = 90

/obj/structure/grid/district_controller/proc/get_district_id()
	if(istext(district) && district)
		return district
	var/area/A = get_area(src)
	var/inferred = _grid_get_area_district(A)
	if(inferred)
		return inferred
	if(SSfaction_control)
		return SSfaction_control.get_district_for_atom(src)
	return null

/obj/structure/grid/district_controller/examine(mob/user)
	. = ..()
	var/d = get_district_id()
	if(!d)
		. += span_warning("District: unassigned. Set district var, map area.grid_district, or place this in NCR/BOS/Legion/Town areas.")
		return
	var/on = _grid_is_district_on(d)
	var/forced = !!GLOB.wasteland_grid_district_forced_off[d]
	var/t = GLOB.wasteland_grid_district_off_until[d]
	var/remaining = (t && t > world.time) ? round((t - world.time) / 10) : 0
	. += span_notice("District: [d] | Routed: [(on ? "ON" : "OFF")]")
	if(forced)
		. += span_warning("Mode: FORCED OFF")
	else if(remaining > 0)
		. += span_notice("Mode: timed outage ([remaining]s remaining)")
	else
		. += span_notice("Mode: normal routing")

/obj/structure/grid/district_controller/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	var/d = get_district_id()
	if(!d)
		to_chat(user, span_warning("No district assigned. Set district var, map area.grid_district, or place this in NCR/BOS/Legion/Town areas."))
		return TRUE

	var/on = _grid_is_district_on(d)
	var/forced = !!GLOB.wasteland_grid_district_forced_off[d]
	var/t = GLOB.wasteland_grid_district_off_until[d]
	var/remaining = (t && t > world.time) ? round((t - world.time) / 10) : 0
	var/msg = "District: [d]\nCurrent route: [(on ? "ON" : "OFF")]\nMode: "
	if(forced)
		msg += "FORCED OFF"
	else if(remaining > 0)
		msg += "Timed outage ([remaining]s)"
	else
		msg += "Normal"

	var/choice = alert(user, msg, "District Load Controller", "Route ON", "Route OFF", "Timed Outage")
	switch(choice)
		if("Route ON")
			_grid_set_district_forced(d, FALSE)
			_announce_grid("WASTELAND GRID: District [d] routed ON by [user].")
		if("Route OFF")
			_grid_set_district_forced(d, TRUE)
			_announce_grid("WASTELAND GRID: District [d] routed OFF by [user].")
		if("Timed Outage")
			var/raw = input(user, "Timed outage length in seconds (15-600).", "Timed Outage", default_outage_seconds) as null|num
			if(isnull(raw))
				return TRUE
			var/dur_s = clamp(round(raw), 15, 600)
			_grid_set_district_forced(d, FALSE)
			_grid_set_district_off(d, dur_s * 10)
			_announce_grid("WASTELAND GRID: District [d] outage scheduled for [dur_s]s by [user].")
	return TRUE

/obj/machinery/f13/grid_relay_console
	name = "relay operations console"
	desc = "Monitors and controls one district power relay."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE
	var/district = null

/obj/machinery/f13/grid_relay_console/bos
	name = "BOS relay console"
	district = "BOS"

/obj/machinery/f13/grid_relay_console/ncr
	name = "NCR relay console"
	district = "NCR"

/obj/machinery/f13/grid_relay_console/legion
	name = "Legion relay console"
	district = "Legion"

/obj/machinery/f13/grid_relay_console/town
	name = "Town relay console"
	district = "Town"

/obj/machinery/f13/grid_relay_console/massfusion
	name = "Mass Fusion relay console"
	district = "Mass Fusion"

/obj/machinery/f13/grid_relay_console/power_change()
	. = ..()
	stat &= ~NOPOWER
	icon_state = "control_on"

/obj/machinery/f13/grid_relay_console/proc/get_district_id()
	if(istext(district) && district)
		return district
	return _grid_get_area_district(get_area(src))

/obj/machinery/f13/grid_relay_console/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	var/d = get_district_id()
	if(!d)
		to_chat(user, span_warning("No district assigned for this console."))
		return TRUE
	var/obj/structure/grid/power_relay/R = _grid_get_relay_for_district(d)
	var/relay_state = R ? (R.is_online() ? "ONLINE" : "OFFLINE") : "MISSING"
	var/power_state = _grid_is_district_on(d) ? "ON" : "OFF"
	var/msg = "District: [d]\nRelay: [relay_state]\nDistrict power: [power_state]"
	var/choice = alert(user, msg, "Relay Operations", "Run Diagnostics", "Remote Reset", "Cancel")
	if(choice == "Run Diagnostics")
		if(!R)
			to_chat(user, span_warning("No relay found for [d]."))
		else
			to_chat(user, span_notice("Relay [d] integrity [round(R.integrity)]%, sabotaged: [R.sabotaged ? "YES" : "NO"]."))
		return TRUE
	if(choice == "Remote Reset")
		if(!R)
			to_chat(user, span_warning("No relay found for [d]."))
			return TRUE
		if(R.sabotaged)
			to_chat(user, span_warning("Remote reset failed: relay sabotaged. Send engineers."))
			return TRUE
		R.integrity = clamp(R.integrity + 15, 0, R.max_integrity)
		R._sync_icon_state()
		_grid_set_district_forced(d, FALSE)
		_grid_reconcile_district_power()
		to_chat(user, span_notice("Remote reset complete for [d]."))
		return TRUE
	return TRUE

/obj/machinery/f13/grid_faction_district_console
	name = "district dispatch console"
	desc = "Reactor-side console for routing BOS, NCR, Legion, Town, and Mass Fusion district power."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE
	var/default_outage_seconds = 90
	var/list/faction_districts = list(
		"BOS" = "BOS",
		"NCR" = "NCR",
		"Legion" = "Legion",
		"Town" = "Town",
		"Mass Fusion" = "Mass Fusion"
	)

/obj/machinery/f13/grid_faction_district_console/bos
	name = "BOS district console"
	faction_districts = list("BOS" = "BOS")

/obj/machinery/f13/grid_faction_district_console/ncr
	name = "NCR district console"
	faction_districts = list("NCR" = "NCR")

/obj/machinery/f13/grid_faction_district_console/legion
	name = "Legion district console"
	faction_districts = list("Legion" = "Legion")

/obj/machinery/f13/grid_faction_district_console/town
	name = "Town district console"
	faction_districts = list("Town" = "Town")

/obj/machinery/f13/grid_faction_district_console/massfusion
	name = "Mass Fusion district console"
	faction_districts = list("Mass Fusion" = "Mass Fusion")

/obj/machinery/f13/grid_faction_district_console/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()
	if(!islist(faction_districts))
		faction_districts = list()

/obj/machinery/f13/grid_faction_district_console/power_change()
	. = ..()
	stat &= ~NOPOWER
	icon_state = "control_on"

/obj/machinery/f13/grid_faction_district_console/proc/get_district_for_faction(faction_name)
	if(!istext(faction_name) || !faction_name)
		return null
	var/d = faction_districts[faction_name]
	if(istext(d) && d)
		return d
	return faction_name

/obj/machinery/f13/grid_faction_district_console/proc/get_status_label(faction_name)
	var/d = get_district_for_faction(faction_name)
	if(!d)
		return "[faction_name]: Unassigned"
	var/on = _grid_is_district_on(d)
	var/forced = !!GLOB.wasteland_grid_district_forced_off[d]
	var/t = GLOB.wasteland_grid_district_off_until[d]
	var/remaining = (t && t > world.time) ? round((t - world.time) / 10) : 0
	if(forced)
		return "[faction_name]: OFF (forced)"
	if(remaining > 0)
		return "[faction_name]: OFF ([remaining]s timed)"
	return "[faction_name]: [(on ? "ON" : "OFF")]"

/obj/machinery/f13/grid_faction_district_console/examine(mob/user)
	. = ..()
	for(var/faction_name in faction_districts)
		var/d = get_district_for_faction(faction_name)
		. += span_notice("[faction_name] -> [d] | [get_status_label(faction_name)]")

/obj/machinery/f13/grid_faction_district_console/attack_hand(mob/user)
	. = ..()
	if(!user) return
	ui_interact(user, null)
	return TRUE

/obj/machinery/f13/grid_faction_district_console/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/f13/grid_faction_district_console/ui_data(mob/user)
	_wasteland_grid_bootstrap()
	var/list/data = list()
	var/list/rows = list()

	for(var/faction_name in faction_districts)
		var/d = get_district_for_faction(faction_name)
		var/on = _grid_is_district_on(d)
		var/forced = !!GLOB.wasteland_grid_district_forced_off[d]
		var/t = GLOB.wasteland_grid_district_off_until[d]
		var/remaining = (t && t > world.time) ? round((t - world.time) / 10) : 0

		rows += list(list(
			"faction" = faction_name,
			"district" = d,
			"routed_on" = !!on,
			"forced_off" = !!forced,
			"remaining_s" = remaining
		))

	data["online"] = !!GLOB.wasteland_grid_online
	data["state"] = GLOB.wasteland_grid_state
	data["rows"] = rows
	data["default_outage_s"] = default_outage_seconds
	return data

/obj/machinery/f13/grid_faction_district_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	_wasteland_grid_bootstrap()
	var/mob/user = ui?.user
	if(!user)
		user = usr
	if(!user)
		return FALSE

	var/faction_name = params["faction"]
	var/d = get_district_for_faction(faction_name)
	if(!istext(d) || !d)
		to_chat(user, span_warning("No district mapped for [faction_name]."))
		return TRUE

	switch(action)
		if("route_on")
			_grid_set_district_forced(d, FALSE)
			_announce_grid("WASTELAND GRID: [faction_name] district ([d]) routed ON by [user].")
			return TRUE
		if("route_off")
			_grid_set_district_forced(d, TRUE)
			_announce_grid("WASTELAND GRID: [faction_name] district ([d]) routed OFF by [user].")
			return TRUE
		if("timed_outage")
			var/raw = text2num(params["seconds"])
			var/dur_s = clamp(round(raw), 15, 600)
			_grid_set_district_forced(d, FALSE)
			_grid_set_district_off(d, dur_s * 10)
			_announce_grid("WASTELAND GRID: [faction_name] district ([d]) outage scheduled for [dur_s]s by [user].")
			return TRUE

	return FALSE

/obj/machinery/f13/grid_faction_district_console/ui_interact(mob/user, datum/tgui/ui)
	_wasteland_grid_bootstrap()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GridDistrictDispatch")
		ui.open()

/obj/structure/grid/purge_valve
	parent_type = /obj/structure/grid/base
	name = "purge valve"
	desc = "A purge valve for flushing contaminated coolant."
	icon = 'fallout/eris/icons/96x96.dmi'
	icon_state = "coolant valve"
	pixel_x = -32
	pixel_y = -32
	var/opened = FALSE

/obj/structure/grid/purge_valve/examine(mob/user)
	. = ..()
	. += span_notice("Status: [(opened ? "OPEN" : "CLOSED")]. Procedure stage: [GLOB.grid_proc_purge_stage].")

/obj/structure/grid/purge_valve/attack_hand(mob/user)
	_wasteland_grid_bootstrap()
	if(!user) return TRUE

	opened = !opened
	to_chat(user, span_notice("Purge valve [(opened ? "opened" : "closed")]."))

	// procedure step tracking
	if(GLOB.grid_proc_purge_stage == 1 && opened)
		GLOB.grid_proc_purge_stage = 2
		_announce_grid("GRID PROCEDURE: Purge valve open. Next: run the pump at LOW RPM for 30 seconds.")
	else if(GLOB.grid_proc_purge_stage == 3 && !opened)
		GLOB.grid_proc_purge_stage = 4
		_announce_grid("GRID PROCEDURE: Purge valve closed. Next: confirm pressure stable at console.")

	return TRUE

///////////////////////////////////////////////////////////////
// PROCEDURES (coolant purge)
///////////////////////////////////////////////////////////////

/proc/grid_start_coolant_purge(mob/user)
	_wasteland_grid_bootstrap()
	if(!user) return FALSE
	if(GLOB.grid_proc_purge_lock)
		to_chat(user, span_warning("A purge procedure is already running."))
		return FALSE

	GLOB.grid_proc_purge_lock = TRUE
	GLOB.grid_proc_purge_operator = user.ckey
	GLOB.grid_proc_purge_stage = 1
	GLOB.grid_proc_purge_started_at = world.time

	_announce_grid("GRID PROCEDURE START: Coolant purge initiated by [user]. Step 1: OPEN purge valve.")
	return TRUE

/proc/grid_abort_coolant_purge(reason)
	_wasteland_grid_bootstrap()
	GLOB.grid_proc_purge_lock = FALSE
	GLOB.grid_proc_purge_operator = null
	GLOB.grid_proc_purge_stage = 0
	GLOB.grid_proc_purge_started_at = 0
	if(reason) _announce_grid("GRID PROCEDURE ABORTED: [reason].")

/proc/grid_tick_procedures()
	if(!GLOB.grid_proc_purge_lock) return

	if(world.time - GLOB.grid_proc_purge_started_at > 5 MINUTES)
		grid_abort_coolant_purge("Purge timed out")
		return

	if(GLOB.grid_proc_purge_stage == 2)
		var/obj/machinery/grid/pump/P = grid_get_component("primary_pump_1")
		if(P && P.rpm <= 35)
			if(!P.__purge_doing)
				// FIX: don't use CALLBACK/PROC_REF from a global /proc (src is invalid here in this codebase)
				// Use a simple spawn() delay and call the pump's proc directly.
				P.__purge_doing = TRUE
				var/obj/machinery/grid/pump/P2 = P
				spawn(30 SECONDS)
					if(P2)
						P2._purge_finish_tick()

///////////////////////////////////////////////////////////////
// CONSOLE (expanded: readouts, controls, maintenance, procedures)
///////////////////////////////////////////////////////////////

/obj/machinery/f13/wasteland_grid_console
	name = "Mass Fusion grid console"
	desc = "Controls the wasteland electrical grid."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE

/obj/machinery/f13/wasteland_grid_console/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()

/obj/machinery/f13/wasteland_grid_console/power_change()
	. = ..()
	stat &= ~NOPOWER
	icon_state = "control_on"

/obj/machinery/f13/wasteland_grid_console/attack_hand(mob/user)
	. = ..()
	if(!user) return
	ui_interact(user, null)


/obj/machinery/f13/wasteland_grid_console/proc/_fault_report()
	var/text = ""
	var/any = FALSE
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed)
			any = TRUE
			text += " - [F.describe()]\n"
	if(!any) text = " - None\n"
	return text

/obj/machinery/f13/wasteland_grid_console/proc/_maint_report()
	var/t = ""
	var/any = FALSE
	for(var/datum/grid_task/M in GLOB.grid_maint_queue)
		if(M && !M.completed)
			any = TRUE
			t += " - [M.describe()]\n"
	if(!any) t = " - None\n"
	return t

/obj/machinery/f13/wasteland_grid_console/ui_data(mob/user)
	_wasteland_grid_bootstrap()

	var/list/data = list()

	// top-level
	data["online"] = !!GLOB.wasteland_grid_online
	data["state"] = GLOB.wasteland_grid_state
	data["bg_rads"] = GLOB.wasteland_grid_background_rads
	data["scram"] = !!GLOB.grid_scram
	data["interlocks"] = !!GLOB.grid_safety_interlocks_enabled
	data["catastrophe_risk"] = round(GLOB.grid_catastrophe_risk)
	data["catastrophe_triggered"] = !!GLOB.grid_catastrophe_triggered
	data["auto_enabled"] = !!GLOB.grid_auto_enabled
	data["auto_active"] = !!GLOB.grid_auto_active
	data["auto_threshold"] = GLOB.grid_auto_player_threshold
	data["active_players"] = _grid_get_active_players()
	data["fault_suppression_active"] = _grid_lowpop_suppression_active()
	data["fault_suppression_threshold"] = GLOB.grid_lowpop_faults_threshold
	var/can_debug = FALSE
	if(user && user.client && user.client.holder)
		can_debug = TRUE
	data["can_debug"] = can_debug
	data["debug_enabled"] = !!GLOB.grid_debug_controls_enabled

	// resources
	data["fuel"] = GLOB.wasteland_grid_fuel
	data["coolant"] = GLOB.wasteland_grid_coolant
	data["restart_stage"] = GLOB.wasteland_grid_restart_stage

	// process vars (send both actual + displayed/drifted if you want)
	data["heat_actual"] = GLOB.wasteland_grid_core_heat
	data["heat_disp"] = _read_heat_display()

	data["reactivity"] = GLOB.grid_core_reactivity
	data["flow_actual"] = GLOB.grid_primary_flow
	data["flow_disp"] = _read_flow_display()

	data["p_primary_actual"] = GLOB.grid_primary_pressure
	data["p_primary_disp"] = _read_press_display()

	data["p_secondary"] = GLOB.grid_secondary_pressure
	data["steam_q"] = GLOB.grid_steam_quality
	data["rpm"] = GLOB.grid_turbine_rpm
	data["output"] = GLOB.grid_output
	data["output_mw"] = _grid_get_export_mw_capacity()
	data["output_mw_max"] = _grid_get_export_mw_max()
	data["turbine_stress"] = round(GLOB.grid_turbine_stress)
	data["turbine_moisture"] = round(GLOB.grid_turbine_moisture)

	// advanced core model
	data["xenon"] = round(GLOB.grid_xenon_poison, 0.1)
	data["iodine"] = round(GLOB.grid_iodine_inventory, 0.1)
	data["samarium"] = round(GLOB.grid_samarium_poison, 0.1)
	data["burnup"] = round(GLOB.grid_fuel_burnup, 0.1)
	data["react_reserve"] = round(GLOB.grid_reactivity_reserve, 0.1)
	data["decay_heat"] = round(GLOB.grid_decay_heat, 0.1)
	data["boron"] = round(GLOB.grid_boron_ppm)
	data["doppler_coeff"] = round(GLOB.grid_doppler_coeff, 0.01)
	data["mtc_coeff"] = round(GLOB.grid_moderator_coeff, 0.01)
	data["subcool_margin"] = round(GLOB.grid_subcool_margin)
	data["npsh_margin"] = round(GLOB.grid_npsh_margin)
	data["pzr_level"] = round(GLOB.grid_pressurizer_level)
	data["condenser_vac"] = round(GLOB.grid_condenser_vacuum)
	data["hotwell"] = round(GLOB.grid_hotwell_level)

	// setpoints
	data["sp_rods"] = GLOB.grid_sp_rod_insertion
	data["sp_coolant_valve"] = GLOB.grid_sp_coolant_valve
	data["sp_feedwater"] = GLOB.grid_sp_feedwater_valve
	data["sp_relief"] = GLOB.grid_sp_relief_valve
	data["sp_bypass"] = GLOB.grid_sp_bypass
	data["sp_target"] = GLOB.grid_sp_target_output
	data["sp_turbine"] = GLOB.grid_sp_turbine_governor
	data["sp_boron"] = GLOB.grid_sp_boron_ppm

	// chemistry/wear
	data["contam"] = round(GLOB.grid_coolant_contamination)
	data["clog"] = round(GLOB.grid_filter_clog)
	data["lube"] = round(GLOB.grid_lube_level)

	data["wear_pump"] = round(GLOB.grid_wear_pump_primary)
	data["wear_valves"] = round(GLOB.grid_wear_valves)
	data["wear_turbine"] = round(GLOB.grid_wear_turbine)
	data["wear_breakers"] = round(GLOB.grid_wear_breakers)
	data["wear_sensors"] = round(GLOB.grid_wear_sensors)

	// faults list
	var/list/faults = list()
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(F && !F.fixed)
			faults += list(list(
				"id" = F.id,
				"name" = F.name,
				"sev" = F.severity,
				"loc" = F.location_hint,
				"cause" = F.cause,
				"needs_tool" = F.get_required_tool_text(),
				"needs_parts" = F.get_effective_reqs_text()
			))
	data["faults"] = faults

	// maintenance list
	var/list/maint = list()
	for(var/datum/grid_task/T in GLOB.grid_maint_queue)
		if(T && !T.completed)
			maint += list(list(
				"id" = T.id,
				"name" = T.name,
				"sev" = T.severity,
				"desc" = T.desc,
				"tag" = T.target_tag
			))
	data["maint"] = maint

	// procedure state
	data["purge_stage"] = GLOB.grid_proc_purge_stage
	data["purge_lock"] = !!GLOB.grid_proc_purge_lock

	// phase 1: upgrades, chemistry program, turbine overhaul
	data["plant_points"] = round(GLOB.grid_plant_upgrade_points)
	data["upg_stability"] = _grid_upgrade_level("stability")
	data["upg_peak_output"] = _grid_upgrade_level("peak_output")
	data["upg_automation"] = _grid_upgrade_level("automation")
	data["upg_safety"] = _grid_upgrade_level("safety")

	data["add_anticorrosion"] = round(GLOB.grid_add_anticorrosion)
	data["add_antifoam"] = round(GLOB.grid_add_antifoam)
	data["add_flowboost"] = round(GLOB.grid_add_flowboost)
	data["stock_anticorrosion"] = round(GLOB.grid_stock_anticorrosion)
	data["stock_antifoam"] = round(GLOB.grid_stock_antifoam)
	data["stock_flowboost"] = round(GLOB.grid_stock_flowboost)

	data["turbine_bearing_cond"] = round(GLOB.grid_turbine_bearing_cond)
	data["turbine_blade_cond"] = round(GLOB.grid_turbine_blade_cond)
	data["turbine_alignment_cond"] = round(GLOB.grid_turbine_alignment_cond)
	data["overhaul_active"] = !!GLOB.grid_overhaul_session["active"]
	data["overhaul_step"] = _grid_get_overhaul_step()
	var/overhaul_bonus_s = max(0, round((GLOB.grid_overhaul_bonus_until - world.time) / 10))
	data["overhaul_bonus_s"] = overhaul_bonus_s

	// phase 2: auctions + dispatch
	data["auction_round"] = round(GLOB.grid_auction_round_id)
	data["auction_open"] = (GLOB.grid_auction_open_until > world.time)
	data["auction_remaining_s"] = max(0, round((GLOB.grid_auction_open_until - world.time) / 10))
	data["auction_committed_mw"] = round(GLOB.grid_committed_mw)
	data["auction_base_supply_mw"] = _grid_get_export_mw_capacity()

	var/list/auction_bids = list()
	for(var/d in GLOB.grid_auction_bids)
		var/list/b = GLOB.grid_auction_bids[d]
		if(!islist(b))
			continue
		auction_bids += list(list(
			"district" = "[d]",
			"faction" = "[b["faction"]]",
			"request_mw" = round(b["request_mw"]),
			"bid_caps" = round(b["bid_caps"])
		))
	data["auction_bids"] = auction_bids

	var/list/alloc_rows = list()
	for(var/d2 in GLOB.grid_district_mw_alloc)
		alloc_rows += list(list(
			"district" = "[d2]",
			"mw" = round(GLOB.grid_district_mw_alloc[d2])
		))
	data["auction_allocs"] = alloc_rows
	data["auction_districts"] = _grid_get_dispatch_districts()

	var/list/dispatch = list()
	for(var/list/C in GLOB.grid_dispatch_calls)
		if(!islist(C))
			continue
		dispatch += list(list(
			"id" = "[C["id"]]",
			"type" = "[C["type"]]",
			"district" = "[C["district"]]",
			"sev" = round(C["severity"]),
			"desc" = "[C["desc"]]",
			"expires_s" = max(0, round((round(C["expires_at"]) - world.time) / 10)),
			"resolved" = !!C["resolved"]
		))
	data["dispatch_calls"] = dispatch

	// phase 3: spent fuel + theft/forensics
	data["spent_fuel_units"] = round(GLOB.grid_spent_fuel_units)
	data["casks_staged"] = round(GLOB.grid_casks_staged)
	data["casks_stored"] = round(GLOB.grid_casks_stored)
	data["casks_processed"] = round(GLOB.grid_casks_processed)
	data["waste_hazard"] = round(GLOB.grid_waste_hazard)

	data["theft_load_mw"] = round(GLOB.grid_theft_load_mw)
	data["forensics_ready"] = (world.time >= GLOB.grid_forensics_last_scan + GRID_FORENSICS_SCAN_COOLDOWN)
	var/list/theft_rows = list()
	for(var/d3 in _grid_get_dispatch_districts())
		theft_rows += list(list(
			"district" = "[d3]",
			"intensity" = round(GLOB.grid_theft_by_district[d3])
		))
	data["theft_rows"] = theft_rows

	return data
/obj/machinery/f13/wasteland_grid_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	_wasteland_grid_bootstrap()

	var/mob/user = ui?.user
	if(!user)
		user = usr

	switch(action)
		if("set_sp")
			var/key = params["key"]
			var/raw = text2num(params["val"])
			var/val = raw
			if(isnull(key)) return TRUE
			if(key == "boron")
				val = clamp(round(val), 0, 2000)
			else
				val = clamp(round(val), 0, 100)

			if(key == "rods") GLOB.grid_sp_rod_insertion = val
			else if(key == "coolant") GLOB.grid_sp_coolant_valve = val
			else if(key == "feedwater") GLOB.grid_sp_feedwater_valve = val
			else if(key == "relief") GLOB.grid_sp_relief_valve = val
			else if(key == "bypass") GLOB.grid_sp_bypass = val
			else if(key == "target") GLOB.grid_sp_target_output = val
			else if(key == "turbine") GLOB.grid_sp_turbine_governor = val
			else if(key == "boron") GLOB.grid_sp_boron_ppm = val
			return TRUE

		if("toggle_scram")
			GLOB.grid_scram = !GLOB.grid_scram
			if(GLOB.grid_scram)
				_announce_grid("WASTELAND GRID: SCRAM triggered by [user]!")
			else
				_announce_grid("WASTELAND GRID: SCRAM cleared by [user].")
			return TRUE

		if("toggle_interlocks")
			if(GLOB.grid_catastrophe_triggered)
				to_chat(user, "<span class='warning'>Safety system unavailable: core already destroyed.</span>")
				return TRUE

			GLOB.grid_safety_interlocks_enabled = !GLOB.grid_safety_interlocks_enabled
			if(GLOB.grid_safety_interlocks_enabled)
				GLOB.grid_catastrophe_risk = max(0, GLOB.grid_catastrophe_risk - 15)
				_announce_grid("WASTELAND GRID: Safety interlocks RE-ENABLED by [user].")
			else
				_announce_grid("WASTELAND GRID: WARNING - Safety interlocks DISABLED by [user].")
			return TRUE

		if("toggle_auto")
			GLOB.grid_auto_enabled = !GLOB.grid_auto_enabled
			if(!GLOB.grid_auto_enabled)
				GLOB.grid_auto_active = FALSE
				_announce_grid("WASTELAND GRID: Auto-operations disabled by [user].")
			else
				_announce_grid("WASTELAND GRID: Auto-operations enabled by [user].")
			return TRUE

		if("toggle_debug_controls")
			if(!user || !user.client || !user.client.holder)
				if(user)
					to_chat(user, span_warning("Debug controls are admin-only."))
				return TRUE
			GLOB.grid_debug_controls_enabled = !GLOB.grid_debug_controls_enabled
			if(GLOB.grid_debug_controls_enabled)
				_announce_grid("WASTELAND GRID: Debug controls ENABLED by [user].")
			else
				_announce_grid("WASTELAND GRID: Debug controls DISABLED by [user].")
			return TRUE

		if("debug_blow_reactor")
			if(!user || !user.client || !user.client.holder)
				if(user)
					to_chat(user, span_warning("Debug controls are admin-only."))
				return TRUE
			if(!GLOB.grid_debug_controls_enabled)
				to_chat(user, span_warning("Enable debug controls first."))
				return TRUE
			if(GLOB.grid_catastrophe_triggered)
				to_chat(user, span_warning("Core catastrophe already triggered."))
				return TRUE
			_announce_grid("WASTELAND GRID: DEBUG CATASTROPHE initiated by [user].")
			_trigger_grid_catastrophe("Manual debug detonation by [user]")
			return TRUE

		if("set_auto_threshold")
			var/raw_threshold = text2num(params["val"])
			GLOB.grid_auto_player_threshold = clamp(round(raw_threshold), 1, 120)
			return TRUE

		if("prime_restart")
			_prime_restart(user)
			return TRUE

		if("engage_restart")
			_engage_restart(user)
			return TRUE

		if("shutdown")
			_manual_shutdown(user)
			return TRUE

		if("start_purge")
			grid_start_coolant_purge(user)
			return TRUE

		if("abort_purge")
			grid_abort_coolant_purge("Aborted by operator")
			return TRUE

		if("buy_upgrade")
			var/key_up = params["key"]
			var/msg_up = _grid_buy_plant_upgrade(user, key_up)
			if(msg_up)
				to_chat(user, span_notice("[msg_up]"))
			return TRUE

		if("inject_additive")
			var/key_add = params["key"]
			var/amt_add = text2num(params["amt"])
			var/msg_add = _grid_apply_additive(user, key_add, amt_add)
			if(msg_add)
				to_chat(user, span_notice("[msg_add]"))
			return TRUE

		if("start_overhaul")
			var/msg_oh = _grid_start_overhaul(user)
			if(msg_oh)
				to_chat(user, span_notice("[msg_oh]"))
			return TRUE

		if("progress_overhaul")
			var/step = params["step"]
			var/msg_oh_step = _grid_progress_overhaul(user, step)
			if(msg_oh_step)
				to_chat(user, span_notice("[msg_oh_step]"))
			return TRUE

		if("bid_power")
			var/d = params["district"]
			var/mw = text2num(params["mw"])
			var/caps = text2num(params["caps"])
			var/msg_bid = _grid_submit_auction_bid(user, d, mw, caps)
			if(msg_bid)
				to_chat(user, span_notice("[msg_bid]"))
			return TRUE

		if("resolve_dispatch")
			var/call_id = params["id"]
			var/msg_res = _grid_resolve_dispatch_call(user, call_id)
			if(msg_res)
				to_chat(user, span_notice("[msg_res]"))
			return TRUE

		if("stage_cask")
			var/msg_sc = _grid_stage_spent_fuel_cask(user)
			if(msg_sc)
				to_chat(user, span_notice("[msg_sc]"))
			return TRUE

		if("store_cask")
			var/msg_st = _grid_store_staged_cask(user)
			if(msg_st)
				to_chat(user, span_notice("[msg_st]"))
			return TRUE

		if("process_cask")
			var/msg_pc = _grid_process_stored_cask(user)
			if(msg_pc)
				to_chat(user, span_notice("[msg_pc]"))
			return TRUE

		if("run_forensics")
			var/did = _grid_run_forensics_scan()
			to_chat(user, did ? span_notice("Forensics scan complete.") : span_warning("Forensics scanner cooling down."))
			return TRUE

		if("shutdown_tap")
			var/td = params["district"]
			var/did_shutdown = _grid_shutdown_tap(td)
			to_chat(user, did_shutdown ? span_notice("Unauthorized tap shutdown in [td].") : span_warning("No active tap detected in [td]."))
			return TRUE

	return FALSE


/obj/machinery/f13/wasteland_grid_console/ui_state(mob/user)
	return GLOB.default_state  // or a stricter state if you have one

/obj/machinery/f13/wasteland_grid_console/ui_interact(mob/user, datum/tgui/ui)
	_wasteland_grid_bootstrap()
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "WastelandGrid") // must match the TS interface filename
		ui.open()


/obj/machinery/f13/wasteland_grid_console/proc/_read_heat_display()
	// show drifted values to operators
	var/v = GLOB.wasteland_grid_core_heat + round(GLOB.grid_sensor_drift_heat)
	return clamp(v, 0, 120)

/obj/machinery/f13/wasteland_grid_console/proc/_read_press_display()
	var/v = GLOB.grid_primary_pressure + round(GLOB.grid_sensor_drift_press)
	return clamp(v, 0, 220)

/obj/machinery/f13/wasteland_grid_console/proc/_read_flow_display()
	var/v = GLOB.grid_primary_flow + round(GLOB.grid_sensor_drift_flow)
	return clamp(v, 0, 120)

/obj/machinery/f13/wasteland_grid_console/proc/_show_menu(mob/user)
	_wasteland_grid_bootstrap()
	grid_tick_procedures()

	var/status = GLOB.wasteland_grid_online ? "ONLINE" : "OFFLINE"
	var/state  = GLOB.wasteland_grid_state

	var/msg = ""
	msg += "Grid: [status] ([state])\n"
	msg += "Fuel: [GLOB.wasteland_grid_fuel] | Coolant: [GLOB.wasteland_grid_coolant]\n"
	msg += "Restart stage: [GLOB.wasteland_grid_restart_stage]\n"
	msg += "=== PLANT ===\n"
	msg += "Heat: [_read_heat_display()] (actual [GLOB.wasteland_grid_core_heat])\n"
	msg += "Reactivity: [GLOB.grid_core_reactivity] | Rods SP: [GLOB.grid_sp_rod_insertion]\n"
	msg += "Flow: [_read_flow_display()] | Coolant valve SP: [GLOB.grid_sp_coolant_valve]\n"
	msg += "Primary P: [_read_press_display()] | Relief SP: [GLOB.grid_sp_relief_valve]\n"
	msg += "Secondary P: [GLOB.grid_secondary_pressure] | Feedwater SP: [GLOB.grid_sp_feedwater_valve]\n"
	msg += "Steam Q: [GLOB.grid_steam_quality] | Bypass SP: [GLOB.grid_sp_bypass]\n"
	msg += "Turbine RPM: [GLOB.grid_turbine_rpm] | Gov SP: [GLOB.grid_sp_turbine_governor] | Output: [GLOB.grid_output] (Target [GLOB.grid_sp_target_output])\n"
	msg += "Xenon/Iodine/Samarium: [round(GLOB.grid_xenon_poison,0.1)] / [round(GLOB.grid_iodine_inventory,0.1)] / [round(GLOB.grid_samarium_poison,0.1)]\n"
	msg += "Burnup: [round(GLOB.grid_fuel_burnup,0.1)] | React reserve: [round(GLOB.grid_reactivity_reserve,0.1)] | Decay heat: [round(GLOB.grid_decay_heat,0.1)]\n"
	msg += "Boron: [GLOB.grid_boron_ppm] ppm (SP [GLOB.grid_sp_boron_ppm]) | Subcool margin: [round(GLOB.grid_subcool_margin)]\n"
	msg += "NPSH margin: [round(GLOB.grid_npsh_margin)]\n"
	msg += "PZR level: [round(GLOB.grid_pressurizer_level)] | Condenser vac: [round(GLOB.grid_condenser_vacuum)] | Hotwell: [round(GLOB.grid_hotwell_level)]\n"
	msg += "Contam: [round(GLOB.grid_coolant_contamination)] | Filter clog: [round(GLOB.grid_filter_clog)] | Lube: [round(GLOB.grid_lube_level)]\n"
	msg += "Wear P/V/T/B/S: [round(GLOB.grid_wear_pump_primary)]/[round(GLOB.grid_wear_valves)]/[round(GLOB.grid_wear_turbine)]/[round(GLOB.grid_wear_breakers)]/[round(GLOB.grid_wear_sensors)]\n"
	msg += "Turbine stress/moisture: [round(GLOB.grid_turbine_stress)] / [round(GLOB.grid_turbine_moisture)]\n"
	msg += "Sensors health: [GLOB.grid_sensor_health]\n"
	msg += "SCRAM: [(GLOB.grid_scram ? "YES" : "no")]\n"
	msg += "Safety interlocks: [(GLOB.grid_safety_interlocks_enabled ? "ENABLED" : "DISABLED")]\n"
	msg += "Catastrophe risk: [round(GLOB.grid_catastrophe_risk)]%\n"
	msg += "Background rads: [GLOB.wasteland_grid_background_rads]\n"
	msg += "=== MAINT ===\n[_maint_report()]"
	msg += "\n=== FAULTS ===\n[_fault_report()]"
	msg += "\nProcedure purge stage: [GLOB.grid_proc_purge_stage]\n"

	var/list/options = list()
	options += "Status (print)"
	options += (GLOB.wasteland_grid_online ? "Shut down grid" : "Prime systems (restart step 1)")
	options += "Engage grid (restart step 4)"
	options += "Insert fuel rod"
	options += "Insert coolant canister"

	// v2 controls
	options += "Set rod insertion (0-100)"
	options += "Set coolant valve SP (0-100)"
	options += "Set feedwater valve SP (0-100)"
	options += "Set relief valve SP (0-100)"
	options += "Set bypass SP (0-100)"
	options += "Set turbine governor SP (0-100)"
	options += "Set target output (0-100)"
	options += "Set boron SP (0-2000 ppm)"
	options += "SCRAM / Clear SCRAM"
	options += "Toggle safety interlocks"

	// v2 procedures
	options += "Start coolant purge procedure"
	options += "Abort coolant purge procedure"

	options += "Close"

	var/choice = input(user, msg, "Mass Fusion Console") as null|anything in options
	if(!choice || choice == "Close") return

	switch(choice)
		if("Status (print)")
			to_chat(user, "<span class='notice'>[msg]</span>")

		if("Shut down grid")
			_manual_shutdown(user)

		if("Prime systems (restart step 1)")
			_prime_restart(user)

		if("Engage grid (restart step 4)")
			_engage_restart(user)

		if("Insert fuel rod")
			_insert_fuel(user)

		if("Insert coolant canister")
			_insert_coolant(user)

		if("Set rod insertion (0-100)")
			var/v = input(user, "Rod insertion (0-100)\nHigher = less power", "Rods") as null|num
			if(!isnull(v)) GLOB.grid_sp_rod_insertion = clamp(round(v), 0, 100)

		if("Set coolant valve SP (0-100)")
			var/v2 = input(user, "Coolant valve SP (0-100)", "Coolant Valve") as null|num
			if(!isnull(v2)) GLOB.grid_sp_coolant_valve = clamp(round(v2), 0, 100)

		if("Set feedwater valve SP (0-100)")
			var/v3 = input(user, "Feedwater SP (0-100)", "Feedwater") as null|num
			if(!isnull(v3)) GLOB.grid_sp_feedwater_valve = clamp(round(v3), 0, 100)

		if("Set relief valve SP (0-100)")
			var/v4 = input(user, "Relief SP (0-100)", "Relief") as null|num
			if(!isnull(v4)) GLOB.grid_sp_relief_valve = clamp(round(v4), 0, 100)

		if("Set bypass SP (0-100)")
			var/v5 = input(user, "Bypass SP (0-100)", "Bypass") as null|num
			if(!isnull(v5)) GLOB.grid_sp_bypass = clamp(round(v5), 0, 100)

		if("Set turbine governor SP (0-100)")
			var/vg = input(user, "Governor SP (0-100)\nCaps achievable RPM.", "Turbine Governor") as null|num
			if(!isnull(vg)) GLOB.grid_sp_turbine_governor = clamp(round(vg), 0, 100)

		if("Set target output (0-100)")
			var/v6 = input(user, "Target output (0-100)", "Target Output") as null|num
			if(!isnull(v6)) GLOB.grid_sp_target_output = clamp(round(v6), 0, 100)

		if("Set boron SP (0-2000 ppm)")
			var/vb = input(user, "Boron setpoint ppm (0-2000)", "Boron") as null|num
			if(!isnull(vb)) GLOB.grid_sp_boron_ppm = clamp(round(vb), 0, 2000)

		if("SCRAM / Clear SCRAM")
			if(!GLOB.grid_scram)
				GLOB.grid_scram = TRUE
				_announce_grid("WASTELAND GRID: SCRAM triggered by [user]!")
			else
				GLOB.grid_scram = FALSE
				_announce_grid("WASTELAND GRID: SCRAM cleared by [user].")

		if("Toggle safety interlocks")
			if(GLOB.grid_catastrophe_triggered)
				to_chat(user, "<span class='warning'>Interlocks unavailable: core already destroyed.</span>")
			else
				GLOB.grid_safety_interlocks_enabled = !GLOB.grid_safety_interlocks_enabled
				if(GLOB.grid_safety_interlocks_enabled)
					GLOB.grid_catastrophe_risk = max(0, GLOB.grid_catastrophe_risk - 15)
					_announce_grid("WASTELAND GRID: Safety interlocks RE-ENABLED by [user].")
				else
					_announce_grid("WASTELAND GRID: WARNING - Safety interlocks DISABLED by [user].")

		if("Start coolant purge procedure")
			grid_start_coolant_purge(user)

		if("Abort coolant purge procedure")
			grid_abort_coolant_purge("Aborted by operator")

	_show_menu(user)

/// Manual shutdown (existing)
/// Note: does not reset v2 setpoints; operators keep them.
/obj/machinery/f13/wasteland_grid_console/proc/_manual_shutdown(mob/user)
	if(!GLOB.wasteland_grid_online)
		to_chat(user, "<span class='warning'>Grid is already offline.</span>")
		return

	set_wasteland_grid_online(FALSE)
	_announce_grid("WASTELAND GRID: Manual shutdown by [user].")

	GLOB.wasteland_grid_restart_stage = 0
	GLOB.wasteland_grid_restart_operator = null
	GLOB.wasteland_grid_restart_lock = FALSE
	_sync_wasteland_grid_reactor()

/// Restart step 1: prime systems (existing)
/obj/machinery/f13/wasteland_grid_console/proc/_prime_restart(mob/user)
	if(GLOB.wasteland_grid_online)
		to_chat(user, "<span class='warning'>Grid is already online.</span>")
		return

	if(GLOB.grid_catastrophe_triggered)
		to_chat(user, "<span class='warning'>Restart impossible: reactor core destroyed by catastrophic failure.</span>")
		return

	if(world.time < GLOB.wasteland_grid_restart_cooldown_until)
		to_chat(user, "<span class='warning'>Restart systems cooling down. Try again shortly.</span>")
		return

	if(GLOB.wasteland_grid_restart_lock)
		to_chat(user, "<span class='warning'>Restart in progress. Don’t spam it.</span>")
		return

	if(GLOB.wasteland_grid_fuel <= 0 || GLOB.wasteland_grid_coolant <= 0)
		to_chat(user, "<span class='warning'>Insufficient fuel/coolant. Feed the plant first.</span>")
		return

	// Xenon pit behavior: immediate restart can be blocked after a recent shutdown.
	if(GLOB.grid_xenon_poison >= 28 && GLOB.grid_sp_boron_ppm >= 400)
		to_chat(user, "<span class='warning'>Reactor restart blocked by xenon poisoning. Lower boron and wait or burn through carefully.</span>")
		return

	GLOB.wasteland_grid_restart_stage = 1
	GLOB.wasteland_grid_restart_operator = user.ckey
	to_chat(user, "<span class='notice'>Systems primed. Next: reset breakers at the breaker panel.</span>")
	_announce_grid("WASTELAND GRID: Restart primed by [user]. Step 2 required: breaker reset.")
	_sync_wasteland_grid_reactor()

/// Restart step 4: engage grid (existing, plus v2 penalties)
/obj/machinery/f13/wasteland_grid_console/proc/_engage_restart(mob/user)
	if(GLOB.wasteland_grid_online)
		to_chat(user, "<span class='warning'>Grid is already online.</span>")
		return

	if(GLOB.wasteland_grid_restart_stage < 3)
		to_chat(user, "<span class='warning'>Restart incomplete. Required steps: Prime -> Breakers -> Coolant -> Engage.</span>")
		return

	if(!GLOB.wasteland_grid_restart_operator || user.ckey != GLOB.wasteland_grid_restart_operator)
		to_chat(user, "<span class='warning'>Only the operator who primed the restart can engage it.</span>")
		return

	if(GLOB.wasteland_grid_restart_lock)
		to_chat(user, "<span class='warning'>Restart already engaging.</span>")
		return

	if(_has_unfixed_faults())
		to_chat(user, "<span class='warning'>Engage failed: unresolved faults present. The grid bucks and trips harder.</span>")
		GLOB.wasteland_grid_fuel = max(0, GLOB.wasteland_grid_fuel - 10)
		GLOB.wasteland_grid_coolant = max(0, GLOB.wasteland_grid_coolant - 10)
		add_grid_fault("control_bus_short", 3)

		// v2: also spike pressures a bit to punish unsafe engage
		GLOB.grid_primary_pressure = clamp(GLOB.grid_primary_pressure + 15, 0, 200)

		GLOB.wasteland_grid_restart_stage = 0
		GLOB.wasteland_grid_restart_operator = null
		GLOB.wasteland_grid_restart_cooldown_until = world.time + 60 SECONDS
		_sync_wasteland_grid_reactor()
		return

	if(GLOB.grid_xenon_poison >= 34)
		to_chat(user, "<span class='warning'>Restart abort: xenon pit too deep. Wait out decay or condition the core first.</span>")
		GLOB.wasteland_grid_restart_stage = 0
		GLOB.wasteland_grid_restart_operator = null
		GLOB.wasteland_grid_restart_cooldown_until = world.time + 45 SECONDS
		_sync_wasteland_grid_reactor()
		return

	GLOB.wasteland_grid_restart_lock = TRUE
	to_chat(user, "<span class='notice'>Engaging breakers... stand by.</span>")
	addtimer(CALLBACK(src, PROC_REF(_finish_engage), user), 4 SECONDS)

/// Finalize engage (existing)
/obj/machinery/f13/wasteland_grid_console/proc/_finish_engage(mob/user)
	GLOB.wasteland_grid_restart_lock = FALSE

	if(GLOB.wasteland_grid_fuel <= 0 || GLOB.wasteland_grid_coolant <= 0)
		to_chat(user, "<span class='warning'>Restart failed: fuel/coolant depleted.</span>")
		GLOB.wasteland_grid_restart_stage = 0
		GLOB.wasteland_grid_restart_operator = null
		GLOB.wasteland_grid_restart_cooldown_until = world.time + 30 SECONDS
		_sync_wasteland_grid_reactor()
		return

	set_wasteland_grid_online(TRUE)
	GLOB.wasteland_grid_restart_stage = 0
	GLOB.wasteland_grid_restart_operator = null
	GLOB.wasteland_grid_restart_cooldown_until = world.time + 30 SECONDS
	_sync_wasteland_grid_reactor()

	_announce_grid("WASTELAND GRID ONLINE: Power restored by [user].")

/// Insert fuel rod (existing)
/obj/machinery/f13/wasteland_grid_console/proc/_insert_fuel(mob/user)
	var/obj/item/f13/grid_fuel/F = user.get_active_held_item()
	if(!istype(F))
		to_chat(user, "<span class='warning'>Hold a fuel rod in your active hand.</span>")
		return

	GLOB.wasteland_grid_fuel = min(200, GLOB.wasteland_grid_fuel + F.fuel_value)
	to_chat(user, "<span class='notice'>Inserted fuel. Fuel now: [GLOB.wasteland_grid_fuel]</span>")
	qdel(F)
	_recalc_wasteland_grid_state()
	_recalc_background_rads()

/// Insert coolant canister (existing, plus minor chemistry improvement)
/obj/machinery/f13/wasteland_grid_console/proc/_insert_coolant(mob/user)
	var/obj/item/f13/grid_coolant/C = user.get_active_held_item()
	if(!istype(C))
		to_chat(user, "<span class='warning'>Hold a coolant canister in your active hand.</span>")
		return

	GLOB.wasteland_grid_coolant = min(200, GLOB.wasteland_grid_coolant + C.coolant_value)
	to_chat(user, "<span class='notice'>Inserted coolant. Coolant now: [GLOB.wasteland_grid_coolant]</span>")
	qdel(C)

	// fresh coolant reduces contamination slightly
	GLOB.grid_coolant_contamination = max(0, GLOB.grid_coolant_contamination - 3)

	_recalc_wasteland_grid_state()
	_recalc_background_rads()

///////////////////////////////////////////////////////////////
// ADVISOR CONSOLE (automated recommendations + quick apply)
///////////////////////////////////////////////////////////////

/obj/machinery/f13/wasteland_grid_advisor_console
	name = "reactor advisor console"
	desc = "Decision-support terminal for reactor operations and safe setpoint guidance."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE
	var/advisor_name = "AZ-5 Decision Support Unit"

/obj/machinery/f13/wasteland_grid_advisor_console/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()

/obj/machinery/f13/wasteland_grid_advisor_console/power_change()
	. = ..()
	stat &= ~NOPOWER
	icon_state = "control_on"

/obj/machinery/f13/wasteland_grid_advisor_console/attack_hand(mob/user)
	. = ..()
	if(!user) return
	ui_interact(user, null)

/obj/machinery/f13/wasteland_grid_advisor_console/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/f13/wasteland_grid_advisor_console/ui_interact(mob/user, datum/tgui/ui)
	_wasteland_grid_bootstrap()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "WastelandGridAdvisor")
		ui.open()

/obj/machinery/f13/wasteland_grid_advisor_console/proc/_compute_setpoint_plan()
	var/list/plan = list()

	var/target = clamp(round(GLOB.grid_sp_target_output), 35, 65)
	if(!GLOB.wasteland_grid_online)
		target = 45
	if(GLOB.wasteland_grid_state == "RED")
		target = min(target, 40)
	if(GLOB.wasteland_grid_core_heat >= 85 || GLOB.grid_primary_pressure >= 145)
		target = min(target, 35)
	if(GLOB.grid_turbine_stress >= 70 || GLOB.grid_turbine_moisture >= 65)
		target = min(target, 40)
	plan["target"] = clamp(round(target), 0, 100)

	var/rods = GLOB.grid_sp_rod_insertion
	if(GLOB.wasteland_grid_core_heat >= 90 || GLOB.grid_primary_pressure >= 160)
		rods = max(rods, 88)
	else if(GLOB.grid_output < (target - 8) && !GLOB.grid_scram)
		rods = max(15, rods - 5)
	else if(GLOB.grid_output > (target + 8))
		rods = min(92, rods + 4)
	plan["rods"] = clamp(round(rods), 0, 100)

	var/coolant = max(60, GLOB.grid_sp_coolant_valve)
	if(GLOB.wasteland_grid_core_heat >= 85 || GLOB.grid_subcool_margin <= 20)
		coolant += 10
	if(GLOB.grid_subcool_margin <= 10 || GLOB.grid_npsh_margin <= 10)
		coolant += 15
	plan["coolant"] = clamp(round(coolant), 0, 100)

	var/feedwater = max(50, GLOB.grid_sp_feedwater_valve)
	if(GLOB.grid_secondary_pressure <= 40 || GLOB.grid_steam_quality <= 45)
		feedwater += 10
	if(GLOB.grid_hotwell_level <= 25)
		feedwater = max(35, feedwater - 10)
	plan["feedwater"] = clamp(round(feedwater), 0, 100)

	var/relief = GLOB.grid_sp_relief_valve
	if(GLOB.grid_primary_pressure >= 170)
		relief = max(relief, 75)
	else if(GLOB.grid_primary_pressure >= 150)
		relief = max(relief, 45)
	else
		relief = clamp(relief, 0, 20)
	plan["relief"] = clamp(round(relief), 0, 100)

	var/bypass = clamp(GLOB.grid_sp_bypass, 5, 30)
	if(GLOB.grid_turbine_moisture >= 60 || GLOB.grid_turbine_stress >= 70)
		bypass = max(bypass, 35)
	plan["bypass"] = clamp(round(bypass), 0, 100)

	var/turbine = clamp(GLOB.grid_sp_turbine_governor, 25, 85)
	if(GLOB.grid_subcool_margin <= 12 || GLOB.grid_npsh_margin <= 10)
		turbine = max(25, turbine - 10)
	else if(GLOB.grid_output < (target - 6) && GLOB.wasteland_grid_core_heat < 80 && GLOB.grid_primary_pressure < 130)
		turbine = min(85, turbine + 3)
	plan["turbine"] = clamp(round(turbine), 0, 100)

	var/boron = 700 + (GLOB.grid_xenon_poison * 12) + (GLOB.grid_fuel_burnup * 2)
	if(GLOB.wasteland_grid_core_heat >= 90)
		boron += 200
	if(GLOB.grid_output < (target - 10))
		boron -= 50
	plan["boron"] = clamp(round(boron), 450, 1700)

	var/recommend_scram = (GLOB.wasteland_grid_core_heat >= 97 || GLOB.grid_primary_pressure >= 185 || GLOB.grid_subcool_margin <= 5 || GLOB.grid_npsh_margin <= 5 || (!GLOB.grid_safety_interlocks_enabled && GLOB.grid_catastrophe_risk >= 85))
	plan["scram"] = recommend_scram ? 1 : 0
	plan["interlocks"] = 1
	return plan

/obj/machinery/f13/wasteland_grid_advisor_console/proc/_build_recommendations(list/plan)
	var/list/recs = list()

	if(!GLOB.grid_safety_interlocks_enabled)
		recs += list(list(
			"id" = "interlocks",
			"sev" = 3,
			"title" = "Re-enable interlocks",
			"detail" = "Safety interlocks are disabled. Catastrophe risk will rise rapidly under unstable conditions.",
			"key" = "interlocks",
			"val" = 1
		))

	if(plan["scram"])
		recs += list(list(
			"id" = "scram",
			"sev" = 3,
			"title" = "Immediate SCRAM recommended",
			"detail" = "Core parameters are in a critical band. Insert rods and stabilize pressure now.",
			"key" = "scram",
			"val" = 1
		))

	if(GLOB.wasteland_grid_core_heat >= 85)
		recs += list(list(
			"id" = "heat",
			"sev" = (GLOB.wasteland_grid_core_heat >= 95) ? 3 : 2,
			"title" = "Core heat is high",
			"detail" = "Raise rod insertion and increase coolant throughput to pull heat down.",
			"key" = "rods",
			"val" = plan["rods"]
		))

	if(GLOB.grid_primary_pressure >= 145)
		recs += list(list(
			"id" = "pressure",
			"sev" = (GLOB.grid_primary_pressure >= 170) ? 3 : 2,
			"title" = "Primary pressure high",
			"detail" = "Open relief path to protect piping and containment margin.",
			"key" = "relief",
			"val" = plan["relief"]
		))

	if(GLOB.grid_subcool_margin <= 20 || GLOB.grid_npsh_margin <= 15)
		recs += list(list(
			"id" = "cooling",
			"sev" = (GLOB.grid_subcool_margin <= 10 || GLOB.grid_npsh_margin <= 10) ? 3 : 2,
			"title" = "Cooling margin is tight",
			"detail" = "Increase coolant valve and reduce aggressive load ramps.",
			"key" = "coolant",
			"val" = plan["coolant"]
		))

	if(GLOB.grid_turbine_moisture >= 60 || GLOB.grid_turbine_stress >= 70)
		recs += list(list(
			"id" = "turbine",
			"sev" = (GLOB.grid_turbine_stress >= 85) ? 3 : 2,
			"title" = "Turbine stress/moisture elevated",
			"detail" = "Increase bypass and reduce governor demand to protect turbine train.",
			"key" = "bypass",
			"val" = plan["bypass"]
		))

	if(GLOB.grid_output < (GLOB.grid_sp_target_output - 10) && !plan["scram"] && GLOB.wasteland_grid_core_heat < 80 && GLOB.grid_primary_pressure < 130)
		recs += list(list(
			"id" = "underpower",
			"sev" = 1,
			"title" = "Output below demand",
			"detail" = "Withdraw rods gradually and tune governor to recover toward target output.",
			"key" = "rods",
			"val" = plan["rods"]
		))

	if(!GLOB.wasteland_grid_online && GLOB.grid_xenon_poison >= 28)
		recs += list(list(
			"id" = "xenon",
			"sev" = 2,
			"title" = "Xenon pit in progress",
			"detail" = "Delay restart or lower boron and burn through carefully. Expect delayed reactivity response.",
			"key" = "boron",
			"val" = max(450, min(plan["boron"], 650))
		))

	if(!length(recs))
		recs += list(list(
			"id" = "stable",
			"sev" = 0,
			"title" = "Plant stable",
			"detail" = "No immediate corrections required. Continue routine monitoring.",
			"key" = "",
			"val" = 0
		))

	return recs

/obj/machinery/f13/wasteland_grid_advisor_console/proc/_apply_single(key, val, mob/user, announce = FALSE)
	if(!istext(key) || !length(key))
		return FALSE

	switch(key)
		if("rods")
			GLOB.grid_sp_rod_insertion = clamp(round(val), 0, 100)
		if("coolant")
			GLOB.grid_sp_coolant_valve = clamp(round(val), 0, 100)
		if("feedwater")
			GLOB.grid_sp_feedwater_valve = clamp(round(val), 0, 100)
		if("relief")
			GLOB.grid_sp_relief_valve = clamp(round(val), 0, 100)
		if("bypass")
			GLOB.grid_sp_bypass = clamp(round(val), 0, 100)
		if("turbine")
			GLOB.grid_sp_turbine_governor = clamp(round(val), 0, 100)
		if("target")
			GLOB.grid_sp_target_output = clamp(round(val), 0, 100)
		if("boron")
			GLOB.grid_sp_boron_ppm = clamp(round(val), 0, 2000)
		if("scram")
			var/desired_scram = !!val
			if(desired_scram != !!GLOB.grid_scram)
				GLOB.grid_scram = desired_scram
				if(announce)
					_announce_grid("WASTELAND GRID: SCRAM [(GLOB.grid_scram ? "ENGAGED" : "CLEARED")] by advisor action ([user]).")
		if("interlocks")
			var/desired_interlocks = !!val
			if(desired_interlocks != !!GLOB.grid_safety_interlocks_enabled)
				GLOB.grid_safety_interlocks_enabled = desired_interlocks
				if(GLOB.grid_safety_interlocks_enabled)
					GLOB.grid_catastrophe_risk = max(0, GLOB.grid_catastrophe_risk - 10)
				if(announce)
					_announce_grid("WASTELAND GRID: Safety interlocks [(GLOB.grid_safety_interlocks_enabled ? "ENABLED" : "DISABLED")] by advisor action ([user]).")
		else
			return FALSE
	return TRUE

/obj/machinery/f13/wasteland_grid_advisor_console/proc/_apply_plan(list/plan, mob/user)
	if(!islist(plan) || !user)
		return

	_apply_single("interlocks", plan["interlocks"], user, FALSE)
	_apply_single("target", plan["target"], user, FALSE)
	_apply_single("rods", plan["rods"], user, FALSE)
	_apply_single("coolant", plan["coolant"], user, FALSE)
	_apply_single("feedwater", plan["feedwater"], user, FALSE)
	_apply_single("relief", plan["relief"], user, FALSE)
	_apply_single("bypass", plan["bypass"], user, FALSE)
	_apply_single("turbine", plan["turbine"], user, FALSE)
	_apply_single("boron", plan["boron"], user, FALSE)
	if(plan["scram"])
		_apply_single("scram", 1, user, TRUE)

	to_chat(user, "<span class='notice'>[advisor_name] applied recommended setpoints.</span>")

/obj/machinery/f13/wasteland_grid_advisor_console/proc/_print_report(mob/user)
	if(!user)
		return
	var/list/plan = _compute_setpoint_plan()
	var/list/recs = _build_recommendations(plan)

	var/text = "[advisor_name] OPERATIONAL REPORT\n"
	text += "Grid: [(GLOB.wasteland_grid_online ? "ONLINE" : "OFFLINE")] ([GLOB.wasteland_grid_state])\n"
	text += "Heat [GLOB.wasteland_grid_core_heat] | Primary P [GLOB.grid_primary_pressure] | Flow [GLOB.grid_primary_flow] | Output [GLOB.grid_output]\n"
	text += "Subcool [round(GLOB.grid_subcool_margin)] | NPSH [round(GLOB.grid_npsh_margin)] | Xenon [round(GLOB.grid_xenon_poison, 0.1)]\n"
	text += "Recommended SP => Rods [plan["rods"]], Coolant [plan["coolant"]], Feedwater [plan["feedwater"]], Relief [plan["relief"]], Bypass [plan["bypass"]], Turbine [plan["turbine"]], Target [plan["target"]], Boron [plan["boron"]]\n"
	text += "Guidance:\n"
	for(var/entry in recs)
		var/list/R = entry
		text += " - S[R["sev"]] [R["title"]]: [R["detail"]]\n"
	to_chat(user, "<span class='notice'>[text]</span>")

/obj/machinery/f13/wasteland_grid_advisor_console/ui_data(mob/user)
	_wasteland_grid_bootstrap()

	var/list/data = list()
	var/list/plan = _compute_setpoint_plan()
	var/list/recs = _build_recommendations(plan)

	data["advisor_name"] = advisor_name
	data["online"] = !!GLOB.wasteland_grid_online
	data["state"] = GLOB.wasteland_grid_state
	data["bg_rads"] = GLOB.wasteland_grid_background_rads
	data["heat"] = GLOB.wasteland_grid_core_heat
	data["pressure"] = GLOB.grid_primary_pressure
	data["flow"] = GLOB.grid_primary_flow
	data["output"] = GLOB.grid_output
	data["target_output"] = GLOB.grid_sp_target_output
	data["subcool"] = round(GLOB.grid_subcool_margin)
	data["npsh"] = round(GLOB.grid_npsh_margin)
	data["xenon"] = round(GLOB.grid_xenon_poison, 0.1)
	data["iodine"] = round(GLOB.grid_iodine_inventory, 0.1)
	data["samarium"] = round(GLOB.grid_samarium_poison, 0.1)
	data["boron"] = round(GLOB.grid_boron_ppm)
	data["scram"] = !!GLOB.grid_scram
	data["interlocks"] = !!GLOB.grid_safety_interlocks_enabled
	data["catastrophe_risk"] = round(GLOB.grid_catastrophe_risk)
	data["catastrophe_triggered"] = !!GLOB.grid_catastrophe_triggered
	data["auto_enabled"] = !!GLOB.grid_auto_enabled
	data["auto_active"] = !!GLOB.grid_auto_active
	data["auto_threshold"] = GLOB.grid_auto_player_threshold
	data["active_players"] = _grid_get_active_players()

	data["plan"] = plan
	data["recs"] = recs
	return data

/obj/machinery/f13/wasteland_grid_advisor_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	_wasteland_grid_bootstrap()
	var/mob/user = ui?.user
	if(!user)
		user = usr
	if(!user)
		return FALSE

	switch(action)
		if("apply_all")
			var/list/plan = _compute_setpoint_plan()
			_apply_plan(plan, user)
			return TRUE

		if("apply_one")
			var/key = params["key"]
			var/raw = text2num(params["val"])
			if(_apply_single(key, raw, user, TRUE))
				to_chat(user, "<span class='notice'>Applied advisor recommendation for [key].</span>")
			return TRUE

		if("print_report")
			_print_report(user)
			return TRUE

		if("toggle_auto")
			GLOB.grid_auto_enabled = !GLOB.grid_auto_enabled
			if(!GLOB.grid_auto_enabled)
				GLOB.grid_auto_active = FALSE
			_announce_grid("WASTELAND GRID: Auto-operations [(GLOB.grid_auto_enabled ? "ENABLED" : "DISABLED")] by [user].")
			return TRUE

		if("set_auto_threshold")
			var/raw_threshold = text2num(params["val"])
			GLOB.grid_auto_player_threshold = clamp(round(raw_threshold), 1, 120)
			return TRUE

	return FALSE

///////////////////////////////////////////////////////////////
// WORK ORDER BOARD (existing, expanded to include maintenance payouts)
///////////////////////////////////////////////////////////////

#define GRID_SUPPLY_ORDER_COUNT 2
#define GRID_SUPPLY_FUEL_REWARD 1200
#define GRID_SUPPLY_COOLANT_REWARD 1000

/datum/f13/work_order
	var/id
	var/title
	var/desc
	var/reward_caps = 0
	var/required_typepath
	var/required_count = 0
	var/completed = FALSE

/datum/f13/work_order/proc/is_done(mob/user)
	return completed

/obj/structure/f13/work_order_board
	name = "work order board"
	desc = "Reactor contracts console. Feed the plant, get paid."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE

	var/list/orders = list()
	var/next_refresh = 0
	var/refresh_interval = 5 MINUTES

/obj/structure/f13/work_order_board/Initialize()
	. = ..()
	_wasteland_grid_bootstrap()
	_generate_orders()

/obj/structure/f13/work_order_board/attack_hand(mob/user)
	. = ..()
	if(world.time >= next_refresh)
		_generate_orders()
	_show_orders(user)

/obj/structure/f13/work_order_board/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(!I || !user) return
	if(world.time >= next_refresh)
		_generate_orders()
	if(_try_turn_in_item(user, I))
		return TRUE

/obj/structure/f13/work_order_board/proc/_generate_orders()
	_wasteland_grid_bootstrap()
	orders.Cut()

	// Always: supply runs
	var/datum/f13/work_order/A = new
	A.id = "fuel"
	A.title = "Deliver Fuel Rods"
	A.desc = "Turn in fuel rods. They are loaded straight into the reactor."
	A.reward_caps = GRID_SUPPLY_FUEL_REWARD
	A.required_typepath = /obj/item/f13/grid_fuel
	A.required_count = GRID_SUPPLY_ORDER_COUNT
	orders += A

	var/datum/f13/work_order/B = new
	B.id = "coolant"
	B.title = "Deliver Coolant"
	B.desc = "Turn in coolant canisters. They inject directly into the reactor loop."
	B.reward_caps = GRID_SUPPLY_COOLANT_REWARD
	B.required_typepath = /obj/item/f13/grid_coolant
	B.required_count = GRID_SUPPLY_ORDER_COUNT
	orders += B

	// Live fault bounties
	for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
		if(!F || F.fixed) continue
		var/datum/f13/work_order/W = new
		W.id = "fault_[F.id]"
		W.title = "Fix Fault: [F.name] (S[F.severity])"
		W.desc = "Go to [F.location_hint] and repair it. Required tool: [F.get_required_tool_text()]. Required parts: [F.get_effective_reqs_text()]."
		W.reward_caps = 40 + (F.severity * 35)
		W.completed = FALSE
		orders += W

	// Maintenance payouts (mirrors active maint tasks)
	for(var/datum/grid_task/T in GLOB.grid_maint_queue)
		if(!T || T.completed) continue
		var/datum/f13/work_order/M = new
		M.id = "maint_[T.id]"
		M.title = "Maintenance: [T.name] (S[T.severity])"
		M.desc = "[T.desc]"
		M.reward_caps = 25 + (T.severity * 25)
		M.completed = FALSE
		orders += M

	next_refresh = world.time + refresh_interval

/obj/structure/f13/work_order_board/proc/_show_orders(mob/user)
	_wasteland_grid_bootstrap()

	var/text = "Available Work Orders:\n"
	for(var/datum/f13/work_order/W in orders)
		var/state = W.completed ? "COMPLETED" : "OPEN"
		var/reward = _get_effective_order_reward(W)
		text += "- [W.title] ([state]) Reward: [reward] caps\n  [W.desc]\n"
		if(W.required_typepath && !W.completed)
			text += "  Remaining turn-ins: [max(0, W.required_count)]\n"

	var/list/options = list()
	options += "Turn in items"
	options += "Claim fault completions"
	options += "Claim maintenance completions"
	options += "Close"

	var/choice = input(user, text, "Work Orders") as null|anything in options
	if(!choice || choice == "Close") return

	switch(choice)
		if("Turn in items")
			_turn_in_items(user)
		if("Claim fault completions")
			_claim_fault_completions(user)
		if("Claim maintenance completions")
			_claim_maint_completions(user)

/obj/structure/f13/work_order_board/proc/_is_repeatable_supply_order(datum/f13/work_order/W)
	if(!W) return FALSE
	return (W.id == "fuel" || W.id == "coolant")

/obj/structure/f13/work_order_board/proc/_get_effective_order_reward(datum/f13/work_order/W)
	if(!W) return 0
	var/reward = max(1, W.reward_caps)
	if(_is_repeatable_supply_order(W))
		if(GLOB.wasteland_grid_state == "RED")
			reward = round(reward * 1.50)
		else if(GLOB.wasteland_grid_state == "YELLOW")
			reward = round(reward * 1.25)
	return max(1, reward)

/obj/structure/f13/work_order_board/proc/_apply_reactor_supply(mob/user, obj/item/I)
	if(istype(I, /obj/item/f13/grid_fuel))
		var/obj/item/f13/grid_fuel/F = I
		var/old_fuel = GLOB.wasteland_grid_fuel
		GLOB.wasteland_grid_fuel = min(200, GLOB.wasteland_grid_fuel + F.fuel_value)
		to_chat(user, "<span class='notice'>Fuel injected directly to reactor: [old_fuel] -> [GLOB.wasteland_grid_fuel]</span>")
	else if(istype(I, /obj/item/f13/grid_coolant))
		var/obj/item/f13/grid_coolant/C = I
		var/old_cool = GLOB.wasteland_grid_coolant
		GLOB.wasteland_grid_coolant = min(200, GLOB.wasteland_grid_coolant + C.coolant_value)
		GLOB.grid_coolant_contamination = max(0, GLOB.grid_coolant_contamination - 3)
		to_chat(user, "<span class='notice'>Coolant injected directly to reactor: [old_cool] -> [GLOB.wasteland_grid_coolant]</span>")
	_recalc_wasteland_grid_state()
	_recalc_background_rads()

/obj/structure/f13/work_order_board/proc/_reset_repeatable_supply_order(datum/f13/work_order/W)
	if(!W) return
	if(!_is_repeatable_supply_order(W)) return
	W.completed = FALSE
	W.required_count = GRID_SUPPLY_ORDER_COUNT

/obj/structure/f13/work_order_board/proc/_try_turn_in_item(mob/user, obj/item/I)
	if(!user || !I) return FALSE
	for(var/datum/f13/work_order/W in orders)
		if(W.completed) continue
		if(!W.required_typepath) continue
		if(!istype(I, W.required_typepath)) continue
		if(!user.doUnEquip(I))
			to_chat(user, "<span class='warning'>You can't submit that item right now.</span>")
			return TRUE
		_apply_reactor_supply(user, I)
		qdel(I)
		W.required_count--
		to_chat(user, "<span class='notice'>Turned in. Remaining for this order: [max(0, W.required_count)]</span>")
		if(W.required_count <= 0)
			var/reward = _get_effective_order_reward(W)
			if(_is_repeatable_supply_order(W))
				_pay_caps(user, reward)
				to_chat(user, "<span class='boldnotice'>Reactor supply contract complete. Paid [reward] caps.</span>")
				_reset_repeatable_supply_order(W)
			else
				W.completed = TRUE
				_pay_caps(user, reward)
				to_chat(user, "<span class='boldnotice'>Order complete! Paid [reward] caps.</span>")
		return TRUE
	to_chat(user, "<span class='warning'>No matching open order for that item.</span>")
	return FALSE

/obj/structure/f13/work_order_board/proc/_turn_in_items(mob/user)
	var/obj/item/I = user.get_active_held_item()
	if(!I)
		to_chat(user, "<span class='warning'>Hold the item you want to turn in.</span>")
		return
	_try_turn_in_item(user, I)

/obj/structure/f13/work_order_board/proc/_claim_fault_completions(mob/user)
	var/paid_any = FALSE

	for(var/datum/f13/work_order/W in orders)
		if(W.completed) continue
		if(findtext(W.id, "fault_") != 1) continue

		var/fid = copytext(W.id, 7)
		var/done = TRUE
		for(var/datum/wasteland_grid_fault/F in GLOB.wasteland_grid_faults)
			if(F && !F.fixed && F.id == fid)
				done = FALSE
				break

		if(done)
			W.completed = TRUE
			_pay_caps(user, W.reward_caps)
			paid_any = TRUE
			to_chat(user, "<span class='boldnotice'>Fault bounty claimed: [W.title]. Paid [W.reward_caps] caps.</span>")

	if(!paid_any)
		to_chat(user, "<span class='notice'>No completed fault bounties to claim yet.</span>")

/obj/structure/f13/work_order_board/proc/_claim_maint_completions(mob/user)
	var/paid_any = FALSE

	for(var/datum/f13/work_order/W in orders)
		if(W.completed) continue
		if(findtext(W.id, "maint_") != 1) continue

		var/mid = copytext(W.id, 7) // after maint_
		var/done = FALSE
		for(var/datum/grid_task/T in GLOB.grid_maint_queue)
			if(T && T.id == mid && T.completed)
				done = TRUE
				break

		if(done)
			W.completed = TRUE
			_pay_caps(user, W.reward_caps)
			paid_any = TRUE
			to_chat(user, "<span class='boldnotice'>Maintenance payout claimed: [W.title]. Paid [W.reward_caps] caps.</span>")

	if(!paid_any)
		to_chat(user, "<span class='notice'>No completed maintenance tasks to claim yet.</span>")

proc/_pay_caps(mob/user, amount)
	if(amount <= 0 || !user) return
	var/turf/T = get_turf(user)
	if(!T) return

	var/remaining = max(1, round(amount))
	while(remaining > 0)
		var/obj/item/stack/f13Cash/caps/C = new /obj/item/stack/f13Cash/caps(T)
		var/give = min(C.max_amount, remaining)
		if(give > 1)
			C.add(give - 1)
		remaining -= give
	playsound(T, 'sound/items/change_jaws.ogg', 60, 1)
	to_chat(user, "<span class='notice'>[amount] caps dispensed.</span>")

///////////////////////////////////////////////////////////////
// MAP PLACEMENT: CONCRETE PLANT OBJECTS (examples)
//
// Place these on the map and set component_tag/network_id/district as desired:
//
// - /obj/machinery/grid/pump            (component_tag = "primary_pump_1")
// - /obj/structure/grid/valve           (component_tag="coolant_valve_1", valve_type="coolant")
// - /obj/structure/grid/relief_valve    (component_tag="relief_1")
// - /obj/structure/grid/filter_unit     (component_tag="filter_1")
// - /obj/structure/grid/heat_exchanger  (component_tag="hx_1")
// - /obj/structure/grid/turbine_assembly (component_tag="turbine_1")
// - /obj/machinery/grid/turbine_controller (component_tag="turbine_ctrl_1")
// - /obj/structure/grid/sensor_panel    (component_tag="sensor_panel_1")
// - /obj/structure/grid/breaker_cabinet (district="Downtown", component_tag="breaker_downtown")
// - /obj/structure/grid/power_relay (district="BOS"/"NCR"/"Legion"/"Town"/"Mass Fusion")
// - /obj/structure/grid/backup_generator (district="BOS"/"NCR"/"Legion"/"Town"/"Mass Fusion", fueled by uranium sheets)
// - /obj/structure/grid/relay_breaker_box (district="BOS"/"NCR"/"Legion"/"Town"/"Mass Fusion")
// - /obj/machinery/f13/grid_relay_console (or /bos /ncr /legion /town /massfusion)
// - /obj/structure/grid/relay_tower (decorative/indestructible)
// - /obj/machinery/f13/grid_faction_district_console (or /bos, /ncr, /legion, /town, /massfusion variants)
// - /obj/machinery/f13/wasteland_grid_console
// - /obj/machinery/f13/wasteland_grid_advisor_console
// - /obj/structure/grid/purge_valve     (component_tag="purge_valve_1")
//
// They’ll automatically register into GLOB.grid_components_by_tag at init.
///////////////////////////////////////////////////////////////

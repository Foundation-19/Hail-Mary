// Enclave Faction Defines

// Access is defined in code/__DEFINES/access.dm

// Vertibird Status
#define VERTIBIRD_STATUS_STANDBY "standby"
#define VERTIBIRD_STATUS_FLYING "flying"
#define VERTIBIRD_STATUS_MAINTENANCE "maintenance"

// Mission Types
#define VERTIBIRD_MISSION_TRANSPORT "transport"
#define VERTIBIRD_MISSION_SUPPLY_DROP "supply_drop"
#define VERTIBIRD_MISSION_EXTRACTION "extraction"
#define VERTIBIRD_MISSION_CAS "close_air_support"

// Cooldowns
#define VERTIBIRD_MISSION_COOLDOWN (5 MINUTES)
#define VERTIBIRD_CAS_COOLDOWN (10 MINUTES)

// Vertibird Stats
#define VERTIBIRD_MAX_FUEL 100
#define VERTIBIRD_MAX_HEALTH 500
#define VERTIBIRD_MAX_AMMO_MINIGUN 500
#define VERTIBIRD_MAX_AMMO_MISSILES 8

// Fuel Costs
#define VERTIBIRD_FUEL_TRANSPORT 10
#define VERTIBIRD_FUEL_SUPPLY_DROP 5
#define VERTIBIRD_FUEL_EXTRACTION 15
#define VERTIBIRD_FUEL_CAS 8

// Supply Crate Types
#define SUPPLY_CRATE_AMMO "ammunition"
#define SUPPLY_CRATE_MEDICAL "medical"
#define SUPPLY_CRATE_EQUIPMENT "equipment"
#define SUPPLY_CRATE_EMERGENCY "emergency"

// Eyebot Network
#define EYEBOT_MAX_UNITS 5
#define EYEBOT_DETECTION_RANGE 7
#define EYEBOT_ALERT_COOLDOWN (30 SECONDS)
#define EYEBOT_PROPAGANDA_RANGE 7
#define EYEBOT_PROPAGANDA_INTERVAL (30 SECONDS)
#define EYEBOT_BATTERY_DRAIN 0.1

// Eyebot Modes
#define EYEBOT_MODE_IDLE "idle"
#define EYEBOT_MODE_PATROL "patrol"
#define EYEBOT_MODE_SURVEILLANCE "surveillance"
#define EYEBOT_MODE_RETURNING "returning"

// Patrol Loop Modes
#define PATROL_LOOP "loop"
#define PATROL_PINGPONG "pingpong"
#define PATROL_ONCE "once"

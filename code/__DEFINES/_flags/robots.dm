// ====================================================
// CPU CERT - CAPABILITY FLAGS
// What a robot/machine/AI is physically able to DO.
// Checked before any action is allowed to proceed.
// ====================================================

// Core mobility and interaction
#define CERT_CAN_MOVE           (1<<0)  // Can physically move under own power
#define CERT_CAN_SHOOT          (1<<1)  // Can operate/fire weapons
#define CERT_CAN_HACK           (1<<2)  // Can initiate fallout hacking minigame on valid targets
#define CERT_CAN_REPAIR         (1<<3)  // Can use repair tools on self/others
#define CERT_CAN_INTERFACE      (1<<4)  // Can operate terminals, machines, doors
#define CERT_CAN_BROADCAST      (1<<5)  // Can use radio/comms systems
#define CERT_CAN_DEPLOY         (1<<6)  // AI shell deployment eligible

// Upgrade-gated capabilities (not present by default, installed via cert_upgrade)
#define CERT_CAN_MALF           (1<<7)  // Malf powers unlocked
#define CERT_CAN_SURVEIL        (1<<8)  // Lip-read/hidden mic camera surveillance
#define CERT_CAN_IONPULSE       (1<<9)  // Ion thruster system installed
#define CERT_CAN_SPRINT         (1<<10) // VTEC/sprint system installed

// Chassis grade flags
#define CERT_MILITARY_GRADE     (1<<11) // Tier 2+ military hardware - gates higher-tier upgrades
#define CERT_PROTOTYPE_GRADE    (1<<12) // Tier 3 prototype hardware

// Protection flags
#define CERT_LOCKED             (1<<13) // NPC robots: cert is immutable, no swapping allowed
#define CERT_EMP_HARDENED       (1<<14) // Reduced EMP vulnerability

// F13 extended flags
#define CERT_CAN_RENAME         (1<<15) // Can use Set Designation verb
#define CERT_IS_HACKABLE        (1<<16) // Can be targeted by a hacking device (standard/med/eng certs)
#define CERT_ICE_HARDENED       (1<<17) // Passive ICE: burns one attacker attempt per hack session


// ====================================================
// C.O.R.E. STAT TYPE DEFINES
// Used as arguments to cpu_cert/proc/get_core_stat()
// ====================================================

#define CORE_COMPUTE        1   // Hacking ability, sensor range, AI interaction
#define CORE_OPERATIONS     2   // Weapon accuracy, response time, targeting
#define CORE_RESILIENCE     3   // Max health, EMP resistance, melee damage
#define CORE_ENERGY         4   // Power budget ceiling, upgrade draw limit


// ====================================================
// CERT TIER DEFINES
// ====================================================

#define CERT_TIER_BASIC         1   // Standard civilian/utility chassis
#define CERT_TIER_MILITARY      2   // Military/security grade
#define CERT_TIER_PROTOTYPE     3   // Experimental, rare


// ====================================================
// CONVENIENCE FLAG GROUPS
// Pre-combined flags for common chassis archetypes
// ====================================================

// A fully capable player borg baseline
#define CERT_FLAGS_PLAYER_BORG  (CERT_CAN_MOVE|CERT_CAN_REPAIR|CERT_CAN_INTERFACE|CERT_CAN_BROADCAST)

// A basic combat chassis
#define CERT_FLAGS_COMBAT       (CERT_FLAGS_PLAYER_BORG|CERT_CAN_SHOOT|CERT_MILITARY_GRADE)

// A locked-down NPC robot - can move and shoot but nobody touches its cert
#define CERT_FLAGS_NPC_BASIC    (CERT_CAN_MOVE|CERT_CAN_SHOOT|CERT_LOCKED)

// A stationary device (turret, fabricator)
#define CERT_FLAGS_DEVICE       (CERT_CAN_SHOOT|CERT_CAN_INTERFACE)

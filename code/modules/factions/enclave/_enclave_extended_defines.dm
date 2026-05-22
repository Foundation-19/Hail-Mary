// Enclave Extended Defines
// Additional systems for Enclave faction

// Covert Operations Defines
#define COVERT_DIFFICULTY_EASY 1
#define COVERT_DIFFICULTY_MEDIUM 2
#define COVERT_DIFFICULTY_HARD 3
#define COVERT_DIFFICULTY_EXTREME 4
#define COVERT_DIFFICULTY_IMPOSSIBLE 5

#define COVERT_TYPE_ASSASSINATION "assassination"
#define COVERT_TYPE_SABOTAGE "sabotage"
#define COVERT_TYPE_THEFT "theft"
#define COVERT_TYPE_INTEL "intel"
#define COVERT_TYPE_EXTRACTION "extraction"
#define COVERT_TYPE_RECON "recon"
#define COVERT_TYPE_DESTABILIZATION "destabilization"

// Detection Levels
#define DETECTION_UNDETECTED 30
#define DETECTION_SUSPICIOUS 60
#define DETECTION_ALERTED 90
#define DETECTION_DETECTED 100

// FEV/Genetic Research Defines
#define FEV_RISK_LOW 1
#define FEV_RISK_MEDIUM 2
#define FEV_RISK_HIGH 3
#define FEV_RISK_VERYHIGH 4
#define FEV_RISK_EXTREME 5

#define GENETIC_PURITY_PURE 95
#define GENETIC_PURITY_WASTELANDER 80
#define GENETIC_PURITY_MINOR_MUTANT 60
#define GENETIC_PURITY_GHOUL 40
#define GENETIC_PURITY_SUPERMUTANT 20

// Propaganda Defines
#define PROPAGANDA_RADIO "radio"
#define PROPAGANDA_EYEBOT "eyebot"
#define PROPAGANDA_TV "tv"
#define PROPAGANDA_PRINT "print"

#define INFLUENCE_HOSTILE 20
#define INFLUENCE_WARY 40
#define INFLUENCE_NEUTRAL 60
#define INFLUENCE_SYMPATHETIC 80
#define INFLUENCE_ALLIED 100

// Soldier Elite Defines
#define ENCLAVE_RANK_RECRUIT 0
#define ENCLAVE_RANK_PRIVATE 1
#define ENCLAVE_RANK_CORPORAL 2
#define ENCLAVE_RANK_SERGEANT 3
#define ENCLAVE_RANK_LIEUTENANT 4
#define ENCLAVE_RANK_COLONEL 5

// Secret Base Defines
#define BASE_SECURITY_POOR 1
#define BASE_SECURITY_FAIR 2
#define BASE_SECURITY_GOOD 3
#define BASE_SECURITY_EXCELLENT 4
#define BASE_SECURITY_PERFECT 5

// Genetic Screening Defines
#define SCREENING_APPROVED "approved"
#define SCREENING_QUARANTINED "quarantined"
#define SCREENING_TERMINATED "terminated"
#define SCREENING_MONITORED "monitored"

// Global Registries
GLOBAL_DATUM_INIT(enclave_covert_ops, /datum/enclave_covert_ops, new())
GLOBAL_DATUM_INIT(enclave_propaganda, /datum/enclave_propaganda, new())
GLOBAL_DATUM_INIT(enclave_soldier_progression, /datum/enclave_soldier_progression_manager, new())
GLOBAL_DATUM_INIT(enclave_secret_base, /datum/enclave_secret_base, new())
GLOBAL_DATUM_INIT(enclave_genetic_screening, /datum/enclave_genetic_screening, new())

GLOBAL_LIST_EMPTY(enclave_soldier_records)
GLOBAL_LIST_EMPTY(enclave_genetic_records)
GLOBAL_LIST_EMPTY(settlement_influence)

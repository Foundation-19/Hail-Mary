#define JOB_MODIFICATION_MAP_NAME "Central Pahrump"

/datum/job/New()
	..()
	MAP_JOB_CHECK

MAP_REMOVE_JOB(atlantic)
MAP_REMOVE_JOB(f13followers)
MAP_REMOVE_JOB(f13atlanticcap)
MAP_REMOVE_JOB(f13atlanticdoc)
MAP_REMOVE_JOB(f13atlanticsailor)
MAP_REMOVE_JOB(f13atlanticmarines)
MAP_REMOVE_JOB(locust_point)
MAP_REMOVE_JOB(f13baltimoredockmaster)
MAP_REMOVE_JOB(f13baltimorecouncil)
MAP_REMOVE_JOB(f13baltimoreconstable)
MAP_REMOVE_JOB(f13baltimorepolice)
MAP_REMOVE_JOB(f13baltimorefarmer)
MAP_REMOVE_JOB(baltimorecitizen)
MAP_REMOVE_JOB(f13baltimoreradiohort)
MAP_REMOVE_JOB(f13baltimorepreacher)
MAP_REMOVE_JOB(f13baltimoremechanic)
MAP_REMOVE_JOB(f13baltimoreshopclerc)
MAP_REMOVE_JOB(f13baltimorepilot)
MAP_REMOVE_JOB(locust/f13minutemen)
MAP_REMOVE_JOB(enclave)
MAP_REMOVE_JOB(khan)
MAP_REMOVE_JOB(eastwood/f13mayor)
MAP_REMOVE_JOB(eastwood/f13secretary)
MAP_REMOVE_JOB(eastwood/f13sheriff)
MAP_REMOVE_JOB(eastwood/f13deputy)
/*MAP_REMOVE_JOB(eastwood/f13prospector)*/
MAP_REMOVE_JOB(eastwood/f13dendoc)
MAP_REMOVE_JOB(eastwood/f13detective)
MAP_REMOVE_JOB(eastwood/f13banker)
MAP_REMOVE_JOB(eastwood/f13pilot)

// for future referance,  map remove job works via job path. e.g (eastwood/f13mayor) kills just the mayor, but (eastwood) will kill everything with eastwood at the start

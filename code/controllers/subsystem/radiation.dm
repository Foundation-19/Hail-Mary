PROCESSING_SUBSYSTEM_DEF(radiation)
	name = "Radiation"
	flags = SS_NO_INIT | SS_BACKGROUND

	var/list/warned_atoms = list()

/datum/controller/subsystem/processing/radiation/proc/get_radiation_stage(mob/living/L)
	if(!L)
		return 0
	var/debt = L.radiation_sickness
	if(debt >= RAD_SICKNESS_STAGE_CRITICAL)
		return 4
	if(debt >= RAD_SICKNESS_STAGE_SEVERE)
		return 3
	if(debt >= RAD_SICKNESS_STAGE_MODERATE)
		return 2
	if(debt >= RAD_SICKNESS_STAGE_MINOR)
		return 1
	return 0

/datum/controller/subsystem/processing/radiation/proc/get_radiation_stage_name(stage)
	switch(stage)
		if(1)
			return "Minor"
		if(2)
			return "Moderate"
		if(3)
			return "Severe"
		if(4)
			return "Critical"
	return "Stable"

/datum/controller/subsystem/processing/radiation/proc/warn(datum/component/radioactive/contamination)
	if(!contamination || QDELETED(contamination))
		return
	var/ref = REF(contamination.parent)
	if(warned_atoms[ref])
		return
	warned_atoms[ref] = TRUE
	var/atom/master = contamination.parent
	SSblackbox.record_feedback("tally", "contaminated", 1, master.type)
	var/msg = "has become contaminated with enough radiation to contaminate other objects. || Source: [contamination.source] || Strength: [contamination.strength]"
	master.investigate_log(msg, INVESTIGATE_RADIATION)

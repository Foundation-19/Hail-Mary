/datum/fantasy_affix
	var/placement // A bitflag of "slots" this affix takes up, for example pre/suffix
	var/alignment
	var/weight = 10

// For those occasional affixes which only make sense in certain circumstances
TYPE_PROC_REF(/datum/fantasy_affix, validate)(datum/component/fantasy/comp)
	return TRUE

TYPE_PROC_REF(/datum/fantasy_affix, apply)(datum/component/fantasy/comp, newName)
	return newName

TYPE_PROC_REF(/datum/fantasy_affix, remove)(datum/component/fantasy/comp)

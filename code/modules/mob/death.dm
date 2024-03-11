//This is the proc for gibbing a mob. Cannot gib ghosts.
//added different sort of gibs and animations. N
TYPE_PROC_REF(/mob, gib)()
	return

//This is the proc for turning a mob into ash. Mostly a copy of gib code (above).
//Originally created for wizard disintegrate. I've removed the virus code since it's irrelevant here.
//Dusting robots does not eject the MMI, so it's a bit more powerful than gib() /N
TYPE_PROC_REF(/mob, dust)(just_ash, drop_items, force)
	return

TYPE_PROC_REF(/mob, death)(gibbed)
	SEND_SIGNAL(src, COMSIG_MOB_DEATH, gibbed)
	return

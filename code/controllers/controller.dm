/datum/controller
	var/name
	// The object used for the clickable stat() button.
	var/obj/effect/statclick/statclick

TYPE_PROC_REF(/datum/controller, Initialize)()

//cleanup actions
TYPE_PROC_REF(/datum/controller, Shutdown)()

//when we enter dmm_suite.load_map
TYPE_PROC_REF(/datum/controller, StartLoadingMap)()

//when we exit dmm_suite.load_map
TYPE_PROC_REF(/datum/controller, StopLoadingMap)()

TYPE_PROC_REF(/datum/controller, Recover)()

TYPE_PROC_REF(/datum/controller, stat_entry)(msg)

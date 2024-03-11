TGS_DEFINE_AND_SET_GLOBAL(tgs, null)

/datum/tgs_api
	var/datum/tgs_version/version
	var/datum/tgs_event_handler/event_handler

	var/list/warned_deprecated_command_runs

/datum/tgs_api/New(datum/tgs_event_handler/event_handler, datum/tgs_version/version)
	. = ..()
	src.event_handler = event_handler
	src.version = version

/datum/tgs_api/latest
	parent_type = /datum/tgs_api/v5

TGS_PROTECT_DATUM(/datum/tgs_api)

TYPE_PROC_REF(/datum/tgs_api, ApiVersion)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, OnWorldNew)(datum/tgs_event_handler/event_handler)
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, OnInitializationComplete)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, OnTopic)(T)
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, OnReboot)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, InstanceName)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, TestMerges)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, EndProcess)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, Revision)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, ChatChannelInfo)()
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, ChatBroadcast)(message, list/channels)
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, ChatTargetedBroadcast)(message, admin_only)
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, ChatPrivateMessage)(message, datum/tgs_chat_user/user)
	return TGS_UNIMPLEMENTED

TYPE_PROC_REF(/datum/tgs_api, SecurityLevel)()
	return TGS_UNIMPLEMENTED

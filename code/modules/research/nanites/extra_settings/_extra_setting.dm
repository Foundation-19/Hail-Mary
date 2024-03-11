/datum/nanite_extra_setting
	var/setting_type
	var/value

TYPE_PROC_REF(/datum/nanite_extra_setting, get_value)()
	return value

TYPE_PROC_REF(/datum/nanite_extra_setting, set_value)(value)
	src.value = value

TYPE_PROC_REF(/datum/nanite_extra_setting, get_copy)()
	return

//I made the choice to send the name as part of the parameter instead of storing it directly on
//this datum as a way of avoiding duplication of data between the containing assoc list
//and this datum.
//Also make sure to double wrap the list when implementing this as
//+= is interpreted as a combine on lists, so the outer list gets unwrapped
TYPE_PROC_REF(/datum/nanite_extra_setting, get_frontend_list)(name)
	return

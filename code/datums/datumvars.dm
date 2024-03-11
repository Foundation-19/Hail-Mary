TYPE_PROC_REF(/datum, CanProcCall)(procname)
	return TRUE

TYPE_PROC_REF(/datum, can_vv_get)(var_name)
	return TRUE

TYPE_PROC_REF(/datum, vv_edit_var)(var_name, var_value) //called whenever a var is edited
	if(var_name == NAMEOF(src, vars))
		return FALSE
	vars[var_name] = var_value
	datum_flags |= DF_VAR_EDITED
	return TRUE

TYPE_PROC_REF(/datum, vv_get_var)(var_name)
	switch(var_name)
		if ("vars")
			return debug_variable(var_name, list(), 0, src)
	return debug_variable(var_name, vars[var_name], 0, src)

TYPE_PROC_REF(/datum, can_vv_mark)()
	return TRUE

//please call . = ..() first and append to the result, that way parent items are always at the top and child items are further down
//add separaters by doing . += "---"
TYPE_PROC_REF(/datum, vv_get_dropdown)()
	. = list()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION(VV_HK_CALLPROC, "Call Proc")
	VV_DROPDOWN_OPTION(VV_HK_MARK, "Mark Object")
	VV_DROPDOWN_OPTION(VV_HK_DELETE, "Delete")
	VV_DROPDOWN_OPTION(VV_HK_EXPOSE, "Show VV To Player")
	VV_DROPDOWN_OPTION(VV_HK_ADDCOMPONENT, "Add Component/Element")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_TRAITS, "Modify Traits")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_RECIPES, "Modify Recipes")
	#ifdef REFERENCE_TRACKING
	VV_DROPDOWN_OPTION(VV_HK_VIEW_REFERENCES, "View References")
	#endif

//This proc is only called if everything topic-wise is verified. The only verifications that should happen here is things like permission checks!
//href_list is a reference, modifying it in these procs WILL change the rest of the proc in topic.dm of admin/view_variables!
//This proc is for "high level" actions like admin heal/set species/etc/etc. The low level debugging things should go in admin/view_variables/topic_basic.dm incase this runtimes.
TYPE_PROC_REF(/datum, vv_do_topic)(list/href_list)
	if(!usr || !usr.client || !usr.client.holder || !check_rights(NONE))
		return FALSE			//This is VV, not to be called by anything else.
	if(href_list[VV_HK_MODIFY_TRAITS])
		usr.client.holder.modify_traits(src)
	if(href_list[VV_HK_MODIFY_RECIPES]) //fortuna addition
		usr.client.modify_recipes(src)
	return TRUE

TYPE_PROC_REF(/datum, vv_get_header)()
	. = list()
	if(("name" in vars) && !isatom(src))
		. += "<b>[vars["name"]]</b><br>"

TYPE_PROC_REF(/datum, on_reagent_change)(changetype)
	return

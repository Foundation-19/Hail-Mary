//This is intended to be a full wrapper. DO NOT directly modify its values
///Container for client viewsize
/datum/viewData
	var/width = 0
	var/height = 0
	var/default = ""
	var/is_suppressed = FALSE
	var/client/chief = null

/datum/viewData/New(client/owner, view_string)
	default = view_string
	chief = owner
	apply()

TYPE_PROC_REF(/datum/viewData, setDefault)(string)
	default = string
	apply()

TYPE_PROC_REF(/datum/viewData, safeApplyFormat)()
	if(isZooming())
		assertFormat()
		return
	resetFormat()

TYPE_PROC_REF(/datum/viewData, assertFormat)()//T-Pose
	// winset(chief, "mapwindow.map", "zoom=0")
	// Citadel Edit - We're using icon dropdown instead

TYPE_PROC_REF(/datum/viewData, resetFormat)()//Cuck
	// winset(chief, "mapwindow.map", "zoom=[chief.prefs.pixel_size]")
	// Citadel Edit - We're using icon dropdown instead

TYPE_PROC_REF(/datum/viewData, setZoomMode)()
	// winset(chief, "mapwindow.map", "zoom-mode=[chief.prefs.scaling_method]")
	// Citadel Edit - We're using icon dropdown instead

TYPE_PROC_REF(/datum/viewData, isZooming)()
	return (width || height)

TYPE_PROC_REF(/datum/viewData, resetToDefault)()
	width = 0
	height = 0
	apply()

TYPE_PROC_REF(/datum/viewData, add)(toAdd)
	width += toAdd
	height += toAdd
	apply()

TYPE_PROC_REF(/datum/viewData, addTo)(toAdd)
	var/list/shitcode = getviewsize(toAdd)
	width += shitcode[1]
	height += shitcode[2]
	apply()

TYPE_PROC_REF(/datum/viewData, setTo)(toAdd)
	var/list/shitcode = getviewsize(toAdd)  //Backward compatability to account
	width = shitcode[1]						//for a change in how sizes get calculated. we used to include world.view in
	height = shitcode[2]					//this, but it was jank, so I had to move it
	apply()

TYPE_PROC_REF(/datum/viewData, setBoth)(wid, hei)
	width = wid
	height = hei
	apply()

TYPE_PROC_REF(/datum/viewData, setWidth)(wid)
	width = wid
	apply()

TYPE_PROC_REF(/datum/viewData, setHeight)(hei)
	width = hei
	apply()

TYPE_PROC_REF(/datum/viewData, addToWidth)(toAdd)
	width += toAdd
	apply()

TYPE_PROC_REF(/datum/viewData, addToHeight)(screen, toAdd)
	height += toAdd
	apply()

TYPE_PROC_REF(/datum/viewData, apply)()
	if(!chief)
		return
	chief.change_view(getView())
	safeApplyFormat()
	if(!QDELETED(chief))
		if(chief.prefs.auto_fit_viewport)
			chief.fit_viewport()

TYPE_PROC_REF(/datum/viewData, supress)()
	is_suppressed = TRUE
	apply()

TYPE_PROC_REF(/datum/viewData, unsupress)()
	is_suppressed = FALSE
	apply()

TYPE_PROC_REF(/datum/viewData, getView)()
	var/list/temp = getviewsize(default)
	if(is_suppressed)
		return "[temp[1]]x[temp[2]]"
	return "[width + temp[1]]x[height + temp[2]]"

TYPE_PROC_REF(/datum/viewData, zoomIn)()
	resetToDefault()
	animate(chief, pixel_x = 0, pixel_y = 0, 0, FALSE, LINEAR_EASING, ANIMATION_END_NOW)

TYPE_PROC_REF(/datum/viewData, zoomOut)(radius = 0, offset = 0, direction = FALSE)
	if(direction)
		var/_x = 0
		var/_y = 0
		switch(direction)
			if(NORTH)
				_y = offset
			if(EAST)
				_x = offset
			if(SOUTH)
				_y = -offset
			if(WEST)
				_x = -offset
		animate(chief, pixel_x = world.icon_size*_x, pixel_y = world.icon_size*_y, 0, FALSE, LINEAR_EASING, ANIMATION_END_NOW)
	//Ready for this one?
	setTo(radius)

/proc/getScreenSize(widescreen)
	if(widescreen)
		return CONFIG_GET(string/default_view)
	return CONFIG_GET(string/default_view_square)

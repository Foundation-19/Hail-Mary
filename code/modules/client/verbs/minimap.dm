/client/verb/show_station_minimap()
	set category = "OOC"
	set name = "Show World Map"
	set desc = "Shows a minimap of the currently loaded world map."

	if(!CONFIG_GET(flag/minimaps_enabled))
		to_chat(usr, span_boldwarning("Minimap generation is not enabled in the server's configuration."))
		return
	if(!SSminimaps.station_minimap)
		to_chat(usr, span_boldwarning("Minimap generation is in progress, please wait! The map will open automatically once it's ready."))
		SSminimaps.waiting_for_map |= usr
		return
	SSminimaps.station_minimap.ui_interact(usr)

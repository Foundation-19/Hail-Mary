// Brotherhood of Steel R&D Console
// Links to BOS techweb instead of science techweb

/obj/machinery/computer/rdconsole/bos
	name = "Brotherhood R&D Console"
	desc = "A specialized research terminal for Brotherhood of Steel technology development."
	req_access = list(ACCESS_BOS)
	icon_screen = "rdcomp"
	icon_keyboard = "rd_key"

/obj/machinery/computer/rdconsole/bos/Initialize()
	. = ..()
	stored_research = SSresearch.bos_tech
	if(stored_research)
		stored_research.consoles_accessing[src] = TRUE
	SyncRDevices()

/obj/machinery/computer/rdconsole/bos/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResearchConsole")
		ui.open()

/obj/machinery/computer/rdconsole/bos/ui_data(mob/user)
	. = ..()
	.["faction"] = "bos"
	.["faction_name"] = "Brotherhood of Steel"

// ============ BOS PROTOLATHE ============

/obj/machinery/rnd/production/protolathe/bos
	name = "Brotherhood Protolathe"
	desc = "A manufacturing unit for Brotherhood of Steel technology."
	req_access = list(ACCESS_BOS)

/obj/machinery/rnd/production/protolathe/bos/Initialize()
	. = ..()
	stored_research = SSresearch.bos_tech
	if(stored_research)
		stored_research.consoles_accessing[src] = TRUE

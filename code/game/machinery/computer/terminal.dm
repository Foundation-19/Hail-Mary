/obj/machinery/computer/terminal
	name = "desktop terminal"
	desc = "A RobCo Industries terminal, widely available for commercial and private use before the war."
	icon_state = "terminal"
	icon_keyboard = "terminal_key"
	icon_screen = "terminal_on_alt"
	connectable = FALSE
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/robco_terminal
	var/broken = FALSE // Used for pre-broken terminals
	var/prog_notekeeper = TRUE // Almost all consoles have the word processor installed, but we can remove it if we want to
	var/termtag = "Home" // We use this for flavor.
	var/termnumber = null // Flavor
	var/mode = 0 // What page we're on. 0 is the main menu.

// Document variables
	var/doc_title_1 = "readme"
	var/doc_content_1 = ""
	var/doc_title_2 = ""
	var/doc_content_2 = ""
	var/doc_title_3 = ""
	var/doc_content_3 = ""
	var/doc_title_4 = ""
	var/doc_content_4 = ""
	var/doc_title_5 = ""
	var/doc_content_5 = ""
	var/loaded_title = ""
	var/loaded_content = ""

// Notekeeper vars
	var/notehtml = ""
	var/note = "ERR://null-data #236XF51"

/obj/machinery/computer/terminal/Initialize()
	. = ..()

	if(!broken)
		desc = "[initial(desc)] Remarkably, it still works."
		termnumber = rand(69,420) // Unlikely to get two identical numbers.
//		write_documents()
	else
		desc = "[initial(desc)] Unfortunately, this one seems to have broken down."

/obj/machinery/computer/terminal/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	var/dat = ""
	dat += "<head><style>body {padding: 0; margin: 15px; background-color: #062113; color: #4aed92; line-height: 170%;} a, button, a:link, a:visited, a:active, .linkOn, .linkOff {color: #4aed92; text-decoration: none; background: #062113; border: none; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a:hover {color: #062113; background: #4aed92; border: 1px solid #4aed92} a.white, a.white:link, a.white:visited, a.white:active {color: #4aed92; text-decoration: none; background: #4aed92; border: 1px solid #161616; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a.white:hover {color: #062113; background: #4aed92;} .linkOn, a.linkOn:link, a.linkOn:visited, a.linkOn:active, a.linkOn:hover {color: #4aed92; background: #062113; border-color: #062113;} .linkOff, a.linkOff:link, a.linkOff:visited, a.linkOff:active, a.linkOff:hover{color: #4aed92; background: #062113; border-color: #062113;}</style></head><font face='courier'>"
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"

	switch (mode)
		if (0) // If we're on the home page
			dat += "= [termtag] Terminal [termnumber] =</center>"
		if (1) // If we're in the word processor
			dat += "= RobCo Word Processor V.22 =</center>"
		if (2) // If we're viewing a document
			dat += "= [loaded_title] =</center>"
	dat += "<br>"
// The next line is the death of hope. Gaze not longer upon it than you need to.
	switch (mode)
		if (0)
			if(prog_notekeeper)
				dat += "TERMINAL FUNCTIONS"
				dat += "<br><a href='byond://?src=[REF(src)];choice=1'>\>  Word Processor</a>"
				dat += "<br><br>"
			dat += "FILE SYSTEM"

			if(doc_title_1)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_1'>\>  [doc_title_1]</a>"
			if(doc_title_2)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_2'>\>  [doc_title_2]</a>"
			if(doc_title_3)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_3'>\>  [doc_title_3]</a>"
			if(doc_title_4)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_4'>\>  [doc_title_4]</a>"
			if(doc_title_5)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_5'>\>  [doc_title_5]</a>"

		if (1)
			dat += "</center><font face=\"Courier\">[(!notehtml ? note : notehtml)]</font>"

		if (2)
			dat += "[loaded_content]"

	if (mode)
		dat += "<br><br><center>=============================================================================</center>"
		if(mode == 1)
			dat += "<a href='byond://?src=[REF(src)];choice=Edit'>\>  Edit</a><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=Return'>\>  Return</a>"


	dat += "</font></div>"

	var/datum/browser/popup = new(user, "terminal", null, 600, 400)
	popup.set_content(dat)
//	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/computer/terminal/Topic(href, href_list)
	..()
	var/mob/living/U = usr

	if(usr.canUseTopic(src) && !href_list["close"])
		add_fingerprint(U)
		U.set_machine(src)

		switch(href_list["choice"])

// Notekeeper

			if ("Edit")
				var/n = stripped_multiline_input(U, "Please enter message", name, note, max_length=MAX_MESSAGE_LEN * 4) //Probably not abusable?? I'd be surprised if anyone managed to crash anything with this
				if (in_range(src, U))
					if (mode == 1 && n)
						note = n
						notehtml = parsemarkdown(n, U)
				else
					return

// Files - We assign the datum information to the loaded_ variables so we don't need a different page for each document

			if ("doc_1")
				loaded_title = doc_title_1
				loaded_content = doc_content_1
				mode = 2
			if ("doc_2")
				loaded_title = doc_title_2
				loaded_content = doc_content_2
				mode = 2
			if ("doc_3")
				loaded_title = doc_title_3
				loaded_content = doc_content_3
				mode = 2
			if ("doc_4")
				loaded_title = doc_title_4
				loaded_content = doc_content_4
				mode = 2
			if ("doc_5")
				loaded_title = doc_title_5
				loaded_content = doc_content_5
				mode = 2

// Return

			if("Return")
				if(mode) // If we're not on the home page...
					mode = 0 // Take us there

// Menu functions
			if ("1")
				mode = 1

	updateUsrDialog()
	return
/*
/obj/machinery/computer/terminal/proc/write_documents()
	if (doc_title_1)
		var/file_in_memory = text2path("/datum/terminal/document/[doc_title_1]")
		var/datum/terminal/document/N = new file_in_memory
		doc_title_1 = "[N.title]"
		doc_content_1 = "[N.content]"
	if (doc_title_2)
		var/file_in_memory = text2path("/datum/terminal/document/[doc_title_2]")
		var/datum/terminal/document/N = new file_in_memory
		doc_title_2 = "[N.title]"
		doc_content_2 = "[N.content]"
	if (doc_title_3)
		var/file_in_memory = text2path("/datum/terminal/document/[doc_title_3]")
		var/datum/terminal/document/N = new file_in_memory
		doc_title_3 = "[N.title]"
		doc_content_3 = "[N.content]"
	if (doc_title_4)
		var/file_in_memory = text2path("/datum/terminal/document/[doc_title_4]")
		var/datum/terminal/document/N = new file_in_memory
		doc_title_4 = "[N.title]"
		doc_content_4 = "[N.content]"
	if (doc_title_5)
		var/file_in_memory = text2path("/datum/terminal/document/[doc_title_5]")
		var/datum/terminal/document/N = new file_in_memory
		doc_title_5 = "[N.title]"
		doc_content_5 = "[N.content]"

	return
*/

/obj/machinery/computer/terminal/grognak2 // original story by skubblers, #1 jerry reed fan

/obj/machinery/computer/terminal/grognak2/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	var/dat = ""
	dat += "<head><style>body {padding: 0; margin: 15px; background-color: #062113; color: #4aed92; line-height: 170%;} a, button, a:link, a:visited, a:active, .linkOn, .linkOff {color: #4aed92; text-decoration: none; background: #062113; border: none; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a:hover {color: #062113; background: #4aed92; border: 1px solid #4aed92} a.white, a.white:link, a.white:visited, a.white:active {color: #4aed92; text-decoration: none; background: #4aed92; border: 1px solid #161616; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a.white:hover {color: #062113; background: #4aed92;} .linkOn, a.linkOn:link, a.linkOn:visited, a.linkOn:active, a.linkOn:hover {color: #4aed92; background: #062113; border-color: #062113;} .linkOff, a.linkOff:link, a.linkOff:visited, a.linkOff:active, a.linkOff:hover{color: #4aed92; background: #062113; border-color: #062113;}</style></head><font face='courier'>"
	dat += "<center><b>GROGNAK THE BARBARIAN: THROWING THE DAGGER INTO THE HEART OF THE INVOKER</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 HUBRIS COMICS</b><br>"
	dat += "<br>"

	switch (mode)
		if (0) // If we're on the home page
			dat += "Dark incantations reverberate far overhead in the halls of the dreaded Invoker, and your vengeful gaze is drawn to the jeering, demonic murals painted on the apse towering above... their laughter mingles with the INVOKER'S LITANY, as he imbues his putrid congregation with LIES!"
		if (1) // If we're in the word processor
			dat += "Dark incantations reverberate far overhead in the halls of the dreaded Invoker, and your vengeful gaze is drawn to the jeering, demonic murals painted on the apse towering above... their laughter mingles with the INVOKER'S LITANY, as he imbues his putrid congregation with LIES!"
		if (2) // If we're viewing a document
			dat += "[loaded_title]"
	dat += "<br>"

/obj/machinery/computer/terminal/grognak
	name = "desktop terminal"
	desc = "A RobCo Industries terminal, widely available for commercial and private use before the war."
	icon_state = "terminal"
	icon_keyboard = "terminal_key"
	icon_screen = "terminal_on_alt"
	connectable = FALSE
	light_color = LIGHT_COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/robco_terminal

/obj/machinery/computer/terminal/grognak/Initialize()
	. = ..()

	if(!broken)
		desc = "[initial(desc)] Remarkably, it still works."
		termnumber = rand(69,420) // Unlikely to get two identical numbers.
//		write_documents()
	else
		desc = "[initial(desc)] Unfortunately, this one seems to have broken down."

/obj/machinery/computer/terminal/grognak/ui_interact(mob/user)
	. = ..()
	if(broken)
		return

	var/dat = ""
	dat += "<head><style>body {padding: 0; margin: 15px; background-color: #062113; color: #4aed92; line-height: 170%;} a, button, a:link, a:visited, a:active, .linkOn, .linkOff {color: #4aed92; text-decoration: none; background: #062113; border: none; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a:hover {color: #062113; background: #4aed92; border: 1px solid #4aed92} a.white, a.white:link, a.white:visited, a.white:active {color: #4aed92; text-decoration: none; background: #4aed92; border: 1px solid #161616; padding: 1px 4px 1px 4px; margin: 0 2px 0 0; cursor:default;} a.white:hover {color: #062113; background: #4aed92;} .linkOn, a.linkOn:link, a.linkOn:visited, a.linkOn:active, a.linkOn:hover {color: #4aed92; background: #062113; border-color: #062113;} .linkOff, a.linkOff:link, a.linkOff:visited, a.linkOff:active, a.linkOff:hover{color: #4aed92; background: #062113; border-color: #062113;}</style></head><font face='courier'>"
	dat += "<center><b>GROGNAK THE BARBARIAN: FROM THE DEPTHS OF DOOMTOPIA</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 HUBRIS COMICS</b><br>"
	dat += "<br>"

	switch (mode)
		if (0) // If we're on the home page
			dat += "The Goblin war party watches you with trepidation, only the Goblin War Chief seems to possess no fear of you, he chitters arrogantly and his men begin approaching you. You feel the need, the need to cleave."
		if (1) // If we're in the word processor
			dat += "The Goblin war party watches you with trepidation, only the Goblin War Chief seems to possess no fear of you, he chitters arrogantly and his men begin approaching you. You feel the need, the need to cleave."
		if (2) // If we're viewing a document
			dat += "[loaded_title]"
	dat += "<br>"
// The next line is the death of hope. Gaze not longer upon it than you need to.
	switch (mode)
		if (0)

			if(doc_title_1)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_1'>\>  [doc_title_1]</a>"
			if(doc_title_2)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_2'>\>  [doc_title_2]</a>"
			if(doc_title_3)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_3'>\>  [doc_title_3]</a>"
			if(doc_title_4)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_4'>\>  [doc_title_4]</a>"
			if(doc_title_5)
				dat += "<br><a href='byond://?src=[REF(src)];choice=doc_5'>\>  [doc_title_5]</a>"

		if (1)
			dat += "</center><font face=\"Courier\">[(!notehtml ? note : notehtml)]</font>"

		if (2)
			dat += "[loaded_content]"

	if (mode)
		dat += "<br><br><center>=============================================================================</center>"
		if(mode == 1)
			dat += "<a href='byond://?src=[REF(src)];choice=Edit'>\>  Edit</a><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=Return'>\>  Return</a>"


	dat += "</font></div>"

	var/datum/browser/popup = new(user, "terminal", null, 600, 400)
	popup.set_content(dat)
//	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/computer/terminal/grognak/Topic(href, href_list)
	..()
	var/mob/living/U = usr

	if(usr.canUseTopic(src) && !href_list["close"])
		add_fingerprint(U)
		U.set_machine(src)

		switch(href_list["choice"])
	
	// Notekeeper

			if ("Edit")
				var/n = stripped_multiline_input(U, "Please enter message", name, note, max_length=MAX_MESSAGE_LEN * 4) //Probably not abusable?? I'd be surprised if anyone managed to crash anything with this
				if (in_range(src, U))
					if (mode == 1 && n)
						note = n
						notehtml = parsemarkdown(n, U)
				else
					return

// Files - We assign the datum information to the loaded_ variables so we don't need a different page for each document

			if ("doc_1")
				loaded_title = doc_title_1
				loaded_content = doc_content_1
				mode = 2
			if ("doc_2")
				loaded_title = doc_title_2
				loaded_content = doc_content_2
				mode = 2
			if ("doc_3")
				loaded_title = doc_title_3
				loaded_content = doc_content_3
				mode = 2
			if ("doc_4")
				loaded_title = doc_title_4
				loaded_content = doc_content_4
				mode = 2
			if ("doc_5")
				loaded_title = doc_title_5
				loaded_content = doc_content_5
				mode = 2

// Return

			if("Return")
				if(mode) // If we're not on the home page...
					mode = 0 // Take us there

// Menu functions
			if ("1")
				mode = 1

	updateUsrDialog()
	return

/obj/machinery/computer/terminal/batlimore
	name = "Baltimore Robco Terminal"
	desc = "A RobCo Industries terminal, widely available for commercial and private use before the war. Unlike the other more standart one, those often have written logs."
	light_color = LIGHT_COLOR_BLUE
	color = "#bfbfff"

/obj/machinery/computer/terminal/batlimore/atlanticcross
	doc_title_1 = "Operation in Area"
	doc_content_1 = "01/01/2288 - (FROM : Fleet Captain Annie Helo) (TO: ACHS Aegis).\
	\
	For this year, the AEGIS refit, now alone is too keep relation with town and brotherhood at a best.\
	Remember to get paid from the people we heal. We also must protect our interess, and funds, so take down of concurence, by peacefull or lethal means have been authorised."
	doc_title_2 = "Price suggestion"
	doc_content_2 = "01/01/2288 - (FROM : Fleet Captain Annie Helo) (TO: ACHS Aegis).\
	\
	Medical Check up : 20 caps \
	Radiation heal : 30 caps \
	Revival : 50 caps \
	Don't hesiate to take the caps, leave a note of payement."

/obj/machinery/computer/terminal/batlimore/minutemen
	doc_title_1 = " Third company and Locust town Settelment"
	doc_content_1 = "04/02/2288 - (FROM : COLONEL KIRKLAND) (TO : Active MAJOR)\
	\
	Unlike our commonthwealth settlements, we hold little power here for now, but the people like us.\
	The general ordered your company protect this town."
	doc_title_2 = "Brotherhood Alliance"
	doc_content_2 = "04/02/2288 - (FROM : COLONEL KIRKLAND) (TO : Active MAJOR)\
	\
	Our Alliance with the brotherhood isn't stable.\
	They act on paranoia, and secrecy \
	Even with the institute gone, many are sure that our members may be synths \
	All mens, be very carefull."

/obj/machinery/computer/terminal/batlimore/minutemen/town
	doc_title_1 = " Third company and Locust town Settelment"
	doc_content_1 = "04/02/2288 - (FROM : COLONEL KIRKLAND) (TO : Active MAJOR)\
	\
	Unlike our commonthwealth settlements, we hold little power here for now, but the people like us.\
	The general ordered your company protect this town."
	doc_title_2 = "Brotherhood Alliance"
	doc_content_2 = "04/02/2288 - (FROM : COLONEL KIRKLAND) (TO : Active MAJOR)\
	\
	Our Alliance with the brotherhood isn't stable.\
	They act on paranoia, and secrecy \
	Even with the institute gone, many are sure that our members may be synths \
	All mens, be very carefull."
	doc_title_2 = "Town concerns"
	doc_content_2 = "(Personal note FROM : Mary Dell)\
	\
	Locust town is a town that existed before us minutemens.\
	They seem to have a history with slavery.\
	I am note sure what to think. Sure officialy its... Gone. There low class worker however still are badly treated\
	Mankind often... Well. Often returns to their past self, ill let the others decide what to."

/obj/machinery/computer/terminal/batlimore/portmary
	doc_title_1 = "ET MERDE LES FEDERAUX - 08/10/2077"
	doc_content_1 = "08/07/2077 - (DE : Captain Lucas) (A : Marseille Fast Transit)\
	\
	MEC, les RICAINS sont en TRAIN de traquer le navire ! Foutu control de TARRIF, si on se fait prendres il vont trouver les armes a BORD !\
	(Robco Translation :) DUDE, the (Yankees) ARE tracking the shit ! (Fucking) TARIFS control, if we are caught, they will find our guns ONBOARD !"
	doc_title_2 = "Ne t'inquiete pas - 12/10/2077"
	doc_content_2 = "12/07/2077 - (DE : Marseille Fast Transit) (A : Captain Lucas)\
	\
	Ne t'inquiete pas. Je connais le directeur d'un des ports de Baltimore. Amare le Port Mary, met les gars armer sur les quais, et tient bon. Un bon deal. Tous se qu'on avait avait a a faire était the prendre de conteneur fait en plomb.\
	(Robco Translation :) Don't worry. I know the director of one of Balitmore's harbors. Dock the Port Mary, and put some armed guys on the dock, then hold tight. It was a good deal. Only needed to put some lead containers on our side." 
	doc_title_3 = "MEC C'EST LA FIN - 23/10/2077"
	doc_content_3 = "23/10/2077 - (DE : Captain Lucas) (A : Marseille Fast Transit)\
	\
	ON NOUS NUKE !!! LES CONTENEUR SONT A PEINE ARRIVER, ON NOUS NUKE !!! PUTAIN DE MERD-\
	(Robco Translation :) We are getting nuked. The cargo containers just arrived, and we got nuked. Fucking bitc-"

/obj/machinery/computer/terminal/batlimore/recruitementcenter
	doc_title_1 = "Welcome to the Naval Reserve center ! - 12/01/2076"
	doc_content_1 = "Greetings ! And welcome ! Ready to start your sailor adventure ?\
	\
	Head on down to the base ! And start your training. We are happy that you are willing to joint the fight on our seas.\
	Be carefull however ! We have a classified vessel in the drydock ! Do not come close, or Ensign DEADLOCK will have you shot !"

/obj/machinery/computer/terminal/batlimore/recruitementcenter/officer
	doc_title_1 = "Issue with the Ironclad Lander 'USS Iron Shadow' - 21/12/2076"
	doc_content_1 = "(FROM : COMMANDER Leon) (TO : NAVY HQ)\
	\
	While the Hull is finished, the USS Iron Shadow didn't get any of its consoles. Apparently, they will arrive in a year, in December 2077.\
	We wont reach Chinese shores without this lander, and you all know it. So please, act fast before its simply too late ! In the mean time, I have put Ensign DEADLOCK inside, to make sure no one takes a peak."

	doc_title_2 = "Northwestern Harbors Control - 01/09/2076"
	doc_content_2 = "(FROM : COMMANDER Leon) (TO : NAVY HQ)\
	\
	The Navy took control of the other side of Patapsco river, and removed all marinas to instead add more warehouses.\
	I don't know what you are planning, but it should grant us more space. Since the local base is staffed by low ranking recruit, we put down turrets. However. Please note the calibers have been reduced to 22LR. It should detert any curious civilian.\
	The squad of Gutsy we got should deal with any armed oposition."

/obj/machinery/computer/terminal/batlimore/brotherhood
	doc_title_1 = "Issue with the Ironclad Lander 'USS Iron Shadow' - 21/12/2076"
	doc_content_1 = "(FROM : COMMANDER Leon) (TO : NAVY HQ)\
	\
	While the Hull is finished, the USS Iron Shadow didn't get any of its consoles. Apparently, they will arrive in a year, in December 2077.\
	We wont reach Chinese shores without this lander, and you all know it. So please, act fast before its simply too late ! In the mean time, I have put Ensign DEADLOCK inside, to make sure no one takes a peak."


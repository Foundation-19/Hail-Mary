//Courier Job
// Basically ? Those item can be bought and sold at vending machines all arround the waste.
// To be tested with baltimore.

/obj/item/package
	name = "Courrier package"
	desc = "A package that must be bought then delivered to another. Notify the devs if you see it."
	icon = 'icons/obj/fallout/lockbox.dmi'
	icon_state = "caravan"
	item_state = "caravan"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/south
	name = "South Caravan Courrier package"
	desc = "A package from the south Baltimore Carvans to be delivered North. It seems to contain various items.\
	Prices : \
	Town : 7 caps\
	Train station : 8 caps\
	Fells point Caravaners : 12 caps\
	Mchenry tunnel : 10 caps"

	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/town
	name = "Town Courrier package"
	desc = "A package from Locust Town to be delivered to other baltimore places. What is inside, you don't know, but its often booze.\
	Prices : \
	South Caravaner : 8 caps\
	Train station : 7 caps\
	Fells point Caravaners : 10 caps\
	Mchenry tunnel : 7 caps"

	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/train
	name = "Train Station Courrier package"
	desc = "A package from the train station to be delivered north. Most of the times, its only letters.\
	Prices : \
	Town : 8 caps\
	South Caravaner : 8 caps\
	Fells point Caravaners : 7 caps\
	Mchenry tunnel : 12 caps"

	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/fells
	name = "Fells point Caravaners Courrier package"
	desc = "A package from the Fells point caravaners. They often trade water and food.\
	Prices : \
	Town : 10 caps\
	South Caravaner : 12 caps\
	Train station : 8 caps\
	Mchenry tunnel : 10 caps"

	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/mchenry
	name = "Mchenry Trade Kingdom Courrier package"
	desc = "A package from the Mc Henry Trade Kingdom, another settlement more east, raiders turned traders. They exchange a lot of various goods of doubious origins.\
	Prices : \
	Town : 7 caps\
	South Caravaner : 7 caps\
	Fells point Caravaners : 10 caps\
	Train station : 12 caps"

	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY


//faction secret paper

/obj/item/paper/fluff/minutemen
	name = "Minutemen operation plans"
	desc = "A secret document, very classified and should not fall in bad hands."
	info = "<b> THIS DOCUMENT CONTAINS ALL OPERATION IN BALTIMORE FOR THE NEXT YEARS</b>"

/obj/item/paper/fluff/brotherhood
	name = "Brotherhood operation plans"
	desc = "A secret document, very classified and should not fall in bad hands."
	info = "<b> THIS DOCUMENT CONTAINS ALL OPERATION IN BALTIMORE FOR THE NEXT YEARS</b>"

/obj/item/paper/fluff/vault125
	name = "Vault 125 operation plans"
	desc = "A secret document, very classified and should not fall in bad hands."
	info = "<b> THIS DOCUMENT CONTAINS ALL OPERATION IN BALTIMORE FOR THE NEXT YEARS</b>"

/obj/item/paper/fluff/enclave
	name = "Enclave operation plans"
	desc = "A secret document, very classified and should not fall in bad hands."
	info = "<b> THIS DOCUMENT CONTAINS ALL OPERATION IN BALTIMORE FOR THE NEXT YEARS</b>"

/obj/item/paper/fluff/institute
	name = "Institute operation plans"
	desc = "A secret document, very classified and should not fall in bad hands."
	info = "<b> THIS DOCUMENT CONTAINS ALL OPERATION IN BALTIMORE FOR THE NEXT YEARS</b>"

//GUN BUYER

/obj/machinery/mineral/wasteland_trader/caravan
	name = "Caravan depot"
	icon_state = "caravandepot_idle"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/town = 5,
						/obj/item/package/train = 5,
						/obj/item/package/fells = 5,)

/obj/machinery/mineral/wasteland_trader/caravan/Topic(href, href_list)
	if(..())
		return
	if(href_list["choice"] == "eject")
		remove_all_caps()
	if(href_list["purchase"])
		var/datum/data/wasteland_equipment/prize = locate(href_list["purchase"])
		if (!prize || !(prize in prize_list))
			to_chat(usr, span_warning("Error: Invalid choice!"))
			return
		if(prize.cost > stored_caps)
			to_chat(usr, span_warning("Error: Insufficent bottle caps value for [prize.equipment_name]!"))
		else
			stored_caps -= prize.cost
			GLOB.vendor_cash += prize.cost
			to_chat(usr, span_notice("[src] clanks to life briefly before vending [prize.equipment_name]!"))
			new prize.equipment_path(src.loc)
			SSblackbox.record_feedback("nested tally", "wasteland_equipment_bought", 1, list("[type]", "[prize.equipment_path]"))
	updateUsrDialog()
	return

/obj/machinery/mineral/wasteland_trader/caravan/ui_interact(mob/user)
	. = ..()
	var/dat
	dat +="<div class='statusDisplay'>"
	dat += "<b>Bottle caps stored:</b> [stored_caps]. <A href='?src=[REF(src)];choice=eject'>Eject caps</A><br>"
	dat += "</div>"
	dat += "<br>"
	dat +="<div class='statusDisplay'>"
	dat += "<b>Trade is the base of all civilisation.</b><br>"
	dat += "<b>Put the packages in.</b><br>"
	dat += "<b>Buy package at the other machine, then deliver them.</b><br>"
	dat += "</div>"

	var/datum/browser/popup = new(user, "tradingvendor", "Trading point", 400, 500)
	popup.set_content(dat)
	popup.open()
	return

/obj/machinery/mineral/wasteland_trader/caravan/attackby(obj/item/I, mob/user, params)
	/*if(user,FACTION_RAIDERS)
		to_chat(usr, span_warning("Refuses to buy this from you, you dirty Raider !"))
		return
		*/
	add_caps(I)

//caravan traders

/obj/machinery/mineral/wasteland_trader/caravan/south
	name = "South Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/town = 8,
						/obj/item/package/train = 8,
						/obj/item/package/fells = 12,
						/obj/item/package/mchenry = 7,)

/obj/machinery/mineral/wasteland_trader/caravan/town
	name = "Town Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 7,
						/obj/item/package/train = 8,
						/obj/item/package/fells = 10,
						/obj/item/package/mchenry = 7,)

/obj/machinery/mineral/wasteland_trader/caravan/fells
	name = "Fells Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 12,
						/obj/item/package/train = 7,
						/obj/item/package/town = 10,
						/obj/item/package/mchenry = 10,)

/obj/machinery/mineral/wasteland_trader/caravan/train
	name = "Train Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 8,
						/obj/item/package/fells = 8,
						/obj/item/package/town = 7,
						/obj/item/package/mchenry = 12,)

/obj/machinery/mineral/wasteland_trader/caravan/mchenry
	name = "McHenry Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 10,
						/obj/item/package/fells = 10,
						/obj/item/package/town = 7,
						/obj/item/package/train = 12,)


//faction courrier traders

/obj/machinery/mineral/wasteland_trader/caravan/minutemen
	name = "Minutemen Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 11,
						/obj/item/package/fells = 11,
						/obj/item/package/town = 7,
						/obj/item/package/train = 11,
						/obj/item/package/mchenry = 11,)

/obj/machinery/mineral/wasteland_trader/caravan/brotherhood
	name = "Brotherhood Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 7,
						/obj/item/package/fells = 11,
						/obj/item/package/town = 11,
						/obj/item/package/train = 11,
						/obj/item/package/mchenry = 11,)

/obj/machinery/mineral/wasteland_trader/caravan/bandit
	name = "Stolen Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/south = 12,
						/obj/item/package/fells = 12,
						/obj/item/package/town = 12,
						/obj/item/package/train = 12,
						/obj/item/package/mchenry = 12,)

/obj/machinery/mineral/wasteland_trader/caravan/bandit/attackby(obj/item/I, mob/user, params)
	add_caps(I)

//special faction trader

/obj/machinery/mineral/wasteland_trader/special
	name = "Special depot"
	desc = "Place weapon package inside. And get the caps."


/obj/machinery/mineral/wasteland_trader/special/Topic(href, href_list)
	if(..())
		return
	if(href_list["choice"] == "eject")
		remove_all_caps()
	if(href_list["purchase"])
		var/datum/data/wasteland_equipment/prize = locate(href_list["purchase"])
		if (!prize || !(prize in prize_list))
			to_chat(usr, span_warning("Error: Invalid choice!"))
			return
		if(prize.cost > stored_caps)
			to_chat(usr, span_warning("Error: Insufficent bottle caps value for [prize.equipment_name]!"))
		else
			stored_caps -= prize.cost
			GLOB.vendor_cash += prize.cost
			to_chat(usr, span_notice("[src] clanks to life briefly before vending [prize.equipment_name]!"))
			new prize.equipment_path(src.loc)
			SSblackbox.record_feedback("nested tally", "wasteland_equipment_bought", 1, list("[type]", "[prize.equipment_path]"))
	updateUsrDialog()
	return

/obj/machinery/mineral/wasteland_trader/special/ui_interact(mob/user)
	. = ..()
	var/dat
	dat +="<div class='statusDisplay'>"
	dat += "<b>Bottle caps stored:</b> [stored_caps]. <A href='?src=[REF(src)];choice=eject'>Eject caps</A><br>"
	dat += "</div>"
	dat += "<br>"
	dat +="<div class='statusDisplay'>"
	dat += "<b>Item of interess that are to be recovered.</b><br>"
	dat += "<b>Put the items in.</b><br>"
	dat += "</div>"

	var/datum/browser/popup = new(user, "tradingvendor", "Trading point", 400, 500)
	popup.set_content(dat)
	popup.open()
	return

/obj/machinery/mineral/wasteland_trader/special/attackby(obj/item/I, mob/user, params)
	add_caps(I)

/obj/machinery/mineral/wasteland_trader/special/minutemen
	name = "Minutemen exchange system"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/paper/fluff/brotherhood = 500,
						/obj/item/paper/fluff/vault125 = 500,
						/obj/item/paper/fluff/enclave = 500,
						/obj/item/paper/fluff/institute = 500,)

/obj/machinery/mineral/wasteland_trader/special/brotherhood
	name = "Brotherhood exchange system"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/paper/fluff/minutemen = 500,
						/obj/item/paper/fluff/vault125 = 500,
						/obj/item/paper/fluff/enclave = 500,
						/obj/item/paper/fluff/institute = 500,)

/obj/machinery/mineral/wasteland_trader/special/vault125
	name = "Vault125 exchange system"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/paper/fluff/minutemen = 500,
						/obj/item/paper/fluff/brotherhood = 500,
						/obj/item/paper/fluff/enclave = 500,
						/obj/item/paper/fluff/institute = 500,)


/obj/machinery/vending/caravan
	name = "\improper Caravan package trader (not this one)"
	desc = "Not supposed to be here."
	icon_state = "caravan"
	icon_vend = "caravan-vend"
	products = list(/obj/item/package)

	refill_canister = /obj/item/vending_refill/caravan
	default_price = PRICE_REALLY_CHEAP
	payment_department = ACCOUNT_SRV

/obj/machinery/vending/caravan/south
	name = "\improper South Caravan package trader"
	desc = "Here you can buy south caravan packages."

	products = list(/obj/item/package/south)

/obj/machinery/vending/caravan/fells
	name = "\improper Fells Caravan package trader"
	desc = "Here you can buy Fells caravan packages."

	products = list(/obj/item/package/fells)

/obj/machinery/vending/caravan/train
	name = "\improper Train Station Caravan package trader"
	desc = "Here you can buy Train Station caravan packages."

	products = list(/obj/item/package/train)


/obj/machinery/vending/caravan/mchenry
	name = "\improper McHenry Caravan package trader"
	desc = "Here you can buy McHenry caravan packages."

	products = list(/obj/item/package/mchenry)

/obj/machinery/vending/caravan/town
	name = "\improper Town Caravan package trader"
	desc = "Here you can buy Town caravan packages."

	products = list(/obj/item/package/town)

/obj/item/vending_refill/caravan
	machine_name = "Package refilling"
	icon_state = "refill_joe"

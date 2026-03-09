//Courier Job
// Basically ? Those item can be bought and sold at vending machines all arround the waste.
// To be tested with baltimore.

/obj/item/package
	name = "Courrier package"
	desc = "A package that must be bought then delivered to another. Notify the devs if you see it."
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/south
	name = "South Caravan Courrier package"
	desc = "A package from the south Baltimore Carvans to be delivered North. It seems to contain various items.\
	Prices : \
	Town : 10 caps\
	Train station : 15 caps\
	Fells point Caravaners : 25 caps\
	Minutemen allied Supply lines : 15 caps\
	Brotherhood controled trade route : 8 caps\
	Mchenry tunnel : 20 caps"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/town
	name = "Town Courrier package"
	desc = "A package from Locust Town to be delivered to other baltimore places. What is inside, you don't know, but its often booze.\
	Prices : \
	South Caravaner : 10 caps\
	Train station : 15 caps\
	Fells point Caravaners : 15 caps\
	Minutemen allied Supply lines : 5 caps\
	Brotherhood controled trade route : 10 caps\
	Mchenry tunnel : 15 caps"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/train
	name = "Train Station Courrier package"
	desc = "A package from the train station to be delivered north. Most of the times, its only letters.\
	Prices : \
	Town : 10 caps\
	South Caravaner : 15 caps\
	Fells point Caravaners : sciences\
	Minutemen allied Supply lines : 20 caps\
	Brotherhood controled trade route : 20 caps"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/fells
	name = "Fells point Caravaners Courrier package"
	desc = "A package from the Fells point caravaners. They often trade water and food.\
	Prices : \
	Town : 10 caps\
	South Caravaner : 25 caps\
	Train station : sciences\
	Minutemen allied Supply lines : medecin\
	Brotherhood controled trade route : attachement"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/mchenry
	name = "Mchenry Trade Kingdom Courrier package"
	desc = "A package from the Mc Henry Trade Kingdom, another settlement more east, raiders turned traders. They exchange a lot of various goods of doubious origins.\
	Prices : \
	Town : 10 caps\
	South Caravaner : 25 caps\
	Train station : sciences\
	Minutemen allied Supply lines : medecin\
	Brotherhood controled trade route : attachement"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

//GUN BUYER

/obj/machinery/mineral/wasteland_trader/courrier_south
	name = "South Caravan depot"
	desc = "Place weapon package inside. And get the caps."
	goods_list = list(/obj/item/package/town = 5,
						/obj/item/package/train = 5,
						/obj/item/package/fells = 5,)

/obj/machinery/mineral/wasteland_trader/courrier_south/Topic(href, href_list)
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

/obj/machinery/mineral/wasteland_trader/courrier_south/ui_interact(mob/user)
	. = ..()
	var/dat
	dat +="<div class='statusDisplay'>"
	dat += "<b>Bottle caps stored:</b> [stored_caps]. <A href='?src=[REF(src)];choice=eject'>Eject caps</A><br>"
	dat += "</div>"
	dat += "<br>"
	dat +="<div class='statusDisplay'>"
	dat += "<b>Disarming the Wasteland one gun at a time.</b><br>"
	dat += "<b>Warning: The automated system cannot guarantee an accurate appraisal of value.</b><br>"
	dat += "<b>Accepted goods and prices:</b><br>"
	dat += "Pistols and revolvers: 5-10 caps<br>"
	dat += "Rifles and Shotguns : 10-15 caps<br>"
	dat += "Does not accept weapons of historical or artisanal value. Those belong in a musuem."
	dat += ""
	dat += "</div>"

	var/datum/browser/popup = new(user, "tradingvendor", "Trading point", 400, 500)
	popup.set_content(dat)
	popup.open()
	return

/obj/machinery/mineral/wasteland_trader/attackby(obj/item/I, mob/user, params)
	if(user,FACTION_RAIDERS)
		to_chat(usr, span_warning("Refuses to buy this from you, you dirty Raider !"))
		return
	add_caps(I)

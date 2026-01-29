//Courier Job
// Basically ? Those item can be bought and sold at vending machines all arround the waste.
// To be tested with baltimore.

/obj/item/package
	name = "Courrier package"
	desc = "A package that must be bought then delivered to another."
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/south
	name = "South Caravan Courrier package"
	desc = "A package from the south Baltimore Carvans to be delivered North.\
	Prices : \
	Town : 10 caps\
	Train station : 15 caps\
	Fells point Caravaners : 20 caps\
	Minutemen allied Supply lines : 15 caps\
	Brotherhood controled trade route : 8 caps"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/town
	name = "Town Courrier package"
	desc = "A package from the south Baltimore Carvans to be delivered North.\
	Prices : \
	South Caravaner : 10 caps\
	Train station : 15 caps\
	Fells point Caravaners : 20 caps\
	Minutemen allied Supply lines : Food\
	Brotherhood controled trade route : Seeds"
	icon_state = "deliverybox"
	item_state = "deliverybox"
	resistance_flags = FLAMMABLE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE //exploits ahoy
	w_class = WEIGHT_CLASS_BULKY

/obj/item/package/train
	name = "Train Station Courrier package"
	desc = "A package from the south Baltimore Carvans to be delivered North.\
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
	desc = "A package from the south Baltimore Carvans to be delivered North.\
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

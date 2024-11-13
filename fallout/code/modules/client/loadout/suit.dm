/* why is any of this here and not with the rest of the loadout stuff?

/datum/gear/suit/goner_red
	name = "olive drab trenchcoat, red"
	path = /obj/item/clothing/suit/armor/light/duster/goner/red
	cost = 4
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/goner_green
	name = "olive drab trenchcoat, green"
	path = /obj/item/clothing/suit/armor/light/duster/goner/green
	cost = 4
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/goner_blue
	name = "olive drab trenchcoat, blue"
	path = /obj/item/clothing/suit/armor/light/duster/goner/blue
	cost = 4
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/goner_yellow
	name = "olive drab trenchcoat, yellow"
	path = /obj/item/clothing/suit/armor/light/duster/goner/yellow
	cost = 4
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
*/
/* it hurts...why isn't this with the rest of loadout stuff




/datum/gear/uniform/goner_red
	name = "utility uniform, red"
	cost = 1
	path = /obj/item/clothing/under/f13/goner/red

/datum/gear/uniform/goner_green
	name = "utility uniform, green"
	cost = 1
	path = /obj/item/clothing/under/f13/goner/green

/datum/gear/uniform/goner_blue
	name = "utility uniform, blue"
	cost = 1
	path = /obj/item/clothing/under/f13/goner/blue

/datum/gear/uniform/goner_yellow
	name = "utility uniform, yellow"
	cost = 1
	path = /obj/item/clothing/under/f13/goner/yellow
*/


/datum/gear/suit
	category = LOADOUT_CATEGORY_SUIT
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL
	slot = SLOT_WEAR_SUIT

/datum/gear/suit/redhood
	name = "Red cloak"
	path = /obj/item/clothing/suit/hooded/cloak/david
	cost = 2

/datum/gear/suit/labcoat
	name = "Labcoat"
	path = /obj/item/clothing/suit/toggle/labcoat
	cost = 2
/*
/datum/gear/suit/rangercape
	name = "Ranger cape"
	path = /obj/item/clothing/neck/mantle/ranger
	cost = 1
*/
/datum/gear/suit/bomber
	name = "Bomber jacket"
	path = /obj/item/clothing/suit/jacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/bomber/oldjacketbomber
	name = "Old bomber jacket"
	path = /obj/item/clothing/suit/bomber

/// Flannels Below

/datum/gear/suit/flannel
	name = "Red flannel jacket"
	path = /obj/item/clothing/suit/jacket/flannel/red
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/flannel/jacketflannelblack
	name = "Black flannel jacket"
	path = /obj/item/clothing/suit/jacket/flannel

/datum/gear/suit/flannel/jacketflannelaqua
	name = "Aqua flannel jacket"
	path = /obj/item/clothing/suit/jacket/flannel/aqua

/datum/gear/suit/flannel/jacketflannelbrown
	name = "Brown flannel jacket"
	path = /obj/item/clothing/suit/jacket/flannel/brown

/datum/gear/suit/jacketleather
	name = "Leather jacket"
	path = /obj/item/clothing/suit/armor/light/leather/leather_jacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

/datum/gear/suit/overcoatleather
	name = "Leather overcoat"
	path = /obj/item/clothing/suit/jacket/leather/overcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/jacketpuffer
	name = "Puffer jacket"
	path = /obj/item/clothing/suit/jacket/puffer
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/vestpuffer
	name = "Puffer vest"
	path = /obj/item/clothing/suit/jacket/puffer/vest
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/jacketlettermanbrown
	name = "Brown letterman jacket"
	path = /obj/item/clothing/suit/jacket/letterman
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/jacketlettermanred
	name = "Red letterman jacket"
	path = /obj/item/clothing/suit/jacket/letterman_red
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/militaryjacket
	name = "Military Jacket"
	path = /obj/item/clothing/suit/jacket/miljacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 1

/datum/gear/suit/autumn
	name = "tan trenchcoat"
	path = /obj/item/clothing/suit/armor/light/duster/autumn
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

/datum/gear/suit/armorkit
	name = "Armor Kit"
	path = /obj/item/clothing/suit/armor/light/kit
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR 	
	cost = 2

/datum/gear/suit/punkkit
	name = "Punk Armor Kit"
	path = /obj/item/clothing/suit/armor/light/kit/punk
	restricted_desc = "Wastelander"
	restricted_roles = list("Wastelander",
							"Outlaw",
							"Preacher",
							)
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR 	
	cost = 2

/datum/gear/suit/khanjacket // Armor kit reskin defense
	name = "Khan Jacket"
	path = /obj/item/clothing/suit/toggle/labcoat/khan_jacket
	restricted_desc = "Wastelander"
	restricted_roles = list("Wastelander",
							"Outlaw",
							)
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 2

/datum/gear/suit/flak
	name = "Flak Jacket"
	path = /obj/item/clothing/suit/armor/medium/vest/flak
	restricted_desc = "Wastelander"
	restricted_roles = list("Wastelander",
							"Outlaw",
							)
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR 	
	cost = 4

/datum/gear/suit/town
	name = "Town Security Armor"
	path = /obj/item/clothing/suit/armor/medium/vest/blueshirt
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR 	
	cost = 4
	restricted_desc = "Eastwood"
	restricted_roles = list("Mayor",
							"Secretary",
							"Sheriff",
							"Doctor",
							"Citizen",
							"Deputy",
							"Shopkeeper",
							"Farmer",
							"Prospector",
							"Detective",
							"Barkeep",
							"Radio Host"
							)

/datum/gear/suit/samurai  //added by TK420634 ~ 5/29/2022 "Samurai Wasteland WeebShit Edition (tm)
	name = "Rusted Samurai Armor"
	path = /obj/item/clothing/suit/samurai
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

/datum/gear/suit/rustedcowboy
	name = "Rusted Cowboy Outfit"
	path = /obj/item/clothing/suit/armor/light/duster/rustedcowboy
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/rain_coat
	name = "Sniper Raincoat"
	path= /obj/item/clothing/suit/rain_coat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/marlowsuit
	name = "Marlow Gang Overcoat"
	path= /obj/item/clothing/suit/armor/light/duster/marlowsuit
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/ikesuit
	name = "Gunfighter Overcoat"
	path= /obj/item/clothing/suit/armor/light/duster/marlowsuit/ikesuit
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/masonsuit
	name = "Vagabond Vest"
	path= /obj/item/clothing/suit/armor/light/duster/marlowsuit/masonsuit
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/townduster
	name = "Black Trenchcoat"
	path= /obj/item/clothing/suit/armor/light/duster/town
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/harpercoat
	name = "Outlaw Coat"
	path= /obj/item/clothing/suit/armor/harpercoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/dustervet
	name = "Merc Veteran Coat"
	path= /obj/item/clothing/suit/armor/light/duster/vet
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/desperado
	name = "Desperado Duster"
	path= /obj/item/clothing/suit/armor/light/duster/desperado
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

datum/gear/suit/leatherarmor
	name = "Leather Armor"
	path= /obj/item/clothing/suit/armor/light/leather
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/tanvest
	name = "Tanned Vest"
	path= /obj/item/clothing/suit/armor/light/leather/tanvest
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/ironchestplate	////Armor kit reskin
	name = "Old Iron Chestplate"
	path= /obj/item/clothing/suit/armor/light/kit/punk/ironchestplate
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/scaledarmor
	name = "Scaled Armor"
	path= /obj/item/clothing/suit/armor/light/kit/punk/scaledarmor
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/roughchainmail
	name = "Rough Chainmail"
	path= /obj/item/clothing/suit/armor/light/kit/punk/roughchainmail
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/fullchainmail
	name = "Chainmail Shirt"
	path= /obj/item/clothing/suit/armor/light/kit/punk/fullchainmail
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 4

datum/gear/suit/ironchestplatered
	name = "Caped Iron Chestplate (Red)"
	path= /obj/item/clothing/suit/armor/light/kit/punk/ironchestplatered
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/ironchestplateblue
	name = "Caped Iron Chestplate (Blue)"
	path= /obj/item/clothing/suit/armor/light/kit/punk/ironchestplateblue
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 3

datum/gear/suit/oldscalemail
	name = "Old Scalemail"
	path= /obj/item/clothing/suit/armor/light/kit/punk/oldscalemail
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 2

datum/gear/suit/chitinbreastplate
	name = "Chitin Breastplate"
	path= /obj/item/clothing/suit/armor/light/kit/punk/chitinbreastplate
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 2

datum/gear/suit/hazmat
	name = "Hazmat Suit"
	path= /obj/item/clothing/suit/bio_suit/hazmat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_ARMOR
	cost = 4

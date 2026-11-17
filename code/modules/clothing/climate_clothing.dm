// How clothing behaves in the climate system, see code/modules/mob/living/carbon/human/climate.dm.
// climate_warmth scales how much an item keeps the cold out, climate_heat_trap how much it holds heat in. Both default to 1
// (ordinary cloth or leather). Subtypes inherit from their parents, so only the families that differ are listed here.
// Rule of thumb: fur and thick fabric are warm, plate and rags are not, and anything sealed or plated cooks you in the sun.

// ---- Suits ----
/obj/item/clothing/suit/armor/light/duster // loose, ventilated and good in the desert
	climate_heat_trap = 0.8

/obj/item/clothing/suit/armor/light/tribal // hides, furs and bone
	climate_warmth = 1.3
	climate_heat_trap = 0.9

/obj/item/clothing/suit/armor/outfit // fabric vests and jackets
	climate_heat_trap = 0.9

/obj/item/clothing/suit/armor/outfit/jacket
	climate_warmth = 1.2
	climate_heat_trap = 1

/obj/item/clothing/suit/armor/medium
	climate_warmth = 0.9
	climate_heat_trap = 1.2

/obj/item/clothing/suit/armor/medium/duster
	climate_warmth = 1
	climate_heat_trap = 0.9

/obj/item/clothing/suit/armor/heavy
	climate_warmth = 0.7
	climate_heat_trap = 1.5

/obj/item/clothing/suit/armor/heavy/tribal
	climate_warmth = 0.9
	climate_heat_trap = 1.3

/obj/item/clothing/suit/hooded/wintercoat
	climate_warmth = 1.5
	climate_heat_trap = 1.3

/obj/item/clothing/suit/hooded/parka
	climate_warmth = 1.6
	climate_heat_trap = 1.3

/obj/item/clothing/suit/hooded/cloak
	climate_warmth = 1.2
	climate_heat_trap = 0.7

/obj/item/clothing/suit/toggle/labcoat
	climate_warmth = 0.9
	climate_heat_trap = 0.9

/obj/item/clothing/suit/bio_suit
	climate_heat_trap = 2

/obj/item/clothing/suit/space
	climate_warmth = 1.5
	climate_heat_trap = 2

/obj/item/clothing/suit/fire
	climate_warmth = 1.2
	climate_heat_trap = 1.8

// ---- Hats and helmets ----
/obj/item/clothing/head/helmet
	climate_warmth = 0.8
	climate_heat_trap = 1.4

/obj/item/clothing/head/helmet/space
	climate_warmth = 1.5
	climate_heat_trap = 2

/obj/item/clothing/head/hardhat
	climate_warmth = 0.8
	climate_heat_trap = 1.2

/obj/item/clothing/head/welding
	climate_warmth = 0.8
	climate_heat_trap = 1.5

/obj/item/clothing/head/bio_hood
	climate_heat_trap = 2

/obj/item/clothing/head/hooded/winterhood
	climate_warmth = 1.8
	climate_heat_trap = 1.2

/obj/item/clothing/head/ushanka
	climate_warmth = 2
	climate_heat_trap = 1.2

/obj/item/clothing/head/coyote // pelts and fur hats
	climate_warmth = 1.8
	climate_heat_trap = 1.1

/obj/item/clothing/head/f13/cowboy // wide brims shade the head and let it breathe
	climate_warmth = 0.6
	climate_heat_trap = 0.5

/obj/item/clothing/head/f13/headscarf
	climate_warmth = 0.8
	climate_heat_trap = 0.5

/obj/item/clothing/head/helmet/f13/brahmincowboyhat
	climate_warmth = 0.6
	climate_heat_trap = 0.5

/obj/item/clothing/head/helmet/f13/rustedcowboyhat
	climate_warmth = 0.6
	climate_heat_trap = 0.5

// ---- Neck ----
/obj/item/clothing/neck // ties and the like add next to nothing
	climate_warmth = 0.4
	climate_heat_trap = 0.4

/obj/item/clothing/neck/scarf
	climate_warmth = 2
	climate_heat_trap = 1.1

/obj/item/clothing/neck/mantle
	climate_warmth = 1.5
	climate_heat_trap = 1

/obj/item/clothing/neck/mantle/peltfur
	climate_warmth = 2.5
	climate_heat_trap = 1.2

/obj/item/clothing/neck/mantle/ragged
	climate_warmth = 1
	climate_heat_trap = 0.8

/obj/item/clothing/neck/mantle/poncho
	climate_warmth = 1.5
	climate_heat_trap = 0.6

// ---- Masks ----
/obj/item/clothing/mask
	climate_warmth = 0.5
	climate_heat_trap = 0.5

/obj/item/clothing/mask/cigarette
	climate_warmth = 0
	climate_heat_trap = 0

/obj/item/clothing/mask/gas
	climate_warmth = 1
	climate_heat_trap = 1.5

/obj/item/clothing/mask/bandana
	climate_warmth = 1
	climate_heat_trap = 0.6

/obj/item/clothing/mask/balaclava
	climate_warmth = 2.5
	climate_heat_trap = 1

// ---- Uniforms ----
/obj/item/clothing/under/f13/rag
	climate_warmth = 0.5
	climate_heat_trap = 0.7

/obj/item/clothing/under/f13/raiderrags
	climate_warmth = 0.5
	climate_heat_trap = 0.7

/obj/item/clothing/under/f13/slaverags
	climate_warmth = 0.5
	climate_heat_trap = 0.7

/obj/item/clothing/under/f13/tribal
	climate_warmth = 0.7
	climate_heat_trap = 0.8

/obj/item/clothing/under/f13/female/tribal
	climate_warmth = 0.7
	climate_heat_trap = 0.8

/obj/item/clothing/under/f13/exile/tribal
	climate_warmth = 0.7
	climate_heat_trap = 0.8

/obj/item/clothing/under/civ/mayan_loincloth
	climate_warmth = 0.6
	climate_heat_trap = 0.6

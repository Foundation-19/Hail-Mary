// Toy/foam-dart ammo boxes, split out from boxes_magazines/lore/ammo_boxes.dm

/obj/item/ammo_box/foambox
	name = "ammo box (Foam Darts)"
	icon = 'icons/obj/guns/toy.dmi'
	icon_state = "foambox"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart
	caliber = list(CALIBER_FOAM)
	max_ammo = 40
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron = MATS_PISTOL_HEAVY_BOX)

/obj/item/ammo_box/foambox/mag
	name = "ammo box (Magnetic Foam Darts)"
	icon = 'icons/obj/guns/toy.dmi'
	icon_state = "foambox"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/mag
	max_ammo = 42

/obj/item/ammo_box/foambox/riot
	icon_state = "foambox_riot"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/riot
	custom_materials = list(/datum/material/iron = MATS_PISTOL_HEAVY_BOX)

/obj/item/ammo_box/foambox/tag
	name = "ammo box (Lastag Foam Darts)"
	icon = 'icons/obj/guns/toy.dmi'
	icon_state = "foambox"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/tag
	max_ammo = 40
	color = "#FF00FF"

/obj/item/ammo_box/foambox/tag/red
	name = "ammo box (Lastag Red Foam Darts)"
	icon = 'icons/obj/guns/toy.dmi'
	icon_state = "foambox"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/tag/red
	max_ammo = 40
	color = "#FF0000"

/obj/item/ammo_box/foambox/tag/blue
	name = "ammo box (Lastag Blue Foam Darts)"
	icon = 'icons/obj/guns/toy.dmi'
	icon_state = "foambox"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/tag/blue
	max_ammo = 40
	color = "#0000FF"

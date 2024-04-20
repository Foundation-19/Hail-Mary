//This is the file that handles donator loadout items.

/datum/gear/donator
	name = "IF YOU SEE THIS, PING A CODER RIGHT NOW!"
	slot = SLOT_IN_BACKPACK
	path = /obj/item/storage/belt/shoulderholster/ranger45
	category = LOADOUT_CATEGORY_DONATOR
	ckeywhitelist = list("This entry should never appear with this variable set.") //If it does, then that means somebody fucked up the whitelist system pretty hard
	cost = 0
/*
/datum/gear/donator/donortestingbikehorn
	name = "Donor item testing"
	slot = SLOT_IN_BACKPACK
	path = /obj/item/storage/belt/shoulderholster/ranger45
	geargroupID = list("DONORTEST") //This is a list mainly for the sake of testing, but geargroupID works just fine with ordinary strings

/datum/gear/donator/monke1818
	name = "CIA Badge"
	slot = SLOT_IN_BACKPACK
	path = /obj/item/clothing/accessory/cia_badge
	ckeywhitelist = list("monke1818")

// COYOTE FLUFF ITEMS

/obj/item/weldingtool/largetank/cylphie //Virtually the same as an industrial but slightly faster
	name = "Cylphie's welding tool"
	desc = "A heavily altered industrial welding tool stolen from the brotherhood."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "welder"
	toolspeed = 0.5
	max_fuel = 40
	custom_materials = list(/datum/material/glass=60)

/obj/item/clothing/gloves/ring/plasma/lucine
	name = "plasma ring"
	desc = "This ring is stylized to have an ornate sun, with a sample of phoron swirling around inside. An inscription reads: my undying love and affection, For my Sunflower."
	icon_state = "ringplasma"
	item_state = "pring"
	mood_event_on_equip = /datum/mood_event/equipped_ring/plasma

/datum/gear/donator/mrsanderp
	name = "Happy Sharky Company Cuisine Book"
	slot = SLOT_IN_BACKPACK
	path = /obj/item/book/granter/crafting_recipe/happysharky
	category = LOADOUT_CATEGORY_BACKPACK
	ckeywhitelist = list("mr.sanderp")
	cost = 0

/datum/gear/donator/risingstarslash
	name = "Slime Cookie Recipe Book"
	slot = SLOT_IN_BACKPACK
	path = /obj/item/book/granter/crafting_recipe/slimecookie
	category = LOADOUT_CATEGORY_BACKPACK
	ckeywhitelist = list("risingstarslash")
	cost = 0

/obj/item/clothing/mask/surgical/sloaff
	name = "rusty muzzle"
	desc = "A rusted steel muzzle. It’s covered in scratches."
	icon = 'icons/obj/clothing/masks.dmi'
	icon_state = "muzzle"
	item_state = "blindfold"
	flags_cover = MASKCOVERSMOUTH
	w_class = WEIGHT_CLASS_SMALL
	gas_transfer_coefficient = 0.9
	equip_delay_other = 20

/obj/item/card/id/dogtag/darknova
	name = "holo dogtag"
	icon_state = "holodogtag"
	desc = "An advanced holographic dogtag that shows the duty of a BoS member. This one in particular is assigned to a Nikolatz, J. S  with a rank of Knight. The sex is listed as male, the blood type is listed as O positive, A serial number is written of 242-355-179-22. The last line then reads: WCBOS-C CB-04 along with an insignia depicting wings, cogwheels and a sword."
	assignment = "ID tags"
	uses_overlays = FALSE

/obj/item/card/id/dogtag/risingstarslash
	name = "holo dogtag"
	icon_state = "holodogtag"
	desc = "An advanced holographic dogtag that shows the duty of a BoS member. This one in particular is assigned to a Amethyst with a rank of Head Paladin. The sex is listed as female, the blood type is listed as A positive, A serial number is written of 234-331-173-22. The last line then reads: WCBOS-C CB-04 along with an insignia depicting wings, cogwheels and a sword."
	assignment = "ID tags"
	uses_overlays = FALSE

/obj/item/card/id/dogtag/radiantflash
	name = "holo dogtag"
	icon_state = "holodogtag"
	desc = "An advanced holographic dogtag that shows the duty of a BoS member. This one in particular is assigned to a Rynn Morand  with a rank of senior scribe. The sex is listed as male, the blood type is listed as O negative, A serial number is written of 210-463-053-15. The last line then reads: WCBOS-C CB-04 along with an insignia depicting wings, cogwheels and a sword."
	assignment = "ID tags"
	uses_overlays = FALSE

/////////////////////
///Loadout Boxes///// See kits.dm, use this model for loadouts that have more than one item per character.
/////////////////////
/datum/gear/donator/kits
	slot = SLOT_IN_BACKPACK

/*example
/datum/gear/donator/kits/averyamadeus
	name = "Avery Amadeus' belongings"
	path = /obj/item/storage/box/large/custom_kit/averyamadeus
	ckeywhitelist = list("topbirb")
*/

//Please alphebetize entries by ckey.
// A

/datum/gear/donator/kits/aerodynamique
	name = "Yee-Haw Sharpshooter Kit"
	path = /obj/item/storage/box/large/custom_kit/aerodynamique
	ckeywhitelist = list("aerodynamique")

/obj/item/storage/box/large/custom_kit/aerodynamique/PopulateContents()
	new /obj/item/gun/ballistic/rifle/repeater/trail(src)
	new /obj/item/gun_upgrade/scope/watchman(src)

/datum/gear/donator/kits/aerodynamique2
	name = "Ancient Huntress' Bounty"
	path = /obj/item/storage/box/large/custom_kit/aerodynamique2
	ckeywhitelist = list("aerodynamique")

/obj/item/storage/box/large/custom_kit/aerodynamique2/PopulateContents()
	new /obj/item/clothing/suit/armor/light/tribal/geckocloak(src)
	new /obj/item/twohanded/sledgehammer/simple(src)
	new /obj/item/throwing_star/spear(src)
	new /obj/item/throwing_star/spear(src)

/datum/gear/donator/kits/aerodynamique3
	name = "Kalcia Loadout Time!"
	path = /obj/item/storage/box/large/custom_kit/aerodynamique3
	ckeywhitelist = list("aerodynamique")

/obj/item/storage/box/large/custom_kit/aerodynamique3/PopulateContents()
	//new /obj/item/gun/ballistic/bow/sturdy(src)
	new /obj/item/gun/ballistic/bow/recurvebow(src)
	new /obj/item/storage/bag/tribe_quiver/light/full(src)
	new /obj/item/reagent_containers/pill/patch/jet(src)

/datum/gear/donator/kits/aldrictalvalin
	name = "Aldric's Supply Kit"
	path = /obj/item/storage/box/large/custom_kit/aldrictalvalin
	ckeywhitelist = list("aldrictalvalin")

/obj/item/storage/box/large/custom_kit/aldrictalvalin/PopulateContents()
	new /obj/item/clothing/head/helmet/f13/ncr/rangercombat/foxcustom(src)
	new /obj/item/clothing/under/f13/enclave/peacekeeper(src)
	new /obj/item/clothing/shoes/f13/enclave/serviceboots(src)
	new /obj/item/clothing/suit/armor/heavy/riot/retrofitted(src)
	new /obj/item/melee/transforming/plasmacutter/regular/eve(src)
	new /obj/item/clothing/glasses/welding(src)
	new /obj/item/book/granter/crafting_recipe/blueprint/plasmarifle(src)

/datum/gear/donator/kits/archyzt
	name = "Follower's Traveler"
	path = /obj/item/storage/box/large/custom_kit/archyzt
	ckeywhitelist = list("archyzt")

/obj/item/storage/box/large/custom_kit/archyzt/PopulateContents()
	new /obj/item/clothing/suit/toggle/labcoat/paramedic(src)
	new /obj/item/storage/backpack/medic(src)
	new /obj/item/pda/medical(src)
	new /obj/item/gun/energy/laser/pistol(src)

// B

/datum/gear/donator/kits/baticon
	name = "Laser Bat Kit"
	path = /obj/item/storage/box/large/custom_kit/baticon
	ckeywhitelist = list("baticon")

/obj/item/storage/box/large/custom_kit/baticon/PopulateContents()
	new /obj/item/gun/energy/laser/pistol(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)

/datum/gear/donator/kits/bladeburstninja
	name = "Split-Noggin's Box"
	path = /obj/item/storage/box/large/custom_kit/bladeburstninja
	ckeywhitelist = list("bladeburstninja")

/obj/item/storage/box/large/custom_kit/bladeburstninja/PopulateContents()
	//new /obj/item/gun/ballistic/bow/silver(src)
	new /obj/item/gun/ballistic/bow/recurvebow(src)
	new /obj/item/clothing/head/helmet/f13/metalmask(src)
	new /obj/item/clothing/suit/armor/light/leather/leathermk2(src)
	new /obj/item/clothing/accessory/talisman(src)
	new /obj/item/storage/bag/tribe_quiver(src)

/datum/gear/donator/kits/bladeburstninja2
	name = "Space Monkey Kit"
	path = /obj/item/storage/box/large/custom_kit/bladeburstninja2
	ckeywhitelist = list("bladeburstninja")

/obj/item/storage/box/large/custom_kit/bladeburstninja2/PopulateContents()
	new /obj/item/melee/unarmed/sappers(src)
	new /obj/item/clothing/head/helmet/space/eva(src)
	new /obj/item/clothing/under/rank/civilian/curator/nasa(src)

/datum/gear/donator/kits/bladeburstninja3
	name = "Bone Zone Kit"
	path = /obj/item/storage/box/large/custom_kit/bladeburstninja3
	ckeywhitelist = list("bladeburstninja")

/obj/item/storage/box/large/custom_kit/bladeburstninja3/PopulateContents()
	new /obj/item/clothing/head/helmet/knight/yellow(src)
	new /obj/item/clothing/glasses/sunglasses/reagent(src)
	new /obj/item/clothing/suit/armor/light/poachervest(src)
	new /obj/item/clothing/gloves/bracer(src)

/datum/gear/donator/kits/bonirus
	name = "Xal-SH Kit"
	path = /obj/item/storage/box/large/custom_kit/bonirus
	ckeywhitelist = list("bonirus")

/obj/item/storage/box/large/custom_kit/bonirus/PopulateContents()
	new /obj/item/clothing/head/cone(src)
	new /obj/item/gun/energy/laser/sida(src)
	new /obj/item/clothing/accessory/bos/initiateS(src)
	new /obj/item/clothing/accessory/bos/headscribe(src)
	new /obj/item/pizzabox/infinite(src)
	new /obj/item/clothing/glasses/welding(src)
	new /obj/item/flashlight/lantern(src)
	new /obj/item/toy/plush/mammal/fox/squishfox(src)

/datum/gear/donator/kits/brimcon
	name = "Gift from Claws"
	path = /obj/item/storage/box/large/custom_kit/brimcon
	ckeywhitelist = list("brimcon")

/obj/item/storage/box/large/custom_kit/brimcon/PopulateContents()
	new /obj/item/clothing/suit/armor/light/tribal/cloak(src)
	new /obj/item/gun/ballistic/automatic/combat/worn/brim(src)

/datum/gear/donator/kits/bwoincognito
	name = "Tasald's Kit"
	path = /obj/item/storage/box/large/custom_kit/bwoincognito
	ckeywhitelist = list("bwoincognito")

/obj/item/storage/box/large/custom_kit/bwoincognito/PopulateContents()
	new /obj/item/clothing/head/helmet/f13/brahmincowboyhat(src)
	new /obj/item/clothing/under/f13/ranger/modif_ranger(src)
	new /obj/item/clothing/shoes/combat(src)
	new /obj/item/melee/onehanded/knife/trench(src)
	new /obj/item/storage/belt/legholster(src)
	new /obj/item/gun/ballistic/revolver/revolver45/gunslinger(src)
	new /obj/item/ammo_box/a45lcrev(src)
	new /obj/item/ammo_box/a45lcrev(src)
	new /obj/item/ammo_box/a45lcbox(src)
	new /obj/item/lighter/fusion(src)
	new /obj/item/book/granter/crafting_recipe/poultice(src)
	new /obj/item/book/granter/crafting_recipe/happysharky(src)
	new /obj/item/clothing/suit/armor/light/leather/leathercoat(src)
	new /obj/item/circuitboard/machine/biogenerator(src)
	new /obj/item/circuitboard/machine/plantgenes(src)
	new /obj/item/circuitboard/machine/seed_extractor(src)

// C

/datum/gear/donator/kits/caseapollo58143
	name = "Missionary Kit"
	path = /obj/item/storage/box/large/custom_kit/caseapollo58143
	ckeywhitelist = list("caseapollo58143")

/obj/item/storage/box/large/custom_kit/caseapollo58143/PopulateContents()
	new /obj/item/nullrod/rosary(src)
	new /obj/item/gun/ballistic/automatic/pistol/m1911/custom(src)
	new /obj/item/ammo_box/magazine/m45(src)
	new /obj/item/ammo_box/magazine/m45(src)
	new /obj/item/storage/belt/legholster(src)
	new /obj/item/storage/book/bible(src)

/datum/gear/donator/kits/caseapollo58143_2
	name = "Missionary Preacher Kit"
	path = /obj/item/storage/box/large/custom_kit/caseapollo58143_2
	ckeywhitelist = list("caseapollo58143")

/obj/item/storage/box/large/custom_kit/caseapollo58143_2/PopulateContents()
	new /obj/item/clothing/suit/armor/light/duster/battlecoat(src)
	new /obj/item/nullrod/rosary(src)
	new /obj/item/gun/ballistic/rifle/mosin(src)
	new /obj/item/reagent_containers/food/drinks/flask/russian(src)
	new /datum/uplink_item/device_tools/syndicate_eyepatch(src)
	new /obj/item/clothing/shoes/russian(src)
	new /obj/item/clothing/under/syndicate/rus_army(src)

/datum/gear/donator/kits/caseapollo58143_3
	name = "Missionary Eyepatch Kit"
	path = /obj/item/storage/box/large/custom_kit/caseapollo58143_3
	ckeywhitelist = list("caseapollo58143")

/obj/item/storage/box/large/custom_kit/caseapollo58143_3/PopulateContents()
	new /obj/item/clothing/glasses/eyepatch/syndicate(src)
	new /obj/item/grown/rose(src)
	new /obj/item/clothing/under/rank/security/detective/brown(src)
	new /obj/item/clothing/suit/det_suit/forensicsblue(src)
	new /obj/item/gun/ballistic/revolver/colt357/mateba(src)
	new /obj/item/lighter/bullet(src)

/datum/gear/donator/kits/cavusogluzevk
	name = "Raider Kit"
	path = /obj/item/storage/box/large/custom_kit/cavusogluzevk
	ckeywhitelist = list("cavusogluzevk")

/obj/item/storage/box/large/custom_kit/cavusogluzevk/PopulateContents()
	new /obj/item/storage/belt/military/alt(src)
	new /obj/item/melee/onehanded/knife/trench(src)
	new /obj/item/melee/unarmed/brass/spiked(src)
	new /obj/item/clothing/suit/armor/light/raider/painspike(src)
	new /obj/item/gun/ballistic/automatic/pistol/sig/worn(src)

/datum/gear/donator/kits/cavusogluzevk2
	name = "B.O.S Loadout"
	path = /obj/item/storage/box/large/custom_kit/cavusogluzevk2
	ckeywhitelist = list("cavusogluzevk")

/obj/item/storage/box/large/custom_kit/cavusogluzevk2/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/n99/crusader(src)
	new /obj/item/clothing/accessory/bos/scribe(src)
	new /obj/item/storage/belt/army/assault(src)
	new /obj/item/melee/unarmed/brass/spiked(src)
	new /obj/item/melee/onehanded/knife/survival(src)

// D

/datum/gear/donator/kits/dameonowen
	name = "Dragon Stash"
	path = /obj/item/storage/box/large/custom_kit/dameonowen
	ckeywhitelist = list("dameonowen")

/obj/item/storage/box/large/custom_kit/dameonowen/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/sig/trusty(src)
	new /obj/item/ammo_box/magazine/m45/rubber(src)
	new /obj/item/ammo_box/magazine/m45/rubber(src)
	new /obj/item/ammo_box/c45/rubber(src)
	new /obj/item/storage/belt/legholster(src)
	new /obj/item/gun/ballistic/automatic/marksman/worn(src)

/datum/gear/donator/kits/darknova92
	name = "Nikolatz BoS"
	path = /obj/item/storage/box/large/custom_kit/darknova92
	ckeywhitelist = list("darknova92")

/obj/item/storage/box/large/custom_kit/darknova92/PopulateContents()
	new /obj/item/card/id/dogtag/darknova(src)
	new /obj/item/gun/ballistic/automatic/pistol/n99/crusader(src)
	new /obj/item/ammo_box/magazine/m10mm/adv/simple(src)
	new /obj/item/ammo_box/magazine/m10mm/adv/simple(src)
	new /obj/item/ammo_box/magazine/m10mm/adv/simple(src)

/datum/gear/donator/kits/dezuel
	name = "Lunas Stash"
	path = /obj/item/storage/box/large/custom_kit/dezuel
	ckeywhitelist = list("dezuel")

/obj/item/storage/box/large/custom_kit/dezuel/PopulateContents()
	new /obj/item/gun/ballistic/revolver/police(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/bedsheet/cult(src)

// E

/datum/gear/donator/kits/esperkin
	name = "Alchemist's Kit"
	path = /obj/item/storage/box/large/custom_kit/esperkin
	ckeywhitelist = list("esperkin")

/obj/item/storage/box/large/custom_kit/esperkin/PopulateContents()
	new /obj/item/clothing/mask/gas/glass(src)
	new /obj/item/melee/onehanded/knife/ritualdagger(src)
	new /obj/item/weldingtool/largetank(src)
	new /obj/item/clothing/glasses/welding(src)
	new /obj/item/gun/energy/laser/pistol(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/smelling_salts(src)
	new /obj/item/circuitboard/machine/chem_dispenser(src)

// F

/datum/gear/donator/kits/ferisramsay
	name = "Feris' Box"
	path = /obj/item/storage/box/large/custom_kit/ferisramsay
	ckeywhitelist = list("ferisramsay")

/obj/item/storage/box/large/custom_kit/ferisramsay/PopulateContents()
	new /obj/item/gun/energy/laser/wattz(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)

/datum/gear/donator/kits/ferisramsay2
	name = "Rhetta's Kit"
	path = /obj/item/storage/box/large/custom_kit/ferisramsay2
	ckeywhitelist = list("ferisramsay")

/obj/item/storage/box/large/custom_kit/ferisramsay2/PopulateContents()
	new /obj/item/gun/ballistic/rifle/repeater/cowboy(src)
	new /obj/item/ammo_box/magazine/m45(src)
	new /obj/item/ammo_box/magazine/m45(src)
	new /obj/item/clothing/suit/armor/light/kit/plates(src)
	new /obj/item/tool_upgrade/productivity/ergonomic_grip(src)

/datum/gear/donator/kits/ferisramsay3
	name = "Maddy's Loadout"
	path = /obj/item/storage/box/large/custom_kit/ferisramsay3
	ckeywhitelist = list("ferisramsay")

/obj/item/storage/box/large/custom_kit/ferisramsay3/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/sig/worn(src)
	new /obj/item/gun/ballistic/automatic/pistol/sig/worn(src)

/datum/gear/donator/kits/fuzlet
	name = "fuzzy supply box"
	path = /obj/item/storage/box/large/custom_kit/fuzlet
	ckeywhitelist = list("fuzlet", "superlagg")

/obj/item/storage/box/large/custom_kit/fuzlet/PopulateContents()
	new /obj/item/card/fuzzy_license(src)
	new /obj/item/geiger_counter(src)
	new /obj/item/toy/plush/mammal/wolf/blue(src)
	new /obj/item/toy/plush/mammal/fox/fuzzy(src)
	new /obj/item/stack/marker_beacon/thirty(src)
	new /obj/item/screwdriver/nuke/nt(src)
	new /obj/item/gun_upgrade/trigger/raidertrigger(src)
	new /obj/item/storage/survivalkit/combat(src)

/datum/gear/donator/kits/fuzlet2
	name = "Scavfox Kit"
	path = /obj/item/storage/box/large/custom_kit/fuzlet2
	ckeywhitelist = list("fuzlet")

/obj/item/storage/box/large/custom_kit/fuzlet2/PopulateContents()
	new /obj/item/gun_upgrade/trigger/raidertrigger(src)
	new /obj/item/storage/survivalkit/triple(src)
	new /obj/item/storage/bag/trash/sack(src)

/datum/gear/donator/kits/fuzlet3
	name = "Thiefy thief Kit"
	path = /obj/item/storage/box/large/custom_kit/fuzlet3
	ckeywhitelist = list("fuzlet")

/obj/item/storage/box/large/custom_kit/fuzlet3/PopulateContents()
	new /obj/item/storage/survivalkit/triple(src)
	new /obj/item/storage/bag/trash/sack(src)
	new /obj/item/gun_upgrade/muzzle/silencer(src)

// G

/datum/gear/donator/kits/generalpantsu
	name = "Appropriated Brotherhood Supplies"
	path = /obj/item/storage/box/large/custom_kit/generalpantsu
	ckeywhitelist = list("generalpantsu")

/obj/item/storage/box/large/custom_kit/generalpantsu/PopulateContents()
	new /obj/item/clothing/head/helmet/armyhelmet/heavy(src)
	new /obj/item/storage/belt/shoulderholster/kemble(src)
	new /obj/item/storage/belt/army/assault(src)
//	new /obj/item/gun/ballistic/revolver/m2405(src) //YEAH UH, NO
	new /obj/item/melee/unarmed/tigerclaw(src)
	new /obj/item/lighter/fusion(src)

/datum/gear/donator/kits/gozulio
	name = "Jess' Kit"
	path = /obj/item/storage/box/large/custom_kit/gozulio
	ckeywhitelist = list("gozulio")

/obj/item/storage/box/large/custom_kit/gozulio/PopulateContents()
	new /obj/item/pda/medical(src)
	new /obj/item/storage/medical/ancientfirstaid(src)
	new /obj/item/storage/belt/shoulderholster(src)
	new /obj/item/gun/energy/laser/pistol(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/healthanalyzer/advanced(src)
	new /obj/item/clothing/gloves/color/latex/nitrile(src)

/datum/gear/donator/kits/greed2323
	name = "Greed Kit"
	path = /obj/item/storage/box/large/custom_kit/greed2323
	ckeywhitelist = list("greed2323")

/obj/item/storage/box/large/custom_kit/greed2323/PopulateContents()
	new /obj/item/gun/ballistic/revolver/m29/alt(src)
	new /obj/item/gun_upgrade/trigger/raidertrigger(src)

// H
// I

/datum/gear/donator/kits/imbubbl101
	name = "Magnum Kit"
	path = /obj/item/storage/box/large/custom_kit/imbubbl101
	ckeywhitelist = list("imbubbl101")

/obj/item/storage/box/large/custom_kit/imbubbl101/PopulateContents()
	new /obj/item/clothing/head/f13/enclave/peacekeeper(src)
	new /obj/item/storage/belt/military(src)

/datum/gear/donator/kits/imbubbl101_2
	name = "Syndi Kit"
	path = /obj/item/storage/box/large/custom_kit/imbubbl101_2
	ckeywhitelist = list("imbubbl101")

/obj/item/storage/box/large/custom_kit/imbubbl101_2/PopulateContents()
	new /obj/item/clothing/accessory/waistcoat(src)
	new /obj/item/clothing/glasses/science/f13(src)
	new /obj/item/melee/classic_baton/telescopic(src)
	new /obj/item/storage/fancy/cigarettes/cigpack_syndicate(src)

// J

/datum/gear/donator/kits/jackalface
	name = "Jackal Kit"
	path = /obj/item/storage/box/large/custom_kit/jackalface
	ckeywhitelist = list("jackalface")

/obj/item/storage/box/large/custom_kit/jackalface/PopulateContents()
	new /obj/item/clothing/under/draculass(src)
	new /obj/item/clothing/mask/chameleon(src)
	new /obj/item/gun/ballistic/automatic/pistol/m1911/custom/jackal(src)

/datum/gear/donator/kits/jackson1112
	name = "Recon Kit"
	path = /obj/item/storage/box/large/custom_kit/jackson1112
	ckeywhitelist = list("jackson1112")

/obj/item/storage/box/large/custom_kit/jackson1112/PopulateContents()
	new /obj/item/gun/ballistic/automatic/marksman/worn(src)
	new /obj/item/ammo_box/magazine/m556/rifle(src)
	new /obj/item/ammo_box/magazine/m556/rifle(src)
	new /obj/item/melee/onehanded/knife/bayonet(src)
	new /obj/item/storage/belt/military(src)
	new /obj/item/storage/box/ration/ranger_breakfast(src)
	new /obj/item/clothing/head/helmet/f13/combat(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/radio(src)
	new /obj/item/binoculars(src)
	new /obj/item/shovel/trench(src)

/datum/gear/donator/kits/jackson1112_2
	name = "SAS Kit"
	path = /obj/item/storage/box/large/custom_kit/jackson1112_2
	ckeywhitelist = list("jackson1112")

/obj/item/storage/box/large/custom_kit/jackson1112_2/PopulateContents()
	new /obj/item/storage/belt/army(src)
	new /obj/item/gun/ballistic/rifle/enfield(src)
	new /obj/item/ammo_box/a308(src)
	new /obj/item/ammo_box/a308(src)
	new /obj/item/gun/ballistic/automatic/pistol/beretta(src)
	new /obj/item/ammo_box/magazine/m9mm/doublestack(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/under/syndicate/camo(src)
	new /obj/item/gun_upgrade/muzzle/silencer(src)
	new /obj/item/radio(src)

// K
// L

/datum/gear/donator/kits/lifelessghoul
	name = "Ancient Memories"
	path = /obj/item/storage/box/large/custom_kit/lifelessghoul
	ckeywhitelist = list("lifelessghoul")

/obj/item/storage/box/large/custom_kit/lifelessghoul/PopulateContents()
	new /obj/item/melee/smith/hammer(src)
	new /obj/item/clothing/head/helmet/f13/legion/orator(src)
	new /obj/item/flashlight/lantern(src)

/datum/gear/donator/kits/lucine
	name = "Earlong Travel Supplies"
	path = /obj/item/storage/box/large/custom_kit/lucine
	ckeywhitelist = list("lucine")

/obj/item/storage/box/large/custom_kit/lucine/PopulateContents()
	//new /obj/item/gun/energy/laser/freeblade(src)
	//new /obj/item/gun/energy/laser/freeblade(src)
	//new /obj/item/stock_parts/cell/ammo/ec(src)
	//new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/gun/flintlock/laser(src)
	new /obj/item/gun/flintlock/laser(src)
	new /obj/item/ammo_box/flintlock(src)
	new /obj/item/ammo_box/flintlock(src)
	new /obj/item/clothing/gloves/ring/plasma/lucine(src)
	new /obj/item/book/granter/martial/carp(src)

/datum/gear/donator/kits/lucine2
	name = "HAVOC"
	path = /obj/item/storage/box/large/custom_kit/lucine2
	ckeywhitelist = list("lucine")

/obj/item/storage/box/large/custom_kit/lucine2/PopulateContents()
	new /obj/item/clothing/head/helmet/knight/f13/metal(src)
	new /obj/item/gun/energy/mmlbuster(src)

// M

/datum/gear/donator/kits/mathiel
	name = "Annastasia's Kit"
	path = /obj/item/storage/box/large/custom_kit/mathiel
	ckeywhitelist = list("mathiel")

/obj/item/storage/box/large/custom_kit/mathiel/PopulateContents()
	new /obj/item/gun/ballistic/revolver/m29/alt(src)
	new /obj/item/clothing/head/helmet/f13/combat/swat(src)
	new /obj/item/clothing/suit/armor/medium/combat/swat(src)
	new /obj/item/clothing/shoes/combat/swat(src)
	new /obj/item/clothing/suit/hooded/wintercoat/medical(src)
	new /obj/item/clothing/under/rank/medical/doctor/skirt(src)

/datum/gear/donator/kits/merek2
	name = "Brotherhood Kit"
	path = /obj/item/storage/box/large/custom_kit/merek2
	ckeywhitelist = list("merek2")

/obj/item/storage/box/large/custom_kit/merek2/PopulateContents()
	new /obj/item/clothing/suit/armor/light/duster/brahmin/biker(src)
	new /obj/item/reagent_containers/food/drinks/flask/vault113(src)
	new /obj/item/lighter/moff(src)
	new /obj/item/clothing/under/f13/bos/fatigues(src)
	new /obj/item/gun/energy/laser/wattzs(src)
	new /obj/item/radio/headset/headset_sci(src)
	new /obj/item/gun/ballistic/automatic/pistol/n99/executive/worn(src)
	new /obj/item/clothing/ears/headphones(src)
	new /obj/item/reagent_containers/food/snacks/grown/tea/catnip(src)
	new /obj/item/reagent_containers/food/snacks/grown/citrus/lemon(src)

/datum/gear/donator/kits/mrsanderp
	name = "Happy Sharky Co. Business Bundle"
	path = /obj/item/storage/box/large/custom_kit/exoticjazz
	ckeywhitelist = list("mrsanderp")

/obj/item/storage/box/large/custom_kit/exoticjazz/PopulateContents()
	new /obj/item/book/granter/crafting_recipe/happysharky(src)

// N

/datum/gear/donator/kits/nightmare6669
	name = "Chadsune"
	path = /obj/item/storage/box/large/custom_kit/nightmare6669
	ckeywhitelist = list("nightmare6669")

/obj/item/storage/box/large/custom_kit/nightmare6669/PopulateContents()
	new /obj/item/gun/ballistic/revolver/m29/alt(src)
	new /obj/item/ammo_box/m44(src)
	new /obj/item/ammo_box/m44(src)
	new /obj/item/storage/belt/shoulderholster(src)
	new /obj/item/melee/onehanded/knife/trench(src)
	new /obj/item/clothing/head/helmet/f13/combat/swat(src)
	new /obj/item/clothing/suit/armor/medium/combat/swat(src)
	new /obj/item/melee/onehanded/machete/spatha(src)

/datum/gear/donator/kits/nirzak
	name = "Vas Kit"
	path = /obj/item/storage/box/large/custom_kit/nirzak
	ckeywhitelist = list("nirzak")

/obj/item/storage/box/large/custom_kit/nirzak/PopulateContents()
	new /obj/item/clothing/suit/armor/harpercoat(src)
	new /obj/item/stealthboy(src)
	new /obj/item/clothing/mask/gas/sechailer(src)
	new /obj/item/storage/belt/military(src)
	new /obj/item/clothing/head/helmet/armyhelmet/heavy(src)

// O
// P

/datum/gear/donator/kits/pappavol
	name = "Tribal Power Kit"
	path = /obj/item/storage/box/large/custom_kit/pappavol
	ckeywhitelist = list("pappavol")

/obj/item/storage/box/large/custom_kit/pappavol/PopulateContents()
	new /obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/tribal/junk(src)
	new /obj/item/twohanded/sledgehammer/simple(src)

/datum/gear/donator/kits/pipes_wildin
	name = "Teyla's Kit"
	path = /obj/item/storage/box/large/custom_kit/pipes_wildin
	ckeywhitelist = list("pipes_wildin")

/obj/item/storage/box/large/custom_kit/pipes_wildin/PopulateContents()
	new /obj/item/gun/ballistic/automatic/combat/worn(src)

/datum/gear/donator/kits/pipes_wildin2
	name = "Zimnt's Kit"
	path = /obj/item/storage/box/large/custom_kit/pipes_wildin2
	ckeywhitelist = list("pipes_wildin")

/obj/item/storage/box/large/custom_kit/pipes_wildin2/PopulateContents()
	new /obj/item/stealthboy(src)

/datum/gear/donator/kits/pixelexip
	name = "Bruiser's Kit"
	path = /obj/item/storage/box/large/custom_kit/pixelexip
	ckeywhitelist = list("pixelexip")

/obj/item/storage/box/large/custom_kit/pixelexip/PopulateContents()
	new /obj/item/clothing/suit/armor/light/poachervest(src)
	new /obj/item/reagent_containers/food/drinks/flask/gold(src)
	new /obj/item/clothing/gloves/fingerless/pugilist/rapid(src)

/datum/gear/donator/kits/pixelexip2
	name = "Hypocritical Oath Kit"
	path = /obj/item/storage/box/large/custom_kit/pixelexip2
	ckeywhitelist = list("pixelexip")

/obj/item/storage/box/large/custom_kit/pixelexip2/PopulateContents()
	new /obj/item/gun/ballistic/rifle/hunting/special(src)

/datum/gear/donator/kits/planetary
	name = "Collector"
	path = /obj/item/storage/box/large/custom_kit/planetary
	ckeywhitelist = list("planetary")

/obj/item/storage/box/large/custom_kit/planetary/PopulateContents()
	new /obj/item/clothing/under/f13/chinasuitcosmetic(src)
	new /obj/item/clothing/head/f13/chinahelmetcosmetic(src)
	new /obj/item/clothing/suit/armor/harpercoat(src)
	new /obj/item/gun/ballistic/automatic/pistol/n99/crusader(src)
	new /obj/item/toy/plush/mammal/fox(src)

/datum/gear/donator/kits/planetary2
	name = "Replica"
	path = /obj/item/storage/box/large/custom_kit/planetary2
	ckeywhitelist = list("planetary")

/obj/item/storage/box/large/custom_kit/planetary2/PopulateContents()
	new /obj/item/clothing/suit/armor/heavy/riot/eliteweak(src)
	new /obj/item/clothing/head/helmet/f13/ncr/rangercombat/eliteriotweak(src)
	new /obj/item/gun/ballistic/revolver/revolver44/desert_ranger(src)

// Q
// R

/datum/gear/donator/kits/radiantflash
	name = "Rynn's Kit"
	path = /obj/item/storage/box/large/custom_kit/radiantflash
	ckeywhitelist = list("radiantflash")

/obj/item/storage/box/large/custom_kit/radiantflash/PopulateContents()
	new /obj/item/book/granter/crafting_recipe/blueprint/aer9/focused/rynn(src)
	new /obj/item/clothing/accessory/bos/seniorscribe(src)
	new /obj/item/clothing/suit/armor/light/kit/punk/labcoat(src)
	new /obj/item/card/id/dogtag/radiantflash(src)

/datum/gear/donator/kits/risingstarslash
	name = "Blue's Kit"
	path = /obj/item/storage/box/large/custom_kit/risingstarslash
	ckeywhitelist = list("risingstarslash")

/obj/item/storage/box/large/custom_kit/risingstarslash/PopulateContents()
	new /obj/item/reagent_containers/food/snacks/grown/poppy/geranium/forgetmenot(src)
	new /obj/item/lighter/fusion(src)
	new /obj/item/melee/onehanded/knife/trench(src)
	new /obj/item/clothing/glasses/prism_glasses(src)
	new /obj/item/stealthboy(src)
	new /obj/item/stock_parts/cell/high/slime/blue(src)

/datum/gear/donator/kits/risingstarslash2
	name = "Slime Cookie Kit"
	path = /obj/item/storage/box/large/custom_kit/risingstarslash2
	ckeywhitelist = list("risingstarslash")

/obj/item/storage/box/large/custom_kit/risingstarslash2/PopulateContents()
	new /obj/item/book/granter/crafting_recipe/slimecookie(src)
	new /obj/item/lighter/slime(src)
	new /obj/item/reagent_containers/food/drinks/drinkingglass/filled/nukagrape(src)
	new /obj/item/reagent_containers/food/drinks/drinkingglass/filled/nukaorange(src)
	new /obj/item/reagent_containers/food/drinks/drinkingglass/filled/nukacherry(src)
	new /obj/item/clothing/glasses/prism_glasses(src)

/datum/gear/donator/kits/risingstarslash3
	name = "Head Paladin Kit"
	path = /obj/item/storage/box/large/custom_kit/risingstarslash3
	ckeywhitelist = list("risingstarslash")

/obj/item/storage/box/large/custom_kit/risingstarslash3/PopulateContents()
	new /obj/item/lighter/gold(src)
	new /obj/item/gun/ballistic/automatic/pistol/n99/crusader(src)
	new /obj/item/card/id/dogtag/risingstarslash(src)

/datum/gear/donator/kits/risingstarslash4
	name = "Trueshot's Kit"
	path = /obj/item/storage/box/large/custom_kit/risingstarslash4
	ckeywhitelist = list("risingstarslash")

/obj/item/storage/box/large/custom_kit/risingstarslash4/PopulateContents()
//	new /obj/item/gun/ballistic/bow/gold(src)
	new /obj/item/storage/bag/tribe_quiver/light/full(src)
	new /obj/item/smelling_salts/wayfarer(src)
	new /obj/item/reagent_containers/pill/fiery_purgative(src)
	new /obj/item/reagent_containers/pill/antivenom(src)

/datum/gear/donator/kits/roachwitharoach
	name = "Desert Kit"
	path = /obj/item/storage/box/large/custom_kit/roachwitharoach
	ckeywhitelist = list("roachwitharoach")

/obj/item/storage/box/large/custom_kit/roachwitharoach/PopulateContents()
	new /obj/item/clothing/under/f13/ncr(src)

// S

/datum/gear/donator/kits/sage1990
	name = "Follower's Starting Kit"
	path = /obj/item/storage/box/large/custom_kit/sage1990
	ckeywhitelist = list("sage1990")

/obj/item/storage/box/large/custom_kit/sage1990/PopulateContents()
	new /obj/item/clothing/suit/armor/light/leather(src)
	new /obj/item/gun/energy/laser/wattz(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)

/datum/gear/donator/kits/saltyscabbard
	name = "Warrior Salty Kity"
	path = /obj/item/storage/box/large/custom_kit/saltyscabbard
	ckeywhitelist = list("saltyscabbard")

/obj/item/storage/box/large/custom_kit/saltyscabbard/PopulateContents()
	new /obj/item/clothing/head/helmet/f13/wayfarer/shamanred(src)
	new /obj/item/clothing/head/helmet/f13/wayfarer/shamanblue(src)
	new /obj/item/shield/riot/buckler(src)
	new /obj/item/melee/onehanded/machete/spatha(src)

/datum/gear/donator/kits/seermankhajiit00
	name = "Warmonger"
	path = /obj/item/storage/box/large/custom_kit/seermankhajiit00
	ckeywhitelist = list("seermankhajiit00")

/obj/item/storage/box/large/custom_kit/seermankhajiit00/PopulateContents()
	new /obj/item/claymore(src)
	new /obj/item/clothing/suit/armor/light/knight(src)
	new /obj/item/clothing/head/helmet/f13/knighthelmet(src)

/datum/gear/donator/kits/seermankhajiit002
	name = "Sovietcat Kit"
	path = /obj/item/storage/box/large/custom_kit/seermankhajiit002
	ckeywhitelist = list("seermankhajiit00", "superlagg")

/obj/item/storage/box/large/custom_kit/seermankhajiit002/PopulateContents()
	new /obj/item/gun/ballistic/rifle/salvaged_eastern_rifle(src)
	new /obj/item/storage/box/hobo_tox(src)
	new /obj/item/pet_carrier/paws(src)
	new /obj/item/reagent_containers/food/snacks/peanut_butter(src)

/datum/gear/donator/kits/seermankhajiit003
	name = "The Director"
	path = /obj/item/storage/box/large/custom_kit/seermankhajiit003
	ckeywhitelist = list("seermankhajiit00")

/obj/item/storage/box/large/custom_kit/seermankhajiit003/PopulateContents()
	new /obj/item/gun/ballistic/automatic/g11/tox(src)
	new /obj/item/gun/ballistic/automatic/pistol/type17/c96auto/tox(src)
	new /obj/item/ammo_box/magazine/uzim9mm/rockwell(src)

/obj/item/pet_carrier/paws
	name = "Paws' carrier"
	desc = "Hey look who it is!"

/obj/item/pet_carrier/paws/Initialize()
	. = ..()
	var/mob/living/simple_animal/pet/fox/paws/pet_paws = new(src)
	add_occupant(pet_paws)

/datum/gear/donator/kits/sloaff
	name = "Leo's Kit"
	path = /obj/item/storage/box/large/custom_kit/sloaff
	ckeywhitelist = list("sloaff")

/obj/item/storage/box/large/custom_kit/sloaff/PopulateContents()
	new /obj/item/binoculars(src)
	new /obj/item/gun/ballistic/revolver/thatgun(src)
	new /obj/item/ammo_box/magazine/m556/rifle/small(src)
	new /obj/item/ammo_box/magazine/m556/rifle/small(src)
	new /obj/item/melee/onehanded/knife/bowie(src)
	new /obj/item/clothing/head/helmet/f13/marlowhat(src)

/datum/gear/donator/kits/sloaff2
	name = "Danger Doggo Kit"
	path = /obj/item/storage/box/large/custom_kit/sloaff2
	ckeywhitelist = list("sloaff")

/obj/item/storage/box/large/custom_kit/sloaff2/PopulateContents()
	new /obj/item/clothing/mask/surgical/sloaff(src)
	new /obj/item/lighter/fusion(src)
	new /obj/item/reagent_containers/pill/patch/jet(src)
	new /obj/item/gun/energy/laser/badlands/worn(src)

/datum/gear/donator/kits/sloaff3
	name = "Sloan's Food Pack"
	path = /obj/item/storage/box/large/custom_kit/sloaff3
	ckeywhitelist = list("sloaff")

/obj/item/storage/box/large/custom_kit/sloaff3/PopulateContents()
	new /obj/item/storage/fancy/cigarettes/cigpack_cannabis(src)
	new /obj/item/reagent_containers/food/drinks/drinkingglass/filled/nukaberry(src)
	new /obj/item/reagent_containers/food/snacks/jellysandwich/pbj/cherry(src)
	new /obj/item/reagent_containers/food/drinks/flask/vault13(src)

/datum/gear/donator/kits/soulwinter446
	name = "Shocome's relic cross"
	path = /obj/item/nullrod/rosary/keep_as_is
	ckeywhitelist = list("soulwinter446")

/datum/gear/donator/kits/superlagg
	name = "Bigfox Kit"
	path = /obj/item/storage/box/large/custom_kit/superlagg
	ckeywhitelist = list("superlagg")

/obj/item/storage/box/large/custom_kit/superlagg/PopulateContents()
	new /obj/item/gun/ballistic/automatic/varmint/extended(src)
	new /obj/item/ammo_box/magazine/m556/rifle(src)
	new /obj/item/gun/ballistic/revolver/revolver44(src)
	new /obj/item/ammo_box/m44(src)
	new /obj/item/ammo_box/m44(src)
	new /obj/item/melee/onehanded/knife/switchblade(src)
	new /obj/item/toy/plush/mammal/fox/squishfox(src)

/datum/gear/donator/kits/superlagg2
	name = "Danny Kit"
	path = /obj/item/storage/box/large/custom_kit/superlagg2
	ckeywhitelist = list("superlagg")

/obj/item/storage/box/large/custom_kit/superlagg2/PopulateContents()
	new /obj/item/gun/ballistic/automatic/smg/sidewinder(src)
	new /obj/item/ammo_box/magazine/uzim9mm/rockwell/empty(src)
	new /obj/item/ammo_box/magazine/cg45/empty(src)
	new /obj/item/ammo_box/magazine/tommygunm45/stick/empty(src)
	new /obj/item/melee/onehanded/knife/switchblade(src)
	new /obj/item/toy/plush/mammal/fox/squishfox(src)

/datum/gear/donator/kits/swirlby
	name = "Tribal Kit"
	path = /obj/item/storage/box/large/custom_kit/swirlby
	ckeywhitelist = list("swirlby")

/obj/item/storage/box/large/custom_kit/swirlby/PopulateContents()
	new /obj/item/clothing/under/f13/exile/vault(src)
	new /obj/item/gun/ballistic/rifle/hunting(src)
	new /obj/item/clothing/suit/armor/light/tribal/rustwalkers(src)
	new /obj/item/clothing/suit/armor/medium/tribal/deadhorses(src)

// T

/datum/gear/donator/kits/thingpony
	name = "The Ultra Cutie Kit"
	path = /obj/item/storage/box/large/custom_kit/thingpony
	ckeywhitelist = list("thingpony")

/obj/item/storage/box/large/custom_kit/thingpony/PopulateContents()
	new /obj/item/clothing/suit/hooded/outcast(src)
	new /obj/item/gun/ballistic/automatic/pistol/ninemil/maria(src)
	new /obj/item/gun/ballistic/automatic/pistol/n99/crusader/thingpony(src)

/datum/gear/donator/kits/tk420634
	name = "Casey's 'Business' Bundle"
	path = /obj/item/storage/box/large/custom_kit/tk420634
	ckeywhitelist = list("tk420634")

/obj/item/storage/box/large/custom_kit/tk420634/PopulateContents()
	new /obj/item/clothing/head/beret/sec/navyofficer(src)
	new /obj/item/clothing/suit/armor/light/leather(src)
	new /obj/item/melee/onehanded/knife/trench(src)
	new /obj/item/gun/ballistic/automatic/varmint/bushmaster_arm_gun(src)
	new /obj/item/ammo_box/a308box/improvised(src)
	new /obj/item/ammo_box/a308box/improvised(src)
	new /obj/item/ammo_box/magazine/m556/rifle(src)
	new /obj/item/reagent_containers/food/snacks/grown/poppy/lily(src)
	new /obj/item/binoculars(src)
	new /obj/item/gun_upgrade/barrel/forged(src)
	new /obj/item/tool_upgrade/refinement/stabilized_grip(src)
	new /obj/item/gun/ballistic/revolver/thatgun(src)
	new /obj/item/ammo_box/a308box(src)

/datum/gear/donator/kits/tk420634_2
	name = "Catgirl Kit"
	path = /obj/item/storage/box/large/custom_kit/tk420634_2
	ckeywhitelist = list("tk420634")

/obj/item/storage/box/large/custom_kit/tk420634_2/PopulateContents()
	new /obj/item/melee/unarmed/brass/spiked(src)
	new /obj/item/reagent_containers/glass/bowl(src)
	new /obj/item/reagent_containers/food/condiment/milk(src)
	new /obj/item/reagent_containers/food/snacks/deadmouse(src)
	new /obj/item/clothing/suit/armor/light/kit/shoulder(src)
	new /obj/item/melee/onehanded/knife/throwing(src)
	new /obj/item/melee/onehanded/knife/throwing(src)
	new /obj/item/melee/onehanded/knife/throwing(src)
	new /obj/item/reagent_containers/food/snacks/kebab/rat/double(src)
	new /obj/item/reagent_containers/food/drinks/bottle/instacocoa(src)

/datum/gear/donator/kits/tk420634_3
	name = "Pandagirl kit"
	path = /obj/item/storage/box/large/custom_kit/tk420634_3
	ckeywhitelist = list("tk420634")

/obj/item/storage/box/large/custom_kit/tk420634_3/PopulateContents()
	new /obj/item/clothing/suit/armor/light/kit/shoulder(src)
	new /obj/item/melee/baton/boomerang/loaded(src)
	new /obj/item/radio/tribal(src)
	new /obj/item/clothing/shoes/combat/sneakboots(src)
	new /obj/item/clothing/glasses/phantomthief(src)
	new /obj/item/storage/backpack/satchel/sec(src)
	new /obj/item/clothing/gloves/thief(src)
	new /obj/item/stealthboy(src)
	new /obj/item/lockpick_set(src)
	new /obj/item/lockpick_set(src)
	new /obj/item/lockpick_set(src)

/datum/gear/donator/kits/tonyburritos
	name = "NCR Scout"
	path = /obj/item/storage/box/large/custom_kit/tonyburritos
	ckeywhitelist = list("tonyburritos")

/obj/item/storage/box/large/custom_kit/tonyburritos/PopulateContents()
	new /obj/item/clothing/gloves/f13/leather/fingerless(src)
	new /obj/item/clothing/under/f13/ncr(src)
	new /obj/item/clothing/shoes/f13/military/ncr(src)
	new /obj/item/clothing/head/f13/ncr/ncr_flapcap(src)
	new /obj/item/clothing/suit/armor/light/leather(src)
	new /obj/item/clothing/mask/ncr_facewrap(src)

/datum/gear/donator/kits/tonyburritos2
	name = "Traveling Ranger"
	path = /obj/item/storage/box/large/custom_kit/tonyburritos2
	ckeywhitelist = list("tonyburritos")

/obj/item/storage/box/large/custom_kit/tonyburritos2/PopulateContents()
	new /obj/item/clothing/suit/armor/medium/combat/desert_ranger(src)
	new /obj/item/clothing/under/f13/ranger/modif_ranger(src)
	new /obj/item/clothing/accessory/ranger(src)
	new /obj/item/clothing/gloves/f13/leather/fingerless(src)
	new /obj/item/clothing/mask/bandana/legion/legprime(src)
	new /obj/item/clothing/shoes/f13/military/desert(src)
	new /obj/item/clothing/head/helmet/f13/ncr/rangercombat/desert(src)
	new /obj/item/clothing/head/helmet/f13/ncr/rangercombat/desert/whiskey(src)
	new /obj/item/gun/ballistic/revolver/revolver45(src)

/datum/gear/donator/kits/truedark
	name = "Stolen Brotherhood Supplies"
	path = /obj/item/storage/box/large/custom_kit/truedark
	ckeywhitelist = list("truedark")

/obj/item/storage/box/large/custom_kit/truedark/PopulateContents()
	new /obj/item/gun/energy/laser/pistol(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/stack/cable_coil/thirty(src)
	new /obj/item/gun/energy/laser/auto/nayriin(src)
	new /obj/item/weldingtool/largetank/cylphie(src)
	new /obj/item/clothing/under/rank/security/officer/skirt(src)

/datum/gear/donator/kits/truedark2
	name = "Alaskan Survival Kit"
	path = /obj/item/storage/box/large/custom_kit/truedark2
	ckeywhitelist = list("truedark")

/obj/item/storage/box/large/custom_kit/truedark2/PopulateContents()
	//new /obj/item/gun/ballistic/bow/xbow(src)
	new /obj/item/gun/ballistic/bow/lightxbow(src)
	new /obj/item/storage/bag/tribe_quiver/light/full(src)
	new /obj/item/smelling_salts/wayfarer(src)
	new /obj/item/reagent_containers/glass/bottle/gaia(src)
	new /obj/item/reagent_containers/pill/patch/turbo(src)

/datum/gear/donator/kits/truedark3
	name = "Junker's Kit"
	path = /obj/item/storage/box/large/custom_kit/truedark3
	ckeywhitelist = list("truedark")

/obj/item/storage/box/large/custom_kit/truedark3/PopulateContents()
	new /obj/item/clothing/suit/armor/light/leather/rig(src)
	new /obj/item/clothing/under/rank/rnd/roboticist(src)
	new /obj/item/clothing/suit/hooded/wintercoat/robotics(src)
	new /obj/item/gun/ballistic/revolver/hobo/piperifle(src)
	new /obj/item/ammo_box/a556(src)
	new /obj/item/toy/plush/lampplushie(src)

/datum/gear/donator/kits/truedark4
	name = "Alien Stuff"
	path = /obj/item/storage/box/large/custom_kit/truedark4
	ckeywhitelist = list("truedark")

/obj/item/storage/box/large/custom_kit/truedark4/PopulateContents()
	new /obj/item/clothing/suit/radiation(src)
	new /obj/item/clothing/head/radiation(src)
	// /obj/item/gun/energy/alien(src)
	new /obj/item/stack/cable_coil/thirty(src)
	new /obj/item/stack/sheet/mineral/abductor/ten(src)

// U
// V
// W

/datum/gear/donator/kits/wrongendoftherainbow
	name = "Slave Equipment"
	path = /obj/item/storage/box/large/custom_kit/wrongendoftherainbow
	ckeywhitelist = list("wrongendoftherainbow")

/obj/item/storage/box/large/custom_kit/wrongendoftherainbow/PopulateContents()
	new /obj/item/electropack/shockcollar/shimsusa_shackles(src)
	new /obj/item/clothing/under/f13/exile/tribal/shimsusa_loincloth(src)
	new /obj/item/storage/bag/plants(src)

/datum/gear/donator/kits/weredoggo
	name = "BBQ Fun"
	path = /obj/item/storage/box/large/custom_kit/weredoggo
	ckeywhitelist = list("weredoggo")

/obj/item/storage/box/large/custom_kit/weredoggo/PopulateContents()
	new /obj/item/reagent_containers/food/condiment/bbqsauce(src)
	new /obj/item/storage/box/hug(src)
	new /obj/item/pen/edagger(src)
	new /obj/item/reagent_containers/food/snacks/peanut_butter(src)
	new /obj/item/coin/gold/dogecoin(src)


// X
// Y

/datum/gear/donator/kits/yawet
	name = "Tribal Drip"
	path = /obj/item/storage/box/large/custom_kit/yawet
	ckeywhitelist = list("yawet330")

/obj/item/storage/box/large/custom_kit/yawet/PopulateContents()
	new /obj/item/clothing/suit/hooded/outcast(src)
	new /obj/item/twohanded/sledgehammer/simple(src)

// Z

/datum/gear/donator/kits/zeronetalpha
	name = "DocBot115"
	path = /obj/item/storage/box/large/custom_kit/zeronetalpha
	ckeywhitelist = list("zeronetalpha")

/obj/item/storage/box/large/custom_kit/zeronetalpha/PopulateContents()
	new /obj/item/gun/energy/laser/pistol(src)
	new /obj/item/storage/belt/shoulderholster(src)
	new /obj/item/clothing/head/beret/med(src)
	new /obj/item/clothing/suit/toggle/labcoat/emt/highvis(src)
	new /obj/item/clothing/under/pants/black(src)
	new /obj/item/clothing/shoes/jackboots(src)
	new /obj/item/stealthboy(src)
	new /obj/item/gun/ballistic/automatic/x9/toy(src)

/datum/gear/donator/kits/zeronetalpha2
	name = "EIEIO"
	path = /obj/item/storage/box/large/custom_kit/zeronetalpha2
	ckeywhitelist = list("zeronetalpha")

/obj/item/storage/box/large/custom_kit/zeronetalpha2/PopulateContents()
	new /obj/item/clothing/gloves/evening/black(src)
	new /obj/item/clothing/shoes/wraps(src)
	new /obj/item/clothing/suit/jacket/leather/overcoat(src)
	new /obj/item/clothing/under/dress/blacktango(src)
	new /obj/item/clothing/head/beret(src)
	new /obj/item/gun/energy/laser/pistol(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)
	new /obj/item/stock_parts/cell/ammo/ec(src)

*/

//Mayor Kit

/*/datum/gear/donator/kits/Mayor_kit
	name = "Mayor Card"
	path = /obj/item/storage/box/large/custom_kit/Mayor_kit
	ckeywhitelist = list("Mayor_kit")

/obj/item/storage/box/large/custom_kit/Mayor_kit/PopulateContents()
	new /obj/item/card/id/captains_spare(src)
	new /obj/item/radio/headset/headset_town/mayor(src)
	new /obj/item/kit_spawner/townie/mayor(src)*/

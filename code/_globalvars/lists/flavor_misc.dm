//Preferences stuff
	//Hairstyles
GLOBAL_LIST_EMPTY(hair_styles_list)			//stores /datum/sprite_accessory/hair indexed by name
GLOBAL_LIST_EMPTY(hair_styles_male_list)		//stores only hair names
GLOBAL_LIST_EMPTY(hair_styles_female_list)	//stores only hair names
GLOBAL_LIST_EMPTY(facial_hair_styles_list)	//stores /datum/sprite_accessory/facial_hair indexed by name
GLOBAL_LIST_EMPTY(facial_hair_styles_male_list)	//stores only hair names
GLOBAL_LIST_EMPTY(facial_hair_styles_female_list)	//stores only hair names
	//Underwear
GLOBAL_LIST_EMPTY_TYPED(underwear_list, /datum/sprite_accessory/underwear/bottom)		//stores bottoms indexed by name
GLOBAL_LIST_EMPTY(underwear_m)	//stores only underwear name
GLOBAL_LIST_EMPTY(underwear_f)	//stores only underwear name
	//Undershirts
GLOBAL_LIST_EMPTY_TYPED(undershirt_list, /datum/sprite_accessory/underwear/top) 	//stores tops indexed by name
GLOBAL_LIST_EMPTY(undershirt_m)	 //stores only undershirt name
GLOBAL_LIST_EMPTY(undershirt_f)	 //stores only undershirt name
	//Socks
GLOBAL_LIST_EMPTY_TYPED(socks_list, /datum/sprite_accessory/underwear/socks)		//stores socks indexed by name

//a way to index the right bodypart list given the type of bodypart
GLOBAL_LIST_INIT(mutant_reference_list, list())

//references wag types to regular types, wings open to wings, etc
GLOBAL_LIST_INIT(mutant_transform_list, list())

GLOBAL_LIST_INIT(ghost_forms_with_directions_list, list("ghost")) //stores the ghost forms that support directional sprites
GLOBAL_LIST_INIT(ghost_forms_with_accessories_list, list("ghost")) //stores the ghost forms that support hair and other such things

GLOBAL_LIST_INIT(ai_core_display_screens, list(
	":thinking:",
	"Alien",
	"Angel",
	"Angryface",
	"AtlantisCZE",
	"Banned",
	"Bliss",
	"Blue",
	"Boy",
	"Boy-Malf",
	"Girl",
	"Girl-Malf",
	"Database",
	"Dorf",
	"Firewall",
	"Fuzzy",
	"Gentoo",
	"Glitchman",
	"Gondola",
	"Goon",
	"Hades",
	"Heartline",
	"Helios",
	"Hotdog",
	"Hourglass",
	"House",
	"Inverted",
	"Jack",
	"Matrix",
	"Monochrome",
	"Mothman",
	"Murica",
	"Nanotrasen",
	"Not Malf",
	"Patriot",
	"Pirate",
	"President",
	"Rainbow",
	"Random",
	"Ravensdale",
	"Red October",
	"Red",
	"Royal",
	"Searif",
	"Serithi",
	"SilveryFerret",
	"Smiley",
	"Static",
	"Syndicat Meow",
	"TechDemon",
	"Terminal",
	"Text",
	"Too Deep",
	"Triumvirate",
	"Triumvirate-M",
	"Wasp",
	"Weird",
	"Xerxes",
	"Yes-Man"
	))

/proc/resolve_ai_icon(input)
	if(!input || !(input in GLOB.ai_core_display_screens))
		return "ai"
	else
		if(input == "Random")
			input = pick(GLOB.ai_core_display_screens - "Random")
		return "ai-[lowertext(input)]"

GLOBAL_LIST_INIT(security_depts_prefs, list(SEC_DEPT_RANDOM, SEC_DEPT_NONE, SEC_DEPT_ENGINEERING, SEC_DEPT_MEDICAL, SEC_DEPT_SCIENCE, SEC_DEPT_SUPPLY))

//Backpacks
#define DBACKPACK "Department Backpack"
#define DSATCHEL "Department Satchel"
#define DDUFFELBAG "Department Duffel Bag"
GLOBAL_LIST_INIT(backbaglist, list(DBACKPACK, DSATCHEL, DDUFFELBAG, //everything after this point is a non-department backpack
	"Hiking Backpack" = /obj/item/storage/backpack,
	"Medical Backpack" = /obj/item/storage/backpack/medic,
	"Service Backpack" = /obj/item/storage/backpack/enclave,
	"Security Backpack" = /obj/item/storage/backpack/security,
	"Captain Backpack" = /obj/item/storage/backpack/captain,
	"Trekkers Pack" = /obj/item/storage/backpack/trekker,
	"Trophy Rack" = /obj/item/storage/backpack/cultpack,
	"Explorer Bag" = /obj/item/storage/backpack/explorer,
	"Grey Duffel Bag" = /obj/item/storage/backpack/duffelbag,
	"Medical Duffel Bag" = /obj/item/storage/backpack/duffelbag/med,
	"Security Duffel Bag" = /obj/item/storage/backpack/duffelbag/sec,
	"Captain Duffel Bag" = /obj/item/storage/backpack/duffelbag/captain,
	"Grey Satchel" = /obj/item/storage/backpack/satchel,
	"Leather Satchel" = /obj/item/storage/backpack/satchel/leather,
	"Bone Satchel" = /obj/item/storage/backpack/satchel/bone,
	"Explorer Satchel" = /obj/item/storage/backpack/satchel/explorer,
	"Medical Satchel" = /obj/item/storage/backpack/satchel/med,
	"Old Satchel" = /obj/item/storage/backpack/satchel/old,
	"Service Satchel" = /obj/item/storage/backpack/satchel/enclave,
	"Security Satchel" = /obj/item/storage/backpack/satchel/sec,
	"Captain Satchel" = /obj/item/storage/backpack/satchel/cap,
	"Trekkers Satchel" = /obj/item/storage/backpack/satchel/trekker,
	))

//Suit/Skirt
#define PREF_SUIT "Jumpsuit"
#define PREF_SKIRT "Jumpskirt"
GLOBAL_LIST_INIT(jumpsuitlist, list(PREF_SUIT, PREF_SKIRT))

//Uplink spawn loc
#define UPLINK_PDA		"PDA"
#define UPLINK_RADIO	"Radio"
#define UPLINK_PEN		"Pen" //like a real spy!
GLOBAL_LIST_INIT(uplink_spawn_loc_list, list(UPLINK_PDA, UPLINK_RADIO, UPLINK_PEN))

//List of cached alpha masked icons.
GLOBAL_LIST_EMPTY(alpha_masked_worn_icons)

	//radical shit
GLOBAL_LIST_INIT(hit_appends, list("-OOF", "-ACK", "-UGH", "-HRNK", "-HURGH", "-GLORF"))

GLOBAL_LIST_INIT(scarySounds, list('sound/weapons/thudswoosh.ogg','sound/weapons/taser.ogg','sound/weapons/armbomb.ogg','sound/voice/hiss1.ogg','sound/voice/hiss2.ogg','sound/voice/hiss3.ogg','sound/voice/hiss4.ogg','sound/voice/hiss5.ogg','sound/voice/hiss6.ogg','sound/effects/glassbr1.ogg','sound/effects/glassbr2.ogg','sound/effects/glassbr3.ogg','sound/items/welder.ogg','sound/items/welder2.ogg','sound/machines/airlock.ogg','sound/effects/clownstep1.ogg','sound/effects/clownstep2.ogg'))


// Reference list for disposal sort junctions. Set the sortType variable on disposal sort junctions to
// the index of the sort department that you want. For example, sortType set to 2 will reroute all packages
// tagged for the Cargo Bay.

/* List of sortType codes for mapping reference
0 Waste
1 Disposals - All unwrapped items and untagged parcels get picked up by a junction with this sortType. Usually leads to the recycler.
2 Cargo Bay
3 QM Office
4 Engineering
5 CE Office
6 Atmospherics
7 Security
8 HoS Office
9 Medbay
10 CMO Office
11 Chemistry
12 Research
13 RD Office
14 Robotics
15 HoP Office
16 Library
17 Chapel
18 Theatre
19 Bar
20 Kitchen
21 Hydroponics
22 Janitor
23 Genetics
24 Circuitry
25 Toxins
26 Dormitories
27 Virology
28 Xenobiology
29 Law Office
30 Detective's Office
*/

//The whole system for the sorttype var is determined based on the order of this list,
//disposals must always be 1, since anything that's untagged will automatically go to disposals, or sorttype = 1 --Superxpdude

//If you don't want to fuck up disposals, add to this list, and don't change the order.
//If you insist on changing the order, you'll have to change every sort junction to reflect the new order. --Pete

GLOBAL_LIST_INIT(TAGGERLOCATIONS, list("Disposals",
	"Cargo Bay", "QM Office", "Engineering", "CE Office",
	"Atmospherics", "Security", "HoS Office", "Medbay",
	"CMO Office", "Chemistry", "Research", "RD Office",
	"Robotics", "HoP Office", "Library", "Chapel", "Theatre",
	"Bar", "Kitchen", "Hydroponics", "Janitor Closet","Genetics",
	"Circuitry", "Toxins", "Dormitories", "Virology",
	"Xenobiology", "Law Office","Detective's Office"))

GLOBAL_LIST_INIT(station_prefixes, world.file2list("strings/station_prefixes.txt") + "")

GLOBAL_LIST_INIT(station_names, world.file2list("strings/station_names.txt" + ""))

GLOBAL_LIST_INIT(station_suffixes, world.file2list("strings/station_suffixes.txt"))

GLOBAL_LIST_INIT(greek_letters, world.file2list("strings/greek_letters.txt"))

GLOBAL_LIST_INIT(phonetic_alphabet, world.file2list("strings/phonetic_alphabet.txt"))

GLOBAL_LIST_INIT(numbers_as_words, world.file2list("strings/numbers_as_words.txt"))

/proc/generate_number_strings()
	var/list/L[198]
	for(var/i in 1 to 99)
		L += "[i]"
		L += "\Roman[i]"
	return L

GLOBAL_LIST_INIT(station_numerals, greek_letters + phonetic_alphabet + numbers_as_words + generate_number_strings())

GLOBAL_LIST_INIT(admiral_messages, list("Do you know how expensive these stations are?","Stop wasting my time.","I was sleeping, thanks a lot.","Stand and fight you cowards!","You knew the risks coming in.","Stop being paranoid.","Whatever's broken just build a new one.","No.", "<i>null</i>","<i>Error: No comment given.</i>", "It's a good day to die!"))

GLOBAL_LIST_INIT(redacted_strings, list("\[REDACTED\]", "\[CLASSIFIED\]", "\[ARCHIVED\]", "\[EXPLETIVE DELETED\]", "\[EXPUNGED\]", "\[INFORMATION ABOVE YOUR SECURITY CLEARANCE\]", "\[MOVE ALONG CITIZEN\]", "\[NOTHING TO SEE HERE\]", "\[ACCESS DENIED\]"))

GLOBAL_LIST_INIT(wisdoms, world.file2list("strings/wisdoms.txt"))

GLOBAL_LIST_INIT(speech_verbs, list("default", "says", "rasps", "states", "bellows", "chirps", "hisses", "mumbles", "squeals", "barks", "meows", "growls", "drawls", "chitters", "declares", "mutters", "howls", "bleats", "cries", "murmurs"))

GLOBAL_LIST_INIT(roundstart_tongues, list(
	"default",
	"human tongue" = /obj/item/organ/tongue
	))

//locked parts are those that your picked species requires to have
//unlocked parts are those that anyone can choose on customisation regardless
//parts not in unlocked, but in all, are thus locked
GLOBAL_LIST_INIT(all_mutant_parts, list())
GLOBAL_LIST_INIT(unlocked_mutant_parts, list())
//parts in either of the above two lists that require a second option that allows them to be coloured
GLOBAL_LIST_INIT(colored_mutant_parts, list())

//body ids that have greyscale sprites
GLOBAL_LIST_INIT(greyscale_limb_types, list("human"))

//body ids that have prosthetic sprites
GLOBAL_LIST_INIT(prosthetic_limb_types, list("xion","bishop","cybersolutions","grayson","hephaestus","nanotrasen","talon"))

//body ids that have non-gendered bodyparts
GLOBAL_LIST_INIT(nongendered_limb_types, list("zombie" ,"synth", "shadow", "cultgolem", "agent", "smutant"))

//list of eye types, corresponding to a respective left and right icon state for the set of eyes
GLOBAL_LIST_INIT(eye_types, list("normal"))

//list linking bodypart bitflags to their actual names
GLOBAL_LIST_INIT(bodypart_names, list(num2text(HEAD) = "Head", num2text(CHEST) = "Chest", num2text(LEG_LEFT) = "Left Leg", num2text(LEG_RIGHT) = "Right Leg", num2text(ARM_LEFT) = "Left Arm", num2text(ARM_RIGHT) = "Right Arm"))
// list linking bodypart names back to the bitflags
GLOBAL_LIST_INIT(bodypart_values, list("Head" = num2text(HEAD), "Chest" = num2text(CHEST), "Left Leg" = num2text(LEG_LEFT), "Right Leg" = num2text(LEG_RIGHT), "Left Arm" = num2text(ARM_LEFT), "Right Arm" = num2text(ARM_RIGHT)))

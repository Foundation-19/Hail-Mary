// Text transformation for roleplay flavor

GLOBAL_LIST_INIT(accent_types, list("tribal", "ghoul", "raider", "bos", "ncr", "robot"))

GLOBAL_LIST_INIT(accent_replacements, list(
	"tribal" = list(
		"hello" = "greetings",
		"help" = "aid",
		"friend" = "brother",
		"enemy" = "walker",
		"dead" = "gone to dust",
		"kill" = "end",
		"die" = "join the dust",
		"food" = "sustenance",
		"water" = "life-water",
		"yes" = "indeed",
		"no" = "never",
		"thank you" = "blessings upon you",
		"go" = "journey",
		"wait" = "hold"
	),
	"ghoul" = list(
		"hello" = "hrrrm",
		"back in my day" = "back before the fires",
		"young" = "fresh",
		"old" = "ancient like me",
		"good" = "right proper",
		"bad" = "mighty wrong",
		"people" = "folk",
		"kids" = "youngins",
		"war" = "the big one"
	),
	"raider" = list(
		"you" = "ya",
		"your" = "yer",
		"hello" = "oi",
		"good" = "solid",
		"bad" = "screwed",
		"give" = "hand over",
		"food" = "grub",
		"money" = "caps",
		"weapon" = "iron",
		"leave" = "scram",
		"drink" = "booze",
		"die" = "croak"
	),
	"bos" = list(
		"soldier" = "knight",
		"people" = "personnel",
		"help" = "assist",
		"mission" = "operation",
		"enemy" = "hostile",
		"report" = "submit report",
		"yes" = "affirmative",
		"no" = "negative"
	),
	"ncr" = list(
		"citizen" = "civilian",
		"soldier" = "trooper",
		"good" = "fair",
		"bad" = "not up to standard"
	)
))

// Apply accent to message
/proc/apply_accent(message, accent_type)
	if(!accent_type || accent_type == "none")
		return message
	
	var/list/replacements = GLOB.accent_replacements[accent_type]
	if(!replacements)
		return message
	
	var/output = message
	for(var/input_word in replacements)
		var/replacement = replacements[input_word]
		var/regex/R = new("\\b[input_word]\\b", "gi")
		output = R.Replace(output, replacement)
	
	// Add accent-specific phrases
	switch(accent_type)
		if("tribal")
			if(prob(10))
				output += ", [pick("blessed sun", "spirits watch", "earth bears")]"
		if("ghoul")
			if(prob(15))
				output = "Hrrr... [output]"
		if("raider")
			if(prob(10))
				output += pick("", "", " HAHA!", " Grah!")
	
	return output

// Mob accent storage - accent_type is defined in human_defines.dm

/mob/living/carbon/human/proc/set_accent(new_accent)
	var/valid_accents = list("tribal", "ghoul", "raider", "bos", "ncr", "robot", "none")
	if(new_accent in valid_accents)
		accent_type = new_accent
		to_chat(src, span_notice("Your accent is now: [new_accent]"))
	else
		to_chat(src, span_warning("Invalid accent type."))

// Player verb to set accent (admin only)
/client/verb/set_accent()
	set name = "Set Accent"
	set category = "Admin"
	set desc = "Change your character's speech accent"
	
	var/choice = input(usr, "Choose your accent:", "Accent Selection") as null|anything in GLOB.accent_types + list("None")
	
	if(choice)
		if(ishuman(usr))
			var/mob/living/carbon/human/H = usr
			H.set_accent(lowertext(choice))
		else
			to_chat(usr, span_notice("Your accent is now: [lowertext(choice)]"))

// Accent descriptions for UI
/proc/get_accent_description(accent_type)
	switch(accent_type)
		if("tribal")
			return "Ancient, symbolic speech with nature references"
		if("ghoul")
			return "Raspy, guttural sounds from the old times"
		if("raider")
			return "Crude, aggressive vocabulary"
		if("bos")
			return "Formal, military terminology"
		if("ncr")
			return "Official, administrative speech"
		if("robot")
			return "Mechanical, programmed responses"
	
	return "Standard wasteland speech"

// ============ SPEECH HANDLER ============
// This applies accents to player speech via signal

/mob/living/carbon/human/proc/handle_accent_speech(datum/source, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(!message || !accent_type || accent_type == "none")
		return
	
	// Don't apply to emotes
	if(copytext_char(message, 1, 2) == "*")
		return
	
	message = apply_accent(message, accent_type)
	speech_args[SPEECH_MESSAGE] = message

// Register the speech handler on humans
/mob/living/carbon/human/Login()
	. = ..()
	RegisterSignal(src, COMSIG_MOB_SAY, PROC_REF(handle_accent_speech))

/mob/living/carbon/human/Logout()
	. = ..()
	UnregisterSignal(src, COMSIG_MOB_SAY)

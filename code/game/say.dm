/*
Miauw's big Say() rewrite.
This file has the basic atom/movable level speech procs.
And the base of the send_speech() proc, which is the core of saycode.
*/

/atom/movable/proc/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null, just_chat)
	if(!can_speak())
		return
	if(message == "" || !message)
		return
	spans |= speech_span
	if(!language)
		language = get_selected_language()
	send_speech(message, 7, src, , spans, message_language=language, just_chat = just_chat)

/atom/movable/proc/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args)

/atom/movable/proc/can_speak()
	return 1

/atom/movable/proc/send_speech(message, range = 7, atom/movable/source = src, bubble_type, list/spans, datum/language/message_language = null, message_mode, just_chat)
	var/rendered = compose_message(src, message_language, message, , spans, message_mode, source)
	for(var/_AM in get_hearers_in_view(range, source))
		var/atom/movable/AM = _AM
		AM.Hear(rendered, src, message_language, message, , spans, message_mode, source)

/atom/movable/proc/compose_message(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, face_name = FALSE, atom/movable/source)
	if(!source)
		source = speaker
	//This proc uses text() because it is faster than appending strings. Thanks BYOND.
	//Basic span
	var/spanpart1 = "<span class='[radio_freq ? get_radio_span(radio_freq) : "game say"]'>"
	//Start name span.
	var/spanpart2 = "<span class='name'>"
	//Radio freq/name display
	var/freqpart = radio_freq ? "\[[get_radio_name(radio_freq)]\] " : ""
	//Speaker name
	var/raw_voice = speaker.GetVoice()
	//The real mob behind a speaker - virtualspeakers (radio, AI) resolve back to whoever is actually talking.
	var/atom/movable/identity_obj = speaker.GetSource() || speaker
	var/namepart = "[raw_voice][speaker.get_alt_name()]"
	//Anonymize natural (non-disguised) voices/faces for living listeners who haven't remembered this speaker yet.
	//Radio speech is gated by voice recognition (known_voices); face-to-face speech is gated by face/badge
	//recognition (known_faces) instead - these are tracked independently, so recognizing someone's voice over
	//the radio doesn't mean you'd recognize their face in person, and vice versa.
	if(isliving(src) && isliving(identity_obj) && identity_obj != src)
		var/mob/living/listener = src
		var/mob/living/real_speaker = identity_obj
		var/natural_voice = ishuman(real_speaker) ? real_speaker.get_visible_name() : null
		//Only go through recognition for their own natural voice - a disguised/mimicked voice already set
		//raw_voice to something else above and should never be touched here.
		if(raw_voice == natural_voice)
			if(radio_freq)
				//A voice the listener has already made a mental note of stays recognizable
				//regardless of radio auto-identify settings - that's the whole point of remembering it.
				if(real_speaker.auto_identifies_on_radio(radio_freq))
					namepart = "[raw_voice][speaker.get_alt_name()]" //opted to reveal their real name on this channel
				else
					var/remembered = listener.knows_voice(real_speaker)
					//Stays a clickable link even once remembered, so the listener can re-remember it under a different name later.
					var/voice_label = remembered ? "[remembered][speaker.get_alt_name()]" : real_speaker.get_voice_tag()
					namepart = "<a href='?src=[REF(listener)];remember_voice=[REF(real_speaker)]'>[voice_label]</a>"
			else
				//Face-to-face: only the badge/job id on their chest, unless the listener has specifically
				//remembered this face before - real names aren't given away just because a face is visible.
				var/remembered_face = listener.knows_face(real_speaker)
				var/face_label = remembered_face ? "[remembered_face][speaker.get_alt_name()]" : real_speaker.get_identity_tag()
				namepart = "<a href='?src=[REF(listener)];remember_face=[REF(real_speaker)]'>[face_label]</a>"
	if(face_name && ishuman(speaker))
		var/mob/living/carbon/human/H = speaker
		namepart = "[H.get_face_name()]" //So "fake" speaking like in hallucinations does not give the speaker away if disguised
	//End name span.
	var/endspanpart = "</span>"

	//Message
	var/messagepart = " <span class='message'>[lang_treat(speaker, message_language, raw_message, spans, message_mode)]</span></span>"

	var/languageicon = ""
	var/datum/language/D = GLOB.language_datum_instances[message_language]
	if(istype(D) && D.display_icon(src))
		languageicon = "[D.get_icon()] "

	return "[spanpart1][spanpart2][freqpart][languageicon][compose_track_href(speaker, namepart)][namepart][compose_job(speaker, message_language, raw_message, radio_freq)][endspanpart][messagepart]"

/atom/movable/proc/compose_track_href(atom/movable/speaker, message_langs, raw_message, radio_freq)
	return ""

/atom/movable/proc/compose_job(atom/movable/speaker, message_langs, raw_message, radio_freq)
	return ""

/atom/movable/proc/say_mod(input, message_mode)
	var/ending = copytext_char(input, -1)
	if(copytext_char(input, -2) == "!!")
		return verb_yell
	else if(ending == "?")
		return verb_ask
	else if(ending == "!")
		return verb_exclaim
	else
		return verb_say

/atom/movable/proc/say_quote(input, list/spans=list(speech_span), message_mode)
	if(!input)
		input = "..."

	if(copytext_char(input, -2) == "!!")
		spans |= SPAN_YELL

	var/spanned = attach_spans(input, spans)
	return "[say_mod(input, message_mode)][spanned ? ", \"[spanned]\"" : ""]"
	// Citadel edit [spanned ? ", \"[spanned]\"" : ""]"

#define ENCODE_HTML_EPHASIS(input, char, html, varname) \
	var/static/regex/##varname = regex("[char]{2}(.+?)[char]{2}", "g");\
	input = varname.Replace_char(input, "<[html]>$1</[html]>")

/// Converts specific characters, like +, |, and _ to formatted output.
/atom/movable/proc/say_emphasis(input)
	var/static/regex/italics = regex(@"\|((?=\S)[\w\W]*?(?<=\S))\|", "g")
	input = italics.Replace_char(input, "<i>$1</i>")
	var/static/regex/bold = regex(@"\+((?=\S)[\w\W]*?(?<=\S))\+", "g")
	input = bold.Replace_char(input, "<b>$1</b>")
	var/static/regex/underline = regex(@"_((?=\S)[\w\W]*?(?<=\S))_", "g")
	input = underline.Replace_char(input, "<u>$1</u>")
	return input

/atom/movable/proc/say_narrate_replace(input, atom/thing)
	if(!istype(thing))
		return
	if(findtext(input, "@"))
		. = replacetext(input, "@", "<b>[thing.name]</b>")
	return

/// Quirky citadel proc for our custom sayverbs to strip the verb out. Snowflakey as hell, say rewrite 3.0 when?
/atom/movable/proc/quoteless_say_quote(input, list/spans = list(speech_span), message_mode)
	if((input[1] == "!") && (length_char(input) > 1))
		return ""
	var/pos = findtext(input, "*")
	return pos? copytext(input, pos + 1) : input

/atom/movable/proc/lang_treat(atom/movable/speaker, datum/language/language, raw_message, list/spans, message_mode, no_quote = FALSE)
	if(has_language(language))
		var/atom/movable/AM = speaker.GetSource()
		raw_message = say_emphasis(raw_message)
		if(AM) //Basically means "if the speaker is virtual"
			return no_quote ? AM.quoteless_say_quote(raw_message, spans, message_mode) : AM.say_quote(raw_message, spans, message_mode)
		else
			return no_quote ? speaker.quoteless_say_quote(raw_message, spans, message_mode) : speaker.say_quote(raw_message, spans, message_mode)
	else if(language)
		var/atom/movable/AM = speaker.GetSource()
		var/datum/language/D = GLOB.language_datum_instances[language]
		raw_message = D.scramble(raw_message)
		if(AM)
			return no_quote ? AM.quoteless_say_quote(raw_message, spans, message_mode) : AM.say_quote(raw_message, spans, message_mode)
		else
			return no_quote ? speaker.quoteless_say_quote(raw_message, spans, message_mode) : speaker.say_quote(raw_message, spans, message_mode)
	else
		return "makes a strange sound."

/proc/get_radio_span(freq)
	var/returntext = GLOB.freqtospan["[freq]"]
	if(returntext)
		return returntext
	return "radio"

/proc/get_radio_name(freq)
	var/returntext = GLOB.reverseradiochannels["[freq]"]
	if(returntext)
		return returntext
	return make_radio_name(freq)
	//return "[copytext_char("[freq]", 1, 4)].[copytext_char("[freq]", 4, 5)]"

/proc/make_radio_name(freq)
	if(freq in GLOB.reverseradiochannels)
		return GLOB.reverseradiochannels["[freq]"]
	var/channel_number = rand(1,9999)
	GLOB.reverseradiochannels["[freq]"] = "CH-[channel_number]"
	return GLOB.reverseradiochannels["[freq]"]
	

/atom/movable/proc/attach_spans(input, list/spans)
	if((input[1] == "!") && (length(input) > 2))
		return
	var/customsayverb = findtext(input, "*")
	if(customsayverb)
		input = capitalize(copytext(input, customsayverb + length(input[customsayverb])))
	if(input)
		return "[message_spans_start(spans)][input]</span>"
	else
		return

/proc/message_spans_start(list/spans)
	var/output = "<span class='"
	for(var/S in spans)
		output = "[output][S] "
	output = "[output]'>"
	return output

/proc/say_test(text)
	var/ending = copytext_char(text, -1)
	if (ending == "?")
		return "1"
	else if (ending == "!")
		return "2"
	return "0"

/atom/movable/proc/GetVoice()
	return "[src]"	//Returns the atom's name, prepended with 'The' if it's not a proper noun

/atom/movable/proc/IsVocal()
	return 1

/atom/movable/proc/get_alt_name()

/*
	Voice/face anonymity system.
	Vars and procs both live here (instead of a separate mob/living file) because this
	codebase's build requires a var/proc to be defined in the same file as, or an
	earlier-included file than, any file that references it - and compose_message()
	below is included very early.
*/

/mob/living
	/// Stable anonymous tag shown to listeners who haven't remembered this mob's voice.
	var/voice_tag
	/// ref -> remembered display name, keyed by the speaking atom's real identity ref. Personal to this mob.
	var/list/known_voices = list()

/// Generates (once) and returns this mob's anonymous voice tag.
/mob/living/proc/get_voice_tag()
	if(!voice_tag)
		voice_tag = "Unknown Voice ([uppertext(num2hex(rand(0, 65535), 4))])"
	return voice_tag

/// Non-human living mobs have no faction radio auto-identify preference by default.
/mob/living/proc/auto_identifies_on_radio(radio_freq)
	return FALSE

/mob/living/carbon/human/auto_identifies_on_radio(radio_freq)
	if(!radio_freq || !client?.prefs?.auto_identify_faction_radio)
		return FALSE
	var/channel_name = get_radio_name(radio_freq)
	return (channel_name in faction)

/// Returns the name this mob has previously remembered for the given speaker, if any.
/mob/living/proc/knows_voice(atom/movable/speaker)
	return known_voices[REF(speaker)]

/// Permanently (for this mob only, this round) associates a speaker's voice with a display name.
/mob/living/proc/remember_voice(atom/movable/speaker, display_name)
	if(!speaker || !display_name)
		return
	known_voices[REF(speaker)] = display_name
	to_chat(src, span_notice("You make a mental note of that voice - it's [display_name]."))

/mob/living
	/// Stable per-mob disambiguating suffix for the anonymous visual identity tag (e.g. "A1B2"). Persists even
	/// if the mob later swaps badges, so a bystander who's noticed "that stranger (A1B2)" can tell if the same
	/// person starts wearing a different badge.
	var/identity_tag_suffix
	/// ref -> remembered display name, keyed by the looked-at mob's real identity ref. Separate from known_voices -
	/// recognizing someone's face doesn't mean you'd recognize their voice over radio, or vice versa.
	var/list/known_faces = list()
	/// world.time deadline before THIS mob (as a target) can be challenged with verify_identity() again. Set on
	/// every attempt, win or lose, so a blown read can't just be immediately re-tried by someone else.
	var/identity_check_cooldown_until = 0
	/// world.time deadline before THIS mob (as a verifier) can use verify_identity() again, regardless of target.
	var/identity_check_verifier_cooldown_until = 0

/// Returns the job id printed on whatever badge this mob is currently wearing, or the generic wasteland default
/// if it has none. Non-human living mobs don't wear badges, so they default to the generic label.
/mob/living/proc/get_badge_assignment()
	return FACTION_WASTELAND

/// Generates (once) and returns this mob's anonymous visual identity tag - their badge's claimed job id, plus a
/// stable random suffix so two strangers wearing the same job id aren't indistinguishable before being remembered.
/mob/living/proc/get_identity_tag()
	if(!identity_tag_suffix)
		identity_tag_suffix = uppertext(num2hex(rand(0, 65535), 4))
	return "[get_badge_assignment()] ([identity_tag_suffix])"

/// Returns the name this mob has previously remembered for the given target's face, if any.
/mob/living/proc/knows_face(mob/living/target)
	return known_faces[REF(target)]

/// Permanently (for this mob only, this round) associates a target's face with a display name.
/mob/living/proc/remember_face(mob/living/target, display_name)
	if(!target || !display_name)
		return
	known_faces[REF(target)] = display_name
	to_chat(src, span_notice("You commit that face to memory - it's [display_name]."))

/// Plain-text (non-link) version of the face-recognition check used by examine()/compose_message() - how
/// `viewer` would see this mob's name in a message (combat, emotes, etc.). No href attached, unlike
/// get_identity_tag()'s use in examine(), since you don't want a "remember" link spamming into combat text.
/mob/living/proc/get_display_name(mob/living/viewer)
	if(!viewer || viewer == src)
		return name
	var/remembered_name = viewer.knows_face(src)
	return remembered_name ? remembered_name : get_identity_tag()

/mob/living/Topic(href, href_list)
	if(href_list["remember_voice"])
		var/atom/movable/speaker = locate(href_list["remember_voice"]) in GLOB.mob_list
		if(speaker)
			var/existing = knows_voice(speaker)
			var/display_name = stripped_input(src, "What do you call this voice?", "Remember Voice", existing, MAX_NAME_LEN)
			if(!display_name)
				return
			remember_voice(speaker, display_name)
		return
	if(href_list["remember_face"])
		var/mob/living/target = locate(href_list["remember_face"]) in GLOB.mob_list
		if(target)
			var/existing = knows_face(target)
			var/display_name = stripped_input(src, "Who is this?", "Remember Face", existing, MAX_NAME_LEN)
			if(!display_name)
				return
			remember_face(target, display_name)
		return
	return ..()

/// Maps a badge/ID assignment string to a canonical Fallout faction define via job-title keywords, since most
/// job titles ("Sentinel", "Paladin Commander", "NCR Trooper") don't literally contain their faction's define
/// text ("BOS", "NCR"). Shared by verify_identity() below and the turret faction-registration terminal
/// (register_id_faction() in terminal.dm) so both read affiliation the same way. Returns null if unrecognised.
/proc/get_faction_from_assignment(assignment)
	if(!assignment)
		return null
	var/assign = lowertext(trim(assignment))
	// NCR / Rangers
	if(findtext(assign, "veteran ranger") || findtext(assign, "vet ranger"))
		return FACTION_RANGER
	if(findtext(assign, "ncr") || findtext(assign, "republic") || findtext(assign, "trooper") || findtext(assign, "ranger"))
		return FACTION_NCR
	// Legion
	if(findtext(assign, "legion") || findtext(assign, "centurion") || findtext(assign, "prime") || findtext(assign, "recruit medallion") || findtext(assign, "veteran medallion") || findtext(assign, "auxilia"))
		return FACTION_LEGION
	// Brotherhood of Steel
	if(findtext(assign, "brotherhood") || findtext(assign, "bos") || findtext(assign, "paladin") || findtext(assign, "knight") || findtext(assign, "scribe") || findtext(assign, "elder") || findtext(assign, "sentinel"))
		return FACTION_BROTHERHOOD
	// Enclave
	if(findtext(assign, "enclave") || findtext(assign, "us officer") || findtext(assign, "us dogtag") || findtext(assign, "american"))
		return FACTION_ENCLAVE
	// Town / Eastwood
	if(findtext(assign, "citizen") || findtext(assign, "settler") || findtext(assign, "mayor") || findtext(assign, "deputy") || findtext(assign, "sheriff"))
		return FACTION_EASTWOOD
	// Raiders
	if(findtext(assign, "raider") || findtext(assign, "outlaw") || findtext(assign, "bandit"))
		return FACTION_RAIDERS
	// Great Khans
	if(findtext(assign, "khan"))
		return FACTION_KHAN
	// Super Mutants
	if(findtext(assign, "mutant"))
		return FACTION_SMUTANT
	// Vault
	if(findtext(assign, "vault") || findtext(assign, "overseer") || findtext(assign, "dweller"))
		return FACTION_VAULT
	// Followers
	if(findtext(assign, "follower"))
		return FACTION_FOLLOWERS
	// Tribe
	if(findtext(assign, "tribe") || findtext(assign, "tribal") || findtext(assign, "talisman"))
		return FACTION_TRIBE
	// Wastelander catch-all
	if(findtext(assign, "waster") || findtext(assign, "wastelander") || findtext(assign, "survivor") || findtext(assign, "scavenger"))
		return FACTION_WASTELAND
	return null

/// Lets a real faction member challenge a nearby person's claimed affiliation - do they actually belong to the
/// faction their badge says they do, or is it stolen/forged? An opposed roll (verifier's Perception vs the
/// target's Charisma), not a certain answer - a lucky impostor can bluff past it, same as a sharp-eyed verifier
/// can see through a genuine member having an off day. Real membership is read from the target's actual faction
/// standing (mob.faction, set by their job/species - not spoofable just by swapping badges), not from the badge
/// itself; the roll only decides whether the verifier's read of that truth is accurate.
/// This is a gut feeling, not a reveal: it never touches known_faces/remember_face, so the target's name (if
/// remembered at all) stays whatever it already was. The verifier walks away personally convinced one way or
/// the other, but has nothing provable to show anyone else - it's a roleplay hook for suspicion, not hard proof.
/// Each target can only be challenged once per cooldown, win or lose - otherwise a failed read would just get
/// immediately retried by the same or another member until someone rolls well enough to unmask them.
/mob/living/verb/verify_identity()
	set name = "Verify Identity"
	set desc = "Get a read on whether a nearby person's credentials are genuine - a hunch, not proof."
	set category = "IC"

	var/list/my_factions = faction - list("neutral")
	if(!length(my_factions))
		to_chat(src, span_warning("You have no faction standing of your own to check anyone's credentials against."))
		return
	if(world.time < identity_check_verifier_cooldown_until)
		to_chat(src, span_warning("You just gave someone's credentials a good look - give it a moment before pressing another."))
		return

	var/list/mob/living/possible_targets = list()
	for(var/mob/living/target in oview(src))
		if(target == src || target.stat == DEAD)
			continue
		possible_targets += target
	if(!length(possible_targets))
		to_chat(src, span_warning("There's nobody nearby to verify."))
		return

	var/mob/living/target = input(src, "Whose credentials do you want to check?", "Verify Identity") as null|mob in possible_targets
	if(!target || QDELETED(target) || target == src)
		return
	if(get_dist(src, target) > 7)
		to_chat(src, span_warning("They've wandered too far away!"))
		return
	if(world.time < target.identity_check_cooldown_until)
		to_chat(src, span_warning("You've already given [target.get_identity_tag()]'s credentials a good look recently - pressing the issue again so soon would just tip them off."))
		return

	var/claimed_faction = get_faction_from_assignment(target.get_badge_assignment())
	if(!claimed_faction || !(claimed_faction in my_factions))
		to_chat(src, span_notice("[target.get_identity_tag()]'s badge doesn't claim any affiliation with [english_list(my_factions)]."))
		return

	// One shot at this target, whichever way it goes - keeps a failed read from just being instantly retried.
	target.identity_check_cooldown_until = world.time + IDENTITY_CHECK_COOLDOWN
	identity_check_verifier_cooldown_until = world.time + IDENTITY_CHECK_VERIFIER_COOLDOWN

	var/verifier_roll = rand(1, 20) + ((special_p - SPECIAL_DEFAULT_ATTR_VALUE) * 2)
	var/target_roll = rand(1, 20) + ((target.special_c - SPECIAL_DEFAULT_ATTR_VALUE) * 2)
	var/really_genuine = (claimed_faction in target.faction)
	var/read_succeeded = (verifier_roll > target_roll)

	// Logged for admins only - the target is never told they were checked, win or lose; disguises live or die
	// purely on the verifier's own skill, not on any out-of-character tell.
	log_game("[key_name(src)] used Verify Identity on [key_name(target)] (claimed [claimed_faction], really genuine: [really_genuine ? "yes" : "no"], read succeeded: [read_succeeded ? "yes" : "no"]).")

	if(!read_succeeded)
		// The read is wrong either way - a genuine member gets needlessly side-eyed, or (the interesting case)
		// an impostor successfully bluffs their way past scrutiny and keeps their cover intact.
		to_chat(src, span_notice("You look [target.get_identity_tag()] over and check their bearing against what you know of our own - nothing seems off. One of ours, you'd guess."))
		return
	if(really_genuine)
		to_chat(src, span_notice("You get a read on [target.get_identity_tag()] - whatever's nagging at you settles. Your gut says they're one of ours."))
	else
		to_chat(src, span_warning("Something about [target.get_identity_tag()] doesn't sit right. Your gut says they aren't really one of ours - but it's just that, a gut feeling. Nothing you could prove."))

//HACKY VIRTUALSPEAKER STUFF BEYOND THIS POINT
//these exist mostly to deal with the AIs hrefs and job stuff.

/atom/movable/proc/GetJob() //Get a job, you lazy butte

/atom/movable/proc/GetSource()

/atom/movable/proc/GetRadio()

//VIRTUALSPEAKERS
/atom/movable/virtualspeaker
	var/job
	var/atom/movable/source
	var/obj/item/radio/radio

INITIALIZE_IMMEDIATE(/atom/movable/virtualspeaker)
/atom/movable/virtualspeaker/Initialize(mapload, atom/movable/M, radio)
	. = ..()
	radio = radio
	source = M
	if (istype(M))
		name = M.GetVoice()
		verb_say = M.verb_say
		verb_ask = M.verb_ask
		verb_exclaim = M.verb_exclaim
		verb_yell = M.verb_yell

	// The mob's job identity
	if(ishuman(M))
		// Humans use their job as seen on the crew manifest. This is so the AI
		// can know their job even if they don't carry an ID.
		var/datum/data/record/findjob = find_record("name", name, GLOB.data_core.general)
		if(findjob)
			job = findjob.fields["rank"]
		else
			job = "Unknown"
	else if(iscarbon(M))  // Carbon nonhuman
		job = "No ID"
	else if(isAI(M))  // AI
		job = "AI"
	else if(iscyborg(M))  // Cyborg
		var/mob/living/silicon/robot/B = M
		job = "[B.designation] Cyborg"
	else if(istype(M, /mob/living/silicon/pai))  // Personal AI (pAI)
		job = "Personal AI"
	else if(isobj(M))  // Cold, emotionless machines
		job = "Machine"
	else  // Unidentifiable mob
		job = "Unknown"

/atom/movable/virtualspeaker/GetJob()
	return job

/atom/movable/virtualspeaker/GetSource()
	return source

/atom/movable/virtualspeaker/GetRadio()
	return radio

//To get robot span classes, stuff like that.
/atom/movable/proc/get_spans()
	return list()

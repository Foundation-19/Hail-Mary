// Additional social and roleplay emotes

/mob/verb/extended_emotes()
	set name = "Extended Emotes"
	set category = "IC"
	
	var/dat = {"
	<center><h2>Extended Emotes</h2></center>
	<p><i>Use these to express your character more fully.</i></p>
	<br>
	<h3>Social</h3>
	<p>
	<b>wave</b> - Wave at someone<br>
	<b>nod</b> - Nod respectfully<br>
	<b>shrug</b> - Shrug your shoulders<br>
	<b>bow</b> - Bow to someone<br>
	</p>
	<br>
	<h3>Gesture</h3>
	<p>
	<b>point</b> - Point at something<br>
	<b>gesture</b> - Make a general gesture<br>
	<b>scratch</b> - Scratch your head<br>
	</p>
	<br>
	<h3>Roleplay</h3>
	<p>
	<b>look</b> - Look around<br>
	<b>think</b> - Think deeply<br>
	<b>pray</b> - Pray<br>
	</p>
	<br>
	<h3>Combat</h3>
	<p>
	<b>stance</b> - Take a combat stance<br>
	<b>scan</b> - Scan the area<br>
	</p>
	<br>
	<h3>Wasteland</h3>
	<p>
	<b>checkGeiger</b> - Check for radiation<br>
	<b>rest</b> - Rest and recover<br>
	</p>
	"}
	
	usr << browse(dat, "window=extended_emotes;size=500x600")

// Extended emote verbs
/mob/verb/wave_at(mob/target as mob in oview())
	set category = "IC"
	set name = "Wave At"
	
	if(target == src)
		to_chat(src, span_warning("You can't wave at yourself."))
		return
	
	emote("waves at [target]")
	visible_message(span_notice("[src] waves at [target]."), span_notice("You wave at [target]."))

/mob/verb/nod_respectfully()
	set category = "IC"
	set name = "Nod Respectfully"
	
	emote("nods respectfully")
	visible_message(span_notice("[src] nods respectfully."), span_notice("You nod respectfully."))

/mob/verb/shrug_emote()
	set category = "IC"
	set name = "Shrug"
	
	emote("shrugs")
	visible_message(span_notice("[src] shrugs."), span_notice("You shrug."))

/mob/verb/bow_to(mob/target as mob in oview())
	set category = "IC"
	set name = "Bow"
	
	if(target == src)
		to_chat(src, span_warning("You can't bow to yourself."))
		return
	
	emote("bows to [target]")
	visible_message(span_notice("[src] bows to [target]."), span_notice("You bow to [target]."))

/mob/verb/point_at(atom/target as atom in view())
	set category = "IC"
	set name = "Point"
	
	emote("points at [target]")
	visible_message(span_notice("[src] points at [target]."), span_notice("You point at [target]."))

/mob/verb/gesture_emote()
	set category = "IC"
	set name = "Gesture"
	
	emote("makes a gesture")
	visible_message(span_notice("[src] makes a vague gesture."), span_notice("You make a gesture."))

/mob/verb/scratch_head_emote()
	set category = "IC"
	set name = "Scratch Head"
	
	emote("scratches their head")
	visible_message(span_notice("[src] scratches their head."), span_notice("You scratch your head."))

/mob/verb/look_around()
	set category = "IC"
	set name = "Look Around"
	
	emote("looks around")
	visible_message(span_notice("[src] looks around."), span_notice("You look around."))

/mob/verb/think_emote()
	set category = "IC"
	set name = "Think"
	
	emote("appears to be thinking")
	visible_message(span_notice("[src] appears to be deep in thought."), span_notice("You think deeply."))

/mob/verb/pray_emote()
	set category = "IC"
	set name = "Pray"
	
	emote("prays")
	visible_message(span_notice("[src] kneels and prays."), span_notice("You kneel and pray."))

/mob/verb/combat_stance()
	set category = "IC"
	set name = "Combat Stance"
	
	emote("takes a combat stance")
	visible_message(span_notice("[src] drops into a combat stance."), span_notice("You drop into a combat stance."))

/mob/verb/scan_area()
	set category = "IC"
	set name = "Scan Area"
	
	emote("scans the area")
	visible_message(span_notice("[src] scans the area carefully."), span_notice("You scan the area."))

/mob/verb/check_geiger()
	set category = "IC"
	set name = "Check Geiger"
	
	emote("checks for radiation")
	visible_message(span_notice("[src] checks for radiation."), span_notice("You check for radiation."))
	
	// Simple radiation check message
	var/turf/T = get_turf(src)
	if(T)
		to_chat(src, span_notice("The area seems [prob(50) ? "safe" : "somewhat radioactive"]."))

/mob/verb/rest_emote()
	set category = "IC"
	set name = "Rest"
	
	if(src.resting)
		to_chat(src, span_warning("You're already resting."))
		return
	
	emote("sits down to rest")
	visible_message(span_notice("[src] sits down to rest."), span_notice("You sit down to rest."))
	
	// Simple rest action
	if(isliving(src))
		var/mob/living/L = src
		L.resting = !L.resting
		L.update_icons()	

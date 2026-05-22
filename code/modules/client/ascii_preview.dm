/proc/generate_ascii_preview(datum/preferences/prefs)
	if(!prefs)
		return get_default_ascii()
	
	var/list/lines = list()
	
	// Hair style affects top of head
	var/hair_top = ""
	var/hair_mid = ""
	if(prefs.hair_style && prefs.hair_style != "Bald")
		hair_top = "  ~~~~~~~  "
		hair_mid = " {~~~~~~~} "
	else
		hair_top = "  .......  "
		hair_mid = " /.......\\ "
	
	lines += "   [hair_top]   "
	lines += "  [hair_mid]  "
	
	// Eyes
	var/eye_style = get_eye_style(prefs)
	lines += " |  [eye_style]  | "
	
	// Nose and mouth
	var/mouth = prefs.gender == MALE ? "{" : "("
	lines += " |   ..    | "
	lines += " |  [mouth]__| "
	
	// Body
	lines += "  \\_______/  "
	lines += "    |   |    "
	
	// Arms and torso
	var/cloth_style = get_cloth_style(prefs)
	lines += "   /[cloth_style]\\   "
	lines += "  / |   | \\  "
	lines += " |  |---|  | "
	
	// Legs
	lines += "    |   |    "
	lines += "   /|   |\\   "
	lines += "  / |   | \\  "
	lines += " /__|   |__\\ "
	
	return jointext(lines, "\n")

/proc/get_eye_style(datum/preferences/prefs)
	// Different eye styles based on eye type or other factors
	if(prefs.eye_type == "robotic")
		return "[0][0]"
	if(prefs.eye_type == "glowing")
		return "**"
	
	// Standard eyes
	if(prefs.split_eye_colors)
		return "@@" // Heterochromia indicator
	return "oo"

/proc/get_cloth_style(datum/preferences/prefs)
	// Different torso styles based on job preference or background
	if(prefs.background == "brotherhood_outcast")
		return "###"
	if(prefs.background == "vault_dweller")
		return "==="
	if(prefs.background == "tribal")
		return "~~~"
	return "###"

/proc/get_default_ascii()
	var/list/lines = list()
	lines += "   .......   "
	lines += "  /.......\\  "
	lines += " |  o   o  | "
	lines += " |    .    | "
	lines += " |   ___   | "
	lines += "  \\_______/  "
	lines += "    |   |    "
	lines += "   /###\\   "
	lines += "  / |   | \\  "
	lines += " |  |---|  | "
	lines += "    |   |    "
	lines += "   /|   |\\   "
	lines += "  / |   | \\  "
	lines += " /__|   |__\\ "
	return jointext(lines, "\n")

// Extended ASCII preview with equipment
/proc/generate_ascii_preview_equipped(datum/preferences/prefs)
	if(!prefs)
		return get_default_ascii()
	
	var/list/lines = list()
	
	// Head with potential headwear
	var/hat_line = "   .-----."
	if(prefs.backbag == 2) // Example: backpack indicator
		hat_line = "   .~~~~~."
	
	lines += hat_line
	lines += "  /.......\\  "
	lines += " |  o   o  | "
	lines += " |    .    | "
	lines += " |   ___   | "
	lines += "  \\_______/  "
	
	// Body with equipment indicators
	lines += "    |$$$|    " // Torso with armor
	lines += "   /$$$$$\\   "
	lines += "  / |   | \\  "
	lines += " |  |---|  | "
	lines += "    |   |    "
	
	// Legs
	lines += "   /|   |\\   "
	lines += "  / |   | \\  "
	lines += " /__|   |__\\ "
	
	return jointext(lines, "\n")

// ASCII art for backgrounds
/proc/get_background_ascii(background_id)
	switch(background_id)
		if("vault_dweller")
			return list(
				"    ___     ",
				"   /   \\    ",
				"  | V | |   ",
				"   \\___/    ",
			)
		if("wastelander")
			return list(
				"   \\   /    ",
				"    \\_/     ",
				"    / \\     ",
				"   /   \\    ",
			)
		if("tribal")
			return list(
				"   <>----<>   ",
				"   |    |   ",
				"   <>----<>   ",
				"            ",
			)
		if("brotherhood_outcast")
			return list(
				"  _______   ",
				" |  BOS  |  ",
				" |$$$$$$$|  ",
				" |_______|  ",
			)
		if("ghoul_prewar")
			return list(
				"   .......  ",
				"  /:.....:\\ ",
				" |  o   o  |",
				"  \\_______/ ",
			)
		if("raider")
			return list(
				"  .~~~~~~.  ",
				" | X   X | ",
				"  `~~~~~~`  ",
				"            ",
			)
		if("enclave_remnant")
			return list(
				"   +---+   ",
				"   | E |   ",
				"   +---+   ",
				"            ",
			)
		if("mercenary")
			return list(
				"   .---.   ",
				"   | $ |   ",
				"   `---'   ",
				"            ",
			)
		else
			return list(
				"   ......   ",
				"  .      .  ",
				"  .      .  ",
				"   ......   ",
			)

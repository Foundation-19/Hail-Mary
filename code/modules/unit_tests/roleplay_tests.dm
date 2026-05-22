// Unit Tests for Roleplay Systems
// Tests karma, reputation, quests, and trade functionality

/datum/unit_test/karma_thresholds

/datum/unit_test/karma_thresholds/Run()
	// Test karma clamping
	var/test_karma = 1500
	var/clamped = clamp(test_karma, KARMA_MIN, KARMA_MAX)
	if(clamped > KARMA_MAX)
		Fail("Karma not properly clamped to KARMA_MAX (1000)")
	if(clamped < KARMA_MIN)
		Fail("Karma not properly clamped to KARMA_MIN (-1000)")
	

/datum/unit_test/karma_action_amounts

/datum/unit_test/karma_action_amounts/Run()
	// Test that karma actions return expected amounts
	var/good_action = get_action_karma_amount("save_life")
	if(good_action <= 0)
		Fail("save_life should give positive karma")
	
	var/bad_action = get_action_karma_amount("kill_civilian")
	if(bad_action >= 0)
		Fail("kill_civilian should give negative karma")
	
	var/neutral_action = get_action_karma_amount("nonexistent_action")
	if(neutral_action != 0)
		Fail("Nonexistent action should return 0 karma")

/datum/unit_test/faction_definitions

/datum/unit_test/faction_definitions/Run()
	// Test that factions exist
	if(!GLOB.factions)
		Fail("GLOB.factions not initialized")
	
	var/list/expected_factions = list("ncr", "legion", "bos", "enclave")
	for(var/faction_id in expected_factions)
		if(!GLOB.factions[faction_id])
			Fail("Missing expected faction: [faction_id]")
	
	// Test faction has ranks
	var/datum/faction/ncr_faction = GLOB.factions["ncr"]
	if(!ncr_faction)
		Fail("NCR faction not found")
	if(!ncr_faction.ranks || !ncr_faction.ranks.len)
		Fail("NCR faction should have ranks defined")

/datum/unit_test/quest_creation

/datum/unit_test/quest_creation/Run()
	// Test quest datum creation
	var/datum/quest/test_quest = new()
	if(!test_quest)
		Fail("Failed to create quest datum")
	
	test_quest.id = "test_quest"
	test_quest.name = "Test Quest"
	test_quest.description = "A test quest"
	test_quest.objective = "Complete the test"
	
	if(test_quest.id != "test_quest")
		Fail("Quest id not set correctly")
	if(test_quest.completed)
		Fail("Quest should not be completed on creation")
	
	qdel(test_quest)

/datum/unit_test/background_definitions

/datum/unit_test/background_definitions/Run()
	// Test backgrounds exist
	if(!GLOB.character_backgrounds)
		Fail("GLOB.character_backgrounds not initialized")
	
	var/list/expected_backgrounds = list("vault_dweller", "wastelander", "tribal", "raider")
	for(var/bg_id in expected_backgrounds)
		if(!GLOB.character_backgrounds[bg_id])
			Fail("Missing expected background: [bg_id]")
	
	// Test background has required vars
	var/datum/background/vault_bg = GLOB.character_backgrounds["vault_dweller"]
	if(!vault_bg)
		Fail("Vault Dweller background not found")
	if(!vault_bg.name)
		Fail("Background should have a name")
	if(!vault_bg.description)
		Fail("Background should have a description")

/datum/unit_test/xp_calculation

/datum/unit_test/xp_calculation/Run()
	// Test XP values are reasonable
	var/xp_raider = get_xp_for_action("kill_raider")
	if(xp_raider <= 0)
		Fail("kill_raider should give positive XP")
	
	var/xp_boss = get_xp_for_action("kill_boss")
	if(xp_boss <= xp_raider)
		Fail("kill_boss should give more XP than kill_raider")
	
	var/xp_player = get_xp_for_action("kill_player")
	// kill_player gives negative XP (discourages RDM)
	if(xp_player >= 0)
		Fail("kill_player should give negative XP to discourage random deathmatch")
	
	// Test nonexistent action
	var/xp_invalid = get_xp_for_action("totally_fake_action")
	if(xp_invalid != 0)
		Fail("Invalid action should return 0 XP")

// ============ NULL SAFETY TESTS ============

/datum/unit_test/null_safety_karma

/datum/unit_test/null_safety_karma/Run()
	// Test null ckey handling
	var/null_karma = get_karma(null)
	if(null_karma != 0)
		Fail("get_karma(null) should return 0")
	
	var/null_set = set_karma(null, 100)
	if(null_set != FALSE)
		Fail("set_karma(null, ...) should return FALSE")
	
	var/null_adjust = adjust_karma(null, 10)
	if(null_adjust != 0)
		Fail("adjust_karma(null, ...) should return 0")

/datum/unit_test/null_safety_reputation

/datum/unit_test/null_safety_reputation/Run()
	// Test null ckey handling
	var/null_rep = get_faction_reputation(null, "ncr")
	if(null_rep != 0)
		Fail("get_faction_reputation(null, ...) should return 0")
	
	var/null_rep2 = get_faction_reputation("test", null)
	if(null_rep2 != 0)
		Fail("get_faction_reputation(..., null) should return 0")
	
	var/null_set = set_faction_reputation(null, "ncr", 50)
	if(null_set != FALSE)
		Fail("set_faction_reputation(null, ...) should return FALSE")

/datum/unit_test/null_safety_quests

/datum/unit_test/null_safety_quests/Run()
	// Test quest data retrieval
	var/valid_quest = get_quest_data("ncr_raiders")
	if(!valid_quest)
		Fail("ncr_raiders quest should exist")
	
	var/invalid_quest = get_quest_data("nonexistent_quest")
	if(invalid_quest)
		Fail("Nonexistent quest should return null")
	
	// Test time formatting with edge cases
	var/negative_time = format_time_remaining(-100)
	if(negative_time != "No time limit")
		Fail("Negative time should return 'No time limit'")
	
	var/zero_time = format_time_remaining(0)
	if(zero_time != "Expired")
		Fail("Zero time should return 'Expired'")

/datum/unit_test/level_system_edge_cases

/datum/unit_test/level_system_edge_cases/Run()
	// Test XP calculations with edge cases
	var/null_xp = get_player_xp(null)
	if(null_xp != 0)
		Fail("get_player_xp(null) should return 0")
	
	var/null_level = get_player_level(null)
	if(null_level != 1)
		Fail("get_player_level(null) should return 1")
	
	// Test XP required calculations
	var/neg_level = get_xp_required_for_level(-5)
	if(neg_level != 0)
		Fail("Negative level should return 0 XP required")
	
	var/zero_level = get_xp_required_for_level(0)
	if(zero_level != 0)
		Fail("Level 0 should return 0 XP required")
	
	var/level_1 = get_xp_required_for_level(1)
	if(level_1 != XP_LEVEL_SCALING)
		Fail("Level 1 should require XP_LEVEL_SCALING XP")
	
	// Test total XP calculations
	var/neg_total = get_total_xp_for_level(-5)
	if(neg_total != 0)
		Fail("Negative level total should return 0")
	
	var/zero_total = get_total_xp_for_level(0)
	if(zero_total != 0)
		Fail("Level 0 total should return 0")

// ============ DIALOGUE SYSTEM TESTS ============

/datum/unit_test/dialogue_tree_tests

/datum/unit_test/dialogue_tree_tests/Run()
	// Test dialogue initialization
	init_dialogue_system()
	
	if(!GLOB.dialogue_trees || !GLOB.dialogue_trees.len)
		Fail("Dialogue trees should be initialized")
	
	// Test expected dialogue trees exist
	var/list/expected_trees = list("ncr", "legion", "bos", "trader", "generic", "enclave", "vault", "bighorn")
	for(var/tree_id in expected_trees)
		if(!GLOB.dialogue_trees[tree_id])
			Fail("Missing expected dialogue tree: [tree_id]")
	
	// Test dialogue node format (DM style has nodes at top level)
	var/list/ncr_tree = GLOB.dialogue_trees["ncr"]
	if(!ncr_tree)
		Fail("NCR dialogue tree should exist")
	if(!ncr_tree["start"])
		Fail("NCR dialogue tree should have 'start' node")

/datum/unit_test/karma_title_tests

/datum/unit_test/karma_title_tests/Run()
	// Test karma titles
	if(get_karma_title(800) != "Legendary Hero")
		Fail("800 karma should be 'Legendary Hero'")
	if(get_karma_title(600) != "Hero")
		Fail("600 karma should be 'Hero'")
	if(get_karma_title(300) != "Good")
		Fail("300 karma should be 'Good'")
	if(get_karma_title(50) != "Neutral")
		Fail("50 karma should be 'Neutral'")
	if(get_karma_title(-100) != "Wanderer")
		Fail("-100 karma should be 'Wanderer'")
	if(get_karma_title(-400) != "Shady")
		Fail("-400 karma should be 'Shady'")
	if(get_karma_title(-600) != "Villain")
		Fail("-600 karma should be 'Villain'")
	if(get_karma_title(-900) != "Infamous")
		Fail("-900 karma should be 'Infamous'")

/datum/unit_test/faction_rank_tests

/datum/unit_test/faction_rank_tests/Run()
	// Test faction rank retrieval
	var/rank_idolized = get_faction_rank("ncr", 100)
	if(rank_idolized != "Idolized")
		Fail("100 rep should be 'Idolized', got '[rank_idolized]'")
	
	var/rank_neutral = get_faction_rank("ncr", 10)
	if(rank_neutral != "Neutral")
		Fail("10 rep should be 'Neutral', got '[rank_neutral]'")
	
	var/rank_vilified = get_faction_rank("ncr", -100)
	if(rank_vilified != "Vilified")
		Fail("-100 rep should be 'Vilified', got '[rank_vilified]'")
	
	// Test invalid faction
	var/rank_invalid = get_faction_rank("nonexistent_faction", 50)
	if(rank_invalid != "Unknown")
		Fail("Invalid faction should return 'Unknown'")

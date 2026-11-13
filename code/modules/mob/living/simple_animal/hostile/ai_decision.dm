// Hostile mob decision layer (Hostile AI redesign, phase 4).
// While a mob has a visible target it scores a handful of intents (attack, flank, hold, retreat, call backup) from
// health, morale, allies and threats, and commits to the winner for a short window so it doesn't dither between
// them every tick. Heavy damage or a changed target breaks the commit. Morale is a 0..1 value that falls on damage,
// ally deaths, near misses and being outnumbered, rises on landed hits and regrouping, and recovers with time.
// Each mob also rolls a small personality (aggression, risk tolerance, patience, curiosity) around its type's
// defaults. The existing movement and attack code still does the actual walking and shooting; the intent only
// chooses which of those paths runs.

#define AI_INTENT_NONE 0
#define AI_INTENT_ATTACK 1
#define AI_INTENT_FLANK 2
#define AI_INTENT_HOLD 3
#define AI_INTENT_RETREAT 4
#define AI_INTENT_BACKUP 5
#define AI_INTENT_INVESTIGATE 6

/// Kiting modes recorded by note_retreat_step()
#define RETREAT_MOVE_AWAY 1
#define RETREAT_MOVE_CLOSE 2

/// A chosen intent is kept for a random time in this range (deciseconds) before it is re-scored
#define AI_COMMIT_MIN 5
#define AI_COMMIT_MAX 10
/// Score bonus the current intent gets when the commit expires, so near-ties don't flip
#define AI_INTENT_STICKINESS 0.12
/// Damage taken during a commit, as a fraction of max health, that breaks it
#define AI_INTERRUPT_DAMAGE 0.2

#define AI_MORALE_REGEN 0.002 // per decisecond
#define AI_MORALE_DAMAGE_FACTOR 1.2
#define AI_MORALE_ALLY_DEATH 0.15
#define AI_MORALE_NEAR_MISS 0.03
#define AI_MORALE_HIT_LANDED 0.04
#define AI_MORALE_OUTNUMBERED 0.03
#define AI_MORALE_REGROUP 0.25
#define AI_MORALE_CALLED_BACKUP 0.1

/// Radius used to count allies around the mob
#define AI_ALLY_RADIUS 7
/// A target acquired after this long without one counts as a new threat and earns a moment of hesitation
#define AI_FRESH_THREAT_GAP 100
#define AI_HESITATE_MIN 5
#define AI_HESITATE_MAX 12
/// Per-spawn personality values are 1 +/- this much
#define AI_PERSONALITY_SPREAD 0.2

/// A freshly acquired target is kept at least this long unless it leaves the target list
#define AI_TARGET_LOCK 15
/// This many target switches inside the window count as flicker, the gate metric for this phase
#define AI_FLICKER_WINDOW 50
#define AI_FLICKER_LIMIT 3

// Phase 6a: fast learning (see ai_doctrine.dm)
/// Intents a doctrine learns weights for: attack, flank, hold, retreat, backup
#define AI_LEARN_INTENTS 5
#define AI_CTX_SOLO 1
#define AI_CTX_PACK 2
#define AI_CTX_COUNT 2
/// Segments scored before an intent's value counts toward its weight
#define AI_DOCTRINE_MIN_SAMPLES 5
/// How far learning can move a utility weight from 1, up or down
#define AI_DOCTRINE_MAX_SHIFT 0.25
/// Weight change per point of reward above the average intent
#define AI_DOCTRINE_GAIN 0.5
/// Share of each new result folded into the running value
#define AI_DOCTRINE_RATE 0.2
/// Each update fades the value slightly, so old results lose weight
#define AI_DOCTRINE_DECAY 0.01
/// Percent chance per decision to try a near-tied intent instead of the best one
#define AI_EXPLORE_PERCENT 5
/// An explored intent must score within this much of the best
#define AI_EXPLORE_MARGIN 0.2
/// Segments shorter than this many seconds say too little to score
#define AI_LEARN_MIN_SEGMENT 3
#define AI_REWARD_HIT 0.6
/// Landed hits beyond this stop adding reward, so mobs are not trained into finishing fights as fast as possible
#define AI_REWARD_HIT_CAP 6
#define AI_REWARD_DAMAGE 1
#define AI_REWARD_ALLY_LOSS 0.15
#define AI_REWARD_ALLY_LOSS_CAP 3
#define AI_REWARD_DEATH 0.5
/// A segment with no hits dealt or taken costs this much per second, up to the cap
#define AI_REWARD_STALL_RATE 0.02
#define AI_REWARD_STALL_CAP 0.2

// Phase 6c behavior library (ai_behaviors.dm)
#define AI_BHV_DOOR 1
#define AI_BHV_CORNER 2
#define AI_BHV_KITE 3
#define AI_BHV_HEAL 4
#define AI_BHV_CAMP 5
#define AI_BHV_COUNT 5
#define AI_BHV_FLAG(b) (1 << ((b) - 1))
// The numbers below can be changed while the game runs from the AI Doctrine admin verb (see ai_behaviors.dm)
#define AI_BHV_TUNE(key) (GLOB.ai_bhv_tuning[key])
/// A counter switches on above this score and off below the lower one, so it does not flicker
#define AI_BHV_ON AI_BHV_TUNE("on")
#define AI_BHV_OFF AI_BHV_TUNE("off")
#define AI_BHV_EVIDENCE AI_BHV_TUNE("evidence")
/// Deciseconds for a score to halve
#define AI_BHV_HALFLIFE AI_BHV_TUNE("halflife")
/// Least time between two pieces of evidence for the same behavior, so one move is not counted twice
#define AI_BHV_EVENT_GAP AI_BHV_TUNE("event_gap")
/// Door passes and peeks only count as repeats within this window
#define AI_BHV_WINDOW AI_BHV_TUNE("window")
/// The most a counter can move any one intent's utility
#define AI_BHV_MAX_MOD AI_BHV_TUNE("max_mod")
/// What hold is worth when a counter asks for it and nothing else did
#define AI_BHV_HOLD_BASE AI_BHV_TUNE("hold_base")
/// Multiplier on every counter's changes
#define AI_BHV_STRENGTH AI_BHV_TUNE("strength")
/// A counter that is still in the place it was needed fades at AI_BHV_SUSTAIN_FADE of the normal rate, for up to
/// AI_BHV_SUSTAIN_TIME after the last evidence. Once the counter works the trick stops, so without this the counter
/// would drop out in the middle of the fight it is winning.
#define AI_BHV_SUSTAIN_TIME AI_BHV_TUNE("sustain_time")
#define AI_BHV_SUSTAIN_FADE AI_BHV_TUNE("sustain_fade")
/// Room camping: this many allies lost near a target that has not moved, and how long the target must hold still
#define AI_BHV_CAMP_DEATHS AI_BHV_TUNE("camp_deaths")
#define AI_BHV_CAMP_STILL AI_BHV_TUNE("camp_still")
#define AI_BHV_CAMP_WINDOW AI_BHV_TUNE("camp_window")
/// Fighters (the mob and the allies near it) needed before a camper is rushed, and the longest a mob waits for them
#define AI_BHV_CAMP_MASS AI_BHV_TUNE("camp_mass")
#define AI_BHV_CAMP_PATIENCE AI_BHV_TUNE("camp_patience")
/// How many search leads past the last known position a mob follows along the target's heading
#define AI_BHV_LEAD_HOPS AI_BHV_TUNE("lead_hops")
/// How much longer a mob remembers a target that heals up during fights
#define AI_BHV_MEMORY_SCALE AI_BHV_TUNE("memory_scale")
/// Target moves of no more than this many tiles from the anchor count as holding still
#define AI_BHV_CAMP_ROAM 3
/// Allied deaths count when they lie this near the target, and when they are no further than AI_BHV_CAMP_SIGHT from us
#define AI_BHV_CAMP_RANGE 9
#define AI_BHV_CAMP_SIGHT 14
#define AI_BHV_DEATH_LOG_MAX 24
/// Search lead: how far one lead runs, the least that is worth walking, and how old the heading may be
#define AI_BHV_LEAD_STEPS 7
#define AI_BHV_LEAD_MIN 4
#define AI_BHV_LEAD_FRESH 300
/// Confidence of a search lead (about the same as a fresh sighting, defined here because ai_memory.dm comes later)
#define AI_BHV_LEAD_CONF 0.9
/// Cover bounding: tiles scanned around the mob, the range inside which it just rushes, pause under cover, repick time
#define AI_BHV_COVER_SCAN 4
#define AI_BHV_COVER_RUSH 3
#define AI_BHV_COVER_PAUSE 8
#define AI_BHV_COVER_REPICK 40

GLOBAL_VAR_INIT(ai_target_switches, 0)
GLOBAL_VAR_INIT(ai_target_flickers, 0)
GLOBAL_LIST_INIT(ai_intent_names, list("attack", "flank", "hold", "retreat", "backup", "investigate"))

/mob/living/simple_animal/hostile
	/// Set to FALSE to bypass the decision layer entirely (the mob behaves as before phase 4)
	var/ai_decision_enabled = TRUE
	/// Whether this mob may fall back toward allies or away from the target. Null means only ranged or kiting mobs may.
	var/ai_can_retreat
	var/ai_intent = AI_INTENT_NONE
	var/ai_intent_until = 0
	var/datum/weakref/ai_intent_target
	/// Set when an intent is committed, cleared once its one-shot actions have run
	var/ai_intent_fresh = FALSE
	var/ai_commit_damage = 0
	var/turf/ai_flank_tile
	var/turf/ai_retreat_goal
	var/ai_morale = 1
	var/ai_morale_stamp = 0
	var/ai_hesitate_until = 0
	var/ai_near_miss_next = 0
	var/ai_target_lock_until = 0
	var/list/ai_switch_times
	var/ai_aggression = 1
	var/ai_risk_tolerance = 1
	var/ai_patience = 1
	var/ai_curiosity = 1

/// Triangular roll in 1 +/- AI_PERSONALITY_SPREAD, so most mobs sit near their type's defaults
/mob/living/simple_animal/hostile/proc/roll_personality_value()
	return 1 + (rand() + rand() - 1) * AI_PERSONALITY_SPREAD

/mob/living/simple_animal/hostile/proc/roll_ai_personality()
	if(ckey || !ai_decision_enabled)
		return
	ai_aggression = roll_personality_value()
	ai_risk_tolerance = roll_personality_value()
	ai_patience = roll_personality_value()
	ai_curiosity = roll_personality_value()
	if(lose_patience_timeout)
		lose_patience_timeout = max(round(lose_patience_timeout * ai_patience), 50)
	curiosity_chance = CLAMP(round(curiosity_chance * ai_curiosity), 0, 100)

/mob/living/simple_animal/hostile/proc/get_ai_morale()
	if(ai_morale < 1)
		ai_morale = min(1, ai_morale + (world.time - ai_morale_stamp) * AI_MORALE_REGEN)
	ai_morale_stamp = world.time
	return ai_morale

/mob/living/simple_animal/hostile/proc/adjust_ai_morale(amount, reason)
	if(ckey || !ai_decision_enabled || !amount)
		return
	if(amount < 0)
		amount /= ai_risk_tolerance
	var/before = get_ai_morale()
	ai_morale = CLAMP(before + amount, 0, 1)
	if(ai_morale != before)
		ai_debug_log("morale_change reason=[reason] [round(before, 0.01)]->[round(ai_morale, 0.01)]")

/mob/living/simple_animal/hostile/proc/ai_note_damage(amount)
	if(ckey || stat == DEAD || !ai_decision_enabled)
		return
	ai_commit_damage += amount
	ai_seg_taken += amount
	ai_bhv_hurt_time = world.time
	ai_hesitate_until = 0
	if(maxHealth > 0)
		adjust_ai_morale(-CLAMP(amount / maxHealth, 0, 1) * AI_MORALE_DAMAGE_FACTOR, "damage")

/mob/living/simple_animal/hostile/proc/ai_note_hit_landed()
	ai_seg_hits++
	adjust_ai_morale(AI_MORALE_HIT_LANDED, "hit_landed")

/// An enemy projectile landed within a couple of tiles of us without hitting
/mob/living/simple_animal/hostile/proc/ai_note_near_miss(atom/source)
	if(world.time < ai_near_miss_next || !isliving(source) || source == src)
		return
	var/mob/living/L = source
	if(faction_check_mob(L))
		return
	ai_near_miss_next = world.time + 10
	adjust_ai_morale(-AI_MORALE_NEAR_MISS, "near_miss")

/// Called from GiveTarget once a target has been set. Holds the target against flip-flopping, tracks flicker for
/// the phase gate, and gives a freshly spotted threat a short beat before the mob commits to moving.
/mob/living/simple_animal/hostile/proc/ai_on_target_acquired(atom/old_target, fresh_threat)
	if(ckey || !ai_decision_enabled)
		return
	if(old_target == target)
		return
	ai_target_lock_until = world.time + AI_TARGET_LOCK
	if(old_target)
		ai_note_target_switch(old_target)
		ai_close_segment("target_switch")
		ai_bhv_reset()
	if(fresh_threat)
		ai_note_engagement()
		ai_hesitate_until = world.time + round(rand(AI_HESITATE_MIN, AI_HESITATE_MAX) / ai_aggression)

/mob/living/simple_animal/hostile/proc/ai_note_target_switch(atom/old_target)
	GLOB.ai_target_switches++
	ai_debug_log("target_switch from=[old_target] to=[target]")
	LAZYADD(ai_switch_times, world.time)
	while(length(ai_switch_times) && ai_switch_times[1] < world.time - AI_FLICKER_WINDOW)
		ai_switch_times.Cut(1, 2)
	if(length(ai_switch_times) >= AI_FLICKER_LIMIT)
		GLOB.ai_target_flickers++
		ai_debug_log("target_flicker switches=[length(ai_switch_times)] window=[AI_FLICKER_WINDOW / 10]s global=[GLOB.ai_target_flickers]/[GLOB.ai_target_switches]")
		ai_switch_times = null

/mob/living/simple_animal/hostile/proc/ai_break_commit(reason)
	ai_debug_log("intent_interrupt intent=[GLOB.ai_intent_names[ai_intent]] reason=[reason]")
	ai_intent_until = 0

/mob/living/simple_animal/hostile/proc/ai_commit_intent(intent, reason, duration, learn = TRUE)
	if(intent != ai_intent || ai_seg_intent == AI_INTENT_NONE)
		if(intent != ai_intent)
			ai_debug_log("intent_chosen intent=[GLOB.ai_intent_names[intent]] was=[ai_intent ? GLOB.ai_intent_names[ai_intent] : "none"] [reason]")
		if(intent != ai_seg_intent)
			ai_close_segment("intent_change")
			ai_open_segment(intent, learn)
	if(!learn)
		ai_seg_learn = FALSE
	ai_intent = intent
	ai_intent_target = target ? WEAKREF(target) : null
	ai_intent_until = world.time + (duration || rand(AI_COMMIT_MIN, AI_COMMIT_MAX))
	ai_intent_fresh = TRUE
	ai_commit_damage = 0

/// Records the intent for a mob that has no line of sight and is running down the last known position
/mob/living/simple_animal/hostile/proc/ai_note_investigating()
	if(!ai_bhv_los_lost)
		ai_bhv_los_lost = world.time
	if(ai_intent != AI_INTENT_INVESTIGATE)
		ai_commit_intent(AI_INTENT_INVESTIGATE, "no_los")

/// Mixed mobs inside this many tiles of their target are in the fight and stay in it
#define AI_MIXED_ENGAGE_RANGE 4

/// Picks what a mob with a visible target does this moment. Returns the committed intent while its window is open.
/mob/living/simple_animal/hostile/proc/ai_decide_intent(target_distance)
	if(!ai_decision_enabled || ckey || !target)
		return AI_INTENT_ATTACK

	// A mixed mob is built to finish the job in melee once someone is on top of it. Falling back, holding or calling
	// backup while a player rushes it just hands over free hits and makes it dither between shooting and swinging,
	// so a stale commit is dropped and it attacks.
	if(combat_mode == COMBAT_MODE_MIXED && target_distance <= AI_MIXED_ENGAGE_RANGE)
		if(ai_intent != AI_INTENT_ATTACK || world.time >= ai_intent_until || RESOLVEWEAKREF(ai_intent_target) != target)
			ai_commit_intent(AI_INTENT_ATTACK, "mixed_engaged dist=[target_distance]", learn = FALSE)
		return AI_INTENT_ATTACK

	if(ai_intent != AI_INTENT_NONE && world.time < ai_intent_until)
		if(RESOLVEWEAKREF(ai_intent_target) != target)
			ai_break_commit("target_changed")
		else if(maxHealth > 0 && ai_commit_damage >= maxHealth * AI_INTERRUPT_DAMAGE)
			ai_break_commit("heavy_damage")
		else if(!ranged && target_distance <= 2 && (ai_intent == AI_INTENT_HOLD || ai_intent == AI_INTENT_FLANK))
			// A melee mob standing still or circling while the target is already on top of it just freezes
			ai_break_commit("target_close")
		else
			return ai_intent

	if(world.time < ai_hesitate_until && target_distance > 2)
		ai_commit_intent(AI_INTENT_HOLD, "hesitate", ai_hesitate_until - world.time, FALSE)
		return AI_INTENT_HOLD

	var/hp = maxHealth > 0 ? CLAMP(health / maxHealth, 0, 1) : 1
	var/morale = get_ai_morale()

	var/allies_near = 0
	var/allies_on_target = 0
	var/allies_idle = 0
	var/closest_ally_dist = INFINITY
	var/datum/ai_squad/nearby_squad
	ai_retreat_goal = null
	for(var/mob/living/simple_animal/hostile/M in range(AI_ALLY_RADIUS, src))
		if(M == src || M.stat == DEAD || M.ckey || !faction_check_mob(M, TRUE))
			continue
		allies_near++
		if(M.ai_squad && (!nearby_squad || length(M.ai_squad.members) > length(nearby_squad.members)))
			nearby_squad = M.ai_squad
		if(M.target == target)
			allies_on_target++
		else if(!M.target && !M.searching)
			allies_idle++
		var/ally_dist = get_dist(src, M)
		if(ally_dist < closest_ally_dist)
			closest_ally_dist = ally_dist
			ai_retreat_goal = get_turf(M)

	var/threats = 0
	for(var/mob/living/L in GetCachedTargets())
		if(L.stat == CONSCIOUS)
			threats++
	threats = max(threats, 1)
	// A mob that has wandered away from its pack stops counting toward the pack's flank slots and blackboard
	if(ai_squad && !allies_near && length(ai_squad.members) > 1)
		ai_squad_leave()
	ai_squad_sync(nearby_squad)
	var/datum/ai_squad/squad = ai_squad
	var/outnumbered = CLAMP(threats - allies_near - 1, 0, 3)
	if(outnumbered)
		adjust_ai_morale(-AI_MORALE_OUTNUMBERED * outnumbered, "outnumbered")
		morale = get_ai_morale()

	var/attack = 0.55 * ai_aggression + 0.25 * morale + 0.2 * hp - 0.1 * outnumbered

	var/can_retreat = isnull(ai_can_retreat) ? (ranged || retreat_distance != null) : ai_can_retreat
	var/retreat = 0
	if(can_retreat && (ai_retreat_goal || retreat_distance != null) && world.time >= retreat_hold_until)
		retreat = ((1 - morale) * 1.1 + (1 - hp) * 0.5) / ai_risk_tolerance

	var/hold = 0
	var/suppressing = FALSE
	if(outnumbered && !ranged && target_distance >= 3)
		hold = 0.35 + 0.5 * (1 - morale)

	var/flank = 0
	ai_flank_tile = null
	if(!ranged && target_distance >= 3 && target_distance <= 10 && allies_on_target && squad)
		var/turf/flank_tile = find_open_flank(target, squad)
		if(flank_tile && squad.can_flank(src, target, flank_tile))
			ai_flank_tile = flank_tile
			flank = 1 + 0.05 * min(allies_on_target, 3)

	// Ranged mobs suppress while a squadmate works around the side: they stay put and keep the target pinned instead
	// of kiting off, so the flank lands on a target that is busy facing them. Needs a clear shot and some nerve.
	if(ranged && squad && target_distance >= 2 && squad.flank_active(target, src))
		var/turf/shot_from = get_turf(src)
		var/turf/shot_to = get_turf(target)
		if(shot_from && shot_to && shot_is_clear(shot_from, shot_to))
			hold = max(hold, 0.6 + 0.5 * morale)
			suppressing = TRUE

	var/backup = 0
	if(allies_idle && COOLDOWN_FINISHED(src, backup_call_cooldown))
		backup = 0.35 + 0.5 * (1 - hp) + 0.3 * (1 - morale) + (outnumbered ? 0.15 : 0)

	var/list/intents = list(AI_INTENT_ATTACK, AI_INTENT_FLANK, AI_INTENT_HOLD, AI_INTENT_RETREAT, AI_INTENT_BACKUP)
	var/list/utility = list(attack, flank, hold, retreat, backup)

	// What the type has learned works scales each intent's score. The context keeps lone fights and pack fights apart.
	ai_decision_ctx = allies_near >= 2 ? AI_CTX_PACK : AI_CTX_SOLO
	var/datum/ai_doctrine/doctrine = ai_learning_active() ? get_ai_doctrine() : null
	if(doctrine)
		for(var/i in 1 to AI_LEARN_INTENTS)
			utility[i] *= doctrine.get_weight(ai_decision_ctx, intents[i])
	ai_apply_behavior_counters(intents, utility, target_distance, doctrine, allies_near)

	var/chosen = AI_INTENT_ATTACK
	var/best = -INFINITY
	var/best_raw = -INFINITY
	for(var/i in 1 to intents.len)
		var/u = utility[i] + (intents[i] == ai_intent ? AI_INTENT_STICKINESS : 0)
		if(u > best)
			best = u
			best_raw = utility[i]
			chosen = intents[i]

	// Now and then try an intent that nearly tied for best, so a weight that drifted down can recover
	if(doctrine && !GLOB.ai_learning_frozen && prob(AI_EXPLORE_PERCENT))
		var/list/near = list()
		for(var/i in 1 to intents.len)
			if(intents[i] != chosen && utility[i] > 0 && best_raw - utility[i] <= AI_EXPLORE_MARGIN)
				near += intents[i]
		if(length(near))
			chosen = pick(near)
			ai_debug_log("doctrine_explore intent=[GLOB.ai_intent_names[chosen]]")

	if(chosen == AI_INTENT_FLANK)
		if(!squad.claim_flank(src, target, ai_flank_tile))
			chosen = AI_INTENT_ATTACK
	else
		squad?.release_flank(src, "not_chosen")
	if(chosen == AI_INTENT_HOLD && suppressing)
		ai_debug_log("squad_suppress target=[target] dist=[target_distance]")

	if(chosen == AI_INTENT_RETREAT && ai_intent != AI_INTENT_RETREAT)
		squad?.note_fallback(src)

	ai_commit_intent(chosen, "atk=[round(attack, 0.01)] flank=[round(flank, 0.01)] hold=[round(hold, 0.01)] retreat=[round(retreat, 0.01)] backup=[round(backup, 0.01)] morale=[round(morale, 0.01)] hp=[round(hp, 0.01)] allies=[allies_near] threats=[threats]")
	return chosen

/// Carries out the movement half of an intent. Returns TRUE if it issued movement, so the default movement is skipped.
/mob/living/simple_animal/hostile/proc/ai_run_intent_movement(intent)
	var/fresh = ai_intent_fresh
	ai_intent_fresh = FALSE
	if(!target)
		return FALSE
	switch(intent)
		if(AI_INTENT_ATTACK)
			// A kiter is closed on from cover to cover, not across open ground
			if((ai_bhv_applied & AI_BHV_FLAG(AI_BHV_KITE)) && ai_cover_advance())
				return TRUE
			return FALSE
		if(AI_INTENT_HOLD)
			// A camper is waited out of its sight until the squad has gathered
			if(ai_bhv_camp_waiting && ai_break_line_of_sight())
				return TRUE
			walk(src, 0)
			var/hold_dir = get_dir(src, target)
			if(hold_dir)
				setDir(hold_dir)
			return TRUE
		if(AI_INTENT_FLANK)
			if(!ai_flank_tile)
				return FALSE
			if(get_dist(src, ai_flank_tile) <= 1)
				ai_squad?.complete_flank(src)
				return FALSE
			Goto(ai_flank_tile, move_to_delay, 0)
			return TRUE
		if(AI_INTENT_BACKUP)
			if(fresh)
				call_for_backup(target, "found")
				adjust_ai_morale(AI_MORALE_CALLED_BACKUP, "called_backup")
				ai_intent_until = world.time
			return FALSE
		if(AI_INTENT_RETREAT)
			if(world.time < retreat_hold_until || !CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
				return FALSE
			if(fresh)
				visible_message(span_warning("[src] falters and falls back!"))
				call_for_backup(target, "found")
			// Against a kiter the way back is out of its line of fire, not toward the pack
			if((ai_bhv_applied & AI_BHV_FLAG(AI_BHV_KITE)) && ai_break_line_of_sight())
				return TRUE
			if(ai_retreat_goal)
				if(get_dist(src, ai_retreat_goal) > 2)
					Goto(ai_retreat_goal, move_to_delay, 1)
					return TRUE
				adjust_ai_morale(AI_MORALE_REGROUP, "regrouped")
				ai_intent_until = world.time
				return FALSE
			if(retreat_distance == null)
				return FALSE
			if(note_retreat_step(RETREAT_MOVE_AWAY))
				walk(src, 0)
				return TRUE
			var/turf/kite_step = find_kite_step(target)
			if(!kite_step)
				return FALSE
			Goto(kite_step, move_to_delay, 0)
			return TRUE
	return FALSE

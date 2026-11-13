// Hostile mob fast learning (Hostile AI redesign, phase 6a).
// Every mob type shares one /datum/ai_doctrine. While a mob fights, each stretch of time spent on one intent is a
// segment. When it ends, the segment is scored (hits landed, damage taken, allies lost, time spent making no
// progress, dying) and the result is folded into a running value for that intent. The doctrine turns those values
// into a small weight on each intent's utility, so a type drifts toward what has been working against players.
// - Learning is keyed to tactics (intent and a solo or pack context), never to individual players.
// - Everything is bounded: weights stay within +/- AI_DOCTRINE_MAX_SHIFT of 1, nothing moves before
//   AI_DOCTRINE_MIN_SAMPLES results, hits count only up to a cap so killing quickly is not rewarded without limit,
//   old values fade, and the mob only explores near-tied intents.
// - GLOB.ai_learning_enabled turns the whole system off, GLOB.ai_learning_frozen keeps applying weights but stops
//   updating them. Both are on the AI Doctrine admin verb.
// - Phase 6b: each doctrine also keeps a saved prior per tactic, blended with the current round's value. Saving,
//   loading and round-end merging live in the ai_doctrine subsystem (code/controllers/subsystem/ai_doctrine.dm).
// Doctrines hold numbers only, never mobs, so they cannot pin anything in memory.

GLOBAL_VAR_INIT(ai_learning_enabled, TRUE)
GLOBAL_VAR_INIT(ai_learning_frozen, FALSE)
GLOBAL_LIST_EMPTY(ai_doctrines)
GLOBAL_VAR_INIT(ai_doctrine_updates, 0)

/// The doctrine for a mob type given as text, made if needed. Null if it is not a hostile mob type.
/proc/ai_doctrine_for(key)
	if(!istext(key))
		return null
	var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
	if(D)
		return D
	if(!ispath(text2path(key), /mob/living/simple_animal/hostile))
		return null
	D = new(key)
	GLOB.ai_doctrines[key] = D
	return D

/datum/ai_doctrine
	var/mob_type
	/// value[context][intent]: running average of this round's segment rewards
	var/list/value
	/// samples[context][intent]: segments scored this round
	var/list/samples
	/// prior[context][intent]: value kept from earlier rounds, null where there is none
	var/list/prior

/datum/ai_doctrine/New(type_text)
	. = ..()
	mob_type = type_text
	clear_prior()
	reset()

/datum/ai_doctrine/proc/clear_prior()
	prior = list()
	for(var/ctx in 1 to AI_CTX_COUNT)
		var/list/p = list()
		for(var/i in 1 to AI_LEARN_INTENTS)
			p += null
		prior += list(p)

/datum/ai_doctrine/proc/has_prior()
	for(var/list/p in prior)
		for(var/x in p)
			if(!isnull(x))
				return TRUE
	return FALSE

/datum/ai_doctrine/proc/has_samples()
	for(var/list/s in samples)
		for(var/x in s)
			if(x)
				return TRUE
	return FALSE

/// Takes priors from file data, ignoring anything that is not a number and clamping the rest
/datum/ai_doctrine/proc/import_prior(list/data)
	clear_prior()
	if(!islist(data))
		return
	for(var/ctx in 1 to min(AI_CTX_COUNT, length(data)))
		var/list/row = data[ctx]
		if(!islist(row))
			continue
		var/list/p = prior[ctx]
		for(var/i in 1 to min(AI_LEARN_INTENTS, length(row)))
			if(isnum(row[i]))
				p[i] = CLAMP(row[i], -1, 1)

/datum/ai_doctrine/proc/export_pending()
	return list("value" = value, "samples" = samples)

/// Folds one round's results into the priors. Only tactics with enough samples move, by a capped step toward the
/// round's value, and with decay every prior then fades a little toward zero. Returns how many tactics moved.
/datum/ai_doctrine/proc/merge_data(list/round_value, list/round_samples, decay)
	. = 0
	for(var/ctx in 1 to AI_CTX_COUNT)
		var/list/p = prior[ctx]
		var/list/vrow = islist(round_value) && length(round_value) >= ctx ? round_value[ctx] : null
		var/list/srow = islist(round_samples) && length(round_samples) >= ctx ? round_samples[ctx] : null
		for(var/i in 1 to AI_LEARN_INTENTS)
			var/n = islist(srow) && length(srow) >= i && isnum(srow[i]) ? srow[i] : 0
			var/v = islist(vrow) && length(vrow) >= i && isnum(vrow[i]) ? vrow[i] : 0
			if(n >= AI_PERSIST_MIN_SAMPLES)
				var/old = isnull(p[i]) ? 0 : p[i]
				var/step = CLAMP((CLAMP(v, -1, 1) - old) * AI_PERSIST_ALPHA, -AI_PERSIST_MAX_STEP, AI_PERSIST_MAX_STEP)
				p[i] = CLAMP(old + step, -1, 1)
				.++
			if(decay && !isnull(p[i]))
				p[i] = p[i] * (1 - AI_PERSIST_DECAY)

/// The intent's value: its prior blended with this round's results, or this round's results alone once there are
/// enough of them. Null when there is nothing to go on.
/datum/ai_doctrine/proc/effective_value(ctx, intent)
	var/list/s = samples[ctx]
	var/n = s[intent]
	var/p = prior[ctx][intent]
	var/list/v = value[ctx]
	if(isnull(p))
		return n >= AI_DOCTRINE_MIN_SAMPLES ? v[intent] : null
	return (p * AI_PERSIST_PRIOR_WEIGHT + v[intent] * n) / (AI_PERSIST_PRIOR_WEIGHT + n)

/datum/ai_doctrine/proc/reset()
	value = list()
	samples = list()
	for(var/ctx in 1 to AI_CTX_COUNT)
		var/list/v = list()
		var/list/s = list()
		for(var/i in 1 to AI_LEARN_INTENTS)
			v += 0
			s += 0
		value += list(v)
		samples += list(s)

/// Multiplier for one intent's utility: 1 until the doctrine has enough to compare (a saved prior or enough results
/// this round), then the intent's value relative to the average of the intents it has a value for
/datum/ai_doctrine/proc/get_weight(ctx, intent)
	if(intent < 1 || intent > AI_LEARN_INTENTS)
		return 1
	var/mine = effective_value(ctx, intent)
	if(isnull(mine))
		return 1
	var/total = 0
	var/count = 0
	for(var/i in 1 to AI_LEARN_INTENTS)
		var/x = effective_value(ctx, i)
		if(!isnull(x))
			total += x
			count++
	if(count < 2)
		return 1
	return 1 + CLAMP((mine - total / count) * AI_DOCTRINE_GAIN, -AI_DOCTRINE_MAX_SHIFT, AI_DOCTRINE_MAX_SHIFT)

/datum/ai_doctrine/proc/record(ctx, intent, reward)
	if(intent < 1 || intent > AI_LEARN_INTENTS)
		return
	var/list/v = value[ctx]
	var/list/s = samples[ctx]
	s[intent] = s[intent] + 1
	if(s[intent] == 1)
		v[intent] = reward
	else
		v[intent] = (v[intent] + AI_DOCTRINE_RATE * (reward - v[intent])) * (1 - AI_DOCTRINE_DECAY)
	GLOB.ai_doctrine_updates++

/datum/ai_doctrine/proc/summary()
	. = list()
	for(var/ctx in 1 to AI_CTX_COUNT)
		var/list/v = value[ctx]
		var/list/s = samples[ctx]
		var/list/parts = list()
		for(var/i in 1 to AI_LEARN_INTENTS)
			var/p = prior[ctx][i]
			parts += "[GLOB.ai_intent_names[i]] n=[s[i]] v=[round(v[i], 0.01)] p=[isnull(p) ? "-" : round(p, 0.01)] w=[round(get_weight(ctx, i), 0.01)]"
		. += "  [ctx == AI_CTX_SOLO ? "solo" : "pack"]: [parts.Join(", ")]"

/mob/living/simple_animal/hostile
	/// Intent segment being scored for learning
	var/ai_seg_intent = AI_INTENT_NONE
	var/ai_seg_start = 0
	var/ai_seg_ctx = AI_CTX_SOLO
	var/ai_seg_learn = FALSE
	var/ai_seg_hits = 0
	var/ai_seg_taken = 0
	var/ai_seg_allies_lost = 0
	/// Context of the latest decision
	var/ai_decision_ctx = AI_CTX_SOLO

/mob/living/simple_animal/hostile/proc/ai_learning_active()
	return GLOB.ai_learning_enabled && ai_decision_enabled && !ckey

/mob/living/simple_animal/hostile/proc/get_ai_doctrine()
	return ai_doctrine_for("[type]")

/// Starts timing a stretch of one intent. learn is FALSE for stretches the mob did not choose itself.
/mob/living/simple_animal/hostile/proc/ai_open_segment(intent, learn)
	ai_seg_intent = intent
	ai_seg_start = world.time
	ai_seg_ctx = ai_decision_ctx
	// Mobs an admin spawned are test fights, not something to learn from
	ai_seg_learn = learn && !(flags_1 & ADMIN_SPAWNED_1)
	ai_seg_hits = 0
	ai_seg_taken = 0
	ai_seg_allies_lost = 0

/// Scores the segment that just ended and hands the result to the doctrine
/mob/living/simple_animal/hostile/proc/ai_close_segment(reason, died = FALSE)
	var/intent = ai_seg_intent
	if(intent == AI_INTENT_NONE)
		return
	ai_seg_intent = AI_INTENT_NONE
	if(!ai_seg_learn || intent > AI_LEARN_INTENTS || !ai_learning_active() || GLOB.ai_learning_frozen)
		return
	var/seconds = (world.time - ai_seg_start) / 10
	if(seconds < AI_LEARN_MIN_SEGMENT && !died)
		return

	var/reward = AI_REWARD_HIT * min(ai_seg_hits, AI_REWARD_HIT_CAP) / AI_REWARD_HIT_CAP
	var/taken = maxHealth > 0 ? CLAMP(ai_seg_taken / maxHealth, 0, 1) : 0
	reward -= AI_REWARD_DAMAGE * taken
	reward -= AI_REWARD_ALLY_LOSS * min(ai_seg_allies_lost, AI_REWARD_ALLY_LOSS_CAP)
	if(!ai_seg_hits && !ai_seg_taken)
		reward -= min(seconds * AI_REWARD_STALL_RATE, AI_REWARD_STALL_CAP)
	if(died)
		reward -= AI_REWARD_DEATH
	reward = CLAMP(reward, -1, 1)

	var/datum/ai_doctrine/D = get_ai_doctrine()
	D.record(ai_seg_ctx, intent, reward)
	ai_debug_log("doctrine_update intent=[GLOB.ai_intent_names[intent]] ctx=[ai_seg_ctx] reason=[reason] secs=[round(seconds, 0.1)] hits=[ai_seg_hits] taken=[round(taken, 0.01)] lost=[ai_seg_allies_lost] reward=[round(reward, 0.01)] weight=[round(D.get_weight(ai_seg_ctx, intent), 0.01)]")

/// Admin panel for the learning system
/client/proc/ai_doctrine_panel()
	set category = "Debug"
	set name = "AI Doctrine"
	set desc = "View, freeze, reset or switch off hostile mob learning."
	if(!check_rights(R_DEBUG))
		return
	var/choice = input(usr, "Learning is [GLOB.ai_learning_enabled ? "ON" : "OFF"], [GLOB.ai_learning_frozen ? "FROZEN" : "updating"]. [length(GLOB.ai_doctrines)] doctrines, [GLOB.ai_doctrine_updates] updates. Persistence: [SSai_doctrine.status].", "AI Doctrine") as null|anything in list("View doctrines", "Toggle learning", "Toggle freeze", "Save now", "Roll back to snapshot", "Reset one doctrine", "Reset all")
	switch(choice)
		if("View doctrines")
			var/list/lines = list("<b>Hostile AI doctrines</b> (v = this round, p = saved prior, w = weight)")
			if(!length(GLOB.ai_doctrines))
				lines += "None yet."
			for(var/key in GLOB.ai_doctrines)
				var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
				lines += "[key]"
				lines += D.summary()
			to_chat(usr, lines.Join("<br>"))
		if("Toggle learning")
			GLOB.ai_learning_enabled = !GLOB.ai_learning_enabled
			message_admins("[key_name_admin(usr)] turned hostile AI learning [GLOB.ai_learning_enabled ? "on" : "off"].")
			log_admin("[key_name(usr)] turned hostile AI learning [GLOB.ai_learning_enabled ? "on" : "off"].")
		if("Toggle freeze")
			GLOB.ai_learning_frozen = !GLOB.ai_learning_frozen
			message_admins("[key_name_admin(usr)] [GLOB.ai_learning_frozen ? "froze" : "unfroze"] hostile AI learning.")
			log_admin("[key_name(usr)] [GLOB.ai_learning_frozen ? "froze" : "unfroze"] hostile AI learning.")
		if("Save now")
			var/ok = SSai_doctrine.save_now()
			message_admins("[key_name_admin(usr)] saved the hostile AI doctrines ([ok ? "ok" : "failed"]).")
			log_admin("[key_name(usr)] saved the hostile AI doctrines ([ok ? "ok" : "failed"]).")
		if("Roll back to snapshot")
			var/list/options = list()
			for(var/i in 1 to AI_DOCTRINE_SNAPSHOTS)
				if(fexists("[AI_DOCTRINE_FILE].[i]"))
					options += "[i]"
			if(!length(options))
				to_chat(usr, span_warning("There are no snapshots."))
				return
			var/which = input(usr, "Restore which snapshot? 1 is the most recent round end.", "AI Doctrine") as null|anything in options
			if(!which)
				return
			var/restored = SSai_doctrine.restore_snapshot(text2num(which))
			message_admins("[key_name_admin(usr)] rolled the hostile AI doctrines back to snapshot [which] ([restored ? "ok" : "failed"]).")
			log_admin("[key_name(usr)] rolled the hostile AI doctrines back to snapshot [which] ([restored ? "ok" : "failed"]).")
		if("Reset one doctrine")
			if(!length(GLOB.ai_doctrines))
				return
			var/key = input(usr, "Reset which doctrine?", "AI Doctrine") as null|anything in GLOB.ai_doctrines
			if(!key)
				return
			var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
			D.reset()
			D.clear_prior()
			message_admins("[key_name_admin(usr)] reset the hostile AI doctrine for [key].")
			log_admin("[key_name(usr)] reset the hostile AI doctrine for [key].")
		if("Reset all")
			for(var/key in GLOB.ai_doctrines)
				var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
				D.reset()
			SSai_doctrine.clear_all_priors()
			message_admins("[key_name_admin(usr)] reset every hostile AI doctrine.")
			log_admin("[key_name(usr)] reset every hostile AI doctrine.")

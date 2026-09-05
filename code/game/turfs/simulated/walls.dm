#define MAX_DENT_DECALS 15

/turf/closed/wall
	name = "wall"
	desc = "A huge chunk of metal used to separate rooms."
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall"
	explosion_block = 1
	flags_1 = DEFAULT_RICOCHET_1
	flags_ricochet = RICOCHET_HARD
	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 312500 //a little over 5 cm thick , 312500 for 1 m by 2.5 m by 0.25 m plasteel wall
	attack_hand_speed = 8
	attack_hand_is_action = TRUE

	baseturfs = /turf/open/floor/plating

	var/hardness = 40 //lower numbers are harder. Used to determine the probability of a hulk smashing through.
	var/slicing_duration = 100  //default time taken to slice the wall
	var/sheet_type = /obj/item/stack/sheet/metal
	var/sheet_amount = 2
	var/girder_type = /obj/structure/girder
	/// Wall breaks on light blast
	var/weak_wall = TRUE

	canSmoothWith = list(
	/turf/closed/wall,
	/turf/closed/wall/r_wall,
	/obj/structure/falsewall,
	/obj/structure/falsewall/brass,
	/obj/structure/falsewall/reinforced,
	/turf/closed/wall/rust,
	/turf/closed/wall/r_wall/rust,
	/turf/closed/wall/clockwork)
	smooth = SMOOTH_TRUE

	var/list/dent_decals

/turf/closed/wall/examine(mob/user)
	. = ..()
	deconstruction_hints(user)

/turf/closed/wall/proc/deconstruction_hints(mob/user)
	return "<span class='notice'>The outer plating is <b>welded</b> firmly in place.</span>"

/turf/closed/wall/attack_tk()
	return

/turf/closed/wall/proc/dismantle_wall(devastated=0, explode=0)
	if(devastated)
		devastate_wall()
	else
		playsound(src, 'sound/items/welder.ogg', 100, 1)
		var/newgirder = break_wall()
		if(newgirder) //maybe we don't /want/ a girder!
			transfer_fingerprints_to(newgirder)

	for(var/obj/O in src.contents) //Eject contents!
		if(istype(O, /obj/structure/sign/poster))
			var/obj/structure/sign/poster/P = O
			P.roll_and_drop(src)

	ScrapeAway()

/turf/closed/wall/proc/break_wall()
	if(sheet_type)
		new sheet_type(src, sheet_amount)
	if(girder_type)
		return new girder_type(src)

/turf/closed/wall/proc/devastate_wall()
	if(sheet_type)
		new sheet_type(src, sheet_amount)
	if(girder_type)
		new /obj/item/stack/sheet/metal(src)

/turf/closed/wall/ex_act(severity, target)
	if(target == src)
		dismantle_wall(1,1)
		return
	switch(severity)
		if(1)
			//SN src = null
			var/turf/NT = ScrapeAway()
			NT.contents_explosion(severity, target)
			return
		if(2)
			if (prob(50))
				dismantle_wall(0,1)
			else
				dismantle_wall(1,1)
		if(3)
			if (weak_wall && prob(hardness))
				dismantle_wall(0,1)
	if(!density)
		..()


/turf/closed/wall/blob_act(obj/structure/blob/B)
	if(prob(50))
		dismantle_wall()
	else
		add_dent(WALL_DENT_HIT)

/turf/closed/wall/mech_melee_attack(obj/mecha/M)
	M.do_attack_animation(src)
	switch(M.damtype)
		if(BRUTE)
			playsound(src, 'sound/weapons/punch4.ogg', 50, 1)
			visible_message(span_danger("[M.name] has hit [src]!"), null, null, COMBAT_MESSAGE_RANGE)
			if(M.force >= hardness*0.8)
				dismantle_wall(1)
				playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
			else
				add_dent(WALL_DENT_HIT)
		if(BURN)
			playsound(src, 'sound/items/welder.ogg', 100, 1)
		if(TOX)
			playsound(src, 'sound/effects/spray2.ogg', 100, 1)
			return FALSE

/turf/closed/wall/attack_paw(mob/living/user)
	return attack_hand(user)

/turf/closed/wall/attack_animal(mob/living/simple_animal/M)
	if(!M.CheckActionCooldown(CLICK_CD_MELEE))
		return
	M.DelayNextAction()
	M.do_attack_animation(src)
	if((M.environment_smash & ENVIRONMENT_SMASH_WALLS) || (M.environment_smash & ENVIRONMENT_SMASH_RWALLS))
		playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
		dismantle_wall(1)
		return

/turf/closed/wall/attack_hulk(mob/living/carbon/user)
	..()
	var/obj/item/bodypart/arm = user.hand_bodyparts[user.active_hand_index]
	if(!arm)
		return
	if(arm.disabled)
		return
	if(prob(hardness))
		playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ), forced = "hulk")
		//hulk_recoil(arm, user)		// citadel edit - no, hulks are already subject to stamina combat
		dismantle_wall(1)

	else
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		add_dent(WALL_DENT_HIT)
		user.visible_message(span_danger("[user] smashes \the [src]!"), \
					span_danger("You smash \the [src]!"), \
					span_hear("You hear a booming smash!"))
	return TRUE

/**
 *Deals damage back to the hulk's arm.
 *
 *When a hulk manages to break a wall using their hulk smash, this deals back damage to the arm used.
 *This is in its own proc just to be easily overridden by other wall types. Default allows for three
 *smashed walls per arm. Also, we use CANT_WOUND here because wounds are random. Wounds are applied
 *by hulk code based on arm damage and checked when we call break_an_arm().
 *Arguments:
 **arg1 is the arm to deal damage to.
 **arg2 is the hulk
 */
/turf/closed/wall/proc/hulk_recoil(obj/item/bodypart/arm, mob/living/carbon/human/hulkman, damage = 20)
	arm.receive_damage(brute = damage, blocked = 0, wound_bonus = CANT_WOUND)
	var/datum/mutation/human/hulk/smasher = locate(/datum/mutation/human/hulk) in hulkman.dna.mutations
	if(!smasher || !damage) //sanity check but also snow and wood walls deal no recoil damage, so no arm breaky
		return
	smasher.break_an_arm(arm)

/turf/closed/wall/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	to_chat(user, span_notice("You push the wall but nothing happens!"))
	playsound(src, 'sound/weapons/genhit.ogg', 25, 1)
	add_fingerprint(user)

/turf/closed/wall/attackby(obj/item/W, mob/user, params)
	if(!user.CheckActionCooldown(CLICK_CD_MELEE))
		return
	if (!user.IsAdvancedToolUser())
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return

	//get the user's location
	if(!isturf(user.loc))
		return	//can't do this stuff whilst inside objects and such

	user.DelayNextAction()
	add_fingerprint(user)

	var/turf/T = user.loc	//get user's location for delay checks

	//the istype cascade has been spread among various procs for easy overriding
	var/srctype = type
	if(try_clean(W, user, T) || try_wallmount(W, user, T) || try_decon(W, user, T) || (type == srctype && try_destroy(W, user, T)))
		return

	return ..()

/turf/closed/wall/proc/try_clean(obj/item/W, mob/user, turf/T)
	if((user.a_intent != INTENT_HELP) || !LAZYLEN(dent_decals))
		return FALSE

	if(istype(W, /obj/item/weldingtool))
		if(!W.tool_start_check(user, amount=0))
			return FALSE

		to_chat(user, span_notice("You begin fixing dents on the wall..."))
		if(W.use_tool(src, user, 0, volume=100))
			if(iswallturf(src) && LAZYLEN(dent_decals))
				to_chat(user, span_notice("You fix some dents on the wall."))
				cut_overlay(dent_decals)
				dent_decals.Cut()
			return TRUE

	return FALSE

/turf/closed/wall/proc/try_wallmount(obj/item/W, mob/user, turf/T)
	//check for wall mounted frames
	if(istype(W, /obj/item/wallframe))
		var/obj/item/wallframe/F = W
		if(F.try_build(src, user))
			F.attach(src, user)
		return TRUE
	//Poster stuff
	else if(istype(W, /obj/item/poster))
		place_poster(W,user)
		return TRUE
	//wall mounted IC assembly stuff
	else if(istype(W, /obj/item/electronic_assembly/wallmount))
		var/obj/item/electronic_assembly/wallmount/A = W
		A.mount_assembly(src, user)
		return TRUE
	else if(istype(W, /obj/item/candle/tribal_torch))
		var/obj/item/candle/tribal_torch/torch = W
		torch.do_wallmount(src, user)
		return TRUE

	return FALSE

/turf/closed/wall/proc/try_decon(obj/item/I, mob/user, turf/T)
	if(istype(I, /obj/item/weldingtool) || istype(I, /obj/item/gun/energy/plasmacutter))
		if(!I.tool_start_check(user, amount=0))
			return FALSE

		to_chat(user, span_notice("You begin slicing through the outer plating..."))
		if(I.use_tool(src, user, slicing_duration, volume=100))
			if(iswallturf(src))
				to_chat(user, span_notice("You remove the outer plating."))
				dismantle_wall()
			return TRUE

	return FALSE


/turf/closed/wall/proc/try_destroy(obj/item/I, mob/user, turf/T)
	if(istype(I, /obj/item/pickaxe/drill/jackhammer))
		to_chat(user, span_notice("You begin to smash though [src]..."))
		if(do_after(user, 70, target = src))
			if(!istype(src, /turf/closed/wall))
				return TRUE
			I.play_tool_sound(src)
			visible_message(span_warning("[user] smashes through [src] with [I]!"), span_italic("You hear the grinding of metal."))
			dismantle_wall()
			return TRUE
	return FALSE

/turf/closed/wall/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		if(prob(50))
			dismantle_wall()
		return
	if(current_size == STAGE_FOUR)
		if(prob(30))
			dismantle_wall()

/turf/closed/wall/narsie_act(force, ignore_mobs, probability = 20)
	. = ..()
	if(.)
		ChangeTurf(/turf/closed/wall/mineral/cult)

/turf/closed/wall/ratvar_act(force, ignore_mobs)
	. = ..()
	if(.)
		ChangeTurf(/turf/closed/wall/clockwork)

/turf/closed/wall/get_dumping_location(obj/item/storage/source, mob/user)
	return null

/turf/closed/wall/acid_act(acidpwr, acid_volume)
	if(explosion_block >= 2)
		acidpwr = min(acidpwr, 50) //we reduce the power so strong walls never get melted.
	. = ..()

/turf/closed/wall/acid_melt()
	dismantle_wall(1)

/turf/closed/wall/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	switch(the_rcd.mode)
		if(RCD_DECONSTRUCT)
			return list("mode" = RCD_DECONSTRUCT, "delay" = 40, "cost" = 26)
	return FALSE

/turf/closed/wall/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_DECONSTRUCT)
			to_chat(user, span_notice("You deconstruct the wall."))
			ScrapeAway()
			return TRUE
	return FALSE

/turf/closed/wall/proc/add_dent(denttype, x=rand(-8, 8), y=rand(-8, 8))
	if(LAZYLEN(dent_decals) >= MAX_DENT_DECALS)
		return

	var/mutable_appearance/decal = mutable_appearance('icons/effects/effects.dmi', "", BULLET_HOLE_LAYER, ABOVE_WALL_PLANE)
	switch(denttype)
		if(WALL_DENT_SHOT)
			decal.icon_state = "bullet_hole"
		if(WALL_DENT_HIT)
			decal.icon_state = "impact[rand(1, 3)]"

	decal.pixel_x = x
	decal.pixel_y = y

	if(LAZYLEN(dent_decals))
		cut_overlay(dent_decals)
		dent_decals += decal
	else
		dent_decals = list(decal)

	add_overlay(dent_decals)

/turf/closed/wall/rust_heretic_act()
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	ChangeTurf(/turf/closed/wall/rust)

#undef MAX_DENT_DECALS


// Free Running perk!
/turf/closed/wall/AltClick(mob/living/user)
	. = ..()
	if(user.stat)
		return
	if(HAS_TRAIT(user, TRAIT_FREERUNNING))
		if(user.restrained())
			return
		if(get_dist	(user,	src)	>	1)
			return
		var/turf/aboveT = get_step_multiz(get_turf(user), UP)
		if(!istype(aboveT, /turf/open/transparent/openspace))
			to_chat(user, "You can't climb there, there is a ceiling!")
			return
		visible_message(span_warning("[user] attempts to climb the [name]!"), span_warning("You begin climbing the [name]"))
		
		if(do_mob(user, user, 40 + (user.getStaminaLoss() * 0.25))) // 25% of your stamina loss will effect the speed on climbing.
			var/turf/targetDest = get_step_multiz(get_turf(src), UP)
			if(istype(targetDest, /turf/open/transparent/openspace)) // This helps prevent boundary breaking.
				to_chat(user, span_warning("There's nothing to stand on once you climb up..!"))
				return
			
			var/failedPass = FALSE
			for(var/obj/O in targetDest.contents)
				if(!O.CanPass(user, get_dir(aboveT, targetDest)))
					failedPass = TRUE
					break

			if(!isloc(targetDest) || targetDest?.density || !targetDest.CanPass(user, get_dir(aboveT, targetDest)) || failedPass)
				to_chat(user, span_warning("You peak towards the top of the wall, but it's not safe to climb there!"))
				return
			if(user.zMove(UP, targetDest, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK))
				to_chat(user, span_notice("You move upwards."))




// ==================== Merged from fallout (code\modules\fallout\turf\walls.dm) ====================
//Fallout 13 general destructible walls directory

/turf/closed/wall/f13/
	name = "glitch"
	desc = "<font color='#6eaa2c'>You suddenly realize the truth - there is no spoon.<br>Something has caused a glitch in the simulation.</font>"
	icon = 'icons/turf/walls_f13.dmi'
	icon_state = "matrix"

/turf/closed/wall/f13/ReplaceWithLattice()
	ChangeTurf(baseturfs)

/turf/closed/wall/f13/ruins
	name = "ruins"
	desc = "All what has left from the good old days."
	icon = 'icons/turf/walls/f13composite.dmi'
	icon_state = "ruins"
	icon_type_smooth = "ruins"
	hardness = 70
	explosion_block = 2
	smooth = SMOOTH_TRUE
	//	disasemblable = 0
	girder_type = 0
	baseturfs = /turf/open/indestructible/ground/outside/ruins
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/ruins, /turf/closed/wall)
	unbreakable = 0


/turf/closed/wall/f13/wood
	name = "wooden wall"
	desc = "A traditional wooden wall."
	icon = 'icons/turf/walls/wood.dmi'
	icon_state = "wood0"
	icon_type_smooth = "wood"
	hardness = 60
	smooth = SMOOTH_OLD
	unbreakable = 0
	baseturfs = /turf/open/floor/plating/wooden
	sheet_type = /obj/item/stack/sheet/mineral/wood
	sheet_amount = 2
	girder_type = 0
	canSmoothWith = list(/turf/closed/wall/f13/wood, /turf/closed/wall)

/turf/closed/wall/f13/woodalt
	name = "wooden wall"
	desc = "A traditional wooden wall."
	icon = 'icons/turf/walls/wood_wall.dmi'
	icon_state = "wood"
	icon_type_smooth = "wood"
	hardness = 60
	smooth = SMOOTH_TRUE
	unbreakable = 0
	baseturfs = /turf/open/floor/plating/wooden
	sheet_type = /obj/item/stack/sheet/mineral/wood
	sheet_amount = 2
	girder_type = 0
	canSmoothWith = list(/turf/closed/wall/f13/wood, /turf/closed/wall, /turf/closed/wall/f13/woodalt)

/turf/closed/wall/f13/wood/house
	name = "house wall"
	desc = "A weathered pre-War house wall."
	icon = 'icons/turf/walls/house.dmi'
	icon_state = "house0"
	icon_type_smooth = "house"
	hardness = 50
	var/broken = FALSE
	var/clean = FALSE
	canSmoothWith = list(/turf/closed/wall/f13/wood/house, /turf/closed/wall/f13/wood/house/broken, /turf/closed/wall, /turf/closed/wall/f13/wood/house/clean, /turf/closed/wall/f13/wood/house/clean/broken, /turf/closed/wall/f13/wood/house/shack)

/turf/closed/wall/f13/wood/house/shack
	name = "shack wall"

/turf/closed/wall/f13/wood/house/broken
	desc = "A broken weathered pre-War house wall."
	broken = TRUE
	damage = 21
	icon_state = "house0-broken"

/turf/closed/wall/f13/wood/house/clean
	desc = "A freshly painted pre-War house wall."
	clean = TRUE
	icon_state = "house0-clean"

/turf/closed/wall/f13/wood/house/clean/broken
	desc = "A broken freshly painted pre-War house wall."
	broken = TRUE
	icon_state = "house0-clean-broken"

/turf/closed/wall/f13/wood/house/take_damage(dam)
	if(damage + dam > hardness/2)
		broken = 1
	..()

/turf/closed/wall/f13/wood/house/relative()
	icon_state = "[icon_type_smooth][junction][clean ? "-clean" : ""][broken ? "-broken" : ""]"

/turf/closed/wall/f13/wood/house/attackby(obj/item/W, mob/user, params)
	if(clean && istype(W, /obj/item/paint/paint_remover))
		playsound(user.loc, 'sound/effects/splat.ogg', 25, 1, 5)
		user.visible_message("[user] starts removing the paint from [src]!", span_notice("You start removing the paint from [src]."))
		if(!do_after(user, 1 SECONDS, FALSE, src))
			to_chat(user, span_warning("You must stand still to remove the paint on the wall!"))
			return
		user.visible_message("[user] removes the paint from [src]!", span_notice("You remove the paint from [src]."))
		if(broken)
			ChangeTurf(/turf/closed/wall/f13/wood/house/broken)
		else
			ChangeTurf(/turf/closed/wall/f13/wood/house)
		return

	if(istype(W, /obj/item/toy/crayon/spraycan))
		var/obj/item/toy/crayon/spraycan/I = W
		if(!I.use_charges(user, 2))
			to_chat(user, span_warning("[I] is too empty to paint [src]!"))
			return

		if(I.is_capped)
			to_chat(user, span_warning("Open the cap first!"))
			return

		playsound(user.loc, 'sound/effects/spray.ogg', 25, 1, 5)
		user.visible_message("[user] starts coating [src] with a fresh layer of paint!", span_notice("You start coating [src] with a fresh layer of paint."))
		if(!do_after(user, 1 SECONDS, FALSE, src))
			to_chat(user, span_warning("You must stand still to paint the wall!"))
			return                                      
		user.visible_message("[user] coats [src] with a fresh layer of paint!", span_notice("You coat [src] with a fresh layer of paint."))
		if(!clean)
			if(broken)
				ChangeTurf(/turf/closed/wall/f13/wood/house/clean/broken)
			else
				ChangeTurf(/turf/closed/wall/f13/wood/house/clean)
		src.add_atom_colour(I.paint_color, WASHABLE_COLOUR_PRIORITY)
		return


	if(broken && istype(W, /obj/item/stack/sheet/mineral/wood))
		var/obj/item/stack/sheet/mineral/wood/I = W
		if(I.amount < 2)
			return
		if(!do_after(user, 5 SECONDS, FALSE, src))
			to_chat(user, span_warning("You must stand still to fix the wall!"))
			return
		W.use(2)
		if(clean)
			ChangeTurf(/turf/closed/wall/f13/wood/house/clean)
		else
			ChangeTurf(/turf/closed/wall/f13/wood/house)
	. = ..()

/turf/closed/wall/f13/wood/house/update_icon()
	if(broken)
		set_opacity(0)
	..()

turf/closed/wall/f13/wood/house/update_damage_overlay()
	if(broken)
		return
	..()

/turf/closed/wall/f13/wood/interior
	name = "interior wall"
	desc = "Interesting, what kind of material they have used - these wallpapers still look good after all the centuries..."
	icon = 'icons/turf/walls/interior.dmi'
	icon_state = "interior0"
	icon_type_smooth = "interior"
	hardness = 10
	smooth = SMOOTH_OLD
	canSmoothWith = list(/turf/closed/wall/f13/wood/interior, /turf/closed/wall)

/turf/closed/wall/f13/store
	name = "store wall"
	desc = "A pre-War store wall made of solid concrete."
	icon = 'icons/turf/walls/f13store.dmi'
	icon_state = "store"
	icon_type_smooth = "store"
	hardness = 80
	smooth = SMOOTH_TRUE
	//	disasemblable = 0
	baseturfs = /turf/open/indestructible/ground/outside/ruins
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/store, /turf/closed/wall/f13/store/constructed, /turf/closed/wall,)

/turf/closed/wall/f13/store/concretewall
	name = "concrete wall"
	canSmoothWith = list(/turf/closed/wall/f13/store, /turf/closed/wall/f13/store/constructed, /turf/closed/wall, /turf/closed/indestructible/f13/obsidian, /turf/closed/wall/mineral/concrete/blastproof, /turf/closed/wall/f13/store/concretewall)

/turf/closed/wall/f13/tentwall
	name = "tent wall"
	desc = "The walls of a portable tent."
	icon = 'icons/turf/walls/tent.dmi'
	icon_state = "tent0"
	icon_type_smooth = "tent"
	hardness = 10
	unbreakable = 0
	smooth = SMOOTH_OLD
	//	disasemblable = 0
	baseturfs = /turf/open/indestructible/ground/outside/ruins
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/tentwall, /turf/closed/wall)

/turf/closed/wall/f13/scrap
	name = "scrap wall"
	desc = "A wall held together by corrugated metal and prayers."
	icon = 'icons/turf/walls/scrap.dmi'
	icon_state = "scrap0"
	icon_type_smooth = "scrap"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall)

/turf/closed/wall/f13/scrap/red
	icon = 'icons/turf/walls/scrap_red.dmi'
	icon_state = "scrapr0"
	icon_type_smooth = "scrapr"

/turf/closed/wall/f13/scrap/blue
	icon = 'icons/turf/walls/scrap_blue.dmi'
	icon_state = "scrapb0"
	icon_type_smooth = "scrapb"

/turf/closed/wall/f13/scrap/white
	icon = 'icons/turf/walls/scrap_white.dmi'
	icon_state = "scrapw0"
	icon_type_smooth = "scrapw"

/turf/closed/wall/f13/scrap/junk
	name = "junk wall"
	desc = "More a pile of debris and rust than a wall, but it'll hold for now."
	icon = 'icons/turf/walls/scrap_rough.dmi'
	icon_state = "scrapro0"
	icon_type_smooth = "scrapro"

/turf/closed/wall/f13/supermart
	name = "concrete wall"
	desc = "A pre-War concrete wall made of reinforced concrete."
	icon = 'icons/turf/walls/f13superstore.dmi'
	icon_state = "supermart"
	icon_type_smooth = "supermart"
	hardness = 90
	explosion_block = 2
	smooth = SMOOTH_TRUE
	baseturfs = /turf/open/indestructible/ground/outside/ruins
	//	disasemblable = 0
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/supermart, /turf/closed/wall/mineral/concrete, /turf/closed/wall, /turf/closed/wall/mineral/concrete/blastproof, /turf/closed/wall/mineral/concrete/blastproof/moresmooth, /turf/closed/wall/mineral/concrete/blastproof/storewall, /turf/closed/indestructible/f13/supermart, /obj/structure/falsewall/concrete, /turf/closed/indestructible/f13/vaultwall/notvaultwall, /turf/closed/indestructible/f13/vaultwall, /turf/closed/indestructible/f13/supermart)

/turf/closed/wall/f13/tunnel
	name = "utility tunnel wall"
	desc = "A sturdy metal wall with various pipes and wiring set inside a special groove."
	icon = 'icons/turf/walls/tunnel.dmi'
	icon_state = "tunnel0"
	icon_type_smooth = "tunnel"
	hardness = 100
	smooth = SMOOTH_OLD
	//	disasemblable = 0
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/tunnel, /turf/closed/wall)

/turf/closed/wall/f13/vault
	name = "vault wall"
	desc = "A sturdy and cold metal wall."
	icon = 'icons/turf/walls/vault.dmi'
	icon_state = "vault0"
	icon_type_smooth = "vault"
	hardness = 130
	explosion_block = 5
	smooth = SMOOTH_OLD
	canSmoothWith = list(/turf/closed/wall/f13/vault, /turf/closed/wall/r_wall/f13/vault, /turf/closed/wall)

/turf/closed/wall/r_wall/f13
	name = "glitch"
	desc = "<font color='#6eaa2c'>You suddenly realize the truth - there is no spoon.<br>Something has caused a glitch in the simulation.</font>"
	icon = 'icons/turf/walls_f13.dmi'
	icon_state = "matrix"

/turf/closed/wall/r_wall/f13/vault
	name = "vault reinforced wall"
	desc = "A wall built to withstand an atomic explosion."
	icon = 'icons/turf/walls/vault_reinforced.dmi'
	icon_state = "vaultrwall0"
	icon_type_smooth = "vaultrwall"
	hardness = 230
	explosion_block = 5
	smooth = SMOOTH_OLD
	canSmoothWith = list(/turf/closed/wall/f13/vault, /turf/closed/wall/r_wall/f13/vault, /turf/closed/wall)

//Sunset custom walls

/turf/closed/wall/f13/sunset/brick_small
	name = "brick wall"
	desc = "A wall made out of solid brick."
	icon = 'icons/turf/walls/brick_small.dmi'
	icon_state = "brick0"
	icon_type_smooth = "brick"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall)

/turf/closed/wall/f13/sunset/brick_small_dark
	name = "brick wall"
	desc = "A wall made out of solid brick."
	icon = 'icons/turf/walls/brick_small_dark.dmi'
	icon_state = "brick0"
	icon_type_smooth = "brick"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall)

/turf/closed/wall/f13/sunset/brick_small_light
	name = "brick wall"
	desc = "A wall made out of solid brick."
	icon = 'icons/turf/walls/brick_small_light.dmi'
	icon_state = "brick0"
	icon_type_smooth = "brick"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall)

//Fallout 13 indestructible walls

/turf/closed/indestructible/f13
	name = "glitch"
	desc = "<font color='#6eaa2c'>You suddenly realize the truth - there is no spoon.<br>Something has caused a glitch in the simulation.</font>"
	icon = 'icons/turf/walls_f13.dmi'
	icon_state = "matrix"

/turf/closed/indestructible/f13/subway
	name = "tunnel wall"
	desc = "This wall is made of reinforced concrete.<br>Pre-War engineers knew how to build reliable things."
	icon = 'icons/turf/walls/subway.dmi'
	icon_state = "subwaytop"

/turf/closed/indestructible/f13/matrix //The Chosen One from Arroyo!
	name = "matrix"
	desc = "<font color='#6eaa2c'>You suddenly realize the truth - there is no spoon.<br>Digital simulation ends here.</font>"
	icon_state = "matrix"
	var/in_use = FALSE

/turf/closed/indestructible/f13/matrix/dirt
	icon = 'icons/turf/floors.dmi'
	icon_state = "dirt"

/turf/closed/indestructible/f13/matrix/saltflats
	icon = 'icons/turf/snow.dmi'
	icon_state = "snow"

/turf/closed/indestructible/f13/matrix/desert
	icon = 'icons/turf/ground.dmi'
	icon_state = "wasteland"

/turf/closed/indestructible/f13/matrix/wendover
	icon = 'icons/obj/wendover.dmi'
	icon_state = "gravelsiding"

/turf/closed/indestructible/f13/matrix/asphalt
	icon = 'icons/turf/asphalt.dmi'
	icon_state = "verticalleftborderright1"

/turf/closed/indestructible/f13/matrix/sidewalk
	icon = 'icons/turf/sidewalk.dmi'
	icon_state = "horizontalbottomborderbottom0"

/turf/closed/indestructible/f13/matrix/subway
	icon = 'icons/turf/ground.dmi'
	icon_state = "railsnone"

/turf/closed/indestructible/f13/matrix/gravel
	icon = 'icons/turf/tileset_gravel.dmi'
	icon_state = "gravel"

/turf/closed/indestructible/f13/matrix/MouseDrop_T(atom/dropping, mob/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return //No ghosts or incapacitated folk allowed to do this.
	if(!ishuman(dropping))
		return //Only humans have job slots to be freed.
	if(in_use) // Someone's already going in.
		return
	var/mob/living/carbon/human/departing_mob = dropping
	if(departing_mob != user && departing_mob.client)
		to_chat(user, span_warning("This one retains their free will. It's their choice if they want to depart or not."))
		return
	if(alert("Are you sure you want to [departing_mob == user ? "depart the area for good (you" : "send this person away (they"] will be removed from the current round, the job slot freed)?", "Departing the swamps", "Confirm", "Cancel") != "Confirm")
		return
	if(user.incapacitated() || QDELETED(departing_mob) || (departing_mob != user && departing_mob.client) || get_dist(src, dropping) > 2 || get_dist(src, user) > 2)
		return //Things have changed since the alert happened.
	if(departing_mob.logout_time && departing_mob.logout_time + 2 MINUTES > world.time)
		to_chat(user, span_warning("This mind has only recently departed. Wait at most two minutes before sending this character out of the round."))
		return
	user.visible_message(span_warning("[user] [departing_mob == user ? "is trying to leave the swamps!" : "is trying to send [departing_mob] away!"]"), span_notice("You [departing_mob == user ? "are trying to leave the swamps." : "are trying to send [departing_mob] away."]"))
	update_icon()
	in_use = TRUE
	if(!do_after(user, 50, target = src))
		in_use = FALSE
		return
	in_use = FALSE
	update_icon()
	var/dat = "[key_name(user)] has despawned [departing_mob == user ? "themselves" : departing_mob], job [departing_mob.job], at [AREACOORD(src)]. Contents despawned along:"
	if(!length(departing_mob.contents))
		dat += " none."
	else
		var/atom/movable/content = departing_mob.contents[1]
		dat += " [content.name]"
		for(var/i in 2 to length(departing_mob.contents))
			content = departing_mob.contents[i]
			dat += ", [content.name]"
		dat += "."
	message_admins(dat)
	log_admin(dat)
	if(departing_mob.stat == DEAD)
		departing_mob.visible_message(span_notice("[user] pushes the body of [departing_mob] over the border. They're someone else's problem now."))
	else
		departing_mob.visible_message(span_notice("[departing_mob == user ? "Out of their own volition, " : "Ushered by [user], "][departing_mob] crosses the border and departs the swamps."))
	departing_mob.despawn()


/turf/closed/indestructible/f13/obsidian //Just like that one game studio that worked on the original game, or that block in Minecraft!
	name = "obsidian"
	desc = "No matter what you do with this rock, there's not even a scratch left on its surface.<br><font color='#7e0707'>You shall not pass!!!</font>"
	icon = 'icons/turf/mining_f13.dmi'
	icon_state = "rock1"

/turf/closed/indestructible/f13/obsidian/New()
	..()
	icon_state = "rock[rand(1,6)]"

/turf/closed/indestructible/f13/harshrock //Just like that one game studio that worked on the original game, or that block in Minecraft!
	name = "cliff"
	desc = "Harsh desert rock tempered by the scorching wasteland."
	icon = 'icons/turf/mining_f13.dmi'
	icon_state = "harshrock"
	layer = EDGED_TURF_LAYER

/turf/closed/indestructible/f13/vaultwall
	name = "vault wall"
	desc = "No matter what you do with this rock, there's not even a scratch left on its surface.<br><font color='#7e0707'>You shall not pass!!!</font>"
	icon = 'icons/turf/walls/f13superstore.dmi'
	icon_state = "supermart"
	icon_type_smooth = "supermart"
	// plane = GAME_PLANE
	// layer = LATTICE_LAYER
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/turf/closed/indestructible/f13/vaultwall)
	plane = GAME_PLANE

/turf/closed/indestructible/f13/vaultwall/notvaultwall
	name = "wall"
	canSmoothWith = list(/turf/closed/wall/f13/supermart, /turf/closed/wall/mineral/concrete, /turf/closed/wall, /turf/closed/wall/mineral/concrete/blastproof, /turf/closed/wall/mineral/concrete/blastproof/moresmooth, /turf/closed/wall/mineral/concrete/blastproof/storewall, /turf/closed/indestructible/f13/supermart, /obj/structure/falsewall/concrete, /turf/closed/indestructible/f13/vaultwall/notvaultwall, /turf/closed/indestructible/f13/vaultwall, /turf/closed/indestructible/f13/supermart)


/turf/closed/indestructible/f13/supermart
	name = "concrete wall"
	desc = "No matter what you do with this rock, there's not even a scratch left on its surface.<br><font color='#7e0707'>You shall not pass!!!</font>"
	icon = 'icons/turf/walls/f13superstore.dmi'
	icon_state = "supermart"
	icon_type_smooth = "supermart"
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/turf/closed/indestructible/f13/vaultwall, /turf/closed/wall/mineral/concrete, /turf/closed/indestructible/f13/supermart)

/turf/closed/indestructible/f13/vaultwall/fakeshutter
	name = "shutter"
	icon = 'icons/obj/doors/shutters.dmi'
	icon_state = "closed"
	smooth = SMOOTH_FALSE

//Splashscreen
/*
/turf/closed/indestructible/f13/splashscreen
	var/tickerPeriod = 300 //in deciseconds
	var/go/fullDark

turf/closed/indestructible/f13/splashscreen/New()
	.=..()
	name = "Fallout 13"
	desc = "The wasteland is calling!"
	icon = 'icons/misc/lobby.dmi'
	icon_state = "title[rand(1,13)]"
	layer = 60
	plane = 1
	src.fullDark = new/go{
		icon = 'icons/misc/lobby.dmi' //Replace with actual icon
		icon_state = "transition" //Replace with actual darkness state
		layer = 61;
		alpha = 0;
		}(src)
	src.fullDark.plane = 1
	spawn() src.ticker()
	return

turf/closed/indestructible/f13/splashscreen/proc/ticker()
	while(src && istype(src,/turf/closed/indestructible/f13/splashscreen))
		src.swapImage()
		sleep(src.tickerPeriod)
	to_chat(world, "Badmins spawn shit and the title screen was deleted.<br>You know... I'm out of here!")
	return

//Change the time to determine how short/long the fading animation is.
//Change the easing to determine what interpolation it uses to change the value on a curve: good ones to try are CUBIC, BOUNCE, and ELASTIC as well as CIRCULAR. BOUNCE and ELASTIC both "bounce" or "flicker" a little bit at the end instead of just finishing straight at black.

/turf/closed/indestructible/f13/splashscreen/proc/swapImage()
	animate(src.fullDark,alpha=255,time=10,easing=CUBIC_EASING)
	sleep(12) //buffer of about 1/5 of the time of the animation, since they are not synchronized: the sleep happens on the server, but the animation is played for each client using directX. It's good to leave a buffer, but most of the time the directX will be much faster than the server anyway so you probably wont have any problems.
	src.icon_state = "title[rand(1,13)]"
	animate(src.fullDark,alpha=0,time=10,easing=CUBIC_EASING)
	return
*/


// ==================== Merged from fallout (code\modules\fallout\eris\code\walls.dm) ====================
/turf/closed/wall/f13/coyote/darkwoodwall
	name = "darkwood wall"
	desc = "A wall made out of darkwood."
	icon = 'icons/turf/walls__port.dmi'
	icon_state = "nordic0"
	icon_type_smooth = "nordic"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/coyote/darkwoodwall, /turf/closed/wall)

/turf/closed/wall/f13/coyote/fortress_brick
	name = "fortress brickwall"
	desc = "An old wall you'd see at a fortress."
	icon = 'icons/turf/walls__port.dmi'
	icon_state = "fortress_brickwall0"
	icon_type_smooth = "fortress_brickwall"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/coyote/fortress_brick, /turf/closed/wall)


/turf/closed/wall/f13/coyote/tavern_wall
	name = "tavern wall"
	desc = "A wall in a tavern style."
	icon = 'icons/turf/walls__port.dmi'
	icon_state = "abashiri0"
	icon_type_smooth = "abashiri"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/coyote/tavern_wall, /obj/structure/window/fulltile/wood, /turf/closed/wall)

/turf/closed/wall/f13/coyote/oldwood
	name = "old wood wall"
	desc = "A wall of very old and rotting wood."
	icon = 'icons/turf/walls__port.dmi'
	icon_state = "oldwood0"
	icon_type_smooth = "oldwood"
	hardness = 80
	smooth = SMOOTH_OLD
	girder_type = 0
	sheet_type = null
	canSmoothWith = list(/turf/closed/wall/f13/coyote/oldwood, /turf/closed/wall)


// ==================== Merged from fallout (turf/wall_damage.dm) ====================
//Fallout 13 wall destruction simulation

/turf/closed/wall
	var/damage = 0
	var/damage_overlay = 0
	var/global/damage_overlays[16]
	var/unbreakable = 1

/turf/closed/wall/proc/take_damage(dam)
	if(dam)
		damage = max(0, damage + dam)
		update_icon()
	if(damage > hardness)
		dismantle_wall(1)
		playsound(src, 'sound/effects/meteorimpact.ogg', rand(50,100), 1)
		return 1
	return 0

/turf/closed/wall/proc/update_damage_overlay()
	if(damage != 0)

		var/overlay = round(damage / hardness * damage_overlays.len) + 1
		if(overlay > damage_overlays.len)
			overlay = damage_overlays.len

		overlays += damage_overlays[overlay]

/turf/closed/wall/proc/generate_overlays()
	var/alpha_inc = 256 / damage_overlays.len

	for(var/i = 1; i <= damage_overlays.len; i++)
		var/image/img = image(icon = 'icons/turf/walls_overlay.dmi', icon_state = "overlay_damage")
		img.blend_mode = BLEND_MULTIPLY
		img.alpha = (i * alpha_inc) - 1
		damage_overlays[i] = img

/turf/closed/wall/attackby(obj/item/W, mob/user, params)
	var/holdHardness = initial(hardness) || 70	 // Holds wall hardness before anything changes the src, defaults to 70
	var/holdUnbreakable = 0
	if(istype(src, /turf/closed/wall))
		holdUnbreakable = unbreakable	 // Holds wall unbreakable state before anything changes the src.
	. = ..()
	if(!.)
		user.do_attack_animation(src)
		if(istype(W, /obj/item/pickaxe)) //stops pickaxes from running needless attack checks on our baseturf
			return	
		if(SEND_SIGNAL(W, COMSIG_LICK_RETURN, src, user)) // so I can lick walls like a frickin frick
			return
		if(W.force > holdHardness/3 && !holdUnbreakable)
			//take_damage(W.force * 0.1)
			to_chat(user, span_warning("You smash the wall with [W]."))
			playsound(src, 'sound/effects/bang.ogg', 50, 1)
		else
			to_chat(user, span_notice("You hit the wall with [W] to no effect."))
			playsound(src, 'sound/weapons/Genhit.ogg', 25, 1)

// code/modules/f13/faction_territory.dm
// Map objects for faction control gameplay loops.

/obj/machinery/f13/faction_capture_node
	name = "district relay node"
	desc = "Use this to claim a district for your faction and link a nearby resource pad."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE

	/// Optional explicit district id. If null, area.grid_district is used.
	var/district_id = null
	/// Range to count nearby faction presence.
	var/capture_range = 6
	/// Faction currently progressing capture.
	var/progress_faction = null
	/// Current progress toward capture.
	var/progress = 0
	/// Points needed to capture.
	var/capture_threshold = 100
	/// Resource pad scan distance.
	var/pad_scan_range = 10
	/// Linked resource pad for this relay.
	var/obj/machinery/f13/faction_resource_pad/linked_resource_pad = null
	/// last successful link timestamp (world.time)
	var/last_link_time = 0

/obj/machinery/f13/faction_capture_node/Initialize()
	. = ..()
	// Relay capture is manual-by-click for a simple, predictable control loop.

/obj/machinery/f13/faction_capture_node/Destroy()
	return ..()

/obj/machinery/f13/faction_capture_node/proc/get_district()
	if(istext(district_id) && length(district_id))
		return district_id
	if(SSfaction_control)
		return SSfaction_control.get_district_for_atom(src)
	return null

/obj/machinery/f13/faction_capture_node/proc/ensure_district()
	if(!SSfaction_control) return null
	var/d = get_district()
	if(istext(d) && length(d))
		SSfaction_control.ensure_district(d)
		return d
	district_id = SSfaction_control.create_dynamic_district()
	return district_id

/obj/machinery/f13/faction_capture_node/proc/scan_and_link_resource_pad(mob/user)
	if(!SSfaction_control || !user) return FALSE
	var/faction = SSfaction_control.get_mob_faction(user)
	if(!faction || !SSfaction_control.is_controllable_faction(faction))
		to_chat(user, span_warning("Only BOS, NCR, Legion, and Town can operate relay nodes."))
		return FALSE

	var/district = ensure_district()
	if(!district)
		to_chat(user, span_warning("This relay has no valid district id."))
		return FALSE
	var/current_owner = SSfaction_control.get_owner(district)
	if(current_owner != faction)
		to_chat(user, span_warning("Claim this district for your faction before linking a resource pad."))
		return FALSE

	var/obj/machinery/f13/faction_resource_pad/best = null
	var/best_dist = 99999
	for(var/obj/machinery/f13/faction_resource_pad/P in range(pad_scan_range, src))
		if(!P || QDELETED(P)) continue
		var/d = get_dist(src, P)
		if(d < best_dist)
			best = P
			best_dist = d
	if(!best)
		to_chat(user, span_warning("No faction resource pad found within [pad_scan_range] tiles."))
		return FALSE

	linked_resource_pad = best
	best.linked_node = src
	best.active_from_node = TRUE
	best.district_id = district
	// Prime first production quickly after linking so setup feels responsive.
	best.next_production = min(best.next_production, world.time + 10 SECONDS)
	last_link_time = world.time
	to_chat(user, span_notice("Relay linked to [best] ([best_dist] tiles). Resource production is now enabled."))
	return TRUE

/obj/machinery/f13/faction_capture_node/proc/process_capture_tick()
	if(!SSfaction_control) return
	var/district = get_district()
	if(!district) return

	var/list/presence = list()
	for(var/mob/living/M in range(capture_range, src))
		if(M.stat) continue
		var/f = SSfaction_control.get_mob_faction(M)
		if(!f) continue
		if(!SSfaction_control.can_faction_capture(district, f))
			continue
		presence[f] += 1

	if(!length(presence))
		progress = max(0, progress - FACTION_CTRL_CAPTURE_DECAY)
		return

	var/top_faction = null
	var/top_count = 0
	var/tied = FALSE
	for(var/faction in presence)
		var/count = presence[faction]
		if(count > top_count)
			top_count = count
			top_faction = faction
			tied = FALSE
		else if(count == top_count)
			tied = TRUE

	if(tied || !top_faction)
		progress = max(0, progress - FACTION_CTRL_CAPTURE_DECAY)
		return

	var/current_owner = SSfaction_control.get_owner(district)
	if(current_owner == top_faction)
		progress_faction = null
		progress = 0
		return

	if(progress_faction != top_faction)
		progress_faction = top_faction
		progress = 0

	if(!SSfaction_control.can_faction_capture(district, top_faction))
		progress = max(0, progress - FACTION_CTRL_BANNED_CAPTURE_DECAY)
		return

	progress += (FACTION_CTRL_CAPTURE_GAIN + max(0, top_count - 1))
	if(progress < capture_threshold)
		return

	progress = 0
	progress_faction = null
	SSfaction_control.set_owner(district, top_faction, null)

/obj/machinery/f13/faction_capture_node/examine(mob/user)
	. = ..()
	if(!SSfaction_control) return
	var/d = get_district()
	var/o = SSfaction_control.get_owner(d)
	to_chat(user, span_notice("District: [d ? d : "Unassigned"] | Owner: [o ? o : "Unclaimed"]"))
	to_chat(user, span_notice("Use: Click relay -> 'Claim District' or 'Scan Resource Pad'."))
	to_chat(user, span_notice("Pad scan radius: [pad_scan_range] tiles."))
	if(linked_resource_pad && !QDELETED(linked_resource_pad))
		to_chat(user, span_notice("Linked pad: [linked_resource_pad]"))
		if(last_link_time)
			to_chat(user, span_notice("Linked [round((world.time - last_link_time) / 10)]s ago."))
	if(progress_faction)
		to_chat(user, span_notice("Capture pressure: [progress_faction] [round(progress)]/[capture_threshold]"))

/obj/machinery/f13/faction_capture_node/attack_hand(mob/user)
	if(!SSfaction_control || !user) return
	var/faction = SSfaction_control.get_mob_faction(user)
	if(!faction || !SSfaction_control.is_controllable_faction(faction))
		to_chat(user, span_warning("Only BOS, NCR, Legion, and Town can operate relay nodes."))
		return

	var/choice = alert(user, "Relay controls", "District Relay Node", "Claim District", "Scan Resource Pad", "Cancel")
	if(choice == "Claim District")
		var/d = ensure_district()
		if(!d)
			to_chat(user, span_warning("Failed to resolve district id for this relay."))
			return
		SSfaction_control.set_owner(d, faction, user)
		if(linked_resource_pad && !QDELETED(linked_resource_pad))
			linked_resource_pad.district_id = d
		to_chat(user, span_notice("District [d] is now controlled by [faction]."))
		return
	if(choice == "Scan Resource Pad")
		scan_and_link_resource_pad(user)
		return


/obj/machinery/f13/faction_grid_override
	parent_type = /obj/machinery/f13/faction_locked
	name = "faction grid override panel"
	desc = "District-level power routing control. Requires Strategic Grid Override research."
	icon_state = "control_off"
	require_district_owner = TRUE
	required_research_unlock = "ops_strategic_override"
	/// Optional district override when area.grid_district is not mapped.
	var/district_id = null

/obj/machinery/f13/faction_grid_override/attack_hand(mob/user)
	if(!can_user_access(user))
		to_chat(user, span_warning(last_access_denial_reason ? last_access_denial_reason : "Access denied: district not controlled by your faction."))
		return
	to_chat(user, span_notice("District blackout controls were moved to reactor district load controllers. Coordinate with reactor operators for local power routing."))
	return


/obj/machinery/f13/faction_supply_beacon
	parent_type = /obj/machinery/f13/faction_locked
	name = "faction supply beacon"
	desc = "Calls a local supply drop for the district owner. Requires Supply Automation research."
	icon_state = "control_on"
	require_district_owner = TRUE
	required_research_unlock = "ops_supply_automation"
	/// Optional district override when area.grid_district is not mapped.
	var/district_id = null

/obj/machinery/f13/faction_supply_beacon/attack_hand(mob/user)
	if(SSfaction_control && !SSfaction_control.get_district_for_atom(src))
		to_chat(user, span_warning("No district configured for this beacon. Set area.grid_district or district_id."))
		return
	if(!can_user_access(user))
		to_chat(user, span_warning(last_access_denial_reason ? last_access_denial_reason : "Access denied: district not controlled by your faction."))
		return
	if(!SSfaction_control) return
	var/turf/T = get_turf(src)
	if(!T) return
	SSfaction_control.request_supply_drop(user, T, SSfaction_control.get_district_for_atom(src))

/obj/machinery/f13/faction_resource_pad
	parent_type = /obj/machinery/f13/faction_locked
	name = "faction resource pad"
	desc = "A district-owned pad that periodically manufactures field supplies."
	icon = 'icons/obj/machines/teleporter.dmi'
	icon_state = "tele-o"
	require_district_owner = TRUE

	/// Override district. If null, uses area.grid_district.
	var/district_id = null
	/// world.time when this pad can produce again.
	var/next_production = 0
	/// Human-readable status for debugging and admin checks.
	var/last_status = "offline - waiting for relay link"
	/// world.time of last successful production cycle.
	var/last_produced_at = 0
	/// Per-cycle outputs.
	var/metal_per_cycle = FACTION_CTRL_RESOURCE_METAL
	var/blackpowder_per_cycle = FACTION_CTRL_RESOURCE_BLACKPOWDER
	var/caps_per_cycle = FACTION_CTRL_RESOURCE_CAPS
	/// Resource pads stay disabled until a relay links and scans them.
	var/active_from_node = FALSE
	/// Relay node that activated this pad.
	var/obj/machinery/f13/faction_capture_node/linked_node = null

/obj/machinery/f13/faction_resource_pad/Initialize()
	. = ..()
	next_production = world.time + FACTION_CTRL_RESOURCE_EVERY
	if(SSfaction_control)
		SSfaction_control.register_resource_pad(src)

/obj/machinery/f13/faction_resource_pad/Destroy()
	if(SSfaction_control)
		SSfaction_control.unregister_resource_pad(src)
	return ..()

/obj/machinery/f13/faction_resource_pad/proc/get_district()
	if(istext(district_id) && length(district_id))
		return district_id
	if(linked_node && !QDELETED(linked_node))
		var/linked_d = linked_node.get_district()
		if(istext(linked_d) && length(linked_d))
			return linked_d
	if(SSfaction_control)
		return SSfaction_control.get_district_for_atom(src)
	return null

/obj/machinery/f13/faction_resource_pad/proc/process_resource_tick()
	if(!SSfaction_control) return
	if(!active_from_node)
		last_status = "offline - waiting for relay link"
		return
	if(!linked_node || QDELETED(linked_node))
		active_from_node = FALSE
		last_status = "offline - linked relay missing"
		return
	if(world.time < next_production)
		last_status = "standby - next cycle pending"
		return

	var/d = get_district()
	if(!d)
		last_status = "error - no district id"
		next_production = world.time + 30 SECONDS
		return

	var/owner = SSfaction_control.get_owner(d)
	if(!owner || !SSfaction_control.is_controllable_faction(owner))
		last_status = "idle - district unowned"
		next_production = world.time + 30 SECONDS
		return

	var/metal_mult = SSfaction_control.get_resource_output_mult(owner, d, "metal")
	var/powder_mult = SSfaction_control.get_resource_output_mult(owner, d, "blackpowder")
	var/caps_mult = SSfaction_control.get_resource_output_mult(owner, d, "caps")
	var/industry_lvl = SSfaction_control.get_upgrade_level(d, "industry")

	SSfaction_control.spawn_metal_bundle(src, max(0, round(metal_per_cycle * metal_mult)))
	SSfaction_control.spawn_blackpowder_bundle(src, max(0, round(blackpowder_per_cycle * powder_mult)))
	SSfaction_control.spawn_caps_bundle(src, max(0, round(caps_per_cycle * caps_mult)))
	if(SSfaction_control.has_research_unlock(owner, "ind_smelter_chain") && industry_lvl >= 2)
		var/plasteel_mult = SSfaction_control.get_resource_output_mult(owner, d, "plasteel")
		var/plasteel_amt = max(0, round((20 + (industry_lvl * 10)) * plasteel_mult))
		SSfaction_control.spawn_plasteel_bundle(src, plasteel_amt)
	if(SSfaction_control.has_research_unlock(owner, "ind_advanced_forges") && industry_lvl >= 3)
		var/titanium_mult = SSfaction_control.get_resource_output_mult(owner, d, "titanium")
		var/titanium_amt = max(0, round((14 + (industry_lvl * 8)) * titanium_mult))
		SSfaction_control.spawn_titanium_bundle(src, titanium_amt)
	SSfaction_control.spawn_security_ammo_bundle(src, owner, d, 0.75)
	SSfaction_control.spawn_rare_crafting_bundle(src, SSfaction_control.get_rare_chance_bonus(owner))

	next_production = world.time + FACTION_CTRL_RESOURCE_EVERY
	last_produced_at = world.time
	last_status = "online - resources dispensed"
	visible_message(span_notice("[src] hums and dispenses fresh supplies for [owner]."))

/obj/machinery/f13/faction_resource_pad/examine(mob/user)
	. = ..()
	var/d = get_district()
	if(!d || !SSfaction_control) return
	var/o = SSfaction_control.get_owner(d)
	var/remaining = max(0, round((next_production - world.time) / 10))
	to_chat(user, span_notice("District: [d] | Owner: [o ? o : "Unclaimed"]"))
	to_chat(user, span_notice("Activation: [active_from_node ? "ONLINE (linked to relay)" : "OFFLINE (use a relay scan)"]"))
	to_chat(user, span_notice("Status: [last_status]"))
	if(last_produced_at)
		to_chat(user, span_notice("Last production: [round((world.time - last_produced_at) / 10)]s ago."))
	to_chat(user, span_notice("Production base: [metal_per_cycle] metal, [blackpowder_per_cycle] blackpowder, [caps_per_cycle] caps every 10 minutes."))
	to_chat(user, span_notice("Industry upgrades increase output and can unlock plasteel/titanium with research."))
	to_chat(user, span_notice("Security upgrades add ammo production; doctrine research changes ammo type and tier."))
	to_chat(user, span_notice("Bonus loot: occasional rare crafting components."))
	to_chat(user, span_notice("Next cycle in [remaining] seconds."))


/obj/machinery/f13/faction_water_purifier
	name = "water rights purifier node"
	desc = "A capturable purifier node that feeds district water utilities."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE

	var/district_id = null
	var/owner_faction = null
	var/output_rate = FACTION_CTRL_WATER_NODE_OUTPUT
	/// share|taxed|restricted
	var/export_mode = "share"
	var/operational = TRUE

/obj/machinery/f13/faction_water_purifier/Initialize()
	. = ..()
	if(SSfaction_control)
		SSfaction_control.register_water_node(src)

/obj/machinery/f13/faction_water_purifier/Destroy()
	if(SSfaction_control)
		SSfaction_control.unregister_water_node(src)
	return ..()

/obj/machinery/f13/faction_water_purifier/proc/get_district()
	if(istext(district_id) && length(district_id))
		return district_id
	if(SSfaction_control)
		return SSfaction_control.get_district_for_atom(src)
	return null

/obj/machinery/f13/faction_water_purifier/examine(mob/user)
	. = ..()
	var/d = get_district()
	to_chat(user, span_notice("District: [d ? d : "Unmapped"]"))
	to_chat(user, span_notice("Owner: [owner_faction ? owner_faction : "Unclaimed"]"))
	to_chat(user, span_notice("Mode: [export_mode] | Output: [output_rate] | [operational ? "ONLINE" : "OFFLINE"]"))
	to_chat(user, span_notice("Modes: share = open network, taxed = open network + owner tax, restricted = owner-only routing."))

/obj/machinery/f13/faction_water_purifier/attack_hand(mob/user)
	if(!SSfaction_control || !user) return
	var/f = SSfaction_control.get_mob_faction(user)
	if(!f || !SSfaction_control.is_controllable_faction(f))
		to_chat(user, span_warning("Only BOS, NCR, Legion, and Town can operate water nodes."))
		return

	if(!owner_faction || owner_faction != f)
		owner_faction = f
		to_chat(user, span_notice("Water node claimed for [f]."))
		return

	var/list/options = list("Share", "Taxed", "Restricted", "Toggle Online", "Cancel")
	var/choice = input(user, "Water node controls", "Water Node") as null|anything in options
	switch(choice)
		if("Share")
			export_mode = "share"
			to_chat(user, span_notice("Water node set to shared routing."))
		if("Taxed")
			export_mode = "taxed"
			to_chat(user, span_notice("Water node set to taxed routing."))
		if("Restricted")
			export_mode = "restricted"
			to_chat(user, span_notice("Water node set to restricted routing."))
		if("Toggle Online")
			operational = !operational
			to_chat(user, span_notice("Water node [operational ? "online" : "offline"]."))


/obj/machinery/f13/faction_intel_tower
	name = "intel relay tower"
	desc = "Capturable signal node for reconnaissance and counter-intel actions."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_off"
	density = TRUE

	var/district_id = null
	var/owner_faction = null
	var/intel_rate = FACTION_CTRL_INTEL_PER_TOWER
	var/next_tick = 0

/obj/machinery/f13/faction_intel_tower/Initialize()
	. = ..()
	next_tick = world.time + 1 MINUTES
	if(SSfaction_control)
		SSfaction_control.register_intel_tower(src)

/obj/machinery/f13/faction_intel_tower/Destroy()
	if(SSfaction_control)
		SSfaction_control.unregister_intel_tower(src)
	return ..()

/obj/machinery/f13/faction_intel_tower/proc/get_district()
	if(istext(district_id) && length(district_id))
		return district_id
	if(SSfaction_control)
		return SSfaction_control.get_district_for_atom(src)
	return null

/obj/machinery/f13/faction_intel_tower/proc/process_intel_tick()
	if(!SSfaction_control) return
	if(world.time < next_tick) return
	next_tick = world.time + 1 MINUTES
	if(!owner_faction) return
	if(!SSfaction_control.is_controllable_faction(owner_faction)) return
	var/d = get_district()
	if(d)
		var/o = SSfaction_control.get_owner(d)
		if(o && o != owner_faction)
			return
	SSfaction_control.add_faction_intel_points(owner_faction, intel_rate)

/obj/machinery/f13/faction_intel_tower/examine(mob/user)
	. = ..()
	var/d = get_district()
	to_chat(user, span_notice("District: [d ? d : "Unmapped"]"))
	to_chat(user, span_notice("Owner: [owner_faction ? owner_faction : "Unclaimed"]"))
	if(owner_faction && SSfaction_control)
		to_chat(user, span_notice("Intel generation: +[intel_rate]/min (current [SSfaction_control.get_faction_intel_points(owner_faction)])."))

/obj/machinery/f13/faction_intel_tower/attack_hand(mob/user)
	if(!SSfaction_control || !user) return
	var/f = SSfaction_control.get_mob_faction(user)
	if(!f || !SSfaction_control.is_controllable_faction(f))
		to_chat(user, span_warning("Only BOS, NCR, Legion, and Town can operate intel towers."))
		return

	if(!owner_faction || owner_faction != f)
		owner_faction = f
		icon_state = "control_on"
		to_chat(user, span_notice("Intel tower captured for [f]."))
		return

	var/list/options = list("Scan Routes", "Jam District", "Fake Distress", "Cancel")
	var/choice = input(user, "Intel controls", "Intel Tower") as null|anything in options
	switch(choice)
		if("Scan Routes")
			SSfaction_control.intel_scan_routes(user)
		if("Jam District")
			var/list/choices = list()
			for(var/list/row in SSfaction_control.get_status_rows(f))
				var/d = row["district"]
				if(!d) continue
				if(row["owner"] == f) continue
				choices += d
			if(!length(choices))
				to_chat(user, span_warning("No enemy/unclaimed districts available to jam."))
				return
			var/target = input(user, "Choose district to jam", "Intel Jam") as null|anything in choices
			if(istext(target) && length(target))
				SSfaction_control.intel_jam_district(user, target)
		if("Fake Distress")
			var/list/choices2 = list()
			for(var/list/row2 in SSfaction_control.get_status_rows(f))
				var/d2 = row2["district"]
				if(!d2) continue
				if(row2["owner"] == f) continue
				choices2 += d2
			if(!length(choices2))
				to_chat(user, span_warning("No eligible districts for fake distress operations."))
				return
			var/target2 = input(user, "Choose district for fake distress operation", "Counter-Intel") as null|anything in choices2
			if(istext(target2) && length(target2))
				SSfaction_control.intel_fake_distress(user, target2)


/obj/machinery/f13/faction_hazard_extractor
	parent_type = /obj/machinery/f13/faction_locked
	name = "hazard extraction terminal"
	desc = "Runs rare-material extraction during active hazard windows."
	icon_state = "control_on"
	require_district_owner = TRUE
	required_research_unlock = "ops_hazard_extraction"
	var/district_id = null

/obj/machinery/f13/faction_hazard_extractor/attack_hand(mob/user)
	if(!can_user_access(user))
		to_chat(user, span_warning(last_access_denial_reason ? last_access_denial_reason : "Access denied."))
		return
	if(!SSfaction_control) return
	var/d = SSfaction_control.get_district_for_atom(src)
	var/turf/T = get_turf(src)
	if(!d || !T)
		to_chat(user, span_warning("Hazard extractor is not mapped to a valid district."))
		return
	SSfaction_control.extract_hazard_resources(user, d, T)


/obj/structure/f13/faction_district_buildable_marker
	name = "district doctrine structure"
	desc = "A faction doctrine deployment that modifies district operations."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE
	anchored = TRUE

	var/owner_faction = null
	var/district_id = null

/obj/structure/f13/faction_district_buildable_marker/proc/configure_from_data(new_name, new_desc, new_owner, new_district)
	if(istext(new_name) && length(new_name))
		name = new_name
	if(istext(new_desc) && length(new_desc))
		desc = new_desc
	owner_faction = new_owner
	district_id = new_district

/obj/structure/f13/faction_district_buildable_marker/examine(mob/user)
	. = ..()
	to_chat(user, span_notice("Faction: [owner_faction ? owner_faction : "Unknown"] | District: [district_id ? district_id : "Unmapped"]"))


/obj/structure/f13/faction_caravan_marker
	name = "faction supply convoy"
	desc = "A moving convoy carrying district cargo."
	icon = 'icons/obj/storage.dmi'
	icon_state = "crate"
	density = TRUE
	anchored = FALSE

	var/caravan_id = null
	var/faction = null
	var/from_district = null
	var/to_district = null
	var/list/cargo_manifest = null
	var/datum/weakref/target_turf_ref = null
	var/health = 160

/obj/structure/f13/faction_caravan_marker/proc/setup_route(new_id, new_faction, from_d, to_d, turf/target_turf, list/manifest)
	caravan_id = new_id
	faction = new_faction
	from_district = from_d
	to_district = to_d
	if(target_turf)
		target_turf_ref = WEAKREF(target_turf)
	if(islist(manifest))
		cargo_manifest = manifest.Copy()
	name = "[faction] convoy ([from_d] -> [to_d])"

/obj/structure/f13/faction_caravan_marker/examine(mob/user)
	. = ..()
	if(!cargo_manifest) return
	to_chat(user, span_notice("Manifest: metal [round(cargo_manifest["metal"])] | powder [round(cargo_manifest["blackpowder"])] | caps [round(cargo_manifest["caps"])]"))

/obj/structure/f13/faction_caravan_marker/attackby(obj/item/W, mob/user, params)
	..()
	if(!user || !SSfaction_control) return
	var/f = SSfaction_control.get_mob_faction(user)
	if(f == faction)
		to_chat(user, span_notice("You reinforce the convoy's formation."))
		return
	health -= rand(22, 40)
	visible_message(span_warning("[user] sabotages [src]!"))
	if(health <= 0)
		visible_message(span_warning("[src] is destroyed in an ambush!"))
		qdel(src)


/obj/machinery/f13/faction_turret_controller
	parent_type = /obj/machinery/f13/faction_locked
	name = "faction turret controller"
	desc = "Controls linked turret network for the district. Requires Turret Uplink Doctrine research."
	icon_state = "control_on"
	require_district_owner = TRUE
	required_research_unlock = "ops_turret_uplink"
	/// Optional district override when area.grid_district is not mapped.
	var/district_id = null

	var/link_range = 12
	var/list/linked_turrets = list()

/obj/machinery/f13/faction_turret_controller/proc/refresh_links()
	linked_turrets = list()
	for(var/obj/machinery/porta_turret/T in range(link_range, src))
		linked_turrets += T

/obj/machinery/f13/faction_turret_controller/proc/apply_network_state(force_on = TRUE)
	if(!SSfaction_control) return
	var/d = SSfaction_control.get_district_for_atom(src)
	var/owner = SSfaction_control.get_owner(d)
	if(!owner) return

	refresh_links()
	for(var/obj/machinery/porta_turret/T in linked_turrets)
		if(!T || QDELETED(T)) continue
		T.on = !!force_on
		// Keep turret-friendly list aligned with district owner.
		T.faction = list("turret", owner)
		if(hascall(T, "power_change"))
			call(T, "power_change")()
		if(hascall(T, "update_icon"))
			call(T, "update_icon")()

/obj/machinery/f13/faction_turret_controller/attack_hand(mob/user)
	if(SSfaction_control && !SSfaction_control.get_district_for_atom(src))
		to_chat(user, span_warning("No district configured for this controller. Set area.grid_district or district_id."))
		return
	if(!can_user_access(user))
		to_chat(user, span_warning(last_access_denial_reason ? last_access_denial_reason : "Access denied: district not controlled by your faction."))
		return

	refresh_links()
	var/d = SSfaction_control ? SSfaction_control.get_district_for_atom(src) : "Unknown"
	var/owner = SSfaction_control ? SSfaction_control.get_owner(d) : null
	var/msg = "District: [d]\nOwner: [owner ? owner : "Unclaimed"]\nLinked turrets: [length(linked_turrets)]"
	var/choice = alert(user, msg, "Turret Controller", "Activate", "Disable", "Cancel")
	switch(choice)
		if("Activate")
			apply_network_state(TRUE)
		if("Disable")
			apply_network_state(FALSE)
	return


/obj/machinery/f13/faction_control_console
	parent_type = /obj/machinery/f13/faction_locked
	name = "faction command console"
	desc = "Command console for district economy and control operations."
	icon_state = "control_on"
	require_district_owner = FALSE
	allowed_factions = list(FACTION_BROTHERHOOD, FACTION_NCR, FACTION_LEGION, FACTION_EASTWOOD)

/obj/machinery/f13/faction_control_console/contracts
	name = "faction contracts board"
	desc = "Operations board for contracts, upgrades, events, caravans, and research."

/obj/machinery/f13/faction_control_console/logistics
	name = "faction logistics terminal"
	desc = "Terminal focused on caravans, supply routing, and district operations."

/obj/machinery/f13/faction_control_console/attack_hand(mob/user)
	. = ..()
	if(!can_user_access(user))
		to_chat(user, span_warning(last_access_denial_reason ? last_access_denial_reason : "Only BOS, NCR, Legion, and Town command can use this console."))
		return
	ui_interact(user, null)

/obj/machinery/f13/faction_control_console/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/f13/faction_control_console/ui_data(mob/user)
	if(!SSfaction_control)
		return list(
			"faction" = "None",
			"can_control" = FALSE,
			"funds" = 0,
			"supply_cost" = 0,
			"override_cost" = 0,
			"supply_cd" = 0,
			"supply_ready" = TRUE,
			"district_total" = 0,
			"district_owned" = 0,
			"income_owned" = 0,
			"rep" = 0,
			"research_points" = 0,
			"research_tier" = 0,
			"research_next_cost" = 0,
			"research_unlocked_count" = 0,
			"research_projects_total" = 0,
			"research_rows" = list(),
			"rows" = list(),
			"contracts" = list(),
			"upgrade_rows" = list(),
			"events" = list(),
			"caravans" = list(),
			"top_rep" = list(),
			"water_rows" = list(),
			"hazard_rows" = list(),
			"buildable_rows" = list(),
			"intel_points" = 0,
			"intel_reveal_s" = 0,
			"buildable_template_name" = "",
			"buildable_template_requires" = ""
		)
	return SSfaction_control.get_faction_dashboard(user)

/obj/machinery/f13/faction_control_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui?.user
	if(!user)
		user = usr
	if(!user || !can_user_access(user))
		return TRUE

	switch(action)
		if("override_blackout")
			var/d = params["district"]
			if(istext(d) && length(d))
				SSfaction_control.request_grid_override(user, d, "blackout")
			return TRUE
		if("override_restore")
			var/d2 = params["district"]
			if(istext(d2) && length(d2))
				SSfaction_control.request_grid_override(user, d2, "restore")
			return TRUE
		if("supply_drop")
			var/d3 = params["district"]
			var/turf/T = get_turf(src)
			if(T && istext(d3) && length(d3))
				SSfaction_control.request_supply_drop(user, T, d3)
			return TRUE
		if("turnin_contract")
			var/cid = params["id"]
			if(istext(cid) && length(cid))
				SSfaction_control.turn_in_contract(user, cid)
			return TRUE
		if("buy_upgrade")
			var/d4 = params["district"]
			var/k = params["kind"]
			if(istext(d4) && length(d4) && istext(k) && length(k))
				SSfaction_control.buy_district_upgrade(user, d4, k)
			return TRUE
		if("start_caravan")
			var/from_d = params["district"]
			if(istext(from_d) && length(from_d))
				SSfaction_control.start_caravan(user, from_d)
			return TRUE
		if("unlock_research")
			SSfaction_control.unlock_next_research(user)
			return TRUE
		if("unlock_research_project")
			var/pid = params["id"]
			if(istext(pid) && length(pid))
				SSfaction_control.unlock_research_project(user, pid)
			return TRUE
		if("intel_reveal_routes")
			SSfaction_control.intel_scan_routes(user)
			return TRUE
		if("intel_jam_district")
			var/d5 = params["district"]
			if(istext(d5) && length(d5))
				SSfaction_control.intel_jam_district(user, d5)
			return TRUE
		if("intel_fake_distress")
			var/d6 = params["district"]
			if(istext(d6) && length(d6))
				SSfaction_control.intel_fake_distress(user, d6)
			return TRUE
		if("hazard_extract")
			var/d7 = params["district"]
			var/turf/T2 = null
			if(istext(d7) && length(d7))
				T2 = SSfaction_control.get_anchor_turf_for_district(d7)
				if(!T2)
					T2 = get_turf(src)
			if(T2 && istext(d7) && length(d7))
				SSfaction_control.extract_hazard_resources(user, d7, T2)
			return TRUE
		if("deploy_buildable")
			var/d8 = params["district"]
			var/turf/T3 = null
			if(istext(d8) && length(d8))
				T3 = SSfaction_control.get_anchor_turf_for_district(d8)
				if(!T3)
					T3 = get_turf(src)
			if(T3 && istext(d8) && length(d8))
				SSfaction_control.deploy_doctrine_buildable(user, d8, T3)
			return TRUE

	return FALSE

/obj/machinery/f13/faction_control_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FactionControl")
		ui.open()

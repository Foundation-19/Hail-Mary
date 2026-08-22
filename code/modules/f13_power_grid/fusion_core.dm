// ============================================================
// FUSION CORE — Item
// ============================================================

/obj/item/f13/fusion_core
	name = "fusion core"
	desc = "A high-density energy cell used to power advanced machinery and faction base generators. Insert it into a generator to restore base power."
	icon = 'icons/fallout/objects/power_grid/fusion_core.dmi'
	icon_state = "fusion_core"
	w_class = WEIGHT_CLASS_SMALL
	/// Whether this core is spent; depleted cores do not power generators.
	var/depleted = FALSE

/obj/item/f13/fusion_core/examine(mob/user)
	. = ..()
	. += depleted ? span_warning("The power cell indicator is dark — this core is spent.") : span_notice("The power cell indicator glows a steady blue.")

// ── Depleted variant — produced when a generator fully consumes a core.
/obj/item/f13/fusion_core/depleted
	name = "depleted fusion core"
	desc = "A spent fusion core casing. The housing is intact; a core fabricator can recycle it into a fresh core at reduced material cost."
	icon_state = "fusion_core-dead"
	depleted = TRUE


// ============================================================
// ATOMIC FUEL CELL
// ============================================================
// Used by /obj/machinery/f13/faction_generator/atomic.
/obj/item/f13/atomic_cell
	name = "atomic fuel cell"
	desc = "A Poseidon Energy POS-7R atomic fuel cell: a shielded alloy rod packed with refined fissile material. Poseidon's safety record was not exactly stellar, but this thing puts out more power than a dozen diesel tanks. Handle with care."
	icon = 'icons/fallout/objects/power_grid/atomic_cell.dmi'
	icon_state = "fusion_core"
	w_class = WEIGHT_CLASS_SMALL

// Returned when an atomic generator's fuel is ejected or fully consumed.
/obj/item/f13/atomic_cell/depleted
	name = "depleted atomic fuel cell"
	desc = "A burned-out Poseidon Energy atomic fuel cell. Exhausted, but the radiation shielding remains intact — for now. Deep waste disposal recommended; casual littering is not advised."
	icon_state = "fusion_core-dead"

/obj/item/f13/atomic_cell/depleted/Initialize()
	. = ..()
	// Residual radiation from the spent cell — brief low-level pulse on the tile it lands on.
	radiation_pulse(src, 15, 1)


// ============================================================
// GENERATOR SECURITY MODULE — Lock upgrade item
// ============================================================
// Applied to a wasteland/jury-rigged generator to install access control.
// Requires electronics knowledge: use a screwdriver to fit the module into
// the generator's control panel.

/obj/item/f13/security_module
	name = "RobCo security module"
	desc = "A pre-War RobCo Industries access-control board pulled from a terminal casing. Hard-wire it into a generator's control panel with a screwdriver to add personal or faction ID-lock capability. Not exactly plug-and-play."
	icon = 'icons/fallout/objects/power_grid/fusion_core.dmi'
	icon_state = "fusion_core-dead"
	w_class = WEIGHT_CLASS_SMALL

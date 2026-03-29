// ============================================================
// FUSION CORE — Item
// ============================================================

/obj/item/f13/fusion_core
	name = "fusion core"
	desc = "A high-density energy cell used to power advanced machinery and faction base generators. Insert it into a generator to restore base power."
	icon = 'icons/fallout/objects/powercells.dmi'
	icon_state = "mfc-full"
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
	icon_state = "mfc-empty"
	depleted = TRUE

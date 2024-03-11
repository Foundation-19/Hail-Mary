/mob/living
	var/holdup_targeting = FALSE

TYPE_PROC_REF(/mob/living, holdup_activate)()
	//activates/deactivates holding up people when clicked
	if(holdup_targeting)
		holdup_targeting=FALSE
	else
		holdup_targeting=TRUE

TYPE_PROC_REF(/mob/living, holdup_action)(mob/living/target)
//targets the clicked target and aims a gun at them

TYPE_PROC_REF(/mob/living, holdup_message)(mob/living/target)
//messages the target that they are being held up in fat text

TYPE_PROC_REF(/mob/living, holdup_fire_at)(mob/living/target)
//fires a projectile at the target if they move

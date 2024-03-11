/mob/living/silicon/Moved(oldLoc, dir)
	. = ..()
	update_camera_location(oldLoc)

/mob/living/silicon/forceMove(atom/destination)
	. = ..()
	//Only bother updating the camera if we actually managed to move
	if(.)
		update_camera_location(destination)

TYPE_PROC_REF(/mob/living/silicon, do_camera_update)(oldLoc)
	if(!QDELETED(builtInCamera) && oldLoc != get_turf(src))
		GLOB.cameranet.updatePortableCamera(builtInCamera)
	updating = FALSE

#define SILICON_CAMERA_BUFFER 10
TYPE_PROC_REF(/mob/living/silicon, update_camera_location)(oldLoc)
	oldLoc = get_turf(oldLoc)
	if(!QDELETED(builtInCamera) && !updating && oldLoc != get_turf(src))
		updating = TRUE
		addtimer(CALLBACK(src, PROC_REF(do_camera_update), oldLoc), SILICON_CAMERA_BUFFER)
#undef SILICON_CAMERA_BUFFER

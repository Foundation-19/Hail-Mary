//#define LOWMEMORYMODE //uncomment this to load centcom and runtime station and thats it.

#include "map_files\generic\CentCom.dmm"

#ifndef LOWMEMORYMODE
	#ifdef ALL_MAPS
		#include "map_files/Baltimore/baltimore_surface.dmm"
		#include "map_files/Baltimore/baltimore_upperlevel.dmm"
		#include "map_files/Baltimore/baltimore_underground.dmm"
		#ifdef TRAVISBUILDING
			#include "templates.dm"
		#endif
	#endif
#endif

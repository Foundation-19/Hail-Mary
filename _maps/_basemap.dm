//#define LOWMEMORYMODE //uncomment this to load centcom and runtime station and thats it.

#include "map_files\generic\CentCom.dmm"

#ifndef LOWMEMORYMODE
	#ifdef ALL_MAPS
		#include "map_files/Pahrump-AB/Dungeons.dmm"
		#include "map_files/Pahrump-AB/Pahrump-AB-Lower.dmm"
		#include "map_files/Pahrump-AB/Pahrump-AB.dmm"
		#include "map_files/Pahrump-AB/Pahrump-AB-Upper.dmm"
		#ifdef TRAVISBUILDING
			#include "templates.dm"
		#endif
	#endif
#endif

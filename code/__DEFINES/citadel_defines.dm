//Global defines for most of the unmentionables.
//Be sure to update the min/max of these if you do change them.
//Measurements are in imperial units. Inches, feet, yards, miles. Tsp, tbsp, cups, quarts, gallons, etc

#define CIT_FILTER_STAMINACRIT filter(type="drop_shadow", x=0, y=0, size=-3, color="#04080F")

//Individual logging define
#define INDIVIDUAL_LOOC_LOG "LOOC log"

#define ADMIN_MARKREAD(client) "(<a href='?_src_=holder;markedread=\ref[client]'>MARK READ</a>)"//marks an adminhelp as read and under investigation
#define ADMIN_IC(client) "(<a href='?_src_=holder;icissue=\ref[client]'>IC</a>)"//marks and adminhelp as an IC issue
#define ADMIN_REJECT(client) "(<a href='?_src_=holder;rejectadminhelp=\ref[client]'>REJT</a>)"//Rejects an adminhelp for being unclear or otherwise unhelpful. resets their adminhelp timer

#define CITADEL_MENTOR_OOC_COLOUR "#224724"

//xenobio console upgrade stuff
#define XENOBIO_UPGRADE_MONKEYS				1
#define XENOBIO_UPGRADE_SLIMEBASIC			2
#define XENOBIO_UPGRADE_SLIMEADV			4


//icon states for the default eyes and for a state for no eye
#define DEFAULT_EYES_TYPE			"normal"
#define DEFAULT_LEFT_EYE_STATE		"normal_left_eye"
#define DEFAULT_RIGHT_EYE_STATE		"normal_right_eye"
#define DEFAULT_NO_EYE_STATE		"no_eye"

//special species definitions
#define MINIMUM_MUTANT_COLOR	"#202020" //this is how dark players mutant parts and skin can be

//defines for different matrix sections
#define MATRIX_RED			"red"
#define MATRIX_GREEN		"green"
#define MATRIX_BLUE			"blue"
#define MATRIX_RED_GREEN	"red_green"
#define MATRIX_RED_BLUE		"red_blue"
#define MATRIX_GREEN_BLUE	"green_blue"
#define MATRIX_ALL			"red_green_blue"
#define MATRIX_NONE			"none"

//defines for the two colour schemes, advanced and old
#define OLD_CHARACTER_COLORING			"old_color_system"
#define ADVANCED_CHARACTER_COLORING		"advanced_color_system"


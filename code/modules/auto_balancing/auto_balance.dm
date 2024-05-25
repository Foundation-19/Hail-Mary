#define AUTO_BALANCING_DISABLED 0
#define AUTO_BALANCING_ENABLED 1

proc/AB_ModeToText(var/mode)
	switch(mode)
		if(AUTO_BALANCING_DISABLED)
			return "Disabled"
		if(AUTO_BALANCING_ENABLED)
			return "Enabled"

/datum/admins/proc/AB_ToggleState()

	set name = "Auto Balancing - Toggle Mode"
	set category = "Admin.Game"
	set desc="Enables or disables faction auto balancing"

	var/AutoBalanceMode = CONFIG_GET(number/auto_balancing)

	var/choice = input("New State (Current state is: [AB_ModeToText(AutoBalanceMode)])", "Faction Auto Balancing State") as null|anything in list("Disabled", "Enabled")

	switch(choice)
		if("Disabled")
			if(AutoBalanceMode != AUTO_BALANCING_DISABLED)
				AutoBalanceMode = AUTO_BALANCING_DISABLED
				log_and_message_admins("has disabled faction auto balancing.")
		if("Enabled")
			if(AutoBalanceMode != AUTO_BALANCING_ENABLED)
				AutoBalanceMode = AUTO_BALANCING_ENABLED
				log_and_message_admins("has enabled faction auto balancing.")

	CONFIG_SET(number/auto_balancing, AutoBalanceMode)

	return

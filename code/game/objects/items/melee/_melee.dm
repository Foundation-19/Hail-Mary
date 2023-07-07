//Strength buff. Written by Kitsunemitsu
/obj/item/attack(mob/living/target, mob/living/carbon/user)
	var/forceholder = force
	force += (user.special_s * 2 - 10)	//You're going up and down by 10 force per hit
	..()
	force = forceholder

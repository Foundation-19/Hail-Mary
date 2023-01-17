# Blacksmithing Fallout Edition v.1.4
## Who made this module?
Pebbles the 2nd. Credits at the end.

## What is this module?
Ancient TG smithing code remodeled, new art, lot of new code and concepts. Now called Blacksmithing to differentiate it, and to avoid mixing with the mutated alpha stuff floating around. Changelog at the end.

Core principles:
- Ingame documentation, not code diving (advice book, new description system)
- Visual/audio feedback and mood important
- Files sorted and defines used
- All items should be useful in some way, trade offs, gimmicks added
- Recipes organized so similar sorts of items use similar recipes (the more cutting, the more folds etc)
- EVERYTHING must have icons AND inhands. No more terrible sword pikes.
- As little reliant on outdated external stuff as possible. So no Ratvar, Narsie stuff.
- Reduced duplication and redundancy. Forging should be made on a anvil.

## Is it complete?
Sort of. It works, but the following was planned, before time and heart ran out.

- Radial menus instead of the pop up menus
- Adding more gimmicks, mood modifiers, etc
- Balancing (depends on the codebase since armor and competition varies in the extreme, pretty damn obvious. Try adjusting in increments instead of doubling values on the fly.)
- Perfecting sizing (standardized icon sizes, partway there but not all the way)
- Quenching affecting quality (intended 3 ways, air cooled, maybe 30s timer, -1, water temper normal, oil temper +1)
- X and Y offsets dynamic so the long items (spears etc) can have the workpiece centered then moved to the finished position once dofinish is done
- Replacing forge mittens with tongs (having both useful would be optimal)

If you plan on adding or changing stuff ADD changelog to the end of this readme. Adjust damage by changing the define values first, not by messing with the formulas, for obvious reasons.

## Whats new?
So much its hard to list
Item quality much less impactful (this just means low quality items arent completely useless)

Light & Sound: Whole bunch of overlays, lighting, sounds added to all steps of the process

Steps: Heat ingot, place on anvil, hammer it, quench it, add finisher, done.

Repathing: Items in the module mostly shifted to root /blacksmith in the path for easier mapping and finding them in the gamepanel for admins. They are part of the same system and its good they are easy to find.

Forge mittens are sort of a stand-in for tongs, its what you use for touching hot metal, not any flimsy glove.

Basic idea with the belt slot/back slot for weapons is that it makes sheath objects redundant, just make the correct slots for the item.

Various effects added: Crusher harming ghoul mobs, axes extra damage to barricades, dagger eyestab (relies on the inheritance of eyecover objects to NOT be FUBAR to work well.), use of defines

## Known issues

The anvil refactor Gremling did solve some issues but sadly seems to have had some side-effects, the elusive overlay not being cut properly on live servers being the main one. I am not able to replicate the issue offline and so cannot see any solution to it currently.
(when a workpiece is finished sometimes the overlay remains on the anvil, and occasionally the same happens when quenching.)
Armor pieces made from smithing are not affected by quality and material currently. This is WAD but a bit crude.
Some tools do not inherit the force calculated on quality correctly, notes in finished items about this.

## Some facts about the Blacksmith system

* TG wikis will not help you very much, its been totally overhauled, even if the same framework is used. The Forgemasters Primer was written to replace the need for out of game guides.
* Materials do affect the end product in exactly the same way as in the old system, the difference here is the space replicant alloyed bronze has been replaced by "real" bronze so is no longer stronger than iron. This means for most weapons a maximum 10% boost in the raw force, or 20% using the non existent pre-war steel ingot. This has been true since day 1 of the beta, and anyone claiming otherwise is incorrect.
* Quality of hammer, and anvil, and the level of blacksmithing the user has all play a part in the final product quality, that in turn affects the base force and sometimes AP or other attributes such as pickaxe speed.
* End product stats are based on the finished_items.dm values, with material/qualitiy modifiers on top, so expect rapidly compounding values if you make big changes to the base stats, at least for wielded items which have various multipliers.


## Credits

I wish to be clear. this module is my work, and it is a total rework of the entire old TG smithing systen, adding many features such as sound, sparks, text feedback, use of overlays, light system, etc, and replacing every asset. The visually similar system floating around on some servers that lack this module are based on my old beta stuff, they are incomplete and I can't really guarantee anything about them. All the designs are mine, the primer, mittens, so on, the concepts, mechanics, and assets (code copy paste with edits tho) used to make leather strips, to make wooden rods from planks, to make chains, the smithed armor, the plates, ad nauseum. It could not exist without the base TG smithing code however, I am not a coder, I do design and art, and edit/adapt existing code, so if you want to give the coder people props look below. For getting to finish it uninterrupted I'd like to thank Raptor and Lamasmaster.

The base TG smithing code is still very much the core, made by lolman in 2019.
GremlingSS refactored the code in anvil.dm in 2022, wich was adapted and then used for this module.

Sounds: A few edited base FO13 ones, but the anvil sounds were made by me, they are from royalty free sampling from videvo.net edited a lot in Audacity.

Sprites: (basically I made all the art, TLDR) furnace, sandstone furnace, chain, leatherstrip, dagger, machete, gladius, macheter, waki, saw, sabre, sword, spatha, katana, spear, lance, trident, crusher, mace, univeral tool, axe, waraxe, scrapblade, javelin, bola, knife, hammer, sledgehammer, shovel, pickaxe, prospect, crowbar, ball and chain, ingot, anvil, tablevil, sandvil, overlays, blacksmith mittens, armor pieces, smithed armor, quenching through, metalworking bench - Pebbles the 2nd
(Waraxe is based on the Warhoned axe by Raptor, wich in turn was based on my fireaxe art but with a twist.)
sabre hilt, bowie blade, longsword(scraptana), ring, bola reuses a fair bit from legacy sprites, so inspiration credit to their makers which sadly is not known to me. The anvil outline loans heavily from the old one but the sprite is new.

Since I'll not be around to maintain this forever feel free to edit for fixing issues I might have missed or whatever but please keep it documented and not shitty, thanks.
- Pebbles the 2nd


## Changelog

v1.2 - Peb
- Added armor pieces, fixed some errors impacting labeling

v1.3 - Peb
- Added smithed armor
- Adjusted some volumes, quality cutoff points in anvil.dm

v1.4 - Peb
- New furnace art, metal and sandstone, with smoke and such.
- Added new sledgehammer art, so it matches the stuff in the module since its connected
- Added all missing inhands, spears now proper long
- Added some minor shading on a bunch of icons
- Adjusted pickaxe quality speed/range modifiers, was insanely good.
- Added the metal workbench + updated its art since it was made as a part of the module originally
- Changed notsword to workpiece because why God
- Refactored smithed twohanders so the correct art loads when wielded even in stupid Eris code


smw-tas
=======
**smw-tas** is an utility for making [Tool-Assisted Speedruns](http://tasvideos.org/) of Super Mario World and for debugging the game. The main script is done to be run on the [lsnes](http://tasvideos.org/Lsnes.html) emulator, but there's partial support for [BizHawk](http://tasvideos.org/BizHawk.html) and [Snes9x](https://code.google.com/p/snes9x-rr/).

Download page
-------------
Users are recommended to download the script(s) in the [downloads' wiki page](https://github.com/rodamaral/smw-tas/wiki/Downloads), according to their emulator.

Emulators version
-----------------
**lsnes:**
The latest release requires lsnes-rr2-β23++. This is the most complete script, with more features.

**BizHawk:**
There's a script for version 1.11.0++.
The functionality is better with maximized window, necessary to display text on the black lateral gaps.

**Snes9x-rr:**
The script works in the latest versions of 1.43 and 1.51. Snes9x 1.52 has poor Lua support and 1.53 doesn't have Lua.

Features
--------
Feature|lsnes | BizHawk |Snes9x
------------ | ------------- | ------------- | -------------
Movie info on screen|yes|yes|yes
Input display|yes|no, use TAStudio|no
Level info|yes|yes|yes
Player info/hitbox|yes|yes|yes
Sprite info/hitbox|yes|yes|yes
Yoshi/tongue info|yes|yes|yes
Extended sprite info/hitbox|yes|yes|yes
Cluster sprite info/hitbox|yes|yes|yes
Minor extended sprite info/hitbox|yes|yes|yes
Bounce sprite info|yes|yes|yes
Counters and timers|yes|yes|yes
Static Camera Region|yes|yes|yes
Line of death|yes|no|no
Tile drawing with mouse|yes|yes|yes
Open bus execution helper|yes|no|no
Cheats (controller)|yes|yes|yes
Cheats (form)|no|yes|no
Cheats (command)|yes|no|no
Comparison script|beta|no|[external](http://tasvideos.org/forum/viewtopic.php?p=219824#219824)


Comparison script (experimental)
--------------------------------
In order to add the comparison script to the main utility, follow the instructions:

 1.  Open **lib/simple-ghost-player.lua** and edit the option *ghost_dumps*, putting the file location of each ghost, between the brackets. Separate each file with a comma. E.g.: `local ghost_dumps  = { "SMW-any%.smwg", "C:/Folder/simpleghost837244.smwg"}`
 2. To run and see the ghosts, you must run **smw-tas-lsnes.lua**, click on *Menu* > *Settings* and select *Load comparison ghost* and *Show*. It's better to enter the level after this operation.
 3. You can generate the *smwg* files with **lsnes-dumpghost.lua** or **snes9x-dumpghost.lua**. To do so, load the movie that you wanna dump (read-only mode), pause at the beginning and start the script. To finish it, stop the script. The *smwg* will in the same directory of the emulator or of the generator script, depending on the emulator.

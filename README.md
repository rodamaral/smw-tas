smw-tas
=======
**smw-tas** is an utility for making [Tool-Assisted Speedruns](http://tasvideos.org/) of Super Mario World and for debugging the game. The main script is done to be run on the [lsnes](http://tasvideos.org/Lsnes.html) emulator, but there's partial support for [BizHawk](http://tasvideos.org/BizHawk.html) and [Snes9x](https://code.google.com/p/snes9x-rr/).

![smw-tas for lsnes screenshot](http://i.imgur.com/YpnrF1C.png)

----------
How to use
-------------
1. Clone the repository into a folder. You can choose between a more [tested and stable release](https://github.com/rodamaral/smw-tas/releases) or the [latest "nightly" software](https://github.com/rodamaral/smw-tas/archive/master.zip).
2. Open lsnes, go to *Tools > Run Lua script* and select **smw-tas-lsnes.lua**.
3. If you use BizHawk or Snes9x-rr, load their respective scripts at folder *extra*.

----------
Emulators version
-----------------
**lsnes:**
lsnes-rr2-β23 or higher.

**BizHawk:**
1.11.0 or higher.
Since 1.11.4, it's possible to set lateral gaps and use a much better font.

**Snes9x-rr:**
1.43 or 1.51.

----------
Features
--------
Those options are present in all the three utility scripts.
**Movie info**: signals the movie mode, frames recorded, lag count and rerecord count.
**Level Info**: type of level (horizontal or vertical), number of screens and buoyancy level flag.
**Player info**: positions, speeds, subspeed, camera, cape, blocked status, hitbox against sprites, points of interaction with tiles.
**Sprite info**: positions, speeds, stunned state number, many tables, hitbox against other objects, points of interaction with tiles.
**Yoshi/tongue info**: id, sprite on mouth, timings, length and hitbox.
**Other sprites info**: extended, cluster, minor extended and bounce sprites.
**Counters and timers**: counters that decrement once per frame or using some frame rule.
**Static Camera Region**: region on which the player must scape to scroll the camera.
**Tile drawing with mouse**: layer 1 (left click) and layer 2 (right click).
**Cheats**: current cheats include free movement, beat level (depends on ROM hack), powerup, score and coin number (for lag manipulation), dragging and dropping sprites with mouse. The user must click to allow the cheats before using them.

----------
***lsnes only:***
**Input display/editor**: in readonly mode, clicking on a future input will toggle the state of the selected button.
**Line of death**: always appear below the game area, showing where Mario or sprites die.
**Arbitrary code execution helper**: signals when some known or useful addresses are executed, such as joypad hardware registers and common open bus addresses. It doesn't cover addresses, using the tracelogger is still needed.
**Lagmeter**: shows how close to lagged the last frame has been.

----------
Comparison ghosts
--------------------------------
There's a tool that allows one to compare two runs while making a TAS. It's possible to dump the ghost info from lsnes or Snes9x and to read that info from lsnes. The module is heavily based on [amaurea's script](http://tasvideos.org/forum/viewtopic.php?p=219824&highlight=#219824):

 1.  To generate a ghost file, use the *record scripts* at **extra**. Start the script at the very beginning of the movie and stop whenever you want. After that, a *ghost.dump* file will appear. Put that file into the folder **ghosts** of this repository.
 2. To run and see the ghosts, you must run **smw-tas-lsnes.lua**, click on *Menu* > *Settings* and select *Load comparison ghost*. It's better to enter the current level/room after this operation.
 3. Edit **config.ini** to include or remove ghost files. It's under option "ghost_dump_files". 
eg.: `"ghost_dump_files": [ "ghost-amarat.dump", "ghost-ism-mister.dump", "bahamete,masterjun,pangaeapanga-supermarioworld-warps.dump", bahametekaizoman666misterpangaeapanga-supermarioworld-warps.dump" ],`

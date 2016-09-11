smw-tas
=======
**smw-tas** is an utility for making [Tool-Assisted Speedruns](http://tasvideos.org/) of Super Mario World and for debugging the game. The script can be run on the emulators:  [lsnes](http://tasvideos.org/Lsnes.html), [BizHawk](http://tasvideos.org/BizHawk.html) and [Snes9x-rr](https://code.google.com/p/snes9x-rr/).

![smw-tas for lsnes screenshot](http://i.imgur.com/YpnrF1C.png)

----------
How to use
-------------
1. Download the source code **zip** of the latest [release](https://github.com/rodamaral/smw-tas/releases) and extract its contents into a folder.
2. Alternatively, clone the [repository](https://github.com/rodamaral/smw-tas/archive/master.zip) into a folder.
3. Open the emulator and its Lua console.

  lsnes: *Tools > Run Lua script*.

  BizHawk: *Tools > Lua Console > Script > Open script*

  Snes9x-rr: *File > Lua Scripting > New Lua Script Window*
4. Run file **smw-tas.lua**.

----------
Emulators version
-----------------
**lsnes:**
lsnes-rr2-β23 or higher.

**BizHawk:**
1.11.0 or higher.
Since 1.11.4, it's possible to set lateral gaps and use a much better font.

**Snes9x-rr:**
1.43 or 1.51. Version 1.43 is not recommended due to poor emulation and to not computing lag like a real SNES would.

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

**Tile drawing with mouse**: layer 1 (left click), layer 2 (right click) and block duplication predictor.

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
 2. To see the ghosts as you play, you must run the main script on lsnes, click on *Menu* > *Settings* and select *Load comparison ghost*. It's better to enter the current level/room after this operation.
 3. Edit **config.ini** to include or remove ghost files. It's under option "ghost_dump_files".
eg.:
`"ghost_dump_files": [ "ghost1.dump", "ghost-ism-mister.dump", "smw-any%.dump", smw-96exits.dump" ],`

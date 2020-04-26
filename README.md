smw-tas
=======
**smw-tas** is an utility for making [Tool-Assisted Speedruns](http://tasvideos.org/) of Super Mario World and for debugging the game. The script can be run on the emulators:  [lsnes](http://tasvideos.org/Lsnes.html) and [Snes9x-rr](https://code.google.com/p/snes9x-rr/).

![smw-tas for lsnes screenshot](http://i.imgur.com/YpnrF1C.png)

----------
How to use
-------------

1. Download the source code **zip** of the latest [release](https://github.com/rodamaral/smw-tas/releases) and extract its contents into a folder.
2. Open the emulator and its Lua console.
  - lsnes: *Tools > Run Lua script*.
  - Snes9x-rr: *File > Lua Scripting > New Lua Script Window*

3. Run file **smw-tas.lua**.

#### Development

You need [LuaRocks](https://luarocks.org/) to install the dependencies.

1. Clone the [repository](https://github.com/rodamaral/smw-tas/archive/master.zip) into a folder: `git clone git@github.com:rodamaral/smw-tas.git`.
2. Open the `smw-tas` directory and run `luarocks make --tree lua_modules` to install the dependencies.

----------
Emulators version
-----------------
**lsnes:**
lsnes-rr2-β23 or higher.
As of 2018/08, make sure to **NOT** use the current β23 from TASVideos, as it's old and has a bug that can crash Lua scripts or mess up the display of background colors. More recent Windows builds are available in [true's website](https://lsnes.truecontrol.org/).

**Snes9x-rr:**
1.43 or 1.51.

**BizHawk:**
Support to BizHawk has been **deprecated**. You can use, for example [brunovalads/smw-stuff](https://github.com/brunovalads/smw-stuff), or an old release (not recommended).

----------
Features
--------
Those options are present in all the three utility scripts.

**Movie info**: signals the movie mode, frames recorded, lag count and rerecord count.

**Level Info**: type of level (horizontal or vertical), number of screens and buoyancy level flag.

**Player info**: positions, speeds, subspeed, camera, cape, blocked status, hitbox against sprites, points of interaction with tiles.

**Sprite info**: positions, speeds, stunned state number, many tables, hitbox against other objects, points of interaction with tiles, data, load status.

**Yoshi/tongue info**: id, sprite on mouth, timings, length and hitbox.

**Other sprites info**: extended, cluster, minor extended and bounce sprites.

**Counters and timers**: counters that decrement once per frame or using some frame rule.

**Static Camera Region**: region on which the player must scape to scroll the camera.

**Line of death**: always appear below the game area, showing where Mario or sprites die.

**Tile drawing with mouse**: layer 1 (left click), layer 2 (right click) and block duplication predictor.

**Cheats**: current cheats include free movement, beat level (depends on ROM hack), powerup, score and coin number (for lag manipulation), dragging and dropping sprites with mouse. The user must click to allow the cheats before using them.

*TODO: update those*

----------
***lsnes only:***

**Input display/editor**: in readonly mode, clicking on a future input will toggle the state of the selected button.

**Arbitrary code execution helper**: signals when some known or useful addresses are executed, such as joypad hardware registers and common open bus addresses. It doesn't cover addresses, using the tracelogger is still needed.

**Lagmeter**: shows how close to lagged the last frame has been.

*TODO: update those*

----------
Comparison ghosts
--------------------------------
There's a tool that allows one to compare two runs while making a TAS. It's possible to dump the ghost info from lsnes or Snes9x and to read that info from lsnes. The module is heavily based on [amaurea's script](http://tasvideos.org/forum/viewtopic.php?p=219824&highlight=#219824):

 1.  To generate a ghost file, use the *record scripts* at **extra**. Start the script at the very beginning of the movie and stop whenever you want. After that, a *ghost.dump* file will appear. Put that file into the folder **ghosts** of this repository.
 2. To see the ghosts as you play, you must run the main script on lsnes, click on *Menu* > *Settings* and select *Load comparison ghost*. It's better to enter the current level/room after this operation.
 3. Edit **config.ini** to include or remove ghost files. It's under option "ghost_dump_files".
eg.:
`"ghost_dump_files": [ "ghost1.dump", "ghost-ism-mister.dump", "smw-any%.dump", smw-96exits.dump" ],`

Comparison script (experimental)
--------------------------------
In order to add the comparison script to the main utility, follow the instructions:

 1. Open the configuration file **smw-tas.ini** and edit the option *ghost_filename*, putting the file location of **lsnes-player.lua**. The path can be absolute or relative to **lsnes-bsnes.exe**. 
E.g.: `ghost_filename = "C:/Folder/lsnes-player.lua"`
 2. Open **lsnes-player.lua** and edit the option *ghost_dumps*, putting the file location of each ghost, between the brackets. Separate each file with a comma. E.g.: `local ghost_dumps  = { "SMW-any%.smwg", "C:/Folder/simpleghost837244.smwg"}`
 3. To run and see the ghosts, you must run **smw-lsnes-rr2.lua**, click on *Menu* > *Settings* and select *Load comparison ghost* and *Show*. It's better to enter the level after this operation.
 4. You can generate the *smwg* files with **lsnes-dumpghost.lua** or **snes9x-dumpghost.lua**. To do so, load the movie that you wanna dump (read-only mode), pause at the beginning and start the script. To finish it, stop the script. The *smwg* will in the same directory of the emulator or of the generator script, depending on the emulator.

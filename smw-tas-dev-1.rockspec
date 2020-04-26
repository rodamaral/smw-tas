package = "smw-tas"
version = "dev-1"
supported_platforms = {"linux", "macosx", "windows"}
source = {
   url = "git+ssh://git@github.com/rodamaral/smw-tas.git"
}
description = {
   summary = "Utility scripts and TAS tools for Super Mario World to be run on lsnes or Snes9x-rr.",
   detailed = "smw-tas is an utility for making Tool-Assisted Speedruns of Super Mario World and for debugging the game. The script can be run on the emulators: lsnes and Snes9x-rr.",
   homepage = "https://github.com/rodamaral/smw-tas",
   license = "The MIT License (MIT)"
}
dependencies = {
    "argparse >= 0.7.0"
}
build = {
   type = "builtin",
   modules = {}
}

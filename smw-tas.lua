local SCRIPTS_FOLDER = "src"
local ERROR_MESSAGE =  "Your emulator is not supported"

if lsnes_features then -- lsnes emulator
  -- run just one instance of smw-tas per Lua VM
  assert(not SMW_TAS_RUNNING, "smw-tas is already running!\n" ..
    "You can reset all the Lua Virtual Machine at Tools > Reset Lua VM")
  SMW_TAS_RUNNING = true

  local LUA_SCRIPT_FILENAME = load([==[return @@LUA_SCRIPT_FILENAME@@]==])()

  GLOBAL_SMW_TAS_PARENT_DIR = LUA_SCRIPT_FILENAME:match("(.+)[/\\][^/\\+]") .. "/"

  local file = assert(loadfile(GLOBAL_SMW_TAS_PARENT_DIR ..
    SCRIPTS_FOLDER .. "/smw-lsnes.lua"))
  file()

elseif bizstring then -- BizHawk emulator
  local file = assert(loadfile(SCRIPTS_FOLDER .. "\\smw-bizhawk.lua"))
  file()

elseif snes9x then -- Snes9x-rr emulator
  local file = assert(loadfile(SCRIPTS_FOLDER .. "\\smw-snes9x.lua"))
  file()

else
  print(ERROR_MESSAGE)
end

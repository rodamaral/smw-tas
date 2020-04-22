local lsnes_features = _G.lsnes_features
local snes9x = _G.snes9x

local ERROR_MESSAGE = 'Your emulator is not supported'
local LSNES_FILENAME_TOKEN = [==[return @@LUA_SCRIPT_FILENAME@@]==]
local file, err

if lsnes_features then -- lsnes emulator
    local directory = 'lsnes/scripts/'

    -- run just one instance of smw-tas per Lua VM
    assert(not _G.SMW_TAS_RUNNING, 'smw-tas is already running!\n' ..
           'You can reset all the Lua Virtual Machine at Tools > Reset Lua VM')
    _G.SMW_TAS_RUNNING = true

    local script_filename = load(LSNES_FILENAME_TOKEN)()
    _G.GLOBAL_SMW_TAS_PARENT_DIR = script_filename:match('(.+)[/\\][^/\\+]') .. '/'
    file, err = assert(loadfile(_G.GLOBAL_SMW_TAS_PARENT_DIR .. directory .. 'smw-lsnes.lua'))
elseif snes9x then -- Snes9x-rr emulator
    local directory = 'snes9x/scripts/'
    file, err = assert(loadfile(directory .. 'smw-snes9x.lua'))
else
    error(ERROR_MESSAGE)
end

if file then
    file()
else
    error(err)
end

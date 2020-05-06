local movie= _G.movie
local cheat = require('cheat')
local controller = require('lsnes').controller

local M = {}

function M:new(joypad)
    local function on_input (--[[ subframe ]])
        if not movie.rom_loaded() or not controller.info_loaded then return end

        joypad:getKeys()
        cheat.on_input()
    end

    return on_input
end

return M

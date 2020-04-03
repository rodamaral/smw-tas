local M = {}

local memory2 = _G.memory2

local config = require 'config'
local smw = require 'game.smw'

local OPTIONS = config.OPTIONS
local DEBUG_REGISTER_ADDRESSES = smw.DEBUG_REGISTER_ADDRESSES

function M.register_debug_callback(toggle)
    if not toggle then
        for index in ipairs(DEBUG_REGISTER_ADDRESSES) do
            DEBUG_REGISTER_ADDRESSES[index].fn = function()
                DEBUG_REGISTER_ADDRESSES.active[index] = true
            end
        end
    end

    if toggle then OPTIONS.register_ACE_debug_callback = not OPTIONS.register_ACE_debug_callback end

    if OPTIONS.register_ACE_debug_callback then
        for _, addr_table in ipairs(DEBUG_REGISTER_ADDRESSES) do
            memory2[addr_table[1]]:registerexec(addr_table[2], addr_table.fn)
            --[[ print(string.format("Registering address $%x at memory area %s.",
        addr_table[2], addr_table[1]), addr_table.fn) ]]
        end
    else
        for _, addr_table in ipairs(DEBUG_REGISTER_ADDRESSES) do
            memory2[addr_table[1]]:unregisterexec(addr_table[2], addr_table.fn)
            --[[ print(string.format("Unregistering address $%x at memory area %s.",
        addr_table[2], addr_table[1]), addr_table.fn) ]]
        end
    end

    config.save_options()
end

return M

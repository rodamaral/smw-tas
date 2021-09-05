local memory = _G.memory
local smw = require 'game.smw'
local lsnes = require 'lsnes'
local mem = require 'memory'

local WRAM = smw.WRAM
local u8 = mem.u8
local s16 = mem.s16

local M = {}

function M:new(interface)
    local options = interface.options
    local state = interface.state
    local movieinfo = interface.movieinfo
    local address_watcher = interface.address_watcher
    local registered_addresses = interface.registered_addresses

    local function on_frame_emulated()
        local lagged
        if options.use_custom_lag_detector then
            lagged = not lsnes.Controller_latch_happened or (u8(0x10) == 0)
            movieinfo.set_lagged(lagged)
        else
            lagged = memory.get_lag_flag()
            movieinfo.set_lagged(lagged)
        end
        if options.use_custom_lagcount then
            memory.set_lag_flag(lagged)
        end

        -- Resets special WRAM addresses for changes
        for _, inner in pairs(address_watcher) do
            inner.watching_changes = false
        end

        if
            options.register_player_position_changes == 'simple'
            and options.display_player_info
            and state.previous.next_x
        then
            local change = s16(WRAM.x) - state.previous.next_x
            registered_addresses.mario_position = change == 0 and ''
                or (change > 0 and (change .. '→') or (-change .. '←'))
        end
    end

    return on_frame_emulated
end

return M

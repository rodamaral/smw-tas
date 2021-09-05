-- FIXME: module seems to be unused
-- FIXME: uses external global variable
local M = {}

local memory = _G.memory

local luap = require 'luap'
local mem = require 'memory'
local config = require 'config'
local smw = require 'game.smw'

local WRAM = smw.WRAM
local OPTIONS = config.OPTIONS
local u8 = mem.u8
local s16 = mem.s16

-- Private methods

-- Public methods

-- Resets special WRAM addresses for changes
for _, inner in pairs(M) do
    inner.watching_changes = false
end

-- Resets special WRAM addresses for changes
for _, inner in pairs(M) do
    inner.watching_changes = false
    inner.info = ''
end

-- Register special WRAM addresses for changes
M[WRAM.x] = {
    watching_changes = false,
    register = function(_, value)
        local tabl = M[WRAM.x]
        if tabl.watching_changes then
            local new = luap.signed16(256 * u8(WRAM.x + 1) + value)
            local change = new - s16(WRAM.x)
            if OPTIONS.register_player_position_changes == 'complete' and change ~= 0 then
                Registered_addresses.mario_position = Registered_addresses.mario_position
                    .. (change > 0 and (change .. '→') or (-change .. '←'))
                    .. ' '

                -- Debug: display players' hitbox when position changes
                Midframe_context:set()
                player.player_hitbox(
                    new,
                    s16(WRAM.y),
                    u8(WRAM.is_ducking),
                    u8(WRAM.powerup),
                    1,
                    DBITMAPS.interaction_points_palette_alt
                )
            end
        end

        tabl.watching_changes = true
    end,
}

M[WRAM.y] = {
    watching_changes = false,
    register = function(_, value)
        local tabl = M[WRAM.y]
        if tabl.watching_changes then
            local new = luap.signed16(256 * u8(WRAM.y + 1) + value)
            local change = new - s16(WRAM.y)
            if OPTIONS.register_player_position_changes == 'complete' and change ~= 0 then
                Registered_addresses.mario_position = Registered_addresses.mario_position
                    .. (change > 0 and (change .. '↓') or (-change .. '↑'))
                    .. ' '

                -- Debug: display players' hitbox when position changes
                if math.abs(new - Previous.y) > 1 then -- ignores the natural -1 for y, while on top of a block
                    Midframe_context:set()
                    player.player_hitbox(
                        s16(WRAM.x),
                        new,
                        u8(WRAM.is_ducking),
                        u8(WRAM.powerup),
                        1,
                        DBITMAPS.interaction_points_palette_alt
                    )
                end
            end
        end

        tabl.watching_changes = true
    end,
}

for address, inner in pairs(M) do
    memory.registerwrite('WRAM', address, inner.register)
end

function M.new()
    local t = {}
    setmetatable(t, { __index = M })

    return t
end

return M

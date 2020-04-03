local M = {}

local memory = _G.memory

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = memory.readbyte
local s16 = memory.readsword
local fmt = string.format
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant

-- sprite_table environment
do
    local height, xCam, yCam, bounce_sprite_number, stop_id, xPos, yPos, xText, yText

    local function sprite_info(id)
        xPos = luap.signed16(256 * u8('WRAM', WRAM.bouncespr_x_high + id) +
                             u8('WRAM', WRAM.bouncespr_x_low + id))
        yPos = luap.signed16(256 * u8('WRAM', WRAM.bouncespr_y_high + id) +
                             u8('WRAM', WRAM.bouncespr_y_low + id))
        local bounce_timer = u8('WRAM', WRAM.bouncespr_timer + id)

        if OPTIONS.display_debug_bounce_sprite then
            draw.text(xText, yText + height * (id + 1),
                      fmt('#%d:%d (%d, %d)', id, bounce_sprite_number, xPos, yPos))
        end

        if OPTIONS.display_bounce_sprite_info then
            local x_screen, y_screen = screen_coordinates(xPos, yPos, xCam, yCam)
            x_screen, y_screen = draw.AR_x * (x_screen + 8), draw.AR_y * y_screen

            local color = id == stop_id and COLOUR.warning or COLOUR.text
            draw.text(x_screen, y_screen, fmt('#%d:%d', id, bounce_timer), color, false, false, 0.5) -- timer

            -- Turn blocks
            if bounce_sprite_number == 7 then
                local turn_block_timer = u8('WRAM', WRAM.turn_block_timer + id)
                draw.text(x_screen, y_screen + height, turn_block_timer, color, false, false, 0.5)
            end
        end
    end

    function M.sprite_table()
        if not OPTIONS.display_bounce_sprite_info then return end

        -- Debug info
        xText, yText = draw.AR_x * 90, draw.AR_y * 37
        if OPTIONS.display_debug_bounce_sprite then
            draw.Font = 'snes9xluasmall'
            draw.text(xText, yText, 'Bounce Spr.', COLOUR.weak)
        end

        xCam = s16('WRAM', WRAM.camera_x)
        yCam = s16('WRAM', WRAM.camera_y)

        -- Font
        draw.Font = 'Uzebox6x8'
        height = draw.font_height()

        stop_id = (u8('WRAM', WRAM.bouncespr_last_id) - 1) % SMW.bounce_sprite_max
        for id = 0, SMW.bounce_sprite_max - 1 do
            bounce_sprite_number = u8('WRAM', WRAM.bouncespr_number + id)
            if bounce_sprite_number ~= 0 then sprite_info(id) end
        end
    end
end

return M

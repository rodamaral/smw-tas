local M = {}

local luap = require 'luap'
local mem = require('memory')
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local s8 = mem.s8
local s16 = mem.s16
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant
local fmt = string.format
local floor = math.floor

-- sprite_table environment
do
    local xText, yText, xCam, yCam, minorspr_number, counter, height

    local function draw_near_sprite(id, timer, x_screen, y_screen)
        if OPTIONS.display_minor_extended_sprite_info then
            local text = '#' .. id .. (timer ~= 0 and (' ' .. timer) or '')
            draw.text(draw.AR_x * (x_screen + 8), draw.AR_y * (y_screen + 4), text,
                      COLOUR.minor_extended_sprites, false, false, 0.5, 1.0)
        end
    end

    local function sprite_info(id)
        -- Reads WRAM addresses
        local x = luap.signed16(256 * u8(WRAM.minorspr_x_high + id) +
                                u8(WRAM.minorspr_x_low + id))
        local y = luap.signed16(256 * u8(WRAM.minorspr_y_high + id) +
                                u8(WRAM.minorspr_y_low + id))
        local xspeed, yspeed = s8(WRAM.minorspr_xspeed + id),
                               s8(WRAM.minorspr_yspeed + id)
        local x_sub, y_sub = u8(WRAM.minorspr_x_sub + id),
                             u8(WRAM.minorspr_y_sub + id)
        local timer = u8(WRAM.minorspr_timer + id)

        -- Only sprites 1 and 10 use the higher byte
        local x_screen, y_screen = screen_coordinates(x, y, xCam, yCam)
        if minorspr_number ~= 1 and minorspr_number ~= 10 then -- Boo stream and Piece of brick block
            x_screen = x_screen % 0x100
            y_screen = y_screen % 0x100
        end

        draw_near_sprite(id, timer, x_screen, y_screen)

        if OPTIONS.display_minor_extended_sprite_hitbox and minorspr_number == 10 then -- Boo stream
            draw.rectangle(x_screen + 4, y_screen + 4, 8, 8, COLOUR.minor_extended_sprites,
                           COLOUR.sprites_bg)
        end

        -- Draw in the table
        if OPTIONS.display_debug_minor_extended_sprite then
            draw.text(xText, yText + counter * height,
                      fmt('#%d(%d): %d.%x(%d), %d.%x(%d)', id, minorspr_number, x,
                          floor(x_sub / 16), xspeed, y, floor(y_sub / 16), yspeed),
                      COLOUR.minor_extended_sprites)
        end
        counter = counter + 1
    end

    function M.sprite_table()
        draw.Text_opacity = 1.0
        draw.Font = 'Uzebox6x8'
        height = draw.font_height()
        xText, yText = 0, draw.Buffer_height - height * SMW.minor_extended_sprite_max
        counter = 0

        xCam = s16(WRAM.camera_x)
        yCam = s16(WRAM.camera_y)

        for id = 0, SMW.minor_extended_sprite_max - 1 do
            minorspr_number = u8(WRAM.minorspr_number + id)
            if minorspr_number ~= 0 then sprite_info(id) end
        end

        if OPTIONS.display_debug_minor_extended_sprite then
            draw.text(xText, yText - height, 'Minor Ext Spr:' .. counter, COLOUR.weak)
        end
    end
end

return M

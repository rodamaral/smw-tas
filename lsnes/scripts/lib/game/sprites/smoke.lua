local M = {}

local config = require 'config'
local mem = require 'memory'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local s16 = mem.s16
local OPTIONS = config.OPTIONS
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant

-- sprite_table environment
do
    local xText, yText, height, xCam, yCam, xPos, yPos, number, color

    local function draw_near_sprite(slot)
        local x, y = screen_coordinates(xPos, yPos, xCam, yCam)

        x = x % 0x100
        y = y % 0x100

        local timer = u8(WRAM.smokespr_timer + slot)
        local text = string.format('#%x %s', slot, timer)

        draw.Font = 'Uzebox6x8'
        draw.text(draw.AR_x * x, draw.AR_y * y, text, color, 0x000060)
    end

    local function sprite_info(slot)
        xPos = u8(WRAM.smokespr_x + slot)
        yPos = u8(WRAM.smokespr_y + slot)

        color = (number <= 3 or number == 5) and 0xf0d89e or 0xff0000
        local text = string.format('#%x: %.2x (%x, %x)', slot, number, xPos, yPos)

        draw.Font = 'Uzebox8x12'
        draw.text(xText, yText, text, color, 0x000030)
        draw_near_sprite(slot)
    end

    function M.sprite_table()
        if not OPTIONS.display_smoke_sprite_info then
            return
        end

        draw.Font = 'Uzebox8x12'
        height = draw.font_height()
        xText = draw.AR_y * 80
        yText = draw.AR_y * 248
        xCam = s16(WRAM.camera_x)
        yCam = s16(WRAM.camera_y)

        draw.text(xText, yText, 'Smoke sprites:', 0xf0d89e, 0x000030)
        yText = yText + height

        for slot = 0, SMW.smoke_sprite_max - 1 do
            number = u8(WRAM.smokespr_number + slot)

            if number ~= 0 then
                sprite_info(slot)
                yText = yText + height
            end
        end
    end
end

return M

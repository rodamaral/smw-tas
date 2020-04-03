local M = {}

local memory = _G.memory

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = memory.readbyte
local s16 = memory.readsword
local OPTIONS = config.OPTIONS
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant

-- sprite_table environment
do
    local xText, yText, height, xCam, yCam, realFrame, xPos, yPos, number, color

    local function draw_near_sprite(slot)
        local x, y = screen_coordinates(xPos, yPos, xCam, yCam)
        local timer = u8('WRAM', WRAM.shooter_timer + slot)
        local realTimer = 2 * timer - (realFrame % 2 == 0 and 1 or 0)
        local text = string.format('#%x %s', slot, realTimer)

        draw.Font = 'Uzebox6x8'
        draw.text(draw.AR_x * x, draw.AR_y * y, text, color, 0x000060)
    end

    local function sprite_info(slot)
        local xLow = u8('WRAM', WRAM.shooter_x_low + slot)
        local xHigh = u8('WRAM', WRAM.shooter_x_high + slot)
        local yLow = u8('WRAM', WRAM.shooter_y_low + slot)
        local yHigh = u8('WRAM', WRAM.shooter_y_high + slot)

        xPos = luap.signed16(0x100 * xHigh + xLow)
        yPos = luap.signed16(0x100 * yHigh + yLow)
        color = number <= 2 and 0x6bf442 or 0xf40842
        local text = string.format('#%x: %.2x (%d, %d)', slot, number, xPos, yPos)

        draw.Font = 'Uzebox8x12'
        draw.text(xText, yText, text, color, 0x000030)
        draw_near_sprite(slot)
    end

    function M.sprite_table()
        if not OPTIONS.display_shooter_sprite_info then return end

        draw.Font = 'Uzebox8x12'
        height = draw.font_height()
        xText = draw.AR_x * 160
        yText = draw.AR_y * 248
        xCam = s16('WRAM', WRAM.camera_x)
        yCam = s16('WRAM', WRAM.camera_y)
        realFrame = u8('WRAM', WRAM.real_frame)

        draw.text(xText, yText, 'Shooters:', 0x6bf442, 0x000030)
        yText = yText + height

        for slot = 0, SMW.shooter_sprite_max - 1 do
            number = u8('WRAM', WRAM.shooter_number + slot)

            if number ~= 0 then
                sprite_info(slot)
                yText = yText + height
            end
        end
    end
end

return M
